package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
local EventContract = include("cc_event_contract")
-- Needed for %_T below; no vanilla file at this path to inherit it from.
include("stringutility")

local RogueAIProbe = {}

function RogueAIProbe.initialize(eventId, seed)
    if onServer() then RogueAIProbe.spawn(eventId, seed) end
end

function RogueAIProbe.spawn(eventId, seed)
    if type(eventId) ~= "string" then return end
    EventContract.Begin(eventId, "rogue_ai_probe", 1)
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getPirateFaction(0)

    local probe = ShipGenerator.createMilitaryShip(faction, SectorGenerator(x,y):getPositionInSector())
    if not valid(probe) then EventContract.Fail(eventId, "probe_creation_failed") return end
    if type(eventId) == "string" then
        EventContract.Tag(probe, eventId, "rogue_ai_probe")
    end
    probe.title = "Rogue AI Probe"%_T
    probe:addScriptOnce("data/scripts/entity/ai/patrol.lua")

    -- Fast and evasive, scaling on distance to core
    local d = math.sqrt(x*x + y*y)
    local scale = math.max(1, (500 - d) / 100)

    probe:addBaseMultiplier(StatsBonuses.FireRate, scale - 1.0)

    -- The Chronicle tracker owns the timeout so escape and destruction remain distinct.
    probe:addScriptOnce("entity/cc_probe_tracker.lua", eventId, 180)

    EventContract.Complete(eventId, 1)

    Sector():broadcastChatMessage("Scanner"%_T, 2, "WARNING: Highly evasive, unidentified Rogue AI signature detected."%_T)
end

function initialize(...)
    if RogueAIProbe.initialize then RogueAIProbe.initialize(...) end
    terminate()
end
