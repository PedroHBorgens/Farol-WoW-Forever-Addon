-- Avisos de durabilidade e bolsas: dispara uma vez, rearma depois que melhora, intervalo mínimo,
-- limites configuráveis, som opcional, janela e comandos.
-- Durability and bag warnings.

local function setDurability(H, pct)
    H.durability = { [1] = { pct, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function setFree(H, free)
    H.bagFree = { [0] = free, 0, 0, 0, 0 }
end

return {
    { "defaults are on (20% and 2 slots) and invalid saved values are fixed", function(T, Mock)
        local H = Mock.new():login({ warnings = { durab = "x", durabPct = 99, bagSlots = 3, sound = false } })
        local w = H.env.FarolDB.warnings
        T.eq(w.durab, true); T.eq(w.durabPct, 20, "out of range -> default")
        T.eq(w.bagSlots, 3); T.eq(w.sound, false); T.eq(w.bags, true)
    end },

    { "low durability warns once, on screen and in chat, with its own sound", function(T, Mock)
        local H = Mock.new():login()
        setDurability(H, 15); H:update(1)
        T.eq(H.warnSounds, 1); T.eq(H.sounds, 0, "not the alarm sound")
        T.has(H.strip(H.screen), "Durabilidade baixa: 15% — hora de reparar!")
        T.has(H:lastMsg(), "Durabilidade baixa: 15%")
        for _ = 1, 10 do H:update(60) end
        T.eq(H.warnSounds, 1, "no repeat while still low")
    end },

    { "warns again only after repairing and after the 5 minute cooldown", function(T, Mock)
        local H = Mock.new():login()
        setDurability(H, 15); H:update(1); T.eq(H.warnSounds, 1)
        setDurability(H, 100); H:update(1)                  -- reparou
        setDurability(H, 10); H:update(60); T.eq(H.warnSounds, 1, "cooldown")
        for _ = 1, 4 do H:update(60) end; T.eq(H.warnSounds, 2, "after 5 min")
    end },

    { "bags: almost full, then full, without repeating while flapping", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        setDurability(H, 100)
        setFree(H, 2); H:update(1)
        T.eq(H.warnSounds, 1); T.has(H.strip(H.screen), "Bags almost full: 2 free slot(s).")
        setFree(H, 1); H:update(1); setFree(H, 2); H:update(1)
        T.eq(H.warnSounds, 1, "no repeat while it changes between 1 and 2")
        setFree(H, 0); H:update(1)
        T.eq(H.warnSounds, 2); T.has(H.strip(H.screen), "Bags full!")
        H:update(1); T.eq(H.warnSounds, 2, "full warning only once")
        setFree(H, 20); H:update(1); setFree(H, 1)
        for _ = 1, 5 do H:update(60) end
        T.eq(H.warnSounds, 3, "re-armed after emptying the bags")
    end },

    { "thresholds and switches by command; invalid values rejected", function(T, Mock)
        local H = Mock.new():login()
        local w = H.env.FarolDB.warnings
        H:slash("aviso durab 30"); T.eq(w.durabPct, 30)
        H:slash("aviso durab 80"); T.has(H:lastMsg(), "valor inválido: use de 5 a 50"); T.eq(w.durabPct, 30)
        H:slash("aviso bolsas 5"); T.eq(w.bagSlots, 5)
        H:slash("aviso bolsas 11"); T.eq(w.bagSlots, 5)
        H:slash("aviso som off"); T.eq(w.sound, false)
        H:slash("aviso durab off"); T.eq(w.durab, false)
        H:slash("aviso xyz"); T.has(H:lastMsg(), "uso: /farol aviso durab N | bolsas N")
    end },

    { "disabled warnings and sound off are respected", function(T, Mock)
        local H = Mock.new():login({ warnings = { durab = false, sound = false } })
        setDurability(H, 5); H:update(1)
        T.eq(H.warnSounds, 0, "durability warning off")
        setFree(H, 0); H:update(1)
        T.eq(H.warnSounds, 0, "sound off")
        T.has(H.strip(H.screen), "Bolsas cheias!", "message still shown")
    end },

    { "warnings window: checkboxes, number boxes and test button", function(T, Mock)
        local H = Mock.new():login()
        H.env.FarolFrame._scripts.OnMouseUp(H.env.FarolFrame, "RightButton")
        local button
        for _, frame in ipairs(H:framesOf("Button")) do
            if frame._text == "Avisos..." then button = frame end
        end
        T.ok(button, "Warnings... button in the options menu")
        H:click(button)
        local window = H.env.FarolWarnings
        T.ok(window:IsShown(), "window open")
        T.eq(H.env.FarolWarnDurabPct._text, "20")
        H.env.FarolWarnDurabPct._text = "25"
        H.env.FarolWarnDurabPct._scripts.OnEnterPressed(H.env.FarolWarnDurabPct)
        T.eq(H.env.FarolDB.warnings.durabPct, 25)
        H.env.FarolWarnBagSlots._text = "99"
        H.env.FarolWarnBagSlots._scripts.OnEnterPressed(H.env.FarolWarnBagSlots)
        T.eq(H.env.FarolDB.warnings.bagSlots, 2, "invalid rejected")
        T.eq(H.env.FarolWarnBagSlots._text, "2", "box reverts")
        H:check(H.env.FarolWarnSound, false); T.eq(H.env.FarolDB.warnings.sound, false)
        H:click(H.env.FarolWarnTest); T.has(H.strip(H.screen), "Durabilidade baixa: 24%")
    end },

    { "warnings work with the panel hidden and ignore secret values", function(T, Mock)
        local H = Mock.new({ secret = true }):login()
        H:slash("")
        setDurability(H, 15) -- 15 é "secreto" no modo secret: ignorado
        H:update(1); T.eq(H.warnSounds, 0)
        setDurability(H, 12); H:update(1); T.eq(H.warnSounds, 1, "works with the panel hidden")
    end },
}
