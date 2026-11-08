-- Aparência: escala, fundo, borda, barra vertical, esconder em combate e em instâncias.
-- Appearance: scale, background, border, vertical bar, hide in combat and in instances.

local function bar(H) return H.env.FarolFrame end

return {
    { "defaults are applied and invalid saved values are fixed", function(T, Mock)
        local H = Mock.new():login({ scale = 9, bgAlpha = -1, vertical = "x", hideCombat = true })
        local db = H.env.FarolDB
        T.eq(db.scale, 1); T.eq(db.bgAlpha, 0.7); T.eq(db.vertical, false); T.eq(db.hideCombat, true)
        T.eq(bar(H)._scale, 1); T.eq(bar(H)._bgAlpha, 0.7); T.eq(bar(H)._borderAlpha, 1)
    end },

    { "scale and background by command, with limits", function(T, Mock)
        local H = Mock.new():login()
        H:slash("aparencia escala 150"); T.eq(H.env.FarolDB.scale, 1.5); T.eq(bar(H)._scale, 1.5)
        H:slash("aparencia escala 300"); T.has(H:lastMsg(), "escala inválida"); T.eq(H.env.FarolDB.scale, 1.5)
        H:slash("aparencia fundo 0"); T.eq(bar(H)._bgAlpha, 0)
        H:slash("aparencia fundo 101"); T.has(H:lastMsg(), "fundo inválido")
        H:slash("aparencia borda"); T.eq(bar(H)._borderAlpha, 0, "border hidden")
        H:slash("aparencia xyz"); T.has(H:lastMsg(), "uso: /farol aparencia escala N | fundo N")
    end },

    { "vertical bar: one item per line, left aligned, taller", function(T, Mock)
        local H = Mock.new():login()
        T.eq(bar(H)._h, 26)
        H:slash("aparencia vertical")
        local text = H.env.FarolFrame._fontStrings[1]
        T.has(text._text, "\n"); T.eq(text._justify, "LEFT")
        local lines = 0
        for _ in string.gmatch(text._text, "[^\n]+") do lines = lines + 1 end
        T.eq(lines, 6, "six default items")
        T.eq(bar(H)._h, 6 * 14 + 14)
        H:slash("aparencia vertical")
        T.hasnt(H.env.FarolFrame._fontStrings[1]._text, "\n"); T.eq(bar(H)._h, 26)
    end },

    { "hide in combat: hides on entering combat and comes back after", function(T, Mock)
        local H = Mock.new():login()
        H:event("PLAYER_REGEN_DISABLED"); T.ok(bar(H):IsShown(), "option off: stays visible")
        H:event("PLAYER_REGEN_ENABLED")
        H:slash("aparencia combate")
        H:event("PLAYER_REGEN_DISABLED"); T.ok(not bar(H):IsShown(), "hidden in combat")
        H:event("PLAYER_REGEN_ENABLED"); T.ok(bar(H):IsShown(), "back after combat")
        H:slash("") -- jogador escondeu o painel
        H:event("PLAYER_REGEN_DISABLED"); H:event("PLAYER_REGEN_ENABLED")
        T.ok(not bar(H):IsShown(), "stays hidden when the player hid it")
    end },

    { "hide in instances, and in combat at login (reload mid-fight)", function(T, Mock)
        local H = Mock.new():login({ hideInstance = true })
        T.ok(bar(H):IsShown(), "open world")
        H.instanceType = "party"; H:event("ZONE_CHANGED_NEW_AREA")
        T.ok(not bar(H):IsShown(), "hidden in a dungeon")
        H.instanceType = nil; H:event("PLAYER_ENTERING_WORLD")
        T.ok(bar(H):IsShown(), "back outside")
        local H2 = Mock.new()
        H2.inCombat = true
        H2:login({ hideCombat = true })
        T.ok(not bar(H2):IsShown(), "hidden when logging in during combat")
    end },

    { "alarms and warnings keep working while the bar is hidden in combat", function(T, Mock)
        local H = Mock.new():login({ hideCombat = true })
        H:slash("alarme add 07:30")
        H:event("PLAYER_REGEN_DISABLED")
        H:update(1); H.clock.hour, H.clock.min = 7, 30; H:update(1)
        T.eq(H.sounds, 1)
    end },

    { "appearance window: steppers, checkboxes and restore defaults", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local button
        for _, frame in ipairs(H:framesOf("Button")) do
            if frame._text == "Appearance..." then button = frame end
        end
        T.ok(button, "Appearance... button in the options menu")
        H:click(button)
        local window = H.env.FarolAppearance
        T.ok(window:IsShown())
        T.eq(H:text(window.scale.value), "100%")
        for _ = 1, 15 do H:click(H.env.FarolAppScaleUp) end
        T.eq(H.env.FarolDB.scale, 2, "stops at 200%"); T.eq(H:text(window.scale.value), "200%")
        H:click(H.env.FarolAppBgDown); T.eq(H:text(window.bg.value), "60%")
        H:check(H.env.FarolApp_vertical, true); T.eq(H.env.FarolDB.vertical, true)
        H:check(H.env.FarolApp_hideCombat, true); T.eq(H.env.FarolDB.hideCombat, true)
        T.eq(H:text(H.env.FarolApp_hideInstance.label), "Hide in dungeons, raids, arenas and battlegrounds")
        H:click(H.env.FarolAppReset)
        local db = H.env.FarolDB
        T.eq(db.scale, 1); T.eq(db.bgAlpha, 0.7); T.eq(db.vertical, false); T.eq(db.hideCombat, false)
        T.eq(H.env.FarolApp_vertical._checked, false, "window refreshed")
    end },
}
