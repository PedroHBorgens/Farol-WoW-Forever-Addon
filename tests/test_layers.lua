-- Camadas das janelas: o que abre a partir do menu fica NA FRENTE do menu.
-- Window layering: windows opened from the options menu appear in front of it.

local function openMenu(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    return H.env.FarolOptions
end

-- O mesmo botão existe no painel de configurações do jogo e na janela do menu;
-- o último criado é o da janela do menu.
local function buttonByText(H, text)
    local found
    for _, frame in ipairs(H:framesOf("Button")) do
        if frame._text == text then found = frame end -- o último criado é o da janela do menu
    end
    return found
end

return {
    { "every Farol window is top-level (clicking it brings it to the front)", function(T, Mock)
        local H = Mock.new():login()
        openMenu(H)
        H:slash("alarme"); H:slash("saque"); H:slash("aviso"); H:slash("aparencia"); H:slash("historico")
        for _, name in ipairs({ "FarolOptions", "FarolAlarms", "FarolLoot", "FarolWarnings",
                                "FarolAppearance", "FarolWarnHistory" }) do
            T.eq(H.env[name]._toplevel, true, name .. " is top-level")
        end
    end },

    { "windows opened from the menu appear in front of the menu", function(T, Mock)
        local H = Mock.new():login()
        local menu = openMenu(H)
        T.ok(menu._raisedAt, "menu raised when opened")
        for _, entry in ipairs({ { "Alarmes...", "FarolAlarms" }, { "Saques...", "FarolLoot" },
                                 { "Avisos...", "FarolWarnings" }, { "Aparência...", "FarolAppearance" } }) do
            H:click(buttonByText(H, entry[1]))
            local window = H.env[entry[2]]
            T.ok(window:IsShown(), entry[2] .. " open")
            T.ok(window._raisedAt > menu._raisedAt, entry[2] .. " is in front of the menu")
        end
    end },

    { "reopening the menu brings it back to the front; popups open on top", function(T, Mock)
        local H = Mock.new():login()
        local menu = openMenu(H)
        H:slash("alarme")
        H:slash("menu"); H:slash("menu") -- fecha e reabre o menu
        T.ok(menu._raisedAt > H.env.FarolAlarms._raisedAt, "reopened menu in front")
        H:slash("alarme add 07:30"); H:update(1); H.clock.hour, H.clock.min = 7, 30; H:update(1)
        T.ok(H.env.FarolAlarmPopup._raisedAt > menu._raisedAt, "alarm popup on top")
        T.eq(H.env.FarolAlarmPopup._toplevel, true)
        H:update(1) -- a durabilidade baixa do simulador abre a janelinha de aviso
        T.ok(H.env.FarolWarnPopup._raisedAt > menu._raisedAt, "warning popup on top")
    end },
}
