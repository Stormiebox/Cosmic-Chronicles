-- Capture the vanilla init call
local CosmicChronicles_old_init = initialize

function initialize(...)
    if CosmicChronicles_old_init then CosmicChronicles_old_init(...) end

    if onServer() then
        local entity = Entity()
        if entity.isStation then
            entity:addScriptOnce("entity/cosmicchronicles_rumormonger.lua")
        end
    end
end
