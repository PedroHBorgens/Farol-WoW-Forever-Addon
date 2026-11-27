-- Menu de opções: abrir/fechar, caixinhas sincronizadas, idioma, horário do servidor.
-- Options menu: open/close, synced checkboxes, language, server time.

local ITEM_COUNT, GENERAL_COUNT = 31, 30 -- 31 itens + mostrar/travar (Barra) + 8 da aba Geral + 20 da aba Avisos

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
        local H = Mock.new():login({ hub = false })
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local window = H.env.FarolOptions
        T.ok(window and window:IsShown(), "window open")
        T.eq(H.env.UISpecialFrames[1], "FarolOptions", "Esc closes the window")
        H:slash("menu"); T.ok(not window:IsShown(), "toggled closed")
        H:slash("menu"); T.ok(window:IsShown(), "toggled open")
    end },

    { "both menus have every checkbox, with translated labels", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local panel, window = openMenu(H)
        T.eq(#H:framesOf("CheckButton"), 2 * (ITEM_COUNT + GENERAL_COUNT), "settings panel + window")
        T.eq(H:text(window[1].label), "FPS")
        T.eq(H:text(window[5].label), "Zona")
        T.eq(H:text(window[10].label), "Lixo nas bolsas")
        T.eq(H:text(window[11].label), "Munição e reagentes")
        T.eq(H:text(window[15].label), "Ouro por hora")
        T.eq(H:text(window[17].label), "XP por hora")
        T.eq(H:text(window[18].label), "Reputação")
        T.eq(H:text(window[19].label), "Profissões")
        T.eq(H:text(window[20].label), "Metas (ouro/nível)")
        T.eq(H:text(window[21].label), "Farm (metas de itens)")
        T.eq(H:text(window[22].label), "Missões (diário)")
        T.eq(H:text(window[23].label), "Missões concluídas")
        T.eq(H:text(window[26].label), "Tarefas (diárias/semanais)")
        T.eq(H:text(window[27].label), "Anotações (bloco de notas)")
        T.eq(H:text(window[29].label), "Masmorra / raide atual")
        T.eq(H:text(window[32].label), "Mostrar")
        T.eq(H:text(window[34].label), "Horário do servidor")
        T.eq(H:text(panel[33].label), "Travar")
    end },

    { "ticking a box updates the bar, the saved settings and the other menu", function(T, Mock)
        local H = Mock.new():login({ hub = false })
        local panel, window = openMenu(H)
        H:check(window[13], false) -- ouro
        T.eq(H.env.FarolDB.items.gold, false)
        T.hasnt(H:bar(), "123g")
        T.eq(panel[13]._checked, false, "settings panel synced")
        H:slash("show ouro")
        T.eq(window[13]._checked, true, "command syncs the checkbox")
    end },

    { "show panel, lock and server time options", function(T, Mock)
        local H = Mock.new():login({ hub = false })
        local _, window = openMenu(H)
        H:check(window[33], true); T.eq(H.env.FarolDB.locked, true)
        H:check(window[32], false)
        T.eq(H.env.FarolDB.shown, false); T.ok(not H.env.FarolFrame:IsShown(), "panel hidden")
        H:check(window[34], true); T.eq(H.env.FarolDB.serverTime, true)
        H:slash(""); T.ok(H.env.FarolFrame:IsShown(), "/farol shows it again")
        H:slash("show hora"); H:update(1)
        T.has(H:bar(), "21:05", "clock uses server time")
    end },

    { "language buttons switch the menu and highlight the choice", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
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
        local H = Mock.new():login({ hub = false })
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
        local H = Mock.new({ locale = "enUS" }):login({ hub = false })
        H.msgs = {}
        H:slash("help")
        local help = H.strip(table.concat(H.msgs, "\n"))
        for _, command in ipairs({ "/farol menu", "/farol lock", "/farol show", "/farol alarm", "/farol session reset",
                                   "/farol snooze", "/farol loot", "/farol version", "/farol lang" }) do
            T.has(help, command)
        end
    end },
}
