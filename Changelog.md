# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Never remove, overwrite or write above this

## [v3.2.0]

### ⭐ Feature Overhaul
- [Feature] **Galactic News Network: More To Report On.** Extended the network's reach further into the Cosmic series and added a new domestic report type:
  - **EMPIRE HAS FALLEN (`cc_newsgenerator.lua`):** Added a lightweight tracker that watches every known AI faction and detects the exact moment one transitions from active to eradicated (via the same `FactionEradicationUtility` check every generator here already uses), publishing a Breaking News article naming the fallen empire. Previously this was one of the biggest events a galaxy can have — and it went completely unreported; only a plain chat broadcast from a third-party dependency ever mentioned it, never the News Network. Only reports a transition it actually observes (a faction already gone before the tracker ever saw it active is not retroactively announced), and persists its tracking across server restarts.
  - **Cosmic War Integration:** Fully completing a War Bounty License and AI factions actually reaching a ceasefire are now both reported — see Cosmic War's own changelog for details. Neither the Cosmic War hooks nor most existing generators used the shared API's new `breaking` flag by default; only genuinely rare, galaxy-scale events (Behemoth Incursions, boss defeats, empire collapses) are tagged that way, keeping the Breaking News banner meaningful instead of constant.
  - **Cosmic Vault API Upgrade:** `cosmicvaultnews.lua`'s `breaking` field is now formally documented and validated by the shared API itself rather than being an implicit convention this mod invented; see Cosmic Vault's own changelog.
- [Feature] **Galactic News Network Completely Overhauled (`cc_newsboard.lua`, `cc_newsgenerator.lua`):** The News Board was a single-column headline list with no sorting, filtering, search, timestamps, or way to tell a genuinely major event apart from routine ambient flavor text — despite the underlying `CosmicVaultNews` API already being used by 4+ mods across the Cosmic series with 30+ distinct, unnormalized category strings (`"War Crime"`, `"Trade Crisis"`, `"Galactic Milestone"`, etc.). Rebuilt the UI around a category-grouping layer that maps every observed category (plus a keyword-based fallback for any new one introduced later) onto seven stable top-level groups (War & Conflict, Economy, Threats & Crises, Discoveries & Milestones, Captain Stories, Politics, General), each with its own color: (1) a **category filter dropdown** and a **live search box** (matching vanilla's own Encyclopedia search-box pattern) let players narrow the headline list instead of scrolling a flat, unsorted feed; (2) the headline list is now a proper 3-column sortable-by-glance table (Category / Headline / Age) instead of a single plain-text column, color-coded by group; (3) a session-local **unread tracker** bolds unread headlines, marks them with a `●`, and shows a running "N Unread" counter in the header; (4) a new **Breaking News** system — `cc_newsgenerator.lua`'s highest-priority articles (the Behemoth Incursion alert and every one-time boss-defeat report) now set a `breaking` flag CosmicVaultNews' schema already tolerates without any change to the shared Cosmic Vault API — surfaces as a dedicated, clickable red banner atop the tab and an immediate galaxy-wide chat alert the moment it's published, instead of requiring a player to remember to open the News tab at all; (5) every headline now shows a relative age ("5m", "2h", "3d"), computed server-side per sync (`Client().unpausedRuntime` and `Server().unpausedRuntime` are different clocks with different origins, so the server snapshots each article's age directly rather than sending a raw timestamp for the client to compare against its own clock); (6) added a fourth ambient content generator, **Discovery News** (uncharted signals, derelict fleets, ancient ruins, rare stellar phenomena reported near a random active faction's territory), rebalancing the existing War/Economy/Captain Feats generation odds to make room for it; (7) the header layout was decluttered onto separate rows, matching the pattern already established elsewhere in the Cosmic series.

## [v3.1.5]

### 🚨 Critical Fixes
- [Bugfix] **Ghost Ship / Diplomat Escort / Rogue AI Probe Duplication Exploit:** Fixed a class of infinite farming exploits where these three events could be repeatedly re-triggered by reloading the sector before looting, because `terminate()` was never called (or only called on a non-payout branch) after the entity spawned. All three now unconditionally detach their spawner script immediately after spawning, matching the fix pattern already established for the Ghostship event in v3.1.4.
- [Bugfix] **Bounty Ambush Duplication Exploit:** Fixed a similar exploit in `cc_bounty_ambush.lua` where reloading the sector before killing the boss could spawn additional 2.5M-credit bounty bosses. Added a sector-value spawn guard and moved `terminate()` to fire only after the reward is paid out.
- [Bugfix] **Pirate Attack VFS Pragma:** Restored the missing `-- namespace PirateAttack` declaration in `pirateattack.lua`, required for the Virtual File System to correctly merge this override with the vanilla script.
- [Bugfix] **Galactic News Network & Stock Market Never Ran:** Fixed `cosmicchronicles.lua` passing relative (rather than full `data/scripts/...`) paths to `Galaxy():addScriptOnce()` for the News Generator and Stock Market background systems. Both silently failed to attach — `addScriptOnce` fails silently on a bad path — so the features simply never ran. Both now correctly initialize.
- [Bugfix] **Eclipse Lore Generator Memory Leak:** Fixed `cc_eclipselore.lua` only calling `terminate()` on the successful-spawn branch; every early-return path (already-evaluated sector, entity cap exceeded, the 95%-common no-spawn roll, invalid wreckage) left the generator permanently attached to the sector. `terminate()` now runs unconditionally at the top of `initialize()`, matching the one-shot generator pattern used elsewhere in the engine.
- [Bugfix] **Radio Chatter Save Bloat:** Fixed `radiochatter.lua` re-injecting its ambient dialogue lines into the persisted station data on every single sector/database reload instead of only on first creation, causing unbounded save-file growth over a long campaign.
- [Bugfix] **Diplomat Rescue Payout Exploit & Bribe Bug:** Fixed `diplomatdialog.lua` allowing the extraction reward to be claimed multiple times by spam-clicking the dialogue option during the ~4.5 second window before `deletejumped.lua` actually removes the entity. Also fixed the Smuggler-tier illegal tech bribe being dropped for an undefined global instead of the actual buyer.
- [Feature] **Captain's Log — Actually Implemented:** The file responsible for appending narrative "Captain's Log" text to background command yields (`background/simulation/command.lua`) patched a method (`Command:sendMail`) that doesn't exist in the engine and was never attached to anything — this feature has never worked since it was introduced. Replaced with a same-path VFS override of `background/simulation/simulation.lua` that hooks `Simulation.makeCommand`'s `command.addYield`, matching the exact pattern Cosmic Overhaul itself uses to extend the same file, so the two mods' hooks compose correctly regardless of load order.
- [Removed] **Dead Files:** Removed `entity/story/storybulletins.lua` (a duplicate of vanilla's own `bulletins.lua`, saved under a filename the VFS never matches — it added no unique content and nothing in the mod depended on it) and `player/background/simulation/command.lua` (superseded by the Captain's Log fix above).

### 🪲 Bug Fixes
- [Bugfix] **Destruction Tracker Locale Bug:** Fixed `cc_destructiontracker.lua` comparing an untranslated `faction.name` against a runtime-translated (`%_t`) string, which silently failed on any non-English server locale and lost the Pirate/Xsotan flavor text. Also removed a dead trailing `return` left over from a previous cleanup pass.
- [Bugfix] **Captain Class Mislabeling:** Fixed `cc_newsgenerator.lua` mapping `primaryClass == 1` to "Explorer" in generated news text; per the engine's captain class enum, 1 is Commodore and 6 is Explorer.
- [Bugfix] **Ghost Ship Dialogue Soft-Lock:** Fixed `ghostshipdialog.lua` setting its loot-claimed flag before validating the captain-class requirement for tiers 2/3, permanently soft-locking the wreck with zero payout if an ineligible captain triggered the wrong tier.
- [Bugfix] **Exodus Determinism:** Replaced two `math.random()` calls in `exodus.lua`'s wreckage placement with the engine's deterministic `random():getFloat()`/`getInt()`, matching this mod's established multiplayer-sync convention.
- [Bugfix] **Passing Ships Structural Consistency:** Wrapped an unconditionally-defined function in `passingships.lua` in `if onServer() then ... end` to match vanilla's own structure.

### 🧹 Cleanup
- [Changed] Fixed a hardcoded `X_success = true` anti-pattern across `cc_event_controller.lua`, `alienattack.lua`, `headhunter.lua`, and `spawntravellingmerchant.lua` that always reported a soft dependency include as successful regardless of whether it actually loaded; now correctly reflects the real `pcall(include, ...)` result.
- [Changed] Added missing localization markers (`%_t`) in `eclipseloredialog.lua` and `ancientcachedialog.lua`, and removed a dead redundant `callable(nil, "tooFar")` registration in `eclipseloredialog.lua`.
- [Changed] Removed a dead, unused `local EclipseLoot = {}` table and a dead commented-out `include()` in `factionattackssmugglers.lua`.

## [v3.1.4]

### 🪲 Bug Fixes
- [Bugfix] **Ghostship Exploit:** Fixed an infinite credit-farming exploit where the Ghostship event would repeatedly trigger upon reloading the sector. The event script is now safely purged from the engine's background simulation immediately upon looting the derelict. 
- [Feature] **Cinematic Explosions:** Added a massive client-side explosion effect that triggers immediately after looting the ghostship to provide visual feedback before the entity is deleted.

## [v3.1.3]

### 🪲 Bug Fixes
- [Bugfix] **Hidden Stash Crash & Performance:** Fixed a fatal crash in `cc_hiddenstash.lua` and `cc_blackbox.lua` caused by an invalid `SectorGenerator:getFactionIndex()` engine call. Drastically improved the sector generation performance by pulling the expensive `SectorGenerator` instantiation out of the asteroid spawning loops and properly adding a `terminate()` shutdown method to clear memory. Added proper translation hooks (`%_T`) for the broadcast messages.
- [Bugfix] **Global Wrapper Cleanup:** Cleaned up `cc_eclipselore.lua` and `cc_hiddenstash.lua` to remove deprecated pseudo-namespace global wrappers and redundant `initialize` wrappers, strictly enforcing the Code Review Protocol to prevent callback conflicts.

## [v3.1.2]

### 🪲 Bug Fixes
- [Bugfix] **Server Crash Prevention:** Fixed a critical server-side crash in `cc_blackbox.lua`, `ghostshipdialog.lua`, and `ancientcachedialog.lua` caused by the script improperly invoking `Sector():createExplosion()` on the dedicated server thread. The visual explosions have been safely decoupled or removed, ensuring the loot containers are successfully deleted at the end of the event.
- [Bugfix] **Ghost Ship Turret Errors:** Fixed a scripting error in `cc_ghostship.lua` where the engine attempted to call a non-existent `removeTurret` function. Turrets attached to the ghost ship are now safely and natively deleted from the sector.

## [v3.1.1]

### 🪲 Bug Fixes
- [Bugfix] **Generator Memory Leaks:** Fixed an issue in `cc_eclipselore.lua` and `cc_ancientdatacache.lua` where the generator script would permanently attach to the sector context if it hit an early return trap, causing background memory leaks over time.
- [Bugfix] **Generator Crash Check:** Added a `valid()` safety check to the Eclipse Lore and Ancient Data Cache generation scripts to ensure the engine fails gracefully instead of crashing if a wreckage plan fails to load.

## [v3.1.0]

### ⭐ Features
- **Newsboard Bounties:** The Galactic News Network will now occasionally post physical bounties for pirate leaders with exact coordinates! Hunt them down to claim a massive reward!
- **Derelict Log Fragments (Rift Exchange):** Ancient Data Caches now yield "Encrypted Log Fragments". You can trade these fragments at any Research Station for large sums of credits and a reputation boost!
- **Refugee Dialogue Tips (Stash Spawns):** When donating supplies to a Refugee Convoy, there is now a 25% chance they will tip you off to a massive hidden stash of resources and upload the coordinates to your map!

## [v3.0.8]

### 🪲 Bug Fixes
- [Bugfix] **Fire Rate API Error:** Fixed a core mathematical error inside the Rogue AI Probe event where extreme `FireRate` multipliers were being accidentally applied as flat additive numbers instead of percentages, preventing the probe from properly scaling its weapon attack speed.

## v3.0.7

### 🐛 Bug Fixes & Refactoring

- [Fixed] **Event Routing Desync Fix**: Following a strict architecture audit, a widespread event-routing violation was resolved across 6 scripts (`cc_factionmonument.lua`, `cc_refugeedialogue.lua`, `storybulletins.lua`, `cc_newsboard.lua`, `cc_destructiontracker.lua`, and `cosmicchronicles.lua`). These scripts were incorrectly defining global wrappers for standard engine callbacks (like `onInteract`, `initialize`, `onEntityDestroyed`), which shadowed the native namespace hooks. All illegal global wrappers have been permanently stripped so these modules securely and natively bind to the engine via their official namespace.

## v3.0.6

### 🔧 Balancing & Gameplay

- [Balance] **Empty Sector Density:** Massively reduced the spawn probabilities for deep space ambient events (Ghost Ships, Datacaches, Refugees, Rogue AI Probes) in `cc_event_controller.lua`. Empty sectors will now remain significantly more barren, returning a sense of eerie isolation to deep space exploration and making rare events feel genuinely special.

## v3.0.5

### 🐛 Bug Fixes
- [Fixed] **AI & Loot Logic:** Fixed various files with faulty AI and loot logic.
- [Fixed] **Namespace RPC Registries:** Fixed a critical structural flaw across `cosmicchronicles_rumormonger.lua`, `cc_refugeedialogue.lua`, `cc_factionmonument.lua`, and `cc_blackbox.lua` where multiple server dialogue callbacks were using global scope wrappers instead of the required namespace-aware `callable` registries. This previously prevented the Avorion C++ engine from properly routing `invokeServerFunction` calls to these systems, silently aborting station dialogues, monument inscriptions, and deep-space events.
- [Fixed] **Dynamic Reward Payout Crash:** Patched a severe bug in `cc_refugeedialogue.lua`, `cc_blackbox.lua`, and `diplomatdialog.lua` where dynamic credit rewards (Hazard Pay, Smuggled Goods, and Recovered Credits) utilized the unstable `player:receive()` API overload. The engine would occasionally fatally crash upon attempting to award credits. This has been completely replaced with direct property assignment (`player.money = player.money + ...`), permanently securing the reward payout.
- [Fixed] **Rogue AI Probe Timer:** Fixed a script pathing error in `cc_rogueaiprobe.lua` where the intended `warpawaytimer.lua` script did not exist. It has been replaced with the engine-native `delayeddelete.lua` utility, ensuring the Rogue AI Probe properly hyperspaces away if not destroyed within 3 minutes.

### 📦 Content Additions
- [Added] New .xml designs for events, lore and missions.

## v3.0.4

### 🐛 Bug Fixes

- [Fixed] **Guardian Event Disruption:** Fixed a critical bug in `cc_event_controller.lua` where calculating the entity count of an empty sector would throw a `length of a nil value` exception. This background crash was silently halting the global sector update loop, completely preventing the Wormhole Guardian flavor text and events from triggering upon entering the core.
- [Fixed] **Xsotan Distress Calls:** Fixed a bug in `cc_diplomatescort.lua` and `cc_refugeeconvoy.lua` where the script would grab "The Xsotan" as the nearest faction when triggered deep inside the galactic core. Refugees and diplomats will no longer accidentally spawn as disguised Xsotan vessels!
- [Fixed] **Infinite Loot Exploit:** Patched a severe multiplayer exploit in `ancientcachedialog.lua`, `eclipseloredialog.lua`, and `ghostshipdialog.lua` where players could use macros to rapidly spam the dialogue options, forcing the server to drop hundreds of loot instances before the cache entity was fully deleted at the end of the server tick.

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
- [Fixed] **Eclipse Anomaly Rarity Crash:** Fixed a critical bug where looting an Ancient Eclipse Anomaly would cause the `upgradegenerator.lua` script to crash due to a mismatch in the Rarity parameter arguments.
- [Fixed] **Eclipse Anomaly VFX Crash:** Fixed a dedicated server crash where the Anomaly was incorrectly trying to broadcast a client-only explosion effect on the server thread.
- [Fixed] **Multiplayer Exploit Prevention:** Added missing RPC callable registrations to prevent a silent error when the server attempted to warn players they were too far away from the Anomaly.
- [Fixed] **Research Station Hook:** Fixed a VFM script injection failure that was completely overwriting the vanilla `initUI` namespace in `researchstation.lua`, preventing the new Log Fragment turn-in interaction from ever appearing.
