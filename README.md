# WoW Forever Info

[Português](README.pt-BR.md) | **English**

A **free and open-source** addon for WoW Forever: a small, draggable on-screen panel showing
**FPS · latency · coordinates · gold**.

## Installation

1. Download this repository (**Code → Download ZIP**).
2. Copy the `WoWForeverInfo` folder into `World of Warcraft/Interface/AddOns/`
   (the result must be `Interface/AddOns/WoWForeverInfo/Core.lua`).
3. On the character select screen, click **AddOns** and enable **WoW Forever Info**.
   If it shows as "out of date", tick **Load out of date AddOns**.

## Commands

| Command         | What it does                                          |
|-----------------|-------------------------------------------------------|
| `/wf`           | Show/hide the panel                                   |
| `/wf lock`      | Lock/unlock the panel (drag with left mouse button)   |
| `/wf reset`     | Move the panel back to its default position           |
| `/wf version`   | Show the client version and **Interface** number      |
| `/wf lang en`   | English interface                                     |
| `/wf lang pt`   | Portuguese interface                                  |
| `/wf lang auto` | Follow the client language (default)                  |

## Language

By default the addon follows your client language: **Portuguese** on `ptBR`/`ptPT` clients and
**English** on all others. Switch any time with `/wf lang en` or `/wf lang pt`; your choice is saved.

## Finding your client version

Run `/wf version` in game. The Interface number it prints goes on the first line of the `.toc` file:

- `WoWForeverInfo.toc` — default — **16001** (WoW Forever, client 1.60.1)
- `WoWForeverInfo_Vanilla.toc` — WoW Forever and Classic Era (16001, 11507)
- `WoWForeverInfo_Mainline.toc` — Retail (110205)

Clients pick the `.toc` with the matching suffix and fall back to the default one. If a future WoW Forever patch marks the addon as incompatible, update the number from the login screen version (e.g. 1.60.1 → 16001).

## Security

Information security is this project's first rule:

- **Nothing leaves your computer.** The addon never uses `SendAddonMessage`, chat or any other channel to send data.
- **No external code is executed.** No `loadstring`/`RunScript`; commands only accept fixed words.
- **No automation.** It only reads and displays information; it never plays for you (which would break server rules).
- **Saved data is validated.** `WoWForeverInfoDB` only stores the panel's position, state and language, and is
  checked on load — a corrupted or tampered file falls back to defaults.
- **Only download from the official source** (this repository). Addons are plain Lua text: you can read all of it in `Core.lua`.

Found a security issue? Open an issue without including personal data, passwords or account details.

## License

MIT — free to use, modify and distribute. See `LICENSE`.
