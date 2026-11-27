-- Menu em abas (3.4): Barra · Avisos · Ferramentas · Geral; itens em grupos; tudo sincronizado entre o menu do
-- Farol e o painel das configurações do jogo.
-- Tabbed menu (3.4): Bar · Warnings · Tools · General; grouped items; menu and game settings panel stay in sync.

local function open(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    return H.env.FarolOptions, H.env.FarolOptions.controls
end
local function shownTab(set)
    local shown = {}
    for key, page in pairs(set.pages) do if page:IsShown() then shown[#shown + 1] = key end end
    table.sort(shown)
    return table.concat(shown, ",")
end
local function buttonByText(H, text, parent)
    local found
    for _, frame in ipairs(H:framesOf("Button")) do
        if frame._text == text and (not parent or frame._parent == parent) then found = frame end
    end
    return found
end

return {
    { "four tabs; the Bar tab opens first and only one page shows at a time", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local window, set = open(H)
        T.ok(window:IsShown())
        for key, label in pairs({ bar = "Barra", warnings = "Avisos", tools = "Ferramentas", general = "Geral" }) do
            T.eq(H:text(set.tabs[key]), label, key)
        end
        T.eq(shownTab(set), "bar"); T.eq(set.tabs.bar._highlight, true)
        for _, key in ipairs({ "warnings", "tools", "general", "bar" }) do
            H:click(set.tabs[key])
            T.eq(shownTab(set), key, "only " .. key)
            T.eq(set.tabs[key]._highlight, true); T.eq(set.tabs.general._highlight, key == "general")
        end
    end },

    { "items are grouped, in the same order as the bar items; group titles translated", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local flat = {}
        for _, group in ipairs(H.ns.ITEM_GROUPS) do for _, key in ipairs(group[2]) do flat[#flat + 1] = key end end
        T.eq(table.concat(flat, ","), table.concat(H.ns.ITEM_ORDER, ","), "every item once, same order")
        local _, set = open(H)
        local titles = {}
        for _, header in ipairs(set.groups) do titles[#titles + 1] = H:text(header) end
        T.eq(table.concat(titles, " | "), "Desempenho | Lugar | Equipamento e bolsas | Ouro | Progresso | Tempo e social")
        H:check(set.items.tasks, true); T.eq(H.env.FarolDB.items.tasks, true)
    end },

    { "/farol aviso opens the menu on the Warnings tab; again closes it; right-click goes back to Bar", function(T, Mock)
        local H = Mock.new():login({ hub = false })
        H:slash("aviso")
        local window, set = H.env.FarolOptions, H.env.FarolOptions.controls
        T.ok(window:IsShown()); T.eq(shownTab(set), "warnings")
        H:slash("aviso"); T.ok(not window:IsShown(), "toggled closed")
        H:slash("aviso"); H:click(set.tabs.general)
        H:slash("aviso"); T.ok(window:IsShown(), "other tab: switches instead of closing"); T.eq(shownTab(set), "warnings")
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        T.ok(window:IsShown()); T.eq(shownTab(set), "bar", "right-click shows the Bar tab")
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        T.ok(not window:IsShown(), "right-click again closes")
        H:slash("barra 2 mostrar"); H:slash("barra 1"); open(H)
        H.env.FarolBar2._scripts.OnMouseUp(H.env.FarolBar2, "RightButton")
        T.ok(window:IsShown(), "right-click on another bar keeps it open"); T.eq(rawget(H.env.FarolDB, "activeBar"), 2)
    end },

    { "Warnings tab: sections, the new tasks checkbox, and sync with the game settings panel", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        H:slash("aviso")
        local w = H.env.FarolOptions.controls.warnings
        T.eq(H:text(w.gearHeader), "Equipamento e bolsas"); T.eq(H:text(w.charHeader), "Personagem")
        T.eq(H:text(w.breaksHeader), "Pausas"); T.eq(H:text(w.howHeader), "Como avisar")
        T.eq(H:text(w.questHeader), "Missões e viagem")
        T.eq(H:text(H.env.FarolWarnTasks.label), "Tarefas diárias pendentes (1 h antes)")
        H:check(H.env.FarolWarnTasks, true); T.eq(H.env.FarolDB.warnings.tasks, true)
        T.eq(H.env.FarolPanelWarnTasks._checked, true, "settings panel synced")
        H:check(H.env.FarolPanelWarnSound, false); T.eq(H.env.FarolDB.warnings.sound, false)
        T.eq(H.env.FarolWarnSound._checked, false, "menu synced")
        H:slash("tarefa aviso off"); T.eq(H.env.FarolWarnTasks._checked, false, "command syncs the checkbox")
    end },

    { "Tools tab: one button per window, with a description; Summary now prints in chat", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local _, set = open(H); H:click(set.tabs.tools)
        local texts = {}
        for _, button in ipairs(set.tools) do texts[#texts + 1] = H:text(button) .. " = " .. H:text(button.desc) end
        local all = table.concat(texts, " | ")
        T.has(all, "Alarmes... = até 10 alarmes"); T.has(all, "Tarefas... = diárias e semanais"); T.has(all, "Anotações... = bloco de notas da conta, com caixinhas"); T.has(all, "Histórico... = os 10 últimos avisos")
        for _, entry in ipairs({ { 1, "FarolAlarms" }, { 2, "FarolTasks" }, { 3, "FarolNotes" }, { 4, "FarolGoals" }, { 5, "FarolRuns" }, { 6, "FarolCompleted" }, { 7, "FarolLoot" }, { 8, "FarolWarnHistory" } }) do
            H:click(set.tools[entry[1]]); T.ok(H.env[entry[2]]:IsShown(), entry[2])
        end
        H:click(set.tools[9]); T.has(H.strip(table.concat(H.msgs, "\n")), "resumo da sessão")
    end },

    { "General tab: sections, Appearance-only options, danger area apart (3.24)", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local _, set = open(H); H:click(set.tabs.general)
        T.eq(H:text(set.langHeader), "Idioma"); T.eq(H:text(set.chatHeader), "Chat e mensagens")
        T.eq(H:text(set.barHeader), "Barra e relógio"); T.eq(H:text(set.accessHeader), "Minimapa e acessibilidade")
        T.eq(H:text(set.restoreHeader), "Restaurar e apagar"); T.eq(H:text(set.profileHeader), "Perfis (avançado)")
        T.eq(set.tooltipFull, nil, "full tooltip only in the Appearance window")
        T.eq(set.warnButton, nil); T.eq(set.lootButton, nil)
        T.has(H:text(set.appearanceHint), "tooltip completo"); T.has(H:text(set.forgetHint), "segundo clique")
        H:click(set.appearanceAll); T.ok(H.env.FarolAppearance and H.env.FarolAppearance:IsShown(), "Appearance... opens the window")
        T.has(set.forget._text, "|T", "danger button has the alert icon")
        T.has(set.forget._text, H.env.FarolDB.colorblind and "ff8a33" or "ff6666", "danger color from the palette")
        -- Sections in order, from top to bottom, without overlapping.
        local order = { set.langHeader, set.chatHeader, set.barHeader, set.accessHeader, set.profileHeader, set.restoreHeader }
        for i = 2, #order do
            T.ok(order[i - 1].farolTop - order[i - 1].farolHeight >= order[i].farolTop, "section " .. i .. " below the previous one")
        end
        local last = order[#order]
        T.ok(-(last.farolTop - last.farolHeight) <= 494, "fits in the page"); T.ok(last.farolDanger, "danger section")
    end },

    { "tabs look like tabs: only the open one is marked (3.24)", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login({ hub = false })
        local _, set = open(H)
        T.ok(set.tabs.bar.farolMark:IsShown(), "Bar open"); T.ok(not set.tabs.general.farolMark:IsShown())
        H:click(set.tabs.general)
        T.ok(set.tabs.general.farolMark:IsShown()); T.ok(not set.tabs.bar.farolMark:IsShown(), "only one marked")
        T.ok(set.tabLine, "line under the tabs")
        H:slash("aparencia botao"); T.eq(H.env.FarolDB.warnButton, false, "quick buttons still change by command")
    end },

    { "English tabs, groups and warning sections", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login({ hub = false })
        local _, set = open(H)
        T.eq(H:text(set.tabs.tools), "Tools"); T.eq(H:text(set.groups[3]), "Gear and bags")
        T.eq(H:text(set.shown.label), "Show")
        T.eq(H:text(set.warnings.breaksHeader), "Breaks"); T.eq(H:text(set.warnings.questHeader), "Quests and travel"); T.eq(H:text(H.env.FarolWarnDurab.label), "Durability below")
        T.eq(H:text(set.tools[9]), "Summary now")
    end },
}
