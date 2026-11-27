-- Central do Farol (3.27, estilo detalhado): desligada por padrão; barra lateral, página Início em cartões,
-- janelas de sempre encaixadas e devolvidas; volta ao estilo simples. Só lê; nada é enviado.
-- Farol hub: off by default; side bar, Home cards, regular windows docked and released; back to simple style.

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "new install: detailed style on (owner, 3.28); existing users keep the simple style", function(T, Mock)
        local N = Mock.new({ locale = "ptBR" }):login()
        T.eq(N.env.FarolDB.hub, true, "new install starts in the detailed style")
        local U = Mock.new():login({ items = { fps = true } })
        T.eq(U.env.FarolDB.hub, false, "rule 8: updating never turns it on")
        local K = Mock.new():login({ items = { fps = true }, hub = true })
        T.eq(K.env.FarolDB.hub, true, "a saved choice is kept")
        local Z = Mock.new():login({ hub = false })
        T.eq(Z.env.FarolDB.hub, false, "a saved 'off' is kept even without items")
        N.ns.MinimapButton.Click("LeftButton"); T.ok(N.env.FarolHub and N.env.FarolHub:IsShown(), "minimap opens the hub")
    end },

    { "simple style for existing users (windows open on their own); /farol central turns it on and opens Home", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ items = { fps = true } })
        T.eq(H.env.FarolDB.hub, false, "rule 8: off")
        H:slash("notas"); T.ok(H.env.FarolNotes:IsShown())
        T.eq(H.env.FarolNotes:GetParent(), H.env.UIParent, "simple style: not docked"); T.eq(H.env.FarolHub, nil, "hub not even created")
        H:slash("notas")
        H:slash("central"); T.eq(H.env.FarolDB.hub, true); T.has(chat(H), "Central do Farol ligada")
        local hub = H.env.FarolHub
        T.ok(hub and hub:IsShown(), "hub open"); T.eq(H.env.UISpecialFrames[#H.env.UISpecialFrames], "FarolHub", "Esc closes it")
        T.eq(H:text(H.env.FarolHubNavhome.text), "Início"); T.eq(H:text(H.env.FarolHubNavsettings.text), "Configurações")
        T.ok(H.env.FarolHubNavhome.mark:IsShown(), "Home is the open section")
        local home = hub.pages.home
        T.has(H:text(home.hero.title), "Esta sessão"); T.eq(H:text(home.stats[1].label), "Ouro na sessão")
        T.ok(H:text(home.stats[1].value) ~= "", "session gold shown"); T.eq(H:text(home.stats[4].label), "XP por hora")
        T.eq(H:text(home.cards[3].rows[1].left), "Durabilidade"); T.eq(H:text(home.cards[3].rows[1].right), "15%", "label stripped from the bar text")
        T.has(H:text(home.xpText), "XP 62% do nível")
        H:slash("central"); T.ok(not hub:IsShown(), "/farol central toggles it closed")
    end },

    { "detailed style: windows open docked in the hub, switch sections, give back on close", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = true })
        H:slash("notas")
        local hub, notes = H.env.FarolHub, H.env.FarolNotes
        T.ok(hub and hub:IsShown(), "opening a window opens the hub")
        T.eq(notes:GetParent(), H.env.FarolHubContent, "docked in the content area"); T.eq(notes.farolDocked, true)
        T.ok(H.env.FarolHubNavnotes.mark:IsShown(), "Notes marked in the side bar"); T.ok(not H.env.FarolHubNavhome.mark:IsShown())
        H:click(H.env.FarolHubNavtasks)
        local tasks = H.env.FarolTasks
        T.ok(tasks:IsShown()); T.eq(tasks:GetParent(), H.env.FarolHubContent, "Tasks docked")
        T.ok(not notes:IsShown(), "previous window hidden"); T.eq(notes:GetParent(), H.env.UIParent, "and given back")
        tasks:Hide(); T.ok(hub:IsShown(), "closing the docked window keeps the hub"); T.ok(H.env.FarolHubNavhome.mark:IsShown(), "back to Home")
        T.eq(tasks:GetParent(), H.env.UIParent)
        H:click(H.env.FarolHubNavsettings); T.ok(H.env.FarolOptions:IsShown()); T.eq(H.env.FarolOptions:GetParent(), H.env.FarolHubContent)
        hub:Hide(); T.ok(not H.env.FarolOptions:IsShown(), "closing the hub closes the docked window"); T.eq(H.env.FarolOptions:GetParent(), H.env.UIParent)
        -- arrastar a janela encaixada move a Central (e o arrasto original volta ao devolver)
        H:slash("tarefa"); T.eq(tasks.farolDocked, true); T.ok(tasks:GetScript("OnDragStart") ~= tasks.farolUndock.dragStart)
        local original = tasks.farolUndock.dragStart
        tasks:Hide(); T.eq(tasks:GetScript("OnDragStart"), original, "drag restored")
        -- clique num cartão abre a seção
        H:slash("central"); H:slash("central") -- fecha e abre
        H:click(hub.pages.home.cards[5]); T.ok(H.env.FarolKeep:IsShown(), "Kept items card opens the section")
    end },

    { "own pages: characters and professions; back to simple style; menu checkbox and minimap", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        H.profs = { { "Alquimia", 150, 150, true }, { "Pesca", 40, 75 } }
        H:login({ hub = true })
        H:slash("central"); local hub = H.env.FarolHub
        H:click(H.env.FarolHubNavprofs)
        local profs = hub.pages.profs
        T.ok(profs:IsShown()); T.ok(not hub.pages.home:IsShown())
        local c1, c2 = profs.cards[1], profs.cards[2]
        T.eq(H:text(c1.title), "Alquimia"); T.eq(H:text(c1.badge), "[Artífice]")
        T.has(H:text(c1.sub), "150 / 150"); T.has(H:text(c1.sub), "no limite")
        T.eq(H:text(c1.session.left), "Próximo passo"); T.has(H:text(c1.session.right), "procure um instrutor para treinar Perito")
        T.eq(H:text(c1.track.limitText), "seu limite 150"); T.eq(H:text(c1.track.labels[4]), "300 · Artesão")
        T.eq(H:text(c2.title), "Pesca"); T.eq(H:text(c2.badge), "[Aprendiz]"); T.has(H:text(c2.sub), "40 / 75")
        T.has(H:text(c2.session.right), "sem mudança")
        -- subiu na sessão: parte dourada e "+N pontos"
        H.profs[2][2] = 49; H:event("SKILL_LINES_CHANGED")
        T.has(H:text(c2.session.right), "+9"); T.ok(c2.track.gain:IsShown(), "gain shown in gold")
        T.ok(not profs.cards[3]:IsShown(), "only the professions you have")
        -- Personagens: tabela, instâncias e descanso
        H:click(H.env.FarolHubNavchars)
        local chars = hub.pages.chars
        T.ok(chars:IsShown()); T.eq(H:text(chars.table.title), "Personagens deste reino")
        T.eq(H:text(chars.heads[5]), "PEDRA DE REGRESSO")
        local first = chars.rows[1].cells
        T.has(H:text(first[1]), "— você", "current character first"); T.eq(H:text(first[6]), "agora")
        T.has(H:text(chars.locks.title), "Instâncias salvas"); T.has(H:text(chars.rest.title), "Descanso")
        H:click(H.env.FarolHubSimple); T.eq(H.env.FarolDB.hub, false); T.ok(not hub:IsShown()); T.has(H:lastMsg(), "estilo simples")
        H:slash("notas"); T.eq(H.env.FarolNotes:GetParent(), H.env.UIParent, "simple again: not docked"); H:slash("notas")
        H:slash("menu"); local set = H.env.FarolOptions.controls; H:click(set.tabs.general)
        T.eq(H:text(set.hub.label), "Estilo detalhado (Central do Farol)"); T.eq(set.hub._checked, false)
        H:check(set.hub, true); T.eq(H.env.FarolDB.hub, true)
        T.eq(H.env.FarolOptions:GetParent(), H.env.FarolHubContent, "the open menu moves into the hub")
        H.env.FarolHub:Hide()
        H.ns.MinimapButton.Click("LeftButton"); T.ok(H.env.FarolHub:IsShown(), "minimap click opens the hub in detailed style")
        H:slash("central talvez"); T.has(H:lastMsg(), "uso: /farol central")
        H:slash("central off"); T.eq(H.env.FarolDB.hub, false)
    end },

    { "characters page: other characters with rest estimate and saved instances (any realm name)", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = true }); H:update(1)
        local name, realm = H.ns.CurrentCharacter()
        local now = H.env.time()
        H.env.FarolDB.chars[realm]["Mira"] = { gold = 10000000, level = 34, t = now - 3600, rest = 1500, max = 1000, inn = true,
            bind = "Vila do Vale", locks = { { n = "Cripta Antiga", k = 2, b = 5, r = now + 2 * 86400 } } }
        H.env.FarolDB.chars[realm]["Tor"] = { gold = 500, level = 12, t = now - 86400, rest = 100, max = 1000, inn = true }
        H:slash("central"); H:click(H.env.FarolHubNavchars)
        local chars = H.env.FarolHub.pages.chars
        T.has(H:text(chars.rows[1].cells[1]), "— você")
        T.eq(H:text(chars.rows[2].cells[1]), "Mira"); T.eq(H:text(chars.rows[2].cells[5]), "Vila do Vale")
        T.has(H:text(chars.rows[2].cells[4]), "cheio")
        T.eq(H:text(chars.lockLines[1].left), "Mira — Cripta Antiga"); T.has(H:text(chars.lockLines[1].right), "2 de 5 chefes")
        T.has(H:text(chars.lockLines[1].right), "reseta em 2d")
        T.eq(H:text(chars.restLines[1].left), "Mira (34)"); T.has(H:text(chars.restLines[1].right), "pronto para upar")
        T.has(H:text(chars.restLines[2].right), "cheio em ~")
        T.has(H:text(chars.table.sub), "Ouro da conta")
    end },

    { "3.29: the medallion shows the Farol icon file (not the chat code)", function(T, Mock)
        local H = Mock.new():login({ hub = true }); H:slash("central")
        local tex = H.env.FarolHub.medal._texture
        T.eq(tex, "Interface\\AddOns\\Farol\\Media\\Farol"); T.hasnt(tostring(tex), "|T")
    end },

    { "3.29: Tasks in cards inside the hub (daily | weekly), back to the usual layout outside", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = true })
        H:slash("tarefa add Pescaria"); H:slash("tarefa add semanal Masmorra"); H:slash("tarefa add Ervas")
        H:slash("tarefa feita 1")
        H:slash("tarefa"); local W = H.env.FarolTasks
        T.eq(W.farolDocked, true); T.eq(W:GetWidth(), 770, "detailed size")
        local p = W.farolPanels
        T.eq(H:text(p.daily.title), "Diárias"); T.has(H:text(p.daily.sub), "1 de 2 · reseta em")
        T.eq(H:text(p.weekly.title), "Semanais"); T.has(H:text(p.weekly.sub), "0 de 1")
        T.ok(p.daily.bg:IsShown(), "panels shown"); T.eq(W.farolBars.daily.fill:GetWidth(), 174, "half of the bar")
        T.eq(W.rows[2].check._x, 402, "weekly task in the right column"); T.eq(W.rows[3].check._x, 20, "daily task in the left one")
        T.ok(not W.hint:IsShown(), "hint moved into the panel"); T.eq(W._bgAlpha, 0, "dialog frame hidden: the hub has its own")
        W:Hide()
        T.ok(not p.daily.bg:IsShown(), "panels hidden outside the hub"); T.eq(W:GetWidth(), 460, "usual size back")
        H:slash("central off"); H:slash("tarefa")
        T.eq(W.rows[2].check._x, 20, "usual layout back"); T.ok(W.hint:IsShown())
    end },

    { "3.29: Notes and Kept items in cards inside the hub", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        H.items[7001] = { "Erva-de-luar", 2, 25 }; H.itemCounts[7001] = 4
        H:login({ hub = true, notes = { { t = "Rota", x = "a", m = 1800000000 }, { t = "Feita", x = "", d = true } } })
        H:slash("notas"); local N = H.env.FarolNotes
        T.eq(N.farolDocked, true); T.ok(N.farolPanels.list.bg:IsShown())
        T.eq(H:text(N.farolPanels.list.title), "Anotações"); T.eq(H:text(N.farolPanels.list.sub), "1 de 2 pendentes")
        T.ok(not N.title:IsShown(), "window title hidden: the hub has the section")
        N:Hide(); T.ok(not N.farolPanels.list.bg:IsShown()); T.ok(N.title:IsShown(), "title back outside the hub")
        H:slash("guardar |cff1eff00|Hitem:7001::|h[Erva-de-luar]|h|r: receita de Alquimia")
        H:slash("guardar"); local K = H.env.FarolKeep
        T.eq(K.farolDocked, true)
        local card1, card2 = K.farolPanels.card1, K.farolPanels.card2
        T.ok(card1.bg:IsShown(), "card for the item"); T.ok(not card2.bg:IsShown(), "no card without an item")
        T.has(H:text(K.rows[1].have), "receita de Alquimia"); T.has(H:text(K.rows[1].why), "sem prazo")
        T.ok(K.rows[1].icon:IsShown(), "item icon"); T.eq(H:text(K.farolPanels.form.title), "Guardar um item")
        T.eq(H:text(K.farolPanels.options.title), "Lembretes"); T.ok(not K.note:IsShown())
        K:Hide(); T.ok(not card1.bg:IsShown()); T.eq(K.rows[1].pick._x, 22, "usual row back")
    end },

    { "3.30: Goals in cards (gold, level, farm cards) inside the hub; usual layout outside", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        H.items[4306] = { "Tecido de Seda", 1, 150 }; H.itemCounts[4306] = 27
        H:login({ hub = true })
        H:slash("meta ouro 500"); H:slash("meta nivel 40")
        H:slash("meta item |cffffffff|Hitem:4306::::::::60:::::|h[Tecido de Seda]|h|r 40")
        H:slash("meta"); local W = H.env.FarolGoals
        T.eq(W.farolDocked, true); T.eq(W:GetWidth(), 770)
        local p = W.farolPanels
        T.eq(H:text(p.gold.title), "Ouro"); T.eq(H:text(p.gold.sub), "meta 500g")
        T.eq(H:text(p["text:gold1.l"].fs), "Você tem"); T.has(H:text(p["text:gold2.v"].fs), "376g")
        T.eq(H:text(p.level.title), "Nível"); T.has(H:text(p.level.sub), "ao 40")
        T.has(H:text(p["text:level2.v"].fs), "níveis")
        T.eq(H:text(p.farm.title), "Farm (itens)"); T.has(H:text(p.farm.sub), "1 de 10")
        T.ok(p.fcard1.bg:IsShown(), "card for the farm goal"); T.ok(not p.fcard2.bg:IsShown(), "no card without a goal")
        T.ok(W.farmRows[1].icon:IsShown(), "item icon"); T.has(H:text(W.farmRows[1].text), "27/40")
        T.ok(not W.farmRows[1].set:IsShown(), "Enter in the box sets the amount")
        T.ok(not W.hint:IsShown()); T.eq(W._bgAlpha, 0)
        W:Hide()
        T.ok(not p.gold.bg:IsShown(), "panels hidden outside the hub"); T.ok(not W.farmRows[1].icon:IsShown())
        H:slash("central off"); H:slash("meta")
        T.ok(W.hint:IsShown()); T.ok(W.farmRows[1].set:IsShown()); T.eq(W.gold.box._x, 84, "usual layout back")
        T.has(H:text(W.gold.status), "de 500g")
    end },

    { "3.30: Dungeons (now, averages, history) and Completed quests in cards inside the hub", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        local now = 1800000000
        H.env.time = function(t) if t then return os.time(t) end return now end
        H.env.GetInstanceInfo = function() return "Cripta Antiga", H.instanceType end
        H:login({ hub = true, questRecord = true },
            { runs = { list = { { n = "Torre", k = "party", t = now - 9000, s = 2400, x = 16000, g = 81200, l = 27, r = 0, e = 0, d = 1 },
                                 { n = "Fortaleza", k = "raid", t = now - 90000, s = 6000, x = 30000, g = 140000, l = 58, r = 1, e = 0, d = 4 } } } })
        H.instanceType = "party"; H:event("PLAYER_ENTERING_WORLD")
        for _ = 1, 3 do now = now + 1; H:update(1) end
        H:slash("masmorra"); local R = H.env.FarolRuns
        T.eq(R.farolDocked, true)
        local p = R.farolPanels
        T.eq(H:text(p.now.title), "Agora: Cripta Antiga"); T.has(H:text(p.now.sub), "desde")
        T.eq(H:text(p.avg.title), "Últimas 2"); T.eq(H:text(p["text:avg1.v"].fs), "1h 10m")
        T.eq(H:text(p.hist.sub), "2 de 10 · deste personagem")
        T.ok(p.row1.bg:IsShown()); T.ok(p.row2.bg:IsShown()); T.ok(not p.row3.bg:IsShown(), "no row card without a run")
        now = now + 60; H:update(1)
        T.eq(H:text(p["text:now1.v"].fs), "1m", "the current run updates live")
        H.instanceType = nil; H:event("PLAYER_ENTERING_WORLD")
        T.eq(H:text(p.now.title), "Corrida atual"); T.eq(H:text(p.avg.title), "Últimas 3", "the run went to the history")
        R:Hide(); T.ok(not p.now.bg:IsShown())
        local name, realm = H.ns.CurrentCharacter() -- 2ª passada: reino vazio e sobrenome (WoW Forever real)
        H.env.FarolDB.completed = { [realm] = { [name] = { list = {
            { i = 1520, n = "Lobos", l = 24, z = "Vale", t = now - 60 }, { i = 1521, n = "Ervas", t = now - 3 * 86400 } } } } }
        H:slash("concluidas"); local C = H.env.FarolCompleted
        T.eq(C.farolDocked, true)
        local q = C.farolPanels
        T.eq(H:text(q.list.title), "Últimas entregues"); T.eq(H:text(q["text:sum1.v"].fs), "2")
        T.eq(H:text(q["text:sum2.v"].fs), "1", "turned in today"); T.eq(H:text(q["text:qd_col_zone"].fs), "Zona")
        T.ok(not C.recorded:IsShown()); T.ok(not C.note:IsShown())
        H:click(H.env.FarolCompletedRow1); T.ok(H.env.FarolCompletedLink:IsShown(), "link still works in the hub")
        C:Hide(); T.ok(not q.list.bg:IsShown()); T.ok(C.recorded:IsShown(), "usual texts back outside the hub")
    end },

    { "3.31: Loot, Alarms and the warnings history in cards inside the hub", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true })
        for i = 1, 3 do
            H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff1eff00|Hitem:" .. (7000 + i) .. "|h[Item " .. i .. "]|h|r.")
        end
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cffffffff|Hitem:7009|h[Pano]|h|r.")
        H:slash("saque"); local L = H.env.FarolLoot
        T.eq(L.farolDocked, true); T.eq(L:GetWidth(), 770)
        local p = L.farolPanels
        T.eq(H:text(p.list.title), "Últimos saques"); T.eq(H:text(p["text:sum1.v"].fs), "4")
        T.has(H:text(p["text:sum2.v"].fs), "3", "uncommon or better")
        T.ok(p.lrow1.bg:IsShown()); T.ok(p.lrow4.bg:IsShown()); T.ok(not p.lrow5.bg:IsShown(), "no card without loot")
        T.ok(not L.grip:IsShown(), "the hub has its own size grip"); T.ok(not L.hint:IsShown())
        L:Hide(); T.ok(L.grip:IsShown(), "grip back outside the hub"); T.ok(not p.list.bg:IsShown())
        H:slash("alarme add 07:30 Raide"); H:slash("alarme add 12:00 servidor"); H:slash("alarme off 2")
        H:slash("alarme"); local A = H.env.FarolAlarms
        T.eq(A.farolDocked, true)
        local a = A.farolPanels
        T.eq(H:text(a["text:nexttime"].fs), "07:30", "next alarm on"); T.has(H:text(a["text:nextline"].fs), "Raide")
        T.eq(H:text(a.list.sub), "2 de 10 · marque para ligar")
        T.eq(H:text(a["text:atime1"].fs), "07:30"); T.has(H:text(a["text:awhen1"].fs), "em ")
        T.has(H:text(a["text:awhen2"].fs), "desligado"); T.ok(not a.arow3.bg:IsShown())
        T.ok(not A.hint:IsShown()); A:Hide(); T.ok(A.hint:IsShown(), "usual layout back"); T.eq(A.rows[1].check._x, 20)
        H.env.FarolCharDB.warnHistory = { { t = 1700000000, text = "Antigo" }, { t = os.time() - 120, text = "Bolsas quase cheias" } }
        H:slash("historico"); local W = H.env.FarolWarnHistory
        T.eq(W.farolDocked, true)
        local w = W.farolPanels
        T.eq(H:text(w["text:sum1.v"].fs), "2"); T.eq(H:text(w["text:sum2.v"].fs), "1", "today")
        T.has(H:text(w["text:sum3.v"].fs), "há "); T.eq(H:text(w["text:day1"].fs), "HOJE")
        T.eq(H:text(W.rows[1]), "Bolsas quase cheias"); T.has(H:text(w["text:day2"].fs), "/", "older day: date")
        W:Hide(); T.has(H:text(W.rows[1]) or "", "Bolsas", "usual rows back")
    end },

    { "3.31: hub size grip (70% to 130%, saved and validated), size command and the medallion parts", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true })
        H:slash("central"); local hub = H.env.FarolHub
        T.eq(hub:GetScale(), 1, "100% by default"); T.ok(H.env.FarolHubResize, "grip exists")
        local cx, cy = 1000, 500
        H.env.GetCursorPosition = function() return cx, cy end
        H.ns.Hub.StartResize(H.env.FarolHubResize)
        cx = cx + 500; H.env.FarolHubResize._scripts.OnUpdate(H.env.FarolHubResize, 0.1)
        T.eq(H.env.FarolDB.hubScale, 1.3, "bigger, at most 130%"); T.eq(hub:GetScale(), 1.3)
        cx = 0; cy = 2000; H.env.FarolHubResize._scripts.OnUpdate(H.env.FarolHubResize, 0.1)
        T.eq(H.env.FarolDB.hubScale, 0.7, "smaller, at least 70%")
        H.ns.Hub.StopResize(); T.eq(H.env.FarolHubResize._scripts.OnUpdate, nil)
        H.env.FarolHubResize._scripts.OnDoubleClick(H.env.FarolHubResize); T.eq(H.env.FarolDB.hubScale, 1, "double-click: 100%")
        H:slash("central tamanho 85"); T.eq(H.env.FarolDB.hubScale, 0.85); T.has(H:lastMsg(), "85%")
        H:slash("central tamanho 300"); T.has(H:lastMsg(), "uso: /farol central tamanho"); T.eq(H.env.FarolDB.hubScale, 0.85)
        H.env.GetCursorPosition = function() error("x") end
        H.ns.Hub.StartResize(H.env.FarolHubResize) -- cursor com erro: nada quebra
        T.eq(hub.medalRing, nil, "3.31.1: no ring (it came out crooked in the game)"); T.eq(hub.medal:GetWidth(), 28); T.eq(hub.medal:GetHeight(), 28, "square")
        T.eq(hub.medal._anchorPoint, "LEFT"); T.eq(hub.medal._anchor, hub.topBack, "top-left corner of the top bar")
        T.eq(hub.title._anchor, hub.topBack, "title on the same line (both centered on the top bar)")
        T.eq(hub.medal._texture, "Interface\\AddOns\\Farol\\Media\\Farol", "the icon sits next to the title")
        for _, bad in ipairs({ 0 / 0, 1 / 0, 0.2, 5, "x" }) do
            local X = Mock.new():login({ hub = true, hubScale = bad })
            T.eq(X.env.FarolDB.hubScale, 1, "bad size goes back to 100%: " .. tostring(bad))
        end
        local Y = Mock.new():login({ hub = true, hubScale = 1.2 }); Y:slash("central")
        T.eq(Y.env.FarolHub:GetScale(), 1.2, "saved size is used when the hub opens")
    end },

    { "3.31.2: the hub X closes everything (no docked window left open); inner X hidden in the hub", function(T, Mock)
        for _, sec in ipairs({ { "warnings", "FarolWarnHistory" }, { "tasks", "FarolTasks" }, { "loot", "FarolLoot" },
                { "alarms", "FarolAlarms" }, { "notes", "FarolNotes" }, { "keep", "FarolKeep" }, { "goals", "FarolGoals" },
                { "quests", "FarolCompleted" }, { "runs", "FarolRuns" }, { "settings", "FarolOptions" } }) do
            local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true })
            H:slash("central"); H.ns.Hub.Select(sec[1])
            local W = H.env[sec[2]]
            T.ok(W:IsShown() and W.farolDocked, sec[1] .. " docked")
            T.ok(W.farolClose and not W.farolClose:IsShown(), sec[1] .. ": its own X is hidden inside the hub")
            H.env.FarolHub:Hide() -- o X da Central (o jogo também esconde as janelas de dentro)
            T.ok(not W:IsShown(), sec[1] .. ": closed together with the hub, not left open on its own")
            T.eq(W:GetParent(), H.env.UIParent, sec[1] .. ": given back"); T.ok(W.farolClose:IsShown(), sec[1] .. ": X back")
            H:slash("central off")
            if sec[1] == "settings" then H:slash("menu") else H.ns.Hub.Select(sec[1]) end
        end
    end },

    { "3.31.2: Home tasks card shows the daily and weekly reset on their own lines; labels fit their text", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true }); H:slash("central")
        local card = H.env.FarolHub.pages.home.cards[2]
        T.eq(H:text(card.rows[2].left), "Reset diário"); T.eq(H:text(card.rows[3].left), "Reset semanal")
        T.ok(H:text(card.rows[2].right) ~= "", "daily countdown shown")
        local row = card.rows[2]
        T.ok(row.left:GetWidth() + row.right:GetWidth() + 34 <= card:GetWidth() + 0.5, "label + value fit the card")
        T.ok(row.left:GetWidth() >= 150, "the label gets the width of its text (simulator: 150)")
    end },

    { "3.32: Settings in cards inside the hub (same options, kept in sync); the usual menu outside", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true })
        H:slash("central"); H.ns.Hub.Select("settings")
        local W = H.env.FarolOptions
        local d, simple = W.detailControls, W.controls
        T.ok(d and d.detail, "a set of controls made for the hub")
        T.ok(d.pages.bar:IsShown() and not simple.pages.bar:IsShown() and not simple.tabs.bar:IsShown(), "only the cards show")
        local p = d.pages.bar.farolPanels
        T.eq(H:text(p.barcard.title), "Barra"); T.eq(H:text(p.packcard.title), "Pacotes")
        T.eq(H:text(p.grp1.title), "Desempenho"); T.has(H:text(p.grp1.sub), " de 3")
        T.has(H:text(d.hint), "itens na barra")
        H:click(d.items.mem) -- marca um item no cartão: o menu de sempre acompanha
        T.eq(simple.items.mem:GetChecked() and true or false, H.env.FarolDB.items.mem and true or false)
        H:click(d.tabs.warnings)
        T.ok(d.pages.warnings:IsShown()); T.eq(H:text(d.pages.warnings.farolPanels.wgear.title), "Equipamento e bolsas")
        H:click(d.tabs.general)
        local g = d.pages.general.farolPanels
        T.eq(H:text(g.lang.title), "Idioma"); T.has(H:text(g.restore.title), "Restaurar")
        T.ok(not d.langHeader:IsShown(), "old section headers hidden in the cards")
        H:slash("aviso"); T.ok(d.pages.warnings:IsShown(), "/farol aviso opens the Warnings card page inside the hub")
        H.env.FarolHub:Hide()
        H:slash("central off"); H:slash("menu")
        T.ok(W:IsShown() and not W.farolDocked); T.ok(simple.tabs.bar:IsShown(), "usual tabs back")
        T.ok(not d.tabs.bar:IsShown() and not d.pages.warnings:IsShown(), "cards hidden outside the hub")
    end },

    { "3.33: warning and alarm popups in the hub look (title + detail, level stripe, type icon); simple style unchanged", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login({ hub = true })
        H:update(1) -- o simulador começa com durabilidade baixa: um aviso
        local P = H.env.FarolWarnPopup
        T.ok(P and P:IsShown(), "warning shown")
        T.ok(P.farolPanels and P.farolPanels.pbg.bg:IsShown(), "Farol frame drawn"); T.ok(P.farolPopupIcon:IsShown())
        T.ok(P.farolStripe:IsShown() and P.farolKind:IsShown(), "level stripe and type icon")
        T.eq(P.farolKind._texture, "Interface\\Icons\\Trade_BlackSmithing")
        T.has(H:text(P.text), "\n", "title and detail on two lines")
        T.eq(P.title._anchorPoint, "TOPLEFT")
        H.talentPoints = 1; H:update(1)
        T.has(H:text(P.title), "(2)", "two warnings together")
        local row = P.rows[2]
        T.ok(row.farolStripe:IsShown() and row.farolKind:IsShown(), "each row has its stripe and icon")
        H:slash("central off"); H:update(1); H.talentPoints = 2; H:update(1)
        T.ok(not P.farolPanels.pbg.bg:IsShown(), "simple style: the usual popup"); T.ok(not row.farolStripe:IsShown())
        T.eq(P.title._anchorPoint, "TOP")
        -- alarme
        local A = Mock.new({ locale = "ptBR" }); A:login({ hub = true }); A:slash("alarme add 07:30 Raide da guilda")
        A:update(1); A.clock.hour, A.clock.min = 7, 30; A:update(1)
        local AP = A.env.FarolAlarmPopup
        T.ok(AP and AP:IsShown(), "alarm ringing")
        T.eq(A:text(AP.farolPanels["text:time"].fs), "07:30"); T.eq(A:text(AP.text), "Raide da guilda")
        T.has(A:text(AP.farolPanels["text:kind"].fs), "tocando agora"); T.ok(AP.farolPanels.pbg.bg:IsShown())
    end },

    { "saved value is validated; English texts; language dropdown", function(T, Mock)
        for _, bad in ipairs({ "sim", 1, 0 / 0, {} }) do
            local X = Mock.new():login({ hub = bad })
            T.eq(X.env.FarolDB.hub, false, "bad value goes back to off: " .. tostring(bad))
        end
        local E = Mock.new({ locale = "enUS" }):login({ hub = true })
        E:slash("hub"); local hub = E.env.FarolHub
        T.eq(E:text(E.env.FarolHubNavhome.text), "Home"); T.eq(E:text(E.env.FarolHubSimple), "Simple style")
        T.has(E:text(hub.pages.home.hero.title), "This session")
        E:click(E.env.FarolHubLang)
        for i = 1, 3 do
            local entry = E.env["FarolHubLangEntry" .. i]
            if entry and E:text(entry.text) == "Português" then E:click(entry) end
        end
        T.eq(E.env.FarolDB.lang, "pt"); T.eq(E:text(E.env.FarolHubNavhome.text), "Início", "hub follows the language")
        E:slash("central"); E:slash("central")
        T.eq(E:text(E.env.FarolHubSummary), "Resumo agora"); E:click(E.env.FarolHubSummary)
        T.has(chat(E), "resumo da sessão")
    end },
}
