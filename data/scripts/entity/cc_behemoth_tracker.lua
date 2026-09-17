-- namespace ChronicleBehemothTracker
ChronicleBehemothTracker = {}
local self = ChronicleBehemothTracker
local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
self.entityId = nil

function ChronicleBehemothTracker.initialize()
    if not onServer() then return end
    self.entityId = tostring(Entity().id)
    Entity():registerCallback("onDestroyed", "onDestroyed")
end

function ChronicleBehemothTracker.onDestroyed(entityId, destroyerId)
    local destroyer = Entity(destroyerId)
    if tostring(entityId) ~= self.entityId or not valid(destroyer) then return end
    local faction = Faction(destroyer.factionIndex)
    if not faction or (not faction.isPlayer and not faction.isAlliance) then return end
    local x, y = Sector():getCoordinates()
    Galaxy():invokeFunction(COORDINATOR, "resolveBehemoth",
        "data/scripts/entity/cc_behemoth_tracker.lua", x, y, self.entityId,
        tostring(destroyerId))
end

function ChronicleBehemothTracker.secure() return {entityId = self.entityId} end
function ChronicleBehemothTracker.restore(data)
    if type(data) == "table" then self.entityId = data.entityId end
end

return ChronicleBehemothTracker
