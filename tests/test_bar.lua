-- Barra de informações: compatibilidade, idioma, itens, tooltip, valores bloqueados, dados salvos.
-- Info bar: compatibility, language, items, tooltip, secret values, saved data.

local ALL_ITEMS = { "fps", "ms", "mem", "coords", "zone", "speed", "durab", "bags",
                    "gold", "session", "goldh", "xp", "xph", "rep", "clock", "reset", "playtime", "friends", "guild" }

return {
    { "loads on WoW Forever and shows the default items", function(T, Mock)
        local H = Mock.new({ mode = "forever" }):login()
        local bar = H:bar()
        T.has(bar, "60 fps"); T.has(bar, "60 ms"); T.has(bar, "45.0, 61.0")
        T.has(bar, "Floresta de Elwynn"); T.has(bar, "Dur 15%"); T.has(bar, "123g 45s 67c")
        T.hasnt(bar, "XP", "XP is off by default")
        T.eq(H.env.FarolFrame._template, "BackdropTemplate", "modern backdrop template")
        T.ok(H.settingsCategory, "registered in the game's AddOns settings")
    end },

    { "loads on the 3.3.5a client with the old APIs", function(T, Mock)
        local H = Mock.new({ mode = "wotlk" }):login()
        local bar = H:bar()
        T.has(bar, "87 ms"); T.has(bar, "45.3, 61.1")
        T.eq(H.env.FarolFrame._template, nil, "no BackdropTemplate on old clients")
        T.ok(H.settingsPanel, "registered in Interface > AddOns")
        H:slash("version")
        T.has(H.strip(H.msgs[#H.msgs - 1]), "Interface: 30300", "Interface deduced from the version")
    end },

    { "/farol version shows the WoW Forever Interface number", function(T, Mock)
        local H = Mock.new():login()
        H:slash("version")
        T.has(H.strip(H.msgs[#H.msgs - 1]), "cliente 1.60.1 (build 70862, Nov 6 2026) — Interface: 16001")
    end },

    { "language: auto follows the client, pt/en switch, invalid rejected", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H:slash("lock"); T.has(H:lastMsg(), "panel locked")
        H:slash("lang pt"); H:slash("lock"); T.has(H:lastMsg(), "painel destravado")
        H:slash("lang klingon"); T.has(H:lastMsg(), "uso: /farol lang pt | en | auto")
        T.eq(H.env.FarolDB.lang, "pt")
        local H2 = Mock.new({ locale = "ptBR" }):login()
        H2:slash("lock"); T.has(H2:lastMsg(), "painel travado")
    end },

    { "corrupted saved settings fall back to safe defaults", function(T, Mock)
        local H = Mock.new():login({
            x = "hack", y = 99999, point = "EVIL", lang = "xx", snoozeMinutes = 1.5,
            items = { fps = false, gold = 1, evil = "x" },
        })
        local db = H.env.FarolDB
        T.eq(db.x, 0); T.eq(db.y, -20); T.eq(db.point, "TOP"); T.eq(db.lang, "auto")
        T.eq(db.snoozeMinutes, 5)
        T.eq(db.items.fps, false, "a saved 'false' is kept")
        T.eq(db.items.gold, true, "invalid value -> default")
        T.eq(db.items.evil, nil, "unknown keys dropped")
        T.eq(db.items.xp, false, "new items default to off")
        T.eq(db.items.xph, false); T.eq(db.items.goldh, false)
    end },

    { "show/hide items by command (PT and EN names) and list them", function(T, Mock)
        local H = Mock.new():login()
        H:slash("esconder ouro"); T.hasnt(H:bar(), "123g")
        H:slash("show gold"); T.has(H:bar(), "123g")
        H:slash("hide klingon"); T.has(H:lastMsg(), "uso: /farol show|hide fps | ms | mem")
        H.msgs = {}
        H:slash("itens"); T.has(H.strip(table.concat(H.msgs, "/")), "Ouro (ouro): visível")
        for _, key in ipairs(ALL_ITEMS) do H:slash("hide " .. key) end
        T.has(H:bar(), "/farol show <item>", "hint when every item is hidden")
    end },

    { "all 19 items render with correct values", function(T, Mock)
        local H = Mock.new():login()
        for _, key in ipairs(ALL_ITEMS) do H:slash("show " .. key) end
        H:update(3725)
        local bar = H:bar()
        T.has(bar, "Vel 100%"); T.has(bar, "Bolsas 6/80"); T.has(bar, "Sessão +0c")
        T.has(bar, "XP 62% +15%"); T.has(bar, "Jogando 1h 02m")
        T.has(bar, "Amigos 8"); T.has(bar, "Guilda 12"); T.has(bar, "Mem ")
        T.has(bar, "Ouro/h +0c"); T.has(bar, "XP/h --", "no XP gained yet")
        T.has(bar, "Diário 5h 12m · Semanal 2d 4h")
        H:slash("alarme add 06:00"); H:update(1)
        T.ok(string.find(H:barRaw(), "PocketWatch", 1, true), "clock shows the alarm icon")
    end },

    { "guild roster is requested at most once per minute and only when enabled", function(T, Mock)
        local H = Mock.new():login()
        for _ = 1, 5 do H:update(1) end
        T.eq(H.rosterRequests, 0, "item off: no requests")
        H:slash("show guilda")
        for _ = 1, 30 do H:update(1) end
        T.eq(H.rosterRequests, 1)
        for _ = 1, 31 do H:update(1) end
        T.eq(H.rosterRequests, 2)
    end },

    { "tooltip lists latency, subzone, damaged gear, XP, times and counts", function(T, Mock)
        local H = Mock.new():login()
        H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        local tip = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(tip, "Latência = local 40 ms / mundo 60 ms")
        T.has(tip, "Subzona = Vale Norte")
        T.has(tip, "Espaço 5 = 15%"); T.has(tip, "[Elmo] = 50%")
        T.has(tip, "Experiência = 6200 / 10000 (62%)")
        T.has(tip, "Hora do servidor = 21:05")
        T.has(tip, "Amigos online = WoW 3 / Battle.net 5")
        T.has(tip, "Guilda online = 12 / 80")
    end },

    { "secret values show '--' instead of errors", function(T, Mock)
        local H = Mock.new({ secret = true, locale = "enUS" }):login()
        local bar = H:bar()
        T.has(bar, "--", "blocked zone"); T.has(bar, "Dur 50%", "secret durability ignored")
        H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        T.has(H.strip(table.concat(H.env.GameTooltip.lines, " / ")), "Zone = --")
    end },

    { "panel position is saved when dragged", function(T, Mock)
        local H = Mock.new():login()
        H.env.FarolFrame._scripts.OnDragStop(H.env.FarolFrame)
        T.eq(H.env.FarolDB.x, 12); T.eq(H.env.FarolDB.y, -5)
        H:slash("reset"); T.eq(H.env.FarolDB.x, 0)
    end },
}
