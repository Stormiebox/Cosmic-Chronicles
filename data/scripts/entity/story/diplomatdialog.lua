-- Migration shim for pre-v4 stranded diplomats.
function initialize()
    if onServer() then Entity():addScriptOnce("data/scripts/entity/cc_diplomat.lua") end
    terminate()
end
