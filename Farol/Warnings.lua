--[[
  Farol — Avisos de durabilidade e bolsas / Durability and bag warnings

  * Durabilidade: avisa quando a peça mais gasta fica abaixo do limite (padrão 20%).
  * Bolsas: avisa quando sobram poucos espaços livres (padrão 2 ou menos) e quando enchem.
  * Avisa UMA vez: só avisa de novo depois que a situação melhora (reparou / liberou espaço)
    e com intervalo mínimo de 5 minutos, para não repetir quando o número oscila.
  * Mensagem no centro da tela e no SEU chat (nada é enviado a ninguém) + som opcional.
]]

local _, ns = ...

local COOLDOWN = 5 * 60
local DURAB_MIN, DURAB_MAX = 5, 50
local BAGS_MIN, BAGS_MAX = 0, 10
local DEFAULTS = { durab = true, durabPct = 20, bags = true, bagSlots = 2, sound = true }

local Warnings = {}
ns.Warnings = Warnings

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        warn_title      = "Avisos",
        warn_durab      = "Durabilidade baixa: %d%% — hora de reparar!",
        warn_bags       = "Bolsas quase cheias: %d espaço(s) livre(s).",
        warn_bags_full  = "Bolsas cheias!",
        warn_opt_durab  = "Avisar quando a durabilidade ficar abaixo de",
        warn_opt_bags   = "Avisar quando sobrarem até",
        warn_unit_pct   = "%",
        warn_unit_slots = "espaços nas bolsas",
        warn_opt_sound  = "Tocar som nos avisos",
        warn_opt_test   = "Testar aviso",
        warn_hint       = "Avisa uma vez; avisa de novo depois que melhorar (mín. 5 min).",
        warn_set_durab  = "aviso de durabilidade: abaixo de %d%%.",
        warn_set_bags   = "aviso de bolsas: até %d espaço(s) livre(s).",
        warn_on         = "aviso ligado: %s",
        warn_off        = "aviso desligado: %s",
        warn_name_durab = "durabilidade",
        warn_name_bags  = "bolsas",
        warn_name_sound = "som",
        warn_bad_durab  = "valor inválido: use de 5 a 50 (%).",
        warn_bad_bags   = "valor inválido: use de 0 a 10 espaços.",
        warn_usage      = "uso: /farol aviso durab N || bolsas N || durab off || bolsas off || som off (ou on)",
        opt_warnings    = "Avisos...",
        help_warn       = "  /farol aviso         - abrir a janela de avisos (durabilidade e bolsas)",
    },
    en = {
        warn_title      = "Warnings",
        warn_durab      = "Low durability: %d%% — time to repair!",
        warn_bags       = "Bags almost full: %d free slot(s).",
        warn_bags_full  = "Bags full!",
        warn_opt_durab  = "Warn when durability drops below",
        warn_opt_bags   = "Warn when only",
        warn_unit_pct   = "%",
        warn_unit_slots = "bag slots or fewer are free",
        warn_opt_sound  = "Play a sound with warnings",
        warn_opt_test   = "Test warning",
        warn_hint       = "Warns once; warns again after it improves (min. 5 min).",
        warn_set_durab  = "durability warning: below %d%%.",
        warn_set_bags   = "bag warning: %d free slot(s) or fewer.",
        warn_on         = "warning on: %s",
        warn_off        = "warning off: %s",
        warn_name_durab = "durability",
        warn_name_bags  = "bags",
        warn_name_sound = "sound",
        warn_bad_durab  = "invalid value: use 5 to 50 (%).",
        warn_bad_bags   = "invalid value: use 0 to 10 slots.",
        warn_usage      = "usage: /farol warn durab N || bags N || durab off || bags off || sound off (or on)",
        opt_warnings    = "Warnings...",
        help_warn       = "  /farol warn          - open the warnings window (durability and bags)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Settings() return ns.GetDB().warnings end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

local function InRange(value, low, high)
    value = tonumber(value)
    if value and value == math.floor(value) and value >= low and value <= high then return value end
    return nil
end

function Warnings.Sanitize(saved)
    local clean = {}
    if type(saved) ~= "table" then saved = {} end
    for _, key in ipairs({ "durab", "bags", "sound" }) do
        if type(saved[key]) == "boolean" then clean[key] = saved[key] else clean[key] = DEFAULTS[key] end
    end
    clean.durabPct = InRange(saved.durabPct, DURAB_MIN, DURAB_MAX) or DEFAULTS.durabPct
    clean.bagSlots = InRange(saved.bagSlots, BAGS_MIN, BAGS_MAX) or DEFAULTS.bagSlots
    return clean
end

---------------------------------------------------------------------------
-- Disparo
---------------------------------------------------------------------------

-- Estado de cada aviso: armed = pode avisar; lastAt = quando avisou (GetTime).
local state = {
    durab = { armed = true, lastAt = nil },
    bags = { armed = true, lastAt = nil, full = false },
}

local function PlayWarningSound()
    -- Som da "checagem de prontidão": diferente do som do alarme.
    if SOUNDKIT and SOUNDKIT.READY_CHECK then
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
    elseif PlaySound then
        PlaySound("ReadyCheck", "Master")
    end
end

local function Announce(text)
    -- Só no SEU cliente: centro da tela + sua janela de chat. Nada é enviado.
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.6, 0)
    end
    Print("|cffff9900" .. text .. "|r")
    if Settings().sound then pcall(PlayWarningSound) end
end

local function CanFire(entry, now)
    return entry.armed and (entry.lastAt == nil or now - entry.lastAt >= COOLDOWN)
end

local function Fire(entry, now, text)
    entry.armed = false
    entry.lastAt = now
    Announce(text)
end

local function CheckDurability(now)
    local settings = Settings()
    local lowest = ns.GetLowestDurability()
    if not settings.durab or type(lowest) ~= "number" or ns.IsSecret(lowest) then return end
    if lowest < settings.durabPct then
        if CanFire(state.durab, now) then
            Fire(state.durab, now, string.format(T("warn_durab"), math.floor(lowest)))
        end
    else
        state.durab.armed = true -- reparou: pode avisar de novo
    end
end

local function CheckBags(now)
    local settings = Settings()
    if not settings.bags then return end
    local free = ns.GetBagSpace()
    if type(free) ~= "number" or ns.IsSecret(free) then return end
    local entry = state.bags
    if free == 0 and not entry.full then
        -- Encheu de vez: avisa mesmo que já tenha avisado "quase cheias" há pouco.
        entry.full = true
        entry.armed = false
        entry.lastAt = now
        Announce(T("warn_bags_full"))
    elseif free <= settings.bagSlots then
        if free > 0 then entry.full = false end
        if CanFire(entry, now) then
            Fire(entry, now, string.format(T("warn_bags"), free))
        end
    else
        entry.armed = true
        entry.full = false
    end
end

-- Verifica uma vez por segundo, num frame próprio (funciona com o painel escondido).
local driver = CreateFrame("Frame")
local sinceCheck = 0
driver:SetScript("OnUpdate", function(_, elapsed)
    sinceCheck = sinceCheck + elapsed
    if sinceCheck < 1 then return end
    sinceCheck = 0
    if not ns.GetDB() or not Settings() then return end
    local now = GetTime()
    pcall(CheckDurability, now)
    pcall(CheckBags, now)
end)

---------------------------------------------------------------------------
-- Ajustes (usados pela janela e pelos comandos)
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function SetEnabled(key, value)
    Settings()[key] = value
    if state[key] then state[key].armed = true end
    Print(string.format(value and T("warn_on") or T("warn_off"), T("warn_name_" .. key)))
    if RefreshWindow then RefreshWindow() end
end

local function SetDurabPct(value)
    local pct = InRange(value, DURAB_MIN, DURAB_MAX)
    if not pct then Print(T("warn_bad_durab")) return false end
    Settings().durabPct = pct
    state.durab.armed = true
    Print(string.format(T("warn_set_durab"), pct))
    if RefreshWindow then RefreshWindow() end
    return true
end

local function SetBagSlots(value)
    local slots = InRange(value, BAGS_MIN, BAGS_MAX)
    if not slots then Print(T("warn_bad_bags")) return false end
    Settings().bagSlots = slots
    state.bags.armed = true
    Print(string.format(T("warn_set_bags"), slots))
    if RefreshWindow then RefreshWindow() end
    return true
end

---------------------------------------------------------------------------
-- Janela de avisos
---------------------------------------------------------------------------

local window

local function NumberBox(frame, name, anchor, onSave)
    local box = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
    box:SetSize(28, 20)
    box:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(2)
    box:SetScript("OnEnterPressed", function(self)
        if not onSave(self:GetText()) then RefreshWindow() end -- inválido: volta ao valor salvo
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) RefreshWindow(); self:ClearFocus() end)
    return box
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolWarnings", UIParent, ns.backdropTemplate)
    frame:SetSize(470, 196)
    frame:SetPoint("CENTER", 0, 60)
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

    local function Check(name, y, key)
        local check = CreateFrame("CheckButton", name, frame, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 20, y)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check:SetScript("OnClick", function(self) SetEnabled(key, self:GetChecked() and true or false) end)
        return check
    end

    frame.durab = Check("FarolWarnDurab", -50, "durab")
    frame.durabBox = NumberBox(frame, "FarolWarnDurabPct", frame.durab.label, SetDurabPct)
    frame.durabUnit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.durabUnit:SetPoint("LEFT", frame.durabBox, "RIGHT", 6, 0)

    frame.bags = Check("FarolWarnBags", -80, "bags")
    frame.bagsBox = NumberBox(frame, "FarolWarnBagSlots", frame.bags.label, SetBagSlots)
    frame.bagsUnit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.bagsUnit:SetPoint("LEFT", frame.bagsBox, "RIGHT", 6, 0)

    frame.sound = Check("FarolWarnSound", -110, "sound")

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("TOPLEFT", 22, -142)

    frame.test = CreateFrame("Button", "FarolWarnTest", frame, "UIPanelButtonTemplate")
    frame.test:SetSize(130, 22)
    frame.test:SetPoint("BOTTOMRIGHT", -24, 18)
    frame.test:SetScript("OnClick", function()
        Announce(string.format(T("warn_durab"), Settings().durabPct - 1))
    end)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolWarnings") -- ESC fecha
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local settings = Settings()
    window.title:SetText(T("warn_title"))
    window.durab.label:SetText(T("warn_opt_durab"))
    window.durab:SetChecked(settings.durab)
    window.durabUnit:SetText(T("warn_unit_pct"))
    window.bags.label:SetText(T("warn_opt_bags"))
    window.bags:SetChecked(settings.bags)
    window.bagsUnit:SetText(T("warn_unit_slots"))
    window.sound.label:SetText(T("warn_opt_sound"))
    window.sound:SetChecked(settings.sound)
    window.hint:SetText(T("warn_hint"))
    window.test:SetText(T("warn_opt_test"))
    if not window.durabBox:HasFocus() then window.durabBox:SetText(tostring(settings.durabPct)) end
    if not window.bagsBox:HasFocus() then window.bagsBox:SetText(tostring(settings.bagSlots)) end
end

function Warnings.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Warnings.Refresh()
    RefreshWindow()
end

---------------------------------------------------------------------------
-- Comandos: /farol aviso ...
---------------------------------------------------------------------------

local KEYS = {
    durab = "durab", dur = "durab", durabilidade = "durab", durability = "durab",
    bolsas = "bags", bolsa = "bags", bags = "bags", bag = "bags",
    som = "sound", sound = "sound",
}
local ON = { on = true, ligar = true, ativar = true, sim = true }
local OFF = { off = true, desligar = true, desativar = true, nao = true }

function Warnings.HandleCommand(rest)
    local word, value = string.match(rest or "", "^%s*(%a*)%s*(%w*)")
    word, value = string.lower(word or ""), string.lower(value or "")
    local key = KEYS[word]
    if word == "" then
        Warnings.ToggleWindow()
    elseif not key then
        Print(T("warn_usage"))
    elseif ON[value] then
        SetEnabled(key, true)
    elseif OFF[value] then
        SetEnabled(key, false)
    elseif key == "durab" and value ~= "" then
        SetDurabPct(value)
    elseif key == "bags" and value ~= "" then
        SetBagSlots(value)
    else
        Print(T("warn_usage"))
    end
end
