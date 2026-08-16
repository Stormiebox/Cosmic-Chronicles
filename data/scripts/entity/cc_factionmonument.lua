package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("stringutility")
include("relations")

-- namespace CosmicChroniclesMonument
CosmicChroniclesMonument = {}

function CosmicChroniclesMonument.interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    if craft:getNearestDistance(Entity()) > 500 then return false end
    return true
end

function CosmicChroniclesMonument.initUI()
    ScriptUI():registerInteraction("Read Inscription"%_t, "onInteract")
end

function CosmicChroniclesMonument.onInteract()
    invokeServerFunction("readLore")
end

function CosmicChroniclesMonument.readLore()
    if not onServer() then return end

    local player = Player(callingPlayer)
    local entity = Entity()
    local ship = player.craft
    if not ship or ship:getNearestDistance(entity) > 500 then
        invokeClientFunction(player, "tooFar")
        return
    end

    local faction = Faction(entity.factionIndex)
    if not faction then return end

    local fName = faction.name

    -- Procedurally generate the monument's text based on the AI's internal traits
    local trait1 = "diplomacy and unity"%_T
    if faction:getTrait("aggressive") > 0.5 then
        trait1 = "unyielding strength and conquest"%_T
    end

    local trait2 = "scavenging the ashes of the old world"%_T
    if faction:getTrait("wealthy") > 0.5 then
        trait2 = "endless prosperity"%_T
    end

    -- Award a small reputation boost for paying respects (once per player)
    local readKey = "cc_monument_read_" .. player.index
    if not Entity():getValue(readKey) then
        Entity():setValue(readKey, true)
        local repTarget = player
        if ship then repTarget = Faction(ship.factionIndex) or player end
        changeRelations(repTarget, faction, 2500, RelationChangeType.General)
        player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "You paid your respects to the faction's history. Reputation improved."%_T)
    end

    invokeClientFunction(player, "showLoreDialog", fName, trait1, trait2)
end
callable(CosmicChroniclesMonument, "readLore")

function CosmicChroniclesMonument.showLoreDialog(fName, trait1, trait2)
    if not onClient() then return end

    local text = "=== CULTURAL MONUMENT OF THE ${faction} ===\n\nWe survived the Great Darkness through ${trait1}.\nOur future among the stars is paved with ${trait2}.\n\nLet all who pass through this system know that we stand eternal against the Xsotan threat."%_t % {faction = fName:upper(), trait1 = trait1, trait2 = trait2}

    local dialog = {text = text, answers = {{answer = "Fascinating."%_t}}}
    ScriptUI():showDialog(dialog)
end

function CosmicChroniclesMonument.tooFar()
    local dialog = {}
    dialog.text = "You're too far away. Come closer so you can read the inscription."%_t
    ScriptUI():interactShowDialog(dialog, true)
end

function interactionPossible(...)
    if CosmicChroniclesMonument.interactionPossible then return CosmicChroniclesMonument.interactionPossible(...) end
end
function initUI(...)
    if CosmicChroniclesMonument.initUI then return CosmicChroniclesMonument.initUI(...) end
end
function onInteract(...)
    if CosmicChroniclesMonument.onInteract then return CosmicChroniclesMonument.onInteract(...) end
end

return CosmicChroniclesMonument
