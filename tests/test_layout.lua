-- Barra maleável: colunas alinhadas à esquerda, largura escolhida arrastando a alça,
-- atalhos "uma linha" / "uma coluna", altura automática.
-- Flexible bar: left-aligned columns, width chosen by dragging, one line / one column presets.
--
-- No simulador cada informação mede 150 px; margens 10 + 10 e 14 px entre colunas.
-- Assim, c colunas ocupam 20 + 150*c + 14*(c-1) px: 1 = 170, 2 = 334, 3 = 498, 6 = 990.

local SHOW_ALL = { "mem", "speed", "bags", "session", "goldh", "xp", "xph", "clock", "playtime", "friends" }

local function bar(H) return H.env.FarolFrame end

-- Linhas e colunas pelas posições das células.
local function grid(H)
    local xs, ys = {}, {}
    for _, cell in ipairs(H:cells()) do xs[cell._x] = true; ys[cell._y] = true end
    local cols, rows = 0, 0
    for _ in pairs(xs) do cols = cols + 1 end
    for _ in pairs(ys) do rows = rows + 1 end
    return cols, rows
end

local function drag(H, width)
    local grip = H.env.FarolBarResize
    grip._scripts.OnMouseDown(grip)
    bar(H)._w = width
    bar(H)._scripts.OnSizeChanged(bar(H))
    grip._scripts.OnMouseUp(grip)
end

return {
    { "default: everything on one line, cells left aligned, height 26", function(T, Mock)
        local H = Mock.new():login()
        local cols, rows = grid(H)
        T.eq(rows, 1); T.eq(cols, 6, "six default items side by side")
        T.eq(bar(H)._w, 990); T.eq(bar(H)._h, 26)
        for _, cell in ipairs(H:cells()) do
            T.eq(cell._justify, "LEFT"); T.eq(cell._anchorPoint, "TOPLEFT")
        end
    end },

    { "dragging the grip sets the width; columns stay aligned and height follows", function(T, Mock)
        local H = Mock.new():login()
        for _, key in ipairs(SHOW_ALL) do H:slash("show " .. key) end
        drag(H, 500)
        T.eq(H.env.FarolDB.barWidth, 500, "width saved")
        local cols, rows = grid(H)
        T.eq(cols, 3, "3 columns fit in 500 px"); T.eq(rows, 6, "16 items in 3 columns")
        T.eq(bar(H)._w, 498, "frame shrinks to the content")
        T.eq(bar(H)._h, 4 * 2 + 6 * 17, "height = rows x line height + margins")
        local cells = H:cells()
        T.eq(cells[1]._x, cells[4]._x, "same column, same x (aligned)")
        T.eq(cells[1]._y, cells[2]._y, "same row, same y")
        drag(H, 170)
        cols = grid(H); T.eq(cols, 1, "narrow: one column")
        drag(H, 3000)
        cols, rows = grid(H); T.eq(rows, 1, "wide: one line again")
    end },

    { "the bar reorganizes live while dragging", function(T, Mock)
        local H = Mock.new():login()
        local grip = H.env.FarolBarResize
        grip._scripts.OnMouseDown(grip)
        bar(H)._w = 334
        bar(H)._scripts.OnSizeChanged(bar(H))
        local cols, rows = grid(H)
        T.eq(cols, 2); T.eq(rows, 3, "6 items in 2 columns while dragging")
        T.eq(bar(H)._w, 334, "width not overridden while dragging")
        grip._scripts.OnMouseUp(grip)
    end },

    { "one line / one column presets (window and commands)", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H:slash("appearance column")
        local cols, rows = grid(H)
        T.eq(cols, 1); T.eq(rows, 6); T.eq(H.env.FarolDB.barWidth, 1)
        T.has(H:lastMsg(), "layout: one column")
        H:slash("appearance row")
        cols, rows = grid(H); T.eq(rows, 1); T.eq(H.env.FarolDB.barWidth, 0)
        H:slash("appearance width 400")
        cols = grid(H); T.eq(cols, 2, "400 px fits 2 columns")
        H:slash("appearance width 10"); T.has(H:lastMsg(), "invalid width")
        H:slash("appearance")
        H:click(H.env.FarolAppOneColumn); T.eq(H.env.FarolDB.barWidth, 1)
        H:click(H.env.FarolAppOneLine); T.eq(H.env.FarolDB.barWidth, 0)
        T.has(H:text(H.env.FarolAppearance.layoutHint), "drag the grip")
    end },

    { "old 'vertical bar' setting becomes one column; invalid widths are fixed", function(T, Mock)
        local H = Mock.new():login({ vertical = true })
        T.eq(H.env.FarolDB.barWidth, 1, "vertical users keep a single column")
        T.eq(grid(H), 1)
        local H2 = Mock.new():login({ barWidth = -5 })
        T.eq(H2.env.FarolDB.barWidth, 0)
        local H3 = Mock.new():login({ barWidth = 500.7 })
        T.eq(H3.env.FarolDB.barWidth, 500)
    end },

    { "locking the bar hides the grip; quick buttons follow the number of rows", function(T, Mock)
        local H = Mock.new():login()
        local grip = H.env.FarolBarResize
        T.ok(grip:IsShown(), "grip visible when unlocked")
        H:slash("lock"); T.ok(not grip:IsShown(), "hidden when locked")
        grip._scripts.OnMouseDown(grip); T.eq(H.env.FarolDB.barWidth, 0, "locked: no resizing")
        H:slash("lock"); T.ok(grip:IsShown())
        T.eq(H.env.FarolWarnHistoryButton._anchorPoint, "LEFT", "one line: buttons at the side")
        H:slash("aparencia coluna")
        T.eq(H.env.FarolWarnHistoryButton._anchorPoint, "TOPLEFT", "several rows: buttons at the top corner")
        T.eq(H.env.FarolLootButton._anchor, H.env.FarolWarnHistoryButton)
    end },

    { "line height uses the real text height measured by the game", function(T, Mock)
        local H = Mock.new():login()
        H.env.FarolFrame._fontStrings[2]._stringHeight = 12 -- texto de medida: altura real de uma linha
        H:slash("aparencia icones")                         -- sem ícones: vale a altura do texto
        H:slash("aparencia coluna")
        T.eq(bar(H)._h, 4 * 2 + 6 * (12 + 3), "6 rows of 15 px")
    end },

    { "the order chosen by the player fills the grid row by row", function(T, Mock)
        local H = Mock.new():login({ order = { "gold", "zone" } })
        H:slash("aparencia largura 500")
        local cells = H:cells()
        T.has(H.strip(cells[1]._text), "123g"); T.has(H.strip(cells[2]._text), "Floresta")
        T.eq(cells[1]._y, cells[3]._y, "first three items on the first row")
        T.ok(cells[4]._y < cells[1]._y, "fourth item starts the second row")
    end },
}
