package.path = package.path .. ";data/scripts/lib/?.lua"
local PlanGenerator = include("plangenerator")
include("stringutility")

function initialize()
    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then terminate() return end

    -- Generate a massive procedural station based on the faction's architectural style
    local plan = PlanGenerator.makeStationPlan(faction)
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
    station:addScriptOnce("entity/cc_factionmonument.lua")

    -- Use the vanilla API property to ensure it cannot be destroyed by stray pirate attacks
    station.invincible = true

    -- Alert the player that something interesting is in the sector
    Sector():broadcastChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Sensors are detecting a massive, ancient architectural structure in this sector."%_T)

    terminate()
end