# 🪐 Cosmic Chronicles: Player Guide

Have you ever docked at a station and wondered what the locals are actually thinking? In the vast, procedurally generated universe of Avorion, space can feel a little quiet. **Cosmic Chronicles** was built to change that, turning the cold math of background simulations into stories.

This guide walks through what Cosmic Chronicles does and how it differs from the base game, in plain English.

## 📜 Contents

- [The Vanilla Way: Static Radio Chatter](#the-vanilla-way-static-radio-chatter)
- [The Cosmic Way: The Rumormonger](#the-cosmic-way-the-rumormonger)
- [Beyond Stations: A Connected Universe](#beyond-stations-a-connected-universe)
- [📰 The Galactic News Network Tab](#-the-galactic-news-network-tab)
- [🌌 Cosmic Vault Synergy](#-cosmic-vault-synergy)
- [Behind the Scenes](#behind-the-scenes)

---

## The Vanilla Way: Static Radio Chatter

To understand why Cosmic Chronicles is different, start with how the base game handles background text.

In vanilla Avorion, when a station spawns, the game hands it a static list of phrases. An Equipment Dock might have ten lines like *"Guns, guns, guns!"* or *"No refunds."* Every few seconds the game rolls a die, picks one at random, and displays it above the station.

It has zero awareness of what's actually happening in the galaxy:

- You could be at war, and the station will still yell *"Guns, guns, guns!"*
- The faction could be bankrupt, and the station will still yell *"Guns, guns, guns!"*
- You could be their worst enemy with a terrible reputation, and they'll cheerfully try to sell to you anyway.

## The Cosmic Way: The Rumormonger

Cosmic Chronicles introduces the **Rumormonger**. Instead of handing a station a static list and walking away, it actively watches the galaxy in real time.

Every 35 seconds, the mod checks the state of the sector before anyone is allowed to speak:

1. **Who is listening?** What's your reputation? Hero, neutral trader, or hated pirate?
2. **What is the economy doing?** Wealthy, average, or poor?
3. **Where are we?** Near the galactic core, or out on the lawless rim?
4. **Is there a war?** It asks *Cosmic War* how high the political tension is right now.
5. **Who is speaking?** Casino, shipyard, or smuggler's market?

Once it has that context, it searches the shared lore database via **Cosmic Vault**, throws out anything that doesn't fit the current situation, and broadcasts a line that does. Sometimes that line is a tip that teaches you a deeper mechanic (the Trash Manager, Captain synergies) without breaking immersion.

Because of this context-awareness, the galaxy reacts to you:

- **High War Heat:** military outposts talk about mobilizing fleets, civilians panic about trade sanctions.
- **Bad reputation:** smugglers tip you off on unbranding stolen goods, security forces warn you to keep your transponder clean.
- **Poor faction:** repair docks complain about holding ships together with duct tape because they can't afford cohesive field generators.

It runs alongside the vanilla game rather than replacing it. You'll still hear the classic Avorion lines, woven together with the reactive ones.

## Beyond Stations: A Connected Universe

The Rumormonger doesn't stop at stations. Cosmic Chronicles extends the same awareness into deep space.

### Dynamic Deep Space Events

Jump into an empty sector and the mod checks the local political climate. If War Heat is boiling over, you might find a **Derelict Graveyard**: the smoking aftermath of a fleet battle, with Black Box recordings and system upgrades that scale in value the closer you are to the core. A Scavenger captain recovers up to 50% more value from a Black Box, an Explorer up to 25% more, and both improve your odds of pulling a Rare or Legendary system upgrade. If the wreckage happens to sit in Eclipse territory, the reward doubles, but extracting it instantly draws an Ascendancy ambush. Black boxes can also carry `Rift Research Data` and `Subclass Subsystems`, both worth real money on the black market.

If tensions are rising rather than boiling, you might intercept a **Refugee Convoy** asking for food or medical supplies to repair their hyperdrive before a hunter fleet arrives. Donating has a 25% chance of a tip-off to a hidden resource stash.

Venture deep into an ancient faction's territory and your ship's computer might warn you about a colossal, cinematic **Cultural Monument**. Reading its inscription earns a permanent **+2,500 reputation** boost with that faction.

You may also find **Ancient Data Caches** that yield *Encrypted Log Fragments*, tradeable at any Research Station for credits and reputation, or stumble onto an **Ancient Eclipse Anomaly** radiating extreme energy. Extracting its core can yield rare system upgrades, but handle it wrong and it detonates.

Other deep-space encounters: silent **Drifting Ghost Ships**, **Rogue AI Probes** that need destroying before they warp out with your sector data, and **Stranded Diplomats** whose military escort didn't make it.

### Omni-Sensor Utility

Your ship's sensors got an upgrade: passive deep-space intelligence. Every jump into a sector, the Omni-Sensor scans the area and pings your chat with the coordinates of any claimable asteroids or hidden resource stashes.

### Your Crew Matters (Captain Synergies)

Cosmic Chronicles knows who's sitting in the captain's chair, and events change based on their class:

- **Smugglers and Explorers** keep a low profile. They can extract rumors from stations even where the local faction hates you.
- Rescuing a refugee convoy: a **Merchant** captain negotiates a flat 50,000-credit hazard pay fee; a **Smuggler** quietly skims 75,000 credits worth of valuables from the cargo during the transfer.
- Extracting a Black Box: **Scavenger** and **Explorer** captains recover more value (up to 50% and 25% more respectively) and have better odds of a high-rarity system upgrade.

### Captain's Logs

If you use *Cosmic Overhaul*, you can send captains on background missions (Mining, Trading, and so on). When they finish, they mail you a report, and Cosmic Chronicles appends a narrative **Captain's Log** to the bottom of it. Send a captain into a warzone and their log reflects close calls with military patrols. Send them into the deep unknown and they might write about strange phantom signatures on their scanners.

---

## 📰 The Galactic News Network Tab

Open your Player Window and find the **Galactic News** tab to read everything the Rumormonger and the rest of the Cosmic series are reporting on. It's a proper newsroom:

- **Category filter & search:** narrow the headline list to War & Conflict, Economy, Threats & Crises, Discoveries & Milestones, Captain Stories, or Politics, or type a keyword to search titles and article text directly.
- **Unread tracking:** unread headlines are bolded with a `●` marker, and a running "N Unread" counter in the header tells you at a glance whether you're caught up.
- **Breaking News:** galaxy-shaking events (a Behemoth Incursion, a major boss finally going down, an empire's total collapse) trigger an instant chat alert the moment they happen, plus a clickable red banner right in the News tab. You don't have to remember to check.
- **Headline ages:** every story shows how long ago it broke ("5m", "2h", "3d"), so you can tell a fresh crisis from old news.
- **Discovery News:** a new ambient story type covers uncharted signals, derelict fleets, ancient ruins, and rare stellar phenomena turning up near active factions. Pure flavor, no mechanical effect, just more reasons to read.
- **EMPIRE HAS FALLEN:** when an AI faction is wiped out entirely, the News Network now says so, with a dedicated Breaking article naming the fallen empire. That used to be one of the biggest things that could happen in a galaxy, and nobody reported it.
- **Cosmic War on the board:** finishing a War Bounty License or watching two AI factions actually agree to a ceasefire both show up here now too.

## 🌌 Cosmic Vault Synergy

- **Deep economy warfare:** ambient News events (Trade Crisis, Market Boom) aren't just cosmetic. They tie into the Cosmic Vault Economy API, raising or lowering a faction's Famine Score.
- **Dead Empire Filter:** News generation checks the Vault before it lets a faction speak, so destroyed empires can't broadcast messages from beyond the grave.
- **Post-Boss Anomalies:** destroying the Bottan Dreadnought spawns a persistent Spatial Rift anomaly for advanced exploration.
- **Famine Relief:** emergency relief caches show up during severe faction famines. Steal the contents for personal loot, or donate them for **+25,000 reputation** and an instant famine reduction.
- **Galactic Lore Broadcasts:** find a Legendary system upgrade or a huge credit haul in a data cache, and the News Network reports your discovery to the whole galaxy.

## Behind the Scenes

A few things run quietly under the hood so the galaxy stays consistent for everyone:

- Every dice roll that affects gameplay uses Avorion's own deterministic randomization instead of ordinary Lua random calls, so a multiplayer server doesn't drift out of sync during a big fleet spawn.
- Background and UI scripts check who's actually allowed to trigger them, closing off a class of exploit where a modified client could fake a "free" action.
- All the deep lore, stat blocks, and mechanics documented here are also readable in-game from the Cosmic Codex tab, so there's no need to alt-tab to a wiki mid-session.

**Cosmic Chronicles** doesn't just add words to the screen. It listens to the invisible math behind the wars and economies around you, and turns that math into stories you can actually read.
