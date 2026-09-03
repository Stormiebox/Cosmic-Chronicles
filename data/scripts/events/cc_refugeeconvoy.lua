package.path = package.path .. ";data/scripts/lib/?.lua"
local ShipGenerator = include("shipgenerator")
include("stringutility")

function initialize()
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getNearestFaction(x, y)

    if not faction or faction.name == "The Xsotan" or faction.name == "The Xsotan"%_t or faction.isPlayer or faction.isAlliance then
        return
    end

    -- Spawn 2-3 fleeing refugee ships
    local count = random():getInt(2, 3)
    for i = 1, count do
        local ship = ShipGenerator.createFreighterShip(faction, MatrixLookUpPosition(-vec3(1,0,0), vec3(0,1,0), vec3(random():getInt(-500, 500), random():getInt(-500, 500), random():getInt(-500, 500))))
        ship.title = "Refugee Transport"%_T
        -- createFreighterShip always attaches civilship.lua, which registers its own competing
        -- interactions and can worsen relations via its threaten() path.
        ship:removeScript("data/scripts/entity/civilship.lua")
        ship:addScriptOnce("entity/cc_refugeedialogue.lua")
        ship:addScriptOnce("entity/deleteonplayersleft.lua")
    end

    Sector():broadcastChatMessage("Refugee Convoy"%_T, ChatMessageType.Chatter, "Mayday! Our hyperdrives are offline and we are fleeing the frontline! Is anyone out there?"%_T)
    local article = {
        title = "Mass Exodus Intercepted",
        content = "A massive convoy of civilian refugees has broadcasted a distress signal from sector [" .. x .. ":" .. y .. "]. The convoy claims to be fleeing severe hostilities in their home sectors. Relief ships are en route.",
        category = "Humanitarian"
    }
    local cv_news = include("cosmicvaultnews")
    cv_news.publishArticle(article)
end
