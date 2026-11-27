-- Endurecimento (3.13.2, auditoria de segurança): dados salvos adulterados e enormes não podem travar o jogo ao
-- entrar. Listas longas ficam com os N mais recentes em tempo linear (ns.KeepLast); nomes com milhares de espaços
-- são aparados em tempo linear (ns.Trim).
-- Hardening (3.13.2, security audit): huge tampered saved data must not freeze the game at login.

local BIG = 50000 -- com o código antigo (table.remove(lista, 1) em laço), isto levava dezenas de segundos

local function timed(fn)
    local t0 = os.clock(); fn(); return os.clock() - t0
end

return {
    { "ns.KeepLast keeps the last N valid items, in order, skipping bad ones", function(T, Mock)
        local H = Mock.new():login()
        local keep = H.ns.KeepLast
        local list = { 1, "x", 2, 3, "y", 4, 5 }
        local out = keep(list, 3, function(v) return type(v) == "number" and v * 10 or nil end)
        T.eq(table.concat(out, ","), "30,40,50")
        T.eq(#keep({}, 5, function(v) return v end), 0)
        T.eq(#keep("nope", 5, function(v) return v end), 0)
        T.eq(table.concat(keep({ 1, 2 }, 10, function(v) return v end), ","), "1,2")
    end },

    { "ns.Trim trims spaces in linear time and cuts very long text", function(T, Mock)
        local H = Mock.new():login()
        local trim = H.ns.Trim
        T.eq(trim("  Pesca diária  "), "Pesca diária"); T.eq(trim("     "), ""); T.eq(trim(nil), ""); T.eq(trim("a"), "a")
        T.eq(trim(" a b "), "a b")
        local huge = string.rep(" ", 200000) .. "a" .. string.rep(" ", 200000) .. "b"
        local secs = timed(function() T.eq(trim(huge), "") end)
        T.ok(secs < 2, "huge text trimmed quickly (" .. secs .. " s)")
        T.ok(#trim(string.rep("x", 5000)) <= 1024, "cut to 1024 bytes")
    end },

    { "huge tampered histories load fast and keep only the most recent entries", function(T, Mock)
        local items, hist, runs = {}, {}, { list = {} }
        for i = 1, BIG do
            items[i] = { link = "|cff1eff00|Hitem:" .. i .. "|h[Erva " .. i .. "]|h|r", count = 1, t = 1 }
            hist[i] = { t = 1700000000 + i, text = "aviso " .. i }
            runs.list[i] = { n = "Cripta " .. i, k = "party", t = 1700000000 + i, s = 600 }
        end
        local H
        local secs = timed(function() H = Mock.new():login(nil, { items = items, warnHistory = hist, runs = runs }) end)
        T.ok(secs < 3, "login with huge tampered data took " .. secs .. " s")
        local db = H.env.FarolCharDB
        T.eq(#db.items, 100); T.has(db.items[100].link, "Erva " .. BIG); T.has(db.items[1].link, "Erva " .. (BIG - 99))
        T.eq(#db.warnHistory, 10); T.eq(db.warnHistory[10].text, "aviso " .. BIG)
        T.eq(#db.runs.list, 10); T.eq(db.runs.list[10].n, "Cripta " .. BIG)
    end },

    { "names with huge runs of spaces load fast (tasks, alarms, farm)", function(T, Mock)
        local big = string.rep(" ", 200000) .. "a" .. string.rep(" ", 200000) .. "b"
        local H
        local secs = timed(function()
            H = Mock.new():login({ alarms = { { h = 7, m = 30, label = big } } },
                { tasks = { { n = big }, { n = "  Pesca  " } }, farm = { { id = 1, n = big, c = 5 } } })
        end)
        T.ok(secs < 3, "login took " .. secs .. " s")
        T.eq(H.env.FarolCharDB.tasks[#H.env.FarolCharDB.tasks].n, "Pesca")
    end },

    { "the quadratic trim pattern is not used on saved text", function(T)
        for _, file in ipairs({ "Core.lua", "Alarm.lua", "Loot.lua", "Warnings.lua", "Tasks.lua", "Notes.lua", "Goals.lua", "Farm.lua", "Keep.lua",
                                "Quests.lua", "Hearth.lua", "Runs.lua", "Combat.lua", "Completed.lua", "Sources.lua", "Diag.lua", "Hub.lua", "MinimapButton.lua", "Appearance.lua", "Order.lua" }) do
            local f = io.open("Farol/" .. file, "r"); local code = f:read("*a"); f:close()
            code = string.gsub(code, "%-%-[^\n]*", "") -- comentários podem citar o padrão
            T.ok(not code:find('"^%s*(.-)%s*$"', 1, true), file .. ": use ns.Trim instead of \"^%s*(.-)%s*$\"")
        end
    end },
}
