# Cosmic Chronicles

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**Cosmic Chronicles** is the narrative, world-building, and lore module of the Cosmic mod series for Avorion.

This mod acts as a dynamic "Living Galaxy" text system, feeding atmospheric dialogue, ambient chatter, and dynamic rumors to players based on their reputation, current sector, and local faction states. It translates the abstract background math of the Cosmic ecosystem into human stories.

---

## 🚀 Core Features (v1.1.0)

- **The Rumormonger System:** Dynamic dialogue and ambient chatter injected into stations and merchants that react live to Faction Wealth, Geography, and War Heat.
- **Captain's Logs:** Narrative event logs appended to operation report mails, reacting to the dangers and anomalies your captains encounter during background commands.
- **Dynamic Events:** Experience deep-space flashpoints like *Refugee Convoys* and *Derelict Graveyards* complete with Black Box extractions.
- **Vault Powered:** Built seamlessly on top of the shared `Cosmic Vault` dialogue API framework, making it highly modular and extensible for other modders.

---

## 🛠️ Installation & Dependencies

Cosmic Chronicles requires the core Cosmic simulation mods to function properly, as it reads their background data to generate its narrative context.

1. Place the mod folder into:
   - **Windows:** `%AppData%\Avorion\mods\`
   - **Linux:** `~/.avorion/mods/`
2. Ensure the following **required dependencies** are installed:
   - **[Cosmic Vault]** (Core API)
   - **[Cosmic Overhaul]** (Required for Captain's Logs)
   - **[Cosmic War]** (Required for War Heat synergy & events)
3. Enable **Cosmic Chronicles** (alongside its dependencies) in **Settings -> Mods**.
4. Restart the game/server when prompted.

---

## ⚙️ Compatibility Snapshot

- `serverSideOnly = false`
- Heavily relies on **Cosmic Vault** for its core API injections. Failsafes (`pcall`) are built into hard-hooks to prevent crashes if a dependency drops, but the narrative experience will be heavily degraded.
- Seamlessly supports custom stations and modded factions by falling back to generic lore categories when unique traits cannot be identified.
- Fully localized in 7 languages (Chinese, German, Russian, Portuguese, French, Japanese, and Spanish).
- For full dependency specifics, see `modinfo.lua`.
