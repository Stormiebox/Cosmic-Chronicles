# Cosmic Chronicles: A Player's Guide to a Living Galaxy

Have you ever docked at a station and wondered what the locals are actually thinking? In the vast, procedurally generated universe of Avorion, space can sometimes feel a little quiet. **Cosmic Chronicles** was built to change that by transforming the cold math of background simulations into human stories.

Here is a plain-English breakdown of exactly how Cosmic Chronicles works behind the scenes, and how it differs from the base game.

---

## The Vanilla Way: Static "Radio Chatter"

To understand why Cosmic Chronicles is special, you first need to understand how the base game handles background text.

In vanilla Avorion, when a station spawns, the game hands it a simple, static list of phrases. For an Equipment Dock, it might be a list of 10 phrases like *"Guns, guns, guns!"* or *"No refunds."*

Every few seconds, the game just rolls a die, picks a phrase from that list completely at random, and displays it above the station.

> **The Limitation:** It has zero awareness of what is actually happening in the galaxy.
>
> * You could be at war, and the station will just happily yell *"Guns, guns, guns!"*
> * The faction could be bankrupt, and the station will still yell *"Guns, guns, guns!"*
> * You could be their worst enemy with a terrible reputation, and they will cheerfully try to sell to you.

## The Cosmic Way: The "Rumormonger"

Cosmic Chronicles introduces a highly advanced system called the **Rumormonger**. Instead of giving a station a static list of text and walking away, the Rumormonger actively *watches* the galaxy in real-time.

Every 35 seconds, the mod wakes up and asks a series of questions about the current state of the sector before anyone is allowed to speak:

1. **Who is listening?** (What is your Reputation? Are you a hero, a neutral trader, or a hated pirate?)
2. **What is the economy doing?** (Is this faction Wealthy, Average, or Poor?)
3. **Where are we?** (Are we near the galactic core, or out on the lawless Rim?)
4. **Is there a War?** (It asks the *Cosmic War* mod exactly how high the political tension is right now).
5. **Who is speaking?** (Is this a Casino, a Shipyard, or a Smuggler's Market?)

Once it gathers this "Context", it looks into the massive database of lore with the help of **Cosmic Vault.**. It throws out every single piece of dialogue that doesn't make sense for the current situation, and then broadcasts a perfectly tailored piece of ambient chatter. Sometimes, it will even broadcast helpful tips to naturally teach you how to use deeper mechanics (like the Trash Manager or Captain Synergies) without breaking immersion!

### The Result: True Immersion

Because of this context-awareness, the galaxy actually reacts to you and the world around it:

* **If War Heat is high:** You will suddenly hear military outposts talking about mobilizing fleets, and civilians panicking about trade sanctions.
* **If you have Bad Reputation:** Smugglers will give you tips on unbranding stolen goods, while security forces will tell you to keep your transponders clean.
* **If the Faction is Poor:** Repair docks will complain about holding ships together with duct tape because they can't afford cohesive field generators.

And the best part? It works *alongside* the vanilla game. You'll still hear the classic Avorion chatter, but it is beautifully interwoven with deep, reactive world-building.

---

## Beyond Stations: A Connected Universe

The Rumormonger system doesn't just stop at stations. Cosmic Chronicles extends this dynamic awareness into the dark reaches of space:

### 📅 Dynamic Deep Space Events

When you jump into an empty sector, the mod checks the local political climate. If "War Heat" is boiling over, you might stumble into a **Derelict Graveyard**—the immediate, smoking aftermath of a massive fleet battle where you can recover doomed Black Box recordings and system upgrades that actively scale in value the closer you get to the galactic core. If tensions are rising, you might intercept a **Refugee Convoy** begging for food and medical supplies to repair their hyperdrives before a hunter fleet arrives.

If you venture deep into the heart of an ancient faction's territory, your ship's computer might warn you about a colossal, cinematic **Cultural Monument**. Taking the time to approach it and read its inscriptions will earn you a massive, permanent (+1500) reputation boost with that faction.

These aren't just random events; they only happen *because* of the state of the galaxy.

### 🎖️ Your Crew Matters (Captain Synergies)

Cosmic Chronicles also knows *who* is sitting in the captain's chair, and it actively changes how events unfold based on their class:

* **Smugglers & Explorers** know how to keep a low profile. They can subtly extract rumors from stations even when the local faction actively hates you.
* When rescuing a refugee convoy, a **Merchant** captain can aggressively negotiate a hefty "Hazard Pay" reward for the supplies, while a **Smuggler** might quietly skim valuable smuggled goods from their cargo holds (yielding up to 100,000 credits) during the transfer.
* When extracting a Black Box from a graveyard, **Scavenger** and **Explorer** captains are far more skilled at decrypting the data, recovering up to 50% more credits and earning a higher chance to pull *Exceptional* rarity system upgrades.

### 🎖️ Captain's Logs

If you use the *Cosmic Overhaul* mod, you can send your captains on background missions (like Mining or Trading). When they finish, they send you an email report.

Cosmic Chronicles intercepts these emails and dynamically writes a **Captain's Log** at the bottom of the message. If you sent your captain to a dangerous warzone, their log will reflect close calls with military patrols. If you sent them to the deep unknown, they might write about strange phantom signatures on their scanners.

---

### Summary

**Cosmic Chronicles** doesn't just add words to the screen. It creates a narrative ecosystem that listens to the invisible math dictating the wars and economies around you, and translates that math into living, breathing stories.


---

## 🔗 Cosmic Series Integration & Audit 3.0 Updates
<details>
<summary><b>Click to expand</b></summary>

During the Cosmic Series Final QA Audit (v3.0+), several massive backend systems were standardized across all mods:

### 📖 Cosmic Codex Integration
All deep lore, stat blocks, and dynamic recipes have been fully integrated into the in-game **Cosmic Codex**. You no longer need to tab out of the game to read these features; they will natively update and unlock inside your Codex UI as you progress!

### 🔒 Network Safety & Anti-Cheat
- **Math.Random Fix:** We systematically replaced all unstable Lua `math.random` calls with Avorion's deterministic `random():getInt()` generation sequence. This guarantees 100% synchronization on Multiplayer Dedicated Servers and prevents cascading desyncs during massive fleet spawns.
- **Callable Validation:** UI and background scripts have been fully hardened. Malicious clients can no longer spoof "free" remote calls; the server actively verifies execution contexts before processing any requests, sealing multiple Arbitrary Code Execution (ACE) vulnerabilities.

### 🛠️ Vanilla Bug Fixes
- **Scout Mission Fix:** We patched a massive, long-standing vanilla bug where Scout Missions would completely skip and ignore Faction Headquarters sectors because the native dialogue trees were missing the template definition.
</details>

### Core Integration
The Chronicles news network is deeply integrated into the Core 5 mods, reporting on everything from Famines to Ascendancy Sieges.
