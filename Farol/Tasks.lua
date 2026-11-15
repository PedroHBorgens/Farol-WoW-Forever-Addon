--[[
  Farol — Lista de tarefas diárias e semanais / Daily and weekly task list

  O jogador escreve suas tarefas (até 10, por personagem) e marca o que já fez. As diárias voltam a "não feita"
  no reset diário; as semanais, no semanal (horários lidos com ns.GetResetTimes, já validados).
  Só lê e mostra: o addon não confere missões, instâncias nem nada no jogo; quem marca é o jogador.
  Fica em FarolCharDB.tasks = { { n = nome limpo, w = semanal?, d = quando foi marcada (time()) }, ... },
  validado ao carregar (Tasks.Sanitize).
]]

local _, ns = ...

local MAX_TASKS = 10
local MAX_NAME_CHARS = 40
local DAY, WEEK = 86400, 7 * 86400
local ROW_HEIGHT = 24

local Tasks = {}
ns.Tasks = Tasks

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_tasks    = "Tarefas (diárias/semanais)", cmd_tasks = "tarefas",
        desc_tasks    = "Sua lista de tarefas: quantas já fez. As diárias e as semanais zeram sozinhas no reset.",
        label_tasks   = "Tarefas",
        tt_tasks      = "Tarefas",
        tt_tasks_none = "nenhuma tarefa (/farol tarefa add Nome)",
        tt_task_done  = "feita",
        tt_task_todo  = "falta",
        tt_task_daily = "diária",
        tt_task_weekly = "semanal",
        tt_tasks_reset = "zeram em",
        task_title    = "Tarefas",
        task_hint     = "Marque o que já fez. Diárias zeram no reset diário; semanais, no semanal.",
        task_empty    = "Nenhuma tarefa ainda: escreva abaixo e clique em Adicionar.",
        task_daily    = "Diária",
        task_weekly   = "Semanal",
        task_add      = "Adicionar",
        task_warn     = "Avisar 1 h antes do reset diário se faltar alguma diária",
        task_resets   = "Reset diário em %s · semanal em %s",
        task_added    = "tarefa adicionada: %s (%s).",
        task_removed  = "tarefa apagada: %s.",
        task_marked   = "tarefa %s: %s.",
        task_full     = "a lista já tem 10 tarefas; apague uma antes.",
        task_bad_name = "escreva um nome para a tarefa (até 40 letras, sem \"||\").",
        task_bad_num  = "não existe a tarefa %s (use /farol tarefa lista).",
        task_list     = "Farol — tarefas (%d de %d feitas):",
        task_line     = "  %d. %s (%s): %s",
        task_usage    = "uso: /farol tarefa || /farol tarefa add [diaria||semanal] Nome || /farol tarefa feita N || /farol tarefa apagar N || /farol tarefa lista || /farol tarefa aviso on||off",
        help_tasks    = "  /farol tarefa        - lista de tarefas diárias e semanais (zera sozinha no reset)",
        opt_tasks     = "Tarefas...",
        news_tasks    = "lista de tarefas diárias e semanais que zera sozinha no reset (/farol tarefa)",
    },
    en = {
        name_tasks    = "Tasks (daily/weekly)", cmd_tasks = "tasks",
        desc_tasks    = "Your task list: how many you have done. Daily and weekly tasks reset on their own.",
        label_tasks   = "Tasks",
        tt_tasks      = "Tasks",
        tt_tasks_none = "no tasks (/farol task add Name)",
        tt_task_done  = "done",
        tt_task_todo  = "to do",
        tt_task_daily = "daily",
        tt_task_weekly = "weekly",
        tt_tasks_reset = "reset in",
        task_title    = "Tasks",
        task_hint     = "Tick what you have done. Daily tasks reset at the daily reset; weekly, at the weekly one.",
        task_empty    = "No tasks yet: type one below and click Add.",
        task_daily    = "Daily",
        task_weekly   = "Weekly",
        task_add      = "Add",
        task_warn     = "Warn 1 h before the daily reset if a daily task is left",
        task_resets   = "Daily reset in %s · weekly in %s",
        task_added    = "task added: %s (%s).",
        task_removed  = "task removed: %s.",
        task_marked   = "task %s: %s.",
        task_full     = "the list already has 10 tasks; remove one first.",
        task_bad_name = "type a name for the task (up to 40 letters, no \"||\").",
        task_bad_num  = "there is no task %s (use /farol task list).",
        task_list     = "Farol — tasks (%d of %d done):",
        task_line     = "  %d. %s (%s): %s",
        task_usage    = "usage: /farol task || /farol task add [daily||weekly] Name || /farol task done N || /farol task remove N || /farol task list || /farol task warn on||off",
        help_tasks    = "  /farol task          - daily and weekly task list (resets on its own)",
        opt_tasks     = "Tasks...",
        news_tasks    = "daily and weekly task list that resets on its own (/farol task)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function List() return FarolCharDB and FarolCharDB.tasks or {} end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

-- Nome seguro: sem "|" (códigos do chat do WoW), sem caracteres de controle, até MAX_NAME_CHARS letras (UTF-8).
local function CleanName(text)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "|", "")
    text = string.gsub(text, "%c", "")
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > MAX_NAME_CHARS then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end
Tasks.CleanName = CleanName

local function Now()
    local ok, now = pcall(time)
    if ok and type(now) == "number" and now == now and now > 0 and now < 4102444800 then return now end
    return nil
end

function Tasks.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    local now = Now() or 4102444800
    for _, entry in ipairs(saved) do
        if #clean >= MAX_TASKS then break end
        if type(entry) == "table" then
            local name = CleanName(entry.n)
            if name ~= "" then
                local d = entry.d
                if type(d) ~= "number" or d ~= d or d <= 0 or d > now + 60 then d = nil end
                clean[#clean + 1] = { n = name, w = entry.w == true, d = d and math.floor(d) or nil }
            end
        end
    end
    return clean
end

---------------------------------------------------------------------------
-- Feita ou não: marcada depois do último reset do tipo dela.
---------------------------------------------------------------------------

local function Resets()
    if not ns.GetResetTimes then return nil, nil end
    local ok, daily, weekly = pcall(ns.GetResetTimes)
    if not ok then return nil, nil end
    return daily, weekly
end

-- Sem o horário do reset (cliente antigo), a marca vale por 1 dia (diária) ou 7 dias (semanal).
local function IsDone(task, now, daily, weekly)
    if not task.d or not now then return false end
    local secs, period = daily, DAY
    if task.w then secs, period = weekly, WEEK end
    local lastReset = secs and (now + secs - period) or (now - period)
    return task.d > lastReset
end

function Tasks.Counts()
    local now, daily, weekly = Now(), Resets()
    local done, total, dailyLeft = 0, 0, 0
    for _, task in ipairs(List()) do
        total = total + 1
        if IsDone(task, now, daily, weekly) then
            done = done + 1
        elseif not task.w then
            dailyLeft = dailyLeft + 1
        end
    end
    return done, total, dailyLeft, daily
end

-- Para o aviso: diárias que faltam e segundos até o reset diário.
function Tasks.PendingDaily()
    local _, _, dailyLeft, daily = Tasks.Counts()
    return dailyLeft, daily
end

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

function Tasks.BarText()
    local done, total = Tasks.Counts()
    if total == 0 then return T("label_tasks") .. " |cff888888--|r" end
    local color = done >= total and "|cff40ff40" or "|cffffff3a"
    return string.format("%s %s%d/%d|r", T("label_tasks"), color, done, total)
end

local function Countdown(seconds)
    if not seconds then return "--" end
    seconds = math.floor(seconds)
    if seconds >= DAY then
        return string.format("%dd %dh", math.floor(seconds / DAY), math.floor((seconds % DAY) / 3600))
    end
    return ns.FormatDuration and ns.FormatDuration(seconds) or tostring(seconds)
end

function Tasks.Tooltip()
    local list = List()
    local now, daily, weekly = Now(), Resets()
    local done, total = Tasks.Counts()
    GameTooltip:AddDoubleLine(T("tt_tasks"), total > 0 and string.format("%d / %d", done, total) or "--",
        1, 0.82, 0, 1, 1, 1)
    if total == 0 then
        GameTooltip:AddLine("   " .. T("tt_tasks_none"), 0.7, 0.7, 0.7)
        return
    end
    for _, task in ipairs(list) do
        local ok = IsDone(task, now, daily, weekly)
        local kind = task.w and T("tt_task_weekly") or T("tt_task_daily")
        GameTooltip:AddDoubleLine("   " .. task.n .. " |cff888888(" .. kind .. ")|r",
            ok and T("tt_task_done") or T("tt_task_todo"),
            0.9, 0.9, 0.9, ok and 0.25 or 1, ok and 1 or 1, ok and 0.25 or 0.23)
    end
    GameTooltip:AddDoubleLine("   " .. T("tt_tasks_reset"),
        string.format("%s %s · %s %s", T("tt_task_daily"), Countdown(daily), T("tt_task_weekly"), Countdown(weekly)),
        0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function Changed()
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
end

function Tasks.Add(name, weekly)
    local list = List()
    if #list >= MAX_TASKS then Print(T("task_full")) return false end
    name = CleanName(name)
    if name == "" then Print(T("task_bad_name")) return false end
    list[#list + 1] = { n = name, w = weekly == true }
    Print(string.format(T("task_added"), name, weekly and T("tt_task_weekly") or T("tt_task_daily")))
    Changed()
    return true
end

function Tasks.Remove(index)
    local list = List()
    local task = list[index]
    if not task then Print(string.format(T("task_bad_num"), tostring(index))) return end
    table.remove(list, index)
    Print(string.format(T("task_removed"), task.n))
    Changed()
end

-- Marca (true) ou desmarca (false) a tarefa; sem "value", inverte.
function Tasks.SetDone(index, value)
    local task = List()[index]
    if not task then Print(string.format(T("task_bad_num"), tostring(index))) return end
    local now, daily, weekly = Now(), Resets()
    if value == nil then value = not IsDone(task, now, daily, weekly) end
    task.d = value and now or nil
    Print(string.format(T("task_marked"), task.n, value and T("tt_task_done") or T("tt_task_todo")))
    Changed()
end

local function SetWarning(value)
    local settings = ns.GetDB() and ns.GetDB().warnings
    if not settings then return end
    settings.tasks = value
    if ns.Warnings and ns.Warnings.TasksChanged then ns.Warnings.TasksChanged() end
    Print(string.format(value and T("warn_on") or T("warn_off"), T("warn_name_tasks")))
    Changed()
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window
local newWeekly = false

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolTasks", UIParent, ns.backdropTemplate)
    frame:SetSize(460, 118 + MAX_TASKS * ROW_HEIGHT + 96)
    frame:SetPoint("CENTER", 40, 0)
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
    frame.hint:SetWidth(416)
    frame.hint:SetJustifyH("LEFT")
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("TOPLEFT", 26, -80)

    frame.rows = {}
    for i = 1, MAX_TASKS do
        local y = -70 - (i - 1) * ROW_HEIGHT
        local row = {}
        row.check = CreateFrame("CheckButton", "FarolTaskDone" .. i, frame, "UICheckButtonTemplate")
        row.check:SetSize(24, 24)
        row.check:SetPoint("TOPLEFT", 20, y)
        row.check:SetScript("OnClick", function(self) Tasks.SetDone(i, self:GetChecked() and true or false) end)
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
        row.text:SetWidth(270)
        row.text:SetJustifyH("LEFT")
        row.kind = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.kind:SetPoint("TOPRIGHT", -62, y - 6)
        row.remove = CreateFrame("Button", "FarolTaskRemove" .. i, frame, "UIPanelButtonTemplate")
        row.remove:SetSize(24, 20)
        row.remove:SetPoint("TOPRIGHT", -26, y - 2)
        row.remove:SetText("X")
        row.remove:SetScript("OnClick", function() Tasks.Remove(i) end)
        frame.rows[i] = row
    end

    local addY = -70 - MAX_TASKS * ROW_HEIGHT - 10
    frame.name = CreateFrame("EditBox", "FarolTaskName", frame, "InputBoxTemplate")
    frame.name:SetSize(220, 20)
    frame.name:SetPoint("TOPLEFT", 30, addY)
    frame.name:SetAutoFocus(false)
    frame.name:SetMaxLetters(MAX_NAME_CHARS)
    frame.kind = CreateFrame("Button", "FarolTaskKind", frame, "UIPanelButtonTemplate")
    frame.kind:SetSize(80, 22)
    frame.kind:SetPoint("LEFT", frame.name, "RIGHT", 8, 0)
    frame.kind:SetScript("OnClick", function() newWeekly = not newWeekly; RefreshWindow() end)
    frame.add = CreateFrame("Button", "FarolTaskAdd", frame, "UIPanelButtonTemplate")
    frame.add:SetSize(96, 22)
    frame.add:SetPoint("LEFT", frame.kind, "RIGHT", 6, 0)
    local function AddFromBox()
        if Tasks.Add(frame.name:GetText(), newWeekly) then frame.name:SetText("") end
        frame.name:ClearFocus()
    end
    frame.add:SetScript("OnClick", AddFromBox)
    frame.name:SetScript("OnEnterPressed", AddFromBox)
    frame.name:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    frame.warn = CreateFrame("CheckButton", "FarolTaskWarn", frame, "UICheckButtonTemplate")
    frame.warn:SetSize(24, 24)
    frame.warn:SetPoint("TOPLEFT", 20, addY - 30)
    frame.warn.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.warn.label:SetPoint("LEFT", frame.warn, "RIGHT", 4, 0)
    frame.warn:SetScript("OnClick", function(self) SetWarning(self:GetChecked() and true or false) end)
    frame.resets = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.resets:SetPoint("TOPLEFT", 26, addY - 60)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolTasks") -- ESC fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local list = List()
    local now, daily, weekly = Now(), Resets()
    window.title:SetText(T("task_title"))
    window.hint:SetText(T("task_hint"))
    window.empty:SetText(T("task_empty"))
    if #list == 0 then window.empty:Show() else window.empty:Hide() end
    for i, row in ipairs(window.rows) do
        local task = list[i]
        if task then
            local ok = IsDone(task, now, daily, weekly)
            row.check:SetChecked(ok)
            row.text:SetText(ok and ("|cff40ff40" .. task.n .. "|r") or task.n)
            row.kind:SetText(task.w and T("tt_task_weekly") or T("tt_task_daily"))
            row.check:Show(); row.text:Show(); row.kind:Show(); row.remove:Show()
        else
            row.check:Hide(); row.text:Hide(); row.kind:Hide(); row.remove:Hide()
        end
    end
    window.kind:SetText(newWeekly and T("task_weekly") or T("task_daily"))
    window.add:SetText(T("task_add"))
    local settings = ns.GetDB() and ns.GetDB().warnings
    window.warn:SetChecked(settings and settings.tasks or false)
    window.warn.label:SetText(T("task_warn"))
    window.resets:SetText(string.format(T("task_resets"), Countdown(daily), Countdown(weekly)))
end

function Tasks.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Tasks.Refresh() RefreshWindow() end

---------------------------------------------------------------------------
-- Comandos: /farol tarefa ...
---------------------------------------------------------------------------

local WORDS = {
    add = "add", adicionar = "add", nova = "add", new = "add",
    feita = "done", feito = "done", done = "done", marcar = "done", check = "done",
    apagar = "remove", remover = "remove", remove = "remove", del = "remove", delete = "remove",
    lista = "list", listar = "list", list = "list",
    aviso = "warn", avisar = "warn", warn = "warn", warning = "warn",
}
local KINDS = { diaria = false, daily = false, semanal = true, weekly = true }
local SWITCH = { on = true, ligar = true, off = false, desligar = false }

local function PrintList()
    local list = List()
    local now, daily, weekly = Now(), Resets()
    local done, total = Tasks.Counts()
    Print(string.format(T("task_list"), done, total))
    if total == 0 then Print("  " .. T("tt_tasks_none")) return end
    for i, task in ipairs(list) do
        Print(string.format(T("task_line"), i, task.n, task.w and T("tt_task_weekly") or T("tt_task_daily"),
            IsDone(task, now, daily, weekly) and T("tt_task_done") or T("tt_task_todo")))
    end
end

function Tasks.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    word = string.lower(word or "")
    local action = WORDS[word]
    if word == "" then
        Tasks.ToggleWindow()
    elseif action == "add" then
        local kindWord, name = string.match(tail or "", "^(%a+)%s+(.+)$")
        local weekly = false
        if kindWord and KINDS[string.lower(kindWord)] ~= nil then
            weekly = KINDS[string.lower(kindWord)]
        else
            name = tail
        end
        Tasks.Add(string.sub(name or "", 1, 200), weekly)
    elseif action == "done" or action == "remove" then
        local n = tonumber(string.match(tail or "", "^(%d%d?)$"))
        if not n or not List()[n] then Print(string.format(T("task_bad_num"), (string.gsub(string.sub(tail or "", 1, 10), "|", "")))) return end
        if action == "done" then Tasks.SetDone(n) else Tasks.Remove(n) end
    elseif action == "list" and tail == "" then
        PrintList()
    elseif action == "warn" and SWITCH[string.lower(tail or "")] ~= nil then
        SetWarning(SWITCH[string.lower(tail)])
    else
        Print(T("task_usage"))
    end
end
