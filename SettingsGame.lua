task.spawn(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players.LocalPlayer
	local SettingsEvent = ReplicatedStorage
		:WaitForChild("Networking")
		:WaitForChild("Settings")
		:WaitForChild("SettingsEvent")

	local function isOff(uiGradient)
		if not uiGradient or not uiGradient:IsA("UIGradient") then
			return false
		end

		local keypoints = uiGradient.Color.Keypoints
		if #keypoints == 0 then
			return false
		end

		local r, g, b = 0, 0, 0
		for i, kp in ipairs(keypoints) do
			r += kp.Value.R
			g += kp.Value.G
			b += kp.Value.B
		end

		r /= #keypoints
		g /= #keypoints
		b /= #keypoints

		print(string.format(
			"AVG COLOR -> R: %.3f G: %.3f B: %.3f",
			r, g, b
		))

		-- ON = เขียวเด่น
		-- OFF = แดง/ม่วงเด่น
		if g < r or g < b then
			print("→ OFF DETECTED")
			return true
		end

		print("→ ON")
		return false
	end

	local settingsList = {
		{ Name = "AutoSkipWaves", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Gameplay.AutoSkipWaves.Slider.UIStroke.UIGradient },
		{ Name = "SummonMaxAffordable", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableCameraShake.Slider.UIStroke.UIGradient },
		{ Name = "DisableCameraShake", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableCameraShake.Slider.UIStroke.UIGradient },
		{ Name = "DisableDepthOfField", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.DisableDepthOfField.Slider.UIStroke.UIGradient },
		{ Name = "HideFamiliars", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.HideFamiliars.Slider.UIStroke.UIGradient },
		{ Name = "LowDetailMode", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Graphics.LowDetailMode.Slider.UIStroke.UIGradient },
		{ Name = "DisableGlobalMessages", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.DisableGlobalMessages.Slider.UIStroke.UIGradient },
		{ Name = "SkipSummonAnimation", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Miscellaneous.SkipSummonAnimation.Slider.UIStroke.UIGradient },
		{ Name = "DisableDamageIndicators", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableDamageIndicators.Slider.UIStroke.UIGradient },
		{ Name = "DisableVisualEffects", Path = player.PlayerGui.Windows.Settings.Holder.Main.ScrollingFrame.Units.DisableVisualEffects.Slider.UIStroke.UIGradient },
	}

	for _, setting in ipairs(settingsList) do
		print("\n>>> CHECK:", setting.Name)

		if isOff(setting.Path) then
			print("🔥 TOGGLE:", setting.Name)
			SettingsEvent:FireServer("Toggle", setting.Name)
			task.wait(0.08)
		else
			print("✅ ALREADY ON")
		end
	end
end)
