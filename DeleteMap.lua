repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16277809958
if game.PlaceId ~= targetPlace then
    warn("PlaceId ไม่ตรง ไม่ลบแมพให้")
    return
end

local map = workspace:WaitForChild("Map")

local assets = map:FindFirstChild("Assets")
if assets then
	for _, obj in ipairs(assets:GetChildren()) do
		obj:Destroy()
	end
end

local skellingtons = map:FindFirstChild("Skellingtons")
if skellingtons then
	skellingtons:Destroy()
end
