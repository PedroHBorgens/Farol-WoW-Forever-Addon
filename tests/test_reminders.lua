-- Talentos não gastos, magias de grau antigo na barra e a janelinha "Silenciar / Lembrar em 30 min".
-- Unspent talents, lower-rank spells on the bars and the "Silence / Remind in 30 min" popup.

local function popupText(H) return H:text(H.env.FarolWarnPopup.text) end

local function fixGear(H) -- tira a durabilidade baixa padrão do simulador, para isolar os testes
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

return {
    { "unspent talent points: warns once per new point, never in combat", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.talentPoints = 1; H.inCombat = true; H:update(1)
        T.eq(H.warnSounds, 0, "waits for combat to end")
        H.inCombat = false; H:update(1)
        T.eq(H.warnSounds, 1); T.has(popupText(H), "Você tem 1 ponto(s) de talento para gastar.")
        H:update(60); T.eq(H.warnSounds, 1, "same number: no repeat")
        H.talentPoints = 2; H:update(1); T.eq(H.warnSounds, 2, "new point: warns again")
        H.talentPoints = 0; H:update(1); H.talentPoints = 1; H:update(1); T.eq(H.warnSounds, 3, "after spending all")
    end },

    { "talents work with the classic API (3.3.5a style) and the modern trait API", function(T, Mock)
        local H = Mock.new({ mode = "wotlk", locale = "enUS" }):login(); fixGear(H)
        H.talentPoints = 3; H:update(1)
        T.has(H:lastMsg(), "You have 3 unspent talent point(s).")
        local H2 = Mock.new():login(); fixGear(H2)
        H2.env.GetUnspentTalentPoints = nil
        H2.env.C_ClassTalents = { GetActiveConfigID = function() return 7 end }
        H2.env.C_Traits = {
            GetConfigInfo = function() return { treeIDs = { 1, 2 } } end,
            GetTreeCurrencyInfo = function(_, tree) return { { quantity = tree } } end,
        }
        H2:update(1)
        T.has(H2:lastMsg(), "Você tem 3 ponto(s) de talento")
        H2:slash("aviso status")
        T.has(H2.strip(table.concat(H2.msgs, "/")), "talentos: 3 ponto(s) não gasto(s) (função: C_Traits)")
    end },

    { "a talent function that always returns 0 no longer hides real unspent points", function(T, Mock)
        -- Cenário provável do WoW Forever: existe uma função de outro sistema que sempre devolve 0.
        local H = Mock.new():login(); fixGear(H)
        H.env.GetUnspentTalentPoints = function() return 0 end
        H.env.GetNumTalentTabs = function() return 3 end
        local spent = { 10, 8, 0 } -- 18 pontos gastos no nível 30 (21 esperados) = 3 sobrando
        H.env.GetTalentTabInfo = function(tab) return "Árvore " .. tab, 135, spent[tab], "file" end
        H:update(1)
        T.has(H:lastMsg(), "Você tem 3 ponto(s) de talento para gastar.")
        H:slash("aviso status")
        local status = H.strip(table.concat(H.msgs, "/"))
        T.has(status, "talentos: 3 ponto(s) não gasto(s) (função: estimativa/estimate)")
        T.has(status, "GetUnspentTalentPoints: 0")
        T.has(status, "UnitCharacterPoints: nil")
        T.has(status, "GetTalentTabInfo: 10 / 8 / 0")
        T.has(status, "UnitLevel: 30")
    end },

    { "talent estimate reads both GetTalentTabInfo layouts and never goes negative", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login(); fixGear(H)
        H.env.GetUnspentTalentPoints = nil
        H.env.GetNumTalentTabs = function() return 3 end
        -- formato Wrath+: id, nome, descrição, ícone, pontosGastos
        H.env.GetTalentTabInfo = function(tab) return 160 + tab, "Tree", "desc", 135, ({ 5, 5, 5 })[tab] end
        H:update(1)
        T.has(H:lastMsg(), "You have 6 unspent talent point(s).", "21 expected - 15 spent")
        local H2 = Mock.new():login(); fixGear(H2)
        H2.env.GetUnspentTalentPoints = nil
        H2.env.GetNumTalentTabs = function() return 3 end
        H2.env.GetTalentTabInfo = function() return "Árvore", 135, 20 end -- 60 gastos (bônus do Forever)
        H2:update(1)
        T.eq(H2.warnSounds, 0, "more points spent than expected: no false warning")
    end },

    { "lower-rank spell on the bar is reported with the best known rank", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.actions = { [1] = { "spell", 143 }, [2] = { "spell", 116 }, [3] = { "spell", 118 }, [4] = { "macro", 5 } }
        H:event("ACTIONBAR_SLOT_CHANGED"); H:update(1)
        T.eq(H.warnSounds, 1)
        T.has(popupText(H), "Magia de grau antigo na barra: Bola de Fogo (Grau 2) — você já tem o Grau 3.")
        T.hasnt(popupText(H), "Seta de Gelo", "highest rank is fine")
        H:event("ACTIONBAR_SLOT_CHANGED"); H:update(6); T.eq(H.warnSounds, 1, "no repeat for the same spell")
        H.actions[1] = { "spell", 145 }; H:event("ACTIONBAR_SLOT_CHANGED"); H:update(6)
        H.actions[5] = { "spell", 133 }; H:event("ACTIONBAR_SLOT_CHANGED"); H:update(6)
        T.eq(H.warnSounds, 2, "a different outdated spell warns")
        H:slash("aviso status"); T.has(H.strip(table.concat(H.msgs, "/")), "magias de grau antigo na barra: 1.")
    end },

    { "spell ranks also work with the 3.3.5a spellbook API", function(T, Mock)
        local H = Mock.new({ mode = "wotlk", locale = "enUS" }):login(); fixGear(H)
        H.actions = { [10] = { "spell", 133 } }
        H:event("SPELLS_CHANGED"); H:update(1)
        T.has(H:lastMsg(), "Bola de Fogo (Rank 1) — you already know Rank 3")
    end },

    { "learning a new rank triggers the warning (level up)", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.actions = { [1] = { "spell", 116 } }
        H:update(1); T.eq(H.warnSounds, 0)
        H.spells[117] = { "Seta de Gelo", 2 }; H.book[#H.book + 1] = 117
        H:event("LEARNED_SPELL_IN_TAB"); H:update(6)
        T.has(popupText(H), "Seta de Gelo (Grau 1) — você já tem o Grau 2")
    end },

    { "popup: Silence keeps it quiet until the situation changes", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.talentPoints = 1; H:update(1)
        T.ok(H.env.FarolWarnPopup:IsShown())
        T.eq(H:text(H.env.FarolWarnSilence), "Silenciar"); T.eq(H:text(H.env.FarolWarnRemind), "Lembrar em 30 min")
        H:click(H.env.FarolWarnSilence)
        T.ok(not H.env.FarolWarnPopup:IsShown()); T.has(H:lastMsg(), "aviso silenciado")
        for _ = 1, 40 do H:update(60) end
        T.eq(H.warnSounds, 1, "silent even after 40 minutes")
    end },

    { "popup: Remind in 30 min warns again only if still a problem", function(T, Mock)
        local H = Mock.new():login(); fixGear(H)
        H.talentPoints = 1; H:update(1)
        H:click(H.env.FarolWarnRemind); T.has(H:lastMsg(), "aviso de novo às")
        for _ = 1, 29 do H:update(60) end; T.eq(H.warnSounds, 1, "not before 30 min")
        H:update(60); T.eq(H.warnSounds, 2, "reminder after 30 min"); T.ok(H.env.FarolWarnPopup:IsShown())
        H:slash("aviso lembrar")                          -- lembrar de novo pelo chat
        H.talentPoints = 0; for _ = 1, 31 do H:update(60) end
        T.eq(H.warnSounds, 2, "fixed in the meantime: no reminder")
    end },

    { "remind works for durability, bags and spell ranks too", function(T, Mock)
        local H = Mock.new():login()
        H:update(1) -- durabilidade 15% do simulador avisa no primeiro segundo
        T.has(popupText(H), "Durabilidade baixa: 15%")
        H:click(H.env.FarolWarnRemind)
        for _ = 1, 30 do H:update(60) end
        T.has(popupText(H), "Durabilidade baixa: 15%", "durability reminded")
        H:slash("aviso silenciar")
        H.bagFree = { [0] = 1, 0, 0, 0, 0 }; H:update(1)
        T.has(popupText(H), "Bolsas quase cheias: 1")
        H:slash("aviso lembrar"); for _ = 1, 30 do H:update(60) end
        T.has(popupText(H), "Bolsas quase cheias: 1", "bags reminded")
        H:slash("aviso silenciar")
        H.actions = { [1] = { "spell", 133 } }; H:event("ACTIONBAR_SLOT_CHANGED"); H:update(6)
        T.has(popupText(H), "Bola de Fogo (Grau 1)")
        H:slash("aviso lembrar"); for _ = 1, 31 do H:update(60) end
        T.has(popupText(H), "Bola de Fogo (Grau 1)", "ranks reminded")
    end },

    { "several warnings at once are shown one at a time", function(T, Mock)
        local H = Mock.new():login() -- durabilidade baixa já está na fila
        H.talentPoints = 2; H:update(1)
        T.has(popupText(H), "Durabilidade baixa")
        H:click(H.env.FarolWarnSilence)
        T.has(popupText(H), "Você tem 2 ponto(s) de talento")
        H:click(H.env.FarolWarnSilence)
        T.ok(not H.env.FarolWarnPopup:IsShown())
        H:slash("aviso silenciar"); T.has(H:lastMsg(), "nenhum aviso aberto")
    end },

    { "talent and rank warnings can be turned off", function(T, Mock)
        local H = Mock.new():login({ warnings = { talents = false, ranks = false } }); fixGear(H)
        H.talentPoints = 3; H.actions = { [1] = { "spell", 133 } }
        H:event("ACTIONBAR_SLOT_CHANGED"); H:update(6)
        T.eq(H.warnSounds, 0)
        H:slash("aviso talentos on"); H:update(1); T.eq(H.warnSounds, 1)
        H:slash("aviso graus on"); H:update(6); T.eq(H.warnSounds, 2)
        T.eq(H.env.FarolDB.warnings.ranks, true)
    end },
}
