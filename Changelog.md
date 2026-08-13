# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Never remove, overwrite or write above this

## v3.0.3

### 🐛 Bug Fixes & ⚙️ Adjustments

- [Fixed] **Dialogue Syntax Errors:** Patched server-side crashes in the Bottan Smuggler mission caused by improper `invokeFunction` logic when un-quested players attempted to interact.
- [Changed] **Anti-Exploit Distances:** Recalculated the anti-exploit distance checks across 10+ event scripts. Interaction limits have been expanded (ranging from 500 - 3000 units) to ensure players flying huge ships are no longer falsely flagged as being "too far away."
- [Changed] **File Cleanup:** Stripped out unneeded script files (like `smugglerdelivery.lua`) that were identical to vanilla, reducing the mod's footprint and preventing future VFS conflicts.


## v3.0.2

### 🐛 Bug Fixes & ⚖️ Balance Tweaks

- [Fixed] **Bottan Delivery Feedback:** When attempting to hand over goods to the Smuggler during the Easy Delivery mission, players who were too far away (>50km) would experience a silent dialogue closure due to the anti-exploit check. The smuggler will now provide appropriate dialogue feedback explaining you are too far away to hand over the goods.
- [Balanced] **Refugee Convoys (Cosmic Overhaul):** Buffed the Merchant captain hazard pay from `25,000` to `50,000` credits. Buffed the Smuggler captain skimming limits from `35,000` to `75,000` credits.
- [Balanced] **Echoes of the Frontline (Cosmic Overhaul):** Buffed the Black Box extraction multiplier for Scavenger and Explorer captains from `1.5x` (+50%) to `2.0x` (+100%).
- [Balanced] **Cinematic Monuments (Cosmic Vault):** Increased the permanent reputation boost awarded for reading a faction's monument from `+1500` to `+2500`.
- [Balanced] **Corrupted Lore Nodes (Cosmic Ascendancy):** Increased the base credit payout of Eclipse caches from `150,000` to `250,000` base credits to properly compensate for the massive eclipse ships ambush that they spawn.
- [Fixed] **Silent Dialogue Failures:** Resolved a systemic issue affecting 9 different deep-space event scripts (Refugees, Monuments, Ancient Caches, Ghost Ships, Diplomats, Eclipse Caches, Bosses, Black Boxes, and Rumormongers). Previously, clicking a dialog option while out of range would silently abort the interaction. These events now provide a client-side dialogue box explaining that you are too far away.
- [Tweaked] **Swoks Boss Interaction:** Expanded the interaction range limit for the Swoks boss fight from `50km` to `200km`.

## v3.0.1 🐛Bug Fix Patch Update!🐛

- [Fixed] **File Path Error:** Corrected a pathing error in include() for the hermit missions.

## v3.0.0 UNRELEASED WORKSHOP VERSION (PROJECT UNDER DEVELOPMENT)

### ✨ New Features & 📦 Content Additions

- [Feature] **Deep Economy Integration:** Ambient Galactic News events (Trade Crisis & Market Boom) seamlessly tie into the `CosmicVaultEconomy` API, natively spiking or dropping a faction's active Famine Score.
- [Feature] **Dead Empire Filter:** Galactic News Generation natively utilizes `FactionEradicationUtility` to strictly filter out destroyed empires, preventing ghost factions from broadcasting messages.
- [Feature] **Post-Boss Anomalies:** Upon destroying the infamous Bottan Dreadnought, the game natively invokes `CosmicVaultAnomalies` to spawn a persistent `SpatialRift` anomaly for advanced exploration.
- [Feature] **Cosmic Codex Integration:** The mod now fully supports the Cosmic Codex! Comprehensive lore and mechanical documentation are readable directly in-game from the new Cosmic Codex tab.
- [Feature] **Deep Wiki Integration:** Hooked the Rumormonger and Captain's Log systems directly into the Cosmic Codex to explain their dynamic narrative mechanics natively in-game.
- [Feature] **Galactic News - The Stock Market:** The News Board now actively scans and reports on extreme economic supply/demand disparities, creating dynamic trading opportunities.
- [Feature] **Cosmic Vault API Framework:** Fully integrated with the Cosmic Vault API framework. Swept codebase for legacy callbacks and implemented safe pcall fallbacks.
- [Feature] **Corrupted Lore Nodes:** High risk, high reward data caches in Eclipse territory.
- [Feature] **Explorer Resonance:** Explorer captains detect black boxes from much further away.
- [Feature] **Galactic Lore Broadcasts:** Major discoveries publish global Cosmic Vault News.
- [Feature] **Famine Relief Anomalies:** Interactive Famine Relief Caches during severe faction famines.
- [Content] **Vanilla Story Quest Migration:** Massively ported and modernized all 21 core Avorion story quests directly into the unified Cosmic Codex API.
- [Content] **Unified Radio & Dynamic Chatter Expansion:** Centralized all ambient radio storytelling into Cosmic Chronicles. Expanded radio traffic with over 450+ new, immersive dialogue lines featuring deep lore drops on The Eclipse, Ascendants, and The Commune, vastly expanding the ambient variety of Station Chatter, Captain Logs, Rumors, Pirate Threats, and Sector Radio Broadcasts.
- [Content] **Dynamic Passing Ships:** Completely overhauled passing ship chatter via an override script. Ships now pull from a unique pool of ~270 customized lore lines.
- [Content] **Expanded Pirate Threats:** Injected a `pirateattack.lua` override that expands pirate ambush speech bubbles from a vanilla pool of 9 lines to a massive pool of 59 unique taunts.
- [Content] **Rumormonger Intrigues:** Injected over 30 new intricate rumors into the `CosmicVaultDialogue` system, giving players much more depth when asking stations for the latest galaxy gossip.
- [Content] **Deep Space Event - The Ghost Ship:** Discover intact derelicts with corrupted logs and hidden compartments. Captain Synergy: Scavengers find extra loot, Explorers decrypt coordinates.
- [Content] **Deep Space Event - Rogue AI Probe:** A fast, evasive anomaly scaling in difficulty near the core. Destroy it before it warps away for rare technology.
- [Content] **Deep Space Event - Diplomatic Escort:** Escort a stranded VIP across sectors. Captain Synergy: Diplomats negotiate massive payouts, Smugglers bypass patrols.
- [Content] **Deep Space Event - Ancient Data Caches:** Discover ancient vaults near the core to gain permanent buffs and massive Xsotan lore drops. Now dynamically loads a bespoke, ancient monolithic structure.
- [Content] **Deep Space Sector Generation - Eclipse Lore:** Replaced empty sectors with the chance to find Eclipse Beacons, Shipwrecks, and Stashes yielding deep lore and core-scaled loot. Beacons, Stashes, and Monuments now generate massive, customized `.xml` megastructures.
- [Content] **Classified Rift Tech:** Recovered Black Boxes now have a chance to drop highly-classified `Rift Research Data` and `Subclass Subsystems`. These contraband goods are extremely valuable on the black market.

### ⚙️ Changed & ⚖️ Balanced

- [Changed] **Standardized Jump Logic:** Swept the entire event codebase to remove hardcoded deletion logic. All AI ships now natively use the engine's `deletejumped.lua` script for flawless hyper-jump escapes.
- [Changed] **Inanimate Object Polish:** Swept all debris events (Ghost Ships, Blackboxes) to ensure they play `Sector():createExplosion()` before despawning, rather than just blinking out of existence.
- [Changed] **Lore-Accurate Debris:** Ghost ships and derelicts have had their AI controllers stripped. They now function as actual dead ships rather than active pirates.
- [Changed] **Updated:** Global Compliance and API updates across various scripts.
- [Changed] **Vault Integration:** Assured full compatibility with the new CCM 3-Column layout and Keybind systems.
- [Changed] **Unified News API:** Refactored multiple legacy news broadcasting systems to securely pass through the new `CosmicVaultNews.publishArticle` architecture for global validation.
- [Changed] **Core Dependencies:** Removed `pcall` soft-dependencies. Core 5 mods are now hard requirements.
- [Balanced] **Galactic Turn Synchronization:** The Stock Market background simulation interval has been synced to the global 20-minute (1200s) server turn to improve dedicated server performance.
- [Balanced] **Narrative Spawn Balancing:** Adjusted the global `events.lua` controller to strictly bound `Cosmic Chronicles` narrative event spawn rates to between 6% and 12% per sector visit, preventing overwhelming event chains.
- [Balanced] **Interaction Distance Enforcement:** Hardcoded a strict 500m distance constraint onto all callable interaction scripts (Diplomats, Distress Beacons) to prevent long-distance exploit interaction.

### 🐛 Bug Fixes & 🛠️ Optimization

- [Optimized] **Performance & TPS Optimization:** Drastically reduced server load during late-game scenarios. Injected a hardcoded `getUpdateInterval` throttle (1.0s) into `buymission.lua` and `hermitmission.lua` to prevent the engine from polling the sector 60 times a second.
- [Fixed] **Truthiness Logic Stabilized:** Applied strict explicit float comparisons (`> 0.5`) inside `cc_factionmonument.lua`, `radiochatter.lua` and other scripts, resolving cases where Avorion Lua engine would implicitly evaluate 0 values as truthy.
- [Fixed] **Cross-Mod API Integration:** Fixed a critical namespace error in `cc_newsboard.lua` where it incorrectly attempted to invoke the `cosmicvaultnews_server.lua` API via the `Server()` object instead of the `Galaxy()` object, completely restoring cross-mod news fetching functionality and resolving engine stack trace crashes.
- [Fixed] **Cosmic Codex Loading Crash:** Fixed missing global definitions (e.g. `entities`, `rangeType`) in the codex files that prevented the encyclopedia from loading correctly and crashed the UI.
- [Fixed] **Dynamic Event Spawn Logic:** Patched structural logic issues in the Ghost Ship, Stock Market, and Eclipse Lore scripts where float probability checks were being compared against `random():getInt()`, ensuring accurate event triggers globally.
- [Fixed] **Eclipse Lore Spawn Rate:** Fixed a math logic bug where `random():getInt() > 0.05` mathematically guaranteed an Eclipse Lore spawn almost 100% of the time, replacing it with `getFloat()` to restore the intended 5% rarity.
- [Fixed] **Data Cache Fallback Crash:** Injected a missing `plangenerator` requirement into `cc_ancientdatacache.lua` to prevent the engine from fatally crashing if the new `.xml` plans fail to load and the game attempts a procedural fallback.
- [Fixed] **Engine Freeze & Lockup Prevention:** Fixed a catastrophic script error inside `spawnrandombosses.lua` where a `while true do` loop lacked a failsafe iteration cap. This previously caused the entire Dedicated Server process to lock up 100% CPU and freeze during late-game boss anomaly generation.
- [Fixed] **Pathing Crash Hazards:** Repaired illegal absolute `include()` path injections (`include("data/scripts/entity/story/hermit")`) inside `crossthebarriermission` and `hermitmission` that could violently crash the server context.
- [Fixed] **Multiplayer Networking:** Added `onClient()` wrappers to the Exodus Wormhole Beacon UI to prevent the local singleplayer thread from self-invoking networking callbacks.
- [Fixed] **Desyncs:** Replaced `math.random` with `random():getInt()` inside `cc_rogueaiprobe.lua` and other event generators. This prevents physics desyncs and invisible collisions in multiplayer.

- [Fixed] **VFS Compliance:** Stripped redundant global wrapper functions from namespaced scripts to prevent silent double-execution logic loops and engine crashes.
