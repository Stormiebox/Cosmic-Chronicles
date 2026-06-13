package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")

local AncientCache = {}

function AncientCache.initialize()
    if onServer() then AncientCache.spawn() end
end

function AncientCache.spawn()
    local x, y = Sector():getCoordinates()
    
    local cache = Sector():createWreckage(PlanGenerator.makeStationPlan(Galaxy():getPirateFaction(0)), SectorGenerator(x,y):getPositionInSector())
    cache.title = "Ancient Data Cache"
    cache:addScript("data/scripts/entity/story/ancientcachedialog.lua")
    
    Sector():broadcastChatMessage("Scanner", 0, "Extremely old quantum signatures detected nearby. Could it be Xsotan origins?")
end

return AncientCache
