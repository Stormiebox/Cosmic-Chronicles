package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PlanGenerator = include("plangenerator")
local EventContract = include("cc_event_contract")
-- Needed for the %_T broadcast below; nothing else this file includes reaches it.
include("stringutility")

function initialize(eventId, seed)
    -- One-shot generation script: detach immediately so an idle instance doesn't stay
    -- attached on any early-return path below (client included).
    terminate()

    if onClient() then return end
    spawn(eventId, seed)
end

function spawn(eventId, seed)
    if type(eventId) ~= "string" then return end
    local sector = Sector()
    local x, y = sector:getCoordinates()
    
    local numStashes = random():getInt(3, 6)
    EventContract.Begin(eventId, "hidden_stash", numStashes)
    local generator = SectorGenerator(x, y)
    local spawned = {}
    
    for i = 1, numStashes do
        local plan = PlanGenerator.makeContainerPlan()
        
        -- Use the SectorGenerator to get a valid position away from center
        local position = generator:getPositionInSector()
        
        local container = sector:createWreckage(plan, position)
        if valid(container) and type(eventId) == "string" then
            EventContract.Tag(container, eventId, "hidden_stash")
            spawned[#spawned + 1] = container
        end
        if valid(container) then
        container.title = "Hidden Stash"%_T
        
        container:addScript("data/scripts/entity/stash.lua")
        
        if random():test(0.25) then
            container:addScript("data/scripts/entity/cc_blackbox.lua")
        end
        end
    end

    if #spawned ~= numStashes then
        EventContract.Fail(eventId, "partial_hidden_stash_spawn")
        return
    end
    EventContract.Complete(eventId, #spawned)

    Sector():broadcastChatMessage("Scanner"%_T, 0, "Massive anomalous resource signatures detected. This must be the stash the refugees mentioned!"%_T)
end
