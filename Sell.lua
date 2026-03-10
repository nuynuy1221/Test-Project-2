repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่รันสคริปต์")
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
repeat task.wait() until player:FindFirstChild("PlayerGui")

local playerGui = player.PlayerGui

local Networking = ReplicatedStorage:WaitForChild("Networking")

local MemoriaEvent = Networking
    :WaitForChild("Memorias")
    :WaitForChild("MemoriaEvent")

local SellEvent = Networking
    :WaitForChild("Units")
    :WaitForChild("SellEvent")

--------------------------------------------------
-- SELL MYTHIC NON SHINY
--------------------------------------------------

local function sellNonShinyMythic(items)

    local unitsToSell = {}

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then

            for _, guidFrame in ipairs(cache:GetChildren()) do

                local guid = guidFrame.Name
                local container = guidFrame:FindFirstChild("Container")

                if not container then continue end

                local holder = container:FindFirstChild("Holder")
                local main = holder and holder:FindFirstChild("Main")

                if not main then continue end

                local isMythic = main:FindFirstChild("Mythic")

                local shinyFrame = container:FindFirstChild("ShinyFrame")
                local isShiny = shinyFrame and shinyFrame.Visible

                if isMythic and not isShiny then
                    table.insert(unitsToSell, guid)
                end

            end

        end
    end

    if #unitsToSell > 0 then

        local args = {
            [1] = unitsToSell
        }

        pcall(function()
            SellEvent:FireServer(unpack(args))
        end)

    end

end

--------------------------------------------------
-- SELL MEMORIA
--------------------------------------------------

local function sellMemoria(items)

    local memoriaToSell = {}

    for _, cache in ipairs(items:GetChildren()) do
        if cache.Name == "CacheContainer" then

            for _, guidFrame in ipairs(cache:GetChildren()) do

                local guid = guidFrame.Name

                local container = guidFrame:FindFirstChild("Container")
                if not container then continue end

                local holder = container:FindFirstChild("Holder")
                local main = holder and holder:FindFirstChild("Main")

                if not main then continue end

                if main:FindFirstChild("Rare")
                or main:FindFirstChild("Epic")
                or main:FindFirstChild("Legendary")
                or main:FindFirstChild("Mythic") then

                    table.insert(memoriaToSell, guid)

                end

            end

        end
    end

    if #memoriaToSell > 0 then
        pcall(function()
            MemoriaEvent:FireServer("Sell", memoriaToSell)
        end)
    end

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

task.spawn(function()

    while true do

        local success, items = pcall(function()
            return playerGui.Windows
                .GlobalInventory.Holder
                .LeftContainer.FakeScrollingFrame
                .Items
        end)

        if success and items then

            sellMemoria(items)

            sellNonShinyMythic(items)

        end

        task.wait(2)

    end

end)
