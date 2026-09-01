# 🪐 Cosmic Chronicles: Detailed Features

Welcome to the **Cosmic Chronicles** wiki. This page is the full technical reference for the narrative and lore expansion module in the **Cosmic** mod series.

**Cosmic Chronicles**:

- Acts as the narrative wrapper for the background simulations running in **Cosmic War** and **Cosmic Overhaul**.
- Provides dynamic lore through station interactions and deep-space events.
- Reports on the state of the galaxy through the Galactic News Network.

---

## 📜 Table of Contents

- [Mod Identity & Design Goals](#-mod-identity--design-goals)
- [Architecture Summary](#-architecture-summary)
- [Full Feature Breakdown](#-full-feature-breakdown)
- [Cosmic Vault & Series Integration](#-cosmic-vault--series-integration)
- [Dependencies & Compatibility](#-dependencies--compatibility)

---

## 🎯 Mod Identity & Design Goals

<details>
<summary><b>View Mod Identity & Core Goals</b></summary>

**Primary focus:** injecting dynamic text, dialogue, and narrative events into the galaxy based on backend simulation state.

**Core goals:**

1. **Contextual lore.** Rumors and dialogue reflect the current state of the sector (War Heat, faction wealth, distance from the core) instead of firing at random.
2. **Synergy.** Translate the hard math of `Cosmic Overhaul` and `Cosmic War` into stories a player can read.
3. **Immersion.** Add background chatter, derelict logs, and civilian interactions that enrich the world without interrupting play.
4. **Mod-friendly API.** Use `Cosmic Vault`'s dialogue registry so other mods can inject their own lore into the Chronicles ecosystem.

</details>

---

## 🏗️ Architecture Summary

<details>
<summary><b>View Architecture Details</b></summary>

The mod uses a centralized dialogue API (`CosmicVaultDialogue`) to register localized strings by type (`ambient`, `rumor`, `captain_log`).

When an event or interaction happens, the mod builds a **Context Table** describing the current sector (`warHeat = 80`, `stationType = "shipyard"`, `economy = "wealthy"`) and asks the Vault API for a matching string. The Vault filters out any line that doesn't fit the context and returns one that does. Hard hooks are wrapped in `pcall(include)` to keep a missing soft dependency from taking down the sector script.

Cosmic Chronicles ships as a hard dependency alongside Cosmic Vault, Cosmic Overhaul, and Cosmic War (see [Dependencies & Compatibility](#-dependencies--compatibility) for the exact version requirements from `modinfo.lua`). Cross-mod calls assume all three are present and do not fall back to a reduced feature set if one is missing.

</details>

---

## ⚙️ Full Feature Breakdown

<details>
<summary><h3>The Rumormonger System</h3></summary>

Adds dynamic background chatter and interactive rumor-gathering to NPC stations, backed by a registry of 60+ unique, localized lore strings.

**Key mechanics:**

- **Ambient chatter:** stations run a 35-second background chatter loop, broadcasting floating overhead text based on their type and the current situation (global sector cooldown 30 seconds, 50% speech probability).
- **Interaction:** players can dock and ask "Any rumors?" for a dynamic tip.
- **Tutorialization:** the Rumormonger occasionally teaches players a mechanic (Merchant synergies, Trash Manager filters) through gameplay rather than a tooltip.
- **Contextual awareness:** the Rumormonger reads:
  - **Station type:** 12+ vanilla station scripts, pre-cached in `init.lua` for performance.
  - **War Heat:** pulled live from the Cosmic War bridge.
  - **Faction wealth:** `wealthy` vs. `poor` economies produce different lines.
  - **Geography:** some lines (Deep Core lore, for instance) won't spawn near the Outer Rim.
  - **Player reputation:** stations refuse to gossip below −30,000 reputation, so hostile military outposts stay in character.
  - **Captain synergy:** Smuggler and Explorer captains can extract rumors down to −60,000 reputation. They know how to buy a drink quietly, even in hostile ports.

</details>

<details>
<summary><h3>Captain's Logs</h3></summary>

Hooks directly into the Cosmic Overhaul background command simulation.

**Key mechanics:**

- When a captain finishes a map command (Scout, Mine, Trade, etc.) and mails the player a report, a narrative "Captain's Log" is appended to the bottom of the message.
- **Context validation:** logs reflect the faction and sector where the operation took place. Trading in a high-War-Heat sector produces logs about military patrols and close calls with blockades.
- Implemented as a same-path VFS override of `background/simulation/simulation.lua`, hooking `Simulation.makeCommand`'s `command.addYield`. That's the same pattern Cosmic Overhaul itself uses, so both mods' hooks compose regardless of load order.

</details>

<details>
<summary><h3>Dynamic Narrative Events & Interactions</h3></summary>

A global event controller (`cc_event_controller.lua`) listens for hyperspace jumps and spawns events based on the local geopolitical climate.

**Available events:**

1. **Refugee Convoys** *(War Heat > 40).* Civilian ships with damaged hyperdrives appear and ask for Food or Medical Supplies. Donating grants reputation and a rumor, plus a 25% chance the refugees tip off the coordinates of a hidden resource stash.
   - **Captain synergy:** a Merchant captain negotiates a flat 50,000-credit hazard pay fee; a Smuggler quietly skims 75,000 credits worth of valuables from the convoy's cargo during the transfer.
2. **Echoes of the Frontline (Graveyards)** *(War Heat > 80).* Players jumping into an empty sector may find a massive, persistent wreckage field: the immediate aftermath of a fleet clash between major factions.
3. **Black Box Extraction.** Spawns via a stash script inside Derelict Graveyards. Interacting extracts the doomed captain's final audio log, a system upgrade, and credits that scale with distance to the core.
   - **Captain synergy:** a Scavenger captain extracts up to 50% more value (1.5x); an Explorer captain extracts up to 25% more (1.25x). Both also raise the odds of the upgrade rolling Rare or even Legendary rarity.
   - **Corrupted Lore Nodes:** if the wreckage sits in Eclipse territory, the reward doubles (2x), but extracting it instantly spawns an Ascendancy ambush.
   - **Classified Rift Tech:** black boxes also carry a chance to yield `Rift Research Data` and `Subclass Subsystems`, both high-value contraband on the black market. Scavenger and Explorer bonuses raise these odds too.
4. **Cinematic Monuments** *(deep inside AI territory).* Colossal, 2.5x-scaled procedural monuments. A Ship Computer broadcast warns players on entry; reading the inscription grants a permanent **+2,500 reputation** boost with the local faction.
5. **Drifting Ghost Ship.** A faint, repeating distress signal from a derelict freighter. Boarding it triggers a narrative dialogue.
6. **Rogue AI Probe.** A fast, evasive military probe that scales its shields and damage the closer it is to the Galactic Core. If it survives 3 minutes, it hyperspaces away with scanned sector data.
7. **Stranded Diplomat.** A faction's diplomat is stranded after their escort is destroyed. Extract them before they're captured.
8. **Ancient Data Caches.** Derelict data banks that yield *Encrypted Log Fragments*, tradeable at any Research Station for credits and reputation.
9. **Ancient Eclipse Anomaly.** A volatile physical anomaly. Extracting its core yields rare system upgrades, but it can detonate if mishandled.

</details>

<details>
<summary><h3>Omni-Sensor Intelligence</h3></summary>

The player's ship computer gets automated deep-space scanning.

**Key mechanics:**

- **Auto-scan on entry:** every jump into a new sector triggers an Omni-Sensor ping for high-value targets.
- **Actionable intelligence:** exact coordinates for claimable asteroids or hidden resource stashes print straight to chat, cutting out manual searching.

</details>

<details>
<summary><h3>Galactic News Network</h3></summary>

The News Board (`cc_newsboard.lua`, `cc_newsgenerator.lua`) reports on events across the whole Cosmic series through the shared `CosmicVaultNews` API, currently fed by 4+ mods publishing 30+ distinct, unnormalized category strings ("War Crime", "Trade Crisis", "Galactic Milestone", and so on). The News tab was rebuilt around that reality.

**Category grouping.** Every observed category maps onto seven stable, color-coded top-level groups: War & Conflict, Economy, Threats & Crises, Discoveries & Milestones, Captain Stories, Politics, and General. A category that doesn't have an explicit mapping falls back to a keyword match, so a brand-new category from any mod still lands somewhere sensible instead of vanishing from the filter.

**Filtering and search.** A category dropdown and a live search box (matching vanilla's own Encyclopedia search pattern) narrow the headline list instead of forcing a scroll through an unsorted feed. Search matches both title and article text.

**Headline table.** The single-column list is now a 3-column, sortable-by-glance table (Category, Headline, Age), color-coded by group.

**Unread tracking.** Session-local: unread headlines are bolded and marked with a `●`, and a header counter reads "N Unread" (or "All caught up" once you've read everything).

**Breaking News.** The highest-priority articles set a `breaking` flag that `CosmicVaultNews`' schema already tolerates without any change to the shared API. Only genuinely rare, galaxy-scale events use it: a Behemoth Incursion, a one-time boss defeat, an empire's collapse. That keeps the banner meaningful instead of firing constantly. A breaking article triggers both an immediate galaxy-wide chat alert and a clickable red banner atop the News tab; clicking it jumps straight to the article.

**Headline ages.** Every story shows a relative age ("5m", "2h", "3d"), computed server-side on each sync rather than sent as a raw timestamp. `Client().unpausedRuntime` and `Server().unpausedRuntime` are different clocks with different origins, so comparing them client-side would produce nonsense.

**Discovery News.** A fourth ambient generator reports uncharted signals, derelict fleets, ancient ruins, and rare stellar phenomena near a random active faction's territory. Adding it meant rebalancing the odds across the four generators (War, Economy, Captain Feats, Discovery), so each now fires roughly a quarter of the time.

**EMPIRE HAS FALLEN.** A lightweight tracker watches every known AI faction and detects the exact moment one transitions from active to eradicated, using the same `FactionEradicationUtility` check every generator here already relies on. The moment a tracked faction falls, it publishes a Breaking News article naming the empire. It only reports a transition it actually observed (a faction already gone before the tracker ever saw it active isn't retroactively announced), and its tracking state persists across server restarts. Previously this was one of the biggest events a galaxy can have, and it went completely unreported outside a plain chat line from a third-party dependency.

**Cosmic War integration.** Fully completing a War Bounty License and AI factions actually reaching a ceasefire are both reported to the News Network now too (see Cosmic War's own changelog for the mechanics on that side).

</details>

---

## 🌌 Cosmic Vault & Series Integration

<details>
<summary><b>View Integration Details</b></summary>

### Cosmic Codex Integration
All deep lore, stat blocks, and mechanical documentation are readable in-game from the Cosmic Codex tab, so there's no need to tab out to a wiki.

### Cosmic Vault Hooks
- **Deep Economy Integration:** ambient News events (Trade Crisis, Market Boom) tie into the `CosmicVaultEconomy` API, raising or lowering a faction's Famine Score.
- **Dead Empire Filter:** all News generation runs through `FactionEradicationUtility` to keep destroyed empires from broadcasting.
- **Post-Boss Anomalies:** destroying the Bottan Dreadnought invokes `CosmicVaultAnomalies` to spawn a persistent `SpatialRift`.
- **Unified News API:** every News broadcast path goes through `CosmicVaultNews.publishArticle` for global validation, including the new `breaking` field, which is now formally part of the shared schema rather than an implicit convention this mod invented (see Cosmic Vault's own changelog).

### Network Safety & Anti-Cheat
- **Deterministic randomization:** unstable `math.random` calls have been systematically replaced with Avorion's `random():getInt()`, keeping multiplayer servers in sync during large fleet spawns.
- **Callable validation:** background and UI scripts verify execution context server-side before processing a request, closing several remote-call exploits.

### Vanilla Bug Fixes
- **Scout Mission fix:** a long-standing vanilla bug that made Scout Missions skip Faction Headquarters sectors (a missing dialogue template) is patched.

</details>

---

## 🔌 Dependencies & Compatibility

<details>
<summary><h3>Required Mods</h3></summary>

Per `modinfo.lua`, Cosmic Chronicles hard-requires:

- **Avorion**
- **Cosmic Vault** — dialogue API and context parser.
- **Cosmic Overhaul** — background Captain's Log hooks, dynamic economy stats, and captain-class synergy detection.
- **Cosmic War** — War Heat data and conflict events.

</details>

<details>
<summary><h3>Compatibility Notes</h3></summary>

- File paths stay strictly within Avorion's VFS boundaries (`entity/`, `events/`, `player/`).
- Engine-safe randomization (`random():getInt()`) is enforced across the mod for multiplayer sync.
- Event controllers are uniquely prefixed (`cc_`) to avoid VFS overlap with other mods.
- Custom stations and modded factions are supported by falling back to `generic` lore categories when a unique trait can't be identified.

</details>
