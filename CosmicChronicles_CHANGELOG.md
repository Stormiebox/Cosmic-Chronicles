# Cosmic Chronicles - Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [v2.0.0] - 2026-05-30 In Sync with Cosmic Overhaul v4.0.0 Development

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
