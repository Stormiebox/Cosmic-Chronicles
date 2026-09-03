package.path = package.path .. ";data/scripts/lib/?.lua"
local PlanGenerator = include("plangenerator")
include("stringutility")

function initialize()
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction then return end

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
    station:addScriptOnce("entity/cc_factionmonument.lua")

    -- Use the vanilla API property to ensure it cannot be destroyed by stray pirate attacks
    station.invincible = true

    -- Alert the player that something interesting is in the sector
    Sector():broadcastChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Sensors are detecting a massive, ancient architectural structure in this sector."%_T)

    local article = {
        title = "Ancient Cultural Monument Sighted",
        content = "Sensors have picked up massive architectural signatures emitting strange energy patterns from sector [" .. x .. ":" .. y .. "]. Historians and explorers are rushing to the sector to analyze the ancient " .. faction.name .. " structure.",
        category = "Exploration"
    }
    local cv_news = include("cosmicvaultnews")
    cv_news.publishArticle(article)
end
