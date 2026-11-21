-- Diário de missões: item da barra, tooltip (prontas, andamento, nível, "e mais N"), API moderna e antiga,
-- avisos de diário quase cheio e de missões prontas ao entrar numa cidade/estalagem, valores ruins.
-- Quest log: bar item, tooltip (ready, in progress, level, "and N more"), modern and old API,
-- "almost full" and "ready when entering a city/inn" warnings, bad values.

local function log(H, n, ready)
    H.quests = { { title = "Baía do Farol", header = true } }
    for i = 1, n do
        local q = { title = "Missão " .. i, level = 30 + (i % 4) }
        if i <= (ready or 0) then q.done = true else q.have, q.need = 1, 4 end
        H.quests[#H.quests + 1] = q
    end
end
local function setup(Mock, opts)
    local H = Mock.new(opts)
    H:login(); H.xp.level = 32
    H:slash("mostrar missoes"); H:update(1)
    return H
end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function count(text, pattern) return select(2, string.gsub(text, pattern, "")) end

return {
    { "off by default; count / max with colors and how many are ready", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Missões"); T.eq(H.env.FarolDB.items.quests, false)
        H = setup(Mock)
        T.has(H:bar(), "Missões 0/20")
        log(H, 12); H:update(1)
        T.has(H:barRaw(), "|cff40ff4012/20|r", "green with room")
        log(H, 17, 3); H:update(1)
        T.has(H:bar(), "Missões 17/20 · 3 prontas"); T.has(H:barRaw(), "|cffffff3a17/20|r", "yellow from max - 3")
        log(H, 20, 1); H:update(1)
        T.has(H:bar(), "Missões 20/20 · 1 pronta"); T.has(H:barRaw(), "|cffff666620/20|r", "red when full")
    end },

    { "tooltip: ready first, then in progress with objectives; level colors; and N more; high level", function(T, Mock)
        local H = setup(Mock)
        log(H, 9, 2)
        H.quests[5].failed, H.quests[5].have, H.quests[5].need, H.quests[5].level = true, nil, nil, 39
        H.quests[#H.quests + 1] = { title = "A Torre Alta", level = 40, have = 0, need = 1 }
        H.quests[#H.quests + 1] = { title = "Entrega antiga", level = 20 }
        H.quests[2].title = "Entrega|cffff0000 velha" -- pronta: aparece no topo
        H:update(1)
        local t = tip(H)
        T.has(t, "Missões — 11 / 20")
        T.has(t, "Prontas para entregar (2)"); T.has(t, "Em andamento (9)")
        T.ok(t:find("Prontas para entregar", 1, true) < t:find("Em andamento", 1, true), "ready list first")
        T.has(t, "[40] A Torre Alta = 0/1", "highest level first, with its objective")
        T.has(t, "= 1/4"); T.has(t, "= falhou")
        T.has(t, "… e mais 4")
        T.has(t, "2 missão(ões) bem acima do seu nível (37+)")
        T.hasnt(H.env.GameTooltip.lines[1] or "", "|Hitem")
        local raw = table.concat(H.env.GameTooltip.lines, "\n")
        T.has(raw, "|cffff1919[40]|r", "red: 5+ levels above")
        T.has(raw, "|cffffff00[33]|r", "yellow: around your level")
        T.has(t, "Entregacffff0000 velha", "'|' removed from quest titles")
    end },

    { "old client (3.3.5a): GetQuestLogTitle with the group in the 4th value, limit 25, text objectives", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk" })
        log(H, 6, 2)
        H.quests[2].collapsed = true; H.quests[1].collapsed = true
        H:update(1)
        T.has(H:bar(), "Missões 6/25 · 2 prontas")
        local t = tip(H)
        T.has(t, "Prontas para entregar (2)"); T.has(t, "= 1/4")
        T.has(t, "algumas categorias estão fechadas", "collapsed categories are mentioned, never opened")
        T.eq(H.clickedLink, nil)
    end },

    { "warning: almost full from N, again when full, re-arms after freeing space; command sets N", function(T, Mock)
        local H = setup(Mock)
        H:slash("aviso missoes on"); T.has(H:lastMsg(), "diário de missões quase cheio")
        log(H, 18); H:update(1); H:update(1)
        T.hasnt(all(H), "Diário de missões quase cheio:")
        log(H, 19); H:update(1); H:update(1)
        T.has(all(H), "Diário de missões quase cheio: 19/20.")
        local n = count(all(H), "quase cheio: 19/20")
        H:update(1); H:update(1)
        T.eq(count(all(H), "quase cheio: 19/20"), n, "once")
        log(H, 20); H:update(1); H:update(1)
        T.has(all(H), "Diário de missões cheio: 20/20!")
        log(H, 10); H:update(1)
        H:slash("aviso missoes 15"); T.has(H:lastMsg(), "a partir de 15 missões"); T.eq(H.env.FarolDB.warnings.questMin, 15)
        log(H, 16); H:update(1); H:update(1)
        T.hasnt(all(H), "quase cheio: 16/20", "waits 5 minutes between warnings, like the bags one")
        H:update(301); H:update(1)
        T.has(all(H), "Diário de missões quase cheio: 16/20.", "warns again after freeing space")
        H:slash("aviso missoes 0"); T.has(H:lastMsg(), "valor inválido"); T.eq(H.env.FarolDB.warnings.questMin, 15)
        H:slash("aviso missoes 101"); T.has(H:lastMsg(), "valor inválido")
    end },

    { "warning: ready quests when entering a city or inn, at most every 5 minutes", function(T, Mock)
        local H = setup(Mock)
        H:slash("aviso prontas on")
        log(H, 8, 3); H.resting = false; H:update(1); H:update(1)
        T.hasnt(all(H), "prontas para entregar.")
        H.resting = true; H:update(1); H:update(1)
        T.has(all(H), "Você tem 3 missões prontas para entregar.")
        local n = count(all(H), "prontas para entregar%.")
        H.resting = false; H:update(1); H.resting = true; H:update(1); H:update(1)
        T.eq(count(all(H), "prontas para entregar%."), n, "not again within 5 minutes")
        H.resting = false; H:update(1); H:update(301); H.resting = true; H:update(1); H:update(1)
        T.eq(count(all(H), "prontas para entregar%."), n + 1, "again after 5 minutes")
        log(H, 8, 0); H.resting = false; H:update(1); H:update(301); H.resting = true; H:update(1); H:update(1)
        T.eq(count(all(H), "prontas para entregar%."), n + 1, "nothing ready: no warning")
        log(H, 8, 1); H.resting = false; H:update(1); H:update(301); H.resting = true; H:update(1); H:update(1)
        T.has(all(H), "Você tem 1 missão pronta para entregar.")
    end },

    { "blocked values and errors show -- and never break the bar or the warnings", function(T, Mock)
        local H = setup(Mock, { mode = "secret" })
        H:slash("aviso missoes on"); H:slash("aviso prontas on")
        log(H, 19, 2)
        H.env.C_QuestLog.GetNumQuestLogEntries = function() return 0 / 0 end
        H:update(1); H:update(1)
        T.has(H:bar(), "Missões --"); tip(H)
        H.env.C_QuestLog.GetNumQuestLogEntries = function() error("bloqueado") end
        H.env.IsResting = function() error("bloqueado") end
        H:update(1); H:update(1); T.has(H:bar(), "Missões --")
        H.env.C_QuestLog.GetNumQuestLogEntries = function() return 3, 3 end
        H.env.C_QuestLog.GetInfo = function() return { title = {}, level = 1 / 0, questID = "x" } end
        H.env.C_QuestLog.GetMaxNumQuestsCanAccept = function() return -1 end
        H:update(1); T.has(H:bar(), "Missões 3/20"); tip(H)
        H.env.C_QuestLog = nil; H.env.GetNumQuestLogEntries = nil
        H:update(1); T.has(H:bar(), "Missões --")
        H:slash("aviso status"); T.has(all(H), "missões: --")
        H.env.UnitLevel = function() error("bloqueado") end -- o diagnóstico lia o nível sem proteção
        local ok, err = pcall(H.slash, H, "aviso status"); T.ok(ok, tostring(err)); T.has(all(H), "UnitLevel: --")
    end },

    { "saved warning settings are validated", function(T, Mock)
        for _, bad in ipairs({ 0, 101, 0 / 0, 1 / 0, "19", 18.5, {} }) do
            local H = Mock.new():login({ warnings = { questMin = bad, questFull = "yes", questReady = 1 } })
            T.eq(H.env.FarolDB.warnings.questMin, 19); T.eq(H.env.FarolDB.warnings.questFull, false)
            T.eq(H.env.FarolDB.warnings.questReady, false)
        end
        local H = Mock.new():login({ warnings = { questMin = 12, questFull = true } })
        T.eq(H.env.FarolDB.warnings.questMin, 12); T.eq(H.env.FarolDB.warnings.questFull, true)
    end },

    { "English and the Warnings tab controls", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        log(H, 17, 1); H:update(1)
        T.has(H:bar(), "Quests 17/20 · 1 ready"); T.has(tip(H), "Ready to turn in (1)")
        H:slash("menu")
        T.eq(H:text(H.env.FarolWarnQuestFull.label), "Quest log from")
        T.eq(H.env.FarolWarnQuestMin._text, "19")
        H:check(H.env.FarolWarnQuestReady, true); T.eq(H.env.FarolDB.warnings.questReady, true)
        T.eq(H.env.FarolPanelWarnQuestReady._checked, true, "settings panel synced")
    end },
}
