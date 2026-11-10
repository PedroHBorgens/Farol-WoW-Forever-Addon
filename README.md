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
| `/farol loot`       | Open the recent loot window |
| `/farol loot clear` | Clear this character's loot history |
| `/farol session reset`| Restart session gold, gold/h, XP/h and time |
| `/farol warn`       | Open the warnings window (durability and bags) |
| `/farol history`    | Last 10 warnings (also the note button next to the bar, or a key binding) |
| `/farol appearance` | Open the appearance window (scale, background, layout, hide in combat) |
| `/farol order`      | Choose the order of the items on the bar |
| `/farol alarm`      | Open the alarms window |
| `/farol alarm add 07:30`| Create an alarm (see below) |
| `/farol snooze`     | Snooze the ringing alarm (configured time, default 5 min) |
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
- **Snooze time:** type 1–60 minutes and press **Enter** (default 5). The Snooze button shows the current time.

When an alarm goes off it plays a sound and posts a message **only in your own chat window** — nothing is
sent to the server or other players — and a small window appears with **Snooze** and **Stop**.
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
| `/farol alarm snooze 10`                       | Set the snooze time to 10 minutes (1–60)      |
| `/farol snooze`                                | Snooze using the configured time              |
| `/farol snooze 15`                             | Snooze just this once for 15 minutes          |
| `/farol stop`                                  | Stop the ringing alarm                        |

Alarms only ring while the game is open. An alarm is not triggered in the same minute it is created or
after a `/reload` inside that minute (this avoids false alarms).

## Appearance

Open **Appearance...** in the options menu (or `/farol appearance`):

- **Scale** 50%–200% and **background opacity** 0%–100% (0% = only the text floats on screen), with [-]/[+] buttons.
- **Text size** 8–24 and **icon size** 10–32, separately (scale enlarges everything together). The bar and the
  quick buttons next to it adjust automatically.
- **Flexible layout**: drag the **grip at the bottom-right corner of the bar** (bar unlocked) to choose its width.
  Items rearrange into **left-aligned columns** that fit: wide = one line, narrow = one item per line, anything in
  between = 2, 3, 4… columns. The height adjusts automatically. Shortcuts: **One line** / **One column**. Locking the
  bar (`/farol lock`) hides the grip.
- **Show border** on/off, **show icons on the bar** (one per item) and **show the warning history button** and **show the loot button**.
- **Hide in combat** (comes back when the fight ends) and **hide in dungeons, raids, arenas and battlegrounds**.
  Alarms and warnings keep working while the bar is hidden.
- **Restore defaults** puts everything back.

Commands: `/farol appearance scale 120`, `/farol appearance bg 40`, `/farol appearance text 14`, `/farol appearance icons 20`, `/farol appearance row`, `/farol appearance column`, `/farol appearance width 400`,
`/farol appearance border`, `/farol appearance combat`, `/farol appearance instance`, `/farol appearance default`.

## Durability and bag warnings

Farol warns you **once** when your most damaged item drops below **20%** durability, and when only **2 or
fewer** bag slots are free (with a separate "Bags full!" warning). The warning appears **in the middle of
your screen and in your own chat** (nothing is sent to anyone), with the game's ready-check sound.

- It warns again only after things improve (you repaired / freed slots), and at most once every 5 minutes,
  so it won't keep repeating while you loot or sell.
- Open **Warnings...** in the options menu (or `/farol warn`) to turn each warning on/off, change the limits
  (durability 5–50%, bags 0–10 slots), turn the sound off or test it.
- Commands: `/farol warn durab 25`, `/farol warn bags 4`, `/farol warn durab off`, `/farol warn sound off`.

### Talents and spell ranks

- **Unspent talent points:** "You have 2 unspent talent point(s)." Warns at login and for each new point.
- **Lower-rank spells on your action bars:** "Fireball (Rank 3) — you already know Rank 5". Farol reads your
  spellbook and bars and warns once per spell until you replace it. It **never** changes your bars for you
  (that would be automation): you drag the new rank yourself.
- These two never warn in the middle of a fight; they wait until combat ends.
- `/farol warn status` shows what Farol can read on your client: the unspent points, the result of **each**
  talent source (the game function name changed between WoW versions, so Farol asks all of them and uses the
  highest value, plus a level-based estimate: level − 9 minus points spent), and lower-rank spells found. Turn them off with `/farol warn talents off` / `/farol warn ranks off`.

### Silence or remind me in 30 minutes

Every warning opens a small window with two choices:

- **Silence**: the warning stays quiet and only comes back if the situation changes (e.g. you repair and the
  durability drops again, or you gain a new talent point).
- **Remind in 30 min**: if the problem is still there in 30 minutes, the warning shows up again.

Several warnings at once are shown one at a time. Chat: `/farol warn silence`, `/farol warn remind`.

### Warning history

The **last 10 warnings** (with date and time) are kept per character. Open them by:

- clicking the **note button next to the bar**: a red number shows how many new warnings you haven't seen;
- a **key binding** of your choice: Esc → Options → Keybindings → AddOns → Farol (uses the game's official
  `Bindings.xml`; it only opens the window);
- `/farol history`, or **History...** in the Warnings window.

## Recent loot window

A separate window listing the items **you** looted or received, newest first.

- Open it with the **bag button next to the bar** (a green number shows items looted since you last opened
  it), **Loot...** in the options menu, or `/farol loot`.
- **Show** dropdown — 5, 10, 15 or 20 recent items.
- **Quality** dropdown — tick Poor, Common, Uncommon, Rare, Epic and Legendary+ (names and colors come from the game), or use *Check all* / *Uncheck all*.
- **Resizable** — drag the corner grip; the list follows the width and scrolls with the mouse wheel when it doesn't fit. The size is saved.
- Each row shows the item icon, the colored item link, the quantity and the time. Hover for the item tooltip;
  **Shift-click** puts the link in your chat box (you decide whether to send it).
- History is saved **per character** (last 100 items). **Clear** erases it.

It reads only the game's own loot messages about **you** ("You receive loot: …"), using the client's text,
so it works in any language. Other players' loot is ignored. In some instance/combat situations the
modern client may hide chat contents from addons; those items are simply not recorded.

## Bar items

The first six items are on by default; the others start off — tick them in the menu.

Session items (session gold, gold/h, XP/h, session time) count from login or `/reload`. Use **Reset session**
in the menu, or `/farol session reset`, to restart them (e.g. when you move to a new farming spot).

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
| Gold per hour   | Session gold per hour (red when negative)              | `goldh`      | off     |
| Experience (XP) | XP % and rested bonus (hidden at max level)            | `xp`         | off     |
| XP per hour     | XP/h and time to next level (after 1 min of session)   | `xph`        | off     |
| Reputation      | Watched faction: standing (game colors), progress %, rep/hour | `rep`        | off     |
| Clock           | Local time, or server time (menu option)               | `clock`      | off     |
| Resets          | Time until the daily and weekly reset                  | `reset`      | off     |
| Session time    | How long you've been playing since login / `/reload`   | `playtime`   | off     |
| Friends online  | Count of online WoW + Battle.net friends               | `friends`    | off     |
| Guild online    | Count of online guild members (hidden without a guild) | `guild`      | off     |

**Order:** open **Order...** in the options menu (or `/farol order`) and use the [▲]/[▼] arrows to move each
item; the bar updates immediately (in any layout). Hidden items are greyed out so you can place them in
advance. **Restore default order** (or `/farol order default`) undoes it.

Example: `/farol hide gold` hides gold; `/farol show gold` brings it back. Portuguese names also work
(`zona`, `ouro`, `bolsas`, `hora`…). Your choices are saved.

**Reputation:** shows the faction you mark as **"Show as Experience Bar"** in the game's reputation panel. The
tooltip adds progress, reputation per hour and an estimate of the time to the next standing.

**Resets:** counts down to the **daily** and **weekly** reset, using the time the game itself reports. The tooltip
shows when each one happens in local and server time. Older clients only report the daily reset.

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
- **Saved data is validated.** `FarolDB` only stores the panel's position, state, language, visible items your alarms (time, clock type, on/off, a cleaned-up name and the snooze time) and warning settings. `FarolCharDB` (per character) stores only validated item links from your loot history, and is
  checked on load — a corrupted or tampered file falls back to defaults.
- **Only download from the official source** (this repository). Addons are plain Lua text: you can read all of it in `Core.lua`.

Found a security issue? Please report it **privately** (Security → Report a vulnerability), as explained in
[`SECURITY.md`](SECURITY.md). Never include personal data, passwords or account details.

## Tests

The add-on has automated tests that run **outside the game**, on Lua 5.1 (the same version the WoW client
uses), against a small mock of the WoW API (`tests/wow_mock.lua`). They cover the bar on WoW Forever and
3.3.5a clients, secret values, the options menu, alarms and snooze, the loot window, the `.toc` files, and a
scan that fails if the code ever uses automation, messaging or dynamic-code APIs, and fuzzing with random and
malicious commands, chat messages and tampered saved data.

```
lua5.1 tests/run.lua
```

GitHub Actions runs them on every push and pull request (`.github/workflows/tests.yml`) and attaches an
install-ready `Farol-<version>` package to each run (Actions tab → the run → *Artifacts*).

## Publishing on CurseForge

The page text is in [`assets/curseforge-description.md`](assets/curseforge-description.md) and the project
avatar in [`assets/farol-icon-400.png`](assets/farol-icon-400.png). Upload a ZIP whose root contains only the
`Farol` folder, and select the WoW Forever game version (1.60.1).

The in-game icon (`Farol/Media/Farol.tga`, shown in the AddOns list) is original artwork made for this project.

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

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md) for the changes in each version.

## License

MIT — free to use, modify and distribute. See `LICENSE`.
