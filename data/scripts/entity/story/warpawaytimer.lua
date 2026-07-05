package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local timeRemaining = 180

function initialize(timer)
    if timer then
        timeRemaining = timer
    end
end

function getUpdateInterval()
    return 1.0
end

local warned = false

function updateServer(timeStep)
    timeRemaining = timeRemaining - timeStep
    
    if timeRemaining <= 0 then
        local sector = Sector()
        local entity = Entity()
        
        sector:broadcastChatMessage(entity.title or "Rogue AI", 0, "Data extraction complete. Initiating hyperspace warp. Goodbye, organics.")
        
        -- Jump out cleanly using native jump script
        entity:addScriptOnce("deletejumped.lua")
        terminate()
    elseif timeRemaining <= 60 and not warned then
        warned = true
        Sector():broadcastChatMessage(Entity().title or "Rogue AI", 0, "Warning: Local data assimilation at 75%. Preparing for warp jump in 60 seconds.")
    end
end

function secure()
    return {
        timeRemaining = timeRemaining,
        warned = warned
    }
end

function restore(data)
    timeRemaining = data.timeRemaining or 180
    warned = data.warned or false
end
