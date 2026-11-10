-- Ordem dos itens na barra: setas, salvar, validar, restaurar, modo vertical.
-- Bar item order: arrows, saving, validation, restore, vertical mode.

local function positions(H)
    -- posição de cada texto na barra (sem cores/ícones)
    local bar = H:bar()
    return function(fragment) return string.find(bar, fragment, 1, true) end
end

return {
    { "default order matches the original bar", function(T, Mock)
        local H = Mock.new():login()
        local order = H.env.FarolDB.order
        T.eq(#order, 19); T.eq(order[1], "fps"); T.eq(order[19], "guild")
        local at = positions(H)
        T.ok(at("fps") < at("ms") and at("ms") < at("Floresta"), "fps, latency, zone in default order")
    end },

    { "arrows move items and the bar follows immediately", function(T, Mock)
        local H = Mock.new():login()
        H:slash("ordem")
        local window = H.env.FarolOrder
        T.ok(window:IsShown(), "window open"); T.eq(window._toplevel, true)
        T.eq(H:text(window.rows[5].text), "Zona")
        for _ = 1, 4 do H:click(H.env["FarolOrderUp" .. (6 - _)]) end -- sobe a Zona da 5ª para a 1ª posição
        T.eq(H.env.FarolDB.order[1], "zone")
        T.eq(H:text(window.rows[1].text), "Zona")
        local at = positions(H)
        T.ok(at("Floresta") < at("fps"), "zone now first on the bar")
        H:click(H.env.FarolOrderDown1) -- desce de novo uma posição
        T.eq(H.env.FarolDB.order[2], "zone"); T.eq(H.env.FarolDB.order[1], "fps")
    end },

    { "first up and last down arrows are disabled; hidden items are greyed", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H:slash("order")
        T.eq(H.env.FarolOrderUp1._disabled, true); T.eq(H.env.FarolOrderDown1._disabled, false)
        T.eq(H.env.FarolOrderDown19._disabled, true)
        H:click(H.env.FarolOrderUp1); T.eq(H.env.FarolDB.order[1], "fps", "nothing moves past the top")
        local guild = H.env.FarolOrder.rows[19]
        T.eq(H:text(guild.text), "Guild online (hidden)"); T.eq(guild.text._color[1], 0.5)
        H:slash("show guild")
        T.eq(H:text(guild.text), "Guild online", "updates when the item is shown")
    end },

    { "order is saved; invalid, duplicated and unknown entries are fixed", function(T, Mock)
        local H = Mock.new():login({ order = { "gold", "zone", "gold", "evil", 42 } })
        local order = H.env.FarolDB.order
        T.eq(#order, 19, "every item exactly once")
        T.eq(order[1], "gold"); T.eq(order[2], "zone"); T.eq(order[3], "fps", "missing items keep default order")
        local seen = {}
        for _, key in ipairs(order) do T.ok(not seen[key], "no duplicates: " .. key); seen[key] = true end
        local at = positions(H)
        T.ok(at("123g") < at("Floresta") and at("Floresta") < at("fps"), "bar uses the saved order")
    end },

    { "restore default order (button and command) and vertical mode", function(T, Mock)
        local H = Mock.new():login({ order = { "guild", "gold" } })
        H:slash("aparencia coluna")
        T.has(H.strip(H:cells()[1]._text), "123g", "one-column bar starts with gold (guild is hidden)")
        H:slash("ordem padrao"); T.has(H:lastMsg(), "ordem da barra restaurada")
        T.eq(H.env.FarolDB.order[1], "fps")
        H:slash("ordem"); H:click(H.env.FarolOrderUp2)
        T.eq(H.env.FarolDB.order[1], "ms")
        H:click(H.env.FarolOrderReset); T.eq(H.env.FarolDB.order[1], "fps")
        H:slash("ordem xyz"); T.has(H:lastMsg(), "uso: /farol ordem")
    end },

    { "the options menu has an Order... button", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local button
        for _, frame in ipairs(H:framesOf("Button")) do
            if frame._text == "Order..." then button = frame end
        end
        T.ok(button, "button exists")
        H:click(button)
        T.ok(H.env.FarolOrder:IsShown())
        T.ok(H.env.FarolOrder._raisedAt > H.env.FarolOptions._raisedAt, "opens in front of the menu")
    end },
}
