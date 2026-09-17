# 🪐 Cosmic Chronicles

*A dynamic narrative and living-galaxy expansion for Avorion.*

![Version](https://img.shields.io/badge/version-3.2.3-6f42c1?style=flat-square)
![Avorion](https://img.shields.io/badge/Avorion-2.5.13-2f81f7?style=flat-square)
![License](https://img.shields.io/badge/license-GPLv3-informational?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey?style=flat-square)
![Requires](https://img.shields.io/badge/requires-Core%204-success?style=flat-square)

> [!TIP]
> New here? [`PLAYER_GUIDE.md`](PLAYER_GUIDE.md) is a friendly gameplay tour. [`WIKI.md`](WIKI.md) has the full technical reference with exact numbers.

## 📖 Overview

Cosmic Chronicles turns verified events from the Cosmic series into a galaxy that talks back. Station chatter reacts to conflict, weather, Rift activity, Eclipse activity, faction wealth, geography, and player reputation. Deep-space stories grow from real wars, crises, hazards, and discoveries. The Galactic News Network keeps those reports in a searchable newsroom with persistent personal read state.

## ✨ Features

<details>
<summary><b>Click to expand features</b></summary>

- **The Rumormonger:** context-aware station chatter and rumors selected from a shared, versioned catalog. Recent-line memory limits repetition, while nearby News, War Heat, weather, Rift conditions, Eclipse state, geography, faction traits, and reputation shape what fits.
- **Galactic News Network:** Live Feed, Chronicle, and Saved Leads views with source/topic/status filters, search, four-column headlines, developing story threads, locations, outcomes, and persistent individual/Mark All read state. Source and severity text keep the interface readable without relying on color alone.
- **Deep Space Events:** Refugee Convoys, Derelict Graveyards with Black Box extraction, Cinematic Monuments, Ancient Data Caches, Rogue AI Probes, Stranded Diplomats, Ghost Ships, and Ancient Eclipse Anomalies. Events are queued from verified facts, materialized on natural sector entry, and correlated by stable event IDs.
- **Captain's Logs:** Cosmic Overhaul mission reports get a narrative log appended, written to match where the captain actually went.
- **Captain Synergies:** Scavengers and Explorers pull more value out of Black Boxes, Merchants and Smugglers profit differently from a refugee rescue, and Smugglers and Explorers can talk their way past a hostile station.
- **Safe persistence:** event materialization, interaction costs, rewards, publications, and milestone bonuses use receipts. An interrupted result that cannot be proved becomes visible repair work instead of repeating a charge or reward.
- **Deep Integration:** Vault, War, Overhaul, Ascendancy, and Chronicles publish through one News lifecycle. Starfall is not part of this integration.

</details>

## 🌌 Cosmic Vault Synergy

<details>
<summary><b>Click to expand</b></summary>

Cosmic Chronicles is built on the shared **Cosmic Vault** APIs:

- **News v2:** Vault stores stable source/event identities, developing threads, revisions, audience, location, expiry, and outcomes. Retries update the same report instead of duplicating it.
- **Dialogue v2:** Vault owns the shared catalog across Avorion's separate script VMs. Chronicles adds player-specific repetition memory and presentation.
- **Materialization queues:** Chronicle events are recorded before anything spawns and complete only after tagged entities and scripts are verified.
- **Records and repair:** JSON-backed Vault records keep Chronicle state within Avorion's primitive custom-value rules. `/chroniclesstatus` reads canonical health; administrators can dry-run and apply explicit repairs with `/chroniclesrepair`.

</details>

## ⚙️ Requirements

- **Avorion** 1.0+
- **Required:** `Cosmic Vault`, `Cosmic Overhaul`, `Cosmic War`, and `Cosmic Ascendancy` — Cosmic Chronicles is one of the Core 4, and the Core 4 require each other plus Vault.

`modinfo.lua` directly declares Vault, Overhaul, and War; Ascendancy is required through Cosmic Chronicles' Steam Workshop "Require Items" listing instead, the same way the rest of the Core 4 require each other — Avorion throws a circular-dependency error if the Core 4 try to cross-declare each other's `modinfo.lua` in every direction.

## 🚀 Installation

1. Place the folder in:
   - **Windows:** `%AppData%\Avorion\mods\`
   - **Linux:** `~/.avorion/mods/`
2. Enable **Cosmic Chronicles** in **Settings → Mods**.
3. Restart Avorion when prompted.

## 📚 Documentation

| Document | For | Covers |
|---|---|---|
| [`PLAYER_GUIDE.md`](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Players-Guide-The-Living-Galaxy) | Players | A plain-English walkthrough of every feature. |
| [`WIKI.md`](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Features-and-Enhancements) | Anyone who wants the exact numbers | Complete technical reference. |
| **Cosmic Codex** *(in-game)* | Players | Mechanics and lore, readable without leaving the game. |

---

<div align="center">

**🪐 Cosmic Chronicles** — part of the [Cosmic Series](https://github.com/Stormiebox) · built by **Stormbox**

</div>
