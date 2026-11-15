-- Versão 3: perfis e barras. Dados antigos (2.x, tudo "solto") viram profiles.account.bars[1] sem mudar nada na
-- tela; dados novos (3.x) carregam igual; o que é salvo no disco não tem metatable; perfis adulterados voltam ao padrão.
-- Version 3: profiles and bars. Old flat data migrates to bars[1] with an identical bar; tampered profiles fall back.

-- Cópia "crua", como o WoW grava o SavedVariables (ignora metatables, só os campos de verdade).
local function rawcopy(value, depth)
    depth = depth or 0
    assert(depth < 20, "saved data too deep")
    if type(value) ~= "table" then return value end
    local out = {}
    for key, inner in next, value do out[key] = rawcopy(inner, depth + 1) end
    return out
end

local OLD = { shown = true, locked = true, point = "BOTTOM", relPoint = "BOTTOM", x = 12, y = 34, scale = 1.3,
    bgAlpha = 0.4, border = false, barWidth = 1, fontSize = 14, iconSize = 18, icons = false, hideCombat = true,
    hideInstance = true, items = { fps = false, gold = true, clock = true }, order = { "clock", "gold" },
    lang = "en", serverTime = true, newsSeen = 99, alarms = {}, warnings = {} }

return {
    { "2.x flat data migrates to profile bar 1 and the bar looks the same", function(T, Mock)
        local before = Mock.new():login(rawcopy(OLD)); before:update(1)
        local oldText = before:barRaw()
        local H = Mock.new():login(rawcopy(OLD)); H:update(1)
        local db = H.env.FarolDB
        T.eq(H:barRaw(), oldText, "same bar after migration")
        local bar = rawget(db, "profiles").account.bars[1]
        T.eq(bar.point, "BOTTOM"); T.eq(bar.x, 12); T.eq(bar.scale, 1.3); T.eq(bar.barWidth, 1)
        T.eq(bar.items.fps, false); T.eq(bar.order[1], "clock")
        T.eq(rawget(db, "scale"), nil, "bar keys no longer loose on FarolDB")
        T.eq(rawget(db, "items"), nil); T.eq(rawget(db, "lang"), "en", "globals stay on FarolDB")
        T.eq(rawget(db, "activeBar"), 1); T.eq(rawget(db, "dataVersion"), 3)
        T.eq(db.scale, 1.3, "code still reads db.scale"); T.eq(db.items.gold, true)
    end },

    { "3.x data saved to disk loads back identically (round trip, no metatable on disk)", function(T, Mock)
        local H = Mock.new():login(rawcopy(OLD)); H:update(1)
        H:slash("aparencia escala 80"); H.env.FarolDB.items.gold = false; H:update(5)
        local text = H:barRaw()
        T.hasnt(H:bar(), "123g", "gold hidden")
        local disk = rawcopy(H.env.FarolDB)
        T.eq(getmetatable(disk), nil)
        T.eq(disk.scale, nil, "written to the bar, not loose")
        local bar = disk.profiles.account.bars[1]
        T.eq(bar.scale, 0.8); T.eq(bar.items.gold, false)
        local H2 = Mock.new():login(disk); H2:update(1)
        T.eq(H2:barRaw(), text, "same bar after reload")
        T.eq(H2.env.FarolDB.scale, 0.8)
        local disk2 = rawcopy(H2.env.FarolDB)
        T.eq(disk2.profiles.account.bars[1].scale, 0.8, "stable across several reloads")
    end },

    { "writes from the options go to the active bar", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        local db = H.env.FarolDB
        db.x = 77; db.items = { gold = false }
        local bar = rawget(db, "profiles").account.bars[1]
        T.eq(bar.x, 77); T.eq(bar.items.gold, false); T.eq(rawget(db, "x"), nil)
        db.lang = "pt"; T.eq(rawget(db, "lang"), "pt", "global keys stay loose")
    end },

    { "tampered profiles fall back to defaults; unknown keys are dropped", function(T, Mock)
        local bad = {
            { profiles = "x" },
            { profiles = { account = "x" } },
            { profiles = { account = { bars = "x" } } },
            { profiles = { account = { bars = { "x" } } } },
            { profiles = { account = { bars = { { scale = 0 / 0, x = 1 / 0, point = "EVIL", items = "x",
                order = { "nope", 5 }, evil = function() end, barWidth = -5, fontSize = 999 } } },
                other = { bars = { { scale = 2 } } } }, activeBar = 99, dataVersion = "x" },
        }
        local clean = Mock.new():login(); clean:update(1)
        for i, saved in ipairs(bad) do
            local H = Mock.new():login(saved); H:update(1)
            local db = H.env.FarolDB
            T.eq(H:barRaw(), clean:barRaw(), "default bar for case " .. i)
            T.eq(rawget(db, "activeBar"), 1); T.eq(rawget(db, "dataVersion"), 3)
            local profiles = rawget(db, "profiles")
            T.eq(profiles.other, nil, "unknown profile dropped")
            local bar = profiles.account.bars[1]
            T.eq(bar.evil, nil); T.eq(bar.scale, 1); T.eq(bar.point, "TOP"); T.eq(bar.x, 0)
            T.eq(#profiles.account.bars, 1)
        end
    end },

    { "profile wins over leftover loose keys; English", function(T, Mock)
        local saved = { scale = 2, x = 5, lang = "en",
            profiles = { account = { bars = { { scale = 0.9, x = 40 } } } } }
        local H = Mock.new():login(saved); H:update(1)
        T.eq(H.env.FarolDB.scale, 0.9); T.eq(H.env.FarolDB.x, 40)
        T.eq(rawget(H.env.FarolDB, "scale"), nil)
        H:slash("help"); T.has(H:lastMsg() or "", "farol")
    end },
}
