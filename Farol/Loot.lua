--[[
  Farol — Janela de últimos saques / Recent loot window

  * Registra os itens que VOCÊ saqueia ou recebe, lendo a mensagem de saque que o próprio jogo
    mostra no seu chat ("Você recebe saque: ..."). Usa os textos do cliente, então funciona em
    qualquer idioma.
  * Janela separada da barra, redimensionável: menus suspensos para ver os últimos 5, 10, 15 ou 20
    itens e filtrar por qualidade.
  * Histórico salvo por personagem (até 100 itens).

  Segurança: só lê mensagens de saque do próprio jogador; nada é enviado a ninguém. Os links salvos
  são validados ao carregar (só links de item no formato do jogo sobrevivem).
]]

local _, ns = ...

local HISTORY_MAX = 100
local COUNT_OPTIONS = { 5, 10, 15, 20 }
local QUALITY_KEYS = { 0, 1, 2, 3, 4, 5 } -- 5 = Lendário ou acima (artefato, herança...)
local ROW_HEIGHT = 22
local LIST_TOP = -84      -- onde a lista começa (abaixo dos filtros)
local FOOTER_H = 62       -- espaço do rodapé (dica, Limpar, alça)
local DEFAULT_W, DEFAULT_H = 420, 380
local MIN_W, MIN_H, MAX_W, MAX_H = 380, 220, 900, 900

local Loot = {}
ns.Loot = Loot

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        loot_title    = "Últimos saques",
        loot_show     = "Mostrar:",
        loot_quality  = "Qualidade:",
        loot_clear    = "Limpar",
        loot_empty    = "Nenhum item saqueado ainda.",
        loot_filtered = "Nenhum item com esse filtro.",
        loot_cleared  = "histórico de saques apagado.",
        loot_legend_plus = "Lendário+",
        loot_hint     = "Mouse: detalhes · Shift+clique: link · Roda: rolar",
        loot_all      = "Todas",
        loot_none     = "Nenhuma",
        loot_n_selected = "%d selecionadas",
        loot_check_all = "Marcar todas",
        loot_uncheck_all = "Desmarcar todas",
        loot_scroll   = "%d–%d de %d",
        opt_loot      = "Saques...",
        loot_button_tip = "Últimos saques",
        loot_button_new = "%d item(ns) novo(s) — clique para ver",
        loot_button_none = "Clique para ver",
        loot_when     = "Saqueado: %s",
        help_loot     = "  /farol saque [limpar] - abrir a janela de últimos saques (ou apagar o histórico)",
    },
    en = {
        loot_title    = "Recent loot",
        loot_show     = "Show:",
        loot_quality  = "Quality:",
        loot_clear    = "Clear",
        loot_empty    = "Nothing looted yet.",
        loot_filtered = "No items match this filter.",
        loot_cleared  = "loot history cleared.",
        loot_legend_plus = "Legendary+",
        loot_hint     = "Hover: details · Shift-click: link · Wheel: scroll",
        loot_all      = "All",
        loot_none     = "None",
        loot_n_selected = "%d selected",
        loot_check_all = "Check all",
        loot_uncheck_all = "Uncheck all",
        loot_scroll   = "%d–%d of %d",
        opt_loot      = "Loot...",
        loot_button_tip = "Recent loot",
        loot_button_new = "%d new item(s) — click to view",
        loot_button_none = "Click to view",
        loot_when     = "Looted: %s",
        help_loot     = "  /farol loot [clear]  - open the recent loot window (or clear the history)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function Settings() return ns.GetDB().loot end

local history = {} -- lista do mais antigo para o mais novo: { link, count, q, t }

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

-- Link de item no formato do jogo. Dentro do nome só é aceito o ícone de qualidade de
-- profissão (|A...|a) dos clientes modernos; qualquer outro código "|" é recusado.
local function ValidLink(link)
    if type(link) ~= "string" or #link > 400 then return false end
    local name = string.match(link, "^|c[^|]*|Hitem:[^|]*|h%[(.-)%]|h|r$")
    if not name then return false end
    name = string.gsub(name, "|A[^|]*|a", "")
    return not string.find(name, "|", 1, true)
end

local function ValidCount(n)
    for _, option in ipairs(COUNT_OPTIONS) do
        if n == option then return true end
    end
    return false
end

-- Data salva válida: número finito entre 1970 e 2100 (um arquivo adulterado com "infinito"
-- ou NaN quebraria a formatação da data).
local function ValidTime(t)
    t = tonumber(t)
    if t and t == t and t >= 0 and t <= 4102444800 then return math.floor(t) end
    return nil
end

function Loot.SanitizeSettings(saved)
    local clean = { count = 10, qualities = {}, w = DEFAULT_W, h = DEFAULT_H }
    if type(saved) ~= "table" then saved = {} end
    if ValidCount(saved.count) then clean.count = saved.count end
    -- Tamanho da janela: só números dentro dos limites.
    local w, h = tonumber(saved.w), tonumber(saved.h)
    if w and w == w and w >= MIN_W and w <= MAX_W then clean.w = math.floor(w) end
    if h and h == h and h >= MIN_H and h <= MAX_H then clean.h = math.floor(h) end
    local savedQ = type(saved.qualities) == "table" and saved.qualities or {}
    for _, q in ipairs(QUALITY_KEYS) do
        clean.qualities[q] = savedQ[q] ~= false -- padrão: todas visíveis
    end
    return clean
end

function Loot.SanitizeHistory(saved)
    local clean = {}
    if type(saved) ~= "table" or type(saved.items) ~= "table" then return { items = clean } end
    for _, entry in ipairs(saved.items) do
        if type(entry) == "table" and ValidLink(entry.link) then
            local count = tonumber(entry.count) or 1
            if count < 1 or count > 100000 or count ~= math.floor(count) then count = 1 end
            local q = tonumber(entry.q)
            if q and (q < 0 or q > 9 or q ~= math.floor(q)) then q = nil end
            clean[#clean + 1] = { link = entry.link, count = count, q = q, t = ValidTime(entry.t) or 0 }
        end
    end
    while #clean > HISTORY_MAX do table.remove(clean, 1) end
    history = clean
    return { items = clean }
end

---------------------------------------------------------------------------
-- Leitura das mensagens de saque
---------------------------------------------------------------------------

-- Converte um texto do jogo (ex.: "Você recebe saque: %sx%d.") em padrão Lua.
local function ToPattern(format)
    if type(format) ~= "string" then return nil end
    format = string.gsub(format, "%%%d%$s", "\1")
    format = string.gsub(format, "%%s", "\1")
    format = string.gsub(format, "%%%d%$d", "\2")
    format = string.gsub(format, "%%d", "\2")
    format = string.gsub(format, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    format = string.gsub(format, "\1", "(.+)")
    format = string.gsub(format, "\2", "(%%d+)")
    return "^" .. format .. "$"
end

-- Ordem importa: as versões com quantidade primeiro.
local PATTERNS = {}
for _, entry in ipairs({
    { "LOOT_ITEM_SELF_MULTIPLE", true },
    { "LOOT_ITEM_PUSHED_SELF_MULTIPLE", true },
    { "LOOT_ITEM_SELF", false },
    { "LOOT_ITEM_PUSHED_SELF", false },
}) do
    local pattern = ToPattern(_G[entry[1]])
    if pattern then PATTERNS[#PATTERNS + 1] = { pattern = pattern, multiple = entry[2] } end
end

local function ExtractLink(text)
    return string.match(text, "(|c[^|]*|Hitem:[^|]*|h%[.-%]|h|r)")
end

local KNOWN_COLORS = {
    ["9d9d9d"] = 0, ["ffffff"] = 1, ["1eff00"] = 2, ["0070dd"] = 3,
    ["a335ee"] = 4, ["ff8000"] = 5, ["e6cc80"] = 6, ["00ccff"] = 7,
}

local function QualityOf(link)
    local q = string.match(link, "^|cnIQ(%d):") -- formato de cor dos clientes modernos
    if q then return tonumber(q) end
    if C_Item and C_Item.GetItemQualityByID then
        local ok, value = pcall(C_Item.GetItemQualityByID, link)
        if ok and type(value) == "number" then return value end
    end
    if GetItemInfo then
        local ok, _, _, value = pcall(GetItemInfo, link)
        if ok and type(value) == "number" then return value end
    end
    local hex = string.match(link, "^|cff(%x%x%x%x%x%x)")
    return hex and KNOWN_COLORS[string.lower(hex)] or nil
end

local function IconOf(link)
    local id = tonumber(string.match(link, "|Hitem:(%d+)"))
    local icon
    if id and C_Item and C_Item.GetItemIconByID then
        local ok, value = pcall(C_Item.GetItemIconByID, id)
        if ok then icon = value end
    end
    if not icon and id and GetItemIcon then
        local ok, value = pcall(GetItemIcon, id)
        if ok then icon = value end
    end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local RefreshWindow -- definida abaixo

---------------------------------------------------------------------------
-- Botão rápido ao lado da barra (abre a janela de saques)
---------------------------------------------------------------------------

local LOOT_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local unseen = 0  -- itens saqueados desde a última vez que a janela foi aberta
local lootButton
local window      -- janela de saques (criada sob demanda, mais abaixo)

local function UpdateButton()
    local db = ns.GetDB()
    if not db or not ns.frame then return end
    if not db.lootButton then
        if lootButton then lootButton:Hide() end
        ns.LayoutQuickButtons()
        return
    end
    if not lootButton then
        lootButton = CreateFrame("Button", "FarolLootButton", ns.frame)
        lootButton:SetSize(18, 18)
        lootButton.icon = lootButton:CreateTexture(nil, "ARTWORK")
        lootButton.icon:SetAllPoints()
        lootButton.icon:SetTexture(LOOT_ICON)
        lootButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        lootButton.badge = lootButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lootButton.badge:SetPoint("BOTTOMRIGHT", 4, -2)
        lootButton.badge:SetTextColor(0.3, 1, 0.3)
        lootButton:RegisterForClicks("LeftButtonUp")
        lootButton:SetScript("OnClick", function() Loot.ToggleWindow() end)
        lootButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("loot_button_tip"))
            GameTooltip:AddLine(unseen > 0 and string.format(T("loot_button_new"), unseen) or T("loot_button_none"),
                0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        lootButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        table.insert(ns.quickButtons, lootButton)
    end
    lootButton.badge:SetText(unseen > 0 and tostring(unseen) or "")
    lootButton:Show()
    ns.LayoutQuickButtons()
end
Loot.UpdateButton = UpdateButton

local function Record(link, count)
    if not ValidLink(link) then return end
    history[#history + 1] = { link = link, count = count, q = QualityOf(link), t = time() }
    while #history > HISTORY_MAX do table.remove(history, 1) end
    if FarolCharDB then FarolCharDB.items = history end
    if RefreshWindow then RefreshWindow() end
    if not (window and window:IsShown()) then
        unseen = unseen + 1
        UpdateButton()
    end
end

local function OnLootMessage(text)
    if type(text) ~= "string" then return end
    if ns.IsSecret(text) then return end -- conteúdo protegido pelo jogo: ignorado
    for _, entry in ipairs(PATTERNS) do
        local a, b = string.match(text, entry.pattern)
        if a then
            local link = ExtractLink(a)
            if link then Record(link, entry.multiple and (tonumber(b) or 1) or 1) end
            return
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, arg1)
    if not ns.GetDB() then return end
    if event == "CHAT_MSG_LOOT" then
        pcall(OnLootMessage, arg1)
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- Informação do item chegou: completa qualidades que faltavam.
        local changed = false
        for _, entry in ipairs(history) do
            if entry.q == nil then
                entry.q = QualityOf(entry.link)
                if entry.q ~= nil then changed = true end
            end
        end
        if changed and RefreshWindow then RefreshWindow() end
    end
end)

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------


local function QualityName(q)
    if q == 5 then return T("loot_legend_plus") end
    return _G["ITEM_QUALITY" .. q .. "_DESC"] or tostring(q)
end

local function QualityColor(q)
    if GetItemQualityColor then
        local ok, r, g, b = pcall(GetItemQualityColor, q)
        if ok and r then return r, g, b end
    end
    return 1, 1, 1
end

local function Passes(entry, qualities)
    local q = entry.q
    if q == nil then return true end -- qualidade ainda desconhecida: mostra
    if q >= 5 then return qualities[5] end
    return qualities[q]
end

---------------------------------------------------------------------------
-- Menu suspenso próprio (dropdown)
-- Feito do zero em vez do UIDropDownMenu da Blizzard, que está obsoleto nos clientes modernos
-- e é conhecido por causar "taint". Funciona igual em qualquer versão.
---------------------------------------------------------------------------

local openList -- lista de dropdown aberta no momento (só uma por vez)

-- Clique fora da lista fecha a lista.
local catcher = CreateFrame("Button", nil, UIParent)
catcher:SetAllPoints(UIParent)
catcher:SetFrameStrata("FULLSCREEN_DIALOG")
catcher:EnableMouse(true)
catcher:Hide()

local function CloseDropdown()
    if openList then openList:Hide() end
    openList = nil
    catcher:Hide()
end
catcher:SetScript("OnClick", CloseDropdown)

-- getItems() devolve { { text=, checked=, r=, g=, b=, onClick=, keepOpen= }, ... }
local function CreateDropdown(parent, name, width, getItems)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrow:SetSize(18, 18)
    arrow:SetPoint("RIGHT", -2, 0)
    local label = button:GetFontString()
    if label then
        label:ClearAllPoints()
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", arrow, "LEFT", -2, 0)
        label:SetJustifyH("LEFT")
    end

    local list = CreateFrame("Frame", name .. "List", UIParent, ns.backdropTemplate)
    list:SetFrameStrata("FULLSCREEN_DIALOG")
    list:SetFrameLevel(catcher:GetFrameLevel() + 10)
    list:SetClampedToScreen(true)
    if list.SetBackdrop then
        list:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        list:SetBackdropColor(0, 0, 0, 0.95)
    end
    list.entries = {}
    list:Hide()

    local function Populate()
        local items = getItems()
        local entryWidth = math.max(width, 150)
        for i, item in ipairs(items) do
            local entry = list.entries[i]
            if not entry then
                entry = CreateFrame("Button", name .. "Entry" .. i, list)
                entry:SetHeight(18)
                local hl = entry:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints()
                hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                hl:SetBlendMode("ADD")
                entry.check = entry:CreateTexture(nil, "OVERLAY")
                entry.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                entry.check:SetSize(16, 16)
                entry.check:SetPoint("LEFT", 2, 0)
                entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entry.text:SetPoint("LEFT", 22, 0)
                entry.text:SetJustifyH("LEFT")
                list.entries[i] = entry
            end
            entry:SetWidth(entryWidth - 12)
            entry:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 18)
            entry.text:SetText(item.text)
            entry.text:SetTextColor(item.r or 1, item.g or 1, item.b or 1)
            if item.checked then entry.check:Show() else entry.check:Hide() end
            entry:SetScript("OnClick", function()
                item.onClick()
                if item.keepOpen then Populate() else CloseDropdown() end
            end)
            entry:Show()
        end
        for i = #items + 1, #list.entries do list.entries[i]:Hide() end
        list:SetSize(entryWidth, #items * 18 + 12)
    end

    button:SetScript("OnClick", function()
        if openList == list then CloseDropdown() return end
        CloseDropdown()
        Populate()
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
        list:Show()
        catcher:Show()
        openList = list
    end)
    button:SetScript("OnHide", function() if openList == list then CloseDropdown() end end)
    return button
end
ns.CreateDropdown = CreateDropdown -- também usado pelos avisos (tempo do "Lembrar")

---------------------------------------------------------------------------
-- Janela (redimensionável)
---------------------------------------------------------------------------

local scrollOffset = 0

local function CountItems()
    local items = {}
    for _, n in ipairs(COUNT_OPTIONS) do
        items[#items + 1] = {
            text = tostring(n),
            checked = Settings().count == n,
            onClick = function()
                Settings().count = n
                scrollOffset = 0
                RefreshWindow()
            end,
        }
    end
    return items
end

local function QualityItems()
    local qualities = Settings().qualities
    local items = {}
    for _, q in ipairs(QUALITY_KEYS) do
        local r, g, b = QualityColor(q)
        items[#items + 1] = {
            text = QualityName(q), r = r, g = g, b = b,
            checked = qualities[q], keepOpen = true, -- multi-seleção: a lista fica aberta
            onClick = function()
                qualities[q] = not qualities[q]
                scrollOffset = 0
                RefreshWindow()
            end,
        }
    end
    for _, entry in ipairs({ { "loot_check_all", true }, { "loot_uncheck_all", false } }) do
        items[#items + 1] = {
            text = "|cffaaaaaa" .. T(entry[1]) .. "|r", keepOpen = true,
            onClick = function()
                for _, q in ipairs(QUALITY_KEYS) do qualities[q] = entry[2] end
                scrollOffset = 0
                RefreshWindow()
            end,
        }
    end
    return items
end

-- Texto do botão de qualidade: "Todas", "Nenhuma", até 2 nomes, ou "N selecionadas".
local function QualitySummary()
    local qualities = Settings().qualities
    local names, count = {}, 0
    for _, q in ipairs(QUALITY_KEYS) do
        if qualities[q] then
            count = count + 1
            names[#names + 1] = QualityName(q)
        end
    end
    if count == #QUALITY_KEYS then return T("loot_all") end
    if count == 0 then return T("loot_none") end
    if count <= 2 then return table.concat(names, ", ") end
    return string.format(T("loot_n_selected"), count)
end

local function SetResizeLimits(frame)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H) -- clientes modernos
    else
        if frame.SetMinResize then frame:SetMinResize(MIN_W, MIN_H) end
        if frame.SetMaxResize then frame:SetMaxResize(MAX_W, MAX_H) end
    end
end

local function CreateWindow()
    local settings = Settings()
    local frame = CreateFrame("Frame", "FarolLoot", UIParent, ns.backdropTemplate)
    frame:SetSize(settings.w, settings.h)
    frame:SetPoint("CENTER", -40, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    SetResizeLimits(frame)
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

    -- Linha de filtros: Mostrar [10 ▼]   Qualidade [Todas ▼]
    frame.showLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.showLabel:SetPoint("TOPLEFT", 20, -52)
    frame.countDropdown = CreateDropdown(frame, "FarolLootCount", 64, CountItems)
    frame.countDropdown:SetPoint("LEFT", frame.showLabel, "RIGHT", 6, 0)

    frame.qualityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.qualityLabel:SetPoint("LEFT", frame.countDropdown, "RIGHT", 14, 0)
    frame.qualityDropdown = CreateDropdown(frame, "FarolLootQuality", 150, QualityItems)
    frame.qualityDropdown:SetPoint("LEFT", frame.qualityLabel, "RIGHT", 6, 0)

    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("TOPLEFT", 24, LIST_TOP - 4)

    -- Linhas da lista
    frame.rows = {}
    for i = 1, COUNT_OPTIONS[#COUNT_OPTIONS] do
        local row = CreateFrame("Button", nil, frame)
        row:SetHeight(ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", 20, LIST_TOP - (i - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
        row:RegisterForClicks("LeftButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", 0, 0)
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.info:SetPoint("RIGHT", 0, 0)
        row.info:SetJustifyH("RIGHT")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetPoint("RIGHT", row.info, "LEFT", -8, 0) -- acompanha a largura da janela
        row.text:SetJustifyH("LEFT")
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        row:SetScript("OnEnter", function(self)
            if not self.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
            local when = ns.FormatWhen(self.when, true)
            if when ~= "--" then GameTooltip:AddLine(string.format(T("loot_when"), when), 0.6, 0.6, 0.6) end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            -- Shift+clique coloca o link na SUA caixa de chat (você decide se envia).
            if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
        end)
        frame.rows[i] = row
    end

    -- Rodapé: dica, posição da rolagem, Limpar e alça de redimensionar.
    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("BOTTOMLEFT", 22, 20)
    frame.hint:SetPoint("RIGHT", frame, "RIGHT", -120, 0)
    frame.hint:SetJustifyH("LEFT")
    frame.scrollInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.scrollInfo:SetPoint("BOTTOMLEFT", frame.hint, "TOPLEFT", 0, 4)
    frame.clear = CreateFrame("Button", "FarolLootClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(80, 22)
    frame.clear:SetPoint("BOTTOMRIGHT", -30, 16)
    frame.clear:SetScript("OnClick", function() Loot.Clear() end)

    local grip = CreateFrame("Button", "FarolLootResize", frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -8, 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        settings.w = math.floor(frame:GetWidth() + 0.5)
        settings.h = math.floor(frame:GetHeight() + 0.5)
    end)

    -- Roda do mouse rola a lista quando nem tudo cabe.
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        scrollOffset = scrollOffset - delta
        RefreshWindow()
    end)
    frame:SetScript("OnSizeChanged", function() RefreshWindow() end)

    frame:SetScript("OnShow", function()
        unseen = 0 -- abriu a janela: itens novos foram vistos
        UpdateButton()
        RefreshWindow()
    end)
    frame:SetScript("OnHide", CloseDropdown)
    tinsert(UISpecialFrames, "FarolLoot") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local settings = Settings()

    window.title:SetText(T("loot_title"))
    window.showLabel:SetText(T("loot_show"))
    window.qualityLabel:SetText(T("loot_quality"))
    window.countDropdown:SetText(tostring(settings.count))
    window.qualityDropdown:SetText(QualitySummary())
    window.clear:SetText(T("loot_clear"))
    window.hint:SetText(T("loot_hint"))

    -- Os N mais recentes que passam no filtro, do mais novo para o mais antigo.
    local shown = {}
    for i = #history, 1, -1 do
        if #shown >= settings.count then break end
        if history[i].q == nil then history[i].q = QualityOf(history[i].link) end
        if Passes(history[i], settings.qualities) then shown[#shown + 1] = history[i] end
    end

    -- Quantas linhas cabem na altura atual (o resto é acessado rolando).
    local available = (window:GetHeight() or settings.h) + LIST_TOP - FOOTER_H
    local fit = math.max(1, math.floor(available / ROW_HEIGHT))
    local maxOffset = math.max(0, #shown - fit)
    if scrollOffset > maxOffset then scrollOffset = maxOffset end
    if scrollOffset < 0 then scrollOffset = 0 end

    for i, row in ipairs(window.rows) do
        local entry = shown[i + scrollOffset]
        if entry and i <= fit then
            row.link = entry.link
            row.icon:SetTexture(IconOf(entry.link))
            row.text:SetText(entry.link)
            row.when = entry.t
            local info = ns.FormatWhen(entry.t)
            if entry.count > 1 then info = "x" .. entry.count .. "   " .. info end
            row.info:SetText(info)
            row:Show()
        else
            row.link = nil
            row:Hide()
        end
    end

    if #shown > fit then
        window.scrollInfo:SetText(string.format(T("loot_scroll"),
            scrollOffset + 1, math.min(scrollOffset + fit, #shown), #shown))
        window.scrollInfo:Show()
    else
        window.scrollInfo:Hide()
    end

    if #shown == 0 then
        window.empty:SetText(#history == 0 and T("loot_empty") or T("loot_filtered"))
        window.empty:Show()
    else
        window.empty:Hide()
    end
end

function Loot.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Loot.Clear()
    wipe(history)
    if FarolCharDB then FarolCharDB.items = history end
    Print(T("loot_cleared"))
    RefreshWindow()
end

function Loot.Refresh()
    RefreshWindow()
end

function Loot.HandleCommand(rest)
    local word = string.lower(string.match(rest or "", "^%s*(%a*)") or "")
    if word == "limpar" or word == "clear" then
        Loot.Clear()
    else
        Loot.ToggleWindow()
    end
end

-- Só para testes automatizados: expõe o leitor de mensagens.
Loot._OnLootMessage = OnLootMessage
Loot._ToPattern = ToPattern
