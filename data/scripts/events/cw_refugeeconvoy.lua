package.path = package.path .. ";data/scripts/lib/?.lua"
local ShipGenerator = include("shipgenerator")

function initialize()
    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then terminate() return end

    -- Spawn 2-3 fleeing refugee ships
    local count = random():getInt(2, 3)
    for i = 1, count do
        local ship = ShipGenerator.createFreighter(faction, MatrixLookUpPosition(-vec3(1,0,0), vec3(0,1,0), vec3(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))))
        ship.title = "Refugee Transport"%_t
        ship:addScriptOnce("entity/cc_refugeedialogue.lua")
    end

    Sector():broadcastChatMessage("Refugee Convoy"%_t, ChatMessageType.Chatter, "Mayday! Our hyperdrives are offline and we are fleeing the frontline! Is anyone out there?"%_t)
    terminate()
end