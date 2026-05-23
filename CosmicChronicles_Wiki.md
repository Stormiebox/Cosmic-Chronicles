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
  - [The Rumormonger System](#the-rumormonger-system)
  - [Captain's Logs](#captains-logs)
  - [Dynamic Narrative Events](#dynamic-narrative-events)
- [Dependencies & Compatibility](#dependencies--compatibility)

---

## Mod Identity & Design Goals

**Primary Focus:** Injecting dynamic text, dialogue, and narrative events into the galaxy based on backend simulation states.

**Core Goals:**
1. **Contextual Lore:** Rumors and dialogue shouldn't be entirely random; they should reflect the current state of the sector (e.g., War Heat, Faction Wealth, Distance from Core).
2. **Synergy:** Translate the hard math of `Cosmic Overhaul` and `Cosmic War` into human stories.
3. **Immersion:** Add background chatter, derelict logs, and civilian interactions that don't interrupt gameplay but enrich the atmosphere.
4. **Mod-Friendly API:** Utilize `Cosmic Vault`'s dialogue registry so other modders can easily inject their own lore into the Chronicles ecosystem.

---

## Architecture Summary

The mod utilizes a centralized dialogue API (`CosmicVaultDialogue`) to register localized strings categorized by type (`ambient`, `rumor`, `captain_log`).

When an event or interaction occurs, the mod builds a **Context Table** containing data about the current sector (e.g., `warHeat = 80`, `stationType = "shipyard"`) and requests a valid string from the Vault API. The Vault filters out any lore that doesn't match the context, returning a perfectly tailored narrative snippet.

---

## Full Feature Breakdown

### The Rumormonger System
**What it does:**
Adds dynamic background chatter and interactive rumor-gathering to all NPC stations in the game.

**Key Mechanics:**
- **Ambient Chatter:** Stations will periodically broadcast floating overhead text based on their specific type (e.g., Shipyards complaining about hull plate shortages, Casinos boasting about high rollers).
- **Interaction:** Players can dock and ask "Any rumors?" to receive a dynamic tip.
- **Contextual Awareness:** Rumors adapt to:
  - **Station Type:** (12+ unique vanilla station scripts parsed).
  - **War Heat:** (Pulls live conflict data from `Cosmic War`).
  - **Faction Wealth:** (Wealthy vs. Poor traits).
  - **Geography:** (Deep Core vs. Outer Rim).
  - **Player Reputation:** (Smugglers won't talk to cops).

### Captain's Logs
**What it does:**
Hooks directly into the **Cosmic Overhaul** background command simulation.

**Key Mechanics:**
- When a captain completes a map command (Scout, Mine, Trade, etc.) and sends the player a mail report, a narrative "Captain's Log" is appended to the bottom of the message.
- Logs react to the sector they operated in. For example, if they traded in a high `War Heat` sector, the captain will log complaints about aggressive military patrols.

### Dynamic Narrative Events
**What it does:**
Listens for sector jumps and spawns immersive, world-building events based on the local geopolitical climate.

**Available Events:**
1. **Refugee Convoys:** (Triggers when War Heat > 40). Fleeing civilian ships appear with damaged hyperdrives. Players can open comms and donate Food or Medical Supplies to rescue them, receiving massive reputation boosts and insider rumors in return.
2. **Echoes of the Frontline (Graveyards):** (Triggers when War Heat > 80). Players jumping into an empty sector may stumble upon the immediate, blazing aftermath of a massive fleet clash.
3. **Black Box Extraction:** Spawns inside Derelict Graveyards. Players can interact with the Stash to extract the doomed captain's final audio log, alongside high-tier System Upgrades and credits.

---

## Dependencies & Compatibility

### Required Mods
- **Avorion**
- **Cosmic Vault** (Core dependency for the Dialogue API and context parser).
- **Cosmic Overhaul** (Required for background Captain's Log hooks).
- **Cosmic War** (Required for War Heat synergy and conflict events).

### Compatibility
- Failsafes (`pcall`) are built into all hard-hooks to prevent crashes if a dependency is temporarily missing, but the narrative experience will be heavily degraded.
- Seamlessly supports custom stations and modded factions by falling back to `generic` lore categories when unique traits cannot be identified.