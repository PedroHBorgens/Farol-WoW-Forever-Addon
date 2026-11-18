--[[
  Farol — Diário de missões / Quest log

  Quantas missões há no diário (e quantas cabem), quais estão prontas para entregar e o andamento das outras,
  com o nível colorido pela dificuldade, como no jogo. Avisos opcionais (Warnings.lua): diário quase cheio e
  missões prontas ao entrar numa cidade ou estalagem.
  Só lê: nunca aceita, entrega, abandona, compartilha nem acompanha missões, e não abre grupos fechados do diário.
  Nada é salvo (a informação vem do jogo na hora) e nada é enviado.
  Clientes modernos: C_QuestLog (GetNumQuestLogEntries, GetInfo, IsComplete, IsFailed, GetQuestObjectives,
  GetMaxNumQuestsCanAccept). Antigos: GetNumQuestLogEntries, GetQuestLogTitle (a ordem dos valores muda entre
  versões), GetNumQuestLeaderBoards / GetQuestLogLeaderBoard e MAX_QUESTLOGQUESTS.
]]

local _, ns = ...

local MAX_FALLBACK = 20   -- limite do diário no estilo clássico, quando o jogo não informa
local MAX_ENTRIES = 100   -- linhas lidas do diário (categorias + missões)
local LIST_MAX = 5        -- missões mostradas em cada lista do tooltip
local HIGH_LEVELS = 5     -- "bem acima do seu nível": 5 níveis ou mais
local NAME_MAX = 60       -- letras do nome mostradas

local Quests = {}
ns.Quests = Quests

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_quests   = "Missões (diário)", cmd_quests = "missoes",
        desc_quests   = "Quantas missões há no diário e quantas cabem, as prontas para entregar e o andamento das outras.",
        label_quests  = "Missões",
        quests_ready_n = "%d prontas",
        quests_ready_1 = "1 pronta",
        tt_quests     = "Missões — %d / %d",
        tt_quests_ready = "Prontas para entregar (%d)",
        tt_quests_active = "Em andamento (%d)",
        tt_quests_more = "… e mais %d",
        tt_quests_failed = "falhou",
        tt_quests_high = "%d missão(ões) bem acima do seu nível (%d+) — melhor deixar para depois",
        tt_quests_none = "nenhuma missão no diário",
        tt_quests_closed = "algumas categorias estão fechadas no diário (o Farol não as abre)",
        tt_quests_colors = "cor do nível = dificuldade, como no jogo",
        news_quests   = "diário de missões na barra: quantas cabem, as prontas para entregar e avisos opcionais",
        quests_status = "missões: %s, %d pronta(s) — fonte: %s",
    },
    en = {
        name_quests   = "Quests (quest log)", cmd_quests = "quests",
        desc_quests   = "How many quests are in your log and how many fit, the ones ready to turn in and the progress of the rest.",
        label_quests  = "Quests",
        quests_ready_n = "%d ready",
        quests_ready_1 = "1 ready",
        tt_quests     = "Quests — %d / %d",
        tt_quests_ready = "Ready to turn in (%d)",
        tt_quests_active = "In progress (%d)",
        tt_quests_more = "… and %d more",
        tt_quests_failed = "failed",
        tt_quests_high = "%d quest(s) well above your level (%d+) — better leave them for later",
        tt_quests_none = "no quests in your log",
        tt_quests_closed = "some categories are collapsed in your quest log (Farol does not open them)",
        tt_quests_colors = "level color = difficulty, as in the game",
        news_quests   = "quest log on the bar: how many fit, the ones ready to turn in and optional warnings",
        quests_status = "quests: %s, %d ready — source: %s",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end

---------------------------------------------------------------------------
-- Leituras do jogo (protegidas: erro, valor bloqueado ou absurdo = nil)
---------------------------------------------------------------------------

local function Secret(value) return ns.IsSecret and ns.IsSecret(value) end

local function Int(value, low, high)
    if type(value) ~= "number" or Secret(value) or value ~= value or value < low or value > high then return nil end
    return math.floor(value)
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

-- Nome limpo: sem "|" (códigos do chat), sem controle, até NAME_MAX letras (UTF-8 inteiro).
local function Clean(text)
    if type(text) ~= "string" or Secret(text) then return nil end
    text = string.gsub(string.gsub(text, "|", ""), "%c", "")
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > NAME_MAX then break end
        out[#out + 1] = char
    end
    text = table.concat(out)
    return text ~= "" and text or nil
end

local function Truthy(value) return value == true or value == 1 end

-- "3/8" de um objetivo ainda não cumprido (texto antigo: "Morcego morto: 3/8").
local function Progress(have, need)
    have, need = Int(have, 0, 100000), Int(need, 1, 100000)
    if have and need and have < need then return have .. "/" .. need end
    return nil
end

local function ModernObjective(questID)
    if not (C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
    local ok, list = Call(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(list) ~= "table" then return nil end
    for i = 1, math.min(#list, 10) do
        local o = list[i]
        if type(o) == "table" and not Truthy(o.finished) then
            local text = Progress(o.numFulfilled, o.numRequired)
            if text then return text end
        end
    end
    return nil
end

local function OldObjective(index)
    if not (GetNumQuestLeaderBoards and GetQuestLogLeaderBoard) then return nil end
    local ok, count = Call(GetNumQuestLeaderBoards, index)
    count = ok and Int(count, 0, 10) or 0
    for j = 1, count do
        local okBoard, text, _, finished = Call(GetQuestLogLeaderBoard, j, index)
        if okBoard and type(text) == "string" and not Secret(text) and not Truthy(finished) then
            local have, need = string.match(text, "(%d+)%s*/%s*(%d+)")
            local progress = Progress(tonumber(have), tonumber(need))
            if progress then return progress end
        end
    end
    return nil
end

-- Uma linha do diário: { title, level, header, done (pronta), failed, objective } ou nil.
local function ModernEntry(i)
    local ok, info = Call(C_QuestLog.GetInfo, i)
    if not ok or type(info) ~= "table" then return nil end
    if Truthy(info.isHeader) then return { header = true, collapsed = Truthy(info.isCollapsed) } end
    if Truthy(info.isHidden) or Truthy(info.isTask) or Truthy(info.isBounty) then return nil end
    local id = Int(info.questID, 1, 100000000)
    local entry = { title = Clean(info.title), level = Int(info.level, 0, 200) }
    if id then
        local okDone, done = Call(C_QuestLog.IsComplete, id)
        entry.done = okDone and Truthy(done)
        local okFail, failed = Call(C_QuestLog.IsFailed, id)
        entry.failed = okFail and Truthy(failed)
        if not entry.done then entry.objective = ModernObjective(id) end
    end
    return entry
end

-- GetQuestLogTitle: 1.12 = título, nível, tag, categoria?, fechada?, completa (1/-1)...; 1.13+ = título, nível,
-- grupo (número), categoria?, fechada?, completa...; 3.3.5 = título, nível, tag, grupo (número), categoria?, fechada?,
-- completa... Quando o 4º valor é número, tudo anda uma posição.
local function OldEntry(i)
    local ok, title, level, _, v4, v5, v6, v7 = Call(GetQuestLogTitle, i)
    if not ok then return nil end
    local header, collapsed, complete = v4, v5, v6
    if type(v4) == "number" then header, collapsed, complete = v5, v6, v7 end
    if Truthy(header) then return { header = true, collapsed = Truthy(collapsed) } end
    local entry = { title = Clean(title), level = Int(level, 0, 200) }
    entry.done = complete == 1 or complete == true
    entry.failed = complete == -1
    if not entry.done then entry.objective = OldObjective(i) end
    return entry
end

local function MaxQuests()
    local value
    if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
        local ok, n = Call(C_QuestLog.GetMaxNumQuestsCanAccept); value = ok and n or nil
    end
    if not Int(value, 1, 100) and C_QuestLog and C_QuestLog.GetMaxNumQuests then
        local ok, n = Call(C_QuestLog.GetMaxNumQuests); value = ok and n or nil
    end
    if not Int(value, 1, 100) then value = MAX_QUESTLOGQUESTS end
    return Int(value, 1, 100) or MAX_FALLBACK
end

-- Qual leitura este cliente usa (para /farol aviso status).
function Quests.Source()
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then return "C_QuestLog" end
    if GetNumQuestLogEntries and GetQuestLogTitle then return "GetQuestLogTitle" end
    return "--"
end

-- Lê o diário. nil se o jogo não informar; senão { count, max, ready = {}, active = {}, high, closed, level }.
function Quests.Read()
    local modern = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo
    local numFn = modern and C_QuestLog.GetNumQuestLogEntries or GetNumQuestLogEntries
    if type(numFn) ~= "function" or (not modern and type(GetQuestLogTitle) ~= "function") then return nil end
    local ok, numEntries, numQuests = Call(numFn)
    numEntries = ok and Int(numEntries, 0, 1000) or nil
    if not numEntries then return nil end
    local okLevel, playerLevel = Call(UnitLevel, "player")
    playerLevel = okLevel and Int(playerLevel, 1, 200) or nil
    local data = { ready = {}, active = {}, high = 0, closed = false, level = playerLevel }
    local listed = 0
    for i = 1, math.min(numEntries, MAX_ENTRIES) do
        local entry = modern and ModernEntry(i) or OldEntry(i)
        if entry and entry.header then
            if entry.collapsed then data.closed = true end
        elseif entry then
            listed = listed + 1
            entry.title = entry.title or "?"
            if entry.done then
                data.ready[#data.ready + 1] = entry
            else
                data.active[#data.active + 1] = entry
                if playerLevel and entry.level and entry.level >= playerLevel + HIGH_LEVELS then data.high = data.high + 1 end
            end
        end
    end
    data.count = Int(numQuests, 0, 100) or listed
    if data.count < listed then data.count = listed end
    data.max = MaxQuests()
    if data.count > data.max then data.max = data.count end
    local byLevel = function(a, b)
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
        return a.title < b.title
    end
    table.sort(data.ready, byLevel); table.sort(data.active, byLevel)
    return data
end

-- Cor do nível pela dificuldade: a do jogo (GetQuestDifficultyColor) ou a conta do estilo clássico.
local function LevelColor(level, playerLevel)
    if not level then return "ffffff" end
    local getColor = GetQuestDifficultyColor or GetDifficultyColor
    local ok, color = Call(getColor, level)
    if ok and type(color) == "table" then
        local c = { color.r, color.g, color.b }
        local valid = true
        for i = 1, 3 do -- índice fixo: um valor ausente não pode passar
            if type(c[i]) ~= "number" or Secret(c[i]) or c[i] ~= c[i] or c[i] < 0 or c[i] > 1 then valid = false end
        end
        if valid then return string.format("%02x%02x%02x", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255)) end
    end
    if not playerLevel then return "ffffff" end
    local diff = level - playerLevel
    if diff >= 5 then return "ff2020" end
    if diff >= 3 then return "ff8040" end
    if diff >= -2 then return "ffff00" end
    if diff >= -(playerLevel <= 20 and 5 or 8) then return "40c040" end
    return "808080"
end

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

local function CountColor(count, max)
    if count >= max then return "|cffff4040" end
    if count >= max - 3 then return "|cffffff3a" end
    return "|cff40ff40"
end

function Quests.BarText()
    local data = Quests.Read()
    if not data then return T("label_quests") .. " |cff888888--|r" end
    local text = string.format("%s %s%d/%d|r", T("label_quests"), CountColor(data.count, data.max), data.count, data.max)
    local ready = #data.ready
    if ready > 0 then
        text = text .. " · |cff40ff40" .. (ready == 1 and T("quests_ready_1") or string.format(T("quests_ready_n"), ready)) .. "|r"
    end
    return text
end

local function Line(entry, playerLevel)
    local level = entry.level and string.format("|cff%s[%d]|r ", LevelColor(entry.level, playerLevel), entry.level) or ""
    local right = entry.failed and ("|cffff4040" .. T("tt_quests_failed") .. "|r") or (entry.objective or "")
    GameTooltip:AddDoubleLine("      " .. level .. entry.title, right, 0.9, 0.9, 0.9, 0.7, 0.7, 0.7)
end

local function List(title, list, r, g, b, playerLevel)
    if #list == 0 then return end
    GameTooltip:AddLine("   " .. string.format(title, #list), r, g, b)
    for i = 1, math.min(#list, LIST_MAX) do Line(list[i], playerLevel) end
    if #list > LIST_MAX then
        GameTooltip:AddLine("      " .. string.format(T("tt_quests_more"), #list - LIST_MAX), 0.6, 0.6, 0.6)
    end
end

function Quests.Tooltip()
    local data = Quests.Read()
    if not data then
        GameTooltip:AddLine(T("label_quests") .. " --", 1, 0.82, 0)
        return
    end
    GameTooltip:AddLine(string.format(T("tt_quests"), data.count, data.max), 1, 0.82, 0)
    if data.count == 0 and #data.active == 0 and #data.ready == 0 then
        GameTooltip:AddLine("   " .. T("tt_quests_none"), 0.7, 0.7, 0.7)
        return
    end
    List(T("tt_quests_ready"), data.ready, 0.25, 1, 0.25, data.level)
    List(T("tt_quests_active"), data.active, 1, 0.82, 0, data.level)
    if data.high > 0 and data.level then
        GameTooltip:AddLine("   " .. string.format(T("tt_quests_high"), data.high, data.level + HIGH_LEVELS), 1, 0.4, 0.4, true)
    end
    if data.closed then GameTooltip:AddLine("   " .. T("tt_quests_closed"), 0.6, 0.6, 0.6, true) end
    GameTooltip:AddLine("   " .. T("tt_quests_colors"), 0.5, 0.5, 0.5)
end
