-- Metas de farm (itens): comando com link ou nome, barra, tooltip com ritmo, aviso único, janela de Metas,
-- botão "+ Meta" dos saques, limites e dados adulterados.
-- Farm goals (items): command with link or name, bar, tooltip with pace, one-time warning, Goals window,
-- "+ Goal" button in the loot window, limits and tampered data.

local SILK = "|cffffffff|Hitem:4306::::::::60:::::|h[Tecido de Seda]|h|r"
local function setup(Mock, opts, savedChar)
    local H = Mock.new(opts)
    H.items[4306] = { "Tecido de Seda", 1, 150 }
    H.items[2772] = { "Minério de Ferro", 1, 200 }
    H.itemCounts[4306] = 27
    H:login(nil, savedChar)
    H:slash("mostrar farm"); H:update(1)
    return H
end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "off by default; no goal shows --; a link adds the item with its count", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.hasnt(H:bar(), "Farm"); T.eq(H.env.FarolDB.items.farm, false)
        H = setup(Mock)
        T.has(H:bar(), "Farm --")
        H:slash("meta item " .. SILK .. " 40"); H:update(1)
        T.has(H:lastMsg(), "meta de farm: Tecido de Seda 27/40")
        local saved = H.env.FarolCharDB.farm[1]
        T.eq(saved.id, 4306); T.eq(saved.c, 40); T.eq(saved.n, "Tecido de Seda")
        T.has(H:bar(), "Tecido de Seda 27/40")
        T.has(H:barRaw(), "|cffffff3a27/40|r", "yellow while in progress")
        T.has(tip(H), "Tecido de Seda = 27/40"); T.has(tip(H), "sem ritmo ainda nesta sessão")
    end },

    { "pace per hour and estimate from what was gathered this session", function(T, Mock)
        local H = setup(Mock)
        H:slash("farm " .. SILK .. " 40")
        for _ = 1, 10 do H.itemCounts[4306] = H.itemCounts[4306] + 1; H:update(60) end -- +10 em 10 min = 60/h
        local t = tip(H)
        T.has(t, "Tecido de Seda = 37/40")
        T.has(t, "+10 nesta sessão (~60/h) · faltam ~3m")
        H.itemCounts[4306] = 20; H:update(1) -- usou/vendeu: recomeça a contar a sessão daqui
        T.has(tip(H), "sem ritmo ainda nesta sessão")
    end },

    { "by name: found in the bags or in the loot history; unknown names are refused", function(T, Mock)
        local H = setup(Mock)
        H.itemCounts[9010] = 5
        H:slash("meta item Pão de Centeio 20")
        T.has(H:lastMsg(), "meta de farm: Pão de Centeio 5/20"); T.eq(H.env.FarolCharDB.farm[1].id, 9010)
        H:slash("meta item [pão de centeio] 25") -- colchetes e maiúsculas não importam; muda a meta
        T.has(H:lastMsg(), "meta de farm: Pão de Centeio agora é 25"); T.eq(#H.env.FarolCharDB.farm, 1)
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cffffffff|Hitem:2772::::|h[Minério de Ferro]|h|rx2.")
        H:slash("meta item Minério de Ferro 20")
        T.eq(H.env.FarolCharDB.farm[2].id, 2772, "found through the loot history")
        H:slash("meta item Coisa Que Não Existe 5")
        T.has(H:lastMsg(), "item não encontrado"); T.eq(#H.env.FarolCharDB.farm, 2)
    end },

    { "several goals: bar shows done/total; completion warns once and goes to the history", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta aviso on")
        H:slash("meta item " .. SILK .. " 40")
        H.itemCounts[2772] = 3
        H:slash("meta item |cffffffff|Hitem:2772::::|h[Minério de Ferro]|h|r 20"); H:update(1)
        T.has(H:bar(), "Farm 0/2")
        T.has(tip(H), "Minério de Ferro = 3/20"); T.has(H.strip(tip(H)), "conta bolsas + banco")
        H.itemCounts[2772] = 20; H:update(2); H:update(2)
        T.has(H:bar(), "Farm 1/2")
        T.has(all(H), "meta alcançada: Minério de Ferro 20/20!")
        local count = select(2, string.gsub(all(H), "Minério de Ferro 20/20", ""))
        H:update(5); H:update(5)
        T.eq(select(2, string.gsub(all(H), "Minério de Ferro 20/20", "")), count, "only once")
        T.eq(H.env.FarolCharDB.farm[2].w, true, "remembered across sessions")
        H:slash("meta item remover minério de ferro")
        T.has(H:lastMsg(), "meta de farm apagada: Minério de Ferro"); T.has(H:bar(), "Tecido de Seda 27/40")
        H:slash("meta item remover 9"); T.has(H:lastMsg(), "nenhuma meta de farm")
        H:slash("farm limpar"); T.eq(#H.env.FarolCharDB.farm, 0); T.has(H:bar(), "Farm --")
    end },

    { "limits: amount 1..100000, at most 10 items, usage for bad input", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta item " .. SILK .. " 0"); T.has(H:lastMsg(), "quantidade inválida")
        H:slash("meta item " .. SILK .. " 100001"); T.has(H:lastMsg(), "quantidade inválida")
        H:slash("meta item " .. SILK); T.has(H:lastMsg(), "uso: /farol meta item")
        for id = 1, 10 do
            H:slash("meta item |cffffffff|Hitem:" .. (5000 + id) .. "::::|h[Item " .. id .. "]|h|r 5")
        end
        T.eq(#H.env.FarolCharDB.farm, 10)
        H:slash("meta item " .. SILK .. " 40"); T.has(H:lastMsg(), "no máximo 10 itens"); T.eq(#H.env.FarolCharDB.farm, 10)
        H:slash("meta item"); T.has(all(H), "metas de farm:"); T.has(H:lastMsg(), "uso: /farol meta item")
    end },

    { "loot window '+ Goal' button tracks the item with 20 and does not change an existing goal", function(T, Mock)
        local H = setup(Mock)
        H:event("CHAT_MSG_LOOT", "Você recebe saque: " .. SILK .. "x3.")
        H:slash("saque")
        local button = H.env.FarolLootTrack1
        T.ok(button and button:IsShown(), "button on the row"); T.eq(H:text(button), "+ Meta")
        H:click(button)
        T.eq(H.env.FarolCharDB.farm[1].id, 4306); T.eq(H.env.FarolCharDB.farm[1].c, 20)
        T.has(H:lastMsg(), "meta de farm: Tecido de Seda 27/20")
        H:slash("meta item " .. SILK .. " 40"); H:click(button)
        T.eq(H.env.FarolCharDB.farm[1].c, 40, "existing goal kept"); T.eq(#H.env.FarolCharDB.farm, 1)
    end },

    { "Goals window lists farm items; editing the amount and X remove work", function(T, Mock)
        local H = setup(Mock)
        H:slash("meta item " .. SILK .. " 40")
        H:slash("meta")
        local window = H.env.FarolGoals
        T.ok(window:IsShown())
        T.has(H:text(window.farmRows[1].text), "Tecido de Seda 27/40")
        T.ok(not window.farmRows[2].text:IsShown(), "unused rows hidden")
        local box = H.env.FarolFarmTarget1
        box:SetText("50"); H:click(H.env.FarolFarmSet1)
        T.eq(H.env.FarolCharDB.farm[1].c, 50)
        H:click(H.env.FarolFarmRemove1)
        T.eq(#H.env.FarolCharDB.farm, 0); T.ok(not window.farmRows[1].text:IsShown())
    end },

    { "English, the old client and blocked values", function(T, Mock)
        local H = setup(Mock, { locale = "enUS" })
        H:slash("goal item " .. SILK .. " 40")
        T.has(H:lastMsg(), "farm goal: Tecido de Seda 27/40")
        T.has(tip(H), "Farm (item goals)")
        H = setup(Mock, { mode = "wotlk" })
        H:slash("meta item " .. SILK .. " 40"); H:update(1)
        T.has(H:bar(), "Tecido de Seda 27/40")
        H = setup(Mock, { mode = "secret" })
        H:slash("meta item " .. SILK .. " 40"); H:update(1)
        H.env.GetItemCount = function() error("blocked") end
        if H.env.C_Item then H.env.C_Item.GetItemCount = function() error("blocked") end end
        H:update(1)
        T.has(H:bar(), "Tecido de Seda --/40", "unreadable count shows --")
    end },

    { "tampered saved data is cleaned on load", function(T, Mock)
        local bad = { farm = {
            { id = 4306, n = "Tecido|cffff0000 de Seda", c = 40, w = "x" },
            { id = 4306, n = "duplicado", c = 10 },
            { id = 0 / 0, n = "nan", c = 5 }, { id = 2772, n = "", c = 5 }, { id = 2772, n = "Minério", c = 1e9 },
            { id = 9010, n = string.rep("a", 300), c = 3, w = true },
        } }
        local H = setup(Mock, nil, bad)
        local farm = H.env.FarolCharDB.farm
        T.eq(#farm, 2)
        T.eq(farm[1].n, "Tecidocffff0000 de Seda"); T.eq(farm[1].w, nil)
        T.eq(farm[2].id, 9010); T.eq(#farm[2].n, 40); T.eq(farm[2].w, true)
        H = setup(Mock, nil, { farm = "lixo" }); T.eq(#H.env.FarolCharDB.farm, 0)
    end },
}
