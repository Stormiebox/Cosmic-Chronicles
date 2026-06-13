# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Never remove, overwrite or write above this

## v3.0.0 (CURRENT PROJECT VERSION - NO RELEASE DATE YET!)

### UI & Codex
- **Cosmic Codex Integration:** The mod now fully supports the Cosmic Codex! Comprehensive lore and mechanical documentation (such as features, UI tools, and dynamic events) are now readable directly in-game from the new Cosmic Codex tab.

### Bug Fixes & Compliance
- **Engine Freeze & Lockup Prevention:** Fixed a catastrophic script error inside `spawnrandombosses.lua` where a `while true do` loop lacked a failsafe iteration cap. This previously caused the entire Dedicated Server process to lock up 100% CPU and freeze during late-game boss anomaly generation.
- **Pathing Crash Hazards:** Repaired illegal absolute `include()` path injections (`include("data/scripts/entity/story/hermit")`) inside `crossthebarriermission` and `hermitmission` that could violently crash the server context.
- **Multiplayer Networking:** Added `onClient()` wrappers to the Exodus Wormhole Beacon UI to prevent the local singleplayer thread from self-invoking networking callbacks.
- **Performance & TPS Optimization:** Drastically reduced server load during late-game scenarios. Injected a hardcoded `getUpdateInterval` throttle (1.0s) into `buymission.lua` and `hermitmission.lua` to prevent the engine from polling the sector 60 times a second for these story encounters.
- **Desyncs:** Replaced `math.random` with `random():getInt()` inside `cc_rogueaiprobe.lua` and other event generators. This prevents physics desyncs and invisible collisions in multiplayer.

### Added
- **Deep Space Event: The Ghost Ship**: Discover intact derelicts with corrupted logs and hidden compartments. Captain Synergy: Scavengers find extra loot, Explorers decrypt coordinates.
- **Deep Space Event: Rogue AI Probe**: A fast, evasive anomaly scaling in difficulty near the core. Destroy it before it warps away for rare technology.
- **Deep Space Event: Diplomatic Escort**: Escort a stranded VIP across sectors. Captain Synergy: Diplomats negotiate massive payouts, Smugglers bypass patrols.
- **Deep Space Event: Ancient Data Caches**: Discover ancient vaults near the core to gain permanent buffs and massive Xsotan lore drops.
- **Deep Space Sector Generation: Eclipse Lore**: Replaced empty sectors with the chance to find Eclipse Beacons, Shipwrecks, and Stashes yielding deep lore and core-scaled loot.
- **Galactic News: The Stock Market**: The News Board now actively scans and reports on extreme economic supply/demand disparities, creating dynamic trading opportunities.
- **Vanilla Story Quest Migration**: Massively ported and modernized all 21 core Avorion story quests directly into the unified Cosmic Codex API.

- Fully integrated with the Cosmic Vault API framework.
- Swept codebase for legacy callbacks and implemented safe pcall fallbacks.