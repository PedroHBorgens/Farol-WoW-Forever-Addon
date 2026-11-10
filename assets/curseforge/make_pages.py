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
    ("🗺️", '45.0, 61.0'), ("🌍", '<span class="zone">Orgrimmar</span>'),
    ("🔨", 'Dur <span class="g">87%</span>'), ("🎒", 'Bags <span class="y">8</span>/80'),
    ("💰", '<span class="gold">123g</span> <span class="silver">45s</span> <span class="copper">67c</span>'),
    ("📈", 'Gold/h <span class="g">+</span><span class="gold">12g</span> <span class="silver">30s</span>'),
    ("⏳", 'XP/h 18.4k · 42m'),
]
REP_ITEM = ("🏅", 'Orgrimmar <span class="g">Honored</span> 35% <span class="g">+600/h</span>')
RESET_ITEM = ("📜", 'Daily 5h 12m · Weekly 2d 4h')
HERO_ITEMS = BAR_ITEMS[:2] + [BAR_ITEMS[3], BAR_ITEMS[6], BAR_ITEMS[8], REP_ITEM, ("📜", 'Daily 5h 12m')]
def hbar(items=BAR_ITEMS, extra_style=""):
    return f'<div class="bar" style="{extra_style}">' + "".join(item(e,h) for e,h in items) + \
        '<span class="qb">📝<span class="badge r">2</span></span><span class="qb">👜<span class="badge g">3</span></span></div>'

# 1. Hero
page("01_farol", f"""
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
          ("🗺️",'58.5, 54.1'),("🌍",'<span class="zone">Orgrimmar</span>'),("👟",'Speed 100%'),("🔨",'Dur <span class="g">77%</span>'),
          ("🎒",'Bags <span class="g">13</span>/38'),("💰",'<span class="gold">0g</span> <span class="silver">97s</span> <span class="copper">23c</span>'),
          ("🪙",'Session <span class="g">+</span><span class="silver">5s</span> <span class="copper">34c</span>'),
          ("📈",'Gold/h <span class="g">+</span><span class="gold">1g</span> <span class="silver">33s</span>'),
          ("📖",'XP 46% <span class="blue">+0%</span>'),("⏳",'XP/h 18.4k · 42m'),REP_ITEM,("⏰",'18:49'),
          RESET_ITEM,("⌛",'Played 1h 02m'),("👥",'Friends 4'),("🛡️",'Guild 12')]
grid = ('<div class="vbar" style="display:grid;grid-template-columns:repeat(3,auto);column-gap:18px;row-gap:6px;position:relative;padding-bottom:16px;font-size:13px;white-space:nowrap">'
        + "".join(item(e,h) for e,h in gitems)
        + '<span style="position:absolute;right:4px;bottom:0;color:#ccc;font-size:14px">◢</span></div>')
tip = """<div class="tip" style="width:330px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol</div>
<div class="row"><span class="k">Latency</span><span>home 40 ms / world 60 ms</span></div>
<div class="row"><span class="k">Durability (lowest)</span><span class="y">31%</span></div>
<div class="row"><span>&nbsp; [Helm of Valor]</span><span class="y">31%</span></div>
<div class="row"><span class="k">XP per hour</span><span>18.4k</span></div>
<div class="row"><span class="k">Reputation</span><span>Orgrimmar</span></div>
<div class="row"><span class="k">Daily reset in</span><span>5h 12m</span></div>
<div class="row"><span class="k">Server time</span><span>21:05</span></div>
<div class="dim" style="margin-top:6px">Right-click: options.</div></div>"""
page("02_bar", f"""
<div style="display:flex;flex-direction:column;gap:22px;align-items:flex-start">{hbar(BAR_ITEMS[:4])}{tip}</div>
<div style="display:flex;flex-direction:column;gap:8px;align-items:flex-start"><div class="dim">Drag the corner ◢ — one line, one column or columns</div>{grid}</div>""",
     "19 items with icons — one line, one column or columns", "19 informações com ícones — em linha, coluna ou colunas alinhadas, com tooltip")

# 3. Options menu + order
names = ["FPS","Latency","Memory","Coordinates","Zone","Speed","Durability","Bags","Gold","Session gold","Gold per hour","Experience (XP)","XP per hour","Reputation","Clock","Resets (daily/weekly)","Session time","Friends online","Guild online"]
on = {0,1,3,4,6,7,8,10,12,13,15}
half = 10
col = lambda rng: "".join(f'<div class="ck"><span class="box">{"✓" if i in on else ""}</span>{names[i]}</div>' for i in rng)
menu = f"""<div class="win" style="width:580px;padding-top:12px;padding-bottom:14px"><div class="x">×</div><div class="t">Farol</div>
<div class="dim" style="font-size:13px">Tick what you want to see on the bar.</div>
<div class="h">Bar items</div><div style="display:flex;gap:30px"><div>{col(range(0,half))}</div><div>{col(range(half,19))}</div></div>
<div class="h">General</div><div style="display:flex;gap:22px"><div class="ck"><span class="box">✓</span>Show panel</div><div class="ck"><span class="box"></span>Lock position</div><div class="ck"><span class="box">✓</span>Server time</div></div>
<div style="display:flex;gap:8px;align-items:center;margin-top:6px"><span class="k" style="font-size:14px">Language:</span><span class="btn" style="padding:2px 10px">Auto</span><span class="btn" style="padding:2px 10px">Português</span><span class="btn hl" style="padding:2px 10px">English</span></div>
<div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap"><span class="btn">Alarms...</span><span class="btn">Loot...</span><span class="btn">Warnings...</span><span class="btn">Appearance...</span><span class="btn hl">Order...</span><span class="btn">Reset position</span><span class="btn">Reset session</span></div></div>"""
order_names = [("🌍","Zone"),("🔭","FPS"),("⚡","Latency"),("💰","Gold"),("🏅","Reputation"),("📜","Resets (daily/weekly)"),("🔨","Durability"),("🎒","Bags"),("⏰","Clock (hidden)")]
order = '<div class="win" style="width:330px"><div class="x">×</div><div class="t">Bar order</div>' + "".join(
    f'<div class="ck" style="justify-content:space-between"><span><span class="dim" style="display:inline-block;width:22px;text-align:right">{i+1}.</span> {ic(e)} <span class="{"dim" if "hidden" in n else ""}">{n}</span></span><span>▲ ▼</span></div>'
    for i,(e,n) in enumerate(order_names)) + '<div style="text-align:right;margin-top:10px"><span class="btn">Restore default order</span></div></div>'
page("03_menu_order", menu + order, "Tick what you want — and choose the order", "Marque o que quiser e escolha a ordem com as setas")

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
page("04_alarms", alarms + popup, "Clock alarms with snooze — local or server time", "Alarmes do relógio com soneca — hora local ou do servidor")

# 5. Loot
loot_items = [("q5","⚔️","[Thunderfury, Blessed Blade]","","21:42"),("q4","🛡️","[Helm of Valor]","","21:38"),("q3","💍","[Band of the Ancients]","","21:30"),
              ("q2","🌿","[Peacebloom]","x6","21:27"),("q1","🧵","[Linen Cloth]","x12","21:20"),("q2","🗡️","[Bloodlust Dagger]","","21:12")]
rows = "".join(f'<div class="row" style="padding:3px 0;font-size:15px"><span>{ic(e)} <span class="{q}">{n}</span></span><span class="dim">{c}&nbsp;&nbsp;{t}</span></div>' for q,e,n,c,t in loot_items)
dd = """<div class="tip" style="position:absolute;left:236px;top:92px;width:200px;font-size:14px;line-height:1.7;z-index:2;background:#0a0d1a">
<div><span class="k">✓</span> <span class="q0">Poor</span></div><div>&nbsp;&nbsp;&nbsp;<span class="q1">Common</span></div><div><span class="k">✓</span> <span class="q2">Uncommon</span></div>
<div><span class="k">✓</span> <span class="q3">Rare</span></div><div><span class="k">✓</span> <span class="q4">Epic</span></div><div><span class="k">✓</span> <span class="q5">Legendary+</span></div>
<div class="dim">Check all</div><div class="dim">Uncheck all</div></div>"""
loot = f"""<div class="win" style="width:560px;padding-bottom:26px"><div class="x">×</div><div class="t">Recent loot</div>
<div style="display:flex;gap:10px;align-items:center;margin-bottom:10px"><span class="k">Show:</span><span class="btn">10 ▾</span><span class="k" style="margin-left:14px">Quality:</span><span class="btn">5 selected ▾</span></div>
{dd}{rows}<div class="dim" style="font-size:12px;margin-top:10px">Hover: details · Shift-click: link · Wheel: scroll</div>
<div style="position:absolute;right:8px;bottom:6px;color:#aaa">◢</div></div>"""
page("05_loot", loot, "Recent loot window with quality filter", "Janela de últimos saques com filtro de qualidade — redimensionável")

# 6. Warnings
warnpop = """<div class="win" style="width:440px;text-align:center"><div class="t">Warning</div><div style="font-size:16px">You have 2 unspent talent point(s).</div>
<div style="display:flex;justify-content:space-between;margin-top:16px"><span class="btn">Silence</span><span class="btn">Remind in 30 min</span></div></div>"""
hist = """<div class="win" style="width:520px"><div class="x">×</div><div class="t">Recent warnings</div>
<div style="font-size:14px;line-height:1.9"><div><span class="dim">09/11 21:40</span>&nbsp; You have 2 unspent talent point(s).</div>
<div><span class="dim">09/11 21:12</span>&nbsp; Lower-rank spell on your bars: Fireball (Rank 3) — you already know Rank 5.</div>
<div><span class="dim">09/11 20:55</span>&nbsp; Bags almost full: 2 free slot(s).</div>
<div><span class="dim">09/11 20:31</span>&nbsp; Low durability: 18% — time to repair!</div></div>
<div style="text-align:right;margin-top:10px"><span class="btn">Clear</span></div></div>"""
page("06_warnings", f'<div style="display:flex;flex-direction:column;gap:22px;align-items:center">{warnpop}<div style="display:flex;gap:10px;align-items:center">{hbar(BAR_ITEMS[:4])}</div></div>{hist}',
     "Warnings: durability, bags, talents, spell ranks", "Avisos de durabilidade, bolsas, talentos e graus de magia — silenciar ou lembrar em 30 min")

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
<div style="text-align:right;margin-top:8px"><span class="btn">Restore defaults</span></div></div>"""
small = hbar(BAR_ITEMS[:4], "font-size:12px;transform:scale(.9)")
big = hbar(BAR_ITEMS[:4], "font-size:19px;background:#0004;border-color:#0000")
page("07_appearance", f'{app}<div style="display:flex;flex-direction:column;gap:30px;align-items:flex-start"><div class="dim">Small · compact</div>{small}<div class="dim">Large · transparent</div>{big}</div>',
     "Make it yours: shape, size, background, hide in combat", "Do seu jeito: formato livre, tamanho do texto e ícones, fundo, esconder em combate")
# 8. Progress: XP, reputation, resets
pbar = hbar([("📖",'XP 46% <span class="blue">+12%</span>'),("⏳",'XP/h 18.4k · 42m'),REP_ITEM,RESET_ITEM])
ptip = """<div class="tip" style="width:470px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol</div>
<div class="row"><span class="k">Experience</span><span>11,040 / 24,000 (46%)</span></div>
<div class="row"><span class="k">XP per hour</span><span>18.4k</span></div>
<div class="row"><span class="k">Next level in</span><span>42m</span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Reputation</span><span>Orgrimmar</span></div>
<div class="row"><span class="k">Standing</span><span class="g">Honored</span></div>
<div class="row"><span class="k">Progress</span><span>4.2k / 12.0k (35%)</span></div>
<div class="row"><span class="k">Reputation per hour</span><span>+600</span></div>
<div class="row"><span class="k">Next standing in</span><span>13h 00m</span></div>
<div style="height:6px"></div>
<div class="row"><span class="k">Daily reset in</span><span>5h 12m (02:17 local · 05:17 server)</span></div>
<div class="row"><span class="k">Weekly reset in</span><span>2d 4h (Wed 01:05 local · 04:05 server)</span></div></div>"""
page("08_progress", f'<div style="display:flex;flex-direction:column;gap:22px;align-items:center">{pbar}{ptip}</div>',
     "Track your progress: XP, reputation and resets", "Acompanhe seu progresso: XP, reputação e contagem até os resets")
print("pages ok")
