# Cosmic Chronicles - Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

## [v1.1.0] - 2026-05-28

### Fixed

- **Virtual File System Compliance:** Fixed an architectural flaw where `pcall(require)` was bypassing Avorion's VFS to check for *Cosmic War* in background scripts. All cross-mod bridges now correctly use `pcall(include)`. In case cosmic mods like *Cosmic War* isn't loaded.
- **Translation Scaling:** Verified and corrected all string format injections across the event scripts to ensure variables resolve dynamically without breaking the `.po` scanner.
- **Broken Event Path:** Fixed a critical bug where the `cc_event_controller.lua` was failing to correctly identify and trigger events due to an incorrect path in the `Player():addScriptOnce` call inside `player/init.lua` for the `cc_event_controller.lua` script, causing events to never trigger. This was due to a missing leading slash in the script path, which prevented the script from being found.


### Changed

- **Rumormonger Rebalance:** Increased the frequency of custom lore chatter to better compete with vanilla dialogue. The background loop now ticks every 35 seconds (down from 60), global sector cooldown is reduced to 30 seconds, and speech probability increased to 50%.
- **Lore Conditions:** Added baseline reputation (`minReputation`) and geographic (`minDistanceToCenter`) conditions to several generic rumors to prevent hostile military outposts or deep-core stations from offering out-of-character dialogue.
- **Performance Optimization:** Pre-cached station script types in `init.lua` to prevent expensive `hasScript()` calls during every Rumormonger tick.
- **Black Box Scaling:** Credits and system upgrades recovered from Derelict Graveyard black boxes now correctly scale based on distance from the galactic core.

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
