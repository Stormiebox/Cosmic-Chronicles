local CosmicVaultDialogue = include("cosmicvaultdialogue")

if not Command then Command = {} end
local cc_old_sendMail = Command.sendMail

-- Intercept the vanilla/Cosmic Overhaul mail dispatcher
function Command:sendMail(sender, header, text, formatArgs, items)
    formatArgs = formatArgs or {}

    -- Try to fetch a relevant captain's log
    local log = CosmicVaultDialogue.getValidLine("captain_log", {})

    if log then
        -- Avorion mail requires format string parameters for translations to work correctly
        text = text .. "\n\n${ccLogHeader}\n\"${ccLogText}\""
        formatArgs.ccLogHeader = "Captain's Log:"%_T
        formatArgs.ccLogText = log
    end

    if cc_old_sendMail then
        cc_old_sendMail(self, sender, header, text, formatArgs, items)
    end
end