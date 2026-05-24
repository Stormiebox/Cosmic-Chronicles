# Cosmic Chronicles - Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog,
and this project adheres to Semantic Versioning.

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