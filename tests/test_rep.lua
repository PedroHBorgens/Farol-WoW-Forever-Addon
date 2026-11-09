-- Reputação na barra: facção acompanhada, nível com cor, progresso, reputação por hora e tooltip.
-- Reputation on the bar: watched faction, colored standing, progress, reputation per hour, tooltip.

local function honored(value) -- Darnassus, Honrado (6): de 9000 a 21000
    return { name = "Darnassus", reaction = 6, min = 9000, max = 21000, value = value, id = 69 }
end

local function setup(Mock, opts)
    local H = Mock.new(opts)
    H.faction = honored(13200) -- 4200 de 12000 = 35%
    H:login()
    H:slash("show rep")
    return H
end

local function tip(H)
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "shows the watched faction, colored standing and progress", function(T, Mock)
        local H = setup(Mock)
        T.has(H:bar(), "Darnassus Honrado 35%")
        T.has(H:barRaw(), "|cff00991aHonrado|r", "standing in the game's color")
        T.eq(H.env.FarolDB.items.rep, true)
    end },

    { "no watched faction shows 'Rep --' and a hint in the tooltip", function(T, Mock)
        local H = Mock.new():login()
        H:slash("show reputacao")
        T.has(H:bar(), "Rep --")
        T.has(tip(H), "nenhuma facção acompanhada")
    end },

    { "reputation per hour and time to the next standing", function(T, Mock)
        local H = setup(Mock)
        -- +500 de reputação em 10 minutos = 3000/h; faltam 7300 = 2h 26m
        for _ = 1, 10 do H.faction.value = H.faction.value + 50; H:update(60) end
        T.has(H:bar(), "+3.0k/h")
        local text = tip(H)
        T.has(text, "Reputação = Darnassus"); T.has(text, "Nível = Honrado")
        T.has(text, "Progresso = 4.7k / 12.0k (39%)")
        T.has(text, "Reputação por hora = +3.0k")
        T.has(text, "Próximo nível em = 2h 26m")
    end },

    { "the rate waits one minute; switching factions restarts the count", function(T, Mock)
        local H = setup(Mock)
        H.faction.value = H.faction.value + 200; H:update(30)
        T.hasnt(H:bar(), "/h", "no rate before 1 minute")
        T.has(tip(H), "Reputação por hora = calculando")
        H.faction = { name = "Ferraria", reaction = 4, min = 0, max = 3000, value = 100, id = 70 }
        H:update(1)
        H.faction.value = 400; H:update(90)
        T.has(H:bar(), "Ferraria Neutro 13%")
        T.has(H:bar(), "+12.0k/h", "only the gain in the new faction counts (300 in 90 s)")
    end },

    { "exalted (no next standing) shows only the standing; session reset clears the rate", function(T, Mock)
        local H = setup(Mock)
        H.faction = { name = "Darnassus", reaction = 8, min = 42000, max = 42000, value = 42000, id = 69 }
        H:update(1)
        local repCell
        for _, cell in ipairs(H:cells()) do
            if string.find(cell._text, "Darnassus", 1, true) then repCell = H.strip(cell._text) end
        end
        T.has(repCell, "Darnassus Exaltado"); T.hasnt(repCell, "%", "no percentage at the last standing")
        local H2 = setup(Mock)
        for _ = 1, 5 do H2.faction.value = H2.faction.value + 100; H2:update(60) end
        T.has(H2:bar(), "/h")
        H2:slash("sessao zerar"); H2:update(1)
        T.hasnt(H2:bar(), "/h", "reset clears the reputation rate")
    end },

    { "works with the old API (3.3.5a) and status shows which function was used", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk", locale = "enUS" })
        T.has(H:bar(), "Darnassus Honrado 35%")
        H:slash("warn status")
        T.has(H.strip(table.concat(H.msgs, "/")), "reputation: Darnassus (function: GetWatchedFactionInfo)")
        local H2 = setup(Mock)
        H2:slash("aviso status")
        T.has(H2.strip(table.concat(H2.msgs, "/")), "reputação: Darnassus (função: C_Reputation)")
    end },

    { "blocked or invalid values show '--' instead of an error", function(T, Mock)
        local H = setup(Mock)
        H.faction.value = 0 / 0
        H:update(1); T.has(H:bar(), "Rep --")
        H.faction = { name = "Darnassus", reaction = 6, min = "x", max = 21000, value = 13200, id = 69 }
        H:update(1); T.has(H:bar(), "Rep --")
        H.env.C_Reputation.GetWatchedFactionData = function() error("blocked by the game") end
        H:update(1); T.has(H:bar(), "--", "error inside the game API is contained")
    end },
}
