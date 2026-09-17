package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
local Interaction = include("cc_interaction_controller")
local ChronicleGoods = include("cc_goods")
include("callable")
include("faction")
include("galaxy")
include("goods")
include("goodsindex")
include("relations")
include("stringutility")

ChronicleGoods.RegisterAll()

-- namespace CosmicChroniclesBlackBox
CosmicChroniclesBlackBox = {}
local self = CosmicChroniclesBlackBox
local OWNER = "data/scripts/entity/cc_blackbox.lua"
self.record = nil
self.blocked = nil

local function eventId()
    return Entity():getValue("cc_event_id") or ("blackbox:" .. tostring(Entity().id))
end

local function load()
    self.record, self.blocked = Interaction.Load(Entity(), {eventId = eventId(),
        interactionType = "black_box", ownerFactionIndex = Entity().factionIndex})
end

local function resolvePlayer()
    local buyer, craft, targetPlayer = getInteractingFaction(callingPlayer)
    if not buyer or not craft or not targetPlayer then return nil end
    local maxDistance = 500
    local captain = craft:getCaptain()
    if captain and captain:hasClass(CaptainClass.Explorer) then maxDistance = 1500 end
    if craft:getNearestDistance(Entity()) > maxDistance then return nil end
    return buyer, craft, targetPlayer
end

local function eclipseControlled(x, y)
    local controlling = Galaxy():getControllingFaction(x, y)
    return controlling and controlling.getValue and controlling:getValue("is_eclipse") == true
end

local function rewardSnapshot(craft, action)
    local x, y = Sector():getCoordinates()
    if action == "donate" then
        return {action = action, reputation = 25000, famineDelta = -50,
            factionIndex = tonumber(Entity():getValue("is_famine_relief"))}
    end
    local captain = craft:getCaptain()
    local multiplier = 1
    if captain and captain:hasClass(CaptainClass.Scavenger) then multiplier = 1.5
    elseif captain and captain:hasClass(CaptainClass.Explorer) then multiplier = 1.25 end
    local isEclipse = eclipseControlled(x, y)
    if isEclipse then multiplier = multiplier * 2 end
    local factor = Balancing_GetSectorRewardFactor(x, y)
    local rand = Random(Seed(eventId() .. ":blackbox"))
    local amount = math.floor(rand:getInt(15000, 35000) * factor * multiplier)
    local rarity = RarityType.Uncommon
    if rand:test(math.min(1, 0.15 * factor * multiplier)) then rarity = RarityType.Rare end
    if rand:test(math.min(1, 0.02 * factor * multiplier)) then rarity = RarityType.Legendary end
    local riftData = rand:test(math.min(1, 0.25 * multiplier)) and rand:getInt(2, 5) or 0
    local subclasses = rand:test(math.min(1, 0.15 * multiplier)) and rand:getInt(1, 2) or 0
    return {action = action, credits = amount, rarity = rarity, riftData = riftData,
        subclasses = subclasses, fragments = 1, eclipse = isEclipse, x = x, y = y}
end

function CosmicChroniclesBlackBox.initialize()
    if onServer() then load() end
end

function CosmicChroniclesBlackBox.interactionPossible(playerIndex)
    local targetPlayer = Player(playerIndex)
    if not targetPlayer or not targetPlayer.craft then return false end
    local distance = 500
    local captain = targetPlayer.craft:getCaptain()
    if captain and captain:hasClass(CaptainClass.Explorer) then distance = 1500 end
    return targetPlayer.craft:getNearestDistance(Entity()) <= distance
        and (not onServer() or (self.record and self.record.state == "available"))
end

function CosmicChroniclesBlackBox.initUI()
    ScriptUI():registerInteraction(Entity():getValue("is_famine_relief")
        and "Inspect Relief Cache"%_t or "Extract Data"%_t, "onInteract")
end

function CosmicChroniclesBlackBox.onInteract()
    if Entity():getValue("is_famine_relief") then
        ScriptUI():showDialog({text = "This relief cache can be recovered or donated to the starving population."%_t,
            answers = {{answer = "Recover the supplies."%_t, onSelect = "chooseExtract"},
                {answer = "Donate the supplies."%_t, onSelect = "chooseDonate"}}})
    else
        invokeServerFunction("resolve", "extract")
    end
end

function CosmicChroniclesBlackBox.chooseExtract() invokeServerFunction("resolve", "extract") end
function CosmicChroniclesBlackBox.chooseDonate() invokeServerFunction("resolve", "donate") end

function CosmicChroniclesBlackBox.resolve(action)
    if not onServer() or (action ~= "extract" and action ~= "donate") then return end
    local buyer, craft, targetPlayer = resolvePlayer()
    if not targetPlayer or self.blocked or not self.record
            or self.record.state ~= "available" then return end
    if action == "donate" and not Entity():getValue("is_famine_relief") then return end
    local reward = rewardSnapshot(craft, action)
    if action == "donate" and not reward.factionIndex then return end
    reward.factionIndex = reward.factionIndex or buyer.index
    local receipt, _, created = Interaction.PrepareReceipt(OWNER, Entity(),
        "black_box_" .. action, targetPlayer.index,
        {eventId = self.record.eventId, action = action,
            factionIndex = buyer.index}, reward)
    if not receipt then return end
    if not created then
        if receipt.state == "prepared" then
            self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
                targetPlayer.index, receipt, "interrupted_black_box_reward") or self.record
        end
        return
    end
    local prepared, prepareError = Interaction.Transition(Entity(), self.record,
        "reward_prepared", {claimantPlayerIndex = targetPlayer.index,
            operationId = receipt.receiptId, receiptId = receipt.receiptId,
            rewardSnapshot = reward, preparedAt = Interaction.Now()})
    if not prepared then
        Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt, "repair_required",
            receipt.resultEvidence, prepareError)
        return
    end
    self.record = prepared

    local delivered = pcall(function()
        if action == "donate" then
            local faction = Faction(reward.factionIndex)
            if not faction then error("faction_unavailable") end
            local economy = include("cosmicvaulteconomy")
            economy.addFamineScore(reward.factionIndex, reward.famineDelta)
            changeRelations(buyer, faction, reward.reputation, RelationChangeType.General)
        else
            buyer:receive("Recovered Credits from the cache.", reward.credits)
            targetPlayer:setValue("cc_log_fragments",
                (tonumber(targetPlayer:getValue("cc_log_fragments")) or 0) + reward.fragments)
            local generator = include("upgradegenerator")()
            local upgrade = generator:generateSectorSystem(reward.x, reward.y, Rarity(reward.rarity))
            if upgrade then buyer:getInventory():add(upgrade) end
            local rift = goods["Rift Research Data"]
            if reward.riftData > 0 and rift then
                Sector():dropCargo(craft.translationf, buyer, nil, rift:good(), buyer.index,
                    reward.riftData)
            end
            local subclass = goods["Subclass Subsystem"]
            if reward.subclasses > 0 and subclass then
                Sector():dropCargo(craft.translationf, buyer, nil, subclass:good(), buyer.index,
                    reward.subclasses)
            end
        end
    end)
    if not delivered then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "black_box_delivery_failed") or self.record
        return
    end
    local completed = Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt,
        "succeeded", {reward = reward, deliveredAt = Interaction.Now()})
    if not completed then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, nil, "black_box_receipt_completion_failed") or self.record
        return
    end
    self.record = Interaction.Transition(Entity(), self.record, "resolving") or self.record
    self.record = Interaction.Transition(Entity(), self.record, "succeeded",
        {completedAt = Interaction.Now()}) or self.record
    local typeName = Entity():getValue("cc_event_type")
    if typeName ~= "hidden_stash" then
        Interaction.ResolveEvent(Entity(), action == "donate"
            and "A famine relief cache was donated to its intended recipients."
            or "An ancient data cache was safely extracted.", reward)
    end
    targetPlayer:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information,
        action == "donate" and "Relief supplies transferred successfully."%_T
            or "Cache extraction completed and recorded."%_T)
    Sector():deleteEntity(Entity())
end

callable(CosmicChroniclesBlackBox, "resolve")
return CosmicChroniclesBlackBox
