-- Contagem regressiva dos resets diário e semanal: barra, tooltip, API antiga e valores ruins.
-- Daily and weekly reset countdown: bar, tooltip, old API and bad values.

local function setup(Mock, opts)
    local H = Mock.new(opts):login()
    H:slash("show reset")
    H:update(1)
    return H
end

local function tip(H)
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "off by default; /farol show reset turns it on", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Diário", "off by default")
        H:slash("show reset"); H:update(1)
        T.has(H:bar(), "Diário 5h 12m · Semanal 2d 4h")
        T.eq(H.env.FarolDB.items.reset, true, "saved")
    end },

    { "English labels and short countdowns", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        T.has(H:bar(), "Daily 5h 12m · Weekly 2d 4h")
        H.dailyReset, H.weeklyReset = 38 * 60 + 59, 86400 + 59
        H:update(1)
        T.has(H:bar(), "Daily 38m · Weekly 1d 0h")
    end },

    { "tooltip shows time left, local moment and server time", function(T, Mock)
        local H = setup(Mock)
        local text = tip(H)
        -- servidor 21:05 + 5h 12m = 02:17; + 2d 4h = 01:05
        T.has(text, "Reset diário em = 5h 12m (")
        T.has(text, "local · 02:17 servidor)")
        T.has(text, "Reset semanal em = 2d 4h (")
        T.has(text, "local · 01:05 servidor)")
        local weekday = string.match(text, "Reset semanal em = 2d 4h %((%S+) %d%d:%d%d local")
        T.ok(weekday and string.find("dom,seg,ter,qua,qui,sex,sáb", weekday, 1, true), "weekday name in Portuguese")
    end },

    { "old client (3.3.5a) shows only the daily reset", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk" })
        T.has(H:bar(), "Diário 5h 12m"); T.hasnt(H:bar(), "Semanal")
        T.has(tip(H), "Reset semanal em = o jogo não informou")
        H:slash("aviso status")
        T.has(H.strip(table.concat(H.msgs, "/")), "diário 5h 12m (função: GetQuestResetTime) · semanal -- (função: --)")
    end },

    { "status shows which function answered", function(T, Mock)
        local H = setup(Mock)
        H:slash("aviso status")
        T.has(H.strip(table.concat(H.msgs, "/")), "diário 5h 12m (função: C_DateAndTime) · semanal 52h 00m (função: C_DateAndTime)")
    end },

    { "missing, blocked, negative, NaN or infinite values show '--' and never error", function(T, Mock)
        local H = setup(Mock)
        for _, bad in ipairs({ false, -1, 0 / 0, math.huge, -math.huge, 9 * 86400, "5", {} }) do
            H.dailyReset, H.weeklyReset = bad, bad
            H:update(1)
            T.has(H:bar(), "Reset --", "bad value " .. tostring(bad))
            T.has(tip(H), "Reset diário em = o jogo não informou")
        end
        H.dailyReset = 600; H.weeklyReset = 30 * 86400 -- semanal fora da faixa
        H:update(1); T.has(H:bar(), "Diário 10m"); T.hasnt(H:bar(), "Semanal")
        H.env.C_DateAndTime.GetSecondsUntilDailyReset = function() error("blocked by the game") end
        H:update(1); T.has(H:bar(), "Reset --", "error inside the game API is contained")
        H.env.C_DateAndTime = nil
        H:update(1); T.has(H:bar(), "Reset --", "API missing")
    end },
}
