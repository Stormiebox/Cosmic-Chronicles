# Changelog

All notable changes to **Cosmic Chronicles** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Never remove, overwrite or write above this

## [v3.2.3]

### ⭐ New Features

- [Feature] **Galactic News Network: "Mark All As Read" Button (`player/ui/cc_newsboard.lua`):** Reported by a player: checking the news board after letting it sit for hours means every article is unread, and clearing that backlog one headline at a time is tedious. Added a "Mark All As Read" button next to Refresh (same row, same height, `onMarkAllReadClicked` marking every article currently in `self.currentNewsArray` as seen via the same `seenArticles[articleKey(article)] = true` mechanism `selectArticle` already uses for a single article, then re-running `populateUI()`). The button grays out (`.active = false`) once there's nothing unread left, mirroring the existing `upgradeShuttlesButton.active` pattern in Cosmic Overhaul's `factory.lua`. This is a client-only stopgap, not a fix for the underlying issue noted separately below.
- [Known Issue] **Read State Doesn't Persist Across Relogin/Save Reload (`player/ui/cc_newsboard.lua`):** Also reported by the same player: `seenArticles` (the table tracking which articles have been read) is a plain client-side Lua local with no `secure()`/`restore()` round-trip anywhere in this file, so it always resets to empty on script reload — every relogin or save reload shows every article as unread again, regardless of what was actually read in a prior session. Confirmed by reading the file: there is no persistence path for this table at all, client or server side. Deliberately left unfixed for now (the "Mark All As Read" button above is the interim workaround); actually fixing this requires deciding where read-state should live (a per-player server-side value, most likely, since a purely client-side value can't be shared across a player's own alts/devices) and is being tracked as separate follow-up work, not bundled into this entry.

### 🪲 Bug Fixes

- [Bugfix] **Stranded Diplomat Unenterable & Docking Always Denied (`cc_diplomatescort.lua:57-68`):** Reported by multiple players: the diplomat ship could not be docked with (NPC radio chatter reported docking permission denied), and pressing the enter-craft key on it returned "This craft has no owner." Root cause: v3.2.1's fix for the diplomat reputation-loss bug kept `diplomat.factionIndex = 0` from an earlier, since-disproven theory as "defense-in-depth," on top of the actual fix (removing `civilship.lua`). `0` is not a neutral placeholder — it is vanilla's explicit sentinel for "no owner" (see `entity/claim.lua`'s claimable-asteroid check, `IShipOwner.cpp`'s "This craft has no owner." string), and every native ownership-sensitive system — docking permission resolution and the enter-craft check alike — requires a resolvable owning faction to grant access to anyone. With no faction, nobody could be granted permission, which is the opposite of "defense-in-depth." Removed the `factionIndex = 0` assignment entirely, restoring real faction ownership exactly as `cc_ghostship.lua` (which was never affected by this bug) has always done — `civilship.lua`'s removal already fully addresses the original -15,000 reputation exploit on its own, so no defense-in-depth measure was needed here in the first place. Also reworded the distress broadcast from "Dock and open a comm link" to "Approach and open a comm link," since the actual mechanic (`diplomatdialog.lua`'s `interactionPossible`) only ever checked proximity (≤500 units), never an actual docking clamp — the old wording was steering players toward a vanilla docking attempt the script never needed or supported.

## [v3.2.2]

### 🚨 Critical Fixes

- [Bugfix] **Bounty Ambush Never Spawned (`cc_bounty_ambush.lua:31`):** `BountyAmbush.spawn()` called `SectorGenerator(x, y):getFactionIndex()`, a method that does not exist on `SectorGenerator` (confirmed against `lib/SectorGenerator.lua` — this is the same invalid call already fixed in `cc_hiddenstash.lua`/`cc_blackbox.lua`, but missed here). The nil-method call threw immediately on every attempted spawn, so the "Dread Pirate Lord" boss and its bounty payout never actually appeared. `Galaxy:getPirateFaction(level)` takes a pirate difficulty *level*, not a faction index; replaced with `Galaxy():getPirateFaction(Balancing_GetPirateLevel(x, y))`, the same computation vanilla uses in `asyncpirategenerator.lua`/`entitydbg.lua`.
- [Bugfix] **Diplomat Smuggler-Tier Bribe Crash (`diplomatdialog.lua:126`):** `triggerServerPayout`'s tier-3 branch called `UpgradeGenerator():generateSectorSystem(x, y, 0, Rarity(RarityType.Exotic))`. The function's signature is `generateSectorSystem(x, y, rarity_in, rarities_in)` — the 4th argument is fed straight into `getValueFromDistribution()`'s `pairs()` loop and must be a weighted distribution *table*, not a single `Rarity()` object. Passing a `Rarity` there threw `table expected, got userdata` the instant a player picked the Smuggler bribe option. Fixed by moving the `Rarity(RarityType.Exotic)` argument to the 3rd parameter (`rarity_in`), matching the correct usage already present in `ancientcachedialog.lua` and `eclipseloot.lua`.

### 🪲 Bug Fixes

- [Bugfix] **Credit Rewards Bypassing `receive()` (`ancientcachedialog.lua:86`, `ghostshipdialog.lua:98/102/106`, `cc_blackbox.lua:154`, `cc_refugeedialogue.lua:95/99`, `diplomatdialog.lua:114/117/120`):** All seven sites granted credits via a direct `faction.money = faction.money + amount` (or `buyer`/`receiver`/`repTarget` equivalent) property write instead of the documented `Faction:receive()`/`Player:receive()` method. This traces back to Changelog v3.0.5's "Dynamic Reward Payout Crash" entry, which blamed "the unstable `player:receive()` API overload" for a crash and replaced it with direct assignment — but that diagnosis does not hold up: `receive()` is one of the single most common vanilla idioms for granting money (`insurance.lua`, `shop.lua`, `pirateattack.lua`, `rewards.lua`, and 50+ more call sites, all using it without incident), and this exact mod's own `eclipseloot.lua`, `cc_bounty_ambush.lua`, and `researchstation.lua` already use it safely. All seven sites now call `:receive(description, amount)` instead. `ancientcachedialog.lua`'s call deliberately keeps a plain (non-`%_T`) description, since the receiving faction can resolve to a client-less AI faction there and `%_T` targeting one crashes the server (`Avorion_Modding_Codex.md`, "Never send a localized translation payload to an AI faction").
- [Bugfix] **`%1%`/`%2%` Placeholders Never Substituted (`researchstation.lua:51`, `cc_bounty_ambush.lua:66/67`, `ancientcachedialog.lua:95`, `eclipseloot.lua:23`, `cc_ancientdatacache.lua:27/34`, `cc_ghostship.lua:21/42`, `cc_rogueaiprobe.lua:18/30`, `cc_diplomatescort.lua:23/58`):** Multiple `receive()`/`sendChatMessage()` calls used `%_t` instead of `%_T`, or no translation wrapper at all, on a description containing a `%1%`/`%2%` placeholder. Every vanilla call site of this pattern (30+ examples checked across `pirateattack.lua`, `insurance.lua`, `shop.lua`, `stationfounder.lua`, and more) wraps the string in `%_T` specifically because that operator builds the deferred `NamedFormat` object the money/coordinate arguments get substituted into — `%_t` resolves immediately with nothing to substitute, and a bare string just shows the literal `%1%`/`%2%` text. Affected: the Encrypted Log Fragment payout, the bounty claim reward and news broadcast, the Black Box credit chat line, the Eclipse cache loot description, and the title/broadcast lines on the Ancient Data Cache, Ghost Ship, Rogue AI Probe, and Diplomat Escort spawns. `cc_bounty_ambush.lua`, `cc_ancientdatacache.lua`, `cc_ghostship.lua`, and `cc_rogueaiprobe.lua` also gained an explicit `include("stringutility")`, since none of them share a vanilla file at the same path to inherit the `%_t`/`%_T` metatable setup from via VFS merge (the same crash mechanism documented for `eclipseloredialog.lua` in v3.2.1).
- [Bugfix] **"Wealthy"/"Poor" Faction Flavor Text Never Selectable (`cc_factionmonument.lua:49`, `entity/utility/radiochatter.lua:30`, `sector/background/radiochatter.lua:850`, `cosmicchronicles_rumormonger.lua:68`/`176`, `entity/dialogs/storyhints.lua:50`):** All six sites computed a `factionWealth` context value via `faction:getTrait("wealthy")` / `faction:getTrait("poor")`. Neither is a real Avorion faction trait — the engine's only trait keys are `aggressive`/`brave`/`greedy`/`honorable`/`mistrustful` (confirmed against every faction-generation table in `server/factions.lua`). `getTrait()` silently returns `0.0` for an unrecognized key with no error, so the `> 0.5` check always failed and `factionWealth` was permanently `"average"` — the 14 `factionWealth = "wealthy"`/`"poor"` dialogue lines registered in `server/cosmicchronicles.lua`, plus the equivalent lines in every ambient/rumor pool across the mod, could never be selected. Replaced with a direct `faction.money` threshold (`> 10,000,000` wealthy, `< 1,000,000` poor) at all six sites, since no native wealth/richness property exists to restore instead.
- [Bugfix] **Eclipse Lore Generator Denied a Busy Sector's Roll Forever (`cc_eclipselore.lua:17`):** `sector:setValue("cc_eclipselore_evaluated", true)` ran *before* the `sector.numEntities > 100` busy-sector check, not after. Since a sector with 100+ entities always gets saved to disk (per `sector/init.lua`'s "empty sectors aren't saved" note), any sector that merely happened to have a player fleet passing through on its first visit permanently lost its 5% Eclipse Lore spawn roll, with no way to ever retry. Moved the flag-set to after the busy-sector check, so only a sector that actually reached the roll gets marked evaluated.
- [Bugfix] **Refugee Convoy & Ghost Ship Vulnerable to the Diplomat's Civilship Bug (`cc_refugeeconvoy.lua:26`, `cc_ghostship.lua:33`):** Both spawners reuse `ShipGenerator.createFreighterShip`, which (per `lib/shipgenerator.lua`) always attaches `civilship.lua` on top of whatever AI scripts get stripped afterward. `civilship.lua` unconditionally registers its own "Where is your home sector?"/"Give me all your cargo!" interactions in the same menu as the intended dialogue, and its `threaten()`/`worsenRelations()` path can cost -15,000 reputation — the exact mechanism already found and fixed for `cc_diplomatescort.lua` in v3.2.1, but the same reuse pattern in these two sibling spawners was never checked. Both now `removeScript("data/scripts/entity/civilship.lua")` alongside their existing AI-script removals.
- [Bugfix] **News Board Never Received Live Updates (`player/ui/cc_newsboard.lua`):** `CosmicChroniclesNewsBoard.onNewsPublished()`/`deferredNewsSync()` exist specifically to push a live update — and show the "Breaking News" banner — to the client the moment `CosmicVaultNews.publishArticle()` fires its `onCCNewsPublishArticle` callback, but nothing in the file ever called `registerCallback("onCCNewsPublishArticle", "onNewsPublished")`. The News Board only ever refreshed when a player manually clicked Refresh or reopened the tab; the automatic "Breaking News" push (advertised in v3.2.0's feature entry) never actually ran. Added a server-side `CosmicChroniclesNewsBoard.initialize()` that registers the callback.
- [Bugfix] **Bounty Boss Map Icon Broken (`cc_bounty_ambush.lua:49`):** `boss:addScript("icon.lua", "data/textures/icons/pixel/skull.png")` pointed at a texture that doesn't exist anywhere in vanilla's or this mod's asset folders, silently falling back to a missing/broken map icon. Replaced with `double_skull_big.png`, a real vanilla icon.
- [Bugfix] **Hidden Stash Short Script Path (`cc_hiddenstash.lua:36`):** `container:addScript("entity/stash.lua")` used a short relative path; vanilla's own dynamic attachment of this exact script (`bountyhuntmission.lua`) always uses the full `data/scripts/entity/stash.lua` form, which is the only zero-exception-safe convention for `addScript`/`addScriptOnce` path resolution in this codebase. Updated to match.
- [Bugfix] **Environmental/Unowned Damage Misattributed (`cc_destructiontracker.lua:23`):** `if valid(inflictor) and inflictor.factionIndex then` always passed once `inflictor` was valid, because `factionIndex` is always a number — including `0` for "no faction" — and `0` is truthy in Lua. Vanilla always guards this comparison with `> 0` (`relationchanges.lua`, `respawncontainerfield.lua`); changed to match, so a station destroyed by unowned/environmental damage is no longer looked up as if it had an owning faction.
- [Bugfix] **Dead File Removed (`entity/story/warpawaytimer.lua`):** Confirmed still orphaned via a full-workspace grep — the Rogue AI Probe self-destruct timer this file was written for was rewired to the engine-native `delayeddelete.lua` back in v3.0.5 (`cc_rogueaiprobe.lua`), and nothing has referenced this file since. Deleted.

### ⚡ Performance

- [Perf] **Stock Market Re-Including Libraries Every 20 Minutes (`cc_stockmarket.lua`):** `simulateStockMarket()` called `include("factioneradicationutility")`, `include("cosmicvaulteconomy")`, and `include("cosmicvaultnews")` on every invocation of its own body instead of once at file load. Hoisted all three to file-scope locals.
- [Perf] **Radio Chatter Re-Fetching the Same Table in a Loop (`entity/utility/radiochatter.lua:51`):** `EntityRadioChatter.secure()` was called inside a 3-iteration loop purely to fetch the entity's `data.lines` table, which `secure()` returns by the same reference every time. Hoisted the call outside the loop.

### 🧹 Dead Code

- [Cleanup] **Unused `cosmicvaultdialogue` Include (14 files):** `artifactdelivery.lua`, `bottanmission.lua`, `buymission.lua`, `collectxsotantechnology.lua`, `crossthebarriermission.lua`, `exodus.lua`, `exodusmission.lua`, `hermitmission.lua`, `killguardianmission.lua`, `researchmission.lua`, `scientistmission.lua`, `smugglerretaliation.lua`, `swoksmission.lua`, and `the4mission.lua` all `include("cosmicvaultdialogue")` alongside the "Dynamic Mission Reward Hook" addition, but never call `CosmicVaultDialogue` — only `organizedallies.lua` (which correctly keeps the include) actually uses it. Removed from the other 14.
- [Cleanup] **Unused Includes & Local (`entity/story/smuggler.lua`, `cc_bounty_ambush.lua`):** Removed `smuggler.lua`'s unused `include("faction")`/`include("randomext")` and its unused `local smugglerFaction = Faction()`; removed `cc_bounty_ambush.lua`'s unused `local ShipGenerator`, `local SpawnUtility`, and `local LootGenerator` includes.
- [Cleanup] **Redundant `terminate()` Calls (`cc_derelictgraveyard.lua`, `cc_spawnmonument.lua`, `cc_hiddenstash.lua`, `cc_refugeeconvoy.lua`):** All four one-shot spawners called `terminate()` conditionally (after their busy checks, or only server-side) instead of unconditionally at the top of `initialize()`, leaving a client-side script instance permanently attached in the one-shot-but-never-detaches sense already fixed for `cc_eclipselore.lua` in v3.1.5. Moved `terminate()` to run first on all four, and removed the now-redundant secondary `terminate()` calls this left behind.

### 📖 Content Accuracy

- [Fixed] **In-Game Codex Overstated Explorer Bonus (`player/codex/infoCc.lua`):** The "Full Feature Breakdown" article claimed Explorer captains get "+400% (range 250)" interaction range on Black Boxes. The actual code (`cc_blackbox.lua`) uses a base range of 500, extended to 1,500 for Explorer captains — a 3x multiplier from a base of 500, not +400% from a base of 250. Corrected the codex text to "3x (500 to 1,500)".

## [v3.2.1]

### 🪲 Bug Fixes

- [Bugfixed] **Dedicated Server Crash: Ancient Eclipse Anomaly (`eclipseloredialog.lua`):** `Entity().title = "Ancient Eclipse Anomaly"%_t` runs inside `function initialize() if onServer() then ... end end` - genuinely function-scoped, genuinely guarded - but the file only had `include("callable")`, never `include("stringutility")`. `%_t`/`%_T` aren't engine syntax; they're ordinary Lua's `%` operator, wired to translation logic only after `stringutility.lua`'s `getmetatable("").__mod = interp` line has run at least once in that Lua state (see `Avorion_Modding_Codex.md`'s "UI Development" section for the full mechanism, confirmed by reading `stringutility.lua` directly). Without it, `%` falls through to real arithmetic, and a string operand can't coerce to a number - the server crashed with `attempt to perform arithmetic on a string value`, reported directly against this file. Fixed with `include("stringutility")`. A wider audit (proper transitive-closure over every mod's `include()` graph, not just per-file) initially flagged 29 more files across 6 mods with the same surface shape; every one of them turned out to already be protected by either a VFS merge with a vanilla file at the same path, or a caller whose own top-level `include()` chain runs before the flagged code could ever execute - so none of those were touched. This file's crash is the one instance with real evidence (a live crash log) behind it.

- [Bugfixed] **Diplomat Rescue Ship: Missing Interaction & 15,000 Reputation Loss (`cc_diplomatescort.lua`):** Reported via Discord: a stranded diplomat's special rescue dialogue failed to appear, and towing the ship to safety as a fallback cost the reporting player roughly 15,000 reputation with the escort's allied faction. Root cause found on a second, deeper pass: `ShipGenerator.createFreighterShip` (vanilla `lib/shipgenerator.lua`) always attaches `civilship.lua` to every freighter it builds, and this spawner only ever stripped `ai/patrol.lua`/`ai/freighter.lua` - `civilship.lua` was never removed. It registers its own competing interaction options ("Where is your home sector?", "Give me all your cargo!") in the same menu as `diplomatdialog.lua`'s intended "Open Comm Link", which is consistent with the rescue prompt being easy to miss or mistake for a generic vanilla civilian-ship encounter. Worse, `civilship.lua`'s own `CivilShip.threaten()` - reachable through that "Give me all your cargo!" path, or through a client-triggered hostile action such as towing - calls `CivilShip.worsenRelations()`, whose default `delta` is exactly `-15000`, matching the reported loss precisely; this was the real mechanism, not the ship's own faction ownership (an earlier, weaker theory from the first investigation pass). Fixed by adding `diplomat:removeScript("data/scripts/entity/civilship.lua")` alongside the existing AI removals, so only the intended dialogue remains registered. Also kept `diplomat.factionIndex = 0` (vanilla's "no faction" sentinel) from the first pass as defense-in-depth against any other vanilla ownership-sensitive system, and added a line to the diplomat's initial distress broadcast telling players to dock and open a comm link rather than tow or attack the ship. Separately verified, on request, that a player with no captain assigned or a captain of no class was never blocked from the rescue: `interactionPossible` in `diplomatdialog.lua` has no captain/class check at all, the base "Dock your pod" answer in `Dialog()` is unconditional, and `triggerServerPayout`'s captain-class gate only applies to the `tier == 2`/`tier == 3` bonus payouts - the standard `tier == 1` reward (150,000 credits, intentionally lower than the Merchant tier's 450,000) was already guaranteed to fire for any valid player regardless of captain status. No behavior changed; added comments at both points making this guarantee explicit so a future edit can't silently regress it.

## [v3.2.0]

### ⭐ Feature Overhaul
- [Feature] **Galactic News Network: More To Report On.** Extended the network's reach further into the Cosmic series and added a new domestic report type:
  - **EMPIRE HAS FALLEN (`cc_newsgenerator.lua`):** Added a lightweight tracker that watches every known AI faction and detects the exact moment one transitions from active to eradicated (via the same `FactionEradicationUtility` check every generator here already uses), publishing a Breaking News article naming the fallen empire. Previously this was one of the biggest events a galaxy can have — and it went completely unreported; only a plain chat broadcast from a third-party dependency ever mentioned it, never the News Network. Only reports a transition it actually observes (a faction already gone before the tracker ever saw it active is not retroactively announced), and persists its tracking across server restarts.
  - **Cosmic War Integration:** Fully completing a War Bounty License and AI factions actually reaching a ceasefire are now both reported — see Cosmic War's own changelog for details. Neither the Cosmic War hooks nor most existing generators used the shared API's new `breaking` flag by default; only genuinely rare, galaxy-scale events (Behemoth Incursions, boss defeats, empire collapses) are tagged that way, keeping the Breaking News banner meaningful instead of constant.
  - **Cosmic Vault API Upgrade:** `cosmicvaultnews.lua`'s `breaking` field is now formally documented and validated by the shared API itself rather than being an implicit convention this mod invented; see Cosmic Vault's own changelog.
- [Feature] **Galactic News Network Completely Overhauled (`cc_newsboard.lua`, `cc_newsgenerator.lua`):** The News Board was a single-column headline list with no sorting, filtering, search, timestamps, or way to tell a genuinely major event apart from routine ambient flavor text — despite the underlying `CosmicVaultNews` API already being used by 4+ mods across the Cosmic series with 30+ distinct, unnormalized category strings (`"War Crime"`, `"Trade Crisis"`, `"Galactic Milestone"`, etc.). Rebuilt the UI around a category-grouping layer that maps every observed category (plus a keyword-based fallback for any new one introduced later) onto seven stable top-level groups (War & Conflict, Economy, Threats & Crises, Discoveries & Milestones, Captain Stories, Politics, General), each with its own color: (1) a **category filter dropdown** and a **live search box** (matching vanilla's own Encyclopedia search-box pattern) let players narrow the headline list instead of scrolling a flat, unsorted feed; (2) the headline list is now a proper 3-column sortable-by-glance table (Category / Headline / Age) instead of a single plain-text column, color-coded by group; (3) a session-local **unread tracker** bolds unread headlines, marks them with a `●`, and shows a running "N Unread" counter in the header; (4) a new **Breaking News** system — `cc_newsgenerator.lua`'s highest-priority articles (the Behemoth Incursion alert and every one-time boss-defeat report) now set a `breaking` flag CosmicVaultNews' schema already tolerates without any change to the shared Cosmic Vault API — surfaces as a dedicated, clickable red banner atop the tab and an immediate galaxy-wide chat alert the moment it's published, instead of requiring a player to remember to open the News tab at all; (5) every headline now shows a relative age ("5m", "2h", "3d"), computed server-side per sync (`Client().unpausedRuntime` and `Server().unpausedRuntime` are different clocks with different origins, so the server snapshots each article's age directly rather than sending a raw timestamp for the client to compare against its own clock); (6) added a fourth ambient content generator, **Discovery News** (uncharted signals, derelict fleets, ancient ruins, rare stellar phenomena reported near a random active faction's territory), rebalancing the existing War/Economy/Captain Feats generation odds to make room for it; (7) the header layout was decluttered onto separate rows, matching the pattern already established elsewhere in the Cosmic series.

## [v3.1.5]

### 🚨 Critical Fixes
- [Bugfix] **Ghost Ship / Diplomat Escort / Rogue AI Probe Duplication Exploit:** Fixed a class of infinite farming exploits where these three events could be repeatedly re-triggered by reloading the sector before looting, because `terminate()` was never called (or only called on a non-payout branch) after the entity spawned. All three now unconditionally detach their spawner script immediately after spawning, matching the fix pattern already established for the Ghostship event in v3.1.4.
- [Bugfix] **Bounty Ambush Duplication Exploit:** Fixed a similar exploit in `cc_bounty_ambush.lua` where reloading the sector before killing the boss could spawn additional 2.5M-credit bounty bosses. Added a sector-value spawn guard and moved `terminate()` to fire only after the reward is paid out.
- [Bugfix] **Pirate Attack VFS Pragma:** Restored the missing `-- namespace PirateAttack` declaration in `pirateattack.lua`, required for the Virtual File System to correctly merge this override with the vanilla script.
- [Bugfix] **Galactic News Network & Stock Market Never Ran:** Fixed `cosmicchronicles.lua` passing relative (rather than full `data/scripts/...`) paths to `Galaxy():addScriptOnce()` for the News Generator and Stock Market background systems. Both silently failed to attach — `addScriptOnce` fails silently on a bad path — so the features simply never ran. Both now correctly initialize.
- [Bugfix] **Eclipse Lore Generator Memory Leak:** Fixed `cc_eclipselore.lua` only calling `terminate()` on the successful-spawn branch; every early-return path (already-evaluated sector, entity cap exceeded, the 95%-common no-spawn roll, invalid wreckage) left the generator permanently attached to the sector. `terminate()` now runs unconditionally at the top of `initialize()`, matching the one-shot generator pattern used elsewhere in the engine.
- [Bugfix] **Radio Chatter Save Bloat:** Fixed `radiochatter.lua` re-injecting its ambient dialogue lines into the persisted station data on every single sector/database reload instead of only on first creation, causing unbounded save-file growth over a long campaign.
- [Bugfix] **Diplomat Rescue Payout Exploit & Bribe Bug:** Fixed `diplomatdialog.lua` allowing the extraction reward to be claimed multiple times by spam-clicking the dialogue option during the ~4.5 second window before `deletejumped.lua` actually removes the entity. Also fixed the Smuggler-tier illegal tech bribe being dropped for an undefined global instead of the actual buyer.
- [Feature] **Captain's Log — Actually Implemented:** The file responsible for appending narrative "Captain's Log" text to background command yields (`background/simulation/command.lua`) patched a method (`Command:sendMail`) that doesn't exist in the engine and was never attached to anything — this feature has never worked since it was introduced. Replaced with a same-path VFS override of `background/simulation/simulation.lua` that hooks `Simulation.makeCommand`'s `command.addYield`, matching the exact pattern Cosmic Overhaul itself uses to extend the same file, so the two mods' hooks compose correctly regardless of load order.
- [Removed] **Dead Files:** Removed `entity/story/storybulletins.lua` (a duplicate of vanilla's own `bulletins.lua`, saved under a filename the VFS never matches — it added no unique content and nothing in the mod depended on it) and `player/background/simulation/command.lua` (superseded by the Captain's Log fix above).

### 🪲 Bug Fixes
- [Bugfix] **Destruction Tracker Locale Bug:** Fixed `cc_destructiontracker.lua` comparing an untranslated `faction.name` against a runtime-translated (`%_t`) string, which silently failed on any non-English server locale and lost the Pirate/Xsotan flavor text. Also removed a dead trailing `return` left over from a previous cleanup pass.
- [Bugfix] **Captain Class Mislabeling:** Fixed `cc_newsgenerator.lua` mapping `primaryClass == 1` to "Explorer" in generated news text; per the engine's captain class enum, 1 is Commodore and 6 is Explorer.
- [Bugfix] **Ghost Ship Dialogue Soft-Lock:** Fixed `ghostshipdialog.lua` setting its loot-claimed flag before validating the captain-class requirement for tiers 2/3, permanently soft-locking the wreck with zero payout if an ineligible captain triggered the wrong tier.
- [Bugfix] **Exodus Determinism:** Replaced two `math.random()` calls in `exodus.lua`'s wreckage placement with the engine's deterministic `random():getFloat()`/`getInt()`, matching this mod's established multiplayer-sync convention.
- [Bugfix] **Passing Ships Structural Consistency:** Wrapped an unconditionally-defined function in `passingships.lua` in `if onServer() then ... end` to match vanilla's own structure.

### 🧹 Cleanup
- [Changed] Fixed a hardcoded `X_success = true` anti-pattern across `cc_event_controller.lua`, `alienattack.lua`, `headhunter.lua`, and `spawntravellingmerchant.lua` that always reported a soft dependency include as successful regardless of whether it actually loaded; now correctly reflects the real `pcall(include, ...)` result.
- [Changed] Added missing localization markers (`%_t`) in `eclipseloredialog.lua` and `ancientcachedialog.lua`, and removed a dead redundant `callable(nil, "tooFar")` registration in `eclipseloredialog.lua`.
- [Changed] Removed a dead, unused `local EclipseLoot = {}` table and a dead commented-out `include()` in `factionattackssmugglers.lua`.

## [v3.1.4]

### 🪲 Bug Fixes
- [Bugfix] **Ghostship Exploit:** Fixed an infinite credit-farming exploit where the Ghostship event would repeatedly trigger upon reloading the sector. The event script is now safely purged from the engine's background simulation immediately upon looting the derelict. 
- [Feature] **Cinematic Explosions:** Added a massive client-side explosion effect that triggers immediately after looting the ghostship to provide visual feedback before the entity is deleted.

## [v3.1.3]

### 🪲 Bug Fixes
- [Bugfix] **Hidden Stash Crash & Performance:** Fixed a fatal crash in `cc_hiddenstash.lua` and `cc_blackbox.lua` caused by an invalid `SectorGenerator:getFactionIndex()` engine call. Drastically improved the sector generation performance by pulling the expensive `SectorGenerator` instantiation out of the asteroid spawning loops and properly adding a `terminate()` shutdown method to clear memory. Added proper translation hooks (`%_T`) for the broadcast messages.
- [Bugfix] **Global Wrapper Cleanup:** Cleaned up `cc_eclipselore.lua` and `cc_hiddenstash.lua` to remove deprecated pseudo-namespace global wrappers and redundant `initialize` wrappers, strictly enforcing the Code Review Protocol to prevent callback conflicts.

## [v3.1.2]

### 🪲 Bug Fixes
- [Bugfix] **Server Crash Prevention:** Fixed a critical server-side crash in `cc_blackbox.lua`, `ghostshipdialog.lua`, and `ancientcachedialog.lua` caused by the script improperly invoking `Sector():createExplosion()` on the dedicated server thread. The visual explosions have been safely decoupled or removed, ensuring the loot containers are successfully deleted at the end of the event.
- [Bugfix] **Ghost Ship Turret Errors:** Fixed a scripting error in `cc_ghostship.lua` where the engine attempted to call a non-existent `removeTurret` function. Turrets attached to the ghost ship are now safely and natively deleted from the sector.

## [v3.1.1]

### 🪲 Bug Fixes
- [Bugfix] **Generator Memory Leaks:** Fixed an issue in `cc_eclipselore.lua` and `cc_ancientdatacache.lua` where the generator script would permanently attach to the sector context if it hit an early return trap, causing background memory leaks over time.
- [Bugfix] **Generator Crash Check:** Added a `valid()` safety check to the Eclipse Lore and Ancient Data Cache generation scripts to ensure the engine fails gracefully instead of crashing if a wreckage plan fails to load.

## [v3.1.0]

### ⭐ Features
- **Newsboard Bounties:** The Galactic News Network will now occasionally post physical bounties for pirate leaders with exact coordinates! Hunt them down to claim a massive reward!
- **Derelict Log Fragments (Rift Exchange):** Ancient Data Caches now yield "Encrypted Log Fragments". You can trade these fragments at any Research Station for large sums of credits and a reputation boost!
- **Refugee Dialogue Tips (Stash Spawns):** When donating supplies to a Refugee Convoy, there is now a 25% chance they will tip you off to a massive hidden stash of resources and upload the coordinates to your map!

## [v3.0.8]

### 🪲 Bug Fixes
- [Bugfix] **Fire Rate API Error:** Fixed a core mathematical error inside the Rogue AI Probe event where extreme `FireRate` multipliers were being accidentally applied as flat additive numbers instead of percentages, preventing the probe from properly scaling its weapon attack speed.

## v3.0.7

### 🐛 Bug Fixes & Refactoring

- [Fixed] **Event Routing Desync Fix**: Following a strict architecture audit, a widespread event-routing violation was resolved across 6 scripts (`cc_factionmonument.lua`, `cc_refugeedialogue.lua`, `storybulletins.lua`, `cc_newsboard.lua`, `cc_destructiontracker.lua`, and `cosmicchronicles.lua`). These scripts were incorrectly defining global wrappers for standard engine callbacks (like `onInteract`, `initialize`, `onEntityDestroyed`), which shadowed the native namespace hooks. All illegal global wrappers have been permanently stripped so these modules securely and natively bind to the engine via their official namespace.

## v3.0.6

### 🔧 Balancing & Gameplay

- [Balance] **Empty Sector Density:** Massively reduced the spawn probabilities for deep space ambient events (Ghost Ships, Datacaches, Refugees, Rogue AI Probes) in `cc_event_controller.lua`. Empty sectors will now remain significantly more barren, returning a sense of eerie isolation to deep space exploration and making rare events feel genuinely special.

## v3.0.5

### 🐛 Bug Fixes
- [Fixed] **AI & Loot Logic:** Fixed various files with faulty AI and loot logic.
- [Fixed] **Namespace RPC Registries:** Fixed a critical structural flaw across `cosmicchronicles_rumormonger.lua`, `cc_refugeedialogue.lua`, `cc_factionmonument.lua`, and `cc_blackbox.lua` where multiple server dialogue callbacks were using global scope wrappers instead of the required namespace-aware `callable` registries. This previously prevented the Avorion C++ engine from properly routing `invokeServerFunction` calls to these systems, silently aborting station dialogues, monument inscriptions, and deep-space events.
- [Fixed] **Dynamic Reward Payout Crash:** Patched a severe bug in `cc_refugeedialogue.lua`, `cc_blackbox.lua`, and `diplomatdialog.lua` where dynamic credit rewards (Hazard Pay, Smuggled Goods, and Recovered Credits) utilized the unstable `player:receive()` API overload. The engine would occasionally fatally crash upon attempting to award credits. This has been completely replaced with direct property assignment (`player.money = player.money + ...`), permanently securing the reward payout.
- [Fixed] **Rogue AI Probe Timer:** Fixed a script pathing error in `cc_rogueaiprobe.lua` where the intended `warpawaytimer.lua` script did not exist. It has been replaced with the engine-native `delayeddelete.lua` utility, ensuring the Rogue AI Probe properly hyperspaces away if not destroyed within 3 minutes.

### 📦 Content Additions
- [Added] New .xml designs for events, lore and missions.

## v3.0.4

### 🐛 Bug Fixes

- [Fixed] **Guardian Event Disruption:** Fixed a critical bug in `cc_event_controller.lua` where calculating the entity count of an empty sector would throw a `length of a nil value` exception. This background crash was silently halting the global sector update loop, completely preventing the Wormhole Guardian flavor text and events from triggering upon entering the core.
- [Fixed] **Xsotan Distress Calls:** Fixed a bug in `cc_diplomatescort.lua` and `cc_refugeeconvoy.lua` where the script would grab "The Xsotan" as the nearest faction when triggered deep inside the galactic core. Refugees and diplomats will no longer accidentally spawn as disguised Xsotan vessels!
- [Fixed] **Infinite Loot Exploit:** Patched a severe multiplayer exploit in `ancientcachedialog.lua`, `eclipseloredialog.lua`, and `ghostshipdialog.lua` where players could use macros to rapidly spam the dialogue options, forcing the server to drop hundreds of loot instances before the cache entity was fully deleted at the end of the server tick.

## v3.0.3

### 🐛 Bug Fixes & ⚙️ Adjustments

- [Fixed] **Dialogue Syntax Errors:** Patched server-side crashes in the Bottan Smuggler mission caused by improper `invokeFunction` logic when un-quested players attempted to interact.
- [Changed] **Anti-Exploit Distances:** Recalculated the anti-exploit distance checks across 10+ event scripts. Interaction limits have been expanded (ranging from 500 - 3000 units) to ensure players flying huge ships are no longer falsely flagged as being "too far away."
- [Changed] **File Cleanup:** Stripped out unneeded script files (like `smugglerdelivery.lua`) that were identical to vanilla, reducing the mod's footprint and preventing future VFS conflicts.


## v3.0.2

### 🐛 Bug Fixes & ⚖️ Balance Tweaks

- [Fixed] **Bottan Delivery Feedback:** When attempting to hand over goods to the Smuggler during the Easy Delivery mission, players who were too far away (>50km) would experience a silent dialogue closure due to the anti-exploit check. The smuggler will now provide appropriate dialogue feedback explaining you are too far away to hand over the goods.
- [Balanced] **Refugee Convoys (Cosmic Overhaul):** Buffed the Merchant captain hazard pay from `25,000` to `50,000` credits. Buffed the Smuggler captain skimming limits from `35,000` to `75,000` credits.
- [Balanced] **Echoes of the Frontline (Cosmic Overhaul):** Buffed the Black Box extraction multiplier for Scavenger and Explorer captains from `1.5x` (+50%) to `2.0x` (+100%).
- [Balanced] **Cinematic Monuments (Cosmic Vault):** Increased the permanent reputation boost awarded for reading a faction's monument from `+1500` to `+2500`.
- [Balanced] **Corrupted Lore Nodes (Cosmic Ascendancy):** Increased the base credit payout of Eclipse caches from `150,000` to `250,000` base credits to properly compensate for the massive eclipse ships ambush that they spawn.
- [Fixed] **Silent Dialogue Failures:** Resolved a systemic issue affecting 9 different deep-space event scripts (Refugees, Monuments, Ancient Caches, Ghost Ships, Diplomats, Eclipse Caches, Bosses, Black Boxes, and Rumormongers). Previously, clicking a dialog option while out of range would silently abort the interaction. These events now provide a client-side dialogue box explaining that you are too far away.
- [Tweaked] **Swoks Boss Interaction:** Expanded the interaction range limit for the Swoks boss fight from `50km` to `200km`.

## v3.0.1 🐛Bug Fix Patch Update!🐛

- [Fixed] **File Path Error:** Corrected a pathing error in include() for the hermit missions.

## v3.0.0 UNRELEASED WORKSHOP VERSION (PROJECT UNDER DEVELOPMENT)

### ✨ New Features & 📦 Content Additions

- [Feature] **Deep Economy Integration:** Ambient Galactic News events (Trade Crisis & Market Boom) seamlessly tie into the `CosmicVaultEconomy` API, natively spiking or dropping a faction's active Famine Score.
- [Feature] **Dead Empire Filter:** Galactic News Generation natively utilizes `FactionEradicationUtility` to strictly filter out destroyed empires, preventing ghost factions from broadcasting messages.
- [Feature] **Post-Boss Anomalies:** Upon destroying the infamous Bottan Dreadnought, the game natively invokes `CosmicVaultAnomalies` to spawn a persistent `SpatialRift` anomaly for advanced exploration.
- [Feature] **Cosmic Codex Integration:** The mod now fully supports the Cosmic Codex! Comprehensive lore and mechanical documentation are readable directly in-game from the new Cosmic Codex tab.
- [Feature] **Deep Wiki Integration:** Hooked the Rumormonger and Captain's Log systems directly into the Cosmic Codex to explain their dynamic narrative mechanics natively in-game.
- [Feature] **Galactic News - The Stock Market:** The News Board now actively scans and reports on extreme economic supply/demand disparities, creating dynamic trading opportunities.
- [Feature] **Cosmic Vault API Framework:** Fully integrated with the Cosmic Vault API framework. Swept codebase for legacy callbacks and implemented safe pcall fallbacks.
- [Feature] **Corrupted Lore Nodes:** High risk, high reward data caches in Eclipse territory.
- [Feature] **Explorer Resonance:** Explorer captains detect black boxes from much further away.
- [Feature] **Galactic Lore Broadcasts:** Major discoveries publish global Cosmic Vault News.
- [Feature] **Famine Relief Anomalies:** Interactive Famine Relief Caches during severe faction famines.
- [Content] **Vanilla Story Quest Migration:** Massively ported and modernized all 21 core Avorion story quests directly into the unified Cosmic Codex API.
- [Content] **Unified Radio & Dynamic Chatter Expansion:** Centralized all ambient radio storytelling into Cosmic Chronicles. Expanded radio traffic with over 450+ new, immersive dialogue lines featuring deep lore drops on The Eclipse, Ascendants, and The Commune, vastly expanding the ambient variety of Station Chatter, Captain Logs, Rumors, Pirate Threats, and Sector Radio Broadcasts.
- [Content] **Dynamic Passing Ships:** Completely overhauled passing ship chatter via an override script. Ships now pull from a unique pool of ~270 customized lore lines.
- [Content] **Expanded Pirate Threats:** Injected a `pirateattack.lua` override that expands pirate ambush speech bubbles from a vanilla pool of 9 lines to a massive pool of 59 unique taunts.
- [Content] **Rumormonger Intrigues:** Injected over 30 new intricate rumors into the `CosmicVaultDialogue` system, giving players much more depth when asking stations for the latest galaxy gossip.
- [Content] **Deep Space Event - The Ghost Ship:** Discover intact derelicts with corrupted logs and hidden compartments. Captain Synergy: Scavengers find extra loot, Explorers decrypt coordinates.
- [Content] **Deep Space Event - Rogue AI Probe:** A fast, evasive anomaly scaling in difficulty near the core. Destroy it before it warps away for rare technology.
- [Content] **Deep Space Event - Diplomatic Escort:** Escort a stranded VIP across sectors. Captain Synergy: Diplomats negotiate massive payouts, Smugglers bypass patrols.
- [Content] **Deep Space Event - Ancient Data Caches:** Discover ancient vaults near the core to gain permanent buffs and massive Xsotan lore drops. Now dynamically loads a bespoke, ancient monolithic structure.
- [Content] **Deep Space Sector Generation - Eclipse Lore:** Replaced empty sectors with the chance to find Eclipse Beacons, Shipwrecks, and Stashes yielding deep lore and core-scaled loot. Beacons, Stashes, and Monuments now generate massive, customized `.xml` megastructures.
- [Content] **Classified Rift Tech:** Recovered Black Boxes now have a chance to drop highly-classified `Rift Research Data` and `Subclass Subsystems`. These contraband goods are extremely valuable on the black market.

### ⚙️ Changed & ⚖️ Balanced

- [Changed] **Standardized Jump Logic:** Swept the entire event codebase to remove hardcoded deletion logic. All AI ships now natively use the engine's `deletejumped.lua` script for flawless hyper-jump escapes.
- [Changed] **Inanimate Object Polish:** Swept all debris events (Ghost Ships, Blackboxes) to ensure they play `Sector():createExplosion()` before despawning, rather than just blinking out of existence.
- [Changed] **Lore-Accurate Debris:** Ghost ships and derelicts have had their AI controllers stripped. They now function as actual dead ships rather than active pirates.
- [Changed] **Updated:** Global Compliance and API updates across various scripts.
- [Changed] **Vault Integration:** Assured full compatibility with the new CCM 3-Column layout and Keybind systems.
- [Changed] **Unified News API:** Refactored multiple legacy news broadcasting systems to securely pass through the new `CosmicVaultNews.publishArticle` architecture for global validation.
- [Changed] **Core Dependencies:** Removed `pcall` soft-dependencies. Core 5 mods are now hard requirements.
- [Balanced] **Galactic Turn Synchronization:** The Stock Market background simulation interval has been synced to the global 20-minute (1200s) server turn to improve dedicated server performance.
- [Balanced] **Narrative Spawn Balancing:** Adjusted the global `events.lua` controller to strictly bound `Cosmic Chronicles` narrative event spawn rates to between 6% and 12% per sector visit, preventing overwhelming event chains.
- [Balanced] **Interaction Distance Enforcement:** Hardcoded a strict 500m distance constraint onto all callable interaction scripts (Diplomats, Distress Beacons) to prevent long-distance exploit interaction.

### 🐛 Bug Fixes & 🛠️ Optimization

- [Optimized] **Performance & TPS Optimization:** Drastically reduced server load during late-game scenarios. Injected a hardcoded `getUpdateInterval` throttle (1.0s) into `buymission.lua` and `hermitmission.lua` to prevent the engine from polling the sector 60 times a second.
- [Fixed] **Truthiness Logic Stabilized:** Applied strict explicit float comparisons (`> 0.5`) inside `cc_factionmonument.lua`, `radiochatter.lua` and other scripts, resolving cases where Avorion Lua engine would implicitly evaluate 0 values as truthy.
- [Fixed] **Cross-Mod API Integration:** Fixed a critical namespace error in `cc_newsboard.lua` where it incorrectly attempted to invoke the `cosmicvaultnews_server.lua` API via the `Server()` object instead of the `Galaxy()` object, completely restoring cross-mod news fetching functionality and resolving engine stack trace crashes.
- [Fixed] **Cosmic Codex Loading Crash:** Fixed missing global definitions (e.g. `entities`, `rangeType`) in the codex files that prevented the encyclopedia from loading correctly and crashed the UI.
- [Fixed] **Dynamic Event Spawn Logic:** Patched structural logic issues in the Ghost Ship, Stock Market, and Eclipse Lore scripts where float probability checks were being compared against `random():getInt()`, ensuring accurate event triggers globally.
- [Fixed] **Eclipse Lore Spawn Rate:** Fixed a math logic bug where `random():getInt() > 0.05` mathematically guaranteed an Eclipse Lore spawn almost 100% of the time, replacing it with `getFloat()` to restore the intended 5% rarity.
- [Fixed] **Data Cache Fallback Crash:** Injected a missing `plangenerator` requirement into `cc_ancientdatacache.lua` to prevent the engine from fatally crashing if the new `.xml` plans fail to load and the game attempts a procedural fallback.
- [Fixed] **Engine Freeze & Lockup Prevention:** Fixed a catastrophic script error inside `spawnrandombosses.lua` where a `while true do` loop lacked a failsafe iteration cap. This previously caused the entire Dedicated Server process to lock up 100% CPU and freeze during late-game boss anomaly generation.
- [Fixed] **Pathing Crash Hazards:** Repaired illegal absolute `include()` path injections (`include("data/scripts/entity/story/hermit")`) inside `crossthebarriermission` and `hermitmission` that could violently crash the server context.
- [Fixed] **Multiplayer Networking:** Added `onClient()` wrappers to the Exodus Wormhole Beacon UI to prevent the local singleplayer thread from self-invoking networking callbacks.
- [Fixed] **Desyncs:** Replaced `math.random` with `random():getInt()` inside `cc_rogueaiprobe.lua` and other event generators. This prevents physics desyncs and invisible collisions in multiplayer.

- [Fixed] **VFS Compliance:** Stripped redundant global wrapper functions from namespaced scripts to prevent silent double-execution logic loops and engine crashes.
- [Fixed] **Eclipse Anomaly Rarity Crash:** Fixed a critical bug where looting an Ancient Eclipse Anomaly would cause the `upgradegenerator.lua` script to crash due to a mismatch in the Rarity parameter arguments.
- [Fixed] **Eclipse Anomaly VFX Crash:** Fixed a dedicated server crash where the Anomaly was incorrectly trying to broadcast a client-only explosion effect on the server thread.
- [Fixed] **Multiplayer Exploit Prevention:** Added missing RPC callable registrations to prevent a silent error when the server attempted to warn players they were too far away from the Anomaly.
- [Fixed] **Research Station Hook:** Fixed a VFM script injection failure that was completely overwriting the vanilla `initUI` namespace in `researchstation.lua`, preventing the new Log Fragment turn-in interaction from ever appearing.
