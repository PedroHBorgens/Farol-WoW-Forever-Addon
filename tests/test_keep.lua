-- Itens guardados (3.26): lista da conta com motivo e "quando", lembretes no comerciante e na hora certa, fora da
-- conta do lixo, item da barra, linha no tooltip do item, dados salvos validados. Tudo desligado por padrão.
-- Kept items: account list with reason and "when", merchant and ready reminders, left out of junk, bar item, item
-- tooltip line, validated saved data. Everything starts off.

local LINK = "|cff1eff00|Hitem:7001::|h[Erva-de-luar]|h|r"

local function setup(Mock, opts, saved)
    local H = Mock.new(opts or { locale = "ptBR" })
    H.items[7001] = { "Erva-de-luar", 2, 25 }
    H.itemCounts[7001] = 4
    H.bankCounts = { [7001] = 8 }
    H.bagItems[2] = { [1] = { 7001, 4 } } -- nas bolsas: dá para achar pelo nome
    H:login(saved)
    return H
end
-- Abre o menu "Quando" e clica na opção com esse texto.
local function pick(H, text)
    H:click(H.env.FarolKeepWhen)
    for i = 1, 20 do
        local entry = H.env["FarolKeepWhenEntry" .. i]
        if entry and entry:IsShown() and H:text(entry.text) == text then H:click(entry) return true end
    end
    error("option not found: " .. text)
end
local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "off by default; the window adds by name with reason and level; rows show have/bank and status", function(T, Mock)
        local H = setup(Mock)
        H.xp.level = 28
        T.eq(H.env.FarolDB.items.keep, false, "bar item off"); T.eq(H.env.FarolDB.keepMerchant, false)
        T.eq(H.env.FarolDB.keepReady, false); T.eq(H.env.FarolDB.keepTooltip, false)
        H:slash("guardar"); local W = H.env.FarolKeep
        T.ok(W:IsShown(), "window open"); T.eq(H.env.UISpecialFrames[#H.env.UISpecialFrames], "FarolKeep")
        T.ok(W.empty:IsShown(), "empty state"); T.eq(H:text(H.env.FarolKeepItem.farolHint), "Nome do item (ou /farol guardar + Shift + clique no item)")
        H.env.FarolKeepItem:SetText("Erva-de-luar"); H.env.FarolKeepReason:SetText("receita de Alquimia")
        pick(H, "Quando: nível")
        T.ok(H.env.FarolKeepValue:IsShown(), "level box shows for 'level'")
        H.env.FarolKeepValue:SetText("35"); H:click(H.env.FarolKeepAdd)
        local entry = H.env.FarolDB.keep[1]
        T.eq(entry.id, 7001); T.eq(entry.n, "Erva-de-luar"); T.eq(entry.r, "receita de Alquimia"); T.eq(entry.k, "l"); T.eq(entry.v, 35)
        T.has(chat(H), "guardado: Erva-de-luar.")
        T.eq(H:text(W.rows[1].have), "12 (8 banco)"); T.eq(H:text(W.rows[1].why), "receita de Alquimia · nível 35 — faltam 7")
        T.eq(H:text(W.title), "Itens guardados (1)"); T.eq(H.env.FarolKeepItem:GetText(), "", "form cleared")
        H.env.FarolKeepItem:SetText("nada assim"); H:click(H.env.FarolKeepAdd); T.has(H:lastMsg(), "item não encontrado")
        H.env.FarolKeepItem:SetText("Erva-de-luar"); pick(H, "Quando: nível")
        H.env.FarolKeepValue:SetText("999"); H:click(H.env.FarolKeepAdd); T.has(H:lastMsg(), "escreva o nível de 1 a 100")
    end },

    { "command with link and reason; profession deadline; click a row to edit; remove and Undo", function(T, Mock)
        local H = setup(Mock)
        H.profs = { { "Alquimia", 140, 150, true } }
        H:slash("guardar " .. LINK .. ": receita de Alquimia")
        T.eq(H.env.FarolDB.keep[1].r, "receita de Alquimia"); T.eq(H.env.FarolDB.keep[1].k, nil, "no deadline yet")
        H:slash("guardar"); local W = H.env.FarolKeep
        T.eq(H:text(W.rows[1].why), "receita de Alquimia · sem prazo")
        H:click(W.rows[1].pick)
        T.eq(H.env.FarolKeepItem:GetText(), "Erva-de-luar", "row loaded into the form")
        pick(H, "Quando: Alquimia")
        H.env.FarolKeepValue:SetText("150"); H:click(H.env.FarolKeepAdd)
        local entry = H.env.FarolDB.keep[1]
        T.eq(#H.env.FarolDB.keep, 1, "updated, not duplicated"); T.eq(entry.k, "p"); T.eq(entry.p, "Alquimia"); T.eq(entry.v, 150)
        T.has(chat(H), "atualizado: Erva-de-luar.")
        T.eq(H:text(W.rows[1].why), "receita de Alquimia · Alquimia 150 — faltam 10")
        H:click(H.env.FarolKeepRemove1); T.eq(#H.env.FarolDB.keep, 0)
        T.ok(W.undoBack:IsShown(), "undo strip"); T.eq(H:text(W.undoText), "Tirado da lista: Erva-de-luar")
        H:click(W.undo); T.eq(H.env.FarolDB.keep[1].v, 150, "Undo brings it back as it was")
        H:slash("guardar tirar erva-de-luar"); T.eq(#H.env.FarolDB.keep, 0, "remove by name")
        H:slash("guardar desfazer"); T.eq(#H.env.FarolDB.keep, 1)
        H:slash("guardar lista"); T.has(chat(H), "1. Erva-de-luar ×12 — receita de Alquimia · Alquimia 150 — faltam 10")
        H:slash("guardar tirar 9"); T.has(H:lastMsg(), "esse item não está na lista")
        H:slash("guardar desfazer"); T.has(H:lastMsg(), "nada para desfazer")
    end },

    { "merchant reminder: only when on, only items in the bags, at most 5 + 'and N more'", function(T, Mock)
        local H = setup(Mock)
        H:slash("guardar " .. LINK .. ": receita de Alquimia")
        H.msgs = {}; H:event("MERCHANT_SHOW"); T.hasnt(chat(H), "guardados nas bolsas", "off by default")
        H:slash("guardar comerciante on"); T.has(H:lastMsg(), "Lembrar ao abrir um comerciante")
        H.msgs = {}; H:event("MERCHANT_SHOW")
        T.has(chat(H), "guardados nas bolsas: Erva-de-luar ×4 (receita de Alquimia)")
        H.itemCounts[7001] = 0; H.msgs = {}; H:event("MERCHANT_SHOW")
        T.hasnt(chat(H), "guardados nas bolsas", "only in the bank: nothing to remind")
        for i = 1, 7 do
            H.items[7100 + i] = { "Item " .. i, 1, 10 }; H.itemCounts[7100 + i] = i
            H:slash("guardar |cffffffff|Hitem:" .. (7100 + i) .. "::|h[Item " .. i .. "]|h|r")
        end
        H.msgs = {}; H:event("MERCHANT_SHOW")
        T.has(chat(H), "Item 5 ×5, e mais 2"); T.hasnt(chat(H), "Item 6 ×6")
    end },

    { "ready reminder: once per character at the level (PLAYER_LEVEL_UP value), never for what was already ready", function(T, Mock)
        local H = setup(Mock)
        H.xp.level = 28
        H:slash("guardar " .. LINK .. ": receita"); H:slash("guardar"); local W = H.env.FarolKeep
        H:click(W.rows[1].pick); T.eq(H.env.FarolKeepReason:GetText(), "receita", "row loads the reason too")
        pick(H, "Quando: nível")
        H.env.FarolKeepValue:SetText("29"); H:click(H.env.FarolKeepAdd)
        H.msgs = {}; H:event("PLAYER_LEVEL_UP", 29); T.hasnt(chat(H), "já pode usar", "off by default")
        H.xp.level = 28; H:check(H.env.FarolKeep_keepReady, true); T.eq(H.env.FarolDB.keepReady, true)
        H.msgs = {}; H:event("PLAYER_LEVEL_UP", 29) -- UnitLevel ainda diz 28: vale o número do evento
        T.has(chat(H), "você chegou ao nível 29: já pode usar Erva-de-luar ×12 (receita). 8 estão no banco.")
        H.xp.level = 29; H.msgs = {}; H:event("PLAYER_ENTERING_WORLD"); H:event("PLAYER_LEVEL_UP", 30)
        T.hasnt(chat(H), "já pode usar", "only once")
        T.eq(H.env.FarolCharDB.keepSeen[7001], true)
        T.has(H:text(W.rows[1].why), "nível 29 — já pode")
        -- profissão: aviso ao subir (SKILL_LINES_CHANGED)
        H.profs = { { "Alquimia", 149, 150, true } }
        H:slash("guardar " .. LINK); H.env.FarolKeepItem:SetText("Erva-de-luar")
        pick(H, "Quando: Alquimia"); H.env.FarolKeepValue:SetText("150"); H:click(H.env.FarolKeepAdd)
        H.profs[1][2] = 150; H.msgs = {}; H:event("SKILL_LINES_CHANGED")
        T.has(chat(H), "Alquimia chegou a 150: já pode usar Erva-de-luar")
    end },

    { "kept items are left out of the junk count; bar item and tooltip", function(T, Mock)
        local H = setup(Mock)
        H:slash("show lixo"); H:update(1)
        T.has(H:bar(), "Lixo 3g 26s (3)")
        H.itemCounts[9003] = 1
        H:slash("guardar |cff9d9d9d|Hitem:9003::|h[Espada Enferrujada]|h|r: lembrança"); H:update(1)
        T.has(H:bar(), "Lixo 76s 50c (2)", "kept sword no longer counted as junk")
        H:slash("show guardados"); H:update(1); T.has(H:bar(), "Guardados 1")
        H.xp.level = 40; H:slash("guardar " .. LINK); H:slash("guardar")
        H.env.FarolKeepItem:SetText("Erva-de-luar"); pick(H, "Quando: nível")
        H.env.FarolKeepValue:SetText("35"); H:click(H.env.FarolKeepAdd); H:update(1)
        T.has(H:bar(), "Guardados 2 · 1")
        H.env.GameTooltip.lines = {}; H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        local tip = H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        T.has(tip, "Itens guardados"); T.has(tip, "Espada Enferrujada ×1 — lembrança · sem prazo"); T.has(tip, "nível 35 — já pode")
    end },

    { "item tooltip line: off by default, hooked only when turned on, protected; English", function(T, Mock)
        local H = setup(Mock)
        local calls = {}
        H.env.TooltipDataProcessor = { AddTooltipPostCall = function(kind, fn) calls[#calls + 1] = { kind, fn } end }
        H.env.Enum = { TooltipDataType = { Item = 0 } }
        H:slash("guardar " .. LINK .. ": receita de Alquimia")
        T.eq(#calls, 0, "nothing hooked while the option is off")
        H:slash("guardar tooltip on"); T.eq(#calls, 1, "hooked once"); H:slash("guardar tooltip off"); H:slash("guardar tooltip on")
        T.eq(#calls, 1, "never hooked twice")
        local tip = H.env.GameTooltip; tip.lines = {}
        calls[1][2](tip, { id = 7001 }); T.has(H.strip(table.concat(tip.lines, " / ")), "Farol: guardado — receita de Alquimia")
        tip.lines = {}; calls[1][2](tip, { id = 1234 }); T.eq(#tip.lines, 0, "other items untouched")
        tip.lines = {}; calls[1][2]({ AddLine = function() error("boom") end }, { id = 7001 }); T.ok(true, "errors are swallowed")
        H:slash("guardar tooltip off"); tip.lines = {}; calls[1][2](tip, { id = 7001 }); T.eq(#tip.lines, 0, "off: no line")
        local E = setup(Mock, { locale = "enUS" })
        E:slash("keep " .. LINK .. ": Alchemy recipe"); T.has(E:lastMsg(), "kept: Erva-de-luar.")
        E:slash("keep"); T.eq(E:text(E.env.FarolKeep.checks[1].label), "Remind me when I open a merchant (kept items in my bags)")
        E:slash("keep merchant maybe"); T.has(E:lastMsg(), "usage: /farol keep")
    end },

    { "pick list: click the item box to see bags + noted bank; typing filters; click or Enter picks", function(T, Mock)
        local H = setup(Mock)
        H:slash("guardar"); local W, box = H.env.FarolKeep, H.env.FarolKeepItem
        box._scripts.OnEditFocusGained(box)
        local pick = H.env.FarolKeepPick
        T.ok(pick:IsShown(), "list opens with the box")
        T.has(H:text(pick.head), "itens nas bolsas e no banco"); T.eq(H:text(pick.bank), "abra o banco uma vez para os itens dele aparecerem aqui")
        local names = {}
        for i = 1, 8 do local row = H.env["FarolKeepPick" .. i]; if row:IsShown() then names[#names + 1] = H:text(row.name) end end
        T.eq(names[1], "Couro Rasgado", "alphabetical"); T.has(table.concat(names, ","), "Erva-de-luar")
        -- banco: só quando aberto; anota número e nome (o banco continua lá na próxima sessão)
        H.bankSlots = { [-1] = 28 }; H.bagItems[-1] = { [1] = { 9010, 20 }, [2] = { 7001, 8 } }
        H:event("BANKFRAME_OPENED"); H:event("BANKFRAME_CLOSED")
        local noted = H.env.FarolCharDB.keepBank
        T.eq(#noted.l, 2); T.eq(noted.l[1].n, "Erva-de-luar"); T.eq(noted.l[1].c, 8)
        H.bagItems[-1] = {}; H:event("PLAYERBANKSLOTS_CHANGED"); T.eq(#H.env.FarolCharDB.keepBank.l, 2, "closed bank: nothing re-read")
        box:SetText("pão"); box._scripts.OnTextChanged(box, true)
        T.eq(H:text(pick.head), '1 item com "pão"')
        local row = H.env.FarolKeepPick1
        T.eq(H:text(row.name), "Pão de Centeio"); T.eq(H:text(row.count), "×25"); T.eq(H:text(row.where), "bolsas + banco")
        T.has(H:text(pick.bank), "banco anotado:")
        box:SetText("erva"); box._scripts.OnTextChanged(box, true); T.eq(H:text(H.env.FarolKeepPick1.where), "bolsas + banco")
        H:click(H.env.FarolKeepPick1)
        T.eq(box:GetText(), "Erva-de-luar"); T.ok(not pick:IsShown(), "list closes after picking")
        H.env.FarolKeepReason:SetText("receita"); H:click(H.env.FarolKeepAdd)
        T.eq(H.env.FarolDB.keep[1].id, 7001); T.eq(H.env.FarolDB.keep[1].r, "receita")
        box._scripts.OnEditFocusGained(box); box:SetText("erva"); box._scripts.OnTextChanged(box, true)
        T.has(H:text(H.env.FarolKeepPick1.where), "guardado", "already kept is marked")
        box._scripts.OnEnterPressed(box); T.eq(H.env.FarolKeepReason:GetText(), "receita", "Enter picks the first; kept item loads its reason")
        box._scripts.OnEditFocusGained(box); box:SetText("zzz"); box._scripts.OnTextChanged(box, true)
        T.eq(H:text(pick.head), "nenhum item com esse nome nas bolsas nem no banco anotado")
        box._scripts.OnEscapePressed(box); T.ok(not pick:IsShown(), "Esc closes the list")
    end },

    { "loot window: Keep button per item; already kept shows a check and is disabled", function(T, Mock)
        local H = setup(Mock)
        H:event("CHAT_MSG_LOOT", "Você recebe saque: " .. LINK .. "x2.")
        H:slash("saque")
        local keep = H.env.FarolLootKeep1
        T.ok(keep and keep:IsShown(), "button shown"); T.eq(H:text(keep), "Guardar")
        H:click(keep); T.eq(H.env.FarolDB.keep[1].id, 7001); T.has(chat(H), "guardado: Erva-de-luar.")
        T.eq(keep._disabled, true, "already kept: disabled"); T.has(keep._text, "ReadyCheck-Ready")
        H.ns.Keep.KeepLink(LINK); T.has(H:lastMsg(), "já está guardado: Erva-de-luar.")
    end },

    { "saved data is validated: bad types, NaN, '|', duplicates, too many, huge files", function(T, Mock)
        local big = {}
        for i = 1, 5000 do big[i] = { id = 100 + i, n = "Item " .. i } end
        local H = setup(Mock, nil, { keep = {
            { id = 7001, n = "Erva|cff", r = string.rep("x", 90), k = "l", v = 35 },
            { id = 7001, n = "Dup" }, { id = 0 / 0, n = "NaN" }, { id = 5, n = "" }, { id = 6, n = "Seis", k = "l", v = 1e9 },
            { id = 7, n = "Sete", k = "p", v = 100, p = "" }, { id = 8, n = "Oito", k = "p", v = 120, p = "Couraria" }, "lixo",
        }, keepMerchant = "sim", keepReady = 1, keepTooltip = {} })
        local keep = H.env.FarolDB.keep
        T.eq(#keep, 4); T.eq(keep[1].n, "Ervacff"); T.eq(#keep[1].r, 40)
        T.eq(keep[2].id, 6); T.eq(keep[2].k, nil, "absurd level dropped"); T.eq(keep[3].k, nil, "profession without name dropped")
        T.eq(keep[4].p, "Couraria"); T.eq(keep[4].v, 120)
        T.eq(H.env.FarolDB.keepMerchant, false); T.eq(H.env.FarolDB.keepReady, false); T.eq(H.env.FarolDB.keepTooltip, false)
        local B = setup(Mock, nil, { keep = big }); T.eq(#B.env.FarolDB.keep, 50, "at most 50")
        local S = Mock.new(); S:login(nil, { keepSeen = { [7001] = true, [-1] = true, x = true, [8] = "sim" } })
        T.eq(S.env.FarolCharDB.keepSeen[7001], true); T.eq(S.env.FarolCharDB.keepSeen[-1], nil); T.eq(S.env.FarolCharDB.keepSeen[8], nil)
        for i = 1, 50 do H:slash("guardar |cffffffff|Hitem:" .. (8000 + i) .. "::|h[I" .. i .. "]|h|r") end
        T.eq(#H.env.FarolDB.keep, 50); T.has(H:lastMsg(), "a lista já tem 50 itens")
        -- banco anotado adulterado: tipos ruins, repetidos, '|', enorme
        local bank = { t = 0 / 0, l = { { id = 9001, n = "Couro|r", c = -5, q = 99 }, { id = 9001, n = "Dup" }, "x", { id = 1.5, n = "Meio" } } }
        for i = 1, 3000 do bank.l[#bank.l + 1] = { id = 20000 + i, n = "B" .. i, c = 1 } end
        local Z = Mock.new(); Z:login(nil, { keepBank = bank })
        local saved = Z.env.FarolCharDB.keepBank
        T.eq(saved.t, nil); T.eq(saved.l[1].n, "Couror"); T.eq(saved.l[1].c, 1); T.eq(saved.l[1].q, nil)
        T.ok(#saved.l <= 1000, "at most 1000 bank items")
    end },
}
