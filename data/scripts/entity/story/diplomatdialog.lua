package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
include("callable")

local paidOut = false

function interactionPossible(playerIndex, option)
    if paidOut then return false end

    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end

    -- Must be within 500 units to dock/board
    if craft:getNearestDistance(Entity()) > 500 then return false end

    return true
end

function initUI()
    ScriptUI():registerInteraction("Open Comm Link"%_t, "onInteract")
end

function onInteract()
    ScriptUI():showDialog(Dialog())
end

function Dialog()
    local player = Player()
    local craft = player.craft

    local hasMerchant = false
    local hasSmuggler = false

    if craft then
        local captain = craft:getCaptain()
        if captain then
            if captain:hasClass(CaptainClass.Merchant) then hasMerchant = true end
            if captain:hasClass(CaptainClass.Smuggler) then hasSmuggler = true end
        end
    end

    local d0 = {}
    d0.text = "Thank the stars! My escort was ambushed by hostiles. I am a high-ranking diplomat and I require immediate extraction. If you can take me aboard and get me out of this sector, I will see you properly compensated."%_t

    -- This base answer is always present, regardless of captain/class - a player
    -- with no captain, or a captain with no class, must still be able to complete
    -- the rescue for the (lower) standard reward. Only the two bonus answers below
    -- are conditional on a specific captain class.
    d0.answers = { {answer = "Dock your pod. We'll get you out of here."%_t, onSelect = "triggerStandardPayout"} }

    if hasMerchant then
        table.insert(d0.answers, {answer = "[Merchant] This is an active warzone. My hazard pay rate just went up 200%. Take it or leave it."%_t, onSelect = "triggerMerchantPayout"})
    end

    if hasSmuggler then
        table.insert(d0.answers, {answer = "[Smuggler] We can bypass local patrols if we forge a new transponder identity for your pod. Let's make a deal."%_t, onSelect = "triggerSmugglerPayout"})
    end

    return d0
end

function triggerStandardPayout()
    if onClient() then invokeServerFunction("triggerServerPayout", 1); return end
end
function triggerMerchantPayout()
    if onClient() then invokeServerFunction("triggerServerPayout", 2); return end
end
function triggerSmugglerPayout()
    if onClient() then invokeServerFunction("triggerServerPayout", 3); return end
end

function triggerServerPayout(tier)
    -- Exploit Fix: deletejumped.lua takes ~4.5s to actually remove the entity, so without
    -- this flag a player could re-open the dialog and spam-click a payout option during
    -- that window to collect the reward multiple times.
    if paidOut then return end

    local entity = Entity()
    local player = Player(callingPlayer)
    if not player then return end

    local craft = player.craft
    if not craft then return end

    -- Multiplayer Exploit Fix: Verify distance on the server
    if craft:getNearestDistance(entity) > 500 then
        invokeClientFunction(player, "tooFar")
        return
    end

    -- Exploit Fix: Verify captain class on the server for special tiers.
    -- Tier 1 (standard payout) is deliberately NOT gated here - a player with no
    -- captain at all, or a captain of no class, must still be able to complete the
    -- rescue and receive the (lower) standard reward. Do not add a captain
    -- requirement to the tier == 1 path; only tiers 2/3 are class-gated bonuses.
    local captain = craft:getCaptain()
    if tier == 2 and (not captain or not captain:hasClass(CaptainClass.Merchant)) then return end
    if tier == 3 and (not captain or not captain:hasClass(CaptainClass.Smuggler)) then return end

    paidOut = true

    local sector = Sector()
    local buyer = player
    if craft.factionIndex == player.allianceIndex then
        buyer = Alliance(player.allianceIndex)
    end

    if tier == 1 then
        player:sendChatMessage("Diplomat"%_t, 0, "I've transferred standard extraction fees to your account. Let's move!"%_t)
        buyer:receive("Extraction fee.", 150000)
    elseif tier == 2 then
        player:sendChatMessage("Diplomat"%_t, 0, "You're bleeding me dry, but I don't have a choice! Hazard pay transferred."%_t)
        buyer:receive("Hazard pay.", 450000)
    elseif tier == 3 then
        player:sendChatMessage("Diplomat"%_t, 0, "I'll turn a blind eye to your... less than legal operations in exchange for this escape route."%_t)
        buyer:receive("Diplomat's payoff.", 100000)

        -- Smuggler bonus: Illegal Goods (e.g. 50x Unbranded Weapons or similar)
        -- Since adding specific cargo safely requires more logic, we can just drop a high rarity system upgrade as a "bribe"
        local UpgradeGenerator = include("upgradegenerator")
        local x, y = sector:getCoordinates()
        -- generateSectorSystem(x, y, rarity_in, rarities_in) -- the 4th arg is only for a
        -- weighted distribution table; a single desired Rarity goes in the 3rd (rarity_in).
        local upgrade = UpgradeGenerator():generateSectorSystem(x, y, Rarity(RarityType.Exotic))
        sector:dropUpgrade(entity.translationf, buyer, nil, upgrade)
        player:sendChatMessage("Smuggler"%_t, 0, "They threw in some highly illegal tech as a bribe to keep our mouths shut."%_t)
    end

    -- Visual warp out
    entity:addScriptOnce("deletejumped.lua")
end

callable(nil, "triggerServerPayout")

function tooFar()
    local dialog = {}
    dialog.text = "You're too far away. Come closer so we can dock."%_t
    ScriptUI():interactShowDialog(dialog, true)
end
