--[[
  Farol — Ordem dos itens na barra / Bar item order

  Janela com a lista dos itens e setas [▲] [▼] para mudar a posição de cada um.
  A barra se reorganiza na hora (também no modo vertical). A ordem fica salva em FarolDB.order
  e é validada ao carregar: cada item aparece exatamente uma vez.
]]

local _, ns = ...

local ROW_HEIGHT = 22

local Order = {}
ns.Order = Order

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        order_title   = "Ordem da barra",
        order_hint    = "Use as setas para mudar a posição de cada informação.",
        order_hidden  = "(escondido)",
        order_reset   = "Restaurar ordem padrão",
        order_restored = "ordem da barra restaurada ao padrão.",
        order_usage   = "uso: /farol ordem (abre a janela) || /farol ordem padrao",
        opt_order     = "Ordem...",
        help_order    = "  /farol ordem         - escolher a ordem das informações na barra",
    },
    en = {
        order_title   = "Bar order",
        order_hint    = "Use the arrows to change the position of each item.",
        order_hidden  = "(hidden)",
        order_reset   = "Restore default order",
        order_restored = "bar order restored to default.",
        order_usage   = "usage: /farol order (opens the window) || /farol order default",
        opt_order     = "Order...",
        help_order    = "  /farol order         - choose the order of the items on the bar",
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

---------------------------------------------------------------------------
-- Validação: cada item conhecido exatamente uma vez, na ordem salva;
-- itens que faltam (ex.: itens novos de uma versão futura) entram no fim.
---------------------------------------------------------------------------

function Order.Sanitize(saved)
    local known, used, clean = {}, {}, {}
    for _, key in ipairs(ns.ITEM_ORDER) do known[key] = true end
    if type(saved) == "table" then
        for _, key in ipairs(saved) do
            if known[key] and not used[key] then
                clean[#clean + 1] = key
                used[key] = true
            end
        end
    end
    for _, key in ipairs(ns.ITEM_ORDER) do
        if not used[key] then clean[#clean + 1] = key end
    end
    return clean
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

-- Move o item da posição "index" uma casa para cima (-1) ou para baixo (+1).
local function Move(index, direction)
    local order = DB().order
    local target = index + direction
    if target < 1 or target > #order then return end
    order[index], order[target] = order[target], order[index]
    ns.UpdateText()
    RefreshWindow()
end

local function RestoreDefault()
    local order = DB().order
    for i = #order, 1, -1 do order[i] = nil end
    for i, key in ipairs(ns.ITEM_ORDER) do order[i] = key end
    ns.UpdateText()
    RefreshWindow()
    Print(T("order_restored"))
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window

local function ArrowButton(parent, name, up)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(22, 22)
    local base = up and "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp" or "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown"
    button:SetNormalTexture(base .. "-Up")
    button:SetPushedTexture(base .. "-Down")
    button:SetDisabledTexture(base .. "-Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return button
end

local function CreateWindow()
    local count = #ns.ITEM_ORDER
    local frame = CreateFrame("Frame", "FarolOrder", UIParent, ns.backdropTemplate)
    frame:SetSize(360, 112 + count * ROW_HEIGHT)
    frame:SetPoint("CENTER", 60, 0)
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

    frame.rows = {}
    for i = 1, count do
        local y = -64 - (i - 1) * ROW_HEIGHT
        local row = {}
        row.number = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.number:SetPoint("TOPLEFT", 22, y - 4)
        row.number:SetWidth(22)
        row.number:SetJustifyH("RIGHT")
        row.icon = frame:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("TOPLEFT", 50, y - 2)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("TOPLEFT", 72, y - 3)
        row.up = ArrowButton(frame, "FarolOrderUp" .. i, true)
        row.up:SetPoint("TOPRIGHT", -50, y + 1)
        row.up:SetScript("OnClick", function() Move(i, -1) end)
        row.down = ArrowButton(frame, "FarolOrderDown" .. i, false)
        row.down:SetPoint("TOPRIGHT", -24, y + 1)
        row.down:SetScript("OnClick", function() Move(i, 1) end)
        frame.rows[i] = row
    end

    frame.reset = CreateFrame("Button", "FarolOrderReset", frame, "UIPanelButtonTemplate")
    frame.reset:SetSize(190, 22)
    frame.reset:SetPoint("BOTTOMRIGHT", -24, 18)
    frame.reset:SetScript("OnClick", RestoreDefault)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolOrder") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local db = DB()
    window.title:SetText(T("order_title"))
    window.hint:SetText(T("order_hint"))
    window.reset:SetText(T("order_reset"))
    for i, row in ipairs(window.rows) do
        local key = db.order[i]
        row.number:SetText(i .. ".")
        row.icon:SetTexture("Interface\\Icons\\" .. (ns.ITEM_ICONS[key] or "INV_Misc_QuestionMark"))
        local name = T("name_" .. key)
        if db.items[key] then
            row.text:SetText(name)
            row.text:SetTextColor(1, 1, 1)
        else
            row.text:SetText(name .. " " .. T("order_hidden"))
            row.text:SetTextColor(0.5, 0.5, 0.5)
        end
        if i == 1 then row.up:Disable() else row.up:Enable() end
        if i == #window.rows then row.down:Disable() else row.down:Enable() end
    end
end

function Order.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Order.Refresh()
    RefreshWindow()
end

function Order.HandleCommand(rest)
    local word = string.lower(string.match(rest or "", "^%s*(%a*)") or "")
    if word == "" then
        Order.ToggleWindow()
    elseif word == "padrao" or word == "default" or word == "reset" then
        RestoreDefault()
    else
        Print(T("order_usage"))
    end
end
