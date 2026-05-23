package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("cosmicvaultdialogue")

-- namespace CosmicChroniclesRefugee
CosmicChroniclesRefugee = {}
local helped = false

function CosmicChroniclesRefugee.interactionPossible(playerIndex, option)
    if helped then return false end
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

    local player = Player(callingPlayer)
    local ship = player.craft
    if not ship or not ship:hasComponent(ComponentType.CargoBay) then return end

    if ship:getCargoAmount(goodName) >= amount then
        ship:removeCargo(goodName, amount)
        helped = true

        local faction = Faction(Entity().factionIndex)
        if faction then Galaxy():changeFactionRelations(player.index, faction.index, 10000) end

        local context = { warHeat = 100 }
        local rumor = CosmicVaultDialogue.getValidLine("rumor", context) or "The enemy is ruthless... stay safe out there."%_T

        invokeClientFunction(player, "showThanksDialog", rumor)
        deferredCallback(10, "jumpAway") -- Jump to safety after 10 seconds
    end
end
callable(CosmicChroniclesRefugee, "donate")

function CosmicChroniclesRefugee.showThanksDialog(rumor)
    if not onClient() then return end
    local text = "Thank you so much! You saved our lives. By the way, be careful... ${rumor}"%_t % {rumor = rumor%_t}
    local dialog = {text = text, answers = {{answer = "Safe travels."%_t}}}
    ScriptUI():showDialog(dialog)
end

function CosmicChroniclesRefugee.jumpAway()
    if not onServer() then return end
    Entity():addScriptOnce("entity/utility/delayedjump.lua", 2)
end