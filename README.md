# Farol

[Português](README.pt-BR.md) | **English**

**Farol** (Portuguese for *lighthouse*) is a **free and open-source**, unofficial addon for WoW Forever: a small, draggable on-screen panel showing
**FPS · latency · memory · coordinates · zone · speed · Hearthstone · durability · bags · junk value · ammo & reagents · gold · session gold · gold/hour · XP · XP/hour ·
reputation · professions · gold/level goals · farm goals (items) · quest log · completed quests · clock · daily/weekly resets · tasks · notes · kept items · session time · current dungeon run · friends · guild** — you pick what shows (31 items).
Hover the panel for a detailed tooltip. It also has **clock alarms**, a **recent loot window** and **warnings**
(durability, bags, unspent talents, lower-rank spells).

## You decide: almost everything starts off

Farol respects your choice: **only what you turn on runs**, and **every new feature arrives turned off** — updating the
add-on never turns anything on by itself (an automated test checks this).

| On the first time | Everything else starts off |
|---|---|
| The bar with the basics: FPS, latency, coordinates, zone, Hearthstone, durability and gold (7 of 31 items) | The other 24 bar items and bars 2 and 3 |
| Warnings for durability, bags, unspent talents, lower-rank spells and professions (with sound) | Ammo, reagents, break, water, tasks, goals, quests, rested XP of your characters |
| Session summary at login and when leaving a dungeon — only in **your** chat | Full tooltip, server time, gold of all characters, hide in combat |
| Minimap button | Per-character profiles, alarms, tasks, goals |

- **To turn things on or off:** right-click the bar (or `/farol menu`) — hover each item to see what it shows.
  Everything that starts on can be turned off too.
- **After an update**, Farol lists what is new once in your chat and says which ones are off and where to turn them on
  (`/farol news` shows it again). If you already use the add-on, it keeps exactly what you chose.

## Installation

> **Upgrading from "WoW Forever Info"?** The addon was renamed. Delete the old
> `Interface/AddOns/WoWForeverInfo` folder before installing `Farol`. Your old settings are not carried
> over (just re-tick your items in the menu), and the chat command is now `/farol`.

1. Install it from **[CurseForge](https://www.curseforge.com/wow/addons/farol)**, or download this repository (**Code → Download ZIP**).
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
| `/farol lockouts`   | Saved instances (raid lockouts) of this and your other characters |
| `/farol summary`    | Summary of the current session (gold, XP, reputation, loot, warnings) |
| `/farol gold`       | Gold of all your characters on this realm |
| `/farol gold total on` / `off` | Show / hide the realm total next to your gold on the bar |
| `/farol gold forget Name` | Forget a character you deleted or no longer play |
| `/farol summary on` / `off` | Show / don't show the last session's summary at login |
| `/farol warn`       | Open the menu on the Warnings tab (durability, bags, talents, spell ranks, break, water) |
| `/farol warn status`| Show what Farol can read on your client (talents, reputation, resets) |
| `/farol history`    | Last 10 warnings (also the note button next to the bar, or a key binding) |
| `/farol appearance` | Open the appearance window (scale, background, layout, hide in combat) |
| `/farol order`      | Choose the order of the items on the bar |
| `/farol goal`       | Gold and level goals with a time estimate (`/farol goal gold 500`, `/farol goal level 40`) |
| `/farol preset`     | Turns on a preset of items: `basic` (back to the basics), `leveling`, `farm`, `dungeons`; `undo` |
| `/farol goal item`  | Farm goals: `/farol goal item [link] 40` (shift-click the item) or by name; `remove`, `clear` |
| `/farol minimap`    | Show/hide or lock the minimap button (`on`, `off`, `lock`, `unlock`) |
| `/farol dungeon`    | Your last 10 dungeons and raids: time, XP, gold, loot, deaths (`/farol run`) |
| `/farol completed`  | Completed quests of each character (list with search and total); `record on\|off` |
| `/farol chat Name`  | Which chat window Farol writes to (e.g. a tab named "Farol"); `/farol chat main` goes back |
| `/farol source on\|off` | Show where the session's XP and gold come from (quests, monsters, loot, merchant) |
| `/farol diag`       | Shows in your own chat how the game answered (character, realm, gold, last logout, events); read-only |
| `/farol keep`       | Items kept for later: reason, when they become useful, reminders (`[item]: reason`, `list`, `remove N`, `undo`) |
| `/farol notes`      | Account notepad: up to 10 notes with a done checkbox (`new Title`, `list`, `undo`) |
| `/farol task`       | Daily and weekly task list (resets on its own; `/farol task add Name`) |
| `/farol profile`    | Account profile or this character only; copy from another (`/farol profile copy Name`) |
| `/farol bar 2 show` | Turn on bar 2 (or 3) and pick it for the menu, Appearance and Order (`/farol bar` lists the bars) |
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

- **Click the Farol button on the minimap** (or in the game's addon list next to the minimap, on modern clients)
- **Right-click** the panel
- Type `/farol menu`
- **Esc → Options → AddOns → Farol**

The menu has **four tabs**:

- **Bar** — what belongs to the chosen bar: **Editing: Bar 1 / 2 / 3** (only picks which bar you are editing; it
  changes nothing), **Show** and **Lock**; in a box of its own, **Apply preset:** with the **presets** (**Basic**
  goes back to the basics; **Leveling**, **Gold & farm** and **Dungeons** turn on a set of items that go together;
  after applying one, the menu says what changed and an **Undo** button appears — also `/farol preset leveling` /
  `/farol preset undo`); the items in groups (Performance,
  Location, Gear and bags, Gold, Progress, Time and social), with a **gear** next to the ones that have settings (it
  opens that item's window or warning); a **strip at the bottom explains the hovered item**; and the
  **Appearance...** and **Order...** buttons of this bar.
- **Warnings** — every warning in groups: Gear and bags, Character, Quests and travel, Breaks, How to warn (sound,
  "Remind in", test, history). At the top, **Recommended only** and **Turn all off** (`/farol warn recommended` /
  `/farol warn none`); at the bottom, the explanation of the hovered warning. `/farol warn` opens the menu on this
  tab.
- **Tools** — one button per window, with what it does: Alarms, Tasks, Goals, Dungeons, **Completed quests**, Loot, History and **Summary now**.
- **General** — what applies to all your characters, in sections: **Language** (Auto / Português / English);
  **Chat and messages** (which chat tab, session summary at login, where XP and gold come from); **Bar and clock**
  (server time, gold of all characters, and an **Appearance...** button for the full tooltip, quick buttons, size and
  background); **Minimap and accessibility** (minimap button show / lock, colorblind-friendly colors); **Profiles
  (advanced)**: the same bars on every character or just this one, and **Copy from...**; and, set apart in red,
  **Restore and delete**: bar position, reset session and **forget characters** (asks for a second click).

**Minimap button:** click = menu, **right-click = hide/show every bar at once** (this session only — handy for
screenshots; `/farol` also brings them back), Shift-click = Warnings tab. Drag it around the minimap (unless locked).
`/farol minimap on|off|lock|unlock`. It is Farol's own button — no other addon or library is needed.

Press **Esc** to close it. If you hide the bar, use `/farol menu` to bring it back.

### Up to 3 bars

At the top of the menu, **Editing: [Bar 1] [Bar 2] [Bar 3]** chooses which bar the menu, **Appearance...** and
**Order...** change. Pick **Bar 2**, tick **Show** and the items you want: each bar has its **own items,
position, appearance (scale, background, text, layout, hide in combat) and order**. Right-clicking a bar opens the
menu with that bar already chosen. Bars 2 and 3 start off (and below bar 1); `/farol bar 2 show` / `/farol bar 2 hide`
also work. Alarms, loot, warnings, language and the quick buttons (📝 👜, next to bar 1) are shared.

### Profiles: account or this character only

**Profile: [Account ▾]** in the menu: by default every character uses the **account** profile (the same bars).
Choose **This character only** to give the current character its own bars (it starts as a copy of the account
profile; the account profile is kept). **Copy from... ▾** copies the 3 bars of the account or of another of your
characters into the profile in use — `/farol profile undo` puts it back (until you log out). Commands:
`/farol profile`, `/farol profile account`, `/farol profile character`, `/farol profile copy Name` (or `account`).
Profiles of your own characters only; forgetting a character (`/farol gold forget Name`) also forgets its profile.

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
- **Show border** on/off, **show icons on the bar** (one per item) and **show the warning history button**, **show the loot button**, **show the notes button** (off by default) and **full tooltip** (all information on every item).
- **Hide in combat** (comes back when the fight ends) and **hide in dungeons, raids, arenas and battlegrounds**.
  Alarms and warnings keep working while the bar is hidden.
- **Restore defaults** puts everything back.

Commands: `/farol appearance scale 120`, `/farol appearance bg 40`, `/farol appearance text 14`, `/farol appearance icons 20`, `/farol appearance row`, `/farol appearance column`, `/farol appearance width 400`,
`/farol appearance border`, `/farol appearance combat`, `/farol appearance instance`, `/farol appearance icons` (on/off),
`/farol appearance button` (warning history button), `/farol appearance lootbutton`, `/farol appearance tooltip`,
`/farol appearance default`.

## Durability and bag warnings

Farol warns you **once** when your most damaged item drops below **20%** durability, and when only **2 or
fewer** bag slots are free (with a separate "Bags full!" warning). The warning appears **in the middle of
your screen and in your own chat** (nothing is sent to anyone), with the game's ready-check sound.
When there is junk to sell, the bag warning says so: "… 3 slot(s) hold junk (3g 26s) you can sell."

- It warns again only after things improve (you repaired / freed slots), and at most once every 5 minutes,
  so it won't keep repeating while you loot or sell.
- Open the **Warnings** tab of the menu (or `/farol warn`) to turn each warning on/off, change the limits
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

### Ammo and reagents

The **Ammo & reagents** bar item (off by default) counts what your class uses: hunter ammo, warlock Soul Shards,
mage Arcane Powder and runes, priest candles, paladin symbols, druid seeds and Gift reagents, shaman Ankhs, rogue
powders. **You choose the warning and critical limits** in the Warnings tab (defaults: ammo 400 / 200,
reagents 10 / 5; critical must be lower than warning, 0 in warning = no warning level; on the bar, warning = yellow and
critical = red, or orange with the colorblind-friendly colors), or with `/farol warn ammo 400 200` and
`/farol warn reagents 10 5`. Optional warnings (off by default) fire once below red, wait for combat to end, and come
back after you restock: "Ammo: 150 running low — restock before leaving town." A reagent is only tracked after the
character has had at least one (a level 10 mage is not warned about Arcane Powder). Farol only **counts** — it never
buys, uses or moves items. `/farol warn status` shows what was found.

### Professions: find a trainer

In the classic style, professions stop leveling at each training limit (75, 150, 225, 300). When one reaches its
limit, Farol warns once: "Mining 150/150 at the training limit — find a trainer to keep leveling." It warns again at
the next limit after you train, never at the last one (300/300). Several at once are listed in one warning. It waits
for combat to end, has Silence / Remind like the others, and turns off with `/farol warn professions off` or in the
Warnings tab. `/farol warn status` shows the professions read and which game function answered.

### Break and drink-water reminders

Two optional reminders, **both off by default**, turned on in the Warnings tab:

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
  then, the warning shows up again. The time that comes selected is set in the Warnings tab (default 30).

- **Several warnings at once appear together** in one window, one line each (with its own Silence / Remind),
  plus **Silence all** and **Remind all in [N min ▾]**.
- One reminder per warning type: reminding again replaces the previous time. A reminder whose problem is
  already solved (you repaired, spent the points…) is dropped. Reminders end with `/reload` or logout.
- Chat: `/farol warn silence` and `/farol warn remind [minutes]` (all open warnings), `/farol warn default 10`.
- **Nothing is cut (since 3.21):** a long warning wraps onto up to 3 lines and the window grows taller; hover a
  warning to see the whole text, what it is about and where to adjust it. Drag the **◢ grip** in the corner to make
  the window wider or narrower (saved; right-click the grip or **Reset position** goes back to the default width).

### Warning history

The **last 10 warnings** (with date and time) are kept per character. Open them by:

- clicking the **note button next to the bar**: a red number shows how many new warnings you haven't seen;
- a **key binding** of your choice: Esc → Options → Keybindings → AddOns → Farol (uses the game's official
  `Bindings.xml`; it only opens the window);
- `/farol history`, or **History...** in the Warnings tab.

## Gold and level goals

Pick a goal — **gold** (e.g. 500 gold) and/or a **level** (e.g. 40) — with `/farol goal`, **Goals...** in the Tools tab
of the menu, or `/farol goal gold 500` / `/farol goal level 40`. The bar item **Goals** (off by default) shows how much
of each goal you have and an **estimate** of the time left from this session's pace (gold per hour, XP per hour):
`Goal 500g 44% ~27m · Lv 40 36% ~6h 10m` (yellow while in progress, green "reached"). The tooltip shows what you have,
the estimate ("around 22:41") and the pace. The level estimate assumes each remaining level costs as much XP as the
current one, so treat it as a rough guide. Optional warning (off by default): **"Goal reached: 500g!"**, once per goal.
Goals are per character. `/farol goal clear [gold|level]` removes them.

### Farm goals (items)

For gathering profession, quest or reputation materials: `/farol goal item [link] 40` (type the command and
**shift-click** the item to insert its link) or by name, `/farol goal item Silk Cloth 40` (the item must be in your bags
or in the loot history). You can also click **+ Goal** on a row of the loot window 👜 (a goal of 20, which you can change
later). The bar item **Farm** (off by default) shows the item and its progress (`Silk Cloth 27/40`: red at first,
yellow, green when done) or, with several goals, how many are done (`Farm 2/5`). The tooltip lists each item with how
many you got this session, the pace per hour and an estimate ("+18 this session (~24/h) · ~32m left"). The count
includes the bank when the game reports it. The **Goals...** window lists the items so you can change the amount or
remove them (X — removed one by mistake? **Undo**, next to the "Farm" title, or `/farol goal item undo`). Up to 10
items per character; the "goal reached" warning covers them too, once per item.
`/farol goal item remove <name or number>`, `/farol goal item clear`. Farol only **counts** items: it never moves, sells,
uses or loots anything, and nothing is sent.

## Accessibility

- **Colorblind-friendly colors** (General tab, off by default; `/farol colors colorblind` / `/farol colors default`):
  green (good) becomes **blue** and red (bad) becomes **orange**, while yellow (warning) stays. The three colors stay
  distinct for protanopia, deuteranopia and tritanopia. It applies to the bar, the tooltips and the counters on the
  📝 👜 buttons.
- Gold amounts show the number in the normal text color and only the **g / s / c** letters in gold, silver and
  copper, so yellow always means "warning".
- Removing a task or a farm goal, or applying a preset, can be **undone** with one click (this session).
- Status colors always come with a number or a word (`60 fps`, `Dur 54%`, `ready`): color is never the only cue.
- The bar's red is lighter, for better reading over bright scenery; windows have an opaque background and hints use a
  lighter gray.
- **Tab** moves to the next number field (Warnings tab and Goals window); Enter confirms and Esc closes.

## Hearthstone

The **Hearthstone** item shows where it is bound and how long until it is ready: `Lighthouse Village · 23m` (yellow),
`Lighthouse Village · ready` (green) or `Lighthouse Village · no stone` (grey, when it is not in your bags — the place
still shows). The tooltip shows what time it will be ready. It is on **only on a fresh install** (approved as an
exception to the "new features start off" rule); if you already use Farol, it arrives off — turn it on in Menu > Bar
(`/farol show hearth`). Optional warning (off) in the **Warnings** tab: **"Hearthstone ready"**, once per cooldown,
waiting for combat and dungeons to end (`/farol warn hearth on`). The **gold** tooltip also shows where each of your
characters was bound when they logged out. Farol only **reads**: it never uses the stone or binds it anywhere.

## Quest log

The bar item **Quests** (off by default) shows how many quests are in your log and how many fit, and how many are
**ready to turn in**: `Quests 17/20 · 3 ready` (green with room, yellow from 3 below the limit, red when full). The
tooltip lists the **ready to turn in** quests first, then the ones **in progress**, with the objective left (`3/8`), the
level colored by difficulty (as in the game) and how many are well above your level (at most 5 per list, "… and N
more"). Two optional warnings (off) in the **Warnings** tab: **quest log almost full** from N quests
(`/farol warn quests 19`, `/farol warn quests on`) and **quests ready** when you enter a city or inn
(`/farol warn ready on`; at most every 5 minutes). Farol only **reads** the quest log: it never accepts, turns in,
abandons or shares quests, and never opens collapsed categories. `/farol warn status` shows what it read.

**Value of the ready quests (since 3.23, off by default):** tick **XP and gold of ready ones** in the Warnings tab and
the bar shows `Quests 8/40 · 5 ready (+7.4k XP)`; the tooltip adds the total XP and gold of the ready quests, each
ready quest with its own reward (most XP first), **"Turning them all in: level 23 → 24 (6.5k XP left over)"** (or how
much XP is still missing) and the XP of the quests still in progress. The rewards come from the game itself for each
quest in your log (modern clients). Optional warning **Ready ones level you up** (off): once per level, when turning
in the ready quests is already enough to level up.

## Completed quests

The **Completed quests** window (Menu > Tools, or `/farol completed`) shows the quests each of **your** characters has
turned in: `[32] Delivery to Lighthouse Bay — #4127 — North Vale — Today 21:40`, newest first, with a **search by name
or ID** and mouse wheel scrolling. The **ID** (`#4127`) is the unique number the game gives each quest, handy to look the
quest up. **Click a quest** to see its Wowhead link in the WoW Forever section
(`https://www.wowhead.com/forever/quest=ID`), already selected so you can copy it with Ctrl+C and paste it in your
browser. It also works for quests from before recording, which only have their ID. Farol does not access the internet:
it only builds the address. At the top, pick the character (only yours, on the same realm).

- **Recording starts off.** Tick **"Record turned-in quests"** in the window (or `/farol completed record on`) and from
  then on each quest you turn in is saved with name, level, zone and date (up to 2,000 per character, the most recent).
- **Quests from before recording, by ID only:** tick **"Show quests from before recording (ID only)"** in the window
  (off by default) to see, after the recorded ones, the quests the game reports as completed: `#3210 (before
  recording)`, highest first, searchable by ID. Farol saves those IDs (up to 15,000 per character) each time you log in
  with recording on; other characters show up after they log in once with it on. The list includes internal markers of
  the game (IDs that are not real quests).
- **Names learned from the game:** with recording on, Farol saves the name of every quest you **see** — when you read
  it at the NPC, accept it, while it is in your log and when you turn it in — in an account-wide dictionary (up to
  5,000 names, for all your characters). Quests from before recording show their name once it is known; the others show
  "(name not seen yet)". The window shows "Known names: X of Y". All local reads: no server requests.
- **Total in game:** how many quests the game says the character has completed, **including those from before
  recording**. Their names are not shown: the game only reports them if the add-on asks the server, and Farol does not
  make that request. The total includes some internal markers of the game, so it may be a little higher than the real
  number. If the client does not report it, it shows `--` (the recorded list still works).
- Optional bar item (off): `Completed 412`, with each character's total, how many you turned in today and the latest
  ones in the tooltip.
- Everything stays on your computer (`FarolDB`); nothing is sent. **Forget characters** also deletes their lists.
  `/farol warn status` shows which game function reported the total. Farol only **reads**: it never accepts, turns in
  or abandons quests.

## Dungeon and raid runs

When you enter a **dungeon or raid**, Farol starts a "run" on its own: time inside, **XP**, **gold** (net, so repairs
count), **loot** (with rares and epics) and **deaths** — your own numbers only. The bar item **Dungeon / raid**
(off by default) shows it while you are inside (`Ember Depths 18m · +4.2k XP · +12g`); hover it for details and your
last time there. When you leave, a short **summary in your chat** (can be turned off): "left Ember Depths (dungeon):
32m · XP +6.8k · Gold +18g 40s · Loot 14 (2 rares, 1 epic) · Deaths 1". The window **Dungeons and raids**
(`/farol dungeon`, or **Dungeons...** in the Tools tab) lists the **last 10 runs** of the character.

A `/reload` inside keeps the run; if you are away from the game for more than 15 minutes, it ends at the last moment
seen. Visits under one minute are not saved. `/farol dungeon summary on|off`, `/farol dungeon clear`. (`/farol lockouts`
still lists your saved instances.)

## Daily and weekly tasks

Your own checklist of things to do, per character (up to 10): open it with `/farol task` or **Tasks...** in the
menu, type a task, choose **Daily** or **Weekly** and click **Add**. Tick what you have done. **Daily tasks go back to
"to do" at the daily reset, weekly tasks at the weekly reset** — on their own. The bar item **Tasks** (off by default)
shows how many are done (`Tasks 3/5`, yellow while something is left, green when all are done); hover it for the list.
Optional warning (off by default): **1 hour before the daily reset, if a daily task is left**.

Farol does not check anything in the game — you tick the tasks yourself. Commands: `/farol task add [daily|weekly] Name`,
`/farol task done N`, `/farol task remove N`, `/farol task undo`, `/farol task list`, `/farol task warn on|off`.
In the window, **Type: Daily / Weekly** picks the type of the new task; removed one by mistake (X)? A
**Task removed: ... [Undo]** line appears and puts it back in the same place (this session only).

## Notes (notepad)

Since 3.22, Farol has a notepad for the **whole account** (the same notes on every character): up to **10 notes**,
each with a short title (up to 40 letters) and a text of several lines (up to 500 letters), saved as you type. Open it
with `/farol notes` or **Notes...** in Menu > Tools.

- On the left, the list with a checkbox for each note: tick it when it is done. Done notes go below, in grey, and stay
  until you delete them (nothing resets on its own).
- On the right, the title and the text of the selected note; **✓ Done / Reopen** and **Delete**.
- **Delete** and **Clear done** ask first (click again to confirm) and show an **Undo** line (this session only).
- Optional bar item **Notes** (off by default): `Notes 2/5` = 2 pending of 5; hover it for the pending ones.
- **Notes button** next to the bar (since 3.25, off by default; Menu > General > **Appearance...** > "Show the notes
  button", or `/farol notes button on`): the number shows the pending notes; click opens/closes the window,
  **Shift-click** opens it with a new note, hovering lists the pending ones.
- **Key binding** of your choice: Esc → Options → Keybindings → AddOns → Farol → "Notes" (Farol sets no key).
- Commands: `/farol notes new Title`, `/farol notes list`, `/farol notes undo`, `/farol notes button on|off`.
- The notes stay on your computer; nothing is sent. Saved text is checked on load (size limits, no chat codes).

## Kept items (for later)

Since 3.26, you can keep a list of items you want to hold on to — for example a material for a recipe you only learn
at a higher level. Open it with `/farol keep` or **Kept items...** in Menu > Tools. The list is for the **whole
account** (up to 50 items).

- At the top: the item — **click the box to pick from a list of what you have** (bags, plus the bank as it was the
  last time you opened it; typing filters, the mouse wheel scrolls, click or Enter picks), or use `/farol keep` and
  Shift-click the item — an optional **reason** and
  **when** it becomes useful: no deadline, a **character level** or a **profession level** (from your professions).
  Click a row to load it back into the form and change it.
- Each row shows how many you have (with how many are in the bank, when the game says), the reason and the state:
  "level 35 — 7 to go", "ready", or "no deadline". **X** removes it, with **Undo** at the bottom.
- Kept items are left out of **Junk in bags**. The **Loot** window has a **Keep** button on each item (a check when
  it is already kept).
- The game only shows the bank while it is open: when you open it, Farol notes which items are there (item number and
  name, up to 1000, per character) just for this list. It never opens the bank or touches items.
- Optional reminders (off by default, in the window or by command):
  - **at a merchant** (`/farol keep merchant on`): which kept items are in your bags, with the reason;
  - **when the time comes** (`/farol keep ready on`): once per character, when you reach the level or profession level;
  - **in the item tooltip** (`/farol keep tooltip on`): a "Farol: kept — reason" line.
- Optional bar item **Kept items** (off): `Kept 4 · 1` = 4 kept, 1 ready.
- Farol never sells, moves or locks items: it only reminds you. Nothing is sent; the list is checked on load.

## Session summary

`/farol summary` shows, **only in your own chat**, what you did in this session:

```
Farol: session summary (2h 14m):
Farol:   Gold: +38g 12s (+17g 6s/h) · XP: +84.2k (1 level, 37.6k/h)
Farol:   Reputation: +1.3k Harbor Guild (Honored → Revered)
Farol:   Loot: 46 (3 rares, 1 epic) · Warnings: 2
```

- When you log out, Farol saves this summary for the character, and **the next time you log in** it shows
  "last session (date, duration)" in your chat. It is not shown after a `/reload`, and sessions under 5 minutes
  are not saved.
- Turn it off with **Session summary at login** in the options menu or `/farol summary off`.
- It uses the same numbers as the bar (session gold, XP/h, reputation per hour) and the loot and warning
  histories. Nothing is sent to anyone.

### Farol messages in a chat tab of their own (since 3.20)

Farol only writes in **your own** chat (nothing is ever sent). By default that is the main chat; to keep it apart:

1. Right-click a chat tab → **New Window** and name it **Farol** (once; Farol never creates or renames tabs).
2. Choose it in Menu > General > **"Farol messages in"**, or type `/farol chat Farol`.

Everything Farol writes goes there: session summary, warnings in chat, diagnostics, command answers, news. The
alarm and warning pop-ups stay on screen as before. If the tab is closed or renamed, messages go back to the main
chat, so nothing is lost. `/farol chat` lists your chat windows; `/farol chat main` goes back to the default.

### Where the XP and gold come from (optional, since 3.19)

Turn on **"Show where the XP and gold come from"** (Menu > General, or `/farol source on`) and the XP and gold
tooltips, plus the session summary, split the session by source:

- **XP:** quests (with how many you turned in), monsters (XP gained in combat or up to 3 s after it) and other
  (discovering places, professions).
- **Gold:** quest rewards, monster loot (with the loot window open), merchant sales, merchant purchases and repairs,
  and other (mail, auction house, trade, trainers, flights...).
- Quests use the XP and gold the game reports when you turn one in; if the game does not report them, the change
  that arrives together with the turn-in (up to 2 s) counts. "Other" is always the session total minus the other
  sources, so the sum matches the session gold and XP. `/farol diag` shows whether the game reported the reward.
- The percentages cover the whole session (the game does not say how long you spent on each activity, so there is
  no "per hour" for each source). Off by default; only events the game already sends are read; nothing is sent.

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
- History is saved **per character** (last 100 items). **Clear** asks first ("Delete 23 items?") and a second click
  within 5 seconds erases it. The same goes for the warning history and the dungeon log.

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
| Ammo & reagents | Ammo/reagents of your class, colored by your limits    | `ammo`       | off     |
| Gold            | Money on your character (optional total of all your characters) | `gold` | on      |
| Session gold    | Gold gained or spent since login / `/reload`           | `session`    | off     |
| Gold per hour   | Session gold per hour (red when negative)              | `goldh`      | off     |
| Experience (XP) | XP % and rested bonus (hidden at max level)            | `xp`         | off     |
| XP per hour     | XP/h and time to next level (after 1 min of session)   | `xph`        | off     |
| Reputation      | Watched faction: standing (game colors), progress %, rep/hour | `rep`        | off     |
| Professions     | Main professions with level/training limit (yellow near, red at the limit) | `prof` | off |
| Completed quests | How many quests this character has completed (each character's list in the window) | `completed` | off |
| Clock           | Local time, or server time (menu option)               | `clock`      | off     |
| Resets          | Time until the daily and weekly reset                  | `reset`      | off     |
| Notes           | Pending notes of your notepad (`Notes 2/5`)            | `notes`      | off     |
| Kept items      | Items kept for later and how many are ready (`Kept 4 · 1`) | `keep`   | off     |
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
city. The gold tooltip then shows an **estimate** for your other characters — e.g. `Mira (34) 150% full` or
`Tomas (22) 5% full in ~9d 16h` — using the classic rules: in an inn/city, 5% of a level every 8 hours; outside, a
quarter of that; up to 150%. The real value replaces the estimate when you log in with that character. Optional
warning (off by default) in the Warnings tab or `/farol warn rested on`: "Rested XP full (150%): Mira (34)…",
once per session.

**Junk in bags:** adds up the vendor price of your gray (Poor) items, e.g. `Junk 3g 26s (3)`; the tooltip shows
the most valuable ones. **Farol never sells anything** (that would be automation): you sell at a vendor. Items the
game has not loaded yet are counted as soon as their information arrives.

**Professions:** the bar shows your main professions (or the secondary ones if you have no main profession); the
tooltip lists all of them, including cooking, fishing and first aid, with the points gained this session.

**Resets:** counts down to the **daily** and **weekly** reset, using the time the game itself reports. The tooltip
shows when each one happens in local and server time. Older clients only report the daily reset.
The tooltip also lists your **saved instances** (raid/dungeon lockouts) — e.g. `Cinder Caverns 7/10 bosses, reset in
2d 4h` — and the gold tooltip shows where your **other characters** are saved (saved when you log out; expired
lockouts disappear by themselves). `/farol lockouts` lists everything in your chat. To get the list, Farol asks the
server once at login and at most once a minute after that (the same request as the game's own Raid window).

**Tooltip:** hover an item to see **only its details** — e.g. gold shows your gold, gold per hour, your characters
and their rested XP/lockouts; durability shows each damaged item; Resets shows the reset times and saved instances.
Hold **Shift** (or hover the edge of the bar) to see **everything** at once: home/world latency, subzone, exact XP,
local *and* server time, friends split by WoW / Battle.net, and more. Long lists show 5 lines and "and N more".
Prefer the old way? Tick **Full tooltip** in the Appearance window (`/farol appearance tooltip`).

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


WoW Forever **does not report the realm** and characters have a **first name and a surname**. Farol identifies each
character by name + surname (e.g. "Oxis Raknash") and groups them all under a fallback realm, shown as "this realm".
This applies to your characters' gold and rested XP, saved instances, per-character profiles and completed quests.
`/farol warn status` shows how the character was identified. When you log out, WoW Forever reports 0 gold, so Farol
saves the gold from the last reading made while you were playing; other readings that fail at that moment (rested
XP, saved instances, Hearthstone place) never erase what was already saved.

`/farol diag` (since 3.18) shows **in your own chat** how the game answered: character name and surname, the realm as
the game reported it, current gold, whether the game reported 0 gold at your last logout (and Farol kept the right
value), server time and resets, completed quests, and how many times some game events happened this session (quest
turn-in, reward window, quest accepted, gold changed). It only reads: nothing is sent or requested from the server,
and the counts live only in memory. A screenshot of it helps a lot when you report a problem.
## Security

Information security is this project's first rule:

- **Nothing leaves your computer.** The addon never uses `SendAddonMessage`, chat or any other channel to send data.
- **No external code is executed.** No `loadstring`/`RunScript`; commands only accept fixed words.
- **No automation.** It only reads and displays information; it never plays for you (which would break server rules).
- **Saved data is validated.** `FarolDB` only stores your settings: panel position and state, language, visible
  items and their order, appearance, alarms (time, clock type, on/off, a cleaned-up name and the snooze time),
  loot window and warning settings (since 3.0 the bar settings are grouped in a profile), your notes (notepad, titles and texts checked on load), and the gold and level of **your own** characters per realm (for the account
  total). `FarolCharDB` (per character) stores only your loot history (validated item
  links), the last 10 warnings, the last session's summary (numbers only, including the XP/gold by source when that option is on) and whether the game reported 0 gold at the last logout (yes/no and when, for `/farol diag`). Everything is checked on load — a corrupted or tampered file falls back to defaults.
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
saved data. The suite runs on Lua 5.1 and is also checked on Lua 5.4. It runs **twice**: once with a "textbook" mock
and once ("forever-real") the way WoW Forever really answers — empty realm, a surname in the character name and
0 gold at logout — plus a test where every game reading returns 0 or empty at logout and nothing saved may be lost.

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
| Must not hurt realm performance | ✅ Only two server requests, both read-only and rate-limited: the guild roster (at most once a minute, only if the Guild item is on) and the saved-instance list (once at login, then at most once a minute) — the same requests the game's own Guild and Raid windows make |
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
