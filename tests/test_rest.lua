-- Descanso dos seus personagens: gravado ao sair, estimativa (regras do estilo clássico), tooltip, aviso opcional.
-- Rested XP of your characters: saved on logout, classic-style estimate, tooltip, optional warning.

local H8 = 8 * 3600

local function alts(now)
    return { chars = { Azralon = {
        Jaina = { gold = 100, level = 34, t = now - 30 * H8, rest = 0, max = 10000, inn = true },  -- 30 x 5% = cheio
        Arthas = { gold = 100, level = 22, t = now - H8 + 60, rest = 0, max = 10000, inn = true }, -- ~5% (folga de 1 min)
        Uther = { gold = 100, level = 40, t = now - 4 * H8, rest = 1000, max = 10000 },            -- fora: 10% + 5% = 15%
        Thrall = { gold = 100, level = 60, t = now },                                              -- nível máximo
    } } }
end

local function fixGear(H)
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "logout saves the rested XP, the level's XP and whether you are in an inn/city", function(T, Mock)
        local H = Mock.new():login(); H.resting = true; H:update(1)
        H:event("PLAYER_LOGOUT")
        local me = H.env.FarolDB.chars.Azralon.Garrosh
        T.eq(me.rest, 1500); T.eq(me.max, 10000); T.eq(me.inn, true)
        local M = Mock.new():login(); M.xp.level = 60; M:update(1); M:event("PLAYER_LOGOUT")
        T.eq(M.env.FarolDB.chars.Azralon.Garrosh.rest, nil, "max level: nothing to rest")
    end },

    { "tooltip estimates the rested XP of your other characters (classic rules)", function(T, Mock)
        local H = Mock.new():login(alts(os.time())); fixGear(H); H:update(1)
        local text = tip(H)
        T.has(text, "Descanso dos seus personagens (estimativa)")
        T.has(text, "Jaina (34) = 150%  cheio  estalagem/cidade")
        T.has(text, "Uther (40) = 15%  cheio em ~")
        T.has(text, "fora")
        T.has(text, "Arthas (22) = 5%  cheio em ~9d 16h  estalagem/cidade") -- (15000 - 500) / (500 por 8 h)
        local block = string.match(text, "Descanso dos seus personagens %(estimativa%)(.-)Bolsas") or ""
        T.ok(block ~= "", "rest block found")
        T.hasnt(block, "Thrall", "max level not listed in the rest block")
        T.hasnt(block, "Garrosh", "current character not listed")
        local jaina, uther, arthas = string.find(text, "Jaina (34) = 150", 1, true), string.find(text, "Uther (40) = 15", 1, true),
            string.find(text, "Arthas (22) = 5", 1, true)
        T.ok(jaina < uther and uther < arthas, "fullest first")
    end },

    { "optional warning (off by default): once at login when another character is full", function(T, Mock)
        local H = Mock.new():login(alts(os.time())); fixGear(H); H:update(1)
        T.eq(H.warnSounds, 0, "off by default")
        local saved = alts(os.time()); saved.warnings = { restFull = true }
        local W = Mock.new():login(saved); fixGear(W); W:update(1)
        T.eq(W.warnSounds, 1)
        T.has(W:text(W.env.FarolWarnPopup.text), "Descanso cheio (150%): Jaina (34) — bom momento para jogar com eles.")
        W:click(W.env.FarolWarnRemindTime); W:click(W.env.FarolWarnRemindTimeEntry1) -- 2 min
        W:click(W.env.FarolWarnRemind)
        W:update(60); T.eq(W.warnSounds, 1)
        W:update(61); T.eq(W.warnSounds, 2, "reminded")
        W:click(W.env.FarolWarnSilence)
        for _ = 1, 30 do W:update(60) end; T.eq(W.warnSounds, 2, "once per session")
        W:slash("aviso descansado off"); T.eq(W.env.FarolDB.warnings.restFull, false)
        T.eq(W.env.FarolDB.warnings.pause, false, "'descanso' still means the break reminder (unchanged)")
        W:slash("aviso descanso on"); T.eq(W.env.FarolDB.warnings.pause, true)
        T.eq(W.env.FarolDB.warnings.restFull, false)
        W:slash("aviso")
        T.eq(W:text(W.env.FarolWarnRestFull.label), "Avisar ao entrar se outro personagem estiver com o descanso cheio")
    end },

    { "no warning when nobody is full", function(T, Mock)
        local saved = alts(os.time()); saved.chars.Azralon.Jaina = nil; saved.warnings = { restFull = true }
        local H = Mock.new():login(saved); fixGear(H); H:update(1)
        T.eq(H.warnSounds, 0)
    end },

    { "tampered rest data is cleaned; English texts", function(T, Mock)
        local now = os.time()
        local saved = { chars = { Azralon = {
            A = { gold = 1, level = 10, t = now, rest = 0 / 0, max = 10000 },
            B = { gold = 1, level = 10, t = now, rest = 10, max = 0 },
            C = { gold = 1, level = 10, t = now, rest = 10, max = 1e10 },
            D = { gold = 1, level = 10, t = now, rest = 10, max = 100, inn = "sim" },
        } } }
        local H = Mock.new({ locale = "enUS" }):login(saved); fixGear(H); H:update(1)
        local chars = H.env.FarolDB.chars.Azralon
        T.eq(chars.A.rest, nil); T.eq(chars.B.rest, nil); T.eq(chars.C.rest, nil)
        T.eq(chars.D.rest, 10); T.eq(chars.D.inn, false, "invalid inn flag becomes false")
        T.eq(chars.A.gold, 1, "the rest of the record is kept")
        T.has(tip(H), "Rested XP of your characters (estimate)")
        T.has(tip(H), "D (10) = 10%  full in ~")
        T.has(tip(H), "outside")
    end },
}
