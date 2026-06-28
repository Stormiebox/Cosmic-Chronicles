# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Never remove, overwrite or write above this

## v3.0.0 UNRELEASED WORKSHOP VERSION (PROJECT UNDER DEVELOPMENT)

### 🌌 Cosmic Vault Synergy (Cross-Mod Engine)
- **Deep Economy Integration:** Ambient Galactic News events (Trade Crisis & Market Boom) are no longer just cosmetic text. They seamlessly tie into the `CosmicVaultEconomy` API, natively spiking or dropping a faction's active Famine Score.
- **Dead Empire Filter:** Galactic News Generation natively utilizes `FactionEradicationUtility` to strictly filter out destroyed empires, preventing ghost factions from broadcasting messages.
- **Post-Boss Anomalies:** Upon destroying the infamous Bottan Dreadnought, the game natively invokes `CosmicVaultAnomalies` to spawn a persistent `SpatialRift` anomaly for advanced exploration.
- **Unified News API:** Refactored multiple legacy news broadcasting systems to securely pass through the new `CosmicVaultNews.publishArticle` architecture for global validation.

### 🚀 Improved & Upgraded
- **Updated:** Global Compliance and API updates across various scripts.
- **Vault Integration:** Assured full compatibility with the new CCM 3-Column layout and Keybind systems.


### 🪐 Major Overhaul Features
- **Vanilla Story Quest Migration:** Massively ported and modernized all 21 core Avorion story quests directly into the unified Cosmic Codex API.
- **Cosmic Codex Integration:** The mod now fully supports the Cosmic Codex! Comprehensive lore and mechanical documentation (such as features, UI tools, and dynamic events) are now readable directly in-game from the new Cosmic Codex tab.

### ➕ Added
- **Deep Wiki Integration:** Hooked the Rumormonger and Captain's Log systems directly into the Cosmic Codex to explain their dynamic narrative mechanics natively in-game.
- **Deep Space Event: The Ghost Ship:** Discover intact derelicts with corrupted logs and hidden compartments. Captain Synergy: Scavengers find extra loot, Explorers decrypt coordinates.
- **Deep Space Event: Rogue AI Probe:** A fast, evasive anomaly scaling in difficulty near the core. Destroy it before it warps away for rare technology.
- **Deep Space Event: Diplomatic Escort:** Escort a stranded VIP across sectors. Captain Synergy: Diplomats negotiate massive payouts, Smugglers bypass patrols.
- **Deep Space Event: Ancient Data Caches:** Discover ancient vaults near the core to gain permanent buffs and massive Xsotan lore drops. Now dynamically loads a bespoke, ancient monolithic structure instead of procedural scrap.
- **Deep Space Sector Generation: Eclipse Lore:** Replaced empty sectors with the chance to find Eclipse Beacons, Shipwrecks, and Stashes yielding deep lore and core-scaled loot. Beacons, Stashes, and Monuments now generate massive, customized `.xml` megastructures.
- **Galactic News: The Stock Market:** The News Board now actively scans and reports on extreme economic supply/demand disparities, creating dynamic trading opportunities.
- **Cosmic Vault API Framework:** Fully integrated with the Cosmic Vault API framework. Swept codebase for legacy callbacks and implemented safe pcall fallbacks.

### ⚖️ Balance
- **Galactic Turn Synchronization:** The Stock Market background simulation interval has been synced to the global 20-minute (1200s) server turn to improve dedicated server performance.

### 🐛 Bug Fixes & Optimization
- Removed `pcall` soft-dependencies. Core 5 mods are now hard requirements.
- **Cosmic Codex Loading Crash:** Fixed missing global definitions (e.g. `entities`, `rangeType`) in the codex files that prevented the encyclopedia from loading correctly and crashed the UI.
- **Dynamic Event Spawn Logic:** Patched structural logic issues in the Ghost Ship, Stock Market, and Eclipse Lore scripts where float probability checks were being compared against `random():getInt()`, ensuring accurate event triggers globally.
- **Eclipse Lore Spawn Rate:** Fixed a math logic bug where `random():getInt() > 0.05` mathematically guaranteed an Eclipse Lore spawn almost 100% of the time, replacing it with `getFloat()` to restore the intended 5% rarity.
- **Data Cache Fallback Crash:** Injected a missing `plangenerator` requirement into `cc_ancientdatacache.lua` to prevent the engine from fatally crashing if the new `.xml` plans fail to load and the game attempts a procedural fallback.
- **Engine Freeze & Lockup Prevention:** Fixed a catastrophic script error inside `spawnrandombosses.lua` where a `while true do` loop lacked a failsafe iteration cap. This previously caused the entire Dedicated Server process to lock up 100% CPU and freeze during late-game boss anomaly generation.
- **Pathing Crash Hazards:** Repaired illegal absolute `include()` path injections (`include("data/scripts/entity/story/hermit")`) inside `crossthebarriermission` and `hermitmission` that could violently crash the server context.
- **Multiplayer Networking:** Added `onClient()` wrappers to the Exodus Wormhole Beacon UI to prevent the local singleplayer thread from self-invoking networking callbacks.
- **Performance & TPS Optimization:** Drastically reduced server load during late-game scenarios. Injected a hardcoded `getUpdateInterval` throttle (1.0s) into `buymission.lua` and `hermitmission.lua` to prevent the engine from polling the sector 60 times a second for these story encounters.
- **Desyncs:** Replaced `math.random` with `random():getInt()` inside `cc_rogueaiprobe.lua` and other event generators. This prevents physics desyncs and invisible collisions in multiplayer.
