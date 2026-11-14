-- Munição e reagentes: contagem por classe, cores pelos limites escolhidos, aviso opcional, validação.
-- Ammo and reagents: count per class, colors from the chosen limits, optional warning, validation.
-- O Farol só CONTA (test_toc proíbe comprar, usar ou mover itens).

local function fixGear(H)
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function setup(Mock, class, saved, opts)
    local H = Mock.new(opts)
    H.class = class
    H:login(saved); fixGear(H)
    H:slash("show municao"); H:update(1)
    return H
end

local function cellText(H)
    for _, cell in ipairs(H.env.FarolFrame._fontStrings) do
        if cell.farolKey == "ammo" and cell:IsShown() then return cell._text or "" end
    end
    return ""
end

local function hover(H)
    for _, cell in ipairs(H.env.FarolFrame._fontStrings) do
        if cell.farolKey == "ammo" and cell:IsShown() then
            H.env.GameTooltip.lines = {}
            cell.hover._scripts.OnEnter(cell.hover)
            return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
        end
    end
    return ""
end

return {
    { "hunter: ammo count with colors from the limits (normal, yellow, red)", function(T, Mock)
        local H = Mock.new(); H.class = "HUNTER"; H.ammo = 842
        H:login(); fixGear(H); H:update(1)
        T.hasnt(H:bar(), "Munição", "off by default")
        H:slash("show municao"); H:update(1)
        T.has(H:bar(), "Munição 842"); T.hasnt(cellText(H), "|cff", "normal color above 400")
        H.ammo = 310; H:update(1); T.has(cellText(H), "|cffffff3a310|r", "yellow below 400")
        H.ammo = 150; H:update(1); T.has(cellText(H), "|cffff4040150|r", "red below 200")
        local text = hover(H)
        T.has(text, "Munição = 150"); T.has(text, "Amarelo / vermelho abaixo de = 400 / 200")
        T.has(text, "o Farol só conta, nunca compra")
    end },

    { "mage: each reagent with its own color; classes without reagents hide the item", function(T, Mock)
        local H = Mock.new(); H.class = "MAGE"; H.itemCounts = { [17020] = 8, [17031] = 2, [17032] = 1 }
        H:login(); fixGear(H); H:slash("show municao"); H:update(1)
        T.has(H:barRaw(), "Pó Arcano |cffffff3a8|r · Runas |cffff40403|r")
        local W = setup(Mock, "WARRIOR")
        T.hasnt(W:bar(), "Munição"); T.hasnt(W:bar(), "Pó")
        local L = setup(Mock, "WARLOCK")
        T.has(L:bar(), "Munição --", "warlock with no shard yet: nothing tracked")
        L.itemCounts[6265] = 12; L:update(1)
        T.has(L:bar(), "Fragmentos 12")
        L.itemCounts[6265] = 0; L:update(1)
        T.has(L:barRaw(), "Fragmentos |cffff40400|r", "once seen, 0 is shown in red")
        T.eq(L.env.FarolCharDB.supplySeen.shard, true, "remembered per character")
        L.msgs = {}; L:slash("aviso status")
        T.has(H.strip(table.concat(L.msgs, "/")), "munição/reagentes: Fragmentos 0.")
        W.msgs = {}; W:slash("aviso status")
        T.has(H.strip(table.concat(W.msgs, "/")), "munição/reagentes: nada para a sua classe")
    end },

    { "the player chooses the limits (window and command); invalid values are refused", function(T, Mock)
        local H = setup(Mock, "HUNTER"); H.ammo = 300; H:update(1)
        T.has(cellText(H), "|cffffff3a300|r")
        H:slash("aviso municao 250 100")
        T.eq(H.env.FarolDB.warnings.ammoYellow, 250); T.eq(H.env.FarolDB.warnings.ammoRed, 100)
        T.has(H:lastMsg(), "munição: amarelo abaixo de 250, vermelho abaixo de 100.")
        H:update(1); T.hasnt(cellText(H), "|cff", "300 is now above the yellow limit")
        H:slash("aviso municao 100 300"); T.has(H:lastMsg(), "vermelho menor que o amarelo")
        T.eq(H.env.FarolDB.warnings.ammoYellow, 250, "unchanged")
        H:slash("aviso municao 6000 10"); T.has(H:lastMsg(), "de 0 a 5000")
        H:slash("aviso reagentes 0 3"); T.eq(H.env.FarolDB.warnings.reagYellow, 0, "0 = no yellow")
        H:slash("aviso")
        T.eq(H:text(H.env.FarolWarnAmmo.label), "Avisar quando a munição acabar")
        T.eq(H:text(H.env.FarolWarnAmmoYellow), "250"); T.eq(H:text(H.env.FarolWarnAmmoRed), "100")
        local yellow, red = H.env.FarolWarnAmmoYellow, H.env.FarolWarnAmmoRed
        yellow._text, red._text = "500", "50"
        yellow._scripts.OnEnterPressed(yellow)
        T.eq(H.env.FarolDB.warnings.ammoYellow, 500); T.eq(H.env.FarolDB.warnings.ammoRed, 50, "both boxes saved together")
    end },

    { "optional warning (off by default): once below red, again after restocking", function(T, Mock)
        local H = setup(Mock, "HUNTER"); H.ammo = 150; H:update(1)
        T.eq(H.warnSounds, 0, "off by default")
        H:slash("aviso municao on"); H:update(1)
        T.eq(H.warnSounds, 1)
        T.has(H:text(H.env.FarolWarnPopup.text), "Munição: 150 acabando — reabasteça antes de sair da cidade.")
        H:click(H.env.FarolWarnSilence)
        H.ammo = 120; for _ = 1, 30 do H:update(60) end
        T.eq(H.warnSounds, 1, "no repeat while still low")
        H.ammo = 1000; H:update(1); H.ammo = 100; H:update(1)
        T.eq(H.warnSounds, 2, "warns again after restocking")
        H:click(H.env.FarolWarnSilence)
        H.ammo = 1000; H:update(1)                      -- reabastece na cidade
        H.inCombat = true; H.ammo = 90; H:update(1)     -- gasta na luta
        T.eq(H.warnSounds, 2, "waits for combat to end")
        H.inCombat = false; H:update(1); T.eq(H.warnSounds, 3)
    end },

    { "reagent warning is separate from the ammo warning; English", function(T, Mock)
        local H = setup(Mock, "PRIEST", { warnings = { reag = true } }, { locale = "enUS" })
        H.itemCounts = { [17029] = 3 }; H:update(1)
        T.has(H:text(H.env.FarolWarnPopup.text), "Candles: 3 running low — restock before leaving town.")
        T.has(H:barRaw(), "Candles |cffff40403|r")
        local A = setup(Mock, "HUNTER", { warnings = { reag = true } }); A.ammo = 10; A:update(1)
        T.eq(A.warnSounds, 0, "the reagent warning does not cover ammo")
    end },

    { "tampered saved limits and flags fall back safely; bad counts are ignored", function(T, Mock)
        local H = setup(Mock, "HUNTER", { warnings = { ammoYellow = 100, ammoRed = 300, reagYellow = 0 / 0, reagRed = -1, ammo = "sim" } })
        local w = H.env.FarolDB.warnings
        T.eq(w.ammoYellow, 400); T.eq(w.ammoRed, 200); T.eq(w.reagYellow, 10); T.eq(w.reagRed, 5); T.eq(w.ammo, false)
        local C = Mock.new(); C.class = "MAGE"
        C:login(nil, { supplySeen = { powder = true, evil = true, runes = "sim" } })
        T.eq(C.env.FarolCharDB.supplySeen.powder, true)
        T.eq(C.env.FarolCharDB.supplySeen.evil, nil); T.eq(C.env.FarolCharDB.supplySeen.runes, nil)
        H.ammo = 0 / 0; H:update(1); T.hasnt(H:bar(), "nan")
        H.env.GetInventoryItemCount = function() error("blocked") end; H:update(1)
        H.env.UnitClass = function() error("blocked") end; H:update(1)
    end },
}
