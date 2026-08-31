package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local CaptainClass = include("captainclass")
include("callable")
include("utility")


function interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    if craft:getNearestDistance(Entity()) > 500 then return false end
    return true
end

function initUI()
    ScriptUI():registerInteraction("Board & Investigate"%_t, "onInteract")
end

function onInteract()
    ScriptUI():showDialog(Dialog())
end

function Dialog()
    local player = Player()
    local craft = player.craft

    local hasScavenger = false
    local hasExplorer = false

    if craft then
        local captain = craft:getCaptain()
        if captain then
            if captain:hasClass(CaptainClass.Scavenger) then hasScavenger = true end
            if captain:hasClass(CaptainClass.Explorer) then hasExplorer = true end
        end
    end

    local d0 = {}
    d0.text = "[CORRUPTED LOG ENTRY] ...it's not radiation. It's whispering. The bulkheads are singing to us... [STATIC] ...Jenkins opened the airlock just to hear them better. We can't stop the humming. I'm taking the ship offline."%_t

    d0.answers = { {answer = "Salvage what's left and leave."%_t, onSelect = "triggerStandardLoot"} }

    if hasScavenger then
        table.insert(d0.answers, {answer = "[Scavenger] Bypass the corrupted locks and crack the hidden smuggler holds!"%_t, onSelect = "triggerScavengerLoot"})
    end

    if hasExplorer then
        table.insert(d0.answers, {answer = "[Explorer] Isolate the nav-computer and decrypt its recent jump coordinates!"%_t, onSelect = "triggerExplorerLoot"})
    end

    return d0
end

function triggerStandardLoot()
    if onClient() then invokeServerFunction("triggerServerLoot", 1); return end
end
function triggerScavengerLoot()
    if onClient() then invokeServerFunction("triggerServerLoot", 2); return end
end
function triggerExplorerLoot()
    if onClient() then invokeServerFunction("triggerServerLoot", 3); return end
end

function triggerServerLoot(lootTier)
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

    if entity:getValue("cc_loot_triggered") then return end

    -- Exploit Fix: Verify captain class on the server for special tiers
    -- (checked before setting the flag below, otherwise a mismatched-tier call
    -- would permanently soft-lock this cache without paying out anything)
    local captain = craft:getCaptain()
    if lootTier == 2 and (not captain or not captain:hasClass(CaptainClass.Scavenger)) then return end
    if lootTier == 3 and (not captain or not captain:hasClass(CaptainClass.Explorer)) then return end

    entity:setValue("cc_loot_triggered", true)

    local sector = Sector()
    local faction = Faction(craft.factionIndex)
    if not faction then return end

    if lootTier == 1 then
        player:sendChatMessage("Crew"%_t, 0, "We recovered some credits and loose cargo, but this place gives me the creeps."%_t)
        faction.money = faction.money + 25000
        player:sendChatMessage("Ship Computer"%_t, ChatMessageType.Information, "Salvaged 25,000 Credits from Ghost Ship."%_t)
    elseif lootTier == 2 then
        player:sendChatMessage("Scavenger"%_t, 0, "Jackpot! They had a shielded under-deck completely untouched by whatever hit them."%_t)
        faction.money = faction.money + 125000
        player:sendChatMessage("Ship Computer"%_t, ChatMessageType.Information, "Salvaged 125,000 Credits from Ghost Ship."%_t)
    elseif lootTier == 3 then
        player:sendChatMessage("Explorer"%_t, 0, "I've successfully pulled their last known jump coordinates. We found the anomaly's exact location, transferring data bounty!"%_t)
        faction.money = faction.money + 100000
        player:sendChatMessage("Ship Computer"%_t, ChatMessageType.Information, "Salvaged 100,000 Credits from Ghost Ship."%_t)
    end
    
    local pos = entity.translationf
    local radius = entity.radius or 50
    broadcastInvokeClientFunction("spawnExplosion", pos, radius)
    Sector():removeScript("events/cc_ghostship.lua")
    sector:deleteEntity(entity)
end

function spawnExplosion(pos, radius)
    if onServer() then return end
    Sector():createExplosion(pos, radius, false)
end

callable(nil, "triggerServerLoot")

function tooFar()
    local dialog = {}
    dialog.text = "You're too far away. Come closer to interface."%_t
    ScriptUI():interactShowDialog(dialog, true)
end

