task.spawn(function()

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local SettingsEvent = ReplicatedStorage
		:WaitForChild("Networking")
		:WaitForChild("Settings")
		:WaitForChild("SettingsEvent")

	--=========================
	-- CHECK COLOR (SETTING)
	--=========================
	local function isOff(uiGradient)

		if not uiGradient or not uiGradient:IsA("UIGradient") then
			return false
		end

		local keypoints = uiGradient.Color.Keypoints
		if #keypoints == 0 then
			return false
		end

		local r,g,b = 0,0,0

		for _,kp in ipairs(keypoints) do
			r += kp.Value.R
			g += kp.Value.G
			b += kp.Value.B
		end

		r /= #keypoints
		g /= #keypoints
		b /= #keypoints

		if g < r or g < b then
			return true
		end

		return false
	end

	--=========================
	-- SETTINGS
	--=========================
	local settingsList = {
		{ Name = "AutoSkipWaves", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Gameplay.AutoSkipWaves.Slider.UIStroke.UIGradient },
		{ Name = "DisableCameraShake", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableCameraShake.Slider.UIStroke.UIGradient },
		{ Name = "DisableDepthOfField", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableDepthOfField.Slider.UIStroke.UIGradient },
		{ Name = "HideFamiliars", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.HideFamiliars.Slider.UIStroke.UIGradient },
		{ Name = "LowDetailMode", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.LowDetailMode.Slider.UIStroke.UIGradient },
		{ Name = "DisableGlobalMessages", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.DisableGlobalMessages.Slider.UIStroke.UIGradient },
		{ Name = "SkipSummonAnimation", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.SkipSummonAnimation.Slider.UIStroke.UIGradient },
		{ Name = "DisableDamageIndicators", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableDamageIndicators.Slider.UIStroke.UIGradient },
		{ Name = "DisableVisualEffects", Path = playerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableVisualEffects.Slider.UIStroke.UIGradient },
	}

	for _,setting in ipairs(settingsList) do

		if isOff(setting.Path) then
			print("🔥 TOGGLE:",setting.Name)
			SettingsEvent:FireServer("Toggle",setting.Name)
			task.wait(0.08)
		end

	end


	--=========================
	-- AUT OSELL (REMOTE)
	--=========================

	task.wait(1)

	local rarities = playerGui.Windows.Summon.Holder.Box.AutoSell.Rarities

	local list = {
		{UI = rarities.Rare, Name = "Rare"},
		{UI = rarities.Epic, Name = "Epic"},
		{UI = rarities.Legendary, Name = "Legendary"},
		{UI = rarities.Mythic, Name = "Mythic"}
	}

	for _,data in ipairs(list) do

		local gradient = data.UI.UIStroke.EnabledGradient

		print("CHECK AUT OSELL:",data.Name)

		if gradient.Enabled then
			print("✅ ALREADY ON:",data.Name)

		else
			print("🔥 ENABLE:",data.Name)

			SettingsEvent:FireServer("Toggle",data.Name)

			task.wait(0.15)
		end

	end

end)
