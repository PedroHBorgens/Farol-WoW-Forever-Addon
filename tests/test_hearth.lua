-- Pedra de Regresso: item da barra (ligado só em instalação nova), estados, tooltip, aviso opcional, lugar dos
-- personagens no tooltip do ouro, API moderna e antiga, valores ruins.
-- Hearthstone: bar item (on only on a fresh install), states, tooltip, optional warning, characters' bind place in
-- the gold tooltip, modern and old API, bad values.

local function setup(Mock, opts, saved)
    local H = Mock.new(opts)
    H.bind = "Vila do Farol"
    H.itemCounts[6948] = 1
    H:login(saved); H:update(1)
    return H
end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function count(text, pattern) return select(2, string.gsub(text, pattern, "")) end

return {
    { "fresh install: on, shows the place and ready / cooldown / no stone", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.env.FarolDB.items.hearth, true, "approved default on a fresh install")
        T.has(H:bar(), "Vila do Farol · pronta"); T.has(H:barRaw(), "|cff40ff40pronta|r")
        H.hearthCD = { H.now - 60, 3600 }; H:update(1)
        T.has(H:bar(), "Vila do Farol · 58m"); T.has(H:barRaw(), "|cffffff3a58m|r")
        H.hearthCD = { H.now, 1.5 }; H:update(1)
        T.has(H:bar(), "Vila do Farol · pronta", "the global cooldown does not count")
        H.itemCounts[6948] = 0; H:update(1)
        T.has(H:bar(), "Vila do Farol · sem pedra")
        H.bind = nil; H:update(1)
        T.hasnt(H:bar(), "Vila do Farol", "no place reported: the item hides itself")
    end },

    { "existing players get it off on update; the news says where to turn it on", function(T, Mock)
        local H = setup(Mock, nil, { items = { fps = true, gold = true }, newsSeen = 0 })
        T.eq(H.env.FarolDB.items.hearth, false, "rule 8: updating never turns anything on")
        T.hasnt(H:bar(), "Vila do Farol")
        T.has(all(H), "Pedra de Regresso na barra: onde está vinculada e quanto falta da recarga — desligado (ligue em Menu > Barra)")
        H:slash("mostrar regresso"); H:update(1)
        T.has(H:bar(), "Vila do Farol · pronta")
        H = setup(Mock, nil, { items = { fps = true, hearth = "yes" } })
        T.eq(H.env.FarolDB.items.hearth, true, "an invalid saved value goes back to the default")
    end },

    { "tooltip: bound place, cooldown and the time it is ready", function(T, Mock)
        local H = setup(Mock)
        H.hearthCD = { H.now - 600, 3600 }; H:update(1)
        local t = tip(H)
        T.has(t, "Pedra de Regresso"); T.has(t, "Vinculada em = Vila do Farol"); T.has(t, "Recarga = 49m")
        T.has(t, "pronta às = ")
        H.itemCounts[6948] = 0
        T.has(tip(H), "a pedra não está nas suas bolsas")
    end },

    { "optional warning: once when the cooldown ends, waits for combat and dungeons, not at login", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.env.FarolDB.warnings.hearthReady, false, "off by default")
        H:slash("aviso regresso on"); T.has(H:lastMsg(), "Pedra de Regresso pronta")
        H:update(1); H:update(1)
        T.eq(count(all(H), "Pedra de Regresso pronta %("), 0, "already ready at login: no warning")
        H.hearthCD = { H.now, 30 }; H:update(1); H:update(1)
        H.inCombat = true; H:update(31); H:update(1)
        T.eq(count(all(H), "Pedra de Regresso pronta %("), 0, "waits for combat")
        H.inCombat = false; H.instanceType = "party"; H:update(1)
        T.eq(count(all(H), "Pedra de Regresso pronta %("), 0, "waits for the dungeon")
        H.instanceType = nil; H:update(1); H:update(1)
        T.has(all(H), "Pedra de Regresso pronta (Vila do Farol).")
        H:update(1); H:update(5)
        T.eq(count(all(H), "Pedra de Regresso pronta %("), 1, "once per cooldown")
        H.hearthCD = { H.now, 20 }; H:update(1); H:update(21); H:update(1)
        T.eq(count(all(H), "Pedra de Regresso pronta %("), 2, "again after the next cooldown")
    end },

    { "the gold tooltip shows where each of your characters is bound; saved places are cleaned", function(T, Mock)
        local saved = { items = { fps = true, gold = true }, chars = { Azralon = {
            Mira = { gold = 3381500, level = 34, t = os.time() - 3600, bind = "Porto|cffff0000 Cinzento" },
            Tomas = { gold = 10205000, level = 60, t = os.time() - 7200, bind = string.rep("á", 80) },
            Aldric = { gold = 9700, level = 22, t = os.time() - 9000, bind = { 1 } } } } }
        local H = setup(Mock, nil, saved)
        local chars = H.env.FarolDB.chars.Azralon
        T.eq(chars.Mira.bind, "Portocffff0000 Cinzento"); T.eq(chars.Aldric.bind, nil)
        T.eq(select(2, string.gsub(chars.Tomas.bind, "[\192-\244]", "")), 40, "at most 40 letters")
        H:slash("ouro"); H:update(61)
        T.has(tip(H), "Portocffff0000 Cinzento")
        T.eq(chars[H.playerName or "Garrosh"] and chars[H.playerName or "Garrosh"].bind, "Vila do Farol", "own place saved")
    end },

    { "old client (GetItemCooldown) and blocked values", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk" })
        H.hearthCD = { H.now - 60, 3600 }; H:update(1)
        T.has(H:bar(), "Vila do Farol · 58m")
        H = setup(Mock, { mode = "secret" })
        H.env.C_Container.GetItemCooldown = function() error("bloqueado") end; H:update(1)
        T.has(H:bar(), "Vila do Farol · --")
        H.env.C_Container.GetItemCooldown = function() return 0 / 0, 1 / 0 end; H:update(1)
        T.has(H:bar(), "Vila do Farol · --"); tip(H)
        H.env.GetBindLocation = function() return "a|Hitem:1|h" .. string.rep("x", 100) end; H:update(1)
        T.hasnt(H:barRaw(), "|Hitem"); tip(H)
        H.env.GetBindLocation = function() error("x") end; H:update(1); tip(H)
        H:slash("aviso regresso on"); H:update(1); H:update(1)
    end },
}
