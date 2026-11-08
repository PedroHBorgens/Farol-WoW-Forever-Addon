--[[
  Farol — Aparência da barra / Bar appearance

  Escala (50% a 200%), opacidade do fundo (0% a 100%), borda, barra vertical,
  esconder em combate e esconder em masmorras/raides/arenas.
  Usa botões [-] e [+] em vez de barra deslizante (o modelo de slider mudou entre versões do jogo).
]]

local _, ns = ...

local SCALE_MIN, SCALE_MAX, SCALE_STEP = 50, 200, 10  -- em %
local BG_MIN, BG_MAX, BG_STEP = 0, 100, 10            -- em %
local FONT_MIN, FONT_MAX, FONT_STEP = 8, 24, 1
local ICON_MIN, ICON_MAX, ICON_STEP = 10, 32, 2
local FONT_DEFAULT, ICON_DEFAULT = 11, 14

local Appearance = {}
ns.Appearance = Appearance

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        app_title     = "Aparência",
        app_scale     = "Escala:",
        app_bg        = "Fundo:",
        app_font      = "Texto:",
        app_icon      = "Ícones:",
        app_set_font  = "tamanho do texto: %d.",
        app_set_icon  = "tamanho dos ícones: %d.",
        app_bad_font  = "tamanho de texto inválido: use de 8 a 24.",
        app_bad_icon  = "tamanho de ícone inválido: use de 10 a 32.",
        app_vertical  = "Barra vertical (um item por linha)",
        app_border    = "Mostrar borda",
        app_combat    = "Esconder em combate",
        app_instance  = "Esconder em masmorras, raides, arenas e campos de batalha",
        app_icons     = "Mostrar ícones na barra",
        app_warnbutton = "Mostrar botão do histórico de avisos",
        app_lootbutton = "Mostrar botão de saques",
        app_reset     = "Restaurar padrão",
        app_set_scale = "escala: %d%%.",
        app_set_bg    = "fundo: %d%% de opacidade.",
        app_on        = "ligado: %s",
        app_off       = "desligado: %s",
        app_restored  = "aparência restaurada ao padrão.",
        app_bad_scale = "escala inválida: use de 50 a 200 (%).",
        app_bad_bg    = "fundo inválido: use de 0 a 100 (%).",
        app_usage     = "uso: /farol aparencia escala N || fundo N || texto N || icones N || vertical || borda || icones || botao || botaosaques || combate || instancia || padrao",
        opt_appearance = "Aparência...",
        help_appearance = "  /farol aparencia     - abrir a janela de aparência (escala, fundo, vertical, esconder em combate)",
    },
    en = {
        app_title     = "Appearance",
        app_scale     = "Scale:",
        app_bg        = "Background:",
        app_font      = "Text:",
        app_icon      = "Icons:",
        app_set_font  = "text size: %d.",
        app_set_icon  = "icon size: %d.",
        app_bad_font  = "invalid text size: use 8 to 24.",
        app_bad_icon  = "invalid icon size: use 10 to 32.",
        app_vertical  = "Vertical bar (one item per line)",
        app_border    = "Show border",
        app_combat    = "Hide in combat",
        app_instance  = "Hide in dungeons, raids, arenas and battlegrounds",
        app_icons     = "Show icons on the bar",
        app_warnbutton = "Show the warning history button",
        app_lootbutton = "Show the loot button",
        app_reset     = "Restore defaults",
        app_set_scale = "scale: %d%%.",
        app_set_bg    = "background: %d%% opacity.",
        app_on        = "on: %s",
        app_off       = "off: %s",
        app_restored  = "appearance restored to defaults.",
        app_bad_scale = "invalid scale: use 50 to 200 (%).",
        app_bad_bg    = "invalid background: use 0 to 100 (%).",
        app_usage     = "usage: /farol appearance scale N || bg N || text N || icons N || vertical || border || icons || button || lootbutton || combat || instance || default",
        opt_appearance = "Appearance...",
        help_appearance = "  /farol appearance   - open the appearance window (scale, background, vertical, hide in combat)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function DB() return ns.GetDB() end

-- Opções liga/desliga: chave salva -> texto do menu
local TOGGLES = {
    vertical = "app_vertical",
    border = "app_border",
    hideCombat = "app_combat",
    hideInstance = "app_instance",
    icons = "app_icons",
    warnButton = "app_warnbutton",
    lootButton = "app_lootbutton",
}

---------------------------------------------------------------------------
-- Ajustes
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function Apply()
    ns.ApplyAppearance()
    ns.ApplyVisibility()
    if RefreshWindow then RefreshWindow() end
end

local function Percent(value) return math.floor(value * 100 + 0.5) end

local function SetScalePercent(value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) or value < SCALE_MIN or value > SCALE_MAX then
        Print(T("app_bad_scale"))
        return false
    end
    DB().scale = value / 100
    Apply()
    Print(string.format(T("app_set_scale"), value))
    return true
end

local function SetBgPercent(value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) or value < BG_MIN or value > BG_MAX then
        Print(T("app_bad_bg"))
        return false
    end
    DB().bgAlpha = value / 100
    Apply()
    Print(string.format(T("app_set_bg"), value))
    return true
end

local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end

local function StepScale(direction)
    SetScalePercent(Clamp(Percent(DB().scale) + direction * SCALE_STEP, SCALE_MIN, SCALE_MAX))
end

local function StepBg(direction)
    SetBgPercent(Clamp(Percent(DB().bgAlpha) + direction * BG_STEP, BG_MIN, BG_MAX))
end

local function SetSize(key, value, low, high, okKey, badKey)
    value = tonumber(value)
    if not value or value ~= math.floor(value) or value < low or value > high then
        Print(T(badKey))
        return false
    end
    DB()[key] = value
    Apply()
    Print(string.format(T(okKey), value))
    return true
end

local function SetFontSize(value) return SetSize("fontSize", value, FONT_MIN, FONT_MAX, "app_set_font", "app_bad_font") end
local function SetIconSize(value) return SetSize("iconSize", value, ICON_MIN, ICON_MAX, "app_set_icon", "app_bad_icon") end

local function StepFont(direction)
    SetFontSize(Clamp(DB().fontSize + direction * FONT_STEP, FONT_MIN, FONT_MAX))
end

local function StepIcon(direction)
    SetIconSize(Clamp(DB().iconSize + direction * ICON_STEP, ICON_MIN, ICON_MAX))
end

local function SetToggle(key, value)
    DB()[key] = value
    Apply()
    Print(string.format(value and T("app_on") or T("app_off"), T(TOGGLES[key])))
end

local function RestoreDefaults()
    local db = DB()
    db.scale, db.bgAlpha, db.border = 1, 0.7, true
    db.vertical, db.hideCombat, db.hideInstance = false, false, false
    db.icons, db.warnButton, db.lootButton = true, true, true
    db.fontSize, db.iconSize = FONT_DEFAULT, ICON_DEFAULT
    Apply()
    Print(T("app_restored"))
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window

local function StepperRow(frame, y, name, onStep)
    local row = {}
    row.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("TOPLEFT", 24, y)
    row.down = CreateFrame("Button", name .. "Down", frame, "UIPanelButtonTemplate")
    row.down:SetSize(26, 22)
    row.down:SetPoint("TOPLEFT", 130, y + 4)
    row.down:SetText("-")
    row.down:SetScript("OnClick", function() onStep(-1) end)
    row.value = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.value:SetPoint("LEFT", row.down, "RIGHT", 8, 0)
    row.value:SetWidth(48)
    row.up = CreateFrame("Button", name .. "Up", frame, "UIPanelButtonTemplate")
    row.up:SetSize(26, 22)
    row.up:SetPoint("LEFT", row.value, "RIGHT", 8, 0)
    row.up:SetText("+")
    row.up:SetScript("OnClick", function() onStep(1) end)
    return row
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolAppearance", UIParent, ns.backdropTemplate)
    frame:SetSize(470, 410)
    frame:SetPoint("CENTER", 0, 40)
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

    frame.scale = StepperRow(frame, -54, "FarolAppScale", StepScale)
    frame.bg = StepperRow(frame, -84, "FarolAppBg", StepBg)
    frame.font = StepperRow(frame, -114, "FarolAppFont", StepFont)
    frame.icon = StepperRow(frame, -144, "FarolAppIcon", StepIcon)

    frame.checks = {}
    local y = -170
    for _, key in ipairs({ "icons", "vertical", "border", "warnButton", "lootButton", "hideCombat", "hideInstance" }) do
        local check = CreateFrame("CheckButton", "FarolApp_" .. key, frame, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 20, y)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check:SetScript("OnClick", function(self) SetToggle(key, self:GetChecked() and true or false) end)
        frame.checks[key] = check
        y = y - 26
    end

    frame.reset = CreateFrame("Button", "FarolAppReset", frame, "UIPanelButtonTemplate")
    frame.reset:SetSize(150, 22)
    frame.reset:SetPoint("BOTTOMRIGHT", -24, 18)
    frame.reset:SetScript("OnClick", RestoreDefaults)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolAppearance") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local db = DB()
    window.title:SetText(T("app_title"))
    window.scale.label:SetText(T("app_scale"))
    window.scale.value:SetText(Percent(db.scale) .. "%")
    window.bg.label:SetText(T("app_bg"))
    window.bg.value:SetText(Percent(db.bgAlpha) .. "%")
    window.font.label:SetText(T("app_font"))
    window.font.value:SetText(tostring(db.fontSize))
    window.icon.label:SetText(T("app_icon"))
    window.icon.value:SetText(tostring(db.iconSize))
    for key, check in pairs(window.checks) do
        check.label:SetText(T(TOGGLES[key]))
        check:SetChecked(db[key])
    end
    window.reset:SetText(T("app_reset"))
end

function Appearance.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Appearance.Refresh()
    RefreshWindow()
end

---------------------------------------------------------------------------
-- Comandos: /farol aparencia ...
---------------------------------------------------------------------------

local WORDS = {
    escala = "scale", scale = "scale",
    fundo = "bg", bg = "bg", background = "bg",
    texto = "font", fonte = "font", font = "font", text = "font",
    icone = "iconsize", icon = "iconsize", tamicone = "iconsize", iconsize = "iconsize",
    vertical = "vertical",
    borda = "border", border = "border",
    combate = "hideCombat", combat = "hideCombat",
    instancia = "hideInstance", instance = "hideInstance", masmorra = "hideInstance",
    icones = "icons", icons = "icons",
    botao = "warnButton", button = "warnButton",
    botaosaques = "lootButton", lootbutton = "lootButton",
    padrao = "reset", default = "reset", reset = "reset",
}

function Appearance.HandleCommand(rest)
    local word, value = string.match(rest or "", "^%s*(%a*)%s*(%d*)")
    word = string.lower(word or "")
    local action = WORDS[word]
    if word == "" then
        Appearance.ToggleWindow()
    elseif action == "scale" then
        SetScalePercent(value)
    elseif action == "bg" then
        SetBgPercent(value)
    elseif action == "font" then
        SetFontSize(value)
    elseif action == "iconsize" or (action == "icons" and value ~= "") then
        SetIconSize(value) -- "icones 20" = tamanho; "icones" sozinho = liga/desliga
    elseif action == "reset" then
        RestoreDefaults()
    elseif action then
        SetToggle(action, not DB()[action]) -- liga/desliga
    else
        Print(T("app_usage"))
    end
end
