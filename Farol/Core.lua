--[[
  Farol — barra de informações para WoW Forever (não oficial, não afiliado à Blizzard)
  Painel na tela com FPS, latência, memória, coordenadas, zona, velocidade, durabilidade, bolsas,
  ouro, ouro da sessão, XP, horário, tempo de sessão, amigos e guilda — você escolhe o que aparece.
  On-screen info bar with selectable items. (PT / EN)

  Princípios de segurança deste addon:
    * Não usa loadstring/RunScript nem executa código vindo de chat, arquivos ou outros jogadores.
    * Não envia nem recebe mensagens de addon (SendAddonMessage) — nenhum dado sai do seu cliente.
    * Não automatiza ações de jogo (nada de bot); apenas LÊ informações e as mostra.
    * Só grava posição, idioma e itens visíveis em SavedVariables, e valida esses dados ao carregar.
    * Cada leitura de dados é isolada (pcall): se o jogo bloquear algo, aparece "--", nunca um erro.
]]

local ADDON_NAME, ns = ... -- ns: tabela compartilhada com Alarm.lua
local ICON = "|TInterface\\AddOns\\Farol\\Media\\Farol:16:16|t" -- ícone do addon (Media/Farol.tga)
local PREFIX = "|cff33ccffFarol|r: "
local UPDATE_INTERVAL = 0.5 -- segundos entre atualizações do painel

-- Itens da barra, na ordem em que aparecem.
local ITEM_ORDER = {
    "fps", "ms", "mem", "coords", "zone", "speed", "durab", "bags", "junk", "ammo",
    "gold", "session", "goldh", "xp", "xph", "rep", "prof", "clock", "reset", "playtime", "friends", "guild",
}

-- Visível por padrão? Os itens originais vêm ligados; os novos, desligados (ative no menu).
local ITEM_DEFAULTS = {
    fps = true, ms = true, coords = true, zone = true, durab = true, gold = true,
    mem = false, speed = false, bags = false, session = false, xp = false,
    goldh = false, xph = false, rep = false, prof = false, junk = false, ammo = false,
    clock = false, reset = false, playtime = false, friends = false, guild = false,
}

-- Nomes aceitos nos comandos /farol show|hide (português e inglês).
local ITEM_ALIASES = {
    fps = "fps",
    ms = "ms", ping = "ms", latencia = "ms", latency = "ms",
    mem = "mem", memoria = "mem", memory = "mem",
    coords = "coords", coord = "coords", coordenadas = "coords", coordinates = "coords",
    zona = "zone", zone = "zone",
    vel = "speed", velocidade = "speed", speed = "speed",
    durab = "durab", dur = "durab", durabilidade = "durab", durability = "durab",
    bolsas = "bags", bags = "bags", bolsa = "bags", bag = "bags",
    ouro = "gold", gold = "gold",
    sessao = "session", session = "session",
    xph = "xph", xphora = "xph", xpperhour = "xph",
    ouroh = "goldh", ourohora = "goldh", goldh = "goldh", goldperhour = "goldh",
    rep = "rep", reputacao = "rep", reputation = "rep", faccao = "rep", faction = "rep",
    prof = "prof", profissao = "prof", profissoes = "prof", profession = "prof", professions = "prof",
    lixo = "junk", junk = "junk", cinza = "junk", cinzas = "junk", gray = "junk", grey = "junk",
    municao = "ammo", ammo = "ammo", reagentes = "ammo", reagents = "ammo", reagente = "ammo",
    xp = "xp", experiencia = "xp", experience = "xp",
    hora = "clock", horario = "clock", relogio = "clock", clock = "clock", time = "clock",
    reset = "reset", resets = "reset", reinicio = "reset",
    tempo = "playtime", playtime = "playtime", played = "playtime",
    amigos = "friends", friends = "friends",
    guilda = "guild", guild = "guild",
}

local DEFAULTS = {
    shown = true,
    locked = false,
    point = "TOP",
    relPoint = "TOP",
    x = 0,
    y = -20,
    lang = "auto", -- "auto" (segue o idioma do cliente), "pt" ou "en"
    serverTime = false, -- relógio mostra o horário do servidor em vez do local
    summary = true,     -- mostrar o resumo da última sessão ao entrar no jogo
    goldTotal = false,  -- item Ouro mostra também o total de todos os seus personagens do reino
    tooltipFull = false, -- false = cada item mostra só o seu tooltip (Shift mostra tudo); true = sempre completo
    newsSeen = 0,       -- quantas novidades (NEWS) o jogador já viu; boas-vindas/novidades aparecem uma vez
    snoozeMinutes = 5,  -- duração da soneca dos alarmes (1 a 60)
    -- Aparência
    scale = 1,              -- escala da barra (0.5 a 2)
    bgAlpha = 0.7,          -- opacidade do fundo (0 a 1)
    border = true,          -- mostrar a borda
    barWidth = 0,           -- largura máxima escolhida pelo jogador (0 = tudo em uma linha; 1 = uma coluna)
    hideCombat = false,     -- esconder em combate
    hideInstance = false,   -- esconder em masmorras, raides, arenas e campos de batalha
    icons = true,           -- ícone antes de cada informação da barra
    warnButton = true,      -- botão do histórico de avisos ao lado da barra
    lootButton = true,      -- botão da janela de saques ao lado da barra
    fontSize = 11,          -- tamanho do texto da barra (8 a 24)
    iconSize = 14,          -- tamanho dos ícones da barra e dos botões ao lado (10 a 32)
}

local VALID_LANGS = { auto = true, pt = true, en = true }

---------------------------------------------------------------------------
-- Textos / Strings (Português e English)
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        help_title   = "comandos:",
        help_toggle  = "  /farol               - mostrar/ocultar o painel",
        help_lock    = "  /farol lock          - travar/destravar o painel (arraste com o botão esquerdo)",
        help_reset   = "  /farol reset         - voltar o painel à posição padrão",
        help_show    = "  /farol show <item>   - mostrar um item na barra",
        help_hide    = "  /farol hide <item>   - esconder um item da barra",
        help_items   = "  /farol itens         - listar os itens e o que está visível",
        help_version = "  /farol version       - mostrar a versão do cliente e o número de Interface",
        help_lang    = "  /farol lang pt||en||auto - escolher o idioma (auto = idioma do cliente)",
        shown        = "painel visível.",
        hidden       = "painel oculto.",
        locked       = "painel travado.",
        unlocked     = "painel destravado — arraste para mover.",
        reset        = "posição restaurada.",
        version      = "cliente %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use esse número na linha '## Interface:' do arquivo .toc.",
        lang_set     = "idioma: Português.",
        lang_auto    = "idioma: automático (segue o cliente).",
        lang_usage   = "uso: /farol lang pt || en || auto",
        item_usage   = "uso: /farol show||hide",
        item_on      = "%s: |cff00ff00visível|r",
        item_off     = "%s: |cffff3333escondido|r",
        items_title  = "itens da barra:",
        none_shown   = "Farol — /farol show <item>",
        name_fps = "FPS",              cmd_fps = "fps",
        name_ms = "Latência",          cmd_ms = "ms",
        name_mem = "Memória",          cmd_mem = "mem",
        name_coords = "Coordenadas",   cmd_coords = "coords",
        name_zone = "Zona",            cmd_zone = "zona",
        name_speed = "Velocidade",     cmd_speed = "vel",
        name_durab = "Durabilidade",   cmd_durab = "durab",
        name_bags = "Bolsas",          cmd_bags = "bolsas",
        name_gold = "Ouro",            cmd_gold = "ouro",
        name_session = "Ouro da sessão", cmd_session = "sessao",
        name_goldh = "Ouro por hora",  cmd_goldh = "ouroh",
        name_xph = "XP por hora",      cmd_xph = "xph",
        name_rep = "Reputação",        cmd_rep = "rep",
        name_prof = "Profissões",      cmd_prof = "prof",
        name_junk = "Lixo nas bolsas", cmd_junk = "lixo",
        name_ammo = "Munição e reagentes", cmd_ammo = "municao",
        name_xp = "Experiência (XP)",  cmd_xp = "xp",
        name_clock = "Horário",        cmd_clock = "hora",
        name_reset = "Resets (diário/semanal)", cmd_reset = "reset",
        name_playtime = "Tempo de sessão", cmd_playtime = "tempo",
        name_friends = "Amigos online", cmd_friends = "amigos",
        name_guild = "Guilda online",  cmd_guild = "guilda",
        label_durab  = "Dur",
        label_mem    = "Mem",
        label_speed  = "Vel",
        label_bags   = "Bolsas",
        label_session = "Sessão",
        label_goldh  = "Ouro/h",
        label_xph    = "XP/h",
        label_rep    = "Rep",
        label_prof   = "Prof",
        label_junk   = "Lixo",
        label_ammo   = "Munição",
        sup_ammo     = "Munição",
        sup_shard    = "Fragmentos",
        sup_powder   = "Pó Arcano",
        sup_runes    = "Runas",
        sup_candle   = "Velas",
        sup_symbol   = "Símbolos",
        sup_seed     = "Sementes",
        sup_gift     = "Dádiva",
        sup_ankh     = "Ankhs",
        sup_flash    = "Pó de Lampejo",
        sup_blind    = "Pó Cegante",
        tt_supply    = "Munição e reagentes",
        tt_supply_limits = "Amarelo / vermelho abaixo de",
        tt_supply_hint = "Reabasteça num vendedor (o Farol só conta, nunca compra).",
        tt_supply_none = "nenhum reagente acompanhado para a sua classe ainda",
        label_playtime = "Jogando",
        label_reset  = "Reset",
        label_reset_daily = "Diário",
        label_reset_weekly = "Semanal",
        label_friends = "Amigos",
        label_guild  = "Guilda",
        opt_servertime = "Horário do servidor",
        opt_summary  = "Resumo da sessão ao entrar",
        opt_goldtotal = "Ouro de todos os personagens na barra",
        opt_forget   = "Esquecer personagens",
        opt_forget_confirm = "Clique de novo para confirmar",
        label_gold_total = "Total %s",
        tt_gold_total = "Ouro na conta (%s)",
        tt_gold_this = "este",
        tt_rest_title = "Descanso dos seus personagens (estimativa)",
        tt_locks     = "Instâncias salvas",
        tt_locks_none = "nenhuma",
        tt_locks_wait = "carregando...",
        tt_locks_bosses = "%d/%d chefes",
        tt_locks_reset = "reset em %s",
        tt_locks_alts = "Instâncias salvas dos seus personagens",
        locks_title  = "instâncias salvas deste personagem:",
        locks_none   = "este personagem não está salvo em nenhuma instância.",
        locks_alts   = "outros personagens deste reino:",
        locks_status = "instâncias salvas: %d (função: %s).",
        help_locks   = "  /farol instancias    - instâncias salvas (bloqueios de raide) deste e dos outros personagens",
        tt_rest_full = "cheio",
        tt_rest_eta  = "cheio em ~%s",
        tt_rest_inn  = "estalagem/cidade",
        tt_rest_out  = "fora",
        gold_forgot  = "personagem esquecido: %s.",
        gold_forgot_all = "%d personagem(ns) deste reino esquecido(s) (o atual continua).",
        gold_forget_self = "não dá para esquecer o personagem em que você está.",
        gold_not_found = "personagem não encontrado neste reino: %s.",
        gold_list    = "ouro dos seus personagens em %s (total %s):",
        gold_total_on = "total de ouro na barra: ligado.",
        gold_total_off = "total de ouro na barra: desligado.",
        help_gold    = "  /farol ouro [total on||off || esquecer Nome] - ouro de todos os seus personagens do reino",
        sum_title    = "resumo da sessão (%s):",
        sum_last     = "última sessão (%s, %s):",
        sum_gold     = "Ouro: %s",
        sum_xp       = "XP: +%s",
        sum_level1   = "1 nível",
        sum_levels   = "%d níveis",
        sum_rep      = "Reputação: +%s %s",
        sum_loot     = "Saques: %d",
        sum_rare1    = "1 raro",
        sum_rares    = "%d raros",
        sum_epic1    = "1 épico",
        sum_epics    = "%d épicos",
        sum_legend1  = "1 lendário",
        sum_legends  = "%d lendários",
        sum_warns    = "Avisos: %d",
        sum_on       = "resumo da sessão ao entrar: ligado.",
        sum_off      = "resumo da sessão ao entrar: desligado.",
        help_summary = "  /farol resumo [on||off] - resumo da sessão atual (ou ligar/desligar o resumo ao entrar)",
        tt_mem       = "Memória Lua (interface + addons)",
        tt_speed     = "Velocidade",
        tt_bags      = "Bolsas (livres / total)",
        tt_session   = "Ouro na sessão",
        tt_goldh     = "Ouro por hora",
        tt_xph       = "XP por hora",
        tt_tolevel   = "Próximo nível em",
        tt_rep       = "Reputação",
        tt_rep_standing = "Nível",
        tt_rep_progress = "Progresso",
        tt_rep_rate  = "Reputação por hora",
        tt_rep_next  = "Próximo nível em",
        tt_rep_none  = "nenhuma facção acompanhada (marque 'Mostrar como barra de experiência' no painel de reputação)",
        tt_prof      = "Profissões",
        tt_junk      = "Lixo nas bolsas (valor de venda)",
        tt_junk_slots = "Espaços ocupados por lixo",
        tt_junk_pending = "carregando informações de %d item(ns)...",
        tt_junk_hint = "Venda no comerciante (o Farol só mostra, nunca vende).",
        junk_status  = "lixo nas bolsas: %s em %d espaço(s) (função: %s).",
        tt_prof_none = "nenhuma profissão aprendida",
        tt_prof_gain = " (+%d nesta sessão)",
        tt_prof_cap  = "no máximo do treinamento — procure um instrutor",
        prof_status  = "profissões: %s (função: %s).",
        prof_status_none = "profissões: nenhuma encontrada (função: %s).",
        rep_status   = "reputação: %s (função: %s).",
        rep_status_none = "reputação: nenhuma facção acompanhada.",
        tt_reset_daily  = "Reset diário em",
        tt_reset_weekly = "Reset semanal em",
        tt_reset_at     = "%s (%s local · %s servidor)",
        tt_reset_none   = "o jogo não informou",
        reset_status    = "resets: diário %s (função: %s) · semanal %s (função: %s).",
        weekdays        = "dom,seg,ter,qua,qui,sex,sáb",
        weekdays_long   = "domingo,segunda-feira,terça-feira,quarta-feira,quinta-feira,sexta-feira,sábado",
        months          = "jan,fev,mar,abr,mai,jun,jul,ago,set,out,nov,dez",
        when_today      = "Hoje",
        when_yesterday  = "Ontem",
        when_date       = "DD/MM",
        when_date_year  = "DD/MM/YY",
        when_long       = "WEEKDAY, DD/MM/YYYY às HH:MI",
        tt_rate_wait = "calculando... (1 min)",
        session_reset = "sessão zerada: ouro, XP e tempo recomeçam agora.",
        help_session = "  /farol sessao zerar  - recomeçar a contagem de ouro, XP e tempo da sessão",
        opt_session_reset = "Zerar sessão",
        tt_xp        = "Experiência",
        tt_rested    = "Descansado",
        tt_maxlevel  = "Nível máximo",
        tt_clock_local  = "Hora local",
        tt_clock_server = "Hora do servidor",
        tt_playtime  = "Tempo de sessão",
        tt_friends   = "Amigos online",
        tt_friends_value = "WoW %d / Battle.net %d",
        tt_guild     = "Guilda online",
        tt_noguild   = "Sem guilda",
        tt_latency   = "Latência",
        tt_lat_value = "local %d ms / mundo %d ms",
        tt_coords    = "Coordenadas",
        tt_zone      = "Zona",
        tt_subzone   = "Subzona",
        tt_durab     = "Durabilidade (menor peça)",
        tt_all_ok    = "Todo o equipamento está 100%.",
        tt_no_gear   = "Nenhum item com durabilidade equipado.",
        tt_gold      = "Ouro",
        tt_drag      = "Arraste para mover.",
        tt_locked    = "Painel travado (/farol lock).",
        tt_help      = "/farol ajuda — lista de comandos",
        tt_slot      = "Espaço %d",
        help_menu    = "  /farol menu          - abrir o menu de opções (ou clique direito no painel)",
        opt_items    = "Itens da barra",
        opt_general  = "Geral",
        opt_shown    = "Mostrar painel",
        opt_locked   = "Travar posição",
        opt_lang     = "Idioma",
        opt_reset    = "Resetar posição",
        opt_alarms   = "Alarmes...",
        opt_hint     = "Marque o que deseja ver na barra.",
        opt_hint_count = "Itens na barra: %d de %d ligados — marque os que quiser (passe o mouse para ver o que cada um mostra).",
        tt_rightclick_more = "Clique direito: opções (mais %d informações para ligar).",
        tt_shift_full = "Segure Shift para ver todas as informações.",
        tt_more      = "e mais %d",
        welcome1     = "bem-vindo! A barra começa só com o básico: %s.",
        welcome2     = "há mais %d informações e vários avisos desligados — clique com o botão direito na barra para escolher (ou /farol menu). /farol ajuda lista os comandos.",
        news_title   = "novidades desde a sua última versão (a maioria vem desligada — ative no menu: clique direito na barra):",
        news_rep     = "reputação na barra",
        news_reset   = "contagem até os resets",
        news_lootdates = "datas na janela de saques",
        news_summary = "resumo da sessão (/farol resumo)",
        news_breaks  = "lembretes de pausa e de água",
        news_remind  = "\"Lembrar em\" de 2 a 30 min",
        news_prof    = "profissões e aviso de instrutor",
        news_junk    = "valor do lixo nas bolsas",
        news_alts    = "ouro de todos os personagens (/farol ouro)",
        news_rested  = "descanso dos seus personagens",
        news_locks   = "instâncias salvas (/farol instancias)",
        news_tooltip = "tooltip menor: cada item mostra só o seu (Shift mostra tudo)",
        news_supply  = "munição e reagentes, com limites que você escolhe",
        help_news    = "  /farol novidades     - ver de novo as novidades das últimas versões",
        desc_fps      = "Quadros por segundo (verde 50+, amarelo 25+).",
        desc_ms       = "Latência: a maior entre local e mundo.",
        desc_mem      = "Memória Lua usada pela interface e addons.",
        desc_coords   = "Sua posição no mapa (some em instâncias).",
        desc_zone     = "Nome da zona atual.",
        desc_speed    = "Velocidade de movimento (100% = correr normal).",
        desc_durab    = "Sua peça mais gasta (vermelho abaixo de 20%).",
        desc_bags     = "Espaços livres / total nas bolsas.",
        desc_junk     = "Valor de venda dos itens cinzentos (o Farol nunca vende).",
        desc_ammo     = "Munição e reagentes da sua classe; cores pelos limites da janela de Avisos.",
        desc_gold     = "Seu ouro (e, opcional, o total dos seus personagens).",
        desc_session  = "Ouro ganho ou gasto desde que você entrou.",
        desc_goldh    = "Ouro da sessão por hora.",
        desc_xp       = "Porcentagem de XP e bônus descansado.",
        desc_xph      = "XP por hora e tempo até o próximo nível.",
        desc_rep      = "Facção acompanhada: nível, progresso e rep/hora.",
        desc_prof     = "Profissões com nível / limite do treinamento.",
        desc_clock    = "Hora local ou do servidor (alarmes ficam aqui).",
        desc_reset    = "Tempo até o reset diário e o semanal.",
        desc_playtime = "Quanto tempo você está jogando nesta sessão.",
        desc_friends  = "Quantos amigos estão online (sem nomes).",
        desc_guild    = "Quantos membros da guilda estão online (sem nomes).",
        tt_rightclick = "Clique direito: opções.",
    },
    en = {
        help_title   = "commands:",
        help_toggle  = "  /farol               - show/hide the panel",
        help_lock    = "  /farol lock          - lock/unlock the panel (drag with left mouse button)",
        help_reset   = "  /farol reset         - move the panel back to its default position",
        help_show    = "  /farol show <item>   - show an item on the bar",
        help_hide    = "  /farol hide <item>   - hide an item from the bar",
        help_items   = "  /farol items         - list items and which are visible",
        help_version = "  /farol version       - show the client version and Interface number",
        help_lang    = "  /farol lang pt||en||auto - choose the language (auto = client language)",
        shown        = "panel shown.",
        hidden       = "panel hidden.",
        locked       = "panel locked.",
        unlocked     = "panel unlocked — drag to move.",
        reset        = "position restored.",
        version      = "client %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use this number on the '## Interface:' line of the .toc file.",
        lang_set     = "language: English.",
        lang_auto    = "language: automatic (follows the client).",
        lang_usage   = "usage: /farol lang pt || en || auto",
        item_usage   = "usage: /farol show||hide",
        item_on      = "%s: |cff00ff00shown|r",
        item_off     = "%s: |cffff3333hidden|r",
        items_title  = "bar items:",
        none_shown   = "Farol — /farol show <item>",
        name_fps = "FPS",              cmd_fps = "fps",
        name_ms = "Latency",           cmd_ms = "ms",
        name_mem = "Memory",           cmd_mem = "mem",
        name_coords = "Coordinates",   cmd_coords = "coords",
        name_zone = "Zone",            cmd_zone = "zone",
        name_speed = "Speed",          cmd_speed = "speed",
        name_durab = "Durability",     cmd_durab = "durab",
        name_bags = "Bags",            cmd_bags = "bags",
        name_gold = "Gold",            cmd_gold = "gold",
        name_session = "Session gold", cmd_session = "session",
        name_goldh = "Gold per hour",  cmd_goldh = "goldh",
        name_xph = "XP per hour",      cmd_xph = "xph",
        name_rep = "Reputation",       cmd_rep = "rep",
        name_prof = "Professions",     cmd_prof = "prof",
        name_junk = "Junk in bags",    cmd_junk = "junk",
        name_ammo = "Ammo & reagents", cmd_ammo = "ammo",
        name_xp = "Experience (XP)",   cmd_xp = "xp",
        name_clock = "Clock",          cmd_clock = "clock",
        name_reset = "Resets (daily/weekly)", cmd_reset = "reset",
        name_playtime = "Session time", cmd_playtime = "playtime",
        name_friends = "Friends online", cmd_friends = "friends",
        name_guild = "Guild online",   cmd_guild = "guild",
        label_durab  = "Dur",
        label_mem    = "Mem",
        label_speed  = "Speed",
        label_bags   = "Bags",
        label_session = "Session",
        label_goldh  = "Gold/h",
        label_xph    = "XP/h",
        label_rep    = "Rep",
        label_prof   = "Prof",
        label_junk   = "Junk",
        label_ammo   = "Ammo",
        sup_ammo     = "Ammo",
        sup_shard    = "Shards",
        sup_powder   = "Arcane Powder",
        sup_runes    = "Runes",
        sup_candle   = "Candles",
        sup_symbol   = "Symbols",
        sup_seed     = "Seeds",
        sup_gift     = "Gift",
        sup_ankh     = "Ankhs",
        sup_flash    = "Flash Powder",
        sup_blind    = "Blinding Powder",
        tt_supply    = "Ammo & reagents",
        tt_supply_limits = "Yellow / red below",
        tt_supply_hint = "Restock at a vendor (Farol only counts, it never buys).",
        tt_supply_none = "no reagent tracked for your class yet",
        label_playtime = "Played",
        label_reset  = "Reset",
        label_reset_daily = "Daily",
        label_reset_weekly = "Weekly",
        label_friends = "Friends",
        label_guild  = "Guild",
        opt_servertime = "Server time",
        opt_summary  = "Session summary at login",
        opt_goldtotal = "Gold of all characters on the bar",
        opt_forget   = "Forget characters",
        opt_forget_confirm = "Click again to confirm",
        label_gold_total = "Total %s",
        tt_gold_total = "Gold on this account (%s)",
        tt_gold_this = "this one",
        tt_rest_title = "Rested XP of your characters (estimate)",
        tt_locks     = "Saved instances",
        tt_locks_none = "none",
        tt_locks_wait = "loading...",
        tt_locks_bosses = "%d/%d bosses",
        tt_locks_reset = "reset in %s",
        tt_locks_alts = "Saved instances of your characters",
        locks_title  = "saved instances of this character:",
        locks_none   = "this character is not saved to any instance.",
        locks_alts   = "other characters on this realm:",
        locks_status = "saved instances: %d (function: %s).",
        help_locks   = "  /farol lockouts      - saved instances (raid lockouts) of this and your other characters",
        tt_rest_full = "full",
        tt_rest_eta  = "full in ~%s",
        tt_rest_inn  = "inn/city",
        tt_rest_out  = "outside",
        gold_forgot  = "character forgotten: %s.",
        gold_forgot_all = "%d character(s) on this realm forgotten (the current one stays).",
        gold_forget_self = "you cannot forget the character you are playing.",
        gold_not_found = "character not found on this realm: %s.",
        gold_list    = "gold of your characters on %s (total %s):",
        gold_total_on = "gold total on the bar: on.",
        gold_total_off = "gold total on the bar: off.",
        help_gold    = "  /farol gold [total on||off || forget Name] - gold of all your characters on this realm",
        sum_title    = "session summary (%s):",
        sum_last     = "last session (%s, %s):",
        sum_gold     = "Gold: %s",
        sum_xp       = "XP: +%s",
        sum_level1   = "1 level",
        sum_levels   = "%d levels",
        sum_rep      = "Reputation: +%s %s",
        sum_loot     = "Loot: %d",
        sum_rare1    = "1 rare",
        sum_rares    = "%d rares",
        sum_epic1    = "1 epic",
        sum_epics    = "%d epics",
        sum_legend1  = "1 legendary",
        sum_legends  = "%d legendaries",
        sum_warns    = "Warnings: %d",
        sum_on       = "session summary at login: on.",
        sum_off      = "session summary at login: off.",
        help_summary = "  /farol summary [on||off] - current session summary (or turn the summary at login on/off)",
        tt_mem       = "Lua memory (UI + addons)",
        tt_speed     = "Speed",
        tt_bags      = "Bags (free / total)",
        tt_session   = "Gold this session",
        tt_goldh     = "Gold per hour",
        tt_xph       = "XP per hour",
        tt_tolevel   = "Next level in",
        tt_rep       = "Reputation",
        tt_rep_standing = "Standing",
        tt_rep_progress = "Progress",
        tt_rep_rate  = "Reputation per hour",
        tt_rep_next  = "Next standing in",
        tt_rep_none  = "no watched faction (tick 'Show as Experience Bar' in the reputation panel)",
        tt_prof      = "Professions",
        tt_junk      = "Junk in bags (vendor value)",
        tt_junk_slots = "Slots taken by junk",
        tt_junk_pending = "loading information for %d item(s)...",
        tt_junk_hint = "Sell it at a vendor (Farol only shows it, it never sells).",
        junk_status  = "junk in bags: %s in %d slot(s) (function: %s).",
        tt_prof_none = "no profession learned",
        tt_prof_gain = " (+%d this session)",
        tt_prof_cap  = "at the training limit — find a trainer",
        prof_status  = "professions: %s (function: %s).",
        prof_status_none = "professions: none found (function: %s).",
        rep_status   = "reputation: %s (function: %s).",
        rep_status_none = "reputation: no watched faction.",
        tt_reset_daily  = "Daily reset in",
        tt_reset_weekly = "Weekly reset in",
        tt_reset_at     = "%s (%s local · %s server)",
        tt_reset_none   = "not reported by the game",
        reset_status    = "resets: daily %s (function: %s) · weekly %s (function: %s).",
        weekdays        = "Sun,Mon,Tue,Wed,Thu,Fri,Sat",
        weekdays_long   = "Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday",
        months          = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
        when_today      = "Today",
        when_yesterday  = "Yesterday",
        when_date       = "MON D",
        when_date_year  = "MON D 'YY",
        when_long       = "WEEKDAY, MON D, YYYY at HH:MI",
        tt_rate_wait = "calculating... (1 min)",
        session_reset = "session reset: gold, XP and time start counting now.",
        help_session = "  /farol session reset - restart the session gold, XP and time counters",
        opt_session_reset = "Reset session",
        tt_xp        = "Experience",
        tt_rested    = "Rested",
        tt_maxlevel  = "Max level",
        tt_clock_local  = "Local time",
        tt_clock_server = "Server time",
        tt_playtime  = "Session time",
        tt_friends   = "Friends online",
        tt_friends_value = "WoW %d / Battle.net %d",
        tt_guild     = "Guild online",
        tt_noguild   = "No guild",
        tt_latency   = "Latency",
        tt_lat_value = "home %d ms / world %d ms",
        tt_coords    = "Coordinates",
        tt_zone      = "Zone",
        tt_subzone   = "Subzone",
        tt_durab     = "Durability (lowest item)",
        tt_all_ok    = "All gear is at 100%.",
        tt_no_gear   = "No equipped items with durability.",
        tt_gold      = "Gold",
        tt_drag      = "Drag to move.",
        tt_locked    = "Panel locked (/farol lock).",
        tt_help      = "/farol help — list of commands",
        tt_slot      = "Slot %d",
        help_menu    = "  /farol menu          - open the options menu (or right-click the panel)",
        opt_items    = "Bar items",
        opt_general  = "General",
        opt_shown    = "Show panel",
        opt_locked   = "Lock position",
        opt_lang     = "Language",
        opt_reset    = "Reset position",
        opt_alarms   = "Alarms...",
        opt_hint     = "Tick what you want to see on the bar.",
        opt_hint_count = "Bar items: %d of %d on — tick the ones you want (hover to see what each one shows).",
        tt_rightclick_more = "Right-click: options (%d more items you can turn on).",
        tt_shift_full = "Hold Shift to see all information.",
        tt_more      = "and %d more",
        welcome1     = "welcome! The bar starts with the basics only: %s.",
        welcome2     = "there are %d more items and several warnings turned off — right-click the bar to choose (or /farol menu). /farol help lists the commands.",
        news_title   = "new since your last version (most are off by default — turn them on in the menu: right-click the bar):",
        news_rep     = "reputation on the bar",
        news_reset   = "reset countdown",
        news_lootdates = "dates in the loot window",
        news_summary = "session summary (/farol summary)",
        news_breaks  = "break and water reminders",
        news_remind  = "\"Remind in\" 2 to 30 min",
        news_prof    = "professions and trainer warning",
        news_junk    = "junk value in bags",
        news_alts    = "gold of all your characters (/farol gold)",
        news_rested  = "rested XP of your characters",
        news_locks   = "saved instances (/farol lockouts)",
        news_tooltip = "smaller tooltip: each item shows its own (Shift shows everything)",
        news_supply  = "ammo and reagents, with limits you choose",
        help_news    = "  /farol news          - show the news of the latest versions again",
        desc_fps      = "Frames per second (green 50+, yellow 25+).",
        desc_ms       = "Latency: the higher of home and world.",
        desc_mem      = "Lua memory used by the UI and add-ons.",
        desc_coords   = "Your map position (hidden in instances).",
        desc_zone     = "Current zone name.",
        desc_speed    = "Movement speed (100% = normal running).",
        desc_durab    = "Your most damaged item (red below 20%).",
        desc_bags     = "Free / total bag slots.",
        desc_junk     = "Vendor value of gray items (Farol never sells).",
        desc_ammo     = "Ammo and reagents of your class; colors follow the limits in the Warnings window.",
        desc_gold     = "Your gold (and, optionally, all your characters' total).",
        desc_session  = "Gold gained or spent since you logged in.",
        desc_goldh    = "Session gold per hour.",
        desc_xp       = "XP percentage and rested bonus.",
        desc_xph      = "XP per hour and time to the next level.",
        desc_rep      = "Watched faction: standing, progress and rep/hour.",
        desc_prof     = "Professions with level / training limit.",
        desc_clock    = "Local or server time (alarms live here).",
        desc_reset    = "Time until the daily and weekly reset.",
        desc_playtime = "How long you have been playing this session.",
        desc_friends  = "How many friends are online (no names).",
        desc_guild    = "How many guild members are online (no names).",
        tt_rightclick = "Right-click: options.",
    },
}

ns.STRINGS = STRINGS

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local db -- configurações validadas (preenchida em ADDON_LOADED)

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

-- Idioma ativo: escolha do usuário, ou o idioma do cliente quando "auto".
local function CurrentLang()
    local lang = db and db.lang or "auto"
    if lang == "auto" then
        local locale = GetLocale and GetLocale() or "enUS"
        return (locale == "ptBR" or locale == "ptPT") and "pt" or "en"
    end
    return lang
end

-- Busca um texto traduzido; cai para inglês se faltar.
local function T(key)
    local lang = STRINGS[CurrentLang()] or STRINGS.en
    return lang[key] or STRINGS.en[key] or key
end

ns.T = T
ns.ICON = ICON

-- Janelas do Farol ficam na mesma camada de desenho; sem isto, uma janela recém-aberta pode
-- ficar atrás de outra (ex.: Alarmes atrás do menu). Toda janela aberta vem para a frente, e
-- clicar em qualquer uma a traz para a frente (como as janelas do próprio jogo).
function ns.MakeToplevel(frame)
    if frame.SetToplevel then frame:SetToplevel(true) end
    if frame.HookScript then
        frame:HookScript("OnShow", function(self) self:Raise() end)
    end
end
ns.Print = Print
ns.GetDB = function() return db end

-- Garante que SavedVariables tenham só os tipos/valores esperados.
-- Um arquivo corrompido ou editado à mão nunca quebra o addon.
local function SanitizeDB(saved)
    local clean = {}
    if type(saved) ~= "table" then saved = {} end

    for key, default in pairs(DEFAULTS) do
        local value = saved[key]
        if type(value) ~= type(default) then
            value = default
        end
        clean[key] = value
    end

    if not VALID_POINTS[clean.point] then clean.point = DEFAULTS.point end
    if not VALID_POINTS[clean.relPoint] then clean.relPoint = DEFAULTS.relPoint end
    if not VALID_LANGS[clean.lang] then clean.lang = DEFAULTS.lang end
    local snooze = clean.snoozeMinutes
    if snooze ~= math.floor(snooze) or snooze < 1 or snooze > 60 then clean.snoozeMinutes = DEFAULTS.snoozeMinutes end
    -- Aparência: números fora da faixa (ou NaN) voltam ao padrão.
    if clean.scale ~= clean.scale or clean.scale < 0.5 or clean.scale > 2 then clean.scale = DEFAULTS.scale end
    if clean.bgAlpha ~= clean.bgAlpha or clean.bgAlpha < 0 or clean.bgAlpha > 1 then clean.bgAlpha = DEFAULTS.bgAlpha end
    -- Largura da barra: 0 (uma linha), 1 (uma coluna) ou de 2 a 4000 pixels.
    if clean.barWidth ~= clean.barWidth or clean.barWidth < 0 or clean.barWidth > 4000 then
        clean.barWidth = DEFAULTS.barWidth
    end
    clean.barWidth = math.floor(clean.barWidth)
    -- Quem usava a antiga "barra vertical" continua vendo uma coluna.
    if saved.vertical == true and saved.barWidth == nil then clean.barWidth = 1 end
    if clean.fontSize ~= math.floor(clean.fontSize) or clean.fontSize < 8 or clean.fontSize > 24 then
        clean.fontSize = DEFAULTS.fontSize
    end
    if clean.iconSize ~= math.floor(clean.iconSize) or clean.iconSize < 10 or clean.iconSize > 32 then
        clean.iconSize = DEFAULTS.iconSize
    end

    -- Limita deslocamentos a valores razoáveis.
    local limit = 5000
    if clean.x ~= clean.x or clean.x > limit or clean.x < -limit then clean.x = DEFAULTS.x end
    if clean.y ~= clean.y or clean.y > limit or clean.y < -limit then clean.y = DEFAULTS.y end

    -- Itens visíveis: só chaves conhecidas, só booleanos; o resto é descartado.
    local savedItems = type(saved.items) == "table" and saved.items or {}
    clean.items = {}
    for _, key in ipairs(ITEM_ORDER) do
        local value = savedItems[key]
        if type(value) == "boolean" then
            clean.items[key] = value
        else
            clean.items[key] = ITEM_DEFAULTS[key] -- padrão do item
        end
    end

    return clean
end

---------------------------------------------------------------------------
-- Versão 3: perfis e barras. No disco, o que é de cada barra fica em profiles.account.bars[N]; o resto (idioma,
-- alarmes, avisos, saques, personagens...) continua no FarolDB. No código, db.items, db.scale etc. continuam
-- funcionando: um metatable leva essas chaves para a barra ativa. Dados antigos (2.x, tudo "solto") e novos (3.x)
-- passam pela MESMA validação de sempre (SanitizeDB, Order.Sanitize) antes de serem montados no formato novo.
---------------------------------------------------------------------------

local Profiles = { DATA_VERSION = 3 } -- uma só variável local (o arquivo já está perto do limite de 200 do Lua)
Profiles.BAR_KEYS = { "shown", "locked", "point", "relPoint", "x", "y", "scale", "bgAlpha", "border", "barWidth",
                   "fontSize", "iconSize", "icons", "hideCombat", "hideInstance", "items", "order" }
Profiles.BAR_KEY = {}
for _, key in ipairs(Profiles.BAR_KEYS) do Profiles.BAR_KEY[key] = true end
ns.BAR_KEYS = Profiles.BAR_KEYS

-- Barra 1 do perfil da conta, se o arquivo salvo tiver o formato 3.x (tudo validado depois, como sempre).
function Profiles.SavedBar(saved)
    if type(saved) ~= "table" then return nil end
    local profiles = rawget(saved, "profiles")
    local account = type(profiles) == "table" and profiles.account
    local bars = type(account) == "table" and account.bars
    local bar = type(bars) == "table" and bars[1]
    return type(bar) == "table" and bar or nil
end

-- Visão "solta" (como na 2.x) dos dados salvos, para a validação de sempre: campos da barra vêm do perfil.
function Profiles.Flatten(saved)
    if type(saved) ~= "table" then return saved end
    local flat = {}
    for key, value in pairs(saved) do flat[key] = value end
    local bar = Profiles.SavedBar(saved)
    if bar then
        for _, key in ipairs(Profiles.BAR_KEYS) do
            if bar[key] ~= nil then flat[key] = bar[key] end
        end
    end
    flat.profiles, flat.activeBar, flat.dataVersion = nil, nil, nil
    return flat
end

Profiles.PROXY = {
    __index = function(t, key)
        if Profiles.BAR_KEY[key] then
            local profiles = rawget(t, "profiles")
            return profiles.account.bars[rawget(t, "activeBar") or 1][key]
        end
    end,
    __newindex = function(t, key, value)
        if Profiles.BAR_KEY[key] then
            local profiles = rawget(t, "profiles")
            profiles.account.bars[rawget(t, "activeBar") or 1][key] = value
        else
            rawset(t, key, value)
        end
    end,
}

-- Move os campos de barra (já validados) para profiles.account.bars[1] e liga o metatable.
function Profiles.Build(clean)
    local bar = {}
    for _, key in ipairs(Profiles.BAR_KEYS) do
        bar[key] = rawget(clean, key)
        rawset(clean, key, nil)
    end
    rawset(clean, "profiles", { account = { bars = { bar } } })
    rawset(clean, "activeBar", 1)
    rawset(clean, "dataVersion", Profiles.DATA_VERSION)
    return setmetatable(clean, Profiles.PROXY)
end

-- Executa uma leitura de dados isolada: qualquer erro/bloqueio vira nil.
local function Safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

-- WoW Forever / Midnight podem marcar valores como "secretos" (secret values);
-- não podemos fazer contas com eles, então os tratamos como indisponíveis.
local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end
ns.IsSecret = IsSecret

local function FormatMoney(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    return string.format("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", gold, silver, cop)
end

-- Cores: verde (bom), amarelo (médio), vermelho (ruim).
local GREEN, YELLOW, RED = "|cff00ff00", "|cffffff00", "|cffff3333"

local function ColorLowIsGood(value, good, ok)
    if value <= good then return GREEN end
    if value <= ok then return YELLOW end
    return RED
end

local function ColorHighIsGood(value, good, ok)
    if value >= good then return GREEN end
    if value >= ok then return YELLOW end
    return RED
end

---------------------------------------------------------------------------
-- Leitura de dados compatível com várias versões do cliente
---------------------------------------------------------------------------

local function GetFPS()
    return math.floor((GetFramerate() or 0) + 0.5)
end

local function GetLatency()
    -- 3.3.5a retorna (entrada, saída, latência); clientes modernos retornam também latencyWorld.
    local _, _, home, world = GetNetStats()
    home = tonumber(home) or 0
    world = tonumber(world) or 0
    return math.max(home, world), home, world
end

local function GetCoordsRaw()
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local x, y = pos:GetXY()
                if x and y and (x > 0 or y > 0) then return x, y end
            end
        end
    elseif GetPlayerMapPosition then
        local x, y = GetPlayerMapPosition("player")
        if x and y and (x > 0 or y > 0) then return x, y end
    end
    return nil -- instâncias e alguns mapas não informam posição
end

local function GetCoords()
    local x, y = Safe(GetCoordsRaw)
    if x == nil or IsSecret(x) or IsSecret(y) then return nil end
    return x, y
end

local function GetZones()
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    local sub = GetSubZoneText and GetSubZoneText() or ""
    if IsSecret(zone) then zone = "" end
    if IsSecret(sub) then sub = "" end
    return zone, sub
end

-- Durabilidade: guardada em cache e recalculada só quando o equipamento muda.
local durability = { lowest = nil, damaged = {} }
ns.GetLowestDurability = function() return durability.lowest end -- usado por Warnings.lua

local function ScanDurabilityRaw()
    local lowest, damaged = nil, {}
    for slot = 1, 19 do -- espaços de equipamento
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and not IsSecret(cur) and not IsSecret(max) and max > 0 then
            local pct = cur / max * 100
            if not lowest or pct < lowest then lowest = pct end
            if pct < 100 then
                damaged[#damaged + 1] = { slot = slot, pct = pct }
            end
        end
    end
    table.sort(damaged, function(a, b) return a.pct < b.pct end)
    durability.lowest, durability.damaged = lowest, damaged
end

local function ScanDurability()
    if not pcall(ScanDurabilityRaw) then
        durability.lowest, durability.damaged = nil, {}
    end
end

-- Estado da sessão (desde que você entrou no jogo, deu /reload ou zerou a sessão).
local session = { startMoney = nil, startTime = nil, xpGained = 0 }
local RATE_MIN_SECONDS = 60 -- taxas por hora só aparecem depois de 1 minuto (evita números absurdos)

-- Soma o XP ganho desde a última leitura, inclusive quando o personagem sobe de nível.
local function SampleXP()
    local level = UnitLevel("player")
    local cur, max = UnitXP("player"), UnitXPMax("player")
    if type(cur) ~= "number" or type(max) ~= "number" or IsSecret(cur) or IsSecret(max) then return end
    if session.lastXP then
        if level > session.lastLevel then
            session.xpGained = session.xpGained + math.max(0, session.lastMax - session.lastXP) + cur
        elseif cur > session.lastXP then
            session.xpGained = session.xpGained + (cur - session.lastXP)
        end
    end
    session.lastXP, session.lastMax, session.lastLevel = cur, max, level
end

-- Reputação da facção acompanhada (a marcada como "Mostrar como barra de experiência" no painel de
-- reputação). O nome da função mudou entre versões: clientes modernos usam
-- C_Reputation.GetWatchedFactionData; os antigos, GetWatchedFactionInfo. Tentamos as duas.
-- Devolve (dados, nome da função) ou nil se não houver facção acompanhada.
local function GetWatchedFaction()
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        local data = C_Reputation.GetWatchedFactionData()
        if type(data) == "table" and data.name then
            return { id = data.factionID or data.name, name = data.name, reaction = data.reaction,
                     min = data.currentReactionThreshold, max = data.nextReactionThreshold,
                     value = data.currentStanding }, "C_Reputation"
        end
    end
    if GetWatchedFactionInfo then
        local name, reaction, min, max, value, id = GetWatchedFactionInfo()
        if name then
            return { id = id or name, name = name, reaction = reaction, min = min, max = max, value = value },
                "GetWatchedFactionInfo"
        end
    end
    return nil
end
ns.GetWatchedFaction = GetWatchedFaction

-- Dados utilizáveis: texto e números de verdade, nada bloqueado pelo jogo.
local function ValidFaction(f)
    if type(f) ~= "table" or type(f.name) ~= "string" or IsSecret(f.name) then return false end
    for _, key in ipairs({ "reaction", "min", "max", "value" }) do
        local v = f[key]
        -- número de verdade: nem bloqueado, nem NaN, nem infinito
        if type(v) ~= "number" or IsSecret(v) or v ~= v or v == math.huge or v == -math.huge then return false end
    end
    return true
end

-- Nome da facção pronto para mostrar: "|" vira barra literal (nada de códigos/links) e no máximo 48 bytes.
local function FactionName(name)
    name = string.gsub(name, "|", "||")
    if #name > 48 then
        local cut = string.sub(name, 1, 48)
        local nextByte = string.byte(name, 49)
        if nextByte >= 128 and nextByte < 192 then -- a letra seguinte ficaria cortada no meio (UTF-8)
            cut = string.gsub(cut, "[\192-\255][\128-\191]*$", "")
        end
        name = cut .. "..."
    end
    return name
end

-- Progresso no nível atual, sempre dentro da faixa: atual, total e % (0 a 100). nil se o nível não tem faixa.
local function RepProgress(f)
    local total = f.max - f.min
    if total <= 0 then return nil end
    local cur = math.max(0, math.min(total, f.value - f.min))
    return cur, total, math.floor(cur / total * 100)
end

---------------------------------------------------------------------------
-- Profissões: nível e máximo do treinamento (só leitura).
-- Clientes modernos: GetProfessions + GetProfessionInfo. Antigos (3.3.5a / clássico): GetSkillLineInfo,
-- grupo "Profissões" (as que podem ser abandonadas) e o grupo seguinte ("Profissões secundárias").
---------------------------------------------------------------------------

local PROF_FINAL = 300 -- último limite do estilo clássico: aqui não há mais instrutor para procurar

local function ValidProf(name, level, max)
    if type(name) ~= "string" or name == "" or IsSecret(name) then return false end
    for _, v in ipairs({ level, max }) do
        if type(v) ~= "number" or IsSecret(v) or v ~= v or v < 0 or v > 100000 then return false end
    end
    return max > 0
end

local function AddProf(list, name, level, max, primary)
    if ValidProf(name, level, max) then
        list[#list + 1] = { name = name, level = math.floor(math.min(level, max)), max = math.floor(max),
                            primary = primary and true or false }
    end
end

local function ReadProfessions()
    if GetProfessions and GetProfessionInfo then
        local ok, p1, p2, _, fishing, cooking, firstAid = pcall(GetProfessions)
        if ok then
            local list = {}
            for _, slot in ipairs({ { p1, true }, { p2, true }, { cooking }, { firstAid }, { fishing } }) do
                if type(slot[1]) == "number" then
                    local okInfo, name, _, level, max = pcall(GetProfessionInfo, slot[1])
                    if okInfo then AddProf(list, name, level, max, slot[2]) end
                end
            end
            if #list > 0 or not (GetNumSkillLines and GetSkillLineInfo) then return list, "GetProfessions" end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        local ok, count = pcall(GetNumSkillLines)
        if not ok or type(count) ~= "number" then return nil end
        local entries, header, profHeader = {}, 0, nil
        for i = 1, math.min(count, 200) do
            local okLine, name, isHeader, _, level, _, _, max, abandonable = pcall(GetSkillLineInfo, i)
            if okLine then
                if isHeader then
                    header = header + 1
                else
                    entries[#entries + 1] = { name, level, max, abandonable, header }
                    if abandonable and not profHeader then profHeader = header end
                end
            end
        end
        local list = {}
        for _, e in ipairs(entries) do
            if profHeader and (e[5] == profHeader or (e[5] == profHeader + 1 and not e[4])) then
                AddProf(list, e[1], e[2], e[3], e[4])
            end
        end
        return list, "GetSkillLineInfo"
    end
    return nil
end
ns.ReadProfessions = ReadProfessions -- usado pelo aviso de "procure um instrutor"
ns.PROF_FINAL = PROF_FINAL

-- Situação no treinamento: "cap" (parou: procure um instrutor), "near" (faltam até 5), "final" ou "ok".
local function ProfState(p)
    if p.max >= PROF_FINAL then return p.level >= p.max and "final" or "ok" end
    if p.level >= p.max then return "cap" end
    if p.max - p.level <= 5 then return "near" end
    return "ok"
end
ns.ProfState = ProfState

local PROF_COLORS = { cap = "|cffff4040", near = "|cffffff3a", final = "|cff40ff40" }

local function ProfText(p)
    local value = p.level .. "/" .. p.max
    local color = PROF_COLORS[ProfState(p)]
    if color then value = color .. value .. "|r" end
    return value
end

-- Pontos ganhos nesta sessão, por nome da profissão.
local function SampleProfs()
    local list = ReadProfessions()
    if not list then return end
    session.profStart = session.profStart or {}
    for _, p in ipairs(list) do
        if session.profStart[p.name] == nil then session.profStart[p.name] = p.level end
    end
end

local function ProfGain(p)
    local start = session.profStart and session.profStart[p.name]
    return start and math.max(0, p.level - start) or 0
end

-- Soma a reputação ganha na facção acompanhada; trocar de facção recomeça a contagem.
local function SampleRep()
    local f = GetWatchedFaction()
    if not ValidFaction(f) then return end
    if session.repID ~= f.id then
        session.repID, session.repLast, session.repGained, session.repStart = f.id, f.value, 0, GetTime()
        session.repName, session.repFrom, session.repTo = f.name, f.reaction, f.reaction
        return
    end
    if f.value > session.repLast then
        session.repGained = session.repGained + (f.value - session.repLast)
    end
    session.repLast = f.value
    session.repTo = f.reaction
end

local function ResetSession()
    session.startMoney = GetMoney()
    session.startTime = GetTime()
    session.startClock = time() -- hora do relógio: separa os saques e avisos desta sessão
    local okLevel, level = pcall(UnitLevel, "player")
    session.startLevel = (okLevel and type(level) == "number" and not IsSecret(level)) and level or nil
    session.xpGained = 0
    session.lastXP = nil
    session.repID = nil -- recomeça a contagem de reputação
    session.profStart = nil -- e a das profissões
    pcall(SampleXP)
    pcall(SampleRep)
    pcall(SampleProfs)
end

local function StartSession()
    if session.startTime then return end
    ResetSession()
end

local function GetMemoryMB()
    return (collectgarbage("count") or 0) / 1024 -- leitura barata, sem travar o jogo
end

local function GetSpeedPercent()
    local current, run = GetUnitSpeed("player")
    local base = BASE_MOVEMENT_SPEED or 7
    local speed = (current and current > 0) and current or run or 0
    return speed / base * 100
end

---------------------------------------------------------------------------
-- Ouro dos seus personagens (FarolDB.chars[reino][nome] = { gold, level, t }).
-- Cada personagem só registra o PRÓPRIO ouro e nível, quando você joga com ele. Fica só no seu computador.
---------------------------------------------------------------------------

local MAX_REALMS, MAX_CHARS = 20, 60

-- Nome de personagem ou reino aceitável: texto de 1 a 48 bytes, sem "|" nem caracteres de controle.
local function ValidName(name)
    return type(name) == "string" and not IsSecret(name) and #name >= 1 and #name <= 48
        and not string.find(name, "[|%c]")
end

-- Mantém os "limit" itens mais recentes (maior t; empate: nome), em ordem fixa (pairs não tem ordem garantida).
local function KeepRecent(map, limit, recentOf)
    local keys = {}
    for key in pairs(map) do keys[#keys + 1] = key end
    if #keys <= limit then return map end
    table.sort(keys, function(a, b)
        local ta, tb = recentOf(map[a]), recentOf(map[b])
        if ta ~= tb then return ta > tb end
        return a < b
    end)
    local kept = {}
    for i = 1, limit do kept[keys[i]] = map[keys[i]] end
    return kept
end

local function SanitizeChars(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    for realm, chars in pairs(saved) do
        if ValidName(realm) and type(chars) == "table" then
            local list, count = {}, 0
            for name, info in pairs(chars) do
                if ValidName(name) and type(info) == "table" then
                    local gold, level, t = info.gold, info.level, info.t
                    if type(gold) == "number" and gold == gold and gold >= 0 and gold <= 1e12
                            and type(level) == "number" and level >= 1 and level <= 200
                            and type(t) == "number" and t >= 0 and t < 4102444800 then
                        local entry = { gold = math.floor(gold), level = math.floor(level), t = math.floor(t) }
                        -- Descanso (opcional): XP descansado, XP do nível e se estava em estalagem/cidade.
                        local rest, max = info.rest, info.max
                        if type(rest) == "number" and rest == rest and rest >= 0 and rest <= 1e9
                                and type(max) == "number" and max >= 1 and max <= 1e9 then
                            entry.rest, entry.max = math.floor(rest), math.floor(max)
                            entry.inn = info.inn == true
                        end
                        -- Instâncias salvas (opcional): nome, chefes mortos/total e quando o bloqueio acaba.
                        if type(info.locks) == "table" then
                            local locks = {}
                            for _, lock in ipairs(info.locks) do
                                if #locks >= 20 then break end
                                if type(lock) == "table" and type(lock.n) == "string" and #lock.n >= 1 and #lock.n <= 64
                                        and not string.find(lock.n, "[|%c]")
                                        and type(lock.r) == "number" and lock.r == lock.r and lock.r > 0 and lock.r < 4102444800 then
                                    local k, b = lock.k, lock.b
                                    if type(k) ~= "number" or k ~= k or k < 0 or k > 50 then k = nil end
                                    if type(b) ~= "number" or b ~= b or b < 1 or b > 50 then b = nil end
                                    if k and b and k > b then k = b end
                                    locks[#locks + 1] = { n = lock.n, r = math.floor(lock.r),
                                                          k = k and math.floor(k) or nil, b = b and math.floor(b) or nil }
                                end
                            end
                            if #locks > 0 then entry.locks = locks end
                        end
                        list[name] = entry
                        count = count + 1
                    end
                end
            end
            if count > 0 then clean[realm] = KeepRecent(list, MAX_CHARS, function(e) return e.t end) end
        end
    end
    -- Arquivo adulterado com reinos demais: fica com os de atividade mais recente.
    return KeepRecent(clean, MAX_REALMS, function(chars)
        local latest = 0
        for _, e in pairs(chars) do if e.t > latest then latest = e.t end end
        return latest
    end)
end

-- Quem está jogando agora: nome e reino (nil se o jogo ainda não informou).
local function CurrentCharacter()
    local okName, name = pcall(UnitName, "player")
    local getRealm = GetNormalizedRealmName or GetRealmName
    local okRealm, realm = false, nil
    if GetRealmName then okRealm, realm = pcall(GetRealmName) end
    if (not okRealm or not ValidName(realm)) and getRealm then okRealm, realm = pcall(getRealm) end
    if not okName or not ValidName(name) or name == UNKNOWNOBJECT or name == "Unknown" then return nil end
    if not okRealm or not ValidName(realm) then return nil end
    return name, realm
end

-- XP descansado do personagem atual: descanso, XP do nível e se está em estalagem/cidade (nil no nível máximo).
local function CurrentRest()
    if IsPlayerAtEffectiveMaxLevel then
        local ok, maxed = pcall(IsPlayerAtEffectiveMaxLevel)
        if ok and maxed then return nil end
    end
    local okMax, maxLevel = pcall(function() return GetMaxPlayerLevel and GetMaxPlayerLevel() end)
    local okLevel, level = pcall(UnitLevel, "player")
    if okMax and okLevel and type(maxLevel) == "number" and type(level) == "number" and level >= maxLevel then return nil end
    local okXP, max = pcall(UnitXPMax, "player")
    if not okXP or type(max) ~= "number" or IsSecret(max) or max ~= max or max < 1 or max > 1e9 then return nil end
    local rest = 0
    if GetXPExhaustion then
        local okRest, value = pcall(GetXPExhaustion)
        if okRest and type(value) == "number" and not IsSecret(value) and value == value and value >= 0 and value <= 1e9 then
            rest = value
        end
    end
    local inn = false
    if IsResting then
        local okInn, value = pcall(IsResting)
        inn = okInn and value and true or false
    end
    return math.floor(rest), math.floor(max), inn
end

---------------------------------------------------------------------------
-- Instâncias salvas (bloqueios de raide/masmorra). SÓ LÊ a lista oficial do jogo.
-- O jogo só atualiza a lista depois de pedir ao servidor (RequestRaidInfo, a mesma consulta da janela de Raide):
-- pedimos uma vez ao entrar e, depois, no máximo uma vez por minuto (tooltip/comando).
---------------------------------------------------------------------------

local LOCK_REQUEST_INTERVAL = 60
local lastLockRequest
local locksLoaded = false     -- já chegou a resposta do servidor (UPDATE_INSTANCE_INFO)?

local function RequestLockouts(force)
    if not RequestRaidInfo then return end
    local now = GetTime()
    if not force and lastLockRequest and now - lastLockRequest < LOCK_REQUEST_INTERVAL then return end
    lastLockRequest = now
    pcall(RequestRaidInfo)
end

-- Lista do personagem atual: { name, killed, total, reset (segundos) }, só bloqueios ativos. nil se a API não existe.
local function ReadLockouts()
    if not GetNumSavedInstances or not GetSavedInstanceInfo then return nil end
    local ok, count = pcall(GetNumSavedInstances)
    if not ok or type(count) ~= "number" or count ~= count or count < 0 then return nil end
    local list = {}
    for i = 1, math.min(math.floor(count), 50) do
        local okInfo, name, _, reset, _, locked, _, _, _, _, _, total, killed = pcall(GetSavedInstanceInfo, i)
        if okInfo and type(name) == "string" and not IsSecret(name) and #name >= 1 and #name <= 64
                and not string.find(name, "[|%c]") and locked
                and type(reset) == "number" and not IsSecret(reset) and reset == reset and reset > 0 and reset < 30 * 86400 then
            if type(total) ~= "number" or total ~= total or total < 1 or total > 50 then total = nil end
            if type(killed) ~= "number" or killed ~= killed or killed < 0 or killed > 50 or not total then killed = nil end
            if killed and killed > total then killed = total end
            list[#list + 1] = { name = name, reset = math.floor(reset),
                                total = total and math.floor(total), killed = killed and math.floor(killed) }
        end
    end
    table.sort(list, function(a, b)
        if a.reset ~= b.reset then return a.reset < b.reset end
        return a.name < b.name
    end)
    return list
end

ns.ReadLockouts = ReadLockouts -- usado por /farol aviso status

-- Formato para guardar: data do fim do bloqueio (não "segundos a partir de agora").
local function LocksToSave(list)
    if not list or #list == 0 then return nil end
    local saved, now = {}, time()
    for i = 1, math.min(20, #list) do
        local l = list[i]
        saved[i] = { n = l.name, k = l.killed, b = l.total, r = now + l.reset }
    end
    return saved
end

-- Registra o ouro e o nível do personagem atual (force = ao sair: grava também o descanso atual).
local function RecordCharacter(force)
    if not db or type(db.chars) ~= "table" then return end
    local name, realm = CurrentCharacter()
    if not name then return end
    local okMoney, gold = pcall(GetMoney)
    local okLevel, level = pcall(UnitLevel, "player")
    if not okMoney or type(gold) ~= "number" or IsSecret(gold) or gold ~= gold or gold < 0 or gold > 1e12 then return end
    if not okLevel or type(level) ~= "number" or IsSecret(level) or level < 1 or level > 200 then return end
    local chars = db.chars[realm]
    if not chars then
        local realms = 0
        for _ in pairs(db.chars) do realms = realms + 1 end
        if realms >= MAX_REALMS then return end
        chars = {}
        db.chars[realm] = chars
    end
    if not chars[name] then
        local count = 0
        for _ in pairs(chars) do count = count + 1 end
        if count >= MAX_CHARS then return end
    end
    local entry = chars[name]
    gold, level = math.floor(gold), math.floor(level)
    local rest, max, inn = CurrentRest()
    if not force and entry and entry.gold == gold and entry.level == level and entry.rest == rest
            and entry.inn == inn and time() - entry.t < 60 then return end
    -- Instâncias salvas: atualizadas só quando a resposta do servidor já chegou; senão, mantém as anteriores.
    local locks = entry and entry.locks
    if locksLoaded then locks = LocksToSave(ReadLockouts()) end
    chars[name] = { gold = gold, level = level, t = time(), rest = rest, max = max, inn = rest and inn or nil,
                    locks = locks }
end

-- Estimativa do descanso de um personagem deslogado, pelas regras do estilo clássico: em estalagem/cidade ganha
-- 5% do XP do nível a cada 8 h; fora, 1/4 disso; máximo 150% (1,5 nível). Devolve %, cheio? e segundos até encher.
local REST_CAP, REST_INN_RATE, REST_OUT_RATE = 1.5, 0.05 / (8 * 3600), 0.0125 / (8 * 3600)
local function EstimateRest(info, now)
    if not info.rest or not info.max then return nil end
    local rate = (info.inn and REST_INN_RATE or REST_OUT_RATE) * info.max
    local cap = REST_CAP * info.max
    local elapsed = math.max(0, (now or time()) - info.t)
    local value = math.min(cap, info.rest + rate * elapsed)
    local eta = value >= cap and 0 or (cap - value) / rate
    return math.floor(value / info.max * 100 + 0.5), value >= cap, eta
end

-- Outros personagens do reino com descanso conhecido (o atual tem o valor real no tooltip de XP).
local function RestedAlts()
    local name, realm = CurrentCharacter()
    if not name or not db or type(db.chars) ~= "table" then return nil end
    local list, now = {}, time()
    for charName, info in pairs(db.chars[realm] or {}) do
        if charName ~= name then
            local pct, full, eta = EstimateRest(info, now)
            if pct then
                list[#list + 1] = { name = charName, level = info.level, pct = pct, full = full, eta = eta, inn = info.inn }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.pct ~= b.pct then return a.pct > b.pct end
        return a.name < b.name
    end)
    return list
end
ns.RestedAlts = RestedAlts -- usado pelo aviso de "descanso cheio"

-- Outros personagens do reino com instâncias ainda salvas (bloqueios vencidos somem sozinhos).
local function AltLockouts()
    local name, realm = CurrentCharacter()
    if not name or not db or type(db.chars) ~= "table" then return nil end
    local list, now = {}, time()
    for charName, info in pairs(db.chars[realm] or {}) do
        if charName ~= name and info.locks then
            local names = {}
            for _, lock in ipairs(info.locks) do
                if lock.r > now then names[#names + 1] = lock.n end
            end
            if #names > 0 then
                table.sort(names)
                list[#list + 1] = { name = charName, level = info.level, locks = names }
            end
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Personagens do reino atual, do mais rico para o mais pobre, e o total. O atual vem marcado (current = true).
local function RealmCharacters()
    local name, realm = CurrentCharacter()
    if not name or not db or type(db.chars) ~= "table" then return nil end
    local list, total = {}, 0
    for charName, info in pairs(db.chars[realm] or {}) do
        list[#list + 1] = { name = charName, gold = info.gold, level = info.level, t = info.t, current = charName == name }
        total = total + info.gold
    end
    table.sort(list, function(a, b)
        if a.gold ~= b.gold then return a.gold > b.gold end
        return a.name < b.name
    end)
    return list, total, realm
end

-- Esquece um personagem deste reino (ou todos, menos o atual, com name = nil).
local function ForgetCharacters(target)
    local name, realm = CurrentCharacter()
    local chars = name and db.chars[realm]
    if not chars then return end
    if target == nil then
        local count = 0
        for charName in pairs(chars) do
            if charName ~= name then chars[charName] = nil; count = count + 1 end
        end
        Print(string.format(T("gold_forgot_all"), count))
        return
    end
    for charName in pairs(chars) do
        if string.lower(charName) == string.lower(target) then
            if charName == name then Print(T("gold_forget_self")) return end
            chars[charName] = nil
            Print(string.format(T("gold_forgot"), (string.gsub(charName, "|", "||"))))
            return
        end
    end
    Print(string.format(T("gold_not_found"), (string.gsub(target, "|", "||"))))
end

-- Última bolsa a ler (mochila = 0). Valor do jogo validado: um número estranho nunca vira um laço sem fim.
local function LastBag()
    local n = NUM_BAG_SLOTS
    if type(n) ~= "number" or n ~= n or n < 0 or n > 12 then return 4 end
    return math.floor(n)
end

local function GetBagSpace()
    local getFree = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    local getSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not getFree or not getSlots then return nil end
    local free, total = 0, 0
    for bag = 0, LastBag() do
        local slots = getSlots(bag) or 0
        local bagFree, family = getFree(bag)
        if slots > 0 and (family == nil or family == 0) then -- só bolsas comuns
            free = free + (bagFree or 0)
            total = total + slots
        end
    end
    if total == 0 then return nil end
    return free, total
end
ns.GetBagSpace = GetBagSpace -- usado por Warnings.lua

-- Lixo (itens cinzentos, qualidade 0) nas bolsas: valor de venda total, espaços ocupados e os itens.
-- SÓ LÊ: o Farol nunca vende nada (isso seria automação). Clientes modernos: C_Container.GetContainerItemInfo
-- (tabela); antigos: GetContainerItemInfo + GetContainerItemLink. Preço de venda: 11º valor de GetItemInfo.
-- Itens que o jogo ainda não carregou ficam "pendentes" e entram na conta na próxima atualização.
local function ItemPrice(item)
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not getInfo or item == nil then return nil end
    local ok, name, _, quality, _, _, _, _, _, _, _, price = pcall(getInfo, item)
    if not ok or name == nil then return nil end
    return name, quality, price
end

local function ReadSlot(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if not ok or type(info) ~= "table" then return nil end
        return info.hyperlink or info.itemID, info.stackCount, info.quality, info.hasNoValue, "C_Container"
    end
    if GetContainerItemInfo then
        local ok, _, count, _, quality, _, _, link = pcall(GetContainerItemInfo, bag, slot)
        if not ok then return nil end
        if link == nil and GetContainerItemLink then
            local okLink, value = pcall(GetContainerItemLink, bag, slot)
            if okLink then link = value end
        end
        return link, count, quality, nil, "GetContainerItemInfo"
    end
    return nil
end

local function ValidNumber(v, max)
    return type(v) == "number" and not IsSecret(v) and v == v and v >= 0 and v <= max
end

---------------------------------------------------------------------------
-- Munição e reagentes da classe (só CONTA: nunca compra, usa ou move). IDs do jogo clássico.
-- Um grupo só passa a ser acompanhado depois que o personagem já teve pelo menos 1 (FarolCharDB.supplySeen):
-- assim um mago de nível 10 não é avisado por falta de Pó Arcano que ele ainda nem usa.
---------------------------------------------------------------------------

local SUPPLIES = {
    HUNTER  = { { key = "ammo", kind = "ammo", ammoSlot = true } },
    WARLOCK = { { key = "shard", ids = { 6265 } } },
    MAGE    = { { key = "powder", ids = { 17020 } }, { key = "runes", ids = { 17031, 17032 } } },
    PRIEST  = { { key = "candle", ids = { 17028, 17029 } } },
    PALADIN = { { key = "symbol", ids = { 17033, 21177 } } },
    DRUID   = { { key = "seed", ids = { 17034, 17035, 17036, 17037, 17038 } }, { key = "gift", ids = { 17021, 17026 } } },
    SHAMAN  = { { key = "ankh", ids = { 17030 } } },
    ROGUE   = { { key = "flash", ids = { 5140 } }, { key = "blind", ids = { 5530 } } },
}
ns.SUPPLIES = SUPPLIES

local function SafeCount(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, n = pcall(fn, ...)
    if not ok or type(n) ~= "number" or IsSecret(n) or n ~= n or n < 0 or n > 100000 then return nil end
    return math.floor(n)
end

local function ItemCount(id)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    return SafeCount(getCount, id)
end

local function PlayerClass()
    if not UnitClass then return nil end
    local ok, _, classFile = pcall(UnitClass, "player")
    if ok and type(classFile) == "string" and SUPPLIES[classFile] then return classFile end
    return nil
end

-- Limites (amarelo, vermelho) escolhidos na janela de Avisos.
local function SupplyLimits(kind)
    local w = db and db.warnings
    if not w then return 0, 0 end
    if kind == "ammo" then return w.ammoYellow or 400, w.ammoRed or 200 end
    return w.reagYellow or 10, w.reagRed or 5
end
ns.SupplyLimits = SupplyLimits

-- Grupos acompanhados: { key, kind, count, yellow, red, state = "ok"|"low"|"out" }. nil se a classe não usa nada.
local function GetSupplies()
    local class = PlayerClass()
    if not class then return nil end
    local seen = type(FarolCharDB) == "table" and FarolCharDB.supplySeen
    local list = {}
    for _, group in ipairs(SUPPLIES[class]) do
        local count
        if group.ammoSlot then
            count = SafeCount(GetInventoryItemCount, "player", 0) -- espaço da munição (aljava/bolsas)
        else
            for _, id in ipairs(group.ids) do
                local n = ItemCount(id)
                if n then count = (count or 0) + n end
            end
        end
        if count then
            if count > 0 and type(seen) == "table" then seen[group.key] = true end
            if count > 0 or (type(seen) == "table" and seen[group.key]) then
                local kind = group.kind or "reagent"
                local yellow, red = SupplyLimits(kind)
                local state = (red > 0 and count < red) and "out" or ((yellow > 0 and count < yellow) and "low" or "ok")
                list[#list + 1] = { key = group.key, kind = kind, count = count, yellow = yellow, red = red, state = state }
            end
        end
    end
    return list
end
ns.GetSupplies = GetSupplies

local SUPPLY_COLORS = { low = "|cffffff3a", out = "|cffff4040" }
local function SupplyText(s)
    local n = tostring(s.count)
    if SUPPLY_COLORS[s.state] then n = SUPPLY_COLORS[s.state] .. n .. "|r" end
    return T("sup_" .. s.key) .. " " .. n
end

local function GetJunk()
    local getSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not getSlots then return nil end
    local total, slots, pending, items, source = 0, 0, 0, {}, nil
    for bag = 0, LastBag() do
        local okSlots, count = pcall(getSlots, bag)
        count = (okSlots and ValidNumber(count, 200)) and count or 0
        for slot = 1, count do
            local item, stack, quality, noValue, from = ReadSlot(bag, slot)
            if item ~= nil then
                source = source or from
                local name, infoQuality, price = ItemPrice(item)
                if not ValidNumber(quality, 10) then quality = infoQuality end
                if name == nil then
                    if quality == 0 then pending = pending + 1 end
                elseif quality == 0 and not noValue and ValidNumber(price, 1e9) and price > 0 then
                    stack = ValidNumber(stack, 10000) and math.max(1, math.floor(stack)) or 1
                    local value = math.floor(price) * stack
                    total, slots = total + value, slots + 1
                    items[#items + 1] = { name = name, count = stack, value = value }
                end
            end
        end
    end
    table.sort(items, function(a, b) return a.value > b.value end)
    return { total = total, slots = slots, pending = pending, items = items }, source
end
ns.GetJunk = GetJunk -- usado pelo aviso de bolsas

local function GetSessionMoney()
    if not session.startMoney then return nil end
    return GetMoney() - session.startMoney
end

local function GetXPInfo()
    if IsPlayerAtEffectiveMaxLevel and IsPlayerAtEffectiveMaxLevel() then return nil end
    if GetMaxPlayerLevel and UnitLevel("player") >= GetMaxPlayerLevel() then return nil end
    local cur, max = UnitXP("player"), UnitXPMax("player")
    if not cur or not max or max <= 0 then return nil end
    local rested = (GetXPExhaustion and GetXPExhaustion()) or 0
    return cur, max, rested
end

-- Hora do servidor validada: horas inteiras 0-23 e minutos 0-59; qualquer outra coisa (bloqueado, NaN,
-- infinito, texto, fora da faixa) devolve nil. Usada pelo relógio, pelos alarmes e pelos resets.
local function GetServerClock()
    if type(GetGameTime) ~= "function" then return nil end
    local ok, hour, minute = pcall(GetGameTime)
    if not ok or type(hour) ~= "number" or type(minute) ~= "number" or IsSecret(hour) or IsSecret(minute) then
        return nil
    end
    if hour ~= math.floor(hour) or minute ~= math.floor(minute) then return nil end -- também recusa NaN/infinito
    if hour < 0 or hour > 23 or minute < 0 or minute > 59 then return nil end
    return hour, minute
end
ns.GetServerClock = GetServerClock

local function GetClockText(server)
    if server then
        local hour, minute = GetServerClock()
        if not hour then return "--" end
        return string.format("%02d:%02d", hour, minute)
    end
    return date("%H:%M")
end

local function GetSessionSeconds()
    if not session.startTime then return nil end
    return GetTime() - session.startTime
end
ns.GetSessionSeconds = GetSessionSeconds -- usado pelos avisos (lembrete de pausa)


local function FormatDuration(seconds)
    seconds = math.floor(seconds or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
    return string.format("%dm", minutes)
end
ns.FormatDuration = FormatDuration -- usado pelos avisos (lembrete de pausa)

-- Data de um momento salvo (segundos desde 1970), para as janelas de histórico.
-- Curta: "Hoje 21:42" / "Ontem 21:27" / "08/11 21:12" (o dia vem em cinza). Longa: "domingo, 08/11/2026 às 21:12".
-- Momento inválido (0, negativo, não-número) devolve "--". Os nomes vêm das traduções.
local function ListOf(key)
    local list = {}
    for name in string.gmatch(T(key), "[^,]+") do list[#list + 1] = name end
    return list
end

local function DateTokens(t)
    local tokens = {
        DD = date("%d", t), MM = date("%m", t), YYYY = date("%Y", t), YY = date("%y", t),
        HH = date("%H", t), MI = date("%M", t),
    }
    tokens.D = tostring(tonumber(tokens.DD) or tokens.DD)
    tokens.MON = ListOf("months")[tonumber(tokens.MM) or 0] or tokens.MM
    tokens.WEEKDAY = ListOf("weekdays_long")[(tonumber(date("%w", t)) or 0) + 1] or ""
    return tokens
end

local function FormatWhen(t, long)
    if type(t) ~= "number" or t ~= t or t <= 0 or t >= 4102444800 then return "--" end
    t = math.floor(t) -- segundos inteiros: date() recusa frações em motores Lua mais novos
    if t <= 0 then return "--" end
    local tokens = DateTokens(t)
    if long then return (string.gsub(T("when_long"), "%u+", tokens)) end
    local now = time()
    local day, today = date("%Y-%m-%d", t), date("%Y-%m-%d", now)
    -- Ontem = o dia de 3 h antes da meia-noite de hoje (funciona mesmo com horário de verão).
    local sinceMidnight = (tonumber(date("%H", now)) or 0) * 3600 + (tonumber(date("%M", now)) or 0) * 60
        + (tonumber(date("%S", now)) or 0)
    local yesterday = date("%Y-%m-%d", now - sinceMidnight - 3 * 3600)
    local label
    if day == today then
        label = T("when_today")
    elseif day == yesterday then
        label = T("when_yesterday")
    elseif tokens.YYYY == date("%Y", now) then
        label = string.gsub(T("when_date"), "%u+", tokens)
    else
        label = string.gsub(T("when_date_year"), "%u+", tokens)
    end
    return "|cff8c8c8c" .. label .. "|r " .. tokens.HH .. ":" .. tokens.MI
end
ns.FormatWhen = FormatWhen

-- Segundos até os resets, como o próprio jogo informa. Clientes modernos: C_DateAndTime;
-- antigos (3.3.5a): GetQuestResetTime (só o diário). Devolve diário, semanal e o nome de cada função.
local function ResetSeconds(fn, limit)
    if type(fn) ~= "function" then return nil end
    local ok, seconds = pcall(fn)
    if not ok or type(seconds) ~= "number" or IsSecret(seconds) or seconds ~= seconds then return nil end
    if seconds < 0 or seconds > limit then return nil end -- também recusa infinito
    return seconds
end

local function GetResetTimes()
    local daily, dailySource, weekly, weeklySource
    local dt = C_DateAndTime
    if type(dt) == "table" then
        daily = ResetSeconds(dt.GetSecondsUntilDailyReset, 2 * 86400)
        if daily then dailySource = "C_DateAndTime" end
        weekly = ResetSeconds(dt.GetSecondsUntilWeeklyReset, 8 * 86400)
        if weekly then weeklySource = "C_DateAndTime" end
    end
    if not daily then
        daily = ResetSeconds(GetQuestResetTime, 2 * 86400)
        if daily then dailySource = "GetQuestResetTime" end
    end
    return daily, weekly, dailySource, weeklySource
end
ns.GetResetTimes = GetResetTimes

-- Tempo curto com dias: "2d 4h", "5h 12m", "38m".
local function FormatCountdown(seconds)
    seconds = math.floor(seconds)
    if seconds >= 86400 then
        return string.format("%dd %dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end
    return FormatDuration(seconds)
end

-- Quando o reset acontece: dia da semana (se for depois de hoje) e hora local, mais a hora do servidor.
local function ResetMoment(seconds)
    local at = time() + math.floor(seconds)
    local localText = date("%H:%M", at)
    if seconds >= 86400 or date("%d", at) ~= date("%d") then
        local names = {}
        for name in string.gmatch(T("weekdays"), "[^,]+") do names[#names + 1] = name end
        local day = names[(tonumber(date("%w", at)) or 0) + 1]
        if day then localText = day .. " " .. localText end
    end
    local serverText = "--"
    local hour, minute = GetServerClock()
    if hour then
        local total = (hour * 60 + minute + math.floor(seconds / 60 + 0.5)) % 1440
        serverText = string.format("%02d:%02d", math.floor(total / 60), total % 60)
    end
    return localText, serverText
end

local function GetFriendsOnline()
    local wow = 0
    if C_FriendList and C_FriendList.GetNumOnlineFriends then
        wow = C_FriendList.GetNumOnlineFriends() or 0
    elseif GetNumFriends then
        local _, online = GetNumFriends()
        wow = online or 0
    end
    local bnet = 0
    if BNGetNumFriends then
        local _, online = BNGetNumFriends()
        bnet = online or 0
    end
    return wow, bnet -- só contagens: nenhum nome é lido ou guardado
end

local function GetGuildOnline()
    if not (IsInGuild and IsInGuild()) then return nil end
    local total, online = GetNumGuildMembers()
    if online == nil then -- clientes antigos devolvem só o total
        online = 0
        for i = 1, total or 0 do
            local isOnline = select(9, GetGuildRosterInfo(i))
            if isOnline then online = online + 1 end
        end
    end
    return online, total
end

-- A lista da guilda só atualiza quando pedida; pedimos no máximo a cada 60 s.
local lastRosterRequest = -60
local function RequestGuildRoster()
    if not (IsInGuild and IsInGuild()) then return end
    local now = GetTime()
    if now - lastRosterRequest < 60 then return end
    lastRosterRequest = now
    local request = (C_GuildInfo and C_GuildInfo.GuildRoster) or GuildRoster
    if request then request() end
end

-- Versão curta: omite unidades zeradas à esquerda (ex.: "45s 20c" em vez de "0g 45s 20c").
local function FormatMoneyShort(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    if gold > 0 then
        return string.format("|cffffd700%dg|r |cffc7c7cf%ds|r", gold, silver)
    elseif silver > 0 then
        return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", silver, cop)
    end
    return string.format("|cffeda55f%dc|r", cop)
end

local function FormatMoneyDelta(delta)
    if delta >= 0 then return GREEN .. "+|r" .. FormatMoneyShort(delta) end
    return RED .. "-|r" .. FormatMoneyShort(-delta)
end

-- 45200 -> "45.2k", 1250000 -> "1.3M"
local function FormatBig(n)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 1000 then return string.format("%.1fk", n / 1000) end
    return tostring(math.floor(n + 0.5))
end

-- XP por hora e segundos até o próximo nível (nil enquanto não há dados suficientes).
local function GetXPRate()
    local seconds = GetSessionSeconds()
    if not seconds or seconds < RATE_MIN_SECONDS or session.xpGained <= 0 then return nil end
    local perSecond = session.xpGained / seconds
    local cur, max = GetXPInfo()
    local toLevel = cur and (max - cur) / perSecond or nil
    return perSecond * 3600, toLevel
end

-- Ouro (em cobre) por hora; negativo quando você gastou mais do que ganhou.
local function GetGoldRate()
    local seconds = GetSessionSeconds()
    local delta = GetSessionMoney()
    if not seconds or not delta or seconds < RATE_MIN_SECONDS then return nil end
    return delta / seconds * 3600
end

-- Reputação por hora na facção acompanhada (nil antes de 1 minuto ou sem ganho).
local function GetRepRate()
    if not session.repStart or not session.repGained or session.repGained <= 0 then return nil end
    local seconds = GetTime() - session.repStart
    if seconds < RATE_MIN_SECONDS then return nil end
    return session.repGained / seconds * 3600
end

-- Nome do nível (Neutro, Honrado...) com a cor do próprio jogo.
local function StandingText(reaction)
    if reaction ~= math.floor(reaction) then return "?" end
    local label = _G["FACTION_STANDING_LABEL" .. reaction]
    if type(label) ~= "string" then label = tostring(reaction) end
    local color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
    if type(color) == "table" and type(color.r) == "number" and type(color.g) == "number"
            and type(color.b) == "number" then
        local function byte(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
        return string.format("|cff%02x%02x%02x%s|r", byte(color.r), byte(color.g), byte(color.b), label)
    end
    return label
end

---------------------------------------------------------------------------
-- Resumo da sessão: só números já calculados pela barra. Mostrado só no SEU chat.
---------------------------------------------------------------------------

local function CountSince(list, since, quality)
    local n = 0
    if type(list) ~= "table" or not since then return 0 end
    for _, entry in ipairs(list) do
        if type(entry) == "table" and type(entry.t) == "number" and entry.t >= since
                and (not quality or (type(entry.q) == "number" and quality(entry.q))) then
            n = n + 1
        end
    end
    return n
end

-- Fotografia numérica da sessão atual (é isso que fica salvo ao sair).
local function BuildSummary()
    local char = FarolCharDB or {}
    local okLevel, level = pcall(UnitLevel, "player")
    local levels = 0
    if okLevel and type(level) == "number" and not IsSecret(level) and session.startLevel then
        levels = math.max(0, level - session.startLevel)
    end
    local since = session.startClock
    return {
        t = time(),
        secs = math.floor(GetSessionSeconds() or 0),
        money = GetSessionMoney() or 0,
        xp = math.floor(session.xpGained or 0),
        levels = levels,
        rep = math.floor(session.repGained or 0),
        repName = session.repName,
        repFrom = session.repFrom,
        repTo = session.repTo,
        loot = CountSince(char.items, since),
        rare = CountSince(char.items, since, function(q) return q == 3 end),
        epic = CountSince(char.items, since, function(q) return q == 4 end),
        legend = CountSince(char.items, since, function(q) return q >= 5 end),
        warns = CountSince(char.warnHistory, since),
    }
end

-- Valida o resumo salvo (arquivo pode estar corrompido ou adulterado). Inválido = nil.
local function SanitizeSummary(saved)
    if type(saved) ~= "table" then return nil end
    local function int(v, lo, hi)
        if type(v) ~= "number" or v ~= v or v < lo or v > hi then return nil end
        return math.floor(v)
    end
    local t = int(saved.t, 1, 4102444799)
    if not t then return nil end
    local clean = {
        t = t,
        secs = int(saved.secs, 0, 30 * 86400) or 0,
        money = int(saved.money, -1e12, 1e12) or 0,
        xp = int(saved.xp, 0, 1e10) or 0,
        levels = int(saved.levels, 0, 100) or 0,
        rep = int(saved.rep, 0, 1e9) or 0,
        repFrom = int(saved.repFrom, 1, 8),
        repTo = int(saved.repTo, 1, 8),
        loot = int(saved.loot, 0, 100) or 0,
        rare = int(saved.rare, 0, 100) or 0,
        epic = int(saved.epic, 0, 100) or 0,
        legend = int(saved.legend, 0, 100) or 0,
        warns = int(saved.warns, 0, 10) or 0,
    }
    if type(saved.repName) == "string" and #saved.repName > 0 and #saved.repName <= 100 then
        clean.repName = saved.repName
    end
    return clean
end
ns.SanitizeSummary = SanitizeSummary

local function Plural(n, one, many)
    if n == 1 then return T(one) end
    return string.format(T(many), n)
end

-- Linhas de texto do resumo. "last" = resumo salvo da sessão anterior.
local function SummaryLines(s, last)
    local lines = {}
    if last then
        lines[1] = string.format(T("sum_last"), FormatWhen(s.t), FormatDuration(s.secs))
    else
        lines[1] = string.format(T("sum_title"), FormatDuration(s.secs))
    end
    local perHour = s.secs >= RATE_MIN_SECONDS and 3600 / s.secs or nil
    local parts = {}
    local gold = string.format(T("sum_gold"), FormatMoneyDelta(s.money))
    if perHour then
        local rate = s.money * perHour
        rate = rate >= 0 and math.floor(rate) or -math.floor(-rate)
        gold = gold .. " (" .. FormatMoneyDelta(rate) .. "/h)"
    end
    parts[#parts + 1] = gold
    if s.xp > 0 or s.levels > 0 then
        local xp = string.format(T("sum_xp"), FormatBig(s.xp))
        local extra = {}
        if s.levels > 0 then extra[#extra + 1] = Plural(s.levels, "sum_level1", "sum_levels") end
        if perHour and s.xp > 0 then extra[#extra + 1] = FormatBig(s.xp * perHour) .. "/h" end
        if #extra > 0 then xp = xp .. " (" .. table.concat(extra, ", ") .. ")" end
        parts[#parts + 1] = xp
    end
    lines[#lines + 1] = "  " .. table.concat(parts, " · ")
    if s.rep > 0 and s.repName then
        local text = string.format(T("sum_rep"), FormatBig(s.rep), FactionName(s.repName))
        if s.repFrom and s.repTo then
            local standing = StandingText(s.repTo)
            if s.repFrom ~= s.repTo then standing = StandingText(s.repFrom) .. " → " .. standing end
            text = text .. " (" .. standing .. ")"
        end
        lines[#lines + 1] = "  " .. text
    end
    local loot = string.format(T("sum_loot"), s.loot)
    local special = {}
    if s.rare > 0 then special[#special + 1] = Plural(s.rare, "sum_rare1", "sum_rares") end
    if s.epic > 0 then special[#special + 1] = Plural(s.epic, "sum_epic1", "sum_epics") end
    if s.legend > 0 then special[#special + 1] = Plural(s.legend, "sum_legend1", "sum_legends") end
    if #special > 0 then loot = loot .. " (" .. table.concat(special, ", ") .. ")" end
    lines[#lines + 1] = "  " .. loot .. " · " .. string.format(T("sum_warns"), s.warns)
    return lines
end

local function PrintSummary(s, last)
    local ok, lines = pcall(SummaryLines, s, last)
    if not ok then return end
    for _, line in ipairs(lines) do Print(line) end
end

local SUMMARY_MIN_SECONDS = 300 -- sessões com menos de 5 minutos não ficam salvas
local summaryShown = false      -- mostra a última sessão uma vez por carregamento

-- Ao sair (ou /reload): guarda a fotografia da sessão, se ela durou o bastante.
local function SaveSummary()
    if not FarolCharDB or not session.startTime then return end
    local ok, s = pcall(BuildSummary)
    if ok and s.secs >= SUMMARY_MIN_SECONDS then FarolCharDB.lastSession = s end
end

-- Ao entrar: mostra a última sessão só no login de verdade (não depois de /reload) e apaga o registro.
local function ShowLastSummary(isInitialLogin, isReloadingUi)
    if summaryShown then return end
    summaryShown = true
    local last = FarolCharDB and FarolCharDB.lastSession
    if not db.summary or not last then return end
    if isInitialLogin == false or isReloadingUi == true then return end
    -- Cliente antigo (sem esses argumentos): um /reload logo depois de salvar não conta como sessão nova.
    if isInitialLogin == nil and time() - last.t < 120 then return end
    PrintSummary(last, true)
    FarolCharDB.lastSession = nil
end

---------------------------------------------------------------------------
-- Orientação ao jogador: quase tudo vem desligado. Boas-vindas (primeira vez) ou novidades (atualização),
-- uma única vez, só no SEU chat. Nada é ligado sozinho: só informa.
---------------------------------------------------------------------------

-- Novidades em ordem; ao lançar algo novo, acrescente no FIM (quem atualizar vê só o que ainda não viu).
local NEWS = { "news_rep", "news_reset", "news_lootdates", "news_summary", "news_breaks", "news_remind",
               "news_prof", "news_junk", "news_alts", "news_rested", "news_locks",
               "news_tooltip", "news_supply" }
ns.NEWS = NEWS -- os testes conferem a lista inteira
local onboarding                -- "welcome", "news" ou nil (decidido ao carregar os dados salvos)
local onboardingShown = false

local function ItemCounts()
    local on = 0
    for _, key in ipairs(ITEM_ORDER) do if db.items[key] then on = on + 1 end end
    return on, #ITEM_ORDER
end

local function ShowNews(from)
    local names = {}
    for i = (from or 0) + 1, #NEWS do names[#names + 1] = T(NEWS[i]) end
    if #names == 0 then return end
    Print(T("news_title"))
    for _, name in ipairs(names) do Print("  • " .. name) end -- uma novidade por linha, mais fácil de ler
end

local function ShowOnboarding()
    if onboardingShown or not onboarding then return end
    onboardingShown = true
    if onboarding == "welcome" then
        local shown = {}
        for _, key in ipairs(ITEM_ORDER) do if db.items[key] then shown[#shown + 1] = T("name_" .. key) end end
        local on, total = ItemCounts()
        Print(string.format(T("welcome1"), table.concat(shown, ", ")))
        Print(string.format(T("welcome2"), total - on))
    else
        ShowNews(db.newsSeen)
    end
    db.newsSeen = #NEWS
end

-- No 3.3.5a as coordenadas dependem do mapa "ativo"; ao trocar de zona,
-- voltamos o mapa para a zona atual (sem mexer se o jogador estiver com o mapa aberto).
local function ResetMapToCurrentZone()
    if SetMapToCurrentZone and not (C_Map and C_Map.GetBestMapForUnit) then
        if not (WorldMapFrame and WorldMapFrame:IsShown()) then
            SetMapToCurrentZone()
        end
    end
end

---------------------------------------------------------------------------
-- Itens da barra: cada um devolve o texto que aparece no painel
---------------------------------------------------------------------------

local ITEM_TEXT = {
    fps = function()
        local fps = GetFPS()
        return string.format("%s%d|r fps", ColorHighIsGood(fps, 50, 25), fps)
    end,
    ms = function()
        local ms = GetLatency()
        return string.format("%s%d|r ms", ColorLowIsGood(ms, 100, 250), ms)
    end,
    coords = function()
        local x, y = GetCoords()
        if not x then return "--, --" end
        return string.format("%.1f, %.1f", x * 100, y * 100)
    end,
    zone = function()
        local zone = GetZones()
        if zone == "" then return nil end
        return "|cffffcc66" .. zone .. "|r"
    end,
    durab = function()
        local pct = durability.lowest
        if not pct then return nil end -- sem itens com durabilidade (ex.: personagem sem equipamento)
        return string.format("%s %s%d%%|r", T("label_durab"), ColorHighIsGood(pct, 50, 20), math.floor(pct))
    end,
    gold = function()
        local text = FormatMoney(GetMoney())
        if db.goldTotal then
            local list, total = RealmCharacters()
            if list and #list > 1 then
                text = text .. " |cffaaaaaa(" .. string.format(T("label_gold_total"), FormatMoneyShort(total)) .. ")|r"
            end
        end
        return text
    end,
    mem = function()
        local mb = GetMemoryMB()
        return string.format("%s %s%.0f MB|r", T("label_mem"), ColorLowIsGood(mb, 150, 400), mb)
    end,
    speed = function()
        local pct = GetSpeedPercent()
        if IsSecret(pct) then return "--" end
        return string.format("%s %d%%", T("label_speed"), math.floor(pct + 0.5))
    end,
    bags = function()
        local free, total = GetBagSpace()
        if not free then return nil end
        return string.format("%s %s%d|r/%d", T("label_bags"), ColorHighIsGood(free, 9, 3), free, total)
    end,
    session = function()
        local delta = GetSessionMoney()
        if not delta then return nil end
        return T("label_session") .. " " .. FormatMoneyDelta(delta)
    end,
    xp = function()
        local cur, max, rested = GetXPInfo()
        if not cur then return nil end -- nível máximo: o item some
        local textXP = string.format("XP %d%%", math.floor(cur / max * 100))
        if rested > 0 then
            textXP = textXP .. string.format(" |cff4da6ff+%d%%|r", math.floor(rested / max * 100))
        end
        return textXP
    end,
    clock = function()
        local clock = GetClockText(db.serverTime)
        if ns.Alarm and ns.Alarm.HasEnabled() then
            clock = clock .. " |TInterface\\Icons\\INV_Misc_PocketWatch_01:12:12|t" -- há alarme ativo
        end
        return clock
    end,
    rep = function()
        local f = GetWatchedFaction()
        if not ValidFaction(f) then return T("label_rep") .. " --" end
        local text = FactionName(f.name) .. " " .. StandingText(f.reaction)
        local _, _, pct = RepProgress(f)
        if pct then text = text .. string.format(" %d%%", pct) end
        local rate = GetRepRate()
        if rate then text = text .. " |cff4dff4d+" .. FormatBig(rate) .. "/h|r" end
        return text
    end,
    ammo = function()
        local list = GetSupplies()
        if not list then return nil end -- classe sem munição/reagentes: o item some
        if #list == 0 then return T("label_ammo") .. " --" end
        local parts = {}
        for _, s in ipairs(list) do parts[#parts + 1] = SupplyText(s) end
        return table.concat(parts, " · ")
    end,
    junk = function()
        local junk = GetJunk()
        if not junk then return T("label_junk") .. " --" end
        if junk.slots == 0 then return T("label_junk") .. " 0" end
        return T("label_junk") .. " " .. FormatMoneyShort(junk.total) .. " (" .. junk.slots .. ")"
    end,
    prof = function()
        local list = ReadProfessions()
        if not list or #list == 0 then return T("label_prof") .. " --" end
        local shown, parts = {}, {}
        for _, p in ipairs(list) do if p.primary then shown[#shown + 1] = p end end
        if #shown == 0 then shown = list end -- só secundárias: mostra essas
        for _, p in ipairs(shown) do parts[#parts + 1] = FactionName(p.name) .. " " .. ProfText(p) end
        return table.concat(parts, " · ")
    end,
    xph = function()
        if not GetXPInfo() then return nil end -- nível máximo: o item some
        local perHour, toLevel = GetXPRate()
        if not perHour then return T("label_xph") .. " --" end
        local text = T("label_xph") .. " " .. FormatBig(perHour)
        if toLevel then text = text .. " · " .. FormatDuration(toLevel) end
        return text
    end,
    goldh = function()
        local perHour = GetGoldRate()
        if not perHour then return T("label_goldh") .. " --" end
        local copper = perHour >= 0 and math.floor(perHour) or -math.floor(-perHour)
        return T("label_goldh") .. " " .. FormatMoneyDelta(copper)
    end,
    reset = function()
        local daily, weekly = GetResetTimes()
        if not daily and not weekly then return T("label_reset") .. " --" end
        local parts = {}
        if daily then parts[#parts + 1] = T("label_reset_daily") .. " " .. FormatCountdown(daily) end
        if weekly then parts[#parts + 1] = T("label_reset_weekly") .. " " .. FormatCountdown(weekly) end
        return table.concat(parts, " · ")
    end,
    playtime = function()
        local seconds = GetSessionSeconds()
        if not seconds then return nil end
        return T("label_playtime") .. " " .. FormatDuration(seconds)
    end,
    friends = function()
        local wow, bnet = GetFriendsOnline()
        return string.format("%s %d", T("label_friends"), wow + bnet)
    end,
    guild = function()
        local online = GetGuildOnline()
        if not online then return nil end -- sem guilda: o item some
        return string.format("%s %d", T("label_guild"), online)
    end,
}

---------------------------------------------------------------------------
-- Painel
---------------------------------------------------------------------------

-- Clientes modernos exigem o template "BackdropTemplate" para usar SetBackdrop; os antigos não o possuem.
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
ns.backdropTemplate = backdropTemplate

local frame = CreateFrame("Frame", "FarolFrame", UIParent, backdropTemplate)
frame:SetSize(330, 26)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

if frame.SetBackdrop then
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

-- Cada informação é uma "célula" (um texto próprio), posicionada numa grade de colunas
-- alinhadas à esquerda. O número de colunas depende da largura que o jogador escolher.
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") -- 1ª célula
text:SetJustifyH("LEFT")
text.farolCell = 1
-- Texto invisível usado só para medir a largura de cada informação e a altura de uma linha.
local measure = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
measure:Hide()
-- Fonte original da barra: só o tamanho muda (a fonte e o contorno continuam os do jogo).
local FONT_PATH, _, FONT_FLAGS = text:GetFont()
text:SetText("...")

-- Área invisível de mouse sobre o item: tooltip só deste item. Arrastar e clicar continuam indo para a barra.
local function AttachHover(cell)
    local hover = CreateFrame("Frame", nil, frame)
    hover:EnableMouse(true)
    if hover.RegisterForDrag then hover:RegisterForDrag("LeftButton") end
    local function forward(script)
        return function(_, ...)
            local handler = frame:GetScript(script)
            if handler then handler(frame, ...) end
        end
    end
    hover:SetScript("OnDragStart", forward("OnDragStart"))
    hover:SetScript("OnDragStop", forward("OnDragStop"))
    hover:SetScript("OnMouseUp", forward("OnMouseUp"))
    hover:SetScript("OnEnter", function() if ns.ShowTooltip then ns.ShowTooltip(frame, cell.farolKey) end end)
    hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hover:Hide()
    cell.hover = hover
end

local cells = { text }
AttachHover(text)
local function Cell(index)
    local cell = cells[index]
    if not cell then
        cell = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell:SetJustifyH("LEFT")
        cell.farolCell = index
        if FONT_PATH and db then cell:SetFont(FONT_PATH, db.fontSize, FONT_FLAGS) end
        AttachHover(cell)
        cells[index] = cell
    end
    return cell
end

local PAD_X, PAD_Y, GAP_X = 10, 4, 14 -- margens e espaço entre colunas (pixels)

-- Altura de uma linha: a altura real do texto (medida pelo jogo) ou do ícone, o que for maior.
local function LineHeight()
    measure:SetText("Ag")
    local textHeight = measure:GetStringHeight()
    if type(textHeight) ~= "number" or textHeight <= 0 then textHeight = db.fontSize end
    return math.max(textHeight, db.icons and db.iconSize or 0) + 3
end

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point, db.relPoint = point, relPoint
    db.x, db.y = math.floor(x + 0.5), math.floor(y + 0.5)
    FarolDB = db
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

frame:SetScript("OnDragStart", function(self)
    if db and not db.locked and not InCombatLockdown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then SavePosition() end
end)

-- Ícone de cada item (texturas do próprio jogo). Recorte 5..59 remove a borda do ícone.
local ITEM_ICONS = {
    fps = "INV_Misc_Spyglass_03",       ms = "Spell_Nature_Lightning",
    mem = "INV_Misc_Gear_01",           coords = "INV_Misc_Map_01",
    zone = "Spell_Nature_FarSight",     speed = "Ability_Rogue_Sprint",
    durab = "Trade_BlackSmithing",      bags = "INV_Misc_Bag_08",
    gold = "INV_Misc_Coin_01",          session = "INV_Misc_Coin_02",
    goldh = "INV_Misc_Coin_04",         xp = "INV_Misc_Book_09",
    xph = "Spell_Holy_BorrowedTime",    clock = "INV_Misc_PocketWatch_01",
    rep = "Achievement_Reputation_01",  reset = "INV_Misc_Note_06",
    prof = "Trade_Mining",              junk = "INV_Misc_Bone_HumanSkull_01",
    ammo = "INV_Ammo_Arrow_02",
    playtime = "INV_Misc_PocketWatch_02", friends = "Spell_Holy_PrayerOfFortitude",
    guild = "INV_Shirt_GuildTabard_01",
}
ns.ITEM_ICONS = ITEM_ICONS
ns.ITEM_ORDER = ITEM_ORDER -- ordem padrão; a ordem escolhida pelo jogador fica em db.order

local function IconTag(key)
    local icon = ITEM_ICONS[key]
    if not icon then return "" end
    local size = db.iconSize
    return "|TInterface\\Icons\\" .. icon .. ":" .. size .. ":" .. size .. ":0:0:64:64:5:59:5:59|t "
end

local isSizing = false   -- o jogador está arrastando a alça de largura
local layoutRows = 1     -- quantas linhas a barra tem agora

local function UpdateText()
    local parts, keys = {}, {}
    for _, key in ipairs(db.order or ITEM_ORDER) do -- ordem escolhida pelo jogador
        if db.items[key] then
            local ok, value = pcall(ITEM_TEXT[key])
            if not ok then value = "--" end
            if value then
                if db.icons then value = IconTag(key) .. value end
                parts[#parts + 1] = value
                keys[#parts] = key
            end
        end
    end

    if #parts == 0 then
        parts = { "|cff888888" .. T("none_shown") .. "|r" }
    end

    -- Largura de cada informação.
    local widths = {}
    for i, part in ipairs(parts) do
        measure:SetText(part)
        widths[i] = measure:GetStringWidth() or 0
    end

    -- Quantas colunas cabem: começa com tudo numa linha e reduz até caber na largura escolhida.
    -- Cada coluna tem a largura da maior informação dela (colunas alinhadas, como uma tabela).
    local n = #parts
    local available
    if isSizing then
        available = frame:GetWidth()            -- enquanto o jogador arrasta a alça
    elseif db.barWidth > 0 then
        available = db.barWidth                 -- largura escolhida (1 = uma coluna)
    end
    local cols, colWidths, total
    for c = n, 1, -1 do
        local w = {}
        for i = 1, n do
            local col = (i - 1) % c + 1
            w[col] = math.max(w[col] or 0, widths[i])
        end
        local sum = PAD_X * 2 + GAP_X * (c - 1)
        for col = 1, c do sum = sum + w[col] end
        if not available or sum <= available or c == 1 then
            cols, colWidths, total = c, w, sum
            break
        end
    end

    -- Posiciona cada célula na grade, alinhada à esquerda.
    local lineHeight = LineHeight()
    local colX, x = {}, PAD_X
    for col = 1, cols do
        colX[col] = x
        x = x + colWidths[col] + GAP_X
    end
    for i = 1, n do
        local cell = Cell(i)
        local row, col = math.floor((i - 1) / cols), (i - 1) % cols + 1
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", colX[col], -PAD_Y - row * lineHeight - 2)
        cell:SetText(parts[i])
        cell:Show()
        cell.farolKey = keys[i]
        cell.hover:ClearAllPoints()
        cell.hover:SetPoint("TOPLEFT", cell, "TOPLEFT", -GAP_X / 2, 2)
        cell.hover:SetSize(widths[i] + GAP_X, lineHeight)
        if keys[i] then cell.hover:Show() else cell.hover:Hide() end
    end
    for i = n + 1, #cells do cells[i]:Hide(); cells[i].hover:Hide() end

    layoutRows = math.ceil(n / cols)
    if not isSizing then frame:SetWidth(math.max(60, total)) end -- a barra encolhe até o conteúdo
    frame:SetHeight(math.max(26, PAD_Y * 2 + layoutRows * lineHeight))
    if ns.LayoutQuickButtons then ns.LayoutQuickButtons() end
end

-- Escala, fundo e borda.
local function ApplyAppearance()
    if ns.Warnings and ns.Warnings.UpdateButton then ns.Warnings.UpdateButton() end
    if ns.Loot and ns.Loot.UpdateButton then ns.Loot.UpdateButton() end
    frame:SetScale(db.scale)
    if FONT_PATH then
        for _, cell in ipairs(cells) do cell:SetFont(FONT_PATH, db.fontSize, FONT_FLAGS) end
        measure:SetFont(FONT_PATH, db.fontSize, FONT_FLAGS)
    end
    if frame.SetBackdropColor then
        frame:SetBackdropColor(0, 0, 0, db.bgAlpha)
        frame:SetBackdropBorderColor(0.4, 0.4, 0.4, db.border and 1 or 0)
    end
    UpdateText()
end

---------------------------------------------------------------------------
-- Tooltip (passar o mouse sobre o painel)
---------------------------------------------------------------------------

local WHITE = { 1, 1, 1 }
local GOLD_TXT = { 1, 0.82, 0 }

local function AddPair(label, value)
    GameTooltip:AddDoubleLine(label, value, GOLD_TXT[1], GOLD_TXT[2], GOLD_TXT[3], WHITE[1], WHITE[2], WHITE[3])
end

-- Listas longas: no máximo LIST_MAX linhas e um "e mais N" no fim.
local LIST_MAX = 5
local function More(count)
    if count > LIST_MAX then GameTooltip:AddLine("   " .. string.format(T("tt_more"), count - LIST_MAX), 0.6, 0.6, 0.6) end
end

-- Seções do tooltip. Cada item da barra mostra só as suas (TIP_SECTIONS); Shift ou a opção "Tooltip completo"
-- mostram todas, na ordem de TIP_ORDER.
local TIP = {}

TIP.perf = function()
    local fps = Safe(GetFPS)
    AddPair("FPS", fps and tostring(fps) or "--")
    local _, home, world = Safe(GetLatency)
    AddPair(T("tt_latency"), home and string.format(T("tt_lat_value"), home, world) or "--")
    local mb = Safe(GetMemoryMB)
    AddPair(T("tt_mem"), mb and string.format("%.1f MB", mb) or "--")
end

TIP.place = function()
    local x, y = GetCoords()
    AddPair(T("tt_coords"), x and string.format("%.1f, %.1f", x * 100, y * 100) or "--, --")
    local zone, sub = Safe(GetZones)
    AddPair(T("tt_zone"), (zone and zone ~= "") and zone or "--")
    if sub and sub ~= "" and sub ~= zone then AddPair(T("tt_subzone"), sub) end
    local speed = Safe(GetSpeedPercent)
    AddPair(T("tt_speed"), (speed and not IsSecret(speed)) and string.format("%d%%", math.floor(speed + 0.5)) or "--")
end

TIP.durab = function()
    if not durability.lowest then GameTooltip:AddLine(T("tt_no_gear"), 0.6, 0.6, 0.6) return end
    AddPair(T("tt_durab"), string.format("%s%d%%|r", ColorHighIsGood(durability.lowest, 50, 20), math.floor(durability.lowest)))
    if #durability.damaged == 0 then GameTooltip:AddLine(T("tt_all_ok"), 0.6, 0.6, 0.6) return end
    for i = 1, math.min(LIST_MAX, #durability.damaged) do
        local entry = durability.damaged[i]
        local link = Safe(GetInventoryItemLink, "player", entry.slot)
        if type(link) ~= "string" or IsSecret(link) then link = string.format(T("tt_slot"), entry.slot) end
        GameTooltip:AddDoubleLine("  " .. link, string.format("%s%d%%|r", ColorHighIsGood(entry.pct, 50, 20), math.floor(entry.pct)))
    end
    More(#durability.damaged)
end

TIP.gold = function()
    local money = Safe(GetMoney)
    AddPair(T("tt_gold"), money and FormatMoney(money) or "--")
    local delta = Safe(GetSessionMoney)
    if delta then AddPair(T("tt_session"), FormatMoneyDelta(delta)) end
    local goldRate = Safe(GetGoldRate)
    if goldRate then
        local copper = goldRate >= 0 and math.floor(goldRate) or -math.floor(-goldRate)
        AddPair(T("tt_goldh"), FormatMoneyDelta(copper))
    else
        AddPair(T("tt_goldh"), T("tt_rate_wait"))
    end
    local chars, charsTotal, realm = Safe(RealmCharacters)
    if chars and #chars > 1 then
        AddPair(string.format(T("tt_gold_total"), FactionName(realm)), FormatMoneyShort(charsTotal))
        for i = 1, math.min(LIST_MAX, #chars) do
            local c = chars[i]
            local when = c.current and T("tt_gold_this") or FormatWhen(c.t)
            GameTooltip:AddDoubleLine("   " .. FactionName(c.name) .. " (" .. c.level .. ")",
                FormatMoneyShort(c.gold) .. "  |cff8c8c8c" .. when .. "|r", 0.8, 0.8, 0.8, 1, 1, 1)
        end
        More(#chars)
    end
end

-- Seus outros personagens: descanso estimado e instâncias salvas.
TIP.alts = function()
    local rested = Safe(RestedAlts)
    if rested and #rested > 0 then
        GameTooltip:AddLine(T("tt_rest_title"), GOLD_TXT[1], GOLD_TXT[2], GOLD_TXT[3])
        for i = 1, math.min(LIST_MAX, #rested) do
            local r = rested[i]
            local status = r.full and ("|cff40ff40" .. T("tt_rest_full") .. "|r")
                or string.format(T("tt_rest_eta"), FormatCountdown(r.eta))
            local place = "|cff8c8c8c" .. (r.inn and T("tt_rest_inn") or T("tt_rest_out")) .. "|r"
            GameTooltip:AddDoubleLine("   " .. FactionName(r.name) .. " (" .. r.level .. ")",
                r.pct .. "%  " .. status .. "  " .. place, 0.8, 0.8, 0.8, 1, 1, 1)
        end
        More(#rested)
    end
    local altLocks = Safe(AltLockouts)
    if altLocks and #altLocks > 0 then
        GameTooltip:AddLine(T("tt_locks_alts"), GOLD_TXT[1], GOLD_TXT[2], GOLD_TXT[3])
        for i = 1, math.min(LIST_MAX, #altLocks) do
            local a = altLocks[i]
            GameTooltip:AddLine("   " .. FactionName(a.name) .. " (" .. a.level .. "): " .. table.concat(a.locks, ", "),
                0.8, 0.8, 0.8, true)
        end
        More(#altLocks)
    end
end

TIP.bags = function()
    local free, total = Safe(GetBagSpace)
    AddPair(T("tt_bags"), free and string.format("%d / %d", free, total) or "--")
end

TIP.supply = function()
    local list = Safe(GetSupplies)
    if not list then return end
    if #list == 0 then AddPair(T("tt_supply"), T("tt_supply_none")) return end
    for _, s in ipairs(list) do
        local value = tostring(s.count)
        if SUPPLY_COLORS[s.state] then value = SUPPLY_COLORS[s.state] .. value .. "|r" end
        AddPair(T("sup_" .. s.key), value)
    end
    local ay, ar = SupplyLimits("ammo")
    local ry, rr = SupplyLimits("reagent")
    local kind = list[1].kind
    AddPair(T("tt_supply_limits"), kind == "ammo" and (ay .. " / " .. ar) or (ry .. " / " .. rr))
    GameTooltip:AddLine(T("tt_supply_hint"), 0.6, 0.6, 0.6)
end

TIP.junk = function()
    local junk = Safe(GetJunk)
    if not junk then AddPair(T("tt_junk"), "--") return end
    AddPair(T("tt_junk"), junk.slots > 0 and FormatMoneyShort(junk.total) or "0")
    if junk.slots > 0 then
        AddPair(T("tt_junk_slots"), tostring(junk.slots))
        for i = 1, math.min(LIST_MAX, #junk.items) do
            local item = junk.items[i]
            local name = "   " .. FactionName(item.name) .. (item.count > 1 and (" x" .. item.count) or "")
            GameTooltip:AddDoubleLine(name, FormatMoneyShort(item.value), 0.62, 0.62, 0.62, 1, 1, 1)
        end
        More(#junk.items)
        GameTooltip:AddLine(T("tt_junk_hint"), 0.6, 0.6, 0.6)
    end
    if junk.pending > 0 then GameTooltip:AddLine(string.format(T("tt_junk_pending"), junk.pending), 0.6, 0.6, 0.6) end
end

TIP.xp = function()
    local cur, max, rested = Safe(GetXPInfo)
    if not cur then AddPair(T("tt_xp"), T("tt_maxlevel")) return end
    AddPair(T("tt_xp"), string.format("%d / %d (%d%%)", cur, max, math.floor(cur / max * 100)))
    if rested and rested > 0 then
        AddPair(T("tt_rested"), string.format("%d (%d%%)", rested, math.floor(rested / max * 100)))
    end
    local perHour, toLevel = Safe(GetXPRate)
    if perHour then
        AddPair(T("tt_xph"), FormatBig(perHour))
        if toLevel then AddPair(T("tt_tolevel"), FormatDuration(toLevel)) end
    else
        AddPair(T("tt_xph"), T("tt_rate_wait"))
    end
end

TIP.rep = function()
    local f = Safe(GetWatchedFaction)
    if not ValidFaction(f) then AddPair(T("tt_rep"), T("tt_rep_none")) return end
    AddPair(T("tt_rep"), FactionName(f.name))
    AddPair(T("tt_rep_standing"), StandingText(f.reaction))
    local cur, total, pct = RepProgress(f)
    if cur then
        AddPair(T("tt_rep_progress"), string.format("%s / %s (%d%%)", FormatBig(cur), FormatBig(total), pct))
        local rate = Safe(GetRepRate)
        if rate then
            AddPair(T("tt_rep_rate"), "+" .. FormatBig(rate))
            AddPair(T("tt_rep_next"), FormatDuration((total - cur) / rate * 3600))
        else
            AddPair(T("tt_rep_rate"), T("tt_rate_wait"))
        end
    end
end

TIP.prof = function()
    local list = Safe(ReadProfessions)
    if not list or #list == 0 then AddPair(T("tt_prof"), T("tt_prof_none")) return end
    for _, p in ipairs(list) do
        local value = ProfText(p)
        local gain = ProfGain(p)
        if gain > 0 then value = value .. string.format(T("tt_prof_gain"), gain) end
        AddPair(FactionName(p.name), value)
        if ProfState(p) == "cap" then GameTooltip:AddLine("   " .. T("tt_prof_cap"), 1, 0.4, 0.4) end
    end
end

TIP.clock = function()
    AddPair(T("tt_clock_local"), Safe(GetClockText, false) or "--")
    AddPair(T("tt_clock_server"), Safe(GetClockText, true) or "--")
    if ns.Alarm then pcall(ns.Alarm.AddTooltipLines, AddPair) end
end

TIP.reset = function()
    local daily, weekly = Safe(GetResetTimes)
    for _, entry in ipairs({ { "tt_reset_daily", daily }, { "tt_reset_weekly", weekly } }) do
        if entry[2] then
            local localText, serverText = ResetMoment(entry[2])
            AddPair(T(entry[1]), string.format(T("tt_reset_at"), FormatCountdown(entry[2]), localText, serverText))
        else
            AddPair(T(entry[1]), T("tt_reset_none"))
        end
    end
    RequestLockouts(false) -- no máximo uma vez por minuto
    local locks = Safe(ReadLockouts)
    if not locks then return end
    if #locks == 0 then
        AddPair(T("tt_locks"), locksLoaded and T("tt_locks_none") or T("tt_locks_wait"))
        return
    end
    GameTooltip:AddLine(T("tt_locks"), GOLD_TXT[1], GOLD_TXT[2], GOLD_TXT[3])
    for i = 1, math.min(LIST_MAX, #locks) do
        local l = locks[i]
        local value = string.format(T("tt_locks_reset"), FormatCountdown(l.reset))
        if l.killed then value = string.format(T("tt_locks_bosses"), l.killed, l.total) .. "  " .. value end
        GameTooltip:AddDoubleLine("   " .. l.name, value, 0.8, 0.8, 0.8, 1, 1, 1)
    end
    More(#locks)
end

TIP.playtime = function()
    local seconds = Safe(GetSessionSeconds)
    AddPair(T("tt_playtime"), seconds and FormatDuration(seconds) or "--")
end

TIP.social = function()
    local wow, bnet = Safe(GetFriendsOnline)
    AddPair(T("tt_friends"), wow and string.format(T("tt_friends_value"), wow, bnet) or "--")
    local gOnline, gTotal = Safe(GetGuildOnline)
    AddPair(T("tt_guild"), gOnline and string.format("%d / %d", gOnline, gTotal or 0) or T("tt_noguild"))
end

-- Item da barra -> seções do seu tooltip.
local TIP_SECTIONS = {
    fps = { "perf" }, ms = { "perf" }, mem = { "perf" },
    coords = { "place" }, zone = { "place" }, speed = { "place" },
    durab = { "durab" }, bags = { "bags", "junk" }, junk = { "junk", "bags" }, ammo = { "supply" },
    gold = { "gold", "alts" }, session = { "gold" }, goldh = { "gold" },
    xp = { "xp" }, xph = { "xp" }, rep = { "rep" }, prof = { "prof" },
    clock = { "clock" }, reset = { "reset" }, playtime = { "playtime" },
    friends = { "social" }, guild = { "social" },
}
ns.TIP_SECTIONS = TIP_SECTIONS

-- Tooltip completo: tudo, na ordem de sempre (rep, lixo, profissões e resets só se estiverem ligados na barra).
local TIP_ORDER = { "perf", "place", " ", "durab", " ", "gold", "alts", "bags", "xp", " ", "clock",
                    "rep", "junk", "supply", "prof", "reset", "playtime", "social" }
local TIP_NEEDS_ITEM = { rep = "rep", junk = "junk", supply = "ammo", prof = "prof", reset = "reset" }

local function FillTooltip(key, full)
    GameTooltip:AddLine(ICON .. " Farol", 0.2, 0.8, 1)
    if full or not key then -- tooltip completo: Shift, a opção, ou o mouse no fundo da barra
        do
            for _, section in ipairs(TIP_ORDER) do
                if section == " " then
                    GameTooltip:AddLine(" ")
                elseif not TIP_NEEDS_ITEM[section] or db.items[TIP_NEEDS_ITEM[section]] then
                    pcall(TIP[section])
                end
            end
        end
    else
        for _, section in ipairs(TIP_SECTIONS[key] or {}) do pcall(TIP[section]) end
    end
    GameTooltip:AddLine(" ")
    if not full then GameTooltip:AddLine(T("tt_shift_full"), 0.6, 0.6, 0.6) end
    GameTooltip:AddLine(db.locked and T("tt_locked") or T("tt_drag"), 0.6, 0.6, 0.6)
    local itemsOn, itemsTotal = ItemCounts()
    GameTooltip:AddLine(itemsOn < itemsTotal and string.format(T("tt_rightclick_more"), itemsTotal - itemsOn)
        or T("tt_rightclick"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(T("tt_help"), 0.6, 0.6, 0.6)
end

-- Qual item está sob o mouse (nil = fundo da barra). Shift ou a opção "Tooltip completo" mostram tudo.
local tipKey
local function ShiftDown()
    if not IsShiftKeyDown then return false end
    local ok, value = pcall(IsShiftKeyDown)
    return ok and value and true or false
end

local function ShowTooltip(_, key)
    if not db then return end
    tipKey = key
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    local full = db.tooltipFull or ShiftDown() or key == nil
    pcall(FillTooltip, key, full)
    GameTooltip:Show()
end
ns.ShowTooltip = ShowTooltip

frame:SetScript("OnEnter", function() ShowTooltip(frame, nil) end)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function TooltipIsOurs()
    return GameTooltip ~= nil and GameTooltip:IsShown() and GameTooltip.IsOwned ~= nil and GameTooltip:IsOwned(frame)
end

local elapsedSinceUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= UPDATE_INTERVAL then
        elapsedSinceUpdate = 0
        pcall(SampleXP) -- mede o XP antes de redesenhar, para a taxa não ficar atrasada
        pcall(SampleRep)
        if db.items.prof then pcall(SampleProfs) end
        pcall(RecordCharacter) -- ouro e nível deste personagem (para o total da conta)
        UpdateText()
        if db.items.guild then RequestGuildRoster() end
        if TooltipIsOurs() then ShowTooltip(self, tipKey) end -- mantém o tooltip atualizado (mesmo item)
    end
end)

ns.ApplyAppearance = function() ApplyAppearance() end

-- Alça no canto inferior direito: arrastar muda a LARGURA; a altura se ajusta sozinha.
-- Fica escondida com a barra travada, para não mudar o formato sem querer.
frame:SetResizable(true)
if frame.SetResizeBounds then
    frame:SetResizeBounds(60, 20, 4000, 2000)
else
    if frame.SetMinResize then frame:SetMinResize(60, 20) end
    if frame.SetMaxResize then frame:SetMaxResize(4000, 2000) end
end
local grip = CreateFrame("Button", "FarolBarResize", frame)
grip:SetSize(12, 12)
grip:SetPoint("BOTTOMRIGHT", -1, 1)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetScript("OnMouseDown", function()
    if db and not db.locked then
        isSizing = true
        frame:StartSizing("RIGHT")
    end
end)
grip:SetScript("OnMouseUp", function()
    if not isSizing then return end
    frame:StopMovingOrSizing()
    isSizing = false
    db.barWidth = math.max(2, math.floor(frame:GetWidth() + 0.5))
    SavePosition()
    UpdateText()
    if ns.Appearance then ns.Appearance.Refresh() end
end)
frame:SetScript("OnSizeChanged", function()
    if isSizing then UpdateText() end -- reorganiza ao vivo enquanto arrasta
end)

local function UpdateGrip()
    if db.locked then grip:Hide() else grip:Show() end
end
ns.UpdateGrip = UpdateGrip

-- Atalhos de formato (usados pela janela Aparência e pelos comandos).
function ns.SetBarWidth(width)
    db.barWidth = width
    UpdateText()
end
ns.UpdateText = function() UpdateText() end

-- Botões rápidos ao lado da barra (histórico de avisos, saques...), na ordem em que foram criados.
-- Os visíveis ficam encostados um no outro; se um some, o próximo encosta no anterior.
ns.quickButtons = {}
function ns.LayoutQuickButtons()
    local anchor = frame
    for _, button in ipairs(ns.quickButtons) do
        if button:IsShown() then
            button:ClearAllPoints()
            if anchor == frame and layoutRows > 1 then
                button:SetPoint("TOPLEFT", frame, "TOPRIGHT", 2, -4) -- várias linhas: no canto de cima
            else
                button:SetPoint("LEFT", anchor, "RIGHT", 2, 0)
            end
            button:SetSize(db.iconSize + 4, db.iconSize + 4) -- acompanha o tamanho dos ícones
            anchor = button
        end
    end
end
ns.frame = frame

-- Combate e instância: a barra some temporariamente se o jogador escolheu isso.
local inCombat = false

local function InHiddenInstance()
    if not (db.hideInstance and IsInInstance) then return false end
    local inside, kind = IsInInstance()
    return inside and kind ~= "none" and true or false
end

local function ApplyVisibility()
    local visible = db.shown
        and not (db.hideCombat and inCombat)
        and not InHiddenInstance()
    if visible then frame:Show() else frame:Hide() end
end

---------------------------------------------------------------------------
-- Ações (usadas pelos comandos e pelo menu de opções)
---------------------------------------------------------------------------

local RefreshOptions -- definida abaixo; sincroniza as caixinhas com as configurações

local function SetShown(value)
    db.shown = value
    ApplyVisibility()
    RefreshOptions()
end

local function SetLocked(value)
    db.locked = value
    UpdateGrip()
    RefreshOptions()
end

local function SetServerTime(value)
    db.serverTime = value
    UpdateText()
    RefreshOptions()
end

local function SetSummary(value)
    db.summary = value
    RefreshOptions()
end

local function SetGoldTotal(value)
    db.goldTotal = value
    UpdateText()
    RefreshOptions()
end

local function ResetPosition()
    db.point, db.relPoint, db.x, db.y = DEFAULTS.point, DEFAULTS.relPoint, DEFAULTS.x, DEFAULTS.y
    ApplyPosition()
end

local function SetLang(lang)
    db.lang = lang
    UpdateText()
    RefreshOptions()
    if ns.Alarm then ns.Alarm.Refresh() end
    if ns.Loot then ns.Loot.Refresh() end
    if ns.Warnings then ns.Warnings.Refresh() end
    if ns.Appearance then ns.Appearance.Refresh() end
    if ns.Order then ns.Order.Refresh() end
end

local function SetItemVisible(key, value)
    db.items[key] = value
    UpdateText()
    RefreshOptions()
    if ns.Order then ns.Order.Refresh() end -- atualiza o "escondido" na janela de ordem
end

---------------------------------------------------------------------------
-- Menu de opções (caixinhas para marcar)
-- Os mesmos controles aparecem na janela própria (/farol menu, clique direito)
-- e na lista de AddOns das configurações do jogo.
---------------------------------------------------------------------------

local controlSets = {} -- cada conjunto de controles criado (janela e painel de configurações)
local widgetCount = 0

local function NextName(kind)
    widgetCount = widgetCount + 1
    return "Farol" .. kind .. widgetCount
end

local function IsChecked(button)
    return button:GetChecked() and true or false -- 3.3.5a devolve 1/nil; clientes modernos, true/false
end

local function CreateHeader(parent, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, y)
    return header
end

local function CreateCheck(parent, x, y, onClick)
    local check = CreateFrame("CheckButton", NextName("Check"), parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, y)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check:SetScript("OnClick", function(self) onClick(IsChecked(self)) end)
    return check
end

local function CreateButton(parent, width, onClick)
    local button = CreateFrame("Button", NextName("Button"), parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetScript("OnClick", onClick)
    return button
end

-- Cria todos os controles dentro de "parent", começando na altura "top".
local function BuildControls(parent, top)
    local set = { items = {}, langs = {} }
    local y = top

    set.hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    set.hint:SetPoint("TOPLEFT", 16, y)
    y = y - 22

    set.itemsHeader = CreateHeader(parent, y)
    y = y - 20
    -- Duas colunas para caber todos os itens.
    local perColumn = math.ceil(#ITEM_ORDER / 2)
    for index, key in ipairs(ITEM_ORDER) do
        local column = (index > perColumn) and 1 or 0
        local row = (index - 1) % perColumn
        set.items[key] = CreateCheck(parent, 20 + column * 165, y - row * 26,
            function(value) SetItemVisible(key, value) end)
        -- Passar o mouse: o que este item mostra.
        set.items[key]:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("name_" .. key))
            GameTooltip:AddLine(T("desc_" .. key), 1, 1, 1, true)
            GameTooltip:Show()
        end)
        set.items[key]:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    y = y - perColumn * 26

    y = y - 10
    set.generalHeader = CreateHeader(parent, y)
    y = y - 20
    set.shown = CreateCheck(parent, 20, y, SetShown)
    set.locked = CreateCheck(parent, 185, y, SetLocked)
    y = y - 26
    set.serverTime = CreateCheck(parent, 20, y, SetServerTime)
    set.summary = CreateCheck(parent, 185, y, SetSummary)
    y = y - 26
    set.goldTotal = CreateCheck(parent, 20, y, SetGoldTotal)
    y = y - 36

    set.langHeader = CreateHeader(parent, y)
    y = y - 22
    local x = 20
    for _, entry in ipairs({ { "auto", "Auto" }, { "pt", "Português" }, { "en", "English" } }) do
        local lang, label = entry[1], entry[2]
        local button = CreateButton(parent, 84, function() SetLang(lang) end)
        button:SetPoint("TOPLEFT", x, y)
        button:SetText(label)
        set.langs[lang] = button
        x = x + 88
    end
    y = y - 36

    set.reset = CreateButton(parent, 150, function() ResetPosition() end)
    set.reset:SetPoint("TOPLEFT", 20, y)
    set.alarms = CreateButton(parent, 150, function() ns.Alarm.ToggleWindow() end)
    set.alarms:SetPoint("TOPLEFT", 176, y)
    y = y - 26
    set.loot = CreateButton(parent, 150, function() ns.Loot.ToggleWindow() end)
    set.loot:SetPoint("TOPLEFT", 20, y)
    set.sessionReset = CreateButton(parent, 150, function()
        ResetSession()
        UpdateText()
        Print(T("session_reset"))
    end)
    set.sessionReset:SetPoint("TOPLEFT", 176, y)
    y = y - 26
    set.warnings = CreateButton(parent, 150, function() ns.Warnings.ToggleWindow() end)
    set.warnings:SetPoint("TOPLEFT", 20, y)
    set.appearance = CreateButton(parent, 150, function() ns.Appearance.ToggleWindow() end)
    set.appearance:SetPoint("TOPLEFT", 176, y)
    y = y - 26
    set.order = CreateButton(parent, 150, function() ns.Order.ToggleWindow() end)
    set.order:SetPoint("TOPLEFT", 20, y)
    -- "Esquecer personagens": pede um segundo clique (em até 5 s) para confirmar.
    set.forget = CreateButton(parent, 150, nil)
    set.forget:SetScript("OnClick", function(self)
        local now = GetTime()
        if self.confirmAt and now - self.confirmAt <= 5 then
            self.confirmAt = nil
            ForgetCharacters(nil)
            UpdateText()
        else
            self.confirmAt = now
            self:SetText(T("opt_forget_confirm"))
            return
        end
        RefreshOptions()
    end)
    set.forget:SetPoint("TOPLEFT", 176, y)
    y = y - 30

    controlSets[#controlSets + 1] = set
    return set, y
end

RefreshOptions = function()
    if not db then return end
    for _, set in ipairs(controlSets) do
        local on, total = ItemCounts()
        set.hint:SetText(string.format(T("opt_hint_count"), on, total))
        set.itemsHeader:SetText(T("opt_items"))
        set.generalHeader:SetText(T("opt_general"))
        set.langHeader:SetText(T("opt_lang"))
        for key, check in pairs(set.items) do
            check.label:SetText(T("name_" .. key))
            check:SetChecked(db.items[key])
        end
        set.shown.label:SetText(T("opt_shown"))
        set.shown:SetChecked(db.shown)
        set.locked.label:SetText(T("opt_locked"))
        set.locked:SetChecked(db.locked)
        set.serverTime.label:SetText(T("opt_servertime"))
        set.serverTime:SetChecked(db.serverTime)
        set.summary.label:SetText(T("opt_summary"))
        set.summary:SetChecked(db.summary)
        set.goldTotal.label:SetText(T("opt_goldtotal"))
        set.goldTotal:SetChecked(db.goldTotal)
        set.forget.confirmAt = nil
        set.forget:SetText(T("opt_forget"))
        for lang, button in pairs(set.langs) do
            if lang == db.lang then button:LockHighlight() else button:UnlockHighlight() end
        end
        set.reset:SetText(T("opt_reset"))
        set.alarms:SetText(T("opt_alarms"))
        set.loot:SetText(T("opt_loot"))
        set.sessionReset:SetText(T("opt_session_reset"))
        set.warnings:SetText(T("opt_warnings"))
        set.appearance:SetText(T("opt_appearance"))
        set.order:SetText(T("opt_order"))
    end
end

-- Janela própria, criada só na primeira vez que for aberta.
local optionsWindow

local function CreateOptionsWindow()
    local window = CreateFrame("Frame", "FarolOptions", UIParent, backdropTemplate)
    window:SetFrameStrata("DIALOG")
    window:SetPoint("CENTER")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)

    if window.SetBackdrop then
        window:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText(ICON .. " Farol")

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local _, bottom = BuildControls(window, -46)
    window:SetSize(350, -bottom + 12)

    window:SetScript("OnShow", RefreshOptions)
    tinsert(UISpecialFrames, "FarolOptions") -- ESC fecha a janela
    ns.MakeToplevel(window) -- abre na frente e vem para a frente ao clicar
    window:Hide()
    return window
end

local function ToggleOptions()
    optionsWindow = optionsWindow or CreateOptionsWindow()
    if optionsWindow:IsShown() then
        optionsWindow:Hide()
    else
        optionsWindow:Show()
    end
end

-- Também aparece em Esc > Opções > AddOns (clientes modernos) ou Interface > AddOns (antigos).
local function RegisterSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Farol"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ICON .. " Farol")

    BuildControls(panel, -46)
    panel:SetScript("OnShow", RefreshOptions)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

ns.ApplyVisibility = function() ApplyVisibility() end

-- Clique direito no painel abre o menu.
frame:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" and db then ToggleOptions() end
end)

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT") -- guardar o resumo da sessão (também acontece no /reload)
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("UPDATE_FACTION")
pcall(frame.RegisterEvent, frame, "UPDATE_INSTANCE_INFO") -- resposta do RequestRaidInfo
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- entrou em combate
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- saiu do combate

frame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        local saved = Profiles.Flatten(FarolDB) -- 2.x e 3.x viram a mesma visão, validada abaixo como sempre
        db = SanitizeDB(saved)
        -- Nova instalação = sem dados salvos. Quem já usava (dados sem "newsSeen") vê as novidades uma vez.
        if type(saved) ~= "table" or next(saved) == nil then
            onboarding = "welcome"
        else
            local seen = saved.newsSeen
            if type(seen) ~= "number" or seen ~= seen or seen < 0 then seen = 0 end
            db.newsSeen = math.min(math.floor(seen), #NEWS)
            if db.newsSeen < #NEWS then onboarding = "news" end
        end
        db.alarms = ns.Alarm.Sanitize(type(saved) == "table" and saved.alarms or nil)
        db.loot = ns.Loot.SanitizeSettings(type(saved) == "table" and saved.loot or nil)
        db.warnings = ns.Warnings.Sanitize(type(saved) == "table" and saved.warnings or nil)
        db.order = ns.Order.Sanitize(type(saved) == "table" and saved.order or nil)
        db.chars = SanitizeChars(type(saved) == "table" and saved.chars or nil)
        db = Profiles.Build(db) -- formato 3.x: campos da barra em profiles.account.bars[1]
        FarolDB = db
        local savedChar = FarolCharDB
        FarolCharDB = ns.Loot.SanitizeHistory(savedChar) -- histórico de saques deste personagem
        FarolCharDB.warnHistory = ns.Warnings.SanitizeHistory(type(savedChar) == "table" and savedChar.warnHistory or nil)
        FarolCharDB.lastSession = SanitizeSummary(type(savedChar) == "table" and savedChar.lastSession or nil)
        -- Reagentes que este personagem já teve (só chaves conhecidas, só "true").
        local seenSaved, seen = type(savedChar) == "table" and savedChar.supplySeen, {}
        if type(seenSaved) == "table" then
            for _, groups in pairs(SUPPLIES) do
                for _, group in ipairs(groups) do
                    if seenSaved[group.key] == true then seen[group.key] = true end
                end
            end
        end
        FarolCharDB.supplySeen = seen
        ApplyPosition()
        UpdateGrip()
        ApplyAppearance()
        ApplyVisibility()
        pcall(RegisterSettingsPanel) -- se a API de configurações mudar, o addon continua funcionando
        self:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not db then return end

    if event == "PLAYER_LOGOUT" then
        SaveSummary()
        pcall(RecordCharacter, true) -- grava o descanso e se está em estalagem/cidade ao sair
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        pcall(ShowLastSummary, arg1, arg2) -- antes de StartSession: o registro é da sessão anterior
        pcall(ShowOnboarding)
        RequestLockouts(arg1 == true) -- login: pede já; troca de zona (ou cliente antigo): no máximo 1x por minuto
        StartSession()
        pcall(RecordCharacter)
        ResetMapToCurrentZone()
        ScanDurability()
        local okCombat, combat = pcall(function() return InCombatLockdown and InCombatLockdown() end)
        inCombat = okCombat and combat and true or false
        ApplyVisibility()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ResetMapToCurrentZone()
        ApplyVisibility()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        inCombat = (event == "PLAYER_REGEN_DISABLED")
        ApplyVisibility()
    elseif event == "UPDATE_INSTANCE_INFO" then
        locksLoaded = true
        pcall(RecordCharacter, true)
    elseif event == "UPDATE_FACTION" then
        pcall(SampleRep)
    elseif event == "PLAYER_XP_UPDATE" then
        pcall(SampleXP)
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ScanDurability()
    end
    UpdateText()
end)

---------------------------------------------------------------------------
-- Comandos: /farol
---------------------------------------------------------------------------

local function ShowHelp()
    Print(T("help_title"))
    for _, key in ipairs({ "help_toggle", "help_menu", "help_lock", "help_reset", "help_show",
                           "help_hide", "help_items", "help_alarm", "help_alarm2", "help_alarm3", "help_loot", "help_session", "help_summary", "help_gold", "help_locks", "help_news", "help_warn", "help_history", "help_appearance", "help_order",
                           "help_version", "help_lang" }) do
        Print(T(key))
    end
end

local function ListItems()
    Print(T("items_title"))
    for _, key in ipairs(ITEM_ORDER) do
        local name = T("name_" .. key) .. " (" .. T("cmd_" .. key) .. ")"
        Print("  " .. string.format(db.items[key] and T("item_on") or T("item_off"), name))
    end
end

local function SetItem(alias, visible)
    local key = ITEM_ALIASES[alias] -- só nomes da lista fixa são aceitos
    if not key then
        local names = {}
        for _, k in ipairs(ITEM_ORDER) do names[#names + 1] = T("cmd_" .. k) end
        Print(T("item_usage") .. " " .. table.concat(names, " || ")) -- "||" = barra literal no chat do WoW
        return
    end
    SetItemVisible(key, visible)
    Print(string.format(visible and T("item_on") or T("item_off"), T("name_" .. key)))
end

SLASH_FAROL1 = "/farol"
SlashCmdList["FAROL"] = function(msg)
    if not db then return end
    -- Aceita só palavras simples (letras); qualquer outra coisa mostra a ajuda.
    local cmd, arg = string.match(msg or "", "^%s*(%a*)%s*(%a*)")
    local rest = string.match(msg or "", "^%s*%a*%s*(.-)%s*$") or "" -- usado pelos alarmes (aceita 07:30 e nomes)
    cmd, arg = string.lower(cmd or ""), string.lower(arg or "")

    if cmd == "" then
        SetShown(not db.shown)
        Print(db.shown and T("shown") or T("hidden"))
    elseif cmd == "menu" or cmd == "config" or cmd == "opcoes" or cmd == "options" then
        ToggleOptions()
    elseif cmd == "lock" or cmd == "travar" then
        SetLocked(not db.locked)
        Print(db.locked and T("locked") or T("unlocked"))
    elseif cmd == "reset" then
        ResetPosition()
        Print(T("reset"))
    elseif cmd == "show" or cmd == "mostrar" then
        SetItem(arg, true)
    elseif cmd == "hide" or cmd == "esconder" or cmd == "ocultar" then
        SetItem(arg, false)
    elseif cmd == "items" or cmd == "itens" then
        ListItems()
    elseif cmd == "lang" or cmd == "idioma" then
        if VALID_LANGS[arg] then
            SetLang(arg)
            Print(arg == "auto" and T("lang_auto") or T("lang_set"))
        else
            Print(T("lang_usage"))
        end
    elseif cmd == "alarme" or cmd == "alarmes" or cmd == "alarm" or cmd == "alarms" then
        ns.Alarm.HandleCommand(rest)
    elseif cmd == "ordem" or cmd == "order" then
        ns.Order.HandleCommand(rest)
    elseif cmd == "aparencia" or cmd == "appearance" or cmd == "look" then
        ns.Appearance.HandleCommand(rest)
    elseif cmd == "historico" or cmd == "history" then
        ns.Warnings.ToggleHistory()
    elseif cmd == "aviso" or cmd == "avisos" or cmd == "warn" or cmd == "warning" or cmd == "warnings" then
        ns.Warnings.HandleCommand(rest)
    elseif cmd == "instancias" or cmd == "instancia" or cmd == "lockouts" or cmd == "lockout" or cmd == "raides" then
        RequestLockouts(false)
        local locks = ReadLockouts() or {}
        if #locks == 0 then
            Print(T("locks_none"))
        else
            Print(T("locks_title"))
            for _, l in ipairs(locks) do
                local value = string.format(T("tt_locks_reset"), FormatCountdown(l.reset))
                if l.killed then value = string.format(T("tt_locks_bosses"), l.killed, l.total) .. " · " .. value end
                Print("  " .. l.name .. " — " .. value)
            end
        end
        local alts = AltLockouts()
        if alts and #alts > 0 then
            Print(T("locks_alts"))
            for _, a in ipairs(alts) do
                Print("  " .. FactionName(a.name) .. " (" .. a.level .. "): " .. table.concat(a.locks, ", "))
            end
        end
    elseif cmd == "novidades" or cmd == "news" then
        ShowNews(0)
    elseif cmd == "ouro" or cmd == "gold" then
        local word, target = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
        word, target = string.lower(word or ""), target or ""
        local switch = string.lower(target)
        if word == "total" and (switch == "on" or switch == "ligar") then
            SetGoldTotal(true); Print(T("gold_total_on"))
        elseif word == "total" and (switch == "off" or switch == "desligar") then
            SetGoldTotal(false); Print(T("gold_total_off"))
        elseif (word == "esquecer" or word == "forget") and target ~= "" then
            ForgetCharacters(string.sub(target, 1, 48))
            UpdateText()
        else
            pcall(RecordCharacter)
            local list, total, realm = RealmCharacters()
            if list then
                Print(string.format(T("gold_list"), (string.gsub(realm, "|", "||")), FormatMoneyShort(total)))
                for _, c in ipairs(list) do
                    Print("  " .. FactionName(c.name) .. " (" .. c.level .. "): " .. FormatMoneyShort(c.gold)
                        .. (c.current and (" — " .. T("tt_gold_this")) or ""))
                end
            end
        end
    elseif cmd == "resumo" or cmd == "summary" then
        if arg == "on" or arg == "ligar" then
            SetSummary(true); Print(T("sum_on"))
        elseif arg == "off" or arg == "desligar" then
            SetSummary(false); Print(T("sum_off"))
        else
            pcall(SampleXP); pcall(SampleRep)
            local ok, s = pcall(BuildSummary)
            if ok then PrintSummary(s, false) end
        end
    elseif (cmd == "sessao" or cmd == "session") and (arg == "zerar" or arg == "reset") then
        ResetSession()
        UpdateText()
        Print(T("session_reset"))
    elseif cmd == "saque" or cmd == "saques" or cmd == "loot" then
        ns.Loot.HandleCommand(rest)
    elseif cmd == "soneca" or cmd == "snooze" then
        ns.Alarm.Snooze(rest) -- "/farol soneca 10" adia só desta vez por 10 min
    elseif cmd == "parar" or cmd == "stop" then
        ns.Alarm.Stop()
    elseif cmd == "version" or cmd == "versao" then
        local version, build, date, interface = GetBuildInfo()
        -- Clientes muito antigos não retornam o 4º valor; deduzimos pela versão.
        if not interface and type(version) == "string" then
            local major, minor = string.match(version, "^(%d+)%.(%d+)")
            if major then interface = string.format("%d%02d00", tonumber(major), tonumber(minor)) end
        end
        Print(string.format(T("version"),
            tostring(version), tostring(build), tostring(date), tostring(interface)))
        Print(T("version_hint"))
    else
        ShowHelp()
    end
end
