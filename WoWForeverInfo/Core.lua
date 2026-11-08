--[[
  WoW Forever Info
  Painel na tela com FPS, latência, coordenadas, zona, durabilidade e ouro.
  On-screen panel with FPS, latency, coordinates, zone, durability and gold. (PT / EN)

  Princípios de segurança deste addon:
    * Não usa loadstring/RunScript nem executa código vindo de chat, arquivos ou outros jogadores.
    * Não envia nem recebe mensagens de addon (SendAddonMessage) — nenhum dado sai do seu cliente.
    * Não automatiza ações de jogo (nada de bot); apenas LÊ informações e as mostra.
    * Só grava posição, idioma e itens visíveis em SavedVariables, e valida esses dados ao carregar.
    * Cada leitura de dados é isolada (pcall): se o jogo bloquear algo, aparece "--", nunca um erro.
]]

local ADDON_NAME = ...
local PREFIX = "|cff33ccffWoW Forever Info|r: "
local UPDATE_INTERVAL = 0.5 -- segundos entre atualizações do painel

-- Itens da barra, na ordem em que aparecem.
local ITEM_ORDER = { "fps", "ms", "coords", "zone", "durab", "gold" }

-- Nomes aceitos nos comandos /wfi show|hide (português e inglês).
local ITEM_ALIASES = {
    fps = "fps",
    ms = "ms", ping = "ms", latencia = "ms", latency = "ms",
    coords = "coords", coord = "coords", coordenadas = "coords", coordinates = "coords",
    zona = "zone", zone = "zone",
    durab = "durab", dur = "durab", durabilidade = "durab", durability = "durab",
    ouro = "gold", gold = "gold",
}

local DEFAULTS = {
    shown = true,
    locked = false,
    point = "TOP",
    relPoint = "TOP",
    x = 0,
    y = -20,
    lang = "auto", -- "auto" (segue o idioma do cliente), "pt" ou "en"
}

local VALID_LANGS = { auto = true, pt = true, en = true }

---------------------------------------------------------------------------
-- Textos / Strings (Português e English)
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        help_title   = "comandos:",
        help_toggle  = "  /wfi                 - mostrar/ocultar o painel",
        help_lock    = "  /wfi lock            - travar/destravar o painel (arraste com o botão esquerdo)",
        help_reset   = "  /wfi reset           - voltar o painel à posição padrão",
        help_show    = "  /wfi show <item>     - mostrar um item na barra",
        help_hide    = "  /wfi hide <item>     - esconder um item da barra",
        help_items   = "  /wfi itens           - listar os itens e o que está visível",
        help_version = "  /wfi version         - mostrar a versão do cliente e o número de Interface",
        help_lang    = "  /wfi lang pt|en|auto - escolher o idioma (auto = idioma do cliente)",
        shown        = "painel visível.",
        hidden       = "painel oculto.",
        locked       = "painel travado.",
        unlocked     = "painel destravado — arraste para mover.",
        reset        = "posição restaurada.",
        version      = "cliente %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use esse número na linha '## Interface:' do arquivo .toc.",
        lang_set     = "idioma: Português.",
        lang_auto    = "idioma: automático (segue o cliente).",
        lang_usage   = "uso: /wfi lang pt | en | auto",
        item_usage   = "uso: /wfi show|hide fps | ms | coords | zona | durab | ouro",
        item_on      = "%s: |cff00ff00visível|r",
        item_off     = "%s: |cffff3333escondido|r",
        items_title  = "itens da barra:",
        none_shown   = "WoW Forever Info — /wfi show <item>",
        name_fps     = "FPS",
        name_ms      = "Latência (ms)",
        name_coords  = "Coordenadas (coords)",
        name_zone    = "Zona (zona)",
        name_durab   = "Durabilidade (durab)",
        name_gold    = "Ouro (ouro)",
        label_durab  = "Dur",
        tt_latency   = "Latência",
        tt_lat_value = "local %d ms / mundo %d ms",
        tt_coords    = "Coordenadas",
        tt_zone      = "Zona",
        tt_subzone   = "Subzona",
        tt_durab     = "Durabilidade (menor peça)",
        tt_all_ok    = "Todo o equipamento está 100%.",
        tt_no_gear   = "Nenhum item com durabilidade equipado.",
        tt_gold      = "Ouro",
        tt_drag      = "Arraste para mover.",
        tt_locked    = "Painel travado (/wfi lock).",
        tt_help      = "/wfi ajuda — lista de comandos",
        tt_slot      = "Espaço %d",
        help_menu    = "  /wfi menu            - abrir o menu de opções (ou clique direito no painel)",
        opt_items    = "Itens da barra",
        opt_general  = "Geral",
        opt_shown    = "Mostrar painel",
        opt_locked   = "Travar posição",
        opt_lang     = "Idioma",
        opt_reset    = "Resetar posição",
        opt_hint     = "Marque o que deseja ver na barra.",
        tt_rightclick = "Clique direito: opções.",
    },
    en = {
        help_title   = "commands:",
        help_toggle  = "  /wfi                 - show/hide the panel",
        help_lock    = "  /wfi lock            - lock/unlock the panel (drag with left mouse button)",
        help_reset   = "  /wfi reset           - move the panel back to its default position",
        help_show    = "  /wfi show <item>     - show an item on the bar",
        help_hide    = "  /wfi hide <item>     - hide an item from the bar",
        help_items   = "  /wfi items           - list items and which are visible",
        help_version = "  /wfi version         - show the client version and Interface number",
        help_lang    = "  /wfi lang pt|en|auto - choose the language (auto = client language)",
        shown        = "panel shown.",
        hidden       = "panel hidden.",
        locked       = "panel locked.",
        unlocked     = "panel unlocked — drag to move.",
        reset        = "position restored.",
        version      = "client %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use this number on the '## Interface:' line of the .toc file.",
        lang_set     = "language: English.",
        lang_auto    = "language: automatic (follows the client).",
        lang_usage   = "usage: /wfi lang pt | en | auto",
        item_usage   = "usage: /wfi show|hide fps | ms | coords | zone | durab | gold",
        item_on      = "%s: |cff00ff00shown|r",
        item_off     = "%s: |cffff3333hidden|r",
        items_title  = "bar items:",
        none_shown   = "WoW Forever Info — /wfi show <item>",
        name_fps     = "FPS",
        name_ms      = "Latency (ms)",
        name_coords  = "Coordinates (coords)",
        name_zone    = "Zone (zone)",
        name_durab   = "Durability (durab)",
        name_gold    = "Gold (gold)",
        label_durab  = "Dur",
        tt_latency   = "Latency",
        tt_lat_value = "home %d ms / world %d ms",
        tt_coords    = "Coordinates",
        tt_zone      = "Zone",
        tt_subzone   = "Subzone",
        tt_durab     = "Durability (lowest item)",
        tt_all_ok    = "All gear is at 100%.",
        tt_no_gear   = "No equipped items with durability.",
        tt_gold      = "Gold",
        tt_drag      = "Drag to move.",
        tt_locked    = "Panel locked (/wfi lock).",
        tt_help      = "/wfi help — list of commands",
        tt_slot      = "Slot %d",
        help_menu    = "  /wfi menu            - open the options menu (or right-click the panel)",
        opt_items    = "Bar items",
        opt_general  = "General",
        opt_shown    = "Show panel",
        opt_locked   = "Lock position",
        opt_lang     = "Language",
        opt_reset    = "Reset position",
        opt_hint     = "Tick what you want to see on the bar.",
        tt_rightclick = "Right-click: options.",
    },
}

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local db -- configurações validadas (preenchida em ADDON_LOADED)

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

-- Idioma ativo: escolha do usuário, ou o idioma do cliente quando "auto".
local function CurrentLang()
    local lang = db and db.lang or "auto"
    if lang == "auto" then
        local locale = GetLocale and GetLocale() or "enUS"
        return (locale == "ptBR" or locale == "ptPT") and "pt" or "en"
    end
    return lang
end

-- Busca um texto traduzido; cai para inglês se faltar.
local function T(key)
    local lang = STRINGS[CurrentLang()] or STRINGS.en
    return lang[key] or STRINGS.en[key] or key
end

-- Garante que SavedVariables tenham só os tipos/valores esperados.
-- Um arquivo corrompido ou editado à mão nunca quebra o addon.
local function SanitizeDB(saved)
    local clean = {}
    if type(saved) ~= "table" then saved = {} end

    for key, default in pairs(DEFAULTS) do
        local value = saved[key]
        if type(value) ~= type(default) then
            value = default
        end
        clean[key] = value
    end

    if not VALID_POINTS[clean.point] then clean.point = DEFAULTS.point end
    if not VALID_POINTS[clean.relPoint] then clean.relPoint = DEFAULTS.relPoint end
    if not VALID_LANGS[clean.lang] then clean.lang = DEFAULTS.lang end

    -- Limita deslocamentos a valores razoáveis.
    local limit = 5000
    if clean.x ~= clean.x or clean.x > limit or clean.x < -limit then clean.x = DEFAULTS.x end
    if clean.y ~= clean.y or clean.y > limit or clean.y < -limit then clean.y = DEFAULTS.y end

    -- Itens visíveis: só chaves conhecidas, só booleanos; o resto é descartado.
    local savedItems = type(saved.items) == "table" and saved.items or {}
    clean.items = {}
    for _, key in ipairs(ITEM_ORDER) do
        local value = savedItems[key]
        if type(value) == "boolean" then
            clean.items[key] = value
        else
            clean.items[key] = true -- padrão: visível
        end
    end

    return clean
end

-- Executa uma leitura de dados isolada: qualquer erro/bloqueio vira nil.
local function Safe(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

-- WoW Forever / Midnight podem marcar valores como "secretos" (secret values);
-- não podemos fazer contas com eles, então os tratamos como indisponíveis.
local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

local function FormatMoney(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    return string.format("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", gold, silver, cop)
end

-- Cores: verde (bom), amarelo (médio), vermelho (ruim).
local GREEN, YELLOW, RED = "|cff00ff00", "|cffffff00", "|cffff3333"

local function ColorLowIsGood(value, good, ok)
    if value <= good then return GREEN end
    if value <= ok then return YELLOW end
    return RED
end

local function ColorHighIsGood(value, good, ok)
    if value >= good then return GREEN end
    if value >= ok then return YELLOW end
    return RED
end

---------------------------------------------------------------------------
-- Leitura de dados compatível com várias versões do cliente
---------------------------------------------------------------------------

local function GetFPS()
    return math.floor((GetFramerate() or 0) + 0.5)
end

local function GetLatency()
    -- 3.3.5a retorna (entrada, saída, latência); clientes modernos retornam também latencyWorld.
    local _, _, home, world = GetNetStats()
    home = tonumber(home) or 0
    world = tonumber(world) or 0
    return math.max(home, world), home, world
end

local function GetCoordsRaw()
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local x, y = pos:GetXY()
                if x and y and (x > 0 or y > 0) then return x, y end
            end
        end
    elseif GetPlayerMapPosition then
        local x, y = GetPlayerMapPosition("player")
        if x and y and (x > 0 or y > 0) then return x, y end
    end
    return nil -- instâncias e alguns mapas não informam posição
end

local function GetCoords()
    local x, y = Safe(GetCoordsRaw)
    if x == nil or IsSecret(x) or IsSecret(y) then return nil end
    return x, y
end

local function GetZones()
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or ""
    local sub = GetSubZoneText and GetSubZoneText() or ""
    if IsSecret(zone) then zone = "" end
    if IsSecret(sub) then sub = "" end
    return zone, sub
end

-- Durabilidade: guardada em cache e recalculada só quando o equipamento muda.
local durability = { lowest = nil, damaged = {} }

local function ScanDurabilityRaw()
    local lowest, damaged = nil, {}
    for slot = 1, 19 do -- espaços de equipamento
        local cur, max = GetInventoryItemDurability(slot)
        if cur and max and not IsSecret(cur) and not IsSecret(max) and max > 0 then
            local pct = cur / max * 100
            if not lowest or pct < lowest then lowest = pct end
            if pct < 100 then
                damaged[#damaged + 1] = { slot = slot, pct = pct }
            end
        end
    end
    table.sort(damaged, function(a, b) return a.pct < b.pct end)
    durability.lowest, durability.damaged = lowest, damaged
end

local function ScanDurability()
    if not pcall(ScanDurabilityRaw) then
        durability.lowest, durability.damaged = nil, {}
    end
end

-- No 3.3.5a as coordenadas dependem do mapa "ativo"; ao trocar de zona,
-- voltamos o mapa para a zona atual (sem mexer se o jogador estiver com o mapa aberto).
local function ResetMapToCurrentZone()
    if SetMapToCurrentZone and not (C_Map and C_Map.GetBestMapForUnit) then
        if not (WorldMapFrame and WorldMapFrame:IsShown()) then
            SetMapToCurrentZone()
        end
    end
end

---------------------------------------------------------------------------
-- Itens da barra: cada um devolve o texto que aparece no painel
---------------------------------------------------------------------------

local ITEM_TEXT = {
    fps = function()
        local fps = GetFPS()
        return string.format("%s%d|r fps", ColorHighIsGood(fps, 50, 25), fps)
    end,
    ms = function()
        local ms = GetLatency()
        return string.format("%s%d|r ms", ColorLowIsGood(ms, 100, 250), ms)
    end,
    coords = function()
        local x, y = GetCoords()
        if not x then return "--, --" end
        return string.format("%.1f, %.1f", x * 100, y * 100)
    end,
    zone = function()
        local zone = GetZones()
        if zone == "" then return nil end
        return "|cffffcc66" .. zone .. "|r"
    end,
    durab = function()
        local pct = durability.lowest
        if not pct then return nil end -- sem itens com durabilidade (ex.: personagem sem equipamento)
        return string.format("%s %s%d%%|r", T("label_durab"), ColorHighIsGood(pct, 50, 20), math.floor(pct))
    end,
    gold = function()
        return FormatMoney(GetMoney())
    end,
}

---------------------------------------------------------------------------
-- Painel
---------------------------------------------------------------------------

-- Clientes modernos exigem o template "BackdropTemplate" para usar SetBackdrop; os antigos não o possuem.
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local frame = CreateFrame("Frame", "WoWForeverInfoFrame", UIParent, backdropTemplate)
frame:SetSize(330, 26)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

if frame.SetBackdrop then
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("CENTER")
text:SetText("...")

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point, db.relPoint = point, relPoint
    db.x, db.y = math.floor(x + 0.5), math.floor(y + 0.5)
    WoWForeverInfoDB = db
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

frame:SetScript("OnDragStart", function(self)
    if db and not db.locked and not InCombatLockdown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then SavePosition() end
end)

local function UpdateText()
    local parts = {}
    for _, key in ipairs(ITEM_ORDER) do
        if db.items[key] then
            local ok, value = pcall(ITEM_TEXT[key])
            if not ok then value = "--" end
            if value then parts[#parts + 1] = value end
        end
    end

    if #parts == 0 then
        text:SetText("|cff888888" .. T("none_shown") .. "|r")
    else
        text:SetText(table.concat(parts, "   "))
    end
    frame:SetWidth(math.max(120, text:GetStringWidth() + 20))
end

---------------------------------------------------------------------------
-- Tooltip (passar o mouse sobre o painel)
---------------------------------------------------------------------------

local WHITE = { 1, 1, 1 }
local GOLD_TXT = { 1, 0.82, 0 }

local function AddPair(label, value)
    GameTooltip:AddDoubleLine(label, value, GOLD_TXT[1], GOLD_TXT[2], GOLD_TXT[3], WHITE[1], WHITE[2], WHITE[3])
end

local function FillTooltip()
    GameTooltip:AddLine("WoW Forever Info", 0.2, 0.8, 1)

    local fps = Safe(GetFPS)
    AddPair("FPS", fps and tostring(fps) or "--")

    local _, home, world = Safe(GetLatency)
    AddPair(T("tt_latency"), home and string.format(T("tt_lat_value"), home, world) or "--")

    local x, y = GetCoords()
    AddPair(T("tt_coords"), x and string.format("%.1f, %.1f", x * 100, y * 100) or "--, --")

    local zone, sub = Safe(GetZones)
    AddPair(T("tt_zone"), (zone and zone ~= "") and zone or "--")
    if sub and sub ~= "" and sub ~= zone then
        AddPair(T("tt_subzone"), sub)
    end

    GameTooltip:AddLine(" ")
    if durability.lowest then
        AddPair(T("tt_durab"), string.format("%s%d%%|r",
            ColorHighIsGood(durability.lowest, 50, 20), math.floor(durability.lowest)))
        if #durability.damaged == 0 then
            GameTooltip:AddLine(T("tt_all_ok"), 0.6, 0.6, 0.6)
        else
            for _, entry in ipairs(durability.damaged) do
                local link = Safe(GetInventoryItemLink, "player", entry.slot)
                if type(link) ~= "string" or IsSecret(link) then
                    link = string.format(T("tt_slot"), entry.slot)
                end
                GameTooltip:AddDoubleLine("  " .. link, string.format("%s%d%%|r",
                    ColorHighIsGood(entry.pct, 50, 20), math.floor(entry.pct)))
            end
        end
    else
        GameTooltip:AddLine(T("tt_no_gear"), 0.6, 0.6, 0.6)
    end

    GameTooltip:AddLine(" ")
    local money = Safe(GetMoney)
    AddPair(T("tt_gold"), money and FormatMoney(money) or "--")

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(db.locked and T("tt_locked") or T("tt_drag"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(T("tt_rightclick"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(T("tt_help"), 0.6, 0.6, 0.6)
end

local function ShowTooltip(self)
    if not db then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    pcall(FillTooltip)
    GameTooltip:Show()
end

frame:SetScript("OnEnter", ShowTooltip)
frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function TooltipIsOurs()
    return GameTooltip ~= nil and GameTooltip:IsShown() and GameTooltip.IsOwned ~= nil and GameTooltip:IsOwned(frame)
end

local elapsedSinceUpdate = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= UPDATE_INTERVAL then
        elapsedSinceUpdate = 0
        UpdateText()
        if TooltipIsOurs() then ShowTooltip(self) end -- mantém o tooltip atualizado
    end
end)

local function ApplyVisibility()
    if db.shown then frame:Show() else frame:Hide() end
end

---------------------------------------------------------------------------
-- Ações (usadas pelos comandos e pelo menu de opções)
---------------------------------------------------------------------------

local RefreshOptions -- definida abaixo; sincroniza as caixinhas com as configurações

local function SetShown(value)
    db.shown = value
    ApplyVisibility()
    RefreshOptions()
end

local function SetLocked(value)
    db.locked = value
    RefreshOptions()
end

local function ResetPosition()
    db.point, db.relPoint, db.x, db.y = DEFAULTS.point, DEFAULTS.relPoint, DEFAULTS.x, DEFAULTS.y
    ApplyPosition()
end

local function SetLang(lang)
    db.lang = lang
    UpdateText()
    RefreshOptions()
end

local function SetItemVisible(key, value)
    db.items[key] = value
    UpdateText()
    RefreshOptions()
end

---------------------------------------------------------------------------
-- Menu de opções (caixinhas para marcar)
-- Os mesmos controles aparecem na janela própria (/wfi menu, clique direito)
-- e na lista de AddOns das configurações do jogo.
---------------------------------------------------------------------------

local controlSets = {} -- cada conjunto de controles criado (janela e painel de configurações)
local widgetCount = 0

local function NextName(kind)
    widgetCount = widgetCount + 1
    return "WoWForeverInfo" .. kind .. widgetCount
end

local function IsChecked(button)
    return button:GetChecked() and true or false -- 3.3.5a devolve 1/nil; clientes modernos, true/false
end

local function CreateHeader(parent, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, y)
    return header
end

local function CreateCheck(parent, y, onClick)
    local check = CreateFrame("CheckButton", NextName("Check"), parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", 20, y)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check:SetScript("OnClick", function(self) onClick(IsChecked(self)) end)
    return check
end

local function CreateButton(parent, width, onClick)
    local button = CreateFrame("Button", NextName("Button"), parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetScript("OnClick", onClick)
    return button
end

-- Cria todos os controles dentro de "parent", começando na altura "top".
local function BuildControls(parent, top)
    local set = { items = {}, langs = {} }
    local y = top

    set.hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    set.hint:SetPoint("TOPLEFT", 16, y)
    y = y - 22

    set.itemsHeader = CreateHeader(parent, y)
    y = y - 20
    for _, key in ipairs(ITEM_ORDER) do
        set.items[key] = CreateCheck(parent, y, function(value) SetItemVisible(key, value) end)
        y = y - 26
    end

    y = y - 10
    set.generalHeader = CreateHeader(parent, y)
    y = y - 20
    set.shown = CreateCheck(parent, y, SetShown)
    y = y - 26
    set.locked = CreateCheck(parent, y, SetLocked)
    y = y - 36

    set.langHeader = CreateHeader(parent, y)
    y = y - 22
    local x = 20
    for _, entry in ipairs({ { "auto", "Auto" }, { "pt", "Português" }, { "en", "English" } }) do
        local lang, label = entry[1], entry[2]
        local button = CreateButton(parent, 84, function() SetLang(lang) end)
        button:SetPoint("TOPLEFT", x, y)
        button:SetText(label)
        set.langs[lang] = button
        x = x + 88
    end
    y = y - 36

    set.reset = CreateButton(parent, 160, function() ResetPosition() end)
    set.reset:SetPoint("TOPLEFT", 20, y)
    y = y - 30

    controlSets[#controlSets + 1] = set
    return set, y
end

RefreshOptions = function()
    if not db then return end
    for _, set in ipairs(controlSets) do
        set.hint:SetText(T("opt_hint"))
        set.itemsHeader:SetText(T("opt_items"))
        set.generalHeader:SetText(T("opt_general"))
        set.langHeader:SetText(T("opt_lang"))
        for key, check in pairs(set.items) do
            check.label:SetText((string.gsub(T("name_" .. key), "%s*%b()", "")))
            check:SetChecked(db.items[key])
        end
        set.shown.label:SetText(T("opt_shown"))
        set.shown:SetChecked(db.shown)
        set.locked.label:SetText(T("opt_locked"))
        set.locked:SetChecked(db.locked)
        for lang, button in pairs(set.langs) do
            if lang == db.lang then button:LockHighlight() else button:UnlockHighlight() end
        end
        set.reset:SetText(T("opt_reset"))
    end
end

-- Janela própria, criada só na primeira vez que for aberta.
local optionsWindow

local function CreateOptionsWindow()
    local window = CreateFrame("Frame", "WoWForeverInfoOptions", UIParent, backdropTemplate)
    window:SetFrameStrata("DIALOG")
    window:SetPoint("CENTER")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)

    if window.SetBackdrop then
        window:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("WoW Forever Info")

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local _, bottom = BuildControls(window, -46)
    window:SetSize(310, -bottom + 12)

    window:SetScript("OnShow", RefreshOptions)
    tinsert(UISpecialFrames, "WoWForeverInfoOptions") -- ESC fecha a janela
    window:Hide()
    return window
end

local function ToggleOptions()
    optionsWindow = optionsWindow or CreateOptionsWindow()
    if optionsWindow:IsShown() then
        optionsWindow:Hide()
    else
        optionsWindow:Show()
    end
end

-- Também aparece em Esc > Opções > AddOns (clientes modernos) ou Interface > AddOns (antigos).
local function RegisterSettingsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "WoW Forever Info"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("WoW Forever Info")

    BuildControls(panel, -46)
    panel:SetScript("OnShow", RefreshOptions)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- Clique direito no painel abre o menu.
frame:SetScript("OnMouseUp", function(_, button)
    if button == "RightButton" and db then ToggleOptions() end
end)

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        db = SanitizeDB(WoWForeverInfoDB)
        WoWForeverInfoDB = db
        ApplyPosition()
        ApplyVisibility()
        pcall(RegisterSettingsPanel) -- se a API de configurações mudar, o addon continua funcionando
        self:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not db then return end

    if event == "PLAYER_ENTERING_WORLD" then
        ResetMapToCurrentZone()
        ScanDurability()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ResetMapToCurrentZone()
    elseif event == "UPDATE_INVENTORY_DURABILITY" or event == "PLAYER_EQUIPMENT_CHANGED" then
        ScanDurability()
    end
    UpdateText()
end)

---------------------------------------------------------------------------
-- Comandos: /wfi
---------------------------------------------------------------------------

local function ShowHelp()
    Print(T("help_title"))
    for _, key in ipairs({ "help_toggle", "help_menu", "help_lock", "help_reset", "help_show",
                           "help_hide", "help_items", "help_version", "help_lang" }) do
        Print(T(key))
    end
end

local function ListItems()
    Print(T("items_title"))
    for _, key in ipairs(ITEM_ORDER) do
        Print("  " .. string.format(db.items[key] and T("item_on") or T("item_off"), T("name_" .. key)))
    end
end

local function SetItem(alias, visible)
    local key = ITEM_ALIASES[alias] -- só nomes da lista fixa são aceitos
    if not key then
        Print(T("item_usage"))
        return
    end
    SetItemVisible(key, visible)
    Print(string.format(visible and T("item_on") or T("item_off"), T("name_" .. key)))
end

SLASH_WOWFOREVERINFO1 = "/wfi"
SLASH_WOWFOREVERINFO2 = "/wfinfo"
SlashCmdList["WOWFOREVERINFO"] = function(msg)
    if not db then return end
    -- Aceita só palavras simples (letras); qualquer outra coisa mostra a ajuda.
    local cmd, arg = string.match(msg or "", "^%s*(%a*)%s*(%a*)")
    cmd, arg = string.lower(cmd or ""), string.lower(arg or "")

    if cmd == "" then
        SetShown(not db.shown)
        Print(db.shown and T("shown") or T("hidden"))
    elseif cmd == "menu" or cmd == "config" or cmd == "opcoes" or cmd == "options" then
        ToggleOptions()
    elseif cmd == "lock" or cmd == "travar" then
        SetLocked(not db.locked)
        Print(db.locked and T("locked") or T("unlocked"))
    elseif cmd == "reset" then
        ResetPosition()
        Print(T("reset"))
    elseif cmd == "show" or cmd == "mostrar" then
        SetItem(arg, true)
    elseif cmd == "hide" or cmd == "esconder" or cmd == "ocultar" then
        SetItem(arg, false)
    elseif cmd == "items" or cmd == "itens" then
        ListItems()
    elseif cmd == "lang" or cmd == "idioma" then
        if VALID_LANGS[arg] then
            SetLang(arg)
            Print(arg == "auto" and T("lang_auto") or T("lang_set"))
        else
            Print(T("lang_usage"))
        end
    elseif cmd == "version" or cmd == "versao" then
        local version, build, date, interface = GetBuildInfo()
        -- Clientes muito antigos não retornam o 4º valor; deduzimos pela versão.
        if not interface and type(version) == "string" then
            local major, minor = string.match(version, "^(%d+)%.(%d+)")
            if major then interface = string.format("%d%02d00", tonumber(major), tonumber(minor)) end
        end
        Print(string.format(T("version"),
            tostring(version), tostring(build), tostring(date), tostring(interface)))
        Print(T("version_hint"))
    else
        ShowHelp()
    end
end
