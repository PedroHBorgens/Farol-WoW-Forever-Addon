-- Registro de masmorras e raides: barra durante a corrida, resumo ao sair, histórico de 10, /reload, jogo fechado
-- lá dentro, janela, comandos e dados adulterados.
-- Dungeon and raid runs: bar during the run, summary when leaving, last-10 history, /reload, logging out inside,
-- window, commands and tampered data.

local BASE = 1800000000

local function setup(Mock, opts, savedChar, saved, before)
    local H = Mock.new(opts)
    H.clockNow = BASE
    H.instanceName = "Ember Depths"
    if before then before(H) end
    H.env.time = function(t) if t then return os.time(t) end return H.clockNow end
    H.env.GetInstanceInfo = function() return H.instanceName, H.instanceType end
    H:login(saved, savedChar)
    H:slash("mostrar masmorra")
    return H
end
local function tick(H, seconds) for _ = 1, seconds do H.clockNow = H.clockNow + 1; H:update(1) end end
local function enter(H, kind, name) H.instanceType = kind or "party"; if name then H.instanceName = name end; H:event("PLAYER_ENTERING_WORLD") end
local function leave(H) H.instanceType = nil; H:event("PLAYER_ENTERING_WORLD") end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function runs(H) return H.env.FarolCharDB.runs end

return {
    { "off by default; hidden outside instances; a run starts when you enter a dungeon", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.eq(H.env.FarolDB.items.run, false); T.eq(H.env.FarolDB.runSummary, true)
        H = setup(Mock); tick(H, 2)
        T.hasnt(H:bar(), "Ember Depths", "nothing outside")
        enter(H); tick(H, 125)
        T.has(H:bar(), "Ember Depths 2m · +0 XP · +0s")
        T.eq(runs(H).cur.n, "Ember Depths"); T.eq(runs(H).cur.k, "party")
    end },

    { "XP, gold, loot (rares/epics) and deaths count; leaving prints the summary and saves the run", function(T, Mock)
        local H = setup(Mock)
        enter(H); tick(H, 2)
        H.xp.cur = H.xp.cur + 1500; H:event("PLAYER_XP_UPDATE")
        H.money = 1234567 + 125000
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff0070dd|Hitem:4|h[Anel Azul]|h|r.")
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cffa335ee|Hitem:5|h[Elmo Roxo]|h|r.")
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cnIQ1:|Hitem:6::::|h[Tecido]|h|rx5.")
        H:event("CHAT_MSG_LOOT", "Fulano recebe saque: |cffa335ee|Hitem:9|h[Do outro]|h|r.")
        H:event("PLAYER_DEAD")
        tick(H, 600)
        T.has(H:bar(), "+1.5k XP · +12g 50s")
        H.env.GameTooltip.lines = {}; H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        local tip = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(tip, "Instância = Ember Depths (masmorra)"); T.has(tip, "Saques = 3 (1 raro, 1 épico)"); T.has(tip, "Mortes = 1")
        leave(H); tick(H, 1)
        T.has(all(H), "saiu de Ember Depths (masmorra): 10m")
        T.has(all(H), "XP: +1.5k · Ouro: +12g 50s · Saques: 3 (1 raro, 1 épico) · Mortes: 1")
        local r = runs(H).list[1]
        T.eq(r.x, 1500); T.eq(r.g, 125000); T.eq(r.l, 3); T.eq(r.r, 1); T.eq(r.e, 1); T.eq(r.d, 1)
        T.eq(runs(H).cur, nil); T.hasnt(H:bar(), "Ember Depths")
    end },

    { "short visits are not saved; zone changes inside keep the run; another instance starts a new one", function(T, Mock)
        local H = setup(Mock)
        enter(H); tick(H, 30); leave(H); tick(H, 1)
        T.eq(#runs(H).list, 0, "under 1 minute: not saved"); T.hasnt(all(H), "saiu de")
        enter(H); tick(H, 90); H:event("ZONE_CHANGED_NEW_AREA"); tick(H, 90)
        T.eq(runs(H).cur.t, BASE + 31, "same run after a zone change inside")
        enter(H, "raid", "Sunken Vault"); tick(H, 2)
        T.eq(#runs(H).list, 1); T.eq(runs(H).list[1].n, "Ember Depths"); T.eq(runs(H).cur.n, "Sunken Vault"); T.eq(runs(H).cur.k, "raid")
        T.has(all(H), "saiu de Ember Depths (masmorra)")
    end },

    { "/reload inside keeps the run without counting XP twice; logging out for long closes it", function(T, Mock)
        local H = setup(Mock)
        enter(H); tick(H, 120)
        H.xp.cur = H.xp.cur + 1000; H:event("PLAYER_XP_UPDATE"); tick(H, 2)
        H:event("PLAYER_LOGOUT")
        local char = H.env.FarolCharDB
        local R = setup(Mock, nil, { runs = char.runs }, nil, function(X) X.clockNow = H.clockNow + 5; X.instanceType = "party" end); tick(R, 2)
        T.eq(R.env.FarolCharDB.runs.cur.t, char.runs.cur.t, "same run after /reload"); T.eq(R.env.FarolCharDB.runs.cur.x, 1000, "XP not counted twice")
        R.xp.cur = R.xp.cur + 500; R:event("PLAYER_XP_UPDATE"); tick(R, 2)
        T.eq(R.env.FarolCharDB.runs.cur.x, 1500)
        R:event("PLAYER_LOGOUT")
        local L = setup(Mock, nil, { runs = R.env.FarolCharDB.runs }, nil, function(X) X.clockNow = R.clockNow + 3600 end); tick(L, 1)
        T.eq(L.env.FarolCharDB.runs.cur, nil, "closed after a long time away")
        local saved = L.env.FarolCharDB.runs.list[1]
        T.eq(saved.n, "Ember Depths"); T.ok(saved.s >= 120 and saved.s < 200, "ended at the last moment seen")
    end },

    { "window: newest first, max 10, summary checkbox, clear needs two clicks", function(T, Mock)
        local H = setup(Mock)
        for i = 1, 12 do enter(H, "party", "Masmorra " .. i); tick(H, 61) end
        leave(H); tick(H, 1)
        T.eq(#runs(H).list, 10); T.eq(runs(H).list[10].n, "Masmorra 12"); T.eq(runs(H).list[1].n, "Masmorra 3")
        H:slash("masmorra")
        local W = H.env.FarolRuns
        T.ok(W:IsShown()); T.eq(H:text(W.rows[1][2]), "Masmorra 12"); T.eq(H:text(W.rows[10][2]), "Masmorra 3")
        H:check(H.env.FarolRunsSummary, false); T.eq(H.env.FarolDB.runSummary, false)
        enter(H, "party", "Silenciosa"); tick(H, 61); leave(H); tick(H, 1)
        T.hasnt(all(H), "saiu de Silenciosa", "summary off")
        H:click(H.env.FarolRunsClear); T.eq(#runs(H).list, 10, "first click only asks")
        H:click(H.env.FarolRunsClear); T.eq(#runs(H).list, 0)
    end },

    { "tampered saved runs fall back safely", function(T, Mock)
        local list = { 5, { n = "Ok", k = "party", t = BASE - 1000, s = 600, x = 0 / 0, g = 1 / 0, l = -3, d = 2 },
                       { n = "Bad|Name", k = "raid", t = BASE, s = 100 }, { n = "", k = "party", t = BASE, s = 100 },
                       { n = "Kind", k = "pvp", t = BASE, s = 100 }, { n = "Short", k = "party", t = BASE, s = 10 } }
        for i = 1, 15 do list[#list + 1] = { n = "R" .. i, k = "raid", t = BASE - i, s = 120 } end
        local H = setup(Mock, nil, { runs = { list = list, cur = { n = "X", k = "party", t = "x" } } })
        local r = runs(H)
        T.eq(#r.list, 10); T.eq(r.cur, nil)
        for _, run in ipairs(r.list) do
            T.ok(type(run.n) == "string" and not run.n:find("[|%c]") and #run.n > 0, "clean name")
            T.ok(run.s >= 60 and run.x >= 0 and run.l >= 0, "valid numbers")
        end
        local B = setup(Mock, nil, { runs = "x" }); T.eq(#runs(B).list, 0)
    end },

    { "commands, English, and blocked names fall back to 'Instance'", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        for _, cmd in ipairs({ "dungeon fly", "dungeon summary maybe", "dungeon clear now" }) do
            H:slash(cmd); T.has(H:lastMsg(), "usage: /farol dungeon", cmd)
        end
        H:slash("dungeon summary off"); T.eq(H.env.FarolDB.runSummary, false); H:slash("dungeon summary on")
        H.instanceName = nil; enter(H, "raid"); tick(H, 61); leave(H); tick(H, 1)
        T.has(all(H), "left Instance (raid): 1m")
        H:slash("help"); T.has(all(H), "/farol dungeon")
    end },
}
