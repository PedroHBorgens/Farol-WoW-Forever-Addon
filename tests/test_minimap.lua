-- Botão no minimapa e lista de addons do jogo: cliques, arrastar, opções, comandos, dados adulterados.
-- Minimap button and the game's addon list: clicks, dragging, options, commands, tampered data.

local function setup(Mock, opts, saved)
    local H = Mock.new(opts)
    H.env.Minimap = H.env.CreateFrame("Frame", "Minimap") -- o minimapa do jogo
    H:login(saved)
    return H, H.env.FarolMinimapButton
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "without a minimap (other UI) there is simply no button, and no error", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.eq(H.env.FarolMinimapButton, nil)
        H:slash("minimapa off"); H:slash("minimapa on")
        T.eq(H.env.FarolMinimapButton, nil)
    end },

    { "shown by default at the default angle; the tooltip explains the clicks", function(T, Mock)
        local H, B = setup(Mock)
        T.ok(B and B:IsShown(), "button shown"); T.eq(B._anchor, H.env.Minimap)
        T.eq(H.env.FarolDB.minimap.show, true); T.eq(H.env.FarolDB.minimap.angle, 220)
        local r = 140 / 2 + 10
        T.ok(math.abs(B._x - math.cos(math.rad(220)) * r) < 0.01 and math.abs(B._y - math.sin(math.rad(220)) * r) < 0.01, "placed on the edge")
        H.env.GameTooltip.lines = {}; B._scripts.OnEnter(B)
        local tip = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(tip, "Clique: abrir o menu"); T.has(tip, "Clique direito: mostrar/esconder as barras"); T.has(tip, "Shift + clique: avisos")
        T.has(tip, "Arraste para mover")
    end },

    { "left-click opens the menu (Bar tab); Shift opens Warnings; right-click hides/shows every bar", function(T, Mock)
        local H, B = setup(Mock)
        H:slash("barra 2 mostrar"); H:slash("barra 1")
        B._scripts.OnClick(B, "LeftButton")
        T.ok(H.env.FarolOptions:IsShown()); T.ok(H.env.FarolOptions.controls.pages.bar:IsShown())
        B._scripts.OnClick(B, "LeftButton"); T.ok(not H.env.FarolOptions:IsShown(), "click again closes")
        H.shift = true; B._scripts.OnClick(B, "LeftButton"); H.shift = false
        T.ok(H.env.FarolOptions.controls.pages.warnings:IsShown(), "Shift: Warnings tab")
        B._scripts.OnClick(B, "RightButton")
        T.ok(not H.env.FarolFrame:IsShown() and not H.env.FarolBar2:IsShown(), "all bars hidden")
        T.has(H:lastMsg(), "barras escondidas")
        T.eq(H.env.FarolDB.shown, true, "the saved 'show' option is not changed")
        B._scripts.OnClick(B, "RightButton")
        T.ok(H.env.FarolFrame:IsShown() and H.env.FarolBar2:IsShown(), "shown again")
        B._scripts.OnClick(B, "RightButton"); H:slash("")
        T.ok(H.env.FarolFrame:IsShown(), "/farol also brings them back")
    end },

    { "dragging moves it around the minimap; locked does not move", function(T, Mock)
        local H, B = setup(Mock)
        local M = H.env.Minimap
        M.GetCenter = function() return 500, 400 end
        M.GetEffectiveScale = function() return 2 end
        H.env.GetCursorPosition = function() return 1000, 1000 end -- 500,500 na escala do minimapa: acima do centro
        B._scripts.OnDragStart(B); B._scripts.OnUpdate(B, 0.1); B._scripts.OnDragStop(B)
        T.ok(math.abs(H.env.FarolDB.minimap.angle - 90) < 0.01, "angle 90")
        T.eq(B._scripts.OnUpdate, nil, "stops following the cursor")
        H:slash("minimapa travar"); T.eq(H.env.FarolDB.minimap.locked, true)
        H.env.GetCursorPosition = function() return 2000, 800 end
        B._scripts.OnDragStart(B); T.eq(B._scripts.OnUpdate, nil, "locked: no dragging")
        T.ok(math.abs(H.env.FarolDB.minimap.angle - 90) < 0.01)
        H.env.GetCursorPosition = function() return 0 / 0, 1 / 0 end
        H:slash("minimapa destravar"); B._scripts.OnDragStart(B); B._scripts.OnUpdate(B, 0.1)
        T.ok(math.abs(H.env.FarolDB.minimap.angle - 90) < 0.01, "bad cursor values are ignored")
    end },

    { "General tab checkboxes and commands; invalid commands refused", function(T, Mock)
        local H, B = setup(Mock)
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local set = H.env.FarolOptions.controls
        T.eq(H:text(set.minimap.label), "Mostrar botão no minimapa"); T.eq(set.minimap._checked, true)
        H:check(set.minimap, false); T.ok(not B:IsShown()); T.eq(H.env.FarolDB.minimap.show, false)
        H:slash("minimapa on"); T.ok(B:IsShown()); T.eq(set.minimap._checked, true, "command syncs the checkbox")
        H:check(set.minimapLock, true); T.eq(H.env.FarolDB.minimap.locked, true)
        for _, cmd in ipairs({ "minimapa", "minimapa voar", "minimapa on agora" }) do
            H:slash(cmd); T.has(H:lastMsg(), "uso: /farol minimapa", cmd)
        end
    end },

    { "the game's addon list (compartment) does the same; English", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        T.eq(type(H.env.Farol_OnAddonCompartmentClick), "function")
        H.env.Farol_OnAddonCompartmentClick("Farol", "LeftButton")
        T.ok(H.env.FarolOptions:IsShown())
        H.env.GameTooltip.lines = {}; H.env.Farol_OnAddonCompartmentEnter("Farol", H.env.FarolFrame)
        T.has(H.strip(table.concat(H.env.GameTooltip.lines, " / ")), "Right-click: show/hide the bars")
        H.env.Farol_OnAddonCompartmentLeave("Farol")
        H.env.Farol_OnAddonCompartmentClick("Farol", "RightButton"); T.has(H:lastMsg(), "bars hidden")
        H:slash("help"); T.has(all(H), "/farol minimap")
    end },

    { "tampered saved settings fall back safely; settings survive reload", function(T, Mock)
        for _, bad in ipairs({ "x", { angle = 0 / 0, show = "no", locked = 1 }, { angle = 400 }, { angle = -1 }, { angle = 1 / 0 } }) do
            local H = setup(Mock, nil, { minimap = bad })
            local m = H.env.FarolDB.minimap
            T.eq(m.angle, 220); T.eq(m.show, true); T.eq(m.locked, false)
        end
        local H = setup(Mock, nil, { minimap = { angle = 45.5, show = false, locked = true } })
        T.eq(H.env.FarolDB.minimap.angle, 45.5); T.ok(not H.env.FarolMinimapButton, "hidden: not even created")
    end },
}
