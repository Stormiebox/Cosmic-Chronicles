package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")
local EventContract = include("cc_event_contract")
-- Needed for %_T below; no vanilla file at this path to inherit it from.
include("stringutility")

local AncientCache = {}

function AncientCache.initialize(eventId, seed)
    if onServer() then AncientCache.spawn(eventId, seed) end
end

function AncientCache.spawn(eventId, seed)
    if type(eventId) ~= "string" then return end
    EventContract.Begin(eventId, "ancient_data_cache", 1)
    local x, y = Sector():getCoordinates()

    local planPath = "data/plans/chronicles/ancient_data_cache.xml"
    local plan = LoadPlanFromFile(planPath)
    if not plan then plan = PlanGenerator.makeStationPlan(Galaxy():getPirateFaction(0)) end

    local cache = Sector():createWreckage(plan, SectorGenerator(x,y):getPositionInSector())
    
    if not valid(cache) then EventContract.Fail(eventId, "cache_creation_failed") return end

    if type(eventId) == "string" then
        EventContract.Tag(cache, eventId, "ancient_data_cache")
    end
    cache.title = "Ancient Data Cache"%_T
    cache:addScriptOnce("data/scripts/entity/cc_blackbox.lua")

    EventContract.Complete(eventId, 1)

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Extremely old quantum signatures detected nearby. Could it be Xsotan origins?"%_T)
end

function initialize(...)
    if AncientCache.initialize then 
        AncientCache.initialize(...) 
    end
    terminate()
end
