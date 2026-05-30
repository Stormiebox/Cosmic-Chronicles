local CosmicVaultDialogue = include("cosmicvaultdialogue")
include("stringutility")

local cw_success = pcall(include, "cosmicwarbridge")

if not Command then Command = {} end
local cc_old_sendMail = Command.sendMail

-- Intercept the vanilla/Cosmic Overhaul mail dispatcher
function Command:sendMail(sender, header, text, formatArgs, items)
    formatArgs = formatArgs or {}
    local parentFaction = getParentFaction()

    -- Build the context for the dialogue API using the operation's location
    local context = {}
    if self.area and self.area.lower then
        local x = math.floor((self.area.lower.x + self.area.upper.x) / 2)
        local y = math.floor((self.area.lower.y + self.area.upper.y) / 2)
        context.distanceToCenter = math.sqrt(x * x + y * y)

        local nearestFaction = Galaxy():getNearestFaction(x, y)
        if nearestFaction then
            context.reputation = parentFaction:getRelations(nearestFaction.index)

            if cw_success and CosmicWarBridge and CosmicWarBridge.getFactionWarHeat then
                local rawHeat = CosmicWarBridge.getFactionWarHeat(nearestFaction.index) or 0
                context.warHeat = math.floor(rawHeat * 100)
            end
        end
    end

    -- Try to fetch a relevant captain's log
    local log = CosmicVaultDialogue.getValidLine("captain_log", context)

    if log then
        -- Use a compound Format object to safely append the log without breaking C++ deferred translations!
        local originalFormat = Format(text, formatArgs)
        local combinedFormat = Format("%1%\n\n%2%\n\"%3%\""%_T, originalFormat, "Captain's Log:"%_T, log)

        local mail = Mail()
        mail.text = combinedFormat
        mail.header = header
        mail.sender = sender
        if items then
            for _, item in pairs(items) do mail:addItem(item) end
        end

        parentFaction:addMail(mail)
    elseif cc_old_sendMail then
        cc_old_sendMail(self, sender, header, text, formatArgs, items)
    end
end