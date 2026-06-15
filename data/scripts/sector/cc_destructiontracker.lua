package.path = package.path .. ";data/scripts/lib/?.lua"

-- namespace CCDestructionTracker
CCDestructionTracker = {}

function CCDestructionTracker.initialize()
    if onServer() then
        Sector():registerCallback("onDestroyed", "onEntityDestroyed")
    end
end

function CCDestructionTracker.onEntityDestroyed(entityIndex, lastDamageInflictor)
    if not onServer() then return end
    
    local entity = Entity(entityIndex)
    if not entity then return end

    -- We only care about Stations getting destroyed
    if entity.isStation then
        local inflictor = Entity(lastDamageInflictor)
        local inflictorName = "Unknown Forces"
        
        if inflictor and inflictor.factionIndex then
            local faction = Faction(inflictor.factionIndex)
            if faction then
                if faction.isPlayer or faction.isAlliance then
                    inflictorName = "a hostile Independent Pilot"
                elseif faction.isAIFaction and faction.name == "Pirates"%_t then
                    inflictorName = "Pirate Raiders"
                elseif faction.isAIFaction and faction.name == "Xsotan"%_t then
                    inflictorName = "the Xsotan Swarm"
                else
                    inflictorName = "the " .. faction.name
                end
            end
        end

        local x, y = Sector():getCoordinates()
        local article = {
            title = "Tragedy: " .. (entity.translatedTitle or "Station") .. " Destroyed!",
            category = "Breaking News",
            content = string.format("A catastrophic event has occurred in sector %i:%i. The %s was completely obliterated by %s. Rescue operations are underway, but casualties are expected to be massive.", x, y, entity.translatedTitle or "Station", inflictorName)
        }

        Server():sendCallback("onCCNewsPublishArticle", article)
    end
end

function initialize()
    CCDestructionTracker.initialize()
end
