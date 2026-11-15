"""Gera video.html: vídeo de divulgação do Farol, animado por tempo (window.render(t)) para gravar quadro a quadro.
Reaproveita o CSS e os componentes do gerador das imagens do CurseForge (sem gravar as páginas dele).
Uso (na raiz do repositório): python3 assets/video/make_video.py  →  node assets/video/record.js video
Promo video generator: same look as the CurseForge illustrations; see assets/video/README.md."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(OUT, "..", ".."))
src = open(os.path.join(REPO, "assets/curseforge/make_pages.py"), encoding="utf-8").read()
src = src.replace('open(os.path.join(OUT, name + ".html"), "w", encoding="utf-8").write(html)', 'pass')
src = src.replace('print("pages ok")', '')
ns = {"__file__": os.path.join(REPO, "assets/curseforge/make_pages.py")}
exec(compile(src, "make_pages", "exec"), ns)
CSS, logo, ic, item = ns["CSS"], ns["logo"], ns["ic"], ns["item"]

def items_html(lst, cls="bi"):
    return "".join(f'<span class="{cls}">{item(e, h)}</span>' for e, h in lst)

BAR1 = [("🔭", '<span class="g">60</span> fps'), ("⚡", '<span class="g">42</span> ms'),
        ("🌍", '<span class="zone">Silverpine Hills</span>'), ("🔨", 'Dur <span class="g">87%</span>'),
        ("💰", '<span class="gold">123g</span> <span class="silver">45s</span> <span class="copper">67c</span>'),
        ("📈", 'Gold/h <span class="g">+</span><span class="gold">12g</span> <span class="silver">30s</span>'),
        ("⏳", 'XP/h 18.4k · 42m')]
BAR1_EXTRA = [("🏅", 'Rep <span class="g">Honored</span> 35% <span class="g">+600/h</span>'),
              ("⛏️", 'Mining <span class="y">148/150</span>')]
BAR2 = [("⏰", '20:58'), ("📜", 'Daily 5h 12m · Weekly 2d 4h'), ("⌛", 'Played 1h 02m'),
        ("👥", 'Friends 4'), ("🛡️", 'Guild 12')]
BAR3 = [("🎒", 'Bags <span class="y">8</span>/80'), ("🦴", 'Junk <span class="gold">3g</span> <span class="silver">26s</span>'),
        ("🏹", 'Ammo <span class="y">310</span>'), ("🧠", 'Mem <span class="g">35 MB</span>'), ("🗺️", '45.0, 61.0')]

def ck(id_, label, checked=False):
    return f'<div class="ck"><span class="box" id="{id_}">{"✓" if checked else ""}</span>{label}</div>'

names = ["FPS", "Latency", "Zone", "Durability", "Bags", "Junk in bags", "Ammo & reagents", "Gold", "Gold per hour",
         "XP per hour", "Reputation", "Professions", "Clock", "Resets (daily/weekly)", "Friends online", "Guild online"]
on = {0, 1, 2, 3, 7, 8, 9}
colA = "".join(ck(f"m{i}", n, i in on) for i, n in enumerate(names[:8]))
colB = "".join(ck(f"m{i}", n, i in on) for i, n in enumerate(names[8:], 8))
menu = f"""<div class="win" id="menu" style="width:620px;padding-top:12px;padding-bottom:12px"><div class="x">×</div><div class="t">Farol</div>
<div style="display:flex;gap:8px;align-items:center;margin-top:2px"><span class="k" style="font-size:14px">Bar:</span>
<span class="btn" id="b1" style="padding:2px 10px">Bar 1</span><span class="btn" id="b2" style="padding:2px 10px">Bar 2 (off)</span>
<span class="btn" id="b3" style="padding:2px 10px">Bar 3 (off)</span><span id="newbadge">NEW · NOVO</span></div>
<div style="display:flex;gap:8px;align-items:center;margin-top:6px"><span class="k" style="font-size:14px">Profile:</span>
<span class="btn" style="padding:2px 10px">Account ▾</span><span class="btn" style="padding:2px 10px">Copy from... ▾</span></div>
<div class="h" style="margin-top:6px">Bar items</div><div style="display:flex;gap:60px"><div>{colA}</div><div>{colB}</div></div>
<div class="h">General</div><div style="display:flex;gap:40px">{ck("mshow", "Show panel", True)}{ck("mlock", "Lock position")}</div>
<div style="display:flex;gap:8px;margin-top:8px;white-space:nowrap"><span class="btn">Alarms...</span><span class="btn">Loot...</span>
<span class="btn">Warnings...</span><span class="btn" id="mapp">Appearance...</span><span class="btn">Order...</span></div></div>"""

def stepper(label, vid, value, minus_id, plus_id):
    return (f'<div style="display:flex;align-items:center;gap:10px;margin:7px 0"><span class="k" style="width:110px">{label}</span>'
            f'<span class="btn" id="{minus_id}" style="padding:2px 9px">-</span><span id="{vid}" style="width:52px;text-align:center">{value}</span>'
            f'<span class="btn" id="{plus_id}" style="padding:2px 9px">+</span></div>')
app = f"""<div class="win" id="app" style="width:430px"><div class="x">×</div><div class="t">Appearance — Bar 2</div>
{stepper("Scale:", "vscale", "100%", "sm", "sp")}{stepper("Background:", "vbg", "70%", "bm", "bp")}{stepper("Text:", "vtx", "11", "tm", "tp")}
<div style="display:flex;align-items:center;gap:10px;margin:8px 0"><span class="k" style="width:110px">Layout:</span><span class="btn hl" id="lline">One line</span><span class="btn" id="lcol">One column</span></div>
<div class="ck"><span class="box">✓</span>Show icons on the bar</div><div class="ck"><span class="box" id="acombat"></span>Hide in combat</div></div>"""

tipsmall = """<div class="tip" id="tip1" style="width:300px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol · Gold</div>
<div class="row"><span class="k">Gold</span><span>123g 45s 67c</span></div>
<div class="row"><span class="k">Gold per hour</span><span><span class="g">+</span>12g 30s</span></div>
<div class="row"><span class="k">All characters</span><span>1482g 10s</span></div>
<div class="dim" style="margin-top:6px">Hold Shift to see all information.</div></div>"""
tipfull = """<div class="tip" id="tip2" style="width:400px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">Farol <span class="dim">(Shift)</span></div>
<div class="row"><span class="k">FPS</span><span>60</span></div><div class="row"><span class="k">Latency</span><span>home 42 ms / world 58 ms</span></div>
<div class="row"><span class="k">Zone</span><span>Silverpine Hills · Old Mill</span></div>
<div class="row"><span class="k">Durability (lowest)</span><span>87%</span></div>
<div class="row"><span class="k">Gold</span><span>123g 45s 67c</span></div><div class="row"><span class="k">Gold per hour</span><span>+12g 30s</span></div>
<div class="row"><span class="k">Experience</span><span>11,040 / 24,000 (46%)</span></div><div class="row"><span class="k">XP per hour</span><span>18.4k · next level 42m</span></div>
<div class="row"><span class="k">Reputation</span><span class="g">Honored 35%</span></div>
<div class="row"><span class="k">Daily reset in</span><span>5h 12m</span></div><div class="row"><span class="k">Session</span><span>1h 02m</span></div></div>"""

alarm = """<div class="win" id="alarm" style="width:360px;text-align:center"><div class="t">⏰ Alarm!</div><div style="font-size:16px">21:00 (Server) Raid</div>
<div style="display:flex;justify-content:space-between;margin-top:16px"><span class="btn">Snooze (10 min)</span><span class="btn">Stop</span></div></div>"""
def wrow(text):
    return (f'<div style="display:flex;align-items:center;gap:8px;margin:7px 0"><span style="flex:1;font-size:14px;white-space:nowrap">{text}</span>'
            '<span class="btn" style="padding:3px 10px;font-size:13px">Silence</span>'
            '<span class="btn" style="padding:3px 10px;font-size:13px">Remind in 10 min</span></div>')
warn = f"""<div class="win" id="warn" style="width:700px"><div class="t">Warnings (3)</div>
{wrow("Low durability: 18% — time to repair!")}{wrow("You've been playing for 2h 00m — time for a break?")}{wrow("Time to drink some water!")}</div>"""
loot_items = [("q4", "🛡️", "[Helm of the Lighthouse]", "", "21:42"), ("q3", "💍", "[Band of the Tides]", "", "21:38"),
              ("q2", "🌿", "[Peacebloom]", "x6", "21:20"), ("q1", "🧵", "[Linen Cloth]", "x12", "21:05")]
lrows = "".join(f'<div class="row" style="padding:3px 0;font-size:15px"><span>{ic(e)} <span class="{q}">{n}</span> <span class="dim">{c}</span></span>'
                f'<span class="dim">Today {t}</span></div>' for q, e, n, c, t in loot_items)
loot = f"""<div class="win" id="loot" style="width:430px"><div class="x">×</div><div class="t">Recent loot</div>{lrows}</div>"""

outro = f"""<div id="outro" class="center"><div style="display:flex;align-items:center;gap:26px">
<img src="data:image/png;base64,{logo}" style="width:140px;height:140px;border-radius:14px;box-shadow:0 0 0 3px #c9a24a,0 12px 40px #000">
<div><div style="font:800 76px 'Inter';color:#ffd75a;text-shadow:0 4px 16px #000">Farol</div>
<div style="font:600 26px 'Inter';color:#fff">Free on CurseForge · Grátis no CurseForge</div>
<div style="font:500 20px 'Inter';color:#9fb3cf;margin-top:6px">Open source (MIT) · English / Português</div></div></div>
<div class="pill" style="margin-top:34px">Only reads and shows — no automation, never sends anything</div>
<div class="pill" style="margin-top:10px">Só lê e mostra — nada de automação, nunca envia nada</div>
<div style="font:500 15px 'Inter';color:#9fb3cf;margin-top:22px">Unofficial add-on for WoW Forever · not affiliated with Blizzard Entertainment</div></div>"""

intro = f"""<div id="intro" class="center"><img id="ilogo" src="data:image/png;base64,{logo}" style="width:170px;height:170px;border-radius:16px;box-shadow:0 0 0 3px #c9a24a,0 12px 50px #000">
<div id="ititle" style="font:800 88px 'Inter';color:#ffd75a;text-shadow:0 4px 16px #000;margin-top:18px">Farol</div>
<div id="isub" style="font:500 26px 'Inter';color:#d9e4f2">Info bar · Alarms · Loot · Warnings — for WoW Forever</div></div>"""

CAPS = [
    (0.0, 5.0, "Farol — your info bar for WoW Forever", "Farol — sua barra de informações para o WoW Forever"),
    (5.0, 12.0, "Everything you need, at a glance", "Tudo o que você precisa, num relance"),
    (12.0, 19.5, "Hover an item for its details — Shift shows everything", "Passe o mouse num item para ver os detalhes — Shift mostra tudo"),
    (19.5, 26.0, "Right-click the bar: tick the items you want", "Clique direito na barra: marque os itens que quiser"),
    (26.0, 36.5, "NEW: up to 3 bars, each with its own items and look", "NOVO: até 3 barras, cada uma com itens, posição e aparência próprios"),
    (36.5, 44.0, "Scale, background, text, one line or one column — per bar", "Escala, fundo, texto, uma linha ou uma coluna — em cada barra"),
    (44.0, 51.5, "Alarms, warnings, break reminders and your recent loot", "Alarmes, avisos, lembretes de pausa e seus últimos saques"),
    (51.5, 60.0, "Free · open source · only reads and shows", "Grátis · código aberto · só lê e mostra"),
]
caps_html = "".join(f'<div class="capx" id="cap{i}"><h1>{en}</h1><h2>{pt}</h2></div>' for i, (a, b, en, pt) in enumerate(CAPS))

EXTRA_CSS = """
.layer{position:absolute;left:0;top:0;width:1280px;height:720px}
.center{position:absolute;left:0;right:0;top:0;bottom:150px;display:flex;flex-direction:column;align-items:center;justify-content:center}
.abs{position:absolute}
.capx{position:absolute;left:60px;right:60px;bottom:34px}
.capx h1{font-family:'Inter',sans-serif;font-weight:800;font-size:36px;white-space:nowrap;color:#ffd75a;text-shadow:0 2px 8px #000}
.capx h2{font-family:'Inter',sans-serif;font-weight:500;font-size:25px;color:#d9e4f2;margin-top:6px;text-shadow:0 2px 6px #000}
.capbg{position:absolute;left:0;right:0;bottom:0;height:150px;background:linear-gradient(180deg,#0000,#000c 35%)}
.bi{display:inline-flex;transition:none}
.bar,.vbar{white-space:nowrap}
#newbadge{font:800 12px 'Inter';color:#111;background:#ffd75a;border-radius:999px;padding:3px 9px;margin-left:6px;box-shadow:0 0 12px #ffd75a}
.pill{font:600 18px 'Inter';color:#fff;background:#0007;border:1px solid #c9a24a88;border-radius:999px;padding:8px 18px}
#cursor{position:absolute;width:26px;height:34px;z-index:50;pointer-events:none}
#ring{position:absolute;width:44px;height:44px;border-radius:50%;border:3px solid #ffd75a;z-index:49;pointer-events:none}
#shift{position:absolute;z-index:40;font:700 18px 'Inter';color:#111;background:#e8e8e8;border-radius:6px;padding:6px 14px;box-shadow:0 3px 0 #888,0 6px 18px #000a}
.chat{font-size:15px;line-height:1.7}
#menu .ck{margin:1px 0}
"""

html = f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}{EXTRA_CSS}</style></head><body>
<div class="stars"></div>
<div class="brand" id="brand"><img src="data:image/png;base64,{logo}">Farol</div>
<div class="tag">Illustration · Ilustração</div>
{intro}
<div class="abs" id="bar1wrap" style="left:0;right:0;top:66px;display:flex;justify-content:center">
 <div class="bar" id="bar1" style="font-size:13px;gap:12px;padding:6px 12px">{items_html(BAR1)}<span id="bar1x">{items_html(BAR1_EXTRA, "bx")}</span>
 <span class="qb">📝<span class="badge r">2</span></span><span class="qb">👜<span class="badge g">3</span></span></div></div>
<div class="abs" id="bar2wrap" style="left:0;right:0;top:112px;display:flex;justify-content:center">
 <div class="bar" id="bar2" style="transform-origin:center top">{items_html(BAR2)}</div></div>
<div class="abs" id="bar3" style="left:36px;top:170px"><div class="vbar">{items_html(BAR3)}</div></div>
<div class="abs" id="tip1w" style="left:600px;top:104px">{tipsmall}</div>
<div class="abs" id="tip2w" style="left:480px;top:104px">{tipfull}</div>
<div id="shift" style="left:880px;top:300px">⇧ Shift</div>
<div class="abs" id="menuw" style="left:330px;top:160px;transform-origin:center top">{menu}</div>
<div class="abs" id="appw" style="left:425px;top:190px">{app}</div>
<div class="abs" id="alarmw" style="left:70px;top:160px">{alarm}</div>
<div class="abs" id="lootw" style="left:780px;top:160px">{loot}</div>
<div class="abs" id="warnw" style="left:290px;top:340px">{warn}</div>
{outro}
<div class="capbg"></div>{caps_html}
<div id="ring"></div>
<svg id="cursor" viewBox="0 0 26 34"><path d="M2 2 L2 28 L9 21 L14 32 L18 30 L13 19 L23 19 Z" fill="#fff" stroke="#000" stroke-width="2" stroke-linejoin="round"/></svg>
<script>
const CAPS = {[[a, b] for a, b, _, _ in CAPS]};
</script>
<script src="timeline.js"></script>
</body></html>"""
open(os.path.join(OUT, "video.html"), "w", encoding="utf-8").write(html)
print("video.html ok")
