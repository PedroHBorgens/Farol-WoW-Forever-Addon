--[[
  Farol — Central do Farol / Farol hub (3.27, estilo "detalhado")

  Uma janela só com barra lateral: Início (cartões com o resumo do que o Farol mede), Personagens, Profissões e as
  janelas de sempre (Metas, Missões concluídas, Tarefas, Anotações, Guardados, Masmorras, Saques, Alarmes, Avisos e
  Configurações) encaixadas na área da direita. Vem DESLIGADA (regra 8): com FarolDB.hub = false tudo abre como hoje
  (estilo "simples"). Só lê e mostra; nada é enviado e não há pedido ao servidor.
  Encaixe: toda janela do Farol chama ns.MakeToplevel ao ser criada, que chama Hub.Watch(frame); com o estilo
  detalhado ligado, a janela que abrir é levada para dentro da Central (SetParent) e devolvida ao fechar.
]]

local _, ns = ...

local Hub = {}
ns.Hub = Hub

local WIDTH, HEIGHT = 1000, 640
local SIDE_W = 206
local TOP_H, FOOT_H = 52, 34

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        hub_title     = "Farol",
        hub_home      = "Início",
        hub_chars     = "Personagens",
        hub_goals     = "Metas",
        hub_quests    = "Missões",
        hub_profs     = "Profissões",
        hub_tasks     = "Tarefas",
        hub_notes     = "Anotações",
        hub_keep      = "Guardados",
        hub_runs      = "Masmorras",
        hub_loot      = "Saques",
        hub_alarms    = "Alarmes",
        hub_warnings  = "Avisos",
        hub_settings  = "Configurações",
        hub_simple    = "Estilo simples",
        hub_simple_tip = "Volta ao estilo simples: cada janela abre sozinha, como antes.",
        hub_summary   = "Resumo agora",
        hub_bar       = "Barra...",
        hub_appearance = "Aparência...",
        hub_foot      = "Clique num cartão para abrir a seção · tudo só leitura; nada é enviado",
        hub_session   = "Esta sessão",
        hub_session_t = "Esta sessão · %s",
        hub_gold      = "Ouro na sessão",
        hub_goldh     = "Ouro por hora",
        hub_xp        = "Experiência",
        hub_xph       = "XP por hora",
        hub_xpbar     = "XP %d%% do nível %d",
        hub_rested    = " · descansado +%d%%",
        hub_card_quests = "Missões",
        hub_card_tasks = "Tarefas e resets",
        hub_card_gear = "Equipamento e bolsas",
        hub_card_notes = "Anotações",
        hub_card_keep = "Itens guardados",
        hub_card_warn = "Avisos",
        hub_card_chars = "Personagens e profissões",
        hub_row_log   = "Diário",
        hub_row_done  = "Concluídas",
        hub_row_tasks = "Tarefas",
        hub_row_reset = "Resets",
        hub_row_durab = "Durabilidade",
        hub_row_bags  = "Bolsas",
        hub_row_junk  = "Lixo",
        hub_row_hearth = "Pedra de Regresso",
        hub_row_notes = "Pendentes",
        hub_row_keep  = "Guardados",
        hub_row_last  = "Último aviso",
        hub_row_none  = "nenhum aviso recente",
        hub_row_more  = "Os 10 últimos em Avisos",
        hub_row_gold  = "Ouro da conta (este reino)",
        hub_row_count = "Personagens anotados",
        hub_none      = "--",
        hub_chars_head = "Personagens deste reino (ouro e nível anotados ao sair)",
        hub_chars_empty = "Nenhum personagem anotado ainda: o ouro e o nível de cada um são anotados quando você sai do jogo.",
        hub_chars_row = "%s (%d)",
        hub_chars_you = " — você",
        hub_level     = "Nível %d",
        hub_profs_head = "Suas profissões (nível / limite do treinamento)",
        hub_profs_empty = "Nenhuma profissão encontrada.",
        hub_on        = "Central do Farol ligada (estilo detalhado): as janelas do Farol abrem dentro dela. /farol central off volta ao simples.",
        hub_off       = "estilo simples: cada janela do Farol abre sozinha, como antes.",
        hub_usage     = "uso: /farol central || /farol central on||off",
        opt_hub       = "Estilo detalhado (Central do Farol)",
        help_hub      = "  /farol central       - Central do Farol: todas as janelas num painel só (estilo detalhado)",
        news_hub      = "Central do Farol (estilo detalhado): um painel com barra lateral e um resumo em cartões; as janelas abrem dentro dela (/farol central)",
    },
    en = {
        hub_title     = "Farol",
        hub_home      = "Home",
        hub_chars     = "Characters",
        hub_goals     = "Goals",
        hub_quests    = "Quests",
        hub_profs     = "Professions",
        hub_tasks     = "Tasks",
        hub_notes     = "Notes",
        hub_keep      = "Kept items",
        hub_runs      = "Dungeons",
        hub_loot      = "Loot",
        hub_alarms    = "Alarms",
        hub_warnings  = "Warnings",
        hub_settings  = "Settings",
        hub_simple    = "Simple style",
        hub_simple_tip = "Back to the simple style: each window opens on its own, as before.",
        hub_summary   = "Summary now",
        hub_bar       = "Bar...",
        hub_appearance = "Appearance...",
        hub_foot      = "Click a card to open its section · read-only; nothing is sent",
        hub_session   = "This session",
        hub_session_t = "This session · %s",
        hub_gold      = "Session gold",
        hub_goldh     = "Gold per hour",
        hub_xp        = "Experience",
        hub_xph       = "XP per hour",
        hub_xpbar     = "XP %d%% of level %d",
        hub_rested    = " · rested +%d%%",
        hub_card_quests = "Quests",
        hub_card_tasks = "Tasks and resets",
        hub_card_gear = "Gear and bags",
        hub_card_notes = "Notes",
        hub_card_keep = "Kept items",
        hub_card_warn = "Warnings",
        hub_card_chars = "Characters and professions",
        hub_row_log   = "Quest log",
        hub_row_done  = "Completed",
        hub_row_tasks = "Tasks",
        hub_row_reset = "Resets",
        hub_row_durab = "Durability",
        hub_row_bags  = "Bags",
        hub_row_junk  = "Junk",
        hub_row_hearth = "Hearthstone",
        hub_row_notes = "Pending",
        hub_row_keep  = "Kept",
        hub_row_last  = "Last warning",
        hub_row_none  = "no recent warning",
        hub_row_more  = "The last 10 in Warnings",
        hub_row_gold  = "Account gold (this realm)",
        hub_row_count = "Characters noted",
        hub_none      = "--",
        hub_chars_head = "Characters on this realm (gold and level noted when you log out)",
        hub_chars_empty = "No characters noted yet: each one's gold and level are noted when you log out.",
        hub_chars_row = "%s (%d)",
        hub_chars_you = " — you",
        hub_level     = "Level %d",
        hub_profs_head = "Your professions (level / training limit)",
        hub_profs_empty = "No professions found.",
        hub_on        = "Farol hub on (detailed style): Farol windows open inside it. /farol hub off goes back to simple.",
        hub_off       = "simple style: each Farol window opens on its own, as before.",
        hub_usage     = "usage: /farol hub || /farol hub on||off",
        opt_hub       = "Detailed style (Farol hub)",
        help_hub      = "  /farol hub           - Farol hub: every window in one panel (detailed style)",
        news_hub      = "Farol hub (detailed style): one panel with a side bar and a summary in cards; the windows open inside it (/farol hub)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do ns.STRINGS[lang][key] = value end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function DB() return ns.GetDB and ns.GetDB() end

local function Fill(texture, r, g, b, a)
    if texture.SetColorTexture then texture:SetColorTexture(r, g, b, a) else texture:SetTexture(r, g, b, a) end
end

local function Num(value, low, high)
    if type(value) ~= "number" or value ~= value or value < low or value > high then return nil end
    if ns.IsSecret and ns.IsSecret(value) then return nil end
    return value
end

---------------------------------------------------------------------------
-- Seções (ordem da barra lateral). page = página própria; frame/open = janela de sempre, encaixada.
---------------------------------------------------------------------------

local SECTIONS = {
    { key = "home", icon = "Interface\\Icons\\INV_Misc_Map_01", page = true },
    { key = "chars", icon = "Interface\\Icons\\INV_Misc_Coin_01", page = true },
    { key = "goals", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", frame = "FarolGoals", open = function() ns.Goals.ToggleWindow() end },
    { key = "quests", icon = "Interface\\Icons\\INV_Misc_Book_08", frame = "FarolCompleted", open = function() ns.Completed.ToggleWindow() end },
    { key = "profs", icon = "Interface\\Icons\\Trade_Mining", page = true },
    { key = "tasks", icon = "Interface\\Icons\\INV_Scroll_03", frame = "FarolTasks", open = function() ns.Tasks.ToggleWindow() end },
    { key = "notes", icon = "Interface\\Icons\\INV_Misc_Note_02", frame = "FarolNotes", open = function() ns.Notes.ToggleWindow() end },
    { key = "keep", icon = "Interface\\Icons\\INV_Box_01", frame = "FarolKeep", open = function() ns.Keep.ToggleWindow() end },
    { key = "runs", icon = "Interface\\Icons\\INV_Misc_Key_03", frame = "FarolRuns", open = function() ns.Runs.ToggleWindow() end },
    { key = "loot", icon = "Interface\\Icons\\INV_Misc_Bag_10", frame = "FarolLoot", open = function() ns.Loot.ToggleWindow() end },
    { key = "alarms", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", frame = "FarolAlarms", open = function() ns.Alarm.ToggleWindow() end },
    { key = "warnings", icon = "Interface\\Icons\\INV_Misc_Note_06", frame = "FarolWarnHistory", open = function() ns.Warnings.ToggleHistory() end },
    { key = "settings", icon = "Interface\\Icons\\INV_Misc_Gear_01", frame = "FarolOptions", open = function() ns.OpenOptions("bar") end },
}
Hub.SECTIONS = SECTIONS
local BY_KEY, BY_FRAME = {}, {}
for _, section in ipairs(SECTIONS) do
    BY_KEY[section.key] = section
    if section.frame then BY_FRAME[section.frame] = section end
end

function Hub.Enabled()
    local db = DB()
    return db and db.hub == true or false
end

---------------------------------------------------------------------------
-- Encaixe das janelas de sempre
---------------------------------------------------------------------------

local hub            -- a janela da Central (criada na primeira vez)
local docked         -- janela encaixada agora
local current = "home"
local switching = false

local function FitScale(frame)
    local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
    local cw, ch = WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16
    if w <= 0 or h <= 0 then return 1 end
    return math.min(1, cw / w, ch / h)
end

local function Release(frame, hide)
    if not frame or not frame.farolDocked then return end
    frame.farolDocked = false
    local saved = frame.farolUndock or {}
    switching = true
    if hide then frame:Hide() end
    switching = false
    frame:SetParent(UIParent)
    if frame.SetScale then frame:SetScale(saved.scale or 1) end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER")
    frame:SetScript("OnDragStart", saved.dragStart)
    frame:SetScript("OnDragStop", saved.dragStop)
    if docked == frame then docked = nil end
end

local function Dock(frame)
    if not (hub and frame) or frame.farolDocked then return end
    frame.farolUndock = { scale = frame.GetScale and frame:GetScale() or 1,
        dragStart = frame:GetScript("OnDragStart"), dragStop = frame:GetScript("OnDragStop") }
    frame.farolDocked = true
    frame:SetParent(hub.content)
    if frame.SetScale then frame:SetScale(FitScale(frame)) end
    frame:ClearAllPoints()
    frame:SetPoint("TOP", hub.content, "TOP", 0, -2)
    if frame.SetFrameLevel and hub.content.GetFrameLevel then frame:SetFrameLevel(hub.content:GetFrameLevel() + 5) end
    -- Arrastar a janela encaixada move a Central inteira.
    frame:SetScript("OnDragStart", function() hub:StartMoving() end)
    frame:SetScript("OnDragStop", function() hub:StopMovingOrSizing() end)
    docked = frame
end

-- Chamada pelo ns.MakeToplevel de cada janela, uma vez, quando a janela é criada.
function Hub.Watch(frame)
    if not (frame and frame.GetName and frame.HookScript) then return end
    local name = frame:GetName()
    local section = name and BY_FRAME[name]
    if not section then return end
    frame:HookScript("OnShow", function(self)
        if switching or self.farolDocked or not Hub.Enabled() then return end
        Hub.Open(section.key)
    end)
    frame:HookScript("OnHide", function(self)
        if switching or not self.farolDocked then return end
        Release(self, false)
        if hub and hub:IsShown() then Hub.Select("home") end
    end)
end

---------------------------------------------------------------------------
-- Cartões e páginas
---------------------------------------------------------------------------

local function ItemText(key)
    local text = ns.ItemText and ns.ItemText(key)
    if type(text) ~= "string" or text == "" then return T("hub_none") end
    return text
end

-- Valor sem o rótulo da barra ("Dur 86%" -> "86%"); "raw" mantém o texto inteiro.
local function Value(key, raw)
    local text = ItemText(key)
    if raw or text == T("hub_none") then return text end
    local stripped = string.gsub(text, "^[^%d|%-+]*", "")
    return stripped ~= "" and stripped or text
end

local function Card(parent, x, y, w, h, titleKey, section, rows, leftW)
    leftW = leftW or 118
    local card = CreateFrame("Button", nil, parent, ns.backdropTemplate)
    card:SetSize(w, h)
    card:SetPoint("TOPLEFT", x, y)
    if card.SetBackdrop then
        card:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        card:SetBackdropColor(0.09, 0.075, 0.05, 0.95)
        if card.SetBackdropBorderColor then card:SetBackdropBorderColor(0.6, 0.47, 0.2, 1) end
    end
    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    card.title:SetPoint("TOPLEFT", 12, -10)
    card.titleKey = titleKey
    card.line = card:CreateTexture(nil, "ARTWORK")
    card.line:SetPoint("TOPLEFT", 10, -26)
    card.line:SetSize(w - 20, 1)
    Fill(card.line, 0.6, 0.47, 0.2, 0.5)
    card.rows = {}
    for i = 1, rows do
        local row = {}
        row.left = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.left:SetPoint("TOPLEFT", 12, -32 - (i - 1) * 18)
        row.left:SetJustifyH("LEFT")
        row.right = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.right:SetPoint("TOPRIGHT", -12, -32 - (i - 1) * 18)
        row.right:SetJustifyH("RIGHT")
        row.left:SetWidth(leftW)
        if row.left.SetWordWrap then row.left:SetWordWrap(false) end
        row.right:SetWidth(w - leftW - 30)
        if row.right.SetWordWrap then row.right:SetWordWrap(false) end
        card.rows[i] = row
    end
    card.section = section
    card:SetScript("OnClick", function(self) if self.section then Hub.Select(self.section) end end)
    card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    return card
end

local function SetRows(card, rows)
    card.title:SetText(T(card.titleKey))
    for i, row in ipairs(card.rows) do
        local data = rows[i]
        if data then
            row.left:SetText(data[1] or ""); row.right:SetText(data[2] or "")
            row.left:Show(); row.right:Show()
        else
            row.left:Hide(); row.right:Hide()
        end
    end
end

local function XPBar()
    if not (UnitXP and UnitXPMax and UnitLevel) then return nil end
    local okXP, xp = pcall(UnitXP, "player")
    local okMax, max = pcall(UnitXPMax, "player")
    local okLevel, level = pcall(UnitLevel, "player")
    xp, max = okXP and Num(xp, 0, 1e9), okMax and Num(max, 1, 1e9)
    level = okLevel and Num(level, 1, 100)
    if not (xp and max and level) then return nil end
    local rested = 0
    if GetXPExhaustion then
        local ok, value = pcall(GetXPExhaustion)
        rested = ok and Num(value, 0, 1e9) or 0
    end
    return math.min(1, xp / max), math.min(1, rested / max), level
end

local function BuildHome(page)
    local W = WIDTH - SIDE_W - 24
    local colW = math.floor((W - 24) / 3)
    page.hero = Card(page, 0, 0, W, 108, "hub_session", nil, 0)
    -- Quatro números grandes lado a lado: ouro, ouro/hora, XP, XP/hora.
    page.stats = {}
    for i = 1, 4 do
        local stat = {}
        local x = 12 + (i - 1) * math.floor((W - 24) / 4)
        stat.label = ns.Dim(page.hero:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        stat.label:SetPoint("TOPLEFT", x, -32)
        stat.value = page.hero:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        stat.value:SetPoint("TOPLEFT", x, -46)
        stat.value:SetWidth(math.floor((W - 24) / 4) - 8)
        stat.value:SetJustifyH("LEFT")
        if stat.value.SetWordWrap then stat.value:SetWordWrap(false) end
        page.stats[i] = stat
    end
    page.xpBack = page.hero:CreateTexture(nil, "ARTWORK")
    page.xpBack:SetPoint("TOPLEFT", 12, -74)
    page.xpBack:SetSize(W - 24, 10)
    Fill(page.xpBack, 0.12, 0.12, 0.12, 1)
    page.xpFill = page.hero:CreateTexture(nil, "OVERLAY")
    page.xpFill:SetPoint("TOPLEFT", page.xpBack, "TOPLEFT", 0, 0)
    page.xpFill:SetHeight(10)
    Fill(page.xpFill, 0.45, 0.3, 1, 1)
    page.xpRest = page.hero:CreateTexture(nil, "OVERLAY")
    page.xpRest:SetPoint("TOPLEFT", page.xpFill, "TOPRIGHT", 0, 0)
    page.xpRest:SetHeight(10)
    Fill(page.xpRest, 0.2, 0.35, 0.65, 1)
    page.xpText = ns.Dim(page.hero:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    page.xpText:SetPoint("TOPLEFT", page.xpBack, "BOTTOMLEFT", 0, -4)
    local y2, y3, y4 = -118, -226, -334
    page.cards = {
        Card(page, 0, y2, colW, 100, "hub_card_quests", "quests", 3),
        Card(page, colW + 12, y2, colW, 100, "hub_card_tasks", "tasks", 3),
        Card(page, 2 * (colW + 12), y2, colW, 100, "hub_card_gear", nil, 4),
        Card(page, 0, y3, colW, 100, "hub_card_notes", "notes", 3),
        Card(page, colW + 12, y3, colW, 100, "hub_card_keep", "keep", 3),
        Card(page, 2 * (colW + 12), y3, colW, 100, "hub_card_warn", "warnings", 3, colW - 90), -- o aviso ocupa a linha
    }
    page.chars = Card(page, 0, y4, W, 100, "hub_card_chars", "chars", 3, 240)
end

local function LastWarning()
    local list = type(FarolCharDB) == "table" and FarolCharDB.warnHistory
    local first = type(list) == "table" and list[1]
    if type(first) ~= "table" or type(first.text) ~= "string" then return nil end
    return first.text, ns.FormatWhen and ns.FormatWhen(first.t) or ""
end

local function RefreshHome(page)
    page.hero.title:SetText(string.format(T("hub_session_t"), Value("playtime")))
    local stats = { { "hub_gold", Value("session") }, { "hub_goldh", Value("goldh") }, { "hub_xp", Value("xp") }, { "hub_xph", Value("xph") } }
    for i, stat in ipairs(page.stats) do
        stat.label:SetText(T(stats[i][1])); stat.value:SetText(stats[i][2])
    end
    local filled, rested, level = XPBar()
    local W = WIDTH - SIDE_W - 48
    if filled then
        page.xpFill:SetWidth(math.max(1, W * filled))
        page.xpRest:SetWidth(math.max(1, W * math.min(rested, 1 - filled)))
        page.xpText:SetText(string.format(T("hub_xpbar"), math.floor(filled * 100), level)
            .. (rested > 0 and string.format(T("hub_rested"), math.floor(rested * 100)) or ""))
        page.xpFill:Show(); page.xpRest:Show()
    else
        page.xpFill:Hide(); page.xpRest:Hide(); page.xpText:SetText("")
    end
    local c = page.cards
    SetRows(c[1], { { T("hub_row_log"), Value("quests", true) }, { T("hub_row_done"), Value("qdone") } })
    SetRows(c[2], { { T("hub_row_tasks"), Value("tasks") }, { T("hub_row_reset"), Value("reset", true) } })
    SetRows(c[3], { { T("hub_row_durab"), Value("durab") }, { T("hub_row_bags"), Value("bags") },
        { T("hub_row_junk"), Value("junk") }, { T("hub_row_hearth"), Value("hearth", true) } })
    SetRows(c[4], { { T("hub_row_notes"), Value("notes") } })
    SetRows(c[5], { { T("hub_row_keep"), Value("keep") } })
    local text, when = LastWarning()
    SetRows(c[6], { { T("hub_row_last"), when or "" }, { text or ns.C.dim .. T("hub_row_none") .. "|r", "" }, { ns.C.dim .. T("hub_row_more") .. "|r", "" } })
    local list, total = nil, nil
    if ns.RealmCharacters then
        local ok, l, t = pcall(ns.RealmCharacters)
        if ok then list, total = l, t end
    end
    local profs = {}
    if ns.ReadProfessions then
        local ok, l = pcall(ns.ReadProfessions)
        if ok and type(l) == "table" then
            for i = 1, math.min(#l, 2) do
                local p = l[i]
                if type(p) == "table" and p.name then profs[#profs + 1] = p.name .. " " .. (p.level or 0) .. "/" .. (p.max or 0) end
            end
        end
    end
    SetRows(page.chars, {
        { T("hub_row_gold"), total and ns.FormatMoney and ns.FormatMoney(total) or T("hub_none") },
        { T("hub_row_count"), list and tostring(#list) or T("hub_none") },
        { T("hub_profs"), #profs > 0 and table.concat(profs, " · ") or T("hub_none") },
    })
end

local LIST_ROWS = 16

local function BuildList(page, headKey)
    page.head = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    page.head:SetPoint("TOPLEFT", 6, -4)
    page.headKey = headKey
    page.empty = ns.Dim(page:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    page.empty:SetPoint("TOPLEFT", 6, -30)
    page.empty:SetWidth(WIDTH - SIDE_W - 40)
    page.empty:SetJustifyH("LEFT")
    page.rows = {}
    for i = 1, LIST_ROWS do
        local row = {}
        local y = -30 - (i - 1) * 26
        row.left = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.left:SetPoint("TOPLEFT", 10, y)
        row.right = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.right:SetPoint("TOPRIGHT", -14, y)
        row.right:SetJustifyH("RIGHT")
        row.back = page:CreateTexture(nil, "BACKGROUND")
        row.back:SetPoint("TOPLEFT", 4, y + 4)
        row.back:SetSize(WIDTH - SIDE_W - 34, 22)
        Fill(row.back, 1, 1, 1, i % 2 == 0 and 0.03 or 0.06)
        row.bar = page:CreateTexture(nil, "ARTWORK")
        row.bar:SetPoint("TOPLEFT", 300, y - 4)
        row.bar:SetHeight(8)
        row.barBack = page:CreateTexture(nil, "BORDER")
        row.barBack:SetPoint("TOPLEFT", 300, y - 4)
        row.barBack:SetSize(260, 8)
        Fill(row.barBack, 0.15, 0.15, 0.15, 1)
        page.rows[i] = row
    end
end

local function ShowRows(page, data, emptyKey)
    page.head:SetText(T(page.headKey))
    if #data == 0 then page.empty:SetText(T(emptyKey)); page.empty:Show() else page.empty:Hide() end
    for i, row in ipairs(page.rows) do
        local d = data[i]
        if d then
            row.left:SetText(d[1]); row.right:SetText(d[2] or "")
            row.left:Show(); row.right:Show(); row.back:Show()
            if d.pct then
                row.bar:SetWidth(math.max(1, 260 * d.pct)); row.bar:Show(); row.barBack:Show()
                Fill(row.bar, d.pct >= 1 and 0.9 or 0.25, d.pct >= 1 and 0.55 or 0.7, 0.2, 1)
            else
                row.bar:Hide(); row.barBack:Hide()
            end
        else
            row.left:Hide(); row.right:Hide(); row.back:Hide(); row.bar:Hide(); row.barBack:Hide()
        end
    end
end

local function RefreshChars(page)
    local data = {}
    local list
    if ns.RealmCharacters then
        local ok, l = pcall(ns.RealmCharacters)
        if ok then list = l end
    end
    for i, c in ipairs(list or {}) do
        if i > LIST_ROWS then break end
        local name = string.format(T("hub_chars_row"), c.name, c.level or 0) .. (c.current and (ns.C.good .. T("hub_chars_you") .. "|r") or "")
        local when = c.t and ns.FormatWhen and (ns.C.dim .. ns.FormatWhen(c.t) .. "|r  ") or ""
        data[#data + 1] = { name, when .. (ns.FormatMoney and ns.FormatMoney(c.gold or 0) or tostring(c.gold or 0)) }
    end
    ShowRows(page, data, "hub_chars_empty")
end

local function RefreshProfs(page)
    local data = {}
    local list
    if ns.ReadProfessions then
        local ok, l = pcall(ns.ReadProfessions)
        if ok and type(l) == "table" then list = l end
    end
    for _, p in ipairs(list or {}) do
        if type(p) == "table" and p.name and #data < LIST_ROWS then
            local level, max = Num(p.level, 0, 1000) or 0, Num(p.max, 1, 1000) or 1
            local color = level >= max and ns.C.warn or ""
            data[#data + 1] = { p.name, color .. level .. " / " .. max .. (color ~= "" and "|r" or ""), pct = math.min(1, level / max) }
        end
    end
    ShowRows(page, data, "hub_profs_empty")
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if type(get) ~= "function" then return "" end
    local ok, value = pcall(get, "Farol", "Version")
    if ok and type(value) == "string" and #value <= 20 and not string.find(value, "|", 1, true) then return "v" .. value end
    return ""
end

local function CreateHub()
    local frame = CreateFrame("Frame", "FarolHub", UIParent, ns.backdropTemplate)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end
    -- Topo: faixa escura com o título; medalhão com o ícone do Farol no canto.
    frame.topBack = frame:CreateTexture(nil, "BORDER")
    frame.topBack:SetPoint("TOPLEFT", 12, -12)
    frame.topBack:SetPoint("TOPRIGHT", -12, -12)
    frame.topBack:SetHeight(TOP_H - 12)
    Fill(frame.topBack, 0.16, 0.12, 0.07, 0.95)
    frame.medal = frame:CreateTexture(nil, "OVERLAY")
    frame.medal:SetSize(64, 64)
    frame.medal:SetPoint("TOPLEFT", -14, 18)
    frame.medal:SetTexture(ns.ICON or "Interface\\Icons\\INV_Misc_Map_01")
    frame.medalRing = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.medalRing:SetSize(90, 90)
    frame.medalRing:SetPoint("CENTER", frame.medal, "CENTER", 13, -13)
    frame.medalRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -24)
    frame.version = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.version:SetPoint("TOPRIGHT", -300, -28)
    frame.lang = ns.CreateDropdown(frame, "FarolHubLang", 86, function()
        local db = DB() or {}
        local items = {}
        for _, entry in ipairs({ { "auto", "Auto" }, { "pt", "Português" }, { "en", "English" } }) do
            items[#items + 1] = { text = entry[2], checked = db.lang == entry[1], onClick = function() if ns.SetLang then ns.SetLang(entry[1]) end end }
        end
        return items
    end)
    frame.lang:SetPoint("TOPRIGHT", -196, -22)
    frame.simple = CreateFrame("Button", "FarolHubSimple", frame, "UIPanelButtonTemplate")
    frame.simple:SetSize(120, 22)
    frame.simple:SetPoint("TOPRIGHT", -40, -22)
    frame.simple:SetScript("OnClick", function() Hub.SetEnabled(false) end)
    frame.simple:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(T("hub_simple_tip"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.simple:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -16)

    -- Barra lateral.
    frame.sideBack = frame:CreateTexture(nil, "BORDER")
    frame.sideBack:SetPoint("TOPLEFT", 12, -TOP_H)
    frame.sideBack:SetSize(SIDE_W - 12, HEIGHT - TOP_H - FOOT_H - 8)
    Fill(frame.sideBack, 0.05, 0.045, 0.035, 0.95)
    frame.nav = {}
    for i, section in ipairs(SECTIONS) do
        local b = CreateFrame("Button", "FarolHubNav" .. section.key, frame)
        b:SetSize(SIDE_W - 28, 30)
        b:SetPoint("TOPLEFT", 20, -TOP_H - 14 - (i - 1) * 32)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        b.mark = b:CreateTexture(nil, "BACKGROUND")
        b.mark:SetAllPoints()
        Fill(b.mark, 0.45, 0.3, 0.08, 0.6)
        b.edge = b:CreateTexture(nil, "ARTWORK")
        b.edge:SetPoint("TOPLEFT"); b.edge:SetPoint("BOTTOMLEFT"); b.edge:SetWidth(3)
        Fill(b.edge, 1, 0.82, 0, 1)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(20, 20)
        b.icon:SetPoint("LEFT", 8, 0)
        b.icon:SetTexture(section.icon)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        b.text:SetPoint("LEFT", b.icon, "RIGHT", 10, 0)
        b.key = section.key
        b:SetScript("OnClick", function(self) Hub.Select(self.key) end)
        frame.nav[section.key] = b
    end
    frame.who = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.who:SetPoint("BOTTOMLEFT", 24, FOOT_H + 26)
    frame.whoInfo = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.whoInfo:SetPoint("TOPLEFT", frame.who, "BOTTOMLEFT", 0, -3)

    -- Área da direita: páginas próprias e janelas encaixadas.
    frame.content = CreateFrame("Frame", "FarolHubContent", frame)
    frame.content:SetPoint("TOPLEFT", SIDE_W + 12, -TOP_H - 8)
    frame.content:SetSize(WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16)
    frame.pages = {}
    frame.pages.home = CreateFrame("Frame", nil, frame.content)
    frame.pages.home:SetPoint("TOPLEFT", 0, 0)
    frame.pages.home:SetSize(WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16)
    BuildHome(frame.pages.home)
    frame.pages.chars = CreateFrame("Frame", nil, frame.content)
    frame.pages.chars:SetPoint("TOPLEFT", 0, 0)
    frame.pages.chars:SetSize(WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16)
    BuildList(frame.pages.chars, "hub_chars_head")
    frame.pages.profs = CreateFrame("Frame", nil, frame.content)
    frame.pages.profs:SetPoint("TOPLEFT", 0, 0)
    frame.pages.profs:SetSize(WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16)
    BuildList(frame.pages.profs, "hub_profs_head")

    -- Rodapé.
    frame.footBack = frame:CreateTexture(nil, "BORDER")
    frame.footBack:SetPoint("BOTTOMLEFT", 12, 12)
    frame.footBack:SetPoint("BOTTOMRIGHT", -12, 12)
    frame.footBack:SetHeight(FOOT_H - 8)
    Fill(frame.footBack, 0.06, 0.05, 0.035, 0.95)
    local function Foot(name, width, key, onClick, anchor)
        local b = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")
        b:SetSize(width, 22)
        if anchor then b:SetPoint("LEFT", anchor, "RIGHT", 6, 0) else b:SetPoint("BOTTOMLEFT", 20, 14) end
        b:SetScript("OnClick", onClick)
        b.key = key
        return b
    end
    frame.summary = Foot("FarolHubSummary", 130, "hub_summary", function() if ns.SummaryNow then ns.SummaryNow() end end)
    frame.barBtn = Foot("FarolHubBar", 100, "hub_bar", function() Hub.Select("settings") end, frame.summary)
    frame.appBtn = Foot("FarolHubAppearance", 120, "hub_appearance", function() if ns.Appearance then ns.Appearance.ToggleWindow() end end, frame.barBtn)
    frame.foot = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.foot:SetPoint("BOTTOMRIGHT", -24, 20)

    -- Atualiza a página Início uma vez por segundo enquanto a Central está aberta.
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + (tonumber(dt) or 0)
        if elapsed < 1 then return end
        elapsed = 0
        if current == "home" then pcall(RefreshHome, frame.pages.home) end
    end)
    frame:SetScript("OnShow", function() Hub.Refresh() end)
    frame:SetScript("OnHide", function() Release(docked, true) end)
    tinsert(UISpecialFrames, "FarolHub") -- Esc fecha
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:Hide()
    return frame
end

function Hub.Refresh()
    if not (hub and hub:IsShown()) then return end
    hub.title:SetText(T("hub_title"))
    hub.version:SetText(Version())
    local db = DB() or {}
    hub.lang:SetText(db.lang == "pt" and "Português" or db.lang == "en" and "English" or "Auto")
    hub.simple:SetText(T("hub_simple"))
    for _, section in ipairs(SECTIONS) do
        local b = hub.nav[section.key]
        b.text:SetText(T("hub_" .. section.key))
        local on = section.key == current
        if on then b.mark:Show(); b.edge:Show() else b.mark:Hide(); b.edge:Hide() end
        b.text:SetFontObject(on and "GameFontNormal" or "GameFontHighlight")
    end
    local name, realm = nil, nil
    if ns.CurrentCharacter then
        local ok, n, r = pcall(ns.CurrentCharacter)
        if ok then name, realm = n, r end
    end
    hub.who:SetText(name or "")
    local level
    if UnitLevel then
        local ok, value = pcall(UnitLevel, "player")
        level = ok and Num(value, 1, 100)
    end
    hub.whoInfo:SetText(level and string.format(T("hub_level"), level) or "")
    for _, b in ipairs({ hub.summary, hub.barBtn, hub.appBtn }) do b:SetText(T(b.key)) end
    hub.foot:SetText(T("hub_foot"))
    for key, page in pairs(hub.pages) do
        if key == current then page:Show() else page:Hide() end
    end
    if current == "home" then pcall(RefreshHome, hub.pages.home)
    elseif current == "chars" then pcall(RefreshChars, hub.pages.chars)
    elseif current == "profs" then pcall(RefreshProfs, hub.pages.profs) end
end

-- Mostra uma seção: página própria ou a janela de sempre encaixada.
function Hub.Select(key)
    local section = BY_KEY[key]
    if not section or not hub then return end
    if docked and (not section.frame or docked:GetName() ~= section.frame) then Release(docked, true) end
    current = key
    if section.frame then
        local frame = _G[section.frame]
        switching = true
        if not (frame and frame:IsShown()) then pcall(section.open) end
        frame = _G[section.frame]
        if frame and not frame:IsShown() then pcall(section.open) end -- o toggle fechou: abre de novo
        switching = false
        frame = _G[section.frame]
        if frame and frame:IsShown() then Dock(frame) end
    end
    Hub.Refresh()
end

function Hub.Open(key)
    if not DB() then return end
    hub = hub or CreateHub()
    if not hub:IsShown() then hub:Show() end
    Hub.Select(key or "home")
end

function Hub.Toggle()
    if hub and hub:IsShown() then hub:Hide() else Hub.Open("home") end
end

function Hub.SetEnabled(value)
    local db = DB()
    if not db then return end
    db.hub = value and true or false
    if db.hub then
        Print(T("hub_on"))
        -- Uma janela do Farol já aberta (ex.: o menu onde a opção foi ligada) entra na Central.
        local open = "home"
        for _, section in ipairs(SECTIONS) do
            local frame = section.frame and _G[section.frame]
            if frame and frame:IsShown() then open = section.key break end
        end
        Hub.Open(open)
    else
        if hub and hub:IsShown() then hub:Hide() end
        Print(T("hub_off"))
    end
    if ns.RefreshOptions then ns.RefreshOptions() end
end

local SWITCH = { on = true, ligar = true, ligado = true, sim = true, off = false, desligar = false, desligado = false, nao = false,
    simples = false, simple = false, detalhado = true, detailed = true }

function Hub.HandleCommand(rest)
    local word = string.lower(string.match(rest or "", "^%s*(%a*)") or "")
    if word == "" then
        if Hub.Enabled() then Hub.Toggle() else Hub.SetEnabled(true) end
        return
    end
    local value = SWITCH[word]
    if value == nil then Print(T("hub_usage")) else Hub.SetEnabled(value) end
end
