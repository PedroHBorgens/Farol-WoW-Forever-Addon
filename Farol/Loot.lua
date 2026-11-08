--[[
  Farol — Janela de últimos saques / Recent loot window

  * Registra os itens que VOCÊ saqueia ou recebe, lendo a mensagem de saque que o próprio jogo
    mostra no seu chat ("Você recebe saque: ..."). Usa os textos do cliente, então funciona em
    qualquer idioma.
  * Janela separada da barra: escolha ver os últimos 5, 10, 15 ou 20 itens e filtre por qualidade.
  * Histórico salvo por personagem (até 100 itens).

  Segurança: só lê mensagens de saque do próprio jogador; nada é enviado a ninguém. Os links salvos
  são validados ao carregar (só links de item no formato do jogo sobrevivem).
]]

local _, ns = ...

local HISTORY_MAX = 100
local COUNT_OPTIONS = { 5, 10, 15, 20 }
local QUALITY_KEYS = { 0, 1, 2, 3, 4, 5 } -- 5 = Lendário ou acima (artefato, herança...)
local ROW_HEIGHT = 22
local LIST_TOP = -150

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
        loot_hint     = "Mouse: detalhes do item · Shift+clique: link no chat",
        opt_loot      = "Saques...",
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
        loot_hint     = "Hover: item details · Shift-click: link in chat",
        opt_loot      = "Loot...",
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

function Loot.SanitizeSettings(saved)
    local clean = { count = 10, qualities = {} }
    if type(saved) ~= "table" then saved = {} end
    if ValidCount(saved.count) then clean.count = saved.count end
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
            clean[#clean + 1] = { link = entry.link, count = count, q = q, t = tonumber(entry.t) or 0 }
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

local function Record(link, count)
    if not ValidLink(link) then return end
    history[#history + 1] = { link = link, count = count, q = QualityOf(link), t = time() }
    while #history > HISTORY_MAX do table.remove(history, 1) end
    if FarolCharDB then FarolCharDB.items = history end
    if RefreshWindow then RefreshWindow() end
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

local window

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

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolLoot", UIParent, ns.backdropTemplate)
    frame:SetWidth(390)
    frame:SetPoint("CENTER", -40, 0)
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

    -- Quantidade: 5 / 10 / 15 / 20
    frame.showLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.showLabel:SetPoint("TOPLEFT", 20, -50)
    frame.countButtons = {}
    for i, n in ipairs(COUNT_OPTIONS) do
        local button = CreateFrame("Button", "FarolLootCount" .. n, frame, "UIPanelButtonTemplate")
        button:SetSize(40, 22)
        button:SetPoint("TOPLEFT", 90 + (i - 1) * 44, -45)
        button:SetText(tostring(n))
        button:SetScript("OnClick", function()
            Settings().count = n
            RefreshWindow()
        end)
        frame.countButtons[n] = button
    end
    frame.clear = CreateFrame("Button", "FarolLootClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(80, 22)
    frame.clear:SetPoint("TOPRIGHT", -24, -45)
    frame.clear:SetScript("OnClick", function() Loot.Clear() end)

    -- Filtro de qualidade (2 linhas de 3)
    frame.qualityLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.qualityLabel:SetPoint("TOPLEFT", 20, -78)
    frame.qualityChecks = {}
    for i, q in ipairs(QUALITY_KEYS) do
        local column, row = (i - 1) % 3, math.floor((i - 1) / 3)
        local check = CreateFrame("CheckButton", "FarolLootQuality" .. q, frame, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 20 + column * 120, -94 - row * 24)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
        check:SetScript("OnClick", function(self)
            Settings().qualities[q] = self:GetChecked() and true or false
            RefreshWindow()
        end)
        frame.qualityChecks[q] = check
    end

    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("TOPLEFT", 24, LIST_TOP - 4)

    -- Linhas da lista
    frame.rows = {}
    for i = 1, COUNT_OPTIONS[#COUNT_OPTIONS] do
        local row = CreateFrame("Button", nil, frame)
        row:SetSize(350, ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", 20, LIST_TOP - (i - 1) * ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetWidth(240)
        row.text:SetJustifyH("LEFT")
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.info:SetPoint("RIGHT", 0, 0)
        row.info:SetJustifyH("RIGHT")
        row:SetScript("OnEnter", function(self)
            if not self.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            -- Shift+clique coloca o link na SUA caixa de chat (você decide se envia).
            if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
        end)
        frame.rows[i] = row
    end

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolLoot") -- ESC fecha
    frame:Hide()
    return frame
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local settings = Settings()

    window.title:SetText(T("loot_title"))
    window.showLabel:SetText(T("loot_show"))
    window.qualityLabel:SetText(T("loot_quality"))
    window.clear:SetText(T("loot_clear"))
    for n, button in pairs(window.countButtons) do
        if n == settings.count then button:LockHighlight() else button:UnlockHighlight() end
    end
    for q, check in pairs(window.qualityChecks) do
        check.label:SetText(QualityName(q))
        check.label:SetTextColor(QualityColor(q))
        check:SetChecked(settings.qualities[q])
    end

    -- Os N mais recentes que passam no filtro, do mais novo para o mais antigo.
    local shown = {}
    for i = #history, 1, -1 do
        if #shown >= settings.count then break end
        if history[i].q == nil then history[i].q = QualityOf(history[i].link) end
        if Passes(history[i], settings.qualities) then shown[#shown + 1] = history[i] end
    end

    for i, row in ipairs(window.rows) do
        local entry = shown[i]
        if entry and i <= settings.count then
            row.link = entry.link
            row.icon:SetTexture(IconOf(entry.link))
            row.text:SetText(entry.link)
            local info = date("%H:%M", entry.t)
            if entry.count > 1 then info = "x" .. entry.count .. "   " .. info end
            row.info:SetText(info)
            row:Show()
        else
            row.link = nil
            row:Hide()
        end
    end

    if #shown == 0 then
        window.empty:SetText(#history == 0 and T("loot_empty") or T("loot_filtered"))
        window.empty:Show()
    else
        window.empty:Hide()
    end

    local listRows = math.max(#shown, 1)
    local bottom = LIST_TOP - listRows * ROW_HEIGHT
    window.hint:ClearAllPoints()
    window.hint:SetPoint("TOPLEFT", 22, bottom - 8)
    window.hint:SetText(T("loot_hint"))
    window:SetHeight(-bottom + 44)
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
