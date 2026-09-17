package.path = package.path .. ";data/scripts/lib/?.lua"
local ShipGenerator = include("shipgenerator")
local EventContract = include("cc_event_contract")
include("stringutility")

function initialize(eventId, seed)
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end

    local sector = Sector()
    if type(eventId) ~= "string" then return end
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction or faction.name == "The Xsotan" or faction.name == "The Xsotan"%_t or faction.isPlayer or faction.isAlliance then
        EventContract.Begin(eventId, "refugee_convoy", 1)
        EventContract.Fail(eventId, "eligible_faction_unavailable")
        return
    end

    -- Spawn 2-3 fleeing refugee ships
    local count = random():getInt(2, 3)
    EventContract.Begin(eventId, "refugee_convoy", count)
    local spawned = {}
    for i = 1, count do
        local ship = ShipGenerator.createFreighterShip(faction, MatrixLookUpPosition(-vec3(1,0,0), vec3(0,1,0), vec3(random():getInt(-500, 500), random():getInt(-500, 500), random():getInt(-500, 500))))
        if valid(ship) and type(eventId) == "string" then
            EventContract.Tag(ship, eventId, "refugee_convoy")
            spawned[#spawned + 1] = ship
        end
        if valid(ship) then
        ship.title = "Refugee Transport"%_T
        -- createFreighterShip always attaches civilship.lua, which registers its own competing
        -- interactions and can worsen relations via its threaten() path.
        ship:removeScript("data/scripts/entity/civilship.lua")
        ship:addScriptOnce("entity/cc_refugeedialogue.lua")
        ship:addScriptOnce("entity/deleteonplayersleft.lua")
        end
    end

    if #spawned ~= count then EventContract.Fail(eventId, "partial_refugee_spawn") return end
    EventContract.Complete(eventId, #spawned)

    Sector():broadcastChatMessage("Refugee Convoy"%_T, ChatMessageType.Chatter, "Mayday! Our hyperdrives are offline and we are fleeing the frontline! Is anyone out there?"%_T)
end
