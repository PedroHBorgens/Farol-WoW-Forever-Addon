import base64, os
OUT = os.path.dirname(os.path.abspath(__file__))
logo = base64.b64encode(open(os.path.join(OUT, '..', 'farol-icon-512.png'),'rb').read()).decode()

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
body{width:1280px;height:720px;overflow:hidden;font-family:'DejaVu Sans',sans-serif;color:#fff;
 background:radial-gradient(ellipse at 70% 20%,#2a4a7a 0%,#12243f 45%,#070d1a 100%);position:relative}
.stars{position:absolute;inset:0;background-image:radial-gradient(#fff8 1px,transparent 1.5px);background-size:90px 90px;opacity:.25}
.stage{position:absolute;left:0;right:0;top:0;bottom:150px;display:flex;align-items:center;justify-content:center;gap:40px}
.cap{position:absolute;left:0;right:0;bottom:0;height:150px;background:linear-gradient(180deg,#0000,#000c 35%);
 display:flex;flex-direction:column;justify-content:center;padding:0 60px}
.cap h1{font-family:'Inter',sans-serif;font-weight:800;font-size:40px;color:#ffd75a;letter-spacing:.2px;text-shadow:0 2px 8px #000}
.cap h2{font-family:'Inter',sans-serif;font-weight:500;font-size:26px;color:#d9e4f2;margin-top:6px;text-shadow:0 2px 6px #000}
.tag{position:absolute;top:16px;right:20px;font:600 14px 'Inter';color:#ffffffaa;background:#0007;border:1px solid #fff3;border-radius:999px;padding:5px 12px}
.brand{position:absolute;top:14px;left:18px;display:flex;align-items:center;gap:10px;font:800 22px 'Inter';color:#ffd75a;text-shadow:0 2px 6px #000}
.brand img{width:40px;height:40px;border-radius:6px;box-shadow:0 0 0 2px #c9a24a}
.win{background:linear-gradient(#141821f2,#0b0e15f5);border:3px solid #6e5b2e;outline:1px solid #c9a24a;outline-offset:-6px;border-radius:8px;
 box-shadow:0 12px 40px #000c;padding:18px 20px;position:relative}
.win .t{font-family:'DejaVu Serif',serif;font-weight:bold;color:#ffd100;text-align:center;font-size:20px;margin-bottom:12px;text-shadow:0 1px 2px #000}
.x{position:absolute;top:10px;right:12px;width:22px;height:22px;border-radius:4px;background:#7a1c12;border:1px solid #d8a24a;color:#ffd;font:bold 14px/20px sans-serif;text-align:center}
.bar{background:#000b;border:2px solid #666;border-radius:6px;padding:7px 14px;display:inline-flex;gap:16px;align-items:center;font-size:15px;box-shadow:0 6px 24px #000a;white-space:nowrap}
.vbar{background:#000b;border:2px solid #666;border-radius:6px;padding:10px 14px;display:flex;flex-direction:column;gap:5px;font-size:15px;box-shadow:0 6px 24px #000a}
.it{display:inline-flex;align-items:center;gap:6px}
.ic{width:20px;height:20px;border-radius:4px;background:linear-gradient(#3a3a46,#15151b);border:1px solid #000;box-shadow:inset 0 0 0 1px #ffffff22;
 display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-family:'Noto Color Emoji'}
.g{color:#40ff40}.y{color:#ffff3a}.r{color:#ff4040}.zone{color:#ffcc66}.gold{color:#ffd700}.silver{color:#c7c7cf}.copper{color:#eda55f}.blue{color:#4da6ff}.dim{color:#9a9a9a}
.btn{display:inline-block;background:linear-gradient(#a3281a,#5e130b);border:1px solid #2a0a05;box-shadow:inset 0 1px 0 #ff9a7a66;color:#ffd100;
 font:bold 14px 'DejaVu Sans';padding:5px 14px;border-radius:4px;text-shadow:0 1px 1px #000}
.btn.hl{box-shadow:inset 0 0 0 2px #ffe08a,0 0 8px #ffd10088}
.ck{display:flex;align-items:center;gap:8px;font-size:15px;margin:5px 0}
.box{vertical-align:middle;line-height:1;flex:none;width:20px;height:20px;border:2px solid #b7a26b;border-radius:3px;background:#111;display:inline-flex;align-items:center;justify-content:center;color:#ffd100;font:bold 15px sans-serif}
.h{color:#ffd100;font-weight:bold;font-size:15px;margin:10px 0 4px}
.qb{position:relative;width:26px;height:26px;border-radius:5px;background:linear-gradient(#5a4a2e,#2a1f10);border:1px solid #000;display:inline-flex;align-items:center;justify-content:center;font-family:'Noto Color Emoji';font-size:16px}
.badge{position:absolute;right:-6px;bottom:-6px;font:bold 12px sans-serif}
.input{display:inline-block;background:#000;border:1px solid #777;border-radius:3px;padding:2px 8px;min-width:34px;text-align:center;color:#fff;font-size:14px}
.tip{background:#0a0d1af2;border:2px solid #555c75;border-radius:6px;padding:12px 14px;font-size:14px;line-height:1.55;box-shadow:0 8px 30px #000c}
.row{display:flex;justify-content:space-between;gap:24px}
.k{color:#ffd100}
.q0{color:#9d9d9d}.q1{color:#fff}.q2{color:#1eff00}.q3{color:#0070dd}.q4{color:#a335ee}.q5{color:#ff8000}
"""

def page(name, stage, en, pt, extra=""):
    html = f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}{extra}</style></head><body>
<div class="stars"></div>
<div class="brand"><img src="data:image/png;base64,{logo}">Farol</div>
<div class="tag">Illustration · Ilustração</div>
<div class="stage">{stage}</div>
<div class="cap"><h1>{en}</h1><h2>{pt}</h2></div></body></html>"""
    open(os.path.join(OUT, name + ".html"), "w", encoding="utf-8").write(html)

def ic(e): return f'<span class="ic">{e}</span>'
def item(e, html): return f'<span class="it">{ic(e)}<span>{html}</span></span>'
BAR_ITEMS = [
    ("🔭", '<span class="g">60</span> fps'), ("⚡", '<span class="g">42</span> ms'),
    ("🗺️", '45.0, 61.0'), ("🌍", '<span class="zone">Harbor Guild</span>'),
    ("🔨", 'Dur <span class="g">87%</span>'), ("🎒", 'Bags <span class="y">8</span>/80'),
    ("💰", '123<span class="gold">g</span> 45<span class="silver">s</span> 67<span class="copper">c</span>'),
    ("📈", 'Gold/h <span class="g">+</span>12<span class="gold">g</span> 30<span class="silver">s</span>'),
    ("⏳", 'XP/h 18.4k · 42m'),
]
REP_ITEM = ("🏅", 'Harbor Guild <span class="g">Honored</span> 35% <span class="g">+600/h</span>')
RESET_ITEM = ("📜", 'Daily 5h 12m · Weekly 2d 4h')
PROF_ITEM = ("⛏️", 'Mining <span class="y">148/150</span> · Herbalism 92/150')
HERO_ITEMS = BAR_ITEMS[:2] + [BAR_ITEMS[3], BAR_ITEMS[6], BAR_ITEMS[8], REP_ITEM, ("📜", 'Daily 5h 12m')]
def hbar(items=BAR_ITEMS, extra_style=""):
    return f'<div class="bar" style="{extra_style}">' + "".join(item(e,h) for e,h in items) + \
        '<span class="qb">📝<span class="badge r">2</span></span><span class="qb">👜<span class="badge g">3</span></span></div>'

# 1. Hero
page("farol-01-overview-info-bar", f"""
<div style="display:flex;flex-direction:column;align-items:center;gap:30px">
 <div style="display:flex;align-items:center;gap:26px">
  <img src="data:image/png;base64,{logo}" style="width:150px;height:150px;border-radius:14px;box-shadow:0 0 0 3px #c9a24a,0 12px 40px #000">
  <div><div style="font:800 76px 'Inter';color:#ffd75a;text-shadow:0 4px 16px #000">Farol</div>
  <div style="font:500 24px 'Inter';color:#d9e4f2">Info bar · Alarms · Loot · Warnings</div>
  <div style="font:500 20px 'Inter';color:#9fb3cf;margin-top:4px">Free & open source · Unofficial · EN / PT-BR</div></div>
 </div>
 {hbar(HERO_ITEMS)}
</div>""", "Your info bar for WoW Forever", "Sua barra de informações para o WoW Forever")

# 2. Bar: aligned columns (flexible layout) + tooltip
gitems = [("🔭",'<span class="g">60</span> fps'),("⚡",'<span class="y">172</span> ms'),("🧠",'Mem <span class="y">235 MB</span>'),
          ("🗺️",'58.5, 54.1'),("🌍",'<span class="zone">Harbor Guild</span>'),("👟",'Speed 100%'),("🔨",'Dur <span class="g">77%</span>'),
          ("🎒",'Bags <span class="g">13</span>/38'),("🦴",'Junk 3<span class="gold">g</span> 26<span class="silver">s</span> (3)'),("🏹",'Ammo <span class="y">310</span>'),("💰",'0<span class="gold">g</span> 97<span class="silver">s</span> 23<span class="copper">c</span>'),
          ("🪙",'Session <span class="g">+</span>5<span class="silver">s</span> 34<span class="copper">c</span>'),
          ("📈",'Gold/h <span class="g">+</span>1<span class="gold">g</span> 33<span class="silver">s</span>'),
          ("📖",'XP 46% <span class="blue">+0%</span>'),("⏳",'XP/h 18.4k · 42m'),REP_ITEM,PROF_ITEM,("⏰",'18:49'),
          ("✅",'Completed 412'),RESET_ITEM,("📒",'Notes <span class="y">2</span>/5'),("📦",'Kept 4 · <span class="g">1</span>'),("⌛",'Played 1h 02m'),("👥",'Friends 4'),("🛡️",'Guild 12')]
grid = ('<div class="vbar" style="display:grid;grid-template-columns:repeat(3,auto);column-gap:14px;row-gap:6px;position:relative;padding-bottom:16px;font-size:12px;white-space:nowrap">'
        + "".join(item(e,h) for e,h in gitems)
        + '<span style="position:absolute;right:4px;bottom:0;color:#ccc;font-size:14px">◢</span></div>')
tip = """<div class="tip" style="width:330px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Gold</div>
<div class="row"><span class="k">Gold</span><span>123g 45s 67c</span></div>
<div class="row"><span class="k">Gold this session</span><span><span class="g">+</span>38g 12s</span></div>
<div class="row"><span class="k">Gold per hour</span><span><span class="g">+</span>17g 6s</span></div>
<div class="row"><span class="k">Gold on this account</span><span>1482g 10s</span></div>
<div class="row"><span>&nbsp; Aldric (60)</span><span>1020g 50s <span class="dim">Today</span></span></div>
<div class="row"><span>&nbsp; Mira (34)</span><span>338g 15s <span class="dim">Yesterday</span></span></div>
<div class="dim" style="margin-top:6px">Hold Shift to see all information.</div></div>"""
page("farol-02-bar-items-layout-tooltip", f"""
<div style="display:flex;flex-direction:column;gap:22px;align-items:flex-start">{hbar(BAR_ITEMS[:4])}{tip}</div>
<div style="display:flex;flex-direction:column;gap:8px;align-items:flex-start"><div class="dim">Drag the corner ◢ — one line, one column or columns</div>{grid}</div>""",
     "31 items, each with its own short tooltip (Shift: all)", "31 informações, cada uma com o seu tooltip curto (Shift: tudo)")

# 3. Options menu + order
names = ["FPS","Latency","Memory","Coordinates","Zone","Speed","Hearthstone","Durability","Bags","Junk in bags","Ammo & reagents","Kept items","Gold","Session gold","Gold per hour","Experience (XP)","XP per hour","Reputation","Professions","Goals (gold/level)","Farm (item goals)","Quests (quest log)","Completed quests","Clock","Resets (daily/weekly)","Tasks (daily/weekly)","Notes (notepad)","Session time","Dungeon / raid run","Friends online","Guild online"]
on = {0,1,3,4,6,7,8,9,10,12,14,16,17,18,19,20,21,24}
half = 12
col = lambda rng: "".join(f'<div class="ck"><span class="box">{"✓" if i in on else ""}</span>{names[i]}</div>' for i in rng)
GROUPS = [("Performance", [0, 1, 2]), ("Location", [3, 4, 5, 6]), ("Gear and bags", [7, 8, 9, 10, 11]), ("Gold", [12, 13, 14]),
          ("Progress", [15, 16, 17, 18, 19, 20, 21, 22]), ("Time and social", [23, 24, 25, 26, 27, 28, 29, 30])]
GEAR = {6, 10, 19, 20, 21, 22, 23, 25, 26, 28, 11}  # itens com ⚙ (configuração)
grp = lambda title, idx: (f'<div class="grp"><div class="gh">{title}</div>'
                          + "".join(f'<div class="ck"><span class="box">{"✓" if i in on else ""}</span>{names[i]}{"<span class=gear>⚙</span>" if i in GEAR else ""}</div>' for i in idx) + '</div>')
tabs = lambda active: '<div class="tabs">' + "".join(f'<span class="tab{" on" if t == active else ""}">{t}</span>' for t in ["Bar", "Warnings", "Tools", "General"]) + '</div>'
menu = f"""<div class="win menu3" style="width:640px;padding-top:12px;padding-bottom:14px;transform:scale(.86);transform-origin:center"><div class="x">×</div><div class="t">Farol</div>
{tabs("Bar")}
<div class="line"><span class="k">Editing:</span><span class="btn hl" style="padding:2px 10px;color:#fff">Bar 1</span><span class="btn" style="padding:2px 10px">Bar 2</span><span class="btn" style="padding:2px 10px">Bar 3 (off)</span><span class="ck" style="margin:0 0 0 18px"><span class="box">✓</span>Show</span><span class="ck" style="margin:0 0 0 12px"><span class="box"></span>Lock</span></div>
<div class="line" style="background:#0008;border-radius:4px;padding:3px 6px;margin-left:-6px;margin-right:-6px"><span class="k" style="white-space:nowrap;width:auto;min-width:0;margin-right:10px">Apply preset:</span><span class="btn" style="padding:2px 9px">Basic</span><span class="btn" style="padding:2px 9px">Leveling</span><span class="btn" style="padding:2px 9px">Gold &amp; farm</span><span class="btn" style="padding:2px 9px">Dungeons</span><span class="btn" style="padding:2px 9px">Undo</span></div>
<div class="g" style="font-size:12px;margin:4px 0">Preset Leveling applied to bar 1 (3 changes). Don't like it? Click Undo.</div>
<div class="cols">{"".join(grp(t, i) for t, i in GROUPS)}</div>
<div class="info"><b style="color:#ffd100">Hearthstone:</b> where your Hearthstone is bound and how long until you can use it again.</div>
<div class="line" style="margin-top:10px"><span class="btn">Appearance...</span><span class="btn hl">Order...</span></div></div>"""
TAB_CSS = """
.tabs{display:flex;gap:4px;border-bottom:2px solid #6e5b2e;margin:0 0 8px}
.tab{font:bold 14px 'DejaVu Sans';color:#c9b88a;padding:5px 16px;border:1px solid #6e5b2e;border-bottom:none;border-radius:6px 6px 0 0;background:#1a1a22}
.tab.on{color:#ffd100;background:#3a2a10;box-shadow:inset 0 2px 0 #ffd100}
.menu3 .line{display:flex;gap:8px;align-items:center;margin:6px 0}.menu3 .line .k{width:56px;font-size:14px}
.cols{display:grid;grid-template-columns:repeat(3,1fr);gap:4px 16px}
.grp .ck{margin:2px 0;font-size:13px}.gh{color:#ffd100;font-weight:bold;font-size:13px;margin:6px 0 2px;border-bottom:1px solid #6e5b2e55}
.menu3 .box{width:16px;height:16px;font-size:12px}
.gear{display:inline-block;margin-left:4px;font-size:10px;color:#ffd75a;border:1px solid #ffd75a55;border-radius:3px;padding:0 2px;line-height:12px}
.info{margin-top:8px;background:#ffd75a12;border:1px solid #ffd75a40;border-radius:4px;padding:5px 9px;font-size:12px;color:#e8e0c8}
"""
hover_tip = ""  # a explicação de cada item aparece ao passar o mouse (não cabe junto com a janela de ordem)
order_names = [("🌍","Zone"),("🔭","FPS"),("⚡","Latency"),("💰","Gold"),("🏅","Reputation"),("📜","Resets (daily/weekly)"),("🔨","Durability"),("🎒","Bags"),("⏰","Clock (hidden)")]
order = '<div class="win" style="width:330px"><div class="x">×</div><div class="t">Bar order</div>' + "".join(
    f'<div class="ck" style="justify-content:space-between"><span><span class="dim" style="display:inline-block;width:22px;text-align:right">{i+1}.</span> {ic(e)} <span class="{"dim" if "hidden" in n else ""}">{n}</span></span><span>▲ ▼</span></div>'
    for i,(e,n) in enumerate(order_names)) + '<div style="text-align:right;margin-top:10px"><span class="btn">Restore default order</span></div></div>'
page("farol-03-options-menu-bar-order", menu.replace('<div class="x">×</div><div class="t">Farol</div>', '<div class="x">×</div><div class="t">Farol</div>' + hover_tip, 1) + order, "Menu: presets with Undo, items in groups, a gear each", "Menu: pacotes prontos com Desfazer, itens em grupos e engrenagem", TAB_CSS)

# 4. Alarms
alarms = """<div class="win" style="width:470px"><div class="x">×</div><div class="t">Alarms</div>
<div class="dim" style="font-size:13px">Up to 10 alarms. Tick the box to enable.</div>
<div class="ck" style="justify-content:space-between"><span><span class="box">✓</span> 1. 07:30 (Local) Wake up</span><span class="btn" style="padding:2px 8px">X</span></div>
<div class="ck" style="justify-content:space-between"><span><span class="box">✓</span> 2. 21:00 (Server) Raid</span><span class="btn" style="padding:2px 8px">X</span></div>
<div class="ck" style="justify-content:space-between"><span><span class="box"></span> 3. 18:15 (Local) Auction house</span><span class="btn" style="padding:2px 8px">X</span></div>
<div class="h">New alarm</div>
<div style="display:flex;gap:8px;align-items:center"><span class="input">22</span>:<span class="input">45</span><span class="btn">Server</span><span class="input" style="min-width:150px;text-align:left;color:#aaa">name (optional)</span></div>
<div style="display:flex;gap:8px;margin-top:12px"><span class="btn">Add</span><span class="btn">Test sound</span></div>
<div style="margin-top:12px;font-size:14px"><span class="k">Snooze time:</span> <span class="input">10</span> min</div></div>"""
popup = """<div style="display:flex;flex-direction:column;gap:18px">
<div class="win" style="width:400px;text-align:center"><div class="t">⏰ Alarm!</div><div style="font-size:16px">21:00 (Server) Raid</div>
<div style="display:flex;justify-content:space-between;margin-top:16px"><span class="btn">Snooze (10 min)</span><span class="btn">Stop</span></div></div>
<div class="tip" style="width:400px;font-size:13px"><span style="color:#33ccff">Farol:</span> ⏰ <span style="color:#ff6600">Alarm!</span> 21:00 (Server) Raid — /farol snooze or /farol stop</div></div>"""
page("farol-04-clock-alarms-snooze", alarms + popup, "Clock alarms with snooze — local or server time", "Alarmes do relógio com soneca — hora local ou do servidor")

# 5. Loot
loot_items = [("q5","⚔️","[Stormcaller, Blade of the Tides]","","Today","21:42"),("q4","🛡️","[Helm of the Lighthouse]","","Today","21:38"),("q3","💍","[Band of the Tides]","","Today","09:30"),
              ("q2","🌿","[Meadow Bloom]","x6","Yesterday","22:27"),("q1","🧵","[Linen Cloth]","x12","Yesterday","21:20"),("q2","🗡️","[Harbor Cutlass]","","Nov 7","21:12")]
rows = "".join(f'<div class="row" style="padding:3px 0;font-size:15px"><span style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{ic(e)} <span class="{q}">{n}</span></span><span style="white-space:nowrap"><span class="dim">{c}</span>&nbsp;&nbsp;<span style="color:#8c8c8c">{d}</span> <span style="color:#c8c8c8">{t}</span>&nbsp;&nbsp;<span class="btn" style="padding:0 7px;font-size:11px;{'opacity:.6' if n == '[Meadow Bloom]' else ''}">{'✓' if n == '[Meadow Bloom]' else 'Keep'}</span> <span class="btn" style="padding:0 7px;font-size:11px">+ Goal</span></span></div>' for q,e,n,c,d,t in loot_items)
dd = """<div class="tip" style="position:absolute;left:236px;top:92px;width:200px;font-size:14px;line-height:1.7;z-index:2;background:#0a0d1a">
<div><span class="k">✓</span> <span class="q0">Poor</span></div><div>&nbsp;&nbsp;&nbsp;<span class="q1">Common</span></div><div><span class="k">✓</span> <span class="q2">Uncommon</span></div>
<div><span class="k">✓</span> <span class="q3">Rare</span></div><div><span class="k">✓</span> <span class="q4">Epic</span></div><div><span class="k">✓</span> <span class="q5">Legendary+</span></div>
<div class="dim">Check all</div><div class="dim">Uncheck all</div></div>"""
loot = f"""<div class="win" style="width:720px;padding-bottom:26px"><div class="x">×</div><div class="t">Recent loot</div>
<div style="display:flex;gap:10px;align-items:center;margin-bottom:10px"><span class="k">Show:</span><span class="btn">10 ▾</span><span class="k" style="margin-left:14px">Quality:</span><span class="btn">5 selected ▾</span></div>
{dd}{rows}<div class="dim" style="font-size:12px;margin-top:10px">Hover: details · Shift-click: link · Wheel: scroll · Keep: save it for later · + Goal: track the item (farm goal)</div>
<div style="position:absolute;right:8px;bottom:6px;color:#aaa">◢</div></div>"""
page("farol-05-recent-loot-window", loot, "Recent loot: quality filter, Keep and + Goal", "Últimos saques: quando você pegou, filtro de qualidade, Guardar e + Meta")

# 6. Warnings: grouped window with remind-time dropdowns + history
def wrow(text):
    return (f'<div style="display:flex;align-items:flex-start;gap:8px;margin:7px 0"><span style="flex:1;font-size:14px;line-height:1.35">{text}</span>'
            '<span class="btn" style="padding:3px 10px;font-size:13px">Silence</span>'
            '<span class="btn" style="padding:3px 10px;font-size:13px">Remind in 10 min</span>'
            '<span class="btn" style="padding:3px 7px;font-size:13px">▾</span></div>')
dd6 = """<div class="tip" style="position:absolute;right:20px;top:104px;width:96px;font-size:13px;line-height:1.7;z-index:2;background:#0a0d1a">
<div>&nbsp;&nbsp;&nbsp;2 min</div><div>&nbsp;&nbsp;&nbsp;5 min</div><div><span class="k">✓</span> 10 min</div><div>&nbsp;&nbsp;&nbsp;15 min</div><div>&nbsp;&nbsp;&nbsp;30 min</div></div>"""
warnpop = f"""<div class="win" style="width:740px"><div class="t">Warnings (3)</div>{dd6}
{wrow("Low durability: 18% — time to repair!")}
{wrow("Cooking 150/150 at the training limit — find a trainer to keep leveling.")}
{wrow("Time to drink some water!")}
<div style="display:flex;justify-content:space-between;margin-top:14px"><span class="btn">Silence all</span>
<span><span class="btn">Remind all in 10 min</span> <span class="btn" style="padding:5px 8px">▾</span></span></div>
<div style="position:absolute;right:6px;bottom:2px;color:#ddd;font-size:15px">◢</div>
<div class="tip" style="position:absolute;left:-292px;top:70px;width:270px;font-size:12.5px;line-height:1.45;z-index:3"><div class="k">Farol warning</div><div>Cooking 150/150 at the training limit — find a trainer to keep leveling.</div><div class="dim">Turn off or adjust: Menu &gt; Warnings.</div></div></div>"""
hist = """<div class="win" style="width:520px"><div class="x">×</div><div class="t">Recent warnings</div>
<div style="font-size:14px;line-height:1.9"><div><span class="dim">11/11 21:40</span>&nbsp; Time to drink some water!</div>
<div><span class="dim">11/11 21:40</span>&nbsp; You've been playing for 2h 00m — time for a break?</div>
<div><span class="dim">11/11 21:12</span>&nbsp; Lower-rank spell on your bars: Fireball (Rank 3).</div>
<div><span class="dim">11/11 20:31</span>&nbsp; Low durability: 18% — time to repair!</div></div>
<div style="text-align:right;margin-top:10px"><span class="btn">Clear</span></div></div>"""
page("farol-06-warnings-break-water-reminders", f'<div style="display:flex;flex-direction:column;gap:18px;align-items:center;transform:scale(.92)">{warnpop}{hist}</div>',
     "Warnings: nothing cut, remind in 2–30 min", "Avisos inteiros (quebra de linha e tooltip), lembretes de pausa e água, lembrar em 2 a 30 min")

# 7. Appearance
def stepper(label, value): return f'<div style="display:flex;align-items:center;gap:10px;margin:7px 0"><span class="k" style="width:110px">{label}</span><span class="btn" style="padding:2px 9px">-</span><span style="width:52px;text-align:center">{value}</span><span class="btn" style="padding:2px 9px">+</span></div>'
app = f"""<div class="win" style="width:470px"><div class="x">×</div><div class="t">Appearance</div>
{stepper("Scale:","120%")}{stepper("Background:","40%")}{stepper("Text:","13")}{stepper("Icons:","18")}
<div style="display:flex;align-items:center;gap:10px;margin:8px 0"><span class="k" style="width:110px">Layout:</span><span class="btn hl">One line</span><span class="btn">One column</span></div>
<div class="dim" style="font-size:12px;margin-bottom:6px">or drag the grip at the bottom-right corner of the bar</div>
<div class="ck"><span class="box">✓</span>Show icons on the bar</div>
<div class="ck"><span class="box">✓</span>Show border</div><div class="ck"><span class="box">✓</span>Hide in combat</div>
<div class="ck"><span class="box"></span>Hide in dungeons, raids, arenas and battlegrounds</div>
<div class="ck"><span class="box">✓</span>Show the warning history button 📝</div>
<div class="ck"><span class="box">✓</span>Show the loot button 👜</div>
<div class="ck"><span class="box">✓</span>Show the notes button 📓</div>
<div class="ck"><span class="box"></span>Full tooltip (all information on every item)</div>
<div style="text-align:right;margin-top:8px"><span class="btn">Restore defaults</span></div></div>"""
small = hbar(BAR_ITEMS[:4], "font-size:12px;transform:scale(.9)")
big = hbar(BAR_ITEMS[:4], "font-size:19px;background:#0004;border-color:#0000")
page("farol-07-appearance-settings", f'{app}<div style="display:flex;flex-direction:column;gap:30px;align-items:flex-start"><div class="dim">Small · compact</div>{small}<div class="dim">Large · transparent</div>{big}</div>',
     "Make it yours: shape, size, background, hide in combat", "Do seu jeito: formato livre, tamanho do texto e ícones, fundo, esconder em combate")
# 8. Progress: XP, reputation, resets
pbar = hbar([("📖",'XP 46% <span class="blue">+12%</span>'),("⏳",'XP/h 18.4k · 42m'),REP_ITEM,("⛏️", 'Mining <span class="r">150/150</span>'),
             ("🎯",'Goal 500g <span class="y">44%</span> ~27m · Lv 40 <span class="y">36%</span> ~6h 10m')], "font-size:13px")
ptip = """<div class="tip" style="width:470px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol</div>
<div class="row"><span class="k">Experience</span><span>11,040 / 24,000 (46%)</span></div>
<div class="row"><span class="k">XP per hour</span><span>18.4k</span></div>
<div class="row"><span class="k">Next level in</span><span>42m</span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Reputation</span><span>Harbor Guild</span></div>
<div class="row"><span class="k">Standing</span><span class="g">Honored</span></div>
<div class="row"><span class="k">Progress</span><span>4.2k / 12.0k (35%)</span></div>
<div class="row"><span class="k">Reputation per hour</span><span>+600</span></div>
<div class="row"><span class="k">Next standing in</span><span>13h 00m</span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Mining</span><span><span class="r">150/150</span> (+23 this session)</span></div>
<div style="color:#ff6666;font-size:13px">&nbsp;&nbsp;&nbsp;at the training limit — find a trainer</div>
<div class="row"><span class="k">Cooking</span><span>60/75</span></div>
<div style="height:6px"></div>
<div class="k">Goals</div>
<div class="row"><span>&nbsp; Gold 500g</span><span>223g of 500g (44%)</span></div>
<div class="row dim"><span>&nbsp;&nbsp;&nbsp; estimate: ~27m (around 22:41) · pace 600g per hour</span><span></span></div>
<div class="k">Farm (item goals)</div>
<div class="row"><span>&nbsp; Silk Cloth</span><span class="y">27/40</span></div>
<div class="row dim"><span>&nbsp;&nbsp;&nbsp; +18 this session (~24/h) · ~32m left</span><span></span></div>
<div class="row"><span>&nbsp; Iron Ore</span><span class="g">20/20</span></div>
<div class="k">Quests — 17 / 20</div>
<div class="row"><span>&nbsp; Value of the ready ones</span><span>+7.4k XP · +18s</span></div>
<div class="row"><span>&nbsp; <span class="g">Turning them all in: level 35 → 36 (6.5k XP left over)</span></span><span></span></div>
<div class="row"><span>&nbsp; <span class="g">Ready to turn in (3)</span></span><span></span></div>
<div class="row"><span>&nbsp; <span style="color:#ff8040">[35]</span> The Echo Cavern</span><span class="dim">3/8</span></div>
<div style="height:6px"></div>
<div class="k">Rested XP of your characters (estimate)</div>
<div class="row"><span>&nbsp; Mira (34)</span><span>150% <span class="g">full</span> <span class="dim">inn/city</span></span></div>
<div class="row"><span>&nbsp; Tomas (22)</span><span>84% full in ~2d 1h <span class="dim">inn/city</span></span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Daily reset in</span><span>5h 12m (02:17 local · 05:17 server)</span></div>
<div class="row"><span class="k">Weekly reset in</span><span>2d 4h (Wed 01:05 local · 04:05 server)</span></div>
<div class="k">Saved instances</div>
<div class="row"><span>&nbsp; Cinder Caverns</span><span>7/10 bosses &nbsp;reset in 2d 4h</span></div></div>"""
page("farol-08-progress-xp-reputation-professions", f'<div style="display:flex;flex-direction:column;gap:12px;align-items:center;transform:scale(.72);margin-top:10px">{pbar}{ptip}</div>',
     "Progress: XP, reputation, professions, goals, farm, quests", "Seu progresso: XP, reputação, profissões, metas, farm e missões")
# 9. Session summary (chat only)
def chatline(text): return f'<div><span style="color:#33ccff">Farol:</span> {text}</div>'
G = lambda g, sv: f'<span class="g">+</span>{g}<span class="gold">g</span> {sv}<span class="silver">s</span>'
summary_lines = [
    "session summary (2h 14m):",
    f"&nbsp;&nbsp;Gold: {G(38, 12)} ({G(17, 6)}/h) · XP: +84.2k (1 level, 37.6k/h)",
    "XP by source: quests 64% · monsters 33% · other 3% <span class=\"dim\">(optional)</span>",
    f"Gold by source: quests {G(21, 40)} · loot {G(9, 15)} · sales {G(12, 80)} · purchases and repairs <span class=\"r\">-</span>5<span class=\"gold\">g</span> 23<span class=\"silver\">s</span>",
    'Reputation: +1.3k Harbor Guild (<span class="g">Honored</span> → <span style="color:#00b3ff">Revered</span>)',
    "Loot: 46 (3 rares, 1 epic) · Warnings: 2",
]
for i in range(2, len(summary_lines)): summary_lines[i] = "&nbsp;&nbsp;" + summary_lines[i]
def chatbox(title, lines, width=760):
    return (f'<div style="width:{width}px"><div class="dim" style="margin:0 0 6px 4px;font-size:14px">{title}</div>'
            '<div class="tip" style="font-size:15px;line-height:1.7;background:#000a;border-color:#3a3f55">'
            + "".join(chatline(l) for l in lines) + '</div></div>')
last_lines = ["last session (Yesterday 23:41, 2h 14m):"] + summary_lines[1:]
page("farol-09-session-summary-chat", f'''<div style="display:flex;flex-direction:column;gap:26px;align-items:center">
{chatbox("/farol summary — any time, only in your own chat", summary_lines, 940)}
{chatbox("Next login — the last session (not after /reload)", last_lines, 940)}</div>''',
     "Session summary: gold & XP by source, rep, loot", "Resumo da sessão: ouro e XP por origem, reputação e saques — só no seu chat")

# 10. Tasks: daily and weekly checklist that resets on its own
TASK_BAR = hbar([("🔭",'<span class="g">60</span> fps'),("🌍",'<span class="zone">Lighthouse Bay</span>'),("📜",'Tasks <span class="y">3/5</span>'),
                 ("📜",'Daily 5h 12m · Weekly 2d 4h')], "font-size:14px")
TASK_BAR = TASK_BAR.replace('<span class="ic">📜</span><span>Tasks', '<span class="ic">📋</span><span>Tasks', 1)
ttasks = """<div class="tip" style="width:420px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Tasks</div>
<div class="row"><span class="k">Tasks</span><span>3 / 5</span></div>
<div class="row"><span>&nbsp; Fishing daily <span class="dim">(daily)</span></span><span class="g">done</span></div>
<div class="row"><span>&nbsp; Cooking daily <span class="dim">(daily)</span></span><span class="y">to do</span></div>
<div class="row"><span>&nbsp; Sell on the auction house <span class="dim">(daily)</span></span><span class="g">done</span></div>
<div class="row"><span>&nbsp; Ember Depths <span class="dim">(weekly)</span></span><span class="y">to do</span></div>
<div class="row"><span>&nbsp; Guild bank deposit <span class="dim">(weekly)</span></span><span class="g">done</span></div>
<div class="row dim"><span>&nbsp; reset in</span><span>daily 5h 12m · weekly 2d 4h</span></div></div>"""
def trow(name, kind, done):
    return (f'<div class="ck" style="justify-content:space-between"><span><span class="box">{"✓" if done else ""}</span>&nbsp;'
            f'<span class="{"g" if done else ""}">{name}</span></span><span><span class="dim" style="font-size:12px">{kind}</span>&nbsp;&nbsp;'
            '<span class="btn" style="padding:1px 7px">X</span></span></div>')
twin = ('<div class="win" style="width:470px"><div class="x">×</div><div class="t">Tasks</div>'
        '<div class="dim" style="font-size:12px;margin-bottom:6px">Tick what you have done. Daily tasks reset at the daily reset; weekly, at the weekly one.</div>'
        + '<div style="display:flex;gap:8px;align-items:center;margin-bottom:8px"><span class="input" style="min-width:200px;text-align:left;color:#888;font-style:italic">New task...</span>'
          '<span class="btn">Type: Daily</span><span class="btn">Add</span></div>'
        + trow("Fishing daily", "daily", True) + trow("Cooking daily", "daily", False) + trow("Sell on the auction house", "daily", True)
        + trow("Ember Depths", "weekly", False) + trow("Guild bank deposit", "weekly", True)
        + '<div class="ck" style="margin-top:10px"><span class="box">✓</span>Warn 1 h before the daily reset if a daily task is left</div>'
        + '<div class="dim" style="font-size:12px;margin-top:4px">Daily reset in 5h 12m · weekly in 2d 4h</div>'
        + '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px;font-size:12.5px;padding:5px 8px;background:#ffd75a14;border:1px solid #ffd75a44;border-radius:4px">'
          '<span>Task removed: Old errand</span><span class="btn" style="padding:1px 10px">Undo</span></div></div>')
twarn = ('<div class="tip" style="width:420px;font-size:13px"><span style="color:#33ccff">Farol:</span> <span style="color:#ff9900">'
         '1 daily task left and the daily reset is in 58m.</span> <span class="dim">(Silence / Remind in 10 min)</span></div>')
page("farol-10-daily-weekly-tasks", f'<div style="display:flex;flex-direction:column;gap:16px;align-items:flex-start">{TASK_BAR}{ttasks}{twarn}</div>{twin}',
     "Daily & weekly tasks that reset on their own", "Tarefas diárias e semanais que zeram sozinhas no reset")

# 11. Dungeon and raid runs
RUN_BAR = hbar([("🔭",'<span class="g">60</span> fps'),("🔨",'Dur <span class="y">54%</span>'),
                 ("🗝️",'<span class="zone">Ember Depths</span> 18m · <span class="blue">+4.2k XP</span> · <span class="g">+</span>12<span class="gold">g</span>'),
                 ("⏳",'XP/h 14.0k · 1h 05m')], "font-size:14px")
run_summary = ('<div class="tip" style="width:560px;font-size:14px;line-height:1.7;background:#000a;border-color:#3a3f55">'
    '<div><span style="color:#33ccff">Farol:</span> left <span class="zone">Ember Depths</span> (dungeon): <b>32m</b></div>'
    '<div><span style="color:#33ccff">Farol:</span> &nbsp;XP: <span class="blue">+6.8k</span> · Gold: <span class="g">+</span>18<span class="gold">g</span> 40<span class="silver">s</span> · Loot: 14 (<span class="q3">2 rares</span>, <span class="q4">1 epic</span>) · Deaths: 1</div></div>')
RUNS = [("Today 21:42","Ember Depths","32m","+6.8k","+18g 40s","14",'<span class="q4">1 epic</span>',""),
        ("Today 19:05","Sunken Vault","48m","+9.9k","+25g 10s","21",'<span class="q3">2 rares</span>',"2"),
        ("Yesterday","Ember Depths","35m","+7.1k","+16g 05s","12",'<span class="q3">1 rare</span>',""),
        ("Yesterday","Harbor Crypt","27m","+5.2k","+9g 80s","10","",""),
        ("Nov 13","Lighthouse Caverns","1h 12m","+14.6k","+41g 20s","33",'<span class="q3">3 rares</span>',"1")]
rrows = "".join(f'<div class="rrow"><span class="dim">{d}</span><span class="zone">{n}</span><span>{t}</span><span class="blue">{x}</span><span>{g}</span><span>{l} {q}</span><span class="r">{m}</span></div>' for d, n, t, x, g, l, q, m in RUNS)
run_win = (f'<div class="win" style="width:680px"><div class="x">×</div><div class="t">Dungeons and raids</div>'
    '<div class="dim" style="font-size:12px;margin-bottom:6px">This character\'s last 10 dungeons and raids. Your own numbers only; nothing is sent.</div>'
    '<div class="rrow head"><span>When</span><span>Instance</span><span>Time</span><span>XP</span><span>Gold</span><span>Loot</span><span>Deaths</span></div>'
    + rrows + '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px"><span class="ck" style="margin:0"><span class="box">✓</span>Show the summary in chat when leaving</span><span class="btn">Clear history</span></div></div>')
RUN_CSS = """.rrow{display:grid;grid-template-columns:82px 140px 54px 56px 76px 128px 44px;gap:5px;font-size:13px;padding:2px 0;border-bottom:1px solid #ffffff10}
.rrow.head{color:#ffd100;font-weight:bold;font-size:12px}"""
page("farol-11-dungeon-raid-runs", f'<div style="display:flex;flex-direction:column;gap:14px;align-items:center;transform:scale(.92)">{RUN_BAR}{run_summary}{run_win}</div>',
     "Dungeon & raid log: time, XP, gold, loot, deaths", "Registro de masmorras e raides: tempo, XP, ouro, saques e mortes", RUN_CSS)
# 12. Completed quests of each character
QD = [("32","Delivery to Lighthouse Bay","#4127","North Vale","Today 21:40"),("31","Wolves of the Gray Hill","#4093","Gray Hill","Today 20:58"),
      ("31","The Torn Map","#4088","Old Harbor","Today 20:12"),("30","Herbs for the Healer","#3961","North Vale","Yesterday 22:31"),
      ("30","The Tall Tower (group)","#3954","Dry Moor","Yesterday 21:05"),("29","Letters for the Keeper","#3810","Old Harbor","Nov 20"),
      ("29","Ore from the Deep Mine","#3802","Deep Mine","Nov 20"),("28","Road Patrol","#3755","Dry Moor","Nov 19")]
qrows = "".join(f'<div class="qrow"><span class="y">[{l}]</span><span>{n}</span><span class="dim">{i}</span><span class="dim">{z}</span><span class="dim" style="text-align:right">{d}</span></div>' for l, n, i, z, d in QD)
qwin = ('<div class="win" style="width:640px"><div class="x">×</div><div class="t">Completed quests</div>'
    '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px"><span>Character: <span class="btn" style="padding:2px 10px;color:#fff">Aldric — this one ▾</span></span>'
    '<span style="background:#000;border:1px solid #777;padding:3px 8px;width:200px;color:#888;font-size:13px">search by name or ID...</span></div>'
    '<div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:4px"><span>Recorded: <b>8</b></span><span>Known names: <b>37</b> of 412</span><span>Total in game: <b>412</b> <span class="dim">(includes internal markers)</span></span></div>'
    + qrows +
    '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px"><span class="ck" style="margin:0"><span class="box">✓</span>Record turned-in quests (on this computer only; nothing is sent)</span><span class="dim" style="font-size:12px">1–8 of 8</span></div>'
    '<div class="ck" style="margin-top:4px"><span class="box"></span>Show quests from before recording (ID only)</div>'
    '<div style="display:flex;align-items:center;gap:8px;margin-top:6px;font-size:12px"><span class="k" style="color:#ffd100;width:auto">Wowhead (Ctrl+C):</span>'
    '<span style="background:#000;border:1px solid #c9a24a;padding:2px 8px;color:#fff">https://www.wowhead.com/forever/quest=4127</span></div></div>')
QD_BAR = hbar([("📜",'Quests <span class="g">12/20</span>'),("✅",'Completed 412')], "font-size:14px")
qtip = ('<div class="tip" style="width:330px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Completed quests</div>'
    '<div class="row"><span class="k">Aldric (this one)</span><span>412 · today +3</span></div>'
    '<div class="row"><span class="k">Mira (34)</span><span>468</span></div>'
    '<div class="row"><span class="k">Tor (12)</span><span>57</span></div>'
    '<div class="dim" style="margin-top:6px">Latest: Delivery to Lighthouse Bay · Wolves of the Gray Hill</div></div>')
QD_CSS = """.qrow{display:grid;grid-template-columns:40px 230px 56px 120px 106px;gap:6px;font-size:13px;padding:3px 0;border-bottom:1px solid #ffffff10}"""
page("farol-12-completed-quests", f'<div style="display:flex;flex-direction:column;gap:16px;align-items:flex-start">{QD_BAR}{qtip}</div>{qwin}',
     "Completed quests per character, with Wowhead links", "Missões concluídas de cada personagem, com busca e link do Wowhead", QD_CSS)

# 13. Up to 3 bars + per-character profiles
B1 = hbar([("🔭",'<span class="g">60</span> fps'),("⚡",'<span class="g">42</span> ms'),("🌍",'<span class="zone">Harbor Guild</span>'),("💰",'123<span class="gold">g</span> 45<span class="silver">s</span>')], "font-size:14px")
B2 = ('<div class="bar" style="font-size:14px">' + "".join(item(e, h) for e, h in [("📖",'XP 46%'),("⏳",'XP/h 18.4k · 42m'),("📜",'Quests <span class="g">12/20</span>')]) + '</div>')
B3 = ('<div class="vbar" style="font-size:14px">' + "".join(item(e, h) for e, h in [("⏰",'21:05'),("📜",'Daily 5h 12m'),("📋",'Tasks <span class="y">3/5</span>'),("🎒",'Bags <span class="y">8</span>/80')]) + '</div>')
bars = (f'<div style="display:flex;flex-direction:column;gap:14px;align-items:flex-start"><div class="dim">Bar 1 · top</div>{B1}'
        f'<div class="dim">Bar 2 · above the action bars</div>{B2}<div style="display:flex;gap:16px;align-items:flex-start"><div><div class="dim">Bar 3 · one column</div>{B3}</div></div></div>')
gen = f"""<div class="win menu3" style="width:520px"><div class="x">×</div><div class="t">Farol</div>{tabs("General")}
<div class="line"><span class="k" style="width:auto">Editing:</span><span class="btn" style="padding:2px 10px">Bar 1</span><span class="btn" style="padding:2px 10px">Bar 2</span><span class="btn hl" style="padding:2px 10px;color:#fff">Bar 3</span></div>
<div class="h">Profiles (advanced)</div>
<div class="line"><span>Profile:</span><span class="btn" style="padding:2px 10px;color:#fff">This character only ▾</span><span class="btn" style="padding:2px 10px">Copy from... ▾</span></div>
<div class="tip" style="margin:6px 0 0 150px;width:230px;font-size:13px;line-height:1.7"><div class="k">Copy from...</div><div>Account bars</div><div>Mira (34)</div><div>Tor (12)</div></div>
<div class="g" style="font-size:12px;margin-top:8px">Bars copied from Mira. Changed your mind? /farol profile undo</div></div>"""
page("farol-13-multiple-bars-profiles", bars + gen, "Up to 3 bars and a profile per character", "Até 3 barras e perfil por personagem — copiar de outro e desfazer", TAB_CSS)

# 14. Your characters: gold, rested XP, Hearthstone, saved instances
HB = hbar([("💰",'123<span class="gold">g</span> 45<span class="silver">s</span> <span class="dim">(Total 1482g)</span>'),("🏠",'Riverside Inn · <span class="g">ready</span>'),("📜",'Daily 5h 12m')], "font-size:14px")
ctip = """<div class="tip" style="width:560px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol</div>
<div class="row"><span class="k">Gold on this account (this realm)</span><span>1482g 10s</span></div>
<div class="row"><span>&nbsp; Aldric (60)</span><span>1020g 50s <span class="dim">Today · Riverside Inn</span></span></div>
<div class="row"><span>&nbsp; Mira (34)</span><span>338g 15s <span class="dim">Yesterday · Harbor Town</span></span></div>
<div class="row"><span>&nbsp; Lia (22) <span class="dim">— this one</span></span><span>123g 45s <span class="dim">Riverside Inn</span></span></div>
<div style="height:6px"></div>
<div class="k">Rested XP of your characters (estimate)</div>
<div class="row"><span>&nbsp; Mira (34)</span><span>150% <span class="g">full</span> <span class="dim">inn/city</span></span></div>
<div class="row"><span>&nbsp; Tor (12)</span><span>84% full in ~2d 1h <span class="dim">outside</span></span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Hearthstone</span><span>Riverside Inn · ready</span></div>
<div style="height:6px"></div>
<div class="k">Saved instances</div>
<div class="row"><span>&nbsp; Cinder Caverns</span><span>7/10 bosses · reset in 2d 4h</span></div>
<div class="row"><span>&nbsp; Aldric: Sunken Vault</span><span>reset in 4d 9h</span></div></div>"""
page("farol-14-your-characters-hearthstone", f'<div style="display:flex;flex-direction:column;gap:16px;align-items:center">{HB}{ctip}</div>',
     "Your characters: gold, rest, Hearthstone, lockouts", "Seus personagens: ouro, descanso, Pedra de Regresso e instâncias")

# 15. Where the XP and gold come from (optional)
def srow(a, b): return f'<div class="row"><span>&nbsp;&nbsp; {a}</span><span>{b}</span></div>'
sxp = ('<div class="tip" style="width:440px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Experience</div>'
       '<div class="row"><span class="k">XP per hour</span><span>6.6k · next level in 1h 12m</span></div>'
       '<div class="row"><span class="k">Where the XP came from (session)</span><span>8.1k</span></div>'
       '<div style="display:flex;height:8px;border-radius:4px;overflow:hidden;margin:4px 0"><i style="width:72%;background:#4da6ff"></i><i style="width:25%;background:#c07ad8"></i><i style="width:3%;background:#999"></i></div>'
       + srow("Quests (9 turned in)", "5.9k · 72%") + srow("Monsters", "2.0k · 25%") + srow("Other (places, professions)", "240 · 3%") + '</div>')
mg = lambda sign, g, sv: f'<span class="{"g" if sign == "+" else "r"}">{sign}</span>{g}{sv}'
sgold = ('<div class="tip" style="width:440px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Gold</div>'
         '<div class="row"><span class="k">Gold this session</span><span><span class="g">+</span>1<span class="gold">g</span> 12<span class="silver">s</span></span></div>'
         '<div class="k">Where the gold came from (session)</div>'
         + srow("Quest rewards", '<span class="g">+</span>84<span class="silver">s</span>') + srow("Monster loot", '<span class="g">+</span>31<span class="silver">s</span>')
         + srow("Merchant: sales", '<span class="g">+</span>42<span class="silver">s</span>') + srow("Merchant: purchases and repairs", '<span class="r">-</span>45<span class="silver">s</span>')
         + srow("Other (mail, auction, trade)", '0<span class="copper">c</span>') + '</div>')
snote = ('<div class="tip" style="width:440px;font-size:13px;background:#0b1424e8;border-color:#c9a24a88">Off by default — turn it on in Menu &gt; General or <b>/farol source on</b>. '
         'Only events the game already sends; nothing is sent. The sum always matches the session.</div>')
page("farol-15-xp-gold-by-source", f'{sxp}<div style="display:flex;flex-direction:column;gap:16px">{sgold}{snote}</div>',
     "Where your XP and gold come from (optional)", "De onde vem o seu XP e o seu ouro (opcional)")

# 16. Messages in a chat tab of their own + diagnostics
CHAT_CSS = """.ctabs{display:flex;gap:3px}.ctabs span{background:#1a1a22d0;border:1px solid #ffffff33;border-bottom:none;border-radius:6px 6px 0 0;padding:3px 12px;font-size:13px;color:#ccc}
.ctabs span.on{background:#3a3a46;color:#fff}.cwin{background:#000a;border:1px solid #ffffff22;border-radius:0 6px 6px 6px;padding:10px 14px;font-size:13.5px;line-height:1.6}"""
diag = ["<span class=\"y\">Diagnostics</span> <span class=\"dim\">(read-only: nothing is sent or requested from the server)</span>",
        'Character: Lia Rivers · game realm: "" (empty) → saved as this realm',
        'Name from the game: "Lia" + "Rivers" · name used: "Lia Rivers"',
        'Gold now: 123<span class="gold">g</span> 45<span class="silver">s</span> 67<span class="copper">c</span>',
        'Last logout: the game reported 0 gold → the previous value was kept <span class="g">(protection active)</span>',
        "Events this session: quest turn-in 3 · reward window 3 · quest accepted 4 · gold changed 11",
        'Quest turn-in: the game reports it normally <span class="g">(ok)</span>',
        "Reward of the last turn-in: XP 3131 · gold 0g 18s 0c"]
cwin = ('<div style="width:700px"><div class="ctabs"><span>General</span><span>Combat Log</span><span class="on">Farol</span></div>'
        '<div class="cwin">' + "".join(chatline(l) for l in diag) + '</div></div>')
cmenu = f"""<div class="win menu3" style="width:440px"><div class="x">×</div><div class="t">Farol</div>{tabs("General")}
<div class="h">Chat and messages</div>
<div class="line"><span>Farol messages in:</span><span class="btn" style="padding:2px 10px;color:#fff">Farol ▾</span></div>
<div class="tip" style="margin:4px 0 0 140px;width:250px;font-size:13px;line-height:1.7"><div>Main chat (default)</div><div>Combat Log</div><div><span class="k">✓</span> Farol</div><div class="dim">(new tab: right-click the chat)</div></div>
<div class="dim" style="font-size:12px;margin-top:8px">Farol only writes in your own chat; it never creates or changes your chat tabs.</div></div>"""
page("farol-16-chat-tab-diagnostics", f'{cwin}{cmenu}', "A chat tab of its own + /farol diag", "Mensagens numa aba de chat própria e /farol diagnostico", TAB_CSS + CHAT_CSS)

# 17. Minimap button + colorblind-friendly colors
mm = """<div style="position:relative;width:250px;height:250px">
<div style="position:absolute;inset:0;border-radius:50%;background:radial-gradient(circle at 40% 40%,#6b5a3a,#2f2618 70%);border:6px solid #8a7444;box-shadow:0 10px 30px #000"></div>
<div style="position:absolute;right:-6px;top:36px;width:40px;height:40px;border-radius:50%;background:#111;border:3px solid #c9a24a;display:flex;align-items:center;justify-content:center;overflow:hidden">
<img src="data:image/png;base64,LOGO" style="width:30px;height:30px;border-radius:5px"></div></div>""".replace("LOGO", logo)
mtip = ('<div class="tip" style="width:330px;font-size:13px"><div style="color:#33ccff;font-weight:bold">Farol</div>'
        '<div>Left-click: show/hide the bar</div><div>Right-click: hide all bars (this session)</div><div>Drag: move around the minimap</div>'
        '<div class="dim">/farol minimap off · lock</div></div>')
CB = lambda good, warn, bad: hbar([("🔭",f'<span style="color:{good}">60</span> fps'),("⚡",f'<span style="color:{warn}">172</span> ms'),("🔨",f'Dur <span style="color:{bad}">18%</span>'),("🎒",f'Bags <span style="color:{warn}">8</span>/80')], "font-size:14px")
cbs = (f'<div style="display:flex;flex-direction:column;gap:12px;align-items:flex-start"><div class="dim">Default: good · attention · alert</div>{CB("#40ff40","#ffff3a","#ff6666")}'
       f'<div class="dim">Colorblind-friendly (Menu &gt; General): blue · yellow · orange</div>{CB("#66b3ff","#ffff3a","#ff8a33")}</div>')
page("farol-17-minimap-colorblind", f'<div style="display:flex;flex-direction:column;gap:14px;align-items:center">{mm}{mtip}</div>{cbs}',
     "Minimap button and colorblind-friendly colors", "Botão no minimapa e cores para daltonismo")

# 18. Notepad (account-wide notes with a done checkbox)
NCSS = """.ncols{display:grid;grid-template-columns:250px 1fr;gap:14px}
.nlst{background:#0006;border:1px solid #6e5b2e66;border-radius:5px;padding:6px}
.ni{display:flex;align-items:center;gap:8px;padding:4px 6px;border-radius:4px;font-size:14px}.ni.sel{background:#ffd10022;outline:1px solid #ffd10066}
.ndone{color:#8c8c8c;text-decoration:line-through}
.nsep{color:#9a9a9a;font-size:12px;margin:6px 6px 2px;border-top:1px solid #ffffff1a;padding-top:5px}
.ned{background:#000;border:1px solid #777;border-radius:4px;padding:8px 10px;font-size:14px;line-height:1.5;min-height:190px}
.nttl{background:#000;border:1px solid #c9a24a;border-radius:4px;padding:4px 10px;color:#ffd100;font-weight:bold;font-size:15px;margin-bottom:6px}"""
def nrow(title, done=False, sel=False):
    return (f'<div class="ni{" sel" if sel else ""}"><span class="box" style="width:16px;height:16px;font-size:12px">{"✓" if done else ""}</span>'
            f'<span class="{"ndone" if done else ""}">{title}</span></div>')
nwin = ('<div class="win" style="width:760px"><div class="x">×</div><div class="t">Notes (3/5 pending)</div><div class="ncols"><div class="nlst">'
        + nrow("Leather farming route", sel=True) + nrow("Buy at the auction house") + nrow("Friday group at 21:00")
        + '<div class="nsep">Done</div>' + nrow("Train Cooking", True) + nrow("Sell the cloth", True)
        + '<div style="margin-top:10px;display:flex;gap:6px;flex-wrap:wrap"><span class="btn">+ New note</span><span class="btn">Clear done</span></div></div>'
        + '<div><div class="nttl">Leather farming route</div><div class="ned">1. Start in the hills north of the camp<br>2. Follow the river to the old bridge<br>'
          '3. Back by the road (passes the merchant)<br><br>Goal: 40 medium leather before the Friday group.</div>'
        + '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px"><span class="dim" style="font-size:12px">164 / 500 · saved as you type</span>'
          '<span><span class="btn">✓ Done</span> <span class="btn">Delete</span></span></div>'
        + '<div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px;font-size:12.5px"><span>Deleted: Old list</span><span class="btn" style="padding:2px 10px">Undo</span></div>'
        + '</div></div></div>')
NB = hbar([("📒",'Notes <span class="y">3</span>/5'),("⏰",'21:05')], "font-size:14px")
NB = NB[:-len('</div>')] + '<span class="qb" style="box-shadow:0 0 0 2px #ffd75a">📓<span class="badge" style="color:#ffff3a">3</span></span></div>'
ntip = ('<div class="tip" style="width:300px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Notes</div>'
        '<div class="row"><span class="k">Notes</span><span>3 pending of 5</span></div>'
        '<div>&nbsp;&nbsp; Leather farming route</div><div>&nbsp;&nbsp; Buy at the auction house</div><div>&nbsp;&nbsp; Friday group at 21:00</div>'
        '<div class="dim" style="margin-top:4px">📓 button: click opens/closes · Shift-click: new note</div></div>'
        '<div class="tip" style="width:300px;font-size:13px;background:#0b1424e8;border-color:#c9a24a88">Key binding of your choice: Esc &gt; Options &gt; Keybindings &gt; AddOns &gt; Farol &gt; <b>Notes</b></div>')
page("farol-18-notepad", f'<div style="display:flex;flex-direction:column;gap:14px;align-items:flex-start">{NB}{ntip}</div>{nwin}',
     "Notepad: 10 notes, one click away", "Bloco de notas: 10 anotações da conta, a um clique (botão 📓 e tecla de atalho)", NCSS)

# 19. Kept items (for later recipes)
KCSS = """.kr{display:grid;grid-template-columns:26px 190px 110px 1fr 24px;gap:8px;align-items:center;padding:5px 2px;border-bottom:1px solid #ffffff10;font-size:14px}
.khd{display:grid;grid-template-columns:26px 190px 110px 1fr 24px;gap:8px;color:#ffd100;font-size:12px;font-weight:bold;padding-bottom:3px;border-bottom:1px solid #6e5b2e;margin-top:8px}
.kic{width:22px;height:22px;border:1px solid #b7a26b;border-radius:3px;background:#2a2418;display:flex;align-items:center;justify-content:center;font-family:'Noto Color Emoji';font-size:13px}
.kin{background:#000;border:1px solid #777;border-radius:3px;padding:3px 8px;color:#888;font-style:italic;font-size:13px}"""
def krow(icon, name, cls, have, why):
    return (f'<div class="kr"><span class="kic">{icon}</span><span class="{cls}">{name}</span><span>{have}</span><span>{why}</span>'
            '<span class="btn" style="padding:1px 6px">X</span></div>')
kwin = ('<div class="win" style="width:680px"><div class="x">×</div><div class="t">Kept items (4)</div>'
        '<div class="kin" style="margin-bottom:6px">Item name (or /farol keep + Shift-click the item)</div>'
        '<div style="display:flex;gap:8px;align-items:center"><span class="kin" style="flex:1">Reason (optional): Alchemy recipe...</span>'
        '<span class="btn">When: level ▾</span><span class="kin" style="width:34px;font-style:normal;color:#fff;text-align:center">35</span><span class="btn">+ Keep</span></div>'
        '<div class="khd"><span></span><span>Item</span><span>Have</span><span>What for / when</span><span></span></div>'
        + krow("🌿", "Moonleaf herb", "q2", '12 <span class="dim">(8 bank)</span>', 'Alchemy recipe · <span class="y">level 35 — 7 to go</span>')
        + krow("✨", "Glimmer dust", "", '5', 'Enchanting · <span class="g">Enchanting 150 — ready</span>')
        + krow("🦎", "Marsh leather", "", '20 <span class="dim">(20 bank)</span>', 'bag for my alt · <span class="dim">no deadline</span>')
        + krow("🍖", "Old boar meat", "q0", '3', 'village quest · <span class="dim">no deadline</span>')
        + '<div class="ck" style="margin-top:8px"><span class="box">✓</span>Remind me when I open a merchant (kept items in my bags)</div>'
        + '<div class="ck"><span class="box">✓</span>Tell me when the time comes (once per character)</div>'
        + '<div class="ck"><span class="box"></span>Show "kept" in the item tooltip</div>'
        + '<div class="dim" style="font-size:12px;margin-top:4px">Kept items are left out of "Junk in bags". Farol never sells, moves or locks items.</div></div>')
kchat = ('<div class="cwin" style="width:520px;font-size:13.5px;line-height:1.6">'
         '<div><span style="color:#33ccff">Farol:</span> <span class="y">kept items in your bags: Moonleaf herb ×4 (Alchemy recipe), Old boar meat ×3 (village quest)</span></div>'
         '<div><span style="color:#33ccff">Farol:</span> <span class="g">you reached level 35: you can now use Moonleaf herb ×12 (Alchemy recipe). 8 are in the bank.</span></div></div>')
ktip = ('<div class="tip" style="width:300px"><div class="q2" style="font-weight:bold">Moonleaf herb</div><div>Trade goods</div>'
        '<div style="color:#ffd75a;margin-top:4px">Farol: kept — Alchemy recipe (level 35)</div></div>')
kpick = ('<div class="tip" style="width:420px;font-size:13.5px;line-height:1.5"><div class="dim" style="font-size:12px">Click the item box: 3 items with "moon" · wheel to scroll</div>'
         '<div class="row"><span>🌿 <span class="q2">Moonleaf herb</span></span><span>×12 <span class="dim">bags + bank</span></span></div>'
         '<div class="row"><span>🌙 Moonstone shard</span><span>×2 <span class="dim">bank</span></span></div>'
         '<div class="row"><span>🐟 <span class="q1">Moon perch</span></span><span>×5 <span class="dim">bags</span></span></div>'
         '<div class="dim" style="font-size:12px">bank noted: Today 07:40</div></div>')
page("farol-19-kept-items", f'{kwin}<div style="display:flex;flex-direction:column;gap:16px;align-items:flex-start">{kpick}{kchat}{ktip}</div>',
     "Kept items: save materials for later, get reminded", "Itens guardados: materiais para depois, com lembrete no comerciante e na hora certa",
     KCSS + CHAT_CSS)
# 20. Farol hub (detailed style)
HCSS = """.hub{position:relative;width:1060px;height:540px;background:linear-gradient(#17140f,#0d0c0a);border:3px solid #7a5f2a;border-radius:10px;box-shadow:0 0 0 2px #000,0 14px 40px #000;display:grid;grid-template-columns:190px 1fr;grid-template-rows:46px 1fr 30px;font:13px/1.35 'DejaVu Sans',sans-serif;color:#e8e2d0;transform:scale(.88);margin-top:46px}
.htop{grid-column:1/3;display:flex;align-items:center;justify-content:center;border-bottom:2px solid #5a4520;background:linear-gradient(#2a2112,#16120b);border-radius:8px 8px 0 0;position:relative}
.hban{font:bold 20px 'DejaVu Serif',serif;color:#ffd75a;padding:2px 34px;border:1px solid #7a5f2a;border-radius:4px;background:#1b150b}
.hmeta{position:absolute;right:12px;top:12px;display:flex;gap:8px;font-size:12px;color:#a89a78}.hpill{border:1px solid #6e5b2e;border-radius:3px;padding:1px 7px;color:#e8dcb8;background:#0c0a07}
.hmed{position:absolute;left:14px;top:9px;width:28px;height:28px;z-index:3}
.hside{border-right:2px solid #3e3018;background:#100e0a;padding:22px 8px 8px;display:flex;flex-direction:column;gap:1px}
.hnav{display:flex;align-items:center;gap:10px;padding:4px 10px;border-radius:4px;color:#d8cfb4;font-size:13px}.hnav i{font-style:normal;width:18px;font-family:'Noto Color Emoji'}
.hnav.on{background:linear-gradient(90deg,#5a3f12,#2a1f0d);color:#ffd75a;box-shadow:inset 3px 0 0 #ffd100;font-weight:bold}
.hwho{margin-top:auto;border-top:1px solid #3e3018;padding:6px 10px 0;font-size:12px}.hwho b{color:#ffd75a}
.hmain{padding:10px 14px;display:grid;grid-template-columns:repeat(3,1fr);gap:9px;align-content:start}
.hcard{border:1px solid #7a5f2a;border-radius:6px;background:linear-gradient(#1c170f,#120f0a);padding:7px 10px}
.hcard h3{margin:0 0 4px;font:bold 11px 'DejaVu Sans';color:#ffb347;letter-spacing:1px;text-transform:uppercase;border-bottom:1px solid #5a452055;padding-bottom:3px}
.hrow{display:flex;justify-content:space-between;margin:2px 0;font-size:12.5px}.hbig{font-size:19px;font-weight:bold;color:#fff}
.hfoot{grid-column:1/3;border-top:2px solid #3e3018;display:flex;align-items:center;gap:6px;padding:0 12px;background:#0f0c08;border-radius:0 0 8px 8px}
.hrow>span:first-child:has(>div){flex:1}.hnew{display:inline-block;background:#3a6a2a;color:#d8ffd0;font-size:9px;border-radius:3px;padding:0 4px;margin-left:4px;letter-spacing:0}"""
navs = [("🏠","Home",True),("👥","Characters",0),("🎯","Goals",0),("📜","Quests",0),("⚒️","Professions",0),("📋","Tasks",0),("📒","Notes",0),("📦","Kept items",0),("🗝️","Dungeons",0),("👜","Loot",0),("⏰","Alarms",0),("🔔","Warnings",0),("⚙️","Settings",0)]
def hbar(p, c):
    return f'<div style="width:100%;height:6px;border:1px solid #000;border-radius:3px;background:#222;overflow:hidden;margin:-1px 0 3px"><div style="width:{p}%;height:100%;background:{c}"></div></div>'
def hcard(title, rows, extra=""):
    return f'<div class="hcard" style="{extra}"><h3>{title}</h3>' + "".join(f'<div class="hrow"><span>{a}</span><span>{b}</span></div>' for a, b in rows) + '</div>'
hub_html = (f'<div class="hub" style="height:610px;transform:scale(.8);margin-top:20px"><div class="hmed"><img src="data:image/png;base64,{logo}" style="width:28px;height:28px;display:block"></div>'
    '<div class="htop"><span class="hban">Farol</span><div class="hmeta"><span>v3.27</span><span class="hpill">English ▾</span><span class="hpill">Simple style</span><span class="btn" style="padding:0 6px">×</span></div></div>'
    '<div class="hside">' + "".join(f'<div class="hnav{" on" if on else ""}"><i>{e}</i>{n}</div>' for e, n, on in navs)
    + '<div class="hwho"><b>Aldric</b><br><span class="dim">Level 26</span></div></div>'
    '<div class="hmain">'
    '<div class="hcard" style="grid-column:1/4"><h3>This session · 1h 12m</h3><div style="display:flex;gap:46px">'
    '<div><div class="dim" style="font-size:11px">Session gold</div><div class="hbig">+38<span class="gold">g</span> 12<span class="silver">s</span></div></div>'
    '<div><div class="dim" style="font-size:11px">Gold per hour</div><div class="hbig">+31<span class="gold">g</span> 45<span class="silver">s</span></div></div>'
    '<div><div class="dim" style="font-size:11px">Experience</div><div class="hbig">72% <span class="blue" style="font-size:13px">+12%</span></div></div>'
    '<div><div class="dim" style="font-size:11px">XP per hour</div><div class="hbig">17.8k</div></div></div>'
    '<div style="height:9px;border:1px solid #000;border-radius:3px;background:#222;margin:7px 0 2px;position:relative;overflow:hidden"><span style="position:absolute;left:0;top:0;bottom:0;width:72%;background:#7a4dff"></span><span style="position:absolute;left:72%;top:0;bottom:0;width:12%;background:#2a4f8a"></span></div>'
    '<div class="dim" style="font-size:11px">XP 72% of level 26 · rested +12% · next level in ~42m</div></div>'
    + hcard('Goals <span class="hnew">new</span>', [("Gold 500g", "24% · ~11h 50m"), (hbar(24, "#3fbf3f"), ""), ("Level 30", "45% · ~9h 20m"), (hbar(45, "#7a4dff"), ""), ("🌿 Moonleaf", "38/60 · ~40m"), (hbar(63, "#ffd75a"), "")])
    + hcard('Now <span class="hnew">new</span>', [('<span class="hbig" style="font-size:15px">Old Crypt</span>', "37m"), ("XP", "+14.2k"), ("Gold", '+6<span class="gold">g</span> 40<span class="silver">s</span>'), ("Loot", "23 (2 rares)"), ('<span class="dim">outside a dungeon: the next alarm</span>', "")])
    + hcard("Quests", [("Ready to turn in", '<span class="g">5</span>'), ("Value of ready ones", ""), ("12.4k XP · 18s", ""), ('<span class="g">reaches level 27</span>', ""), (hbar(85, "#ffd75a"), ""), ("Completed", "412")])
    + hcard("Tasks and resets", [("Daily 2/3", "5h 12m"), (hbar(66, "#3fbf3f"), ""), ("Weekly 0/2", "2d 4h"), (hbar(0, "#3fbf3f"), "")])
    + hcard("Gear and bags", [("Durability", '<span class="y">34%</span>'), (hbar(34, "#ffd75a"), ""), ("Bags", "72/80 used"), (hbar(90, "#ff8a33"), ""), ("Junk", "3g 26s (3)"), ("Hearthstone", "Lighthouse Bay - ready")])
    + hcard("Warnings and reminders", [("Last warning", '<span class="dim">Today 21:40</span>'), ('<span class="y">Bags almost full</span>', ""), ("Pending notes", "2/5"), ("Kept items", '4 · <span class="g">1 ready</span>'), ("Next alarm", "07:30")])
    + hcard("Characters and professions", [("Account gold (this realm)", "1482g 10s"), ("Characters noted", "3"), ("Professions", "First Aid 133/150 · Fishing 40/75")], "grid-column:1/4")
    + '</div><div class="hfoot"><span class="btn">Summary now</span><span class="btn">Bar...</span><span class="btn">Appearance...</span><span class="dim" style="margin-left:auto;font-size:11px">Click a card to open its section · read-only; nothing is sent</span></div></div>')
page("farol-20-hub-detailed-style", hub_html, "Two styles: simple, or everything in the Farol hub",
     "Dois estilos: simples, ou tudo na Central do Farol (barra lateral e cartões)", HCSS)
# 21. Hub: professions and characters (3.28)
PCSS = """.ptr{position:relative;height:12px;border:1px solid #000;border-radius:3px;background:#1c1c1c;margin:16px 30px 18px 0}
.ptr .f{position:absolute;left:0;top:0;bottom:0;background:#3fbf3f}.ptr .s{position:absolute;top:0;bottom:0;background:#ffd75a}
.ptk{position:absolute;top:-3px;bottom:-3px;width:2px;background:#c9a24a}.ptl{position:absolute;top:15px;font-size:10px;color:#a89a78;transform:translateX(-50%);white-space:nowrap}
.plim{position:absolute;top:-5px;bottom:-5px;width:3px;background:#ff8a33}.ptl.top{top:-15px;color:#e8dcb8}
.pb{display:inline-block;border:1px solid #6e5b2e;border-radius:9px;padding:0 7px;font-size:10.5px;color:#e8dcb8;margin-left:6px}
.pct{display:grid;grid-template-columns:1.3fr .5fr 1fr 1fr 1.2fr .8fr;gap:6px;padding:4px 6px;font-size:12px;border-bottom:1px solid #ffffff10}
.pct.h{color:#ffb347;font-weight:bold;font-size:10.5px;letter-spacing:1px}"""
def ptrack(level, limit, start, names=("Apprentice","Journeyman","Expert","Artisan")):
    pc = lambda v: v / 300 * 100
    h = f'<div class="ptr"><span class="f" style="width:{pc(start)}%"></span><span class="s" style="left:{pc(start)}%;width:{pc(level)-pc(start)}%"></span>'
    for v, n in zip((75, 150, 225, 300), names): h += f'<span class="ptk" style="left:{pc(v)}%"></span><span class="ptl" style="left:{pc(v)}%">{v} · {n}</span>'
    return h + f'<span class="plim" style="left:{pc(limit)}%"></span><span class="ptl top" style="left:{pc(limit)}%">your limit {limit}</span></div>'
def pcard(name, rank, sub, track, row):
    return (f'<div class="hcard"><h3 style="display:flex;justify-content:space-between;text-transform:none;font-size:13px;color:#ffd75a"><span>{name}<span class="pb">{rank}</span></span>'
            f'<span style="font-weight:normal;color:#e8e2d0">{sub}</span></h3>{track}<div class="hrow"><span>{row[0]}</span><span>{row[1]}</span></div></div>')
profs_main = ('<div class="hmain" style="display:block">'
    + pcard("First Aid", "Journeyman", '133 / 150 · <span class="y">17 to the limit</span>', ptrack(133, 150, 115), ("This session", '<span class="g">+18</span> points · ~16 per hour'))
    + '<div style="height:8px"></div>' + pcard("Herbalism", "Expert", "192 / 225", ptrack(192, 225, 192), ("This session", '<span class="dim">no change</span>'))
    + '<div style="height:8px"></div>' + pcard("Fishing", "Journeyman", '150 / 150 · <span class="y">at the limit</span>', ptrack(150, 150, 141), ("Next step", '<span class="y">find a trainer to learn Expert</span>'))
    + '</div>')
chars_main = ('<div class="hmain" style="display:block"><div class="hcard"><h3 style="display:flex;justify-content:space-between;text-transform:none;font-size:13px;color:#ffd75a"><span>Characters on this realm</span><span style="font-weight:normal;color:#a89a78;font-size:11px">Account gold: 1482g 10s</span></h3>'
    '<div class="pct h"><span>CHARACTER</span><span>LEVEL</span><span>GOLD</span><span>RESTED</span><span>HEARTHSTONE</span><span>SEEN</span></div>'
    '<div class="pct"><span class="y">Aldric — you</span><span>26</span><span>123g 45s</span><span>15%</span><span>Lighthouse Bay</span><span>now</span></div>'
    '<div class="pct"><span>Mira</span><span>34</span><span>1020g 50s</span><span class="g">full (150%)</span><span>Valley Village</span><span class="dim">Yesterday</span></div>'
    '<div class="pct"><span>Tor</span><span>12</span><span>338g 15s</span><span>62%</span><span>Old Harbor</span><span class="dim">Nov 8</span></div></div>'
    '<div style="height:8px"></div>' + hcard("Saved instances", [("Tor — Ancient Crypt", "2 of 5 bosses · resets in 2d 4h"), ("Mira — Sunken Tower", "5 of 5 bosses · resets in 5h 12m")])
    + '<div style="height:8px"></div>' + hcard("Rested XP", [("Mira (34)", '<span class="g">fully rested: ready to level</span>'), ("Tor (12)", "62% · full in ~2d 6h")]) + '</div>')
def hub_page(active, main):
    side = "".join(f'<div class="hnav{" on" if n == active else ""}"><i>{e}</i>{n}</div>' for e, n, _ in navs)
    return (f'<div style="width:590px;height:310px;position:relative"><div class="hub" style="transform:scale(.555);transform-origin:top left;margin:0;position:absolute;left:0;top:0"><div class="hmed"><img src="data:image/png;base64,{logo}" style="width:28px;height:28px;display:block"></div>'
        '<div class="htop"><span class="hban">Farol</span><div class="hmeta"><span>v3.28</span><span class="hpill">English ▾</span><span class="hpill">Simple style</span></div></div>'
        f'<div class="hside">{side}<div class="hwho"><b>Aldric</b><br><span class="dim">Level 26</span></div></div>{main}'
        '<div class="hfoot"><span class="btn">Summary now</span><span class="btn">Bar...</span><span class="btn">Appearance...</span></div></div></div>')
page("farol-21-hub-professions-characters", f'<div style="display:flex;gap:28px;align-items:center;margin-top:40px">{hub_page("Professions", profs_main)}{hub_page("Characters", chars_main)}</div>',
     "Professions to your limit, and all your characters", "Profissões até o seu limite e todos os seus personagens (Central do Farol)", HCSS + PCSS)
# 22. Hub: tasks, notes and kept items in cards (3.29)
TCSS = """.hpan{border:1px solid #7a5f2a;border-radius:6px;background:linear-gradient(#1c170f,#120f0a);padding:7px 10px;margin-bottom:8px}
.hpan h4{margin:0 0 5px;display:flex;justify-content:space-between;font:bold 14px 'DejaVu Serif',serif;color:#ffd75a}.hpan h4 small{font:11px 'DejaVu Sans';color:#a89a78}
.tbar{height:7px;border:1px solid #000;border-radius:3px;background:#222;margin:2px 0 6px;overflow:hidden}.tbar span{display:block;height:100%;background:#3fbf3f}
.tk{display:flex;align-items:center;gap:7px;margin:3px 0;font-size:12.5px}.tk .box{width:13px;height:13px;font-size:10px}
.kc{display:flex;gap:8px;align-items:center;border:1px solid #5a4520;border-radius:5px;background:#16120b;padding:4px 7px;font-size:12px}.kc .ki{font-size:22px;font-family:'Noto Color Emoji'}"""
def hub_small(active, main, scale=.455):
    side = "".join(f'<div class="hnav{" on" if n == active else ""}"><i>{e}</i>{n}</div>' for e, n, _ in navs)
    return (f'<div style="width:{int(1066*scale)}px;height:{int(546*scale)}px;position:relative"><div class="hub" style="transform:scale({scale});transform-origin:top left;margin:0;position:absolute;left:0;top:0"><div class="hmed"><img src="data:image/png;base64,{logo}" style="width:28px;height:28px;display:block"></div>'
        '<div class="htop"><span class="hban">Farol</span><div class="hmeta"><span>v3.29</span><span class="hpill">English ▾</span><span class="hpill">Simple style</span></div></div>'
        f'<div class="hside">{side}<div class="hwho"><b>Aldric</b><br><span class="dim">Level 26</span></div></div>{main}'
        '<div class="hfoot"><span class="btn">Summary now</span><span class="btn">Bar...</span><span class="btn">Appearance...</span></div></div></div>')
def tk(done, name, kind=""):
    return f'<div class="tk"><span class="box">{"✓" if done else ""}</span><span class="{"dim" if done else ""}">{name}</span><span class="btn" style="margin-left:auto;padding:0 5px">X</span></div>'
def tcol(title, sub, pct, items):
    return f'<div class="hpan" style="flex:1;height:250px"><h4>{title}<small>{sub}</small></h4><div class="tbar"><span style="width:{pct}%"></span></div>' + "".join(items) + '</div>'
tasks_main = ('<div class="hmain" style="display:block"><div class="hpan"><h4>New task<small>daily tasks reset at the daily reset; weekly ones at the weekly</small></h4>'
    '<div style="display:flex;gap:8px"><span class="kin" style="flex:1">New task...</span><span class="btn">Type: Daily</span><span class="btn">Add</span></div></div>'
    '<div style="display:flex;gap:8px">' + tcol("Daily", "2 of 3 · resets in 5h 12m", 66, [tk(1, "Fishing daily"), tk(1, "Cooking daily"), tk(0, "Herb run")])
    + tcol("Weekly", "0 of 2 · resets in 2d 4h", 0, [tk(0, "Ancient Crypt"), tk(0, "Sunken Tower")]) + '</div>'
    '<div class="hpan"><div class="tk"><span class="box">✓</span>Warn 1 h before the daily reset if a daily is left</div></div></div>')
notes_main = ('<div class="hmain" style="display:flex;gap:8px;align-items:flex-start"><div class="hpan" style="width:270px;height:400px;white-space:nowrap"><h4>Notes<small>2 of 3 pending</small></h4>'
    + tk(0, "Farm route") + tk(0, "Buy at the auction") + tk(1, "Train First Aid")
    + '<div style="margin-top:250px;display:flex;gap:6px"><span class="btn">+ New note</span><span class="btn">Clear done</span></div></div>'
    '<div class="hpan" style="flex:1;height:400px"><h4><span></span><small>edited Today 20:27</small></h4><div class="kin" style="font-style:normal;color:#fff">Farm route</div>'
    '<div class="kin" style="height:250px;margin-top:8px;font-style:normal;color:#e8e2d0;white-space:pre-line">Lake east of the village: herbs and fish.\nThen the old mine: copper.\nSell the junk before going back.</div>'
    '<div style="display:flex;gap:6px;margin-top:8px;align-items:center"><span class="dim" style="font-size:11px">96 / 500 · saved as you type</span><span class="btn" style="margin-left:auto">✓ Done</span><span class="btn">Delete</span></div></div></div>')
def kc(icon, name, cls, have, when):
    return f'<div class="kc"><span class="ki">{icon}</span><div style="flex:1"><div class="{cls}">{name}</div><div class="dim">{have}</div></div><div style="font-size:11px;text-align:right">{when}</div><span class="btn" style="padding:0 5px">X</span></div>'
keep_main = ('<div class="hmain" style="display:block"><div class="hpan"><h4>Keep an item<small>click the box to pick from your bags and bank</small></h4>'
    '<div class="kin" style="margin-bottom:5px">Item name (or /farol keep + Shift-click the item)</div>'
    '<div style="display:flex;gap:8px"><span class="kin" style="flex:1">Reason (optional): Alchemy recipe...</span><span class="btn">When: no deadline</span><span class="btn">+ Keep</span></div></div>'
    '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-bottom:8px">'
    + kc("🌿", "Moonleaf herb", "q2", "12 (8 bank) · Alchemy recipe", '<span class="y">level 35 — 7 to go</span>')
    + kc("✨", "Glimmer dust", "", "5 · Enchanting", '<span class="g">ready</span>')
    + kc("🦎", "Marsh leather", "", "20 (20 bank) · bag for my alt", '<span class="dim">no deadline</span>')
    + kc("🍖", "Old boar meat", "q0", "3 · village quest", '<span class="dim">no deadline</span>') + '</div>'
    '<div class="hpan"><h4>Reminders<small>only in your chat; nothing is sent</small></h4>'
    '<div class="tk"><span class="box">✓</span>Remind me when I open a merchant</div><div class="tk"><span class="box">✓</span>Tell me when the time comes</div></div></div>')
page("farol-22-hub-tasks-notes-kept", '<div style="display:flex;flex-direction:column;gap:10px;align-items:center;margin-top:64px">'
     f'<div style="display:flex;gap:20px">{hub_small("Tasks", tasks_main)}{hub_small("Notes", notes_main)}</div>{hub_small("Kept items", keep_main)}</div>',
     "Tasks, notes and kept items in cards", "Tarefas, anotações e guardados em cartões (Central do Farol)", HCSS + TCSS + KCSS)
# 23. Hub: goals, completed quests and dungeons in cards (3.30)
GCSS = """.trk{height:9px;border:1px solid #000;border-radius:3px;background:#222;overflow:hidden;margin:4px 0 3px;position:relative}.trk span{position:absolute;top:0;bottom:0;left:0}
.st{display:flex;gap:30px}.st .dim{font-size:11px}.big{font-size:18px;font-weight:bold;color:#fff}
.fc{border:1px solid #5a4520;border-radius:5px;background:#16120b;padding:5px 9px;font-size:12px}.fc .ki{font-size:20px;font-family:'Noto Color Emoji';margin-right:6px}
.qr{display:grid;grid-template-columns:44px 1fr 150px 90px;gap:8px;padding:3px 4px;font-size:12px;border-bottom:1px solid #ffffff10}
.qr.h{color:#ffb347;font-weight:bold;font-size:10.5px}.qr.sel{background:#3a2a0e;box-shadow:inset 3px 0 0 #ffd100}
.rc{display:grid;grid-template-columns:1fr 64px 64px 84px 96px 50px;gap:6px;align-items:center;padding:4px 6px;font-size:12px;border:1px solid #5a452066;border-radius:4px;background:#15110a;margin-bottom:4px}"""
def gtrk(p, color="#3fbf3f"): return f'<div class="trk"><span style="width:{p}%;background:{color}"></span></div>'
def gfc(icon, name, cls, have, goal, pct, sess, eta, color="#ffd75a"):
    return (f'<div class="fc"><div style="display:flex;align-items:center"><span class="ki">{icon}</span><span class="{cls}" style="flex:1">{name} {have}/{goal}</span>'
            f'<span class="kin" style="width:40px;font-style:normal;color:#fff">{goal}</span><span class="btn" style="padding:0 5px;margin-left:8px">X</span></div>'
            f'{gtrk(pct, color)}<div style="display:flex;justify-content:space-between" class="dim"><span>{sess}</span><span>{eta}</span></div></div>')
def gstat(items): return '<div class="st">' + "".join(f'<div><div class="dim">{a}</div><div class="big">{b}</div></div>' for a, b in items) + '</div>'
goals_main = ('<div class="hmain" style="display:block"><div style="display:flex;gap:8px">'
    '<div class="hpan" style="flex:1"><h4>Gold<small>goal 500g</small></h4>' + gstat([("You have", '123<span class="gold">g</span> 45<span class="silver">s</span>'), ("Left", "376g"), ("At this pace", "~11h 50m")])
    + gtrk(24) + '<div class="dim" style="font-size:11px">24% · 31g per hour this session</div><div style="display:flex;gap:6px;margin-top:5px"><span class="kin" style="width:70px;font-style:normal;color:#fff">500</span><span class="btn">Set</span><span class="btn">Clear</span></div></div>'
    '<div class="hpan" style="flex:1"><h4>Level<small>from 24 to 30</small></h4>' + gstat([("Now", '26 <span class="dim" style="font-size:12px">72%</span>'), ("Left", "3.3 levels"), ("At this pace", "~9h 20m")])
    + gtrk(45, "#7a4dff") + '<div class="dim" style="font-size:11px">45% of the way · 17800 XP per hour</div><div style="display:flex;gap:6px;margin-top:5px"><span class="kin" style="width:40px;font-style:normal;color:#fff">30</span><span class="btn">Set</span><span class="btn">Clear</span></div></div></div>'
    '<div class="hpan"><h4>Farm (items)<small>3 of 10 · shift-click the item or "+ Goal" in the loot window</small></h4><div style="display:grid;grid-template-columns:1fr 1fr;gap:6px">'
    + gfc("🌿", "Moonleaf herb", "q2", 38, 60, 63, "+14 this session", "~40m")
    + gfc("🪨", "Copper ore", "", 20, 20, 100, '<span class="g">reached</span>', "", "#3fbf3f")
    + gfc("🐟", "Lake perch", "q1", 7, 40, 17, "+7 this session", "~1h 30m") + '</div></div>'
    '<div class="hpan"><div class="tk"><span class="box">✓</span>Warn when a goal is reached (gold, level or farm)</div></div></div>')
def gqr(l, n, z, t, sel=False): return f'<div class="qr{" sel" if sel else ""}"><span class="y">[{l}]</span><span>{n}</span><span class="dim">{z}</span><span class="dim">{t}</span></div>'
quests_main = ('<div class="hmain" style="display:block"><div style="display:flex;gap:8px">'
    '<div class="hpan" style="flex:1.5"><h4>Completed quests<small></small></h4><div style="display:flex;gap:6px;align-items:center"><span>Character:</span><span class="btn">Aldric — this one ▾</span><span class="kin" style="flex:1">search by name or ID...</span></div></div>'
    '<div class="hpan" style="flex:1"><h4>Summary<small>on this computer only</small></h4>' + gstat([("Recorded", "146"), ("Today", "9"), ("Total in game", "412")]) + '</div></div>'
    '<div class="hpan"><h4>Recently turned in<small>click a row for the Wowhead link</small></h4><div class="qr h"><span>Level</span><span>Quest</span><span>Zone</span><span>When</span></div>'
    + gqr(24, "Wolves on the north road", "Mill Valley", "Today 21:42", True) + gqr(25, "A parcel for the smith", "Lighthouse Bay", "Today 21:10")
    + gqr(25, "The lost diary", "Grey Hills", "Today 20:31") + gqr(23, "Herbs for the healer", "Mill Valley", "Yesterday")
    + '<div style="display:flex;gap:6px;align-items:center;margin-top:6px"><span class="dim" style="font-size:11px">Wowhead (Ctrl+C):</span><span class="kin" style="flex:1;font-style:normal;color:#fff">https://www.wowhead.com/forever/quest=1520</span></div></div>'
    '<div class="hpan"><div class="tk"><span class="box">✓</span>Record turned-in quests (on this computer only; nothing is sent)</div></div></div>')
def grc(n, tm, xp, gold, loot, dead): return f'<div class="rc"><span>{n}</span><span>{tm}</span><span class="blue">{xp}</span><span>{gold}</span><span>{loot}</span><span>{dead}</span></div>'
runs_main = ('<div class="hmain" style="display:block"><div style="display:flex;gap:8px">'
    '<div class="hpan" style="flex:1.2;border-color:#c9a24a"><h4>Now: Ancient Crypt<small>dungeon · since 21:05</small></h4>' + gstat([("Time", "37m"), ("XP", "+14.2k"), ("Gold", '+6<span class="gold">g</span> 40<span class="silver">s</span>'), ("Loot", "23 (2 rares)")]) + '</div>'
    '<div class="hpan" style="flex:1"><h4>Last 10<small>average per run</small></h4>' + gstat([("Time", "42m"), ("XP", "+15.1k"), ("Gold", '+7<span class="gold">g</span> 10<span class="silver">s</span>')]) + '</div></div>'
    '<div class="hpan"><h4>History<small>4 of 10 · this character</small></h4>'
    + grc('Sunken Tower <span class="dim">· Today 19:40</span>', "48m", "+16.0k", "+8g 12s", "27 (1 rare)", "1")
    + grc('Ancient Crypt <span class="dim">· Yesterday</span>', "39m", "+13.9k", "+6g 05s", "21", "0")
    + grc('Stone Keep <span class="dim">· Nov 22</span>', "1h 52m", "+31.4k", "+14g 70s", "58 (1 epic)", '<span class="y">4</span>') + '</div>'
    '<div class="hpan" style="display:flex;align-items:center"><div class="tk" style="flex:1"><span class="box">✓</span>Show the summary in chat when leaving</div><span class="btn">Clear history</span></div></div>')
page("farol-23-hub-goals-quests-dungeons", '<div style="display:flex;flex-direction:column;gap:10px;align-items:center;margin-top:64px">'
     f'<div style="display:flex;gap:20px">{hub_small("Goals", goals_main)}{hub_small("Quests", quests_main)}</div>{hub_small("Dungeons", runs_main)}</div>',
     "Goals, completed quests and dungeons in cards", "Metas, missões concluídas e masmorras em cartões (Central do Farol)", HCSS + TCSS + KCSS + GCSS)
# 24. Hub: loot, alarms and warnings in cards; size grip (3.31)
LCSS = """.lr{display:grid;grid-template-columns:24px 1fr 40px 90px 64px 64px;gap:8px;align-items:center;padding:3px 6px;font-size:12px;border:1px solid #5a452066;border-radius:4px;background:#15110a;margin-bottom:4px}.lr .ki{font-family:'Noto Color Emoji';font-size:16px}
.ac{display:grid;grid-template-columns:16px 64px 1fr 90px 22px;gap:8px;align-items:center;padding:5px 8px;border:1px solid #5a452088;border-radius:5px;background:#15110a;margin-bottom:5px;font-size:12px}.atime{font-size:19px;font-weight:bold;color:#fff}
.day{color:#ffb347;font-weight:bold;font-size:11px;letter-spacing:1px;margin:5px 0 3px}.wh{display:grid;grid-template-columns:46px 1fr;gap:8px;padding:3px 6px;font-size:12px;border-left:2px solid #c9a24a;margin:0 0 4px 4px;background:#15110a}
.grip{position:absolute;right:8px;bottom:6px;font-size:30px;color:#ffd75a;line-height:1;text-shadow:0 0 6px #000}"""
def llr(icon, name, cls, qty, when):
    return f'<div class="lr"><span class="ki">{icon}</span><span class="{cls}">{name}</span><span>×{qty}</span><span class="dim">{when}</span><span class="btn" style="padding:0 4px">Keep</span><span class="btn" style="padding:0 4px;white-space:nowrap">+ Goal</span></div>'
loot_main = ('<div class="hmain" style="display:block"><div style="display:flex;gap:8px">'
    '<div class="hpan" style="flex:1.3"><h4>Filters<small>only what you looted</small></h4><div style="display:flex;gap:6px;align-items:center"><span>Show:</span><span class="btn">10 ▾</span><span>Quality:</span><span class="btn">Uncommon+ ▾</span></div></div>'
    '<div class="hpan" style="flex:1"><h4>Summary<small>in this list</small></h4>' + gstat([("Items", "10"), ("Uncommon+", '<span class="g">3</span>'), ("Latest", "21:42")]) + '</div></div>'
    '<div class="hpan"><h4>Recent loot<small>hover: details · shift-click: link</small></h4>'
    + llr("🌿", "Moonleaf herb", "q2", 4, "Today 21:42") + llr("🪨", "Copper ore", "", 6, "Today 21:40") + llr("🗡️", "Watchman's dagger", "q2", 1, "Today 21:31")
    + llr("🐟", "Lake perch", "q1", 3, "Today 21:10") + llr("💍", "Polished copper ring", "q3", 1, "Yesterday") + '</div></div>')
def lac(on, t, name, kind, when):
    return f'<div class="ac"><span class="box" style="width:13px;height:13px;font-size:9px">{"✓" if on else ""}</span><span class="atime" style="{"" if on else "color:#8a8270"}">{t}</span><span>{name}<br><span class="dim" style="font-size:11px">{kind}</span></span><span class="dim" style="text-align:right">{when}</span><span class="btn" style="padding:0 4px">X</span></div>'
alarms_main = ('<div class="hmain" style="display:flex;gap:8px;align-items:flex-start"><div style="width:270px">'
    '<div class="hpan" style="border-color:#c9a24a"><h4>Next<small>by your computer clock</small></h4><div class="big" style="font-size:28px">07:30</div><div class="dim">Guild raid · rings in 3h 12m</div></div>'
    '<div class="hpan"><h4>New alarm<small>up to 10</small></h4><div style="display:flex;gap:6px;align-items:center"><span class="kin" style="width:30px;font-style:normal;color:#fff">21</span>:<span class="kin" style="width:30px;font-style:normal;color:#fff">00</span><span class="btn">Local</span></div>'
    '<div style="display:flex;gap:6px;margin-top:6px"><span class="btn">Add</span><span class="btn">Test sound</span></div></div></div>'
    '<div class="hpan" style="flex:1"><h4>Alarms<small>3 of 10 · tick to turn on</small></h4>'
    + lac(True, "07:30", "Guild raid", "Local", "in 3h 12m") + lac(True, "12:00", "Dailies", "Server", "in 7h 42m") + lac(False, "23:15", "Bedtime", "Local", "off") + '</div></div>')
def lwh(t, text): return f'<div class="wh"><span class="dim">{t}</span><span>{text}</span></div>'
warn_main = ('<div class="hmain" style="display:block"><div class="hpan"><h4>Summary<small>this character · the 10 most recent</small></h4>' + gstat([("Saved", "7"), ("Today", "4"), ("Latest", "12m ago")]) + '</div>'
    '<div class="hpan"><h4>Recent warnings<small>newest first</small></h4><div class="day">TODAY</div>'
    + lwh("21:40", '<span class="y">Bags almost full: 4 free slots</span>') + lwh("21:12", "Durability at 24%: time to repair") + lwh("20:31", '<span class="g">Quests ready: 3 to turn in</span>')
    + '<div class="day">YESTERDAY</div>' + lwh("23:05", "Talent point to spend") + '</div></div>')
grip_hub = hub_small("Warnings", warn_main)
grip_hub = grip_hub[:-12] + '<span class="grip">◢</span>' + grip_hub[-12:]
page("farol-24-hub-loot-alarms-warnings", '<div style="display:flex;flex-direction:column;gap:10px;align-items:center;margin-top:64px">'
     f'<div style="display:flex;gap:20px">{hub_small("Loot", loot_main)}{hub_small("Alarms", alarms_main)}</div>{grip_hub}</div>',
     "Loot, alarms and warnings in cards · drag ◢ to resize", "Saques, alarmes e avisos em cartões · arraste ◢ para mudar o tamanho", HCSS + TCSS + KCSS + GCSS + LCSS)
# 25. Hub: settings in cards (3.32)
SCSS = """.seg{display:flex;margin-bottom:6px}.seg span{border:1px solid #7a5f2a;padding:2px 14px;font-size:12px;color:#d8cfb4;background:#14100a}.seg span.on{background:linear-gradient(#6a4a14,#3a2a0e);color:#ffd75a;font-weight:bold}
.ck2{display:flex;align-items:center;gap:6px;font-size:11.5px;margin:1px 0}.ck2 .box{width:12px;height:12px;font-size:9px}.gear{font-family:'Noto Color Emoji';font-size:11px;margin-left:auto}
.g3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px}.g2{display:grid;grid-template-columns:1fr 1fr;gap:6px}.hpan.red{border-color:#a33;background:linear-gradient(#2a1010,#160909)}.hpan.red h4{color:#ff8a8a}
.nb{display:inline-block;border:1px solid #888;background:#000;color:#fff;font-size:11px;padding:0 4px;margin:0 4px}"""
def sck(on, text, gear=False, extra=""):
    return f'<div class="ck2"><span class="box">{"✓" if on else ""}</span><span>{text}{extra}</span>{"<span class=gear>⚙️</span>" if gear else ""}</div>'
def sseg(active): return '<div class="seg">' + "".join(f'<span class="{"on" if t == active else ""}">{t}</span>' for t in ["Bar", "Warnings", "Tools", "General"]) + '</div>'
def sgrp(title, sub, items, cls=""): return f'<div class="hpan {cls}" style="margin:0"><h4>{title}<small>{sub}</small></h4>' + "".join(items) + '</div>'
set_bar = ('<div class="hmain" style="display:block">' + sseg("Bar") + '<div class="g2" style="margin-bottom:6px">'
    + sgrp("Bar", "picking one changes nothing", ['<div style="display:flex;gap:5px"><span class="btn" style="color:#fff">Bar 1</span><span class="btn">Bar 2 (off)</span><span class="btn">Bar 3 (off)</span></div>', '<div style="display:flex;gap:14px">' + sck(1, "Show") + sck(1, "Lock") + '</div>'])
    + sgrp("Packs", "only turn on what you click", ['<div style="display:flex;gap:5px;flex-wrap:wrap"><span class="btn">Basic</span><span class="btn">Leveling</span><span class="btn">Gold and farm</span><span class="btn">Dungeons</span></div>'])
    + '</div><div class="g3">'
    + sgrp("Performance", "3 of 3", [sck(1, "FPS"), sck(1, "Latency"), sck(1, "Memory")])
    + sgrp("Place", "4 of 4", [sck(1, "Coordinates"), sck(1, "Zone"), sck(1, "Speed"), sck(1, "Hearthstone", True)])
    + sgrp("Gear and bags", "2 of 5", [sck(1, "Durability"), sck(0, "Bags"), sck(1, "Junk in bags"), sck(0, "Ammo and reagents", True), sck(0, "Kept items", True)])
    + sgrp("Gold", "1 of 3", [sck(1, "Gold"), sck(0, "Session gold"), sck(0, "Gold per hour")])
    + sgrp("Progress", "3 of 8", [sck(1, "Experience (XP)"), sck(1, "XP per hour"), sck(0, "Reputation"), sck(0, "Professions"), sck(0, "Goals", True), sck(1, "Quest log", True)])
    + sgrp("Time and social", "0 of 8", [sck(0, "Clock", True), sck(0, "Resets"), sck(0, "Tasks", True), sck(0, "Notes", True), sck(0, "Session time")])
    + '</div></div>')
set_warn = ('<div class="hmain" style="display:block">' + sseg("Warnings")
    + '<div class="hpan" style="display:flex;gap:6px;align-items:center"><span class="btn">Recommended only</span><span class="btn">Turn all off</span><span class="dim" style="font-size:11px">only warns about what is ticked</span></div><div class="g2">'
    + sgrp("Gear and bags", "3 of 4", [sck(1, "Durability below", extra='<span class="nb">20</span>%'), sck(1, "Bags with", extra='<span class="nb">2</span>free slots'), sck(0, "Ammo running low"), sck(0, "Reagents running low")])
    + sgrp("Quests and travel", "0 of 6", [sck(0, "Quest log from", extra='<span class="nb">19</span>quests'), sck(0, "Quests ready"), sck(0, "Hearthstone ready"), sck(0, "Daily tasks left")])
    + sgrp("Character", "3 of 5", [sck(1, "Unspent talent points"), sck(1, "Old spell ranks"), sck(1, "Profession at its limit"), sck(0, "Other character rested")])
    + sgrp("Breaks", "0 of 2", [sck(0, "Break every", extra='<span class="nb">120</span>min'), sck(0, "Water every", extra='<span class="nb">45</span>min')])
    + '</div><div class="hpan" style="margin-top:6px;display:flex;gap:8px;align-items:center">' + sck(1, "Play a sound") + '<span class="btn">30 min</span><span class="btn">Test warning</span><span class="btn">History...</span></div></div>')
set_gen = ('<div class="hmain" style="display:block">' + sseg("General") + '<div class="g2">'
    + sgrp("Language", "", ['<div style="display:flex;gap:5px"><span class="btn" style="color:#fff">Auto</span><span class="btn">Português</span><span class="btn">English</span></div>'])
    + sgrp("Profiles", "advanced", ['<div style="display:flex;gap:5px;align-items:center">Profile: <span class="btn">Account ▾</span><span class="btn">Copy from...</span></div>'])
    + sgrp("Chat and messages", "", ['<div class="ck2">Messages in: <span class="btn" style="padding:0 6px">Main chat ▾</span></div>', sck(1, "Session summary on login"), sck(0, "Where XP and gold come from")])
    + sgrp("Bar and clock", "", [sck(0, "Server time"), sck(1, "Detailed style (Farol hub)"), sck(0, "Gold of all characters")])
    + sgrp("Minimap and accessibility", "", [sck(1, "Minimap button"), sck(0, "Lock the minimap button"), sck(0, "Colorblind colors")])
    + sgrp("⚠ Restore and delete", "asks for a 2nd click", ['<div style="display:flex;gap:5px;flex-wrap:wrap"><span class="btn">Default position</span><span class="btn">Reset session</span><span class="btn">Forget characters</span></div>'], "red")
    + '</div></div>')
page("farol-25-hub-settings", '<div style="display:flex;flex-direction:column;gap:10px;align-items:center;margin-top:64px">'
     f'<div style="display:flex;gap:20px">{hub_small("Settings", set_bar)}{hub_small("Settings", set_warn)}</div>{hub_small("Settings", set_gen)}</div>',
     "Settings in cards, inside the hub", "Configurações em cartões, dentro da Central do Farol", HCSS + TCSS + KCSS + GCSS + SCSS)
# 26. Warning and alarm popups in the hub look (3.33)
POPCSS = """.pop{position:relative;width:440px;border:2px solid #7a5f2a;border-radius:8px;background:linear-gradient(#1c170f,#100d09);box-shadow:0 0 0 2px #000,0 10px 30px #000a;font:13px/1.35 'DejaVu Sans';color:#e8e2d0}
.ptop{display:flex;align-items:center;gap:8px;padding:6px 10px;border-bottom:1px solid #5a4520;background:linear-gradient(#2a2112,#16120b);border-radius:6px 6px 0 0}
.ptop img{width:20px;height:20px}.ptop b{color:#ffd75a;font:bold 14px 'DejaVu Serif',serif}
.wrow{display:grid;grid-template-columns:4px 30px 1fr;gap:10px;padding:8px 10px;border-bottom:1px solid #ffffff10;align-items:center}
.stripe{align-self:stretch;border-radius:2px}.ic{font-family:'Noto Color Emoji';font-size:22px;text-align:center}
.wt{font-weight:bold;color:#fff}.wd{color:#b8af96;font-size:12px}.bt{display:flex;gap:6px;margin-top:5px}
.b2{white-space:nowrap;background:linear-gradient(#8a1a10,#5a0f08);border:1px solid #c33;color:#ffd75a;font-weight:bold;font-size:11px;padding:2px 9px;border-radius:3px}
.pfoot{display:flex;align-items:center;gap:6px;padding:6px 10px}.gr{margin-left:auto;color:#ffd75a}.bigt{font-size:32px;font-weight:bold;color:#fff;line-height:1}
.tg{display:inline-block;border:1px solid #6e5b2e;border-radius:9px;padding:0 7px;font-size:10.5px;color:#e8dcb8}.glow{border-color:#c9a24a;box-shadow:0 0 0 2px #000,0 0 18px #ffd75a66}"""
def ptop(t, extra=""): return f'<div class="ptop"><img src="data:image/png;base64,{logo}"><b>{t}</b>{extra}</div>'
def prow(color, icon, title, detail, buttons=True):
    b = '<div class="bt"><span class="b2">Silence</span><span class="b2">Remind in 30 min ▾</span></div>' if buttons else ""
    return f'<div class="wrow"><span class="stripe" style="background:{color}"></span><span class="ic">{icon}</span><div><div class="wt">{title}</div><div class="wd">{detail}</div>{b}</div></div>'
pop_one = ('<div class="pop">' + ptop("Warning") + prow("#ffd75a", "🎒", "Bags almost full", "2 free slots · 13 slots with junk (38s 14c) to sell.")
    + '<div class="pfoot"></div></div>')
pop_many = ('<div class="pop" style="width:520px">' + ptop("Warnings (3)")
    + prow("#ff6666", "🔨", "Low durability", "18% — time to repair!") + prow("#ffd75a", "🎒", "Bags almost full", "2 free slots.")
    + prow("#ffd75a", "⭐", "Talent point to spend", "You have 1 unspent point.")
    + '<div class="pfoot"><span class="b2">Silence all</span><span class="b2">Remind all in 30 min</span><span class="gr">◢</span></div></div>')
pop_alarm = ('<div class="pop glow" style="width:400px">' + ptop("Alarm", ' <span class="tg">+1 ringing</span>')
    + '<div style="display:grid;grid-template-columns:4px 1fr;gap:12px;padding:12px"><span class="stripe" style="background:#ffd75a"></span><div>'
    + '<div style="display:flex;align-items:baseline;gap:12px"><span class="bigt">07:30</span><span><span class="wt">Guild raid</span><br><span class="wd">Local · ringing now</span></span></div>'
    + '<div class="bt" style="margin-top:10px"><span class="b2">Snooze (5 min)</span><span class="b2">Stop</span></div></div></div></div>')
page("farol-26-hub-popups", '<div style="display:flex;gap:26px;align-items:flex-start;margin-top:70px">'
     f'<div style="display:flex;flex-direction:column;gap:22px">{pop_one}{pop_alarm}</div>{pop_many}</div>',
     "Warnings and alarms in the Farol look", "Avisos e alarmes no visual do Farol (estilo detalhado)", POPCSS)
print("pages ok")
