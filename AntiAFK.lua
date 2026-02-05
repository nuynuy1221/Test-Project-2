repeat task.wait() until game:IsLoaded()
task.wait(15)

task.spawn(function()
    while true do

        local GuiService = game:GetService("GuiService")
        local VirtualInputManager = game:GetService("VirtualInputManager")
        local button = game:GetService("CoreGui").TopBarApp.TopBarApp.UnibarLeftFrame.UnibarMenu["2"]["3"].chat.IconHitArea_chat
    
        button.Selectable = true
        GuiService.SelectedCoreObject = button
        
        VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Return,false,game)
        VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Return,false,game)
        
        wait(0.1)
        GuiService.SelectedCoreObject = nil
        
        wait(15)
        
        local GuiService = game:GetService("GuiService")
         local VirtualInputManager = game:GetService("VirtualInputManager")
        local button = game:GetService("CoreGui").TopBarApp.TopBarApp.UnibarLeftFrame.UnibarMenu["2"]["3"].chat.IconHitArea_chat
        
        button.Selectable = true
        GuiService.SelectedCoreObject = button
        
        VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Return,false,game)
        VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Return,false,game)
        
        wait(0.1)
        GuiService.SelectedCoreObject = nil
        task.wait(15)
    end
end)
