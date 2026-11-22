-- Revisão de textos (3.13.1): "Limpar" pergunta antes ("Apagar 23 itens?"), plurais de verdade, cores descritas
-- pelo estado (valem nas duas paletas), /farol itens pela paleta, "apagar" e "ligar/desligar" em todo lugar.
-- Text review (3.13.1): "Clear" asks first, real plurals, colors described by state, palette in /farol items.

local function loot(H, i) H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff1eff00|Hitem:" .. (8000 + i) .. "|h[Erva " .. i .. "]|h|r.") end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "loot Clear: first click asks how many, second click (within 5 s) deletes; a late click asks again", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        for i = 1, 23 do loot(H, i) end
        H:slash("saque")
        local clear = H.env.FarolLootClear
        T.eq(H:text(clear), "Limpar")
        H:click(clear)
        T.eq(#H.env.FarolCharDB.items, 23, "nothing deleted yet"); T.eq(H:text(clear), "Apagar 23 itens?")
        H:update(6); H:click(clear)
        T.eq(#H.env.FarolCharDB.items, 23, "too late: asks again"); T.eq(H:text(clear), "Apagar 23 itens?")
        H:update(1); H:click(clear)
        T.eq(#H.env.FarolCharDB.items, 0); T.has(H:lastMsg(), "histórico de saques apagado")
        T.eq(H:text(clear), "Limpar", "label back after the window refreshes")
        loot(H, 99); H:click(clear); T.eq(H:text(clear), "Apagar 1 item?", "singular")
        loot(H, 100); T.eq(H:text(clear), "Limpar", "new loot cancels the question")
        H:click(clear); T.eq(#H.env.FarolCharDB.items, 2, "asks again after the refresh")
        local en = Mock.new({ locale = "enUS" }):login(); loot(en, 1); loot(en, 2); en:slash("loot")
        en:click(en.env.FarolLootClear); T.eq(en:text(en.env.FarolLootClear), "Delete 2 items?")
    end },

    { "empty lists clear at once (nothing to lose); dungeon history asks with the count", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("saque"); H:click(H.env.FarolLootClear)
        T.eq(H:text(H.env.FarolLootClear), "Limpar", "nothing to ask")
        H:slash("historico"); H:click(H.env.FarolWarnHistoryClear)
        T.eq(H:text(H.env.FarolWarnHistoryClear), "Limpar")
        local runs = { list = {}, cur = nil }
        for i = 1, 3 do runs.list[i] = { n = "Cripta " .. i, k = "party", t = 1800000000 - i * 3600, s = 600, x = 0, g = 0, l = 0, r = 0, e = 0, d = 0 } end
        H = Mock.new({ locale = "ptBR" }):login(nil, { runs = runs })
        H:slash("masmorra")
        T.eq(#H.env.FarolCharDB.runs.list, 3)
        H:click(H.env.FarolRunsClear); T.eq(H:text(H.env.FarolRunsClear), "Apagar 3 corridas?")
        T.eq(#H.env.FarolCharDB.runs.list, 3)
        H:click(H.env.FarolRunsClear); T.eq(#H.env.FarolCharDB.runs.list, 0)
    end },

    { "a broken clock never deletes by itself", function(T, Mock)
        local H = Mock.new():login()
        for i = 1, 3 do loot(H, i) end
        H:slash("saque")
        for _, bad in ipairs({ function() error("x") end, function() return 0 / 0 end, function() return "x" end }) do
            H.env.GetTime = bad
            local ok, err = pcall(H.click, H, H.env.FarolLootClear); T.ok(ok, tostring(err))
        end
        T.ok(#H.env.FarolCharDB.items >= 0)
    end },

    { "plurals: singular and plural forms, never (s)", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        T.eq(string.format(H.ns.TN("warn_bags", 1), 1), "Bolsas quase cheias: 1 espaço livre.")
        T.eq(string.format(H.ns.TN("warn_bags", 3), 3), "Bolsas quase cheias: 3 espaços livres.")
        T.eq(string.format(H.ns.TN("warn_talents", 1), 1), "Você tem 1 ponto de talento para gastar.")
        T.eq(string.format(H.ns.TN("warn_talents", 0), 0), "Você tem 0 pontos de talento para gastar.")
        T.eq(H.ns.TN("name_fps", 1), "FPS", "keys without _1 fall back to the normal text")
        for _, lang in ipairs({ "pt", "en" }) do
            for key, text in pairs(H.ns.STRINGS[lang]) do
                if type(text) == "string" then
                    for _, bad in ipairs({ "(s)", "(ns)", "(ões)" }) do
                        T.ok(not text:find(bad, 1, true) or key:find("status") or key:find("usage"), lang .. "." .. key .. " uses " .. bad)
                    end
                end
            end
        end
    end },

    { "texts describe the state, not the color (true in both palettes)", function(T, Mock)
        local H = Mock.new():login()
        for _, lang in ipairs({ "pt", "en" }) do
            for _, key in ipairs({ "desc_fps", "desc_durab", "tt_supply_limits", "warn_yellow", "warn_red", "warn_set_supply",
                                   "warn_bad_supply", "warn_desc_ammo", "warn_desc_reag" }) do
                local text = string.lower(H.ns.STRINGS[lang][key])
                for _, color in ipairs({ "verde", "amarelo", "vermelho", "green", "yellow", "red " , "red:", "red." }) do
                    T.ok(not text:find(color, 1, true), lang .. "." .. key .. " names a color: " .. color)
                end
            end
        end
    end },

    { "/farol itens uses the palette (colorblind option too)", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("itens"); local raw = table.concat(H.msgs, "\n")
        T.has(raw, H.ns.C.good .. "visível|r"); T.has(raw, H.ns.C.dim .. "escondido|r")
        H:slash("cores daltonismo"); H.msgs = {}
        H:slash("itens"); T.has(table.concat(H.msgs, "\n"), "|cff66b3ffvisível|r")
        H:slash("mostrar mem"); T.has(table.concat(H.msgs, "\n"), "|cff66b3ffvisível|r")
        local f = io.open("Farol/Core.lua", "r"); local code = f:read("*a"); f:close()
        T.ok(not code:find("|cff00ff00visível", 1, true) and not code:find("|cffff3333", 1, true), "no fixed colors left")
    end },

    { "same words for the same actions: apagar, ligar/desligar; welcome is neutral", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        H:slash("alarme add 07:30 servidor Raide"); H:slash("alarme desativar 1")
        T.has(H:lastMsg(), "alarme desligado: 07:30")
        H:slash("alarme ativar 1"); T.has(H:lastMsg(), "alarme ligado: 07:30")
        H:slash("alarme remover 1"); T.has(H:lastMsg(), "alarme apagado: 07:30")
        T.has(all(Mock.new({ locale = "ptBR" }):login()), "Boas-vindas!")
        T.eq(H.ns.STRINGS.pt.warn_opt_questReady, "Missões prontas (cidade/estalagem)")
        T.has(H.ns.STRINGS.pt.loot_track_tip, "janela Metas")
    end },
}
