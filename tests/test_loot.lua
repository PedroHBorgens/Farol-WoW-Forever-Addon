-- Janela de saques: registro só do próprio jogador, validação, menus suspensos, rolagem, tamanho.
-- Loot window: own loot only, validation, dropdowns, scrolling, resizing.

local COLORS = { [0] = "9d9d9d", "ffffff", "1eff00", "0070dd", "a335ee", "ff8000" }

local function loot(H, message) H:event("CHAT_MSG_LOOT", message) end

local function visibleRows(H)
    local rows = {}
    for _, row in ipairs(H.env.FarolLoot.rows) do
        if row:IsShown() then table.insert(rows, H:text(row.text)) end
    end
    return rows
end

local function lootMany(H, n)
    for i = 1, n do
        loot(H, "Você recebe saque: |cff" .. COLORS[i % 6] .. "|Hitem:" .. (7000 + i) .. "|h[Item " .. i .. "]|h|r.")
    end
end

return {
    { "records only your own loot, with quantity and quality", function(T, Mock)
        local H = Mock.new():login()
        loot(H, "Você recebe saque: |cffff8000|Hitem:19019::::::::60:::::|h[Thunderfury]|h|r.")
        loot(H, "Você recebe saque: |cnIQ1:|Hitem:2589::::|h[Tecido de Linho]|h|rx12.")
        loot(H, "Fulano recebe saque: |cffa335ee|Hitem:999|h[Do outro]|h|r.")
        loot(H, "Você recebe o item: |cff9d9d9d|Hitem:3300|h[Pata de Coelho]|h|r.")
        loot(H, "Você recebe saque: |cff0070dd|Hitem:4|h[Lâmina |A:Professions-ChatIcon-Quality-Tier3:17:17::1|a]|h|r.")
        local items = H.env.FarolCharDB.items
        T.eq(#items, 4, "other players' loot ignored")
        T.eq(items[1].q, 5); T.eq(items[2].count, 12); T.eq(items[2].q, 1)
        T.eq(items[3].q, 0); T.eq(items[4].q, 3, "profession quality icon accepted")
    end },

    { "malicious links and tampered history are rejected", function(T, Mock)
        local H = Mock.new():login(nil, { items = {
            { link = "|cff1eff00|Hitem:2447::::|h[Peacebloom]|h|r", count = 3, q = 2, t = 100 },
            { link = "|cff1eff00|Hitem:1|h[Evil|Hurl:x|h]|h|r", count = 1, t = 1 },
            { link = "nao e link", count = 1 },
            { link = "|cff0070dd|Hitem:2|h[Ok]|h|r", count = -5, q = 99, t = 2 },
        } })
        local items = H.env.FarolCharDB.items
        T.eq(#items, 2, "bad entries dropped")
        T.eq(items[2].count, 1, "bad count fixed"); T.eq(items[2].q, nil, "bad quality cleared")
        loot(H, "Você recebe saque: |cff9d9d9d|Hitem:3|h[Mau|Hurl:http://x|h]|h|r.")
        T.eq(#items, 2, "link with hidden URL rejected")
    end },

    { "history keeps the last 100 items and can be cleared", function(T, Mock)
        local H = Mock.new():login()
        lootMany(H, 120)
        T.eq(#H.env.FarolCharDB.items, 100)
        H:slash("saque limpar"); T.eq(#H.env.FarolCharDB.items, 0)
    end },

    { "count dropdown: 5/10/15/20, closes after picking", function(T, Mock)
        local H = Mock.new():login()
        lootMany(H, 24)
        H:slash("saque")
        T.eq(#visibleRows(H), 10, "default 10")
        T.eq(visibleRows(H)[1], "[Item 24]", "newest first")
        H:click(H.env.FarolLootCount)
        T.ok(H.env.FarolLootCountList:IsShown(), "list open")
        T.eq(H:text(H.env.FarolLootCountEntry1.text), "5")
        H:click(H.env.FarolLootCountEntry1)
        T.eq(H.env.FarolDB.loot.count, 5)
        T.ok(not H.env.FarolLootCountList:IsShown(), "single select closes the list")
        T.eq(#visibleRows(H), 5)
        T.eq(H.env.FarolLootCount._text, "5")
    end },

    { "quality dropdown: multi-select, check/uncheck all, summary text", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        lootMany(H, 24)
        H:slash("loot")
        H:click(H.env.FarolLootQuality)
        T.eq(H:text(H.env.FarolLootQualityEntry6.text), "Legendary+")
        H:click(H.env.FarolLootQualityEntry8) -- uncheck all
        T.ok(H.env.FarolLootQualityList:IsShown(), "multi-select stays open")
        T.eq(H.env.FarolLootQuality._text, "None")
        T.eq(#visibleRows(H), 0)
        T.eq(H:text(H.env.FarolLoot.empty), "No items match this filter.")
        H:click(H.env.FarolLootQualityEntry5); H:click(H.env.FarolLootQualityEntry6)
        T.eq(H.env.FarolLootQuality._text, "Épico, Legendary+")
        for _, row in ipairs(visibleRows(H)) do
            local n = tonumber(string.match(row, "Item (%d+)"))
            T.ok(n % 6 == 4 or n % 6 == 5, "only epic/legendary shown: " .. row)
        end
        H:click(H.env.FarolLootQualityEntry3); T.eq(H.env.FarolLootQuality._text, "3 selected")
        H:click(H.env.FarolLootQualityEntry7); T.eq(H.env.FarolLootQuality._text, "All")
        H.env.FarolLoot:Hide()
        T.ok(not H.env.FarolLootQualityList:IsShown(), "closing the window closes the list")
    end },

    { "resizable window: rows fit the height, mouse wheel scrolls, size saved", function(T, Mock)
        local H = Mock.new():login({ loot = { count = 20, w = 5000, h = "x" } })
        T.eq(H.env.FarolDB.loot.w, 420, "invalid width -> default")
        lootMany(H, 24)
        H:slash("saque")
        local window = H.env.FarolLoot
        T.eq(#visibleRows(H), 10, "380 px tall fits 10 rows")
        T.eq(H:text(window.scrollInfo), "1–10 de 20")
        window._scripts.OnMouseWheel(window, -1); window._scripts.OnMouseWheel(window, -1)
        T.eq(H:text(window.scrollInfo), "3–12 de 20")
        for _ = 1, 50 do window._scripts.OnMouseWheel(window, -1) end
        T.eq(H:text(window.scrollInfo), "11–20 de 20", "scroll stops at the end")
        window:SetSize(500, 84 + 62 + 20 * 22 + 10)
        window._scripts.OnSizeChanged(window)
        T.eq(#visibleRows(H), 20, "taller window shows all")
        H.env.FarolLootResize._scripts.OnMouseUp(H.env.FarolLootResize)
        T.eq(H.env.FarolDB.loot.w, 500, "width saved")
    end },

    { "hovering shows the item tooltip; shift-click inserts the link", function(T, Mock)
        local H = Mock.new():login()
        lootMany(H, 3)
        H:slash("saque")
        local row = H.env.FarolLoot.rows[1]
        row._scripts.OnEnter(row)
        T.eq(H.env.GameTooltip.link, row.link)
        H:click(row)
        T.eq(H.clickedLink, row.link)
    end },

    { "each row shows the day (Today / Yesterday / date) before the time, in both languages", function(T, Mock)
        local now = os.time()
        local sinceMidnight = tonumber(os.date("%H", now)) * 3600 + tonumber(os.date("%M", now)) * 60
            + tonumber(os.date("%S", now))
        local yesterday = now - sinceMidnight - 4 * 3600        -- 20:xx de ontem
        local older = now - sinceMidnight - 5 * 86400 + 3600     -- 01:xx de 5 dias atrás
        local lastYear = now - 400 * 86400
        local function hm(t) return os.date("%H:%M", t) end
        local link = "|cff1eff00|Hitem:2447::::|h[Peacebloom]|h|r"
        local saved = { items = {
            { link = link, count = 1, q = 2, t = lastYear },
            { link = link, count = 1, q = 2, t = older },
            { link = link, count = 6, q = 2, t = yesterday },
            { link = link, count = 1, q = 2, t = now },
            { link = link, count = 1, q = 2, t = -5 },             -- adulterado: vira "--"
        } }
        local expected = {
            pt = { "--", "Hoje " .. hm(now), "x6   Ontem " .. hm(yesterday),
                   nil, os.date("%d/%m/%y ", lastYear) .. hm(lastYear) },
            en = { "--", "Today " .. hm(now), "x6   Yesterday " .. hm(yesterday) },
        }
        local months = { "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec" }
        local function mon(t) return months[tonumber(os.date("%m", t))] .. " " .. tonumber(os.date("%d", t)) end
        local sameYear = os.date("%Y", older) == os.date("%Y", now) -- no começo de janeiro, 5 dias atrás é outro ano
        expected.pt[4] = os.date(sameYear and "%d/%m " or "%d/%m/%y ", older) .. hm(older)
        expected.en[4] = mon(older) .. (sameYear and "" or (" '" .. os.date("%y", older))) .. " " .. hm(older)
        expected.en[5] = mon(lastYear) .. " '" .. os.date("%y", lastYear) .. " " .. hm(lastYear)
        for lang, list in pairs(expected) do
            local H = Mock.new({ locale = lang == "pt" and "ptBR" or "enUS" }):login(nil, { items = saved.items })
            H:slash("saque")
            for i, text in ipairs(list) do
                T.eq(H.strip(H:text(H.env.FarolLoot.rows[i].info)), text, lang .. " row " .. i)
            end
            local raw = H.env.FarolLoot.rows[2].info._text
            T.has(raw, "|cff8c8c8c", "the day is dimmed so the item stands out")
        end
    end },

    { "hovering a row adds the full date to the item tooltip", function(T, Mock)
        local t = os.time({ year = 2026, month = 11, day = 8, hour = 21, min = 12 })
        local saved = { items = { { link = "|cff1eff00|Hitem:2447::::|h[Peacebloom]|h|r", count = 1, q = 2, t = t } } }
        local H = Mock.new():login(nil, saved)
        H:slash("saque")
        local row = H.env.FarolLoot.rows[1]
        H.env.GameTooltip.lines = {}
        row._scripts.OnEnter(row)
        T.eq(H.env.GameTooltip.lines[#H.env.GameTooltip.lines], "Saqueado: domingo, 08/11/2026 às 21:12")
        local E = Mock.new({ locale = "enUS" }):login(nil, saved)
        E:slash("loot")
        local erow = E.env.FarolLoot.rows[1]
        E.env.GameTooltip.lines = {}
        erow._scripts.OnEnter(erow)
        T.eq(E.env.GameTooltip.lines[#E.env.GameTooltip.lines], "Looted: Sunday, Nov 8, 2026 at 21:12")
    end },

    { "an invalid saved date never adds a tooltip line or breaks the window", function(T, Mock)
        for _, bad in ipairs({ 0, -1, 0 / 0, math.huge, "ontem", {} }) do
            local saved = { items = { { link = "|cff1eff00|Hitem:2447::::|h[Peacebloom]|h|r", count = 1, q = 2, t = bad } } }
            local H = Mock.new():login(nil, saved)
            H:slash("saque")
            local row = H.env.FarolLoot.rows[1]
            T.eq(H.strip(H:text(row.info)), "--", "bad date " .. tostring(bad))
            H.env.GameTooltip.lines = {}
            row._scripts.OnEnter(row)
            T.eq(#H.env.GameTooltip.lines, 0, "no date line for " .. tostring(bad))
        end
        local H = Mock.new():login()
        T.eq(H.ns.FormatWhen(nil), "--"); T.eq(H.ns.FormatWhen(5e12), "--"); T.eq(H.ns.FormatWhen("x", true), "--")
        T.eq(H.ns.FormatWhen(0.5), "--", "fraction of the first second")
        T.eq(H.ns.FormatWhen(1e9 + 0.7, true), H.ns.FormatWhen(1e9, true), "fractions are rounded down, never an error")
        T.eq(H.ns.FormatWhen(4102444799.9), H.ns.FormatWhen(4102444799), "last valid second")
    end },
}
