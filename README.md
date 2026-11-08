# WoW Forever Info

[Português](README.pt-BR.md) | **English**

A **free and open-source** addon for WoW Forever: a small, draggable on-screen panel showing
**FPS · latency · memory · coordinates · zone · speed · durability · bags · gold · session gold · XP · clock · session time · friends · guild** — you pick what shows.
Hover the panel for a detailed tooltip, and choose which items appear on the bar.

## Installation

1. Download this repository (**Code → Download ZIP**).
2. Copy the `WoWForeverInfo` folder into `World of Warcraft/_forever_/Interface/AddOns/`
   (the result must be `_forever_/Interface/AddOns/WoWForeverInfo/Core.lua`).
   Other clients use their own folder, e.g. `_retail_` or `_classic_era_`.
3. On the character select screen, click **AddOns** and enable **WoW Forever Info**.
   If it shows as "out of date", tick **Load out of date AddOns**.

## Commands

| Command           | What it does                                           |
|-------------------|--------------------------------------------------------|
| `/wfi`            | Show/hide the panel |
| `/wfi menu`       | Open the options menu (or right-click the panel) |
| `/wfi lock`       | Lock/unlock the panel (drag with left mouse button) |
| `/wfi reset`      | Move the panel back to its default position |
| `/wfi show <item>`| Show an item on the bar |
| `/wfi hide <item>`| Hide an item from the bar |
| `/wfi items`      | List items and which are visible |
| `/wfi help`       | List all commands |
| `/wfi version`    | Show the client version and **Interface** number |
| `/wfi lang en`    | English interface |
| `/wfi lang pt`    | Portuguese interface |
| `/wfi lang auto`  | Follow the client language (default) |

## Options menu

Tick or untick each item — no commands needed. Open it in any of these ways:

- **Right-click** the panel
- Type `/wfi menu`
- **Esc → Options → AddOns → WoW Forever Info**

The menu lets you choose bar items, show/lock the panel, switch the clock to server time, pick the language (Auto / Português / English)
and reset the position. Press **Esc** to close it. If you hide the panel, use `/wfi menu` to bring it back.

## Bar items

The first six items are on by default; the others start off — tick them in the menu.

| Item            | Shows                                                  | Command name | Default |
|-----------------|--------------------------------------------------------|--------------|---------|
| FPS             | Frames per second (green ≥ 50, yellow ≥ 25)            | `fps`        | on      |
| Latency         | Highest of home/world latency (green ≤ 100 ms)         | `ms`         | on      |
| Memory          | Total Lua memory (UI + addons)                         | `mem`        | off     |
| Coordinates     | Your map position (`--` inside instances)              | `coords`     | on      |
| Zone            | Current zone name                                      | `zone`       | on      |
| Speed           | Movement speed (100% = normal running)                 | `speed`      | off     |
| Durability      | Your **most damaged** item (red below 20%)             | `durab`      | on      |
| Bags            | Free / total bag slots (red at 2 or fewer)             | `bags`       | off     |
| Gold            | Money on your character                                | `gold`       | on      |
| Session gold    | Gold gained or spent since login / `/reload`           | `session`    | off     |
| Experience (XP) | XP % and rested bonus (hidden at max level)            | `xp`         | off     |
| Clock           | Local time, or server time (menu option)               | `clock`      | off     |
| Session time    | How long you've been playing since login / `/reload`   | `playtime`   | off     |
| Friends online  | Count of online WoW + Battle.net friends               | `friends`    | off     |
| Guild online    | Count of online guild members (hidden without a guild) | `guild`      | off     |

Example: `/wfi hide gold` hides gold; `/wfi show gold` brings it back. Portuguese names also work
(`zona`, `ouro`, `bolsas`, `hora`…). Your choices are saved.

**Tooltip:** hover the panel to see every detail at once — home/world latency, subzone, each damaged
item, exact XP and rested, local *and* server time, friends split by WoW / Battle.net, and more.

**Privacy:** friends and guild items only read **counts**; no names are read or stored.

## Language

By default the addon follows your client language: **Portuguese** on `ptBR`/`ptPT` clients and
**English** on all others. Switch any time with `/wfi lang en` or `/wfi lang pt`; your choice is saved.

## Finding your client version

Run `/wfi version` in game. The Interface number it prints goes on the first line of the `.toc` file:

- `WoWForeverInfo_Mainline.toc` — **WoW Forever** (16001) and Retail. **This is the file WoW Forever reads.**
- `WoWForeverInfo_Camelot.toc` — WoW Forever-specific fallback (16001)
- `WoWForeverInfo_Vanilla.toc` — Classic Era (11507)
- `WoWForeverInfo.toc` — default for any other client

Clients pick the `.toc` with the matching suffix and fall back to the default one. If a future WoW Forever
patch marks the addon as incompatible, update the number in `_Mainline.toc` from the login screen version
(e.g. 1.60.1 → 16001), or check it in game with `/run print(select(4, GetBuildInfo()))`.

### WoW Forever notes

WoW Forever runs on the modern (Midnight) client and inherits its "secret values" combat restrictions.
This addon only reads FPS, latency, coordinates and gold; if the game hides a value, the panel shows `--`
instead of raising an error.

## Security

Information security is this project's first rule:

- **Nothing leaves your computer.** The addon never uses `SendAddonMessage`, chat or any other channel to send data.
- **No external code is executed.** No `loadstring`/`RunScript`; commands only accept fixed words.
- **No automation.** It only reads and displays information; it never plays for you (which would break server rules).
- **Saved data is validated.** `WoWForeverInfoDB` only stores the panel's position, state, language and visible items, and is
  checked on load — a corrupted or tampered file falls back to defaults.
- **Only download from the official source** (this repository). Addons are plain Lua text: you can read all of it in `Core.lua`.

Found a security issue? Open an issue without including personal data, passwords or account details.

## License

MIT — free to use, modify and distribute. See `LICENSE`.
