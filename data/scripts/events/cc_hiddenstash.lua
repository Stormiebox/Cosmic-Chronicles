package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")

local HiddenStash = {}

function HiddenStash.initialize()
    if onServer() then
        HiddenStash.spawn()
    end
end

function HiddenStash.spawn()
    local sector = Sector()
    local x, y = sector:getCoordinates()

    local faction = Galaxy():getPirateFaction(SectorGenerator(x, y):getFactionIndex())
    
    local numStashes = random():getInt(3, 6)
    
    for i = 1, numStashes do
        local plan = PlanGenerator.makeContainerPlan()
        
        -- Use the SectorGenerator to get a valid position away from center
        local position = SectorGenerator(x,y):getPositionInSector()
        
        local container = sector:createWreckage(plan, position)
        container.title = "Hidden Stash"
        
        container:addScript("entity/stash.lua")
        
        if random():test(0.25) then
            container:addScript("data/scripts/entity/story/ancientcachedialog.lua")
        end
    end

    Sector():broadcastChatMessage("Scanner", 0, "Massive anomalous resource signatures detected. This must be the stash the refugees mentioned!")
end

function initialize(...)
    if HiddenStash.initialize then return HiddenStash.initialize(...) end
end
