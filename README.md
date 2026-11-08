# Farol

[Português](README.pt-BR.md) | **English**

**Farol** (Portuguese for *lighthouse*) is a **free and open-source**, unofficial addon for WoW Forever: a small, draggable on-screen panel showing
**FPS · latency · memory · coordinates · zone · speed · durability · bags · gold · session gold · XP · clock · session time · friends · guild** — you pick what shows.
Hover the panel for a detailed tooltip, and choose which items appear on the bar.

## Installation

> **Upgrading from "WoW Forever Info"?** The addon was renamed. Delete the old
> `Interface/AddOns/WoWForeverInfo` folder before installing `Farol`. Your old settings are not carried
> over (just re-tick your items in the menu), and the chat command is now `/farol`.

1. Download this repository (**Code → Download ZIP**).
2. Copy the `Farol` folder into `World of Warcraft/_forever_/Interface/AddOns/`
   (the result must be `_forever_/Interface/AddOns/Farol/Core.lua`).
   Other clients use their own folder, e.g. `_retail_` or `_classic_era_`.
3. On the character select screen, click **AddOns** and enable **Farol**.
   If it shows as "out of date", tick **Load out of date AddOns**.

## Commands

| Command             | What it does |
|---------------------|--------------------------------------------------------|
| `/farol`            | Show/hide the panel |
| `/farol menu`       | Open the options menu (or right-click the panel) |
| `/farol alarm`      | Open the alarms window |
| `/farol alarm add 07:30`| Create an alarm (see below) |
| `/farol snooze`     | Snooze the ringing alarm for 5 minutes |
| `/farol stop`       | Stop the ringing alarm |
| `/farol lock`       | Lock/unlock the panel (drag with left mouse button) |
| `/farol reset`      | Move the panel back to its default position |
| `/farol show <item>`| Show an item on the bar |
| `/farol hide <item>`| Hide an item from the bar |
| `/farol items`      | List items and which are visible |
| `/farol help`       | List all commands |
| `/farol version`    | Show the client version and **Interface** number |
| `/farol lang en`    | English interface |
| `/farol lang pt`    | Portuguese interface |
| `/farol lang auto`  | Follow the client language (default) |

## Options menu

Tick or untick each item — no commands needed. Open it in any of these ways:

- **Right-click** the panel
- Type `/farol menu`
- **Esc → Options → AddOns → Farol**

The menu lets you choose bar items, show/lock the panel, switch the clock to server time, pick the language (Auto / Português / English)
and reset the position. Press **Esc** to close it. If you hide the panel, use `/farol menu` to bring it back.

## Clock alarms

Create up to **10 alarms**, each using **local time** or **server (game) time**, with an optional name.

- Open the window with **Alarms...** in the options menu, or type `/farol alarm`.
- Type the hour and minutes, click **Local/Server** to choose the clock, give it a name if you like, and click **Add**.
- Tick or untick an alarm to enable/disable it; **X** deletes it. **Test sound** plays the alarm sound.

When an alarm goes off it plays a sound and posts a message **only in your own chat window** — nothing is
sent to the server or other players — and a small window appears with **Snooze (5 min)** and **Stop**.
It **repeats every 30 seconds** until you snooze or stop it. An enabled alarm rings again the next day.
Alarms work even when the panel is hidden, and the Clock item shows a watch icon while any alarm is on.

Chat commands:

| Command                                        | What it does                                  |
|------------------------------------------------|-----------------------------------------------|
| `/farol alarm add 07:30`                       | Alarm at 07:30 (local time)                   |
| `/farol alarm add 22:15 server Raid`           | Alarm at 22:15 server time named "Raid"       |
| `/farol alarm list`                            | List alarms with their numbers                |
| `/farol alarm on 2` / `/farol alarm off 2`     | Enable / disable alarm number 2               |
| `/farol alarm remove 2`                        | Delete alarm number 2                         |
| `/farol snooze` / `/farol stop`                | Snooze 5 minutes / stop the ringing alarm     |

Alarms only ring while the game is open. An alarm is not triggered in the same minute it is created or
after a `/reload` inside that minute (this avoids false alarms).

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

Example: `/farol hide gold` hides gold; `/farol show gold` brings it back. Portuguese names also work
(`zona`, `ouro`, `bolsas`, `hora`…). Your choices are saved.

**Tooltip:** hover the panel to see every detail at once — home/world latency, subzone, each damaged
item, exact XP and rested, local *and* server time, friends split by WoW / Battle.net, and more.

**Privacy:** friends and guild items only read **counts**; no names are read or stored.

## Language

By default the addon follows your client language: **Portuguese** on `ptBR`/`ptPT` clients and
**English** on all others. Switch any time with `/farol lang en` or `/farol lang pt`; your choice is saved.

## Finding your client version

Run `/farol version` in game. The Interface number it prints goes on the first line of the `.toc` file:

- `Farol_Mainline.toc` — **WoW Forever** (16001) and Retail. **This is the file WoW Forever reads.**
- `Farol_Camelot.toc` — WoW Forever-specific fallback (16001)
- `Farol_Vanilla.toc` — Classic Era (11507)
- `Farol.toc` — default for any other client

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
- **Saved data is validated.** `FarolDB` only stores the panel's position, state, language, visible items and your alarms (time, clock type, on/off and a cleaned-up name), and is
  checked on load — a corrupted or tampered file falls back to defaults.
- **Only download from the official source** (this repository). Addons are plain Lua text: you can read all of it in `Core.lua`.

Found a security issue? Open an issue without including personal data, passwords or account details.

## Blizzard add-on policy compliance

This addon follows Blizzard's [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534):

| Policy rule | This addon |
|---|---|
| Must be free | ✅ Free, MIT license — no paid version, no paid features |
| Code must be visible (no obfuscation) | ✅ Plain, commented Lua in `Core.lua` |
| No ads or donation requests | ✅ None, in game or in this repository |
| Must not hurt realm performance | ✅ Only server request is the guild roster, at most once a minute and only if the Guild item is on (the same thing the game's own Guild window does) |
| Must not automate gameplay | ✅ Uses only the official addon API to **read and display** information; it never casts, moves, targets, buys, sells or sends chat |
| Must follow the Terms of Use / EULA | ✅ No external programs, no memory reading, no injection — it is not a `.exe` |

**Not affiliated with Blizzard Entertainment.** World of Warcraft and WoW Forever are trademarks of Blizzard Entertainment, Inc.

### How to stay safe from bans

- What gets accounts banned is **bots, automation software, unlockers, memory/injection tools and exploits** — not regular Lua addons like this one.
- Avoid key-automation tools (e.g. AutoHotkey macros that press keys for you); they can trigger "third-party automation" bans.
- Never run an `.exe` that claims to be an addon. Real addons are only `.lua`/`.toc`/`.xml` text files.
- Download only from this repository (or its official releases), and never type your password anywhere but the official Battle.net launcher.

## License

MIT — free to use, modify and distribute. See `LICENSE`.
