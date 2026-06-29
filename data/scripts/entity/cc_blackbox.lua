package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")
include("stringutility")
include("goods")

-- Load the goods index to ensure goods array is populated
include("goodsindex")

-- namespace CosmicChroniclesBlackBox
CosmicChroniclesBlackBox = {}
local extracted = false

function CosmicChroniclesBlackBox.interactionPossible(playerIndex, option)
    if extracted then return false end

    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end

    -- Cosmic Overhaul/Chronicles: Explorer Resonance
    local maxDistance = 50
    local captain = craft:getCaptain()
    if captain then
        local CaptainClass = include("captainclass")
        if captain:hasClass(CaptainClass.Explorer) then
            maxDistance = 250
        end
    end

    if craft:getNearestDistance(Entity()) > maxDistance then return false end

    return true
end

function CosmicChroniclesBlackBox.initUI()
    if Entity():getValue("is_famine_relief") then
        ScriptUI():registerInteraction("Inspect Relief Cache"%_t, "onInteract")
    else
        ScriptUI():registerInteraction("Extract Data"%_t, "onInteract")
    end
end

function CosmicChroniclesBlackBox.onInteract()
    if Entity():getValue("is_famine_relief") then
        local dialog = {
            text = "This is a Famine Relief Cache. It contains massive amounts of food and medicine intended for the starving populace of this sector.\n\nYou can either steal the contents for personal gain, or donate the supplies to the local planetary governors to relieve the famine."%_t,
            answers = {
                {answer = "Steal Supplies (Gain Loot)"%_t, onSelect = "invokeSteal"},
                {answer = "Donate Supplies (Relieve Famine & Gain Rep)"%_t, onSelect = "invokeDonate"}
            }
        }
        ScriptUI():showDialog(dialog)
    else
        invokeServerFunction("extract")
    end
end

function CosmicChroniclesBlackBox.invokeSteal()
    invokeServerFunction("extract")
end

function CosmicChroniclesBlackBox.invokeDonate()
    invokeServerFunction("donate")
end

function CosmicChroniclesBlackBox.donate()
    if not onServer() then return end
    if extracted then return end
    extracted = true

    local player = Player(callingPlayer)
    local factionIndex = Entity():getValue("is_famine_relief")
    if factionIndex then
        local cve = include("cosmicvaulteconomy")
        if cve and cve.addFamineScore then
            cve.addFamineScore(factionIndex, -50) -- Instantly relieve 50 famine
        end
        local faction = Faction(factionIndex)
        if faction then
            Galaxy():changeFactionRelations(faction, player, 25000)
            player:sendChatMessage(faction.name, ChatMessageType.Information, "We are eternally grateful for these supplies! You have saved countless lives!"%_T)
        end
    end
    Sector():createExplosion(Entity().translationf, 1, false)
    Sector():deleteEntity(Entity())
end
callable(CosmicChroniclesBlackBox, "donate")

function CosmicChroniclesBlackBox.extract()
    if not onServer() then return end
    if extracted then return end
    extracted = true

    local player = Player(callingPlayer)

    -- Generate narrative log text
    local context = { warHeat = 100 }
    local log = CosmicVaultDialogue.getValidLine("captain_log", context) or "Mayday! Shields are failing! They're coming from everywhere!"%_T

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

    -- Cosmic Ascendancy: Corrupted Lore Nodes
    local isEclipseOwned = false
    local controllingFactionIndex = Galaxy():getControllingFaction(x, y)
    if controllingFactionIndex then
        local faction = Faction(controllingFactionIndex)
        if faction and faction.name == "The Eclipse" then
            isEclipseOwned = true
        end
    end

    if isEclipseOwned then
        log = "[CORRUPTED DATA] // TH3Y 4R3 H3R3 // " .. log
        bonusMultiplier = bonusMultiplier * 2.0
    end

    invokeClientFunction(player, "showLogDialog", log)

    -- Balanced from 75k-150k down to 15k-35k base
    local amount = math.floor(random():getInt(15000, 35000) * rewardFactor * bonusMultiplier)
    player:receive("Recovered Credits"%_t, amount)

    if isEclipseOwned then
        -- Spawn Ascendancy Ambush
        local cv_encounter = include("cosmicvaultencounter")
        if cv_encounter and cv_encounter.spawnAmbush then
            cv_encounter.spawnAmbush(controllingFactionIndex, 5000, 3, nil, true)
            player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Warning, "WARNING: Data extraction triggered a quantum distress beacon! Hostile contacts inbound!"%_T)
        end
    end

    local generator = include("upgradegenerator")()
    -- Balanced from guaranteed Rare/Exceptional to guaranteed Uncommon with a chance for Rare
    local rarityValue = RarityType.Uncommon
    if random():test(0.15 * rewardFactor * bonusMultiplier) then rarityValue = RarityType.Rare end
    -- Cosmic Chronicles/Vault: Galactic Lore Broadcasts
    if random():test(0.02 * rewardFactor * bonusMultiplier) then rarityValue = RarityType.Legendary end

    local ok, upgrade = pcall(function() return generator:generateSectorSystem(x, y, nil, {[rarityValue] = 1}) end)
    if ok and upgrade then
        if type(upgrade) == "table" and upgrade.script then
            local seed = generator:getUpgradeSeed(x, y, upgrade.script, upgrade.rarity)
            upgrade = SystemUpgradeTemplate(upgrade.script, upgrade.rarity, seed)
        end
        player:getInventory():add(upgrade)
    end

    -- Cosmic Chronicles - Black Market Rift Trade
    -- Drop Rift Research Data
    if random():test(0.25 * bonusMultiplier) then
        local numData = random():getInt(2, 5)
        player:getInventory():add(goods["Rift Research Data"]:good(), numData)
        player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Extracted %1% Rift Research Data from the black box."%_T, numData)
    end

    -- Drop Subclass Subsystems as high-value contraband trade goods
    if random():test(0.15 * bonusMultiplier) then
        local subclassGoodData = {
            name = "Subclass Subsystem",
            plural = "Subclass Subsystems",
            description = "A heavily encrypted, prototype subsystem core. Smugglers will pay a premium for this technology.",
            icon = "data/textures/icons/circuit-board.png",
            price = 125000,
            size = 2.0,
            illegal = true,
            dangerous = true,
            stolen = true
        }

        local cvGoods = include("cosmicvaultgoods")
        cvGoods.registerGood(subclassGoodData)
        local good = goods["Subclass Subsystem"]
        if good then subclassGood = good:good() end

        if subclassGood then
            local numSub = random():getInt(1, 2)
            player:getInventory():add(subclassGood, numSub)
            player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Extracted %1% Subclass Subsystems from the black box."%_T, numSub)
        end
    end

    if amount >= 50000 or rarityValue == RarityType.Legendary then
        local article = {
            title = "Major Discovery",
            content = "The independent commander " .. player.name .. " has successfully decrypted a highly-classified data cache in sector [" .. x .. ":" .. y .. "], unearthing immense wealth and forgotten technologies.",
            category = "Discovery"
        }
        local cv_news = include("cosmicvaultnews")
        cv_news.publishArticle(article)
    end

    player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Extracted data and recovered credits from the black box."%_T)
    Sector():createExplosion(Entity().translationf, 1, false)
    Sector():deleteEntity(Entity())
end
callable(CosmicChroniclesBlackBox, "extract")

function CosmicChroniclesBlackBox.showLogDialog(log)
    if not onClient() then return end
    local text = "Black Box Recording:\n\n\"${log}\"\n\n*Recording Ends*"%_t % {log = log}
    local dialog = {text = text, answers = {{answer = "Close"%_t}}}
    ScriptUI():showDialog(dialog)
end

return CosmicChroniclesBlackBox
