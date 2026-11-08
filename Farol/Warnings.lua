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
    "Lembrar em 30 min" (avisa de novo se o problema continuar).
  * Mensagem no centro da tela e no SEU chat (nada é enviado a ninguém) + som opcional.
  * Histórico dos 10 últimos avisos (salvo por personagem): botão ao lado da barra com contador
    de avisos novos, atalho de teclado (Esc > Teclas de atalho > AddOns > Farol) e /farol historico.
]]

local _, ns = ...

local COOLDOWN = 5 * 60
local REMIND_SECONDS = 30 * 60 -- "Lembrar em 30 min"
local HISTORY_MAX = 10
local HISTORY_ICON = "Interface\\Icons\\INV_Misc_Note_01"
local DURAB_MIN, DURAB_MAX = 5, 50
local BAGS_MIN, BAGS_MAX = 0, 10
local DEFAULTS = { durab = true, durabPct = 20, bags = true, bagSlots = 2, sound = true, talents = true, ranks = true }
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
        warn_remind_btn = "Lembrar em 30 min",
        warn_silenced   = "aviso silenciado: só volta se a situação mudar.",
        warn_reminded   = "ok: aviso de novo às %s se o problema continuar.",
        warn_chat_hint  = " — /farol aviso silenciar ou /farol aviso lembrar",
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
        warn_set_durab  = "aviso de durabilidade: abaixo de %d%%.",
        warn_set_bags   = "aviso de bolsas: até %d espaço(s) livre(s).",
        warn_on         = "aviso ligado: %s",
        warn_off        = "aviso desligado: %s",
        warn_name_durab = "durabilidade",
        warn_name_bags  = "bolsas",
        warn_name_sound = "som",
        warn_bad_durab  = "valor inválido: use de 5 a 50 (%).",
        warn_bad_bags   = "valor inválido: use de 0 a 10 espaços.",
        warn_usage      = "uso: /farol aviso durab N || bolsas N || durab/bolsas/talentos/graus/som off (ou on) || status || silenciar || lembrar",
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
        warn_remind_btn = "Remind in 30 min",
        warn_silenced   = "warning silenced: it only comes back if the situation changes.",
        warn_reminded   = "ok: I'll warn you again at %s if it's still a problem.",
        warn_chat_hint  = " — /farol warn silence or /farol warn remind",
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
        warn_set_durab  = "durability warning: below %d%%.",
        warn_set_bags   = "bag warning: %d free slot(s) or fewer.",
        warn_on         = "warning on: %s",
        warn_off        = "warning off: %s",
        warn_name_durab = "durability",
        warn_name_bags  = "bags",
        warn_name_sound = "sound",
        warn_bad_durab  = "invalid value: use 5 to 50 (%).",
        warn_bad_bags   = "invalid value: use 0 to 10 slots.",
        warn_usage      = "usage: /farol warn durab N || bags N || durab/bags/talents/ranks/sound off (or on) || status || silence || remind",
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
    for _, key in ipairs({ "durab", "bags", "sound", "talents", "ranks" }) do
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
    talents = { warnedCount = 0 },      -- quantos pontos já foram avisados
    ranks = { warned = {}, dirty = true, lastScan = nil }, -- magias já avisadas; "dirty" = algo mudou
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
-- Janelinha de aviso: "Silenciar" ou "Lembrar em 30 min"
---------------------------------------------------------------------------

local queue = {}  -- avisos esperando resposta: { key = "durab"|"bags"|"talents"|"ranks"|"test", text = ... }
local popup

local function CreatePopup()
    local frame = CreateFrame("Frame", "FarolWarnPopup", UIParent, ns.backdropTemplate)
    frame:SetSize(360, 118)
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
    frame.text:SetWidth(320)
    frame.silence = CreateFrame("Button", "FarolWarnSilence", frame, "UIPanelButtonTemplate")
    frame.silence:SetSize(150, 22)
    frame.silence:SetPoint("BOTTOMLEFT", 22, 16)
    frame.silence:SetScript("OnClick", function() Warnings.Respond(false) end)
    frame.remind = CreateFrame("Button", "FarolWarnRemind", frame, "UIPanelButtonTemplate")
    frame.remind:SetSize(150, 22)
    frame.remind:SetPoint("BOTTOMRIGHT", -22, 16)
    frame.remind:SetScript("OnClick", function() Warnings.Respond(true) end)
    frame:Hide()
    return frame
end

local function ShowNext()
    local current = queue[1]
    if not current then
        if popup then popup:Hide() end
        return
    end
    popup = popup or CreatePopup()
    popup.title:SetText(T("warn_popup_title"))
    popup.text:SetText(current.text)
    popup.silence:SetText(T("warn_silence_btn"))
    popup.remind:SetText(T("warn_remind_btn"))
    popup:Show()
end

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
function Warnings.SanitizeHistory(saved)
    local clean = {}
    if type(saved) ~= "table" then return clean end
    for _, entry in ipairs(saved) do
        if type(entry) == "table" and type(entry.text) == "string" and type(entry.t) == "number" then
            local text = string.gsub(entry.text, "[|%c]", "")
            clean[#clean + 1] = { t = entry.t, text = string.sub(text, 1, 200) }
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
    queue[#queue + 1] = { key = key, text = text }
    ShowNext()
end

-- Resposta do jogador ao aviso mostrado: remind = true (lembrar em 30 min) ou false (silenciar).
function Warnings.Respond(remind)
    local current = table.remove(queue, 1)
    if not current then Print(T("warn_none")) return end
    local entry = state[current.key]
    if remind then
        if entry then entry.remindAt = GetTime() + REMIND_SECONDS end
        Print(string.format(T("warn_reminded"), date("%H:%M", time() + REMIND_SECONDS)))
    else
        if entry then entry.remindAt = nil end
        Print(T("warn_silenced"))
    end
    ShowNext()
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
    local text = free == 0 and T("warn_bags_full") or string.format(T("warn_bags"), free)
    if free == 0 and not entry.full then
        -- Encheu de vez: avisa mesmo que já tenha avisado "quase cheias" há pouco.
        entry.full = true
        Fire(entry, now, text, "bags")
    elseif CanFire(entry, now) then
        Fire(entry, now, text, "bags")
    elseif ReminderDue(entry, now) then
        entry.remindAt = nil
        Announce(text, "bags")
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

local TALENT_SOURCES = {
    { "UnitCharacterPoints", function() return UnitCharacterPoints and UnitCharacterPoints("player") end },
    { "GetUnspentTalentPoints", function() return GetUnspentTalentPoints and GetUnspentTalentPoints() end },
    { "GetNumUnspentTalents", function() return GetNumUnspentTalents and GetNumUnspentTalents() end },
    { "C_Traits", function() return C_ClassTalents and C_Traits and TraitsUnspent() end },
}

-- Devolve (pontos, nome da função usada) ou nil se nenhuma funcionar neste cliente.
local function UnspentTalents()
    for _, source in ipairs(TALENT_SOURCES) do
        local ok, points = pcall(source[2])
        if ok and type(points) == "number" and not ns.IsSecret(points) and points >= 0 then
            return points, source[1]
        end
    end
    return nil
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
    if not (InCombatLockdown and InCombatLockdown()) then -- talentos e graus esperam o combate acabar
        pcall(CheckTalents, now)
        pcall(CheckRanks, now)
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
    frame:SetSize(470, 256)
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

    frame.talents = Check("FarolWarnTalents", -110, "talents")
    frame.ranks = Check("FarolWarnRanks", -140, "ranks")
    frame.sound = Check("FarolWarnSound", -170, "sound")

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hint:SetPoint("TOPLEFT", 22, -202)

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
    window.sound.label:SetText(T("warn_opt_sound"))
    window.sound:SetChecked(settings.sound)
    window.hint:SetText(T("warn_hint"))
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
            row:SetText("|cffaaaaaa" .. date("%d/%m %H:%M", entry.t) .. "|r  " .. entry.text)
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
}

-- Diagnóstico: mostra o que o addon consegue ler neste cliente.
local function PrintStatus()
    local points, source = UnspentTalents()
    if points then
        Print(string.format(T("warn_status_talents"), points, source))
    else
        Print(T("warn_status_notal"))
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
    local word, value = string.match(rest or "", "^%s*(%a*)%s*(%w*)")
    word, value = string.lower(word or ""), string.lower(value or "")
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
        Warnings.Respond(true)
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
