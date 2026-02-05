repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================
-- GUI HUD
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ColorfulStatusHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local function createBar(name, posScale, bgColor, emoji)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,0,posScale,0)
    frame.Size = UDim2.new(0.85,0,0.15,0)
    frame.BackgroundColor3 = bgColor
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,20)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = bgColor:lerp(Color3.new(1,1,1),0.3)
    stroke.Thickness = 4

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = emoji.." "..name
    label.ZIndex = 11
    label.Parent = frame

    return label
end

local userLabel   = createBar("User", 0.18, Color3.fromRGB(52,152,219), "🧑")
local levelLabel  = createBar("Level", 0.36, Color3.fromRGB(46,204,113), "🏆")
local presents26Label = createBar("Presents26", 0.54, Color3.fromRGB(241,196,15), "🎁")
local icequeenLabel   = createBar("IceQueen", 0.72, Color3.fromRGB(231,76,60), "👑")

-- =========================
-- Attribute
-- =========================
if player:GetAttribute("HasIceQueen") == nil then
    player:SetAttribute("HasIceQueen", false)
end

-- =========================
-- Helper
-- =========================
local function getAttr(list)
    for _, name in ipairs(list) do
        local v = player:GetAttribute(name)
        if v ~= nil then return tonumber(v) or 0 end
    end
    return 0
end

local function getLevel()
    return getAttr({"Level", "level", "PlayerLevel", "currentLevel"})
end

local function getPresents26()
    return getAttr({"Presents26", "presents26"})
end

-- =========================
-- เช็ค Ice Queen แยกตาม PlaceId (ไม่สน GUID)
-- =========================
local TARGET = "Ice Queen"  -- ชื่อตัวละครที่ต้องการเช็ค

local function checkIceQueen()
    local currentPlace = game.PlaceId
    
    if currentPlace == 16277809958 then
        -- แมพ 16277809958 → เช็คจาก Units tab
        local success, units = pcall(function()
            return playerGui
                :WaitForChild("Windows", 5)
                :WaitForChild("Units", 5)
                .Holder.Main.Units
        end)
        
        if not success or not units then return false end
        
        for _, unitItem in ipairs(units:GetChildren()) do
            local success, nameLabel = pcall(function()
                return unitItem.Container.Holder.Main.UnitName
            end)
            
            if success and nameLabel and nameLabel.Text then
                if nameLabel.Text:lower():find(TARGET:lower()) then
                    return true
                end
            end
        end
        return false
        
    elseif currentPlace == 16146832113 then
        -- แมพ 16146832113 → เช็คจาก GlobalInventory CacheContainer
        local success, cacheContainer = pcall(function()
            return playerGui
                :WaitForChild("Windows", 5)
                :WaitForChild("GlobalInventory", 5)
                .Holder.LeftContainer.FakeScrollingFrame.Items.CacheContainer
        end)
        
        if not success or not cacheContainer then return false end
        
        for _, guidFrame in ipairs(cacheContainer:GetChildren()) do
            local success, nameLabel = pcall(function()
                return guidFrame.Container.Holder.Main.UnitName
            end)
            
            if success and nameLabel and nameLabel.Text then
                if nameLabel.Text:lower():find(TARGET:lower()) then
                    return true
                end
            end
        end
        return false
        
    else
        -- แมพอื่น → แสดงว่าไม่มี Ice Queen
        return false
    end
end

-- =========================
-- Update HUD (ห่อ pcall ป้องกัน error)
-- =========================
RunService.RenderStepped:Connect(function()
    local ok = pcall(function()
        userLabel.Text   = "🤖 User : "..player.Name
        levelLabel.Text  = "⬆️ Level : "..getLevel()
        presents26Label.Text = "🎁 Presents : "..getPresents26()

        local has = checkIceQueen()
        player:SetAttribute("HasIceQueen", has)

        icequeenLabel.Text = "👑 Ice Queen : "..(has and "✅" or "❌")
    end)
end)

print("สคริปต์ทำงานแล้ว - เช็ค Ice Queen แยกตาม PlaceId")
