-- Central do Farol (3.27, estilo detalhado): desligada por padrão; barra lateral, página Início em cartões,
-- janelas de sempre encaixadas e devolvidas; volta ao estilo simples. Só lê; nada é enviado.
-- Farol hub: off by default; side bar, Home cards, regular windows docked and released; back to simple style.

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "off by default (simple style: windows open on their own); /farol central turns it on and opens Home", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
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
        H:login({ hub = true, chars = { Azralon = { Mira = { gold = 50000, level = 34, t = 1 } } } })
        H:slash("central"); local hub = H.env.FarolHub
        H:click(H.env.FarolHubNavprofs)
        local profs = hub.pages.profs
        T.ok(profs:IsShown()); T.ok(not hub.pages.home:IsShown())
        T.eq(H:text(profs.rows[1].left), "Alquimia"); T.has(H:text(profs.rows[1].right), "150 / 150"); T.ok(profs.rows[1].bar:IsShown())
        T.eq(H:text(profs.rows[2].left), "Pesca")
        H:click(H.env.FarolHubNavchars); T.ok(hub.pages.chars:IsShown())
        T.has(H:text(hub.pages.chars.head), "Personagens deste reino")
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
