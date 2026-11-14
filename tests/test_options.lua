-- Menu de opções: abrir/fechar, caixinhas sincronizadas, idioma, horário do servidor.
-- Options menu: open/close, synced checkboxes, language, server time.

local ITEM_COUNT, GENERAL_COUNT = 21, 5 -- 21 itens + mostrar/travar/horário do servidor/resumo/ouro total

local function openMenu(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    local checks = H:framesOf("CheckButton")
    local perSet = ITEM_COUNT + GENERAL_COUNT
    -- Conjunto 1: painel das configurações do jogo (criado ao carregar). Conjunto 2: janela própria.
    local panel, window = {}, {}
    for i = 1, perSet do
        panel[i] = checks[i]
        window[i] = checks[perSet + i]
    end
    return panel, window
end

return {
    { "right-click opens the options window; /farol menu toggles it; Esc closes it", function(T, Mock)
        local H = Mock.new():login()
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local window = H.env.FarolOptions
        T.ok(window and window:IsShown(), "window open")
        T.eq(H.env.UISpecialFrames[1], "FarolOptions", "Esc closes the window")
        H:slash("menu"); T.ok(not window:IsShown(), "toggled closed")
        H:slash("menu"); T.ok(window:IsShown(), "toggled open")
    end },

    { "both menus have every checkbox, with translated labels", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        local panel, window = openMenu(H)
        T.eq(#H:framesOf("CheckButton"), 2 * (ITEM_COUNT + GENERAL_COUNT), "settings panel + window")
        T.eq(H:text(window[1].label), "FPS")
        T.eq(H:text(window[5].label), "Zona")
        T.eq(H:text(window[9].label), "Lixo nas bolsas")
        T.eq(H:text(window[12].label), "Ouro por hora")
        T.eq(H:text(window[14].label), "XP por hora")
        T.eq(H:text(window[15].label), "Reputação")
        T.eq(H:text(window[16].label), "Profissões")
        T.eq(H:text(window[22].label), "Mostrar painel")
        T.eq(H:text(window[24].label), "Horário do servidor")
        T.eq(H:text(panel[23].label), "Travar posição")
    end },

    { "ticking a box updates the bar, the saved settings and the other menu", function(T, Mock)
        local H = Mock.new():login()
        local panel, window = openMenu(H)
        H:check(window[10], false) -- ouro
        T.eq(H.env.FarolDB.items.gold, false)
        T.hasnt(H:bar(), "123g")
        T.eq(panel[10]._checked, false, "settings panel synced")
        H:slash("show ouro")
        T.eq(window[10]._checked, true, "command syncs the checkbox")
    end },

    { "show panel, lock and server time options", function(T, Mock)
        local H = Mock.new():login()
        local _, window = openMenu(H)
        H:check(window[23], true); T.eq(H.env.FarolDB.locked, true)
        H:check(window[22], false)
        T.eq(H.env.FarolDB.shown, false); T.ok(not H.env.FarolFrame:IsShown(), "panel hidden")
        H:check(window[24], true); T.eq(H.env.FarolDB.serverTime, true)
        H:slash(""); T.ok(H.env.FarolFrame:IsShown(), "/farol shows it again")
        H:slash("show hora"); H:update(1)
        T.has(H:bar(), "21:05", "clock uses server time")
    end },

    { "language buttons switch the menu and highlight the choice", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        local _, window = openMenu(H)
        local buttons = {}
        for _, frame in ipairs(H:framesOf("Button")) do
            if frame._template == "UIPanelButtonTemplate" and frame._text == "English" then
                table.insert(buttons, frame)
            end
        end
        H:click(buttons[#buttons])
        T.eq(H.env.FarolDB.lang, "en")
        T.eq(H:text(window[5].label), "Zone")
        T.eq(buttons[#buttons]._highlight, true, "chosen language highlighted")
    end },

    { "every chat/UI string escapes literal '|' (WoW treats '|' as an escape code)", function(T, Mock)
        local H = Mock.new():login()
        for lang, strings in pairs(H.ns.STRINGS) do
            for key, text in pairs(strings) do
                local rest = text
                rest = string.gsub(rest, "||", "")                  -- barra literal escapada
                rest = string.gsub(rest, "|c%x%x%x%x%x%x%x%x", "") -- cor
                rest = string.gsub(rest, "|r", "")                  -- fim da cor
                T.hasnt(rest, "|", lang .. "." .. key .. " has an unescaped '|'")
            end
        end
    end },

    { "help lists every command", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        H.msgs = {}
        H:slash("help")
        local help = H.strip(table.concat(H.msgs, "\n"))
        for _, command in ipairs({ "/farol menu", "/farol lock", "/farol show", "/farol alarm", "/farol session reset",
                                   "/farol snooze", "/farol loot", "/farol version", "/farol lang" }) do
            T.has(help, command)
        end
    end },
}
