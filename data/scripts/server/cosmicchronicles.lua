package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/server/?.lua"

-- Including Cosmic Vault's API dialogue
include("cosmicvaultdialogue")
include("stringutility")

-- namespace CosmicChronicles
CosmicChronicles = {}

function CosmicChronicles.initialize()
    -- Ensure this dialogue population only runs in the server VM
    if onServer() then
        CosmicChronicles.registerLore()
    end
end

function CosmicChronicles.registerLore()
    -- ==========================================
    -- CAPTAIN'S LOGS (COSMIC OVERHAUL SYNERGY)
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "captain_log",
        text = "The crew has been uneasy since the last jump. The scanners are picking up phantom signatures just outside sensor range. I've doubled the watch shifts."%_T,
        conditions = { minDistanceToCenter = 150 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "captain_log",
        text = "We passed a massive, ancient derelict drifting near the border today. It didn't match any known Xsotan or Faction profiles. We kept our distance."%_T,
        conditions = { minDistanceToCenter = 250 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "captain_log",
        text = "Operations are running smoothly, but the local military patrols have been aggressively scanning us. Tensions in this sector are palpable."%_T,
        conditions = { minWarHeat = 15 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "captain_log",
        text = "Found a hidden cache of smuggled goods floating near an asteroid field. I logged it in the manifest and told the crew to keep their mouths shut."%_T,
        conditions = { minReputation = 0 }
    })

    -- ==========================================
    -- ORIGINAL AMBIENT & RUMORS
    -- ==========================================
    -- Ambient: Dock workers complaining (shows to almost anyone, generic rep)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Careful around the docking bays, section 4 lost gravity plating again."%_T,
        conditions = {
            minReputation = 0
        }
    })

    -- Ambient: Generic trader chat (requires neutral or better rep)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Another load of Energy Cells, another day closer to retirement."%_T,
        conditions = {
            minReputation = 0
        }
    })

    -- Ambient: Miner complaining
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Another shift in the asteroid fields. At least the pay is decent."%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Security guard on duty
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Keep your ship's transponder active. We've had reports of smugglers in this sector."%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Off-duty pilot
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Just finished a long haul from the rim. The bar is calling my name."%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Station engineer
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "The main reactor is humming a bit louder than usual. I'm sure it's fine."%_T,
        conditions = { minReputation = 0 }
    })

    -- Rumor: Pirate activity
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Pirates have been getting bold, hitting trade convoys just a few sectors from here."%_T,
        conditions = { minReputation = -5000 }
    })

    -- Rumor: Economic boom
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "A new trade route just opened up. They say there are fortunes to be made in processor trading."%_T,
        conditions = { minReputation = 5000 }
    })

    -- Rumor: Strange signals
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Some deep space explorers picked up a repeating signal from a dead sector. No one knows what it is."%_T,
        conditions = { minDistanceToCenter = 300 }
    })

    -- Ambient: Casual station life
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "I swear, the replicator in section C makes everything taste like refined iron."%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Traffic control
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Clear the docking lanes! We've got a heavy freighter inbound with failing stabilizers!"%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Merchant haggling
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "I can't go any lower on the price! These turret parts are top quality!"%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Station announcement
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Attention: The shuttle to the inner sphere will be departing from Docking Port 7 in 15 minutes."%_T,
        conditions = { minReputation = 0 }
    })

    -- Rumor: Faction politics
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "The local faction leader is getting paranoid. They've doubled the security patrols."%_T,
        conditions = { factionTrait = "aggressive" }
    })

    -- Rumor: Lost technology
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I heard a rumor about a derelict research station from before the war, supposedly full of lost tech."%_T,
        conditions = { minReputation = 0 }
    })

    -- Rumor: Aggressive faction preparing for war
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I heard the local military is mobilizing. War heat is off the charts."%_T,
        conditions = {
            minWarHeat = 50,
            factionTrait = "aggressive"
        }
    })

    -- Rumor: Smugglers (only players with good rep hear this tip)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Smugglers have been using the asteroid fields near the inner barrier again. Keep your cargo hidden."%_T,
        conditions = {
            minReputation = 5000
        }
    })

    -- Rumor: Core galaxy myth
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "A scout came through babbling about giant alien structures near the center of the galaxy... probably space madness."%_T,
        conditions = { minDistanceToCenter = 200 }
    })

    -- Rumor: Xsotan activity (Universal, almost anyone hears it)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "They say the Xsotan are getting bolder in the outer rim..."%_T,
        conditions = { minReputation = 0 }
    })

    -- Ambient: Wealthy Faction
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "The luxury tax in this sector is absurd, but I guess it pays for the shiny stations."%_T,
        conditions = { factionWealth = "wealthy" }
    })

    -- Rumor: Wealthy Faction
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Rich folks around here are paying top credit for exotic goods. If you've got rare tech, now's the time to sell."%_T,
        conditions = { factionWealth = "wealthy" }
    })

    -- Ambient: Poor Faction
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Half the docking clamps are broken. They say the faction leadership has gone bankrupt."%_T,
        conditions = { factionWealth = "poor" }
    })

    -- Rumor: Poor Faction
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Scavengers are picking the local asteroid fields clean. The local economy is entirely reliant on scraps."%_T,
        conditions = { factionWealth = "poor" }
    })

    -- Ambient: Inner Core (Inside Barrier, Distance <= 150)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Living inside the barrier changes a man. The Avorion hums... you can almost hear it."%_T,
        conditions = { maxDistanceToCenter = 150 }
    })

    -- Ambient: Outer Rim (Distance >= 350)
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Out here on the rim, you gotta watch your own back. Nobody's coming to save you."%_T,
        conditions = { minDistanceToCenter = 350 }
    })

    -- ==========================================
    -- COSMIC WAR SYNERGY LORE
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Tensions are boiling over. I heard command is authorizing a Decapitation Strike if the enemy flagship shows its face."%_T,
        conditions = { minWarHeat = 65 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Keep your eyes on the bulletin boards. The military is handing out massive bounties for anyone willing to dive into the warzone."%_T,
        conditions = { minWarHeat = 15 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Diplomatic sanctions are bleeding the border sectors dry. It's getting harder to find anyone willing to trade across enemy lines."%_T,
        conditions = { factionTrait = "aggressive", minWarHeat = 20 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "A buddy of mine took a 'Force Recon' contract. Said the pay was good, but he hasn't been back in a week."%_T,
        conditions = { minWarHeat = 10 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Watch out for arms deals going down in deep space. Interrupting one could be profitable... or fatal."%_T,
        conditions = { minWarHeat = 15 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "The war pressure in this region is getting intense. It feels like one wrong move could ignite the whole sector."%_T,
        conditions = { minWarHeat = 40 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Some extremists tried to sabotage a peace envoy. If you see a diplomatic ship under fire, helping them out pays big in reputation."%_T,
        conditions = { minWarHeat = 15 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Civilian freighters are being ambushed by hunter fleets near the border. If you have the guns, the refugees need help."%_T,
        conditions = { minWarHeat = 30 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I saw massive strike fleets jumping into the active warzones. It's an absolute bloodbath out there."%_T,
        conditions = { minWarHeat = 50 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "There are whispers of a ceasefire, but only if the frontline commanders can swallow their pride."%_T,
        conditions = { minWarHeat = 55 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Prices are through the roof. Diplomatic sanctions are hurting us more than the actual fighting."%_T,
        conditions = { minWarHeat = 20, factionTrait = "aggressive" }
    })

    -- ==========================================
    -- COSMIC OVERHAUL SYNERGY LORE
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Keep your transponders clean. The Smuggler's Market is paying a huge premium for unbranded, illegal goods lately."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Ever since they overhauled the transporter block regulations, my cargo runners haven't had to physically dock to a station once."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Scrap limiters are gone, friend. You can spend all day in the scrapyards without command breathing down your neck, provided you buy the license."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I used to run the old trade lanes, but these days you need an escort fleet just to run a Scout operation through the inner barriers."%_T,
        conditions = { minWarHeat = 15 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I managed to unbrand some stolen tech modules. Cost a pretty penny, but the Smuggler's Market payout was worth it."%_T,
        conditions = { minReputation = 500 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "The Command Center terminal tracks every ship in the fleet now. Makes logistics a breeze, as long as the captains don't go rogue."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "Logistics is backed up again. The new shuttle volume capacity is great, but we still need more physical docking ports!"%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "I've been using the new universal bulletin board. It's so much easier to find work without having to dock at every single station."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "My captain says his new ship orders are persistent. He can finally finish a trade run without me having to re-issue the command every time I log in."%_T,
        conditions = { minReputation = 0 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "With the new factory overview, I finally figured out my energy cell plant was losing money. Switched it to solar panels and now I'm in the green."%_T,
        conditions = { minReputation = 5000 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "ambient",
        text = "It's nice that being friendly with a faction actually means something now. They're much more willing to help out an ally."%_T,
        conditions = { minReputation = 15000 }
    })

    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles",
        category = "rumor",
        text = "Don't ignore your friends for too long. Reputation isn't permanent anymore; you have to maintain those relationships."%_T,
        conditions = { minReputation = 0 }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: SHIPYARD
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We're backed up on hull plate welding for another three cycles. Logistics is a nightmare."%_T,
        conditions = { stationType = "shipyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Did you see the size of that dreadnought they laid down in dock 4? The faction is definitely gearing up for a strike."%_T,
        conditions = { stationType = "shipyard", minWarHeat = 20 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Captains always ask for more processing power, but never want to pay for the assembly cores..."%_T,
        conditions = { stationType = "shipyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I hear the chief architect was bribed to leak the blueprints of our new cruiser class to the enemy."%_T,
        conditions = { stationType = "shipyard", factionTrait = "aggressive" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "If you need a fast scout, the new interceptor frames just finished their stress testing."%_T,
        conditions = { stationType = "shipyard", factionWealth = "wealthy" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: REPAIR DOCK
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "The plasma burns on that last freighter were nasty. Almost melted right through the armor blocks."%_T,
        conditions = { stationType = "repairdock", minWarHeat = 15 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We're out of cohesive field generators again. Temporary patches only until the next supply run."%_T,
        conditions = { stationType = "repairdock", factionWealth = "poor" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Some folks bring their ships in held together by nothing but duct tape and prayers."%_T,
        conditions = { stationType = "repairdock" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I heard a captain tried to fly through a rift without a dampener. Their ship... it was inside out."%_T,
        conditions = { stationType = "repairdock" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Don't tell command, but we've been using surplus scrap to fix up civilian transports off the books."%_T,
        conditions = { stationType = "repairdock", minReputation = 10000 }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: EQUIPMENT DOCK
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Another crate of low-grade mining lasers. Who even buys these anymore?"%_T,
        conditions = { stationType = "equipmentdock" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Keep an eye on the prototype shield boosters. I think one of the clerks is skimming inventory."%_T,
        conditions = { stationType = "equipmentdock", factionWealth = "poor" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "I finally managed to snag an exceptional transporter software module. Cost me a year's wages."%_T,
        conditions = { stationType = "equipmentdock" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Rumor has it a trader sold us a cursed radar system. Every ship that equips it goes missing."%_T,
        conditions = { stationType = "equipmentdock" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "If you're looking for high-end fire control systems, you're out of luck. The shipment got delayed by pirates."%_T,
        conditions = { stationType = "equipmentdock", factionWealth = "poor" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: MILITARY OUTPOST
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Keep your sidearm loaded. Tensions are running high since the last border skirmish."%_T,
        conditions = { stationType = "militaryoutpost", minWarHeat = 40 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Command is authorizing live-fire drills in sector 4. Best avoid that route."%_T,
        conditions = { stationType = "militaryoutpost" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We just got a fresh batch of torpedoes. Someone is preparing for a long fight."%_T,
        conditions = { stationType = "militaryoutpost", factionTrait = "aggressive" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I overheard the general talking about a preemptive decapitation strike on the rival faction's HQ."%_T,
        conditions = { stationType = "militaryoutpost", minWarHeat = 55 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Leave the recruits alone, they're jumpy enough as it is after the last Xsotan raid."%_T,
        conditions = { stationType = "militaryoutpost" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: SMUGGLER'S MARKET
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Keep your voice down. The local patrol ships have been poking their noses around the docking clamps."%_T,
        conditions = { stationType = "smugglersmarket" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "I've got three crates of unbranded targeting systems, if you've got the credits."%_T,
        conditions = { stationType = "smugglersmarket", minReputation = 1000 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Someone's moving stolen military goods through the asteroid fields. Big payout if you can hijack the haul."%_T,
        conditions = { stationType = "smugglersmarket" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Don't ask where the cargo came from, and I won't ask where it's going. That's the rule."%_T,
        conditions = { stationType = "smugglersmarket" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "The Syndicate is putting a bounty on anyone who undercuts their illegal goods prices. Watch your margins."%_T,
        conditions = { stationType = "smugglersmarket" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: CASINO
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "I lost three months of mining wages on a single hand of Cosmic Hold'em. The house always wins."%_T,
        conditions = { stationType = "casino" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Watch the dealer at table four. I swear they're using a micro grav-manipulator on the dice."%_T,
        conditions = { stationType = "casino" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "A wealthy merchant just bought out the VIP lounge. Could be a good mark for a... business proposition."%_T,
        conditions = { stationType = "casino", factionWealth = "wealthy" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Free drinks as long as you're playing, friend! Just don't check your credit balance tomorrow."%_T,
        conditions = { stationType = "casino" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Some hotshot pilot just bet their entire cruiser on a roulette spin. Didn't end well for them."%_T,
        conditions = { stationType = "casino" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: SCRAPYARD
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "You'd be amazed what people leave behind in these wrecks. Found a pristine energy core yesterday."%_T,
        conditions = { stationType = "scrapyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Watch your thrusters near sector 7. The debris field shifted and tore up a scout ship."%_T,
        conditions = { stationType = "scrapyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "You want to buy a license? Fine, but anything you break out there is on you."%_T,
        conditions = { stationType = "scrapyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I swear I heard a transmission coming from that ancient dreadnought wreck on the edge of the yard..."%_T,
        conditions = { stationType = "scrapyard" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We've got plenty of scrap iron, but Trinium parts are getting harder and harder to find."%_T,
        conditions = { stationType = "scrapyard" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: RESEARCH STATION
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "The latest scans from the barrier are showing massive energy spikes. Something big is moving in there."%_T,
        conditions = { stationType = "researchstation" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Don't touch that console! I've been running that simulation for three weeks uninterrupted!"%_T,
        conditions = { stationType = "researchstation" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We're always looking for Xsotan artifacts. The science division pays top credit for them."%_T,
        conditions = { stationType = "researchstation" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "A scout probe returned from a rift anomaly. The data it brought back... it doesn't make any logical sense."%_T,
        conditions = { stationType = "researchstation" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Funding got cut again. They want military applications, not theoretical physics."%_T,
        conditions = { stationType = "researchstation", factionWealth = "poor" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: TURRET FACTORY
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We need more servo motors if we're going to meet the quota for the double-barrel plasma cannons."%_T,
        conditions = { stationType = "turretfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I know a guy who can override the safety limiters on railguns, for a small fee of course."%_T,
        conditions = { stationType = "turretfactory", minReputation = 10000 }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Quality control rejected the last batch of coaxial cables. Scrap 'em and start over."%_T,
        conditions = { stationType = "turretfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "They say the new coaxial artillery designs can punch straight through a station's shielding in one volley."%_T,
        conditions = { stationType = "turretfactory", factionTrait = "aggressive" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "The assembly line is running hot today. Lots of custom military orders coming in from the border."%_T,
        conditions = { stationType = "turretfactory", minWarHeat = 20 }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: TRADING POST
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Market fluctuations have driven the price of processors through the roof today."%_T,
        conditions = { stationType = "tradingpost" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "A heavily-guarded convoy of luxury goods is arriving tomorrow. Get your buy orders ready."%_T,
        conditions = { stationType = "tradingpost" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "I've been trading between these three sectors for years, but the margins are getting terrifyingly thin."%_T,
        conditions = { stationType = "tradingpost" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Someone is artificially inflating the price of Energy Cells by stockpiling them in deep space."%_T,
        conditions = { stationType = "tradingpost" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Always read the fine print on the manifest. Some of these merchants will swindle you blind if you let them."%_T,
        conditions = { stationType = "tradingpost" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: RESOURCE DEPOT
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "We just took in a massive haul of raw Ogonite. Must have been a good strike out in the outer belt."%_T,
        conditions = { stationType = "resourcedepot" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Prices on Titanium are dropping. Market's flooded with cheap mining yields right now."%_T,
        conditions = { stationType = "resourcedepot" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "There's a massive asteroid cluster out past the nebula, completely untouched. Ripe for the taking if you have the lasers."%_T,
        conditions = { stationType = "resourcedepot" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Keep the loaders moving! We have three freighters waiting for their cargo hold transfers."%_T,
        conditions = { stationType = "resourcedepot" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "Some miners found a strange glowing ore near the core, but it irradiated their hold and ruined the engines."%_T,
        conditions = { stationType = "resourcedepot" }
    })

    -- ==========================================
    -- STATION SPECIFIC LORE: FIGHTER FACTORY
    -- ==========================================
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "The new Mk-IV interceptor chassis is finally ready for mass production."%_T,
        conditions = { stationType = "fighterfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "Command wants more bomber squadrons deployed, but we don't have enough high-capacity warheads in stock."%_T,
        conditions = { stationType = "fighterfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "I heard a test pilot blacked out pulling 15 Gs in the new prototype fighter. They're still scraping him out of the cockpit."%_T,
        conditions = { stationType = "fighterfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "ambient",
        text = "If you need a reliable escort, our heavy fighters are the best in the sector. Pricey, but worth it."%_T,
        conditions = { stationType = "fighterfactory" }
    })
    CosmicVaultDialogue.registerLine({
        modId = "CosmicChronicles", category = "rumor",
        text = "The experimental stealth fighters went missing during a training exercise... maybe their cloaks actually work."%_T,
        conditions = { stationType = "fighterfactory" }
    })
end

return CosmicChronicles