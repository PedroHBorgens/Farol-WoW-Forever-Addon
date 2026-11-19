-- Menu mais simples (3.11): pacotes prontos, ⚙ ao lado dos itens, faixa de explicação, perfil na aba Geral,
-- avisos em grupos com "Só os recomendados" / "Desligar todos".
-- Simpler menu (3.11): presets, gear next to items, info strip, profile in the General tab, grouped warnings
-- with "Recommended only" / "Turn all off".

local function open(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    return H.env.FarolOptions, H.env.FarolOptions.controls
end
local function on(H)
    local list = {}
    for _, key in ipairs(H.ns.ITEM_ORDER) do if H.env.FarolDB.items[key] then list[#list + 1] = key end end
    return table.concat(list, ",")
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "presets add items; Basic goes back to the basics; Undo restores; nothing turns on by itself", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        local before = on(H)
        local _, set = open(H)
        T.eq(H:text(set.packLabel), "Pacotes:"); T.eq(H:text(set.packs[2]), "Upando")
        T.eq(set.packUndo._disabled, true, "nothing to undo yet")
        T.eq(on(H), before, "opening the menu changes nothing")
        H:click(set.packs[2]) -- Upando
        for _, key in ipairs({ "xp", "xph", "quests", "hearth", "fps", "gold" }) do T.eq(H.env.FarolDB.items[key], true, key) end
        T.has(H:lastMsg(), "pacote Upando: 3 item(ns) ligado(s)")
        T.ok(not set.packUndo._disabled, "undo enabled")
        H:click(set.packs[3]) -- Ouro e farm (soma)
        T.eq(H.env.FarolDB.items.farm, true); T.eq(H.env.FarolDB.items.xp, true, "presets add, they do not remove")
        H:click(set.packUndo)
        T.eq(H.env.FarolDB.items.farm, false); T.eq(H.env.FarolDB.items.xp, true, "undo goes back one step")
        T.has(H:lastMsg(), "pacote desfeito")
        H:click(set.packs[1]) -- Básico
        T.eq(on(H), "fps,ms,coords,zone,hearth,durab,gold"); T.has(H:lastMsg(), "a barra voltou ao básico")
        H:slash("pacote desfazer"); T.eq(H.env.FarolDB.items.xp, true)
        H:slash("pacote desfazer"); T.has(H:lastMsg(), "nada para desfazer")
        H:slash("pacote masmorras"); T.eq(H.env.FarolDB.items.run, true); T.eq(H.env.FarolDB.items.ammo, true)
        H:slash("preset dungeons"); H:slash("pacote voar"); T.has(H:lastMsg(), "uso: /farol pacote")
    end },

    { "a preset only changes the bar picked in the menu, and undo goes back to that bar", function(T, Mock)
        local H = Mock.new():login()
        H:slash("barra 2 mostrar"); local _, set = open(H)
        H:click(set.bars[2]); T.eq(rawget(H.env.FarolDB, "activeBar"), 2)
        local bar1 = on(H) -- (lê a barra ativa)
        H:click(set.packs[4])
        T.eq(H.env.FarolDB.items.run, true, "bar 2 got the preset")
        H:click(set.bars[1]); T.eq(H.env.FarolDB.items.run, false, "bar 1 untouched")
        H:click(set.packUndo)
        H:click(set.bars[2]); T.eq(on(H), bar1, "undo restored bar 2")
    end },

    { "gear next to items with settings opens the right window or tab; info strip explains the hovered item", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        local _, set = open(H)
        for _, key in ipairs({ "hearth", "ammo", "quests", "goals", "farm", "clock", "tasks", "run" }) do
            T.ok(set.gears[key], "gear for " .. key)
        end
        T.eq(set.gears.fps, nil, "no gear without settings")
        H:click(set.gears.hearth); T.ok(set.pages.warnings:IsShown(), "hearth gear opens the Warnings tab")
        H:click(set.tabs.bar)
        H:click(set.gears.goals); T.ok(H.env.FarolGoals:IsShown())
        H:click(set.gears.tasks); T.ok(H.env.FarolTasks:IsShown())
        H:click(set.gears.clock); T.ok(H.env.FarolAlarms:IsShown())
        H:click(set.gears.run); T.ok(H.env.FarolRuns:IsShown())
        T.has(H:text(set.info), "Passe o mouse num item")
        set.items.hearth._scripts.OnEnter(set.items.hearth)
        T.has(H:text(set.info), "Pedra de Regresso: Onde a sua Pedra de Regresso está vinculada")
        set.items.hearth._scripts.OnLeave(set.items.hearth)
        T.has(H:text(set.info), "Passe o mouse num item")
        set.packs[2]._scripts.OnEnter(set.packs[2]); T.has(H:text(set.info), "Upando: liga XP")
        set.gears.farm._scripts.OnEnter(set.gears.farm); T.has(H:text(set.info), "Configurar: abre a janela Metas")
    end },

    { "profile and Copy from... moved to the General tab (advanced) and still work", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        local _, set = open(H)
        T.eq(set.profile:GetParent(), set.pages.general); T.eq(set.copy:GetParent(), set.pages.general)
        T.eq(H:text(set.profileHeader), "Perfis (avançado)")
        T.eq(set.locked._anchor, set.shown.label, "Lock sits after the end of the Show label, never on top of it")
        H:slash("perfil personagem"); T.eq(H.env.FarolCharDB.profile, "char")
    end },

    { "Warnings tab: Recommended only / Turn all off, grouped, with an info strip", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("aviso")
        local w = H.env.FarolOptions.controls.warnings
        T.eq(H:text(w.recommended), "Só os recomendados"); T.eq(H:text(w.allOff), "Desligar todos")
        H:slash("aviso pausa on"); H:slash("aviso missoes on"); H:slash("aviso som off")
        H:click(w.allOff)
        for key, value in pairs(H.env.FarolDB.warnings) do
            if type(value) == "boolean" and key ~= "sound" and not key:find("Anywhere") then T.eq(value, false, key .. " off") end
        end
        T.eq(H.env.FarolDB.warnings.sound, false, "sound left as it was")
        T.has(H:lastMsg(), "avisos: todos desligados"); T.eq(H.env.FarolWarnDurab._checked, false, "checkbox synced")
        H:click(w.recommended)
        T.eq(H.env.FarolDB.warnings.durab, true); T.eq(H.env.FarolDB.warnings.bags, true); T.eq(H.env.FarolDB.warnings.pause, false)
        T.eq(H.env.FarolPanelWarnDurab._checked, true, "settings panel synced")
        H:slash("aviso nenhum"); T.eq(H.env.FarolDB.warnings.durab, false)
        H:slash("aviso recomendados"); T.eq(H.env.FarolDB.warnings.durab, true)
        T.has(H:text(w.info), "Avisa uma vez")
        H.env.FarolWarnHearthReady._scripts.OnEnter(H.env.FarolWarnHearthReady)
        T.has(H:text(w.info), "Pedra de Regresso pronta: avisa uma vez quando a recarga")
        H.env.FarolWarnPauseAnywhere._scripts.OnEnter(H.env.FarolWarnPauseAnywhere)
        T.has(H:text(w.info), "Também em lutas e masmorras: sem esta opção")
        H.env.FarolWarnPauseAnywhere._scripts.OnLeave(H.env.FarolWarnPauseAnywhere)
        T.has(H:text(w.info), "Avisa uma vez")
    end },

    { "every warning has a description in both languages", function(T, Mock)
        local H = Mock.new():login()
        for _, key in ipairs({ "durab", "bags", "ammo", "reag", "talents", "ranks", "prof", "restFull", "goals", "questFull",
                               "questReady", "hearthReady", "tasks", "pause", "water", "anywhere", "sound" }) do
            for _, lang in ipairs({ "pt", "en" }) do
                T.ok(H.ns.STRINGS[lang]["warn_desc_" .. key], lang .. " warn_desc_" .. key)
            end
        end
        local E = Mock.new({ locale = "enUS" }):login()
        local _, set = open(E)
        T.eq(E:text(set.packs[3]), "Gold & farm"); T.has(E:text(set.info), "Hover an item")
    end },
}
