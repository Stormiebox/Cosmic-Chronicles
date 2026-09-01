package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local ShipGenerator = include("shipgenerator")
local SectorGenerator = include("SectorGenerator")

local DiplomatEscort = {}

function DiplomatEscort.initialize()
    if onServer() then DiplomatEscort.spawn() end
end

function DiplomatEscort.spawn()
    local x, y = Sector():getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)
    
    if not faction or faction.name == "The Xsotan" or faction.name == "The Xsotan"%_t or faction.isPlayer or faction.isAlliance then
        terminate()
        return
    end

    local diplomat = ShipGenerator.createFreighterShip(faction, SectorGenerator(x,y):getPositionInSector())
    diplomat.title = "Stranded Diplomat"
    diplomat:addScriptOnce("data/scripts/entity/story/diplomatdialog.lua")

    -- Strip AI and weapons so the "stranded, escort destroyed" ship is actually stranded,
    -- matching the sibling cc_ghostship.lua convention for a disabled derelict freighter.
    diplomat:removeScript("data/scripts/entity/ai/patrol.lua")
    diplomat:removeScript("data/scripts/entity/ai/freighter.lua")

    local ai = ShipAI(diplomat.index)
    if ai then
        ai:stop()
        ai:setPassive()
    end

    local turrets = {diplomat:getTurrets()}
    for _, turret in pairs(turrets) do
        Sector():deleteEntity(turret)
    end

    diplomat.crew = Crew()

    Sector():broadcastChatMessage("Scanner", 0, "Emergency civilian broadcast detected: 'Our escort is destroyed. We require immediate extraction!'")
end

function initialize(...)
    if DiplomatEscort.initialize then DiplomatEscort.initialize(...) end
    terminate()
end
