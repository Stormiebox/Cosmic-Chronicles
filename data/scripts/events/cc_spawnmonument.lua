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

    local desc = StationDescriptor()
    desc.factionIndex = faction.index
    desc:setMovePlan(plan)

    -- Spawn it slightly off-center to prevent players hyperspacing directly inside it
    local offset = vec3(math.random(-1500, 1500), math.random(-1500, 1500), math.random(-1500, 1500))
    desc.position = MatrixLookUpPosition(vec3(0,1,0), vec3(1,0,0), offset)
    desc.title = "Cultural Monument"%_T

    local station = sector:createEntity(desc)
    station:addScriptOnce("entity/cc_factionmonument.lua")

    -- Use the vanilla API property to ensure it cannot be destroyed by stray pirate attacks
    station.invincible = true

    terminate()
end