-- De onde vem o XP e o ouro (3.19): missões, monstros, saque, comerciante e outros; opção desligada por padrão.
-- XP and gold by source: quests, monsters, loot, merchant and other; option off by default.

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

local function xp(H, gain) H.xp.cur = H.xp.cur + gain; H:event("PLAYER_XP_UPDATE", "player") end
local function money(H, delta) H.money = (H.money or 1234567) + delta; H:event("PLAYER_MONEY") end

-- Uma sessão com tudo: missão (o jogo informa a recompensa), monstros, descoberta, saque, comerciante e correio.
local function play(H)
    H.money = 100000; H:login(); H:event("PLAYER_ENTERING_WORLD", true, false); H:update(1)
    H:event("PLAYER_REGEN_DISABLED"); H:update(5); xp(H, 300); H:event("PLAYER_REGEN_ENABLED")
    H:update(2); xp(H, 200)                                  -- até 3 s depois da luta: monstro
    H:event("LOOT_OPENED"); money(H, 250); H:event("LOOT_CLOSED")
    H:update(30); xp(H, 900); money(H, 1500)                -- recompensa chega antes do aviso de entrega...
    H:event("QUEST_TURNED_IN", 501, 900, 1500)              -- ...e o jogo informa os valores
    H:update(30); xp(H, 120)                                 -- descobriu um lugar: outros
    H:event("MERCHANT_SHOW"); money(H, 4205); money(H, -4550); H:event("MERCHANT_CLOSED")
    H:update(30); money(H, 700)                              -- correio: outros
    H:update(600)
end

return {
    { "off by default: no tooltip lines, no summary lines, nothing saved", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); play(H)
        T.eq(H.env.FarolDB.sources, false)
        T.hasnt(tip(H), "De onde veio"); H.msgs = {}; H:slash("resumo"); T.hasnt(chat(H), "por origem")
        H:event("PLAYER_LOGOUT"); T.eq(H.env.FarolCharDB.lastSession.src, nil, "summary saves no source numbers")
    end },

    { "XP and gold split by source; 'other' makes the sum match the session totals", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); play(H)
        H:slash("origem on"); T.has(H:lastMsg(), "de onde vem o XP e o ouro: ligado")
        local text = tip(H)
        T.has(text, "De onde veio o XP (sessão) = 1.5k")
        T.has(text, "Missões (1 entregue) = 900 · 59%")
        T.has(text, "Monstros = 500 · 33%")
        T.has(text, "Outros (lugares, profissões) = 120 · 8%")
        T.has(text, "De onde veio o ouro (sessão) /    Recompensas de missão = +15s 0c")
        T.has(text, "Saque de monstros = +2s 50c")
        T.has(text, "Comerciante: vendas = +42s 5c")
        T.has(text, "Comerciante: compras e consertos = -45s 50c")
        T.has(text, "Outros (correio, leilão, troca) = +7s 0c")
        local snap = H.ns.Sources.Snapshot()
        T.eq(snap.qx + snap.mx + snap.ox, H.ns.GetSessionXP(), "XP sum = session XP")
        T.eq(snap.qg + snap.lg + snap.sg - snap.bg + snap.og, H.money - 100000, "gold sum = session gold")
        H.msgs = {}; H:slash("resumo")
        T.has(chat(H), "XP por origem: missões 59% · monstros 33% · outros 8%")
        T.has(chat(H), "Ouro por origem: missões +15s 0c · saque +2s 50c · vendas +42s 5c · compras e consertos -45s 50c · outros +7s 0c")
        -- O resumo salvo leva só os números e aparece no próximo login.
        H:event("PLAYER_LOGOUT")
        T.eq(H.env.FarolCharDB.lastSession.src.qx, 900)
        local B = Mock.new({ locale = "ptBR" }); B.env.FarolDB, B.env.FarolCharDB = H.env.FarolDB, H.env.FarolCharDB
        B:load(); B:event("ADDON_LOADED", "Farol"); B:event("PLAYER_ENTERING_WORLD", true, false)
        T.has(chat(B), "XP por origem: missões 59%")
        -- Zerar a sessão zera as origens.
        B:slash("sessao zerar"); local z = B.ns.Sources.Snapshot()
        T.eq(z.qx + z.mx + z.ox + z.qn + z.qg + z.lg + z.sg + z.bg, 0)
    end },

    { "turn-in without reward values (WoW Forever may not send them): the change next to it counts", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.money = 0; H:login({ sources = true }); H:update(1)
        money(H, 300); H:update(1); H:event("QUEST_TURNED_IN", 7)  -- ouro 1 s antes
        H:update(1); xp(H, 450)                                      -- XP 1 s depois
        local s = H.ns.Sources.Snapshot()
        T.eq(s.qn, 1); T.eq(s.qx, 450); T.eq(s.qg, 300)
        H:update(10); xp(H, 50); money(H, 20)                        -- longe da entrega: outros
        s = H.ns.Sources.Snapshot(); T.eq(s.qx, 450); T.eq(s.ox, 50); T.eq(s.og, 20)
        H:slash("diagnostico"); T.has(chat(H), "Recompensa da última entrega: XP não informado · ouro não informado")
        H:event("QUEST_TURNED_IN", 8, 1200, 9999)
        H.msgs = {}; H:slash("diagnostico"); T.has(chat(H), "Recompensa da última entrega: XP 1200 · ouro 0g 99s 99c")
    end },

    { "menu checkbox (General tab), command, news line and English texts", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }); H:login()
        H:slash("menu"); local set = H.env.FarolOptions.controls
        T.eq(H:text(set.sources.label), "Show where the XP and gold come from (tooltip and summary)")
        T.eq(set.sources._checked, false)
        H:check(set.sources, true); T.eq(H.env.FarolDB.sources, true); T.has(H:lastMsg(), "where the XP and gold come from: on")
        H:slash("source off"); T.eq(H.env.FarolDB.sources, false); T.eq(set.sources._checked, false, "menu synced")
        H:slash("source maybe"); T.has(H:lastMsg(), "usage: /farol source on|off")
        local U = Mock.new({ locale = "ptBR" }); U:login({ items = { fps = true }, newsSeen = #H.ns.NEWS - 2 })
        T.has(chat(U), "de onde vem o XP e o ouro da sessão: missões, monstros, saque e comerciante (tooltip e resumo) — desligado (ligue em Menu > Geral)")
    end },

    { "saved source numbers are validated; blocked or broken values never break anything", function(T, Mock)
        local Z = Mock.new(); Z:login()
        local function clean(src) return Z.ns.SanitizeSummary({ t = 1e9, secs = 600, src = src }).src end
        for _, bad in ipairs({ "x", { qx = 1 }, { qx = 0 / 0, mx = 0, ox = 0, qn = 0, qg = 0, lg = 0, sg = 0, bg = 0, og = 0 },
                               { qx = -1, mx = 0, ox = 0, qn = 0, qg = 0, lg = 0, sg = 0, bg = 0, og = 0 },
                               { qx = 1, mx = 1, ox = 1, qn = 1, qg = 1, lg = 1, sg = 1, bg = 1, og = 1 / 0 } }) do
            T.eq(clean(bad), nil, "bad source numbers dropped")
        end
        local src = clean({ qx = 1.5, mx = 2, ox = 3, qn = 1, qg = 4, lg = 5, sg = 6, bg = 7, og = -8, evil = "x" })
        T.eq(src.qx, 1); T.eq(src.og, -8); T.eq(src.evil, nil)
        -- Valores bloqueados/estranhos nos eventos.
        local S = Mock.new({ mode = "secret" }); S:login({ sources = true })
        S:event("QUEST_TURNED_IN", 1, 0 / 0, 1 / 0); S:event("QUEST_TURNED_IN", 2, "x", {}); S:event("PLAYER_MONEY")
        S:event("LOOT_CLOSED"); S:event("MERCHANT_CLOSED"); S:event("PLAYER_REGEN_ENABLED")
        tip(S); S:slash("resumo"); S:slash("diag")
        local snap = S.ns.Sources.Snapshot(); T.eq(snap.qx, 0); T.eq(snap.qg, 0)
        local W = Mock.new({ mode = "wotlk" }); W:login({ sources = true }); W:update(1); xp(W, 10); tip(W); W:slash("resumo")
    end },
}
