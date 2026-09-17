package.path = package.path .. ";data/scripts/lib/?.lua"
local PlanGenerator = include("plangenerator")
local EventContract = include("cc_event_contract")
include("stringutility")

function initialize(eventId, seed)
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end

    local sector = Sector()
    if type(eventId) ~= "string" then return end
    EventContract.Begin(eventId, "cultural_monument", 1)
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then EventContract.Fail(eventId, "faction_unavailable") return end

    -- Generate a massive procedural station based on the faction's architectural style
    local planPath = "data/plans/chronicles/cosmic_monument.xml"
    local plan = LoadPlanFromFile(planPath)
    if not plan then plan = PlanGenerator.makeStationPlan(faction) end
    plan:scale(vec3(1.5, 1.5, 1.5)) -- Scaled down from 2.5 to prevent C++ physics thread hangs, still looks massive!
    -- TODO: Continue keeping an eye on this monument if it needs to be scaled down further.
    local desc = StationDescriptor()
    desc.factionIndex = faction.index
    desc:setMovePlan(plan)

    -- Spawn it close enough to ping on radar, but far enough to prevent hyperspace collisions
    local offset = vec3(random():getInt(-1000, 1000), random():getInt(-1000, 1000), random():getInt(-1000, 1000))
    desc.position = MatrixLookUpPosition(vec3(0,1,0), vec3(1,0,0), offset)
    desc.title = "Cultural Monument"%_T

    local station = sector:createEntity(desc)
    if not valid(station) then EventContract.Fail(eventId, "monument_creation_failed") return end
    if type(eventId) == "string" then
        EventContract.Tag(station, eventId, "cultural_monument")
    end
    station:addScriptOnce("entity/cc_factionmonument.lua")

    -- Use the vanilla API property to ensure it cannot be destroyed by stray pirate attacks
    station.invincible = true

    EventContract.Complete(eventId, 1)

    -- Alert the player that something interesting is in the sector
    Sector():broadcastChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Sensors are detecting a massive, ancient architectural structure in this sector."%_T)

end
