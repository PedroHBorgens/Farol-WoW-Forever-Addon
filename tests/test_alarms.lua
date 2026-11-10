-- Alarmes: disparo, repetição a cada 30 s, soneca configurável, parar, dia seguinte, servidor, janela.
-- Alarms: trigger, 30 s repeat, configurable snooze, stop, next day, server time, window.

local function at(H, hour, minute) H.clock.hour, H.clock.min = hour, minute end

local function count(text)
    local n = 0
    for _ in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do n = n + 1 end
    return n
end

return {
    { "saved alarms are validated and names are cleaned", function(T, Mock)
        local H = Mock.new():login({ alarms = {
            { h = 7, m = 30, label = "Raid |cffff0000|Hitem:1|h[x]|h|r\n" .. string.rep("é", 50) },
            { h = 99, m = 1 }, "lixo", { h = 8, m = 0, server = true, enabled = false },
        } })
        local alarms = H.env.FarolDB.alarms
        T.eq(#alarms, 2, "invalid alarms dropped")
        T.hasnt(alarms[1].label, "|", "no escape codes")
        T.hasnt(alarms[1].label, "\n", "no control characters")
        T.ok(count(alarms[1].label) <= 30, "name limited to 30 characters")
        T.eq(alarms[2].enabled, false)
    end },

    { "rings at the set time and repeats every 30 seconds", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme add 07:30 Raide")
        H:update(1); T.eq(H.sounds, 0, "not yet")
        at(H, 7, 30); H:update(1); T.eq(H.sounds, 1, "rang")
        T.ok(H.env.FarolAlarmPopup:IsShown(), "popup shown")
        T.has(H:text(H.env.FarolAlarmPopup.text), "07:30 (Local) Raide")
        T.has(H:lastMsg(), "Alarme! 07:30 (Local) Raide — /farol soneca ou /farol parar")
        H:update(10); T.eq(H.sounds, 1, "no repeat before 30 s")
        H:update(21); T.eq(H.sounds, 2, "repeat after 30 s")
    end },

    { "snooze (button uses the configured time) and stop", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme add 07:30")
        H:update(1); at(H, 7, 30); H:update(1)
        T.eq(H:text(H.env.FarolAlarmPopup.snooze), "Soneca (5 min)")
        H:click(H.env.FarolAlarmPopup.snooze)
        T.ok(not H.env.FarolAlarmPopup:IsShown(), "popup hidden while snoozed")
        H:update(60); H:update(60); T.eq(H.sounds, 1, "silent while snoozed")
        at(H, 7, 35); H:update(60); H:update(60); H:update(60)
        T.eq(H.sounds, 2, "rings again after 5 min")
        H:slash("parar"); T.ok(not H.env.FarolAlarmPopup:IsShown())
        H:update(31); H:update(31); T.eq(H.sounds, 2, "stopped")
        at(H, 7, 30); H:update(60); T.eq(H.sounds, 3, "rings again the next day")
    end },

    { "snooze time is configurable and one-off snooze keeps the setting", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme soneca 10"); T.eq(H.env.FarolDB.snoozeMinutes, 10)
        H:slash("alarme soneca 0"); H:slash("alarme soneca 99"); T.eq(H.env.FarolDB.snoozeMinutes, 10)
        H:slash("alarme add 09:00")
        at(H, 8, 59); H:update(1); at(H, 9, 0); H:update(1); T.eq(H.sounds, 1)
        T.eq(H:text(H.env.FarolAlarmPopup.snooze), "Soneca (10 min)")
        H:click(H.env.FarolAlarmPopup.snooze)
        for _ = 1, 9 do H:update(60) end; T.eq(H.sounds, 1, "silent for 9 min")
        H:update(60); T.eq(H.sounds, 2, "rings at 10 min")
        H:slash("soneca 2"); H:update(60); T.eq(H.sounds, 2); H:update(60); T.eq(H.sounds, 3, "one-off 2 min")
        T.eq(H.env.FarolDB.snoozeMinutes, 10, "setting unchanged")
        H:slash("soneca 0"); T.has(H:lastMsg(), "tempo de soneca inválido")
    end },

    { "no false alarm in the same minute it is created", function(T, Mock)
        local H = Mock.new():login()
        at(H, 7, 30)
        H:slash("alarme add 07:30")
        H:update(1); H:update(1); T.eq(H.sounds, 0)
    end },

    { "server-time alarms use the game clock", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme add 21:06 servidor Guilda")
        T.eq(H.env.FarolDB.alarms[1].server, true)
        H:update(1)
        H.env.GetGameTime = function() return 21, 6 end
        H:update(1); T.eq(H.sounds, 1)
    end },

    { "server-time alarms wait (no error) while the game reports an invalid time", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme add 21:06 servidor")
        H:update(1)
        for _, bad in ipairs({ 0 / 0, math.huge, 21.1, -1, "21" }) do
            H.env.GetGameTime = function() return bad, 6 end
            H:update(1)
        end
        T.eq(H.sounds or 0, 0, "never fires on a bad time")
        H.env.GetGameTime = function() return 21, 6 end
        H:update(1); T.eq(H.sounds, 1, "fires once the time is valid")
    end },

    { "alarm commands: add, invalid time, list, enable/disable, remove, limit of 10", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme add 22:15 servidor Dormir")
        H:slash("alarme add 25:00"); T.has(H:lastMsg(), "horário inválido")
        H:slash("alarme add 6h05 Acordar cedo")
        local alarms = H.env.FarolDB.alarms
        T.eq(alarms[2].h, 6); T.eq(alarms[2].m, 5); T.eq(alarms[2].label, "Acordar cedo")
        H:slash("alarme desativar 1"); T.eq(alarms[1].enabled, false)
        H:slash("alarme remover 9"); T.has(H:lastMsg(), "número de alarme inválido")
        H.msgs = {}
        H:slash("alarme lista"); T.has(H.strip(table.concat(H.msgs, "/")), "1. 22:15 (Servidor) Dormir  OFF")
        for i = 1, 8 do H:slash("alarme add 01:0" .. i) end
        T.eq(#alarms, 10)
        H:slash("alarme add 02:00"); T.has(H:lastMsg(), "limite de 10 alarmes")
        H:slash("alarme remover 1"); T.eq(#alarms, 9)
    end },

    { "alarms window: add from the form (name cleaned) and set the snooze", function(T, Mock)
        local H = Mock.new():login()
        H:slash("alarme")
        local window = H.env.FarolAlarms
        T.ok(window:IsShown(), "window open")
        H.env.FarolAlarmHour._text = "23"
        H.env.FarolAlarmMinute._text = "59"
        H.env.FarolAlarmLabel._text = "Teste |T x|t"
        H:click(window.add)
        local alarm = H.env.FarolDB.alarms[1]
        T.eq(alarm.h, 23); T.eq(alarm.m, 59); T.eq(alarm.label, "Teste T xt")
        T.has(H:text(window.rows[1].text), "1. 23:59 (Local) Teste T xt")
        H.env.FarolAlarmSnoozeMinutes._text = "15"
        H.env.FarolAlarmSnoozeMinutes._scripts.OnEnterPressed(H.env.FarolAlarmSnoozeMinutes)
        T.eq(H.env.FarolDB.snoozeMinutes, 15)
        H.env.FarolAlarmSnoozeMinutes._text = "0"
        H.env.FarolAlarmSnoozeMinutes._scripts.OnEnterPressed(H.env.FarolAlarmSnoozeMinutes)
        T.eq(H.env.FarolDB.snoozeMinutes, 15, "invalid value rejected")
        T.eq(H.env.FarolAlarmSnoozeMinutes._text, "15", "box reverts to the saved value")
        H:click(window.rows[1].delete); T.eq(#H.env.FarolDB.alarms, 0)
    end },

    { "alarms keep working with the panel hidden", function(T, Mock)
        local H = Mock.new():login()
        H:slash("") -- esconde o painel
        T.ok(not H.env.FarolFrame:IsShown())
        H:slash("alarme add 07:30")
        H:update(1); at(H, 7, 30); H:update(1); T.eq(H.sounds, 1)
    end },
}
