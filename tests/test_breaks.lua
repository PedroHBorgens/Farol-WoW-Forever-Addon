-- Lembretes de pausa e de beber água: desligados por padrão, intervalo escolhido, espera em lutas/masmorras.
-- Break and drink-water reminders: off by default, chosen interval, wait during fights/dungeons.

local function fixGear(H) -- tira a durabilidade baixa padrão do simulador, para isolar os testes
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function setup(Mock, warnings, opts)
    local H = Mock.new(opts):login({ warnings = warnings }); fixGear(H)
    H:update(1)
    return H
end

local function minutes(H, n) for _ = 1, n do H:update(60) end end
local function popup(H) return H.env.FarolWarnPopup end

return {
    { "both reminders are off by default", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.env.FarolDB.warnings.pause, false); T.eq(H.env.FarolDB.warnings.water, false)
        T.eq(H.env.FarolDB.warnings.pauseMin, 120); T.eq(H.env.FarolDB.warnings.waterMin, 45)
        minutes(H, 300)
        T.eq(H.warnSounds, 0, "nothing in 5 hours")
    end },

    { "break reminder: every N minutes, with the time played", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 60 })
        minutes(H, 59); T.eq(H.warnSounds, 0, "not before 60 min")
        minutes(H, 1)
        T.eq(H.warnSounds, 1)
        T.has(H:text(popup(H).text), "Você está jogando há 1h 00m — que tal uma pausa?")
        T.has(H.strip(table.concat(H.msgs, "\n")), "que tal uma pausa?", "also in your own chat")
        T.has(H.env.FarolCharDB.warnHistory[#H.env.FarolCharDB.warnHistory].text, "que tal uma pausa", "in the history")
        H:click(H.env.FarolWarnSilence)
        minutes(H, 300); T.eq(H.warnSounds, 1, "silenced until the end of the session")
        T.has(H:lastMsg(), "até o fim da sessão")
    end },

    { "water reminder repeats at its own interval; both together share one window", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 60, water = true, waterMin = 30 }, { locale = "enUS" })
        minutes(H, 30)
        T.has(H:text(popup(H).text), "Time to drink some water!")
        H:click(H.env.FarolWarnRemind)               -- "Remind in 30 min" (padrão)
        minutes(H, 30)
        T.eq(H:text(popup(H).title), "Warnings (2)", "break and water at minute 60")
        T.eq(H:text(H.env.FarolWarnSilence), "Silence all")
    end },

    { "by default they wait for fights and dungeons to end; the option shows them anyway", function(T, Mock)
        local H = setup(Mock, { water = true, waterMin = 15 })
        H.inCombat = true
        minutes(H, 20); T.eq(H.warnSounds, 0, "waits during combat")
        H.inCombat = false; H.instanceType = "raid"
        minutes(H, 5); T.eq(H.warnSounds, 0, "waits inside a raid")
        H.instanceType = nil; H:update(1)
        T.eq(H.warnSounds, 1, "shows as soon as you leave")
        H:click(H.env.FarolWarnSilence)

        local A = setup(Mock, { water = true, waterMin = 15, waterAnywhere = true })
        A.inCombat = true; A.instanceType = "party"
        minutes(A, 15); T.eq(A.warnSounds, 1, "shown during fights and dungeons when the option is on")
    end },

    { "remind uses the chosen time and replaces the next reminder", function(T, Mock)
        local H = setup(Mock, { pause = true, pauseMin = 120 })
        minutes(H, 120); T.eq(H.warnSounds, 1)
        H:click(H.env.FarolWarnRemindTime); H:click(H.env.FarolWarnRemindTimeEntry3) -- 10 min
        H:click(H.env.FarolWarnRemind)
        minutes(H, 9); T.eq(H.warnSounds, 1)
        minutes(H, 1); T.eq(H.warnSounds, 2, "back after 10 min")
        H:click(H.env.FarolWarnSilence)
    end },

    { "options: window, commands, interval limits and restart of the count", function(T, Mock)
        local H = setup(Mock)
        H:slash("aviso")
        T.eq(H:text(H.env.FarolWarnPause.label), "Lembrete de pausa a cada")
        T.eq(H:text(H.env.FarolWarnWater.label), "Lembrete de beber água a cada")
        T.eq(H:text(H.env.FarolWarnPauseAnywhere.label), "Também em lutas, raides e masmorras")
        T.eq(H:text(H.env.FarolWarnPauseMin), "120"); T.eq(H:text(H.env.FarolWarnWaterMin), "45")
        T.eq(H:text(H.env.FarolWarnRemindDefault), "30 min")
        H:check(H.env.FarolWarnWater, true); T.eq(H.env.FarolDB.warnings.water, true)
        H:check(H.env.FarolWarnWaterAnywhere, true); T.eq(H.env.FarolDB.warnings.waterAnywhere, true)
        H:slash("aviso agua 20"); T.eq(H.env.FarolDB.warnings.waterMin, 20)
        H:slash("aviso agua 14"); T.has(H:lastMsg(), "use de 15 a 240"); T.eq(H.env.FarolDB.warnings.waterMin, 20)
        H:slash("aviso agua 241"); T.eq(H.env.FarolDB.warnings.waterMin, 20)
        H:slash("aviso pausa on"); H:slash("aviso pausa 15"); H:slash("aviso pausa lutas on")
        T.eq(H.env.FarolDB.warnings.pause, true); T.eq(H.env.FarolDB.warnings.pauseMin, 15)
        T.eq(H.env.FarolDB.warnings.pauseAnywhere, true)
        H:slash("aviso agua lutas off"); T.eq(H.env.FarolDB.warnings.waterAnywhere, false)
        H:slash("aviso pausa off")
        minutes(H, 10); H:slash("aviso agua 30")          -- mudar o intervalo recomeça a contagem
        minutes(H, 29); T.eq(H.warnSounds, 0, "not 20 min after the start: the count restarted")
        minutes(H, 1); T.eq(H.warnSounds, 1, "30 min after the change")
        T.has(H:text(popup(H).text), "Hora de beber água!")
        H:click(H.env.FarolWarnRemindDefault); H:click(H.env.FarolWarnRemindDefaultEntry1)
        T.eq(H.env.FarolDB.warnings.remindMin, 2, "default remind time from the window")
    end },

    { "tampered settings fall back to safe values", function(T, Mock)
        local H = setup(Mock, { pause = "sim", pauseMin = 5, water = 1, waterMin = 0 / 0, pauseAnywhere = "x",
                                waterAnywhere = {}, remindMin = math.huge })
        local w = H.env.FarolDB.warnings
        T.eq(w.pause, false); T.eq(w.pauseMin, 120); T.eq(w.water, false); T.eq(w.waterMin, 45)
        T.eq(w.pauseAnywhere, false); T.eq(w.waterAnywhere, false); T.eq(w.remindMin, 30)
        local B = setup(Mock, { pauseMin = 240.5, waterMin = 1e309 })
        T.eq(B.env.FarolDB.warnings.pauseMin, 120); T.eq(B.env.FarolDB.warnings.waterMin, 45)
    end },
}
