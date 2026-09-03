package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")

function initialize()
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end
    spawn()
end

function spawn()
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    local numStashes = random():getInt(3, 6)
    local generator = SectorGenerator(x, y)
    
    for i = 1, numStashes do
        local plan = PlanGenerator.makeContainerPlan()
        
        -- Use the SectorGenerator to get a valid position away from center
        local position = generator:getPositionInSector()
        
        local container = sector:createWreckage(plan, position)
        container.title = "Hidden Stash"
        
        container:addScript("data/scripts/entity/stash.lua")
        
        if random():test(0.25) then
            container:addScript("data/scripts/entity/story/ancientcachedialog.lua")
        end
    end

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Massive anomalous resource signatures detected. This must be the stash the refugees mentioned!"%_T)
end
