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
	hum.PlatformStand = false
	hum.AutoRotate = false
	hum:ChangeState(Enum.HumanoidStateType.None)
end

local function unfreezeChar()
	local char = player.Character
	if not char then return end

	local hum = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	hrp.Anchored = false
	hum.PlatformStand = false
    hum.AutoRotate = true
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
local MonachApplied = {} -- [uuid] = true
local Upgrading = {} -- [uuid] = true
local BarricadeLoopRunning = false
local BarricadeLoopThread = nil

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
	hum.AutoRotate = true
	hum:ChangeState(Enum.HumanoidStateType.Running)

	-- เป้าหมาย (ยืนหน้าปุ่ม)
	local targetCF = part.CFrame * CFrame.new(0, 0, -2)

	local distance = (hrp.Position - targetCF.Position).Magnitude
	local time = math.clamp(distance / 14, 0.05, 1)

	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(
			time,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{ CFrame = targetCF }
	)
    tween.Name = "MoveTween"

    if hrp:FindFirstChild("MoveTween") then
	    hrp.MoveTween:Cancel()
    end

	tween:Play()

	local finished = false
	tween.Completed:Once(function()
		finished = true
	end)

	local start = tick()
	while not finished and tick() - start < 2 do
		task.wait()
	end

	task.wait(0.05)
end

-- ======================
-- UTIL
-- ======================
local function getWave()
	if not waveLabel or not waveLabel.ContentText then
		return nil
	end
	local text = waveLabel.ContentText

	local wave = tonumber(text:match("(%d+)%s*/") or text:match("%d+"))
	return wave
end

local PromptBusy = false
local function firePrompt(prompt)
	if PromptBusy then return end
	PromptBusy = true

	if not prompt or not prompt:IsA("ProximityPrompt") then
		PromptBusy = false
		return
	end

	unfreezeChar()
	moveToPrompt(prompt)

	if fireproximityprompt then
		fireproximityprompt(prompt, 1)
	end

	task.wait(0.05)
	freezeChar()

	PromptBusy = false
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
-- UNIT MANAGER
-- ======================
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local unitManagerOpened = false

local function ensureUnitManagerOpen()
	local gui = player.PlayerGui

	-- ถ้าเปิดอยู่แล้ว ไม่ต้องกด
	if unitManagerOpened and gui:FindFirstChild("UnitManager") then
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
			unitManagerOpened = true
			return true
		end

		task.wait(0.5)
	end

	warn("❌ กดแล้ว แต่ UnitManager ไม่ขึ้น")
	return false
end

-- ======================
-- WAIT UNIT IN INVENTORY
-- ======================
local function hasUnitInInventory(unitName)
	local gui = player.PlayerGui
	local manager = gui:FindFirstChild("UnitManager")
	if not manager then return false end

	local list = manager:FindFirstChild("Holder")
		and manager.Holder:FindFirstChild("List")

	if not list then return false end

	for _, frame in ipairs(list:GetChildren()) do
		local unit = frame:FindFirstChild("Unit")
		if unit then
			local nameLabel =
				unit:FindFirstChild("Name")
				or unit:FindFirstChild("NameLabel")
				or unit:FindFirstChildWhichIsA("TextLabel")

			if nameLabel and nameLabel.ContentText then
				if string.find(nameLabel.ContentText, unitName, 1, true) then
					return true
				end
			end
		end
	end

	return false
end

-- ======================
-- PLACE UNIT AND WAIT (SAFE)
-- ======================
local function placeUnitAndWait(name, id, position, slot)
	slot = slot or 1

	placeUnit(name, id, position, slot)

	task.wait(0.8)

	if not hasUnitInInventory(name) then
		warn("❌ วางไม่สำเร็จ:", name)
	else
		print("✅ วางสำเร็จ:", name)
	end
end

-- ======================
-- PLACE UNIT รัวๆ
-- ======================
local function placeUnitBurst(name, id, positions, startSlot, step)
	startSlot = startSlot or 1
	step = step or 1

	for i, pos in ipairs(positions) do
		local slot = startSlot + (i - 1) * step
		placeUnit(name, id, pos, slot)
		task.wait(0.5)
	end
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
		if not frame:IsA("Frame") then continue end

		local unitRoot = frame:FindFirstChild("Unit")
		if not unitRoot then continue end

		-- 🔹 ดึง Sprintwagon / ตัวละคร (Frame)
		local unitFrame = unitRoot:FindFirstChild(unitName)
		if not unitFrame then continue end

		-- 🔹 ดึงชื่อจาก UnitName (TextLabel)
		local unitNameLabel =
			unitFrame:FindFirstChild("Container")
			and unitFrame.Container:FindFirstChild("Holder")
			and unitFrame.Container.Holder:FindFirstChild("Main")
			and unitFrame.Container.Holder.Main:FindFirstChild("UnitName")

		if not unitNameLabel or not unitNameLabel.ContentText then
			warn("❌ เจอ Unit แต่ไม่เจอ UnitName:", frame.Name)
			continue
		end

		-- 🔹 เช็คชื่อ (กันพลาด)
		if not string.find(unitNameLabel.ContentText, unitName, 1, true) then
			continue
		end

		-- 🔹 UpgradeLabel
		local upgradeLabel = unitRoot:FindFirstChild("UpgradeLabel")
		if not upgradeLabel or not upgradeLabel.ContentText then
			warn("❌ ไม่มี UpgradeLabel:", frame.Name)
			continue
		end

		-- 🔹 ถ้า Max แล้วข้าม
		if string.find(upgradeLabel.ContentText, "Max") then
			continue
		end

		local uuid = frame.Name

		if Upgrading[uuid] then
			continue
		end
		Upgrading[uuid] = true

		print("⬆️ เริ่มอัพ:", unitNameLabel.ContentText, "uuid:", uuid)

		task.spawn(function()
			while true do
				local text = upgradeLabel.ContentText
				if not text then break end

				if string.find(text, "Max") then break end

				local current = tonumber(text:match("%[(%d+)/"))
				if not current then break end
				if current >= targetLevel then break end

				UnitEvent:FireServer("Upgrade", uuid)
				task.wait(0.8)
			end

			Upgrading[uuid] = nil
			print("✅ อัพเสร็จ:", unitNameLabel.ContentText, "uuid:", uuid)
		end)
	end
end

-- ======================
-- UUID FINDER
-- ======================
local function findUnitUUID(unitName)
	if not ensureUnitManagerOpen() then return nil end

	for _, frame in ipairs(player.PlayerGui.UnitManager.Holder.List:GetChildren()) do
		local unitRoot = frame:FindFirstChild("Unit")
		if unitRoot and unitRoot:FindFirstChild(unitName) then
			return frame.Name
		end
	end
	return nil
end

-- ======================
-- LANES
-- ======================
local function buyLane(num)
	firePrompt(workspace.Map.Interactions["PurchaseLane"..num].Part.ProximityPrompt)
end

-- ======================
-- BOX
-- ======================
local function buyBox()
	firePrompt(workspace.Map.Interactions.MysteryBox1.CrateBottom.default.ProximityPrompt)
end

-- ======================
-- BARRICADE
-- ======================
local function buyBarricade(num)
	firePrompt(workspace.Map.Interactions["Barricade"..num].default.ProximityPrompt)
end

-- ======================
-- BARRICADE LOPE
-- ======================
local function startBarricadeLoop()
	if BarricadeLoopRunning then return end
	BarricadeLoopRunning = true

	BarricadeLoopThread = task.spawn(function()
		while BarricadeLoopRunning do
			for i = 1, 3 do
				buyBarricade(i)
				task.wait(0.3)
			end

			-- ⏱ รอ 20 วินาที
			for i = 1, 20 do
				if not BarricadeLoopRunning then
					return
				end
				task.wait(1)
			end
		end
	end)

	print("🧱 เริ่ม Auto ซื้อ Barricade ทุก 20 วินาที")
end

-- ======================
-- BARRICADE LOPE STOPER
-- ======================
local function stopBarricadeLoop()
	if not BarricadeLoopRunning then return end

	BarricadeLoopRunning = false
	BarricadeLoopThread = nil

	print("🛑 หยุด Auto ซื้อ Barricade (Wave 0)")
end

-- ======================
-- BUY MONACH
-- ======================
local function buyMonach()
	firePrompt(workspace.Map.Interactions.PackATrait1["Cube.005"].ProximityPrompt)
end

-- ======================
-- APPLY MONACH
-- ======================

local function applyMonachToUnit(unitName, limit)
	limit = limit or math.huge

	if not ensureUnitManagerOpen() then
		warn("❌ UnitManager ไม่เปิด")
		return
	end

	local list = player.PlayerGui.UnitManager.Holder.List
	local applied = 0

	for _, frame in ipairs(list:GetChildren()) do
		if applied >= limit then break end
		if not frame:IsA("Frame") then continue end

		local uuid = frame.Name
		if MonachApplied[uuid] then
			continue -- ✅ uuid นี้เคยใส่แล้ว
		end

		local unitRoot = frame:FindFirstChild("Unit")
		if not unitRoot then continue end

		-- 🔹 หา Frame ของ unit ตามชื่อ (สำคัญมาก)
		local unitFrame = unitRoot:FindFirstChild(unitName)
		if not unitFrame then
			continue
		end

		-- 🔹 ปุ่ม Monach จริง
		local button =
			unitFrame:FindFirstChild("Container")
			and unitFrame.Container:FindFirstChild("Button")

		if not button or not button:IsA("GuiButton") then
			warn("❌ ไม่เจอปุ่ม Monach:", unitName, uuid)
			continue
		end

		-- =========================
		-- 🔘 กดปุ่มแบบเดียวกับที่คุณส่งมา
		-- =========================
		button.Selectable = true
		GuiService.SelectedCoreObject = button
		task.wait(0.05)

		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
		task.wait(0.02)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

		task.wait(0.05)
		GuiService.SelectedCoreObject = nil

		-- =========================
		-- ✅ บันทึก uuid ว่าใส่แล้ว
		-- =========================
		MonachApplied[uuid] = true
		applied += 1

		print("👑 ใส่ Monach สำเร็จ:", unitName, "uuid:", uuid)
		task.wait(0.2)
	end

	if applied == 0 then
		warn("⚠️ ไม่มี unit ที่ยังไม่ได้ใส่ Monach:", unitName)
	else
		print("✅ ใส่ Monach เพิ่มทั้งหมด:", applied, "ตัว")
	end
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
                MonachApplied = {}
				inGame = false
                unitManagerOpened = false
			end
            stopBarricadeLoop()
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
		if wave >= 4 and not Executed[4] then
            Executed[4] = true
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
		if wave >= 8 and not Executed[8] then
			Executed[8] = true
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
            		Vector3.new(20.609821319580078, 251.86569213867188, 104.9205322265625)
            	},
	            8,
                2
            )
		end

		if wave >= 9 and not Executed["TP6"] then
            Executed["TP6"] = true
            task.wait(0.5)
			upgradeUnit("Tempest Pirate (Navigator)", 6)
		end

		-- =========================
		-- WAVE 10
		-- =========================
		if wave >= 10 and not Executed[10] then
			Executed[10] = true
			upgradeUnit("Rabbit Hero (Guts)", 8)
		end
        
        -- =========================
		-- WAVE 15
		-- =========================
		if wave >= 15 and not Executed[15] then
			Executed[15] = true
            buyFromShrine("UnitShrine_TempestPirate", 1)

            placeUnitBurst(
	            "Tempest Pirate (Navigator)",
	            "343:Evolved",
	            {
            		Vector3.new(20.609821319580078, 251.86569213867188, 104.9205322265625)
            	},
	            8,
                2
            )
		end

		if wave >= 15 and not Executed["TP6-2"] then
            Executed["TP6-2"] = true
            task.wait(0.5)
			upgradeUnit("Tempest Pirate (Navigator)", 6)
		end

        -- =========================
		-- WAVE 19
		-- =========================
		if wave >= 19 and not Executed[19] then
			Executed[19] = true
			local args = {
                [1] = "Purchase",
                [2] = {
                    ["ModifierId"] = "FortuneCity"
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent"):FireServer(unpack(args))
		end

        -- =========================
		-- WAVE 20
		-- =========================
		if wave >= 20 and not Executed[20] then
			Executed[20] = true
			local args = {
                [1] = "Purchase",
                [2] = {
                    ["ModifierId"] = "EagleEyed"
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent"):FireServer(unpack(args))
		end

        -- =========================
		-- WAVE 21
		-- =========================
		if wave >= 21 and not Executed[21] then
			Executed[21] = true
			local args = {
                [1] = "Purchase",
                [2] = {
                    ["ModifierId"] = "HeavyHitter"
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent"):FireServer(unpack(args))
		end

        -- =========================
		-- WAVE 22
		-- =========================
		if wave >= 22 and not Executed[22] then
			Executed[22] = true
			local args = {
                [1] = "Purchase",
                [2] = {
                    ["ModifierId"] = "FastHands"
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent"):FireServer(unpack(args))
		end

                -- =========================
		-- WAVE 25
		-- =========================
		if wave >= 25 and not Executed[25] then
			Executed[25] = true
			local args = {
                [1] = "Purchase",
                [2] = {
                    ["ModifierId"] = "ArmorBeGone"
                }
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("WinterZombies"):WaitForChild("ModifierMachineEvent"):FireServer(unpack(args))
		end

        -- =========================
		-- WAVE 30
		-- =========================
		if wave >= 30 and not Executed[30] then
			Executed[30] = true
			for i = 1, 200 do
				buyBox()
				task.wait(0.1)
			end
        end

        -- =========================
		-- WAVE 36
		-- =========================
		if wave >= 36 and not Executed[36] then
			Executed[36] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            9,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            9,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
            	},
	            9,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
            		Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            9,
	            2
            )
        end

        -- =========================
		-- WAVE 37
		-- =========================
		if wave >= 37 and not Executed[37] then
			Executed[37] = true
			upgradeUnit("Koguro (Unsealed)", 5)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 5)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 5)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 5)
            task.wait(1)
		end

        -- =========================
		-- WAVE 38
		-- =========================
		if wave >= 38 and not Executed[38] then
			Executed[38] = true
			for i = 1, 150 do
				buyBox()
				task.wait(0.1)
			end
        end

        -- =========================
		-- WAVE 40
		-- =========================
		if wave >= 40 and not Executed[40] then
			Executed[40] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            10,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            10,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
            	},
	            10,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
            		Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            10,
	            2
            )
	    end

        -- =========================
		-- WAVE 43
		-- =========================
		if wave >= 43 and not Executed[43] then
			Executed[43] = true
			for i = 1, 150 do
				buyBox()
				task.wait(0.1)
			end
        end

        -- =========================
		-- WAVE 44
		-- =========================
		if wave >= 44 and not Executed[44] then
			Executed[44] = true
			upgradeUnit("Koguro (Unsealed)", 8)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 8)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 8)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 8)
            task.wait(1)
		end
        -- =========================
		-- WAVE 45
		-- =========================
		if wave >= 45 and not Executed[45] then
			Executed[45] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            11,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            11,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
            	},
	            11,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            11,
	            2
            )
	    end

        -- =========================
		-- WAVE 47
		-- =========================
		if wave >= 47 and not Executed[47] then
			Executed[47] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Rabbit Hero (Guts)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 48
		-- =========================
		if wave >= 48 and not Executed[48] then
			Executed[48] = true
			for i = 1, 100 do
				buyBox()
				task.wait(0.1)
			end
        end

        -- =========================
		-- WAVE 49
		-- =========================
		if wave >= 49 and not Executed[49] then
			Executed[49] = true
			upgradeUnit("Koguro (Unsealed)", 10)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 10)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 10)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 10)
            task.wait(1)
		end
        -- =========================
		-- WAVE 50
		-- =========================
		if wave >= 50 and not Executed[50] then
			Executed[50] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            12,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            12,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
            	},
	            12,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            12,
	            2
            )
	    end

        -- =========================
		-- WAVE 58
		-- =========================
		if wave >= 58 and not Executed[58] then
			Executed[58] = true
			local args = {
   			 [1] = {
      			  [1] = 2,
      			  [2] = 3,
      			  [3] = 5,
      			  [4] = 19
   			 }
			}

			game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("Units"):WaitForChild("Update 9.5"):WaitForChild("ConfirmLichSpells"):FireServer(unpack(args))
		end

        -- =========================
		-- WAVE 59
		-- =========================
		if wave >= 59 and not Executed[59] then
			Executed[59] = true
			upgradeUnit("Koguro (Unsealed)", 12)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15)
            task.wait(1)
		end

        -- =========================
		-- WAVE 62
		-- =========================
		if wave >= 62 and not Executed[62] then
			Executed[62] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Rabbit Hero (Guts)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 64
		-- =========================
		if wave >= 64 and not Executed[64] then
			Executed[64] = true
			buyMonach()
			task.wait(1)

			applyMonachToUnit("Lich King (Ruler)", 1)
			task.wait(1)

            buyMonach()
			task.wait(1)

			applyMonachToUnit("Koguro (Unsealed)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Ice Queen (Release)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Iscanur (Pride)", 1)
			task.wait(1)
		end

        -- =========================
		-- WAVE 66
		-- =========================
		if wave >= 66 and not Executed[66] then
			Executed[66] = true

            placeUnit(
	            "Ice Manipulator (Admiral)",
	            "361:Evolved",
            	Vector3.new(14.536787033081055, 252.58160400390625, 91.04071807861328),
	            13
            )
            task.wait(1)
            placeUnit(
	            "Ice Manipulator (Admiral)",
	            "361:Evolved",
            	Vector3.new(12.214313507080078, 252.58157348632812, 90.87340545654297),
	            14
            )
            task.wait(1)
            placeUnit(
	            "Ice Manipulator (Admiral)",
	            "361:Evolved",
            	Vector3.new(14.403878211975098, 252.5816650390625, 92.87925720214844),
	            15
            )
            task.wait(1)
            placeUnit(
	            "Ice Manipulator (Admiral)",
	            "361:Evolved",
            	Vector3.new(11.800287246704102, 253.0923614501953, 93.03865051269531),
	            16
            )
            task.wait(1)
		end

		if wave >= 66 and not Executed["IM8"] then
			Executed["IM8"] = true  
			upgradeUnit("Ice Manipulator (Admiral)", 8)
		end

        -- =========================
		-- WAVE 69
		-- =========================
		if wave >= 69 and not Executed[69] then
			Executed[69] = true

            placeUnit(
	            "Trash Gamer (Twin Blades)",
	            "366:Evolved",
            	Vector3.new(14.304614067077637, 252.5819549560547, 101.68321990966797),
	            17
            )
            task.wait(1)
            placeUnit(
	            "Trash Gamer (Twin Blades)",
	            "366:Evolved",
            	Vector3.new(13.832529067993164, 252.58201599121094, 103.8165512084961),
	            18
            )
            task.wait(1)
            placeUnit(
	            "Trash Gamer (Twin Blades)",
	            "366:Evolved",
            	Vector3.new(12.289790153503418, 252.58192443847656, 101.69861602783203),
	            19
            )
            task.wait(1)
		end

		if wave >= 69 and not Executed["WB9"] then
			Executed["WB9"] = true  
			upgradeUnit("Trash Gamer (Twin Blades)", 9)
		end

        -- =========================
		-- WAVE 72
		-- =========================
		if wave >= 72 and not Executed[72] then
			Executed[72] = true

            placeUnit(
	            "Armored Mage (Requip)",
	            "358:Evolved",
            	Vector3.new(17.010068893432617, 252.58169555664062, 92.87059020996094),
	            20
            )
            task.wait(1)
            placeUnit(
	            "Armored Mage (Requip)",
	            "358:Evolved",
            	Vector3.new(16.550222396850586, 252.5818328857422, 97.07596588134766),
	            21
            )
            task.wait(1)
            placeUnit(
	            "Armored Mage (Requip)",
	            "358:Evolved",
            	Vector3.new(16.582002639770508, 252.58193969726562, 100.5829086303711),
	            22
            )
            task.wait(1)
		end

		if wave >= 72 and not Executed["AM12"] then
			Executed["AM12"] = true  
			upgradeUnit("Armored Mage (Requip)", 12)
		end

        -- =========================
		-- WAVE 73
		-- =========================
		if wave >= 73 and not Executed[73] then
			Executed[73] = true
			for i = 1, 200 do
				buyBox()
				task.wait(0.1)
			end
        end

        -- =========================
		-- WAVE 75
		-- =========================
		if wave >= 75 and not Executed[75] then
			Executed[75] = true

            placeUnit(
	            "Company Captain (Hybrid)",
	            "360",
            	Vector3.new(14.2889986038208, 253.0923614501953, 95.32842254638672),
	            23
            )
            task.wait(1)
            placeUnit(
	            "Company Captain (Hybrid)",
	            "360",
            	Vector3.new(14.159333229064941, 252.58181762695312, 97.53057861328125),
	            24
            )
            task.wait(1)
            placeUnit(
	            "Company Captain (Hybrid)",
	            "360",
            	Vector3.new(13.996800422668457, 252.5818634033203, 99.35167694091797),
	            25
            )
            task.wait(1)
		end

		if wave >= 75 and not Executed["CC11"] then
			Executed["CC11"] = true
			upgradeUnit("Company Captain (Hybrid)", 11)
		end

        -- =========================
		-- WAVE 77
		-- =========================
		if wave >= 77 and not Executed[77] then
			Executed[77] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            29,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            29,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
                },
            	29,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            29,
	            2
            )
	    end

        -- =========================
		-- WAVE 78
		-- =========================
		if wave >= 78 and not Executed[78] then
			Executed[78] = true
			buyMonach()
			task.wait(1)

			applyMonachToUnit("Lich King (Ruler)", 1)
			task.wait(1)

            buyMonach()
			task.wait(1)

			applyMonachToUnit("Koguro (Unsealed)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Ice Queen (Release)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Iscanur (Pride)", 1)
			task.wait(1)
		end

        -- =========================
		-- WAVE 79
		-- =========================
		if wave >= 79 and not Executed[79] then
			Executed[79] = true
			upgradeUnit("Koguro (Unsealed)", 12)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15)
            task.wait(1)
		end

        -- =========================
		-- WAVE 80
		-- =========================
		if wave >= 80 and not Executed[80] then
			Executed[80] = true
            MonachApplied = {}
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Rabbit Hero (Guts)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 82
		-- =========================
		if wave >= 82 and not Executed[82] then
			Executed[82] = true
			for i = 1, 4 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Ice Manipulator (Admiral)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 86
		-- =========================
		if wave >= 86 and not Executed[86] then
			Executed[86] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Trash Gamer (Twin Blades)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 90
		-- =========================
		if wave >= 90 and not Executed[90] then
			Executed[90] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Armored Mage (Requip)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 95
		-- =========================
		if wave >= 95 and not Executed[95] then
			Executed[95] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Company Captain (Hybrid)", 1)
				task.wait(0.3)
			end
		end

        -- =========================
		-- WAVE 100
		-- =========================
		if wave >= 100 and not Executed[100] then
			Executed[100] = true
            MonachApplied = {}
			buyMonach()
			task.wait(1)

			applyMonachToUnit("Lich King (Ruler)", 1)
			task.wait(1)

            buyMonach()
			task.wait(1)

			applyMonachToUnit("Koguro (Unsealed)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Ice Queen (Release)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Iscanur (Pride)", 1)
			task.wait(1)
		end

        -- =========================
		-- WAVE 101
		-- =========================
		if wave >= 101 and not Executed[101] then
			Executed[101] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Company Captain (Hybrid)", 1)
				task.wait(0.3)
			end
            task.wait(1)
            for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Armored Mage (Requip)", 1)
				task.wait(0.3)
			end
            task.wait(1)
            for i = 1, 3 do

				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Trash Gamer (Twin Blades)", 1)
				task.wait(0.3)
			end
            task.wait(1)
            for i = 1, 4 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Ice Manipulator (Admiral)", 1)
				task.wait(0.3)
			end
            task.wait(1)
            for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Rabbit Hero (Guts)", 1)
				task.wait(0.3)
			end
		end
        -- =========================
		-- WAVE 110
		-- =========================
        if wave >= 110 and not Executed["110"] then
			Executed["110"] = true
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-21.148853302001953, 252.0919647216797, 97.92547607421875)
            	},
	            26,
	            2
            )
            task.wait(1)
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-20.91863441467285, 252.0919647216797, 94.68634796142578)
            	},
	            27,
	            2
            )
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15)
            task.wait(1)
        end

        -- =========================
		-- WAVE 111
		-- =========================
		if wave >= 111 and not Executed[111] then
			Executed[111] = true
			for i = 1, 3 do
				buyMonach()
				task.wait(0.4)

				applyMonachToUnit("Ice Queen (Release)", 1)
				task.wait(0.3)
			end
        end

        -- =========================
		-- WAVE 115
		-- =========================
		if wave >= 115 and not Executed[1150] then
			Executed[115] = true


            placeUnitBurst(
	            "Koguro (Unsealed)",
	            "235",
	            {
            		Vector3.new(6.1883745193481445, 253.0923614501953, 100.23284912109375)
            	},
	            28,
	            2
            )
            placeUnitBurst(
	            "Lich King (Ruler)",
	            "338",
	            {
            		Vector3.new(5.769950866699219, 253.0923614501953, 97.12089538574219)
            	},
	            28,
	            2
            )
            placeUnitBurst(
	            "Iscanur (Pride)",
	            "270",
	            {
            		Vector3.new(5.73417329788208, 253.0923614501953, 93.96935272216797)
            	},
	            28,
	            2
            )
            placeUnitBurst(
	            "Ice Queen (Release)",
	            "363",
	            {
                    Vector3.new(-21.437185287475586, 252.0919647216797, 101.15544891357422)
            	},
	            28,
	            2
            )
	    end

        -- =========================
		-- WAVE 116
		-- =========================
		if wave >= 116 and not Executed[116] then
			Executed[116] = true
			upgradeUnit("Koguro (Unsealed)", 12)
            task.wait(1)
            upgradeUnit("Lich King (Ruler)", 13)
            task.wait(1)
            upgradeUnit("Iscanur (Pride)", 15)
            task.wait(1)
            upgradeUnit("Ice Queen (Release)", 15)
            task.wait(1)
		end

        -- =========================
		-- WAVE 117
		-- =========================
		if wave >= 117 and not Executed[117] then
			Executed[117] = true
            MonachApplied = {}
			buyMonach()
			task.wait(1)

			applyMonachToUnit("Lich King (Ruler)", 1)
			task.wait(1)

            buyMonach()
			task.wait(1)

			applyMonachToUnit("Koguro (Unsealed)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Ice Queen (Release)", 1)
			task.wait(1)
            
            buyMonach()
			task.wait(1)

			applyMonachToUnit("Iscanur (Pride)", 1)
			task.wait(1)
		end
        
        -- =========================
		-- WAVE 118
		-- =========================
        if wave >= 118 and not Executed[118] then
	        Executed[118] = true

	        local uuid = findUnitUUID("Koguro (Unsealed)")
	        if uuid then
	        	ReplicatedStorage.Networking.Units["Update 6.5"].Koguro_DomainEvent
	        		:FireServer("ToggleAuto", uuid)
	        end
        end

        -- =========================
		-- WAVE 125
		-- =========================
		if wave >= 125 and not Executed["BARRICADE"] then
			Executed["BARRICADE"] = true
			startBarricadeLoop()
		end

        -- =========================
		-- WAVE 159
		-- =========================
		if wave >= 159 and not Executed[159] then
			Executed[159] = true
            buyLane(4)
			buyLane(5)
            buyLane(6)
            buyLane(7)
            task.wait(10)
            buyLane(4)
			buyLane(5)
            buyLane(6)
            buyLane(7)
	    end
    end
end)
