-- Profissões: item da barra, tooltip, aviso "procure um instrutor", API moderna e clássica, valores ruins.
-- Professions: bar item, tooltip, "find a trainer" warning, modern and classic APIs, bad values.

local function fixGear(H)
    H.durability = { [1] = { 100, 100 } }
    H:event("UPDATE_INVENTORY_DURABILITY")
end

local function setup(Mock, opts, saved)
    local H = Mock.new(opts)
    if opts and opts.profs then H.profs = opts.profs end
    H:login(saved); fixGear(H)
    H:update(1)
    return H
end

local function profCell(H)
    for _, cell in ipairs(H:cells()) do
        local text = cell._text or ""
        if string.find(text, "Minera", 1, true) or string.find(text, "Prof", 1, true)
            or string.find(text, "Culin", 1, true) then return text end
    end
    return ""
end

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

return {
    { "bar item is off by default; shows the main professions with level/limit", function(T, Mock)
        local H = setup(Mock)
        T.hasnt(H:bar(), "Mineração", "off by default")
        H:slash("show prof"); H:update(1)
        T.has(H:bar(), "Mineração 148/150 · Herborismo 92/150")
        T.hasnt(H:bar(), "Culinária", "secondary professions only in the tooltip")
        T.has(profCell(H), "|cffffff3a148/150|r", "yellow when 5 or fewer points from the limit")
        T.hasnt(profCell(H), "|cffffff3a92", "normal color far from the limit")
        T.eq(H.env.FarolDB.items.prof, true)
    end },

    { "tooltip lists every profession, with points gained this session", function(T, Mock)
        local H = setup(Mock)
        H:slash("show profissoes"); H:update(1)
        H.profs[1][2] = 150; H.profs[3][2] = 63; H:update(1)
        local text = tip(H)
        T.has(text, "Mineração = 150/150 (+2 nesta sessão)")
        T.has(text, "no máximo do treinamento — procure um instrutor")
        T.has(text, "Herborismo = 92/150")
        T.has(text, "Culinária = 63/75 (+3 nesta sessão)")
        H:slash("sessao zerar"); H:update(1)
        T.hasnt(tip(H), "nesta sessão", "session reset restarts the count")
    end },

    { "only secondary professions: the bar shows those; none at all: 'Prof --'", function(T, Mock)
        local H = setup(Mock, { profs = { { "Culinária", 70, 75, false }, { "Pesca", 10, 75, false } } })
        H:slash("show prof"); H:update(1)
        T.has(H:bar(), "Culinária 70/75 · Pesca 10/75")
        local N = setup(Mock, { profs = {} })
        N:slash("show prof"); N:update(1)
        T.has(N:bar(), "Prof --"); T.has(tip(N), "Profissões = nenhuma profissão aprendida")
    end },

    { "'find a trainer' warning: once per limit, again at the next limit, never at 300", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.warnSounds, 0)
        H.profs[1][2] = 150; H:update(1)
        T.eq(H.warnSounds, 1)
        T.has(H:text(H.env.FarolWarnPopup.text), "Mineração 150/150 no máximo do treinamento — procure um instrutor")
        H:click(H.env.FarolWarnSilence)
        for _ = 1, 30 do H:update(60) end; T.eq(H.warnSounds, 1, "no repeat at the same limit")
        H.profs[1][3] = 225; H:update(1); T.eq(H.warnSounds, 1, "trained: new limit, still below it")
        H.profs[1][2] = 225; H:update(1); T.eq(H.warnSounds, 2, "warns at the next limit")
        H:click(H.env.FarolWarnSilence)
        H.profs[1][3] = 300; H.profs[1][2] = 300; H:update(1)
        T.eq(H.warnSounds, 2, "300/300: nothing left to train")
        H:slash("show prof"); H:update(1)
        T.has(profCell(H), "|cff40ff40300/300|r", "green at the final limit")
    end },

    { "two professions at the limit together: one warning listing both", function(T, Mock)
        local H = setup(Mock, { profs = { { "Mineração", 140, 150, true }, { "Ferraria", 140, 150, true } } })
        H.profs[1][2] = 150; H.profs[2][2] = 150; H:update(1)
        T.eq(H.warnSounds, 1)
        T.has(H:text(H.env.FarolWarnPopup.text), "Mineração 150/150, Ferraria 150/150")
    end },

    { "waits for combat; remind works; can be turned off (command and window)", function(T, Mock)
        local H = setup(Mock)
        H.profs[1][2] = 150; H.inCombat = true; H:update(1)
        T.eq(H.warnSounds, 0, "waits during combat")
        H.inCombat = false; H:update(1); T.eq(H.warnSounds, 1)
        H:click(H.env.FarolWarnRemindTime); H:click(H.env.FarolWarnRemindTimeEntry2) -- 5 min
        H:click(H.env.FarolWarnRemind)
        for _ = 1, 5 do H:update(60) end; H:update(1)
        T.eq(H.warnSounds, 2, "reminded after 5 min while still at the limit")
        H:click(H.env.FarolWarnSilence)
        H:slash("aviso profissoes off"); T.eq(H.env.FarolDB.warnings.prof, false)
        H.profs[2][2] = 150; H:update(1); T.eq(H.warnSounds, 2, "off: no warning")
        H:slash("aviso")
        T.eq(H:text(H.env.FarolWarnProf.label), "Avisar quando uma profissão chegar ao máximo do treinamento")
        H:check(H.env.FarolWarnProf, true); H:update(1)
        T.eq(H.warnSounds, 3, "turned on again: warns about the profession at the limit")
    end },

    { "classic API (3.3.5a): reads the professions group, ignores weapons and defense", function(T, Mock)
        local H = setup(Mock, { mode = "wotlk", locale = "enUS" })
        H:slash("show prof"); H:update(1)
        T.has(H:bar(), "Mineração 148/150 · Herborismo 92/150")
        T.hasnt(H:bar(), "Espadas"); T.hasnt(H:bar(), "Defesa")
        T.has(tip(H), "Culinária = 60/75")
        T.hasnt(tip(H), "Espadas", "weapon skills (150/150) are not professions")
        H:slash("warn status")
        T.has(H.strip(table.concat(H.msgs, "/")), "professions: Mineração 148/150, Herborismo 92/150, Culinária 60/75 (function: GetSkillLineInfo).")
        H.profs[1][2] = 150; H:update(1)
        T.has(H:text(H.env.FarolWarnPopup.text), "Mineração 150/150 at the training limit — find a trainer to keep leveling.")
    end },

    { "status shows the modern function too", function(T, Mock)
        local H = setup(Mock)
        H:slash("aviso status")
        T.has(H.strip(table.concat(H.msgs, "/")), "profissões: Mineração 148/150, Herborismo 92/150, Culinária 60/75 (função: GetProfessions).")
    end },

    { "bad or blocked values are ignored; names cannot inject chat codes", function(T, Mock)
        local H = setup(Mock, { profs = {
            { "Evil|Hitem:1|h[x]|h", 150, 150, true }, { "NaN", 0 / 0, 150, true },
            { "Inf", 10, math.huge, false }, { "", 10, 75, false }, { "Neg", -1, 75, false } } })
        H:slash("show prof"); H:update(1)
        T.has(H:barRaw(), "Evil||Hitem:1||h[x]||h", "name shown as plain text")
        T.hasnt(H:bar(), "NaN"); T.hasnt(H:bar(), "Inf"); T.hasnt(H:bar(), "Neg")
        T.hasnt(H.env.FarolCharDB.warnHistory[#H.env.FarolCharDB.warnHistory].text, "|", "history has no codes")
        H.env.GetProfessions = function() error("blocked by the game") end
        H.env.GetProfessionInfo = function() error("blocked") end
        H:update(1); T.has(H:bar(), "Prof --", "API error: no crash")
        H.env.GetProfessions = nil
        H:update(1); tip(H)
    end },
}
