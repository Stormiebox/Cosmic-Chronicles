package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")

function initialize()
    -- One-shot generation script: detach immediately so an idle instance
    -- doesn't stay attached to the sector on any early-return path below.
    terminate()

    if onClient() then return end

    local sector = Sector()
    local x, y = sector:getCoordinates()

    if sector:getValue("cc_eclipselore_evaluated") then return end

    -- Only spawn in empty/unpopulated sectors. Mark evaluated only past this check, since a
    -- busy sector always gets saved to disk and would otherwise permanently lose the roll.
    if sector.numEntities > 100 then return end
    sector:setValue("cc_eclipselore_evaluated", true)

    -- 5% chance to spawn an Eclipse Lore Object
    if random():getFloat() > 0.05 then return end

    local generator = SectorGenerator(x, y)
    local eclipseFaction = Galaxy():getPirateFaction(0)

    local loreType = random():getInt(1, 3)
    local entity = nil

    local planPath = "data/plans/chronicles/eclipse_anomaly.xml"
    local eclipsePlan = LoadPlanFromFile(planPath)

    if loreType == 1 then
        local plan = eclipsePlan or PlanGenerator.makeStationPlan(eclipseFaction)
        entity = sector:createWreckage(plan, generator:getPositionInSector())
    elseif loreType == 2 then
        local plan = eclipsePlan or PlanGenerator.makeShipPlan(eclipseFaction)
        entity = sector:createWreckage(plan, generator:getPositionInSector())
    else
        local plan = eclipsePlan or PlanGenerator.makeFreighterPlan(eclipseFaction)
        entity = sector:createWreckage(plan, generator:getPositionInSector())
    end

    if not valid(entity) then return end

    if loreType == 1 then
        entity.title = "Ancient Eclipse Beacon"
    elseif loreType == 2 then
        entity.title = "Ancient Eclipse Shipwreck"
    else
        entity.title = "Ancient Eclipse Stash"
    end

    -- Add dialog script
    entity:addScriptOnce("data/scripts/entity/story/eclipseloredialog.lua")

    -- Add scaling loot script based on distance to core
    local d = math.sqrt(x*x + y*y)
    local scalingFactor = math.max(1, (500 - d) / 100)

    entity:setValue("cc_eclipse_loot_scale", scalingFactor)
    entity:addScriptOnce("data/scripts/entity/story/eclipseloot.lua")
end
