package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
local Interaction = include("cc_interaction_controller")
include("data/scripts/lib/callable")
include("faction")
include("stringutility")

-- namespace ChronicleGhostShip
ChronicleGhostShip = {}
local self = ChronicleGhostShip
local OWNER = "data/scripts/entity/cc_ghostship.lua"
local CATALOG = {
    standard = {credits = 25000},
    scavenger = {credits = 125000, captain = CaptainClass.Scavenger},
    explorer = {credits = 100000, captain = CaptainClass.Explorer},
}
self.record = nil
self.blocked = nil

function ChronicleGhostShip.initialize()
    if onServer() then
        self.record, self.blocked = Interaction.Load(Entity(), {
            eventId = Entity():getValue("cc_event_id") or ("ghost:" .. tostring(Entity().id)),
            interactionType = "ghost_ship_salvage", ownerFactionIndex = Entity().factionIndex})
    end
end

function ChronicleGhostShip.interactionPossible(playerIndex)
    local targetPlayer = Player(playerIndex)
    return targetPlayer and targetPlayer.craft
        and targetPlayer.craft:getNearestDistance(Entity()) <= 500
        and (not onServer() or (self.record and self.record.state == "available"))
end

function ChronicleGhostShip.initUI()
    ScriptUI():registerInteraction("Board & Investigate"%_t, "onInteract")
end

function ChronicleGhostShip.onInteract()
    local craft = Player().craft
    local captain = craft and craft:getCaptain()
    local answers = {{answer = "Salvage what remains."%_t, onSelect = "chooseStandard"}}
    if captain and captain:hasClass(CaptainClass.Scavenger) then
        answers[#answers + 1] = {answer = "[Scavenger] Open the shielded holds."%_t,
            onSelect = "chooseScavenger"}
    end
    if captain and captain:hasClass(CaptainClass.Explorer) then
        answers[#answers + 1] = {answer = "[Explorer] Decrypt the nav-computer."%_t,
            onSelect = "chooseExplorer"}
    end
    ScriptUI():showDialog({text = "The corrupted log ends in static and a low mechanical hum."%_t,
        answers = answers})
end

function ChronicleGhostShip.chooseStandard() invokeServerFunction("salvage", "standard") end
function ChronicleGhostShip.chooseScavenger() invokeServerFunction("salvage", "scavenger") end
function ChronicleGhostShip.chooseExplorer() invokeServerFunction("salvage", "explorer") end

function ChronicleGhostShip.salvage(recipeId)
    if not onServer() then return end
    local recipe = CATALOG[recipeId]
    local buyer, craft, targetPlayer = getInteractingFaction(callingPlayer)
    if not recipe or not buyer or not craft or not targetPlayer
            or craft:getNearestDistance(Entity()) > 500 or self.blocked or not self.record
            or self.record.state ~= "available" then return end
    local captain = craft:getCaptain()
    if recipe.captain and (not captain or not captain:hasClass(recipe.captain)) then return end
    local result = {credits = recipe.credits, recipeId = recipeId, factionIndex = buyer.index}
    local receipt, _, created = Interaction.PrepareReceipt(OWNER, Entity(),
        "ghost_ship_salvage", targetPlayer.index,
        {eventId = self.record.eventId, recipeId = recipeId, factionIndex = buyer.index}, result)
    if not receipt then return end
    if not created then
        if receipt.state == "prepared" then
            self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
                targetPlayer.index, receipt, "interrupted_ghost_reward") or self.record
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
    local delivered = pcall(function() buyer:receive("Salvaged Credits from Ghost Ship.",
        recipe.credits) end)
    if not delivered then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "ghost_reward_failed") or self.record
        return
    end
    local completed = Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt,
        "succeeded", {credits = recipe.credits, deliveredAt = Interaction.Now()})
    if not completed then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, nil, "ghost_receipt_completion_failed") or self.record
        return
    end
    self.record = Interaction.Transition(Entity(), self.record, "resolving") or self.record
    self.record = Interaction.Transition(Entity(), self.record, "succeeded",
        {completedAt = Interaction.Now()}) or self.record
    Interaction.ResolveEvent(Entity(), "The derelict ghost ship was investigated and salvaged.", result)
    local position, radius = Entity().translationf, Entity().radius or 50
    broadcastInvokeClientFunction("spawnExplosion", position, radius)
    Sector():deleteEntity(Entity())
end

function ChronicleGhostShip.spawnExplosion(position, radius)
    if onClient() then Sector():createExplosion(position, radius, false) end
end

callable(ChronicleGhostShip, "salvage")
return ChronicleGhostShip
