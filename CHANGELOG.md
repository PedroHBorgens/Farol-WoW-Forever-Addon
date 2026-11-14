# Changelog

All notable changes to Farol. Versions follow the `## Version:` line of the `.toc` files.

## 2.24.1
- The list of news after an update shows one item per line (easier to read).

## 2.24.0 — Getting started
- First time: a welcome in your chat explains that the bar starts with the basics and how to turn on the rest
  (right-click the bar). After an update: the news since your version are listed once. `/farol news` shows them again.
  Nothing is turned on automatically.
- Options menu: counter "Bar items: 6 of 21 on" and, on hover, what each item shows (both languages).
- Bar tooltip: "Right-click: options (15 more items you can turn on)".
- Fix: when a tampered file had too many realms/characters, the ones kept were random (Lua 5.4 shuffles tables);
  now the most recently active are kept, in a fixed order.

## 2.23.0 — Rested XP of your characters
- On logout Farol saves your rested XP and whether you were in an inn/city; the gold tooltip shows an estimate for
  your other characters (classic rules: 5% of a level per 8 h in an inn/city, 1/4 of that outside, up to 150%) with
  "full" or the time until full.
- Optional warning (off by default): at login, another character has full rested XP. `/farol warn rested on|off`
  (`descansado` in Portuguese — `descanso` still means the break reminder).
- New test: command alias tables cannot repeat a name (found a clash between the two "rest" words).

## 2.22.0 — Gold of all your characters
- Farol remembers the gold and level of each of your characters (only on your computer) and the gold tooltip lists
  them per realm, richest first, with the total and when you last played each one.
- Option **Gold of all characters on the bar** (off by default): `123g 45s 67c (Total 1482g 10s)`.
- `/farol gold` lists them; `/farol gold forget Name` or **Forget characters** in the options (click twice to
  confirm) removes characters you no longer play. Saved names and values are validated on load (limits: 20 realms,
  60 characters each).

## 2.21.0 — Junk value
- New bar item **Junk in bags** (off by default): vendor value of gray items and the slots they take
  (`Junk 3g 26s (3)`); the tooltip lists the most valuable ones. Farol only shows it — it never sells.
- The bag warning now says how much junk you can sell.
- Works with the modern (`C_Container`) and old (`GetContainerItemInfo`) APIs; `/farol warn status` shows which.
- Robustness: a strange bag count from the game can no longer cause an endless loop. The forbidden-API test now also
  blocks selling, moving, destroying or equipping items and training/abandoning professions.

## 2.20.0 — Professions
- New bar item **Professions** (off by default): main professions with level / training limit (yellow when close,
  red at the limit, green at 300); the tooltip lists all of them with the points gained this session.
- New warning (on by default): a profession at its training limit → "find a trainer to keep leveling"; once per
  limit, never at 300/300; waits for combat; Silence / Remind; `/farol warn professions off`.
- Works with the modern (`GetProfessions`) and classic (`GetSkillLineInfo`) APIs; `/farol warn status` shows which.

## 2.19.0 — Break and water reminders, flexible "Remind"
- New optional **break** and **drink water** reminders, **off by default**: choose the interval (15–240 min) and
  whether they may show during fights, raids and dungeons (by default they wait). Silence = until the end of the session.
- **Remind in [N min ▾]**: every warning has a dropdown with 2, 5, 10, 15 or 30 minutes; the default (30) is set in
  the Warnings window. `/farol warn remind 10`, `/farol warn default 10`.
- Several warnings at once now appear **together in one window**, each with its own buttons, plus **Silence all**
  and **Remind all**. One reminder per warning type; solved problems are not reminded; reminders end on `/reload`.
- New settings validated on load and added to the fuzz test.
- Security review: turning a reminder off removes its open warning; the combat check is protected (if the game
  API fails, warnings wait instead of stopping); new permanent test against generic global names.

## 2.18.0 — Session summary
- `/farol summary` (`/farol resumo`) shows the current session **in your own chat**: gold and gold per hour, XP,
  levels and XP per hour, reputation (standing before → after), loot (rares, epics, legendaries) and warnings.
- On logout the summary is saved per character and shown **the next time you log in** ("last session"); not after
  `/reload`, and sessions under 5 minutes are not saved. Option **Session summary at login** (on by default) and
  `/farol summary on|off`.
- The saved summary holds numbers only and is validated on load (tampered values fall back or are discarded).

## 2.17.0 — Loot dates
- The recent loot window shows the day before the time: **Today 21:42**, **Yesterday 21:27** or the date
  (**Nov 8 21:12** / **08/11 21:12**; the year is added for older years). The day is dimmed so the item stands out.
- Hovering an item adds the full date to its tooltip ("Looted: Sunday, Nov 8, 2026 at 21:12").
- Works across midnight and daylight saving time; invalid saved dates show `--`; fractional timestamps are rounded
  down instead of failing on newer Lua engines (found in the security review).

## 2.16.1 — Security review
- Server time is validated (whole hours 0–23, minutes 0–59) before use in the clock, alarms and reset tooltip;
  an invalid or blocked value shows `--` (server-time alarms wait) instead of a wrong time or an error.

## 2.16.0 — Resets
- New bar item **Resets** (off by default): countdown to the daily and weekly reset (`Daily 5h 12m · Weekly 2d 4h`);
  the tooltip shows when each happens in local and server time.
- Uses `C_DateAndTime` (modern) or `GetQuestResetTime` (old clients, daily only); `/farol warn status` shows which.

## 2.15.1 — Security review
- Reputation: infinite values are rejected, progress always stays between 0% and 100%, odd standings show `?`.
- Faction names are shown as plain text (`|` cannot create links/icons) and are cut at 48 bytes without breaking letters.

## 2.15.0 — Reputation
- New bar item **Reputation** (off by default): watched faction, standing in the game's colors, progress %,
  reputation per hour; the tooltip adds progress and the time to the next standing.
- Works with the modern (`C_Reputation`) and old (`GetWatchedFactionInfo`) APIs; `/farol warn status` shows which one.

## 2.14.1 — Security review
- Fixed: corrupted saved history dates (infinite/NaN) no longer break the warning history and loot windows.
- Fuzz tests for commands, loot messages and tampered saved data.
- GitHub Actions pinned by commit SHA; `SECURITY.md` with private vulnerability reporting.

## 2.14.0 — Flexible bar
- Drag the grip at the bottom-right corner to choose the bar width; items rearrange into **left-aligned columns**
  (one line, one column or anything in between). Height adjusts automatically.
- "Vertical bar" option replaced by **One line / One column** shortcuts (old vertical setting migrates to one column).

## 2.13.1
- Fixed: vertical bar background was taller than the text; quick buttons move to the top corner.

## 2.13.0 — Bar order
- Choose the order of the bar items with ▲/▼ arrows (Order... window, `/farol order`).

## 2.12.0
- Separate **text size** (8–24) and **icon size** (10–32) options.

## 2.11.2
- Fixed: windows opened from the options menu could appear behind it.

## 2.11.1
- Fixed: unspent talent warning on WoW Forever (all talent sources are checked, plus a level-based estimate).

## 2.11.0
- Quick **loot button** 👜 next to the bar, with a new-items counter.

## 2.10.0
- One **icon** for every bar item.
- **History of the last 10 warnings**: note button 📝 with unread counter, key binding and `/farol history`.

## 2.9.0
- Warnings for **unspent talent points** and **lower-rank spells** on the action bars (never changes the bars).
- Every warning offers **Silence** or **Remind in 30 min**.

## 2.8.0 — Appearance
- Scale, background opacity, border, vertical bar, hide in combat and hide in instances.

## 2.7.0
- **Durability** and **bag** warnings (on screen and in your own chat, warns once).

## 2.6.0
- **XP per hour** (with time to next level) and **gold per hour**; session reset.

## 2.5.1
- Automated test suite and CI. Fixed: chat help showed broken `|` separators.

## 2.5.0
- Loot window: dropdown menus for count and quality filter; resizable window.

## 2.4.0
- Original lighthouse icon (AddOns list, menu, tooltip) and CurseForge materials.

## 2.3.0
- **Recent loot window** (last 5/10/15/20 items, quality filter, per-character history).

## 2.2.0
- Configurable alarm snooze (1–60 minutes).

## 2.1.0
- **Clock alarms** (local or server time) with snooze and stop.

## 2.0.0 — Renamed to Farol
- Renamed from "WoW Forever Info" to **Farol** (`/farol`) so it does not look like an official Blizzard product.

## 1.5.0
- Nine more bar items: memory, speed, bags, session gold, XP, clock, session time, friends, guild.

## 1.4.0
- Options menu with checkboxes.

## 1.3.0
- Zone and durability items, show/hide per item, hover tooltip.

## 1.2.0
- Slash command `/wfi`.

## 1.1.x
- Portuguese / English. WoW Forever support (Interface 16001; the client reads `_Mainline.toc`).

## 1.0.0
- First version ("WoW Forever Info"): FPS, latency, coordinates and gold.
