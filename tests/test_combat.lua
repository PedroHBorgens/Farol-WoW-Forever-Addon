-- Registro de combate (3.35): lido do medidor de dano do jogo depois da luta + números de combate (UNIT_COMBAT).
-- Desligado até o jogador ligar; 50 lutas; nomes de outros jogadores só na sessão; nunca apaga as lutas do jogo.
-- Combat log: read from the game's damage meter after each fight + UNIT_COMBAT counts. Off until turned on;
-- 50 fights; other players' names only for the session; never resets the game's sessions.

local ME = "Player-1-0000AAAA"

-- Uma luta no formato que o WoW Forever devolve (lido com /run no jogo, 3.35).
local function addFight(H, id, o)
    o = o or {}
    local m = H.meter
    if not m then return end -- cliente antigo: sem medidor de dano
    m.sessions[#m.sessions + 1] = { sessionID = id, name = o.name or "Guerreiro do Pântano", durationSeconds = o.dur or 6 }
    local enemy = o.enemy or { name = o.name or "Guerreiro do Pântano", sourceGUID = "Creature-0-1-2", totalAmount = o.dealt or 784 }
    local enemies = { enemy }
    for _, e in ipairs(o.more or {}) do enemies[#enemies + 1] = e end
    local allies = { { name = "Oxis", isLocalPlayer = true, sourceGUID = ME, totalAmount = o.dealt or 784, classFilename = "ROGUE",
        deathTimeSeconds = o.died and 5 or 0 } }
    for _, a in ipairs(o.allies or {}) do allies[#allies + 1] = a end
    m.by[id] = {
        [0] = { combatSources = allies, totalAmount = o.dealt or 784 },
        [2] = { combatSources = { { isLocalPlayer = true, sourceGUID = ME, totalAmount = o.heal or 0 } } },
        [7] = { combatSources = { { name = "Oxis", isLocalPlayer = true, sourceGUID = ME, totalAmount = o.taken or 112 } } },
        [10] = { combatSources = enemies },
    }
    m.src[id] = {
        [0] = { [ME] = { combatSpells = o.spells or { { spellID = 1759, totalAmount = 375 }, { spellID = 6603, totalAmount = 300 },
            { spellID = 1752, totalAmount = 109 } } } },
        [7] = { [ME] = { combatSpells = o.hits or { { spellID = 6603, totalAmount = o.taken or 112, isAvoidable = false, isDeadly = false,
            combatSpellDetails = { { unitName = enemy.name, amount = o.taken or 112, isMob = not o.pvp, isPet = false,
                unitClassFilename = "WARRIOR" } } } } } },
    }
end

local function setup(Mock, opts, saved, savedChar)
    local H = Mock.new(opts or { locale = "ptBR" })
    H.spells[1759] = { "Golpe Rápido", 1 }; H.spells[6603] = { "Ataque corpo a corpo", 1 }; H.spells[1752] = { "Estocada", 1 }
    saved = saved or {}
    if saved.hub == nil then saved.hub = false end
    H:login(saved, savedChar)
    return H
end

-- Uma luta inteira: entra em combate, golpes, sai, e o Farol lê no segundo seguinte.
local function fight(H, id, o)
    H:event("PLAYER_REGEN_DISABLED")
    H:event("UNIT_COMBAT", "target", "WOUND", "", 73, 1); H:event("UNIT_COMBAT", "target", "WOUND", "", 73, 1) -- cópia
    H:event("UNIT_COMBAT", "target", "WOUND", "CRITICAL", 150, 1)
    H:event("UNIT_COMBAT", "target", "MISS", "", 0, 1)
    H:event("UNIT_COMBAT", "target", "WOUND", "BLOCK_REDUCED", 16, 1)
    H:event("UNIT_COMBAT", "player", "WOUND", "", 22, 1)
    H:event("UNIT_COMBAT", "player", "DODGE", "", 0, 1)
    if o and o.duel then H:event("DUEL_FINISHED") end
    if o and o.died then H:event("PLAYER_DEAD") end
    addFight(H, id, o)
    H:event("PLAYER_REGEN_ENABLED")
    H.now = H.now + 1; H:update(1)
end

local function all(H) return H.strip(table.concat(H.msgs, "\n")) end
local function list(H) return H.env.FarolCharDB.combat.list end
local function hasText(t, text, seen)
    seen = seen or {}
    if type(t) == "string" then return string.find(t, text, 1, true) ~= nil end
    if type(t) ~= "table" or seen[t] then return false end
    seen[t] = true
    for k, v in pairs(t) do if hasText(k, text, seen) or hasText(v, text, seen) then return true end end
    return false
end

return {
    { "off by default (rule 8): nothing is read or saved; the window explains and turns it on", function(T, Mock)
        local H = setup(Mock)
        T.eq(H.env.FarolDB.combatLog, false, "off on a new install")
        fight(H, 1)
        T.eq(#list(H), 0, "nothing saved while off")
        H:slash("combate")
        local W = H.env.FarolCombat
        T.ok(W and W:IsShown(), "window opens")
        T.has(H:text(W.offText), "Ligue para guardar as suas 50 últimas lutas")
        T.eq(H:text(W.toggle), "Ligar registro")
        H:click(W.toggle)
        T.eq(H.env.FarolDB.combatLog, true); T.has(all(H), "registro de combate ligado")
        T.has(H:text(W.offText), "Nenhuma luta registrada ainda")
        -- a luta de antes de ligar não entra
        H.now = H.now + 1; H:update(1); T.eq(#list(H), 0, "fights from before turning it on are skipped")
    end },

    { "a fight: title, numbers, your abilities with icon and the game's tooltip, what hit you, counts", function(T, Mock)
        local H = setup(Mock, nil, { combatLog = true })
        fight(H, 1)
        local f = list(H)[1]
        T.ok(f, "fight saved")
        T.eq(f.n, "Guerreiro do Pântano"); T.eq(f.d, 784); T.eq(f.tk, 112); T.eq(f.s, 6); T.eq(f.r, "w")
        T.eq(#f.sp, 3); T.eq(f.sp[1].i, 1759); T.eq(f.sp[1].a, 375)
        T.eq(f.hits[1].n, "Guerreiro do Pântano"); T.eq(f.hits[1].a, 112); T.eq(f.hits[1].i, 6603)
        T.eq(f.u.hit, 3, "the repeated event counts once"); T.eq(f.u.crit, 1); T.eq(f.u.miss, 1); T.eq(f.u.blk, 1)
        T.eq(f.u.got, 1); T.eq(f.u.avoid, 1)
        T.eq(H.meterReset, nil, "never resets the game's sessions")
        H:slash("combate")
        local W = H.env.FarolCombat
        T.has(H:text(W.fights[1].title), "Guerreiro do Pântano"); T.has(H:text(W.fights[1].result), "vitória")
        T.eq(H:text(W.fights[1].nums), "784 / 112")
        local row = W.spells[1]
        T.eq(H:text(row.name), "Golpe Rápido"); T.has(H:text(row.value), "375 · 48%")
        T.eq(row.icon._texture, 101759, "the ability's own icon")
        row._scripts.OnEnter(row)
        T.eq(H.env.GameTooltip.spell, 1759, "hovering shows the game's own explanation of the ability")
        row._scripts.OnLeave(row)
        T.eq(H:text(W.hits[1].who.left), "Guerreiro do Pântano"); T.eq(H:text(W.hits[1].name), "Ataque corpo a corpo")
        T.has(H:text(W.lines[1].right), "1 de 3 golpes")
        local p = W.farolPanels
        T.has(H:text(p.pos.title), "Positivo"); T.has(H:text(p.neg.title), "Negativo"); T.eq(H:text(p.part.title), "Participantes")
        T.eq(H:text(W.people[1].left), "você · Ladino"); T.has(H:text(W.people[2].left), "Guerreiro do Pântano · monstro")
        H.msgs = {}; H:slash("diagnostico")
        T.has(all(H), "Combate: medidor de dano do jogo disponível · lutas no medidor: 1 · registro do Farol: ligado · lutas guardadas: 1")
        T.eq(H:text(W.farolPanels.list.sub), "1 guardada")
    end },

    { "other players' names only in this session: duel title, participant and hitter become 'another player' on disk", function(T, Mock)
        local H = setup(Mock, nil, { combatLog = true })
        fight(H, 1, { name = "Mira", duel = true, pvp = true, enemy = { name = "Mira", sourceGUID = "Player-2-0000BBBB", totalAmount = 900,
            classFilename = "MAGE" }, allies = { { name = "Tobin", sourceGUID = "Player-3-0000CCCC", totalAmount = 50, classFilename = "PRIEST" } } })
        local f = list(H)[1]
        T.eq(f.k, "duel"); T.eq(f.np, true); T.eq(f.n, nil)
        T.ok(not hasText(H.env.FarolCharDB, "Mira"), "the opponent's name is not in the saved data")
        T.ok(not hasText(H.env.FarolCharDB, "Tobin"), "the ally's name is not in the saved data")
        H:slash("combate")
        local W = H.env.FarolCombat
        T.eq(H:text(W.fights[1].title), "Duelo: Mira", "shown during the session"); T.has(H:text(W.fights[1].result), "duelo")
        T.eq(H:text(W.hits[1].who.left), "Mira")
        -- depois do /reload: os dados salvos não têm o nome
        local R = setup(Mock, nil, { combatLog = true }, H.env.FarolCharDB)
        R:slash("combate")
        T.eq(R:text(R.env.FarolCombat.fights[1].title), "Duelo: outro jogador")
        T.eq(R:text(R.env.FarolCombat.hits[1].who.left), "outro jogador")
    end },

    { "defeat when you die; keeps the 50 most recent; clear asks first; English texts", function(T, Mock)
        local H = setup(Mock, nil, { combatLog = true })
        fight(H, 1, { died = true })
        T.eq(list(H)[1].r, "l"); T.eq(list(H)[1].dd, 1)
        for id = 2, 56 do fight(H, id) end
        T.eq(#list(H), 50, "only the last 50"); T.eq(H.env.FarolCharDB.combat.last, 56)
        H:slash("combate")
        local W = H.env.FarolCombat
        H:click(W.clear); T.eq(#list(H), 50, "first click only asks"); T.has(H:text(W.clear), "Apagar 50 lutas?")
        H:click(W.clear); T.eq(#list(H), 0, "second click clears")
        H:slash("combate desligar"); T.eq(H.env.FarolDB.combatLog, false)
        local E = setup(Mock, { locale = "enUS" }, { combatLog = true })
        fight(E, 1)
        E:slash("combat")
        T.has(E:text(E.env.FarolCombat.fights[1].result), "victory")
        T.has(E:text(E.env.FarolCombat.farolPanels.neg.sub), "what hit you")
        E:slash("combat xyz"); T.has(all(E), "usage: /farol combat")
    end },

    { "no damage meter (older client) or errors from the game: a message, never an error", function(T, Mock)
        local H = setup(Mock, { locale = "ptBR", mode = "wotlk" }, { combatLog = true })
        fight(H, 1)
        H:slash("combate")
        T.has(H:text(H.env.FarolCombat.offText), "medidor de dano do jogo não está disponível")
        local B = setup(Mock, nil, { combatLog = true })
        B.env.C_DamageMeter.GetCombatSessionFromID = function() error("blocked") end
        B.env.C_DamageMeter.GetCombatSessionSourceFromID = function() return { combatSpells = { { spellID = 0 / 0 }, "x" } } end
        fight(B, 1)
        B:slash("combate"); T.ok(B.env.FarolCombat:IsShown(), "still works")
        local C = setup(Mock, nil, { combatLog = true })
        C.env.C_DamageMeter.GetAvailableCombatSessions = function() return { { sessionID = 1 / 0 }, { sessionID = "x" }, 5 } end
        fight(C, 1); T.eq(#list(C), 0)
    end },

    { "tampered saved data is cleaned on load", function(T, Mock)
        local big = {}
        for i = 1, 5000 do big[i] = { t = 1800000000 - i, n = "Luta " .. i, d = 1, tk = 1, s = 1 } end
        big[1] = { t = 0 / 0 }
        big[2] = { t = 1800000000, n = "Ruim|cffff0000", d = -5, tk = 1 / 0, s = "x", np = true,
            hits = { { i = 6603, a = 5, n = "Alguém", pl = true }, { i = "x" } },
            pa = { { n = "Jogador", pl = true, a = 1, b = 2 }, { n = string.rep("A", 5000), a = 1 } }, u = { hit = 0 / 0 } }
        local H = setup(Mock, nil, { combatLog = true }, { combat = { list = big, last = -3 } })
        local data = H.env.FarolCharDB.combat
        T.eq(#data.list, 49, "50 looked at, the broken one dropped"); T.eq(data.last, 0)
        local f = data.list[1]
        T.eq(f.n, nil, "a player-named fight keeps no name"); T.eq(f.d, 0); T.eq(f.tk, 0); T.eq(f.s, 0)
        T.eq(f.hits[1].n, nil, "player names never come back from disk"); T.eq(#f.hits, 1)
        T.eq(f.pa[1].n, nil); T.ok(#(f.pa[2].n or "") <= 48 * 4, "long names cut")
        T.eq(f.u.hit, 0)
    end },

    { "inside the hub: the Combat section opens the window in cards", function(T, Mock)
        local H = setup(Mock, nil, { combatLog = true, hub = true })
        fight(H, 1)
        H:slash("central")
        T.eq(H:text(H.env.FarolHubNavcombat.text), "Combates")
        H:click(H.env.FarolHubNavcombat)
        local W = H.env.FarolCombat
        T.ok(W:IsShown()); T.eq(W:GetParent(), H.env.FarolHubContent, "docked")
        T.ok(not W.title:IsShown(), "no title inside the hub")
        T.has(H:text(W.fights[1].title), "Guerreiro do Pântano")
    end },
}
