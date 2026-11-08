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
    "gold", "session", "xp", "clock", "playtime", "friends", "guild",
}

-- Visível por padrão? Os itens originais vêm ligados; os novos, desligados (ative no menu).
local ITEM_DEFAULTS = {
    fps = true, ms = true, coords = true, zone = true, durab = true, gold = true,
    mem = false, speed = false, bags = false, session = false, xp = false,
    clock = false, playtime = false, friends = false, guild = false,
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
    xp = "xp", experiencia = "xp", experience = "xp",
    hora = "clock", horario = "clock", relogio = "clock", clock = "clock", time = "clock",
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
        name_xp = "Experiência (XP)",  cmd_xp = "xp",
        name_clock = "Horário",        cmd_clock = "hora",
        name_playtime = "Tempo de sessão", cmd_playtime = "tempo",
        name_friends = "Amigos online", cmd_friends = "amigos",
        name_guild = "Guilda online",  cmd_guild = "guilda",
        label_durab  = "Dur",
        label_mem    = "Mem",
        label_speed  = "Vel",
        label_bags   = "Bolsas",
        label_session = "Sessão",
        label_playtime = "Jogando",
        label_friends = "Amigos",
        label_guild  = "Guilda",
        opt_servertime = "Horário do servidor",
        tt_mem       = "Memória Lua (interface + addons)",
        tt_speed     = "Velocidade",
        tt_bags      = "Bolsas (livres / total)",
        tt_session   = "Ouro na sessão",
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
        name_xp = "Experience (XP)",   cmd_xp = "xp",
        name_clock = "Clock",          cmd_clock = "clock",
        name_playtime = "Session time", cmd_playtime = "playtime",
        name_friends = "Friends online", cmd_friends = "friends",
        name_guild = "Guild online",   cmd_guild = "guild",
        label_durab  = "Dur",
        label_mem    = "Mem",
        label_speed  = "Speed",
        label_bags   = "Bags",
        label_session = "Session",
        label_playtime = "Played",
        label_friends = "Friends",
        label_guild  = "Guild",
        opt_servertime = "Server time",
        tt_mem       = "Lua memory (UI + addons)",
        tt_speed     = "Speed",
        tt_bags      = "Bags (free / total)",
        tt_session   = "Gold this session",
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

-- Estado da sessão (desde que você entrou no jogo ou deu /reload).
local session = { startMoney = nil, startTime = nil }

local function StartSession()
    if session.startTime then return end
    session.startMoney = GetMoney()
    session.startTime = GetTime()
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

local function GetClockText(server)
    if server and GetGameTime then
        local hour, minute = GetGameTime()
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

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("CENTER")
text:SetText("...")

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

local function UpdateText()
    local parts = {}
    for _, key in ipairs(ITEM_ORDER) do
        if db.items[key] then
            local ok, value = pcall(ITEM_TEXT[key])
            if not ok then value = "--" end
            if value then parts[#parts + 1] = value end
        end
    end

    if #parts == 0 then
        text:SetText("|cff888888" .. T("none_shown") .. "|r")
    else
        text:SetText(table.concat(parts, "   "))
    end
    frame:SetWidth(math.max(120, text:GetStringWidth() + 20))
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
    local delta = Safe(GetSessionMoney)
    if delta then AddPair(T("tt_session"), FormatMoneyDelta(delta)) end
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
        UpdateText()
        if db.items.guild then RequestGuildRoster() end
        if TooltipIsOurs() then ShowTooltip(self) end -- mantém o tooltip atualizado
    end
end)

local function ApplyVisibility()
    if db.shown then frame:Show() else frame:Hide() end
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
end

local function SetItemVisible(key, value)
    db.items[key] = value
    UpdateText()
    RefreshOptions()
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

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        local saved = FarolDB
        db = SanitizeDB(saved)
        db.alarms = ns.Alarm.Sanitize(type(saved) == "table" and saved.alarms or nil)
        db.loot = ns.Loot.SanitizeSettings(type(saved) == "table" and saved.loot or nil)
        FarolDB = db
        FarolCharDB = ns.Loot.SanitizeHistory(FarolCharDB) -- histórico de saques deste personagem
        ApplyPosition()
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
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ResetMapToCurrentZone()
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
                           "help_hide", "help_items", "help_alarm", "help_alarm2", "help_alarm3", "help_loot",
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
