# Cosmic Chronicles (WIP)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**Cosmic Chronicles** is the narrative, world-building, and lore module of the Cosmic mod series for Avorion.

Currently an active Work-In-Progress (WIP), this mod aims to breathe life into the universe through a dynamic "Living Galaxy" text system. It feeds atmospheric dialogue, ambient chatter, and dynamic rumors to players based on their reputation, current sector, and local faction states.

---

## Quick Highlights (Planned)

- **Living Galaxy System:** Dynamic dialogue injected into stations, merchants, and entities.
- **Contextual Rumors:** Hear whispers of war, smuggler movements, and Xsotan activity depending on your reputation and faction traits.
- **Vault Powered:** Built seamlessly on top of the shared `Cosmic Vault` dialogue API framework.

---

## Installation

1. Place the mod folder into:
   - **Windows:** `%AppData%\Avorion\mods\`
   - **Linux:** `~/.avorion/mods/`
2. Ensure the required dependency is installed:
   - **Cosmic Vault**
3. Enable **Cosmic Chronicles** in **Settings -> Mods**.
4. Restart the game/server when prompted.

---

## Compatibility Snapshot

- `serverSideOnly = false`
- Heavily relies on **Cosmic Vault** for its core API injections.
- For full dependency specifics, see `modinfo.lua`.

---

## Project Notes

- This repository is currently in active development. Systems and features are subject to rapid iteration.
