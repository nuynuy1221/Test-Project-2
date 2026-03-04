repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่เข้าแมพให้")
    return
end

-- RESET CONFIG ถ้าไม่ได้ตั้งเอง
if getgenv().Config == nil then
    getgenv().Config = {
        BuyMemoria = false,
        LockLV = nil
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = {
        BuyMemoria = false,
        LockLV = nil
    }
    getgenv().Config = Config
end

-- บังคับให้เปิดได้เฉพาะ true เท่านั้น
Config.BuyMemoria = (Config.BuyMemoria == true)

-- LockLV ต้องเป็นตัวเลขเท่านั้น
if type(Config.LockLV) ~= "number" then
    Config.LockLV = nil
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rep = game:GetService("ReplicatedStorage")
local playerGui = player:WaitForChild("PlayerGui", 10)

-- =========================
-- ฟังก์ชันดึงเลเวลจาก Attribute (เสถียรกว่า GUI)
-- =========================
local function getLevel()
    -- ชื่อ Attribute ที่น่าจะเป็น (เรียงจากน่าจะเจอมากที่สุด)
    local possibleLevelNames = {
        "Level",          -- ชื่อมาตรฐานที่สุด
        "PlayerLevel",
        "level",
        "playerLevel",
        "CurrentLevel"
    }
    
    for _, name in ipairs(possibleLevelNames) do
        local value = player:GetAttribute(name)
        if value ~= nil then
            local num = tonumber(value)
            if num then
                print("พบ Level จาก Attribute:", name, "=", num)  -- debug ว่าชื่อจริงคืออะไร
                return num
            end
        end
    end
    
    -- ถ้าไม่เจอเลย ให้ fallback ไปเช็ค GUI เดิม (หรือ return 0)
    warn("ไม่พบ Attribute Level — fallback ไปเช็ค GUI")
    local success, levelLabel = pcall(function()
        return playerGui:WaitForChild("HUD", 5)
                     :WaitForChild("Main", 5)
                     :WaitForChild("Level", 5)  -- หรือปรับ path ตามจริง
    end)
    
    if success and levelLabel and levelLabel:IsA("TextLabel") then
        local text = levelLabel.Text or ""
        local num = text:match("%d+")  -- ดึงตัวเลขแรก
        return tonumber(num) or 0
    end
    
    return 0  -- ถ้าไม่เจอทั้งคู่
end

-- =========================
-- ฟังก์ชัน WinterEvent
-- =========================
local function GoWinter()
    print("🔥 Level ≥ 11 → WinterEvent")
    
    local winterEvent = rep:WaitForChild("Networking"):WaitForChild("Winter"):WaitForChild("WinterLTMEvent")
    local lobbyEvent = rep:WaitForChild("Networking"):WaitForChild("LobbyEvent")
    
    pcall(function() winterEvent:FireServer("Create", "Normal") end)
    task.wait(3)
    pcall(function() lobbyEvent:FireServer("StartMatch") end)
end

-- =========================
-- เช็ค Presents26 (ทำให้ง่ายขึ้น)
-- =========================
local function getPresents26()
    local value = player:GetAttribute("Presents26")
    if value ~= nil then
        return tonumber(value) or 0
    end
    return 0
end

-- =========================
-- เช็ค Ice Queen (Release)
-- =========================
local function hasIceQueen()

    if game.PlaceId ~= 16146832113 then
        return false
    end

    local items
    local start = tick()

    repeat
        local ok
        ok, items = pcall(function()
            return playerGui.Windows.GlobalInventory.Holder
                .LeftContainer.FakeScrollingFrame.Items
        end)
        task.wait(0.5)
    until items or tick() - start > 15

    if not items then
        warn("[IceQueen] ❌ Items not loaded")
        return false
    end

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then
            for _, uuid in ipairs(cache:GetChildren()) do
                local holder = uuid:FindFirstChild("Container")
                    and uuid.Container:FindFirstChild("Holder")

                if holder and holder:FindFirstChild("Ice Queen (Release)") then
                    print("✅ FOUND Ice Queen (Release)")
                    return true
                end
            end
        end
    end

    return false
end

-- =========================
-- เช็ค Memoria : Ice Queen's Rest (FIX ให้ตรงกับ Horst Script)
-- =========================
local function hasIceQueenRest()

    if game.PlaceId ~= 16146832113 then
        return false
    end

    local items
    local start = tick()

    repeat
        local ok
        ok, items = pcall(function()
            return playerGui.Windows.GlobalInventory.Holder
                .LeftContainer.FakeScrollingFrame.Items:GetChildren()
        end)
        task.wait(0.5)
    until (items and #items > 0) or tick() - start > 15

    if not items then
        warn("[Memoria] ❌ Items not loaded")
        return false
    end

    for _, group in ipairs(items) do
        for _, uuid in ipairs(group:GetChildren()) do
            local ok2, label = pcall(function()
                return uuid.Container.Holder.Main.MemoriaName
            end)

            if ok2 and label then
                local name = (label.ContentText or label.Text or "")
                    :gsub("%s+$","")

                if name == "Ice Queen's Rest" then
                    print("✅ FOUND Ice Queen's Rest")
                    return true
                end
            end
        end
    end

    return false
end

-- =========================
-- Summon Event
-- =========================

-- Summon ตัวละคร
local summonEvent = rep:WaitForChild("Networking")
    :WaitForChild("Units")
    :WaitForChild("SummonEvent")

local summonArgs = {"SummonMany", "Winter26", 10}

-- 🔹 Summon Memoria
local memoriaArgs = {"SummonMany", "WinterMemoria", 10}


-- =========================
-- ลูปหลัก (เพิ่ม pcall ห่อเพื่อป้องกัน crash)
-- =========================
while true do
    local DelayCheck = 0.2
    local success, err = pcall(function()
        local level = getLevel()
        local presents = getPresents26()

        local hasUnit = hasIceQueen()
        local hasMemoria = hasIceQueenRest()

        print(
            "🧠 Decision | Level:", level,
            "| Presents:", presents,
            "| Has Unit:", hasUnit,
            "| Has Memoria:", hasMemoria,
            "| BuyMemoria:", Config.BuyMemoria
        )

        -- ❌ ไม่เข้า Story แล้ว ไม่สน Level
        -- ทำแต่ Winter เท่านั้น

        if hasUnit and hasMemoria then
            if not Config.LockLV then
                print("✅ มีของครบอยู่แล้ว (ไม่ล็อคเลเวล)")
                DelayCheck = 600

            elseif level >= Config.LockLV then
                print("🔒 ถึงเลเวลที่ล็อคแล้ว อยู่เฉยๆ")
                DelayCheck = 600
            else
                print("📈 เวลไม่ถึง ล็อคไว้ ต้องไปฟาร์ม")
                task.wait(60)
                GoWinter()
            end
        elseif presents >= 1500 then
            if hasMemoria and not hasUnit then
                print("⁉️ มีแค่ Memoria")
                summonEvent:FireServer(unpack(summonArgs))
                task.wait(1)
            elseif not hasMemoria and hasUnit then
                if Config.BuyMemoria then
                    print("⁉️ มีแค่ Ice Queen (Release)")
                    summonEvent:FireServer(unpack(memoriaArgs))
                    task.wait(1)
                else
                    print("❌ ไม่มี Config Memoria")
                end
            else
                print("❌ ไม่มีทั้งคู่")

                if Config.BuyMemoria then
                    print("❎ มี Config Memoria")
                    summonEvent:FireServer(unpack(memoriaArgs))
                    task.wait(1)
                else
                    print("❎ ไม่มี Config Memoria")
                    summonEvent:FireServer(unpack(summonArgs))
                    task.wait(1)
                end
            end
        else
            print("❌ ไม่มี Presents ไปฟาร์ม")
            task.wait(60)
            GoWinter()
        end
    end)

    if not success then
        warn("❌ Error ใน loop:", err)
    end

    task.wait(DelayCheck)
end
