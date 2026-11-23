-- Missões concluídas (3.14): registro das entregas por personagem (desligado até o jogador ligar), total do jogo,
-- janela com personagem/busca/rolagem, item da barra e tooltip, cliente antigo pela mensagem do sistema, dados
-- adulterados, "esquecer personagem", diagnóstico e inglês.
-- Completed quests (3.14): per-character turn-in log (off until the player turns it on), game total, window,
-- bar item and tooltip, old client via the system message, tampered data, forgetting a character, status, English.

local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function own(H) return H.env.FarolDB.completed[H.realm] and H.env.FarolDB.completed[H.realm][H.playerName] end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function ids(n) local t = {} for i = 1, n do t[i] = i end return t end
-- Entrega uma missão como o jogo faz: abre a recompensa (QUEST_COMPLETE) e confirma (QUEST_TURNED_IN).
local function turnIn(H, id, title)
    H.rewardQuest = { id = id, title = title }
    H:event("QUEST_COMPLETE")
    H.rewardQuest = nil
    if H.completedIDs then H.completedIDs[#H.completedIDs + 1] = id end
    H:event("QUEST_TURNED_IN", id, 1200, 500)
end

return {
    { "off by default: nothing is recorded or saved until the player turns recording on", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.completedIDs = ids(412)
        H:login()
        T.eq(H.env.FarolDB.questRecord, false); T.eq(H.env.FarolDB.items.qdone, false)
        T.hasnt(H:bar(), "Concluídas")
        turnIn(H, 501, "Entrega na Baía do Farol")
        T.eq(own(H), nil, "nothing saved while recording is off")
        H:slash("mostrar concluidas"); H:update(1)
        T.has(H:bar(), "Concluídas 413", "the bar item reads the game total live (counts the turn-in)")
    end },

    { "recording: name, level, zone and time of each turn-in; duplicates ignored; total saved", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.completedIDs = ids(412)
        H.quests = { { title = "Lobos da Colina", level = 31, done = true } }
        H:login()
        H:slash("concluidas registrar on"); T.has(H:lastMsg(), "registro de missões entregues: ligado")
        turnIn(H, 1001, "Lobos da Colina")
        local data = own(H)
        T.eq(#data.list, 1); T.eq(data.list[1].n, "Lobos da Colina"); T.eq(data.list[1].i, 1001)
        T.eq(data.list[1].l, 31, "level read from the quest log before turning in")
        T.eq(data.list[1].z, "Floresta de Elwynn"); T.ok(data.list[1].t > 0)
        T.eq(data.t, 413, "game total saved with recording on")
        H:event("QUEST_TURNED_IN", 1001, 0, 0); T.eq(#own(H).list, 1, "same quest again within seconds: ignored")
        -- Sem a janela de recompensa: nome pelo C_QuestLog.GetTitleForQuestID; sem nome: "Missão #id".
        H.questTitles[777] = "O Mapa |cffff0000Rasgado"
        H:event("QUEST_TURNED_IN", 777, 0, 0)
        T.eq(own(H).list[2].n, "O Mapa cffff0000Rasgado", "'|' removed from quest names")
        H:event("QUEST_TURNED_IN", 888, 0, 0); T.eq(own(H).list[3].n, "Missão #888")
        H:slash("concluidas registrar off"); turnIn(H, 999, "Depois")
        T.eq(#own(H).list, 3, "off again: the list stays, nothing new is added")
        H:slash("concluidas talvez"); T.has(H:lastMsg(), "uso: /farol concluidas")
    end },

    { "old client: the system message '<quest> completed.' is recorded; modern clients ignore it", function(T, Mock)
        local H = Mock.new({ mode = "wotlk", locale = "enUS" }); H.completedMap = { [1] = true, [2] = true, [3] = true }
        H:login({ questRecord = true })
        H:event("CHAT_MSG_SYSTEM", "Wolves of the Hill completed.")
        T.eq(own(H).list[1].n, "Wolves of the Hill"); T.eq(own(H).t, 4, "GetQuestsCompleted count (3) + the turn-in just seen")
        H:event("CHAT_MSG_SYSTEM", "Someone has come online.")
        H:event("CHAT_MSG_SYSTEM", string.rep("x", 400) .. " completed.")
        T.eq(#own(H).list, 1, "other or huge messages are ignored")
        H.completedMap = {}
        local M = Mock.new({ mode = "wotlk" }); M:login({ questRecord = true })
        M:slash("aviso status"); T.has(all(M), "missões concluídas: total --", "empty list = the game did not report it")
        local N = Mock.new(); N:login({ questRecord = true })
        N:event("CHAT_MSG_SYSTEM", "Lobos concluída.")
        T.eq(own(N), nil, "modern client: only QUEST_TURNED_IN counts (no duplicates)")
    end },

    { "window: character menu, search, scroll, counts, empty states and the record checkbox", function(T, Mock)
        local list = {}
        for i = 1, 30 do list[i] = { i = 2000 + i, n = (i % 2 == 0 and "Lobos " or "Ervas ") .. i, l = 20, z = "Vale", t = 1700000000 + i } end
        local saved = { questRecord = true, completed = { Azralon = {
            Garrosh = { t = 412, tt = 1700000000, list = { { n = "Minha missão", t = 1700000000 } } },
            Mira = { t = 468, tt = 1700000100, list = list } } } }
        local H = Mock.new({ locale = "ptBR" }); H.completedIDs = ids(412)
        H:login(saved)
        H:slash("concluidas")
        local W = H.env.FarolCompleted
        T.ok(W:IsShown()); T.eq(H.env.UISpecialFrames[#H.env.UISpecialFrames], "FarolCompleted")
        T.eq(H:text(H.env.FarolCompletedChar), "Garrosh — este")
        T.has(H:text(W.totalText), "Total no jogo: 412"); T.eq(H:text(W.recorded), "Registradas: 1")
        T.eq(H:text(W.rows[1].name), "Minha missão")
        T.eq(H:text(W.rows[1].id), "--", "no ID saved: shows --")
        -- Outro personagem pelo menu.
        H:click(H.env.FarolCompletedChar)
        local entries = {}
        for i = 1, 5 do local e = H.env["FarolCompletedCharEntry" .. i]; if e and e:IsShown() then entries[#entries + 1] = H:text(e.text) end end
        T.eq(table.concat(entries, ","), "Garrosh — este,Mira")
        H:click(H.env.FarolCompletedCharEntry2)
        T.eq(H:text(H.env.FarolCompletedChar), "Mira"); T.has(H:text(W.totalText), "468")
        T.eq(H:text(W.rows[1].name), "Lobos 30", "newest first"); T.eq(H:text(W.scrollInfo), "1–12 de 30")
        T.eq(H:text(W.rows[1].id), "#2030", "the game's quest ID is shown")
        W._scripts.OnMouseWheel(W, -1); T.eq(H:text(W.rows[1].name), "Ervas 27"); T.eq(H:text(W.scrollInfo), "4–15 de 30")
        H.env.FarolCompletedSearch:SetText("lobos"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.scrollInfo), "1–12 de 15"); T.eq(H:text(W.rows[1].name), "Lobos 30")
        -- Busca pelo ID da missão ("2015" ou "#2015").
        H.env.FarolCompletedSearch:SetText("2015"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.scrollInfo), "1–1 de 1"); T.eq(H:text(W.rows[1].name), "Ervas 15"); T.eq(H:text(W.rows[1].id), "#2015")
        H.env.FarolCompletedSearch:SetText("#2030"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.rows[1].name), "Lobos 30")
        H.env.FarolCompletedSearch:SetText("nada assim"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.empty), "Nenhuma missão com esse nome ou ID."); T.ok(not W.rows[1].name:IsShown())
        H:check(H.env.FarolCompletedRecord, false); T.eq(H.env.FarolDB.questRecord, false)
        local E = Mock.new({ locale = "ptBR" }); E:login(); E:slash("concluidas")
        T.has(E:text(E.env.FarolCompleted.empty), "Marque \"Registrar missões entregues\"")
        T.eq(E:text(E.env.FarolCompleted.totalText):match("Total no jogo: %-%-") ~= nil, true, "no total: --")
    end },

    { "tooltip: totals of each character, today's count and the latest quests", function(T, Mock)
        local now = 1800000000
        local H = Mock.new({ locale = "ptBR" }); H.completedIDs = ids(412)
        H.env.time = function(t) if t then return os.time(t) end return now end
        H:login({ questRecord = true, items = { qdone = true },
            chars = { Azralon = { Mira = { gold = 1, level = 34, t = 1 } } },
            completed = { Azralon = { Mira = { t = 468, tt = 1 } } } })
        turnIn(H, 501, "Entrega na Baía"); turnIn(H, 502, "Lobos da Colina")
        H:update(1)
        local t = tip(H)
        T.has(t, "Missões concluídas"); T.has(t, "Garrosh (este) = 414 · hoje +2"); T.has(t, "Mira (34) = 468")
        T.has(t, "Últimas: Lobos da Colina · Entrega na Baía")
    end },

    { "saved data is validated: bad types, NaN, '|', too many entries, realms and names", function(T, Mock)
        local big = {}
        for i = 1, 2500 do big[i] = { i = i, n = "M" .. i, t = 1700000000 + i } end
        local realms = {}
        for r = 1, 25 do realms["R" .. r] = { N = { t = r, tt = r } } end
        realms.Azralon = { Garrosh = { t = 0 / 0, tt = "x", list = big },
            ["Bad|Name"] = { t = 5 }, Mira = { t = 1 / 0 }, Tor = "x",
            Ana = { list = { { n = "|cffff0000Ok|r", t = 1 }, { n = "", t = 1 }, { n = "X", t = -1 }, { n = "Y", t = 1, i = 1.5, l = 999, z = {} } } } }
        local H = Mock.new():login({ completed = realms })
        local data = H.env.FarolDB.completed
        local count = 0
        for _ in pairs(data) do count = count + 1 end
        T.eq(count, 20, "at most 20 realms")
        local g = data.Azralon.Garrosh
        T.eq(#g.list, 2000, "the 2000 most recent"); T.eq(g.list[2000].n, "M2500"); T.eq(g.list[1].n, "M501")
        T.eq(g.t, nil); T.eq(g.tt, nil)
        T.eq(data.Azralon["Bad|Name"], nil); T.eq(data.Azralon.Mira, nil); T.eq(data.Azralon.Tor, nil)
        local a = data.Azralon.Ana.list
        T.eq(#a, 2); T.eq(a[1].n, "cffff0000Okr"); T.eq(a[2].n, "Y"); T.eq(a[2].i, nil); T.eq(a[2].l, nil); T.eq(a[2].z, nil)
        for _, bad in ipairs({ "x", 5, 0 / 0, { Azralon = "x" }, { [{}] = {} } }) do
            local ok, err = pcall(function() Mock.new():login({ completed = bad }) end); T.ok(ok, tostring(err))
        end
    end },

    { "forgetting a character also forgets its quest list", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        H:login({ chars = { Azralon = { Mira = { gold = 1, level = 34, t = 1 }, Tor = { gold = 1, level = 12, t = 1 } } },
                  completed = { Azralon = { Mira = { t = 5 }, Tor = { t = 7 } } } })
        H:slash("ouro esquecer Mira")
        T.eq(H.env.FarolDB.completed.Azralon.Mira, nil); T.ok(H.env.FarolDB.completed.Azralon.Tor)
        H:slash("menu"); H:click(H.env.FarolOptions.controls.tabs.general)
        local forget = H.env.FarolOptions.controls.forget
        H:click(forget); H:click(forget) -- "Esquecer personagens" pede um segundo clique
        T.eq(H.env.FarolDB.completed.Azralon, nil, "forget all clears the others' lists")
    end },

    { "blocked or broken game values never break anything; status line; English", function(T, Mock)
        local H = Mock.new({ mode = "secret" }); H:login({ questRecord = true, items = { qdone = true } })
        H.env.C_QuestLog.GetAllCompletedQuestIDs = function() error("bloqueado") end
        H.env.GetQuestID = function() error("x") end; H.env.GetTitleText = function() return 0 / 0 end
        H.env.GetRealZoneText = function() error("x") end; H.env.GetZoneText = nil
        H:event("QUEST_COMPLETE"); H:event("QUEST_TURNED_IN", 0 / 0); H:event("QUEST_TURNED_IN", -5)
        H:event("QUEST_TURNED_IN", 123)
        H:event("PLAYER_ENTERING_WORLD"); H:update(1)
        T.has(H:bar(), "Concluídas 1", "no game total: shows the recorded count")
        tip(H); H:slash("concluidas"); H:slash("aviso status")
        T.has(all(H), "missões concluídas: total -- (função: --) · registro ligado, 1 registradas.")
        local E = Mock.new({ locale = "enUS" }); E.completedIDs = ids(3); E:login(); E:slash("show completed"); E:update(1)
        T.has(E:bar(), "Completed 3"); E:slash("completed")
        T.eq(E:text(E.env.FarolCompleted.title), "Completed quests")
        T.has(E:text(E.env.FarolCompletedRecord.label), "Record turned-in quests")
        E:slash("help"); T.has(all(E), "/farol completed")
    end },

    { "earlier quests by ID only: off by default, listed after the recorded ones, searchable, saved only when recording", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.completedIDs = { 5, 3, 1001, 9, 3, 0 / 0, -1 }
        H.quests = { { title = "Lobos", level = 31, done = true } }
        H:login()
        H:event("PLAYER_ENTERING_WORLD"); T.eq(own(H), nil, "recording off: no IDs are saved")
        H:slash("concluidas registrar on")
        turnIn(H, 1001, "Lobos")
        H:slash("concluidas")
        local W = H.env.FarolCompleted
        T.eq(table.concat(own(H).a, ","), "3,5,9,1001", "valid IDs, sorted, no repeats")
        T.eq(H.env.FarolCompletedOld._checked, false, "option off by default"); T.eq(H.env.FarolDB.questShowOld, false)
        T.eq(H:text(W.scrollInfo), "1–1 de 1", "only the recorded quest")
        T.eq(H:text(H.env.FarolCompletedOld.label), "Mostrar missões de antes do registro (só o ID)")
        H:check(H.env.FarolCompletedOld, true); T.eq(H.env.FarolDB.questShowOld, true)
        T.eq(H:text(W.scrollInfo), "1–4 de 4")
        T.eq(H:text(W.rows[1].name), "Lobos"); T.eq(H:text(W.rows[1].id), "#1001")
        T.eq(H:text(W.rows[2].id), "#9"); T.has(H:text(W.rows[2].name), "(antes do registro)"); T.eq(H:text(W.rows[2].when), "")
        T.eq(H:text(W.rows[4].id), "#3", "highest IDs first; the recorded one is not repeated")
        H.env.FarolCompletedSearch:SetText("5"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.scrollInfo), "1–1 de 1"); T.eq(H:text(W.rows[1].id), "#5")
        H.env.FarolCompletedSearch:SetText("antes"); H.env.FarolCompletedSearch._scripts.OnTextChanged(H.env.FarolCompletedSearch)
        T.eq(H:text(W.empty), "Nenhuma missão com esse nome ou ID.", "earlier quests have no name to search")
        -- Cliente antigo: IDs pelo GetQuestsCompleted (mapa).
        local O = Mock.new({ mode = "wotlk" }); O.completedMap = { [12] = true, [7] = true }
        O:login({ questRecord = true }); T.eq(table.concat(own(O).a, ","), "7,12")
    end },

    { "saved earlier IDs are validated: bad values and repeats dropped, at most 15000 (the highest)", function(T, Mock)
        local a = { 1, 1, "x", 0 / 0, -3, 2.5, 99999999999 }
        for i = 1, 16000 do a[#a + 1] = 100 + i end
        local H = Mock.new():login({ completed = { Azralon = { Garrosh = { a = a }, Mira = { a = "x" }, Tor = { a = { "y" } } } } })
        local g = H.env.FarolDB.completed.Azralon.Garrosh.a
        T.eq(#g, 15000); T.eq(g[15000], 16100); T.eq(g[1], 1101)
        T.eq(H.env.FarolDB.completed.Azralon.Mira, nil); T.eq(H.env.FarolDB.completed.Azralon.Tor, nil)
    end },
}
