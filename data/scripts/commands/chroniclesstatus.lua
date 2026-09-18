local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"
local PLAYER_CONTROLLER = "data/scripts/player/background/cc_player_controller.lua"

local function reply(player, message)
    player:sendChatMessage("Cosmic Chronicles", 0, message)
end

local function tableCount(values)
    local result = 0
    for _ in pairs(values or {}) do result = result + 1 end
    return result
end

function execute(sender, commandName, ...)
    local player = Player(sender)
    if not player then return 0, "", "" end
    local status, snapshot, errorCode = Galaxy():invokeFunction(COORDINATOR, "getSnapshot")
    if status ~= 0 or not snapshot then
        reply(player, "Chronicle coordinator unavailable: " .. tostring(errorCode or status))
        return 0, "", ""
    end

    local health = snapshot.health or {}
    local cursors = snapshot.sourceCursors or {}
    local migration = snapshot.migration or {}
    reply(player, string.format(
        "News: %s | Dialogue: %s | Feed revision: %s | Migration: %s",
        tostring(health.newsManager or "unknown"),
        tostring(health.dialogueManager or "unknown"),
        tostring(cursors.newsRevision or 0),
        tostring(migration.state or "unknown")))
    local eventStates = snapshot.eventStates or {}
    reply(player, string.format(
        "Events — pending: %d, prepared: %d, active: %d, repair: %d",
        eventStates.pending or 0, eventStates.prepared or 0,
        eventStates.active or 0, eventStates.repair_required or 0))
    local playerStatus, personal, personalError = player:invokeFunction(PLAYER_CONTROLLER,
        "getPlayerSnapshot", player.index)
    if playerStatus == 0 and personal then
        local news = personal.news or {}
        reply(player, string.format("Personal — unread: %d, followed threads: %d, saved leads: %d",
            personal.unreadCount or 0,
            tableCount(news.followedThreads), tableCount(personal.leads)))
    elseif personalError then
        reply(player, "Personal Chronicle state unavailable: " .. tostring(personalError))
    end
    if snapshot.repairRequired or next(snapshot.blocked or {}) then
        reply(player, "Administrative review is required. An administrator can use /chroniclesrepair scan all.")
    end
    return 0, "", ""
end

function getDescription()
    return "Shows the canonical Cosmic Chronicles service and event status."
end

function getHelp()
    return "/chroniclesstatus"
end
