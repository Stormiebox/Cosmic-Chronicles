# 🪐 Cosmic Chronicles: Player Guide

![Version](https://img.shields.io/badge/version-3.2.3-6f42c1?style=flat-square)
![Avorion](https://img.shields.io/badge/Avorion-2.5.13-2f81f7?style=flat-square)

Have you ever docked at a station and wondered what the locals are actually thinking? In the vast, procedurally generated universe of Avorion, space can feel a little quiet. **Cosmic Chronicles** was built to change that, turning the cold math of background simulations into stories.

This guide walks through what Cosmic Chronicles does and how it differs from the base game, in plain English.

> [!TIP]
> For exact numbers and mechanic-by-mechanic detail, see [`WIKI.md`](WIKI.md). See [`README.md`](README.md) for installation.

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

The sector uses one shared 45-second chatter schedule. Before a line is chosen, the mod checks:

1. **Who is listening?** What's your reputation? Hero, neutral trader, or hated pirate?
2. **What is the economy doing?** Wealthy, average, or poor?
3. **Where are we?** Near the galactic core, or out on the lawless rim?
4. **What is happening nearby?** It reads War Heat, active news, weather, Rift conditions, and Eclipse state.
5. **Who is speaking?** Casino, shipyard, or smuggler's market?

Once it has that context, it searches the shared lore database via **Cosmic Vault**, throws out anything that doesn't fit the current situation, and broadcasts a line that does. Sometimes that line is a tip that teaches you a deeper mechanic (the Trash Manager, Captain synergies) without breaking immersion.

Because of this context-awareness, the galaxy reacts to you. The last 20 lines you heard are also remembered so reconnecting does not immediately restart the same small loop:

- **High War Heat:** military outposts talk about mobilizing fleets, civilians panic about trade sanctions.
- **Bad reputation:** smugglers tip you off on unbranding stolen goods, security forces warn you to keep your transponder clean.
- **Poor faction:** repair docks complain about holding ships together with duct tape because they can't afford cohesive field generators.

It runs alongside the vanilla game rather than replacing it. You'll still hear the classic Avorion lines, woven together with the reactive ones.

## Beyond Stations: A Connected Universe

The Rumormonger doesn't stop at stations. Cosmic Chronicles extends the same awareness into deep space.

### Dynamic Deep Space Events

Verified reports from Vault, War, Overhaul, and Ascendancy can create a bounded Chronicle projection. The event is stored first and waits for a player to enter its sector naturally; Chronicles does not load distant sectors just to spawn or inspect it. If War reports a major battle, you might find a **Derelict Graveyard**: the smoking aftermath, with Black Box recordings and system upgrades that scale in value closer to the core. A Scavenger captain recovers up to 50% more value from a Black Box, an Explorer up to 25% more, and both improve rare-loot odds. Black boxes can also carry `Rift Research Data` and `Subclass Subsystems`.

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

Open your Player Window and find the **Galactic News** tab. It contains three views:

- **Live Feed:** current and developing reports from Vault, War, Overhaul, Ascendancy, and Chronicles.
- **Chronicle:** Chronicle-owned stories and their outcomes.
- **Saved Leads:** personal location leads you chose to keep.

The newsroom also provides:

- **Source, topic, status, nearby, and search filters:** narrow the feed without trusting the client to decide what you are allowed to see.
- **Persistent unread tracking:** individual reads and **Mark All Read** are saved on the server per player. They survive reconnects and save reloads. Mark All covers every report you can currently access, not only the active filter.
- **Developing stories:** related reports share one thread, so an advisory, active crisis, and resolution remain connected.
- **Saved locations:** reports with a location can become a personal lead. Adding one to the map preserves any richer sector knowledge you already have.
- **Breaking News:** critical non-weather reports can trigger a rate-limited chat alert and banner. Vault remains the only immediate in-sector weather/Rift danger presenter, so the same hazard is not announced twice.
- **Headline ages:** every story shows how long ago it broke ("5m", "2h", "3d"), so you can tell a fresh crisis from old news.
- **Accessible priority:** source and severity appear as text as well as color.

## 🌌 Cosmic Vault Synergy

- **Verified news:** a headline reports a successful owning-system transition; Chronicles no longer starts a market event or changes famine merely to justify a story.
- **Regional hazards:** weather and Rift reports keep their coordinates and lifecycle, while Vault continues to own damage, effects, sound, warnings, and escalation.
- **Safe event spawning:** Vault's exact-coordinate queue keeps failed or partial Chronicle spawns retryable or repair-visible rather than silently consuming them.
- **Shared dialogue:** the server-owned Dialogue catalog lets all script contexts see the same stable lines.

## Behind the Scenes

A few things run quietly under the hood so the galaxy stays consistent for everyone:

- Every dice roll that affects gameplay uses Avorion's own deterministic randomization instead of ordinary Lua random calls, so a multiplayer server doesn't drift out of sync during a big fleet spawn.
- Background and UI scripts check who's actually allowed to trigger them, closing off a class of exploit where a modified client could fake a "free" action.
- Interaction charges and rewards are prepared before the external effect. If a restart leaves the result unknowable, the interaction locks for administrator review instead of charging or paying twice.
- `/chroniclesstatus` shows service health and canonical event totals. Server administrators can use `/chroniclesrepair scan`, `status`, `apply`, and `history`; scanning never changes state.
- All the deep lore, stat blocks, and mechanics documented here are also readable in-game from the Cosmic Codex tab, so there's no need to alt-tab to a wiki mid-session.

**Cosmic Chronicles** doesn't just add words to the screen. It listens to the invisible math behind the wars and economies around you, and turns that math into stories you can actually read.

---

<div align="center">

[⬆ Back to top](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Players-Guide-The-Living-Galaxy) · [🌌 README](https://github.com/Stormiebox/Cosmic-Chronicles) · [⚙️ Wiki](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Features-and-Enhancements)

</div>
