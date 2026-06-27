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
        
        -- Create a hyperspace animation visual effect
        sector:createHyperspaceAnimation(entity, entity.translationf, ColorRGB(0.1, 0.5, 1.0), 1.5)
        
        -- Delete the entity
        sector:deleteEntity(entity)
    elseif timeRemaining <= 60 and not warned then
        warned = true
        Sector():broadcastChatMessage(Entity().title or "Rogue AI", 0, "Warning: Local data assimilation at 75%. Preparing for warp jump in 60 seconds.")
    end
end
