"""Gera youtube.html: vídeo longo (~4 min) de apresentação do Farol para o YouTube, em 21 cenas.
Cada cena tem um trecho da narração; a duração de cada cena vem de youtube_timing.json (gerado por
youtube_audio.py a partir do áudio) ou, sem ele, de uma estimativa. Mesmo estilo das imagens do CurseForge:
ilustração (não é gravação do jogo), nomes genéricos, nada da Blizzard.
Uso: python3 assets/video/youtube.py  →  PAGE=youtube.html node assets/video/record.js video saida.mp4
(as legendas .srt em inglês e português saem de youtube_audio.py subs)"""
import json, os
OUT = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(OUT, "..", ".."))
src = open(os.path.join(REPO, "assets/curseforge/make_pages.py"), encoding="utf-8").read()
src = src.replace('open(os.path.join(OUT, name + ".html"), "w", encoding="utf-8").write(html)', 'pass').replace('print("pages ok")', '')
ns = {"__file__": os.path.join(REPO, "assets/curseforge/make_pages.py")}
exec(compile(src, "make_pages", "exec"), ns)
CSS, logo, ic, item = ns["CSS"], ns["logo"], ns["ic"], ns["item"]

# Narração de cada cena (o mesmo texto enviado ao gerador de voz) e legendas EN/PT.
SCENES = [
    ("intro", "Meet Farol: a free info bar for WoW Forever. Let's take a quick tour.",
     "Farol — a free info bar for WoW Forever", "Farol — uma barra de informações gratuita para o WoW Forever"),
    ("bar", "Farol puts everything you need in one small bar: frame rate, latency, zone, durability, gold, gold per hour, and XP per hour.",
     "Everything you need, in one small bar", "Tudo o que você precisa, numa barra pequena"),
    ("tip", "Hover any item to see its own short tooltip. Hold Shift, and you get everything at once.",
     "Hover an item for details — hold Shift for everything", "Passe o mouse num item — segure Shift para ver tudo"),
    ("menu", "Right-click the bar to open the menu. It has four tabs: Bar, Warnings, Tools, and General. Tick the items you want, and they show up instantly.",
     "Right-click the bar: a menu with tabs", "Clique direito na barra: um menu com abas"),
    ("order", "Open the Order window to move items up or down, and arrange the bar your way.",
     "Choose the order of the items", "Escolha a ordem dos itens"),
    ("progress", "Track your progress: XP per hour and time to the next level, reputation per hour, and your professions, with a reminder when you reach the training limit.",
     "XP, reputation and professions", "XP, reputação e profissões"),
    ("goals", "Set a gold goal or a level goal. Farol shows how much is left, and estimates how long it will take at your current pace.",
     "Gold and level goals, with a time estimate", "Metas de ouro e de nível, com estimativa de tempo"),
    ("farm", "New in version three point eight: farm goals. Click plus Goal in the loot window, or shift-click any item, and watch your count, your pace per hour, and the time left.",
     "NEW: farm goals — items to gather, pace and estimate", "NOVO: metas de farm — itens para juntar, ritmo e estimativa"),
    ("resets", "See the daily and weekly reset countdowns, your saved instances, and the gold and rested XP of all your characters.",
     "Resets, saved instances and all your characters", "Resets, instâncias salvas e todos os seus personagens"),
    ("tasks", "Keep a list of daily and weekly tasks. Tick them off as you go, and they clear on their own at the reset.",
     "Daily and weekly tasks that reset on their own", "Tarefas diárias e semanais que zeram sozinhas"),
    ("runs", "Inside a dungeon or raid, Farol logs your run: time, experience, gold, loot, and deaths. You get a short summary when you leave, and your last ten runs in one window.",
     "Dungeon and raid log: time, XP, gold, loot, deaths", "Registro de masmorras e raides: tempo, XP, ouro, saques, mortes"),
    ("bars", "Use up to three bars. Pick Bar 2 in the menu, tick Show this bar, and choose its items. Each bar has its own position, look, and order.",
     "Up to 3 bars, each with its own items and look", "Até 3 barras, cada uma com itens e aparência próprios"),
    ("appearance", "In the Appearance window, change the scale, the background, and the text and icon size, or switch to a single column. You can even hide a bar in combat.",
     "Scale, background, text, one line or one column", "Escala, fundo, texto, uma linha ou uma coluna"),
    ("profiles", "With profiles, every character can share the same bars, or have bars of its own. Copy from another character in one click, and undo it if you change your mind.",
     "Profiles — shared or per character, Copy from…", "Perfis — da conta ou por personagem, Copiar de…"),
    ("minimap", "The minimap button opens the menu with one click. Right-click it to hide or show every bar at once, and drag it anywhere around the minimap.",
     "Minimap button: menu, hide all bars, drag it around", "Botão no minimapa: menu, esconder as barras, arrastar"),
    ("alarms", "Set clock alarms, using local or server time, with a snooze button.",
     "Clock alarms with snooze", "Alarmes do relógio com soneca"),
    ("warnings", "Get warnings for low durability, full bags, unspent talent points, and low ammo or reagents, plus optional reminders to take a break and drink some water.",
     "Warnings and break & water reminders", "Avisos e lembretes de pausa e água"),
    ("loot", "The loot window keeps your recent drops, with the time you got them and a quality filter.",
     "Your recent loot, with time and quality filter", "Seus últimos saques, com horário e filtro de qualidade"),
    ("summary", "And every time you log in, you get a short summary of your last session: gold, experience, reputation, and loot.",
     "Session summary at login", "Resumo da sessão ao entrar"),
    ("safety", "Farol only reads and shows. There's no automation, and it never sends anything. It's free, open source, and available in English and Portuguese.",
     "Only reads and shows — free and open source", "Só lê e mostra — grátis e de código aberto"),
    ("outro", "Get Farol on CurseForge. Thanks for watching!",
     "Get Farol on CurseForge", "Baixe o Farol no CurseForge"),
]
# Narração traduzida (legenda em português do YouTube): uma frase para cada frase da narração em inglês.
NARRATION_PT = {
    "intro": "Conheça o Farol: uma barra de informações gratuita para o WoW Forever. Vamos dar uma volta rápida.",
    "bar": "O Farol coloca tudo o que você precisa numa barra pequena: quadros por segundo, latência, zona, durabilidade, ouro, ouro por hora e XP por hora.",
    "tip": "Passe o mouse em qualquer item para ver o tooltip curto dele. Segure Shift e você vê tudo de uma vez.",
    "menu": "Clique com o botão direito na barra para abrir o menu. Ele tem quatro abas: Barra, Avisos, Ferramentas e Geral. Marque os itens que quiser, e eles aparecem na hora.",
    "order": "Abra a janela Ordem para subir ou descer os itens e arrumar a barra do seu jeito.",
    "progress": "Acompanhe seu progresso: XP por hora e tempo até o próximo nível, reputação por hora e suas profissões, com um lembrete quando você chega ao limite do treinamento.",
    "goals": "Defina uma meta de ouro ou de nível. O Farol mostra quanto falta e estima quanto tempo vai levar no seu ritmo atual.",
    "farm": "Novo na versão 3.8: metas de farm. Clique em + Meta na janela de saques, ou dê Shift + clique em qualquer item, e acompanhe a contagem, o ritmo por hora e o tempo que falta.",
    "resets": "Veja quanto falta para os resets diário e semanal, suas instâncias salvas e o ouro e o XP descansado de todos os seus personagens.",
    "tasks": "Mantenha uma lista de tarefas diárias e semanais. Marque conforme for fazendo, e elas zeram sozinhas no reset.",
    "runs": "Dentro de uma masmorra ou raide, o Farol registra a sua corrida: tempo, experiência, ouro, saques e mortes. Você recebe um resumo curto ao sair, e suas dez últimas corridas numa janela.",
    "bars": "Use até três barras. Escolha a Barra 2 no menu, marque Mostrar esta barra e escolha os itens dela. Cada barra tem posição, aparência e ordem próprias.",
    "appearance": "Na janela Aparência, mude a escala, o fundo e o tamanho do texto e dos ícones, ou troque para uma coluna só. Dá até para esconder uma barra em combate.",
    "profiles": "Com os perfis, todos os personagens podem usar as mesmas barras, ou cada um ter as suas. Copie de outro personagem com um clique, e desfaça se mudar de ideia.",
    "minimap": "O botão no minimapa abre o menu com um clique. Clique com o botão direito para esconder ou mostrar todas as barras de uma vez, e arraste-o para qualquer lugar em volta do minimapa.",
    "alarms": "Crie alarmes do relógio, com a hora local ou do servidor, e um botão de soneca.",
    "warnings": "Receba avisos de durabilidade baixa, bolsas cheias, pontos de talento não gastos e pouca munição ou reagentes, além de lembretes opcionais para fazer uma pausa e beber água.",
    "loot": "A janela de saques guarda o que você pegou por último, com o horário e um filtro de qualidade.",
    "summary": "E toda vez que você entra, recebe um resumo curto da sua última sessão: ouro, experiência, reputação e saques.",
    "safety": "O Farol só lê e mostra. Não há automação, e ele nunca envia nada. É grátis, de código aberto, e está em inglês e português.",
    "outro": "Baixe o Farol no CurseForge. Obrigado por assistir!",
}
# Tempo mínimo de cada cena (a animação precisa disso), em segundos.
MIN_DUR = {"intro": 6, "bar": 9, "tip": 9, "menu": 9, "order": 8, "progress": 10, "goals": 9, "farm": 12, "resets": 9, "tasks": 9,
           "runs": 12, "bars": 13, "appearance": 12, "profiles": 13, "minimap": 11, "alarms": 7, "warnings": 10, "loot": 7,
           "summary": 9, "safety": 11, "outro": 8}

timing_path = os.path.join(OUT, "youtube_timing.json")
if os.path.exists(timing_path):
    timing = json.load(open(timing_path))
    durs = timing["durations"]
else:  # estimativa: ~2,5 palavras por segundo + respiro
    durs = [max(MIN_DUR[k], len(text.split()) / 2.5 + 2) for k, text, _, _ in SCENES]
starts, t = [], 0.0
for d in durs:
    starts.append(round(t, 2)); t += d
TOTAL = round(t, 2)

def items_html(lst, cls="bi"):
    return "".join(f'<span class="{cls}">{item(e, h)}</span>' for e, h in lst)
def bar(id_, lst, extra="", style=""):
    return (f'<div class="bar" id="{id_}" style="font-size:14px;gap:13px;padding:6px 12px;{style}">{items_html(lst)}{extra}</div>')
QB = '<span class="qb">📝<span class="badge r">2</span></span><span class="qb">👜<span class="badge g">3</span></span>'
GOLD = '<span class="gold">123g</span> <span class="silver">45s</span> <span class="copper">67c</span>'
B1 = [("🔭", '<span class="g">60</span> fps'), ("⚡", '<span class="g">42</span> ms'), ("🌍", '<span class="zone">Lighthouse Bay</span>'),
      ("🔨", 'Dur <span class="g">87%</span>'), ("💰", GOLD), ("📈", 'Gold/h <span class="g">+</span><span class="gold">12g</span> <span class="silver">30s</span>'),
      ("⏳", 'XP/h 18.4k · 42m')]
REP = ("🏅", 'Harbor Guild <span class="g">Honored</span> 35% <span class="g">+600/h</span>')
PROF = ("⛏️", 'Mining <span class="r">150/150</span>')
B2 = [("⏰", '20:58'), ("📜", 'Daily 5h 12m · Weekly 2d 4h'), ("⌛", 'Played 1h 02m'), ("👥", 'Friends 4'), ("🛡️", 'Guild 12')]
B3 = [("🎒", 'Bags <span class="y">8</span>/80'), ("🦴", 'Junk <span class="gold">3g</span> <span class="silver">26s</span>'),
      ("🏹", 'Ammo <span class="y">310</span>'), ("🧠", 'Mem <span class="g">35 MB</span>'), ("🗺️", '45.0, 61.0')]

def ck(id_, label, checked=False):
    return f'<div class="ck"><span class="box" id="{id_}">{"✓" if checked else ""}</span>{label}</div>'
NAMES = ["FPS", "Latency", "Zone", "Durability", "Bags", "Junk in bags", "Ammo & reagents", "Gold", "Gold per hour",
         "XP per hour", "Reputation", "Professions", "Clock", "Resets (daily/weekly)", "Friends online", "Guild online"]
GROUPS16 = [("Performance", [0, 1]), ("Location", [2]), ("Gear and bags", [3, 4, 5, 6]),
            ("Gold", [7, 8]), ("Progress", [9, 10, 11]), ("Time and social", [12, 13, 14, 15])]  # mesma ordem do addon
TABS_HTML = ('<div class="tabs"><span class="tab on">Bar</span><span class="tab">Warnings</span>'
             '<span class="tab">Tools</span><span class="tab">General</span></div>')
def menu(p, on, selected=1, profile="Account ▾"):
    groups = "".join(f'<div><div class="gh">{title}</div>{"".join(ck(f"{p}m{i}", NAMES[i], i in on) for i in idx)}</div>'
                     for title, idx in GROUPS16)
    btn = lambda n, label: f'<span class="btn{" hl" if n == selected else ""}" id="{p}b{n}" style="padding:2px 10px">{label}</span>'
    return f"""<div class="win menu" id="{p}menu" style="width:620px;padding-top:12px;padding-bottom:12px"><div class="x" id="{p}x">×</div><div class="t">Farol</div>
{TABS_HTML}
<div class="line"><span class="k">Bar:</span>{btn(1, "Bar 1")}{btn(2, "Bar 2 (off)")}{btn(3, "Bar 3 (off)")}</div>
<div class="line"><span class="k">Profile:</span><span class="btn" id="{p}prof" style="padding:2px 10px">{profile}</span><span class="btn" id="{p}copy" style="padding:2px 10px">Copy from... ▾</span></div>
<div style="display:flex;gap:40px;margin-top:4px">{ck(p + "show", "Show this bar", True)}{ck(p + "lock", "Lock position")}</div>
<div class="gcols">{groups}</div>
<div style="display:flex;gap:8px;margin-top:8px;white-space:nowrap"><span class="btn">Appearance...</span><span class="btn">Order...</span></div></div>"""
def tip(id_, title, rows, width=360, foot=""):
    body = "".join(r if r.startswith("<") else "" for r in rows)
    return f'<div class="tip" id="{id_}" style="width:{width}px"><div style="color:#33ccff;font-weight:bold;margin-bottom:4px">{title}</div>{body}{foot}</div>'
def row(k, v): return f'<div class="row"><span class="k">{k}</span><span>{v}</span></div>'
def sub(k, v): return f'<div class="row"><span>&nbsp; {k}</span><span>{v}</span></div>'
def dropdown(id_, entries):
    return f'<div class="tip dd" id="{id_}">' + "".join(f'<div id="{id_}{i}">{e}</div>' for i, e in enumerate(entries)) + '</div>'

ON1 = [0, 1, 2, 3, 7, 8, 9]
S = {}
S["intro"] = f"""<div class="center"><img class="biglogo" id="ilogo" src="data:image/png;base64,{logo}">
<div id="ititle" class="bigtitle">Farol</div><div id="isub" class="bigsub">Info bar · Alarms · Loot · Warnings — for WoW Forever</div>
<div id="isub2" class="bigsub2">Free · open source · English / Português</div></div>"""
S["bar"] = f'<div class="top">{bar("barA", B1, QB)}</div>'
S["tip"] = f"""<div class="top">{bar("barT", B1, QB)}</div>
<div class="abs" style="left:540px;top:108px">{tip("tipS", "Farol · Gold", [row("Gold", "123g 45s 67c"), row("Gold per hour", '<span class="g">+</span>12g 30s'), row("All characters", "1482g 10s")], 300, '<div class="dim" style="margin-top:6px">Hold Shift to see all information.</div>')}</div>
<div class="abs" style="left:420px;top:108px">{tip("tipF", 'Farol <span class="dim">(Shift)</span>', [row("FPS", "60"), row("Latency", "home 42 ms / world 58 ms"), row("Zone", "Lighthouse Bay · Old Mill"), row("Durability (lowest)", "87%"), row("Gold", "123g 45s 67c"), row("Gold per hour", "+12g 30s"), row("Experience", "11,040 / 24,000 (46%)"), row("XP per hour", "18.4k · next level 42m"), row("Daily reset in", "5h 12m"), row("Session", "1h 02m")], 420)}</div>
<div class="key" id="shiftkey" style="left:900px;top:330px">⇧ Shift</div>"""
S["menu"] = f"""<div class="top">{bar("barM", B1, '<span id="mx1">' + items_html([REP], "bx") + '</span><span id="mx2">' + items_html([PROF], "bx") + '</span>' + QB, "font-size:12.5px;gap:11px")}</div>
<div class="abs" style="left:330px;top:120px">{menu("M", ON1)}</div>"""
ORDER = [("🔭", "FPS"), ("⚡", "Latency"), ("🌍", "Zone"), ("🔨", "Durability"), ("💰", "Gold"), ("📈", "Gold per hour"), ("⏳", "XP per hour")]  # = ordem de B1
S["order"] = f"""<div class="top">{bar("barO", B1, QB)}</div>
<div class="abs" style="left:440px;top:120px"><div class="win" style="width:400px"><div class="x">×</div><div class="t">Bar order</div>
<div id="orows" style="position:relative;height:{len(ORDER) * 32}px">""" + "".join(
    f'<div class="orow" id="or{i}" style="top:{i * 32}px"><span><span class="dim onum">{i + 1}.</span> {ic(e)} {n}</span><span><span id="oup{i}">▲</span> <span>▼</span></span></div>'
    for i, (e, n) in enumerate(ORDER)) + """</div><div style="text-align:right;margin-top:10px"><span class="btn">Restore default order</span></div></div></div>"""
PBAR = [("📖", 'XP 46% <span class="blue">+12%</span>'), ("⏳", 'XP/h 18.4k · 42m'), REP, PROF]
S["progress"] = f"""<div class="top">{bar("barP", PBAR)}</div>
<div class="abs" style="left:390px;top:110px">{tip("tipP", "Farol", [row("Experience", "11,040 / 24,000 (46%)"), row("XP per hour", "18.4k"), row("Next level in", "42m"), '<div style="height:6px"></div>', row("Reputation", "Harbor Guild"), row("Standing", '<span class="g">Honored</span>'), row("Progress", "4.2k / 12.0k (35%)"), row("Reputation per hour", "+600"), '<div style="height:6px"></div>', row("Mining", '<span class="r">150/150</span> (+23 this session)'), '<div style="color:#ff6666;font-size:13px">&nbsp;&nbsp;&nbsp;at the training limit — find a trainer</div>', row("Cooking", "60/75")], 500)}</div>"""
S["resets"] = f"""<div class="top">{bar("barR", [("💰", GOLD), ("📜", 'Daily 5h 12m · Weekly 2d 4h')])}</div>
<div class="abs" style="left:150px;top:110px">{tip("tipG", "Farol · Gold", [row("Gold on this account", "1482g 10s"), sub("Tomas (60)", '1020g 50s <span class="dim">Today</span>'), sub("Mira (34)", '338g 15s <span class="dim">Yesterday</span>'), sub("Aldric (22)", '0g 97s <span class="dim">08/11</span>'), '<div style="height:6px"></div>', '<div class="k">Rested XP (estimate)</div>', sub("Mira (34)", '150% <span class="g">full</span>'), sub("Aldric (22)", "84% · full in ~2d 1h")], 440)}</div>
<div class="abs" style="left:640px;top:110px">{tip("tipR", "Farol · Resets", [row("Daily reset in", "5h 12m"), row("Weekly reset in", "2d 4h"), '<div style="height:6px"></div>', '<div class="k">Saved instances</div>', sub("Ember Depths", "7/10 bosses · 2d 4h"), sub("Sunken Vault", "3/4 bosses · 5h 12m"), '<div style="height:6px"></div>', '<div class="k">Your other characters</div>', sub("Tomas", "Ember Depths")], 440)}</div>"""
S["bars"] = f"""<div class="top">{bar("barB1", B1 + [REP], QB, "font-size:13px")}</div>
<div class="top2" id="bwrap2">{bar("barB2", B2)}</div>
<div class="abs" id="bwrap3" style="left:36px;top:170px"><div class="vbar">{items_html(B3)}</div></div>
<div class="abs" style="left:330px;top:160px">{menu("B", ON1 + [10])}</div>"""
def stepper(label, vid, value, minus_id, plus_id):
    return (f'<div style="display:flex;align-items:center;gap:10px;margin:7px 0"><span class="k" style="width:110px">{label}</span>'
            f'<span class="btn" id="{minus_id}" style="padding:2px 9px">-</span><span id="{vid}" style="width:52px;text-align:center">{value}</span>'
            f'<span class="btn" id="{plus_id}" style="padding:2px 9px">+</span></div>')
S["appearance"] = f"""<div class="top">{bar("barA1", B1 + [REP], QB, "font-size:13px")}</div>
<div class="top2">{bar("barA2", B2, "", "transform-origin:center top")}</div>
<div class="abs" style="left:430px;top:200px"><div class="win" style="width:430px"><div class="x">×</div><div class="t">Appearance — Bar 2</div>
{stepper("Scale:", "vscale", "100%", "sm", "sp")}{stepper("Background:", "vbg", "70%", "bm", "bp")}{stepper("Text:", "vtx", "11", "tm", "tp")}
<div style="display:flex;align-items:center;gap:10px;margin:8px 0"><span class="k" style="width:110px">Layout:</span><span class="btn hl" id="lline">One line</span><span class="btn" id="lcol">One column</span></div>
<div class="ck"><span class="box">✓</span>Show icons on the bar</div><div class="ck"><span class="box" id="acombat"></span>Hide in combat</div></div></div>"""
S["profiles"] = f"""<div class="top">{bar("barPF", B1 + B2[:2] + [REP], QB, "font-size:13px")}</div>
<div class="abs" style="left:330px;top:106px">{menu("P", ON1)}</div>
{dropdown("ddprof", ["Account (all characters)", "This character only"])}
{dropdown("ddcopy", ["Account", "Mira", "Aldric"])}
<div class="abs" id="pchat" style="left:60px;top:516px"><div class="tip chat" style="width:1160px;background:#000a;border-color:#3a3f55;font-size:13px;line-height:1.5;padding:6px 12px">
<div id="pc1"><span style="color:#33ccff">Farol:</span> this character now has its own profile (starts as a copy of the account one).</div>
<div id="pc2"><span style="color:#33ccff">Farol:</span> bars copied from Mira to the profile in use (to go back: /farol profile undo).</div></div></div>"""
S["alarms"] = f"""<div class="abs" style="left:90px;top:120px"><div class="win" style="width:470px"><div class="x">×</div><div class="t">Alarms</div>
<div class="dim" style="font-size:13px">Up to 10 alarms. Tick the box to enable.</div>
<div class="ck"><span class="box">✓</span>&nbsp;1. 07:30 (Local) Wake up</div><div class="ck"><span class="box">✓</span>&nbsp;2. 21:00 (Server) Raid</div>
<div class="ck"><span class="box"></span>&nbsp;3. 18:15 (Local) Auction house</div>
<div style="margin-top:12px;font-size:14px"><span class="k">Snooze time:</span> <span class="input">10</span> min</div></div></div>
<div class="abs" id="alarmpop" style="left:680px;top:170px"><div class="win" style="width:400px;text-align:center"><div class="t">⏰ Alarm!</div><div style="font-size:16px">21:00 (Server) Raid</div>
<div style="display:flex;justify-content:space-between;margin-top:16px"><span class="btn" id="snooze">Snooze (10 min)</span><span class="btn">Stop</span></div></div></div>"""
def wrow(text, i):
    return (f'<div class="wrow" id="w{i}" style="display:flex;align-items:center;gap:8px;margin:7px 0"><span style="flex:1;font-size:14px;white-space:nowrap">{text}</span>'
            '<span class="btn" style="padding:3px 10px;font-size:13px">Silence</span><span class="btn" style="padding:3px 10px;font-size:13px">Remind in 10 min</span></div>')
WARN = ["Low durability: 18% — time to repair!", "Your bags are almost full: 2 free slots.", "You have 2 unspent talent points.",
        "Ammo running low: 180 left.", "You've been playing for 2h 00m — time for a break?", "Time to drink some water!"]
S["warnings"] = f"""<div class="abs" style="left:250px;top:110px"><div class="win" style="width:780px"><div class="t">Warnings (6)</div>{"".join(wrow(w, i) for i, w in enumerate(WARN))}
<div style="display:flex;justify-content:space-between;margin-top:12px"><span class="btn">Silence all</span><span class="btn">Remind all in 10 min</span></div></div></div>"""
LOOT = [("q4", "🛡️", "[Helm of the Lighthouse]", "", "Today 21:42"), ("q3", "💍", "[Band of the Tides]", "", "Today 21:38"),
        ("q3", "🗡️", "[Harbor Cutlass]", "", "Today 09:30"), ("q2", "🌿", "[Meadow Bloom]", "x6", "Yesterday 22:27"),
        ("q1", "🧵", "[Linen Cloth]", "x12", "Yesterday 21:20"), ("q0", "🦴", "[Cracked Shell]", "x3", "Yesterday 21:05")]
S["loot"] = f"""<div class="abs" style="left:300px;top:110px"><div class="win" style="width:680px"><div class="x">×</div><div class="t">Recent loot</div>
<div style="display:flex;gap:10px;align-items:center;margin-bottom:10px"><span class="k">Show:</span><span class="btn">10 ▾</span><span class="k" style="margin-left:14px">Quality:</span><span class="btn">5 selected ▾</span></div>""" + "".join(
    f'<div class="row lrow" id="l{i}" style="padding:3px 0;font-size:15px"><span>{ic(e)} <span class="{q}">{n}</span> <span class="dim">{c}</span></span><span class="dim">{t}</span></div>'
    for i, (q, e, n, c, t) in enumerate(LOOT)) + "</div></div>"
SUM = ["session summary (2h 14m):", "&nbsp;&nbsp;Gold: <span class='g'>+</span><span class='gold'>38g</span> <span class='silver'>12s</span> (+17g 6s/h) · XP: +84.2k (1 level, 37.6k/h)",
       "&nbsp;&nbsp;Reputation: +1.3k Harbor Guild (<span class='g'>Honored</span> → <span style='color:#00b3ff'>Revered</span>)",
       "&nbsp;&nbsp;Loot: 46 (3 rares, 1 epic) · Warnings: 2"]
S["summary"] = f"""<div class="abs" style="left:240px;top:170px;width:800px"><div class="dim" style="margin:0 0 6px 4px;font-size:15px">Next login — your last session, only in your own chat</div>
<div class="tip chat" style="font-size:17px;line-height:1.8;background:#000a;border-color:#3a3f55">""" + "".join(
    f'<div id="s{i}"><span style="color:#33ccff">Farol:</span> {l}</div>' for i, l in enumerate(SUM)) + "</div></div>"
PILLS = ["✓ Only reads and shows · Só lê e mostra", "✓ No automation · Nada de automação", "✓ Never sends anything · Nunca envia nada",
         "✓ Free & open source (MIT) · Grátis e código aberto", "✓ English / Português"]
S["safety"] = '<div class="center" style="gap:14px">' + "".join(f'<div class="pill big" id="pl{i}">{p}</div>' for i, p in enumerate(PILLS)) + "</div>"
S["outro"] = f"""<div class="center"><div style="display:flex;align-items:center;gap:26px">
<img src="data:image/png;base64,{logo}" style="width:150px;height:150px;border-radius:14px;box-shadow:0 0 0 3px #c9a24a,0 12px 40px #000">
<div><div class="bigtitle" style="font-size:80px;margin:0">Farol</div>
<div style="font:600 28px 'Inter';color:#fff">Free on CurseForge · Grátis no CurseForge</div>
<div style="font:500 20px 'Inter';color:#9fb3cf;margin-top:6px">Open source (MIT) · English / Português</div></div></div>
<div style="font:600 24px 'Inter';color:#ffd75a;margin-top:30px">Thanks for watching! · Obrigado por assistir!</div>
<div style="font:500 15px 'Inter';color:#9fb3cf;margin-top:20px">Unofficial add-on for WoW Forever · not affiliated with Blizzard Entertainment · Illustration, not gameplay footage</div></div>"""

# Metas de ouro e de nível
GOAL_ITEM = ("🎯", '<span id="gog">Goal 500g <span class="y">44%</span> ~27m</span><span id="gol"> · Lv 40 <span class="y">36%</span> ~6h 10m</span>')
def goal_row(label, vid, value, sid, status):
    return (f'<div style="display:flex;align-items:center;gap:10px;margin:8px 0"><span class="k" style="width:64px">{label}</span>'
            f'<span class="input" id="{vid}" style="min-width:80px;height:24px;line-height:18px">{value}</span><span class="btn" id="{sid}">Set</span><span class="btn">Clear</span></div>'
            f'<div class="dim" style="font-size:13px;margin:-2px 0 6px 74px" id="{sid}st">{status}</div>')
S["goals"] = f"""<div class="top">{bar("barGo", B1[:2] + [B1[4], B1[6], GOAL_ITEM], QB, "font-size:13px")}</div>
<div class="abs" style="left:90px;top:150px"><div class="win" style="width:470px"><div class="x">×</div><div class="t">Goals</div>
<div class="dim" style="font-size:13px">Pick a goal; the bar shows how much is left and an estimate from this session's pace.</div>
{goal_row("Gold:", "gv", "", "gs", "223g of 500g (44%) · ~27m")}{goal_row("Level:", "lv", "", "ls", "34 of 40 (36%) · ~6h 10m")}
<div class="ck" style="margin-top:10px"><span class="box">✓</span>Warn when a goal is reached (gold, level or farm)</div></div></div>
<div class="abs" style="left:640px;top:150px">{tip("tipGo", "Farol · Goals", [row("Gold 500g", "223g of 500g (44%)"), '<div class="dim" style="font-size:13px">&nbsp;&nbsp;&nbsp;estimate: ~27m (around 22:41) · pace 600g per hour</div>', '<div style="height:6px"></div>', row("Level 40", "34 of 40 (36%)"), '<div class="dim" style="font-size:13px">&nbsp;&nbsp;&nbsp;estimate: ~6h 10m · pace 18.4k XP per hour</div>'], 520)}</div>"""
# Metas de farm (3.8)
FARM_ITEM = ("🧵", 'Silk Cloth <span class="y" id="fcnt">27/40</span>')
FLOOT = [("q1", "🧵", "[Silk Cloth]", "x3", "Today 21:44"), ("q1", "⛏️", "[Iron Ore]", "x2", "Today 21:40"), ("q2", "🌿", "[Meadow Bloom]", "x4", "Today 21:31")]
S["farm"] = f"""<div class="top">{bar("barF", B1[:2] + [B1[4], B1[6]], '<span id="fitem">' + items_html([FARM_ITEM], "bx") + '</span>' + QB, "font-size:13px")}</div>
<div class="abs" style="left:70px;top:150px"><div class="win" style="width:600px"><div class="x">×</div><div class="t">Recent loot</div>""" + "".join(
    f'<div class="row" style="padding:4px 0;font-size:15px;align-items:center"><span>{ic(e)} <span class="{q}">{n}</span> <span class="dim">{c}</span></span>'
    f'<span><span class="dim">{t}</span>&nbsp;&nbsp;<span class="btn" id="fb{i}" style="padding:1px 8px;font-size:12px">+ Goal</span></span></div>'
    for i, (q, e, n, c, t) in enumerate(FLOOT)) + f"""<div class="dim" style="font-size:12px;margin-top:8px">+ Goal: track the item (farm goal)</div></div></div>
<div class="abs" style="left:720px;top:150px">{tip("tipF2", "Farol · Farm (item goals)", [row("Silk Cloth", '<span class="y" id="ftcnt">27/40</span>'), '<div class="dim" style="font-size:13px" id="fpace">&nbsp;&nbsp;&nbsp;no pace yet this session</div>', row("Iron Ore", '<span class="g">20/20</span>'), '<div class="dim" style="font-size:12px;margin-top:6px">counts bags + bank (when the game reports it)</div>'], 470)}</div>
<div class="abs" id="fchat" style="left:70px;top:430px"><div class="tip chat" style="width:600px;background:#000a;border-color:#3a3f55;font-size:14px;padding:6px 12px">
<span style="color:#33ccff">Farol:</span> farm goal: Silk Cloth 27/20 — change it with /farol goal item</div></div>
<div id="newbadge2" class="nb">NEW · NOVO 3.8</div>"""
# Tarefas
TASKS = [("Fishing daily", "daily", True), ("Cooking daily", "daily", False), ("Sell on the auction house", "daily", False), ("Harbor Crypt", "weekly", False)]
S["tasks"] = f"""<div class="top">{bar("barTk", B1[:3] + [("📋", 'Tasks <span class="y" id="tkcnt">1/4</span>'), ("📜", 'Daily 5h 12m · Weekly 2d 4h')], QB, "font-size:13px")}</div>
<div class="abs" style="left:380px;top:150px"><div class="win" style="width:520px"><div class="x">×</div><div class="t">Tasks</div>
<div class="dim" style="font-size:12px;margin-bottom:6px">Tick what you have done. Daily tasks reset at the daily reset; weekly, at the weekly one.</div>""" + "".join(
    f'<div class="ck" style="justify-content:space-between"><span><span class="box" id="tb{i}">{"✓" if d else ""}</span>&nbsp;<span id="tn{i}" class="{"g" if d else ""}">{n}</span></span>'
    f'<span><span class="dim" style="font-size:12px">{k}</span>&nbsp;&nbsp;<span class="btn" style="padding:1px 7px">X</span></span></div>'
    for i, (n, k, d) in enumerate(TASKS)) + """<div style="display:flex;gap:8px;align-items:center;margin-top:12px"><span class="input" style="min-width:220px;text-align:left;color:#aaa">new task…</span><span class="btn">Weekly</span><span class="btn">Add</span></div>
<div class="dim" style="font-size:12px;margin-top:8px">Daily reset in 5h 12m · weekly in 2d 4h</div></div></div>"""
# Masmorras e raides
RUN_ITEM = ("🗝️", '<span class="zone">Ember Depths</span> 18m · <span class="blue">+4.2k XP</span> · <span class="g">+</span><span class="gold">12g</span>')
RUNS = [("Today 21:42", "Ember Depths", "32m", "+6.8k", "+18g 40s", "14", '<span class="q4">1 epic</span>', "1"),
        ("Today 19:05", "Sunken Vault", "48m", "+9.9k", "+25g 10s", "21", '<span class="q3">2 rares</span>', "2"),
        ("Yesterday", "Harbor Crypt", "27m", "+5.2k", "+9g 80s", "10", "", ""),
        ("Nov 13", "Lighthouse Caverns", "1h 12m", "+14.6k", "+41g 20s", "33", '<span class="q3">3 rares</span>', "1")]
S["runs"] = f"""<div class="top">{bar("barRn", B1[:2] + [("🔨", 'Dur <span class="y">54%</span>'), ("⏳", 'XP/h 14.0k · 1h 05m'), RUN_ITEM], QB, "font-size:13px")}</div>
<div class="abs" id="rsum" style="left:110px;top:130px"><div class="tip chat" style="width:1060px;font-size:15px;line-height:1.7;background:#000a;border-color:#3a3f55">
<div><span style="color:#33ccff">Farol:</span> left <span class="zone">Ember Depths</span> (dungeon): <b>32m</b></div>
<div><span style="color:#33ccff">Farol:</span> &nbsp;XP: <span class="blue">+6.8k</span> · Gold: <span class="g">+</span><span class="gold">18g</span> <span class="silver">40s</span> · Loot: 14 (<span class="q3">2 rares</span>, <span class="q4">1 epic</span>) · Deaths: 1</div></div></div>
<div class="abs" id="rwin" style="left:280px;top:240px"><div class="win" style="width:720px"><div class="x">×</div><div class="t">Dungeons and raids</div>
<div class="rrow head"><span>When</span><span>Instance</span><span>Time</span><span>XP</span><span>Gold</span><span>Loot</span><span>Deaths</span></div>""" + "".join(
    f'<div class="rrow" id="rr{i}"><span class="dim">{d}</span><span class="zone">{n}</span><span>{t}</span><span class="blue">{x}</span><span>{g}</span><span>{l} {q}</span><span class="r">{m}</span></div>'
    for i, (d, n, t, x, g, l, q, m) in enumerate(RUNS)) + """<div class="ck" style="margin-top:8px"><span class="box">✓</span>Show the summary in chat when leaving</div></div></div>"""
# Botão do minimapa
S["minimap"] = f"""<div class="top" id="mmb1">{bar("barMm1", B1, QB, "font-size:13px")}</div>
<div class="top2" id="mmb2">{bar("barMm2", B2)}</div>
<div class="abs" id="mmmap" style="left:930px;top:250px;width:220px;height:220px;border-radius:50%;background:radial-gradient(circle at 40% 35%,#5b7a3a,#2f4a22 60%,#1b2c14);box-shadow:0 0 0 7px #2a2a2a,0 0 0 11px #8a7440,0 10px 36px #000">
<div style="position:absolute;left:101px;top:101px;width:18px;height:18px;background:#ffd75a;clip-path:polygon(50% 0,100% 100%,50% 75%,0 100%)"></div>
<div style="position:absolute;left:40px;top:150px;width:90px;height:4px;background:#c9b26a99;transform:rotate(-20deg)"></div>
<div style="position:absolute;left:135px;top:40px;width:4px;height:80px;background:#c9b26a99"></div></div>
<div class="abs" id="mmbtn" style="width:40px;height:40px;border-radius:50%;background:#111;box-shadow:0 0 0 3px #c9a24a,0 3px 10px #000;display:flex;align-items:center;justify-content:center;z-index:5">
<img src="data:image/png;base64,{logo}" style="width:28px;height:28px;border-radius:50%"></div>
<div class="abs" id="mmtip" style="left:560px;top:250px">{tip("mmtipin", "Farol", ['<div>Click: open the menu</div>', '<div>Right-click: show/hide the bars</div>', '<div>Shift-click: warnings</div>', '<div class="dim">Drag to move it around the minimap</div>'], 330)}</div>
<div class="abs" id="mmchat" style="left:60px;top:516px"><div class="tip chat" style="width:820px;background:#000a;border-color:#3a3f55;font-size:14px;padding:6px 12px">
<div id="mmc1"><span style="color:#33ccff">Farol:</span> bars hidden until you show them again (right-click the minimap button or /farol).</div>
<div id="mmc2"><span style="color:#33ccff">Farol:</span> bars shown again.</div></div></div>"""

EXTRA = """
.scene{position:absolute;left:0;top:0;width:1280px;height:720px}
.center{position:absolute;left:0;right:0;top:0;bottom:150px;display:flex;flex-direction:column;align-items:center;justify-content:center}
.abs{position:absolute}
.top{position:absolute;left:0;right:0;top:66px;display:flex;justify-content:center}
.top2{position:absolute;left:0;right:0;top:112px;display:flex;justify-content:center}
.capx{position:absolute;left:60px;right:60px;bottom:34px}
.capx h1{font-family:'Inter',sans-serif;font-weight:800;font-size:36px;color:#ffd75a;text-shadow:0 2px 8px #000;white-space:nowrap}
.capx h2{font-family:'Inter',sans-serif;font-weight:500;font-size:25px;color:#d9e4f2;margin-top:6px;text-shadow:0 2px 6px #000}
.capbg{position:absolute;left:0;right:0;bottom:0;height:150px;background:linear-gradient(180deg,#0000,#000c 35%)}
.bi,.bx{display:inline-flex}
.bar,.vbar{white-space:nowrap}
.menu .ck{margin:1px 0}
.tabs{display:flex;gap:4px;border-bottom:2px solid #6e5b2e;margin:0 0 6px}
.tab{font:bold 13px 'DejaVu Sans';color:#c9b88a;padding:4px 14px;border:1px solid #6e5b2e;border-bottom:none;border-radius:6px 6px 0 0;background:#1a1a22}
.tab.on{color:#ffd100;background:#3a2a10;box-shadow:inset 0 2px 0 #ffd100}
.gcols{display:grid;grid-template-columns:repeat(3,1fr);gap:2px 14px}
.gh{color:#ffd100;font-weight:bold;font-size:13px;margin:6px 0 1px;border-bottom:1px solid #6e5b2e55}
.gcols .ck{font-size:13px;margin:1px 0}.gcols .box{width:16px;height:16px;font-size:12px}

.line{display:flex;gap:8px;align-items:center;margin-top:6px}.line .k{font-size:14px;width:58px}
.biglogo{width:170px;height:170px;border-radius:16px;box-shadow:0 0 0 3px #c9a24a,0 12px 50px #000}
.bigtitle{font:800 88px 'Inter';color:#ffd75a;text-shadow:0 4px 16px #000;margin-top:18px}
.bigsub{font:500 26px 'Inter';color:#d9e4f2}.bigsub2{font:500 20px 'Inter';color:#9fb3cf;margin-top:8px}
.key{position:absolute;z-index:40;font:700 18px 'Inter';color:#111;background:#e8e8e8;border-radius:6px;padding:6px 14px;box-shadow:0 3px 0 #888,0 6px 18px #000a}
.dd{position:absolute;font-size:14px;line-height:1.9;z-index:30;background:#0a0d1a;min-width:200px}
.dd div{padding:0 8px;border-radius:3px}
.orow{position:absolute;left:0;right:0;display:flex;justify-content:space-between;align-items:center;font-size:15px;height:30px}
.onum{display:inline-block;width:22px;text-align:right}
.nb{position:absolute;font:800 13px 'Inter';color:#111;background:#ffd75a;border-radius:999px;padding:4px 10px;box-shadow:0 0 12px #ffd75a;left:1030px;top:120px}
.rrow{display:grid;grid-template-columns:90px 160px 60px 62px 84px 140px 50px;gap:6px;font-size:14px;padding:3px 0;border-bottom:1px solid #ffffff10}
.rrow.head{color:#ffd100;font-weight:bold;font-size:13px}
#newbadge{position:absolute;font:800 13px 'Inter';color:#111;background:#ffd75a;border-radius:999px;padding:4px 10px;box-shadow:0 0 12px #ffd75a;left:648px;top:242px}
.pill{font:600 18px 'Inter';color:#fff;background:#0007;border:1px solid #c9a24a88;border-radius:999px;padding:8px 18px}
.pill.big{font-size:24px;padding:10px 26px}
#cursor{position:absolute;width:26px;height:34px;z-index:50;pointer-events:none}
#ring{position:absolute;width:44px;height:44px;border-radius:50%;border:3px solid #ffd75a;z-index:49;pointer-events:none}
"""
scenes_html = "".join(f'<div class="scene" id="sc_{k}">{S[k]}<div class="capx"><h1>{en}</h1><h2>{pt}</h2></div></div>'
                      for k, _, en, pt in SCENES)
html = f"""<!doctype html><html><head><meta charset="utf-8"><style>{CSS}{EXTRA}</style></head><body>
<div class="stars"></div><div class="capbg"></div>
<div class="brand" id="brand"><img src="data:image/png;base64,{logo}">Farol</div>
<div class="tag">Illustration · Ilustração</div>
{scenes_html}
<div id="ring"></div>
<svg id="cursor" viewBox="0 0 26 34"><path d="M2 2 L2 28 L9 21 L14 32 L18 30 L13 19 L23 19 Z" fill="#fff" stroke="#000" stroke-width="2" stroke-linejoin="round"/></svg>
<script>const SCENES = {json.dumps([{"key": k, "start": s, "dur": d} for (k, _, _, _), s, d in zip(SCENES, starts, durs)])};
const TOTAL = {TOTAL};</script>
<script src="youtube.js"></script></body></html>"""
open(os.path.join(OUT, "youtube.html"), "w", encoding="utf-8").write(html)
open(os.path.join(OUT, "youtube_script.txt"), "w", encoding="utf-8").write("\n\n".join(t for _, t, _, _ in SCENES) + "\n")
print(f"youtube.html ok — {len(SCENES)} cenas, {TOTAL:.1f} s")
