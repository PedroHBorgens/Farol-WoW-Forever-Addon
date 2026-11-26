-- Quanto valem as missões prontas (3.23): XP e ouro da recompensa (GetQuestLogRewardXP/Money pelo ID), a soma das
-- prontas na barra e no tooltip, "nível X → Y" e o aviso opcional. Tudo desligado por padrão; só leitura.
-- Ready quests value: reward XP/gold, totals on the bar and tooltip, level-up line and optional warning.

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function count(text, pattern) return select(2, string.gsub(text, pattern, "")) end

-- Nível 30, 6200/10000 de XP (faltam 3800). Prontas: 2500 + 1500 XP (+18s); em andamento: 900 XP.
local function setup(Mock, warnings, opts)
    local H = Mock.new(opts or { locale = "ptBR" })
    H:login({ warnings = warnings })
    H.quests = { { title = "Porto", header = true },
                 { title = "Ladrões no porto", level = 30, done = true, xp = 1500, money = 1800 },
                 { title = "Emboscada", level = 29, done = true, xp = 2500 },
                 { title = "Mina", level = 31, have = 1, need = 4, xp = 900 } }
    H:slash("mostrar missoes"); H:update(1)
    return H
end

return {
    { "off by default: nothing about rewards on the bar or in the tooltip", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.env.FarolDB.warnings.questValue, false); T.eq(H.env.FarolDB.warnings.questLevel, false)
        T.hasnt(H:bar(), "XP)"); T.hasnt(tip(H), "Valor das prontas"); T.hasnt(tip(H), "Entregando todas")
    end },

    { "on: bar total, tooltip sum, per-quest rewards (most XP first), level-up line and in-progress XP", function(T, Mock)
        local H = setup(Mock, { questValue = true })
        T.has(H:bar(), "Missões 3/20 · 2 prontas (+4.0k XP)")
        local text = tip(H)
        T.has(text, "Valor das prontas = +4.0k XP · +0g 18s 0c")
        T.has(text, "Entregando todas: nível 30 → 31 (sobram 200 XP)")
        local a, b = string.find(text, "Emboscada", 1, true), string.find(text, "Ladrões no porto", 1, true)
        T.ok(a and b and a < b, "the one with more XP first")
        T.has(text, "Emboscada = +2.5k XP"); T.has(text, "Ladrões no porto = +1.5k XP · +0g 18s 0c")
        T.has(text, "Em andamento: +900 XP ao concluir")
        -- Não chega ao próximo nível: quanto falta.
        H.quests[3].xp = 1000; H:update(1)
        T.has(tip(H), "Entregando todas: faltam 1.3k XP para o nível 31")
        -- Nível máximo: nada de "sobe de nível".
        H.xp.level = 60; H:update(1)
        T.hasnt(tip(H), "Entregando todas"); T.has(tip(H), "Valor das prontas")
    end },

    { "level-up warning: once per level, again on the next level; off by default", function(T, Mock)
        local H = setup(Mock, { questLevel = true })
        H:update(5)
        T.has(all(H), "Entregue as 2 missões prontas: você sobe para o nível 31.")
        local n = count(all(H), "você sobe para o nível")
        H:update(60); H:update(60)
        T.eq(count(all(H), "você sobe para o nível"), n, "only once for this level")
        H.xp.level, H.xp.cur = 31, 9000; H:update(5)
        T.has(all(H), "você sobe para o nível 32.")
        local Q = setup(Mock); Q:update(30); T.hasnt(all(Q), "você sobe para o nível")
        local U = Mock.new({ locale = "ptBR" }); U:login({ items = { fps = true }, newsSeen = #Q.ns.NEWS - 4 })
        T.has(all(U), "missões prontas: quanto XP e ouro vão dar e se entregar todas sobe você de nível (barra e tooltip) — desligado (ligue em Menu > Avisos)")
    end },

    { "menu checkboxes (Warnings tab) and English texts", function(T, Mock)
        local H = setup(Mock, nil, { locale = "enUS" })
        H:slash("menu")
        T.eq(H:text(H.env.FarolWarnQuestValue.label), "XP and gold of ready ones")
        T.eq(H:text(H.env.FarolWarnQuestLevel.label), "Ready ones level you up")
        H:check(H.env.FarolWarnQuestValue, true); H:update(1)
        T.eq(H.env.FarolDB.warnings.questValue, true)
        T.has(H:bar(), "(+4.0k XP)"); T.has(tip(H), "Value of the ready ones = +4.0k XP")
        T.has(tip(H), "Turning them all in: level 30 → 31 (200 XP left over)")
        H:check(H.env.FarolWarnQuestLevel, true); H:update(5)
        T.has(all(H), "Turn in the 2 ready quests: you reach level 31.")
    end },

    { "broken or strange reward values are ignored; old clients show nothing; saved values validated", function(T, Mock)
        local H = setup(Mock, { questValue = true, questLevel = true })
        H.env.GetQuestLogRewardXP = function(id) if id == 1002 then error("no") end return 0 / 0 end
        H.env.GetQuestLogRewardMoney = function() return 1 / 0 end
        H:update(5); tip(H)
        T.hasnt(H:bar(), "XP)"); T.hasnt(tip(H), "Valor das prontas")
        local S = Mock.new({ mode = "secret" }); S:login({ warnings = { questValue = true, questLevel = true } })
        S:slash("mostrar missoes"); S:update(5); tip(S)
        local W = Mock.new({ mode = "wotlk" }); W:login({ warnings = { questValue = true } })
        W.quests = { { title = "A", level = 30, done = true } }; W:slash("mostrar missoes"); W:update(1)
        T.hasnt(W:bar(), "XP)")
        for _, bad in ipairs({ "sim", 1, {}, 0 / 0 }) do
            local B = Mock.new():login({ warnings = { questValue = bad, questLevel = bad } })
            T.eq(B.env.FarolDB.warnings.questValue, false); T.eq(B.env.FarolDB.warnings.questLevel, false)
        end
    end },
}
