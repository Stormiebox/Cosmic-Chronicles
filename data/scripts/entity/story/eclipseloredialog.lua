package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

include("callable")

function initialize()
    if onServer() then
        Entity().title = "Ancient Eclipse Monolith"
    end
end

function interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    if craft:getDistance(Entity()) > 50 then return false end
    return true
end

function initUI()
    ScriptUI():registerInteraction("Access Database", "onInteract")
end

function onInteract()
    ScriptUI():showDialog(Dialog())
end

function Dialog()
    local logs = {}
    logs.text = "LOG ENTRY 401: We have been observing the sub-space phenomenon we refer to as 'The Eclipse'. It acts as a massive sink for ambient energy and emits chaotic gravitational waves.\n\nLOG ENTRY 412: The energy signatures are stabilizing. We believe the Eclipse is not a natural occurrence, but an artificial bridge. Something is trying to cross over.\n\nLOG ENTRY 413: Evacuation initiated. God help us all."
    logs.answers = { {answer = "Download archived schematics and disconnect.", onSelect = "triggerLoot"} }

    local d0 = {}
    d0.text = "The ancient terminal sparks to life, projecting a holographic interface. An ancient, fragmented database waits to be accessed."
    d0.answers = { {answer = "Decrypt Logs", followUp = logs} }

    return d0
end

function triggerLoot()
    if onClient() then
        invokeServerFunction("triggerLootServer")
        return
    end
end

function triggerLootServer()
    local entity = Entity()
    local player = Player(callingPlayer)

    -- Invoke the loot drop function on the sibling script
    entity:invokeFunction("data/scripts/entity/story/eclipseloot.lua", "dropLoot", callingPlayer)

    -- Send a message to the player
    player:sendChatMessage("Ship Computer", 0, "Downloaded encrypted schematics and valuables from the cache.")

    -- Destroy the stash entity
    Sector():createExplosion(entity.translationf, 1, false)
    Sector():deleteEntity(entity)
end

callable(nil, "triggerLootServer")

