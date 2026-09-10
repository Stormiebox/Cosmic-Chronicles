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

Cosmic Chronicles turns the background math of the Cosmic series into a galaxy that talks back. Station chatter reacts to War Heat and faction wealth instead of looping the same ten vanilla lines. Deep space hides refugee convoys, derelict graveyards, and ancient ruins tied to the state of the world around them. And the Galactic News Network reports on all of it (wars, economies, discoveries, and the rare, galaxy-shaking moments that deserve a Breaking News banner) in a searchable, filterable newsroom tab.

## ✨ Features

<details>
<summary><b>Click to expand features</b></summary>

- **The Rumormonger:** context-aware station chatter and rumors that read War Heat, faction wealth, geography, and your own reputation before deciding what to say. Over 60 unique lines, plus in-character tutorial tips.
- **Galactic News Network:** a searchable, filterable, color-coded newsroom. Seven category groups, live keyword search, a 3-column sortable headline table, session unread tracking, relative headline ages, and a Breaking News system (instant chat alert plus a clickable red banner) reserved for the events that actually matter: Behemoth incursions, boss kills, and a brand-new tracker that reports when an AI empire is wiped out entirely.
- **Deep Space Events:** Refugee Convoys, Derelict Graveyards with Black Box extraction, Cinematic Monuments, Ancient Data Caches, Rogue AI Probes, Stranded Diplomats, Ghost Ships, and Ancient Eclipse Anomalies, each shaped by the current War Heat and faction state.
- **Captain's Logs:** Cosmic Overhaul mission reports get a narrative log appended, written to match where the captain actually went.
- **Captain Synergies:** Scavengers and Explorers pull more value out of Black Boxes, Merchants and Smugglers profit differently from a refugee rescue, and Smugglers and Explorers can talk their way past a hostile station.
- **Deep Integration:** ties into Cosmic War (War Heat, bounty and ceasefire reporting) and Cosmic Overhaul (background commands, economy) so the News Network and Rumormonger reflect what's actually happening in your galaxy.

</details>

## 🌌 Cosmic Vault Synergy

<details>
<summary><b>Click to expand</b></summary>

Cosmic Chronicles is built on the shared **Cosmic Vault** APIs:

- **Economy impact:** ambient News events (Trade Crises, Market Booms) call into `cv_economy` to raise or lower a faction's Famine Score.
- **Dead Empire Filter:** every News broadcast runs through `FactionEradicationUtility` so destroyed empires can't transmit.
- **Post-Boss Anomalies:** defeating the Bottan Dreadnought triggers `cv_anomalies` to spawn a persistent Spatial Rift.
- **Unified News schema:** every article, including the new `breaking` flag, passes through `CosmicVaultNews.publishArticle` for validation shared across the whole series.

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
