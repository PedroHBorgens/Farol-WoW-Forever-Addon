--[[
  Farol — Registro de masmorras e raides / Dungeon and raid runs

  Ao entrar numa masmorra ou raide, começa uma "corrida": tempo, XP, ouro, saques (raros/épicos) e mortes do PRÓPRIO
  personagem. Ao sair, mostra um resumo no seu chat (opção) e guarda as 10 últimas corridas.
  Só lê e mostra: IsInInstance/GetInstanceInfo, ouro, XP, seus saques e PLAYER_DEAD. Nenhum pedido ao servidor, nada
  enviado, nada de outros jogadores.
  FarolCharDB.runs = { list = { corrida, ... (máx. 10) }, cur = corrida em andamento ou nil }
  corrida = { n = nome limpo, k = "party"/"raid", t = início (time()), s = segundos, x = XP, g = cobre (pode ser
  negativo: consertos), l = saques, r = raros, e = épicos ou melhores, d = mortes, u = última vez visto (só "cur") }
  /reload no meio continua a corrida; mais de 15 min sem ver o jogo fecha a corrida no último momento visto.
]]

local _, ns = ...

local MAX_RUNS = 10
local MIN_SECONDS = 60          -- entrar e sair em menos de 1 minuto não vira registro
local GAP = 15 * 60             -- fora do jogo por mais que isso: a corrida anterior acabou
local MAX_NAME_CHARS = 48
local MAX_TIME = 4102444800     -- ano 2100

local Runs = {}
ns.Runs = Runs

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_run      = "Masmorra / raide atual", cmd_run = "masmorra",
        desc_run      = "Dentro de uma masmorra ou raide: tempo, XP e ouro desta corrida. Fora delas, some da barra.",
        run_party     = "masmorra",
        run_raid      = "raide",
        run_unknown   = "Instância",
        tt_run        = "Instância",
        tt_run_none   = "fora de masmorras e raides",
        tt_run_time   = "Tempo dentro",
        tt_run_xp     = "XP",
        tt_run_xp_rate = "%s (%s por hora)",
        tt_run_gold   = "Ouro",
        tt_run_loot   = "Saques",
        tt_run_deaths = "Mortes",
        tt_run_last   = "Última vez aqui",
        run_rares     = "%d raros",
        run_rare      = "1 raro",
        run_epics     = "%d épicos",
        run_epic      = "1 épico",
        run_left      = "saiu de %s (%s): %s",
        run_line      = "  XP: %s · Ouro: %s · Saques: %s · Mortes: %d",
        run_title     = "Masmorras e raides",
        run_hint      = "As 10 últimas masmorras e raides deste personagem. Só os seus números; nada é enviado.",
        run_col_when  = "Quando", run_col_name = "Instância", run_col_time = "Tempo", run_col_xp = "XP",
        run_col_gold  = "Ouro", run_col_loot = "Saques", run_col_deaths = "Mortes",
        run_empty     = "Nenhuma corrida ainda: entre numa masmorra ou raide.",
        run_summary   = "Mostrar o resumo no chat ao sair",
        run_clear     = "Limpar histórico",
        run_clear_confirm = "Clique de novo",
        run_cleared   = "histórico de masmorras apagado.",
        run_sum_on    = "resumo ao sair de masmorras: ligado.",
        run_sum_off   = "resumo ao sair de masmorras: desligado.",
        run_usage     = "uso: /farol masmorra || /farol masmorra resumo on||off || /farol masmorra limpar",
        help_runs     = "  /farol masmorra      - suas últimas masmorras e raides (tempo, XP, ouro, saques, mortes)",
        tool_runs     = "Masmorras...",   tool_runs_desc = "as 10 últimas corridas: tempo, XP, ouro, saques",
        news_runs     = "registro de masmorras e raides, com resumo ao sair (/farol masmorra)",
    },
    en = {
        name_run      = "Dungeon / raid run", cmd_run = "dungeon",
        desc_run      = "Inside a dungeon or raid: time, XP and gold of this run. Outside, it hides itself.",
        run_party     = "dungeon",
        run_raid      = "raid",
        run_unknown   = "Instance",
        tt_run        = "Instance",
        tt_run_none   = "not in a dungeon or raid",
        tt_run_time   = "Time inside",
        tt_run_xp     = "XP",
        tt_run_xp_rate = "%s (%s per hour)",
        tt_run_gold   = "Gold",
        tt_run_loot   = "Loot",
        tt_run_deaths = "Deaths",
        tt_run_last   = "Last time here",
        run_rares     = "%d rares",
        run_rare      = "1 rare",
        run_epics     = "%d epics",
        run_epic      = "1 epic",
        run_left      = "left %s (%s): %s",
        run_line      = "  XP: %s · Gold: %s · Loot: %s · Deaths: %d",
        run_title     = "Dungeons and raids",
        run_hint      = "This character's last 10 dungeons and raids. Your own numbers only; nothing is sent.",
        run_col_when  = "When", run_col_name = "Instance", run_col_time = "Time", run_col_xp = "XP",
        run_col_gold  = "Gold", run_col_loot = "Loot", run_col_deaths = "Deaths",
        run_empty     = "No runs yet: go into a dungeon or raid.",
        run_summary   = "Show the summary in chat when leaving",
        run_clear     = "Clear history",
        run_clear_confirm = "Click again",
        run_cleared   = "dungeon history cleared.",
        run_sum_on    = "summary when leaving dungeons: on.",
        run_sum_off   = "summary when leaving dungeons: off.",
        run_usage     = "usage: /farol dungeon || /farol dungeon summary on||off || /farol dungeon clear",
        help_runs     = "  /farol dungeon       - your last dungeons and raids (time, XP, gold, loot, deaths)",
        tool_runs     = "Dungeons...",    tool_runs_desc = "the last 10 runs: time, XP, gold, loot",
        news_runs     = "dungeon and raid log, with a summary when you leave (/farol dungeon)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Data()
    if not FarolCharDB then return { list = {} } end
    FarolCharDB.runs = FarolCharDB.runs or { list = {} }
    return FarolCharDB.runs
end

---------------------------------------------------------------------------
-- Leituras e validação
---------------------------------------------------------------------------

local function Num(value)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return nil end
    if ns.IsSecret and ns.IsSecret(value) then return nil end
    return value
end
local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c
end
local function Now()
    local now = Num((Read(time)))
    if now and now > 0 and now < MAX_TIME then return math.floor(now) end
    return nil
end

-- Nome seguro: sem "|", sem caracteres de controle, até MAX_NAME_CHARS letras (UTF-8).
local function CleanName(text)
    if type(text) ~= "string" or (ns.IsSecret and ns.IsSecret(text)) then return "" end
    text = string.gsub(text, "[|%c]", "")
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > MAX_NAME_CHARS then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end

local function Int(value, low, high)
    if type(value) ~= "number" or value ~= value or value ~= math.floor(value) or value < low or value > high then return nil end
    return value
end

local function CleanRun(run, current)
    if type(run) ~= "table" then return nil end
    local name = CleanName(run.n)
    local t = Int(run.t, 1, MAX_TIME)
    if name == "" or not t or (run.k ~= "party" and run.k ~= "raid") then return nil end
    local clean = { n = name, k = run.k, t = t,
        x = Int(run.x, 0, 1e9) or 0, g = Int(run.g, -1e11, 1e11) or 0,
        l = Int(run.l, 0, 100000) or 0, r = Int(run.r, 0, 100000) or 0, e = Int(run.e, 0, 100000) or 0,
        d = Int(run.d, 0, 100000) or 0 }
    if current then
        clean.u = Int(run.u, t, MAX_TIME) or t
    else
        clean.s = Int(run.s, MIN_SECONDS, 7 * 86400)
        if not clean.s then return nil end
    end
    return clean
end

function Runs.Sanitize(saved)
    local clean = { list = {} }
    if type(saved) ~= "table" then return clean end
    if type(saved.list) == "table" then
        for _, run in ipairs(saved.list) do
            local r = CleanRun(run, false)
            if r then clean.list[#clean.list + 1] = r end
        end
        while #clean.list > MAX_RUNS do table.remove(clean.list, 1) end
    end
    clean.cur = CleanRun(saved.cur, true)
    return clean
end

---------------------------------------------------------------------------
-- Formatação
---------------------------------------------------------------------------

local function Duration(seconds)
    seconds = math.max(0, math.floor(seconds))
    if ns.FormatDuration then return ns.FormatDuration(seconds) end
    return string.format("%dm", math.floor(seconds / 60))
end
local function Short(n)
    if n >= 1000 then return string.format("%.1fk", n / 1000) end
    return tostring(math.floor(n))
end
local function Gold(copper)
    local sign = copper < 0 and "-" or "+"
    copper = math.abs(math.floor(copper))
    local g, s = math.floor(copper / 10000), math.floor((copper % 10000) / 100)
    if g > 0 then return string.format("%s%dg %02ds", sign, g, s) end
    return string.format("%s%ds", sign, s)
end
local function Kind(run) return run.k == "raid" and T("run_raid") or T("run_party") end
local function LootText(run)
    local extras = {}
    if run.r > 0 then extras[#extras + 1] = run.r == 1 and T("run_rare") or string.format(T("run_rares"), run.r) end
    if run.e > 0 then extras[#extras + 1] = run.e == 1 and T("run_epic") or string.format(T("run_epics"), run.e) end
    if #extras == 0 then return tostring(run.l) end
    return run.l .. " (" .. table.concat(extras, ", ") .. ")"
end

---------------------------------------------------------------------------
-- Corrida atual
---------------------------------------------------------------------------

local baseXP, baseMoney -- última leitura (só em memória: depois de um /reload a primeira leitura vira a base)

local function Where()
    local inside, kind = Read(IsInInstance)
    if not inside or (kind ~= "party" and kind ~= "raid") then return nil end
    local name = CleanName((Read(GetInstanceInfo)))
    if name == "" then name = T("run_unknown") end
    return name, kind
end

local function Sample(run)
    local xp = ns.GetSessionXP and Num((Read(ns.GetSessionXP))) or nil
    if xp then
        if baseXP and xp > baseXP then run.x = math.min(1e9, run.x + math.floor(xp - baseXP)) end
        baseXP = xp
    end
    local money = Num((Read(GetMoney)))
    if money then
        if baseMoney then run.g = math.max(-1e11, math.min(1e11, run.g + math.floor(money - baseMoney))) end
        baseMoney = money
    end
end

local RefreshWindow -- definida abaixo

local function PrintSummary(run)
    if not (ns.GetDB() and ns.GetDB().runSummary) then return end
    Print(string.format(T("run_left"), run.n, Kind(run), Duration(run.s)))
    Print(string.format(T("run_line"), "+" .. Short(run.x), Gold(run.g), LootText(run), run.d))
end

local function Finish(endTime)
    local data = Data()
    local run = data.cur
    data.cur = nil
    baseXP, baseMoney = nil, nil
    if not run then return end
    run.s = math.floor((endTime or run.u or run.t) - run.t)
    run.u = nil
    if run.s < MIN_SECONDS then return end
    run.s = math.min(run.s, 7 * 86400)
    data.list[#data.list + 1] = run
    while #data.list > MAX_RUNS do table.remove(data.list, 1) end
    PrintSummary(run)
    if RefreshWindow then RefreshWindow() end
end

-- Chamado a cada segundo e nas trocas de zona: começa, continua ou fecha a corrida.
function Runs.Update()
    local now = Now()
    if not now or not FarolCharDB then return end
    local data = Data()
    local cur = data.cur
    if cur and cur.u and now - cur.u > GAP then Finish(cur.u); cur = nil end -- jogo fechado lá dentro
    local name, kind = Where()
    if cur and name ~= cur.n then
        Sample(cur)
        Finish(now)
        cur = nil
    end
    if name and not cur then
        cur = { n = name, k = kind, t = now, u = now, x = 0, g = 0, l = 0, r = 0, e = 0, d = 0 }
        data.cur = cur
        baseXP, baseMoney = nil, nil
    end
    if cur then
        Sample(cur)
        cur.u = now
    end
end

function Runs.OnLoot(quality)
    local cur = Data().cur
    if not cur then return end
    cur.l = math.min(100000, cur.l + 1)
    if quality == 3 then cur.r = math.min(100000, cur.r + 1)
    elseif type(quality) == "number" and quality >= 4 then cur.e = math.min(100000, cur.e + 1) end
end

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

function Runs.BarText()
    local cur = Data().cur
    local now = Now()
    if not cur or not now then return nil end
    return string.format("|cffffcc66%s|r %s · |cff4da6ff+%s XP|r · %s", cur.n, Duration(now - cur.t), Short(cur.x), Gold(cur.g))
end

local function LastHere(name)
    local list = Data().list
    for i = #list, 1, -1 do
        if list[i].n == name then return list[i] end
    end
end

function Runs.Tooltip()
    local cur = Data().cur
    local now = Now()
    local function Pair(label, value) GameTooltip:AddDoubleLine(label, value, 1, 0.82, 0, 1, 1, 1) end
    if not cur or not now then
        Pair(T("tt_run"), T("tt_run_none"))
        local list = Data().list
        local last = list[#list]
        if last then
            GameTooltip:AddDoubleLine("   " .. last.n, Duration(last.s) .. " · +" .. Short(last.x) .. " XP", 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
        end
        return
    end
    local secs = math.max(1, now - cur.t)
    Pair(T("tt_run"), cur.n .. " (" .. Kind(cur) .. ")")
    Pair(T("tt_run_time"), Duration(secs))
    Pair(T("tt_run_xp"), secs >= 60 and string.format(T("tt_run_xp_rate"), "+" .. Short(cur.x), Short(cur.x / secs * 3600)) or ("+" .. Short(cur.x)))
    Pair(T("tt_run_gold"), Gold(cur.g))
    Pair(T("tt_run_loot"), LootText(cur))
    Pair(T("tt_run_deaths"), tostring(cur.d))
    local last = LastHere(cur.n)
    if last then
        local when = ns.FormatWhen and ns.FormatWhen(last.t) or ""
        GameTooltip:AddDoubleLine(T("tt_run_last"), when .. ": " .. Duration(last.s) .. " · +" .. Short(last.x) .. " XP",
            0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
    end
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window
local COLS = { { "run_col_when", 22, 110 }, { "run_col_name", 136, 170 }, { "run_col_time", 312, 70 },
               { "run_col_xp", 386, 70 }, { "run_col_gold", 460, 90 }, { "run_col_loot", 554, 150 },
               { "run_col_deaths", 708, 60 } }

local function SetSummary(value)
    local db = ns.GetDB()
    if not db then return end
    db.runSummary = value
    Print(value and T("run_sum_on") or T("run_sum_off"))
    if RefreshWindow then RefreshWindow() end
end

local function ClearHistory()
    Data().list = {}
    Print(T("run_cleared"))
    if RefreshWindow then RefreshWindow() end
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolRuns", UIParent, ns.backdropTemplate)
    frame:SetSize(780, 120 + MAX_RUNS * 20 + 50)
    frame:SetPoint("CENTER", 0, 30)
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
    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("TOPLEFT", 22, -44)
    frame.header = {}
    for i, col in ipairs(COLS) do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", col[2], -66)
        fs:SetWidth(col[3])
        fs:SetJustifyH("LEFT")
        frame.header[i] = fs
    end
    frame.rows = {}
    for r = 1, MAX_RUNS do
        local row = {}
        for i, col in ipairs(COLS) do
            local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("TOPLEFT", col[2], -88 - (r - 1) * 20)
            fs:SetWidth(col[3])
            fs:SetJustifyH("LEFT")
            row[i] = fs
        end
        frame.rows[r] = row
    end
    frame.empty = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    frame.empty:SetPoint("TOPLEFT", 22, -92)

    local bottom = -96 - MAX_RUNS * 20
    frame.summary = CreateFrame("CheckButton", "FarolRunsSummary", frame, "UICheckButtonTemplate")
    frame.summary:SetSize(24, 24)
    frame.summary:SetPoint("TOPLEFT", 20, bottom)
    frame.summary.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.summary.label:SetPoint("LEFT", frame.summary, "RIGHT", 4, 0)
    frame.summary:SetScript("OnClick", function(self) SetSummary(self:GetChecked() and true or false) end)
    -- "Limpar histórico": pede um segundo clique (em até 5 s) para confirmar.
    frame.clear = CreateFrame("Button", "FarolRunsClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(160, 22)
    frame.clear:SetPoint("TOPRIGHT", -24, bottom)
    frame.clear:SetScript("OnClick", function(self)
        local now = GetTime()
        if self.confirmAt and now - self.confirmAt <= 5 then
            self.confirmAt = nil
            ClearHistory()
        else
            self.confirmAt = now
            self:SetText(T("run_clear_confirm"))
        end
    end)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolRuns") -- ESC fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local list = Data().list
    window.title:SetText(T("run_title"))
    window.hint:SetText(T("run_hint"))
    for i, col in ipairs(COLS) do window.header[i]:SetText(T(col[1])) end
    window.empty:SetText(T("run_empty"))
    if #list == 0 then window.empty:Show() else window.empty:Hide() end
    for r, row in ipairs(window.rows) do
        local run = list[#list - r + 1] -- mais recente primeiro
        local values = run and {
            ns.FormatWhen and ns.FormatWhen(run.t) or "", "|cffffcc66" .. run.n .. "|r", Duration(run.s),
            "|cff4da6ff+" .. Short(run.x) .. "|r", Gold(run.g), LootText(run), run.d > 0 and (ns.C.bad .. run.d .. "|r") or "",
        } or {}
        for i, fs in ipairs(row) do fs:SetText(values[i] or "") end
    end
    local db = ns.GetDB()
    window.summary:SetChecked(db and db.runSummary or false)
    window.summary.label:SetText(T("run_summary"))
    window.clear.confirmAt = nil
    window.clear:SetText(T("run_clear"))
end

function Runs.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end
function Runs.Refresh() RefreshWindow() end

---------------------------------------------------------------------------
-- Comandos: /farol masmorra ...
---------------------------------------------------------------------------

local WORDS = {
    resumo = "summary", summary = "summary",
    limpar = "clear", clear = "clear", apagar = "clear",
}
local SWITCH = { on = true, ligar = true, off = false, desligar = false }

function Runs.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    local action = WORDS[string.lower(word or "")]
    tail = string.lower(tail or "")
    if word == "" then
        Runs.ToggleWindow()
    elseif action == "summary" and SWITCH[tail] ~= nil then
        SetSummary(SWITCH[tail])
    elseif action == "clear" and tail == "" then
        ClearHistory()
    else
        Print(T("run_usage"))
    end
end

---------------------------------------------------------------------------
-- Eventos: troca de zona, morte e uma verificação por segundo (funciona com a barra escondida)
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_DEAD", "PLAYER_LOGOUT" }) do
    pcall(events.RegisterEvent, events, event)
end
local since = 0
events:SetScript("OnEvent", function(_, event)
    if not ns.GetDB() or not FarolCharDB then return end
    if event == "PLAYER_DEAD" then
        local cur = Data().cur
        if cur then cur.d = math.min(100000, cur.d + 1) end
        return
    end
    pcall(Runs.Update)
end)
events:SetScript("OnUpdate", function(_, elapsed)
    since = since + elapsed
    if since < 1 then return end
    since = 0
    if not ns.GetDB() or not FarolCharDB then return end
    pcall(Runs.Update)
end)
