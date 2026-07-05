package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
include("callable")

function interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    
    -- Must be within 50 units (500m) to dock/board
    if craft:getNearestDistance(Entity()) > 50 then return false end
    
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

function triggerServerPayout(tier)
    local entity = Entity()
    local player = Player(callingPlayer)
    if not player then return end
    
    local craft = player.craft
    if not craft then return end
    
    -- Multiplayer Exploit Fix: Verify distance on the server
    if craft:getNearestDistance(entity) > 50 then 
        return 
    end
    
    -- Exploit Fix: Verify captain class on the server for special tiers
    local captain = craft:getCaptain()
    if tier == 2 and (not captain or not captain:hasClass(CaptainClass.Merchant)) then return end
    if tier == 3 and (not captain or not captain:hasClass(CaptainClass.Smuggler)) then return end
    
    local sector = Sector()
    local faction = Faction(craft.factionIndex)
    if not faction then return end
    
    if tier == 1 then
        player:sendChatMessage("Diplomat", 0, "I've transferred standard extraction fees to your account. Let's move!")
        faction:receive("Received %1% Credits for VIP Extraction.", 150000)
    elseif tier == 2 then
        player:sendChatMessage("Diplomat", 0, "You're bleeding me dry, but I don't have a choice! Hazard pay transferred.")
        faction:receive("Received %1% Credits for VIP Extraction.", 450000)
    elseif tier == 3 then
        player:sendChatMessage("Diplomat", 0, "I'll turn a blind eye to your... less than legal operations in exchange for this escape route.")
        faction:receive("Received %1% Credits for VIP Extraction.", 100000)
        
        -- Smuggler bonus: Illegal Goods (e.g. 50x Unbranded Weapons or similar)
        -- Since adding specific cargo safely requires more logic, we can just drop a high rarity system upgrade as a "bribe"
        local UpgradeGenerator = include("upgradegenerator")
        local x, y = sector:getCoordinates()
        local upgrade = UpgradeGenerator():generateSectorSystem(x, y, 0, Rarity(RarityType.Exotic))
        sector:dropUpgrade(entity.translationf, faction, nil, upgrade)
        player:sendChatMessage("Smuggler", 0, "They threw in some highly illegal tech as a bribe to keep our mouths shut.")
    end
    
    -- Visual warp out
    entity:addScriptOnce("deletejumped.lua")
end

callable(nil, "triggerServerPayout")
