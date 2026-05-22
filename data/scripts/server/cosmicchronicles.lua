package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/server/?.lua"

-- Always use include() in Avorion to ensure mod extensions are loaded correctly
include("cosmicvaultdialogue")

-- namespace CosmicChronicles
CosmicChronicles = {}

function CosmicChronicles.initialize()
    -- Ensure this dialogue population only runs in the server VM
    if onServer() then
        CosmicChronicles.registerLore()
    end
end

function CosmicChronicles.registerLore()
    -- Ambient: Dock workers complaining (shows to almost anyone, generic rep)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Careful around the docking bays, section 4 lost gravity plating again.",
        conditions = {
            minReputation = -10000
        }
    })

    -- Ambient: Generic trader chat (requires neutral or better rep)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Another load of Energy Cells, another day closer to retirement.",
        conditions = {
            minReputation = 0
        }
    })

    -- Rumor: Aggressive faction preparing for war
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I heard the local military is mobilizing. War heat is off the charts.",
        conditions = {
            minWarHeat = 75,
            factionTrait = "aggressive"
        }
    })

    -- Rumor: Smugglers (only players with good rep hear this tip)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Smugglers have been using the asteroid fields near the inner barrier again. Keep your cargo hidden.",
        conditions = {
            minReputation = 10000
        }
    })

    -- Rumor: Xsotan activity (Universal, almost anyone hears it)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "They say the Xsotan are getting bolder in the outer rim...",
        conditions = { }
    })
end