-- Ouro dos seus personagens: registro do personagem atual, total do reino, tooltip, esquecer, dados adulterados.
-- Gold of your characters: current character record, realm total, tooltip, forget, tampered data.

local function savedWithAlts(now)
    return { chars = {
        Azralon = {
            Thrall = { gold = 10205000, level = 60, t = now - 3600 },   -- 1020g 50s
            Jaina = { gold = 3381500, level = 34, t = now - 90000 },   -- 338g 15s
        },
        Nemesis = { Sylvanas = { gold = 99990000, level = 60, t = now } }, -- outro reino
    } }
end

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "records the current character's gold and level (only on this computer)", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        local me = H.env.FarolDB.chars.Azralon.Garrosh
        T.eq(me.gold, 1234567); T.eq(me.level, 30); T.ok(me.t > 0)
        H.money = 1234567 + 50000; H.xp.level = 31; H:update(1)
        T.eq(H.env.FarolDB.chars.Azralon.Garrosh.gold, 1284567, "updated when gold changes")
        T.eq(H.env.FarolDB.chars.Azralon.Garrosh.level, 31)
    end },

    { "tooltip lists the characters of this realm, richest first, with the total", function(T, Mock)
        local now = os.time()
        local H = Mock.new():login(savedWithAlts(now)); H:update(1)
        local text = tip(H)
        T.has(text, "Ouro na conta (Azralon) = 1482g 10s")  -- 1020g 50s + 338g 15s + 123g 45s
        local thrall, jaina, me = string.find(text, "Thrall (60)", 1, true), string.find(text, "Jaina (34)", 1, true),
            string.find(text, "Garrosh (30)", 1, true)
        T.ok(thrall and jaina and me and thrall < jaina and jaina < me, "sorted by gold")
        T.has(text, "Garrosh (30) = 123g 45s  este", "current character marked")
        T.hasnt(text, "Sylvanas", "other realms are not mixed in")
        T.has(text, "Thrall (60) = 1020g 50s  ", "date shown for the others")
    end },

    { "the gold item shows the realm total only when the option is on and there are other characters", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        H:slash("ouro total on"); H:update(1)
        T.hasnt(H:bar(), "Total", "only one character: no total")
        local A = Mock.new():login(savedWithAlts(os.time())); A:update(1)
        T.hasnt(A:bar(), "Total", "off by default")
        A:slash("ouro total on"); A:update(1)
        T.has(A:bar(), "123g 45s 67c (Total 1482g 10s)")
        T.eq(A.env.FarolDB.goldTotal, true); T.has(A:lastMsg(), "ligado")
        A:slash("ouro total off"); A:update(1); T.hasnt(A:bar(), "Total")
    end },

    { "/farol ouro lists; forget one, never the current one; the button needs a second click", function(T, Mock)
        local H = Mock.new():login(savedWithAlts(os.time())); H:update(1)
        H.msgs = {}; H:slash("ouro")
        T.has(chat(H), "ouro dos seus personagens em Azralon (total 1482g 10s):")
        T.has(chat(H), "Garrosh (30): 123g 45s — este")
        H:slash("ouro esquecer jaina"); T.has(H:lastMsg(), "personagem esquecido: Jaina.")
        T.eq(H.env.FarolDB.chars.Azralon.Jaina, nil)
        H:slash("ouro esquecer Garrosh"); T.has(H:lastMsg(), "não dá para esquecer o personagem em que você está")
        H:slash("ouro esquecer Ninguem"); T.has(H:lastMsg(), "personagem não encontrado neste reino: Ninguem.")
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local forget
        for _, b in ipairs(H:framesOf("Button")) do
            if b._text == "Esquecer personagens" and b:IsShown() and H.env.FarolOptions then forget = b end
        end
        T.ok(forget, "button in the options")
        H:click(forget)
        T.eq(forget._text, "Clique de novo para confirmar"); T.ok(H.env.FarolDB.chars.Azralon.Thrall, "not yet")
        H:click(forget)
        T.eq(H.env.FarolDB.chars.Azralon.Thrall, nil, "forgotten after confirming")
        T.ok(H.env.FarolDB.chars.Azralon.Garrosh, "current character stays")
        T.ok(H.env.FarolDB.chars.Nemesis.Sylvanas, "other realms untouched")
        T.has(H:lastMsg(), "1 personagem(ns) deste reino esquecido(s)")
    end },

    { "a late second click does not confirm", function(T, Mock)
        local H = Mock.new():login(savedWithAlts(os.time())); H:update(1)
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local forget
        for _, b in ipairs(H:framesOf("Button")) do if b._text == "Esquecer personagens" then forget = b end end
        H:click(forget); H:update(6); H:click(forget)
        T.ok(H.env.FarolDB.chars.Azralon.Thrall, "6 s later counts as a new first click")
    end },

    { "tampered saved data is cleaned on load", function(T, Mock)
        local chars = {
            Azralon = {
                ["Evil|Hitem:1|h"] = { gold = 1, level = 1, t = 1 }, [string.rep("A", 49)] = { gold = 1, level = 1, t = 1 },
                Nan = { gold = 0 / 0, level = 10, t = 1 }, Neg = { gold = -1, level = 10, t = 1 },
                Huge = { gold = 1e13, level = 10, t = 1 }, Lvl = { gold = 1, level = 0, t = 1 },
                Inf = { gold = 1, level = 10, t = math.huge }, Txt = "lixo", Ok = { gold = 5.7, level = 12.9, t = 100 },
            },
            [""] = { X = { gold = 1, level = 1, t = 1 } }, ["Reino|c"] = { Y = { gold = 1, level = 1, t = 1 } },
            Lixo = "x",
        }
        for i = 1, 30 do chars["Reino" .. i] = { Z = { gold = 1, level = 1, t = 1 } } end
        local big = {}
        for i = 1, 100 do big["P" .. i] = { gold = 1, level = 1, t = 1 } end
        chars.Grande = big
        local H = Mock.new():login({ chars = chars })
        local saved = H.env.FarolDB.chars
        local azralon = saved.Azralon
        T.eq(azralon.Ok.gold, 5, "rounded down"); T.eq(azralon.Ok.level, 12)
        for _, bad in ipairs({ "Evil|Hitem:1|h", string.rep("A", 49), "Nan", "Neg", "Huge", "Lvl", "Inf", "Txt" }) do
            T.eq(azralon[bad], nil, "dropped: " .. bad)
        end
        T.eq(saved[""], nil); T.eq(saved["Reino|c"], nil); T.eq(saved.Lixo, nil)
        local realms = 0
        for _ in pairs(saved) do realms = realms + 1 end
        T.ok(realms <= 21, "at most 20 saved realms (+ the current one)")
        T.ok(saved.Azralon, "the most recently active realm is kept (fixed order, not random)")
        if saved.Grande then
            local n = 0
            for _ in pairs(saved.Grande) do n = n + 1 end
            T.ok(n <= 60, "at most 60 characters per realm")
        end
        local B = Mock.new():login({ chars = "lixo" }); B:update(1)
        T.ok(B.env.FarolDB.chars.Azralon.Garrosh, "invalid table replaced and the current character recorded")
    end },

    { "unknown name or realm (still loading) records nothing; English texts", function(T, Mock)
        local H = Mock.new()
        H.playerName = "Unknown"; H:login(); H:update(1)
        T.eq(next(H.env.FarolDB.chars), nil, "nothing recorded while the name is unknown")
        H.playerName = "Garrosh"; H.realm = nil; H:update(1)
        T.eq(next(H.env.FarolDB.chars), nil, "nothing without a realm")
        local E = Mock.new({ locale = "enUS" }):login(savedWithAlts(os.time())); E:update(1)
        T.has(tip(E), "Gold on this account (Azralon) = 1482g 10s")
        T.has(tip(E), "this one")
        E:slash("gold forget thrall"); T.has(E:lastMsg(), "character forgotten: Thrall.")
    end },
}
