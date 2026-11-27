-- Crítica de design (3.13): "Barra 1/2/3" só escolhe a barra (pacotes ficam num quadro "Aplicar pacote:"),
-- "Desfazer" visível depois de um pacote e ao apagar tarefa / meta de farm, ouro sem parecer alerta e selos 📝 👜
-- na paleta (cores para daltonismo).
-- Design review (3.13): bar buttons only pick the bar, visible Undo after a preset and when removing a task / farm
-- goal, gold no longer looks like a warning, quick-button badges use the palette.

local SILK = "|cffffffff|Hitem:4306::::::::60:::::|h[Tecido de Seda]|h|r"
local function open(H)
    H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
    return H.env.FarolOptions.controls
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "bar buttons only pick the bar (and say so); presets show what changed and a visible Undo", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login({ hub = false })
        local set = open(H)
        T.eq(H:text(set.barLabel), "Editando:"); T.eq(H:text(set.packLabel), "Aplicar pacote:")
        T.ok(not set.packUndo:IsShown(), "Undo hidden while there is nothing to undo")
        set.bars[2]._scripts.OnEnter(set.bars[2])
        T.has(H:text(set.info), "Trocar de barra não muda nada")
        set.bars[2]._scripts.OnLeave(set.bars[2])
        local before = {}
        for _, key in ipairs(H.ns.ITEM_ORDER) do before[key] = H.env.FarolDB.items[key] end
        H:click(set.bars[2]); H:click(set.bars[1])
        for _, key in ipairs(H.ns.ITEM_ORDER) do T.eq(H.env.FarolDB.items[key], before[key], "picking a bar changes nothing: " .. key) end
        H:click(set.packs[2])
        T.ok(set.packUndo:IsShown(), "Undo shown after a preset")
        T.has(H.strip(H:text(set.hint)), "Pacote Upando aplicado na barra 1 (3 mudanças)")
        H:check(set.items.mem, true)
        T.has(H.strip(H:text(set.hint)), "ligados", "touching an item brings the count back")
        T.ok(set.packUndo:IsShown(), "Undo still available")
        H:click(set.packUndo)
        T.ok(not set.packUndo:IsShown()); T.eq(H.env.FarolDB.items.xp, false)
        local en = Mock.new({ locale = "enUS" }):login({ hub = false })
        local s2 = open(en)
        T.eq(en:text(s2.barLabel), "Editing:"); T.eq(en:text(s2.packLabel), "Apply preset:")
    end },

    { "tasks: removing shows Undo; Undo puts the task back in the same place, once", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("tarefa add Pesca"); H:slash("tarefa add semanal Masmorra"); H:slash("tarefa add Culinária")
        H:slash("tarefa feita 2")
        H:slash("tarefa")
        T.eq(H.env.FarolTaskKind._text, "Tipo: Diária")
        T.ok(not H.env.FarolTaskUndo:IsShown(), "no Undo yet")
        H:click(H.env.FarolTaskRemove2)
        T.eq(#H.env.FarolCharDB.tasks, 2); T.has(H:lastMsg(), "Desfazer na janela")
        T.ok(H.env.FarolTaskUndo:IsShown()); T.has(H:text(H.env.FarolTasks.undoText), "Tarefa apagada: Masmorra")
        H:click(H.env.FarolTaskUndo)
        local list = H.env.FarolCharDB.tasks
        T.eq(#list, 3); T.eq(list[2].n, "Masmorra"); T.eq(list[2].w, true); T.ok(list[2].d, "done mark kept")
        T.ok(not H.env.FarolTaskUndo:IsShown()); T.has(H:lastMsg(), "tarefa de volta: Masmorra")
        H:slash("tarefa desfazer"); T.has(H:lastMsg(), "nada para desfazer")
        T.eq(#H.env.FarolCharDB.tasks, 3, "only once")
        -- Lista cheia: não passa do limite.
        H:slash("tarefa apagar 1")
        for i = 1, 8 do H:slash("tarefa add T" .. i) end
        T.eq(#H.env.FarolCharDB.tasks, 10)
        H:slash("tarefa desfazer"); T.has(H:lastMsg(), "a lista já tem 10 tarefas"); T.eq(#H.env.FarolCharDB.tasks, 10)
        -- A cópia guardada não é a tabela salva: mexer na lista depois não estraga o "Desfazer".
        H:slash("tarefa apagar 10"); H.env.FarolCharDB.tasks[9].n = "mudou"
        H:slash("tarefa desfazer"); T.eq(H.env.FarolCharDB.tasks[10].n, "T8"); T.eq(H.env.FarolCharDB.tasks[9].n, "mudou")
        -- Posição inválida (NaN, negativa, enorme): volta no fim da lista, sem erro.
        for _, bad in ipairs({ 0 / 0, -3, 1e9, "x" }) do
            H:slash("tarefa apagar 1"); H.ns.Tasks.lastRemoved.index = bad
            local ok, err = pcall(H.slash, H, "tarefa desfazer"); T.ok(ok, tostring(err))
            T.eq(#H.env.FarolCharDB.tasks, 10); T.ok(H.env.FarolCharDB.tasks[10].n ~= nil)
        end
    end },

    { "farm goals: removing shows Undo in the Goals window; Undo restores; clear forgets it", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" })
        H.items[4306] = { "Tecido de Seda", 1, 150 }; H.itemCounts[4306] = 27
        H.items[2772] = { "Minério de Ferro", 1, 200 }
        H:login()
        H:slash("meta item " .. SILK .. " 40"); H:slash("meta item |cffffffff|Hitem:2772::::::::60:::::|h[Minério de Ferro]|h|r 20")
        H:slash("meta")
        T.ok(not H.env.FarolFarmUndo:IsShown())
        H:click(H.env.FarolFarmRemove1)
        T.eq(#H.env.FarolCharDB.farm, 1); T.ok(H.env.FarolFarmUndo:IsShown())
        T.has(H.strip(H:text(H.env.FarolGoals.farmHeader)), "apagada: Tecido de Seda")
        H:click(H.env.FarolFarmUndo)
        T.eq(#H.env.FarolCharDB.farm, 2); T.eq(H.env.FarolCharDB.farm[1].id, 4306); T.eq(H.env.FarolCharDB.farm[1].c, 40)
        T.ok(not H.env.FarolFarmUndo:IsShown()); T.has(H:lastMsg(), "meta de farm de volta")
        H:slash("meta item desfazer"); T.has(H:lastMsg(), "nada para desfazer")
        H:slash("meta item remover 1"); H:slash("meta item " .. SILK .. " 10")
        H:slash("meta item desfazer"); T.eq(#H.env.FarolCharDB.farm, 2, "same item already back: no duplicate")
        H:slash("meta item remover 1"); H:slash("farm limpar"); H:slash("farm desfazer")
        T.has(H:lastMsg(), "nada para desfazer"); T.eq(#H.env.FarolCharDB.farm, 0)
    end },

    { "gold: numbers in the text color, only g/s/c colored; badges follow the palette", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.has(H:barRaw(), "|cffffd700g|r", "gold letter colored")
        T.hasnt(H:barRaw(), "|cffffd700%d", "number is not yellow")
        T.ok(not string.find(H:barRaw(), "|cffffd700%d"), "no colored digits")
        local function loot(i) H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff1eff00|Hitem:" .. (8000 + i) .. "|h[Erva " .. i .. "]|h|r.") end
        local button = H.env.FarolLootButton
        loot(1); T.has(button.badge._text, "|cff40ff401|r", "loot badge: palette green")
        H:slash("menu")
        H.env.FarolWarnTest:Click()
        local history = H.env.FarolWarnHistoryButton
        T.has(history.badge._text, "|cffff66661|r", "history badge: palette red")
        H:slash("cores daltonismo")
        T.has(button.badge._text, "|cff66b3ff1|r", "existing badge recolored at once")
        T.has(history.badge._text, "|cffff8a331|r", "existing badge recolored at once")
        loot(2); T.has(button.badge._text, "|cff66b3ff2|r", "loot badge blue in colorblind mode")
        for _, file in ipairs({ "Warnings.lua", "Loot.lua" }) do
            local f = io.open("Farol/" .. file, "r"); local code = f:read("*a"); f:close()
            T.ok(not code:find("badge:SetTextColor", 1, true), file .. ": badge color comes from ns.C")
        end
    end },
}
