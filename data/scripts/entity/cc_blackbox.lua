package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")
include("stringutility")
include("galaxy")

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
    -- Give valuable but balanced rewards
    local x, y = Sector():getCoordinates()
    local rewardFactor = Balancing_GetSectorRewardFactor(x, y)

    -- Cosmic Overhaul Synergy: Scavengers and Explorers extract far more value from black boxes
    local ship = player.craft
    local bonusMultiplier = 1.0
    if ship then
        local captain = ship:getCaptain()
        if captain then
            local CaptainClass = include("captainclass")
            if captain:hasClass(CaptainClass.Scavenger) then
                bonusMultiplier = 1.5
            elseif captain:hasClass(CaptainClass.Explorer) then
                bonusMultiplier = 1.25
            end
        end
    end

    -- Balanced from 75k-150k down to 15k-35k base
    local amount = math.floor(random():getInt(15000, 35000) * rewardFactor * bonusMultiplier)
    player:receive("Recovered Credits"%_t, amount)

    local generator = include("upgradegenerator")()
    -- Balanced from guaranteed Rare/Exceptional to guaranteed Uncommon with a chance for Rare
    local rarityValue = RarityType.Uncommon
    if random():test(0.15 * rewardFactor * bonusMultiplier) then rarityValue = RarityType.Rare end

    local ok, upgrade = pcall(function() return generator:generateSectorSystem(x, y, nil, {[rarityValue] = 1}) end)
    if ok and upgrade then
        if type(upgrade) == "table" and upgrade.script then
            local seed = generator:getUpgradeSeed(x, y, upgrade.script, upgrade.rarity)
            upgrade = SystemUpgradeTemplate(upgrade.script, upgrade.rarity, seed)
        end
        player:getInventory():add(upgrade)
    end

    player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Extracted data and recovered credits from the black box."%_T)
    Sector():deleteEntity(Entity())
end
callable(CosmicChroniclesBlackBox, "extract")

function CosmicChroniclesBlackBox.showLogDialog(log)
    if not onClient() then return end
    local text = "Black Box Recording:\n\n\"${log}\"\n\n*Recording Ends*"%_t % {log = log}
    local dialog = {text = text, answers = {{answer = "Close"%_t}}}
    ScriptUI():showDialog(dialog)
end