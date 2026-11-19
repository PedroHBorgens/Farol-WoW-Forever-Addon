-- Versão 3.1: até 3 barras, cada uma com itens, posição, aparência e ordem próprios.
-- Version 3.1: up to 3 bars, each with its own items, position, appearance and order.

local function cellsOf(frame)
    local list = {}
    for _, fs in ipairs(frame._fontStrings) do
        if fs.farolCell and fs:IsShown() then list[#list + 1] = fs end
    end
    table.sort(list, function(a, b) return a.farolCell < b.farolCell end)
    return list
end

local function barText(H, frame)
    local texts = {}
    for _, cell in ipairs(cellsOf(frame)) do texts[#texts + 1] = cell._text or "" end
    return H.strip(table.concat(texts, "   "))
end

local function data(H, n) return rawget(H.env.FarolDB, "profiles").account.bars[n] end

local function rawcopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, inner in next, value do out[key] = rawcopy(inner) end
    return out
end

local function buttonWithText(H, label)
    local found
    for _, frame in ipairs(H:framesOf("Button")) do
        if frame._text == label then found = frame end
    end
    return found
end

return {
    { "bars 2 and 3 start off and are not even created; bar 1 unchanged", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.eq(H.env.FarolBar2, nil); T.eq(H.env.FarolBar3, nil)
        T.eq(data(H, 2).shown, false); T.eq(data(H, 3).shown, false)
        T.eq(data(H, 2).y, -60, "below bar 1"); T.eq(data(H, 3).y, -100)
        T.has(H:bar(), "fps")
        H:slash("barra")
        T.has(H.strip(table.concat(H.msgs, "\n")), "Barra 2: desligada")
    end },

    { "/farol barra 2 mostrar: bar 2 appears and has its own items", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        local bar1 = H:bar()
        H:slash("barra 2 mostrar")
        T.has(H:lastMsg(), "Barra 2 escolhida (ligada)")
        local bar2 = H.env.FarolBar2
        T.ok(bar2 and bar2:IsShown(), "bar 2 shown")
        T.eq(rawget(H.env.FarolDB, "activeBar"), 2)
        H:slash("esconder fps"); H:slash("mostrar ouro"); H:update(2)
        T.hasnt(barText(H, bar2), "fps"); T.has(barText(H, bar2), "123g")
        T.has(H:bar(), "fps", "bar 1 keeps its items"); T.eq(H:bar(), bar1)
        T.eq(data(H, 1).items.fps, true); T.eq(data(H, 2).items.fps, false)
        H:slash("barra 1"); H:slash("esconder fps"); H:update(2)
        T.hasnt(H:bar(), "fps"); T.eq(data(H, 2).items.gold, true)
    end },

    { "appearance, order, lock and position are per bar", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 3 mostrar")
        H:slash("aparencia escala 150"); H:slash("aparencia fundo 20")
        T.eq(H.env.FarolBar3._scale, 1.5); T.eq(H.env.FarolFrame._scale, 1, "bar 1 untouched")
        T.eq(data(H, 3).bgAlpha, 0.2); T.eq(data(H, 1).bgAlpha, 0.7)
        H:slash("lock"); T.eq(data(H, 3).locked, true); T.eq(data(H, 1).locked, false)
        T.ok(not H.env.FarolBarResize3:IsShown(), "bar 3 grip hidden"); T.ok(H.env.FarolBarResize:IsShown())
        H.env.FarolBar3._scripts.OnDragStop(H.env.FarolBar3)
        T.eq(data(H, 3).x, 12); T.eq(data(H, 1).x, 0, "dragging bar 3 does not move bar 1")
        H:slash("reset"); T.eq(data(H, 3).x, 0); T.eq(data(H, 3).y, -100, "reset goes back below bar 1")
        H:slash("ordem topo relogio")
        T.eq(rawget(H.env.FarolDB, "activeBar"), 3)
    end },

    { "the menu has Bar 1/2/3 buttons; right-click on a bar selects it", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 2 mostrar"); H:slash("barra 1")
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local b2 = buttonWithText(H, "Barra 2")
        T.ok(b2, "button Barra 2"); T.ok(buttonWithText(H, "Barra 3 (desl.)"), "bar 3 marked off")
        T.eq(buttonWithText(H, "Barra 1")._highlight, true)
        H:click(b2)
        T.eq(rawget(H.env.FarolDB, "activeBar"), 2); T.eq(b2._highlight, true)
        H:slash("barra 1")
        H.env.FarolBar2._scripts.OnMouseUp(H.env.FarolBar2, "RightButton")
        T.eq(rawget(H.env.FarolDB, "activeBar"), 2, "right-click on bar 2 selects bar 2")
        T.ok(H.env.FarolOptions:IsShown(), "menu open")
        H:slash("aparencia"); T.has(H:text(H.env.FarolAppearance.title), "Aparência — Barra 2")
    end },

    { "bars survive save and reload; selection goes back to bar 1", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 2 mostrar"); H:slash("esconder fps"); H:slash("aparencia escala 80")
        H.env.FarolBar2._scripts.OnDragStop(H.env.FarolBar2)
        local disk = rawcopy(H.env.FarolDB)
        T.eq(getmetatable(disk), nil)
        local H2 = Mock.new():login(disk); H2:update(2)
        T.ok(H2.env.FarolBar2 and H2.env.FarolBar2:IsShown(), "bar 2 back")
        T.eq(H2.env.FarolBar2._scale, 0.8); T.eq(data(H2, 2).x, 12)
        T.hasnt(barText(H2, H2.env.FarolBar2), "fps"); T.has(H2:bar(), "fps")
        T.eq(rawget(H2.env.FarolDB, "activeBar"), 1); T.eq(H2.env.FarolBar3, nil)
    end },

    { "updates keep running with bar 1 hidden; server requests only for visible bars", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 2 mostrar"); H:slash("mostrar guilda")
        H:slash("barra 1 esconder")
        T.ok(not H.env.FarolFrame:IsShown(), "bar 1 hidden")
        local before = H.rosterRequests or 0
        H:update(1); H:update(1)
        T.has(barText(H, H.env.FarolBar2), "fps", "bar 2 is drawn")
        H:slash("barra 2 esconder"); H:update(70); H:update(70)
        T.ok(not H.env.FarolBar2:IsShown())
        T.ok((H.rosterRequests or 0) <= before + 1, "no roster requests once every bar is hidden")
    end },

    { "hover on bar 2 shows its own tooltip; combat hiding is per bar", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 2 mostrar"); H:slash("aparencia combate"); H:update(1)
        local cell = cellsOf(H.env.FarolBar2)[1]
        H.env.GameTooltip.lines = {}
        cell.hover._scripts.OnEnter(cell.hover)
        T.eq(H.env.GameTooltip.owner, H.env.FarolBar2, "tooltip anchored to bar 2")
        T.ok(#H.env.GameTooltip.lines > 1)
        H:event("PLAYER_REGEN_DISABLED")
        T.ok(not H.env.FarolBar2:IsShown(), "bar 2 hides in combat"); T.ok(H.env.FarolFrame:IsShown(), "bar 1 stays")
        H:event("PLAYER_REGEN_ENABLED"); T.ok(H.env.FarolBar2:IsShown())
    end },

    { "invalid bar commands are refused; English", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        for _, cmd in ipairs({ "bar 0", "bar 4", "bar 99999999999999999999", "bar x", "bar 2 fly", "bar -1",
                               "bar 2.5", "bar 2 show extra" }) do
            H:slash(cmd)
            T.has(H:lastMsg(), "usage: /farol bar", cmd)
        end
        T.eq(rawget(H.env.FarolDB, "activeBar"), 1); T.eq(H.env.FarolBar2, nil)
        H:slash("bar 3 show"); T.has(H:lastMsg(), "Bar 3 selected (on)")
        H:slash("help"); T.has(table.concat(H.msgs, "\n"), "/farol bar N")
    end },

    { "tampered bars 2 and 3 fall back to safe defaults", function(T, Mock)
        local bad = { profiles = { account = { bars = { {}, { shown = "yes", scale = 0 / 0, y = 1 / 0, items = 5,
            order = { "x" }, x = -1 / 0, point = "EVIL", evil = true }, { shown = true, scale = 9, barWidth = -1 } } } } }
        local H = Mock.new():login(bad); H:update(1)
        local b2, b3 = data(H, 2), data(H, 3)
        T.eq(b2.shown, false); T.eq(b2.scale, 1); T.eq(b2.y, -60); T.eq(b2.x, 0); T.eq(b2.point, "TOP")
        T.eq(b2.evil, nil); T.eq(type(b2.items), "table"); T.eq(type(b2.order), "table")
        T.eq(b3.shown, true); T.eq(b3.scale, 1); T.eq(b3.barWidth, 0)
        T.ok(H.env.FarolBar3:IsShown(), "valid shown bar 3 is created"); T.eq(H.env.FarolBar2, nil)
    end },
}
