--[[
  Farol — Alarmes do relógio / Clock alarms

  * Até 10 alarmes, cada um com hora local ou do servidor, nome opcional e liga/desliga.
  * Quando toca: som + mensagem no chat SÓ PARA VOCÊ (nada é enviado ao servidor ou a outros
    jogadores), repetindo a cada 30 s até você apertar "Soneca" ou "Parar".
  * Tempo da soneca configurável de 1 a 60 minutos (padrão 5).
  * Funciona mesmo com o painel escondido.

  Segurança: o nome do alarme é limpo (sem códigos "|" de cor/link/textura, sem caracteres de
  controle, tamanho limitado) e os alarmes salvos são validados ao carregar.
]]

local _, ns = ...

local MAX_ALARMS = 10
local REPEAT_SECONDS = 30
local SNOOZE_MIN, SNOOZE_MAX = 1, 60 -- limites da soneca, em minutos
local MAX_LABEL_CHARS = 30
local ICON = "|TInterface\\Icons\\INV_Misc_PocketWatch_01:14:14|t"

local Alarm = {}
ns.Alarm = Alarm

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        al_title      = "Alarmes",
        al_hint       = "Até 10 alarmes. Marque a caixinha para ativar.",
        al_empty      = "Nenhum alarme criado.",
        al_new        = "Novo alarme",
        al_label_ph   = "nome (opcional)",
        al_add        = "Adicionar",
        al_test       = "Testar som",
        al_local      = "Local",
        al_server     = "Servidor",
        al_ringing    = "Alarme!",
        al_snooze_btn = "Soneca (%d min)",
        al_snooze_label = "Tempo da soneca:",
        al_snooze_unit = "min",
        al_snooze_set = "soneca configurada para %d min.",
        al_bad_snooze = "tempo de soneca inválido: use de 1 a 60 minutos.",
        al_stop_btn   = "Parar",
        al_chat_hint  = "— /farol soneca ou /farol parar",
        al_added      = "alarme adicionado: %s",
        al_removed    = "alarme removido: %s",
        al_on         = "alarme ativado: %s",
        al_off        = "alarme desativado: %s",
        al_snoozed    = "soneca: o alarme toca de novo às %s.",
        al_stopped    = "alarme parado.",
        al_none_ringing = "nenhum alarme tocando.",
        al_full       = "limite de 10 alarmes atingido.",
        al_bad_time   = "horário inválido. Use HH:MM, por exemplo 07:30.",
        al_bad_index  = "número de alarme inválido. Veja /farol alarme lista.",
        al_list_title = "alarmes:",
        al_list_empty = "nenhum alarme. Crie com /farol alarme add 07:30",
        al_more       = "+%d tocando",
        tt_alarms     = "Alarmes ativos",
        help_alarm    = "  /farol alarme        - abrir a janela de alarmes",
        help_alarm2   = "  /farol alarme add 07:30 [local||servidor] [nome] || lista || remover N || ativar N || desativar N || soneca MIN",
        help_alarm3   = "  /farol soneca [MIN] || /farol parar - adiar (tempo configurado ou MIN) ou parar o alarme",
    },
    en = {
        al_title      = "Alarms",
        al_hint       = "Up to 10 alarms. Tick the box to enable.",
        al_empty      = "No alarms yet.",
        al_new        = "New alarm",
        al_label_ph   = "name (optional)",
        al_add        = "Add",
        al_test       = "Test sound",
        al_local      = "Local",
        al_server     = "Server",
        al_ringing    = "Alarm!",
        al_snooze_btn = "Snooze (%d min)",
        al_snooze_label = "Snooze time:",
        al_snooze_unit = "min",
        al_snooze_set = "snooze set to %d min.",
        al_bad_snooze = "invalid snooze time: use 1 to 60 minutes.",
        al_stop_btn   = "Stop",
        al_chat_hint  = "— /farol snooze or /farol stop",
        al_added      = "alarm added: %s",
        al_removed    = "alarm removed: %s",
        al_on         = "alarm enabled: %s",
        al_off        = "alarm disabled: %s",
        al_snoozed    = "snoozed: the alarm rings again at %s.",
        al_stopped    = "alarm stopped.",
        al_none_ringing = "no alarm is ringing.",
        al_full       = "limit of 10 alarms reached.",
        al_bad_time   = "invalid time. Use HH:MM, e.g. 07:30.",
        al_bad_index  = "invalid alarm number. See /farol alarm list.",
        al_list_title = "alarms:",
        al_list_empty = "no alarms. Create one with /farol alarm add 07:30",
        al_more       = "+%d ringing",
        tt_alarms     = "Active alarms",
        help_alarm    = "  /farol alarm         - open the alarms window",
        help_alarm2   = "  /farol alarm add 07:30 [local||server] [name] || list || remove N || on N || off N || snooze MIN",
        help_alarm3   = "  /farol snooze [MIN] || /farol stop - delay (configured time or MIN) or stop the alarm",
    },
}

-- Junta estes textos aos do Core, para que ns.T encontre todos.
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function DB() return ns.GetDB() end

---------------------------------------------------------------------------
-- Dados: validação e formatação
---------------------------------------------------------------------------

-- Nome seguro: sem "|" (códigos de cor, link e textura do WoW), sem caracteres de controle,
-- no máximo MAX_LABEL_CHARS caracteres (contando acentos corretamente em UTF-8).
local function CleanLabel(text)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "|", "")
    text = string.gsub(text, "%c", "")
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > MAX_LABEL_CHARS then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end

local function ValidTime(hour, minute)
    return type(hour) == "number" and type(minute) == "number"
        and hour == math.floor(hour) and minute == math.floor(minute)
        and hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59
end

-- Aceita "7:30", "07:30" ou "7h30".
local function ParseTime(text)
    local h, m = string.match(text or "", "^(%d%d?)[:hH](%d%d)$")
    h, m = tonumber(h), tonumber(m)
    if ValidTime(h, m) then return h, m end
    return nil
end

-- Valida a lista salva: só entradas completas e corretas sobrevivem.
function Alarm.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    for _, entry in ipairs(saved) do
        if #clean >= MAX_ALARMS then break end
        if type(entry) == "table" and ValidTime(entry.h, entry.m) then
            clean[#clean + 1] = {
                h = entry.h,
                m = entry.m,
                server = entry.server == true,
                enabled = entry.enabled ~= false,
                label = CleanLabel(entry.label),
            }
        end
    end
    return clean
end

local function Describe(alarm)
    local text = string.format("%02d:%02d (%s)", alarm.h, alarm.m,
        alarm.server and T("al_server") or T("al_local"))
    if alarm.label ~= "" then text = text .. " " .. alarm.label end
    return text
end

local function NowHM(server)
    if server and GetGameTime then
        local hour, minute = GetGameTime()
        return hour, minute
    end
    local now = date("*t")
    return now.hour, now.min
end

local function FormatClock(seconds)
    return date("%H:%M", seconds)
end

function Alarm.HasEnabled()
    local db = DB()
    if not db or not db.alarms then return false end
    for _, alarm in ipairs(db.alarms) do
        if alarm.enabled then return true end
    end
    return false
end

function Alarm.AddTooltipLines(addPair)
    local db = DB()
    if not db or not db.alarms then return end
    local lines = {}
    for _, alarm in ipairs(db.alarms) do
        if alarm.enabled then lines[#lines + 1] = Describe(alarm) end
    end
    if #lines > 0 then addPair(T("tt_alarms"), table.concat(lines, "\n")) end
end

---------------------------------------------------------------------------
-- Tocar o alarme
---------------------------------------------------------------------------

-- Converte e valida minutos de soneca (número inteiro de 1 a 60); nil se inválido.
local function ValidSnooze(value)
    value = tonumber(value)
    if value and value == math.floor(value) and value >= SNOOZE_MIN and value <= SNOOZE_MAX then
        return value
    end
    return nil
end

local function SnoozeMinutes()
    return ValidSnooze(DB().snoozeMinutes) or 5
end

local ringing = {}   -- alarmes tocando agora: { alarm = ..., nextAt = GetTime() }
local armed = {}     -- [alarm] = true quando pode disparar (fora do minuto marcado)
local popup          -- janelinha com Soneca / Parar (criada sob demanda)
local RefreshWindow  -- definida mais abaixo

local function PlayAlarmSound()
    -- Som do próprio jogo; clientes modernos usam IDs (SOUNDKIT), os antigos usam nomes.
    if SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    elseif PlaySound then
        PlaySound("RaidWarning", "Master")
    end
end

local function Alert(alarm)
    pcall(PlayAlarmSound)
    -- Mensagem só na SUA janela de chat (AddMessage local): nada é enviado a ninguém.
    Print(string.format("%s |cffff6600%s|r %s %s", ICON, T("al_ringing"), Describe(alarm), T("al_chat_hint")))
end

local function CreatePopup()
    local frame = CreateFrame("Frame", "FarolAlarmPopup", UIParent, ns.backdropTemplate)
    frame:SetSize(320, 96)
    frame:SetPoint("TOP", 0, -140)
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
    frame.title:SetPoint("TOP", 0, -16)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("TOP", frame.title, "BOTTOM", 0, -6)

    frame.snooze = CreateFrame("Button", "FarolAlarmSnooze", frame, "UIPanelButtonTemplate")
    frame.snooze:SetSize(130, 22)
    frame.snooze:SetPoint("BOTTOMLEFT", 20, 16)
    frame.snooze:SetScript("OnClick", function() Alarm.Snooze() end) -- usa o tempo configurado

    frame.stop = CreateFrame("Button", "FarolAlarmStop", frame, "UIPanelButtonTemplate")
    frame.stop:SetSize(130, 22)
    frame.stop:SetPoint("BOTTOMRIGHT", -20, 16)
    frame.stop:SetScript("OnClick", function() Alarm.Stop() end)

    frame:Hide()
    return frame
end

local function UpdatePopup()
    local active = {}
    for _, entry in ipairs(ringing) do
        if not entry.snoozed then active[#active + 1] = entry end
    end
    if #active == 0 then
        if popup then popup:Hide() end
        return
    end
    popup = popup or CreatePopup()
    popup.title:SetText(ICON .. " " .. T("al_ringing"))
    local text = Describe(active[1].alarm)
    if #active > 1 then text = text .. "  " .. string.format(T("al_more"), #active - 1) end
    popup.text:SetText(text)
    popup.snooze:SetText(string.format(T("al_snooze_btn"), SnoozeMinutes()))
    popup.stop:SetText(T("al_stop_btn"))
    popup:Show()
end

local function StartRinging(alarm)
    for _, entry in ipairs(ringing) do
        if entry.alarm == alarm then return end -- já está tocando
    end
    ringing[#ringing + 1] = { alarm = alarm, nextAt = 0, snoozed = false }
end

local function StopAlarm(alarm)
    for i = #ringing, 1, -1 do
        if ringing[i].alarm == alarm then table.remove(ringing, i) end
    end
    UpdatePopup()
end

local function SetSnoozeMinutes(value)
    local minutes = ValidSnooze(value)
    if not minutes then Print(T("al_bad_snooze")) return false end
    DB().snoozeMinutes = minutes
    Print(string.format(T("al_snooze_set"), minutes))
    UpdatePopup()
    if RefreshWindow then RefreshWindow() end
    return true
end

-- minutes: opcional, adia só desta vez por esse tempo; sem ele, usa o tempo configurado.
function Alarm.Snooze(minutes)
    if #ringing == 0 then Print(T("al_none_ringing")) return end
    if minutes ~= nil and minutes ~= "" then
        minutes = ValidSnooze(string.match(tostring(minutes), "^%s*(%d+)"))
        if not minutes then Print(T("al_bad_snooze")) return end
    else
        minutes = SnoozeMinutes()
    end
    local seconds = minutes * 60
    local nextAt = GetTime() + seconds
    for _, entry in ipairs(ringing) do
        entry.nextAt = nextAt
        entry.snoozed = true
    end
    UpdatePopup()
    Print(string.format(T("al_snoozed"), FormatClock(time() + seconds)))
end

function Alarm.Stop()
    if #ringing == 0 then Print(T("al_none_ringing")) return end
    wipe(ringing)
    UpdatePopup()
    Print(T("al_stopped"))
end

-- Verifica os alarmes uma vez por segundo, num frame próprio (funciona com o painel escondido).
local driver = CreateFrame("Frame")
local sinceCheck = 0
driver:SetScript("OnUpdate", function(_, elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 1 then return end
    sinceCheck = 0
    local db = DB()
    if not db or not db.alarms then return end

    for _, alarm in ipairs(db.alarms) do
        if alarm.enabled then
            local ok, hour, minute = pcall(NowHM, alarm.server)
            if ok and hour then
                local isTime = (hour == alarm.h and minute == alarm.m)
                if armed[alarm] == nil then
                    armed[alarm] = not isTime -- ao carregar dentro do minuto, não dispara
                elseif isTime and armed[alarm] then
                    armed[alarm] = false
                    StartRinging(alarm)
                elseif not isTime then
                    armed[alarm] = true -- pronto para o próximo dia
                end
            end
        end
    end

    local now = GetTime()
    local changed = false
    for _, entry in ipairs(ringing) do
        if now >= entry.nextAt then
            entry.nextAt = now + REPEAT_SECONDS
            if entry.snoozed then entry.snoozed = false end
            changed = true
            Alert(entry.alarm)
        end
    end
    if changed then UpdatePopup() end
end)

---------------------------------------------------------------------------
-- Criar / remover / ativar (usados pela janela e pelos comandos)
---------------------------------------------------------------------------

local function AddAlarm(hour, minute, server, label)
    local db = DB()
    if #db.alarms >= MAX_ALARMS then Print(T("al_full")) return false end
    if not ValidTime(hour, minute) then Print(T("al_bad_time")) return false end
    local alarm = { h = hour, m = minute, server = server == true, enabled = true, label = CleanLabel(label) }
    db.alarms[#db.alarms + 1] = alarm
    armed[alarm] = nil
    Print(string.format(T("al_added"), Describe(alarm)))
    if RefreshWindow then RefreshWindow() end
    return true
end

local function GetAlarm(index)
    local db = DB()
    index = tonumber(index)
    if not index or not db.alarms[index] then Print(T("al_bad_index")) return nil end
    return db.alarms[index], index
end

local function RemoveAlarm(index)
    local alarm, i = GetAlarm(index)
    if not alarm then return end
    StopAlarm(alarm)
    table.remove(DB().alarms, i)
    armed[alarm] = nil
    Print(string.format(T("al_removed"), Describe(alarm)))
    if RefreshWindow then RefreshWindow() end
end

local function SetEnabled(index, enabled)
    local alarm = GetAlarm(index)
    if not alarm then return end
    alarm.enabled = enabled
    armed[alarm] = nil
    if not enabled then StopAlarm(alarm) end
    Print(string.format(enabled and T("al_on") or T("al_off"), Describe(alarm)))
    if RefreshWindow then RefreshWindow() end
end

local function ListAlarms()
    local db = DB()
    if #db.alarms == 0 then Print(T("al_list_empty")) return end
    Print(T("al_list_title"))
    for i, alarm in ipairs(db.alarms) do
        local state = alarm.enabled and "|cff00ff00ON|r" or "|cffff3333OFF|r"
        Print(string.format("  %d. %s  %s", i, Describe(alarm), state))
    end
end

---------------------------------------------------------------------------
-- Janela de alarmes
---------------------------------------------------------------------------

local window

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolAlarms", UIParent, ns.backdropTemplate)
    frame:SetSize(380, 470)
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
    frame.hint:SetPoint("TOPLEFT", 20, -46)
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("TOPLEFT", 24, -72)

    -- Linhas da lista (uma por alarme).
    frame.rows = {}
    for i = 1, MAX_ALARMS do
        local y = -66 - (i - 1) * 26
        local row = {}
        row.check = CreateFrame("CheckButton", "FarolAlarmCheck" .. i, frame, "UICheckButtonTemplate")
        row.check:SetSize(24, 24)
        row.check:SetPoint("TOPLEFT", 20, y)
        row.check:SetScript("OnClick", function(self)
            SetEnabled(i, self:GetChecked() and true or false)
        end)
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
        row.delete = CreateFrame("Button", "FarolAlarmDelete" .. i, frame, "UIPanelButtonTemplate")
        row.delete:SetSize(26, 22)
        row.delete:SetPoint("TOPRIGHT", -24, y - 1)
        row.delete:SetText("X")
        row.delete:SetScript("OnClick", function() RemoveAlarm(i) end)
        frame.rows[i] = row
    end

    -- Área "Novo alarme".
    local addY = -66 - MAX_ALARMS * 26 - 12
    frame.newHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.newHeader:SetPoint("TOPLEFT", 20, addY)

    local function NumberBox(name, x)
        local box = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
        box:SetSize(28, 20)
        box:SetPoint("TOPLEFT", x, addY - 22)
        box:SetAutoFocus(false)
        box:SetNumeric(true)
        box:SetMaxLetters(2)
        box:SetScript("OnEscapePressed", box.ClearFocus)
        return box
    end
    frame.hour = NumberBox("FarolAlarmHour", 26)
    local colon = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    colon:SetPoint("LEFT", frame.hour, "RIGHT", 4, 0)
    colon:SetText(":")
    frame.minute = NumberBox("FarolAlarmMinute", 70)

    frame.server = false
    frame.mode = CreateFrame("Button", "FarolAlarmMode", frame, "UIPanelButtonTemplate")
    frame.mode:SetSize(84, 22)
    frame.mode:SetPoint("TOPLEFT", 108, addY - 21)
    frame.mode:SetScript("OnClick", function()
        frame.server = not frame.server
        RefreshWindow()
    end)

    frame.label = CreateFrame("EditBox", "FarolAlarmLabel", frame, "InputBoxTemplate")
    frame.label:SetSize(150, 20)
    frame.label:SetPoint("TOPLEFT", 204, addY - 22)
    frame.label:SetAutoFocus(false)
    frame.label:SetMaxLetters(60)
    frame.label:SetScript("OnEscapePressed", frame.label.ClearFocus)
    frame.labelHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.labelHint:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -2)

    local function Submit()
        local hour, minute = tonumber(frame.hour:GetText()), tonumber(frame.minute:GetText())
        if AddAlarm(hour, minute, frame.server, frame.label:GetText()) then
            frame.hour:SetText("")
            frame.minute:SetText("")
            frame.label:SetText("")
        end
        frame.hour:ClearFocus(); frame.minute:ClearFocus(); frame.label:ClearFocus()
    end
    frame.hour:SetScript("OnEnterPressed", Submit)
    frame.minute:SetScript("OnEnterPressed", Submit)
    frame.label:SetScript("OnEnterPressed", Submit)

    frame.add = CreateFrame("Button", "FarolAlarmAdd", frame, "UIPanelButtonTemplate")
    frame.add:SetSize(120, 22)
    frame.add:SetPoint("TOPLEFT", 20, addY - 62)
    frame.add:SetScript("OnClick", Submit)

    frame.test = CreateFrame("Button", "FarolAlarmTest", frame, "UIPanelButtonTemplate")
    frame.test:SetSize(120, 22)
    frame.test:SetPoint("TOPLEFT", 150, addY - 62)
    frame.test:SetScript("OnClick", function() pcall(PlayAlarmSound) end)

    -- Tempo da soneca (minutos).
    frame.snoozeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.snoozeLabel:SetPoint("TOPLEFT", 20, addY - 100)
    frame.snoozeBox = CreateFrame("EditBox", "FarolAlarmSnoozeMinutes", frame, "InputBoxTemplate")
    frame.snoozeBox:SetSize(28, 20)
    frame.snoozeBox:SetPoint("LEFT", frame.snoozeLabel, "RIGHT", 10, 0)
    frame.snoozeBox:SetAutoFocus(false)
    frame.snoozeBox:SetNumeric(true)
    frame.snoozeBox:SetMaxLetters(2)
    local function SaveSnooze(box)
        if not SetSnoozeMinutes(box:GetText()) then RefreshWindow() end -- inválido: volta ao valor salvo
        box:ClearFocus()
    end
    frame.snoozeBox:SetScript("OnEnterPressed", SaveSnooze)
    frame.snoozeBox:SetScript("OnEscapePressed", function(box) RefreshWindow(); box:ClearFocus() end)
    frame.snoozeUnit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.snoozeUnit:SetPoint("LEFT", frame.snoozeBox, "RIGHT", 6, 0)

    frame:SetHeight(-(addY - 100) + 40)
    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolAlarms") -- ESC fecha
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local db = DB()
    window.title:SetText(T("al_title"))
    window.hint:SetText(T("al_hint"))
    window.empty:SetText(T("al_empty"))
    if #db.alarms == 0 then window.empty:Show() else window.empty:Hide() end
    for i, row in ipairs(window.rows) do
        local alarm = db.alarms[i]
        if alarm then
            row.check:SetChecked(alarm.enabled)
            row.text:SetText(string.format("%d. %s", i, Describe(alarm)))
            row.check:Show(); row.text:Show(); row.delete:Show()
        else
            row.check:Hide(); row.text:Hide(); row.delete:Hide()
        end
    end
    window.newHeader:SetText(T("al_new"))
    window.mode:SetText(window.server and T("al_server") or T("al_local"))
    window.labelHint:SetText(T("al_label_ph"))
    window.add:SetText(T("al_add"))
    window.test:SetText(T("al_test"))
    window.snoozeLabel:SetText(T("al_snooze_label"))
    window.snoozeUnit:SetText(T("al_snooze_unit") .. "  (1-60, Enter)")
    if not window.snoozeBox:HasFocus() then window.snoozeBox:SetText(tostring(SnoozeMinutes())) end
end

function Alarm.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Alarm.Refresh()
    RefreshWindow()
    UpdatePopup()
end

---------------------------------------------------------------------------
-- Comandos: /farol alarme ...
---------------------------------------------------------------------------

local SUB = {
    add = "add", adicionar = "add", novo = "add", new = "add",
    list = "list", lista = "list", listar = "list",
    remove = "remove", remover = "remove", apagar = "remove", del = "remove", delete = "remove",
    on = "on", ativar = "on", enable = "on",
    off = "off", desativar = "off", disable = "off",
    soneca = "snooze", snooze = "snooze",
}
local SERVER_WORDS = { servidor = true, server = true, jogo = true, game = true, s = true }
local LOCAL_WORDS = { ["local"] = true, l = true }

function Alarm.HandleCommand(rest)
    local word, args = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    local sub = SUB[string.lower(word or "")]

    if not sub then
        Alarm.ToggleWindow()
    elseif sub == "add" then
        local timeText, after = string.match(args, "^(%S+)%s*(.-)$")
        local hour, minute = ParseTime(timeText)
        if not hour then Print(T("al_bad_time")) return end
        local server = DB().serverTime == true
        local modeWord, label = string.match(after or "", "^(%a+)%s*(.-)$")
        if modeWord and SERVER_WORDS[string.lower(modeWord)] then
            server = true
        elseif modeWord and LOCAL_WORDS[string.lower(modeWord)] then
            server = false
        else
            label = after
        end
        AddAlarm(hour, minute, server, label)
    elseif sub == "list" then
        ListAlarms()
    elseif sub == "remove" then
        RemoveAlarm(string.match(args, "^(%d+)"))
    elseif sub == "on" then
        SetEnabled(string.match(args, "^(%d+)"), true)
    elseif sub == "off" then
        SetEnabled(string.match(args, "^(%d+)"), false)
    elseif sub == "snooze" then
        SetSnoozeMinutes(string.match(args, "^(%d+)"))
    end
end
