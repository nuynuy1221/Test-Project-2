repeat task.wait() until game:IsLoaded()
task.wait(1.5)

-- =========================
-- เช็ค PlaceId (บังคับ)
-- =========================
local TARGET_PLACE = 16277809958
if game.PlaceId ~= TARGET_PLACE then
    warn("❌ ผิดแมพ! ต้องอยู่ในแมพฟาร์มเท่านั้น")
    return
end

-- =========================
-- Services
-- =========================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Networking = RS:WaitForChild("Networking", 10)
local TeleportEvent = Networking:WaitForChild("TeleportEvent", 8)

if not TeleportEvent then
    warn("❌ ไม่เจอ TeleportEvent")
    return
end

-- =========================
-- CONFIG
-- =========================
local TARGET_PRESENTS = 100000   -- ✅ จำนวน Presents ที่ต้องการ
local CHECK_DELAY = 2            -- วินาทีต่อการเช็ค
local EXIT_DELAY = 4             -- หน่วงก่อนออก Lobby

-- =========================
-- Loop เช็ค Presents
-- =========================
local alreadyExit = false

task.spawn(function()
    while true do
        task.wait(CHECK_DELAY)

        local presents = player:GetAttribute("Presents26") or 0

        print("🎁 Presents26:", presents, "/", TARGET_PRESENTS)

        if presents >= TARGET_PRESENTS and not alreadyExit then
            alreadyExit = true
            warn("✅ Presents26 ครบ (" .. presents .. ") → ออก Lobby ใน " .. EXIT_DELAY .. " วินาที")

            task.delay(EXIT_DELAY, function()
                pcall(function()
                    TeleportEvent:FireServer("Lobby")
                end)
            end)

            break
        end
    end
end)

print("✅ Present Checker Loaded")
