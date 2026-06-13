package.path = package.path .. ";data/scripts/lib/?.lua"

include("utility")

function initialize()
    if onClient() then
        Player():registerCallback("onCosmicCodexGatherData", "onCosmicCodexGatherData")
    end
end

function onCosmicCodexGatherData()
    include("codex/infoCc")
    infoCc_injectToCodex()
end
