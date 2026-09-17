# 🪐 Cosmic Chronicles: Detailed Features

![Avorion](https://img.shields.io/badge/Avorion-2.5.13-2f81f7?style=flat-square)

Cosmic Chronicles is the narrative and presentation layer of the Cosmic series. It reports verified events, supplies contextual dialogue, and creates bounded Chronicle-owned aftermath encounters without taking ownership of another mod's mechanics.

> [!TIP]
> Read [`PLAYER_GUIDE.md`](PLAYER_GUIDE.md) for a gameplay tour and [`README.md`](README.md) for installation.

## Contents

- [Ownership and architecture](#ownership-and-architecture)
- [Galactic News Network](#galactic-news-network)
- [Rumors and Captain's Logs](#rumors-and-captains-logs)
- [Narrative rules and events](#narrative-rules-and-events)
- [Persistence and migration](#persistence-and-migration)
- [Status and repair](#status-and-repair)
- [Compatibility](#compatibility)

## Ownership and architecture

Cosmic Vault owns the shared News v2 store, Dialogue v2 catalog, JSON record helpers, and exact-coordinate materialization queues. Cosmic War owns wars and their results. Cosmic Overhaul owns its simulation, commands, stations, and economy features. Cosmic Ascendancy owns the Eclipse campaign, encounters, territory, Beacon, and Forge. Chronicles reads their public records or stable news facts and owns only its UI, personal news state, rumors, projections, events, interactions, and rewards.

The Chronicle coordinator is the sole writer of:

- `cc_state_v2`: migration, source cursors, rule cooldowns, scheduler, external observations, and service health.
- `cc_events_v2`: Chronicle event identity, provenance, coordinates, seed, materialization evidence, lifecycle, participants, and outcome.
- `cc_receipts_v1`: rule, publication, milestone, interaction, and event-reward receipts.
- `cc_repair_audit_v1`: dry-run scans, chosen actions, observed revisions, and repair history.

Each player's controller is the sole writer of `cc_player_v2`, which stores personal read state, followed threads, leads, notification settings, recent dialogue IDs, milestone migration evidence, and repair state. Interactive Chronicle entities own their local `cc_interaction_v1` record.

Clients submit intent only. Costs, rewards, source ownership, coordinates, results, timestamps, and repair evidence are resolved on the server.

## Galactic News Network

Vault assigns every article a stable `publisherId:eventId`, sequence, revision, lifecycle, and optional thread, location, audience, lead, expiry, outcome, and provenance. Identical retries coalesce. Updates and resolutions require the owning publisher and expected revision.

The Galactic News tab keeps the existing teal two-pane newsroom identity and provides:

- **Live Feed:** current and developing reports.
- **Chronicle:** reports published by Chronicles and their outcomes.
- **Saved Leads:** the player's stored location leads and current state.
- Source, topic, status/nearby, and bounded text filters.
- Source, topic, headline, and age columns with written severity markers.
- A detail pane with source, byline, lifecycle, location, thread, body, and outcome.
- Follow/unfollow, save/remove lead, and add-to-map actions when the report supports them.
- Cursor-based older-page loading and feed-revision `not_modified` responses.

An article is read when its sequence is at or below the player's `readThroughSequence` or its stable ID is in the bounded sparse read set. **Mark All Read** advances the cursor to the latest article currently accessible to that player and prunes redundant IDs. Read state, follows, leads, and notification preferences are personal even for alliance members and persist through reconnects and save reloads.

Critical reports may produce a rate-limited breaking chat alert. Weather and Rift topics are excluded from this chat path because Vault's environment presenter already owns immediate in-sector warnings, sound, visuals, and danger UI.

## Rumors and Captain's Logs

Dialogue v2 lives in one Vault manager rather than separate module-local tables in each Avorion script VM. Chronicles registers stable line IDs with serializable conditions and queries the catalog using current context:

- War Heat and nearby News publishers/topics/severities.
- Weather types and Rift escalation.
- Eclipse state from Ascendancy's public snapshot.
- Station type, faction trait and wealth, distance to center, reputation, and captain class.

The player record excludes the latest 20 heard line IDs, which limits immediate repetition across visits and reconnects. Loaded sectors use one shared 45-second chatter schedule rather than one independent poll per station. The interactive Rumormonger uses the same context and catalog.

Captain's Logs are appended inside Cosmic Overhaul's existing background-simulation extension. Chronicles no longer ships a competing `simulation.lua` file. A command report remains personal to the owning player unless its owner explicitly publishes a wider fact.

## Narrative rules and events

Static, validated rules project verified source facts into Chronicle-owned content. Initial families cover:

- War battles, sieges, retreats, and humanitarian reports.
- Vault/Overhaul market, famine, factory, and weather facts.
- Vault/War Rift facts.
- Ascendancy Eclipse, World-Eater, Citadel, and territory facts.

Each article revision/rule pair has one deterministic receipt. The selection roll is stable across restarts, and regional output families use a one-hour cooldown. Rules never write War heat, market state, famine, weather effects, Rift escalation, Ascendancy progression, territory, or rewards.

Chronicle events include Refugee Convoys, Derelict Graveyards and Black Boxes, Hidden Stashes, Ancient Data Caches, Rogue AI Probes, Stranded Diplomats, Ghost Ships, Cultural Monuments, and qualifying Eclipse lore anomalies.

An event record and queue entry exist before sector work begins. Materialization waits for natural player entry, uses the stored seed, tags every entity with the immutable event ID, verifies exact expected entity counts and scripts, and only then marks the event active. A clean failure retries with backoff up to five claims. Partial or ambiguous materialization requires repair. An unloaded sector or missing lookup never counts as a destroyed encounter.

Interactions use fixed server-side recipes and a prepared transition before cargo debit or reward delivery. A successful result receives a deterministic receipt. A restart in an unprovable debit/reward window becomes `repair_required` rather than replaying the operation.

## Persistence and migration

All versioned tables are JSON-backed through Cosmic Vault because Avorion custom values accept primitives, not Lua tables.

Migration is evidence-driven and leaves legacy values untouched for rollback:

- Legacy News records are imported by Vault with deterministic provenance.
- The old client-only seen list cannot be recovered; imported reports begin unread until the player reads them or uses persistent Mark All.
- `cc_active_bounties` and `cc_hidden_stashes` are parsed as exact signed `x:y` tokens. Same-coordinate conflicts become repair findings.
- Old sector spawn/loot flags become consumed tombstones or ambiguous evidence; they never replay an encounter or reward.
- Existing vanilla mission evidence is recorded as `legacy_outcome_unknown` and does not automatically pay an old Chronicle bonus.
- A newly observed irreversible milestone may prepare one receipted v2 bonus. An old ambiguous bonus requires an explicit administrator reissue.

## Status and repair

`/chroniclesstatus` is read-only and reports canonical manager health, migration, event and receipt totals, and personal unread/follow/lead state.

`/chroniclesrepair` is administrator-only:

```text
/chroniclesrepair scan [all|news|player <index>|events|interactions|dialogue|queues]
/chroniclesrepair status [repairId]
/chroniclesrepair apply <repairId> <resume|retry|mark-complete|reissue|abandon>
/chroniclesrepair history [repairId]
```

`scan` never changes state. `apply` checks administrator privileges, the recorded revisions, each finding's permitted actions, and appends an audit entry. Reissuing a potentially delivered milestone reward is never automatic.

## Compatibility

Chronicles keeps only two shared vanilla script paths: the minimal galaxy and player bootstraps needed to attach its owners. Entity initialization, sector initialization, research stations, radio chatter, passing ships, event copies, story mission copies, story dialogue copies, Behemoth spawning, and the simulation wrapper have additive replacements or deliberate retirement handling.

No new vanilla path is added. Starfall is outside this integration and receives no publisher, rule, reference, or changed file.

The mod requires Cosmic Vault, Cosmic Overhaul, Cosmic War, and Cosmic Ascendancy through the Core 4 relationship. It supports singleplayer and dedicated multiplayer with personal news/reward state for each player, including alliance members.

---

<div align="center">

[⬆ Back to top](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Features-and-Enhancements) · [🌌 README](https://github.com/Stormiebox/Cosmic-Chronicles) · [📘 Player Guide](https://github.com/Stormiebox/Cosmic-Chronicles/wiki/Players-Guide-The-Living-Galaxy)

</div>
