-- Tooltip por item: cada informação mostra só o seu; Shift / opção / fundo da barra mostram tudo;
-- listas limitadas a 5; arrastar e clique direito continuam funcionando sobre os itens.
-- Per-item tooltip: each item shows its own; Shift / option / bar background show everything; lists capped at 5.

local function cellOf(H, key)
    for _, cell in ipairs(H.env.FarolFrame._fontStrings) do
        if cell.farolKey == key and cell:IsShown() then return cell end
    end
end

local function hover(H, key)
    local cell = cellOf(H, key)
    assert(cell, "cell for " .. key)
    H.env.GameTooltip.lines = {}
    cell.hover._scripts.OnEnter(cell.hover)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

local function background(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "each item shows only its own details (much smaller tooltip)", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        local gold = hover(H, "gold")
        T.has(gold, "Ouro = 123g 45s 67c"); T.has(gold, "Ouro por hora")
        T.hasnt(gold, "Latência"); T.hasnt(gold, "Durabilidade"); T.hasnt(gold, "Amigos")
        T.has(gold, "Segure Shift para ver todas as informações.")
        local durab = hover(H, "durab")
        T.has(durab, "Durabilidade (menor peça) = 15%"); T.has(durab, "[Elmo] = 50%")
        T.hasnt(durab, "Ouro =")
        local ms = hover(H, "ms")
        T.has(ms, "Latência = local 40 ms / mundo 60 ms"); T.has(ms, "FPS = 60")
        local _, gLines = string.gsub(gold, " / ", "")
        local _, fLines = string.gsub(background(H), " / ", "")
        T.ok(gLines < fLines / 2, "item tooltip is less than half of the full one")
    end },

    { "Shift, the option, or the bar background show the full tooltip", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        H.shift = true
        local text = hover(H, "gold")
        T.has(text, "Latência ="); T.has(text, "Durabilidade"); T.hasnt(text, "Segure Shift")
        H.shift = false
        T.has(background(H), "Latência =", "background = full")
        H:slash("aparencia tooltip")
        T.eq(H.env.FarolDB.tooltipFull, true)
        T.has(hover(H, "gold"), "Latência =", "option = always full")
        H:slash("aparencia tooltip"); T.eq(H.env.FarolDB.tooltipFull, false)
        H:slash("aparencia")
        T.eq(H:text(H.env.FarolApp_tooltipFull.label), "Tooltip completo (todas as informações em qualquer item)")
        H:check(H.env.FarolApp_tooltipFull, true); T.eq(H.env.FarolDB.tooltipFull, true)
        H:slash("aparencia padrao"); T.eq(H.env.FarolDB.tooltipFull, false, "restore defaults")
    end },

    { "the open tooltip refreshes for the same item", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        hover(H, "gold")
        H.env.GameTooltip.lines = {}
        H:update(1)
        local text = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(text, "Ouro ="); T.hasnt(text, "Latência", "still the gold tooltip after the refresh")
    end },

    { "right-click and drag over an item still reach the bar", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        local cell = cellOf(H, "zone")
        cell.hover._scripts.OnMouseUp(cell.hover, "RightButton")
        T.ok(H.env.FarolOptions and H.env.FarolOptions:IsShown(), "right-click over an item opens the options")
        local started, stopped = false, false
        local frame = H.env.FarolFrame
        local start, stop = frame._scripts.OnDragStart, frame._scripts.OnDragStop
        frame._scripts.OnDragStart = function(...) started = true; return start(...) end
        frame._scripts.OnDragStop = function(...) stopped = true; return stop(...) end
        cell.hover._scripts.OnDragStart(cell.hover)
        cell.hover._scripts.OnDragStop(cell.hover)
        T.ok(started and stopped, "drag over an item moves the bar")
    end },

    { "long lists show at most 5 lines and 'and N more'", function(T, Mock)
        local now = os.time()
        local chars = { Garrosh = { gold = 1, level = 30, t = now } }
        for i = 1, 8 do chars["Alt" .. i] = { gold = 1000 * i, level = 10, t = now } end
        local H = Mock.new():login({ chars = { Azralon = chars } }); H:update(1)
        local text = hover(H, "gold")
        local shown = 0
        for _ in string.gmatch(text, "Alt%d %(10%)") do shown = shown + 1 end
        if string.find(text, "Garrosh (30)", 1, true) then shown = shown + 1 end
        T.eq(shown, 5, "5 characters listed (the current one included)")
        T.has(text, "e mais 4", "9 characters - 5 shown")
        H.durability = {}
        for slot = 1, 8 do H.durability[slot] = { 10 + slot, 100 } end
        H:event("UPDATE_INVENTORY_DURABILITY"); H:update(1)
        T.has(hover(H, "durab"), "e mais 3")
    end },

    { "every bar item has tooltip sections; English", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        for _, key in ipairs(H.ns.ITEM_ORDER) do
            T.ok(H.ns.TIP_SECTIONS[key], "sections for " .. key)
            H:slash("show " .. key)
        end
        H:update(1)
        for _, key in ipairs(H.ns.ITEM_ORDER) do
            if cellOf(H, key) then T.has(hover(H, key), "Hold Shift to see all information.", key) end
        end
    end },
}
