-- One-release migration shim. Existing saves may restore this script's old secure state
-- before the v2 Chronicle coordinator is attached. It deliberately performs no simulation,
-- publishing, reward, or economy work.

-- namespace CosmicChroniclesNewsGenerator
CosmicChroniclesNewsGenerator = {}

local reportedBosses = {}
local knownActiveFactions = {}

function CosmicChroniclesNewsGenerator.initialize()
end

function CosmicChroniclesNewsGenerator.exportLegacyState()
    local bosses = {}
    local factions = {}
    for key, value in pairs(reportedBosses or {}) do bosses[key] = value end
    for key, value in pairs(knownActiveFactions or {}) do factions[key] = value end
    return {
        schemaVersion = 1,
        reportedBosses = bosses,
        knownActiveFactions = factions,
    }
end

function CosmicChroniclesNewsGenerator.secure()
    return CosmicChroniclesNewsGenerator.exportLegacyState()
end

function CosmicChroniclesNewsGenerator.restore(data)
    if type(data) ~= "table" then return end
    reportedBosses = type(data.reportedBosses) == "table" and data.reportedBosses or {}
    knownActiveFactions = type(data.knownActiveFactions) == "table" and data.knownActiveFactions or {}
end

