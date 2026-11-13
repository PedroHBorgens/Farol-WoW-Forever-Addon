-- Lixo nas bolsas: valor de venda dos itens cinzentos, tooltip, dica no aviso de bolsas, APIs moderna e antiga.
-- Junk in bags: vendor value of gray items, tooltip, hint in the bag warning, modern and old APIs.
-- O Farol só MOSTRA: nunca vende (test_toc proíbe as funções de vender/mover/destruir itens).

local function fixGear(H)
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function setup(Mock, opts)
    local H = Mock.new(opts):login(); fixGear(H)
    H:slash("show lixo"); H:update(1)
    return H
end

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "off by default; shows the vendor value of gray items and the slots they take", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Lixo", "off by default")
        H:slash("show lixo"); H:update(1)
        -- 8 couros x 8s = 64s, garra 12s 50c, espada 2g 50s = 3g 26s 50c; pão (branco) e pedra (sem valor) fora
        T.has(H:bar(), "Lixo 3g 26s (3)")
        T.eq(H.env.FarolDB.items.junk, true)
    end },

    { "tooltip lists the most valuable junk first, with a reminder that Farol never sells", function(T, Mock)
        local H = setup(Mock)
        local text = tip(H)
        T.has(text, "Lixo nas bolsas (valor de venda) = 3g 26s")
        T.has(text, "Espaços ocupados por lixo = 3")
        local sword, leather, claw = string.find(text, "Espada Enferrujada", 1, true),
            string.find(text, "Couro Rasgado x8", 1, true), string.find(text, "Garra Quebrada", 1, true)
        T.ok(sword and leather and claw and sword < leather and leather < claw, "sorted by value")
        T.has(text, "o Farol só mostra, nunca vende")
        T.hasnt(text, "Pão de Centeio"); T.hasnt(text, "Pedra Sem Valor")
    end },

    { "no junk: 'Junk 0' in English; items still loading are counted when they arrive", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        H.bagItems = { [0] = { [1] = { 9010, 5 } } }; H:update(1)
        T.has(H:bar(), "Junk 0")
        T.has(tip(H), "Junk in bags (vendor value) = 0")
        H.bagItems = { [0] = { [1] = { 9001, 8 }, [2] = { 9003, 1 } } }
        H.itemsLoading = { [9003] = true }; H:update(1)
        T.has(H:bar(), "Junk 64s 0c (1)", "the sword is not loaded yet")
        T.has(tip(H), "loading information for 1 item(s)...")
        H.itemsLoading = nil; H:update(1)
        T.has(H:bar(), "Junk 3g 14s (2)", "counted once the game loads it")
    end },

    { "works with the old API (3.3.5a); status shows which function answered", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk" })
        T.has(H:bar(), "Lixo 3g 26s (3)")
        H:slash("aviso status")
        T.has(H.strip(table.concat(H.msgs, "/")), "lixo nas bolsas: 3g 26s em 3 espaço(s) (função: GetContainerItemInfo).")
        local M = setup(Mock)
        M:slash("aviso status")
        T.has(M.strip(table.concat(M.msgs, "/")), "lixo nas bolsas: 3g 26s em 3 espaço(s) (função: C_Container).")
    end },

    { "the bag warning says how much junk can be sold (plain text in the history)", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.bagFree = { [0] = 1, 0, 0, 0, 0 }; H:update(1)
        local text = H:text(H.env.FarolWarnPopup.text)
        T.has(text, "Bolsas quase cheias: 1 espaço(s) livre(s). Há 3 espaço(s) com lixo (3g 26s) para vender.")
        local history = H.env.FarolCharDB.warnHistory
        T.has(history[#history].text, "(3g 26s)"); T.hasnt(history[#history].text, "|")
        H:click(H.env.FarolWarnSilence)
        local N = Mock.new():login(); fixGear(N)
        N.bagItems = {}; N.bagFree = { [0] = 1, 0, 0, 0, 0 }; N:update(1)
        T.eq(N:text(N.env.FarolWarnPopup.text), "Bolsas quase cheias: 1 espaço(s) livre(s).", "no junk: no hint")
    end },

    { "bad, blocked or missing values never break the bar", function(T, Mock)
        local H = setup(Mock)
        H.items[9001] = { "Couro Rasgado", 0, 0 / 0 }; H.items[9002] = { "Garra", 0, math.huge }
        H.items[9003] = { "Espada|Hitem:1|h", 0, -5 }
        H:update(1); T.has(H:bar(), "Lixo 0", "invalid prices are ignored")
        H.items[9001] = { "Couro Rasgado", 0, 800 }
        H.bagItems = { [0] = { [1] = { 9001, 0 / 0 }, [2] = { 9001, -3 }, [3] = { 9001, 1e9 } } }
        H:update(1); T.has(H:bar(), "Lixo 24s 0c (3)", "odd stack sizes count as 1")
        H.env.C_Container.GetContainerItemInfo = function() error("blocked by the game") end
        H:update(1); T.has(H:bar(), "Lixo 0"); tip(H)
        H.env.C_Container = nil; H.env.GetContainerNumSlots = nil
        H:update(1); T.has(H:bar(), "Lixo --", "no bag API at all")
    end },

    { "a strange bag count from the game never causes an endless loop", function(T, Mock)
        for _, value in ipairs({ math.huge, 1e300, -1, 0 / 0, "4", 99 }) do
            local H = setup(Mock)
            H.env.NUM_BAG_SLOTS = value; H:slash("show bolsas")
            H.bagFree = { [0] = 0, 0, 0, 0, 0 }
            H:update(1)
            T.has(H:bar(), "Lixo 3g 26s (3)", "falls back to the 5 normal bags for " .. tostring(value))
            T.has(H:bar(), "Bolsas 0/80")
        end
    end },
}
