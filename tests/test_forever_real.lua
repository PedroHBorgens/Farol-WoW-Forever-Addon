-- WoW Forever "de verdade" (3.18): o jogo nem sempre responde como a documentação diz. Já aconteceu: reino vazio
-- (GetRealmName() == ""), sobrenome no 2º valor de UnitName("player") e ouro 0 no PLAYER_LOGOUT. Estes testes
-- reproduzem esse jeito de responder e conferem que nada salvo se perde; também testam o /farol diagnostico.
-- WoW Forever as it really answers: empty realm, surname, 0 gold at logout; nothing saved may be lost. Diagnostics.

local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

-- Código do addon sem comentários (para as varreduras de texto).
local FILES = { "Core.lua", "Alarm.lua", "Loot.lua", "Warnings.lua", "Appearance.lua", "Order.lua", "Tasks.lua", "Notes.lua",
                "Goals.lua", "Farm.lua", "Quests.lua", "Hearth.lua", "Runs.lua", "Completed.lua", "Sources.lua", "Diag.lua",
                "MinimapButton.lua" }
local function source(file)
    local f = assert(io.open("Farol/" .. file, "r"))
    local text = f:read("*a"); f:close()
    text = string.gsub(text, "%-%-%[%[.-%]%]", "")
    text = string.gsub(text, "%-%-[^\n]*", "")
    return text
end

-- Como o WoW Forever responde: reino vazio e sobrenome (o ouro 0 ao sair já vem do simulador no modo "forever").
local function forever(Mock, opts, name, surname)
    local H = Mock.new(opts or { locale = "ptBR" })
    H.realm, H.playerName, H.surname = "", name or "Lia", surname or "Montes"
    return H
end

return {
    { "game identity and gold are read in one place only (no direct GetMoney / UnitName('player') / GetRealmName)", function(T)
        local core = source("Core.lua")
        local function body(name)
            local start = assert(string.find(core, "function Profiles%." .. name .. "%("), name)
            local stop = assert(string.find(core, "\nend\n", start, true), name)
            return string.sub(core, start, stop)
        end
        local money, identity = body("Money"), body("ReadIdentity")
        for _, file in ipairs(FILES) do
            local text = source(file)
            if file == "Core.lua" then
                text = string.gsub(text, string.gsub(money, "%p", "%%%0"), "", 1)
                text = string.gsub(text, string.gsub(identity, "%p", "%%%0"), "", 1)
            end
            T.ok(not string.find(text, "GetMoney", 1, true), file .. ": read gold only with ns.Money() / Profiles.Money()")
            T.ok(not string.find(text, "GetRealmName", 1, true), file .. ": read the realm only with ns.CurrentCharacter()")
            T.ok(not string.find(text, "GetNormalizedRealmName", 1, true), file .. ": realm only with ns.CurrentCharacter()")
            T.ok(not string.find(text, 'UnitName%(%s*"player"'), file .. ": the character only with ns.CurrentCharacter()")
            T.ok(not string.find(text, "UnitFullName", 1, true), file .. ": UnitFullName has no surname in WoW Forever")
        end
    end },

    { "two characters with surnames and no realm: gold, level, rest and hearth place survive logout", function(T, Mock)
        local H = forever(Mock, nil, "Lia", "Montes"); H.money = 1520000; H.bind = "Vila do Rio"
        H:login(); H:update(1)
        H:event("PLAYER_LOGOUT")
        local disk, char = H.env.FarolDB, H.env.FarolCharDB
        local me = disk.chars["-"]["Lia Montes"]
        T.eq(me.gold, 1520000, "gold kept although the game said 0 at logout")
        T.eq(me.level, 30); T.eq(me.bind, "Vila do Rio"); T.eq(me.rest, 1500)
        T.eq(char.diag.lz, true, "the protection acted and this is noted for the diagnostics")
        -- Segundo personagem, mesmo nome e outro sobrenome (homônimos não se misturam).
        local B = forever(Mock, nil, "Lia", "Serra"); B.money = 30000
        B:login(disk); B:slash("ouro")
        T.has(all(B), "ouro dos seus personagens em este reino (total 155g 0s):")
        T.has(all(B), "Lia Montes (30): 152g 0s"); T.has(all(B), "Lia Serra (30): 3g 0s — este")
    end },

    { "wrong moment: every game reading returns 0 or empty at logout; nothing saved is lost", function(T, Mock)
        local H = forever(Mock); H.money = 990000; H.bind = "Vila do Rio"
        H:login(); H:event("PLAYER_ENTERING_WORLD", true, false); H:event("UPDATE_INSTANCE_INFO")
        H:slash("show reset"); H:update(61); H:event("PLAYER_LOGOUT")
        local before = H.env.FarolDB.chars["-"]["Lia Montes"]
        T.eq(#before.locks, 2)
        -- Nova sessão: tudo normal durante o jogo; no logout o jogo responde 0/vazio em tudo.
        local B = forever(Mock); B.money = 990000; B.bind = "Vila do Rio"
        B:login(H.env.FarolDB, H.env.FarolCharDB); B:event("PLAYER_ENTERING_WORLD", true, false)
        B:event("UPDATE_INSTANCE_INFO"); B:update(400); B.money = 1000000; B:event("PLAYER_MONEY")
        local env = B.env
        env.GetBindLocation = function() return "" end
        env.UnitXPMax = function() return 0 end
        env.GetXPExhaustion = function() return nil end
        env.GetNumSavedInstances = function() return 0 end
        env.C_QuestLog.GetAllCompletedQuestIDs = function() return {} end
        B:event("PLAYER_LOGOUT")
        local after = B.env.FarolDB.chars["-"]["Lia Montes"]
        T.eq(after.gold, 1000000, "gold"); T.eq(after.level, 30, "level")
        T.eq(after.bind, "Vila do Rio", "hearth place")
        T.eq(after.rest, 1500, "rested XP"); T.eq(after.max, 10000, "level XP")
        T.eq(#(after.locks or {}), 2, "saved instances")
        T.eq(B.env.FarolCharDB.lastSession.money, 10000, "session summary: +1g, not -99g")
        -- Nome também some no logout: nada é gravado por cima (os dados anteriores ficam).
        local C = forever(Mock); C.money = 5
        C:login(B.env.FarolDB, B.env.FarolCharDB); C:update(61)
        C.playerName, C.surname = nil, nil; C:event("PLAYER_LOGOUT")
        T.eq(C.env.FarolDB.chars["-"]["Lia Montes"].gold, 5, "last in-game reading kept")
    end },

    { "/farol diagnostico: identity, gold, logout, clock, quests, events and saved characters (read-only)", function(T, Mock)
        local H = forever(Mock); H.money = 1523405; H.completedIDs = { 1, 2, 3 }
        H:login({ chars = { ["-"] = { ["Ana Lobo"] = { gold = 1, level = 2, t = 1 } } } })
        H:slash("diagnostico")
        local text = all(H)
        T.has(text, "Farol: Diagnóstico (só leitura: nada é enviado nem pedido ao servidor)")
        T.has(text, 'Personagem: Lia Montes · reino do jogo: "" (vazio) → salvo como este reino')
        T.has(text, 'Nome do jogo: "Lia" + "Montes" · nome usado: "Lia Montes"')
        T.has(text, "Ouro agora: 152g 34s 5c")
        T.has(text, "Último logout: ainda sem registro (saia do jogo ou use /reload uma vez)")
        T.has(text, "Hora do servidor: 21:05 · reset diário em 5h 12m · semanal em 2d 4h")
        T.has(text, "Missões concluídas no jogo: 3 (C_QuestLog.GetAllCompletedQuestIDs) · registradas pelo Farol: 0")
        T.has(text, "Eventos nesta sessão: entrega de missão 0 · janela de recompensa 0 · missão aceita 0")
        T.has(text, "Personagens salvos neste reino: 2 · dados salvos: validados ao carregar")
        T.hasnt(text, "Atenção", "no turn-in warning without a reward window")
        -- Janela de recompensa sem aviso de entrega: avisa; com a mensagem do sistema: plano B.
        H.msgs = {}; H.rewardQuest = { id = 501, title = "Entrega" }; H:event("QUEST_COMPLETE")
        H:slash("diag"); T.has(all(H), "Atenção: houve janela de recompensa, mas o jogo não avisou a entrega nem mostrou")
        H.msgs = {}; H:event("CHAT_MSG_SYSTEM", "Entrega concluída."); H:event("CHAT_MSG_SYSTEM", "Outra coisa.")
        H:slash("diag"); T.has(all(H), "mensagem de missão concluída 1")
        T.has(all(H), "Atenção: o jogo não avisou a entrega, mas mostrou a mensagem de missão concluída (serve de plano B).")
        H.msgs = {}; H:event("QUEST_TURNED_IN", 501, 0, 0); H:event("PLAYER_MONEY")
        H:slash("diag"); T.has(all(H), "entrega de missão 1"); T.has(all(H), "ouro mudou 1")
        T.has(all(H), "Entrega de missão: o jogo avisa normalmente (ok)")
        -- Depois de sair: a proteção do ouro aparece; no cliente antigo (ouro lido normalmente), "ok".
        H:event("PLAYER_LOGOUT")
        local B = forever(Mock); B:login(H.env.FarolDB, H.env.FarolCharDB); B:slash("diagnostico")
        T.has(all(B), "Último logout: o jogo informou ouro 0 → mantido o valor anterior (proteção ativa)")
        local W = Mock.new({ mode = "wotlk", locale = "ptBR" }); W.realm, W.surname = "Azralon", nil
        W:login(); W:event("PLAYER_LOGOUT")
        local W2 = Mock.new({ mode = "wotlk", locale = "ptBR" }); W2.realm, W2.surname = "Azralon", nil
        W2:login(W.env.FarolDB, W.env.FarolCharDB)
        W2:slash("diagnostico"); T.has(all(W2), "Último logout: o ouro foi lido normalmente (ok)")
        T.has(all(W2), "reino do jogo: \"Azralon\" → salvo como Azralon")
        T.has(all(W2), 'Nome do jogo: "Garrosh" + nada · nome usado: "Garrosh"')
    end },

    { "diagnostics never break: blocked, broken or strange game values; English texts", function(T, Mock)
        local H = forever(Mock, { locale = "enUS" }, "Li|cffff0000a")
        H:login()
        H.env.GetMoney = function() error("blocked") end
        H.env.GetGameTime = function() return 0 / 0, 1 end
        H.env.C_QuestLog.GetAllCompletedQuestIDs = function() error("no") end
        H:slash("diag")
        local text = all(H)
        T.has(text, "Diagnostics (read-only: nothing is sent or requested from the server)")
        T.has(text, "Gold now: -- (not reported by the game)")
        T.has(text, "Server time: -- · daily reset in 5h 12m")
        T.has(text, "Completed quests in the game: -- (--)")
        T.has(text, "Tip: take a screenshot")
        T.has(table.concat(H.msgs, "\n"), '"Li||cffff0000a"', "shown escaped")
        for _, msg in ipairs(H.msgs) do
            local raw = string.gsub(msg, "||", "")
            T.ok(not string.find(raw, "|cffff0000a", 1, true), "a '|' from the game is escaped, never a color code")
        end
        -- Nome ainda não informado: diz isso em vez de ficar em silêncio.
        local N = forever(Mock); N.playerName = nil; N:login(); N:slash("diagnostico")
        T.has(all(N), "Personagem: o jogo ainda não informou o nome")
        -- Modo "secret" (valores bloqueados em combate): nada quebra.
        local S = Mock.new({ mode = "secret", locale = "ptBR" }); S:login(); S:slash("diagnostico")
        T.has(all(S), "Dica: tire um print desta lista")
    end },

    { "saved diagnostics marker is validated on load", function(T, Mock)
        for _, bad in ipairs({ "x", 5, { lz = "sim", t = 10 }, { lz = true, t = 0 / 0 }, { lz = true, t = -1 },
                               { lz = true, t = 1 / 0 }, { lz = true } }) do
            local H = Mock.new(); H:login(nil, { diag = bad })
            T.eq(H.env.FarolCharDB.diag, nil, "bad marker dropped")
        end
        local H = Mock.new(); H:login(nil, { diag = { lz = false, t = 12.7, extra = "x" } })
        T.eq(H.env.FarolCharDB.diag.lz, false); T.eq(H.env.FarolCharDB.diag.t, 12); T.eq(H.env.FarolCharDB.diag.extra, nil)
    end },
}
