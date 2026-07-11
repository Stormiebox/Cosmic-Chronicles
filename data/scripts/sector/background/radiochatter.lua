package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")
include ("randomext")
include ("callable")


local cw_success = true; include("cosmicwarbridge")
local cv_success = true; include("cosmicvaultdialogue")

local function cc_getFactionWarHeat(faction)
    local realWarHeat = 0
    if cw_success and CosmicWarBridge and CosmicWarBridge.getFactionWarHeat then
        local rawHeat = CosmicWarBridge.getFactionWarHeat(faction.index) or 0
        realWarHeat = math.floor(rawHeat*100)
    elseif faction:getValue("cw_enabled") then
        local rawHeat = faction:getValue("cw_war_heat") or 0
        realWarHeat = math.floor(rawHeat*100)
    end
    return realWarHeat
end

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace RadioChatter
RadioChatter = {}
local self = RadioChatter
local xsotanChatter = nil
local riftInvasionBase = false

if onClient() then

self.entityTimes = {}
self.specificLines = {}
self.dist = nil

self.EntityTimeBetweenSpeechBubbles = 120

function RadioChatter.getUpdateInterval()
    if not self.which then return 1 end

    return 30 + random():getInt(15)
end

function RadioChatter.initialize()
    local sector = Sector()
    riftInvasionBase = (sector:getEntitiesByScript("riftresearchcenter.lua") ~= nil)

    local x, y = sector:getCoordinates()
    local dist = length(vec2(x, y))
    self.dist = dist

    self.GeneralStationChatter =
    {
        -- jibber jabber
        "Dock ${LN2} is clear."%_t,
        "Dock ${LN2} is not clear."%_t,
        "${R}: Docking permission granted."%_t,
        "${R}: Docking permission denied."%_t,
        "Approach vector ${N2}/${N} confirmed."%_t,
        "We cannot allow just anybody to come aboard."%_t,
        "General reminder to the populace: open doors create unnecessary suction."%_t,
        "According to form ${R}, all taxes have been paid."%_t,
        "Requesting confirmation of received goods."%_t,
        "All incoming vessels: we welcome you in our sector and we hope for you that your intentions are peaceful."%_t,
        "Freighter ${N2}: this is ${R}. Please identify yourself."%_t,
        "Oh, back so early?"%_t,
        "Major Tom, please come in."%_t,
        "Please repeat the last statement."%_t,
        "${R}, what is your estimated time of arrival?"%_t,
        "${R}, you're free to dock. Choose whichever dock you please."%_t,
        "${R}, please send us position and approach angle."%_t,
        "Negative, we are still waiting for the delivery."%_t,
        "Hello ${R}, it's great to see you again!"%_t,
        "${R}? What are you guys doing here?"%_t,
        "This is the automated response system. Denied requests can be reviewed at any time by our algorithm."%_t,
        "Mandatory meeting of all station commanders tomorrow in room ${R}."%_t,
        "${R}, please come in."%_t,
        "No, that form is no longer up to date."%_t,
        "We ask all captains and pilots not to occupy docks any longer than necessary."%_t,

        -- hidden world bosses hints
        "Public Service Announcement: After losing contact to our latest chemical transport, we strongly advise not to open any sealed containers."%_t,

        -- Cosmic Series Custom Lore & Easter Eggs
        "Notice to all docked ships: Please report any unusual black Avorion readings directly to station security."%_t,
        "I don't care what the Galactic News says, those monoliths near the core aren't natural."%_t,
        "Station Announcement: Stormbox's anomalous code optimization is now running on all mainframes. Please ignore any minor reality glitches."%_t,
        "We are currently experiencing a shortage of military-grade targeting systems due to the ongoing border skirmishes."%_t,
        "Rumor has it, a rogue architect by the name of Stormbox is out there rebuilding entire weapon systems from scratch."%_t,
        "Attention: Smugglers and Explorers are reminded that illegal hyper-jump modifications will be confiscated at customs."%_t,
        "The Ascendants built a Forge that runs on war. Keep your heads down and your shields up."%_t,
        "A refugee convoy just docked at bay ${N}. They say their home was caught in a massive fleet clash."%_t,
        "Did you hear about the new Overhaul? They say plasma weapons actually melt through shields now."%_t,
        "Remember, war profiteering is entirely legal as long as the local bureaucrats get their cut!"%_t,
        "I traded with a captain yesterday who claimed the universe was just a simulation run by a guy named Stormbox. Crazy."%_t,
        "Warning: Hyperspace anomalies detected in the outer rim. Navigational hazards have increased by 400%."%_t,
        "If you see any ships flying without transponders, assume they are mercenaries and avoid engagement."%_t,
        "Docking Bay ${N} is closed for repairs after a heavily overhauled freighter misjudged its approach vector."%_t,
        "Can someone tell the mechanics to stop installing experimental Stormbox drives in civilian ships? We had another spontaneous quantum leap today."%_t,
        "I swear, the stars looked different yesterday. It's like the entire galaxy was overhauled overnight."%_t,
        "The Eclipse has eyes everywhere. Keep your voice down."%_t,
        "Security update: Headhunter hit-squads have been reported in the area. Please ensure your bounties are paid in full."%_t,
        "The chroniclers are saying that this era of galactic politics will be remembered for centuries."%_t,
        "If you ever meet a rogue engineer named Stormbox, buy him a drink. I heard he basically rewired the entire galaxy's framework!"%_t,
        "Attention: All civilian traffic must detour around the new wreckage field in sector ${LN3}. Salvage crews are already en route."%_t,
        "Ever since the stars started falling, I've had this terrible feeling that we're being watched by something ancient."%_t,
        "Public Service Announcement: The new Cosmic Ascendancy protocols are now in effect. Adjust your ship parameters accordingly."%_t,
        "I'm telling you, the economy is rigged. Every time I find a good trade route, a war breaks out!"%_t,
        "Does anyone else hear that strange hum coming from the hyperspace engines since the last patch?"%_t,
        "Just saw a massive fleet dropping out of hyperspace. Looks like diplomatic relations are finally boiling over."%_t,
        "Friendly reminder to all captains: Bounties are now active across all sectors. Watch your back."%_t,
        "They say if you jump too close to the core, the Eclipse will pull you right out of hyperspace."%_t,
        "We need to offload these weapons before a ceasefire is declared, otherwise prices will plummet!"%_t,
        "Keep your transponder active. You don't want the local military mistaking us for blockade runners."%_t,
        "Did you catch the latest broadcast on the Galactic News network? War tensions are rising in the neighboring sectors."%_t,
        "I swear, these recent overhauls to the hyperdrive systems have made my ship run smoother than ever!"%_t,
        "The chroniclers are saying that this era of galactic politics will be remembered for centuries."%_t,
        "If you ever meet a rogue engineer named Stormbox, buy him a drink. I heard he basically rewired the entire galaxy's framework!"%_t,
        "Ever since the stars started falling, I've had this terrible feeling that we're being watched by something ancient."%_t,
        "A refugee convoy just docked at bay ${N}. They say their home was caught in a massive fleet clash."%_t,
        "We are currently experiencing a shortage of military-grade targeting systems due to the ongoing border skirmishes."%_t,
        "Remember, war profiteering is entirely legal as long as the local bureaucrats get their cut!"%_t,
        "Attention docking crews: All shipments of volatile reactive material must be scanned twice before loading."%_t,
        "I just paid a ridiculous fee to get my ship's hull certified by the Overhaul standards committee."%_t,
        "Are we safe here? The Galactic News says the war heat is rising to dangerous levels."%_t,
        "I heard Stormbox actually recoded the laws of physics to make ships fly faster. Unbelievable."%_t,
        "Don't buy any cheap coaxial weapons from the black market, they've been known to misfire and vaporize the ship."%_t,
        "Does anyone know why half the systems in the outer rim just went dark simultaneously?"%_t,
        "Trade route ${LN2}:${N} has been completely seized by mercenaries. Seek alternate routes."%_t,
        "Station security is conducting randomized scans for restricted Xsotan artifacts. Cooperate or be detained."%_t,
        "I need a drink. It's been a long week navigating through the warzone blockades."%_t,
        "My crew refuses to fly anywhere near the core. They say the ancient statues are waking up."%_t,
        "Keep your eyes peeled, I saw a ship with no registry drift into the dock an hour ago."%_t,
        "This station is completely out of coaxials. Some rich merchant bought the entire supply."%_t,
        "The economy is booming, provided you don't mind trading in military-grade contraband."%_t,
        "Who designed these docking lanes? Probably the same guy who overhauled the whole galaxy..."%_t,
        "I just lost three crew members to a mercenary press gang while on shore leave."%_t,
        "Did you hear the latest rumor from the Chronicles? The Eclipse is a myth to scare away scavengers."%_t,
        "I can't believe the bounties on pirates these days. It's almost worth retrofitting my freighter for combat."%_t,
        "I saw it with my own eyes! A massive black monolith completely drained the energy from a passing dreadnought."%_t,
        "Warning: Solar flare activity has been artificially increased in Sector ${N2}. Do not drop shields."%_t,
        "I don't trust anyone offering to overhaul my engines. Last guy who did it vanished into another dimension."%_t,
        "Can we get maintenance to look at docking ring 3? It's been making a sound like a dying hyperspace core."%_t,
        "If you see Stormbox, tell him his last patch notes were too vague!"%_t,
    }

    self.GeneralShipChatter =
    {
        -- jibber jabber
        "Hyperspace engine is a code ${N2}, shields are a code ${N}. Repairs not urgent, but welcome."%_t,
        "Requesting permission to dock."%_t,
        "Requesting flight vector."%_t,
        "We are now at vector ${N2}/${N}."%_t,
        "Negative, we are still waiting for our goods."%_t,
        "Asking for clearance."%_t,
        "So far, so good."%_t,
        "I have a bad feeling about this."%_t,
        "${R} entering flight vector."%_t,

        -- weapons
        "Personally, I don't like those fancy energy weapons. I'd take some good old chain guns over plasma any day."%_t,
        "... yeah, but shields are nearly useless against plasma weapons."%_t,
        "Railguns rip through a ship's hull like hot targo through a panem. /* Those are fantasy words */"%_t,

        -- general hints
        "One of these days I'll find one of those asteroids and claim it for myself."%_t,
        "No, no, no! With R-Mining Lasers, you get high yields of ores that you have to refine!"%_t,
        "Greedy bastard got himself killed going after the yellow blips on his galaxy map. Pirates everywhere."%_t,
        "Yes, really! If you don't shoot the Xsotan, they just move on! Saw it with my own eyes!"%_t,
        "The lightest material in the galaxy is Trinium. Trinium ships are a dream to steer."%_t,
        "They started building Cloning Pods with Xanion. Gives me the shivers."%_t,
        "If you ever come across one of those Behemoths, just pray that they won't detect you."%_t,
        "That last sector I visited was completely ravaged. Nothing left. Not even salvage. Creepy as hell if you ask me."%_t,

        -- hidden world bosses hints
        "I'm telling you, there's some old guard ship out there. That thing is defending some wrecks like they're still inhabited!"%_t,
        "The captain is completely crazy. Wants all kinds of ship parts for his collection, as if ships were something like rare butterflies."%_t,
        "Have you heard about the ship where everyone is asleep? The autopilot has taken control and put everyone into cryosleep!"%_t,
        "You have to come with us! The galaxy is going down! We're all meeting up to leave this galaxy aboard the \"Opportunity\"! If you're not on the list, they won't let you near it!"%_t,
        "These \"traders\" are even worse than pirates! One should simply equip a ship, search for their hideout and smoke them out once and for all! But our fleet can't even do that!"%_t,
        "Yesterday, Bob once again let off a story. About a motley ship full of crazy people who destroyed his last freighter because it was too gray."%_t,
        "... heard already? They've built a weapon of mass destruction that can instantly pulverize any ship! I saw them once! We barely got away with it!"%_t,
        "... heard about the missing prison ship? A friend told me that the prisoners had taken over the ship!"%_t,
        "I'm telling you: Fully automated! This bot will take down any wreck in no time. I just hope it can tell functional ships from wrecks."%_t,

        -- Cosmic Series Custom Lore & Easter Eggs
        "I've been reading the historical chronicles lately... makes you realize how small we really are in this war."%_t,
        "You hear about that legendary pilot, Stormbox? They say he flies a ship made entirely of anomalous, overhauled tech."%_t,
        "My sensors keep picking up strange readings. Could just be interference, or maybe another catastrophic stellar event."%_t,
        "I wouldn't jump to the outer rim right now. The war heat is off the charts out there."%_t,
        "Thank the stars for the automated news broadcasts. Without them, we'd never know which trade routes were blockaded!"%_t,
        "Ever since the new galactic regulations, I've had to replace every single sub-system on my ship. Good thing it runs better now."%_t,
        "Just saw a massive fleet dropping out of hyperspace. Looks like diplomatic relations are finally boiling over."%_t,
        "If we get interdicted by headhunters, I'm ejecting the cargo and blaming it on you."%_t,
        "Did you see that stranded flagship earlier? Looked like it had been drifting since the last great conflict."%_t,
        "Keep your transponder active. You don't want the local military mistaking us for blockade runners."%_t,
        "My navigator just quit. Said the stars are moving and the hyper-lanes aren't safe anymore."%_t,
        "I picked up a distress signal from a mining crew out near the Eclipse monoliths. By the time I arrived, nothing was left but dust."%_t,
        "Who needs a dreadnought when my newly overhauled corvette can outmaneuver a plasma barrage?"%_t,
        "I tried installing one of those black-market hyperspace drives Stormbox allegedly designed. Now I'm hearing voices."%_t,
        "Can anyone confirm if the ceasefire in Sector ${LN3} is holding? I have medical supplies to deliver."%_t,
        "The Ascendants are mobilizing. I saw three of their warships jump toward the core."%_t,
        "We need to find a repair dock fast. That last pirate attack stripped away half our armor plating."%_t,
        "If you encounter a ship with no life signs drifting in space, don't board it. Just run."%_t,
        "I'm hauling a cargo full of old Earth artifacts. Some wealthy collector is paying top credit."%_t,
        "The military requisitioned my last freighter. Said it was for the war effort. Didn't even pay me market value!"%_t,
        "This sector gives me the creeps. Let's spool up the hyperspace engine and get out of here."%_t,
        "I'm tired of running blockades. Next station we find, I'm selling the ship and opening a bar."%_t,
        "Did you hear the transmission on the open channel? Someone is broadcasting old symphonies into the void."%_t,
        "That's the third time my sensors have glitched today. It's almost like the game engine is struggling to render reality."%_t,
        "Keep your distance from the asteroid belts. Mercenaries like to hide in the shadows of the rocks."%_t,
        "I paid a smuggler to erase my bounty, but I think he just took the credits and ran."%_t,
        "This new energy core is amazing. It handles the power draw of the overhauled shields perfectly."%_t,
        "If I see one more Xsotan ship, I'm going to lose my mind. They're everywhere these days."%_t,
        "I used to fly with a captain who claimed he met the architect of the universe. Said his name was Stormbox."%_t,
        "The price of Titanium just crashed. I'm going to be eating nutrient paste for a month."%_t,
        "Warning: Proximity alert. We have an unidentified vessel closing fast on our port side."%_t,
        "I don't care if the route is shorter. I am not flying through a radiation storm just to save a few credits."%_t,
        "They say the Ascendancy has discovered a new form of energy. If it's true, it could change everything."%_t,
        "I've got a bad feeling about that station. It's too quiet. Let's find somewhere else to dock."%_t,
        "My chief engineer says the new weapons array is drawing too much power. We might have to upgrade the generator."%_t,
        "Just a heads up, the local faction is scanning all cargo holds for contraband. Make sure your hidden compartments are secure."%_t,
        "I heard a rumor that someone found a way to bypass the barrier without the artifacts. Probably just a spacer's tale."%_t,
        "This ship is falling apart. I need to get to a shipyard and fast, before the life support fails."%_t,
        "The stars are beautiful out here, aren't they? It's easy to forget there's a war going on."%_t,

        -- flair
        "Contact message: We have encountered increased pirate presence in the vicinity. Combat operation requested."%_t,
    }

    self.FreighterChatter =
    {
        -- Cosmic Series Custom Lore & Easter Eggs
        "Hauling military supplies into a warzone... The pay better be worth the risk of being intercepted."%_t,
        "I heard Stormbox pays double for high-grade processors. Let's make a detour to his station."%_t,
        "War is good for business, sure, but I'd rather not end up as a wreckage field for some salvage crew to pick clean."%_t,
        "If the galactic news is right, the trade route through sector ${N2}:${N} is completely blockaded by hostile forces."%_t,
        "We need to offload these weapons before a ceasefire is declared, otherwise prices will plummet!"%_t,
        "A smuggler told me they managed to bypass the blockade. Sounds like a good way to get vaporized."%_t,
        "Are you sure these coordinates from the old chronicles are safe? I'm not looking to become a footnote in history."%_t,
        "The latest sweeping overhauls to customs are making it really hard to falsify our cargo manifests."%_t,
        "Another stellar anomaly means another shortage of rare minerals. Time to hike up our prices!"%_t,
        "Just keep the engines hot and the comms silent. I don't want any diplomatic sabotage fleets spotting us."%_t,
        "My cargo hold is so full of unbranded tech, I think the gravity plating is starting to warp."%_t,
        "We are currently avoiding the Eclipse-controlled sectors. I'm not risking this shipment of luxury goods."%_t,
        "If we get caught smuggling these Ascendancy relics, they'll seize the ship and throw us in the nearest penal colony."%_t,
        "Why did we agree to transport live alien fauna? One of them just ate the starboard sensor array!"%_t,
        "Stormbox's new hyper-route optimization algorithm shaved three days off our travel time, but my cargo manifests are all backward."%_t,
        "Is there a bounty on my head? Why does every pirate in the galaxy seem to know exactly what I'm hauling?"%_t,
        "I don't care if the margin is 500%, I am NOT trading with those zealots near the core."%_t,
        "Attention all escorts, tighten formation. We are entering a high-risk trade sector."%_t,
        "Can someone explain why the price of Zinc just quadrupled overnight? Was there an overhaul I missed?"%_t,
        "I just bribed a customs official with a crate of rare wine. He didn't even look at the weapons cache in the lower deck."%_t,
        "They say the best traders know when to dump their cargo and run. I think that time is now."%_t,
        "I'm hauling a shipment of pure Ogonite. If we get hit, the explosion will be visible from three sectors away."%_t,
        "The Syndicate offered me double the going rate to divert this shipment, but I like my kneecaps attached."%_t,
        "Why is it that every time I find a lucrative trade route, a massive fleet war breaks out right in the middle of it?"%_t,
        "I've got a hold full of medical supplies. Hopefully, they won't try to blockade us."%_t,
        "My sensors are picking up a massive debris field ahead. Looks like another convoy didn't make it."%_t,
        "Does anyone know if the Black Market on the other side of this nebula is still active?"%_t,
        "I swear, these new trading regulations are going to bankrupt me faster than the pirates."%_t,
        "We're running low on fuel, and the next depot is three jumps away through hostile territory."%_t,
        "I paid a fortune for this cloaking device, and it better work when we cross the border."%_t,
        "The demand for raw materials is skyrocketing. Too bad the supply lines are constantly being cut."%_t,
        "I heard a rumor that Stormbox himself engineered the new market algorithms. No wonder the economy is so chaotic."%_t,
        "Keep your eyes on the scanner. I don't want any surprises when we drop out of hyperspace."%_t,
        "This is the last time I accept a contract from the Ascendancy. The paperwork alone is a nightmare."%_t,
        "My crew is getting restless. They haven't had shore leave in three months."%_t,
        "If we can just make it to the inner core, we can sell this load and retire in luxury."%_t,
        "I don't trust the local authorities. They're just as corrupt as the smugglers."%_t,
        "Warning: Cargo containment field failing. We need to stabilize the temperature immediately!"%_t,
        "I'm not saying it was aliens, but my cargo just completely vanished from the hold without a trace."%_t,
        "Let's hope the local faction is too busy fighting the war to notice a little unregistered cargo."%_t,
    }

    self.HostileShipChatter =
    {
        -- Move along
        "Hey you! You'd better move along!"%_t,
        "You need to leave."%_t,
        "Leave our territory."%_t,
        "Please leave our territory."%_t,
        "You should leave our territory."%_t,
        "You had better run along."%_t,
        "I think it would be better for you to move on."%_t,

        -- More formal move along
        "This is a friendly reminder: please leave our territory."%_t,
        "This is a friendly reminder: hostile parties are not welcome, and will find their stay less than rewarding."%_t,
        "You aren't welcome around these parts. We kindly ask you to vacate our territory."%_t,
        "According to our records, you're an enemy of our faction. Please leave our territory, otherwise we'll have to take actions against you."%_t,
        "We'd like to ask you to leave our territory. You're not welcome here."%_t,
        "Our records state that you have to leave our territory."%_t,
        "Our leadership has ordered us to open fire if you don't leave our territory."%_t,

        -- Threatening
        "We've got our eyes on you. One wrong step is all it takes."%_t,
        "We've got orders to shoot down any hostiles if they try something and right now you're on that list. Better move on."%_t,
        "There they are again. Should we shoot them down?"%_t,
        "I hope you're only passing through. Otherwise things could get ugly."%_t,
        "This is a friendly reminder: our faction has mercenaries on their payroll."%_t,
        "This is a friendly reminder: if you don't leave our territory, we will open fire."%_t,
        "This is an unfriendly reminder to leave. Now."%_t,
        "Warning: if you don't leave this territory, we will open fire."%_t,
        "Warning: mercenaries have been contacted."%_t,
        "Warning: your details have been forwarded to our mercenary squad."%_t,

        -- Cosmic Series Custom Lore & Easter Eggs
        "The war heat is rising, and you're caught in the crossfire! Hand over the cargo!"%_t,
        "Even that rogue architect Stormbox can't save you out here!"%_t,
        "You think your overhauled shields can withstand this? Think again!"%_t,
        "Your name just popped up on the galactic bounty boards. Time to collect!"%_t,
        "The Eclipse will consume everything, starting with you!"%_t,
        "We've got orders to leave no survivors in this fleet clash. You're first."%_t,
        "This sector is under military blockade! Turn back or be destroyed!"%_t,
        "Your presence here is a diplomatic incident waiting to happen. We're going to make sure it doesn't."%_t,
        "The chroniclers will remember you as just another piece of debris!"%_t,
        "We don't care about your trade routes. This is a warzone, and you're the enemy."%_t,
        "Target locked. Prepare to experience a catastrophic event of your own!"%_t,
        "Even a complete ship overhaul can't save you from what we're about to do to it!"%_t,
        "Stormbox sends his regards. Say goodbye to your hull integrity!"%_t,
        "Did you really think you could fly an unescorted freighter through Cosmic War territory?"%_t,
        "The Ascendants demand blood, and yours will do nicely!"%_t,
        "I've been looking to test out my newly overhauled plasma cannons. You'll make a fine target."%_t,
        "There is no escape. The hyperspace blockers are already active."%_t,
        "You should have stayed in the civilized sectors. Out here, the strong devour the weak."%_t,
        "Look at this shiny new ship. It'll look even better as scrap metal!"%_t,
        "We are the storm, and you are just in the way."%_t,
        "Drop your cargo and we might let you live to see the next patch!"%_t,
        "You're trespassing in our hunting grounds. Prepare to be hunted."%_t,
        "I heard they updated the combat mechanics. Let's see how long you last!"%_t,
        "Your ship's design is obsolete. Let me help you dismantle it."%_t,
        "The bounty on your head is enough to buy me a new dreadnought. Nothing personal."%_t,
        "We've been tracking your warp signature across three sectors. It ends here."%_t,
        "The dark monoliths hunger for energy, and your ship's reactor will feed them!"%_t,
        "You can't outrun our overhauled engines. Power down your shields!"%_t,
        "I hope you enjoyed the Cosmic Symphony, because this is your final movement!"%_t,
        "Another fool stumbling into our ambush. Open fire!"%_t,
        "This is an Ascendancy-restricted zone. Violators will be disintegrated."%_t,
        "Your armor plating looks expensive. I think I'll take it."%_t,
        "You picked the wrong day to fly through this sector, merchant!"%_t,
        "The faction sent me to clean up their mess, and you're the first piece of garbage."%_t,
        "I don't care if you're a diplomat or a scavenger. Out here, everyone bleeds the same."%_t,
        "Surrender your vessel and we might just eject you into the void instead of vaporizing you."%_t,
        "I've been waiting for a good fight all cycle. Don't disappoint me!"%_t,
        "Your distress signal is being jammed. No one is coming to save you."%_t,
        "The Eclipse will feast on your remains!"%_t,
        "You can't hide in the asteroid belts forever. We'll flush you out."%_t,
        "I need a new hyperdrive, and yours looks like a perfect fit."%_t,
        "Don't bother powering up your weapons. This will be over before you can lock on."%_t,
        "Another sacrifice for the war effort! Glory to the faction!"%_t,
        "You're carrying illegal contraband. The penalty is death, and we are the executioners."%_t,
        "I smell fear. Or maybe that's just your plasma vents leaking."%_t,
        "We don't negotiate with trespassers. We eliminate them."%_t,
        "Your ship is a disgrace to engineering. Let me put it out of its misery."%_t,
        "The Syndicate sends their regards. And a barrage of torpedoes!"%_t,
        "You're outnumbered and outgunned. Make this easy on both of us."%_t,
        "I'm going to enjoy picking through your wreckage for spare parts."%_t,
    }

    if getLanguage() == "en" then
        -- these don't have translation markers on purpose
        table.insert(self.HostileShipChatter, "Why are you even here? Just go somewhere else.")
        table.insert(self.HostileShipChatter, "Do anything even remotely suspicious and you'll be space debris in no time.")
        table.insert(self.HostileShipChatter, "For your information, we tolerate your existence just because we are too lazy to kill you.")
        table.insert(self.HostileShipChatter, "We should have built a hyperspace rift around this sector to keep people like you out.")
        table.insert(self.HostileShipChatter, "Alright guys, who invited THAT piece of scrap here?")
        table.insert(self.HostileShipChatter, "I wish there was a hyperspace rift around this sector to keep people like you out.")
        table.insert(self.HostileShipChatter, "We have our orders. Just leave peacefully and nothing will happen to you.")
        table.insert(self.HostileShipChatter, "We don't serve your kind here!")
        table.insert(self.HostileShipChatter, "Greetings and welcome to- Okay nevermind, it's just some stranger poking their ship in sectors where they don't belong.")
        table.insert(self.HostileShipChatter, "Hey, look sharp now. There is a suspicious ship right there.")

        -- these don't have translation markers on purpose
        table.insert(self.GeneralStationChatter, "Tractor beam capacity at ${N2}%.")
        table.insert(self.GeneralStationChatter, "Who thought it would be a good idea to fix the oxygen vent with duct tape?")
        table.insert(self.GeneralStationChatter, "Where do I sign up?")
        table.insert(self.GeneralStationChatter, "Due to crew shortage, all overtime will be mandatory and unpaid.")
        table.insert(self.GeneralStationChatter, "Station stabilizer fields working at ${N2}% efficiency.")
        table.insert(self.GeneralStationChatter, "Notice to all arriving ships: Dock ${L}-${N} is temporarily disabled for maintenance. Thank you for your patience.")
        table.insert(self.GeneralStationChatter, "Construction of section ${N2} is now complete.")
        table.insert(self.GeneralStationChatter, "So, do you think any of it is true? Multiverse theory?")
        table.insert(self.GeneralStationChatter, "Medical section announcement: Remember to get up from your chair every now and then and take breaks between long gaming sessions.")
        table.insert(self.GeneralStationChatter, "Due to maintenance in corridor ${N2}, all personnel on their way to section ${LN3} should take elevator ${R} instead of ${LN3}.")
        table.insert(self.GeneralStationChatter, "I heard a rumor from a traveling merchant that she found a sector with asteroids placed in really weird formations.")

        -- these don't have translation markers on purpose
        table.insert(self.GeneralShipChatter, "I found this really beautiful sector just a few jumps away. The view was breathtaking.")
        table.insert(self.GeneralShipChatter, "I wish I could land on planets but my ship is too large for atmospheric entry.")
        table.insert(self.GeneralShipChatter, "You ever get the odd feeling that we're just floating around, not even in control of ourselves? Just me? Alright.")
        table.insert(self.GeneralShipChatter, "So, do you come here often?")
        table.insert(self.GeneralShipChatter, "My cousin's out fighting pirates, and what do I get? Guard duty.")
        table.insert(self.GeneralShipChatter, "Transponder signal verified. Continued existence permitted.")
        table.insert(self.GeneralShipChatter, "Flight calculations complete. Initiating automatic flight procedure.")
        table.insert(self.GeneralShipChatter, "Entering rotation cycle ${N2}. All systems nominal.")
        table.insert(self.GeneralShipChatter, "Even after all these years, I still can't fly a spaceship properly.")
        table.insert(self.GeneralShipChatter, "I got ambushed by pirates last week and got miraculously saved by some adventurer who was on their way towards the center of the galaxy.")
        table.insert(self.GeneralShipChatter, "False alarm. For a second I thought that asteroid was a pirate ship.")
        table.insert(self.GeneralShipChatter, "Sometimes you'll mine a rock that looks normal, and you'll find a fantastic stash of minerals inside!")

        -- these don't have translation markers on purpose
        table.insert(self.FreighterChatter, "I sure hope our cargo will fetch a good price.")
        table.insert(self.FreighterChatter, "I think I left my wallet back at the Equipment Dock.")

        -- we don't want these too often to not seem as repetitive
        if random():test(0.25) then
            table.insert(self.GeneralStationChatter, "Attention to all crew members: Get your free plushie alpaca from deck ${N2}.")
            table.insert(self.GeneralStationChatter, "Don't you DARE hit that red button!")

            table.insert(self.GeneralShipChatter, "Whose idea was it to get all these alpacas on board?")
            table.insert(self.GeneralShipChatter, "I am very happy with my job of saying random things to all passers-by while someone else flies the ship.")
            table.insert(self.GeneralShipChatter, "Man, I could really go for a vacation to Pillars of Debauchery ${N}...")
            table.insert(self.GeneralShipChatter, "Roses are red, violets are blue. I'm stuck in outer space, and so are you.")
            table.insert(self.GeneralShipChatter, "There's a bar in sector ${N3}:${N2} that has really good beer, and really cute.... Oh, hi Captain, didn't see you there. ")
            table.insert(self.GeneralShipChatter, "I watched him tear apart those pirates with salvaging turrets. Ripped their ships to shreds. That's what I call savage salvage.")

            table.insert(self.FreighterChatter, "This isn't Echoes of Damnation Alpha! Damned route calculation!")
            table.insert(self.FreighterChatter, "I hope they don't scan us... Wait! Who left the comm open?!")
        end
    end


    self.XsotanSwarmChatter = {
    {
        -- xsotanSwarmOngoing
        "There are too many!"%_t,
        "SOS! We're being overrun! Requesting immediate backup!"%_t,
        "When will it stop? Please make it stop!"%_t,
        "Bloody Xsotan. We'll show you how to stand fast!"%_t,
        "We won't lose! Stay strong!"%_t,
        "Why Boxelware, WHY!?"%_t,
        "I think this qualifies as the worst day of my life."%_t,
        "This sector will burn!"%_t,
        "Empty all magazines! Fire! Fire! Fire!"%_t,
    },
    {
        -- xsotanSwarmSuccess
        "Let's hope this swarm never comes back!"%_t,
        "We showed them damn Xsotan! Woohoo!"%_t,
        "Did those Xsotan really think they could win?!"%_t
    },
    {
        -- xsotanSwarmFail
        "Have we really lost? What now?"%_t,
        "We hoped to defeat the Xsotan plague once and for all. Guess it wasn't meant to be."%_t
    },
    {
        -- xsotanSwarmForeshadow
        "The Xsotan swarm was so damn strong. Let's hope this doesn't happen again!"%_t,
        "It's so good that we defeated the Xsotan swarm. Who knows what would have happened otherwise."%_t,
        "A lot of Xsotan appeared on our radars... are they regrouping?"%_t,
    }
    }

    local x, y = Sector():getCoordinates()
    local dist = length(vec2(x, y))

    if dist > 350 and dist < 430 then
        -- swoks
        table.insert(self.GeneralShipChatter, "Yes, Swoks was his name. I heard he ambushes anyone who is looking for new Titanium asteroid fields."%_t)
        table.insert(self.GeneralShipChatter, "Don't fly around outside the civilized sectors, or Swoks will come for you."%_t)
        table.insert(self.GeneralShipChatter, "Have you heard of this pirate boss, too?"%_t)
        table.insert(self.GeneralShipChatter, "Oh no, not here. I won't take even a single jump outside the civilized sectors."%_t)
        table.insert(self.GeneralShipChatter, "You should stay on the gate routes. There is increased pirate activity in the unexplored and empty sectors."%_t)

        table.insert(self.GeneralShipChatter, "Yes, around here. He appears when you do ten consecutive jumps into empty sectors."%_t)
        table.insert(self.GeneralShipChatter, "There's a myth around here: after ten consecutive jumps through empty sectors, Swoks will come for you."%_t)
        table.insert(self.GeneralShipChatter, "Personally, I don't believe it, but they say that after at least ten consecutive jumps through empty sectors, Swoks will come for you."%_t)
        table.insert(self.GeneralShipChatter, "... don't ask ME how he does it! All I know is, that after ten jumps into empty sectors, he'll come for you."%_t)

    end

    if dist > 240 and dist < 340 then
        -- the AI
        table.insert(self.GeneralShipChatter, "When you venture off into the unknown around here, you can find old war machines."%_t)
        table.insert(self.GeneralShipChatter, "Don't trail off into the unknown. There is some unknown terror around here."%_t)
        table.insert(self.GeneralShipChatter, "Oh no, not here. I won't take even a single jump outside the civilized sectors."%_t)
        table.insert(self.GeneralShipChatter, "I've heard it's an old AI, programmed to fight the Xsotan."%_t)
        table.insert(self.GeneralShipChatter, "It's harmless. Just don't attack it and don't be in the same sector when there are Xsotan."%_t)
        table.insert(self.GeneralShipChatter, "I've seen it once. It's huge and green and terrifying, with tons of plasma cannons."%_t)

        table.insert(self.GeneralShipChatter, "Yes, it tracks you when you jump through no-man's space. Ten jumps or more and you're guaranteed to meet it."%_t)
        table.insert(self.GeneralShipChatter, "Do you actually believe in this myth? How would the number of jumps into empty sectors influence you meeting a monster?"%_t)
        table.insert(self.GeneralShipChatter, "... and it's always watching. It tracks your jumps. Ten or more and it'll come for you."%_t)
    end

    if dist > 150 and dist < 240 then
        -- energy lab
        table.insert(self.GeneralShipChatter, "You can find those satellites in the yellow-blip sectors around here."%_t)
        table.insert(self.GeneralShipChatter, "There are plenty of those research satellites around here, in the non-civilized sectors."%_t)
        table.insert(self.GeneralShipChatter, "My buddy tried to salvage some of those yellow-blip satellites a few days back. Haven't heard from him since."%_t)
        table.insert(self.GeneralShipChatter, "Those new weapons sound like a threat. Are you sure they can't penetrate stone?"%_t)
        table.insert(self.GeneralShipChatter, "Stone can help you defend even against the strongest lightning weapons."%_t)
        table.insert(self.GeneralShipChatter, "They lost contact with their scouts. All they registered was an intense energy signature."%_t)
    end

    if dist > 350 then
        table.insert(self.GeneralShipChatter, "Yes, you can build shield generators out of Naonite! I have to find some!"%_t)
        table.insert(self.GeneralShipChatter, "Naonite, that green metal. Lets you build shield generators. Won't protect against collisions though."%_t)
        table.insert(self.GeneralShipChatter, "I know there's plenty of Iron floating around, but you should really look for Titanium to build your ship."%_t)
        table.insert(self.GeneralShipChatter, "I equipped a buddy's ship with Titanium Integrity Generators. Now it can take quite a few more hits before it breaks apart."%_t)
        table.insert(self.GeneralShipChatter, "I'll start looking for Naonite soon. I really need shield generators."%_t)

    end

    if dist > 330 then
        table.insert(self.GeneralShipChatter, "Best ship building material around here? Titanium. So much lighter than both Naonite and Iron."%_t)
        table.insert(self.GeneralShipChatter, "What? It's your own fault that you don't build ships out of Titanium, it's 42% lighter than Iron!"%_t)
    end

    --chatter only outside the barrier
    if dist > Balancing_GetBlockRingMax() then
        -- swoks
        table.insert(self.GeneralShipChatter, "I heard that in the Iron and Titanium regions, there is this pirate leader Swoks who ambushes anyone who explores the non-civilized sectors."%_t)
        table.insert(self.GeneralShipChatter, "The pirate infestation in the Iron and Titanium regions just doesn't end. As if their leader had doppelgangers."%_t)
        table.insert(self.GeneralShipChatter, "Have you heard of this pirate boss in the Iron and Titanium regions, too?"%_t)
        table.insert(self.GeneralShipChatter, "Don't go exploring in the Iron and Titanium reaches, or you'll be killed by Swoks."%_t)
        table.insert(self.GeneralShipChatter, "Don't fly around outside the civilized sectors in the Iron and Titanium reaches, or Swoks will come for you."%_t)

        -- the 4
        table.insert(self.GeneralShipChatter, "Have you heard of this Brotherhood? Apparently they're looking for Xsotan Artifacts near the Barrier."%_t)
        table.insert(self.GeneralShipChatter, "My colleague found a Xsotan artifact once. He took it to the Brotherhood. Haven't heard from him since."%_t)
        table.insert(self.GeneralShipChatter, "When I find one of those Xsotan artifacts, I'll take it to the Brotherhood and get rich."%_t)
        table.insert(self.GeneralShipChatter, "The Brotherhood pays anyone who brings them Xsotan artifacts good money."%_t)

        -- exodus
        table.insert(self.GeneralShipChatter, "... I kid you not! Some kind of beacon that always repeats the same message."%_t)
        table.insert(self.GeneralShipChatter, "I don't know how they are activated, but apparently those old gates take you far away."%_t)
        table.insert(self.GeneralShipChatter, "My nephew's brother in law's friend told me about this mysterious gate network."%_t)
        table.insert(self.GeneralShipChatter, "... In order to activate those gates, you need Xsotan artifacts."%_t)
        table.insert(self.GeneralShipChatter, "... beacons that always repeat the same message. I found one in an asteroid field."%_t)

        -- research artifact
        table.insert(self.GeneralShipChatter, "Apparently the AI of Research Stations combines legendary-tier subsystems into something new and strange."%_t)
        table.insert(self.GeneralShipChatter, "Some researchers of my wife's Research Station combined legendary-tier subsystems into something new."%_t)
        table.insert(self.GeneralShipChatter, "... and the three legendary-tier subsystems turned into something weird. An artifact with two scratches on it."%_t)

        if getLanguage() == "en" then
            table.insert(self.GeneralShipChatter, "... transporting a strange Xsotan artifact and said he'd take it through some empty sectors in the Naonite Belt just to be safe. Never saw him again.")
        end
    end

    --chatter only inside the barrier
    if dist < Balancing_GetBlockRingMax() then
        -- xsotan swarm
        table.insert(self.GeneralShipChatter,"Remember the great Xsotan Attack? Hundreds of Xsotan swarming all over.\nI wonder what made them stop."%_t)


        -- corrupted AI
        table.insert(self.GeneralShipChatter,"... and they turned it against us... without knowing our language."%_t)
        table.insert(self.GeneralShipChatter,"A lot of the parts that had broken off started flying in our direction and tried to ram us."%_t)

        -- laserboss
        table.insert(self.GeneralShipChatter,"The whole ship...destroyed in seconds."%_t)
        table.insert(self.GeneralShipChatter,"It was protected by some new technology, had something to do with the asteroids around it."%_t)
        table.insert(self.GeneralShipChatter,"We evaded its big laser, but there was no damaging it!"%_t)
        table.insert(self.GeneralShipChatter, "Mayday, mayday! We have suffered a catastrophic hull breach on deck 3!"%_t)
        table.insert(self.GeneralShipChatter, "Traffic control, requesting immediate docking clearance. Our stabilizers are failing!"%_t)
        table.insert(self.GeneralShipChatter, "Attention all vessels, be advised of localized ion storms in the neighboring sector."%_t)
        table.insert(self.GeneralShipChatter, "This is a broadcast from the Free Trade Coalition. All tariffs have been suspended for the cycle."%_t)
        table.insert(self.GeneralShipChatter, "Bounty Hunters Guild notice: New high-value targets have been posted in the local network."%_t)
        table.insert(self.GeneralShipChatter, "Unidentified vessel, you are deviating from the designated trade lanes. Correct your course immediately."%_t)
        table.insert(self.GeneralShipChatter, "This is Freighter Haul-9, we are under attack! Need immediate assistance!"%_t)
        table.insert(self.GeneralShipChatter, "Galactic Weather Service reports heavy solar flare activity. Shield your electronics."%_t)
        table.insert(self.GeneralShipChatter, "Attention, all civilian ships are advised to avoid sector 44-B due to ongoing military exercises."%_t)
        table.insert(self.GeneralShipChatter, "Emergency broadcast: Quarantine protocols have been enacted on Station Zeta. Do not approach."%_t)

    end

    local generalChatter =
    {
        -- jibber jabber
        "Radio test: Can you hear me? Frank? Hello?"%_t,
        "Checking radio... Changing frequency to ${R}."%_t,
        "Looks like the comm is still on."%_t,

        -- general flair
        "The Xsotan are slowly becoming a threat."%_t,
        "I heard that inside the Barrier, the Xsotan eat up entire planets."%_t,
    }

    RadioChatter.addStationChatter(generalChatter)
    RadioChatter.addShipChatter(generalChatter)
end

function RadioChatter.getRiftInvasionBaseChatter()
    local riftChatter =
    {
        -- lines for civil ships
        "Come with me into the rifts. Yes it's dangerous, but do you know how many resources you can gather there with R-Mining Lasers? Huge amounts!"%_t,
        "...The quantum fluctuations of the rift subspace distortion have an adverse effect on purifying ores. It simply is not possible."%_t,
        "...Don't bother with purifiying mining lasers in rifts, R-Mining is the way to go!"%_t,
    }

    return riftChatter
end

function RadioChatter.addStationChatter(lines)
    for _, line in pairs(lines) do
        table.insert(self.GeneralStationChatter, line)
    end
end

function RadioChatter.addShipChatter(lines)
    for _, line in pairs(lines) do
        table.insert(self.GeneralShipChatter, line)
    end
end

function RadioChatter.addHostileShipChatter(lines)
    for _, line in pairs(lines) do
        table.insert(self.HostileShipChatter, line)
    end
end

function RadioChatter.addSpecificLines(id, lines)
    local entity = Entity(id)
    if entity then
        entity:setValue("npc_chatter", true)
    end

    local id_str = tostring(id)

    local tbl = self.specificLines[id_str]
    if not tbl then
        tbl = {}
        self.specificLines[id_str] = tbl
    end

    for _, line in pairs(lines) do
        table.insert(tbl, line)
    end
end

function RadioChatter.updateClient()
    self.which = self.which or random():getInt(1, 2)

    if self.which == 1 then
        self.updateStationChatter()
        self.which = 2
    else
        self.updateShipChatter()
        self.which = 1
    end
end

function RadioChatter.selectLine(entity, general)
    local specific = self.specificLines[entity.id.string]

    local line = ""
    if specific and random():test(0.35) then
        line = randomEntry(random(), specific)
    else
        line = randomEntry(random(), general)
    end

    return self.fillInIdentifiers(line)
end

function RadioChatter.getChatterCandidates(type)

    local firstSelection = {}
    if type == EntityType.Station then
        firstSelection = {Sector():getEntitiesByType(EntityType.Station)}
    else
        firstSelection = {Sector():getEntitiesByScriptValue("npc_chatter")}
    end

    if #firstSelection == 0 then return {} end

    local player = Player()
    local now = appTime()

    local candidates = {}
    for _, candidate in pairs(firstSelection) do
        if candidate:getValue("is_xsotan") then goto continue end
        if candidate:getValue("no_chatter") then goto continue end
        if candidate.type ~= type then goto continue end
        if player and player:getRelationStatus(candidate.factionIndex) == RelationStatus.War then goto continue end

        local time = self.entityTimes[candidate.id.string]
        if time and now - time < self.EntityTimeBetweenSpeechBubbles then goto continue end

        local ai = ShipAI(candidate)
        if ai and (ai.isBusy or ai.isAttackingSomething) then goto continue end

        table.insert(candidates, candidate)

        ::continue::
    end

    return candidates
end

function RadioChatter.updateStationChatter()
    local stations = RadioChatter.getChatterCandidates(EntityType.Station)
    if #stations == 0 then return end

    local station = randomEntry(random(), stations)
    if station.hasPilot then return end -- don't show chatter if player is flying this ship

    -- if relations are hostile, player shouldn't be able to listen in on chatter
    if Player():getRelations(station.factionIndex) < -80000 then return end

    self.entityTimes[station.id.string] = appTime()

    -- check for xsotan event
    RadioChatter.showXsotanSwarmChatter()

    if xsotanChatter and self.dist < 150 and random():test(0.2) then
        displaySpeechBubble(station, randomEntry(random(), self.XsotanSwarmChatter[xsotanChatter]))
    else
        -- Cosmic Chronicles: Increased ping chance to 80% to surface custom lore more frequently
        if random():test(0.20) then
            displaySpeechBubble(station, self.selectLine(station, self.GeneralStationChatter))
        else
            invokeServerFunction("displayStateFormSpecificChatter", station)
        end
    end
end

function RadioChatter.updateShipChatter()
    local ships = RadioChatter.getChatterCandidates(EntityType.Ship)
    if #ships == 0 then return end

    local ship = randomEntry(random(), ships)
    if ship.hasPilot then return end -- don't show chatter if player is flying this ship
    self.entityTimes[ship.id.string] = appTime()

    -- too hostile for normal chatter
    if Player():getRelations(ship.factionIndex) < -80000 then
        displaySpeechBubble(ship, self.selectLine(ship, self.HostileShipChatter))
        return
    end

    -- check for xsotan event
    RadioChatter.showXsotanSwarmChatter()
    if xsotanChatter and self.dist < 150 and random():test(0.2) then
        displaySpeechBubble(ship, randomEntry(random(), self.XsotanSwarmChatter[xsotanChatter]))
        return
    end

    -- rift chatter
    if riftInvasionBase and random():test(0.10) then
        local riftLines = self:getRiftInvasionBaseChatter()
        displaySpeechBubble(ship, self.selectLine(ship, riftLines))
        return
    end

    -- general chatter
    local lines = self.GeneralShipChatter
    if ship:getValue("is_trader") or ship:getValue("is_freighter") then
        if #self.FreighterChatter > 0 and random():test(0.5) then
            lines = self.FreighterChatter
        end
    end

        -- Cosmic Chronicles: Increased ping chance to 80% to surface custom lore more frequently
        if random():test(0.20) then
        displaySpeechBubble(ship, self.selectLine(ship, lines))
    else
        invokeServerFunction("displayStateFormSpecificChatter", ship)
    end
end

function RadioChatter.generate(chars, num)
    local result = ""

    for i = 1, num do
        local c = random():getInt(1, #chars)
        result = result .. chars:sub(c, c)
    end

    return result
end

function RadioChatter.fillInIdentifiers(str)

    local numbers = "0123456789"
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    local args = {}
    args.L = self.generate(letters, 1)
    args.L2 = self.generate(letters, 2)
    args.L3 = self.generate(letters, 3)
    args.L4 = self.generate(letters, 4)

    args.N = self.generate(numbers, 1)
    args.N2 = self.generate(numbers, 2)
    args.N3 = self.generate(numbers, 3)
    args.N4 = self.generate(numbers, 4)

    args.LN = self.generate(letters, 1) .. "-" .. self.generate(numbers, 1)
    args.LN2 = self.generate(letters, 1) .. "-" .. self.generate(numbers, 2)
    args.LN3 = self.generate(letters, 1) .. "-" .. self.generate(numbers, 3)
    args.L2N = self.generate(letters, 2) .. "-" .. self.generate(numbers, 1)
    args.L2N2 = self.generate(letters, 2) .. "-" .. self.generate(numbers, 2)
    args.L2N3 = self.generate(letters, 2) .. "-" .. self.generate(numbers, 3)

    args.player = Player().name

    if random():getInt(1, 2) == 1 then
        args.R = self.generate(letters, random():getInt(1,2)) .. "-" .. self.generate(numbers, random():getInt(1,2))
    else
        args.R = self.generate(numbers, random():getInt(1,2)) .. "-" .. self.generate(letters, random():getInt(1,2))
    end

    return str % args
end

function RadioChatter.displayChatter(entity, line)
    -- called from server with unresolved arguments for tranlsation to work -> fill in identifiers here
    displaySpeechBubble(entity, self.fillInIdentifiers(line%_t))
end

    -- Cosmic Chronicles: Safely display our pre-translated Format objects without triggering vanilla identifier crashes
    function RadioChatter.displayCosmicChatter(entity, line)
        if not valid(entity) then return end
        displaySpeechBubble(entity, tostring(line))
    end

end

function RadioChatter.displayStateFormSpecificChatter(entity)
    if not valid(entity) then return end

    local faction = Faction(entity.factionIndex)
    if not valid(faction) then return end
    if not faction.isAIFaction then return end

    local stateForm = faction:getValue("state_form_type") or FactionStateFormType.Vanilla

    -- Cosmic Chronicles: Intercept and attempt to broadcast dynamic lore first
    local player = Player(callingPlayer)
    if player then
        local sector = Sector()
        local x, y = sector:getCoordinates()

        local stationType = "generic"
        if entity.isStation then
            stationType = entity:getValue("cc_station_type") or "generic"
        else
            stationType = "ship"
        end

        local factionTrait = "peaceful"
        if faction:getTrait("aggressive") > 0.5 then
            factionTrait = "aggressive"
        end

        local factionWealth = "average"
        if faction:getTrait("wealthy") > 0.5 then
            factionWealth = "wealthy"
        elseif faction:getTrait("poor") > 0.5 then
            factionWealth = "poor"
        end

        local context = {
            reputation = player:getRelations(faction.index),
            factionTrait = factionTrait,
            factionWealth = factionWealth,
            distanceToCenter = math.sqrt(x * x + y * y),
            warHeat = cc_getFactionWarHeat(faction),
            stationType = stationType
        }

        local line = cv_success and CosmicVaultDialogue.getValidLine("ambient", context)
        if line then
            invokeClientFunction(player, "displayCosmicChatter", entity, line)
            return -- Skip vanilla faction lines if we have a Cosmic Chronicles match
        end
    end

    local chatterLinesByStateForm = {}

    -- vanilla
    chatterLinesByStateForm[FactionStateFormType.Vanilla] =
    {
        -- no defining traits
    }
    chatterLinesByStateForm[FactionStateFormType.Organization] =
    {
        "Fight for equality for everyone!"%_t,
        "Worker's lives haven't improved for years. It's time to do something about it!"%_t,
        "This job at the factory has been killing people forever!"%_t,
        "I won't stop fighting for my rights!"%_t,
    }

    -- traditional
    chatterLinesByStateForm[FactionStateFormType.Emirate] =
    {
        "Even a prince has to follow traditions."%_t,
        "Remember young ones, listen to your grandfathers! They know best."%_t,
        "Galactic Sun elects the man of your dreams: generous and brave, with a hint of danger!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Kingdom] =
    {
        "Honor is one of the most important qualities of a person."%_t,
        "Whatever you do, do it for king and glory!"%_t,
        "Monarchies may be a bit old-school. But they bring peace and stability!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Empire] =
    {
        "Tea anyone? Quality assured by the Empress herself!"%_t,
        "Join us or be eradicated."%_t,
        "Our army is the best."%_t,
    }

    -- independent
    chatterLinesByStateForm[FactionStateFormType.States] =
    {
        "Be generous, be honorable and peace will follow you!"%_t,
        "Stand up for your rights, but trust in the government."%_t,
        "Honor our forefathers, for they made this life possible!"%_t,
        "It's everyone's duty to stand up for our great nation!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Planets] =
    {
        "The galaxy is vast and mostly empty. Stay safe!"%_t,
        "They say there was once a blue planet named Earth."%_t,
        "Last year ${N} new planets have enriched our community by joining in."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Republic] =
    {
        "The galaxy is vast and full of pirates. Better prepare!"%_t,
        "You don't have to get too close, if you have long-range scanners."%_t,
        "No, being careful has never been a problem."%_t,
        "I have a bad feeling about this."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Dominion] =
    {
        "I say: Shoot first, ask later."%_t,
        "I love my guns, I take one everywhere. Have one right under my pillow, too."%_t,
        "Have you heard? They're finally increasing our military budget."%_t,
        "There is no threat that would be a match for us."%_t,
        "Surveys indicate a happiness index of 9${N}%. That means we can still do better."%_t,
        "The happiness index increased by 4${N}%, after public executions of wrong-thinkers resumed."%_t,
    }

    -- militaristic
    chatterLinesByStateForm[FactionStateFormType.Army] =
    {
        "I'm doing My part!"%_t,
        "Honor our veterans. They risked their lives for us!"%_t,
        "Join the army today and get a free pen to sign your contract!"%_t,
        "Rations in section ${LN2} will have to be cut."%_t,
        "${N2} dishonorable deserters have been eliminated over the past week."%_t,
        "Recruitment is at an all-time high."%_t,
        "We have the biggest military budget per capita of the galaxy!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Clan] =
    {
        "We are the best here!"%_t,
        "Our community ist the best all over the galaxy."%_t,
        "Nothing compares to our big family!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Buccaneers] =
    {
        "Give me a good opportunity and I'll immediately get there."%_t,
        "What's wrong with taking an opportunity if it offers itself?"%_t,
        "... so I took it. A dead guy doesn't need it anyway, does he?"%_t,
    }

    -- religious
    chatterLinesByStateForm[FactionStateFormType.Church] =
    {
        "Unfortunately today's mass is cancelled."%_t,
        "Today, ${N}:00 o'clock: reading from psalm ${LN2}"%_t,
        "Faith offers strength. Always."%_t,
        "Find yourself again in prayer."%_t,
        "Confession will be postponed by ${N} days."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Followers] =
    {
        "The Great One will speak live at the ceremony."%_t,
        "Tune in to channel ${N} to listen to the sacred scrolls."%_t,
        "Follow the prophecy, find to the light."%_t,
        "The prophecy has never and will never fail us."%_t,
        "The prophecy lives through us all."%_t,
    }

    -- corporate
    chatterLinesByStateForm[FactionStateFormType.Corporation] =
    {
        "New work opportunities! Don’t let bots take you down."%_t,
        "${N2} new shipments at Dock ${L}."%_t,
        "We have ${N} open positions in sector ${LN3}."%_t,
        "Department ${LN3}'s workforce has lowered by 1${N}%."%_t,
        "Department ${LN3}'s workforce has increased by 1${N}%."%_t,
        "Stocks have increased by 1${N}%."%_t,
        "Today, I was promoted to consumer."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Syndicate] =
    {
        "We'd like to remind outsiders that all our activities are 100% legal."%_t,
        "Having trouble staying on the straight path? We don’t, either!"%_t,
        "So there's this old, completely legal ship that needs taking care of, and ... oh, wrong channel."%_t,
        "A friend of mine has a special delivery that's looking for a new owner."%_t,
        "Yes, absolutely. Yes, ${N2}% legal."%_t,
        "My friend asked me to join a union. I refused, 'cause I don't want to be fired."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Guild] =
    {
        "Productivity is at 9${N}%."%_t,
        "${N} new shipments today, ${N2} tomorrow."%_t,
        "${N} new businesses have joined the Guild over the past two weeks."%_t,
        "Do what you love, and get a fair wage for it."%_t,
        "I've been waiting for these shipments forever. Where are they!?"%_t,
        "Containers of section ${LN2} have been moved to section ${L2}."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Conglomerate] =
    {
        "Gotta up those numbers."%_t,
        "Find what you love. Then buy it. Then sell it for a profit."%_t,
        "I think I'll sell my vacation days for that 0.${N2}% profit."%_t,
        "Use bots, not workers. They don't need sleep, or wages, or food. It's a win-win-win."%_t,
        "The Conglomerate has bought ${N2} new businesses so far this week."%_t,
    }

    -- alliance
    chatterLinesByStateForm[FactionStateFormType.Federation] =
    {
        "Research, exploration and curiosity is what drives us."%_t,
        "The Federation stands for integrity, unity and honor."%_t,
        "Ugh, that stupid replicator on deck ${L} is broken again."%_t,
        "I don't think you should wear that red shirt on your mission."%_t,
        "Technological progress, so that we can improve a bit every day."%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Alliance] =
    {
        "Those who join us will receive protection."%_t,
        "Together, we're stronger."%_t,
        "Stand together in unison."%_t,
        "The Alliance is the shield we use to defend ourselves."%_t,
        "The Alliance has been joined by ${N3} new individuals today."%_t,
        "Fight the Horde! For the Alliance!"%_t,
    }
    chatterLinesByStateForm[FactionStateFormType.Commonwealth] =
    {
        "The Commonwealth stands for prosperity, liberty and wealth."%_t,
        "Everyone has to do their part here, but it's all worth it."%_t,
        "Sacrifices have to be made to create a better tomorrow."%_t,
        "For the greater good of the Commonwealth."%_t,
        "Update: Cameras in personal apartments on deck ${L} are now operational for your safety."%_t,
        "It's perfectly fine that these holo recorders are everywhere, after all, it's for the safety of all of us."%_t,
    }

    -- sect
    chatterLinesByStateForm[FactionStateFormType.Collective] =
    {
        "Are you willing to give yourself to the light? Join us."%_t,
        "Great pleasure awaits those that follow the path of union."%_t,
        "One of us."%_t,
        "Joining the Collective isn't mandatory, but recommended."%_t,
        "The Collective has welcomed ${N3} happy new individuals yesterday."%_t,
        "There is no discord here."%_t,
    }

    local line = randomEntry(random(), chatterLinesByStateForm[stateForm])
    if line then
        invokeClientFunction(Player(callingPlayer), "displayChatter", entity, line)
    end
end
callable(RadioChatter, "displayStateFormSpecificChatter")

function RadioChatter.showXsotanSwarmChatter()
    if onClient() then
        if self.dist < 150 then
            invokeServerFunction("showXsotanSwarmChatter")
        end
        return
    end

    local server = Server()
    if server:getValue("xsotan_swarm_active") then
        xsotanChatter = 1
    else
        local swarmSuccess = server:getValue("xsotan_swarm_success")
        local swarmTime = server:getValue("xsotan_swarm_time")
        if swarmTime and swarmTime < (15 * 60) then
            xsotanChatter = 4
        elseif swarmSuccess and swarmTime and swarmTime > (115 * 60) then
            xsotanChatter = 2
        elseif swarmSuccess == false and swarmTime and swarmTime > (115 * 60) then
            xsotanChatter = 3
        else
            xsotanChatter = nil
        end
    end

    RadioChatter.sync()
end
callable(RadioChatter, "showXsotanSwarmChatter")

function RadioChatter.sync(data_in)
    if onServer() then
        invokeClientFunction(Player(callingPlayer), "sync", xsotanChatter)
        return
    end

    if onClient() then
        if data_in then
            xsotanChatter = data_in
        else
            invokeServerFunction("sync")
        end
    end
end
callable(RadioChatter, "sync")


function getUpdateInterval(...)
    if RadioChatter.getUpdateInterval then return RadioChatter.getUpdateInterval(...) end
end
function initialize(...)
    if RadioChatter.initialize then return RadioChatter.initialize(...) end
end
function updateClient(...)
    if RadioChatter.updateClient then return RadioChatter.updateClient(...) end
end
