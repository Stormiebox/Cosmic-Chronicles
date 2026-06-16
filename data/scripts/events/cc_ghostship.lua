package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")

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
    ghost.title = "Drifting Ghost Ship"
    ghost:addScript("data/scripts/entity/story/ghostshipdialog.lua")

    -- Strip AI to make it dead
    ghost:removeScript("data/scripts/entity/ai/patrol.lua")

    Sector():broadcastChatMessage("Scanner", 0, "Anomaly detected. Faint, repeating distress signal from a drifting vessel.")
end

function initialize(...)
    if GhostShipEvent.initialize then return GhostShipEvent.initialize(...) end
end


return GhostShipEvent
