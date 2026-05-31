# Cosmic Chronicles - Detailed Features

Welcome to the **Cosmic Chronicles** official wiki! This page contains the full, detailed documentation for the narrative and lore expansion module in the **Cosmic** mod series.

**Cosmic Chronicles** is designed to:

- Act as the narrative wrapper for the abstract background simulations happening in **Cosmic War** and **Cosmic Overhaul**.
- Provide immersive, dynamic lore through station interactions and events.
- Make the Avorion galaxy feel like a living, breathing universe.

---

## Table of Contents

- [Mod Identity & Design Goals](#mod-identity--design-goals)
- [Architecture Summary](#architecture-summary)
- [Full Feature Breakdown](#full-feature-breakdown)
- [Dependencies & Compatibility](#dependencies--compatibility)

---

## Mod Identity & Design Goals

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

## Architecture Summary

<details>
<summary><b>View Architecture Details</b></summary>

The mod utilizes a centralized dialogue API (`CosmicVaultDialogue`) to register localized strings categorized by type (e.g., `ambient`, `rumor`, `captain_log`).

When an event or interaction occurs, the mod builds a **Context Table** containing data about the current sector (e.g., `warHeat = 80`, `stationType = "shipyard"`, `economy = "wealthy"`) and requests a valid string from the Vault API. The Vault filters out any lore that doesn't match the context, returning a perfectly tailored narrative snippet.

</details>

---

## Full Feature Breakdown

<details>
<summary><h3>The Rumormonger System</h3></summary>

Adds dynamic background chatter and interactive rumor-gathering to all NPC stations in the game. Currently features over 60+ unique lore strings.

**Key Mechanics:**

- **Ambient Chatter:** Stations run a 60-second background chatter loop, periodically broadcasting floating overhead text based on their specific type (e.g., Shipyards complaining about hull plate shortages, Casinos boasting about high rollers).
- **Interaction:** Players can dock and access a direct dialogue menu to ask "Any rumors?" and receive a dynamic tip.
- **Contextual Awareness:** The Rumormonger actively parses and adapts to:
  - **Station Type:** Dynamically identifies 12+ vanilla station scripts.
  - **War Heat:** Pulls live conflict data from the `Cosmic War` bridge.
  - **Faction Wealth:** Differentiates between `wealthy` and `poor` economies.
  - **Geography:** Deep Core vs. Outer Rim lore.
  - **Player Reputation:** Station inhabitants generally refuse to gossip with outlaws (cuts off at -30,000 rep).
  - **Captain Synergy:** Smuggler and Explorer captains know how to quietly buy drinks and extract information even in highly hostile ports (extends interaction threshold down to -60,000 reputation).

</details>

<details>
<summary><h3>Captain's Logs</h3></summary>

Hooks directly into the **Cosmic Overhaul** background command simulation (`command.lua`).

**Key Mechanics:**

- When a captain completes a map command (Scout, Mine, Trade, etc.) and sends the player a mail report, a narrative "Captain's Log" is dynamically appended to the bottom of the message.
- Logs react to the sector they operated in. For example, if they traded in a high `War Heat` sector, the captain will log complaints about aggressive military patrols or close calls with blockades.

</details>

<details>
<summary><h3>Dynamic Narrative Events</h3></summary>

A global event controller (`cc_event_controller.lua`) listens for hyperspace jumps and spawns immersive, world-building events based on the local geopolitical climate.

**Available Events:**

1. **Refugee Convoys:** *(Triggers when War Heat > 40)*. Fleeing civilian ships appear with damaged hyperdrives. Players can open comms (`cc_refugeedialogue.lua`) and donate Food or Medical Supplies to rescue them, receiving massive reputation boosts and insider rumors in return. *(Captain Synergy: Merchant captains can aggressively negotiate Hazard Pay; Smugglers can quietly skim supplies for massive credit payouts).*
2. **Echoes of the Frontline (Graveyards):** *(Triggers when War Heat > 80)*. Players jumping into an empty sector may stumble upon massive, persistent wreckage fields (`cc_derelictgraveyard.lua`)—the immediate, blazing aftermath of a massive macro-faction fleet clash.
3. **Black Box Extraction:** Spawns via a custom stash script (`cc_blackbox.lua`) inside Derelict Graveyards. Players can interact with the Stash to extract the doomed captain's final audio log, alongside high-tier System Upgrades and credits that scale based on distance to the core. *(Captain Synergy: Scavenger and Explorer captains extract up to 50% more credits and have a higher chance of pulling Exceptional rarity upgrades).*
4. **Cultural Monuments:** *(Triggers deep inside AI territory)*. Spawns massive, awe-inspiring procedural monuments. Paying your respects by reading the inscription (`cc_factionmonument.lua`) grants a permanent +1500 reputation boost with the local faction.

</details>

---

## Dependencies & Compatibility

<details>
<summary><h3>Required Mods</h3></summary>

- **Avorion**
- **Cosmic Vault:** Core dependency for the Dialogue API and context parser.
- **Cosmic Overhaul:** Required for background Captain's Log hooks.
- **Cosmic War:** Required for War Heat synergy and conflict events.

</details>

<details>
<summary><h3>Compatibility Notes</h3></summary>

- File paths are strictly aligned with Avorion's VM boundaries (`entity/`, `events/`, `player/`).
- Failsafes (`pcall`) are built into all hard-hooks to prevent crashes if a dependency is temporarily missing, but the narrative experience will be heavily degraded without the core Cosmic suite.
- Seamlessly supports custom stations and modded factions by falling back to `generic` lore categories when unique traits cannot be identified.

</details>
