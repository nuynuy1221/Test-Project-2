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
        BuyMemoria = false
    }
end

local Config = getgenv().Config
if type(Config) ~= "table" then
    Config = { BuyMemoria = false }
    getgenv().Config = Config
end

-- บังคับให้เปิดได้เฉพาะ true เท่านั้น
Config.BuyMemoria = (Config.BuyMemoria == true)

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
    local success, items = pcall(function()
        return playerGui
            :WaitForChild("Windows", 8)
            :WaitForChild("GlobalInventory", 8)
            .Holder.LeftContainer.FakeScrollingFrame.Items:GetChildren()
    end)

    if not success or not items then
        warn("ไม่เจอ Inventory Items")
        return false
    end

    for _, group in ipairs(items) do
        for _, cache in ipairs(group:GetChildren()) do
            if cache.Name == "CacheContainer" then
                for _, group in ipairs(items) do
                    for _, uuid in ipairs(group:GetChildren()) do
                        local ok, label = pcall(function()
                            return uuid.Container.Holder.Main.UnitName
                        end)

                        if ok and label then
                            local name = (label.ContentText or label.Text or ""):gsub("%s+$","")
                            if name == "Ice Queen (Release)" then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- =========================
-- เช็ค Memoria : Ice Queen's Rest
-- =========================
local function hasIceQueenRest()
    local success, items = pcall(function()
        return playerGui
            :WaitForChild("Windows", 8)
            :WaitForChild("GlobalInventory", 8)
            .Holder.LeftContainer.FakeScrollingFrame.Items:GetChildren()
    end)

    if not success or not items then
        warn("ไม่เจอ Inventory Items")
        return false
    end

    -- Items จะมีหลายกล่อง และแต่ละกล่องมี CacheContainer ซ้ำ ๆ
    for _, group in ipairs(items) do
        for _, cache in ipairs(group:GetChildren()) do
            if cache.Name == "CacheContainer" then
                for _, group in ipairs(items) do
                    for _, uuid in ipairs(group:GetChildren()) do
                        local ok, label = pcall(function()
                            return uuid.Container.Holder.Main.MemoriaName
                        end)

                        if ok and label then
                            local name = (label.ContentText or ""):gsub("%s+$","")
                            if name == "Ice Queen's Rest" then
                                return true
                            end
                        end
                    end
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

        if hasUnit then
            print("✅ มี Ice Queen (Release) → เริ่ม Winter")
            task.wait(60)
            GoWinter()

        else
            if presents >= 1500 then
                if Config.BuyMemoria and not hasMemoria then
                    print("🎴 ยังไม่มี Ice Queen's Rest → Summon Memoria x10")
                    summonEvent:FireServer(unpack(memoriaArgs))
                    task.wait(2.5)
                else
                    print("❄️ Summon Winter26 x10")
                    summonEvent:FireServer(unpack(summonArgs))
                    task.wait(2)
                end
            else
                print("🎮 Presents26 ไม่พอ → เข้า Winter ฟาร์ม")
                task.wait(60)
                GoWinter()
            end
        end
    end)

    if not success then
        warn("❌ Error ใน loop:", err)
    end

    task.wait(1.5)
end
