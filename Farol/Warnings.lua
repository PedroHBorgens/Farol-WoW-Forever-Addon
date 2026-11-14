--[[
  Farol — Avisos de durabilidade e bolsas / Durability and bag warnings

  * Durabilidade: avisa quando a peça mais gasta fica abaixo do limite (padrão 20%).
  * Bolsas: avisa quando sobram poucos espaços livres (padrão 2 ou menos) e quando enchem.
  * Avisa UMA vez: só avisa de novo depois que a situação melhora (reparou / liberou espaço)
    e com intervalo mínimo de 5 minutos, para não repetir quando o número oscila.
  * Talentos: avisa quando há pontos de talento não gastos (e a cada ponto novo).
  * Graus de magia: avisa quando uma magia na barra de ações não é o grau mais alto que você conhece.
    O addon NÃO troca a magia por você (isso seria automação): só avisa.
  * Talentos e graus nunca avisam no meio do combate: esperam a luta acabar.
  * Cada aviso abre uma janelinha: "Silenciar" (só volta se a situação mudar) ou
    "Lembrar em N min" (2, 5, 10, 15 ou 30; avisa de novo se o problema continuar).
    Vários avisos ao mesmo tempo aparecem juntos, numa janela só, com "Silenciar todos" / "Lembrar todos".
    Um lembrete por tipo de aviso; lembretes acabam no /reload ou ao sair do jogo.
  * Lembretes de pausa e de beber água (desligados por padrão): o jogador escolhe o intervalo (15 a 240 min)
    e se podem aparecer em lutas, raides e masmorras (por padrão esperam). "Silenciar" vale até o fim da sessão.
  * Mensagem no centro da tela e no SEU chat (nada é enviado a ninguém) + som opcional.
  * Histórico dos 10 últimos avisos (salvo por personagem): botão ao lado da barra com contador
    de avisos novos, atalho de teclado (Esc > Teclas de atalho > AddOns > Farol) e /farol historico.
]]

local _, ns = ...

local COOLDOWN = 5 * 60
local REMIND_CHOICES = { 2, 5, 10, 15, 30 } -- minutos do "Lembrar em"
local BREAK_MIN, BREAK_MAX = 15, 240        -- intervalo dos lembretes de pausa e de água (minutos)
local BREAK_KEYS = { "pause", "water" }
local HISTORY_MAX = 10
local HISTORY_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local DURAB_MIN, DURAB_MAX = 5, 50
local BAGS_MIN, BAGS_MAX = 0, 10
local DEFAULTS = {
    durab = true, durabPct = 20, bags = true, bagSlots = 2, sound = true, talents = true, ranks = true,
    prof = true,                                             -- profissão no máximo do treinamento
    restFull = false,                                        -- outro personagem com descanso cheio (ao entrar)
    remindMin = 30,                                          -- tempo padrão do "Lembrar em"
    pause = false, pauseMin = 120, pauseAnywhere = false,    -- lembrete de pausa (desligado por padrão)
    water = false, waterMin = 45, waterAnywhere = false,     -- lembrete de beber água (desligado por padrão)
}
local MAX_ACTION_SLOT = 180 -- barras de ação (clientes modernos têm até 180 espaços)
local RANK_SCAN_INTERVAL = 5 -- segundos entre varreduras quando algo mudou

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
        warn_opt_talents = "Avisar sobre pontos de talento não gastos",
        warn_opt_ranks  = "Avisar sobre magias de grau antigo na barra de ações",
        warn_talents    = "Você tem %d ponto(s) de talento para gastar.",
        warn_ranks      = "Magia de grau antigo na barra: %s.",
        warn_rank_item  = "%s (Grau %d) — você já tem o Grau %d",
        warn_more       = " e mais %d",
        warn_name_talents = "talentos",
        warn_name_ranks = "graus de magia",
        warn_status_talents = "talentos: %d ponto(s) não gasto(s) (função: %s).",
        warn_status_notal = "talentos: não foi possível ler os pontos neste cliente.",
        warn_status_ranks = "magias de grau antigo na barra: %d.",
        warn_popup_title = "Aviso",
        warn_silence_btn = "Silenciar",
        warn_remind_btn = "Lembrar em %d min",
        warn_minutes    = "%d min",
        warn_group_title = "Avisos (%d)",
        warn_silence_all = "Silenciar todos",
        warn_remind_all = "Lembrar todos em %d min",
        warn_silenced   = "aviso silenciado: só volta se a situação mudar.",
        warn_silenced_session = "lembrete silenciado até o fim da sessão.",
        warn_silenced_n = "%d aviso(s) silenciado(s).",
        warn_reminded   = "ok: aviso de novo às %s se o problema continuar.",
        warn_reminded_n = "ok: %d aviso(s) de novo às %s (se ainda for preciso).",
        warn_chat_hint  = " — /farol aviso silenciar ou /farol aviso lembrar [minutos]",
        warn_pause      = "Você está jogando há %s — que tal uma pausa?",
        warn_prof       = "%s no máximo do treinamento — procure um instrutor para continuar subindo.",
        warn_bags_junk  = " Há %d espaço(s) com lixo (%s) para vender.",
        warn_restFull   = "Descanso cheio (150%%): %s — bom momento para jogar com eles.",
        warn_opt_restFull = "Avisar ao entrar se outro personagem estiver com o descanso cheio",
        warn_name_restFull = "descanso cheio",
        warn_opt_prof   = "Avisar quando uma profissão chegar ao máximo do treinamento",
        warn_name_prof  = "profissões",
        warn_water      = "Hora de beber água!",
        warn_opt_pause  = "Lembrete de pausa a cada",
        warn_opt_water  = "Lembrete de beber água a cada",
        warn_unit_min   = "min",
        warn_opt_anywhere = "Também em lutas, raides e masmorras",
        warn_opt_remind = "\"Lembrar em\" vem com:",
        warn_name_pause = "pausa",
        warn_name_water = "beber água",
        warn_set_break  = "lembrete de %s: a cada %d min.",
        warn_set_anywhere = "lembrete de %s: aparece também em lutas, raides e masmorras.",
        warn_set_wait   = "lembrete de %s: espera a luta acabar e você sair da masmorra/raide.",
        warn_set_remind = "\"Lembrar em\" agora vem com %d min.",
        warn_bad_break  = "valor inválido: use de 15 a 240 minutos.",
        warn_bad_remind = "valor inválido: use 2, 5, 10, 15 ou 30 minutos.",
        warn_none       = "nenhum aviso aberto.",
        hist_title      = "Últimos avisos",
        hist_empty      = "Nenhum aviso ainda.",
        hist_clear      = "Limpar",
        hist_cleared    = "histórico de avisos apagado.",
        hist_button_tip = "Últimos avisos",
        hist_button_new = "%d novo(s) — clique para ver",
        hist_button_none = "Clique para ver",
        opt_history     = "Histórico...",
        help_history    = "  /farol historico     - ver os 10 últimos avisos (também pelo botão ao lado da barra ou por atalho de teclado)",
        warn_opt_test   = "Testar aviso",
        warn_hint       = "Avisa uma vez; avisa de novo depois que melhorar (mín. 5 min).",
        warn_hint_break = "Pausa e água vêm desligadas; sem a opção acima, esperam a luta e a masmorra acabarem.",
        warn_set_durab  = "aviso de durabilidade: abaixo de %d%%.",
        warn_set_bags   = "aviso de bolsas: até %d espaço(s) livre(s).",
        warn_on         = "aviso ligado: %s",
        warn_off        = "aviso desligado: %s",
        warn_name_durab = "durabilidade",
        warn_name_bags  = "bolsas",
        warn_name_sound = "som",
        warn_bad_durab  = "valor inválido: use de 5 a 50 (%).",
        warn_bad_bags   = "valor inválido: use de 0 a 10 espaços.",
        warn_usage      = "uso: /farol aviso durab N || bolsas N || pausa N || agua N || durab/bolsas/talentos/graus/profissoes/descansado/pausa/agua/som on||off || pausa/agua lutas on||off || lembrar N || status || silenciar",
        opt_warnings    = "Avisos...",
        help_warn       = "  /farol aviso         - abrir a janela de avisos (durabilidade, bolsas, talentos, graus, profissões, pausa, água)",
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
        warn_opt_talents = "Warn about unspent talent points",
        warn_opt_ranks  = "Warn about lower-rank spells on the action bars",
        warn_talents    = "You have %d unspent talent point(s).",
        warn_ranks      = "Lower-rank spell on your bars: %s.",
        warn_rank_item  = "%s (Rank %d) — you already know Rank %d",
        warn_more       = " and %d more",
        warn_name_talents = "talents",
        warn_name_ranks = "spell ranks",
        warn_status_talents = "talents: %d unspent point(s) (function: %s).",
        warn_status_notal = "talents: unable to read talent points on this client.",
        warn_status_ranks = "lower-rank spells on your bars: %d.",
        warn_popup_title = "Warning",
        warn_silence_btn = "Silence",
        warn_remind_btn = "Remind in %d min",
        warn_minutes    = "%d min",
        warn_group_title = "Warnings (%d)",
        warn_silence_all = "Silence all",
        warn_remind_all = "Remind all in %d min",
        warn_silenced   = "warning silenced: it only comes back if the situation changes.",
        warn_silenced_session = "reminder silenced until the end of the session.",
        warn_silenced_n = "%d warning(s) silenced.",
        warn_reminded   = "ok: I'll warn you again at %s if it's still a problem.",
        warn_reminded_n = "ok: %d warning(s) again at %s (if still needed).",
        warn_chat_hint  = " — /farol warn silence or /farol warn remind [minutes]",
        warn_pause      = "You've been playing for %s — time for a break?",
        warn_prof       = "%s at the training limit — find a trainer to keep leveling.",
        warn_bags_junk  = " %d slot(s) hold junk (%s) you can sell.",
        warn_restFull   = "Rested XP full (150%%): %s — a good time to play them.",
        warn_opt_restFull = "Warn at login if another character has full rested XP",
        warn_name_restFull = "full rested XP",
        warn_opt_prof   = "Warn when a profession reaches its training limit",
        warn_name_prof  = "professions",
        warn_water      = "Time to drink some water!",
        warn_opt_pause  = "Break reminder every",
        warn_opt_water  = "Drink water reminder every",
        warn_unit_min   = "min",
        warn_opt_anywhere = "Also during fights, raids and dungeons",
        warn_opt_remind = "\"Remind in\" starts at:",
        warn_name_pause = "break",
        warn_name_water = "drink water",
        warn_set_break  = "%s reminder: every %d min.",
        warn_set_anywhere = "%s reminder: also shown during fights, raids and dungeons.",
        warn_set_wait   = "%s reminder: waits until the fight ends and you leave the dungeon/raid.",
        warn_set_remind = "\"Remind in\" now starts at %d min.",
        warn_bad_break  = "invalid value: use 15 to 240 minutes.",
        warn_bad_remind = "invalid value: use 2, 5, 10, 15 or 30 minutes.",
        warn_none       = "no open warning.",
        hist_title      = "Recent warnings",
        hist_empty      = "No warnings yet.",
        hist_clear      = "Clear",
        hist_cleared    = "warning history cleared.",
        hist_button_tip = "Recent warnings",
        hist_button_new = "%d new — click to view",
        hist_button_none = "Click to view",
        opt_history     = "History...",
        help_history    = "  /farol history      - view the last 10 warnings (also via the button next to the bar or a key binding)",
        warn_opt_test   = "Test warning",
        warn_hint       = "Warns once; warns again after it improves (min. 5 min).",
        warn_hint_break = "Break and water start off; without the option above they wait for fights and dungeons to end.",
        warn_set_durab  = "durability warning: below %d%%.",
        warn_set_bags   = "bag warning: %d free slot(s) or fewer.",
        warn_on         = "warning on: %s",
        warn_off        = "warning off: %s",
        warn_name_durab = "durability",
        warn_name_bags  = "bags",
        warn_name_sound = "sound",
        warn_bad_durab  = "invalid value: use 5 to 50 (%).",
        warn_bad_bags   = "invalid value: use 0 to 10 slots.",
        warn_usage      = "usage: /farol warn durab N || bags N || break N || water N || durab/bags/talents/ranks/professions/rested/break/water/sound on||off || break/water fights on||off || remind N || status || silence",
        opt_warnings    = "Warnings...",
        help_warn       = "  /farol warn          - open the warnings window (durability, bags, talents, ranks, professions, break, water)",
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
    for _, key in ipairs({ "durab", "bags", "sound", "talents", "ranks", "prof", "restFull", "pause", "pauseAnywhere",
                           "water", "waterAnywhere" }) do
        if type(saved[key]) == "boolean" then clean[key] = saved[key] else clean[key] = DEFAULTS[key] end
    end
    clean.durabPct = InRange(saved.durabPct, DURAB_MIN, DURAB_MAX) or DEFAULTS.durabPct
    clean.bagSlots = InRange(saved.bagSlots, BAGS_MIN, BAGS_MAX) or DEFAULTS.bagSlots
    clean.pauseMin = InRange(saved.pauseMin, BREAK_MIN, BREAK_MAX) or DEFAULTS.pauseMin
    clean.waterMin = InRange(saved.waterMin, BREAK_MIN, BREAK_MAX) or DEFAULTS.waterMin
    clean.remindMin = DEFAULTS.remindMin
    for _, minutes in ipairs(REMIND_CHOICES) do
        if saved.remindMin == minutes then clean.remindMin = minutes end
    end
    return clean
end

---------------------------------------------------------------------------
-- Disparo
---------------------------------------------------------------------------

-- Estado de cada aviso: armed = pode avisar; lastAt = quando avisou (GetTime).
local state = {
    durab = { armed = true, lastAt = nil },
    bags = { armed = true, lastAt = nil, full = false },
    talents = { warnedCount = 0 },      -- quantos pontos já foram avisados
    ranks = { warned = {}, dirty = true, lastScan = nil }, -- magias já avisadas; "dirty" = algo mudou
    prof = { warned = {} },                             -- limites já avisados ("Mineração@150")
    restFull = { checked = false },                     -- descanso cheio: confere uma vez por sessão
    pause = { nextAt = nil, silenced = false },         -- lembretes por tempo: próxima vez (GetTime)
    water = { nextAt = nil, silenced = false },
}

local function PlayWarningSound()
    -- Som da "checagem de prontidão": diferente do som do alarme.
    if SOUNDKIT and SOUNDKIT.READY_CHECK then
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
    elseif PlaySound then
        PlaySound("ReadyCheck", "Master")
    end
end

---------------------------------------------------------------------------
-- Janelinha de aviso: "Silenciar" ou "Lembrar em N min"
-- Um aviso: texto + botões. Vários: uma janela só, com uma linha por aviso e "Silenciar todos" /
-- "Lembrar todos". Cada linha tem o seu próprio tempo de "Lembrar" (menu suspenso).
---------------------------------------------------------------------------

-- Avisos esperando resposta: { key = "durab"|"bags"|"talents"|"ranks"|"pause"|"water"|"test", text, minutes }
local queue = {}
local popup
local groupMinutes          -- tempo escolhido no "Lembrar todos" (nil = padrão das configurações)
local Render                -- definida abaixo

local function DefaultMinutes()
    local settings = ns.GetDB() and Settings()
    return settings and settings.remindMin or DEFAULTS.remindMin
end

-- Itens do menu de tempo: 2, 5, 10, 15, 30 min. get/set leem e gravam o tempo escolhido.
local function MinuteItems(get, set)
    return function()
        local items = {}
        for _, minutes in ipairs(REMIND_CHOICES) do
            items[#items + 1] = {
                text = string.format(T("warn_minutes"), minutes),
                checked = get() == minutes,
                onClick = function() set(minutes); Render() end,
            }
        end
        return items
    end
end

local function NewButton(parent, name, width, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetScript("OnClick", onClick)
    return button
end

local ROW_HEIGHT = 28
local GROUP_WIDTH, SINGLE_WIDTH = 640, 400

local function CreateRow(frame, index)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(GROUP_WIDTH - 40, ROW_HEIGHT - 4)
    row:SetPoint("TOPLEFT", 20, -44 - (index - 1) * ROW_HEIGHT)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 0, 0)
    row.text:SetWidth(300)
    row.text:SetJustifyH("LEFT")
    if row.text.SetWordWrap then row.text:SetWordWrap(false) end
    local prefix = "FarolWarnRow" .. index
    row.time = ns.CreateDropdown(row, prefix .. "Time", 34, MinuteItems(
        function() return row.entry and row.entry.minutes end,
        function(minutes) if row.entry then row.entry.minutes = minutes end end))
    row.time:SetPoint("RIGHT", 0, 0)
    row.remind = NewButton(row, prefix .. "Remind", 130, function()
        if row.entry then Warnings.Respond(true, row.entry.key, row.entry.minutes) end
    end)
    row.remind:SetPoint("RIGHT", row.time, "LEFT", -2, 0)
    row.silence = NewButton(row, prefix .. "Silence", 100, function()
        if row.entry then Warnings.Respond(false, row.entry.key) end
    end)
    row.silence:SetPoint("RIGHT", row.remind, "LEFT", -6, 0)
    row:Hide()
    return row
end

local function CreatePopup()
    local frame = CreateFrame("Frame", "FarolWarnPopup", UIParent, ns.backdropTemplate)
    frame:SetSize(SINGLE_WIDTH, 118)
    frame:SetPoint("TOP", 0, -240)
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
    frame.text:SetWidth(SINGLE_WIDTH - 40)
    -- Botões de baixo: um aviso = Silenciar / Lembrar; vários = Silenciar todos / Lembrar todos.
    frame.silence = NewButton(frame, "FarolWarnSilence", 140, function()
        if #queue == 1 then Warnings.Respond(false, queue[1].key) else Warnings.Respond(false) end
    end)
    frame.silence:SetPoint("BOTTOMLEFT", 22, 16)
    frame.time = ns.CreateDropdown(frame, "FarolWarnRemindTime", 34, MinuteItems(
        function()
            if #queue == 1 then return queue[1].minutes end
            return groupMinutes or DefaultMinutes()
        end,
        function(minutes)
            if #queue == 1 then queue[1].minutes = minutes else groupMinutes = minutes end
        end))
    frame.time:SetPoint("BOTTOMRIGHT", -22, 16)
    frame.remind = NewButton(frame, "FarolWarnRemind", 170, function()
        if #queue == 1 then
            Warnings.Respond(true, queue[1].key, queue[1].minutes)
        else
            Warnings.Respond(true, nil, groupMinutes or DefaultMinutes())
        end
    end)
    frame.remind:SetPoint("RIGHT", frame.time, "LEFT", -2, 0)
    frame.rows = {}
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

Render = function()
    if #queue == 0 then
        groupMinutes = nil
        if popup then popup:Hide() end
        return
    end
    popup = popup or CreatePopup()
    local group = #queue > 1
    for i, row in ipairs(popup.rows) do
        if not (group and queue[i]) then row.entry = nil; row:Hide() end
    end
    if group then
        popup:SetSize(GROUP_WIDTH, 100 + #queue * ROW_HEIGHT)
        popup.title:SetText(string.format(T("warn_group_title"), #queue))
        popup.text:SetText("")
        popup.text:Hide()
        for i, entry in ipairs(queue) do
            local row = popup.rows[i] or CreateRow(popup, i)
            popup.rows[i] = row
            row.entry = entry
            row.text:SetText(entry.text)
            row.silence:SetText(T("warn_silence_btn"))
            row.remind:SetText(string.format(T("warn_remind_btn"), entry.minutes))
            row:Show()
        end
        popup.silence:SetText(T("warn_silence_all"))
        popup.remind:SetText(string.format(T("warn_remind_all"), groupMinutes or DefaultMinutes()))
    else
        popup:SetSize(SINGLE_WIDTH, 118)
        popup.title:SetText(T("warn_popup_title"))
        popup.text:SetText(queue[1].text)
        popup.text:Show()
        popup.silence:SetText(T("warn_silence_btn"))
        popup.remind:SetText(string.format(T("warn_remind_btn"), queue[1].minutes))
    end
    popup:Show()
end
local ShowNext = Render -- nome antigo, usado abaixo

---------------------------------------------------------------------------
-- Histórico dos últimos avisos (FarolCharDB.warnHistory, por personagem)
---------------------------------------------------------------------------

local unread = 0          -- avisos novos desde a última vez que o histórico foi aberto
local historyButton       -- botão ao lado da barra (criado sob demanda)
local historyWindow
local RefreshHistory      -- definida abaixo

local function History()
    if type(FarolCharDB) ~= "table" then return {} end
    FarolCharDB.warnHistory = FarolCharDB.warnHistory or {}
    return FarolCharDB.warnHistory
end

-- Valida o histórico salvo: só texto simples (sem códigos "|"), com no máximo 200 caracteres.
-- Data salva válida: número finito entre 1970 e 2100 (um arquivo adulterado com "infinito"
-- ou NaN quebraria a formatação da data).
local function ValidTime(t)
    t = tonumber(t)
    if t and t == t and t >= 0 and t <= 4102444800 then return math.floor(t) end
    return nil
end

function Warnings.SanitizeHistory(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    for _, entry in ipairs(saved) do
        if type(entry) == "table" and type(entry.text) == "string" and ValidTime(entry.t) then
            local text = string.gsub(entry.text, "[|%c]", "")
            clean[#clean + 1] = { t = ValidTime(entry.t), text = string.sub(text, 1, 200) }
        end
    end
    while #clean > HISTORY_MAX do table.remove(clean, 1) end
    return clean
end

local function UpdateButton()
    local db = ns.GetDB()
    if not db or not ns.frame then return end
    if not db.warnButton then
        if historyButton then historyButton:Hide() end
        ns.LayoutQuickButtons()
        return
    end
    if not historyButton then
        historyButton = CreateFrame("Button", "FarolWarnHistoryButton", ns.frame)
        historyButton:SetSize(18, 18)
        table.insert(ns.quickButtons, historyButton)
        historyButton.icon = historyButton:CreateTexture(nil, "ARTWORK")
        historyButton.icon:SetAllPoints()
        historyButton.icon:SetTexture(HISTORY_ICON)
        historyButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        historyButton.badge = historyButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        historyButton.badge:SetPoint("BOTTOMRIGHT", 4, -2)
        historyButton.badge:SetTextColor(1, 0.2, 0.2)
        historyButton:RegisterForClicks("LeftButtonUp")
        historyButton:SetScript("OnClick", function() Warnings.ToggleHistory() end)
        historyButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("hist_button_tip"))
            GameTooltip:AddLine(unread > 0 and string.format(T("hist_button_new"), unread) or T("hist_button_none"),
                0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        historyButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    historyButton.badge:SetText(unread > 0 and tostring(unread) or "")
    historyButton:Show()
    ns.LayoutQuickButtons()
end
Warnings.UpdateButton = UpdateButton

local function Record(text)
    local history = History()
    history[#history + 1] = { t = time(), text = string.gsub(text, "[|%c]", "") }
    while #history > HISTORY_MAX do table.remove(history, 1) end
    if historyWindow and historyWindow:IsShown() then
        RefreshHistory()
    else
        unread = unread + 1
    end
    UpdateButton()
end

local function Announce(text, key)
    -- Só no SEU cliente: centro da tela + sua janela de chat. Nada é enviado.
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        pcall(UIErrorsFrame.AddMessage, UIErrorsFrame, text, 1, 0.6, 0)
    end
    Print("|cffff9900" .. text .. "|r" .. T("warn_chat_hint"))
    if key ~= "test" then Record(text) end
    if Settings().sound then pcall(PlayWarningSound) end
    -- Um aviso de cada tipo na fila: um aviso novo do mesmo tipo atualiza o texto.
    for _, entry in ipairs(queue) do
        if entry.key == key then
            entry.text = text
            ShowNext()
            return
        end
    end
    queue[#queue + 1] = { key = key, text = text, minutes = DefaultMinutes() }
    ShowNext()
end

local function ValidRemind(minutes)
    minutes = tonumber(minutes)
    for _, choice in ipairs(REMIND_CHOICES) do
        if minutes == choice then return choice end
    end
    return nil
end

local function IsBreak(key) return key == "pause" or key == "water" end

-- Aplica a resposta a um aviso. Um lembrete por tipo: lembrar de novo troca o horário anterior.
local function Apply(current, remind, minutes, now)
    local entry = state[current.key]
    if not entry then return end
    if IsBreak(current.key) then
        if remind then entry.nextAt = now + minutes * 60 else entry.silenced = true end
    elseif remind then
        entry.remindAt = now + minutes * 60
    else
        entry.remindAt = nil
    end
end

-- Resposta do jogador: remind = true (lembrar em "minutes") ou false (silenciar).
-- key = um aviso; sem key = todos os avisos abertos (botões "todos" e comandos do chat).
function Warnings.Respond(remind, key, minutes)
    if #queue == 0 then Print(T("warn_none")) return end
    minutes = ValidRemind(minutes) or DefaultMinutes()
    local now = GetTime()
    local answered, onlyBreaks = {}, true
    for i = #queue, 1, -1 do
        if key == nil or queue[i].key == key then
            local current = table.remove(queue, i)
            Apply(current, remind, minutes, now)
            table.insert(answered, 1, current)
            if not IsBreak(current.key) then onlyBreaks = false end
        end
    end
    if #answered == 0 then Print(T("warn_none")) return end
    local at = date("%H:%M", time() + minutes * 60)
    if #answered > 1 then
        Print(remind and string.format(T("warn_reminded_n"), #answered, at) or string.format(T("warn_silenced_n"), #answered))
    elseif remind then
        Print(string.format(T("warn_reminded"), at))
    else
        Print(onlyBreaks and T("warn_silenced_session") or T("warn_silenced"))
    end
    ShowNext()
end

-- Em combate? Leitura protegida: se o jogo der erro, conta como "em combate" (os avisos só esperam).
local function InCombat()
    if not InCombatLockdown then return false end
    local ok, value = pcall(InCombatLockdown)
    if not ok then return true end
    return value and true or false
end

local function CanFire(entry, now)
    return entry.armed and (entry.lastAt == nil or now - entry.lastAt >= COOLDOWN)
end

local function Fire(entry, now, text, key)
    entry.armed = false
    entry.lastAt = now
    entry.remindAt = nil
    Announce(text, key)
end

-- "Lembrar em 30 min" venceu e o problema continua?
local function ReminderDue(entry, now)
    return entry.remindAt ~= nil and now >= entry.remindAt
end

local function CheckDurability(now)
    local settings = Settings()
    local lowest = ns.GetLowestDurability()
    if not settings.durab or type(lowest) ~= "number" or ns.IsSecret(lowest) then return end
    local entry = state.durab
    if lowest < settings.durabPct then
        local text = string.format(T("warn_durab"), math.floor(lowest))
        if CanFire(entry, now) then
            Fire(entry, now, text, "durab")
        elseif ReminderDue(entry, now) then
            entry.remindAt = nil
            Announce(text, "durab")
        end
    else
        entry.armed = true -- reparou: pode avisar de novo
        entry.remindAt = nil
    end
end

-- Valor em texto simples ("3g 24s"), sem códigos de cor: vai para o chat e para o histórico.
local function PlainMoney(copper)
    local gold, silver, cop = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
    if gold > 0 then return gold .. "g " .. silver .. "s" end
    if silver > 0 then return silver .. "s " .. cop .. "c" end
    return cop .. "c"
end

-- Dica para o aviso de bolsas: quanto lixo dá para vender (o Farol nunca vende sozinho).
local function JunkHint()
    if not ns.GetJunk then return "" end
    local ok, junk = pcall(ns.GetJunk)
    if not ok or not junk or junk.slots == 0 then return "" end
    return string.format(T("warn_bags_junk"), junk.slots, PlainMoney(junk.total))
end

local function CheckBags(now)
    local settings = Settings()
    if not settings.bags then return end
    local free = ns.GetBagSpace()
    if type(free) ~= "number" or ns.IsSecret(free) then return end
    local entry = state.bags
    if free > settings.bagSlots then
        entry.armed = true -- liberou espaço: pode avisar de novo
        entry.full = false
        entry.remindAt = nil
        return
    end
    if free > 0 then entry.full = false end
    -- Texto montado só na hora de avisar (a dica do lixo lê as bolsas).
    local function Text() return (free == 0 and T("warn_bags_full") or string.format(T("warn_bags"), free)) .. JunkHint() end
    if free == 0 and not entry.full then
        -- Encheu de vez: avisa mesmo que já tenha avisado "quase cheias" há pouco.
        entry.full = true
        Fire(entry, now, Text(), "bags")
    elseif CanFire(entry, now) then
        Fire(entry, now, Text(), "bags")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(Text(), "bags")
    end
end

---------------------------------------------------------------------------
-- Talentos não gastos
-- A função mudou de nome entre versões do jogo; tentamos cada uma, em ordem.
---------------------------------------------------------------------------

local function TraitsUnspent()
    -- Clientes modernos: soma a "moeda" de pontos de cada árvore de talentos.
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return nil end
    local config = C_Traits.GetConfigInfo(configID)
    if not config or type(config.treeIDs) ~= "table" then return nil end
    local total = 0
    for _, treeID in ipairs(config.treeIDs) do
        for _, currency in ipairs(C_Traits.GetTreeCurrencyInfo(configID, treeID, false) or {}) do
            total = total + (tonumber(currency.quantity) or 0)
        end
    end
    return total
end

-- Pontos gastos em uma árvore. A ordem dos valores de GetTalentTabInfo muda entre versões:
--   clássico: nome, ícone, pontosGastos, ...       (1º valor é texto)
--   Wrath+:   id, nome, descrição, ícone, pontosGastos, ...   (1º valor é número)
local function TabPointsSpent(tab)
    local r1, _, r3, _, r5 = GetTalentTabInfo(tab)
    local spent
    if type(r1) == "string" then spent = r3 else spent = r5 end
    return type(spent) == "number" and spent or nil
end

-- Estimativa de reserva: no sistema clássico ganha-se 1 ponto por nível a partir do 10
-- (51 no nível 60). Pontos esperados − pontos gastos. Bônus do Forever que dão pontos extras
-- só fazem esta conta avisar A MENOS, nunca a mais.
local function TabsEstimate()
    if not (GetNumTalentTabs and GetTalentTabInfo and UnitLevel) then return nil end
    local tabs = GetNumTalentTabs()
    if type(tabs) ~= "number" or tabs < 1 then return nil end
    local spent = 0
    for tab = 1, tabs do
        local points = TabPointsSpent(tab)
        if not points then return nil end
        spent = spent + points
    end
    local expected = math.max(0, UnitLevel("player") - 9)
    return math.max(0, expected - spent)
end

local TALENT_SOURCES = {
    { "UnitCharacterPoints", function() return UnitCharacterPoints and UnitCharacterPoints("player") end },
    { "GetUnspentTalentPoints", function() return GetUnspentTalentPoints and GetUnspentTalentPoints() end },
    { "GetNumUnspentTalents", function() return GetNumUnspentTalents and GetNumUnspentTalents() end },
    { "C_Traits", function() return C_ClassTalents and C_Traits and TraitsUnspent() end },
    { "estimativa/estimate", TabsEstimate },
}

-- Lê uma fonte: devolve número, "não existe" (nil) ou erro.
local function ReadSource(source)
    local ok, points = pcall(source[2])
    if ok and type(points) == "number" and not ns.IsSecret(points) and points >= 0 and points <= 100 then
        return points
    end
    return nil, ok and "nil" or "erro"
end

-- Consulta TODAS as fontes e usa o maior valor: uma função que existe mas sempre devolve 0
-- (de outro sistema de talentos) não esconde mais os pontos encontrados por outra fonte.
-- Devolve (pontos, nome da fonte) ou nil se nenhuma funcionar neste cliente.
local function UnspentTalents()
    local best, bestSource
    for _, source in ipairs(TALENT_SOURCES) do
        local points = ReadSource(source)
        if points and (not best or points > best) then
            best, bestSource = points, source[1]
        end
    end
    return best, bestSource
end

local function CheckTalents(now)
    if not Settings().talents then return end
    local points = UnspentTalents()
    if not points then return end
    local entry = state.talents
    if points == 0 then
        entry.warnedCount = 0
        entry.remindAt = nil
    elseif points > entry.warnedCount then
        entry.warnedCount = points
        entry.remindAt = nil
        Announce(string.format(T("warn_talents"), points), "talents")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(string.format(T("warn_talents"), points), "talents")
    end
end

---------------------------------------------------------------------------
-- Graus de magia na barra de ações
---------------------------------------------------------------------------

-- Número do grau a partir do texto do jogo ("Grau 3" / "Rank 3"); nil se não for grau.
local function RankNumber(subtext)
    if type(subtext) ~= "string" or ns.IsSecret(subtext) then return nil end
    return tonumber(string.match(subtext, "(%d+)"))
end

local function SpellNameAndRank(spellID)
    local name, sub
    if C_Spell and C_Spell.GetSpellName then
        name = C_Spell.GetSpellName(spellID)
        sub = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellID)
    elseif GetSpellInfo then
        name, sub = GetSpellInfo(spellID) -- clientes antigos: GetSpellInfo devolve nome e grau
        if GetSpellSubtext then sub = GetSpellSubtext(spellID) or sub end
    end
    if type(name) ~= "string" or ns.IsSecret(name) then return nil end
    return name, RankNumber(sub)
end

-- Maior grau conhecido de cada magia, lendo o grimório (API moderna ou clássica).
local function HighestRanks()
    local best = {}
    local function Consider(name, rank)
        if type(name) == "string" and rank and (not best[name] or rank > best[name]) then
            best[name] = rank
        end
    end
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
            if info then
                for index = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
                    if item then Consider(item.name, RankNumber(item.subName)) end
                end
            end
        end
    elseif GetNumSpellTabs and GetSpellTabInfo then
        local getName = GetSpellBookItemName or GetSpellName
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for index = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local name, sub = getName(index, BOOKTYPE_SPELL or "spell")
                Consider(name, RankNumber(sub))
            end
        end
    end
    return best
end

-- Lista as magias da barra cujo grau é menor que o maior conhecido.
local function FindOutdatedSpells()
    local best = HighestRanks()
    local outdated, seen = {}, {}
    for slot = 1, MAX_ACTION_SLOT do
        if HasAction(slot) then
            local kind, id = GetActionInfo(slot)
            if kind == "spell" and type(id) == "number" and not ns.IsSecret(id) then
                local name, rank = SpellNameAndRank(id)
                local key = name and rank and (name .. "#" .. rank)
                if key and best[name] and best[name] > rank and not seen[key] then
                    seen[key] = true
                    outdated[#outdated + 1] = { key = key, name = name, rank = rank, best = best[name] }
                end
            end
        end
    end
    return outdated
end

local function CheckRanks(now)
    if not Settings().ranks then return end
    local entry = state.ranks
    local reminding = ReminderDue(entry, now)
    if reminding then entry.dirty = true end
    if not entry.dirty and entry.lastScan and now - entry.lastScan < 60 then return end
    if entry.lastScan and now - entry.lastScan < RANK_SCAN_INTERVAL then return end
    entry.dirty, entry.lastScan = false, now

    local outdated = FindOutdatedSpells()
    local current, fresh = {}, {}
    for _, spell in ipairs(outdated) do
        current[spell.key] = true
        if not entry.warned[spell.key] then fresh[#fresh + 1] = spell end
    end
    entry.warned = current -- magias trocadas saem da lista e podem avisar de novo no futuro
    if #outdated == 0 then entry.remindAt = nil return end
    if reminding then
        entry.remindAt = nil
        fresh = outdated -- lembrete: mostra todas as que continuam desatualizadas
    end
    if #fresh == 0 then return end

    local parts = {}
    for i = 1, math.min(3, #fresh) do
        parts[i] = string.format(T("warn_rank_item"), fresh[i].name, fresh[i].rank, fresh[i].best)
    end
    local text = table.concat(parts, "; ")
    if #fresh > 3 then text = text .. string.format(T("warn_more"), #fresh - 3) end
    Announce(string.format(T("warn_ranks"), text), "ranks")
end

---------------------------------------------------------------------------
-- Profissão no máximo do treinamento: "procure um instrutor"
---------------------------------------------------------------------------

-- Avisa uma vez por limite (ex.: Mineração em 150/150). Treinou e subiu o limite: o próximo limite avisa de novo.
-- O último limite (300) não avisa: não há mais o que treinar.
local function CheckProfessions(now)
    if not Settings().prof or not ns.ReadProfessions then return end
    local list = ns.ReadProfessions()
    if not list then return end
    local entry = state.prof
    local capped, fresh = {}, {}
    for _, p in ipairs(list) do
        if ns.ProfState(p) == "cap" then
            local id = p.name .. "@" .. p.max
            capped[#capped + 1] = p
            if not entry.warned[id] then fresh[#fresh + 1] = p end
        end
    end
    local warned = {}
    for _, p in ipairs(capped) do warned[p.name .. "@" .. p.max] = true end
    entry.warned = warned -- treinou: sai da lista
    if #capped == 0 then entry.remindAt = nil return end
    local reminding = ReminderDue(entry, now)
    if reminding then entry.remindAt = nil; fresh = capped end
    if #fresh == 0 then return end
    local parts = {}
    for i, p in ipairs(fresh) do
        parts[i] = string.gsub(p.name, "[|%c]", "") .. " " .. p.level .. "/" .. p.max
    end
    Announce(string.format(T("warn_prof"), table.concat(parts, ", ")), "prof")
end

---------------------------------------------------------------------------
-- Outro personagem com o descanso cheio (estimativa feita pelo Core). Confere uma vez por sessão.
---------------------------------------------------------------------------

local function CheckRestFull(now)
    if not Settings().restFull or not ns.RestedAlts then return end
    local entry = state.restFull
    local reminding = ReminderDue(entry, now)
    if entry.checked and not reminding then return end
    local list = ns.RestedAlts()
    if not list then return end -- nome/reino ainda não carregados: tenta de novo
    entry.checked = true
    if reminding then entry.remindAt = nil end
    local names = {}
    for _, r in ipairs(list) do
        if r.full then names[#names + 1] = string.gsub(r.name, "[|%c]", "") .. " (" .. r.level .. ")" end
    end
    if #names == 0 then return end
    if #names > 4 then names = { names[1], names[2], names[3], names[4] .. string.format(T("warn_more"), #names - 4) } end
    Announce(string.format(T("warn_restFull"), table.concat(names, ", ")), "restFull")
end

---------------------------------------------------------------------------
-- Lembretes de pausa e de beber água (por tempo)
---------------------------------------------------------------------------

-- Em luta, ou dentro de masmorra, raide, arena ou campo de batalha?
local function Busy()
    if InCombat() then return true end
    if IsInInstance then
        local ok, inside, kind = pcall(IsInInstance)
        if ok and inside and kind ~= "none" then return true end
    end
    return false
end

-- Conta a partir do login (ou de quando a opção foi ligada / o intervalo mudou). Quando vence:
-- aparece, ou espera a luta/masmorra acabar se o jogador não marcou "também em lutas...".
local function CheckBreaks(now)
    local settings = Settings()
    for _, key in ipairs(BREAK_KEYS) do
        local entry = state[key]
        if not settings[key] then
            entry.nextAt, entry.silenced = nil, false
        elseif not entry.silenced then
            local interval = settings[key .. "Min"] * 60
            if not entry.nextAt then
                entry.nextAt = now + interval
            elseif now >= entry.nextAt and (settings[key .. "Anywhere"] or not Busy()) then
                entry.nextAt = now + interval
                local text = T("warn_water")
                if key == "pause" then
                    local played = ns.GetSessionSeconds and ns.GetSessionSeconds() or nil
                    text = string.format(T("warn_pause"), ns.FormatDuration(played or interval))
                end
                Announce(text, key)
            end
        end
    end
end

-- Mudanças nas barras, no grimório ou no nível pedem uma nova varredura dos graus.
local watcher = CreateFrame("Frame")
for _, event in ipairs({ "ACTIONBAR_SLOT_CHANGED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
                         "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD", "UPDATE_BONUS_ACTIONBAR" }) do
    pcall(watcher.RegisterEvent, watcher, event)
end
watcher:SetScript("OnEvent", function() state.ranks.dirty = true end)

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
    pcall(CheckBreaks, now)
    if not InCombat() then -- talentos e graus esperam o combate acabar
        pcall(CheckTalents, now)
        pcall(CheckRanks, now)
        pcall(CheckProfessions, now)
        pcall(CheckRestFull, now)
    end
end)

---------------------------------------------------------------------------
-- Ajustes (usados pela janela e pelos comandos)
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function SetEnabled(key, value)
    Settings()[key] = value
    if key == "talents" then state.talents.warnedCount = 0
    elseif key == "ranks" then state.ranks.warned = {}; state.ranks.dirty = true
    elseif key == "prof" then state.prof.warned = {}; state.prof.remindAt = nil
    elseif key == "restFull" then state.restFull.checked = false; state.restFull.remindAt = nil
    elseif IsBreak(key) then -- recomeça a contagem agora
        state[key].nextAt = value and GetTime() + Settings()[key .. "Min"] * 60 or nil
        state[key].silenced = false
        if not value then -- desligou: o aviso aberto desse lembrete some da janela
            for i = #queue, 1, -1 do
                if queue[i].key == key then table.remove(queue, i) end
            end
            ShowNext()
        end
    elseif state[key] then state[key].armed = true end
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

-- Intervalo do lembrete de pausa/água (15 a 240 min); a contagem recomeça agora.
local function SetBreakMinutes(key, value)
    local minutes = InRange(value, BREAK_MIN, BREAK_MAX)
    if not minutes then Print(T("warn_bad_break")) return false end
    Settings()[key .. "Min"] = minutes
    state[key].nextAt = GetTime() + minutes * 60 -- a contagem recomeça agora
    Print(string.format(T("warn_set_break"), T("warn_name_" .. key), minutes))
    if RefreshWindow then RefreshWindow() end
    return true
end

-- Pode aparecer em lutas, raides e masmorras? (false = espera)
local function SetAnywhere(key, value)
    Settings()[key .. "Anywhere"] = value
    Print(string.format(value and T("warn_set_anywhere") or T("warn_set_wait"), T("warn_name_" .. key)))
    if RefreshWindow then RefreshWindow() end
end

-- Tempo que já vem escolhido no "Lembrar em".
local function SetRemindDefault(value)
    local minutes = ValidRemind(value)
    if not minutes then Print(T("warn_bad_remind")) return false end
    Settings().remindMin = minutes
    Print(string.format(T("warn_set_remind"), minutes))
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

local function NumberBox(frame, name, anchor, onSave, digits)
    local box = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
    box:SetSize(digits == 3 and 36 or 28, 20)
    box:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(digits or 2)
    box:SetScript("OnEnterPressed", function(self)
        if not onSave(self:GetText()) then RefreshWindow() end -- inválido: volta ao valor salvo
        self:ClearFocus()
    end)
    box:SetScript("OnEscapePressed", function(self) RefreshWindow(); self:ClearFocus() end)
    return box
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolWarnings", UIParent, ns.backdropTemplate)
    frame:SetSize(500, 470)
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

    local function Check(name, y, key, onClick, x)
        local check = CreateFrame("CheckButton", name, frame, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", x or 20, y)
        check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check:SetScript("OnClick", function(self)
            local value = self:GetChecked() and true or false
            if onClick then onClick(value) else SetEnabled(key, value) end
        end)
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

    frame.talents = Check("FarolWarnTalents", -110, "talents")
    frame.ranks = Check("FarolWarnRanks", -140, "ranks")
    frame.prof = Check("FarolWarnProf", -170, "prof")
    frame.restFull = Check("FarolWarnRestFull", -200, "restFull")

    -- Lembretes de pausa e de água: liga/desliga, intervalo em minutos e "também em lutas...".
    local y = -230
    for _, key in ipairs(BREAK_KEYS) do
        local cap = key == "pause" and "Pause" or "Water"
        local check = Check("FarolWarn" .. cap, y, key)
        frame[key] = check
        frame[key .. "Box"] = NumberBox(frame, "FarolWarn" .. cap .. "Min", check.label,
            function(text) return SetBreakMinutes(key, text) end, 3)
        frame[key .. "Unit"] = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame[key .. "Unit"]:SetPoint("LEFT", frame[key .. "Box"], "RIGHT", 6, 0)
        frame[key .. "Anywhere"] = Check("FarolWarn" .. cap .. "Anywhere", y - 24, nil,
            function(value) SetAnywhere(key, value) end, 44)
        y = y - 56
    end

    frame.sound = Check("FarolWarnSound", y, "sound")
    y = y - 32
    frame.remindLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.remindLabel:SetPoint("TOPLEFT", 24, y - 4)
    frame.remindDefault = ns.CreateDropdown(frame, "FarolWarnRemindDefault", 80, MinuteItems(
        function() return Settings().remindMin end,
        function(minutes) SetRemindDefault(minutes) end))
    frame.remindDefault:SetPoint("LEFT", frame.remindLabel, "RIGHT", 10, 0)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("TOPLEFT", 22, y - 34)
    frame.hint:SetWidth(426)
    frame.hint:SetJustifyH("LEFT")

    frame.test = CreateFrame("Button", "FarolWarnTest", frame, "UIPanelButtonTemplate")
    frame.test:SetSize(130, 22)
    frame.test:SetPoint("BOTTOMRIGHT", -24, 18)
    frame.history = CreateFrame("Button", "FarolWarnOpenHistory", frame, "UIPanelButtonTemplate")
    frame.history:SetSize(130, 22)
    frame.history:SetPoint("RIGHT", frame.test, "LEFT", -8, 0)
    frame.history:SetScript("OnClick", function() Warnings.ToggleHistory() end)
    frame.test:SetScript("OnClick", function()
        Announce(string.format(T("warn_durab"), Settings().durabPct - 1), "test")
    end)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolWarnings") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
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
    window.talents.label:SetText(T("warn_opt_talents"))
    window.talents:SetChecked(settings.talents)
    window.ranks.label:SetText(T("warn_opt_ranks"))
    window.ranks:SetChecked(settings.ranks)
    window.prof.label:SetText(T("warn_opt_prof"))
    window.prof:SetChecked(settings.prof)
    window.restFull.label:SetText(T("warn_opt_restFull"))
    window.restFull:SetChecked(settings.restFull)
    window.sound.label:SetText(T("warn_opt_sound"))
    window.sound:SetChecked(settings.sound)
    for _, key in ipairs(BREAK_KEYS) do
        window[key].label:SetText(T("warn_opt_" .. key))
        window[key]:SetChecked(settings[key])
        window[key .. "Unit"]:SetText(T("warn_unit_min"))
        window[key .. "Anywhere"].label:SetText(T("warn_opt_anywhere"))
        window[key .. "Anywhere"]:SetChecked(settings[key .. "Anywhere"])
        if not window[key .. "Box"]:HasFocus() then window[key .. "Box"]:SetText(tostring(settings[key .. "Min"])) end
    end
    window.remindLabel:SetText(T("warn_opt_remind"))
    window.remindDefault:SetText(string.format(T("warn_minutes"), settings.remindMin))
    window.hint:SetText(T("warn_hint") .. " " .. T("warn_hint_break"))
    window.test:SetText(T("warn_opt_test"))
    window.history:SetText(T("opt_history"))
    if not window.durabBox:HasFocus() then window.durabBox:SetText(tostring(settings.durabPct)) end
    if not window.bagsBox:HasFocus() then window.bagsBox:SetText(tostring(settings.bagSlots)) end
end

function Warnings.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

local function CreateHistoryWindow()
    local frame = CreateFrame("Frame", "FarolWarnHistory", UIParent, ns.backdropTemplate)
    frame:SetSize(520, 92 + HISTORY_MAX * 20)
    frame:SetPoint("CENTER", 0, 20)
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
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("TOPLEFT", 24, -52)
    frame.rows = {}
    for i = 1, HISTORY_MAX do
        local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row:SetPoint("TOPLEFT", 22, -48 - (i - 1) * 20)
        row:SetWidth(476)
        row:SetJustifyH("LEFT")
        if row.SetWordWrap then row:SetWordWrap(false) end
        frame.rows[i] = row
    end
    frame.clear = CreateFrame("Button", "FarolWarnHistoryClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(100, 22)
    frame.clear:SetPoint("BOTTOMRIGHT", -24, 16)
    frame.clear:SetScript("OnClick", function()
        local history = History()
        for i = #history, 1, -1 do history[i] = nil end
        Print(T("hist_cleared"))
        RefreshHistory()
    end)
    frame:SetScript("OnShow", function()
        unread = 0
        UpdateButton()
        RefreshHistory()
    end)
    tinsert(UISpecialFrames, "FarolWarnHistory") -- ESC fecha
    ns.MakeToplevel(frame) -- abre na frente e vem para a frente ao clicar
    frame:Hide()
    return frame
end

RefreshHistory = function()
    if not historyWindow or not historyWindow:IsShown() then return end
    historyWindow.title:SetText(T("hist_title"))
    historyWindow.clear:SetText(T("hist_clear"))
    local history = History()
    historyWindow.empty:SetText(T("hist_empty"))
    if #history == 0 then historyWindow.empty:Show() else historyWindow.empty:Hide() end
    for i, row in ipairs(historyWindow.rows) do
        local entry = history[#history - i + 1] -- mais novo primeiro
        if entry then
            row:SetText("|cffaaaaaa" .. (date("%d/%m %H:%M", entry.t) or "--") .. "|r  " .. entry.text)
            row:Show()
        else
            row:Hide()
        end
    end
end

function Warnings.ToggleHistory()
    historyWindow = historyWindow or CreateHistoryWindow()
    if historyWindow:IsShown() then historyWindow:Hide() else historyWindow:Show() end
end

-- Usada pelo atalho de teclado definido em Bindings.xml.
function Farol_ToggleWarnHistory()
    if ns.GetDB() then Warnings.ToggleHistory() end
end
BINDING_HEADER_FAROL = "Farol"
BINDING_NAME_FAROL_WARN_HISTORY = "Últimos avisos / Recent warnings"

function Warnings.Refresh()
    RefreshHistory()
    UpdateButton()
    RefreshWindow()
end

---------------------------------------------------------------------------
-- Comandos: /farol aviso ...
---------------------------------------------------------------------------

local KEYS = {
    durab = "durab", dur = "durab", durabilidade = "durab", durability = "durab",
    bolsas = "bags", bolsa = "bags", bags = "bags", bag = "bags",
    som = "sound", sound = "sound",
    talentos = "talents", talento = "talents", talents = "talents", talent = "talents",
    graus = "ranks", grau = "ranks", ranks = "ranks", rank = "ranks",
    profissoes = "prof", profissao = "prof", prof = "prof", professions = "prof", profession = "prof",
    descansado = "restFull", xpdescansado = "restFull", rested = "restFull", restedxp = "restFull", -- "descanso" = pausa
    pausa = "pause", pause = "pause", ["break"] = "pause", descanso = "pause",
    agua = "water", water = "water", hidratacao = "water", hydrate = "water",
}
local FIGHTS = { lutas = true, luta = true, fights = true, fight = true, combate = true, combat = true }

-- Diagnóstico: mostra o que o addon consegue ler neste cliente.
local function PrintStatus()
    local points, source = UnspentTalents()
    if points then
        Print(string.format(T("warn_status_talents"), points, source))
    else
        Print(T("warn_status_notal"))
    end
    -- Detalhe de cada fonte (para diagnosticar clientes diferentes, como o WoW Forever).
    for _, entry in ipairs(TALENT_SOURCES) do
        local value, why = ReadSource(entry)
        Print(string.format("    %s: %s", entry[1], value and tostring(value) or (why or "-")))
    end
    if GetNumTalentTabs and GetTalentTabInfo then
        local ok, tabs = pcall(GetNumTalentTabs)
        local spent = {}
        for tab = 1, (ok and type(tabs) == "number" and tabs or 0) do
            local okTab, points = pcall(TabPointsSpent, tab)
            spent[#spent + 1] = okTab and tostring(points) or "erro"
        end
        Print(string.format("    GetTalentTabInfo: %s", table.concat(spent, " / ")))
    end
    Print(string.format("    UnitLevel: %s", tostring(UnitLevel and UnitLevel("player"))))
    local okRep, faction, repSource = pcall(ns.GetWatchedFaction)
    if okRep and faction then
        Print(string.format(T("rep_status"), (string.gsub(tostring(faction.name), "|", "||")), tostring(repSource)))
    else
        Print(T("rep_status_none"))
    end
    local okJunk, junk, junkSource = pcall(ns.GetJunk)
    if okJunk and junk then
        Print(string.format(T("junk_status"), PlainMoney(junk.total), junk.slots, tostring(junkSource or "--")))
    end
    local okProf, profs, profSource = pcall(ns.ReadProfessions)
    if okProf and profs and #profs > 0 then
        local parts = {}
        for i, p in ipairs(profs) do parts[i] = string.gsub(p.name, "|", "||") .. " " .. p.level .. "/" .. p.max end
        Print(string.format(T("prof_status"), table.concat(parts, ", "), tostring(profSource)))
    else
        Print(string.format(T("prof_status_none"), tostring(okProf and profSource or "--")))
    end
    local okReset, daily, weekly, dailySource, weeklySource = pcall(ns.GetResetTimes)
    if okReset then
        local function show(v) return v and string.format("%dh %02dm", math.floor(v / 3600), math.floor(v % 3600 / 60)) or "--" end
        Print(string.format(T("reset_status"), show(daily), tostring(dailySource or "--"),
            show(weekly), tostring(weeklySource or "--")))
    end
    local ok, outdated = pcall(FindOutdatedSpells)
    outdated = ok and outdated or {}
    Print(string.format(T("warn_status_ranks"), #outdated))
    for i = 1, math.min(5, #outdated) do
        Print("  " .. string.format(T("warn_rank_item"), outdated[i].name, outdated[i].rank, outdated[i].best))
    end
end
local ON = { on = true, ligar = true, ativar = true, sim = true }
local OFF = { off = true, desligar = true, desativar = true, nao = true }

function Warnings.HandleCommand(rest)
    local word, value, extra = string.match(rest or "", "^%s*(%a*)%s*(%w*)%s*(%w*)")
    word, value, extra = string.lower(word or ""), string.lower(value or ""), string.lower(extra or "")
    local key = KEYS[word]
    if word == "" then
        Warnings.ToggleWindow()
    elseif word == "status" or word == "diagnostico" then
        PrintStatus()
    elseif word == "historico" or word == "history" then
        Warnings.ToggleHistory()
    elseif word == "silenciar" or word == "silence" then
        Warnings.Respond(false)
    elseif word == "lembrar" or word == "remind" then
        if value ~= "" and not ValidRemind(value) then Print(T("warn_bad_remind")) return end
        Warnings.Respond(true, nil, value)
    elseif word == "padrao" or word == "default" then
        SetRemindDefault(value)                       -- /farol aviso padrao 10
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
    elseif IsBreak(key) and FIGHTS[value] and (ON[extra] or OFF[extra]) then
        SetAnywhere(key, ON[extra] and true or false)  -- /farol aviso pausa lutas on
    elseif IsBreak(key) and value ~= "" then
        SetBreakMinutes(key, value)                    -- /farol aviso agua 30
    else
        Print(T("warn_usage"))
    end
end
