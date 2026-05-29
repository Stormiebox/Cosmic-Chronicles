local cc_old_init = initialize

function initialize(...)
    if cc_old_init then cc_old_init(...) end

    if onServer() then
        Player():addScriptOnce("data/scripts/player/background/cc_event_controller.lua")
    end
end