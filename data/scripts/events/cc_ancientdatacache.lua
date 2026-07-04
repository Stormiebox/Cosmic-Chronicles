package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")

local AncientCache = {}

function AncientCache.initialize()
    if onServer() then AncientCache.spawn() end
end

function AncientCache.spawn()
    local x, y = Sector():getCoordinates()

    local planPath = "data/plans/chronicles/ancient_data_cache.xml"
    local plan = LoadPlanFromFile(planPath)
    if not plan then plan = PlanGenerator.makeStationPlan(Galaxy():getPirateFaction(0)) end

    local cache = Sector():createWreckage(plan, SectorGenerator(x,y):getPositionInSector())
    cache.title = "Ancient Data Cache"
    cache:addScriptOnce("data/scripts/entity/story/ancientcachedialog.lua")

    Sector():broadcastChatMessage("Scanner", 0, "Extremely old quantum signatures detected nearby. Could it be Xsotan origins?")
end

function initialize(...)
    if AncientCache.initialize then return AncientCache.initialize(...) end
end
