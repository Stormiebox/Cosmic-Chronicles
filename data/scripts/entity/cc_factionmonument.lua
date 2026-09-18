package.path = package.path .. ";data/scripts/lib/?.lua"

local Interaction = include("cc_interaction_controller")
local ChronicleState = include("cc_state")
include("data/scripts/lib/callable")
include("faction")
include("relations")
include("stringutility")

-- namespace CosmicChroniclesMonument
CosmicChroniclesMonument = {}
local self = CosmicChroniclesMonument
local OWNER = "data/scripts/entity/cc_factionmonument.lua"
self.record = nil
self.blocked = nil

local function options()
    return {eventId = Entity():getValue("cc_event_id")
        or ("monument:" .. tostring(Entity().id)), interactionType = "monument_respect",
        ownerFactionIndex = Entity().factionIndex}
end

function CosmicChroniclesMonument.initialize()
    if onServer() then self.record, self.blocked = Interaction.Load(Entity(), options()) end
end

function CosmicChroniclesMonument.interactionPossible(playerIndex)
    local targetPlayer = Player(playerIndex)
    if not targetPlayer or not targetPlayer.craft
            or targetPlayer.craft:getNearestDistance(Entity()) > 500 then return false end
    if onServer() and self.record then
        return self.record.state == "available"
            and not self.record.completedPlayers[tostring(playerIndex)]
    end
    return true
end

function CosmicChroniclesMonument.initUI()
    ScriptUI():registerInteraction("Read Inscription"%_t, "readLore")
end

function CosmicChroniclesMonument.readLore()
    if onClient() then invokeServerFunction("readLore") return end
    local buyer, craft, targetPlayer = getInteractingFaction(callingPlayer)
    local faction = Faction(Entity().factionIndex)
    if not buyer or not craft or not targetPlayer or not faction
            or craft:getNearestDistance(Entity()) > 500 or self.blocked or not self.record
            or self.record.state ~= "available"
            or self.record.completedPlayers[tostring(targetPlayer.index)] then return end

    local result = {reputation = 2500, factionIndex = faction.index}
    local receipt, _, created = Interaction.PrepareReceipt(OWNER, Entity(),
        "monument_respect", targetPlayer.index,
        {eventId = self.record.eventId, receiptDiscriminator = "player:"
            .. tostring(targetPlayer.index), playerIndex = targetPlayer.index}, result)
    if not receipt then return end
    if not created then
        if receipt.state == "succeeded" then
            self.record.completedPlayers[tostring(targetPlayer.index)] = receipt.receiptId
            Interaction.Store(Entity(), self.record, self.record)
        elseif receipt.state == "prepared" then
            self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
                targetPlayer.index, receipt, "interrupted_monument_reward") or self.record
        end
        return
    end
    local prepared, prepareError = Interaction.Transition(Entity(), self.record,
        "reward_prepared", {claimantPlayerIndex = targetPlayer.index,
            operationId = receipt.receiptId, receiptId = receipt.receiptId,
            rewardSnapshot = result, preparedAt = Interaction.Now()})
    if not prepared then
        Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt, "repair_required",
            receipt.resultEvidence, prepareError)
        return
    end
    self.record = prepared
    local delivered = pcall(function()
        changeRelations(buyer, faction, result.reputation, RelationChangeType.Default)
    end)
    if not delivered then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "monument_reward_failed") or self.record
        return
    end
    local completed = Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt,
        "succeeded", {reputation = result.reputation, deliveredAt = Interaction.Now()})
    if not completed then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, nil, "monument_receipt_completion_failed") or self.record
        return
    end
    local nextRecord = ChronicleState.NewInteraction(options(), Interaction.Now())
    nextRecord.completedPlayers = self.record.completedPlayers or {}
    nextRecord.completedPlayers[tostring(targetPlayer.index)] = receipt.receiptId
    nextRecord.lastOutcomeReceiptId = receipt.receiptId
    self.record = Interaction.Store(Entity(), self.record, nextRecord) or self.record
    Interaction.ResolveEvent(Entity(), "A cultural monument was documented and preserved.", result)

    local trait1 = faction:getTrait("aggressive") > 0.5
        and "unyielding strength and conquest" or "diplomacy and unity"
    local trait2 = faction.money > 10000000 and "endless prosperity"
        or "scavenging the ashes of the old world"
    invokeClientFunction(targetPlayer, "showLore", faction.name, trait1, trait2)
end

function CosmicChroniclesMonument.showLore(factionName, trait1, trait2)
    if not onClient() then return end
    local text = "=== CULTURAL MONUMENT OF ${faction} ===\n\nWe survived the Great Darkness through ${trait1}.\nOur future among the stars is paved with ${trait2}."%_t
        % {faction = string.upper(factionName), trait1 = trait1, trait2 = trait2}
    ScriptUI():showDialog({text = text, answers = {{answer = "Fascinating."%_t}}})
end

callable(CosmicChroniclesMonument, "readLore")
return CosmicChroniclesMonument
