package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")

local RogueAIProbe = {}

function RogueAIProbe.initialize()
    if onServer() then RogueAIProbe.spawn() end
end

function RogueAIProbe.spawn()
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getPirateFaction(0)

    local probe = ShipGenerator.createMilitaryShip(faction, SectorGenerator(x,y):getPositionInSector())
    probe.title = "Rogue AI Probe"
    probe:addScript("data/scripts/entity/ai/patrol.lua")

    -- Fast and evasive, scaling on distance to core
    local d = math.sqrt(x*x + y*y)
    local scale = math.max(1, (500 - d) / 100)

    probe.damageMultiplier = scale * 5.0
    probe.shieldMultiplier = scale * 2.0

    -- If it isn't killed in 3 minutes, it warps away
    probe:addScript("data/scripts/entity/story/warpawaytimer.lua", 180)

    Sector():broadcastChatMessage("Scanner", 2, "WARNING: Highly evasive, unidentified Rogue AI signature detected.")
end

function initialize(...)
    if RogueAIProbe.initialize then return RogueAIProbe.initialize(...) end
end
