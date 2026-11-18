--[[
  Farol — Metas de ouro e de nível / Gold and level goals

  O jogador escolhe um objetivo ("juntar 100 de ouro", "chegar ao nível 40"); o Farol mostra quanto já tem, quanto
  falta e uma ESTIMATIVA de tempo pelo ritmo da sessão (ouro/h e XP/h que o Core já calcula).
  Só lê e mostra: ouro, nível e XP do próprio personagem; nenhum pedido ao servidor, nada enviado.
  Fica em FarolCharDB.goals = { gold = cobre alvo, level = nível alvo, ls = nível quando a meta foi criada,
  gw/lw = aviso de "alcançada" já mostrado }, validado ao carregar (Goals.Sanitize).
]]

local _, ns = ...

local MAX_GOLD = 1000000            -- ouro (1 milhão)
local COPPER = 10000                -- cobre por ouro
local MAX_LEVEL_FALLBACK = 60       -- estilo clássico, quando o jogo não informa o nível máximo

local Goals = {}
ns.Goals = Goals

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_goals    = "Metas (ouro/nível)", cmd_goals = "meta",
        desc_goals    = "Suas metas de ouro e de nível: quanto falta e uma estimativa de tempo pelo ritmo da sessão.",
        label_goals   = "Meta",
        label_goal_level = "Nv",
        goal_done     = "alcançada",
        tt_goals      = "Metas",
        tt_goals_none = "nenhuma meta (/farol meta ouro 100 ou /farol meta nivel 40)",
        tt_goal_gold  = "Ouro",
        tt_goal_level = "Nível",
        tt_goal_have  = "tem %s de %s (%d%%)",
        tt_goal_eta   = "estimativa: ~%s (por volta das %s)",
        tt_goal_norate = "estimativa: -- (ainda sem ritmo nesta sessão)",
        tt_goal_rate_gold = "ritmo: %s por hora",
        tt_goal_rate_xp = "ritmo: %s XP por hora",
        goal_title    = "Metas",
        goal_hint     = "Escolha uma meta; a barra mostra quanto falta e uma estimativa pelo ritmo da sessão. Itens: /farol meta item [link] 40.",
        goal_gold     = "Ouro:",
        goal_level    = "Nível:",
        goal_set      = "Definir",
        goal_clear    = "Limpar",
        goal_warn     = "Avisar quando alcançar uma meta (ouro, nível ou farm)",
        goal_set_gold = "meta de ouro: %s.",
        goal_set_level = "meta de nível: %d.",
        goal_cleared  = "meta apagada: %s.",
        goal_bad_gold = "meta de ouro inválida: use de 1 a 1000000 (ouro).",
        goal_bad_level = "meta de nível inválida: use um nível maior que o atual, até %d.",
        goal_usage    = "uso: /farol meta || /farol meta ouro N || /farol meta nivel N || /farol meta item [link] N || /farol meta limpar [ouro||nivel] || /farol meta aviso on||off",
        help_goals    = "  /farol meta          - metas de ouro e de nível (quanto falta e estimativa de tempo)",
        tool_goals    = "Metas...",       tool_goals_desc = "ouro e nível: quanto falta e quanto tempo deve levar",
        news_goals    = "metas de ouro e de nível, com estimativa de tempo (/farol meta)",
    },
    en = {
        name_goals    = "Goals (gold/level)", cmd_goals = "goal",
        desc_goals    = "Your gold and level goals: how much is left and a time estimate from this session's pace.",
        label_goals   = "Goal",
        label_goal_level = "Lv",
        goal_done     = "reached",
        tt_goals      = "Goals",
        tt_goals_none = "no goals (/farol goal gold 100 or /farol goal level 40)",
        tt_goal_gold  = "Gold",
        tt_goal_level = "Level",
        tt_goal_have  = "%s of %s (%d%%)",
        tt_goal_eta   = "estimate: ~%s (around %s)",
        tt_goal_norate = "estimate: -- (no pace yet this session)",
        tt_goal_rate_gold = "pace: %s per hour",
        tt_goal_rate_xp = "pace: %s XP per hour",
        goal_title    = "Goals",
        goal_hint     = "Pick a goal; the bar shows how much is left and an estimate from this session's pace. Items: /farol goal item [link] 40.",
        goal_gold     = "Gold:",
        goal_level    = "Level:",
        goal_set      = "Set",
        goal_clear    = "Clear",
        goal_warn     = "Warn when a goal is reached (gold, level or farm)",
        goal_set_gold = "gold goal: %s.",
        goal_set_level = "level goal: %d.",
        goal_cleared  = "goal cleared: %s.",
        goal_bad_gold = "invalid gold goal: use 1 to 1000000 (gold).",
        goal_bad_level = "invalid level goal: use a level above your current one, up to %d.",
        goal_usage    = "usage: /farol goal || /farol goal gold N || /farol goal level N || /farol goal item [link] N || /farol goal clear [gold||level] || /farol goal warn on||off",
        help_goals    = "  /farol goal          - gold and level goals (how much is left and a time estimate)",
        tool_goals    = "Goals...",       tool_goals_desc = "gold and level: how much is left and how long it may take",
        news_goals    = "gold and level goals, with a time estimate (/farol goal)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Data() return FarolCharDB and FarolCharDB.goals or {} end

---------------------------------------------------------------------------
-- Leituras do jogo (protegidas: erro ou valor bloqueado = nil)
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

local function Money() return Num((Read(GetMoney))) end
local function Level() return Num((Read(UnitLevel, "player"))) end
local function MaxLevel()
    local max = Num((Read(GetMaxPlayerLevel)))
    if max and max >= 2 and max <= 200 then return math.floor(max) end
    return MAX_LEVEL_FALLBACK
end
local function XP()
    local cur, max = Num((Read(UnitXP, "player"))), Num((Read(UnitXPMax, "player")))
    if not cur or not max or max <= 0 or cur < 0 then return nil end
    return cur, max
end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

local function Int(value, low, high)
    if type(value) ~= "number" or value ~= value or value ~= math.floor(value) or value < low or value > high then return nil end
    return value
end

function Goals.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    clean.gold = Int(saved.gold, 1, MAX_GOLD * COPPER)
    clean.level = Int(saved.level, 2, 200)
    clean.ls = clean.level and Int(saved.ls, 1, clean.level - 1) or nil
    clean.gw = clean.gold and saved.gw == true or nil
    clean.lw = clean.level and saved.lw == true or nil
    return clean
end

---------------------------------------------------------------------------
-- Progresso e estimativa
---------------------------------------------------------------------------

local function Short(copper)
    local gold = math.floor(copper / COPPER)
    if gold >= 1000 then return string.format("%.1fk", gold / 1000) .. "g" end
    return gold .. "g"
end

-- Ouro: { pct, done, eta (s) ou nil, have, target, rate }
function Goals.GoldStatus()
    local target = Data().gold
    if not target then return nil end
    local have = Money()
    if not have then return { target = target } end
    local pct = math.min(100, math.floor(have / target * 100))
    local status = { target = target, have = have, pct = pct, done = have >= target }
    local rate = ns.GetGoldRate and Num((Read(ns.GetGoldRate))) or nil
    status.rate = rate
    if not status.done and rate and rate > 0 then status.eta = (target - have) / rate * 3600 end
    return status
end

-- Nível: progresso em "níveis" desde que a meta foi criada; estimativa supõe que cada nível que falta custa o XP
-- do nível atual (é só uma estimativa — os próximos níveis costumam custar um pouco mais).
function Goals.LevelStatus()
    local data = Data()
    local target = data.level
    if not target then return nil end
    local level = Level()
    if not level then return { target = target } end
    local status = { target = target, level = level, done = level >= target }
    if status.done then status.pct = 100 return status end
    local cur, max = XP()
    local start = data.ls or (level - 1)
    local doneLevels = (level - start) + (cur and cur / max or 0)
    status.pct = math.max(0, math.min(99, math.floor(doneLevels / (target - start) * 100)))
    local rate = ns.GetXPRate and Num((Read(ns.GetXPRate))) or nil
    status.rate = rate
    if cur and rate and rate > 0 then
        local remaining = (max - cur) + (target - level - 1) * max
        status.eta = remaining / rate * 3600
    end
    return status
end

local function Duration(seconds)
    seconds = math.floor(seconds)
    if seconds >= 86400 then
        return string.format("%dd %dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end
    return ns.FormatDuration and ns.FormatDuration(seconds) or tostring(seconds)
end

local function Part(text, status)
    if status.done then return text .. " |cff40ff40" .. T("goal_done") .. "|r" end
    if not status.pct then return text .. " --" end
    local eta = status.eta and (" ~" .. Duration(status.eta)) or ""
    return string.format("%s |cffffff3a%d%%|r%s", text, status.pct, eta)
end

function Goals.BarText()
    local gold, level = Goals.GoldStatus(), Goals.LevelStatus()
    if not gold and not level then return T("label_goals") .. " |cff888888--|r" end
    local parts = {}
    if gold then parts[#parts + 1] = Part(Short(gold.target), gold) end
    if level then parts[#parts + 1] = Part(T("label_goal_level") .. " " .. level.target, level) end
    return T("label_goals") .. " " .. table.concat(parts, " · ")
end

local function Around(seconds)
    local now = Read(time)
    if type(now) ~= "number" or now ~= now or seconds ~= seconds or seconds > 365 * 86400 then return "--" end
    local ok, text = pcall(date, "%H:%M", math.floor(now + seconds))
    return ok and text or "--"
end

function Goals.Tooltip()
    local gold, level = Goals.GoldStatus(), Goals.LevelStatus()
    GameTooltip:AddLine(T("tt_goals"), 1, 0.82, 0)
    if not gold and not level then
        GameTooltip:AddLine("   " .. T("tt_goals_none"), 0.7, 0.7, 0.7)
        return
    end
    local function Lines(name, status, haveText, targetText, rateText)
        local value = status.done and ("|cff40ff40" .. T("goal_done") .. "|r")
            or (status.pct and string.format(T("tt_goal_have"), haveText, targetText, status.pct) or "--")
        GameTooltip:AddDoubleLine("   " .. name .. " " .. targetText, value, 0.9, 0.9, 0.9, 1, 1, 1)
        if status.done then return end
        if status.eta then
            GameTooltip:AddLine("      " .. string.format(T("tt_goal_eta"), Duration(status.eta), Around(status.eta)), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("      " .. T("tt_goal_norate"), 0.7, 0.7, 0.7)
        end
        if rateText then GameTooltip:AddLine("      " .. rateText, 0.7, 0.7, 0.7) end
    end
    if gold then
        Lines(T("tt_goal_gold"), gold, gold.have and Short(gold.have) or "--", Short(gold.target),
            gold.rate and string.format(T("tt_goal_rate_gold"), Short(math.max(0, gold.rate))) or nil)
    end
    if level then
        Lines(T("tt_goal_level"), level, level.level and tostring(level.level) or "--", tostring(level.target),
            level.rate and string.format(T("tt_goal_rate_xp"), tostring(math.floor(level.rate))) or nil)
    end
end

-- Para o aviso: metas alcançadas que ainda não foram avisadas (marca como avisadas).
function Goals.NewlyReached()
    local data, list = Data(), {}
    local gold = Goals.GoldStatus()
    if gold and gold.done and not data.gw then data.gw = true; list[#list + 1] = Short(gold.target) end
    local level = Goals.LevelStatus()
    if level and level.done and not data.lw then
        data.lw = true; list[#list + 1] = T("tt_goal_level") .. " " .. level.target
    end
    if ns.Farm then
        for _, text in ipairs(ns.Farm.NewlyReached()) do list[#list + 1] = text end
    end
    return list
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo
local function Changed()
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
end

function Goals.SetGold(text)
    local gold = tonumber(text)
    if not gold or gold ~= math.floor(gold) or gold < 1 or gold > MAX_GOLD then Print(T("goal_bad_gold")) return false end
    local data = Data()
    data.gold, data.gw = gold * COPPER, nil
    Print(string.format(T("goal_set_gold"), Short(data.gold)))
    Changed()
    return true
end

function Goals.SetLevel(text)
    local target, level, max = tonumber(text), Level(), MaxLevel()
    if not target or target ~= math.floor(target) or not level or target <= level or target > max then
        Print(string.format(T("goal_bad_level"), max))
        return false
    end
    local data = Data()
    data.level, data.ls, data.lw = target, math.floor(level), nil
    Print(string.format(T("goal_set_level"), target))
    Changed()
    return true
end

function Goals.Clear(kind)
    local data = Data()
    if kind ~= "level" then data.gold, data.gw = nil, nil end
    if kind ~= "gold" then data.level, data.ls, data.lw = nil, nil, nil end
    Print(string.format(T("goal_cleared"), kind == "gold" and T("tt_goal_gold") or kind == "level" and T("tt_goal_level")
        or (T("tt_goal_gold") .. " / " .. T("tt_goal_level"))))
    Changed()
end

local function SetWarning(value)
    local settings = ns.GetDB() and ns.GetDB().warnings
    if not settings then return end
    settings.goals = value
    Print(string.format(value and T("warn_on") or T("warn_off"), T("warn_name_goals")))
    if ns.Warnings and ns.Warnings.RefreshControls then ns.Warnings.RefreshControls() end
    Changed()
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolGoals", UIParent, ns.backdropTemplate)
    frame:SetSize(440, 280)
    frame:SetPoint("CENTER", 30, 20)
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
    frame.hint:SetWidth(396)
    frame.hint:SetJustifyH("LEFT")

    local function Row(kind, y, digits, onSet)
        local row = {}
        row.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("TOPLEFT", 24, y - 4)
        row.box = CreateFrame("EditBox", "FarolGoal" .. kind, frame, "InputBoxTemplate")
        row.box:SetSize(digits * 10 + 12, 20)
        row.box:SetPoint("TOPLEFT", 84, y)
        row.box:SetAutoFocus(false)
        row.box:SetNumeric(true)
        row.box:SetMaxLetters(digits)
        local function apply() if onSet(row.box:GetText()) then row.box:ClearFocus() end end
        row.box:SetScript("OnEnterPressed", apply)
        row.box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        row.set = CreateFrame("Button", "FarolGoal" .. kind .. "Set", frame, "UIPanelButtonTemplate")
        row.set:SetSize(80, 22)
        row.set:SetPoint("TOPLEFT", 190, y + 1)
        row.set:SetScript("OnClick", apply)
        row.clear = CreateFrame("Button", "FarolGoal" .. kind .. "Clear", frame, "UIPanelButtonTemplate")
        row.clear:SetSize(80, 22)
        row.clear:SetPoint("LEFT", row.set, "RIGHT", 6, 0)
        row.clear:SetScript("OnClick", function() Goals.Clear(kind == "Gold" and "gold" or "level") end)
        row.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.status:SetPoint("TOPLEFT", 30, y - 26)
        return row
    end
    frame.gold = Row("Gold", -80, 7, Goals.SetGold)
    frame.level = Row("Level", -138, 3, Goals.SetLevel)

    frame.warn = CreateFrame("CheckButton", "FarolGoalWarn", frame, "UICheckButtonTemplate")
    frame.warn:SetSize(24, 24)
    frame.warn:SetPoint("BOTTOMLEFT", 20, 18)
    frame.warn.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.warn.label:SetPoint("LEFT", frame.warn, "RIGHT", 4, 0)
    frame.warn:SetScript("OnClick", function(self) SetWarning(self:GetChecked() and true or false) end)

    if ns.Farm then ns.Farm.Attach(frame, -192) end -- metas de farm (Farm.lua)
    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolGoals") -- ESC fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

local function StatusText(status, have, target)
    if not status then return "" end
    if status.done then return "|cff40ff40" .. T("goal_done") .. "|r" end
    if not status.pct then return "--" end
    local text = string.format(T("tt_goal_have"), have, target, status.pct)
    if status.eta then text = text .. " · ~" .. Duration(status.eta) end
    return text
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local data = Data()
    window.title:SetText(T("goal_title"))
    window.hint:SetText(T("goal_hint"))
    for _, entry in ipairs({ { window.gold, "goal_gold" }, { window.level, "goal_level" } }) do
        entry[1].label:SetText(T(entry[2]))
        entry[1].set:SetText(T("goal_set"))
        entry[1].clear:SetText(T("goal_clear"))
    end
    if not window.gold.box:HasFocus() then window.gold.box:SetText(data.gold and tostring(math.floor(data.gold / COPPER)) or "") end
    if not window.level.box:HasFocus() then window.level.box:SetText(data.level and tostring(data.level) or "") end
    local gold, level = Goals.GoldStatus(), Goals.LevelStatus()
    window.gold.status:SetText(gold and StatusText(gold, gold.have and Short(gold.have) or "--", Short(gold.target)) or "")
    window.level.status:SetText(level and StatusText(level, level.level and tostring(level.level) or "--", tostring(level.target)) or "")
    local settings = ns.GetDB() and ns.GetDB().warnings
    window.warn:SetChecked(settings and settings.goals or false)
    window.warn.label:SetText(T("goal_warn"))
    local rows = ns.Farm and ns.Farm.RefreshRows(window) or 0
    window:SetHeight(280 + rows * (ns.Farm and ns.Farm.ROW_H or 0))
end

function Goals.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end
function Goals.Refresh() RefreshWindow() end

---------------------------------------------------------------------------
-- Comandos: /farol meta ...
---------------------------------------------------------------------------

local WORDS = {
    ouro = "gold", gold = "gold", g = "gold",
    nivel = "level", level = "level", lvl = "level", nv = "level",
    limpar = "clear", clear = "clear", apagar = "clear", remove = "clear",
    aviso = "warn", avisar = "warn", warn = "warn",
    item = "item", itens = "item", items = "item", farm = "item",
}
local SWITCH = { on = true, ligar = true, off = false, desligar = false }

function Goals.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    local action = WORDS[string.lower(word or "")]
    if action == "item" and ns.Farm then return ns.Farm.HandleCommand(tail) end -- nomes e links mantêm maiúsculas
    tail = string.lower(tail or "")
    if word == "" then
        Goals.ToggleWindow()
    elseif action == "gold" and string.match(tail, "^%d+$") then
        Goals.SetGold(tail)
    elseif action == "level" and string.match(tail, "^%d+$") then
        Goals.SetLevel(tail)
    elseif action == "clear" and (tail == "" or WORDS[tail] == "gold" or WORDS[tail] == "level") then
        Goals.Clear(tail ~= "" and WORDS[tail] or nil)
    elseif action == "warn" and SWITCH[tail] ~= nil then
        SetWarning(SWITCH[tail])
    else
        Print(T("goal_usage"))
    end
end
