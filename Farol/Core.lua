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
    "fps", "ms", "mem", "coords", "zone", "speed", "durab", "bags",
    "gold", "session", "goldh", "xp", "xph", "rep", "clock", "reset", "playtime", "friends", "guild",
}

-- Visível por padrão? Os itens originais vêm ligados; os novos, desligados (ative no menu).
local ITEM_DEFAULTS = {
    fps = true, ms = true, coords = true, zone = true, durab = true, gold = true,
    mem = false, speed = false, bags = false, session = false, xp = false,
    goldh = false, xph = false, rep = false,
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
        label_playtime = "Jogando",
        label_reset  = "Reset",
        label_reset_daily = "Diário",
        label_reset_weekly = "Semanal",
        label_friends = "Amigos",
        label_guild  = "Guilda",
        opt_servertime = "Horário do servidor",
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
        label_playtime = "Played",
        label_reset  = "Reset",
        label_reset_daily = "Daily",
        label_reset_weekly = "Weekly",
        label_friends = "Friends",
        label_guild  = "Guild",
        opt_servertime = "Server time",
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

-- Soma a reputação ganha na facção acompanhada; trocar de facção recomeça a contagem.
local function SampleRep()
    local f = GetWatchedFaction()
    if not ValidFaction(f) then return end
    if session.repID ~= f.id then
        session.repID, session.repLast, session.repGained, session.repStart = f.id, f.value, 0, GetTime()
        return
    end
    if f.value > session.repLast then
        session.repGained = session.repGained + (f.value - session.repLast)
    end
    session.repLast = f.value
end

local function ResetSession()
    session.startMoney = GetMoney()
    session.startTime = GetTime()
    session.xpGained = 0
    session.lastXP = nil
    session.repID = nil -- recomeça a contagem de reputação
    pcall(SampleXP)
    pcall(SampleRep)
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

local function GetBagSpace()
    local getFree = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    local getSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not getFree or not getSlots then return nil end
    local free, total = 0, 0
    for bag = 0, (NUM_BAG_SLOTS or 4) do
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


local function FormatDuration(seconds)
    seconds = math.floor(seconds or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
    return string.format("%dm", minutes)
end

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
        return FormatMoney(GetMoney())
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

local cells = { text }
local function Cell(index)
    local cell = cells[index]
    if not cell then
        cell = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell:SetJustifyH("LEFT")
        cell.farolCell = index
        if FONT_PATH and db then cell:SetFont(FONT_PATH, db.fontSize, FONT_FLAGS) end
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
    local parts = {}
    for _, key in ipairs(db.order or ITEM_ORDER) do -- ordem escolhida pelo jogador
        if db.items[key] then
            local ok, value = pcall(ITEM_TEXT[key])
            if not ok then value = "--" end
            if value then
                if db.icons then value = IconTag(key) .. value end
                parts[#parts + 1] = value
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
    end
    for i = n + 1, #cells do cells[i]:Hide() end

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

local function FillTooltip()
    GameTooltip:AddLine(ICON .. " Farol", 0.2, 0.8, 1)

    local fps = Safe(GetFPS)
    AddPair("FPS", fps and tostring(fps) or "--")

    local _, home, world = Safe(GetLatency)
    AddPair(T("tt_latency"), home and string.format(T("tt_lat_value"), home, world) or "--")

    local mb = Safe(GetMemoryMB)
    AddPair(T("tt_mem"), mb and string.format("%.1f MB", mb) or "--")

    local x, y = GetCoords()
    AddPair(T("tt_coords"), x and string.format("%.1f, %.1f", x * 100, y * 100) or "--, --")

    local zone, sub = Safe(GetZones)
    AddPair(T("tt_zone"), (zone and zone ~= "") and zone or "--")
    if sub and sub ~= "" and sub ~= zone then
        AddPair(T("tt_subzone"), sub)
    end
    local speed = Safe(GetSpeedPercent)
    AddPair(T("tt_speed"), (speed and not IsSecret(speed)) and string.format("%d%%", math.floor(speed + 0.5)) or "--")

    GameTooltip:AddLine(" ")
    if durability.lowest then
        AddPair(T("tt_durab"), string.format("%s%d%%|r",
            ColorHighIsGood(durability.lowest, 50, 20), math.floor(durability.lowest)))
        if #durability.damaged == 0 then
            GameTooltip:AddLine(T("tt_all_ok"), 0.6, 0.6, 0.6)
        else
            for _, entry in ipairs(durability.damaged) do
                local link = Safe(GetInventoryItemLink, "player", entry.slot)
                if type(link) ~= "string" or IsSecret(link) then
                    link = string.format(T("tt_slot"), entry.slot)
                end
                GameTooltip:AddDoubleLine("  " .. link, string.format("%s%d%%|r",
                    ColorHighIsGood(entry.pct, 50, 20), math.floor(entry.pct)))
            end
        end
    else
        GameTooltip:AddLine(T("tt_no_gear"), 0.6, 0.6, 0.6)
    end

    GameTooltip:AddLine(" ")
    local money = Safe(GetMoney)
    AddPair(T("tt_gold"), money and FormatMoney(money) or "--")
    local goldRate = Safe(GetGoldRate)
    local delta = Safe(GetSessionMoney)
    if delta then AddPair(T("tt_session"), FormatMoneyDelta(delta)) end
    if goldRate then
        local copper = goldRate >= 0 and math.floor(goldRate) or -math.floor(-goldRate)
        AddPair(T("tt_goldh"), FormatMoneyDelta(copper))
    else
        AddPair(T("tt_goldh"), T("tt_rate_wait"))
    end
    local free, total = Safe(GetBagSpace)
    if free then AddPair(T("tt_bags"), string.format("%d / %d", free, total)) end

    local cur, max, rested = Safe(GetXPInfo)
    if cur then
        AddPair(T("tt_xp"), string.format("%d / %d (%d%%)", cur, max, math.floor(cur / max * 100)))
        if rested and rested > 0 then
            AddPair(T("tt_rested"), string.format("%d (%d%%)", rested, math.floor(rested / max * 100)))
        end
    else
        AddPair(T("tt_xp"), T("tt_maxlevel"))
    end

    GameTooltip:AddLine(" ")
    AddPair(T("tt_clock_local"), Safe(GetClockText, false) or "--")
    AddPair(T("tt_clock_server"), Safe(GetClockText, true) or "--")
    if ns.Alarm then pcall(ns.Alarm.AddTooltipLines, AddPair) end
    if Safe(GetXPInfo) then
        local perHour, toLevel = Safe(GetXPRate)
        if perHour then
            AddPair(T("tt_xph"), FormatBig(perHour))
            if toLevel then AddPair(T("tt_tolevel"), FormatDuration(toLevel)) end
        else
            AddPair(T("tt_xph"), T("tt_rate_wait"))
        end
    end
    if db.items.rep then
        local f = Safe(GetWatchedFaction)
        if ValidFaction(f) then
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
        else
            AddPair(T("tt_rep"), T("tt_rep_none"))
        end
    end
    if db.items.reset then
        local daily, weekly = Safe(GetResetTimes)
        for _, entry in ipairs({ { "tt_reset_daily", daily }, { "tt_reset_weekly", weekly } }) do
            if entry[2] then
                local localText, serverText = ResetMoment(entry[2])
                AddPair(T(entry[1]), string.format(T("tt_reset_at"), FormatCountdown(entry[2]), localText, serverText))
            else
                AddPair(T(entry[1]), T("tt_reset_none"))
            end
        end
    end
    local seconds = Safe(GetSessionSeconds)
    if seconds then AddPair(T("tt_playtime"), FormatDuration(seconds)) end

    local wow, bnet = Safe(GetFriendsOnline)
    AddPair(T("tt_friends"), wow and string.format(T("tt_friends_value"), wow, bnet) or "--")
    local gOnline, gTotal = Safe(GetGuildOnline)
    AddPair(T("tt_guild"), gOnline and string.format("%d / %d", gOnline, gTotal or 0) or T("tt_noguild"))

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(db.locked and T("tt_locked") or T("tt_drag"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(T("tt_rightclick"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(T("tt_help"), 0.6, 0.6, 0.6)
end

local function ShowTooltip(self)
    if not db then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    pcall(FillTooltip)
    GameTooltip:Show()
end

frame:SetScript("OnEnter", ShowTooltip)
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
        UpdateText()
        if db.items.guild then RequestGuildRoster() end
        if TooltipIsOurs() then ShowTooltip(self) end -- mantém o tooltip atualizado
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
    end
    y = y - perColumn * 26

    y = y - 10
    set.generalHeader = CreateHeader(parent, y)
    y = y - 20
    set.shown = CreateCheck(parent, 20, y, SetShown)
    set.locked = CreateCheck(parent, 185, y, SetLocked)
    y = y - 26
    set.serverTime = CreateCheck(parent, 20, y, SetServerTime)
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
    y = y - 30

    controlSets[#controlSets + 1] = set
    return set, y
end

RefreshOptions = function()
    if not db then return end
    for _, set in ipairs(controlSets) do
        set.hint:SetText(T("opt_hint"))
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
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("UPDATE_FACTION")
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- entrou em combate
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- saiu do combate

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        local saved = FarolDB
        db = SanitizeDB(saved)
        db.alarms = ns.Alarm.Sanitize(type(saved) == "table" and saved.alarms or nil)
        db.loot = ns.Loot.SanitizeSettings(type(saved) == "table" and saved.loot or nil)
        db.warnings = ns.Warnings.Sanitize(type(saved) == "table" and saved.warnings or nil)
        db.order = ns.Order.Sanitize(type(saved) == "table" and saved.order or nil)
        FarolDB = db
        local savedChar = FarolCharDB
        FarolCharDB = ns.Loot.SanitizeHistory(savedChar) -- histórico de saques deste personagem
        FarolCharDB.warnHistory = ns.Warnings.SanitizeHistory(type(savedChar) == "table" and savedChar.warnHistory or nil)
        ApplyPosition()
        UpdateGrip()
        ApplyAppearance()
        ApplyVisibility()
        pcall(RegisterSettingsPanel) -- se a API de configurações mudar, o addon continua funcionando
        self:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not db then return end

    if event == "PLAYER_ENTERING_WORLD" then
        StartSession()
        ResetMapToCurrentZone()
        ScanDurability()
        inCombat = InCombatLockdown and InCombatLockdown() or false
        ApplyVisibility()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ResetMapToCurrentZone()
        ApplyVisibility()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        inCombat = (event == "PLAYER_REGEN_DISABLED")
        ApplyVisibility()
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
                           "help_hide", "help_items", "help_alarm", "help_alarm2", "help_alarm3", "help_loot", "help_session", "help_warn", "help_history", "help_appearance", "help_order",
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
