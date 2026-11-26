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
