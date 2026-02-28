repeat task.wait() until game:IsLoaded()
task.wait(5)

local skip = {
    [1] = "PartOne",
    [2] = "Skip"
}
game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("NEWTutorialEvent"):FireServer(unpack(skip))

task.wait(1)
local skip = {
    [1] = "PartTwo",
    [2] = "Skip"
}
game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("NEWTutorialEvent"):FireServer(unpack(skip))
