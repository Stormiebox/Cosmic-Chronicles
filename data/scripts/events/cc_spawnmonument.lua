package.path = package.path .. ";data/scripts/lib/?.lua"
local PlanGenerator = include("plangenerator")

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
    desc.position = Matrix() -- Spawn it perfectly in the center (0,0,0)
    desc.title = "Cultural Monument"%_t

    local station = sector:createEntity(desc)
    station:addScriptOnce("entity/cc_factionmonument.lua")

    -- Ensure it cannot be destroyed by stray pirate attacks
    local durability = Durability(station.index)
    if durability then
        durability.invincibility = 1.0
    end

    terminate()
end