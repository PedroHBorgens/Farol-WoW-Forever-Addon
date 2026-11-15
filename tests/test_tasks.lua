-- Lista de tarefas diárias e semanais: barra, tooltip, janela, comandos, reset automático, aviso, dados adulterados.
-- Daily and weekly task list: bar, tooltip, window, commands, automatic reset, warning, tampered data.

local BASE = 1800000000 -- um instante fixo (o relógio do simulador passa a ser este + avanço)

local function setup(Mock, opts, saved, savedChar)
    local H = Mock.new(opts)
    H.clockNow = BASE
    H.env.time = function(t) if t then return os.time(t) end return H.clockNow end
    H:login(saved, savedChar)
    H:slash("mostrar tarefas"); H:update(1)
    return H
end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "off by default; empty list shows --; commands add daily and weekly tasks", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Tarefas", "off by default"); T.eq(H.env.FarolDB.items.tasks, false)
        H = setup(Mock)
        T.has(H:bar(), "Tarefas --")
        H:slash("tarefa add Missão diária de pesca"); H:slash("tarefa add semanal Ember Depths")
        H:update(1)
        T.has(H:bar(), "Tarefas 0/2")
        local t = tip(H)
        T.has(t, "Tarefas = 0 / 2"); T.has(t, "Missão diária de pesca (diária) = falta"); T.has(t, "Ember Depths (semanal) = falta")
        T.has(t, "zeram em = diária 5h 12m · semanal 2d 4h")
        T.eq(#H.env.FarolCharDB.tasks, 2); T.eq(H.env.FarolCharDB.tasks[2].w, true)
    end },

    { "marking done updates the bar (yellow, then green when all done)", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa add A"); H:slash("tarefa add B")
        H:slash("tarefa feita 1"); H:update(1)
        T.has(H:bar(), "Tarefas 1/2"); T.has(H:barRaw(), "|cffffff3a1/2")
        H:slash("tarefa feita 2"); H:update(1)
        T.has(H:barRaw(), "|cff40ff402/2", "green when everything is done")
        H:slash("tarefa feita 2"); H:update(1)
        T.has(H:bar(), "Tarefas 1/2", "toggles back")
    end },

    { "daily tasks reset at the daily reset; weekly ones only at the weekly reset", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa add Diária"); H:slash("tarefa add semanal Semanal")
        H:slash("tarefa feita 1"); H:slash("tarefa feita 2"); H:update(1)
        T.has(H:bar(), "Tarefas 2/2")
        -- passa o reset diário: 5h12m depois, e o próximo é daqui a 24 h
        H.clockNow = BASE + 5 * 3600 + 12 * 60 + 1; H.dailyReset = 86399; H.weeklyReset = 2 * 86400 + 4 * 3600 - (5 * 3600 + 12 * 60 + 1)
        H:update(1)
        T.has(H:bar(), "Tarefas 1/2", "daily reset, weekly still done")
        -- passa o reset semanal
        H.clockNow = BASE + 2 * 86400 + 4 * 3600 + 1; H.dailyReset = 86000; H.weeklyReset = 7 * 86400 - 1
        H:update(1)
        T.has(H:bar(), "Tarefas 0/2", "weekly reset too")
    end },

    { "old client without the weekly reset: a mark lasts 7 days (weekly) / until the daily reset", function(T, Mock)
        local H = setup(Mock)
        H.weeklyReset = nil
        H:slash("tarefa add semanal S"); H:slash("tarefa feita 1"); H:update(1)
        H.clockNow = BASE + 6 * 86400; H:update(1); T.has(H:bar(), "Tarefas 1/1")
        H.clockNow = BASE + 7 * 86400 + 1; H:update(1); T.has(H:bar(), "Tarefas 0/1")
    end },

    { "window: add with the box and the Daily/Weekly button, tick, remove; warning checkbox", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa")
        local W = H.env.FarolTasks
        T.ok(W:IsShown(), "window open"); T.eq(H.env.UISpecialFrames[#H.env.UISpecialFrames], "FarolTasks")
        T.ok(W.empty:IsShown(), "empty hint")
        H.env.FarolTaskName:SetText("Vender no leilão"); H:click(H.env.FarolTaskAdd)
        H:click(H.env.FarolTaskKind); T.eq(H.env.FarolTaskKind._text, "Semanal")
        H.env.FarolTaskName:SetText("Raide"); H:click(H.env.FarolTaskAdd)
        T.eq(H.env.FarolCharDB.tasks[1].w, false); T.eq(H.env.FarolCharDB.tasks[2].w, true)
        T.eq(H.env.FarolTaskName:GetText(), "", "box cleared")
        T.eq(H:text(W.rows[2].kind), "semanal")
        H:check(H.env.FarolTaskDone1, true); H:update(1)
        T.has(H:bar(), "Tarefas 1/2")
        H:click(H.env.FarolTaskRemove1); H:update(1)
        T.eq(#H.env.FarolCharDB.tasks, 1); T.eq(H.env.FarolCharDB.tasks[1].n, "Raide"); T.has(H:bar(), "Tarefas 0/1")
        H:check(H.env.FarolTaskWarn, true); T.eq(H.env.FarolDB.warnings.tasks, true)
        H:check(H.env.FarolTaskWarn, false); T.eq(H.env.FarolDB.warnings.tasks, false)
    end },

    { "names are cleaned and limited; at most 10 tasks", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa add |cffff0000Vermelho|r")
        T.eq(H.env.FarolCharDB.tasks[1].n, "cffff0000Vermelhor", "no | codes")
        H:slash("tarefa add " .. string.rep("á", 60))
        T.eq(H.env.FarolCharDB.tasks[2].n, string.rep("á", 40), "40 letters, UTF-8 safe")
        H:slash("tarefa add    "); T.has(H:lastMsg(), "escreva um nome")
        for i = 3, 10 do H:slash("tarefa add T" .. i) end
        H:slash("tarefa add Onze"); T.has(H:lastMsg(), "já tem 10 tarefas")
        T.eq(#H.env.FarolCharDB.tasks, 10)
    end },

    { "per character and saved: survives reload", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa add A"); H:slash("tarefa feita 1"); H:event("PLAYER_LOGOUT")
        local char = H.env.FarolCharDB
        local H2 = setup(Mock, nil, nil, { tasks = char.tasks })
        T.has(H2:bar(), "Tarefas 1/1")
        local other = setup(Mock)
        T.has(other:bar(), "Tarefas --", "another character has its own (empty) list")
    end },

    { "optional warning (off by default): once per daily reset when daily tasks are left", function(T, Mock)
        local H = setup(Mock)
        H:slash("tarefa add A"); H:slash("tarefa add B")
        H.dailyReset = 50 * 60; H:update(1); H:update(1)
        T.hasnt(all(H), "tarefas diárias e o reset", "off by default")
        H:slash("tarefa aviso on"); H:update(1)
        T.has(all(H), "faltam 2 tarefas diárias e o reset diário é em 50m")
        local count = select(2, string.gsub(all(H), "faltam 2 tarefas", ""))
        H:update(1); H:update(1)
        T.eq(select(2, string.gsub(all(H), "faltam 2 tarefas", "")), count, "only once per reset")
        H:slash("aviso lembrar 5"); H.now = H.now + 301; H:update(1)
        T.eq(select(2, string.gsub(all(H), "faltam 2 tarefas", "")), count + 1, "reminded after 5 min")
        H:slash("tarefa feita 1"); H.dailyReset = 30 * 60; H:update(1) -- outro horário de reset = novo ciclo
        T.has(all(H), "falta 1 tarefa diária e o reset diário é em 30m", "singular")
        H:slash("tarefa feita 2")
        local before = select(2, string.gsub(all(H), "tarefas diárias e o reset", ""))
        H.dailyReset = 20 * 60; H:update(1); H:update(1) -- mesmo dia, mais perto do reset, tudo feito
        T.eq(select(2, string.gsub(all(H), "tarefas diárias e o reset", "")), before, "no warning when nothing is left")
    end },

    { "tampered saved tasks fall back safely", function(T, Mock)
        local list = { 5, "x", { n = 5 }, { n = "ok|bad", d = 0 / 0 }, { n = "" }, { n = "Futuro", d = 1e20 },
                       { n = "Boa", w = "yes", d = BASE - 10 } }
        for i = 1, 20 do list[#list + 1] = { n = "N" .. i } end
        local H = setup(Mock, nil, nil, { tasks = list })
        local t = H.env.FarolCharDB.tasks
        T.eq(#t, 10)
        T.eq(t[1].n, "okbad"); T.eq(t[1].d, nil); T.eq(t[2].n, "Futuro"); T.eq(t[2].d, nil, "date in the future dropped")
        T.eq(t[3].w, false); T.eq(t[3].d, BASE - 10)
        local H2 = setup(Mock, nil, nil, { tasks = "x" }); T.eq(#H2.env.FarolCharDB.tasks, 0)
    end },

    { "invalid task commands are refused; English", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        H:slash("task add Fishing quest")
        for _, cmd in ipairs({ "task fly", "task done", "task done 99", "task done x", "task remove 0", "task list now", "task warn maybe" }) do
            H:slash(cmd)
            T.ok(string.find(H:lastMsg(), "usage: /farol task", 1, true) or string.find(H:lastMsg(), "there is no task", 1, true), cmd)
        end
        T.eq(#H.env.FarolCharDB.tasks, 1)
        H:slash("task list"); T.has(all(H), "1. Fishing quest (daily): to do")
        H:update(1); T.has(H:bar(), "Tasks 0/1")
        H:slash("help"); T.has(all(H), "/farol task")
    end },
}
