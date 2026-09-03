package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")
include("galaxy")
-- Needed for %_T/%_t below; no vanilla file at this path to inherit it from.
include("stringutility")

local GhostShipEvent = {}

function GhostShipEvent.initialize()
    if onServer() then
        GhostShipEvent.spawn()
    end
end

function GhostShipEvent.spawn()
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))

    local ghost = ShipGenerator.createFreighterShip(faction, SectorGenerator(x,y):getPositionInSector())
    ghost.title = "Drifting Ghost Ship"%_T
    ghost:addScriptOnce("data/scripts/entity/story/ghostshipdialog.lua")

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

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Anomaly detected. Faint, repeating distress signal from a drifting vessel."%_T)
end

function initialize(...)
    if GhostShipEvent.initialize then GhostShipEvent.initialize(...) end
    terminate()
end
