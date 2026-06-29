# 🪐 Cosmic Chronicles - Detailed Features

Welcome to the **Cosmic Chronicles** official wiki! This page contains the full, detailed documentation for the narrative and lore expansion module in the **Cosmic** mod series.

**Cosmic Chronicles** is designed to:

- Act as the narrative wrapper for the abstract background simulations happening in **Cosmic War** and **Cosmic Overhaul**.
- Provide immersive, dynamic lore through station interactions and events.
- Make the Avorion galaxy feel like a living, breathing universe.

---

## 📜 Table of Contents

- [Mod Identity & Design Goals](#mod-identity--design-goals)
- [Architecture Summary](#architecture-summary)
- [Full Feature Breakdown](#full-feature-breakdown)
- [Dependencies & Compatibility](#dependencies--compatibility)

---

## 🔗 Mod Identity & Design Goals

<details>
<summary><b>View Mod Identity & Core Goals</b></summary>

**Primary Focus:** Injecting dynamic text, dialogue, and narrative events into the galaxy based on backend simulation states.

**Core Goals:**

1. **Contextual Lore:** Rumors and dialogue shouldn't be entirely random; they must reflect the current state of the sector (e.g., War Heat, Faction Wealth, Distance from Core).
2. **Synergy:** Translate the hard math of `Cosmic Overhaul` and `Cosmic War` into human stories.
3. **Immersion:** Add background chatter, derelict logs, and civilian interactions that don't interrupt gameplay but enrich the atmosphere.
4. **Mod-Friendly API:** Utilize `Cosmic Vault`'s dialogue registry so other modders can easily inject their own lore into the Chronicles ecosystem.

</details>

---

## 🔗 Architecture Summary

<details>
<summary><b>View Architecture Details</b></summary>

The mod utilizes a centralized dialogue API (`CosmicVaultDialogue`) to register localized strings categorized by type (e.g., `ambient`, `rumor`, `captain_log`).

When an event or interaction occurs, the mod builds a **Context Table** containing data about the current sector (e.g., `warHeat = 80`, `stationType = "shipyard"`, `economy = "wealthy"`) and requests a valid string from the Vault API. The Vault filters out any lore that doesn't match the context, returning a perfectly tailored narrative snippet. All hard hooks are wrapped in robust virtual file system compliance (`pcall(include)`) to ensure engine stability.

</details>

---

## ⚙️ Full Feature Breakdown

<details>
<summary><h3>The Rumormonger System</h3></summary>

Adds dynamic background chatter and interactive rumor-gathering to all NPC stations in the game. Features a rapidly expanding registry of over 60+ unique, localized lore strings.

**Key Mechanics:**

- **Ambient Chatter:** Stations run a highly optimized 35-second background chatter loop, periodically broadcasting floating overhead text based on their specific type and current situation. (Global sector cooldown is 30 seconds with a 50% speech probability).
- **Interaction:** Players can dock and access a direct dialogue menu to ask "Any rumors?" and receive a dynamic tip.
- **Tutorialization:** The Rumormonger now acts as an immersive guide, occasionally broadcasting tips to teach players about complex mechanics (e.g., Merchant synergies, Trash Man filters) naturally through gameplay.
- **Contextual Awareness:** The Rumormonger actively parses and adapts to:
  - **Station Type:** Dynamically identifies 12+ vanilla station scripts (Pre-cached in `init.lua` for performance).
  - **War Heat:** Pulls live conflict data from the `Cosmic War` bridge.
  - **Faction Wealth:** Differentiates between `wealthy` and `poor` economies.
  - **Geography:** Certain rumors (like Deep Core lore) will not spawn near the Outer Rim.
  - **Player Reputation:** Station inhabitants generally refuse to gossip with outlaws (cuts off at -30,000 rep), preventing hostile military outposts from offering out-of-character dialogue.
  - **Captain Synergy:** Smuggler and Explorer captains know how to quietly buy drinks and extract information even in highly hostile ports (extends interaction threshold down to -60,000 reputation).

</details>

<details>
<summary><h3>Captain's Logs</h3></summary>

Hooks directly into the **Cosmic Overhaul** background command simulation.

**Key Mechanics:**

- When a captain completes a map command (Scout, Mine, Trade, etc.) and sends the player a mail report, a narrative "Captain's Log" is dynamically appended to the bottom of the message.
- **Context Validation:** Logs react directly to the parent faction and sector data where the operation took place. For example, trading in a high `War Heat` sector triggers logs detailing aggressive military patrols or close calls with blockades.

</details>

<details>
<summary><h3>Dynamic Narrative Events & Interactions</h3></summary>

A global event controller (`cc_event_controller.lua`) listens for hyperspace jumps and spawns immersive, world-building events based on the local geopolitical climate.

**Available Events:**

1. **Refugee Convoys:** *(Triggers when War Heat > 40)*. Fleeing civilian ships appear with damaged hyperdrives. Players can open comms and donate Food or Medical Supplies to rescue them, receiving massive reputation boosts and insider rumors in return.
   - **Captain Synergy:** Merchant captains can aggressively negotiate Hazard Pay; Smugglers can quietly skim supplies for massive credit payouts (75,000-100,000 credits).
2. **Echoes of the Frontline (Graveyards):** *(Triggers when War Heat > 80)*. Players jumping into an empty sector may stumble upon massive, persistent wreckage fields—the immediate, blazing aftermath of a massive macro-faction fleet clash.
3. **Black Box Extraction:** Spawns via a custom stash script inside Derelict Graveyards. Players can interact with the Stash to extract the doomed captain's final audio log, alongside high-tier System Upgrades and credits that dynamically scale based on distance to the core.
   - **Captain Synergy:** Scavenger and Explorer captains extract 25-50% more value and have a higher chance to pull *Exceptional* system upgrades.
4. **Cinematic Monuments:** *(Triggers deep inside AI territory)*. Spawns colossal, 2.5x scaled procedural monuments. A Ship Computer broadcast warns players upon entry. Paying your respects by reading the inscription grants a permanent **+1500 reputation boost** with the local faction.
5. **Drifting Ghost Ship:** Players may intercept a faint, repeating distress signal from a derelict freighter drifting silently in space. Boarding/interacting with the ship triggers a narrative dialog script.
6. **Rogue AI Probe:** Spawns a fast, evasive military probe that scales its shields and damage up to 500% based on proximity to the Galactic Core. If players cannot destroy it within 3 minutes, it activates its hyperdrive and escapes with scanned sector data.
7. **Stranded Diplomat:** Emergency civilian broadcast detected. A faction's diplomat is stranded in hostile space after their escort was destroyed. Players must extract them before they are captured.

</details>

---

## 🔗 Dependencies & Compatibility

<details>
<summary><h3>Required Mods</h3></summary>

- **Avorion**
- **Cosmic Vault:** Core dependency for the Dialogue API and context parser.
- **Cosmic Overhaul:** Required for background Captain's Log hooks, Dynamic Economy statistics and Class Synergy detection.
- **Cosmic War:** Required for War Heat synergy and conflict events.

</details>

<details>
<summary><h3>Compatibility Notes</h3></summary>

- File paths are strictly aligned with Avorion's VM boundaries (`entity/`, `events/`, `player/`).
- Engine-safe randomization (`random():getInt()`) is enforced universally to guarantee multiplayer sync.
- Event controllers are uniquely prefixed (`cc_`) to prevent Virtual File System overlap with companion mods.
- Seamlessly supports custom stations and modded factions by falling back to `generic` lore categories when unique traits cannot be identified.

</details>


---

## 🔗 Cosmic Series Integration & Audit 3.0 Updates
<details>
<summary><b>Click to expand</b></summary>

During the Cosmic Series Final QA Audit (v3.0+), several massive backend systems were standardized across all mods:

### 🛠️ Cosmic Codex Integration
All deep lore, stat blocks, and dynamic recipes have been fully integrated into the in-game **Cosmic Codex**. You no longer need to tab out of the game to read these features; they will natively update and unlock inside your Codex UI as you progress!

### 🌌 Cosmic Vault
- **Deep Economy Integration:** Ambient Galactic News events (Trade Crisis & Market Boom) are no longer just cosmetic text. They seamlessly tie into the `CosmicVaultEconomy` API, natively spiking or dropping a faction's active Famine Score.
- **Dead Empire Filter:** Galactic News Generation natively utilizes `FactionEradicationUtility` to strictly filter out destroyed empires, preventing ghost factions from broadcasting messages.
- **Post-Boss Anomalies:** Upon destroying the infamous Bottan Dreadnought, the game natively invokes `CosmicVaultAnomalies` to spawn a persistent `SpatialRift` anomaly for advanced exploration.
- **Unified News API:** Refactored multiple legacy news broadcasting systems to securely pass through the new `CosmicVaultNews.publishArticle` architecture for global validation.

### 🛡️ Network Safety & Anti-Cheat
- **Math.Random Fix:** We systematically replaced all unstable Lua `math.random` calls with Avorion's deterministic `random():getInt()` generation sequence. This guarantees 100% synchronization on Multiplayer Dedicated Servers and prevents cascading desyncs during massive fleet spawns.
- **Callable Validation:** UI and background scripts have been fully hardened. Malicious clients can no longer spoof "free" remote calls; the server actively verifies execution contexts before processing any requests, sealing multiple Arbitrary Code Execution (ACE) vulnerabilities.

### 🛠️ Vanilla Bug Fixes
- **Scout Mission Fix:** We patched a massive, long-standing vanilla bug where Scout Missions would completely skip and ignore Faction Headquarters sectors because the native dialogue trees were missing the template definition.
</details>

## 🔗 Architecture Note
Cosmic Chronicles is now a hard-coded dependency of the Core 5 ecosystem.

## Synergy Update
- **Corrupted Lore Nodes**: Data caches in Eclipse territory offer 2x rewards but instantly spawn a massive Ascendancy ambush.
- **Explorer Resonance**: Ships commanded by an Explorer captain gain a +400% (range 250) interaction range on Black Boxes.
- **Galactic Lore Broadcasts**: Finding a Legendary subsystem or massive credits in a data cache broadcasts your discovery globally via Cosmic Vault News.
- **Famine Relief Anomalies**: Interact with emergency relief caches during severe faction famines to either steal the loot or donate it for massive reputation (+25,000) and instant famine reduction.

