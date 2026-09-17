package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")
local EventContract = include("cc_event_contract")
-- Needed for %_T below; no vanilla file at this path to inherit it from.
include("stringutility")

local AncientCache = {}

-- Both ancient_data_cache and eclipse_lore_anomaly materialize through this script; eventType
-- picks which flavor text/title plays out. Built inside a function, not as a file-scope table,
-- so the %_T lookups only ever run with the UI localization metatable available.
local function flavorFor(eventType)
    if eventType == "eclipse_lore_anomaly" then
        return {
            valid = true,
            title = "Corrupted Archive Signal"%_T,
            scanner = "Scanner"%_T,
            message = "Verified Eclipse activity has exposed a corrupted archive signal. Approach with caution."%_T,
        }
    end
    return {
        valid = false,
        title = "Ancient Data Cache"%_T,
        scanner = "Scanner"%_T,
        message = "Extremely old quantum signatures detected nearby. Could it be Xsotan origins?"%_T,
    }
end

function AncientCache.initialize(eventId, seed, eventType)
    if onServer() then AncientCache.spawn(eventId, seed, eventType) end
end

function AncientCache.spawn(eventId, seed, eventType)
    if type(eventId) ~= "string" then return end
    local flavor = flavorFor(eventType)
    local taggedType = flavor.valid and eventType or "ancient_data_cache"
    EventContract.Begin(eventId, taggedType, 1)
    local x, y = Sector():getCoordinates()

    local planPath = "data/plans/chronicles/ancient_data_cache.xml"
    local plan = LoadPlanFromFile(planPath)
    if not plan then plan = PlanGenerator.makeStationPlan(Galaxy():getPirateFaction(0)) end

    local cache = Sector():createWreckage(plan, SectorGenerator(x,y):getPositionInSector())

    if not valid(cache) then EventContract.Fail(eventId, "cache_creation_failed") return end

    if type(eventId) == "string" then
        EventContract.Tag(cache, eventId, taggedType)
    end
    cache.title = flavor.title
    cache:addScriptOnce("data/scripts/entity/cc_blackbox.lua")

    EventContract.Complete(eventId, 1)

    Sector():broadcastChatMessage(flavor.scanner, 0, flavor.message)
end

function initialize(...)
    if AncientCache.initialize then 
        AncientCache.initialize(...) 
    end
    terminate()
end
