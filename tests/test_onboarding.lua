-- Orientação: boas-vindas na primeira vez, novidades ao atualizar (uma vez), contador e explicações no menu,
-- dica no tooltip. Nada é ligado sozinho.
-- Onboarding: welcome on first use, news after an update (once), counter and descriptions in the menu, tooltip hint.

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

local function relog(H, Mock, opts)
    local N = Mock.new(opts)
    N.env.FarolDB, N.env.FarolCharDB = H.env.FarolDB, H.env.FarolCharDB
    N:load(); N:event("ADDON_LOADED", "Farol"); N.msgs = {}
    N:event("PLAYER_ENTERING_WORLD", true, false)
    return N
end

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

local function menuChecks(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    local checks = H:framesOf("CheckButton")
    return checks, H.env.FarolOptions
end

return {
    { "first time: a welcome explains that only the basics are on, once", function(T, Mock)
        local H = Mock.new():login()
        local text = chat(H)
        T.has(text, "bem-vindo! A barra começa só com o básico: FPS, Latência, Coordenadas, Zona, Durabilidade, Ouro.")
        T.has(text, "há mais 15 informações e vários avisos desligados — clique com o botão direito na barra")
        T.hasnt(text, "novidades", "a new player gets the welcome, not the news")
        local N = relog(H, Mock)
        T.hasnt(chat(N), "bem-vindo", "only once")
        T.hasnt(chat(N), "novidades")
        local before = 0
        for _, v in pairs(H.env.FarolDB.items) do if v then before = before + 1 end end
        T.eq(before, 6, "nothing was turned on by the welcome")
    end },

    { "after an update: the news are listed once (only what is new for you)", function(T, Mock)
        local H = Mock.new():login({ items = { fps = true } }) -- já usava o addon (sem "newsSeen")
        local text = chat(H)
        T.has(text, "novidades desde a sua última versão (a maioria vem desligada")
        T.has(text, "reputação na barra · contagem até os resets")
        T.has(text, "descanso dos seus personagens")
        T.hasnt(text, "bem-vindo")
        T.eq(H.env.FarolDB.newsSeen, 10)
        T.hasnt(chat(relog(H, Mock)), "novidades", "once")
        local P = Mock.new():login({ items = { fps = true }, newsSeen = 8 })
        T.has(chat(P), "ouro de todos os personagens (/farol ouro) · descanso dos seus personagens")
        T.hasnt(chat(P), "reputação na barra", "older news are not repeated")
        P.msgs = {}; P:slash("novidades")
        T.has(chat(P), "reputação na barra", "/farol novidades shows all again")
    end },

    { "tampered 'newsSeen' falls back safely", function(T, Mock)
        for _, bad in ipairs({ 0 / 0, -1, "x", math.huge, 1e9, {} }) do
            local H = Mock.new():login({ items = { fps = true }, newsSeen = bad })
            T.ok(H.env.FarolDB.newsSeen >= 0 and H.env.FarolDB.newsSeen <= 10, "valid after " .. tostring(bad))
        end
    end },

    { "options menu: counter of items on, and each item explains what it shows", function(T, Mock)
        local H = Mock.new():login()
        local _, window = menuChecks(H)
        local hints = {}
        for _, fs in ipairs(window._fontStrings or {}) do hints[#hints + 1] = H:text(fs) end
        T.has(table.concat(hints, " | "), "Itens na barra: 6 de 21 ligados — marque os que quiser")
        H:slash("show lixo")
        hints = {}
        for _, fs in ipairs(window._fontStrings or {}) do hints[#hints + 1] = H:text(fs) end
        T.has(table.concat(hints, " | "), "Itens na barra: 7 de 21 ligados", "updates when an item is turned on")
        local junk
        for _, check in ipairs(H:framesOf("CheckButton")) do
            if check.label and H:text(check.label) == "Lixo nas bolsas" then junk = check end
        end
        H.env.GameTooltip.lines = {}
        junk._scripts.OnEnter(junk)
        T.has(table.concat(H.env.GameTooltip.lines, " "), "Valor de venda dos itens cinzentos (o Farol nunca vende).")
    end },

    { "every bar item has a description in both languages", function(T, Mock)
        local H = Mock.new():login()
        for _, key in ipairs(H.ns.ITEM_ORDER) do
            T.ok(H.ns.STRINGS.pt["desc_" .. key], "pt description for " .. key)
            T.ok(H.ns.STRINGS.en["desc_" .. key], "en description for " .. key)
        end
    end },

    { "bar tooltip says how many more items can be turned on; English welcome", function(T, Mock)
        local H = Mock.new():login()
        T.has(tip(H), "Clique direito: opções (mais 15 informações para ligar).")
        for _, key in ipairs(H.ns.ITEM_ORDER) do H:slash("show " .. key) end
        T.has(tip(H), "Clique direito: opções.", "all on: the plain hint")
        local E = Mock.new({ locale = "enUS" }):login()
        T.has(chat(E), "welcome! The bar starts with the basics only: FPS, Latency, Coordinates, Zone, Durability, Gold.")
        T.has(chat(E), "there are 15 more items and several warnings turned off")
    end },
}
