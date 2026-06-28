# 🪐 Cosmic Chronicles - Detailed Features

*A dynamic economy and galactic news simulation.*

## 📖 Overview
Cosmic Chronicles adds a living economy and news network to the galaxy. The Galactic News Network broadcasts real-time events like economic booms, pirate invasions, and trade blockades. The Stock Market allows you to invest in various galactic commodities and faction indices that fluctuate based on these events.

## ✨ Features
<details>
<summary><b>Click to expand features</b></summary>

- **Galactic News Network:** Real-time broadcasts of sector events.
- **Stock Market:** Invest in commodities and watch their prices fluctuate dynamically.
- **Dynamic Local Events:** Gold rushes, trade blockades, and shortages that physically alter sectors and trading profits.
- **Deep Space Discoveries:** Find massive, bespoke `.xml` monoliths, data caches, and lore fragments hidden in uncharted sectors.
- **Deep Integration:** Ties directly into Cosmic War and Overhaul to reflect their events in the news and economy.
</details>

## 🌌 Cosmic Vault Synergy
<details>
<summary><b>Click to expand featuers</b></summary>
Cosmic Chronicles is deeply integrated into the central **Cosmic Vault** APIs:

- **Global Economy Impact:** Ambient Galactic News events (Trade Crises, Market Booms) directly ping `cv_economy` to raise or lower a faction's active Famine levels.
- **Dead Empire Filter:** Galactic broadcasts run through `FactionEradicationUtility` to ensure destroyed empires cannot transmit messages.
- **Post-Boss Anomalies:** Defeating the Bottan Dreadnought triggers `cv_anomalies` to spawn a persistent Spatial Rift.
</details>

## ⚙️ Requirements
- Avorion v2.0+
- Dependencies: **Cosmic Vault, Cosmic Overhaul, Cosmic War and Cosmic Ascendancy**

## 🚀 Installation
1. Place the folder in:
   - **Windows:** `%AppData%\Avorion\mods\`
   - **Linux:** `~/.avorion/mods/`
2. Enable **Cosmic Chronicles** in **Settings -> Mods**.
3. Restart Avorion when prompted.

## 📚 Documentation
For detailed mechanics, guides, and lore, please refer to the in-game **Cosmic Codex**, or check the included `WIKI.md` and `PLAYER_GUIDE.md` files.
