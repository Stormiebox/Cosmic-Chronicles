package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
local Interaction = include("cc_interaction_controller")
include("data/scripts/lib/callable")
include("faction")
include("relations")
include("stringutility")

-- namespace CosmicChroniclesRefugee
CosmicChroniclesRefugee = {}
local self = CosmicChroniclesRefugee
local OWNER = "data/scripts/entity/cc_refugeedialogue.lua"
local RECIPES = {food = {good = "Food", amount = 50},
    medicine = {good = "Medical Supplies", amount = 50}}
self.record = nil
self.blocked = nil

function CosmicChroniclesRefugee.initialize()
    if onServer() then
        self.record, self.blocked = Interaction.Load(Entity(), {
            eventId = Entity():getValue("cc_event_id") or ("refugee:" .. tostring(Entity().id)),
            interactionType = "refugee_aid", ownerFactionIndex = Entity().factionIndex})
    end
end

function CosmicChroniclesRefugee.interactionPossible(playerIndex)
    local targetPlayer = Player(playerIndex)
    return targetPlayer and targetPlayer.craft
        and targetPlayer.craft:getNearestDistance(Entity()) <= 500
        and (not onServer() or (self.record and self.record.state == "available"))
end

function CosmicChroniclesRefugee.initUI()
    ScriptUI():registerInteraction("Offer Assistance"%_t, "onInteract")
end

function CosmicChroniclesRefugee.onInteract()
    local craft = Player().craft
    local answers = {}
    if craft and craft:hasComponent(ComponentType.CargoBay) then
        if craft:getCargoAmount("Food") >= 50 then
            answers[#answers + 1] = {answer = "Transfer 50 Food."%_t,
                onSelect = "chooseFood"}
        end
        if craft:getCargoAmount("Medical Supplies") >= 50 then
            answers[#answers + 1] = {answer = "Transfer 50 Medical Supplies."%_t,
                onSelect = "chooseMedicine"}
        end
    end
    answers[#answers + 1] = {answer = "I cannot help right now."%_t}
    ScriptUI():showDialog({text = "Our engines are damaged and our supplies are exhausted."%_t,
        answers = answers})
end

function CosmicChroniclesRefugee.chooseFood() invokeServerFunction("donate", "food") end
function CosmicChroniclesRefugee.chooseMedicine() invokeServerFunction("donate", "medicine") end

local function buildOutcome(eventId, craft)
    local credits = 0
    local captain = craft:getCaptain()
    if captain and captain:hasClass(CaptainClass.Merchant) then credits = 50000
    elseif captain and captain:hasClass(CaptainClass.Smuggler) then credits = 75000 end
    local x, y = Sector():getCoordinates()
    local rand = Random(Seed(eventId .. ":refugee-aid"))
    local lead
    if rand:test(0.25) then
        lead = {x = x + rand:getInt(-10, 10), y = y + rand:getInt(-10, 10),
            seed = rand:getInt(1, 2147483646)}
    end
    return {reputation = 2500, credits = credits, lead = lead}
end

function CosmicChroniclesRefugee.donate(recipeId)
    if not onServer() then return end
    local recipe = RECIPES[recipeId]
    local buyer, craft, targetPlayer = getInteractingFaction(callingPlayer)
    if not recipe or not buyer or not craft or not targetPlayer
            or not craft:hasComponent(ComponentType.CargoBay)
            or craft:getNearestDistance(Entity()) > 500 or self.blocked or not self.record
            or self.record.state ~= "available" then return end
    local event = Interaction.InvokeCoordinator("getEvent", self.record.eventId)
    if not event or event.state ~= "active" then return end
    if craft:getCargoAmount(recipe.good) < recipe.amount then return end

    local outcome = buildOutcome(self.record.eventId, craft)
    local snapshot = {good = recipe.good, amount = recipe.amount,
        reputation = outcome.reputation, credits = outcome.credits, lead = outcome.lead,
        factionIndex = Entity().factionIndex}
    local receipt, _, created = Interaction.PrepareReceipt(OWNER, Entity(), "refugee_aid",
        targetPlayer.index, {eventId = self.record.eventId, recipeId = recipeId,
            cargoBefore = craft:getCargoAmount(recipe.good), factionIndex = buyer.index}, snapshot)
    if not receipt then return end
    if not created then
        if receipt.state == "prepared" then
            self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
                targetPlayer.index, receipt, "interrupted_refugee_aid") or self.record
        end
        return
    end
    local debitPrepared, prepareError = Interaction.Transition(Entity(), self.record,
        "debit_prepared", {claimantPlayerIndex = targetPlayer.index,
            operationId = receipt.receiptId, receiptId = receipt.receiptId,
            costSnapshot = {good = recipe.good, amount = recipe.amount},
            rewardSnapshot = snapshot, preparedAt = Interaction.Now()})
    if not debitPrepared then
        Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt, "repair_required",
            receipt.resultEvidence, prepareError)
        return
    end
    self.record = debitPrepared
    local debited = pcall(function() craft:removeCargo(recipe.good, recipe.amount) end)
    if not debited then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "refugee_cargo_debit_failed") or self.record
        return
    end
    self.record = Interaction.Transition(Entity(), self.record, "reward_prepared") or self.record
    local delivered = pcall(function()
        local faction = Faction(Entity().factionIndex)
        if faction then changeRelations(buyer, faction, outcome.reputation,
            RelationChangeType.GoodsTrade) end
        if outcome.credits > 0 then buyer:receive("Refugee convoy assistance.", outcome.credits) end
        if outcome.lead then
            local queued, queueError = Interaction.InvokeCoordinator("queueDerivedEvent", OWNER,
                self.record.eventId, "hidden_stash", outcome.lead.x, outcome.lead.y,
                receipt.receiptId, {seed = outcome.lead.seed})
            if not queued then error(queueError or "lead_queue_failed") end
            if not targetPlayer:getKnownSector(outcome.lead.x, outcome.lead.y) then
                local view = SectorView()
                view:setCoordinates(outcome.lead.x, outcome.lead.y)
                view.note = "Chronicle lead: refugee resource cache"
                if view.tagIconPath == "" then
                    view.tagIconPath = "data/textures/icons/cc_galacticnews_rss.png"
                end
                targetPlayer:addKnownSector(view)
            end
        end
    end)
    if not delivered then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "refugee_outcome_failed") or self.record
        return
    end
    local completed = Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt,
        "succeeded", {outcome = outcome, deliveredAt = Interaction.Now()})
    if not completed then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, nil, "refugee_receipt_completion_failed") or self.record
        return
    end
    self.record = Interaction.Transition(Entity(), self.record, "resolving") or self.record
    self.record = Interaction.Transition(Entity(), self.record, "succeeded",
        {completedAt = Interaction.Now()}) or self.record
    Interaction.ResolveEvent(Entity(), "The refugee convoy received emergency supplies.", outcome)
    targetPlayer:sendChatMessage("Refugee Convoy"%_t, ChatMessageType.Information,
        outcome.lead and "Thank you. We uploaded a resource-cache lead to your map."%_t
            or "Thank you. These supplies will save lives."%_t)
    Entity():addScriptOnce("deletejumped.lua")
end

callable(CosmicChroniclesRefugee, "donate")
return CosmicChroniclesRefugee
