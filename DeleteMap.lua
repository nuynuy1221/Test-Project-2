repeat task.wait() until game:IsLoaded()
task.wait(1)

local targetPlace = 16277809958
if game.PlaceId ~= targetPlace then
	local lobby = workspace:FindFirstChild("MainLobby")
    if not lobby then
        warn("[MainLobby] not found")
        return
    end

    for _, obj in ipairs(lobby:GetChildren()) do
        pcall(function()
            obj:Destroy()
        end)
    end

    print("[MainLobby] Cleared all")
        return
    end

local map2 = workspace:WaitForChild("Map")

local assets = map2:FindFirstChild("Assets")
if assets then
	for _, obj in ipairs(assets:GetChildren()) do
		obj:Destroy()
	end
end

local skellingtons = map2:FindFirstChild("Skellingtons")
if skellingtons then
	skellingtons:Destroy()
end
