-- Reino não informado (3.15.1): o WoW Forever devolve GetRealmName() == "". O Farol usa um reino de reserva fixo
-- ("-", mostrado como "este reino") em vez de descartar o personagem: missões concluídas, ouro dos personagens,
-- perfis e diagnóstico funcionam.
-- Realm not reported (3.15.1): WoW Forever returns an empty realm; a fixed fallback realm is used instead.

local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

return {
    { "empty or missing realm: the character is still identified, with a fallback realm", function(T, Mock)
        for _, realm in ipairs({ "", false }) do
            local H = Mock.new({ locale = "ptBR" }); H.realm = realm or nil
            H.env.GetNormalizedRealmName = function() return "" end
            H:login()
            local name, r = H.ns.CurrentCharacter()
            T.eq(name, "Garrosh"); T.eq(r, "-")
            T.eq(H.ns.RealmLabel(r), "este reino")
            H:slash("aviso status"); T.has(all(H), "personagem: Garrosh · reino: o jogo não informou (usando um reino de reserva)")
        end
    end },

    { "completed quests, gold of your characters and profiles work without a realm", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.realm = ""; H.completedIDs = { 1, 2, 3 }
        H:login({ questRecord = true, chars = { ["-"] = { Mira = { gold = 50000, level = 34, t = 1 } } },
                  completed = { ["-"] = { Mira = { t = 9 } } } })
        H.rewardQuest = { id = 501, title = "Entrega" }; H:event("QUEST_COMPLETE"); H.rewardQuest = nil
        H:event("QUEST_TURNED_IN", 501, 0, 0)
        local own = H.env.FarolDB.completed["-"].Garrosh
        T.eq(own.list[1].n, "Entrega"); T.eq(own.t, 4)
        H:slash("concluidas")
        T.eq(H:text(H.env.FarolCompletedChar), "Garrosh — este")
        H:click(H.env.FarolCompletedChar)
        T.eq(H:text(H.env.FarolCompletedCharEntry2.text), "Mira", "other characters of the same (fallback) realm")
        H:event("PLAYER_LOGOUT")
        T.ok(H.env.FarolDB.chars["-"].Garrosh, "gold/level of this character saved")
        H:slash("ouro"); T.has(all(H), "ouro dos seus personagens em este reino")
        H:slash("mostrar ouro"); H:slash("ouro total on"); H:update(1)
        H.env.GameTooltip.lines = {}; H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        T.has(H.strip(table.concat(H.env.GameTooltip.lines, " / ")), "Ouro na conta (este reino)")
        H:slash("perfil personagem"); T.eq(H.env.FarolCharDB.profile, "char", "per-character profile works")
        T.ok(H.env.FarolDB.profiles.chars["-"].Garrosh)
        local E = Mock.new({ locale = "enUS" }); E.realm = ""; E:login(); E:slash("gold")
        T.has(all(E), "gold of your characters on this realm")
    end },

    { "a normal realm is unchanged", function(T, Mock)
        local H = Mock.new():login()
        local name, realm = H.ns.CurrentCharacter()
        T.eq(name, "Garrosh"); T.eq(realm, "Azralon"); T.eq(H.ns.RealmLabel(realm), "Azralon")
    end },

    { "WoW Forever surname: UnitName returns (name, surname); the character is 'Name Surname'", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.realm = ""; H.completedIDs = { 1 }
        H.env.UnitName = function(unit) if unit == "player" then return "Oxis", "Raknash" end end
        H:login({ questRecord = true })
        local name, realm = H.ns.CurrentCharacter()
        T.eq(name, "Oxis Raknash"); T.eq(realm, "-")
        H:event("QUEST_TURNED_IN", 77, 0, 0)
        T.ok(H.env.FarolDB.completed["-"]["Oxis Raknash"], "saved under name + surname")
        H:slash("concluidas"); T.eq(H:text(H.env.FarolCompletedChar), "Oxis Raknash — este")
        H:slash("aviso status"); T.has(H.strip(table.concat(H.msgs, "\n")), "personagem: Oxis Raknash")
        -- Segundo valor igual ao reino (WoW comum com outro reino) ou inválido: só o nome.
        for _, second in ipairs({ "Azralon", "", "a|b", string.rep("x", 60) }) do
            local N = Mock.new()
            N.env.UnitName = function(unit) if unit == "player" then return "Garrosh", second end end
            N:login(); T.eq((N.ns.CurrentCharacter()), "Garrosh", "second value '" .. second:sub(1, 8) .. "' ignored")
        end
    end },

    { "/farol ouro never stays silent: lists this character (WoW Forever) or says the name is not known yet", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H.realm = ""
        H.env.UnitName = function(unit) if unit == "player" then return "Oxis", "Raknash" end end
        H:login(); H.msgs = {}
        H:slash("ouro")
        local text = H.strip(table.concat(H.msgs, "\n"))
        T.has(text, "ouro dos seus personagens em este reino"); T.has(text, "Oxis Raknash (")
        local N = Mock.new({ locale = "ptBR" }); N.env.UnitName = function() return nil end
        N:login(); N.msgs = {}; N:slash("ouro")
        T.has(N.strip(table.concat(N.msgs, "\n")), "o jogo ainda não informou o nome do personagem")
    end },
}
