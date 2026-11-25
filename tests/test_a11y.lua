-- Acessibilidade (3.12): cores para daltonismo (opção, desligada), vermelho mais claro, janelas com fundo opaco,
-- dicas em cinza claro, engrenagem maior e Tab entre os campos de número.
-- Accessibility (3.12): colorblind-friendly colors (option, off), lighter red, opaque window backgrounds, lighter
-- hint text, bigger gear and Tab between number fields.

local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "default colors: green / yellow / lighter red; colorblind option off by default", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.eq(H.env.FarolDB.colorblind, false)
        T.has(H:barRaw(), "|cff00ff0060|r fps")
        T.has(H:barRaw(), "Dur |cffff666615%|r", "red is lighter (more contrast on bright scenery)")
        T.eq(H.ns.C.good, "|cff40ff40"); T.eq(H.ns.C.bad, "|cffff6666")
    end },

    { "colorblind option: blue / yellow / orange everywhere, from the menu or the command, and saved", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("menu")
        local set = H.env.FarolOptions.controls
        T.eq(H:text(set.colorblind.label), "Cores para daltonismo (azul · amarelo · laranja)")
        H:check(set.colorblind, true); H:update(1)
        T.eq(H.env.FarolDB.colorblind, true); T.has(all(H), "bom = azul, atenção = amarelo, ruim = laranja")
        T.has(H:barRaw(), "|cff66b3ff60|r fps"); T.has(H:barRaw(), "Dur |cffff8a3315%|r")
        T.eq(H.ns.C.good, "|cff66b3ff"); T.eq(H.ns.C.bad, "|cffff8a33")
        H.quests = { { title = "Missão", level = 30, done = true } }
        H:slash("mostrar missoes"); H:update(1)
        T.has(H:barRaw(), "|cff66b3ff1 pronta|r", "modules use the palette too")
        local again = Mock.new():login(H.env.FarolDB); again:update(1)
        T.has(again:barRaw(), "|cff66b3ff60|r fps", "saved and applied at login")
        H:slash("cores padrao"); H:update(1)
        T.has(H:barRaw(), "|cff00ff0060|r fps"); T.eq(set.colorblind._checked, false, "checkbox synced")
        H:slash("cores daltonismo"); T.eq(H.env.FarolDB.colorblind, true)
        H:slash("cores azul"); T.has(all(H), "uso: /farol cores")
        for _, bad in ipairs({ "yes", 1, {}, 0 / 0 }) do
            T.eq(Mock.new():login({ colorblind = bad }).env.FarolDB.colorblind, false, "invalid saved value -> off")
        end
    end },

    { "news line says the option is off and where to turn it on", function(T, Mock)
        local H = Mock.new():login({ items = { fps = true }, newsSeen = #Mock.new():login().ns.NEWS - 11 })
        T.has(all(H), "cores para daltonismo (azul, amarelo e laranja) e janelas mais legíveis — desligado (ligue em Menu > Geral)")
    end },

    { "every window gets an opaque backing; hint texts use a lighter gray", function(T, Mock)
        local H = Mock.new():login()
        for _, cmd in ipairs({ "menu", "saque", "alarme", "tarefa", "meta", "masmorra", "ordem", "aparencia", "historico" }) do
            H:slash(cmd)
        end
        for _, name in ipairs({ "FarolOptions", "FarolLoot", "FarolAlarms", "FarolTasks", "FarolGoals", "FarolRuns",
                                "FarolOrder", "FarolAppearance", "FarolWarnHistory" }) do
            T.ok(H.env[name] and H.env[name].farolBacking, name .. " has an opaque backing")
        end
        local color = H.env.FarolLoot.empty._color
        T.ok(color and color[1] >= 0.7, "empty-list text is light gray")
    end },

    { "gear is 16 px; Tab moves between number fields and only saves what changed", function(T, Mock)
        local H = Mock.new():login(); H:slash("menu")
        local set = H.env.FarolOptions.controls
        T.eq(set.gears.hearth._w, 16)
        local durab, bags = H.env.FarolWarnDurabPct, H.env.FarolWarnBagSlots
        bags.SetFocus = function(self) self._focused = true end
        durab._scripts.OnEditFocusGained(durab)
        local before = #H.msgs
        durab._scripts.OnTabPressed(durab)
        T.eq(#H.msgs, before, "unchanged value: no message"); T.ok(bags._focused, "focus moved to the next field")
        durab._scripts.OnEditFocusGained(durab); durab:SetText("25"); durab._scripts.OnTabPressed(durab)
        T.eq(H.env.FarolDB.warnings.durabPct, 25, "changed value saved on Tab")
        H:slash("meta")
        local gold, level = H.env.FarolGoalGold, H.env.FarolGoalLevel
        level.SetFocus = function(self) self._focused = true end
        gold._scripts.OnEditFocusGained(gold); gold:SetText("300"); gold._scripts.OnTabPressed(gold)
        T.eq(H.env.FarolCharDB.goals.gold, 3000000); T.ok(level._focused, "gold -> level")
    end },

    { "status colors come only from the palette (so the colorblind option reaches every module)", function(T)
        for _, file in ipairs({ "Alarm.lua", "Loot.lua", "Warnings.lua", "Appearance.lua", "Order.lua", "Tasks.lua", "Notes.lua", "Goals.lua",
                                "Farm.lua", "Quests.lua", "Hearth.lua", "Runs.lua", "Completed.lua", "Sources.lua", "Diag.lua", "MinimapButton.lua" }) do
            local f = io.open("Farol/" .. file, "r"); local code = f:read("*a"); f:close()
            for _, literal in ipairs({ "|cff40ff40", "|cff00ff00", "|cffffff3a", "|cffff4040", "|cffff3333", "|cffff6666", "|cff888888" }) do
                T.ok(not code:find(literal, 1, true), file .. " uses " .. literal .. " (use ns.C.good/warn/bad/dim)")
            end
        end
    end },
}
