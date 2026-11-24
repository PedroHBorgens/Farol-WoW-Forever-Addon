--[[
  Farol — De onde vem o XP e o ouro / XP and gold by source

  Divide o XP e o ouro da sessão por origem: missões (QUEST_TURNED_IN traz o XP e o ouro da recompensa; sem esses
  valores, conta a mudança de XP/ouro que chega junto da entrega), monstros (XP ganho em luta ou até 3 s depois),
  saque (ouro com a janela de saque aberta), comerciante (vendas e compras/consertos com a janela do comerciante
  aberta) e outros (o resto: descobrir lugares, profissões, correio, leilão, troca, treinador, voo...).
  "Outros" é sempre o total da sessão menos as outras origens, então a soma bate com o XP/ouro da sessão.
  Só lê eventos que o jogo já manda: nada é enviado nem pedido ao servidor. As contas ficam na memória da sessão; o
  resumo salvo guarda só os números (FarolCharDB.lastSession.src, validado). A opção "sources" vem desligada.
]]

local _, ns = ...

local Sources = {}
ns.Sources = Sources

local COMBAT_GRACE = 3  -- XP até 3 s depois da luta ainda é do monstro
local QUEST_WINDOW = 2  -- mudança de XP/ouro até 2 s antes/depois da entrega é da missão (quando o jogo não diz o valor)
local LOOT_GRACE = 1    -- ouro até 1 s depois de fechar a janela de saque ainda é saque
local MAX = 1e12

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        src_xp_title   = "De onde veio o XP (sessão)",
        src_gold_title = "De onde veio o ouro (sessão)",
        src_quests     = "Missões (%d entregues)",
        src_quests_1   = "Missões (%d entregue)",
        src_mobs       = "Monstros",
        src_other_xp   = "Outros (lugares, profissões)",
        src_q_gold     = "Recompensas de missão",
        src_loot       = "Saque de monstros",
        src_sell       = "Comerciante: vendas",
        src_buy        = "Comerciante: compras e consertos",
        src_other_gold = "Outros (correio, leilão, troca)",
        src_sum_xp     = "XP por origem: missões %d%% · monstros %d%% · outros %d%%",
        src_sum_gold   = "Ouro por origem: missões %s · saque %s · vendas %s · compras e consertos %s · outros %s",
        opt_sources    = "Mostrar de onde vem o XP e o ouro (tooltip e resumo)",
        src_on         = "de onde vem o XP e o ouro: ligado (tooltip do XP e do ouro, e resumo da sessão).",
        src_off        = "de onde vem o XP e o ouro: desligado.",
        src_usage      = "uso: /farol origem on||off",
        help_sources   = "  /farol origem on||off - mostrar de onde vem o XP e o ouro (missões, monstros, saque, comerciante)",
        news_sources   = "de onde vem o XP e o ouro da sessão: missões, monstros, saque e comerciante (tooltip e resumo)",
        dg_reward      = "Recompensa da última entrega: XP %s · ouro %s",
        dg_reward_none = "Recompensa na entrega: nenhuma missão entregue nesta sessão",
        dg_not_given   = "não informado",
    },
    en = {
        src_xp_title   = "Where the XP came from (session)",
        src_gold_title = "Where the gold came from (session)",
        src_quests     = "Quests (%d turned in)",
        src_quests_1   = "Quests (%d turned in)",
        src_mobs       = "Monsters",
        src_other_xp   = "Other (places, professions)",
        src_q_gold     = "Quest rewards",
        src_loot       = "Monster loot",
        src_sell       = "Merchant: sales",
        src_buy        = "Merchant: purchases and repairs",
        src_other_gold = "Other (mail, auction, trade)",
        src_sum_xp     = "XP by source: quests %d%% · monsters %d%% · other %d%%",
        src_sum_gold   = "Gold by source: quests %s · loot %s · sales %s · purchases and repairs %s · other %s",
        opt_sources    = "Show where the XP and gold come from (tooltip and summary)",
        src_on         = "where the XP and gold come from: on (XP and gold tooltip, and session summary).",
        src_off        = "where the XP and gold come from: off.",
        src_usage      = "usage: /farol source on||off",
        help_sources   = "  /farol source on||off - show where the XP and gold come from (quests, monsters, loot, merchant)",
        news_sources   = "where the session's XP and gold come from: quests, monsters, loot and merchant (tooltip and summary)",
        dg_reward      = "Reward of the last turn-in: XP %s · gold %s",
        dg_reward_none = "Turn-in reward: no quest turned in this session",
        dg_not_given   = "not reported",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end

-- Número de verdade dentro da faixa (nem bloqueado, nem NaN, nem infinito).
local function Num(v, lo, hi)
    if type(v) ~= "number" or ns.IsSecret(v) or v ~= v or v < lo or v > hi then return nil end
    return v
end

local function Now()
    local ok, t = pcall(GetTime)
    return ok and Num(t, 0, 1e12) or 0
end

---------------------------------------------------------------------------
-- Estado da sessão (só na memória)
---------------------------------------------------------------------------

local s = {}
local state = { inCombat = false, combatEnd = -1e9, lootOpen = false, lootEnd = -1e9, merchant = false }

function Sources.Reset()
    s = { qx = 0, mx = 0, qn = 0, qg = 0, lg = 0, sg = 0, bg = 0 }
    state.lastMoney = ns.Money and ns.Money() or nil
    state.startMoney = state.lastMoney
    state.xpWait, state.moneyWait = nil, nil  -- entrega sem valor informado: esperando a mudança de XP/ouro
    state.lastXP, state.lastGold = nil, nil   -- última mudança "solta" (para a entrega que chega depois)
    state.reward = nil
end
Sources.Reset()

-- XP e ouro totais da sessão (os mesmos da barra).
local function TotalXP()
    local xp = ns.GetSessionXP and ns.GetSessionXP()
    return Num(xp, 0, MAX) or 0
end

local function TotalGold()
    local money = ns.Money and ns.Money()
    if not Num(money, 0, MAX) or not state.startMoney then return 0 end
    return money - state.startMoney
end

local function InFight(now)
    return state.inCombat or now - state.combatEnd <= COMBAT_GRACE
end

-- Chamado pelo Core (SampleXP) com o XP ganho desde a última leitura.
function Sources.OnXP(delta)
    delta = Num(delta, 0, MAX)
    if not delta or delta == 0 then return end
    local now = Now()
    if state.xpWait and now - state.xpWait <= QUEST_WINDOW then
        s.qx = s.qx + delta; state.xpWait = nil
    elseif InFight(now) then
        s.mx = s.mx + delta
    else
        state.lastXP = { v = delta, t = now } -- pode ser de uma entrega que o jogo avisa logo depois
    end
end

local function OnMoney()
    local money = ns.Money and ns.Money()
    money = Num(money, 0, MAX)
    if not money then return end
    if not state.lastMoney then state.lastMoney = money; state.startMoney = state.startMoney or money; return end
    local delta = money - state.lastMoney
    state.lastMoney = money
    if delta == 0 then return end
    local now = Now()
    if state.merchant then
        if delta > 0 then s.sg = s.sg + delta else s.bg = s.bg - delta end
    elseif delta > 0 and state.moneyWait and now - state.moneyWait <= QUEST_WINDOW then
        s.qg = s.qg + delta; state.moneyWait = nil
    elseif delta > 0 and (state.lootOpen or now - state.lootEnd <= LOOT_GRACE) then
        s.lg = s.lg + delta
    elseif delta > 0 then
        state.lastGold = { v = delta, t = now }
    end
end

local function OnTurnIn(xpReward, moneyReward)
    local now = Now()
    s.qn = s.qn + 1
    local xp, money = Num(xpReward, 0, MAX), Num(moneyReward, 0, MAX)
    state.reward = { xp = xp, money = money }
    if xp then
        s.qx = s.qx + xp
    elseif state.lastXP and now - state.lastXP.t <= QUEST_WINDOW then
        s.qx = s.qx + state.lastXP.v; state.lastXP = nil
    else
        state.xpWait = now
    end
    if money then
        s.qg = s.qg + money
    elseif state.lastGold and now - state.lastGold.t <= QUEST_WINDOW then
        s.qg = s.qg + state.lastGold.v; state.lastGold = nil
    else
        state.moneyWait = now
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "QUEST_TURNED_IN", "PLAYER_MONEY", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                         "LOOT_OPENED", "LOOT_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, _, arg2, arg3)
    if event == "QUEST_TURNED_IN" then
        pcall(OnTurnIn, arg2, arg3)
    elseif event == "PLAYER_MONEY" then
        pcall(OnMoney)
    elseif event == "PLAYER_REGEN_DISABLED" then
        state.inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        state.inCombat = false; state.combatEnd = Now()
    elseif event == "LOOT_OPENED" then
        state.lootOpen = true
    elseif event == "LOOT_CLOSED" then
        state.lootOpen = false; state.lootEnd = Now()
    elseif event == "MERCHANT_SHOW" then
        pcall(OnMoney); state.merchant = true -- o que mudou antes de abrir não é do comerciante
    elseif event == "MERCHANT_CLOSED" then
        pcall(OnMoney); state.merchant = false
    end
end)

---------------------------------------------------------------------------
-- Números da sessão (o que vai para o tooltip e para o resumo salvo)
---------------------------------------------------------------------------

-- Totais por origem; "outros" = total da sessão − as outras origens (a soma sempre bate).
function Sources.Snapshot()
    local xp, gold = TotalXP(), TotalGold()
    local qx = math.min(s.qx, xp)
    local mx = math.min(s.mx, xp - qx)
    local snap = { qx = math.floor(qx), mx = math.floor(mx), qn = s.qn, qg = math.floor(s.qg),
                   lg = math.floor(s.lg), sg = math.floor(s.sg), bg = math.floor(s.bg) }
    snap.ox = math.max(0, math.floor(xp) - snap.qx - snap.mx)
    snap.og = math.floor(gold) - snap.qg - snap.lg - snap.sg + snap.bg
    return snap
end

-- Valida o que veio do resumo salvo (arquivo pode estar adulterado). Inválido = nil.
function Sources.SanitizeSnap(saved)
    if type(saved) ~= "table" then return nil end
    local clean = {}
    for _, key in ipairs({ "qx", "mx", "ox", "qn", "qg", "lg", "sg", "bg" }) do
        local v = Num(saved[key], 0, key == "qn" and 100000 or MAX)
        if not v then return nil end
        clean[key] = math.floor(v)
    end
    local og = Num(saved.og, -MAX, MAX)
    if not og then return nil end
    clean.og = math.floor(og)
    return clean
end

local function Pct(part, total)
    if total <= 0 then return 0 end
    return math.floor(part / total * 100 + 0.5)
end

function Sources.Enabled()
    local db = ns.GetDB and ns.GetDB()
    return db and db.sources == true or false
end

-- Seções do tooltip (Core: TIP.xp e TIP.gold).
function Sources.TipXP(addPair)
    if not Sources.Enabled() then return end
    local snap = Sources.Snapshot()
    local total = snap.qx + snap.mx + snap.ox
    if total <= 0 then return end
    addPair(T("src_xp_title"), ns.FormatBig(total))
    local rows = { { string.format(ns.TN("src_quests", snap.qn), snap.qn), snap.qx }, { T("src_mobs"), snap.mx }, { T("src_other_xp"), snap.ox } }
    for _, row in ipairs(rows) do
        GameTooltip:AddDoubleLine("   " .. row[1], ns.FormatBig(row[2]) .. " · " .. Pct(row[2], total) .. "%",
            0.8, 0.8, 0.8, 1, 1, 1)
    end
end

function Sources.TipGold()
    if not Sources.Enabled() then return end
    local snap = Sources.Snapshot()
    if snap.qg + snap.lg + snap.sg + snap.bg == 0 and snap.og == 0 then return end
    GameTooltip:AddLine(T("src_gold_title"), 1, 0.82, 0)
    local rows = { { "src_q_gold", snap.qg }, { "src_loot", snap.lg }, { "src_sell", snap.sg }, { "src_buy", -snap.bg },
                   { "src_other_gold", snap.og } }
    for _, row in ipairs(rows) do
        GameTooltip:AddDoubleLine("   " .. T(row[1]), ns.FormatMoneyDelta(row[2]), 0.8, 0.8, 0.8, 1, 1, 1)
    end
end

-- Linhas do resumo da sessão (Core: SummaryLines).
function Sources.SummaryLines(src)
    if not Sources.Enabled() or type(src) ~= "table" then return {} end
    local lines = {}
    local total = src.qx + src.mx + src.ox
    if total > 0 then
        lines[#lines + 1] = string.format(T("src_sum_xp"), Pct(src.qx, total), Pct(src.mx, total), Pct(src.ox, total))
    end
    if src.qg + src.lg + src.sg + src.bg ~= 0 or src.og ~= 0 then
        local f = ns.FormatMoneyDelta
        lines[#lines + 1] = string.format(T("src_sum_gold"), f(src.qg), f(src.lg), f(src.sg), f(-src.bg), f(src.og))
    end
    return lines
end

-- Linha do /farol diagnostico: o jogo informou o XP e o ouro da recompensa na entrega?
function Sources.DiagLine()
    local r = state.reward
    if not r then return T("dg_reward_none") end
    local function show(v, money)
        if not v then return T("dg_not_given") end
        return money and ns.FormatMoney(v) or tostring(math.floor(v))
    end
    return string.format(T("dg_reward"), show(r.xp), show(r.money, true))
end

-- Liga/desliga (menu e /farol origem).
function Sources.SetEnabled(value)
    local db = ns.GetDB and ns.GetDB()
    if not db then return end
    db.sources = value and true or false
    ns.Print(db.sources and T("src_on") or T("src_off"))
    if ns.RefreshOptions then ns.RefreshOptions() end
end

local SWITCH = { on = true, ligar = true, ["1"] = true, off = false, desligar = false, ["0"] = false }
function Sources.HandleCommand(rest)
    local word = string.lower(string.match(rest or "", "^%s*(%S*)") or "")
    if SWITCH[word] ~= nil then Sources.SetEnabled(SWITCH[word]) else ns.Print(T("src_usage")) end
end
