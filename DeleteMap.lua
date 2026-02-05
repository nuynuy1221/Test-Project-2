repeat task.wait() until game:IsLoaded()
task.wait(1)

--== เช็ค PlaceId ก่อนรัน ==--
local targetPlace = 16277809958
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง สคริปต์จะไม่ทำงาน")
    return
end

local Map = workspace:WaitForChild("Map")
local HEIGHT_LIMIT = -100

-- เช็คความสูง
local function isAboveHeight(obj)
    if obj:IsA("BasePart") then
        return obj.Position.Y > HEIGHT_LIMIT
    end

    if obj:IsA("Model") then
        local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if part then
            return part.Position.Y > HEIGHT_LIMIT
        end
    end

    return false
end

-- ลบรอบแรก
for _, obj in ipairs(Map:GetDescendants()) do
    if isAboveHeight(obj) then
        pcall(function()
            obj:Destroy()
        end)
    end
end

-- กันของเกิดใหม่
Map.DescendantAdded:Connect(function(obj)
    task.wait()
    if isAboveHeight(obj) then
        pcall(function()
            obj:Destroy()
        end)
    end
end)

print("✅ ลบทุกอย่างใน workspace.Map ที่สูงกว่า Y = -100 แล้ว")
