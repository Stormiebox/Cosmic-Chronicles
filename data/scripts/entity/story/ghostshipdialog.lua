-- Migration shim for pre-v4 ghost ships.
function initialize()
    if onServer() then Entity():addScriptOnce("data/scripts/entity/cc_ghostship.lua") end
    terminate()
end
