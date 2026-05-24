package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")

-- namespace CosmicChroniclesBlackBox
CosmicChroniclesBlackBox = {}
local extracted = false

function CosmicChroniclesBlackBox.interactionPossible(playerIndex, option)
    return not extracted
end

function CosmicChroniclesBlackBox.initUI()
    ScriptUI():registerInteraction("Extract Data"%_t, "onInteract")
end

function CosmicChroniclesBlackBox.onInteract()
    invokeServerFunction("extract")
end

function CosmicChroniclesBlackBox.extract()
    if not onServer() then return end
    if extracted then return end
    extracted = true

    local player = Player(callingPlayer)

    -- Generate narrative log text
    local context = { warHeat = 100 }
    local log = CosmicVaultDialogue.getValidLine("captain_log", context) or "Mayday! Shields are failing! They're coming from everywhere!"%_T

    invokeClientFunction(player, "showLogDialog", log)

    -- Give valuable rewards
    local amount = random():getInt(100000, 250000)
    player:receive("Recovered Credits"%_t, amount)

    local UpgradeGenerator = include("upgradegenerator")
    if UpgradeGenerator and UpgradeGenerator.generateSystemUpgrade then
        local upgrade = UpgradeGenerator.generateSystemUpgrade(random():createSeed(), Rarity(RarityType.Rare))
        player:getInventory():add(upgrade)
    end

    player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Extracted data and recovered credits from the black box."%_T)
    Sector():deleteEntity(Entity())
end
callable(CosmicChroniclesBlackBox, "extract")

function CosmicChroniclesBlackBox.showLogDialog(log)
    if not onClient() then return end
    local text = "Black Box Recording:\n\n\"${log}\"\n\n*Recording Ends*"%_t % {log = log%_t}
    local dialog = {text = text, answers = {{answer = "Close"%_t}}}
    ScriptUI():showDialog(dialog)
end