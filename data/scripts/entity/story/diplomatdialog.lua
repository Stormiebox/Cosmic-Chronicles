package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
include("callable")

function interactionPossible(playerIndex, option)
    return true
end

function initUI()
    ScriptUI():registerInteraction("Open Comm Link", "onInteract")
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
    d0.text = "Thank the stars! My escort was ambushed by hostiles. I am a high-ranking diplomat and I require immediate extraction. If you can take me aboard and get me out of this sector, I will see you properly compensated."
    
    d0.answers = { {answer = "Dock your pod. We'll get you out of here.", onSelect = "triggerStandardPayout"} }
    
    if hasMerchant then
        table.insert(d0.answers, {answer = "[Merchant] This is an active warzone. My hazard pay rate just went up 200%. Take it or leave it.", onSelect = "triggerMerchantPayout"})
    end
    
    if hasSmuggler then
        table.insert(d0.answers, {answer = "[Smuggler] We can bypass local patrols if we forge a new transponder identity for your pod. Let's make a deal.", onSelect = "triggerSmugglerPayout"})
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

callable(nil, "triggerServerPayout")
function triggerServerPayout(tier)
    local entity = Entity()
    local player = Player(callingPlayer)
    local sector = Sector()
    
    if tier == 1 then
        player:sendChatMessage("Diplomat", 0, "I've transferred standard extraction fees to your account. Let's move!")
        player:receive("Received %1% Credits for VIP Extraction.", 150000)
    elseif tier == 2 then
        player:sendChatMessage("Diplomat", 0, "You're bleeding me dry, but I don't have a choice! Hazard pay transferred.")
        player:receive("Received %1% Credits for VIP Extraction.", 450000)
    elseif tier == 3 then
        player:sendChatMessage("Diplomat", 0, "I'll turn a blind eye to your... less than legal operations in exchange for this escape route.")
        player:receive("Received %1% Credits for VIP Extraction.", 100000)
        
        -- Smuggler bonus: Illegal Goods (e.g. 50x Unbranded Weapons or similar)
        -- Since adding specific cargo safely requires more logic, we can just drop a high rarity system upgrade as a "bribe"
        local UpgradeGenerator = include("upgradegenerator")
        local upgrade = UpgradeGenerator():generateSectorSystem(sector:getCoordinates(), 0, Rarity(RarityType.Exotic))
        sector:dropUpgrade(entity.translationf, nil, nil, upgrade)
        player:sendChatMessage("Smuggler", 0, "They threw in some highly illegal tech as a bribe to keep our mouths shut.")
    end
    
    -- Visual warp out
    sector:createHyperspaceAnimation(entity, entity.translationf, ColorRGB(0.2, 0.8, 0.2), 1.0)
    sector:deleteEntity(entity)
end
