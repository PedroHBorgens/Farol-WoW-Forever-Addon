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
        hub_row_reset = "Resets", hub_row_daily = "Reset diário", hub_row_weekly = "Reset semanal",
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
        hub_rank1 = "Aprendiz", hub_rank2 = "Artífice", hub_rank3 = "Perito", hub_rank4 = "Artesão", hub_rank5 = "Mestre",
        hub_limit     = "seu limite %d",
        hub_at_limit  = "no limite",
        hub_to_limit  = "faltam %d para o limite",
        hub_this_session = "Nesta sessão",
        hub_next_step = "Próximo passo",
        hub_train     = "procure um instrutor para treinar %s",
        hub_points    = "pontos",
        hub_per_hour  = "~%d por hora",
        hub_no_change = "sem mudança",
        hub_chars_title = "Personagens deste reino",
        hub_col_char  = "PERSONAGEM", hub_col_level = "NÍVEL", hub_col_gold = "OURO", hub_col_rest = "DESCANSO",
        hub_col_bind  = "PEDRA DE REGRESSO", hub_col_seen = "VISTO",
        hub_now       = "agora",
        hub_rest_full = "cheio (%d%%)",
        hub_locks_title = "Instâncias salvas",
        hub_locks_none = "nenhuma instância salva anotada",
        hub_bosses    = "%d de %d chefes",
        hub_resets_in = "reseta em %s",
        hub_rest_title = "Descanso",
        hub_rest_note = "estimado pelas regras do estilo clássico",
        hub_rest_ready = "descanso cheio: pronto para upar",
        hub_rest_eta  = "%d%% · cheio em ~%s",
        hub_rest_none = "nenhum outro personagem com descanso anotado",
        hub_profs_head = "Suas profissões (nível / limite do treinamento)",
        hub_profs_empty = "Nenhuma profissão encontrada.",
        hub_on        = "Central do Farol ligada (estilo detalhado): as janelas do Farol abrem dentro dela. /farol central off volta ao simples.",
        hub_off       = "estilo simples: cada janela do Farol abre sozinha, como antes.",
        hub_usage     = "uso: /farol central || /farol central on||off || /farol central tamanho 70-130",
        hub_size_tip  = "Arraste para aumentar ou diminuir a Central (agora: %d%%). Duplo clique volta a 100%%.",
        hub_size_set  = "tamanho da Central: %d%%.",
        hub_size_usage = "uso: /farol central tamanho 70-130 (porcentagem; 100 = normal)",
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
        hub_row_reset = "Resets", hub_row_daily = "Daily reset", hub_row_weekly = "Weekly reset",
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
        hub_rank1 = "Apprentice", hub_rank2 = "Journeyman", hub_rank3 = "Expert", hub_rank4 = "Artisan", hub_rank5 = "Master",
        hub_limit     = "your limit %d",
        hub_at_limit  = "at the limit",
        hub_to_limit  = "%d to the limit",
        hub_this_session = "This session",
        hub_next_step = "Next step",
        hub_train     = "find a trainer to learn %s",
        hub_points    = "points",
        hub_per_hour  = "~%d per hour",
        hub_no_change = "no change",
        hub_chars_title = "Characters on this realm",
        hub_col_char  = "CHARACTER", hub_col_level = "LEVEL", hub_col_gold = "GOLD", hub_col_rest = "RESTED",
        hub_col_bind  = "HEARTHSTONE", hub_col_seen = "SEEN",
        hub_now       = "now",
        hub_rest_full = "full (%d%%)",
        hub_locks_title = "Saved instances",
        hub_locks_none = "no saved instances noted",
        hub_bosses    = "%d of %d bosses",
        hub_resets_in = "resets in %s",
        hub_rest_title = "Rested XP",
        hub_rest_note = "estimated with the classic-style rules",
        hub_rest_ready = "fully rested: ready to level",
        hub_rest_eta  = "%d%% · full in ~%s",
        hub_rest_none = "no other character with rested XP noted",
        hub_profs_head = "Your professions (level / training limit)",
        hub_profs_empty = "No professions found.",
        hub_on        = "Farol hub on (detailed style): Farol windows open inside it. /farol hub off goes back to simple.",
        hub_off       = "simple style: each Farol window opens on its own, as before.",
        hub_usage     = "usage: /farol hub || /farol hub on||off || /farol hub size 70-130",
        hub_size_tip  = "Drag to make the hub bigger or smaller (now: %d%%). Double-click goes back to 100%%.",
        hub_size_set  = "hub size: %d%%.",
        hub_size_usage = "usage: /farol hub size 70-130 (percent; 100 = normal)",
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

-- Janelas com layout de cartões (3.29): ao entrar na Central, perdem a moldura de diálogo (a Central já tem a dela)
-- e chamam frame.farolDetail(true), que reorganiza tudo em painéis; ao sair, voltam exatamente como eram.
local function Skin(frame, on)
    if frame.SetBackdropColor then frame:SetBackdropColor(1, 1, 1, on and 0 or 1) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(1, 1, 1, on and 0 or 1) end
    if frame.farolBacking then if on then frame.farolBacking:Hide() else frame.farolBacking:Show() end end
    if frame.title then if on then frame.title:Hide() else frame.title:Show() end end
end

local function Release(frame, hide)
    if not frame or not frame.farolDocked then return end
    frame.farolDocked = false
    local saved = frame.farolUndock or {}
    if frame.farolClose then frame.farolClose:Show() end
    if frame.farolDetail then
        Skin(frame, false)
        if saved.w and saved.h then frame:SetSize(saved.w, saved.h) end
        pcall(frame.farolDetail, false)
    end
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
    if frame.farolClose then frame.farolClose:Hide() end -- o X da Central fecha tudo; o de dentro cobria os subtítulos
    if frame.farolDetail then
        frame.farolUndock.w, frame.farolUndock.h = frame:GetWidth(), frame:GetHeight()
        if frame.farolDetailSize then frame:SetSize(frame.farolDetailSize[1], frame.farolDetailSize[2]) end
        Skin(frame, true)
        pcall(frame.farolDetail, true)
    end
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
        -- A janela ainda "mostrada" (IsShown) só sumiu porque a Central fechou: fecha junto (3.31.2). Sem isso, ao
        -- se soltar ela continuava aberta sozinha no meio da tela, e parecia que o X da Central não funcionava.
        if self:IsShown() then Release(self, true) return end
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
    card.farolW = w
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

-- Rótulo à esquerda + valor à direita numa linha (3.31.2): o rótulo ocupa só o que precisa e o valor fica com o
-- resto da largura; assim um valor comprido não é cortado só porque a coluna do rótulo tinha largura fixa.
local function FitPair(left, right, total, pad)
    if type(total) ~= "number" or total <= 0 then return end
    pad = pad or 24
    local lw = 0
    if left:GetText() and left:GetText() ~= "" and left.GetStringWidth then
        local ok, w = pcall(left.GetStringWidth, left)
        if ok and type(w) == "number" and w == w then lw = math.ceil(w) end
    end
    local rightText = right:GetText()
    if not rightText or rightText == "" then lw = total - pad end -- só o rótulo: usa a linha toda
    lw = math.max(0, math.min(math.ceil(lw * 1.12) + 6, total - pad)) -- folga: no jogo a fonte pode sair mais larga
    left:SetWidth(math.max(1, lw))
    right:SetWidth(math.max(1, total - pad - lw - 10))
end

local function SetRows(card, rows)
    card.title:SetText(T(card.titleKey))
    for i, row in ipairs(card.rows) do
        local data = rows[i]
        if data then
            row.left:SetText(data[1] or ""); row.right:SetText(data[2] or "")
            row.left:Show(); row.right:Show()
            FitPair(row.left, row.right, card.farolW or card:GetWidth())
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
    -- Resets em duas linhas (3.31.2): "Diário 5h 12m · Semanal 2d 4h" numa linha só não cabia no cartão.
    local daily, weekly
    if ns.GetResetTimes then
        local ok, d, w = pcall(ns.GetResetTimes)
        if ok then daily, weekly = d, w end
    end
    SetRows(c[2], { { T("hub_row_tasks"), Value("tasks") },
        { T("hub_row_daily"), type(daily) == "number" and (ns.FormatCountdown and ns.FormatCountdown(daily) or tostring(daily)) or "--" },
        { T("hub_row_weekly"), type(weekly) == "number" and (ns.FormatCountdown and ns.FormatCountdown(weekly) or tostring(weekly)) or "--" } })
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

---------------------------------------------------------------------------
-- Kit de estilo do modo detalhado (3.28): cartão com título e "subtítulo" à direita, trilha de progresso com marcas.
-- As próximas versões usam o mesmo kit nas outras telas da Central.
---------------------------------------------------------------------------

local Kit = {}
Hub.Kit = Kit

function Kit.Card(parent, x, y, w, h)
    local card = CreateFrame("Frame", nil, parent, ns.backdropTemplate)
    card:SetSize(w, h)
    card:SetPoint("TOPLEFT", x, y)
    if card.SetBackdrop then
        card:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        card:SetBackdropColor(0.09, 0.075, 0.05, 0.95)
        if card.SetBackdropBorderColor then card:SetBackdropBorderColor(0.6, 0.47, 0.2, 1) end
    end
    card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    card.title:SetPoint("TOPLEFT", 12, -10)
    card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.badge:SetPoint("LEFT", card.title, "RIGHT", 10, 0)
    card.sub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    card.sub:SetPoint("TOPRIGHT", -12, -12)
    card.sub:SetJustifyH("RIGHT")
    return card
end

-- Painel desenhado com texturas no próprio quadro (fundo + borda dourada + título + subtítulo): como fica atrás
-- dos textos e botões da janela, serve para "vestir" as janelas de sempre quando entram na Central.
function Kit.Panel(frame, key, x, y, w, h)
    frame.farolPanels = frame.farolPanels or {}
    local p = frame.farolPanels[key]
    if not p then
        p = { parts = {} }
        local function Tex(layer, r, g, b, a)
            local t = frame:CreateTexture(nil, layer); Fill(t, r, g, b, a); p.parts[#p.parts + 1] = t; return t
        end
        p.bg = Tex("BACKGROUND", 0.09, 0.075, 0.05, 0.95)
        p.top = Tex("BORDER", 0.6, 0.47, 0.2, 1); p.bottom = Tex("BORDER", 0.6, 0.47, 0.2, 1)
        p.left = Tex("BORDER", 0.6, 0.47, 0.2, 1); p.right = Tex("BORDER", 0.6, 0.47, 0.2, 1)
        p.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); p.parts[#p.parts + 1] = p.title
        p.sub = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")); p.parts[#p.parts + 1] = p.sub
        p.sub:SetJustifyH("RIGHT")
        frame.farolPanels[key] = p
    end
    p.bg:ClearAllPoints(); p.bg:SetPoint("TOPLEFT", x, y); p.bg:SetSize(w, h)
    p.top:ClearAllPoints(); p.top:SetPoint("TOPLEFT", x, y); p.top:SetSize(w, 1)
    p.bottom:ClearAllPoints(); p.bottom:SetPoint("TOPLEFT", x, y - h + 1); p.bottom:SetSize(w, 1)
    p.left:ClearAllPoints(); p.left:SetPoint("TOPLEFT", x, y); p.left:SetSize(1, h)
    p.right:ClearAllPoints(); p.right:SetPoint("TOPLEFT", x + w - 1, y); p.right:SetSize(1, h)
    p.title:ClearAllPoints(); p.title:SetPoint("TOPLEFT", x + 12, y - 9)
    p.sub:ClearAllPoints(); p.sub:SetPoint("TOPRIGHT", frame, "TOPLEFT", x + w - 12, y - 12)
    return p
end

function Kit.ShowPanels(frame, on)
    for _, p in pairs(frame.farolPanels or {}) do
        for _, part in ipairs(p.parts) do if on then part:Show() else part:Hide() end end
    end
end

-- Barrinha de progresso feita de texturas (fundo + parte cheia), presa a um painel.
function Kit.Bar(frame, key)
    frame.farolBars = frame.farolBars or {}
    local b = frame.farolBars[key]
    if not b then
        b = { back = frame:CreateTexture(nil, "BORDER"), fill = frame:CreateTexture(nil, "ARTWORK") }
        Fill(b.back, 0.12, 0.12, 0.12, 1); Fill(b.fill, 1, 0.82, 0.2, 1)
        frame.farolBars[key] = b
    end
    return b
end

function Kit.SetBar(b, x, y, w, pct, on, r, g, bl)
    if r then Fill(b.fill, r, g, bl, 1) end
    b.back:ClearAllPoints(); b.back:SetPoint("TOPLEFT", x, y); b.back:SetSize(w, 6)
    b.fill:ClearAllPoints(); b.fill:SetPoint("TOPLEFT", x, y); b.fill:SetSize(math.max(1, w * math.max(0, math.min(1, pct or 0))), 6)
    if on then b.back:Show(); b.fill:Show() else b.back:Hide(); b.fill:Hide() end
end

Kit.FitPair = FitPair

-- Texto solto de um painel (some junto com os painéis fora da Central). justify: "LEFT" (padrão) ou "RIGHT".
function Kit.Text(frame, key, template, x, y, w, justify)
    frame.farolPanels = frame.farolPanels or {}
    local p = frame.farolPanels["text:" .. key]
    if not p then
        local fs = frame:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
        if fs.SetWordWrap then fs:SetWordWrap(false) end
        p = { parts = { fs }, fs = fs }
        frame.farolPanels["text:" .. key] = p
    end
    local fs = p.fs
    fs:ClearAllPoints()
    fs:SetWidth(w or 200)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetPoint("TOPLEFT", x, y)
    fs:Show()
    return fs
end

-- Número em destaque com o rótulo pequeno em cima ("Você tem" / "123g 45s").
function Kit.Stat(frame, key, x, y, w, label, value)
    ns.Dim(Kit.Text(frame, key .. ".l", "GameFontHighlightSmall", x, y, w)):SetText(label or "")
    Kit.Text(frame, key .. ".v", "GameFontHighlightLarge", x, y - 14, w):SetText(value or "--")
end

function Kit.Line(card, y, w)
    local line = {}
    line.left = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.left:SetPoint("TOPLEFT", 12, y)
    line.right = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line.right:SetPoint("TOPRIGHT", -12, y)
    line.right:SetJustifyH("RIGHT")
    line.right:SetWidth(w - 160)
    if line.right.SetWordWrap then line.right:SetWordWrap(false) end
    return line
end

-- Trilha 0..cap com marcas (ex.: 75/150/225/300), o que já havia (verde), o que subiu (dourado) e o limite (laranja).
function Kit.Track(card, x, y, w)
    local t = { x = x, w = w, ticks = {}, labels = {} }
    t.back = card:CreateTexture(nil, "BORDER"); t.back:SetPoint("TOPLEFT", x, y); t.back:SetSize(w, 12)
    Fill(t.back, 0.1, 0.1, 0.1, 1)
    t.base = card:CreateTexture(nil, "ARTWORK"); t.base:SetPoint("TOPLEFT", x, y); t.base:SetHeight(12)
    Fill(t.base, 0.25, 0.7, 0.25, 1)
    t.gain = card:CreateTexture(nil, "ARTWORK"); t.gain:SetPoint("TOPLEFT", t.base, "TOPRIGHT", 0, 0); t.gain:SetHeight(12)
    Fill(t.gain, 1, 0.82, 0.2, 1)
    t.limit = card:CreateTexture(nil, "OVERLAY"); t.limit:SetSize(3, 20)
    Fill(t.limit, 1, 0.54, 0.2, 1)
    t.limitText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.y = y
    for i = 1, 5 do
        t.ticks[i] = card:CreateTexture(nil, "OVERLAY"); t.ticks[i]:SetSize(2, 16); Fill(t.ticks[i], 0.8, 0.64, 0.3, 1)
        t.labels[i] = ns.Dim(card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    end
    return t
end

function Kit.SetTrack(t, start, level, limit, marks, names)
    local cap = marks[#marks]
    local function X(v) return t.x + math.max(0, math.min(1, v / cap)) * t.w end
    t.base:SetWidth(math.max(1, X(start) - t.x))
    local gain = X(level) - X(start)
    if gain >= 1 then t.gain:SetWidth(gain); t.gain:Show() else t.gain:Hide() end
    t.limit:ClearAllPoints(); t.limit:SetPoint("TOP", t.back, "TOPLEFT", X(limit) - t.x, 4)
    t.limitText:ClearAllPoints(); t.limitText:SetPoint("BOTTOM", t.limit, "TOP", 0, 1)
    t.limitText:SetText(string.format(T("hub_limit"), limit))
    for i = 1, 5 do
        local v = marks[i]
        if v then
            t.ticks[i]:ClearAllPoints(); t.ticks[i]:SetPoint("TOP", t.back, "TOPLEFT", X(v) - t.x, 2)
            t.labels[i]:ClearAllPoints(); t.labels[i]:SetPoint("TOP", t.ticks[i], "BOTTOM", 0, -1)
            t.labels[i]:SetText(v .. " · " .. (names[i] or ""))
            t.ticks[i]:Show(); t.labels[i]:Show()
        else
            t.ticks[i]:Hide(); t.labels[i]:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- Página Profissões (3.28): um cartão por profissão com a trilha 75/150/225/300, o limite e o ganho da sessão.
---------------------------------------------------------------------------

local PROF_CARDS = 5
local profStart = {} -- [nome] = nível na primeira leitura desta sessão (só na memória)

local function ReadProfs()
    if not ns.ReadProfessions then return {} end
    local ok, list = pcall(ns.ReadProfessions)
    if not ok or type(list) ~= "table" then return {} end
    local out = {}
    for _, p in ipairs(list) do
        if type(p) == "table" and type(p.name) == "string" then
            local level, max = Num(p.level, 0, 1000), Num(p.max, 1, 1000)
            if level and max then
                out[#out + 1] = { name = p.name, level = level, max = max }
                if profStart[p.name] == nil or profStart[p.name] > level then profStart[p.name] = level end
            end
        end
    end
    return out
end
Hub.ReadProfs = ReadProfs

local RANKS = { 75, 150, 225, 300, 375 }
local function RankIndex(max)
    for i, v in ipairs(RANKS) do if max <= v then return i end end
    return #RANKS
end

local function BuildProfs(page)
    local W = WIDTH - SIDE_W - 24
    page.cards = {}
    for i = 1, PROF_CARDS do
        local card = Kit.Card(page, 0, -(i - 1) * 100, W, 94)
        card.track = Kit.Track(card, 20, -48, W - 110) -- folga para o rótulo da última marca
        card.session = Kit.Line(card, -76, W)
        page.cards[i] = card
    end
    page.empty = ns.Dim(page:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    page.empty:SetPoint("TOPLEFT", 6, -6)
end

local function RefreshProfs(page)
    local list = ReadProfs()
    if #list == 0 then page.empty:SetText(T("hub_profs_empty")); page.empty:Show() else page.empty:Hide() end
    local seconds = ns.GetSessionSeconds and ns.GetSessionSeconds() or 0
    for i, card in ipairs(page.cards) do
        local p = list[i]
        if p then
            local rank = RankIndex(p.max)
            local marks, names = {}, {}
            local top = math.max(4, rank)
            for r = 1, top do marks[r] = RANKS[r]; names[r] = T("hub_rank" .. r) end
            card.title:SetText(p.name)
            card.badge:SetText("[" .. T("hub_rank" .. rank) .. "]")
            local left = p.max - p.level
            local sub = p.level .. " / " .. p.max
            if left == 0 then sub = sub .. " · " .. ns.C.warn .. T("hub_at_limit") .. "|r"
            elseif left <= 15 then sub = sub .. " · " .. ns.C.warn .. string.format(T("hub_to_limit"), left) .. "|r" end
            card.sub:SetText(sub)
            local start = math.min(profStart[p.name] or p.level, p.level)
            Kit.SetTrack(card.track, start, p.level, p.max, marks, names)
            local gain = p.level - start
            card.session.left:SetText(left == 0 and rank < #RANKS and T("hub_next_step") or T("hub_this_session"))
            if left == 0 and rank < #RANKS then
                card.session.right:SetText(ns.C.warn .. string.format(T("hub_train"), T("hub_rank" .. (rank + 1))) .. "|r")
            elseif gain > 0 then
                local text = ns.C.good .. "+" .. gain .. "|r " .. T("hub_points")
                if seconds >= 600 then text = text .. " · " .. string.format(T("hub_per_hour"), math.floor(gain * 3600 / seconds + 0.5)) end
                card.session.right:SetText(text)
            else
                card.session.right:SetText(ns.C.dim .. T("hub_no_change") .. "|r")
            end
            card:Show()
        else
            card:Hide()
        end
    end
end

---------------------------------------------------------------------------
-- Página Personagens (3.28): tabela do reino + instâncias salvas + descanso.
---------------------------------------------------------------------------

local CHAR_ROWS = 8
local COLS = { 12, 212, 258, 362, 476, 650 } -- personagem, nível, ouro, descanso, Pedra, visto (3.31.2: "Hoje 07:49" cabe)

local function BuildChars(page)
    local W = WIDTH - SIDE_W - 24
    page.table = Kit.Card(page, 0, 0, W, 60 + CHAR_ROWS * 24)
    page.heads = {}
    for i, x in ipairs(COLS) do
        local h = page.table:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("TOPLEFT", x, -36)
        page.heads[i] = h
    end
    page.rows = {}
    for r = 1, CHAR_ROWS do
        local y = -54 - (r - 1) * 24
        local row = { cells = {} }
        row.back = page.table:CreateTexture(nil, "BORDER")
        row.back:SetPoint("TOPLEFT", 6, y + 3); row.back:SetSize(W - 12, 22)
        Fill(row.back, 1, 1, 1, r % 2 == 0 and 0.03 or 0.06)
        for i, x in ipairs(COLS) do
            local c = page.table:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            c:SetPoint("TOPLEFT", x, y)
            c:SetWidth((COLS[i + 1] or (W - 10)) - x - 8); c:SetJustifyH("LEFT")
            if c.SetWordWrap then c:SetWordWrap(false) end
            row.cells[i] = c
        end
        row.restBack = page.table:CreateTexture(nil, "ARTWORK")
        row.restBack:SetPoint("TOPLEFT", COLS[4], y - 14); row.restBack:SetSize(110, 4)
        Fill(row.restBack, 0.15, 0.15, 0.15, 1)
        row.restFill = page.table:CreateTexture(nil, "OVERLAY")
        row.restFill:SetPoint("TOPLEFT", row.restBack, "TOPLEFT", 0, 0); row.restFill:SetHeight(4)
        page.rows[r] = row
    end
    local y2 = -(60 + CHAR_ROWS * 24) - 10
    page.locks = Kit.Card(page, 0, y2, W, 86)
    page.lockLines = { Kit.Line(page.locks, -34, W), Kit.Line(page.locks, -52, W), Kit.Line(page.locks, -70, W) }
    page.rest = Kit.Card(page, 0, y2 - 96, W, 68)
    page.restLines = { Kit.Line(page.rest, -34, W), Kit.Line(page.rest, -52, W) }
    page.empty = ns.Dim(page.table:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    page.empty:SetPoint("TOPLEFT", 12, -56); page.empty:SetWidth(W - 30); page.empty:SetJustifyH("LEFT")
end

local function Duration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if seconds >= 86400 then return string.format("%dd %dh", math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600)) end
    return ns.FormatDuration and ns.FormatDuration(seconds) or tostring(seconds)
end

local function RefreshChars(page)
    local list, total
    if ns.CharDetails then
        local ok, l, t = pcall(ns.CharDetails)
        if ok then list, total = l, t end
    end
    list = list or {}
    page.table.title:SetText(T("hub_chars_title"))
    page.table.sub:SetText(total and (T("hub_row_gold") .. ": " .. (ns.FormatMoney and ns.FormatMoney(total) or total)) or "")
    for i, key in ipairs({ "hub_col_char", "hub_col_level", "hub_col_gold", "hub_col_rest", "hub_col_bind", "hub_col_seen" }) do
        page.heads[i]:SetText(T(key))
    end
    if #list == 0 then page.empty:SetText(T("hub_chars_empty")); page.empty:Show() else page.empty:Hide() end
    for r, row in ipairs(page.rows) do
        local c = list[r]
        if c then
            local cells = row.cells
            cells[1]:SetText(c.current and (ns.C.warn .. c.name .. T("hub_chars_you") .. "|r") or c.name)
            cells[2]:SetText(tostring(c.level or "--"))
            cells[3]:SetText(ns.FormatMoney and ns.FormatMoney(c.gold or 0) or tostring(c.gold or 0))
            if c.pct then
                cells[4]:SetText(c.full and (ns.C.good .. string.format(T("hub_rest_full"), c.pct) .. "|r") or (c.pct .. "%"))
                row.restFill:SetWidth(math.max(1, 110 * math.min(1, c.pct / 150)))
                Fill(row.restFill, c.full and 0.25 or 0.3, c.full and 0.75 or 0.44, c.full and 0.25 or 0.72, 1)
                row.restBack:Show(); row.restFill:Show()
            else
                cells[4]:SetText("--"); row.restBack:Hide(); row.restFill:Hide()
            end
            cells[5]:SetText(c.bind or "--")
            cells[6]:SetText(c.current and T("hub_now") or (c.t and ns.FormatWhen and ns.FormatWhen(c.t) or "--"))
            for _, cell in ipairs(cells) do cell:Show() end
            row.back:Show()
        else
            for _, cell in ipairs(row.cells) do cell:Hide() end
            row.back:Hide(); row.restBack:Hide(); row.restFill:Hide()
        end
    end
    -- Instâncias salvas (as que ainda não resetaram).
    page.locks.title:SetText(T("hub_locks_title"))
    local locks = {}
    for _, c in ipairs(list) do
        for _, l in ipairs(c.locks or {}) do locks[#locks + 1] = { c.name, l } end
    end
    for i, line in ipairs(page.lockLines) do
        local item = locks[i]
        if item then
            local l = item[2]
            line.left:SetText(item[1] .. " — " .. (l.n or ""))
            local bosses = (l.k and l.b) and (string.format(T("hub_bosses"), l.k, l.b) .. " · ") or ""
            line.right:SetText(bosses .. string.format(T("hub_resets_in"), Duration(l.left)))
        else
            line.left:SetText(i == 1 and (ns.C.dim .. T("hub_locks_none") .. "|r") or ""); line.right:SetText("")
        end
    end
    for _, line in ipairs(page.lockLines) do FitPair(line.left, line.right, page.locks:GetWidth()) end
    -- Descanso dos outros personagens.
    page.rest.title:SetText(T("hub_rest_title"))
    page.rest.sub:SetText(ns.C.dim .. T("hub_rest_note") .. "|r")
    local rests = {}
    for _, c in ipairs(list) do
        if not c.current and c.pct then rests[#rests + 1] = c end
    end
    table.sort(rests, function(a, b) return a.pct > b.pct end)
    for i, line in ipairs(page.restLines) do
        local c = rests[i]
        if c then
            line.left:SetText(c.name .. " (" .. (c.level or "?") .. ")")
            line.right:SetText(c.full and (ns.C.good .. T("hub_rest_ready") .. "|r")
                or string.format(T("hub_rest_eta"), c.pct, Duration(c.eta)))
        else
            line.left:SetText(i == 1 and (ns.C.dim .. T("hub_rest_none") .. "|r") or ""); line.right:SetText("")
        end
        FitPair(line.left, line.right, page.rest:GetWidth())
    end
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
    -- Fundo opaco (3.31): o fundo de diálogo do jogo é translúcido e deixava ver o mundo (e nomes) por trás.
    frame.backing = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    frame.backing:SetPoint("TOPLEFT", 10, -10)
    frame.backing:SetPoint("BOTTOMRIGHT", -10, 10)
    Fill(frame.backing, 0.06, 0.05, 0.04, 1)
    -- Topo: faixa escura com o ícone e o título.
    frame.topBack = frame:CreateTexture(nil, "BORDER")
    frame.topBack:SetPoint("TOPLEFT", 12, -12)
    frame.topBack:SetPoint("TOPRIGHT", -12, -12)
    frame.topBack:SetHeight(TOP_H - 12)
    Fill(frame.topBack, 0.16, 0.12, 0.07, 0.95)
    -- Ícone do Farol (3.31.1): quadrado, no canto de cima à esquerda, na mesma linha do título "Farol". Os dois se
    -- prendem ao centro vertical da faixa de cima, então ficam sempre alinhados (sem anel nem recorte).
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("CENTER", frame.topBack, "CENTER", 0, 0)
    frame.medal = frame:CreateTexture(nil, "OVERLAY")
    frame.medal:SetSize(28, 28)
    frame.medal:SetPoint("LEFT", frame.topBack, "LEFT", 8, 0)
    frame.medal:SetTexture("Interface\\AddOns\\Farol\\Media\\Farol") -- arquivo do ícone (ns.ICON é o código do chat)
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
    BuildChars(frame.pages.chars)
    frame.pages.profs = CreateFrame("Frame", nil, frame.content)
    frame.pages.profs:SetPoint("TOPLEFT", 0, 0)
    frame.pages.profs:SetSize(WIDTH - SIDE_W - 24, HEIGHT - TOP_H - FOOT_H - 16)
    BuildProfs(frame.pages.profs)

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

    -- Alça ◢ (3.31): arrastar aumenta/diminui a Central inteira, na proporção (70% a 130%); duplo clique = 100%.
    frame.grip = CreateFrame("Button", "FarolHubResize", frame)
    frame.grip:SetSize(18, 18)
    frame.grip:SetPoint("BOTTOMRIGHT", -6, 6)
    frame.grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.grip:SetScript("OnMouseDown", function(self) Hub.StartResize(self) end)
    frame.grip:SetScript("OnMouseUp", function() Hub.StopResize() end)
    frame.grip:SetScript("OnDoubleClick", function() Hub.SetScale(1) end)
    frame.grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(string.format(T("hub_size_tip"), math.floor(Hub.Scale() * 100 + 0.5)), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if frame.SetScale then frame:SetScale(Hub.Scale()) end

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

-- Tamanho da Central (3.31): proporcional, de 70% a 130%, salvo em db.hubScale (validado no Core).
Hub.SCALE_MIN, Hub.SCALE_MAX = 0.7, 1.3
function Hub.Scale()
    local db = DB()
    local v = db and db.hubScale
    if type(v) ~= "number" or v ~= v or v < Hub.SCALE_MIN or v > Hub.SCALE_MAX then return 1 end
    return v
end

-- Muda a escala mantendo o canto de cima à esquerda no mesmo lugar da tela.
local function ApplyScale(value)
    if not hub or not hub.SetScale then return end
    local old = hub:GetScale() or 1
    local left, top = hub:GetLeft(), hub:GetTop()
    hub:SetScale(value)
    if type(left) == "number" and type(top) == "number" and old > 0 then
        hub:ClearAllPoints()
        hub:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * old / value, top * old / value)
    end
end

function Hub.SetScale(value)
    local db = DB()
    if not db or type(value) ~= "number" or value ~= value then return false end
    value = math.max(Hub.SCALE_MIN, math.min(Hub.SCALE_MAX, math.floor(value * 100 + 0.5) / 100))
    db.hubScale = value
    ApplyScale(value)
    return true
end

local resizing
function Hub.StartResize(grip)
    if not hub or not GetCursorPosition then return end
    local ok, x, y = pcall(GetCursorPosition)
    local eff = hub.GetEffectiveScale and hub:GetEffectiveScale() or 1
    if not ok or type(x) ~= "number" or type(y) ~= "number" or type(eff) ~= "number" or eff <= 0 then return end
    resizing = { x = x, y = y, scale = Hub.Scale(), w = WIDTH * eff, h = HEIGHT * eff }
    grip:SetScript("OnUpdate", function()
        if not resizing then return end
        local okc, cx, cy = pcall(GetCursorPosition)
        if not okc or type(cx) ~= "number" or type(cy) ~= "number" then return end
        local f = math.max((resizing.w + cx - resizing.x) / resizing.w, (resizing.h + resizing.y - cy) / resizing.h)
        if f == f then Hub.SetScale(resizing.scale * f) end
    end)
end

function Hub.StopResize()
    resizing = nil
    if hub and hub.grip then hub.grip:SetScript("OnUpdate", nil) end
end

local SWITCH = { on = true, ligar = true, ligado = true, sim = true, off = false, desligar = false, desligado = false, nao = false,
    simples = false, simple = false, detalhado = true, detailed = true }

function Hub.HandleCommand(rest)
    local word = string.lower(string.match(rest or "", "^%s*(%a*)") or "")
    if word == "" then
        if Hub.Enabled() then Hub.Toggle() else Hub.SetEnabled(true) end
        return
    end
    if word == "tamanho" or word == "size" or word == "escala" or word == "scale" then
        local n = tonumber(string.match(rest or "", "(%d+)%s*%%?%s*$") or "")
        if n and n >= Hub.SCALE_MIN * 100 and n <= Hub.SCALE_MAX * 100 and Hub.SetScale(n / 100) then
            Print(string.format(T("hub_size_set"), math.floor(Hub.Scale() * 100 + 0.5)))
        else
            Print(T("hub_size_usage"))
        end
        return
    end
    local value = SWITCH[word]
    if value == nil then Print(T("hub_usage")) else Hub.SetEnabled(value) end
end

---------------------------------------------------------------------------
-- Eventos: anota o nível das profissões ao entrar (para o "nesta sessão") e atualiza a página aberta.
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED" }) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function()
    if not DB() then return end
    pcall(ReadProfs)
    if hub and hub:IsShown() and current == "profs" then Hub.Refresh() end
end)
