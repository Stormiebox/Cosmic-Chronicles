package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")

-- namespace CosmicChroniclesMonument
CosmicChroniclesMonument = {}

function CosmicChroniclesMonument.interactionPossible(playerIndex, option)
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
    local faction = Faction(Entity().factionIndex)
    if not faction then return end

    local fName = faction.name

    -- Procedurally generate the monument's text based on the AI's internal traits
    local trait1 = faction:getTrait("aggressive") and "unyielding strength and conquest"%_T or "diplomacy and unity"%_T
    local trait2 = faction:getTrait("wealthy") and "endless prosperity"%_T or "scavenging the ashes of the old world"%_T

    invokeClientFunction(player, "showLoreDialog", fName, trait1, trait2)
end
callable(CosmicChroniclesMonument, "readLore")

function CosmicChroniclesMonument.showLoreDialog(fName, trait1, trait2)
    if not onClient() then return end

    local text = "=== CULTURAL MONUMENT OF THE ${faction} ===\n\nWe survived the Great Darkness through ${trait1}.\nOur future among the stars is paved with ${trait2}.\n\nLet all who pass through this system know that we stand eternal against the Xsotan threat."%_t % {faction = fName:upper(), trait1 = trait1%_t, trait2 = trait2%_t}

    local dialog = {text = text, answers = {{answer = "Fascinating."%_t}}}
    ScriptUI():showDialog(dialog)
end