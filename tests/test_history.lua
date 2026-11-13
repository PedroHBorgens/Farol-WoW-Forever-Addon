-- Ícones da barra, histórico dos 10 últimos avisos, botão com contador e atalho de teclado.
-- Bar icons, last-10 warning history, counter button and key binding.

local function fixGear(H)
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function rows(H)
    local list = {}
    for _, row in ipairs(H.env.FarolWarnHistory.rows) do
        if row:IsShown() then table.insert(list, H:text(row)) end
    end
    return list
end

return {
    { "every bar item gets its own icon; the option turns them off", function(T, Mock)
        local H = Mock.new():login()
        local raw = H:barRaw()
        T.has(raw, "INV_Misc_Spyglass_03", "fps icon"); T.has(raw, "Trade_BlackSmithing", "durability icon")
        T.has(raw, "INV_Misc_Coin_01", "gold icon")
        for key, icon in pairs(H.ns.ITEM_ICONS) do
            T.ok(type(icon) == "string" and icon ~= "", "icon for " .. key)
        end
        local count = 0
        for _ in pairs(H.ns.ITEM_ICONS) do count = count + 1 end
        T.eq(count, 20, "one icon per item")
        H:slash("aparencia icones")
        T.hasnt(H:barRaw(), "|T", "icons off")
        T.has(H:bar(), "60 fps", "values still shown")
    end },

    { "warnings are recorded (newest first), up to 10, and survive a reload", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        for i = 1, 12 do
            H.talentPoints = i; H:update(1)
            H:slash("aviso silenciar")
        end
        H:slash("historico")
        local list = rows(H)
        T.eq(#list, 10, "only the last 10")
        T.has(list[1], "Você tem 12 ponto(s)"); T.has(list[10], "Você tem 3 ponto(s)")
        T.ok(string.match(list[1], "^%d%d/%d%d %d%d:%d%d  "), "date and time shown")
        local saved = H.env.FarolCharDB
        local H2 = Mock.new():login(nil, { warnHistory = saved.warnHistory })
        T.eq(#H2.env.FarolCharDB.warnHistory, 10, "kept after reload")
    end },

    { "the test warning is not recorded; tampered history is cleaned", function(T, Mock)
        local H = Mock.new():login(nil, { warnHistory = {
            { t = 1, text = "ok" }, { t = "x", text = "bad" }, { t = 2, text = "Link |Hurl:x|h aqui\n" },
        } }); fixGear(H)
        local history = H.env.FarolCharDB.warnHistory
        T.eq(#history, 2); T.eq(history[2].text, "Link Hurl:xh aqui")
        H:slash("aviso"); H:click(H.env.FarolWarnTest)
        T.eq(#history, 2, "test warning not recorded")
    end },

    { "button next to the bar counts unread warnings and opens the history", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        local button = H.env.FarolWarnHistoryButton
        T.ok(button and button:IsShown(), "button shown")
        T.eq(H:text(button.badge), "")
        H.talentPoints = 1; H:update(1); H.talentPoints = 2; H:update(1)
        T.eq(H:text(button.badge), "2", "two unread")
        button._scripts.OnEnter(button)
        T.has(table.concat(H.env.GameTooltip.lines, " "), "2 novo(s)")
        H:click(button)
        T.ok(H.env.FarolWarnHistory:IsShown()); T.eq(H:text(button.badge), "", "read")
        H.talentPoints = 3; H:update(1)
        T.eq(H:text(button.badge), "", "window open: counts as read")
        T.has(rows(H)[1], "Você tem 3 ponto(s)", "window updates live")
        H:click(H.env.FarolWarnHistoryClear); T.eq(#rows(H), 0)
        T.eq(H:text(H.env.FarolWarnHistory.empty), "Nenhum aviso ainda.")
        H:slash("aparencia botao"); T.ok(not button:IsShown(), "button can be hidden")
    end },

    { "key binding function and Bindings.xml", function(T, Mock)
        local H = Mock.new():login()
        T.eq(H.env.BINDING_HEADER_FAROL, "Farol")
        H.env.Farol_ToggleWarnHistory()
        T.ok(H.env.FarolWarnHistory:IsShown(), "binding opens the history")
        local file = io.open("Farol/Bindings.xml", "r")
        T.ok(file, "Bindings.xml exists"); local xml = file:read("*a"); file:close()
        T.has(xml, 'name="FAROL_WARN_HISTORY"'); T.has(xml, "Farol_ToggleWarnHistory()")
        T.hasnt(xml, "SetBinding"); T.hasnt(xml, "RunScript")
    end },
}
