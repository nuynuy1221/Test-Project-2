-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ลอย
local function freezeChar()
	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	hrp.Anchored = true
	hum.PlatformStand = true
	hum.AutoRotate = false
	hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function unfreezeChar()
	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	hrp.Anchored = false
	hum.PlatformStand = false
	hum:ChangeState(Enum.HumanoidStateType.Running)
end

-- PATHS
local waveLabel = player.PlayerGui:WaitForChild("HUD")
	:WaitForChild("Map")
	:WaitForChild("WavesAmount")

local UnitEvent = ReplicatedStorage:WaitForChild("Networking"):WaitForChild("UnitEvent")

-- STATE
local Executed = {}
local inGame = false

-- ======================
-- moveToPrompt
-- ======================
local function moveToPrompt(prompt)
	if not prompt or not prompt.Parent then return end

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	-- หา Part ของ Prompt
	local part = prompt.Parent:IsA("BasePart")
		and prompt.Parent
		or prompt.Parent:FindFirstChildWhichIsA("BasePart")

	if not part then return end

	-- ปลด Anchor / Physics ชั่วคราว (สำคัญ)
	hrp.Anchored = false
	hum.PlatformStand = false
	hum.AutoRotate = false
	hum:ChangeState(Enum.HumanoidStateType.Running)

	-- เป้าหมาย (ยืนหน้าปุ่ม)
	local targetCF = part.CFrame * CFrame.new(0, 0, -2)

	local distance = (hrp.Position - targetCF.Position).Magnitude
	local time = math.clamp(distance / 14, 0.5, 1)

	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(
			time,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{ CFrame = targetCF }
	)

	tween:Play()
	tween.Completed:Wait()

	task.wait(0.05)
end

-- ======================
-- UTIL
-- ======================
local function getWave()
	local text = waveLabel.ContentText
	local wave = tonumber(text:match("%d+"))
	return wave
end

local function firePrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return end

	-- ปลดก่อน Tween
	unfreezeChar()

	moveToPrompt(prompt)

	if fireproximityprompt then
		fireproximityprompt(prompt, 1)
	else
		warn("fireproximityprompt not supported")
	end

	task.wait(0.05)

	-- แช่กลับทันที
	freezeChar()
end

-- ======================
-- Shrine
-- ======================
local function buyFromShrine(shrineName, index)
	local map = workspace:FindFirstChild("Map")
	if not map then return end

	local interactions = map:FindFirstChild("Interactions")
	if not interactions then return end

	local shrine = interactions:FindFirstChild(shrineName)
	if not shrine then return end

	local node = shrine:FindFirstChild(tostring(index))
	if not node then return end

	local prompt = node:FindFirstChild("ProximityPrompt")
	firePrompt(prompt)
end

-- ======================
-- BUY UNITS (SAFE)
-- ======================

local function buyGuts()
	buyFromShrine("UnitShrine_RabbitHero", 1)
end

local function buyWagon()
	buyFromShrine("UnitShrine_Sprintwagon", 1)
end

local function buyTakaroda()
	buyFromShrine("UnitShrine_Takaroda", 1)
end

-- ======================
-- PLACE UNIT
-- ======================
local function placeUnit(name, id, position, slot)
	slot = slot or 1

	local args = {
		[1] = "Render",
		[2] = {
			[1] = name,
			[2] = id,
			[3] = position,
			[4] = 0
		},
		[3] = {
			["SlotIndex"] = slot
		}
	}

	UnitEvent:FireServer(unpack(args))
end

-- ======================
-- PLACE UNIT AND WAIT (SAFE)
-- ======================
local function placeUnitAndWait(name, id, position, slot)
	slot = slot or 1

	-- วางยูนิต
	placeUnit(name, id, position, slot)

	-- รอให้ยูนิตโผล่ใน Unit Manager จริง ๆ
	local ok = waitForUnitInInventory(name, slot, 8)

	if not ok then
		warn("❌ วางไม่สำเร็จ:", name, "slot", slot)
	else
		print("✅ วางสำเร็จ:", name, "slot", slot)
	end
end

-- ======================
-- PLACE UNIT รัวๆ
-- ======================
local function placeUnitBurst(name, id, positions, startSlot)
	startSlot = startSlot or 1

	for i, pos in ipairs(positions) do
		local slot = startSlot + i - 1
		placeUnit(name, id, pos, slot)

		-- หน่วงให้ server รับชัวร์
		task.wait(0.5)
	end
end

-- ======================
-- UNIT MANAGER
-- ======================
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local function ensureUnitManagerOpen()
	local gui = player.PlayerGui

	-- ถ้าเปิดอยู่แล้ว ไม่ต้องกด
	if gui:FindFirstChild("UnitManager") then
		return true
	end

	local button =
		gui:FindFirstChild("Guides")
		and gui.Guides:FindFirstChild("List")
		and gui.Guides.List:FindFirstChild("StageInfo")
		and gui.Guides.List.StageInfo:FindFirstChild("Buttons")
		and gui.Guides.List.StageInfo.Buttons:FindFirstChild("UnitManager")
		and gui.Guides.List.StageInfo.Buttons.UnitManager:FindFirstChild("Button")

	if not button or not button:IsA("GuiButton") then
		warn("❌ ไม่เจอปุ่ม Unit Manager")
		return false
	end

	button.Selectable = true
	GuiService.SelectedCoreObject = button
	task.wait(0.05)

	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
	task.wait(0.03)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

	task.wait(0.15)
	GuiService.SelectedCoreObject = nil

	-- รอ UnitManager โผล่
	for _ = 1, 10 do
		if gui:FindFirstChild("UnitManager") then
			return true
		end
		task.wait(0.1)
	end

	warn("❌ กดแล้ว แต่ UnitManager ไม่ขึ้น")
	return false
end

-- ======================
-- WAIT UNIT IN INVENTORY
-- ======================
local function waitForUnitInInventory(unitName, count, timeout)
	timeout = timeout or 8
	local start = tick()

	while tick() - start < timeout do
		if ensureUnitManagerOpen() then
			local manager = player.PlayerGui:FindFirstChild("UnitManager")
			if manager and manager:FindFirstChild("Holder") then
				local list = manager.Holder:FindFirstChild("List")
				if list then
					local found = 0

					for _, frame in ipairs(list:GetChildren()) do
						local unitFrame = frame:FindFirstChild("Unit")
						if unitFrame then
							-- 🔴 ชื่อยูนิตอยู่ใน TextLabel
							local nameLabel =
								unitFrame:FindFirstChild("Name")
								or unitFrame:FindFirstChild("NameLabel")
								or unitFrame:FindFirstChildWhichIsA("TextLabel")

							if nameLabel and nameLabel.ContentText then
								if string.find(nameLabel.ContentText, unitName, 1, true) then
									found += 1
								end
							end
						end
					end

					-- DEBUG (แนะนำมาก)
					print("📦 Inventory:", unitName, found .. "/" .. count)

					if found >= count then
						return true
					end
				end
			end
		end
		task.wait(0.25)
	end

	warn("⏱️ รอ Unit ไม่ครบ:", unitName, count)
	return false
end

-- ======================
-- UPGRADE UNIT BY NAME
-- ======================
local function upgradeUnit(unitName, targetLevel)
	if not ensureUnitManagerOpen() then
		return
	end

	local list = player.PlayerGui.UnitManager.Holder.List

	for _, frame in ipairs(list:GetChildren()) do
		local unit = frame:FindFirstChild("Unit")
		if not unit then continue end

		-- เช็คว่ายูนิตนี้เป็นชื่อที่ต้องการ
		if not unit:FindFirstChild(unitName) then
			continue
		end

		local upgradeLabel = unit:FindFirstChild("UpgradeLabel")
		if not upgradeLabel then
			continue
		end

		-- ถ้าเป็น Max แล้ว ข้ามทันที
		if string.find(upgradeLabel.ContentText, "Max") then
			continue
		end

		local uuid = frame.Name

		task.spawn(function()
			while true do
				local text = upgradeLabel.ContentText

				-- ถ้ากลายเป็น Max ระหว่างทาง ให้หยุด
				if string.find(text, "Max") then
					break
				end

				local current = tonumber(text:match("%[(%d+)/"))
				if not current then
					break
				end

				if current >= targetLevel then
					break
				end

				UnitEvent:FireServer("Upgrade", uuid)
				task.wait(0.8)
			end
		end)
	end
end

-- ======================
-- LANES
-- ======================
local function buyLane(num)
	firePrompt(workspace.Map.Interactions["PurchaseLane"..num].Part.ProximityPrompt)
end

-- ======================
-- LOOP CHECK WAVE
-- ======================
task.spawn(function()
	while task.wait(0.5) do
		local wave = getWave()
		if wave == nil then continue end

		-- =========================
		-- RESET STATE (WAVE 0)
		-- =========================
		if wave == 0 then
			if inGame then
				warn("🔄 Wave 0 → รีรอบเกม รีเซ็ตทุกอย่าง")
				Executed = {}
				inGame = false
			end
			continue -- ❌ ห้ามทำอะไรตอน Wave 0
		end

		-- =========================
		-- GAME START (WAVE >= 1)
		-- =========================
		if not inGame and wave >= 1 then
			inGame = true
			warn("▶ เกมเริ่มแล้ว (Wave "..wave..") เริ่ม Auto")
		end

		-- =========================
		-- WAVE 1
		-- =========================
		if wave >= 1 and not Executed[1] then
			Executed[1] = true
			buyGuts()
			buyGuts()

			-- ตัวที่ 1
			placeUnit(
				"Rabbit Hero (Guts)",
				"364:Evolved",
				Vector3.new(20.8433,252.5818,95.2065),
				1
			)

			-- ⏱ รอ 5 วินาทีเต็ม
			task.wait(2)

			-- ตัวที่ 2
			placeUnit(
				"Rabbit Hero (Guts)",
				"364:Evolved",
				Vector3.new(20.6082,252.5819,99.6623),
				2
			)
            task.wait(3)

			-- ตัวที่ 2 ซ้ำ
			placeUnit(
				"Rabbit Hero (Guts)",
				"364:Evolved",
				Vector3.new(20.6082,252.5819,99.6623),
				2
			)
            task.wait(5)

			-- ตัวที่ 2 ซ้ำ
			placeUnit(
				"Rabbit Hero (Guts)",
				"364:Evolved",
				Vector3.new(20.6082,252.5819,99.6623),
				2
			)
		end

        -- =========================
		-- WAVE 2
		-- =========================
		if wave >= 2 and not Executed[2] then
			Executed[2] = true
			buyGuts()

            placeUnit(
				"Rabbit Hero (Guts)",
				"364:Evolved",
				Vector3.new(18.577674865722656, 252.5818634033203, 97.36162567138672),
				3
			)
        end

		-- =========================
		-- WAVE 3
		-- =========================
		if wave >= 3 and not Executed[3] then
			Executed[3] = true
			buyWagon()
			buyWagon()
			buyWagon()

            task.wait(2)

            placeUnit(
				"Sprintwagon",
				"35",
				Vector3.new(4.9603,251.6905,115.8387),
				4
			)
            task.wait(0.5)
            placeUnit(
				"Sprintwagon",
				"35",
				Vector3.new(2.4375,251.6905,115.3120),
				5
			)
            task.wait(0.5)
            placeUnit(
				"Sprintwagon",
				"35",
				Vector3.new(-0.7760,251.5234,115.2861),
				6
			)
		end
        
        -- =========================
		-- WAVE 4
		-- =========================
		-- อัพ Wagon ตลอดจนถึงเลเวล 4
		if wave >= 4 then
			upgradeUnit("Sprintwagon", 4)
		end

		-- =========================
		-- WAVE 6
		-- =========================
		if wave >= 6 and not Executed[6] then
			Executed[6] = true
			buyLane(2)
            task.wait(1)
			buyLane(3)
		end

		-- =========================
		-- WAVE 7
		-- =========================
		if wave >= 7 and not Executed[7] then
			Executed[7] = true
			buyTakaroda()

            placeUnitBurst(
	            "Takaroda",
	            "47",
	            {
            		Vector3.new(-13.5438,251.5234,91.1173)
            	},
            	7
            )

		end

		-- =========================
		-- WAVE 8
		-- =========================
		if wave >= 8 then
			upgradeUnit("Takaroda", 6)
		end

		-- =========================
		-- WAVE 9
		-- =========================
		if wave >= 9 and not Executed[9] then
			Executed[9] = true
            buyFromShrine("UnitShrine_TempestPirate", 1)

            placeUnitBurst(
	            "Tempest Pirate (Navigator)",
	            "343:Evolved",
	            {
            		Vector3.new(-13.8315,251.5234,104.7525)
            	},
	            8,
	            2
            )


		end

		if wave >= 9 then
			upgradeUnit("Tempest Pirate (Navigator)", 6)
		end

		-- =========================
		-- WAVE 10
		-- =========================
		if wave >= 10 then
			upgradeUnit("Rabbit Hero (Guts)", 9)
		end

		-- =========================
		-- WAVE 29
		-- =========================
		if wave >= 29 and not Executed[29] then
			Executed[29] = true
			for i = 4,7 do
                task.wait(1)
				buyLane(i)
			end
		end
	end
end)
