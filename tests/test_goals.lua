-- Metas de ouro e de nível: barra, tooltip, estimativa pelo ritmo da sessão, janela, comandos, aviso, dados adulterados.
-- Gold and level goals: bar, tooltip, estimate from the session pace, window, commands, warning, tampered data.

local function setup(Mock, opts, savedChar)
    local H = Mock.new(opts):login({ hub = false }, savedChar) -- estilo simples; a Central tem teste próprio (test_hub)
    H:slash("mostrar metas"); H:update(1)
    return H
end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "off by default; no goal shows --; a gold goal shows the percentage", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Meta"); T.eq(H.env.FarolDB.items.goals, false)
        H = setup(Mock)
        T.has(H:bar(), "Meta --")
        H:slash("meta ouro 200"); H:update(1)
        T.has(H:lastMsg(), "meta de ouro: 200g"); T.eq(H.env.FarolCharDB.goals.gold, 2000000)
        T.has(H:bar(), "Meta 200g 61%"); T.hasnt(H:bar(), "~", "no estimate before there is a pace")
        local t = tip(H)
        T.has(t, "Ouro 200g = tem 123g de 200g (61%)"); T.has(t, "estimativa: -- (ainda sem ritmo nesta sessão)")
    end },

    { "gold estimate from the session pace; reached turns green and warns once (optional)", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta ouro 500"); H:slash("meta aviso on")
        for _ = 1, 10 do H.money = (H.money or 1234567) + 100000; H:update(60) end -- +100g em 10 min = 600g/h
        T.has(H:bar(), "Meta 500g 44% ~27m")
        T.has(tip(H), "estimativa: ~27m (por volta das"); T.has(tip(H), "ritmo: 599g por hora")
        H.money = 5000000; H:update(2)
        T.has(H:barRaw(), "|cff40ff40alcançada|r")
        T.has(all(H), "meta alcançada: 500g!")
        local count = select(2, string.gsub(all(H), "meta alcançada: 500g", ""))
        H:update(5); H:update(5)
        T.eq(select(2, string.gsub(all(H), "meta alcançada: 500g", "")), count, "only once")
        T.eq(H.env.FarolCharDB.goals.gw, true, "remembered")
    end },

    { "level goal: progress since it was set and a time estimate", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta nivel 32"); H:update(1)
        T.eq(H.env.FarolCharDB.goals.level, 32); T.eq(H.env.FarolCharDB.goals.ls, 30)
        T.has(H:bar(), "Nv 32 31%")
        for _ = 1, 10 do H.xp.cur = H.xp.cur + 100; H:update(60) end -- 6000 XP/h
        T.has(H:bar(), "Nv 32 36% ~2h")
        T.has(tip(H), "ritmo: 5980 XP por hora")
        H.xp.level = 32; H:update(2)
        T.has(H:bar(), "Nv 32 alcançada")
    end },

    { "invalid goals are refused; clear removes them", function(T, Mock)
        local H = setup(Mock)
        for _, cmd in ipairs({ "meta ouro 0", "meta ouro 1000001", "meta ouro 99999999999999999999" }) do
            H:slash(cmd); T.has(H:lastMsg(), "meta de ouro inválida", cmd)
        end
        for _, cmd in ipairs({ "meta nivel 30", "meta nivel 12", "meta nivel 61" }) do
            H:slash(cmd); T.has(H:lastMsg(), "meta de nível inválida", cmd)
        end
        for _, cmd in ipairs({ "meta ouro abc", "meta voar", "meta nivel", "meta limpar tudo", "meta aviso talvez" }) do
            H:slash(cmd); T.has(H:lastMsg(), "uso: /farol meta", cmd)
        end
        T.eq(next(H.env.FarolCharDB.goals), nil, "nothing saved")
        H:slash("meta ouro 300"); H:slash("meta nivel 40")
        H:slash("meta limpar ouro"); T.eq(H.env.FarolCharDB.goals.gold, nil); T.eq(H.env.FarolCharDB.goals.level, 40)
        H:slash("meta limpar"); T.eq(H.env.FarolCharDB.goals.level, nil); H:update(1); T.has(H:bar(), "Meta --")
    end },

    { "window: set with the boxes, clear, and the warning checkbox synced with the Warnings tab", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta")
        T.ok(H.env.FarolGoals:IsShown())
        H.env.FarolGoalGold:SetText("250"); H:click(H.env.FarolGoalGoldSet)
        H.env.FarolGoalLevel:SetText("35"); H:click(H.env.FarolGoalLevelSet)
        T.eq(H.env.FarolCharDB.goals.gold, 2500000); T.eq(H.env.FarolCharDB.goals.level, 35)
        T.has(H:text(H.env.FarolGoals.gold.status), "tem 123g de 250g")
        H:click(H.env.FarolGoalLevelClear); T.eq(H.env.FarolCharDB.goals.level, nil)
        H:check(H.env.FarolGoalWarn, true); T.eq(H.env.FarolDB.warnings.goals, true)
        H:slash("aviso"); T.eq(H.env.FarolWarnGoals._checked, true, "Warnings tab synced")
        H:check(H.env.FarolWarnGoals, false); T.eq(H.env.FarolDB.warnings.goals, false)
    end },

    { "per character, saved and validated; tampered data falls back safely", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta ouro 300"); H:slash("meta nivel 40"); H:event("PLAYER_LOGOUT")
        local H2 = setup(Mock, nil, { goals = H.env.FarolCharDB.goals })
        T.has(H2:bar(), "Meta 300g"); T.has(H2:bar(), "Nv 40")
        for _, bad in ipairs({ "x", { gold = 0 / 0, level = 1 / 0 }, { gold = -5, level = 1, ls = 9 },
                               { gold = 1e20, level = 40.5 }, { gold = 1000000, gw = "yes", level = 45, ls = 50, lw = 1 } }) do
            local B = setup(Mock, nil, { goals = bad })
            local g = B.env.FarolCharDB.goals
            T.ok(g.gold == nil or (g.gold >= 1 and g.gold <= 1e10 and g.gold == math.floor(g.gold)), "gold valid")
            T.ok(g.level == nil or (g.level >= 2 and g.level <= 200), "level valid")
            T.ok(g.ls == nil or (g.level and g.ls < g.level), "start below target")
            T.ok(g.gw == nil or g.gw == true); T.ok(g.lw == nil or g.lw == true)
        end
    end },

    { "blocked values (secret) show -- instead of errors; English", function(T, Mock)
        local S = setup(Mock, { mode = "secret" })
        S:slash("meta ouro 200"); S:slash("meta nivel 40"); S:update(1)
        T.has(S:bar(), "Meta"); tip(S)
        local H = setup(Mock, { locale = "enUS" })
        H:slash("goal gold 200"); H:slash("goal level 35"); H:update(1)
        T.has(H:bar(), "Goal 200g 61%"); T.has(H:bar(), "Lv 35")
        H:slash("help"); T.has(all(H), "/farol goal")
    end },
}
