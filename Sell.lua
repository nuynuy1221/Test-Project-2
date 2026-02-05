repeat task.wait() until game:IsLoaded()
task.wait(2)

local targetPlace = 16146832113
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่ขาย Memoria ให้")
    return
end

local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MemoriaEvent = ReplicatedStorage:WaitForChild("Networking"):WaitForChild("Memorias"):WaitForChild("MemoriaEvent")

print("สคริปต์ทำงานครบแล้ว — เริ่มขาย Memoria Rare/Epic อัตโนมัติ")

task.spawn(function()
    while true do
        local success, items = pcall(function()
            local windows = player.PlayerGui:WaitForChild("Windows", 10)
            local globalInv = windows:WaitForChild("GlobalInventory", 10)
            local holder = globalInv.Holder
            local leftContainer = holder.LeftContainer
            local fakeScroll = leftContainer.FakeScrollingFrame
            local itemsFolder = fakeScroll.Items
            return itemsFolder
        end)
       
        if not success or not items then
            task.wait(3)
            continue
        end
       
        local cacheContainers = {}
        for _, child in ipairs(items:GetChildren()) do
            if child.Name == "CacheContainer" then
                table.insert(cacheContainers, child)
            end
        end
       
        local memoriaToSell = {}
       
        for _, cache in ipairs(cacheContainers) do
            for _, guidFrame in ipairs(cache:GetChildren()) do
                local guid = guidFrame.Name
               
                local container = guidFrame:FindFirstChild("Container")
                if not container then continue end
               
                local holderObj = container:FindFirstChild("Holder")
                local main = holderObj and holderObj:FindFirstChild("Main")
                if not main then continue end
               
                local memoriaNameObj = main:FindFirstChild("MemoriaName")
                if not memoriaNameObj then continue end
               
                local rarityObj = main:FindFirstChild("Rare") or main:FindFirstChild("Epic") or main:FindFirstChild("Legendary")
               
                if rarityObj and (rarityObj.Name == "Rare" or rarityObj.Name == "Epic" or rarityObj.Name == "Legendary") then
                    table.insert(memoriaToSell, guid)
                end
            end
        end
       
        if #memoriaToSell > 0 then
            local ok = pcall(function()
                MemoriaEvent:FireServer("Sell", memoriaToSell)
            end)
            if ok then
                print("ขาย Memoria Rare/Epic สำเร็จ จำนวน " .. #memoriaToSell .. " ชิ้น")
            end
        end
       
        task.wait(2.5)
    end
end)
