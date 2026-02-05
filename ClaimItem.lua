repeat task.wait() until game:IsLoaded()
task.wait(2)

--================ CONFIG (REQUIRED) =================--
local Config = getgenv().Config
if not Config then
    warn("❌ ไม่มี Config — ไม่รัน ClaimItem")
    return
end
if Config.ClaimItem ~= true then
    warn("❌ ClaimItem ไม่ได้เปิดจาก Config — ข้ามการรับของ")
    return
end
--===================================================--

--================ PLACE CHECK =================--
local TARGET_PLACE = 16146832113
if game.PlaceId ~= TARGET_PLACE then
    warn("❌ PlaceId ไม่ตรง — ไม่รับของให้")
    return
end
--=============================================--

--================ SERVICES =================--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage:WaitForChild("Networking")
local CodesEvent = Networking:WaitForChild("CodesEvent", 5)          -- สำหรับรีดีมโค้ด
local DailyRewardEvent = Networking:WaitForChild("DailyRewardEvent")
local MilestonesEvent = Networking:WaitForChild("Milestones"):WaitForChild("MilestonesEvent")
local QuestEvent = Networking:WaitForChild("Quests"):WaitForChild("ClaimQuest")
local BattlepassEvent = Networking:WaitForChild("BattlepassEvent")
local ReturningPlayerEvent = Networking:WaitForChild("ReturningPlayerEvent")
local NewPlayerRewardsEvent = Networking:WaitForChild("NewPlayerRewardsEvent")
local APiratesWelcomeEvent = Networking:WaitForChild("APiratesWelcomeEvent", 5)  -- เพิ่มสำหรับ A Pirates Welcome
--============================================--

local DELAY = 0.1

local function safeFire(remote, args)
    local ok, err = pcall(function()
        remote:FireServer(unpack(args))
    end)
    if not ok then
        warn("❌ FireServer ล้มเหลว:", err)
    end
    task.wait(DELAY)
end

--================ REDEEM CODES ===================
task.spawn(function()
    if not CodesEvent then
        warn("⚠️ ไม่เจอ CodesEvent — ข้ามการรีดีมโค้ด")
        return
    end

    local codes = {
        "ALMOST100K",
        "ItsCold",
        "Memoria",
        "Winter26"
    }

    print("เริ่มรีดีมโค้ด...")

    for _, code in ipairs(codes) do
        pcall(function()
            CodesEvent:FireServer(code)
            warn("รีดีมโค้ด: " .. code .. " → ส่งเรียบร้อย")
        end)
        task.wait(1.2)
    end

    print("รีดีมโค้ดทั้งหมดเสร็จสิ้น!")
end)

--================ DAILY REWARD (NORMAL) ===================
for _, reward in ipairs({
    {"Special", 2},
    {"Special", 4},
    {"Special", 7},
    {"Winter", 7},
}) do
    safeFire(DailyRewardEvent, {"Claim", reward})
end

--================ DAILY REWARD (ANNIVERSARY) ===================
for day = 1, 7 do
    safeFire(DailyRewardEvent, {"Claim", {"Anniversary", day}})
end

--================ MILESTONES ===================
for _, milestone in ipairs({5, 10}) do
    safeFire(MilestonesEvent, {"Claim", milestone})
end

--================ QUESTS ===================
safeFire(QuestEvent, {"ClaimAll"})

--================ BATTLEPASS ===================
safeFire(BattlepassEvent, {"ClaimAll"})

--================ RETURNING PLAYER ===================
for day = 1, 7 do
    safeFire(ReturningPlayerEvent, {"Claim", day})
end

--================ NEW PLAYER REWARDS ===================
for day = 1, 7 do
    safeFire(NewPlayerRewardsEvent, {"Claim", day})
end

--================ A PIRATES WELCOME (รับตั้งแต่ 1-7) ===================
if APiratesWelcomeEvent then
    for day = 1, 7 do
        safeFire(APiratesWelcomeEvent, {"Claim", day})
    end
else
    warn("⚠️ ไม่เจอ APiratesWelcomeEvent — ข้ามการรับรางวัลนี้")
end

print("✅ ClaimItem: รับของทั้งหมดเสร็จเรียบร้อย")
