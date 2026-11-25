# Changelog

All notable changes to Farol. Versions follow the `## Version:` line of the `.toc` files.

## 3.24.0 — Clearer menu, consistent windows
- Menu tabs look like tabs: the open one is highlighted, with white text and a gold line under it.
- **General tab in sections:** Language · Chat and messages · Bar and clock · Minimap and accessibility · Profiles
  (advanced) · **Restore and delete**. Full tooltip and the quick buttons are now only in the Appearance window (they
  were in both places); an **Appearance...** button in the General tab opens it and says what is there.
- **Forget characters** is a danger action: alert icon and alert color, in its own reddish section; it still asks
  for a second click.
- Same pattern in the windows: **Tasks** creates at the top (box, type, Add) with the list below; the empty boxes show
  a grey hint ("New task...", "Note title") that disappears when you click or type; the **Undo** strip at the bottom
  has the same light background in Tasks and Notes.
- **Completed quests** with recording off: the empty window explains it and has a **Turn on recording** button
  (still off until you click). Option labels in Tasks and Completed quests use the normal font.
- No feature changed; nothing turns on by itself. Images 10, 13 and 16 updated. 750 tests (2 passes).

## 3.23.0 — Value of the ready quests
- New option **XP and gold of ready ones** (Warnings tab, off by default): the Quests bar item shows the XP of the
  quests ready to turn in (`5 ready (+7.4k XP)`) and its tooltip shows the total XP and gold, each ready quest with
  its reward (most XP first), whether turning them all in levels you up ("level 23 → 24 (6.5k XP left over)", or how
  much is missing) and the XP of the quests in progress.
- New optional warning **Ready ones level you up** (off by default): once per level.
- Rewards read with `GetQuestLogRewardXP` / `GetQuestLogRewardMoney` for each quest of the log (modern clients),
  confirmed in WoW Forever with a `/run` in game. Read-only; nothing is sent. No level-up line at max level.
- Warnings tab: the help strip moved down to make room. Image 08 updated. 744 tests (2 passes).

## 3.22.0 — Notepad
- New **notepad** for the whole account (`/farol notes`, Menu > Tools > Notes...): up to 10 notes, each with a title
  (up to 40 letters) and a multi-line text (up to 500 letters), saved as you type, with a **done** checkbox. Done
  notes go below, in grey, and stay until deleted. **Delete** and **Clear done** ask first and have **Undo**.
- New bar item **Notes** (off by default): pending of total, with the pending ones in the tooltip. 30 bar items.
- Saved in `FarolDB.notes` and validated on load (no `|` or control characters except line breaks, size limits, at
  most 10; a huge tampered file loads fast).
- XP/gold by source: sources that had nothing are no longer shown (no more "+0c" or "quests 0%" in the summary and the
  tooltips).
- Images 02 and 03 updated (30 items) and new image 18 (notepad). 734 tests (2 passes).

## 3.21.0 — Warnings window: nothing cut
- Long warnings no longer end in "…": each one wraps onto up to 3 lines and the window grows taller (one warning or
  several); the Silence / Remind buttons stay at the right of each warning.
- Hovering a warning shows a tooltip with the whole text, what that warning is about and where to adjust it
  (Menu > Warnings).
- New **◢ grip** in the corner of the warnings window: drag to make it wider or narrower (520–1400 px, saved in
  `warnings.popupW`, validated on load); right-click the grip, or **Reset position**, goes back to the default width.
- Image 06 updated. 722 tests (2 passes).

## 3.20.0 — Farol messages in a chat tab of their own
- New option in Menu > General, **"Farol messages in"** (and `/farol chat Name`): choose which of your chat windows
  Farol writes to, for example a tab named "Farol" that you create (right-click a chat tab → New Window). Default:
  the main chat, as before. `/farol chat` lists your chat windows; `/farol chat main` goes back.
- Farol only writes (`AddMessage`) in a window you already have; it never creates, renames or configures chat tabs
  (new forbidden-API entries in `test_toc.lua`). If the tab disappears, is renamed or fails, messages go to the main
  chat. Saved name validated (`FarolDB.chatWindow`, at most 48 bytes, no `|` or control characters).
- CLAUDE.md: confirmed in game that WoW Forever reports the quest XP and gold rewards on turn-in.
- 714 tests (2 passes).

## 3.19.0 — Where the XP and gold come from
- New option (off by default) **"Show where the XP and gold come from"** (Menu > General, `/farol source on|off`):
  the XP and gold tooltips and the session summary split the session by source — XP from quests (with how many were
  turned in), monsters (in combat or up to 3 s after) and other; gold from quest rewards, monster loot (loot window
  open), merchant sales, merchant purchases and repairs, and other (mail, auction, trade, trainers, flights).
- Quests use the XP and gold reported by `QUEST_TURNED_IN`; when the game does not report them, the change within 2 s
  of the turn-in counts. "Other" = session total minus the other sources, so the sum always matches.
- `/farol diag` shows the reward of the last turn-in (or "not reported"). The saved summary keeps only numbers
  (`lastSession.src`, validated on load); the counting itself lives only in memory. Nothing is sent.
- CLAUDE.md: confirmed in game that WoW Forever reports 0 gold only on a real logout, not on `/reload`.
- Image 09 (session summary) updated. 700 tests (2 passes).

## 3.18.0 — Diagnostics and tests that answer like WoW Forever
- New command **`/farol diag`** (`/farol diagnostico`): shows in your own chat how the game answered — name and
  surname, the realm as reported (WoW Forever: empty), current gold, whether the game reported 0 gold at your last
  logout (and Farol kept the right value), server time and resets, completed quests and how many times some events
  happened this session (quest turn-in, reward window, quest accepted, quest completed message, gold changed). It warns
  when there was a reward window but no turn-in event. Read-only: nothing is sent or requested from the server; the
  counts live only in memory; the only saved value is a yes/no + time of the last logout (`FarolCharDB.diag`,
  validated on load). It is just a command: it turns nothing on.
- Fixed (preventive): at logout, a game reading that fails at that moment (rested XP, saved instances) no longer
  erases what was already saved for the character.
- Gold is read in a single place (`Profiles.Money`) and the character/realm in a single place
  (`Profiles.ReadIdentity`); a test fails if any file calls `GetMoney`, `GetRealmName` or `UnitName("player")` directly.
- Tests: the whole suite now runs twice — "textbook" mock and **forever-real** (empty realm, surname, 0 gold at logout);
  new `test_forever_real.lua` with a "wrong moment" logout where every reading returns 0/empty. 690 tests.

## 3.17.1 — Gold of your other characters on WoW Forever
- Fixed: WoW Forever reports 0 gold at the moment you log out, so the character you left was saved with 0 gold
  (`/farol gold` and the gold tooltip) and the next session summary could show the whole gold as lost. Farol now
  saves the last gold reading made while playing (`Profiles.Money`, also sampled on `PLAYER_MONEY`, so it works with
  the bars hidden). The dungeon/raid log and the gold goal use the same safe reading (logging out inside a dungeon no
  longer records the whole gold as lost).
- New regression tests with the values seen in game.

## 3.17.0 — Quest names learned from the game
- Completed quests: with recording on, Farol learns the **name of every quest you see** — at the NPC (`QUEST_DETAIL`),
  when you accept it (`QUEST_ACCEPTED`), while it is in your log (`QUEST_LOG_UPDATE`, read at most every 5 s) and when
  you turn it in — into an account-wide dictionary (`FarolDB.questNames`, up to 5,000 names, the most recent, validated
  on load; a huge tampered file loads in under a second).
- Quests from before recording show their name when it is known ("(name not seen yet)" otherwise); search by name finds
  them; new counter "Known names: X of Y"; turn-ins without the reward window take the name from the dictionary.
- Local reads only: no server request, nothing sent; nothing is learned or saved while recording is off.

## 3.16.0 — Wowhead link for completed quests
- Completed quests window: click a quest (recorded or from before recording) to get its **Wowhead link** in the WoW
  Forever section (`wowhead.com/forever/pt/quest=ID/` in Portuguese, `wowhead.com/forever/quest=ID` in English),
  already selected to copy with Ctrl+C. Read-only box; the address is built only from a valid quest ID.
- Farol still does not access the internet: it only shows the address for you to copy.
- Tests for the link (clicks, read-only box, invalid IDs, English) and the adversarial script.

## 3.15.1 — Characters on WoW Forever (no realm, name + surname)
- Fixed: WoW Forever returns an empty realm, so Farol could not identify the character and the completed quests list,
  the gold/rested XP of your characters, saved instances of alts and per-character profiles stayed empty. A fixed
  fallback realm is now used (shown as "this realm").
- WoW Forever characters have a surname: `UnitName("player")` returns ("Name", "Surname"). The character is now
  identified as "Name Surname", so characters with the same first name are not mixed up.
- `/farol gold` no longer stays silent when the character is not identified; it says so.
- `/farol warn status` shows the identified character and realm. New `tests/test_realm.lua`.

## 3.15.0 — Earlier completed quests by ID
- Completed quests window: new option **"Show quests from before recording (ID only)"** (off by default). It lists, after
  the recorded quests, the IDs the game reports as completed (`#3210 (before recording)`), highest first, searchable by ID.
- With recording on, Farol saves each character's completed quest IDs at login (up to 15,000, the highest, validated on
  load); names are still not requested from the server. The list includes some internal markers of the game.
- Tests: earlier IDs (off by default, order, search, old client, validation) and fuzzing.

## 3.14.0 — Completed quests
- New **Completed quests** window (Menu > Tools, `/farol completed`): the quests each of your characters turned in, with
  name, level, the game's unique **quest ID**, zone and date, newest first, a search by name or ID and a character
  menu (your own characters only).
- **Recording starts off** (rule 8): tick "Record turned-in quests" in the window or `/farol completed record on`.
  Up to 2,000 quests per character; validated on load; "Forget characters" also deletes the lists.
- **Total in game** for each character (`C_QuestLog.GetAllCompletedQuestIDs` or `GetQuestsCompleted`), including quests
  from before recording (names are not available without a server request, which Farol does not make).
- New bar item **Completed** (off by default) with each character's total, today's count and the latest quests.
- Turn-ins come from `QUEST_TURNED_IN` (+ the reward window for the name and level); old clients use the system
  message "<quest> completed.". Read-only: no quest is accepted, turned in or abandoned; nothing is sent.
- Options menu: the Bar tab is a little taller (8 items in the Progress group).
- New `tests/test_completed.lua`; fuzzing covers the new saved data.

## 3.13.2 — Security hardening
- Manual security audit of the whole add-on, CI workflow and asset scripts (details in the pull request).
- Fixed: a tampered saved-variables file with a huge loot history, warning history or dungeon log, or a name made
  of hundreds of thousands of spaces, could freeze the game at login (trimming lists one item at a time and the
  `^%s*(.-)%s*$` trim pattern were quadratic). Lists now keep the most recent entries in linear time (`ns.KeepLast`)
  and names are trimmed in linear time (`ns.Trim`). No change for normal saved data.
- New `tests/test_hardening.lua`; SECURITY.md mentions the check.

## 3.13.1 — Text review
- **Clear** in the loot window and the warning history now asks first ("Delete 23 items?"); a second click within
  5 seconds deletes. The dungeon log asks the same way ("Delete 7 runs?"). Empty lists clear at once.
- Real plurals instead of "(s)": "3 free slots", "1 unspent talent point", "3 changes"...
- Texts describe the state, not the color, so they hold with the colorblind option: ammo/reagent limits are
  **warning / critical** (were yellow / red), FPS "good 50+, warning 25+", durability "alert below 20%".
- `/farol items` uses the palette (it was the last place with fixed colors).
- Same words for the same actions: alarms are turned **on/off** and **deleted** like everything else; neutral welcome
  in Portuguese; clearer Warnings tab hint, "Remind in" default, "Quests ready (city/inn)" and "+ Goal" tooltip.
- Loot window footer: scroll position and Clear on the bottom line, the hint above with the full width.

## 3.13.0 — Clearer menu and Undo
- Bar tab: the row now reads **Editing: [Bar 1] [Bar 2] [Bar 3]** (the chosen bar in white; hovering explains that
  switching bars changes nothing), and the presets sit in a box of their own, **Apply preset:**.
- After a preset, the menu says what changed ("Preset Leveling applied to bar 1 (3 changes)") and the **Undo** button
  appears (hidden when there is nothing to undo).
- **Undo** when removing a task (Tasks window, `/farol task undo`) or a farm goal (Goals window, `/farol goal item
  undo`): it goes back to the same place, this session only.
- Tasks window: the type of the new task is now **Type: Daily / Weekly**.
- Gold amounts: the number in the normal text color, only **g / s / c** colored, so yellow always means "warning".
- The counters on the 📝 👜 buttons follow the palette (and the colorblind option, right away).

## 3.12.0 — Accessibility
- New option **Colorblind-friendly colors** (General tab, off by default; `/farol colors colorblind`): good = blue,
  warning = yellow, bad = orange, distinct for protanopia, deuteranopia and tritanopia. All modules use one palette.
- The default red is lighter (contrast on bright scenery 2.9:1 → 3.7:1).
- Windows get an opaque background (the scenery no longer shows through); hint and "empty" texts use a lighter gray.
- The gear next to items is bigger (16 px, 24×24 click area).
- **Tab** moves between number fields (Warnings tab, Goals window), saving only what changed.
- A test keeps status colors in the palette, so the option reaches every module.

## 3.11.1 — Text review and menu fixes
- Bar tab: "Lock" no longer overlaps "Show" (it now sits right after the label, whatever the font); the row reads
  "Bar: [1] [2] [3]  Show  Lock", and the bar buttons are wider so "Bar 2 (off)" fits.
- The dungeon item is now called "Dungeon / raid run" so its gear fits inside the window.
- Order window wider (long names + "(hidden)" no longer touch the arrows); Alarms window and alarm popup wider, with
  long alarm names cut with "..."; warning popup buttons wider so "Remind all in 30 min" fits.
- Every text reviewed in Portuguese and English: "panel" is now "bar" everywhere; Portuguese help uses the Portuguese
  commands (/farol mostrar, esconder, travar, idioma, versao); "(off)" is "(desl.)" in Portuguese; outdated texts fixed
  (Warnings tab instead of window, the "+ Goal" button, profiles in the General tab, Goals window with farm goals,
  /farol warn recommended / none in the usage line).

## 3.11.0 — Simpler menu
- Bar tab: **presets** (Basic, Leveling, Gold & farm, Dungeons) set up the bar in one click, with **Undo**
  (`/farol preset leveling`, `/farol preset undo`); presets only change what you click (nothing turns on by itself).
- A **gear** next to items with settings (Hearthstone, ammo, quests, goals, farm, clock, tasks, dungeon) opens that
  item's window or warning.
- A strip at the bottom of the Bar and Warnings tabs explains the item or warning under the mouse.
- Warnings tab in groups (Gear and bags, Character, Quests and travel, Breaks, How to warn), with **Recommended only**
  and **Turn all off** (`/farol warn recommended`, `/farol warn none`).
- Profile and "Copy from..." moved to the General tab (Profiles, advanced). No setting changed.

## 3.10.0 — Hearthstone
- New bar item **Hearthstone**: where it is bound and the cooldown (`Lighthouse Village · 23m` / `ready` / `no stone`);
  the tooltip shows what time it will be ready.
- On only on a fresh install (approved exception to rule 8); existing players get it off, and the news says where to
  turn it on. Bar items missing from saved data now always arrive off.
- Optional warning (Warnings tab, off): "Hearthstone ready", once per cooldown, after combat and dungeons.
- The gold tooltip shows where each of your characters was bound when they logged out.
- Only reads (item-using and binding APIs added to the forbidden list); nothing sent. The Order window rows are a bit
  shorter so the 28 items fit on smaller screens.

## 3.9.1 — You decide: almost everything starts off
- New project rule: **every new feature starts off**; updating never turns anything on. An automated test keeps the
  exact list of what is on by default (nothing changed in this version).
- After an update, each news line says when the feature is off and where to turn it on
  (e.g. "quest log on the bar — off (turn it on in Menu > Bar)").
- The menu says everything is optional (Bar and Warnings tabs); READMEs and the CurseForge page list what starts on.

## 3.9.0 — Quest log
- New bar item **Quests** (off by default): `Quests 17/20 · 3 ready`, green / yellow / red as the log fills up.
- Tooltip: quests ready to turn in first, then the ones in progress with the objective left and the level colored by
  difficulty; how many are well above your level.
- Two optional warnings (Warnings tab): quest log almost full from N quests (`/farol warn quests 19`) and quests ready
  when you enter a city or inn (`/farol warn ready on`).
- Only reads the quest log (never accepts, turns in, abandons or shares; never opens collapsed categories); nothing sent.
- Images and docs use generic names only (no Blizzard characters, places or items); a test checks it.
- Fix: `/farol warn status` no longer errors if the game blocks the level reading.

## 3.8.0 — Farm goals (items)
- New **farm goals**: pick items to gather (`/farol goal item [link] 40`, shift-click the item, or by name), up to 10
  per character.
- New bar item **Farm** (off by default): `Silk Cloth 27/40`, or `Farm 2/5` (goals done) with several items.
- Tooltip: progress, how many this session, pace per hour and a time estimate; counts the bank when the game reports it.
- **+ Goal** button on each row of the loot window (goal of 20); the **Goals...** window lists the items to change the
  amount or remove them.
- The optional "goal reached" warning also covers farm goals, once per item.
- Only counts items (never moves, sells, uses or loots); nothing is sent. Saved goals are validated on load.
- Fixes: dragging the minimap button no longer errors if the game returns a missing cursor value; a missing
  profession level is skipped safely.

## 3.7.0 — Minimap button
- New **Farol button on the minimap**: click opens the menu, right-click hides/shows every bar at once (this session
  only; `/farol` also brings them back), Shift-click opens the Warnings tab. Drag it around the minimap.
- Modern clients also list Farol in the game's **addon list** next to the minimap (same clicks).
- **General** tab: "Show the minimap button" (on by default) and "Lock the minimap button position";
  `/farol minimap on|off|lock|unlock`.
- Farol's own button: no other addon or library; nothing is sent. The position is validated on load.

## 3.6.0 — Dungeon and raid runs
- Entering a dungeon or raid starts a **run**: time, XP, gold, loot (rares/epics) and deaths of your character.
- New bar item **Dungeon / raid** (off by default): shown only while inside (`Ember Depths 18m · +4.2k XP · +12g`);
  the tooltip has the details and your last time there.
- When you leave: a short summary in your chat (can be turned off).
- New window **Dungeons and raids** (`/farol dungeon`, or **Dungeons...** in the Tools tab): the last 10 runs.
- A `/reload` inside keeps the run; more than 15 minutes away ends it at the last moment seen; visits under one minute
  are not saved. Reads only your own data; no new server request, nothing sent. Saved runs are validated on load.

## 3.5.0 — Gold and level goals
- New **Goals** (`/farol goal`, or **Goals...** in the Tools tab): a gold goal and/or a level goal per character.
- New bar item **Goals** (off by default): `Goal 500g 44% ~27m · Lv 40 36% ~6h 10m` — how much you have and an
  estimate of the time left from this session's gold per hour and XP per hour; green "reached" when done. The
  tooltip shows the estimate ("around 22:41") and the pace.
- Optional warning (off by default, Warnings tab): "Goal reached: 500g!", once per goal.
- Reads only your own gold, level and XP; no new server request, nothing sent. Goals are validated on load.

## 3.4.0 — Tabbed menu
- The options menu now has four tabs: **Bar** (bar 1/2/3, profile, show/lock, the items in six groups, Appearance
  and Order of this bar), **Warnings** (all warnings in sections: gear and bags, character, breaks, how to warn),
  **Tools** (Alarms, Tasks, Loot, History, Summary now — one button each, with what it does) and **General** (what
  applies to all characters: language, server time, session summary, gold of all characters, full tooltip, quick
  buttons, and Restore).
- The separate Warnings window became the Warnings tab; `/farol warn` opens the menu on it. Shorter labels.
- New checkbox for the daily-tasks warning. The same tabs appear in Esc → Options → AddOns → Farol.
- All commands are unchanged.

## 3.3.0 — Daily and weekly tasks
- New **Tasks** window (`/farol task`, or **Tasks...** in the menu): up to 10 tasks per character, each **daily** or
  **weekly**. Tick what you have done; daily tasks reset at the daily reset and weekly ones at the weekly reset.
- New bar item **Tasks** (off by default): `Tasks 3/5`, yellow while something is left, green when all are done;
  the tooltip lists each task.
- Optional warning (off by default): 1 hour before the daily reset, if a daily task is left.
- You tick the tasks yourself — Farol does not check quests or anything in the game. Task names are cleaned and
  everything is validated on load.

## 3.2.0 — Per-character profiles
- New **Profile: [Account ▾]** in the menu: every character uses the account profile by default; choose
  **This character only** to give the current character its own 3 bars (starts as a copy of the account profile).
- **Copy from... ▾** copies the bars of the account or of another of your characters into the profile in use;
  `/farol profile undo` puts them back (this session).
- `/farol profile` (`/farol perfil`): status, `account`, `character`, `copy Name`, `undo`.
- Profiles of your own characters only, validated on load (same limits as the gold list: 20 realms × 60 characters);
  forgetting a character also forgets its profile.

## 3.1.0 — Up to 3 bars
- New **Bar: [Bar 1] [Bar 2] [Bar 3]** buttons at the top of the menu choose which bar the menu, Appearance and Order
  change. Each bar has its own items, position (drag), appearance, layout, lock, hide in combat/instance and order.
- Bars 2 and 3 start off, below bar 1. Turn them on in the menu (pick the bar, tick **Show panel**) or with
  `/farol bar 2 show`; `/farol bar` lists the bars. Right-clicking a bar opens the menu with that bar chosen.
- Alarms, loot, warnings, language and the quick buttons (next to bar 1) stay shared.
- Bars that were never turned on are not created. Saved bars are validated on load like bar 1.

## 3.0.0 — New settings structure (profiles and bars)
- Internal change preparing for multiple bars and per-character profiles: the bar's settings (position, appearance,
  visible items and their order) now live in `profiles.account.bars[1]` inside `FarolDB`.
- Your 2.x settings are converted automatically on the first login: **the bar looks exactly the same**.
- Old and new data go through the same validation as before; tampered profiles fall back to defaults.
- Alarms, loot window, warnings and characters stay account-wide, as before.

## 2.27.0 — Ammo and reagents
- New bar item **Ammo & reagents** (off by default): what your class uses (hunter ammo, soul shards, arcane powder and
  runes, candles, symbols, seeds, ankhs, rogue powders), yellow/red by the limits **you choose** in the Warnings window
  (`/farol warn ammo 400 200`, `/farol warn reagents 10 5`).
- Optional warnings (off by default) below red: once, wait for combat, again after restocking.
- A reagent is tracked only after the character has had one. Farol only counts — it never buys, uses or moves items.

## 2.26.0 — Smaller tooltip
- Each bar item now has its own short tooltip with only its details (e.g. gold: gold, gold/h, your characters,
  their rested XP and lockouts). Hold **Shift**, or hover the edge of the bar, for the full tooltip.
- Long lists (characters, damaged items, lockouts, junk) show at most 5 lines and "and N more".
- Option **Full tooltip** in the Appearance window (`/farol appearance tooltip`) for the old behavior.
- Dragging the bar and right-clicking for the options still work anywhere on the bar.

## 2.25.0 — Saved instances
- The Resets tooltip lists your saved instances (raid/dungeon lockouts) with bosses killed and time to reset; the
  gold tooltip shows where your other characters are saved (saved on logout; expired lockouts disappear).
- `/farol lockouts` (`/farol instancias`) lists everything; `/farol warn status` shows the count.
- Reads the game's saved-instance list; asks the server (RequestRaidInfo, like the Raid window) once at login and
  at most once a minute after that. Saved data validated on load.

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
