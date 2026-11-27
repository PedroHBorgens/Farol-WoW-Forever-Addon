-- Janela de avisos (3.21): o texto quebra em até 3 linhas (nada de "…"), passar o mouse mostra o aviso inteiro e a
-- alça ◢ muda a largura (salva, validada; clique direito ou "Posição padrão" volta ao padrão).
-- Warnings window: wrapped text, full-text tooltip, resizable width.

local function NoHub(saved) saved = saved or {}; if saved.hub == nil then saved.hub = false end; return saved end -- estilo simples (a Central tem teste próprio)
local function setup(Mock, warnings, opts)
    local H = Mock.new(opts or { locale = "ptBR" }):login(NoHub({ warnings = warnings }))
    H.durability = { [1] = { 100, 100 } }; H:event("UPDATE_INVENTORY_DURABILITY"); H:update(1)
    return H
end
local function minutes(H, n) for _ = 1, n do H:update(60) end end
local function tip(H) return H.strip(table.concat(H.env.GameTooltip.lines, " / ")) end

return {
    { "long warnings wrap: taller lines and a taller window instead of a cut '…'", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 15, water = true, waterMin = 15 })
        minutes(H, 15)
        local popup, row1 = H.env.FarolWarnPopup, H.env.FarolWarnRow1Line
        T.ok(popup:IsShown()); T.eq(popup:GetWidth(), 640)
        local shortH, shortRow = popup:GetHeight(), row1:GetHeight()
        -- O mesmo aviso com texto longo: a linha e a janela crescem (até 3 linhas).
        row1.text._stringHeight = 39
        H.ns.Warnings.SetPopupWidth(0) -- redesenha a janela
        T.ok(row1:GetHeight() > shortRow, "line grows with the text")
        T.ok(popup:GetHeight() > shortH, "window grows with the lines")
        row1.text._stringHeight = 400
        H.ns.Warnings.SetPopupWidth(0)
        T.ok(row1:GetHeight() <= 3 * 13 + 2 + 8, "at most 3 lines")
        T.eq(H:text(row1.text), row1.entry.text, "the whole text is set, never shortened")
    end },

    { "hovering a warning shows the whole text, what it is about and where to adjust it", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 15, water = true, waterMin = 15 })
        minutes(H, 15)
        local row = H.env.FarolWarnRow1Line
        H.env.GameTooltip.lines = {}; row._scripts.OnEnter(row)
        T.has(tip(H), "Aviso do Farol / " .. row.entry.text)
        T.has(tip(H), "Desligar ou ajustar: Menu > Avisos.")
        row._scripts.OnLeave(row); T.ok(not H.env.GameTooltip:IsShown())
        -- Um aviso só: o mouse na janela mostra o texto inteiro.
        H:click(H.env.FarolWarnRow1Silence)
        local popup = H.env.FarolWarnPopup
        H.env.GameTooltip.lines = {}; popup._scripts.OnEnter(popup)
        T.has(tip(H), H:text(popup.text))
    end },

    { "the grip changes the width (saved, validated); right-click and 'Reset position' go back to the default", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 15, water = true, waterMin = 15 })
        minutes(H, 15)
        local popup, grip = H.env.FarolWarnPopup, H.env.FarolWarnPopupGrip
        H.env.GameTooltip.lines = {}; grip._scripts.OnEnter(grip)
        T.has(tip(H), "Arraste para mudar a largura da janela (fica salva). / Clique direito: largura padrão.")
        grip._scripts.OnMouseDown(grip, "LeftButton"); popup:SetWidth(900); grip._scripts.OnMouseUp(grip, "LeftButton")
        T.eq(H.env.FarolDB.warnings.popupW, 900); T.eq(popup:GetWidth(), 900)
        T.eq(H.env.FarolWarnRow1Line:GetWidth(), 860, "lines follow the width")
        grip._scripts.OnMouseDown(grip, "LeftButton"); popup:SetWidth(5000); grip._scripts.OnMouseUp(grip, "LeftButton")
        T.eq(H.env.FarolDB.warnings.popupW, 1400, "at most 1400")
        grip._scripts.OnMouseDown(grip, "LeftButton"); popup:SetWidth(100); grip._scripts.OnMouseUp(grip, "LeftButton")
        T.eq(H.env.FarolDB.warnings.popupW, 0, "too narrow -> default"); T.eq(popup:GetWidth(), 640)
        grip._scripts.OnMouseUp(grip, "LeftButton"); T.eq(H.env.FarolDB.warnings.popupW, 0, "mouse up without a drag does nothing")
        H.ns.Warnings.SetPopupWidth(800); grip._scripts.OnMouseUp(grip, "RightButton")
        T.eq(H.env.FarolDB.warnings.popupW, 0, "right-click: default")
        H.ns.Warnings.SetPopupWidth(800); H:slash("reset"); T.eq(H.env.FarolDB.warnings.popupW, 0, "reset position also resets it")
        -- Um aviso só acompanha a largura escolhida (240 a menos), nunca menor que 400.
        H.ns.Warnings.SetPopupWidth(1000); H:click(H.env.FarolWarnRow1Silence)
        T.eq(popup:GetWidth(), 760)
        H.ns.Warnings.SetPopupWidth(0); T.eq(popup:GetWidth(), 400)
        -- A largura escolhida continua depois de recarregar.
        H.ns.Warnings.SetPopupWidth(700)
        local B = Mock.new(); B:login(H.env.FarolDB); T.eq(B.env.FarolDB.warnings.popupW, 700)
    end },

    { "saved width is validated; English texts; old client", function(T, Mock)
        for _, bad in ipairs({ -5, 300, 1e9, 0 / 0, 1 / 0, "900", true, 700.5 }) do
            T.eq(Mock.new():login(NoHub({ warnings = { popupW = bad } })).env.FarolDB.warnings.popupW, 0, "bad width -> default")
        end
        T.eq(Mock.new():login(NoHub({ warnings = { popupW = 520 } })).env.FarolDB.warnings.popupW, 520)
        local E = setup(Mock, { pause = true, pauseMin = 15, water = true, waterMin = 15 }, { locale = "enUS" })
        minutes(E, 15)
        local row = E.env.FarolWarnRow1Line
        E.env.GameTooltip.lines = {}; row._scripts.OnEnter(row)
        T.has(tip(E), "Farol warning / "); T.has(tip(E), "Turn off or adjust: Menu > Warnings.")
        local W = setup(Mock, { pause = true, pauseMin = 15 }, { mode = "wotlk" }); minutes(W, 15)
        T.ok(W.env.FarolWarnPopup:IsShown())
    end },
}
