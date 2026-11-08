-- XP por hora, ouro por hora, tempo até o próximo nível e "zerar sessão".
-- XP per hour, gold per hour, time to next level and session reset.

local function setup(Mock, opts)
    local H = Mock.new(opts):login()
    H:slash("show xph"); H:slash("show ouroh")
    return H
end

return {
    { "rates wait one minute before showing numbers", function(T, Mock)
        local H = setup(Mock)
        H.xp.cur = 6500; H:update(30)
        T.has(H:bar(), "XP/h --"); T.has(H:bar(), "Ouro/h --")
        H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        T.has(H.strip(table.concat(H.env.GameTooltip.lines, " / ")), "XP por hora = calculando... (1 min)")
    end },

    { "XP per hour and time to the next level", function(T, Mock)
        local H = setup(Mock)
        -- 1000 XP em 10 minutos = 6000 XP/h; faltam 2800 XP = 28 minutos
        for _ = 1, 10 do H.xp.cur = H.xp.cur + 100; H:update(60) end
        T.has(H:bar(), "XP/h 6.0k · 28m")
        H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        local tip = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(tip, "XP por hora = 6.0k"); T.has(tip, "Próximo nível em = 28m")
    end },

    { "XP gained across a level-up is counted", function(T, Mock)
        local H = setup(Mock)
        H.xp.cur = 9500; H:update(1)                       -- +3300
        H.xp.level, H.xp.cur, H.xp.max = 31, 200, 11000    -- +500 até o nível, +200 depois
        H:event("PLAYER_XP_UPDATE")
        H:update(599)                                       -- 10 minutos no total
        -- 4000 XP em 10 min = 24000/h
        T.has(H:bar(), "XP/h 24.0k")
    end },

    { "XP per hour is hidden at max level", function(T, Mock)
        local H = setup(Mock)
        H.xp.level = 60; H:update(120)
        T.hasnt(H:bar(), "XP/h")
    end },

    { "gold per hour, positive and negative", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        H.money = 1234567 + 10000; H:update(1800) -- +1 ouro em 30 min = 2 ouros/h
        T.has(H:bar(), "Gold/h +2g 0s")
        H.money = 1234567 - 5000; H:update(1800)  -- -50 prata em 1 h
        T.has(H:bar(), "Gold/h -50s 0c")
    end },

    { "session reset restarts gold, XP and time counters", function(T, Mock)
        local H = setup(Mock)
        H:slash("show sessao"); H:slash("show tempo")
        H.money = 1234567 + 10000
        for _ = 1, 10 do H.xp.cur = H.xp.cur + 100; H:update(60) end
        T.has(H:bar(), "Sessão +1g 0s")
        H:slash("sessao zerar")
        T.has(H:lastMsg(), "sessão zerada")
        H:update(1)
        local bar = H:bar()
        T.has(bar, "Sessão +0c"); T.has(bar, "XP/h --"); T.has(bar, "Ouro/h --"); T.has(bar, "Jogando 0m")
    end },

    { "the options menu has a session reset button", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local button
        for _, frame in ipairs(H:framesOf("Button")) do
            if frame._text == "Reset session" then button = frame end
        end
        T.ok(button, "button exists")
        H.money = 1234567 + 999; H:update(120)
        H:click(button)
        T.has(H:lastMsg(), "session reset")
        H:slash("show session"); H:update(1)
        T.has(H:bar(), "Session +0c")
    end },
}
