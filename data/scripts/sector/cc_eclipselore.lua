package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")
local Balancing = include("galaxy")

local EclipseLoreGenerator = {}

function EclipseLoreGenerator.initialize()
    if onClient() then return end
    
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    -- Only spawn in empty sectors or unpopulated sectors
    if sector.numEntities > 100 then return end
    
    -- 5% chance to spawn an Eclipse Lore Object
    if math.random() > 0.05 then return end
    
    local generator = SectorGenerator(x, y)
    local eclipseFaction = Galaxy():getPirateFaction(0)
    
    local loreType = math.random(1, 3)
    local entity = nil
    
    if loreType == 1 then
        entity = sector:createWreckage(PlanGenerator.makeStationPlan(eclipseFaction), generator:getPositionInSector())
        entity.title = "Eclipse Beacon"
    elseif loreType == 2 then
        entity = sector:createWreckage(PlanGenerator.makeShipPlan(eclipseFaction), generator:getPositionInSector())
        entity.title = "Eclipse Shipwreck"
    else
        entity = sector:createWreckage(PlanGenerator.makeFreighterPlan(eclipseFaction), generator:getPositionInSector())
        entity.title = "Eclipse Stash"
    end
    
    -- Add dialog script
    entity:addScript("data/scripts/entity/story/eclipseloredialog.lua")
    
    -- Add scaling loot script based on distance to core
    local d = math.sqrt(x*x + y*y)
    local scalingFactor = math.max(1, (500 - d) / 100)
    
    entity:setValue("cc_eclipse_loot_scale", scalingFactor)
    entity:addScript("data/scripts/entity/story/eclipseloot.lua")
end

return EclipseLoreGenerator
