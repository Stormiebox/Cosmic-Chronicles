local COORDINATOR = "data/scripts/galaxy/cc_coordinator.lua"

local function reply(player, message)
    player:sendChatMessage("Chronicles Repair", 0, message)
end

local function invoke(functionName, ...)
    local status, result, errorCode = Galaxy():invokeFunction(COORDINATOR, functionName, ...)
    if status ~= 0 then return nil, "coordinator_unavailable" end
    return result, errorCode
end

function execute(sender, commandName, ...)
    local player = Player(sender)
    if not player then return 0, "", "" end
    if not Server():hasAdminPrivileges(player) then
        reply(player, "Administrator privileges are required.")
        return 0, "", ""
    end

    local args = {...}
    local operation = string.lower(tostring(args[1] or "status"))
    if operation == "scan" then
        local scope = string.lower(tostring(args[2] or "all"))
        local playerIndex
        if scope == "player" then
            playerIndex = tonumber(args[3])
            if not playerIndex then
                reply(player, "Usage: /chroniclesrepair scan player <index>")
                return 0, "", ""
            end
        end
        local scan, scanError = invoke("scanRepair", scope, playerIndex)
        if not scan then
            reply(player, "Scan failed: " .. tostring(scanError))
            return 0, "", ""
        end
        reply(player, string.format("Dry-run %s found %d item(s). No state was changed.",
            scan.repairId, #(scan.findings or {})))
        for _, finding in ipairs(scan.findings or {}) do
            reply(player, string.format("%s [%s]: %s | actions: %s",
                tostring(finding.kind), tostring(finding.itemId), tostring(finding.evidence),
                table.concat(finding.permittedActions or {}, ", ")))
        end
    elseif operation == "status" then
        local scan, statusError = invoke("getRepairStatus", args[2])
        if not scan then
            reply(player, "Status failed: " .. tostring(statusError))
            return 0, "", ""
        end
        reply(player, string.format("%s is %s with %d finding(s).",
            scan.repairId, scan.state, #(scan.findings or {})))
    elseif operation == "history" then
        local history, historyError = invoke("getRepairHistory", args[2])
        if not history then
            reply(player, "History failed: " .. tostring(historyError))
            return 0, "", ""
        end
        if #history == 0 then reply(player, "No matching repair history.") end
        for _, entry in ipairs(history) do
            reply(player, string.format("%s: %s by player %s (%s)", tostring(entry.at),
                tostring(entry.action), tostring(entry.actor), tostring(entry.result)))
        end
    elseif operation == "apply" then
        local repairId = args[2]
        local action = args[3] and string.lower(tostring(args[3]))
        if not repairId or not action then
            reply(player, "Usage: /chroniclesrepair apply <repairId> <resume|retry|mark-complete|reissue|abandon>")
            return 0, "", ""
        end
        local result, applyError = invoke("applyRepair", repairId, action, sender)
        if not result then
            reply(player, "Apply failed: " .. tostring(applyError))
            return 0, "", ""
        end
        reply(player, string.format("%s applied to %s: %s", action, repairId,
            tostring(result.result)))
    else
        reply(player, "Usage: /chroniclesrepair <scan|status|apply|history> ...")
    end
    return 0, "", ""
end

function getDescription()
    return "Dry-run scanning and revision-checked repair for Cosmic Chronicles. Administrator only."
end

function getHelp()
    return "/chroniclesrepair scan [all|news|player <index>|events|interactions|dialogue|queues]\n"
        .. "/chroniclesrepair status [repairId]\n"
        .. "/chroniclesrepair apply <repairId> <resume|retry|mark-complete|reissue|abandon>\n"
        .. "/chroniclesrepair history [repairId]"
end

