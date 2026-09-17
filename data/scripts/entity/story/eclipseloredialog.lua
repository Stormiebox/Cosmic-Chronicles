-- Migration shim for pre-v4 Eclipse lore entities.
function initialize()
    if onServer() then Entity():addScriptOnce("data/scripts/entity/cc_blackbox.lua") end
    terminate()
end
