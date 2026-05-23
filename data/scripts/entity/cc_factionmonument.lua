package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")

-- namespace CosmicChroniclesMonument
CosmicChroniclesMonument = {}

function CosmicChroniclesMonument.interactionPossible(playerIndex, option)
    return true
end

function CosmicChroniclesMonument.initUI()
    ScriptUI():registerInteraction("Read Inscription", "onInteract")
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
    local trait1 = faction:getTrait("aggressive") and "unyielding strength and conquest" or "diplomacy and unity"
    local trait2 = faction:getTrait("wealthy") and "endless prosperity" or "scavenging the ashes of the old world"

    local text = "=== CULTURAL MONUMENT OF THE " .. fName:upper() .. " ===\n\n"
    text = text .. "We survived the Great Darkness through " .. trait1 .. ".\n"
    text = text .. "Our future among the stars is paved with " .. trait2 .. ".\n\n"
    text = text .. "Let all who pass through this system know that we stand eternal against the Xsotan threat."

    invokeClientFunction(player, "showLoreDialog", text)
end
callable(CosmicChroniclesMonument, "readLore")

function CosmicChroniclesMonument.showLoreDialog(text)
    if not onClient() then return end
    local dialog = {text = text, answers = {{answer = "Fascinating."}}}
    ScriptUI():showDialog(dialog)
end