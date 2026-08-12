package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")
include("stringutility")
include("relations")

-- namespace CosmicChroniclesRefugee
CosmicChroniclesRefugee = {}
local helped = false

function CosmicChroniclesRefugee.interactionPossible(playerIndex, option)
    if helped then return false end
    
    local player = Player(playerIndex)
    if not player then return false end
    local craft = player.craft
    if not craft then return false end
    if craft:getNearestDistance(Entity()) > 50 then return false end
    
    return true
end

function CosmicChroniclesRefugee.initUI()
    ScriptUI():registerInteraction("Offer Assistance"%_t, "onInteract")
end

function CosmicChroniclesRefugee.onInteract()
    ScriptUI():showDialog(CosmicChroniclesRefugee.getDialog())
end

function CosmicChroniclesRefugee.getDialog()
    local dialog = {}
    dialog.text = "Thank the stars you stopped! We barely escaped the last sector and our engines are damaged. We are critically low on supplies. Do you have any Food or Medical Supplies to spare?"%_t
    dialog.answers = {}

    local player = Player()
    local ship = player.craft

    if ship and ship:hasComponent(ComponentType.CargoBay) then
        local food = ship:getCargoAmount("Food")
        local meds = ship:getCargoAmount("Medical Supplies")

        if food >= 50 then
            table.insert(dialog.answers, {answer = "Here is 50 Food."%_t, onSelect = "onDonateFood"})
        end
        if meds >= 50 then
            table.insert(dialog.answers, {answer = "Here is 50 Medical Supplies."%_t, onSelect = "onDonateMeds"})
        end
    end

    if #dialog.answers == 0 then
        table.insert(dialog.answers, {answer = "I'm sorry, I don't have anything to spare right now."%_t})
    else
        table.insert(dialog.answers, {answer = "I can't help you right now."%_t})
    end

    return dialog
end

function CosmicChroniclesRefugee.onDonateFood() invokeServerFunction("donate", "Food", 50) end
function CosmicChroniclesRefugee.onDonateMeds() invokeServerFunction("donate", "Medical Supplies", 50) end

function CosmicChroniclesRefugee.donate(goodName, amount)
    if not onServer() then return end
    if helped then return end

    -- SECURITY PATCH: Prevent ACE (Arbitrary Code Execution) vulnerability where clients can send negative amounts or invalid goods
    if goodName ~= "Food" and goodName ~= "Medical Supplies" then return end
    if type(amount) ~= "number" or amount <= 0 then return end

    local player = Player(callingPlayer)
    local entity = Entity()
    local ship = player.craft
    if not ship or not ship:hasComponent(ComponentType.CargoBay) then return end
    if ship:getNearestDistance(entity) > 50 then 
        invokeClientFunction(player, "tooFar")
        return 
    end

    if ship:getCargoAmount(goodName) >= amount then
        ship:removeCargo(goodName, amount)
        helped = true

        -- Balanced from 10000 relation gain to 2500
        local faction = Faction(entity.factionIndex)
        local repTarget = Faction(ship.factionIndex) or player
        if faction then changeRelations(repTarget, faction, 2500, RelationChangeType.General) end

        -- Cosmic Overhaul Synergy: Merchants and Smugglers extract monetary value from the crisis
        local captain = ship:getCaptain()
        if captain then
            local CaptainClass = include("captainclass")
            if captain:hasClass(CaptainClass.Merchant) then
                -- Balanced from 75k to 50k
                repTarget:receive("Hazard Pay"%_t, 50000)
                player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Your Merchant captain negotiated a 50,000 credit hazard pay fee for the supplies."%_T)
            elseif captain:hasClass(CaptainClass.Smuggler) then
                -- Balanced from 100k to 75k
                repTarget:receive("Smuggled Goods"%_t, 75000)
                player:sendChatMessage("Ship Computer"%_T, ChatMessageType.Information, "Your Smuggler captain quietly skimmed 75,000 credits worth of valuables from the refugee convoy during the transfer."%_T)
            end
        end

        local context = { warHeat = 100 }
        local rumor = CosmicVaultDialogue.getValidLine("rumor", context) or "The enemy is ruthless... stay safe out there."%_T

        invokeClientFunction(player, "showThanksDialog", rumor)
        deferredCallback(10, "jumpAway") -- Jump to safety after 10 seconds
    end
end
callable(CosmicChroniclesRefugee, "donate")

function CosmicChroniclesRefugee.showThanksDialog(rumor)
    if not onClient() then return end
    local text = "Thank you so much! You saved our lives. By the way, be careful... ${rumor}"%_t % {rumor = rumor}
    local dialog = {text = text, answers = {{answer = "Safe travels."%_t}}}
    ScriptUI():showDialog(dialog)
end

function CosmicChroniclesRefugee.jumpAway()
    if onServer() then
        Sector():deleteEntityJumped(Entity())
    end
end

function CosmicChroniclesRefugee.tooFar()
    local dialog = {}
    dialog.text = "You're too far away. Come closer so we can transfer the supplies."%_t
    ScriptUI():showDialog(dialog, false)
end

return CosmicChroniclesRefugee
