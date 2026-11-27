--[[
  Farol — Diagnóstico / Diagnostics (/farol diagnostico)

  Mostra no chat do próprio jogador como o jogo respondeu às leituras que já causaram erro no WoW Forever (reino
  vazio, sobrenome no 2º valor de UnitName, ouro 0 ao sair) e quantas vezes alguns eventos aconteceram nesta sessão
  (entrega de missão, janela de recompensa, missão aceita, mensagem de missão concluída, ouro). Só lê e mostra: nada
  é enviado, nada é pedido ao servidor. As contagens ficam só na memória; o único dado salvo é
  FarolCharDB.diag = { lz = o jogo informou 0 de ouro ao sair (proteção agiu), t = quando }, gravado pelo Core.
  É só um comando: não liga nada nem aparece na barra (regra 8).
]]

local _, ns = ...

local Diag = {}
ns.Diag = Diag

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        dg_title       = "%sDiagnóstico|r %s(só leitura: nada é enviado nem pedido ao servidor)|r",
        dg_char        = "Personagem: %s · reino do jogo: %s → salvo como %s",
        dg_char_none   = "Personagem: o jogo ainda não informou o nome (tente de novo em alguns segundos)",
        dg_name        = "Nome do jogo: %s + %s · nome usado: %s",
        dg_empty       = "\"\" (vazio)",
        dg_nothing     = "nada",
        dg_blocked     = "bloqueado",
        dg_money       = "Ouro agora: %s",
        dg_money_none  = "Ouro agora: -- (o jogo não informou)",
        dg_logout_zero = "Último logout: o jogo informou ouro 0 → mantido o valor anterior %s(proteção ativa)|r",
        dg_logout_ok   = "Último logout: o ouro foi lido normalmente %s(ok)|r",
        dg_logout_none = "Último logout: ainda sem registro (saia do jogo ou use /reload uma vez)",
        dg_clock       = "Hora do servidor: %s · reset diário em %s · semanal em %s",
        dg_quests      = "Missões concluídas no jogo: %s %s(%s)|r · registradas pelo Farol: %d",
        dg_events      = "Eventos nesta sessão: entrega de missão %d · janela de recompensa %d · missão aceita %d · mensagem de missão concluída %d · ouro mudou %d",
        dg_turnin_ok   = "Entrega de missão: o jogo avisa normalmente %s(ok)|r",
        dg_turnin_chat = "%sAtenção:|r o jogo não avisou a entrega, mas mostrou a mensagem de missão concluída (serve de plano B).",
        dg_turnin_none = "%sAtenção:|r houve janela de recompensa, mas o jogo não avisou a entrega nem mostrou a mensagem de missão concluída.",
        dg_saved       = "Personagens salvos neste reino: %d · dados salvos: validados ao carregar",
        dg_hint        = "Dica: tire um print desta lista se for relatar um problema.",
        help_diag      = "  /farol diagnostico   - mostra no chat como o jogo respondeu (só leitura; ajuda a relatar problemas)",
        news_diag      = "novo comando /farol diagnostico: mostra no seu chat como o jogo respondeu (só leitura, nada é enviado)",
    },
    en = {
        dg_title       = "%sDiagnostics|r %s(read-only: nothing is sent or requested from the server)|r",
        dg_char        = "Character: %s · game realm: %s → saved as %s",
        dg_char_none   = "Character: the game has not reported the name yet (try again in a few seconds)",
        dg_name        = "Name from the game: %s + %s · name used: %s",
        dg_empty       = "\"\" (empty)",
        dg_nothing     = "nothing",
        dg_blocked     = "blocked",
        dg_money       = "Gold now: %s",
        dg_money_none  = "Gold now: -- (not reported by the game)",
        dg_logout_zero = "Last logout: the game reported 0 gold → the previous value was kept %s(protection active)|r",
        dg_logout_ok   = "Last logout: gold was read normally %s(ok)|r",
        dg_logout_none = "Last logout: nothing recorded yet (log out or use /reload once)",
        dg_clock       = "Server time: %s · daily reset in %s · weekly in %s",
        dg_quests      = "Completed quests in the game: %s %s(%s)|r · recorded by Farol: %d",
        dg_events      = "Events this session: quest turn-in %d · reward window %d · quest accepted %d · quest completed message %d · gold changed %d",
        dg_turnin_ok   = "Quest turn-in: the game reports it normally %s(ok)|r",
        dg_turnin_chat = "%sAttention:|r the game did not report the turn-in, but showed the quest completed message (works as plan B).",
        dg_turnin_none = "%sAttention:|r there was a reward window, but the game neither reported the turn-in nor showed the quest completed message.",
        dg_saved       = "Characters saved on this realm: %d · saved data: validated on load",
        dg_hint        = "Tip: take a screenshot of this list if you report a problem.",
        help_diag      = "  /farol diag          - shows in chat how the game answered (read-only; helps to report problems)",
        news_diag      = "new command /farol diag: shows in your chat how the game answered (read-only, nothing is sent)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end

---------------------------------------------------------------------------
-- Dados salvos: FarolCharDB.diag = { lz = boolean, t = número }
---------------------------------------------------------------------------

function Diag.Sanitize(saved)
    if type(saved) ~= "table" then return nil end
    local t = saved.t
    if type(t) ~= "number" or t ~= t or t < 0 or t > 4102444800 then return nil end -- também NaN/infinito
    if type(saved.lz) ~= "boolean" then return nil end
    return { lz = saved.lz, t = math.floor(t) }
end

---------------------------------------------------------------------------
-- Contagem de eventos (só na memória desta sessão)
---------------------------------------------------------------------------

local COUNTED = { "QUEST_TURNED_IN", "QUEST_COMPLETE", "QUEST_ACCEPTED", "PLAYER_MONEY", "CHAT_MSG_SYSTEM" }
local counts = {}
Diag.counts = counts
for _, event in ipairs(COUNTED) do counts[event] = 0 end
local CHAT_DONE = "CHAT_DONE" -- mensagem do sistema "<missão> concluída."
counts[CHAT_DONE] = 0

local events = CreateFrame("Frame")
for _, event in ipairs(COUNTED) do pcall(events.RegisterEvent, events, event) end
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "CHAT_MSG_SYSTEM" then
        local ok, title = pcall(function() return ns.Completed and ns.Completed.MatchComplete(arg1) end)
        if not (ok and title) then return end
        event = CHAT_DONE
    end
    if counts[event] and counts[event] < 1000000 then counts[event] = counts[event] + 1 end
end)

---------------------------------------------------------------------------
-- Relatório
---------------------------------------------------------------------------

-- Valor cru vindo do jogo, mostrado com segurança: aspas, "|" escapado, no máximo 48 bytes.
local function Show(value)
    if ns.IsSecret(value) then return T("dg_blocked") end
    if value == nil then return T("dg_nothing") end
    if type(value) ~= "string" then return (string.gsub(string.sub(tostring(value), 1, 48), "|", "||")) end
    if value == "" then return T("dg_empty") end
    return "\"" .. string.gsub(string.sub(value, 1, 48), "|", "||") .. "\""
end

local function Line(fn)
    local ok, text = pcall(fn)
    if ok and type(text) == "string" then ns.Print(text) else ns.Print("--") end
end

function Diag.Report()
    local C = ns.C
    ns.Print(string.format(T("dg_title"), C.warn, C.dim))
    local name, realm = ns.CurrentCharacter()
    Line(function()
        if not name then return T("dg_char_none") end
        local _, _, _, _, rawRealm = ns.ReadIdentity()
        return string.format(T("dg_char"), name, Show(rawRealm), ns.RealmLabel(realm))
    end)
    Line(function()
        local _, first, second = ns.ReadIdentity()
        return string.format(T("dg_name"), Show(first), Show(second), name and Show(name) or "--")
    end)
    Line(function()
        local money = ns.Money()
        if not money then return T("dg_money_none") end
        return string.format(T("dg_money"), ns.FormatMoney(money))
    end)
    Line(function()
        local last = type(FarolCharDB) == "table" and FarolCharDB.diag
        if type(last) ~= "table" then return T("dg_logout_none") end
        return last.lz and string.format(T("dg_logout_zero"), C.good) or string.format(T("dg_logout_ok"), C.good)
    end)
    Line(function()
        local hour, minute = ns.GetServerClock()
        local daily, weekly = ns.GetResetTimes()
        return string.format(T("dg_clock"), hour and string.format("%02d:%02d", hour, minute) or "--",
            daily and ns.FormatCountdown(daily) or "--", weekly and ns.FormatCountdown(weekly) or "--")
    end)
    Line(function()
        local total, source = ns.Completed.ReadTotal()
        local own = 0
        local data = name and FarolDB and type(FarolDB.completed) == "table" and FarolDB.completed[realm]
        data = type(data) == "table" and data[name]
        if type(data) == "table" and type(data.list) == "table" then own = #data.list end
        return string.format(T("dg_quests"), total and tostring(total) or "--", C.dim, tostring(source or "--"), own)
    end)
    Line(function()
        return string.format(T("dg_events"), counts.QUEST_TURNED_IN, counts.QUEST_COMPLETE, counts.QUEST_ACCEPTED,
            counts[CHAT_DONE], counts.PLAYER_MONEY)
    end)
    if counts.QUEST_TURNED_IN > 0 then
        Line(function() return string.format(T("dg_turnin_ok"), C.good) end)
    elseif counts.QUEST_COMPLETE > 0 then
        Line(function()
            return string.format(T(counts[CHAT_DONE] > 0 and "dg_turnin_chat" or "dg_turnin_none"), C.warn)
        end)
    end
    if ns.Sources then Line(ns.Sources.DiagLine) end
    if ns.Combat then Line(ns.Combat.DiagLine) end
    Line(function()
        local list = ns.RealmCharacters()
        return string.format(T("dg_saved"), list and #list or 0)
    end)
    ns.Print(C.dim .. T("dg_hint") .. "|r")
end
