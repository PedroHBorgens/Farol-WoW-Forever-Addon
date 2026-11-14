# Farol

[Português](README.pt-BR.md) | **English**

**Farol** (Portuguese for *lighthouse*) is a **free and open-source**, unofficial addon for WoW Forever: a small, draggable on-screen panel showing
**FPS · latency · memory · coordinates · zone · speed · durability · bags · junk value · gold · session gold · gold/hour · XP · XP/hour ·
reputation · professions · clock · daily/weekly resets · session time · friends · guild** — you pick what shows (21 items).
Hover the panel for a detailed tooltip. It also has **clock alarms**, a **recent loot window** and **warnings**
(durability, bags, unspent talents, lower-rank spells).

> **Most features start turned off.** The bar begins with the basics (FPS, latency, coordinates, zone, durability,
> gold). **Right-click the bar** (or `/farol menu`) to turn on the others — hover each item to see what it shows.
> The first time, Farol says this in your chat; after an update it lists what is new, once (`/farol news` shows it
> again).

## Installation

> **Upgrading from "WoW Forever Info"?** The addon was renamed. Delete the old
> `Interface/AddOns/WoWForeverInfo` folder before installing `Farol`. Your old settings are not carried
> over (just re-tick your items in the menu), and the chat command is now `/farol`.

1. Install it from **CurseForge** (search for *Farol*), or download this repository (**Code → Download ZIP**).
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
| `/farol session reset`| Restart session gold, gold/h, XP/h, rep/h and time |
| `/farol news`       | Show again what is new in the latest versions |
| `/farol summary`    | Summary of the current session (gold, XP, reputation, loot, warnings) |
| `/farol gold`       | Gold of all your characters on this realm |
| `/farol gold total on` / `off` | Show / hide the realm total next to your gold on the bar |
| `/farol gold forget Name` | Forget a character you deleted or no longer play |
| `/farol summary on` / `off` | Show / don't show the last session's summary at login |
| `/farol warn`       | Open the warnings window (durability, bags, talents, spell ranks, break, water) |
| `/farol warn status`| Show what Farol can read on your client (talents, reputation, resets) |
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

The menu lets you choose bar items, show/lock the panel, switch the clock to server time, turn the session summary at login on/off, show the gold of all your characters on the bar, forget characters, pick the language (Auto / Português / English)
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
`/farol appearance border`, `/farol appearance combat`, `/farol appearance instance`, `/farol appearance icons` (on/off),
`/farol appearance button` (warning history button), `/farol appearance lootbutton`, `/farol appearance default`.

## Durability and bag warnings

Farol warns you **once** when your most damaged item drops below **20%** durability, and when only **2 or
fewer** bag slots are free (with a separate "Bags full!" warning). The warning appears **in the middle of
your screen and in your own chat** (nothing is sent to anyone), with the game's ready-check sound.
When there is junk to sell, the bag warning says so: "… 3 slot(s) hold junk (3g 26s) you can sell."

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

### Professions: find a trainer

In the classic style, professions stop leveling at each training limit (75, 150, 225, 300). When one reaches its
limit, Farol warns once: "Mining 150/150 at the training limit — find a trainer to keep leveling." It warns again at
the next limit after you train, never at the last one (300/300). Several at once are listed in one warning. It waits
for combat to end, has Silence / Remind like the others, and turns off with `/farol warn professions off` or in the
Warnings window. `/farol warn status` shows the professions read and which game function answered.

### Break and drink-water reminders

Two optional reminders, **both off by default**, turned on in the Warnings window:

- **Break reminder**: "You've been playing for 2h 00m — time for a break?"
- **Drink water reminder**: "Time to drink some water!"
- You choose the interval of each one (**15 to 240 minutes**; defaults 120 and 45). The count starts at login
  (or when you turn it on / change the interval) and repeats.
- **Also during fights, raids and dungeons** (off by default): when off, a reminder that comes due during a fight
  or inside a dungeon, raid, arena or battleground **waits** and shows as soon as you are out.
- **Silence** turns that reminder off until the end of the session (it is back at the next login).
- Commands: `/farol warn break 90`, `/farol warn water 30`, `/farol warn break on` / `off`,
  `/farol warn water fights on` / `off`.

### Silence or remind me later

Every warning opens a small window with two choices:

- **Silence**: the warning stays quiet and only comes back if the situation changes (e.g. you repair and the
  durability drops again, or you gain a new talent point).
- **Remind in [30 min ▾]**: choose **2, 5, 10, 15 or 30 minutes** in the dropdown; if the problem is still there
  then, the warning shows up again. The time that comes selected is set in the Warnings window (default 30).

- **Several warnings at once appear together** in one window, one line each (with its own Silence / Remind),
  plus **Silence all** and **Remind all in [N min ▾]**.
- One reminder per warning type: reminding again replaces the previous time. A reminder whose problem is
  already solved (you repaired, spent the points…) is dropped. Reminders end with `/reload` or logout.
- Chat: `/farol warn silence` and `/farol warn remind [minutes]` (all open warnings), `/farol warn default 10`.

### Warning history

The **last 10 warnings** (with date and time) are kept per character. Open them by:

- clicking the **note button next to the bar**: a red number shows how many new warnings you haven't seen;
- a **key binding** of your choice: Esc → Options → Keybindings → AddOns → Farol (uses the game's official
  `Bindings.xml`; it only opens the window);
- `/farol history`, or **History...** in the Warnings window.

## Session summary

`/farol summary` shows, **only in your own chat**, what you did in this session:

```
Farol: session summary (2h 14m):
Farol:   Gold: +38g 12s (+17g 6s/h) · XP: +84.2k (1 level, 37.6k/h)
Farol:   Reputation: +1.3k Orgrimmar (Honored → Revered)
Farol:   Loot: 46 (3 rares, 1 epic) · Warnings: 2
```

- When you log out, Farol saves this summary for the character, and **the next time you log in** it shows
  "last session (date, duration)" in your chat. It is not shown after a `/reload`, and sessions under 5 minutes
  are not saved.
- Turn it off with **Session summary at login** in the options menu or `/farol summary off`.
- It uses the same numbers as the bar (session gold, XP/h, reputation per hour) and the loot and warning
  histories. Nothing is sent to anyone.

## Recent loot window

A separate window listing the items **you** looted or received, newest first.

- Open it with the **bag button next to the bar** (a green number shows items looted since you last opened
  it), **Loot...** in the options menu, or `/farol loot`.
- **Show** dropdown — 5, 10, 15 or 20 recent items.
- **Quality** dropdown — tick Poor, Common, Uncommon, Rare, Epic and Legendary+ (names and colors come from the game), or use *Check all* / *Uncheck all*.
- **Resizable** — drag the corner grip; the list follows the width and scrolls with the mouse wheel when it doesn't fit. The size is saved.
- Each row shows the item icon, the colored item link, the quantity and **when** you looted it: **Today 21:42**,
  **Yesterday 21:27**, or the date for older items (**Nov 8 21:12**). Hover for the item tooltip, which also shows
  the full date ("Looted: Sunday, Nov 8, 2026 at 21:12"); **Shift-click** puts the link in your chat box (you decide
  whether to send it).
- History is saved **per character** (last 100 items). **Clear** erases it.

It reads only the game's own loot messages about **you** ("You receive loot: …"), using the client's text,
so it works in any language. Other players' loot is ignored. In some instance/combat situations the
modern client may hide chat contents from addons; those items are simply not recorded.

## Bar items

Six items are on by default (FPS, latency, coordinates, zone, durability and gold); the others start off — tick
them in the menu.

Session items (session gold, gold/h, XP/h, reputation per hour, session time) count from login or `/reload`. Use **Reset session**
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
| Junk in bags    | Vendor value of gray items and the slots they take     | `junk`       | off     |
| Gold            | Money on your character (optional total of all your characters) | `gold` | on      |
| Session gold    | Gold gained or spent since login / `/reload`           | `session`    | off     |
| Gold per hour   | Session gold per hour (red when negative)              | `goldh`      | off     |
| Experience (XP) | XP % and rested bonus (hidden at max level)            | `xp`         | off     |
| XP per hour     | XP/h and time to next level (after 1 min of session)   | `xph`        | off     |
| Reputation      | Watched faction: standing (game colors), progress %, rep/hour | `rep`        | off     |
| Professions     | Main professions with level/training limit (yellow near, red at the limit) | `prof` | off |
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

**Gold of all your characters:** Farol remembers the gold and level of each of **your** characters when you play
with it, and the gold tooltip lists them per realm (richest first, with when you last played each one) plus the
total. Tick **Gold of all characters on the bar** (or `/farol gold total on`) to see `123g 45s 67c (Total 1482g 10s)`.
It only knows a character after you log in with it once with Farol on. Use **Forget characters** in the options
(click twice to confirm) or `/farol gold forget Name` for characters you deleted. This stays on your computer only.

**Rested XP of your characters:** when you log out, Farol also saves your rested XP and whether you were in an inn or
city. The gold tooltip then shows an **estimate** for your other characters — e.g. `Jaina (34) 150% full` or
`Arthas (22) 5% full in ~9d 16h` — using the classic rules: in an inn/city, 5% of a level every 8 hours; outside, a
quarter of that; up to 150%. The real value replaces the estimate when you log in with that character. Optional
warning (off by default) in the Warnings window or `/farol warn rested on`: "Rested XP full (150%): Jaina (34)…",
once per session.

**Junk in bags:** adds up the vendor price of your gray (Poor) items, e.g. `Junk 3g 26s (3)`; the tooltip shows
the most valuable ones. **Farol never sells anything** (that would be automation): you sell at a vendor. Items the
game has not loaded yet are counted as soon as their information arrives.

**Professions:** the bar shows your main professions (or the secondary ones if you have no main profession); the
tooltip lists all of them, including cooking, fishing and first aid, with the points gained this session.

**Resets:** counts down to the **daily** and **weekly** reset, using the time the game itself reports. The tooltip
shows when each one happens in local and server time. Older clients only report the daily reset.

**Tooltip:** hover the panel to see every detail at once — home/world latency, subzone, each damaged
item, exact XP and rested, reputation progress, when the daily/weekly reset happens, local *and* server time,
friends split by WoW / Battle.net, and more.

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
Every value Farol reads is protected: if the game hides or blocks a value (for example during combat), the panel
shows `--` instead of raising an error.

## Security

Information security is this project's first rule:

- **Nothing leaves your computer.** The addon never uses `SendAddonMessage`, chat or any other channel to send data.
- **No external code is executed.** No `loadstring`/`RunScript`; commands only accept fixed words.
- **No automation.** It only reads and displays information; it never plays for you (which would break server rules).
- **Saved data is validated.** `FarolDB` only stores your settings: panel position and state, language, visible
  items and their order, appearance, alarms (time, clock type, on/off, a cleaned-up name and the snooze time),
  loot window and warning settings, and the gold and level of **your own** characters per realm (for the account
  total). `FarolCharDB` (per character) stores only your loot history (validated item
  links), the last 10 warnings and the last session's summary (numbers only). Everything is checked on load — a corrupted or tampered file falls back to defaults.
- **Only download from the official sources** (this repository or the CurseForge page). Addons are plain Lua text:
  you can read all of it in the `Farol` folder.

Found a security issue? Please report it **privately** (Security → Report a vulnerability), as explained in
[`SECURITY.md`](SECURITY.md). Never include personal data, passwords or account details.

## Tests

The add-on has automated tests that run **outside the game**, on Lua 5.1 (the same version the WoW client
uses), against a small mock of the WoW API (`tests/wow_mock.lua`). They cover the bar on WoW Forever and
3.3.5a clients, secret values, the options menu, alarms and snooze, the loot window, warnings (including break and
water reminders and the grouped window), appearance, reputation, resets, the session summary, the `.toc` files, a
scan that fails if the code ever uses automation, messaging or dynamic-code APIs, a check that the add-on creates no
generic global names (only `Farol…`), and fuzzing with random and malicious commands, chat messages and tampered
saved data. The suite runs on Lua 5.1 and is also checked on Lua 5.4.

```
lua5.1 tests/run.lua
```

GitHub Actions runs them on every push and pull request (`.github/workflows/tests.yml`) and attaches an
install-ready `Farol-<version>` package to each run (Actions tab → the run → *Artifacts*).

## Publishing on CurseForge

The page text is in [`assets/curseforge-description.md`](assets/curseforge-description.md) and the project
avatar in [`assets/farol-icon-400.png`](assets/farol-icon-400.png); the screenshots (illustrations) are in
[`assets/curseforge/`](assets/curseforge/). Upload a ZIP whose root contains **only** the `Farol` folder (with
`LICENSE.txt` inside it — any file loose at the root is rejected), and select the WoW Forever game version (1.60.1).
Each GitHub Actions run builds that package for you (*Artifacts*).

The in-game icon (`Farol/Media/Farol.tga`, shown in the AddOns list) is original artwork made for this project.

## Blizzard add-on policy compliance

This addon follows Blizzard's [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534):

| Policy rule | This addon |
|---|---|
| Must be free | ✅ Free, MIT license — no paid version, no paid features |
| Code must be visible (no obfuscation) | ✅ Plain, commented Lua in the `Farol` folder |
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
