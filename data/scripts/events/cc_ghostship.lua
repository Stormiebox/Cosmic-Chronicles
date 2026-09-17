package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
local EventContract = include("cc_event_contract")
include("galaxy")
-- Needed for %_T/%_t below; no vanilla file at this path to inherit it from.
include("stringutility")

local GhostShipEvent = {}

function GhostShipEvent.initialize(eventId, seed)
    if onServer() then
        GhostShipEvent.spawn(eventId, seed)
    end
end

function GhostShipEvent.spawn(eventId, seed)
    if type(eventId) ~= "string" then return end
    EventContract.Begin(eventId, "ghost_ship", 1)
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))

    local ghost = ShipGenerator.createFreighterShip(faction, SectorGenerator(x,y):getPositionInSector())
    if not valid(ghost) then EventContract.Fail(eventId, "ghost_ship_creation_failed") return end
    if type(eventId) == "string" then
        EventContract.Tag(ghost, eventId, "ghost_ship")
    end
    ghost.title = "Drifting Ghost Ship"%_T
    ghost:addScriptOnce("data/scripts/entity/cc_ghostship.lua")

    -- Strip AI and weapons to make it completely dead
    ghost:removeScript("data/scripts/entity/ai/patrol.lua")
    ghost:removeScript("data/scripts/entity/ai/freighter.lua")
    -- createFreighterShip always attaches civilship.lua, which registers its own competing
    -- interactions regardless of crew count and can worsen relations via its threaten() path.
    ghost:removeScript("data/scripts/entity/civilship.lua")
    
    local ai = ShipAI(ghost.index)
    if ai then
        ai:stop()
        ai:setPassive()
    end

    -- Remove any auto-firing turrets so it doesn't shoot the player
    local turrets = {ghost:getTurrets()}
    for _, turret in pairs(turrets) do
        Sector():deleteEntity(turret)
    end

    ghost.crew = Crew()

    EventContract.Complete(eventId, 1)

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Anomaly detected. Faint, repeating distress signal from a drifting vessel."%_T)
end

function initialize(...)
    if GhostShipEvent.initialize then GhostShipEvent.initialize(...) end
    terminate()
end
