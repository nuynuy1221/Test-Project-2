repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม้อัพเกรดกระเป๋าให้")
    return
end

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
repeat task.wait() until player and player:FindFirstChild("PlayerGui")

local playerGui = player.PlayerGui

-- =========================
-- CONFIG
-- =========================
local MAX_UNIT = 300
local CHECK_DELAY = 3 -- เช็คทุกกี่วิ (กัน spam)

-- =========================
-- Get Max Unit From Text (x/y)
-- =========================
local function getMaxUnit()
    local ok, label = pcall(function()
        return playerGui.Windows.GlobalInventory.Holder
            .LeftContainer.BottomBar.OwnedItems.ItemAmount
    end)

    if not ok or not label then
        return nil
    end

    local text = label.ContentText or label.Text
    if not text then
        return nil
    end

    -- ดึงเลขหลัง /
    local current, max = text:match("(%d+)%s*/%s*(%d+)")
    if max then
        return tonumber(max)
    end

    return nil
end

-- =========================
-- Purchase Unit Expansion
-- =========================
local function purchaseUnitExpansion()
    local args = {
        [1] = "Purchase"
    }

    ReplicatedStorage:WaitForChild("Networking")
        :WaitForChild("UnitExpansionEvent")
        :FireServer(unpack(args))

    print("[UnitExpansion] Purchase fired")
end

-- =========================
-- Main Loop
-- =========================
task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local maxUnit = getMaxUnit()
        if maxUnit then
            print("[UnitExpansion] Current Max =", maxUnit)

            if maxUnit < MAX_UNIT then
                purchaseUnitExpansion()
            else
                print("[UnitExpansion] Max Unit reached (300)")
            end
        end
    end
end)
