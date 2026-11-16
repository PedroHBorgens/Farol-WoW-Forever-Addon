--[[
  Farol — Botão no minimapa e entrada na lista de addons do jogo / Minimap button and addon compartment entry

  Botão próprio (sem bibliotecas) na borda do minimapa do jogo: clique esquerdo abre o menu, direito mostra/esconde
  todas as barras (só nesta sessão), Shift + clique abre os avisos; arrastar move o botão em volta do minimapa.
  Nos clientes que têm a lista de addons ao lado do minimapa (AddonCompartment), o .toc aponta para
  Farol_OnAddonCompartmentClick/Enter/Leave, que fazem o mesmo. Nenhuma comunicação com outros addons.
  FarolDB.minimap = { show = true, locked = false, angle = 0..360 }, validado ao carregar.
]]

local _, ns = ...

local DEFAULT_ANGLE = 220
local RADIUS_PAD = 10 -- distância além da borda do minimapa

local MinimapButton = {}
ns.MinimapButton = MinimapButton

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        mm_left       = "Clique: abrir o menu",
        mm_right      = "Clique direito: mostrar/esconder as barras",
        mm_shift      = "Shift + clique: avisos",
        mm_drag       = "Arraste para mover em volta do minimapa",
        mm_locked     = "Posição travada (aba Geral)",
        mm_bars_hidden = "barras escondidas até você mostrar de novo (clique direito no botão do minimapa ou /farol).",
        mm_bars_shown = "barras mostradas de novo.",
        opt_minimap   = "Mostrar botão no minimapa",
        opt_minimap_lock = "Travar posição do botão do minimapa",
        mm_on         = "botão do minimapa: mostrado.",
        mm_off        = "botão do minimapa: escondido (use /farol menu para abrir as opções).",
        mm_lock_on    = "botão do minimapa: travado.",
        mm_lock_off   = "botão do minimapa: destravado (arraste para mover).",
        mm_usage      = "uso: /farol minimapa on||off || /farol minimapa travar||destravar",
        help_minimap  = "  /farol minimapa      - mostrar/esconder ou travar o botão do Farol no minimapa",
        news_minimap  = "botão no minimapa (clique: menu; clique direito: mostrar/esconder as barras)",
    },
    en = {
        mm_left       = "Click: open the menu",
        mm_right      = "Right-click: show/hide the bars",
        mm_shift      = "Shift-click: warnings",
        mm_drag       = "Drag to move it around the minimap",
        mm_locked     = "Position locked (General tab)",
        mm_bars_hidden = "bars hidden until you show them again (right-click the minimap button or /farol).",
        mm_bars_shown = "bars shown again.",
        opt_minimap   = "Show the minimap button",
        opt_minimap_lock = "Lock the minimap button position",
        mm_on         = "minimap button: shown.",
        mm_off        = "minimap button: hidden (use /farol menu to open the options).",
        mm_lock_on    = "minimap button: locked.",
        mm_lock_off   = "minimap button: unlocked (drag to move).",
        mm_usage      = "usage: /farol minimap on||off || /farol minimap lock||unlock",
        help_minimap  = "  /farol minimap       - show/hide or lock Farol's minimap button",
        news_minimap  = "minimap button (click: menu; right-click: show/hide the bars)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Settings()
    local db = ns.GetDB()
    return db and db.minimap
end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

function MinimapButton.Sanitize(saved)
    if type(saved) ~= "table" then saved = {} end
    local angle = saved.angle
    if type(angle) ~= "number" or angle ~= angle or angle < 0 or angle > 360 then angle = DEFAULT_ANGLE end
    return {
        show = saved.show ~= false and true or false, -- padrão: mostrado
        locked = saved.locked == true,
        angle = angle,
    }
end

---------------------------------------------------------------------------
-- Ações (botão do minimapa e lista de addons do jogo)
---------------------------------------------------------------------------

local function Shift()
    if not IsShiftKeyDown then return false end
    local ok, value = pcall(IsShiftKeyDown)
    return ok and value and true or false
end

function MinimapButton.Click(button)
    if not ns.GetDB() then return end
    if Shift() then
        if ns.OpenOptions then ns.OpenOptions("warnings") end
    elseif button == "RightButton" then
        local hidden = ns.SetAllBarsHidden and ns.SetAllBarsHidden(not ns.AllBarsHidden())
        Print(hidden and T("mm_bars_hidden") or T("mm_bars_shown"))
    else
        if ns.OpenOptions then ns.OpenOptions("bar") end
    end
end

local function FillTooltip(locked)
    GameTooltip:AddLine("Farol", 0.2, 0.8, 1)
    GameTooltip:AddLine(T("mm_left"), 1, 1, 1)
    GameTooltip:AddLine(T("mm_right"), 1, 1, 1)
    GameTooltip:AddLine(T("mm_shift"), 1, 1, 1)
    if locked ~= nil then GameTooltip:AddLine(locked and T("mm_locked") or T("mm_drag"), 0.6, 0.6, 0.6) end
end

-- Lista de addons do jogo (AddonCompartment): os nomes ficam no .toc. Globais com o prefixo do projeto.
Farol_OnAddonCompartmentClick = function(_, mouseButton) MinimapButton.Click(mouseButton) end
Farol_OnAddonCompartmentEnter = function(_, frame)
    if not GameTooltip or not frame then return end
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    FillTooltip(nil)
    GameTooltip:Show()
end
Farol_OnAddonCompartmentLeave = function() if GameTooltip then GameTooltip:Hide() end end

---------------------------------------------------------------------------
-- Botão
---------------------------------------------------------------------------

local button
local atan2 = math.atan2 or math.atan -- Lua 5.4 não tem math.atan2 (math.atan aceita dois números)

local function Radius()
    local ok, w = false, nil
    if Minimap and Minimap.GetWidth then ok, w = pcall(Minimap.GetWidth, Minimap) end -- leitura protegida
    if not ok or type(w) ~= "number" or w ~= w or w <= 0 or w > 2000 then w = 140 end
    return w / 2 + RADIUS_PAD
end

local function Place()
    local settings = Settings()
    if not button or not settings then return end
    local a = math.rad(settings.angle)
    local r = Radius()
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

-- Ângulo do cursor em volta do centro do minimapa (graus, 0 a 360). nil se o jogo não informar.
local function CursorAngle()
    if not GetCursorPosition or not Minimap or not Minimap.GetCenter then return nil end
    local okC, cx, cy = pcall(GetCursorPosition)
    local okM, mx, my = pcall(Minimap.GetCenter, Minimap)
    local okS, scale = pcall(Minimap.GetEffectiveScale, Minimap)
    if not (okC and okM and okS) then return nil end
    for _, v in ipairs({ cx, cy, mx, my, scale }) do
        if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
    end
    if scale <= 0 then return nil end
    local angle = math.deg(atan2(cy / scale - my, cx / scale - mx)) % 360
    if angle ~= angle then return nil end
    return angle
end

local function Create()
    if button or not Minimap then return button end
    button = CreateFrame("Button", "FarolMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER", 0, 1)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\Farol\\Media\\Farol") -- ícone próprio do Farol
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", 0, 1)
    button.icon = icon
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouse) MinimapButton.Click(mouse) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local settings = Settings()
        FillTooltip(settings and settings.locked or false)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        local settings = Settings()
        if not settings or settings.locked then return end
        self:SetScript("OnUpdate", function()
            local angle = CursorAngle()
            if angle then settings.angle = angle; Place() end
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    return button
end

function MinimapButton.Apply()
    local settings = Settings()
    if not settings then return end
    if settings.show then
        Create()
        if button then Place(); button:Show() end
    elseif button then
        button:Hide()
    end
end

function MinimapButton.SetShown(value)
    local settings = Settings()
    if not settings then return end
    settings.show = value and true or false
    MinimapButton.Apply()
    Print(value and T("mm_on") or T("mm_off"))
    if ns.RefreshOptions then ns.RefreshOptions() end
end

function MinimapButton.SetLocked(value)
    local settings = Settings()
    if not settings then return end
    settings.locked = value and true or false
    Print(value and T("mm_lock_on") or T("mm_lock_off"))
    if ns.RefreshOptions then ns.RefreshOptions() end
end

---------------------------------------------------------------------------
-- Comandos: /farol minimapa ...
---------------------------------------------------------------------------

local WORDS = {
    on = "show", ligar = "show", mostrar = "show", show = "show",
    off = "hide", desligar = "hide", esconder = "hide", hide = "hide",
    travar = "lock", lock = "lock", destravar = "unlock", unlock = "unlock",
}

function MinimapButton.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    local action = WORDS[string.lower(word or "")]
    if tail ~= "" or not action then Print(T("mm_usage")) return end
    if action == "show" or action == "hide" then MinimapButton.SetShown(action == "show")
    else MinimapButton.SetLocked(action == "lock") end
end
