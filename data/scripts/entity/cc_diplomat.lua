package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
local Interaction = include("cc_interaction_controller")
include("callable")
include("faction")
include("stringutility")

-- namespace ChronicleDiplomat
ChronicleDiplomat = {}
local self = ChronicleDiplomat
local OWNER = "data/scripts/entity/cc_diplomat.lua"
local CATALOG = {
    standard = {credits = 150000, label = "Extraction fee."},
    merchant = {credits = 450000, label = "Hazard pay.", captain = CaptainClass.Merchant},
    smuggler = {credits = 100000, label = "Diplomat's payoff.",
        captain = CaptainClass.Smuggler, upgrade = true},
}
self.record = nil
self.blocked = nil

local function load()
    self.record, self.blocked = Interaction.Load(Entity(), {
        eventId = Entity():getValue("cc_event_id") or ("diplomat:" .. tostring(Entity().id)),
        interactionType = "diplomat_rescue", ownerFactionIndex = Entity().factionIndex})
end

local function resolvePlayer()
    local buyer, craft, targetPlayer = getInteractingFaction(callingPlayer)
    if not buyer or not craft or not targetPlayer then return nil end
    if craft:getNearestDistance(Entity()) > 500 then return nil end
    return buyer, craft, targetPlayer
end

function ChronicleDiplomat.initialize()
    if onServer() then load() end
end

function ChronicleDiplomat.interactionPossible(playerIndex)
    local targetPlayer = Player(playerIndex)
    return targetPlayer and targetPlayer.craft
        and targetPlayer.craft:getNearestDistance(Entity()) <= 500
        and (not onServer() or (self.record and self.record.state == "available"))
end

function ChronicleDiplomat.initUI()
    ScriptUI():registerInteraction("Open Comm Link"%_t, "onInteract")
end

function ChronicleDiplomat.onInteract()
    local craft = Player().craft
    local captain = craft and craft:getCaptain()
    local answers = {{answer = "Dock your pod. We'll get you out of here."%_t,
        onSelect = "chooseStandard"}}
    if captain and captain:hasClass(CaptainClass.Merchant) then
        answers[#answers + 1] = {answer = "[Merchant] Negotiate hazard pay."%_t,
            onSelect = "chooseMerchant"}
    end
    if captain and captain:hasClass(CaptainClass.Smuggler) then
        answers[#answers + 1] = {answer = "[Smuggler] Offer a forged extraction route."%_t,
            onSelect = "chooseSmuggler"}
    end
    ScriptUI():showDialog({text = "My escort was destroyed. I require immediate extraction."%_t,
        answers = answers})
end

function ChronicleDiplomat.chooseStandard() invokeServerFunction("rescue", "standard") end
function ChronicleDiplomat.chooseMerchant() invokeServerFunction("rescue", "merchant") end
function ChronicleDiplomat.chooseSmuggler() invokeServerFunction("rescue", "smuggler") end

function ChronicleDiplomat.rescue(recipeId)
    if not onServer() then return end
    local recipe = CATALOG[recipeId]
    local buyer, craft, targetPlayer = resolvePlayer()
    if not recipe or not targetPlayer or self.blocked or not self.record
            or self.record.state ~= "available" then return end
    local captain = craft:getCaptain()
    if recipe.captain and (not captain or not captain:hasClass(recipe.captain)) then return end

    local result = {credits = recipe.credits, upgrade = recipe.upgrade == true,
        recipeId = recipeId, factionIndex = buyer.index}
    local receipt, _, created = Interaction.PrepareReceipt(OWNER, Entity(),
        "diplomat_rescue", targetPlayer.index,
        {eventId = self.record.eventId, recipeId = recipeId,
            factionIndex = buyer.index}, result)
    if not receipt then return end
    if not created then
        if receipt.state == "prepared" then
            self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
                targetPlayer.index, receipt, "interrupted_diplomat_reward") or self.record
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
        buyer:receive(recipe.label, recipe.credits)
        if recipe.upgrade then
            local generator = include("upgradegenerator")()
            local x, y = Sector():getCoordinates()
            local upgrade = generator:generateSectorSystem(x, y, Rarity(RarityType.Exotic))
            Sector():dropUpgrade(Entity().translationf, buyer, nil, upgrade)
        end
    end)
    if not delivered then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, receipt, "diplomat_reward_failed") or self.record
        return
    end
    local completed = Interaction.FinishReceipt(OWNER, targetPlayer.index, receipt,
        "succeeded", {credits = recipe.credits, upgrade = recipe.upgrade == true,
            deliveredAt = Interaction.Now()})
    if not completed then
        self.record = Interaction.RequireRepair(Entity(), self.record, OWNER,
            targetPlayer.index, nil, "diplomat_receipt_completion_failed") or self.record
        return
    end
    self.record = Interaction.Transition(Entity(), self.record, "resolving") or self.record
    self.record = Interaction.Transition(Entity(), self.record, "succeeded",
        {completedAt = Interaction.Now()}) or self.record
    Interaction.ResolveEvent(Entity(), "The stranded diplomat was safely extracted.", result)
    targetPlayer:sendChatMessage("Diplomat"%_t, ChatMessageType.Information,
        "Extraction complete. Payment transferred."%_t)
    Entity():addScriptOnce("deletejumped.lua")
end

callable(ChronicleDiplomat, "rescue")
return ChronicleDiplomat
