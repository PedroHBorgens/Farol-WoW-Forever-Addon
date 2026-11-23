--[[
  Farol — Missões concluídas / Completed quests

  Lista das missões entregues por cada um dos SEUS personagens (só depois que o jogador liga "Registrar missões
  entregues": regra 8) e o total que o jogo informa (missões de antes do registro entram só no total, porque o jogo
  não informa os nomes delas sem pedir ao servidor — e o Farol não faz esse pedido).

  - Entrega: QUEST_TURNED_IN (clientes modernos; nome pelo QUEST_COMPLETE logo antes ou C_QuestLog.GetTitleForQuestID).
    Clientes antigos: a mensagem do sistema "<missão> concluída." (ERR_QUEST_COMPLETE_S), como o saque no chat.
  - Total: C_QuestLog.GetAllCompletedQuestIDs (moderno) ou GetQuestsCompleted (antigo; 0 = "o jogo não informou",
    porque no 3.3.5a a lista só existe depois de um pedido ao servidor, que o Farol não faz).
  - Dados: FarolDB.completed[reino][nome] = { t = total, tt = quando foi lido, list = { { i, n, l, z, t } } }
    (máx. 2000 por personagem, 20 reinos × 60 nomes), validados ao carregar. Nunca nomes de outros jogadores.
  Só lê: nunca aceita, entrega ou abandona missões (essas funções são proibidas pelo test_toc). Nada é enviado.
]]

local _, ns = ...

local MAX_LIST = 2000        -- missões guardadas por personagem (as mais recentes)
local MAX_OLD = 15000        -- IDs de missões concluídas guardados por personagem (as de antes do registro)
local MAX_DICT = 5000        -- dicionário ID -> nome aprendido com o jogo (conta toda; os mais recentes)
local SCAN_INTERVAL = 5      -- segundos entre leituras do diário para aprender nomes
local NAME_MAX, ZONE_MAX = 60, 40
local MAX_ID = 10000000
local MAX_REALMS, MAX_NAMES = 20, 60
local MAX_TIME = 4102444800  -- 2100
local ROWS, ROW_H = 12, 20
local MENU_MAX = 20          -- personagens no menu suspenso

local Completed = {}
ns.Completed = Completed

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_qdone    = "Missões concluídas", cmd_qdone = "concluidas", label_qdone = "Concluídas",
        desc_qdone    = "Total de missões que o jogo diz que este personagem já concluiu; a engrenagem abre a lista de cada personagem.",
        gear_qdone    = "abre a janela Missões concluídas.",
        qd_title      = "Missões concluídas",
        qd_char       = "Personagem:",
        qd_this       = "este",
        qd_search     = "buscar pelo nome ou ID...",
        qd_no_id      = "--",
        qd_recorded   = "Registradas: %d",
        qd_total      = "Total no jogo: %s",
        qd_total_note = "(inclui marcadores internos)",
        qd_record     = "Registrar missões entregues (só neste computador; nada é enviado)",
        qd_note       = "Os nomes vêm do próprio jogo: o Farol aprende o nome de cada missão que você vê (no NPC ou no diário).",
        qd_old        = "Mostrar missões de antes do registro (só o ID)",
        qd_old_name   = "antes do registro",
        qd_unseen     = "(nome ainda não visto)",
        qd_known      = "Nomes conhecidos: %d de %d",
        qd_link_label = "Wowhead (Ctrl+C):",
        qd_link_tip   = "Clique para copiar o link do Wowhead desta missão",
        qd_wowhead_url = "https://www.wowhead.com/forever/pt/quest=%d/",
        qd_empty_off  = "Nenhuma missão registrada. Marque \"Registrar missões entregues\" abaixo e entregue uma missão.",
        qd_empty_on   = "Nenhuma missão registrada ainda: entregue uma missão.",
        qd_no_match   = "Nenhuma missão com esse nome ou ID.",
        qd_scroll     = "%d–%d de %d",
        qd_unknown    = "Missão",
        qd_rec_on     = "registro de missões entregues: ligado (só neste computador).",
        qd_rec_off    = "registro de missões entregues: desligado (a lista guardada continua).",
        qd_status     = "missões concluídas: total %s (função: %s) · registro %s, %d registradas.",
        qd_usage      = "uso: /farol concluidas || /farol concluidas registrar on||off",
        tt_qdone      = "Missões concluídas",
        tt_qdone_today = "hoje +%d",
        tt_qdone_last = "Últimas: %s",
        tt_qdone_none = "o jogo não informou o total; ligue o registro na janela (Menu > Ferramentas)",
        help_qdone    = "  /farol concluidas    - missões concluídas de cada personagem (lista com busca e total)",
        tool_qdone    = "Missões concluídas...",
        tool_qdone_desc = "por personagem, com busca",
        news_qdone    = "missões concluídas de cada personagem: janela em Menu > Ferramentas (o registro e o item da barra vêm desligados)",
        news_qdone_old = "missões concluídas: opção para mostrar também as de antes do registro, só pelo ID (na janela; vem desligada)",
        news_qdone_link = "missões concluídas: clique numa missão para copiar o link dela no Wowhead (seção WoW Forever)",
        news_qdone_names = "missões concluídas: o Farol aprende os nomes das missões que você vê no jogo e mostra nas de antes do registro (com o registro ligado)",
        qd_on_word    = "ligado",
        qd_off_word   = "desligado",
    },
    en = {
        name_qdone    = "Completed quests", cmd_qdone = "completed", label_qdone = "Completed",
        desc_qdone    = "How many quests the game says this character has completed; the gear opens each character's list.",
        gear_qdone    = "opens the Completed quests window.",
        qd_title      = "Completed quests",
        qd_char       = "Character:",
        qd_this       = "this one",
        qd_search     = "search by name or ID...",
        qd_no_id      = "--",
        qd_recorded   = "Recorded: %d",
        qd_total      = "Total in game: %s",
        qd_total_note = "(includes internal markers)",
        qd_record     = "Record turned-in quests (on this computer only; nothing is sent)",
        qd_note       = "Names come from the game itself: Farol learns the name of each quest you see (at the NPC or in your log).",
        qd_old        = "Show quests from before recording (ID only)",
        qd_old_name   = "before recording",
        qd_unseen     = "(name not seen yet)",
        qd_known      = "Known names: %d of %d",
        qd_link_label = "Wowhead (Ctrl+C):",
        qd_link_tip   = "Click to copy this quest's Wowhead link",
        qd_wowhead_url = "https://www.wowhead.com/forever/quest=%d",
        qd_empty_off  = "No quests recorded. Tick \"Record turned-in quests\" below and turn in a quest.",
        qd_empty_on   = "No quests recorded yet: turn in a quest.",
        qd_no_match   = "No quest with that name or ID.",
        qd_scroll     = "%d–%d of %d",
        qd_unknown    = "Quest",
        qd_rec_on     = "recording turned-in quests: on (on this computer only).",
        qd_rec_off    = "recording turned-in quests: off (the saved list stays).",
        qd_status     = "completed quests: total %s (function: %s) · recording %s, %d recorded.",
        qd_usage      = "usage: /farol completed || /farol completed record on||off",
        tt_qdone      = "Completed quests",
        tt_qdone_today = "today +%d",
        tt_qdone_last = "Latest: %s",
        tt_qdone_none = "the game did not report the total; turn on recording in the window (Menu > Tools)",
        help_qdone    = "  /farol completed     - completed quests of each character (list with search and total)",
        tool_qdone    = "Completed quests...",
        tool_qdone_desc = "per character, with search",
        news_qdone    = "completed quests of each character: window in Menu > Tools (recording and the bar item start off)",
        news_qdone_old = "completed quests: option to also show the ones from before recording, by ID only (in the window; starts off)",
        news_qdone_link = "completed quests: click a quest to copy its Wowhead link (WoW Forever section)",
        news_qdone_names = "completed quests: Farol learns the names of the quests you see in the game and shows them for earlier quests (with recording on)",
        qd_on_word    = "on",
        qd_off_word   = "off",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Secret(value) return ns.IsSecret and ns.IsSecret(value) end

local function Int(value, low, high)
    if type(value) ~= "number" or Secret(value) or value ~= value or value ~= math.floor(value)
            or value < low or value > high then return nil end
    return value
end

-- Texto seguro: sem "|", sem controle, aparado em tempo linear, até "limit" letras (UTF-8).
local function Clean(text, limit)
    if type(text) ~= "string" or Secret(text) then return "" end
    text = string.gsub(string.sub(text, 1, 4096), "[|%c]", "")
    text = ns.Trim(text)
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > limit then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end
Completed.Clean = Clean

local function Now()
    local ok, t = pcall(time)
    return (ok and Int(t, 0, MAX_TIME)) or 0
end

---------------------------------------------------------------------------
-- Dados salvos
---------------------------------------------------------------------------

local function CleanEntry(entry)
    if type(entry) ~= "table" then return nil end
    local name = Clean(entry.n, NAME_MAX)
    local t = Int(entry.t, 0, MAX_TIME)
    if name == "" or not t then return nil end
    local zone = Clean(entry.z, ZONE_MAX)
    return { i = Int(entry.i, 1, MAX_ID), n = name, l = Int(entry.l, 0, 200), z = zone ~= "" and zone or nil, t = t }
end

local function CleanChar(info)
    if type(info) ~= "table" then return nil end
    local clean = { list = ns.KeepLast(info.list, MAX_LIST, CleanEntry) }
    clean.t = Int(info.t, 0, 1000000)
    clean.tt = Int(info.tt, 0, MAX_TIME)
    -- IDs de todas as missões concluídas (lidos do jogo com o registro ligado): só números válidos, sem repetir.
    local seen, ids = {}, {}
    for _, id in ipairs(ns.KeepLast(info.a, MAX_OLD, function(v) return Int(v, 1, MAX_ID) end)) do
        if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
    if #ids > 0 then clean.a = ids end
    if not clean.t and #clean.list == 0 and not clean.a then return nil end
    return clean
end

local function Latest(info)
    local last = info.list[#info.list]
    return math.max(info.tt or 0, last and last.t or 0)
end

function Completed.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    for realm, chars in pairs(saved) do
        if ns.ValidName(realm) and type(chars) == "table" then
            local list, count = {}, 0
            for name, info in pairs(chars) do
                local entry = ns.ValidName(name) and CleanChar(info)
                if entry then list[name] = entry; count = count + 1 end
            end
            if count > 0 then clean[realm] = ns.KeepRecent(list, MAX_NAMES, Latest) end
        end
    end
    return ns.KeepRecent(clean, MAX_REALMS, function(chars)
        local latest = 0
        for _, info in pairs(chars) do latest = math.max(latest, Latest(info)) end
        return latest
    end)
end

-- Dicionário ID -> { n = nome, l = nível?, t = quando foi visto }, da conta toda (só os mais recentes).
function Completed.SanitizeNames(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    -- 1) escolhe os mais recentes só pelos números (barato); 2) limpa o texto só desses (um arquivo adulterado com
    -- centenas de milhares de nomes carrega rápido).
    local candidates = {}
    for id, entry in pairs(saved) do
        local qid = Int(id, 1, MAX_ID)
        if qid and type(entry) == "table" and type(entry.n) == "string" then
            candidates[qid] = { raw = entry, t = Int(entry.t, 0, MAX_TIME) or 0 }
        end
    end
    for qid, c in pairs(ns.KeepRecent(candidates, MAX_DICT, function(e) return e.t end)) do
        local name = Clean(c.raw.n, NAME_MAX)
        if name ~= "" then clean[qid] = { n = name, l = Int(c.raw.l, 0, 200), t = c.t } end
    end
    return clean
end

local function DB() return ns.GetDB() end
local function Realms()
    local db = DB()
    if not db then return {} end
    if type(rawget(db, "completed")) ~= "table" then rawset(db, "completed", {}) end
    return rawget(db, "completed")
end
local function Recording() local db = DB() return db and db.questRecord == true end
local function Names()
    local db = DB()
    if not db then return {} end
    if type(rawget(db, "questNames")) ~= "table" then rawset(db, "questNames", {}) end
    return rawget(db, "questNames")
end
local namesCount -- quantos nomes há no dicionário (contado na primeira vez)

-- Aprende o nome de uma missão vista no jogo (só com o registro ligado: regra 8). Leitura local; nada é pedido.
function Completed.Learn(questID, title, level)
    if not Recording() then return end
    local id = Int(questID, 1, MAX_ID)
    if not id or Secret(title) then return end
    local name = Clean(title, NAME_MAX)
    if name == "" then return end
    local names = Names()
    if not namesCount then namesCount = 0; for _ in pairs(names) do namesCount = namesCount + 1 end end
    if not names[id] then namesCount = namesCount + 1 end
    names[id] = { n = name, l = Int(level, 0, 200) or (names[id] and names[id].l), t = Now() }
    if namesCount > MAX_DICT + 100 then -- corte de vez em quando (não a cada missão)
        local db = DB()
        rawset(db, "questNames", ns.KeepRecent(names, MAX_DICT, function(e) return e.t end))
        namesCount = MAX_DICT
    end
end

function Completed.NameOf(questID)
    local id = Int(questID, 1, MAX_ID)
    local entry = id and Names()[id]
    return entry and entry.n or nil
end

-- Lê o diário de missões e aprende os nomes (moderno: C_QuestLog; antigo: GetQuestLogTitle com o ID no 9º valor).
local lastScan
function Completed.ScanLog()
    if not Recording() then return end
    local okT, now = pcall(GetTime)
    if okT and type(now) == "number" and lastScan and now - lastScan >= 0 and now - lastScan < SCAN_INTERVAL then return end
    lastScan = okT and type(now) == "number" and now or nil
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local ok, count = pcall(C_QuestLog.GetNumQuestLogEntries)
        for i = 1, (ok and Int(count, 0, 200)) or 0 do
            local okI, info = pcall(C_QuestLog.GetInfo, i)
            if okI and type(info) == "table" and not info.isHeader then Completed.Learn(info.questID, info.title, info.level) end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        local ok, count = pcall(GetNumQuestLogEntries)
        for i = 1, (ok and Int(count, 0, 200)) or 0 do
            local okI, title, level, _, _, header, _, _, _, questID = pcall(GetQuestLogTitle, i)
            if okI and not header then Completed.Learn(questID, title, level) end
        end
    end
end

-- Registro do personagem atual (cria se "create"); nil se o jogo ainda não informou o nome.
local function Own(create)
    local name, realm = ns.CurrentCharacter()
    if not name then return nil end
    local realms = Realms()
    if not realms[realm] then
        if not create then return nil, name, realm end
        realms[realm] = {}
    end
    if not realms[realm][name] and create then realms[realm][name] = { list = {} } end
    return realms[realm][name], name, realm
end

---------------------------------------------------------------------------
-- Leituras do jogo
---------------------------------------------------------------------------

local total, totalSource -- total do personagem atual nesta sessão (nil = o jogo não informou)

-- Total de missões concluídas que o jogo informa. Devolve número (ou nil) e o nome da função que respondeu.
function Completed.ReadTotal()
    if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
        local ok, ids = pcall(C_QuestLog.GetAllCompletedQuestIDs)
        if ok and type(ids) == "table" and not Secret(ids) then
            local n = #ids
            if Int(n, 0, 1000000) then return n, "C_QuestLog.GetAllCompletedQuestIDs" end
        end
    end
    if GetQuestsCompleted then
        local ok, map = pcall(GetQuestsCompleted)
        if ok and type(map) == "table" and not Secret(map) then
            local n = 0
            for _ in pairs(map) do
                n = n + 1
                if n > 1000000 then return nil, "GetQuestsCompleted" end
            end
            if n > 0 then return n, "GetQuestsCompleted" end -- 0 = ainda não pedido ao servidor (não pedimos)
        end
    end
    return nil, "--"
end

-- IDs das missões concluídas que o jogo informa (em ordem crescente, no máximo MAX_OLD, os maiores). Só leitura local:
-- nada é pedido ao servidor e os nomes não são buscados (pedir o nome de missões antigas seria um pedido ao servidor).
function Completed.ReadIDs()
    local raw
    if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
        local ok, ids = pcall(C_QuestLog.GetAllCompletedQuestIDs)
        if ok and type(ids) == "table" and not Secret(ids) then raw = {}; for i = 1, math.min(#ids, 1000000) do raw[i] = ids[i] end end
    end
    if not raw and GetQuestsCompleted then
        local ok, map = pcall(GetQuestsCompleted)
        if ok and type(map) == "table" and not Secret(map) then
            raw = {}
            for id in pairs(map) do
                raw[#raw + 1] = id
                if #raw > 1000000 then break end
            end
        end
    end
    if not raw then return nil end
    local seen, out = {}, {}
    for _, v in ipairs(raw) do
        local id = Int(v, 1, MAX_ID)
        if id and not seen[id] then seen[id] = true; out[#out + 1] = id end
    end
    table.sort(out)
    if #out > MAX_OLD then
        local cut = {}
        for i = #out - MAX_OLD + 1, #out do cut[#cut + 1] = out[i] end
        out = cut
    end
    return out
end

function Completed.Refresh()
    local ok, n, source = pcall(Completed.ReadTotal)
    if ok then total, totalSource = n, source else total, totalSource = nil, "--" end
    if total and Recording() then
        local own = Own(true)
        if own then
            own.t, own.tt = total, Now()
            local okIDs, ids = pcall(Completed.ReadIDs)
            if okIDs and ids and #ids > 0 then own.a = ids end
        end
    end
end

function Completed.Total() return total, totalSource end

-- Nome e nível de uma missão que ainda está no diário (antes de ser entregue).
local function FromLog(questID)
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetInfo and questID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        if ok and Int(index, 1, 1000) then
            local okInfo, info = pcall(C_QuestLog.GetInfo, index)
            if okInfo and type(info) == "table" then return info.title, info.level end
        end
    end
    return nil
end

local pending -- { id, n, l } capturado ao abrir a janela de recompensa (QUEST_COMPLETE)

local function OnQuestComplete()
    local id, title, level
    if GetQuestID then
        local ok, value = pcall(GetQuestID)
        if ok then id = Int(value, 1, MAX_ID) end
    end
    if GetTitleText then
        local ok, value = pcall(GetTitleText)
        if ok and type(value) == "string" then title = value end
    end
    local logTitle, logLevel = FromLog(id)
    title = title or logTitle
    level = Int(logLevel, 0, 200)
    if not level and title and GetNumQuestLogEntries and GetQuestLogTitle then -- clientes antigos
        local ok, count = pcall(GetNumQuestLogEntries)
        for i = 1, (ok and Int(count, 0, 100)) or 0 do
            local okT, t, l = pcall(GetQuestLogTitle, i)
            if okT and t == title then level = Int(l, 0, 200) break end
        end
    end
    pending = { id = id, n = Clean(title, NAME_MAX), l = level }
    Completed.Learn(id, title, level)
end

-- Missão lida no NPC (QUEST_DETAIL): só aprende o nome (não aceita nada).
local function OnQuestDetail()
    local id, title
    if GetQuestID then
        local ok, value = pcall(GetQuestID)
        if ok then id = Int(value, 1, MAX_ID) end
    end
    if GetTitleText then
        local ok, value = pcall(GetTitleText)
        if ok and type(value) == "string" then title = value end
    end
    Completed.Learn(id, title, nil)
end

local function Zone()
    for _, fn in ipairs({ GetRealZoneText, GetZoneText }) do
        local ok, value = pcall(fn)
        if ok and type(value) == "string" and value ~= "" and not Secret(value) then return value end
    end
    return nil
end

local RefreshWindow -- definida abaixo

-- Grava uma entrega (só com o registro ligado). id e/ou nome podem faltar; sem nome nem id, nada é gravado.
function Completed.Record(questID, title)
    local id = Int(questID, 1, MAX_ID)
    local name = Clean(title, NAME_MAX)
    local level
    if pending and ((id and pending.id == id) or (not id and name ~= "" and pending.n == name)) then
        if name == "" then name = pending.n end
        id, level = id or pending.id, pending.l
    end
    if name == "" and id then name = Completed.NameOf(id) or "" end -- dicionário aprendido com o jogo
    if name == "" and id and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, value = pcall(C_QuestLog.GetTitleForQuestID, id)
        if ok then name = Clean(value, NAME_MAX) end
    end
    pending = nil
    if name == "" and not id then return end
    if name == "" then name = T("qd_unknown") .. " #" .. id else Completed.Learn(id, name, level) end
    if total then total = total + 1 end
    if not Recording() then return end
    local own = Own(true)
    if not own then return end
    local now = Now()
    local last = own.list[#own.list]
    if last and now - last.t <= 10 and ((id and last.i == id) or last.n == name) then return end -- repetida
    own.list[#own.list + 1] = { i = id, n = name, l = level, z = Clean(Zone(), ZONE_MAX), t = now }
    if own.list[#own.list].z == "" then own.list[#own.list].z = nil end
    if #own.list > MAX_LIST then table.remove(own.list, 1) end -- no máximo 1 a mais: corte simples
    if total then own.t, own.tt = total, now end
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
end

-- Clientes antigos: "<missão> concluída." no chat do sistema (ERR_QUEST_COMPLETE_S).
local completePattern
if type(ERR_QUEST_COMPLETE_S) == "string" then
    local p = string.gsub(ERR_QUEST_COMPLETE_S, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    p = string.gsub(p, "%%%%s", "(.+)")
    completePattern = "^" .. p .. "$"
end
local turnedInEvent = false -- o cliente tem QUEST_TURNED_IN: a mensagem do sistema é ignorada

local events = CreateFrame("Frame")
for _, event in ipairs({ "QUEST_TURNED_IN", "QUEST_COMPLETE", "CHAT_MSG_SYSTEM", "PLAYER_ENTERING_WORLD", "QUEST_DETAIL",
                         "QUEST_ACCEPTED", "QUEST_LOG_UPDATE" }) do
    local ok = pcall(events.RegisterEvent, events, event)
    if ok and event == "QUEST_TURNED_IN" and C_QuestLog then turnedInEvent = true end
end
events:SetScript("OnEvent", function(_, event, arg1)
    if not DB() then return end
    if event == "QUEST_COMPLETE" then
        pcall(OnQuestComplete)
    elseif event == "QUEST_TURNED_IN" then
        if not Secret(arg1) then pcall(Completed.Record, arg1, nil) end
    elseif event == "CHAT_MSG_SYSTEM" then
        if turnedInEvent or not completePattern or type(arg1) ~= "string" or Secret(arg1) or #arg1 > 300 then return end
        local title = string.match(arg1, completePattern)
        if title then pcall(Completed.Record, nil, title) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        Completed.Refresh()
        lastScan = nil; pcall(Completed.ScanLog)
    elseif event == "QUEST_DETAIL" then
        pcall(OnQuestDetail)
    elseif event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" then
        if event == "QUEST_ACCEPTED" then lastScan = nil end -- missão nova: lê o diário já
        pcall(Completed.ScanLog)
    end
end)

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

local function TodayCount(info)
    if not info then return 0 end
    local today = date("%Y-%m-%d", Now())
    local n = 0
    for i = #info.list, 1, -1 do
        if date("%Y-%m-%d", info.list[i].t) ~= today then break end
        n = n + 1
    end
    return n
end

function Completed.BarText()
    local own = Own(false)
    local value = total or (own and own.t) or (Recording() and own and #own.list) or nil
    return T("label_qdone") .. " " .. (value and tostring(value) or "--")
end

local function CharLevel(realm, name)
    local db = DB()
    local chars = db and db.chars and db.chars[realm]
    return chars and chars[name] and chars[name].level
end

-- Personagens do reino com registro, mais recentes primeiro (o atual sempre primeiro).
local function CharsOf(realm, current)
    local list = {}
    for name, info in pairs(Realms()[realm] or {}) do
        if name ~= current then list[#list + 1] = { name = name, info = info } end
    end
    table.sort(list, function(a, b)
        local ta, tb = Latest(a.info), Latest(b.info)
        if ta ~= tb then return ta > tb end
        return a.name < b.name
    end)
    if current then table.insert(list, 1, { name = current, info = (Realms()[realm] or {})[current] or { list = {} } }) end
    return list
end

function Completed.Tooltip()
    local name, realm = ns.CurrentCharacter()
    GameTooltip:AddLine(T("tt_qdone"), 1, 0.82, 0)
    if not name then GameTooltip:AddLine("   --", 1, 1, 1) return end
    local chars = CharsOf(realm, name)
    for i, entry in ipairs(chars) do
        if i > 5 then
            GameTooltip:AddLine("   " .. string.format(T("tt_more"), #chars - 5), 0.6, 0.6, 0.6)
            break
        end
        local current = entry.name == name
        local value = current and (total or entry.info.t) or entry.info.t
        value = value or (#entry.info.list > 0 and #entry.info.list) or nil
        local right = value and tostring(value) or "--"
        local today = current and TodayCount(entry.info) or 0
        if today > 0 then right = right .. " · " .. string.format(T("tt_qdone_today"), today) end
        local level = CharLevel(realm, entry.name)
        local label = entry.name .. (current and (" (" .. T("qd_this") .. ")") or (level and (" (" .. level .. ")") or ""))
        GameTooltip:AddDoubleLine("   " .. label, right, 1, 0.82, 0, 1, 1, 1)
    end
    local own = (Realms()[realm] or {})[name]
    if own and #own.list > 0 then
        local names = {}
        for i = #own.list, math.max(1, #own.list - 2), -1 do names[#names + 1] = own.list[i].n end
        GameTooltip:AddLine("   " .. string.format(T("tt_qdone_last"), table.concat(names, " · ")), 0.75, 0.75, 0.75, true)
    elseif not total then
        GameTooltip:AddLine("   " .. T("tt_qdone_none"), 0.75, 0.75, 0.75, true)
    end
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window
local selected     -- { realm, name } escolhido no menu (nil = o atual)
local offset = 0   -- rolagem
local search = ""

local function SetRecording(value)
    local db = DB()
    if not db then return end
    db.questRecord = value == true
    Print(db.questRecord and T("qd_rec_on") or T("qd_rec_off"))
    if db.questRecord then Completed.Refresh() end
    if RefreshWindow then RefreshWindow() end
    if ns.UpdateText then ns.UpdateText() end
end
Completed.SetRecording = SetRecording

local function Selected()
    local name, realm = ns.CurrentCharacter()
    if selected and Realms()[selected.realm] and Realms()[selected.realm][selected.name] then
        return selected.realm, selected.name, selected.name == name and selected.realm == realm
    end
    return realm, name, true
end

local function ShowOld() local db = DB() return db and db.questShowOld == true end

local function Filtered(info)
    local out = {}
    if not info then return out end
    local wanted = string.lower(search)
    local idWanted = string.match(wanted, "^#?(%d+)$")
    for i = #info.list, 1, -1 do -- mais nova primeiro
        local entry = info.list[i]
        -- Busca pelo nome ou pelo ID da missão (o número que o jogo dá a cada missão; "#123" ou "123").
        local id = entry.i and tostring(entry.i)
        if wanted == "" or string.find(string.lower(entry.n), wanted, 1, true) or (idWanted and id and string.find(id, idWanted, 1, true)) then
            out[#out + 1] = entry
        end
    end
    -- Missões de antes do registro (opção, desligada): só o ID, das maiores para as menores; as já registradas ficam de fora.
    if ShowOld() and info.a then
        local recorded = {}
        for _, entry in ipairs(info.list) do if entry.i then recorded[entry.i] = true end end
        for i = #info.a, 1, -1 do
            local id = info.a[i]
            local known = Completed.NameOf(id)
            if not recorded[id] and (wanted == "" or (idWanted and string.find(tostring(id), idWanted, 1, true))
                    or (known and string.find(string.lower(known), wanted, 1, true))) then
                out[#out + 1] = { i = id, old = true, n = known }
            end
        end
    end
    return out
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolCompleted", UIParent, ns.backdropTemplate)
    frame:SetSize(640, 150 + ROWS * ROW_H + 94)
    frame:SetPoint("CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -18)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    frame.charLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.charLabel:SetPoint("TOPLEFT", 24, -52)
    frame.char = ns.CreateDropdown(frame, "FarolCompletedChar", 210, function()
        local name, realm = ns.CurrentCharacter()
        local items = {}
        local cur = select(2, Selected())
        for i, entry in ipairs(name and CharsOf(realm, name) or {}) do
            if i > MENU_MAX then break end
            local label = entry.name .. (entry.name == name and (" — " .. T("qd_this")) or "")
            items[#items + 1] = { text = label, checked = entry.name == cur, onClick = function()
                selected = { realm = realm, name = entry.name }; offset = 0; RefreshWindow()
            end }
        end
        if #items == 0 then items[1] = { text = "--", r = .6, g = .6, b = .6, onClick = function() end } end
        return items
    end)
    frame.char:SetPoint("LEFT", frame.charLabel, "RIGHT", 8, 0)

    frame.search = CreateFrame("EditBox", "FarolCompletedSearch", frame, "InputBoxTemplate")
    frame.search:SetSize(200, 20)
    frame.search:SetPoint("TOPRIGHT", -30, -50)
    frame.search:SetAutoFocus(false)
    frame.search:SetMaxLetters(40)
    frame.searchHint = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.searchHint:SetPoint("LEFT", frame.search, "LEFT", 4, 0)
    frame.search:SetScript("OnTextChanged", function(self)
        search = Clean(self:GetText(), 40); offset = 0; RefreshWindow()
    end)
    frame.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    frame.search:SetScript("OnEditFocusGained", function() frame.searchHint:Hide() end)
    frame.search:SetScript("OnEditFocusLost", function() RefreshWindow() end)

    frame.recorded = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.recorded:SetPoint("TOPLEFT", 24, -82)
    frame.known = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall") -- "Nomes conhecidos: 37 de 131"
    frame.known:SetPoint("TOPLEFT", 150, -82)
    frame.totalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.totalText:SetPoint("TOPRIGHT", -30, -82)

    frame.rows = {}
    for i = 1, ROWS do
        local y = -104 - (i - 1) * ROW_H
        local row = {}
        row.level = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.level:SetPoint("TOPLEFT", 26, y)
        row.level:SetWidth(36)
        row.level:SetJustifyH("LEFT")
        row.name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("TOPLEFT", 64, y)
        row.name:SetWidth(240)
        row.name:SetJustifyH("LEFT")
        row.zone = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        row.id = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")) -- ID da missão no jogo
        row.id:SetPoint("TOPLEFT", 310, y)
        row.id:SetWidth(64)
        row.id:SetJustifyH("LEFT")
        row.zone:SetPoint("TOPLEFT", 380, y)
        row.zone:SetWidth(132)
        row.zone:SetJustifyH("LEFT")
        row.when = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        row.when:SetPoint("TOPRIGHT", -30, y)
        row.when:SetWidth(90)
        row.when:SetJustifyH("RIGHT")
        for _, fs in ipairs({ row.level, row.name, row.id, row.zone, row.when }) do
            if fs.SetWordWrap then fs:SetWordWrap(false) end
        end
        -- A linha inteira é clicável: mostra o link do Wowhead da missão para copiar (o addon não abre nada).
        row.click = CreateFrame("Button", "FarolCompletedRow" .. i, frame)
        row.click:SetPoint("TOPLEFT", 22, y + 3)
        row.click:SetSize(596, ROW_H)
        row.click:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.click:SetScript("OnClick", function(self) if self.questID then Completed.ShowLink(self.questID) end end)
        row.click:SetScript("OnEnter", function(self)
            if not self.questID then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("#" .. self.questID)
            GameTooltip:AddLine(T("qd_link_tip"), 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row.click:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame.rows[i] = row
    end
    frame.empty = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    frame.empty:SetPoint("TOPLEFT", 26, -110)
    frame.empty:SetWidth(580)
    frame.empty:SetJustifyH("LEFT")
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        offset = math.max(0, offset - (delta or 0) * 3)
        RefreshWindow()
    end)

    local bottom = -104 - ROWS * ROW_H - 10
    frame.record = CreateFrame("CheckButton", "FarolCompletedRecord", frame, "UICheckButtonTemplate")
    frame.record:SetSize(24, 24)
    frame.record:SetPoint("TOPLEFT", 20, bottom)
    frame.record.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.record.label:SetPoint("LEFT", frame.record, "RIGHT", 4, 0)
    frame.record:SetScript("OnClick", function(self) SetRecording(self:GetChecked() and true or false) end)
    frame.scrollInfo = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.scrollInfo:SetPoint("TOPRIGHT", -30, bottom - 6)
    frame.note = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.old = CreateFrame("CheckButton", "FarolCompletedOld", frame, "UICheckButtonTemplate")
    frame.old:SetSize(24, 24)
    frame.old:SetPoint("TOPLEFT", 20, bottom - 24)
    frame.old.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.old.label:SetPoint("LEFT", frame.old, "RIGHT", 4, 0)
    frame.old:SetScript("OnClick", function(self)
        local db = DB()
        if db then db.questShowOld = self:GetChecked() and true or false end
        offset = 0
        RefreshWindow()
    end)
    frame.note:SetPoint("TOPLEFT", 24, bottom - 54)
    frame.note:SetWidth(590)
    frame.note:SetJustifyH("LEFT")
    -- Link do Wowhead para copiar (aparece no lugar da nota): só texto, o addon não acessa a internet.
    frame.linkLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.linkLabel:SetPoint("TOPLEFT", 24, bottom - 54)
    frame.link = CreateFrame("EditBox", "FarolCompletedLink", frame, "InputBoxTemplate")
    frame.link:SetSize(440, 20)
    frame.link:SetPoint("TOPLEFT", 150, bottom - 50)
    frame.link:SetAutoFocus(false)
    frame.link:SetMaxLetters(120)
    frame.link:SetScript("OnTextChanged", function(self, userInput)
        -- Só leitura: se o jogador digitar, o link volta (assim o Ctrl+C sempre copia o endereço certo).
        if userInput and self.farolURL and self:GetText() ~= self.farolURL then
            self:SetText(self.farolURL); self:HighlightText()
        end
    end)
    local function HideLink(self) self:ClearFocus(); Completed.HideLink() end
    frame.link:SetScript("OnEscapePressed", HideLink)
    frame.link:SetScript("OnEnterPressed", HideLink)
    frame.link:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    frame.linkLabel:Hide(); frame.link:Hide()

    frame:SetScript("OnShow", function() Completed.Refresh(); RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolCompleted") -- ESC fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local realm, name, isCurrent = Selected()
    local info = realm and name and (Realms()[realm] or {})[name]
    window.title:SetText(T("qd_title"))
    window.charLabel:SetText(T("qd_char"))
    window.char:SetText(name and (name .. (isCurrent and (" — " .. T("qd_this")) or "")) or "--")
    window.searchHint:SetText(T("qd_search"))
    if window.search:GetText() == "" and not window.search:HasFocus() then window.searchHint:Show() else window.searchHint:Hide() end
    window.recorded:SetText(string.format(T("qd_recorded"), info and #info.list or 0))
    local knownCount, allIDs = 0, info and info.a and #info.a or 0
    if info and info.a then for _, id in ipairs(info.a) do if Completed.NameOf(id) then knownCount = knownCount + 1 end end end
    window.known:SetText(allIDs > 0 and string.format(T("qd_known"), knownCount, allIDs) or "")
    local shownTotal = isCurrent and (total or (info and info.t)) or (info and info.t)
    window.totalText:SetText(string.format(T("qd_total"), shownTotal and tostring(shownTotal) or "--") .. " " .. ns.C.dim .. T("qd_total_note") .. "|r")

    local list = Filtered(info)
    local maxOffset = math.max(0, #list - ROWS)
    if offset > maxOffset then offset = maxOffset end
    for i, row in ipairs(window.rows) do
        local entry = list[offset + i]
        if entry then
            row.level:SetText(entry.l and (ns.C.warn .. "[" .. entry.l .. "]|r") or "")
            if entry.old then
                row.name:SetText(entry.n or (ns.C.dim .. T("qd_unseen") .. "|r"))
            else
                row.name:SetText(entry.n)
            end
            row.id:SetText(entry.i and ("#" .. entry.i) or T("qd_no_id"))
            row.zone:SetText(entry.z or "")
            row.when:SetText(entry.old and T("qd_old_name") or (entry.t and ns.FormatWhen(entry.t) or ""))
            row.level:Show(); row.name:Show(); row.id:Show(); row.zone:Show(); row.when:Show()
            row.click.questID = entry.i
            if entry.i then row.click:Show() else row.click:Hide() end
        else
            row.level:Hide(); row.name:Hide(); row.id:Hide(); row.zone:Hide(); row.when:Hide()
            row.click.questID = nil; row.click:Hide()
        end
    end
    if #list == 0 then
        local key = (info and (#info.list > 0 or (ShowOld() and info.a))) and "qd_no_match" or (Recording() and "qd_empty_on" or "qd_empty_off")
        window.empty:SetText(T(key)); window.empty:Show()
    else
        window.empty:Hide()
    end
    window.scrollInfo:SetText(#list > 0 and string.format(T("qd_scroll"), offset + 1, math.min(offset + ROWS, #list), #list) or "")
    window.record:SetChecked(Recording())
    window.record.label:SetText(T("qd_record"))
    window.note:SetText(T("qd_note"))
    window.linkLabel:SetText(T("qd_link_label"))
    if window.link:IsShown() then window.note:Hide() else window.note:Show() end
    window.old:SetChecked(ShowOld())
    window.old.label:SetText(T("qd_old"))
end

function Completed.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Completed.RefreshWindow() if RefreshWindow then RefreshWindow() end end

-- Endereço do Wowhead (seção WoW Forever, no idioma do Farol) só a partir de um ID inteiro válido.
function Completed.WowheadURL(questID)
    local id = Int(questID, 1, MAX_ID)
    return id and string.format(T("qd_wowhead_url"), id) or nil
end

function Completed.ShowLink(questID)
    local url = Completed.WowheadURL(questID)
    if not url or not window then return end
    window.link.farolURL = url
    window.link:SetText(url)
    window.note:Hide(); window.linkLabel:Show(); window.link:Show()
    window.link:SetFocus(); window.link:HighlightText()
end

function Completed.HideLink()
    if not window then return end
    window.link.farolURL = nil
    window.link:Hide(); window.linkLabel:Hide(); window.note:Show()
end

---------------------------------------------------------------------------
-- Comandos e diagnóstico
---------------------------------------------------------------------------

local SWITCH = { on = true, ligar = true, ligado = true, off = false, desligar = false, desligado = false }
local RECORD = { registrar = true, registro = true, record = true, recording = true }

function Completed.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(%a*)%s*$")
    word, tail = string.lower(word or ""), string.lower(tail or "")
    if word == "" then
        Completed.ToggleWindow()
    elseif RECORD[word] and SWITCH[tail] ~= nil then
        SetRecording(SWITCH[tail])
    else
        Print(T("qd_usage"))
    end
end

function Completed.StatusLine()
    local n, source = Completed.ReadTotal()
    local own = Own(false)
    return string.format(T("qd_status"), n and tostring(n) or "--", tostring(source or "--"),
        Recording() and T("qd_on_word") or T("qd_off_word"), own and #own.list or 0)
end

-- Esquecer um personagem (Core): a lista dele também vai embora.
function Completed.Forget(realm, name)
    local realms = Realms()
    if realms[realm] then
        realms[realm][name] = nil
        if next(realms[realm]) == nil then realms[realm] = nil end
    end
end
