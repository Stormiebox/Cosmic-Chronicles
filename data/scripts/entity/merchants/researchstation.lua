package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("relations")

local CC_ResearchStation = {}

function CC_ResearchStation.initUI()
    ScriptUI():registerInteraction("Turn in Encrypted Log Fragment"%_t, "onTurnInLogFragment")
end

function CC_ResearchStation.onTurnInLogFragment()
    local dialog = {}
    dialog.text = "You have an Encrypted Log Fragment? These are incredibly rare... they usually contain telemetry from ships that encountered spatial anomalies or rogue AI constructs. We will pay handsomely for this data."%_t
    
    local player = Player()
    local fragments = player:getValue("cc_log_fragments") or 0
    
    if fragments > 0 then
        dialog.answers = {
            {answer = "Here is 1 Encrypted Log Fragment. (Receive 1,000,000 Credits)"%_t, onSelect = "onPayFragment"},
            {answer = "I'll hold onto it for now."%_t}
        }
    else
        dialog.answers = {
            {answer = "I don't have any right now."%_t}
        }
    end
    
    ScriptUI():showDialog(dialog)
end

function CC_ResearchStation.onPayFragment()
    invokeServerFunction("payFragmentServer")
end

function CC_ResearchStation.payFragmentServer()
    local player = Player(callingPlayer)
    if not player then return end
    
    local fragments = player:getValue("cc_log_fragments") or 0
    if fragments < 1 then return end
    
    -- Consume 1 fragment
    player:setValue("cc_log_fragments", fragments - 1)
    
    -- %_T (not %_t): needed for the "%1%" placeholder to resolve to the money argument.
    player:receive("Received %1% Credits for Encrypted Log Fragment."%_T, 1000000)
    
    -- Grant relations
    local station = Entity()
    local faction = Faction(station.factionIndex)
    if faction then
        local repTarget = player
        if player.craft and player.craft.factionIndex then
            local craftFaction = Faction(player.craft.factionIndex)
            if craftFaction then repTarget = craftFaction end
        end
        changeRelations(repTarget, faction, 1500, RelationChangeType.General)
    end
end

-- Inject into vanilla namespace
local CC_old_initUI = ResearchStation.initUI
function ResearchStation.initUI(...)
    if CC_old_initUI then CC_old_initUI(...) end
    CC_ResearchStation.initUI()
end

function ResearchStation.onTurnInLogFragment(...)
    return CC_ResearchStation.onTurnInLogFragment(...)
end

function ResearchStation.onPayFragment(...)
    return CC_ResearchStation.onPayFragment(...)
end

function ResearchStation.payFragmentServer(...)
    return CC_ResearchStation.payFragmentServer(...)
end

callable(ResearchStation, "payFragmentServer")

-- Do NOT return a table at the end of this script to avoid VFM crashes!
