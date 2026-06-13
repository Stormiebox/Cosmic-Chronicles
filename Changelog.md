# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

--

## v2.1.0 (CURRENT PROJECT VERSION - NO RELEASE DATE YET!)

### Added
- **Vanilla Story Quest Migration**: Massively ported and modernized all 21 core Avorion story quests directly into the unified Cosmic Codex API.

- Fully integrated with the Cosmic Vault API framework.
- Swept codebase for legacy callbacks and implemented safe pcall fallbacks.


### LEGACY LOGS BELOW - KEPT FOR HISTORICAL PURPOSES!

# 2.0.1

- **Hotfix:** Removed duplicate base-game translation strings from the mod's localization files to prevent  inygettext collision warnings from spamming the client log.

# Cosmic Chronicles - Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [v2.0.0] - 2026-06-07

### Fixed

- **Engine Bootstrap Compliance:** Removed invalid `initialize()` wrappers inside `player/init.lua` and `entity/init.lua`. Wrapping the payload inside a function was causing the UI hooks and rumormonger logic to fail to inject on fresh saves.
- **Galactic News Network Crash:** Refactored `cc_newsboard.lua` to stop calling `Server().invokeFunction` (which doesn't exist in the Avorion API). Communication with the Vault news server now securely passes through Avorion's native global event bus via `Server():sendCallback()`.
- **UI Crash:** Removed an invalid `fontSize` assignment on a TextBox component in `cc_newsboard.lua` that was causing the client to instantly crash when attempting to render the Galactic News tab.
- **Compliance Fix:** Wrapped core injection files (init.lua) safely to prevent them from wiping out vanilla initialization scripts.
- **Procedural News State Persistence:** Fixed a bug in `cc_newsgenerator.lua` where the generator would spam duplicate Boss Kill articles after every server restart. The generator now correctly uses `secure()` and `restore()` lifecycle functions to remember which bosses it has already reported on.
- **Vanilla Boss Variables:** Fixed a bug in `cc_newsgenerator.lua` that was querying incorrect internal variable names (e.g. `swoks_defeated`), preventing it from tracking boss kills dynamically during gameplay. It now queries the correct native Avorion variables.

### Added

- **Galactic News Board:** A brand new dedicated "News" tab has been added to the Player Window!
  - Generates random, dynamic news articles every 15 real-time minutes based on the current state of the galaxy.
  - **Cosmic War Synergy:** Tracks local War Heat. If heat hits critical levels, it publishes High-Value Bounties (giving players a target to hunt). Otherwise, it reports on frontline sector shifts.
  - **Cosmic Overhaul Synergy:** Actively tracks faction wealth levels to publish "Trade Crises" (shortages) and "Market Booms", guiding Merchant captains to profitable sectors. Occasionally spotlights the feats of a random online player's Captain!
  - **Vanilla Avorion Synergy:** Tracks core progression. The moment a server defeats Swoks, the AI, the MAD Science Lab, or the Guardian, a massive server-wide breaking news article is permanently published.
  - **Historical Backfilling (Self-Healing):** When installed mid-playthrough, the system intelligently scans the `Server` and `Player` database for previously killed vanilla bosses (Swoks, Big AI, Project Beta, Bottan, MAD Scientist, The 4, Guardian, Pirate Hideouts) and backfills them into the news history so older saves don't miss out on past lore.
  - Keeps a rolling server-wide buffer of the latest 30 articles, broadcasting them directly to all players to deeply immerse them in the ecosystem's background math.
- **Galactic News Expansion (Narrative Events):** Narrative events (Derelict Graveyard, Refugee Convoy Exodus, Monument Discovery) now push immersive lore articles to the Galactic News Network when triggered.
- **Galactic News Expansion (Vanilla Events):** Safely integrated proxy hooks into standard Vanilla Avorion events without overwriting base game files. The News Network now tracks and reports on Xsotan Invasions, Smuggler Outpost Raids, Traveling Merchant Caravans, and Bounty Hunter deployments.
- **Galactic News Expansion (Vanilla DLC):** Safely integrated proxy hooks for the Behemoth DLC. The News Network now broadcasts massive warnings when a Behemoth spawns, and will report on either the sector's total destruction or the Behemoth's defeat.
- **Vanilla Rumormonger Integration:** Hooked into Avorion's native `storyhints.lua` script. When players ask station NPCs "Anything interesting around here?", there is now a 60% chance they will dispense context-aware Cosmic Chronicles lore (based on war heat, local wealth, and distance to the core) instead of a generic vanilla rumor.
- **Vanilla Ambient Chatter Integration:** Hooked into Avorion's native `radiochatter.lua` script. Context-aware Cosmic Chronicles ambient lines are now seamlessly injected into the background chatter pools of all vanilla civilian, military, and event ships across the galaxy.

- **Translation Additions:** Added in new translation strings in all .po files for all available languages. Spanish, German, French, Japanese, Chinese, Russian and Portuguese.

### Changed

- **Event Reward Re-balancing (Compliance Fix):** To strictly comply with the mod's core philosophy as a pure "Lore and Narrative" expansion, the heavy material payouts from dynamic events have been significantly balanced to prevent economy inflation:
  - **Black Box Extracts:** Reduced the massive credit payouts from 75k-150k down to a balanced 15k-35k. Upgrades dropped are now guaranteed Uncommon (with a 15% chance to be Rare) rather than guaranteed Rare/Exceptional. Scavenger/Explorer Captain synergies still apply to these new baselines.
  - **Refugee Convoys:** The instant reputation reward for donating supplies has been reduced from +10,000 to a more reasonable +2,500. Merchant and Smuggler hazard pay synergies have been lowered from 75k/100k to 25k/35k.

- **Galactic News UI Overhaul:** Upgraded the News Board UI from a standard text box to a native Avorion `MultiLineTextBox`. Articles now word-wrap perfectly and support vertical scrolling, significantly improving readability.
- **Real-Time News Synchronization:** The News Board now actively listens for the `onCosmicVaultNewsUpdated` client callback from the Vault. Players can leave the Galactic News tab open and watch articles pop into the list in real-time.
- **Graceful Loading:** Added a "Connecting to Galactic News Network..." fallback message while the client waits for the initial asynchronous server data fetch.
- **Event Stability & Standardization:** Bypassed the brittle `CosmicVaultNews` library wrapper entirely across all dynamic events and Vanilla Behemoth DLC hooks. The mod now natively pushes news straight to the engine via `Server():sendCallback("onCCNewsPublishArticle")`, guaranteeing perfectly stable article delivery regardless of load order.

### Removed

- **Texture Folder:** All textures were removed and migrated into `Cosmic Vault`.

## [v1.1.0] - 2026-05-30 In Sync with Cosmic Overhaul v4.0.0 Development

### Added

- **Captain Synergies (Events):** Integrated Cosmic Overhaul Captain Classes into deep-space events:
  - *Scavenger & Explorer:* Extract 25-50% more value and have a higher chance to pull *Exceptional* system upgrades from Black Boxes.
  - *Merchant & Smuggler:* Can aggressively negotiate Hazard Pay or skim Smuggled Goods (75,000-100,000 credits) when rescuing Refugee Convoys.
  - *Smuggler & Explorer:* Can quietly extract rumors from highly hostile stations (down to -60,000 reputation).
- **Monument Reputation Synergy:** Reading a faction's Cultural Monument for the first time now grants a +1500 reputation boost and a satisfying ship computer notification.
- **Immersive Tutorialization:** Added brand new highly-thematic rumors and ambient chatter lines to naturally teach players about the new v4.0.0 Cosmic Overhaul mechanics (Merchant/Smuggler synergies, Trash Man filters, and Scavenger Wreckage intel).
- **Localization Expansion:** Updated the translation template and all 7 supported language `.po` files with the new event interactions and synergy rumors.
- **Native Radio Chatter Integration:** Hooked directly into Avorion's native radio chatter engine! NPC Freighters, Miners, and Military Patrols will now seamlessly broadcast dynamic Cosmic lore based on their local economy, war heat, and your reputation, bringing the entire galaxy to life without the need for heavy custom background loops.

### Fixed

- **Virtual File System Compliance:** Fixed an architectural flaw where `pcall(require)` was bypassing Avorion's VFS to check for *Cosmic War* in background scripts. All cross-mod bridges now correctly use `pcall(include)`. In case cosmic mods like *Cosmic War* isn't loaded.
- **Translation Scaling:** Verified and corrected all string format injections across the event scripts to ensure variables resolve dynamically without breaking the `.po` scanner.
- **Broken Event Path:** Fixed a critical bug where the `cc_event_controller.lua` was failing to correctly identify and trigger events due to an incorrect path in the `Player():addScriptOnce` call inside `player/init.lua` for the `cc_event_controller.lua` script, causing events to never trigger. This was due to a missing leading slash in the script path, which prevented the script from being found.
- **Dead Initialization File:** Fixed a silent failure where the player hook was located in `player/background/init.lua`. It has been moved to the engine-compliant `player/init.lua` so the game actually executes it.
- **Client-Side Translation Traps:** Fixed severe UI thread crashes in `cc_refugeedialogue.lua`, `cc_blackbox.lua`, `cc_factionmonument.lua`, and `cosmicchronicles_rumormonger.lua` where the UI attempted to perform arithmetic on C++ `Format` userdata objects instead of strings.
- **Server-Side Translation Traps:** Fixed a Server-Side Translation Trap in `command.lua` where concatenating the Captain's Log text in Lua broke the C++ `Format` object, permanently locking operation mails into English.
- **Captain's Log Context Bug:** Fixed a massive logic failure in `command.lua` where the script passed an empty context table to the Vault API, preventing almost all Captain's Logs from ever spawning.
- **Alliance Operation Mail Bug:** Fixed a bug in `command.lua` where players commanding Alliance fleets would never receive their operation reports by correctly passing the `getParentFaction()` context.
- **Event VFS Conflict:** Renamed `cw_refugeeconvoy.lua` and `cw_derelictgraveyard.lua` to `cc_` prefixes to prevent Avorion's Virtual File System from silently overwriting them if *Cosmic War* was also installed.
- **Graveyard Missing Import:** Fixed a critical silent crash in the Derelict Graveyard event caused by a missing `SectorGenerator` import, which prevented Black Boxes from ever spawning.
- **Multiplayer Generation Desyncs:** Replaced all instances of native `math.random` in the event scripts with the engine-safe `random():getInt()` to prevent multiplayer server/client desyncs.
- **Black Box Silent Loot Bug:** Fixed a bug where `UpgradeGenerator` was improperly instantiated, causing the script to fail silently and never actually reward players with system upgrades.

### Changed

- **Rumormonger Rebalance:** Increased the frequency of custom lore chatter to better compete with vanilla dialogue. The background loop now ticks every 35 seconds (down from 60), global sector cooldown is reduced to 30 seconds, and speech probability increased to 50%.
- **Lore Conditions:** Added baseline reputation (`minReputation`) and geographic (`minDistanceToCenter`) conditions to several generic rumors to prevent hostile military outposts or deep-core stations from offering out-of-character dialogue.
- **Performance Optimization:** Pre-cached station script types in `init.lua` to prevent expensive `hasScript()` calls during every Rumormonger tick.
- **Black Box Scaling:** Credits and system upgrades recovered from Derelict Graveyard black boxes now correctly scale based on distance from the galactic core.
- **Cinematic Monuments:** Scaled procedural Cultural Monuments up by 2.5x to make them genuinely massive and awe-inspiring, adjusted their spawn offset so they ping reliably on radar, and added a Ship Computer broadcast warning when players enter their sector.

---

## [v1.0.0] - Ready For Launch - Development Continues

### Added

- **Core Architecture:** Setup the initial mod structure, dependencies, and `init.lua` hooks.
- **Vault API Integration:** Hooked into `CosmicVaultDialogue` to support rich context filtering for lore strings.
- **The Rumormonger:** Added `cosmicchronicles_rumormonger.lua` to stations. Features a 60-second interval background chatter loop (overhead floating text) and a direct interaction dialogue menu.
- **Dynamic Context Feeder:** The Rumormonger now actively parses:
  - Live `War Heat` from the `Cosmic War` bridge.
  - Faction Economy (`wealthy` / `poor`).
  - Station Type (dynamically identifies 12+ vanilla station scripts).
  - Distance to the galactic core.
- **Lore Database:** Registered over 60+ unique lore strings covering ambient chatter and rumors, sorted meticulously by station type and political climate.
- **Captain's Logs:** Intercepted `Cosmic Overhaul` map simulation commands (`command.lua`) to dynamically append narrative logs to the bottom of operation report mails.
- **Global Event Controller:** Created `cc_event_controller.lua` to listen for hyperspace jumps and trigger narrative flashpoints in deep space.
- **Event: Refugee Convoy:** Spawns fleeing civilian ships in high-tension regions. Includes a custom interactive dialogue script (`cc_refugeedialogue.lua`) allowing players to donate Food/Medicine for rewards.
- **Event: Echoes of the Frontline:** Spawns massive, persistent wreckage fields in sectors with extreme War Heat (`cw_derelictgraveyard.lua`).
- **Black Box Extraction:** Added a custom stash script (`cc_blackbox.lua`) inside graveyards that allows players to extract the final narrative logs of doomed fleets alongside rare loot.

### Localization

- **Translation .po files:** Added and translate all dialogues, events, lore and logs for all supported languages. Chinese, German, Russian, Portuguese, French, Japanese and Spanish.

### Fixed

- Restructured file paths to perfectly align with Avorion's strict VM boundaries (`entity/`, `events/`, `player/`).
- **cc_event_controller.lua**: Prevented an infinite event farming loop by setting a persistent vanilla `cc_event_spawned` flag to the sector.
- **cw_derelictgraveyard.lua**: Fixed an issue where derelict ships disappeared instantly by reverting to proper C++ physics engine destruction, leaving behind standard wreckage and explosion VFX.
- **cc_spawnmonument.lua**: Fixed hyperspace collisions by adding a randomized offset to the spawn coordinates, and corrected the invulnerability hook to use the proper Avorion API (`station.invincible = true`).
- **cc_blackbox.lua**: Resolved a silent Lua C++ Type crash by correctly passing `random():createSeed()` instead of a boolean to `UpgradeGenerator`.
