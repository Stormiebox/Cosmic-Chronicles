package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = include("SectorGenerator")
local PirateGenerator = include("pirategenerator")
local Placer = include("placer")
local PlanGenerator = include("plangenerator")
local Balancer = include("galaxy")
local ShipUtility = include("shiputility")
local EventContract = include("cc_event_contract")
include("stringutility")

-- namespace BountyAmbush
BountyAmbush = {}
local self = BountyAmbush
local unpackValues = table.unpack or unpack

local function packValues(...)
    return {n = select("#", ...), ...}
end

local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local REWARD = 2500000
self.eventId = nil
self.bossId = nil

local function invokeCoordinator(functionName, ...)
    local values = packValues(Galaxy():invokeFunction(COORDINATOR, functionName, ...))
    if values[1] ~= 0 then return nil, "coordinator_unavailable" end
    return unpackValues(values, 2, values.n)
end

local function cleanup(entities)
    for _, entity in ipairs(entities) do
        if valid(entity) then Sector():deleteEntity(entity) end
    end
end

function BountyAmbush.initialize(eventId, seed)
    self.eventId = eventId
    if onServer() then BountyAmbush.spawn(eventId, seed) end
end

function BountyAmbush.spawn(eventId, seed)
    if type(eventId) ~= "string" then return end
    local sector = Sector()
    local existing = {sector:getEntitiesByScriptValue("cc_event_id", eventId)}
    if #existing > 0 then return end
    local expectedCount = 5
    EventContract.Begin(eventId, "bounty_ambush", expectedCount)
    local x, y = sector:getCoordinates()
    local faction = Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))
    local volume = Balancer.getSectorShipVolume(x, y) * 5
    local plan = PlanGenerator.makeShipPlan(faction, volume)
    local spawned = {}
    local boss = sector:createShip(faction, "", plan, SectorGenerator(x, y):getPositionInSector())
    if not valid(boss) then EventContract.Fail(eventId, "boss_creation_failed") return end
    EventContract.Tag(boss, eventId, "bounty_ambush")
    spawned[#spawned + 1] = boss
    boss.title = "Dread Pirate Lord"
    boss.name = "Bounty Target"
    boss.crew = boss.idealCrew
    boss:addScript("icon.lua", "data/textures/icons/pixel/double_skull_big.png")
    ShipUtility.addArmedTurretsToCraft(boss, 3)
    boss.damageMultiplier = (boss.damageMultiplier or 1) * 2
    boss:setValue("is_pirate", true)

    for _ = 1, 4 do
        local minion = PirateGenerator.createPirate()
        if valid(minion) then
            EventContract.Tag(minion, eventId, "bounty_ambush")
            spawned[#spawned + 1] = minion
            Placer.resolveIntersections({minion})
        end
    end
    if #spawned ~= expectedCount then
        cleanup(spawned)
        EventContract.Fail(eventId, "partial_bounty_spawn")
        return
    end
    self.bossId = tostring(boss.id)
    boss:registerCallback("onDestroyed", "onBossDestroyed")
    EventContract.Complete(eventId, #spawned)
    sector:broadcastChatMessage(boss.title, ChatMessageType.Chatter,
        "So, you're the one trying to collect the bounty? You've walked into your own grave!"%_T)
end

function BountyAmbush.onBossDestroyed(entityId)
    if not onServer() or type(self.eventId) ~= "string" then return end
    if self.bossId and entityId and tostring(entityId) ~= self.bossId then return end
    local event = invokeCoordinator("getEvent", self.eventId)
    if not event or event.state ~= "active" then return end
    local players = {Sector():getPlayers()}
    local participants = {}
    for _, targetPlayer in ipairs(players) do
        if targetPlayer then participants[#participants + 1] = targetPlayer.index end
    end
    table.sort(participants)
    local resolving = invokeCoordinator("requestEventTransition", "event_resolver",
        self.eventId, event.revision, "resolving", {participants = participants,
            outcome = {kind = "boss_destroyed", bossId = self.bossId,
                summary = "The pirate bounty target was destroyed."}})
    if not resolving then return end

    local ambiguous = false
    for _, playerIndex in ipairs(participants) do
        local targetPlayer = Player(playerIndex)
        local receipt, _, created = invokeCoordinator("prepareEventRewardReceipt",
            "event_resolver", self.eventId, playerIndex,
            {eventId = self.eventId, eventRevision = resolving.revision,
                bossId = self.bossId}, {credits = REWARD})
        if receipt and created and targetPlayer then
            local delivered = pcall(function()
                targetPlayer:receive("Received %1% Credits for claiming the bounty."%_T, REWARD)
            end)
            if delivered then
                local completed = invokeCoordinator("transitionEventRewardReceipt",
                    "event_resolver", self.eventId, playerIndex, receipt.receiptId,
                    receipt.revision, "succeeded", {credits = REWARD,
                        deliveredAt = Server().unpausedRuntime})
                if not completed then ambiguous = true end
            else
                ambiguous = true
                invokeCoordinator("transitionEventRewardReceipt", "event_resolver",
                    self.eventId, playerIndex, receipt.receiptId, receipt.revision,
                    "repair_required", receipt.resultEvidence, "reward_delivery_failed")
            end
        elseif receipt and receipt.state ~= "succeeded" then
            ambiguous = true
            if receipt.state == "prepared" then
                invokeCoordinator("transitionEventRewardReceipt", "event_resolver",
                    self.eventId, playerIndex, receipt.receiptId, receipt.revision,
                    "repair_required", receipt.resultEvidence, "interrupted_reward_delivery")
            end
        elseif not receipt then
            ambiguous = true
        end
    end
    local nextState = ambiguous and "repair_required" or "succeeded"
    invokeCoordinator("requestEventTransition", "event_resolver", self.eventId,
        resolving.revision, nextState, {outcome = {kind = "boss_destroyed",
            bossId = self.bossId, participants = participants,
            summary = ambiguous and "The bounty target was destroyed; reward delivery needs review."
                or "The bounty target was destroyed and eligible pilots were paid."},
            lastError = ambiguous and "reward_delivery_ambiguous" or nil,
            repairRequired = ambiguous and "One or more bounty rewards cannot be proven." or nil})
    if not ambiguous then terminate() end
end

function BountyAmbush.secure()
    return {eventId = self.eventId, bossId = self.bossId}
end

function BountyAmbush.restore(data)
    if type(data) ~= "table" then return end
    self.eventId = data.eventId
    self.bossId = data.bossId
end

return BountyAmbush
