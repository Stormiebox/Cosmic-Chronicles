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
    probe:addScriptOnce("data/scripts/entity/ai/patrol.lua")

    -- Fast and evasive, scaling on distance to core
    local d = math.sqrt(x*x + y*y)
    local scale = math.max(1, (500 - d) / 100)

    probe:addMultiplyableBias(StatsBonuses.FireRate, scale * 5.0 - 1.0)

    -- If it isn't killed in 3 minutes, it warps away
    probe:addScriptOnce("entity/utility/delayeddelete.lua", 180)

    Sector():broadcastChatMessage("Scanner", 2, "WARNING: Highly evasive, unidentified Rogue AI signature detected.")
end

function initialize(...)
    if RogueAIProbe.initialize then return RogueAIProbe.initialize(...) end
end
