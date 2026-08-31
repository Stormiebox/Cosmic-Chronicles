if onServer() then
    local CosmicVaultDialogue = include("cosmicvaultdialogue")
    include("stringutility")

    local cw_success = pcall(include, "cosmicwarbridge")

    -- Cosmic Chronicles: append a context-aware "Captain's Log" line to every background
    -- command's yield message, same-path override so it composes with Cosmic Overhaul's
    -- own Simulation.makeCommand wrapper regardless of mod load order (see modinfo.lua
    -- dependency on Cosmic Overhaul; that mod's wrapper is captured as "original" below).
    local cc_Simulation_makeCommand_original = Simulation.makeCommand
    function Simulation.makeCommand(...)
        local command = cc_Simulation_makeCommand_original(...)

        local originalAddYield = command.addYield
        command.addYield = function(self, message, money, resources, items)
            local context = {}

            if self.area and self.area.lower then
                local x = math.floor((self.area.lower.x + self.area.upper.x) / 2)
                local y = math.floor((self.area.lower.y + self.area.upper.y) / 2)
                context.distanceToCenter = math.sqrt(x * x + y * y)

                local nearestFaction = Galaxy():getNearestFaction(x, y)
                if nearestFaction then
                    local parentFaction = getParentFaction()
                    context.reputation = parentFaction:getRelations(nearestFaction.index)

                    if cw_success and CosmicWarBridge and CosmicWarBridge.getFactionWarHeat then
                        local rawHeat = CosmicWarBridge.getFactionWarHeat(nearestFaction.index) or 0
                        context.warHeat = math.floor(rawHeat * 100)
                    end
                end
            end

            local log = CosmicVaultDialogue.getValidLine("captain_log", context)
            if log then
                -- Use a compound Format object so we don't break the C++ deferred translation of the original message
                message = Format("%1%\n\n%2%\n\"%3%\""%_T, message or "", "Captain's Log:"%_T, log)
            end

            originalAddYield(self, message, money, resources, items)
        end

        return command
    end
end
