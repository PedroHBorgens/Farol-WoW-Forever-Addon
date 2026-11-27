--[[
  Farol - registro de combate (3.35)

  O registro de combate do jogo (COMBAT_LOG_EVENT_UNFILTERED) é bloqueado para addons no WoW Forever, como no
  Midnight ("ForceTaint_Strong", confirmado no jogo). Este módulo usa só leituras liberadas:
    - o medidor de dano do próprio jogo (C_DamageMeter: GetAvailableCombatSessions, GetCombatSessionFromID,
      GetCombatSessionSourceFromID), lido DEPOIS que a luta acaba: participantes, habilidades, quem te acertou;
    - os números de combate (UNIT_COMBAT, você e o alvo): acertos, críticos, erros, esquivas, bloqueios.
  Nunca apaga as lutas do jogo (ResetAllCombatSessions), nunca mexe no C_CombatLog e não envia nada.

  Desligado até o jogador ligar (regra 8: db.combatLog). Guarda as últimas 50 lutas em FarolCharDB.combat.
  Nomes de OUTROS jogadores ficam só na memória desta sessão (decisão do dono): no disco viram "outro jogador".
]]

local _, ns = ...
local Combat = {}
ns.Combat = Combat

local MAX_FIGHTS, MAX_SPELLS, MAX_HITS, MAX_PEOPLE = 50, 10, 10, 10
local NAME_MAX = 48
local DMG, HEAL, TAKEN, ENEMY = 0, 2, 7, 10 -- Enum.DamageMeterType (lido no jogo: DamageDone=0, HealingDone=2...)
local LIST_ROWS = 8 -- lutas visíveis na lista (a roda do mouse rola)

local STRINGS = {
    pt = {
        cbt_title      = "Combates",
        cbt_list       = "Últimas lutas",
        cbt_list_sub   = "%d guardadas", cbt_list_sub_1 = "%d guardada",
        cbt_list_foot  = "dano causado / dano recebido",
        cbt_win        = "vitória",
        cbt_loss       = "derrota",
        cbt_duel       = "duelo",
        cbt_duel_vs    = "Duelo: %s",
        cbt_more       = "%s (+%d)",
        cbt_fight      = "Luta",
        cbt_dur        = "Duração",
        cbt_done       = "Dano causado",
        cbt_taken      = "Dano recebido",
        cbt_heal       = "Cura",
        cbt_deaths     = "Mortes",
        cbt_per_sec    = "%s/s",
        cbt_pos        = "Positivo",
        cbt_pos_sub    = "suas habilidades",
        cbt_neg        = "Negativo",
        cbt_neg_sub    = "o que te acertou",
        cbt_crits      = "Críticos",
        cbt_crits_v    = "%d de %d golpes",
        cbt_avoid      = "Esquivas e bloqueios",
        cbt_missed     = "Golpes que erraram",
        cbt_blocked    = "Bloqueados pelo alvo",
        cbt_avoidable  = "evitável",
        cbt_deadly     = "mortal",
        cbt_people     = "Participantes",
        cbt_people_sub = "quem lutou",
        cbt_allies     = "ALIADOS",
        cbt_enemies    = "OPONENTES",
        cbt_you        = "você",
        cbt_other      = "outro jogador",
        cbt_mob        = "monstro",
        cbt_pet        = "mascote",
        cbt_dealt_taken = "%s causado · %s recebido",
        cbt_no_spells  = "nenhuma habilidade com dano",
        cbt_no_hits    = "nada te acertou",
        cbt_none       = "--",
        cbt_off_title  = "Registro de combate desligado",
        cbt_off_text   = "Ligue para guardar as suas 50 últimas lutas: habilidades, quem te acertou, participantes, críticos, erros e bloqueios. Os números vêm do medidor de dano do próprio jogo, lido depois de cada luta; nada é enviado.",
        cbt_turn_on    = "Ligar registro",
        cbt_turn_off   = "Desligar",
        cbt_empty      = "Nenhuma luta registrada ainda: lute com um monstro e ela aparece aqui.",
        cbt_no_meter   = "O medidor de dano do jogo não está disponível neste cliente: o registro não tem de onde ler.",
        cbt_clear      = "Limpar",
        cbt_clear_ask  = "Apagar %d lutas?",
        cbt_clear_ask_1 = "Apagar %d luta?",
        cbt_on         = "registro de combate ligado: as próximas lutas aparecem em /farol combate.",
        cbt_off        = "registro de combate desligado (as lutas guardadas continuam lá).",
        cbt_cleared    = "lutas apagadas.",
        cbt_usage      = "uso: /farol combate || /farol combate ligar||desligar||limpar",
        help_combat   = "  /farol combate       - registro de combate: últimas lutas, habilidades e quem te acertou",
        tool_combat   = "Combates...",     tool_combat_desc = "últimas lutas: habilidades, quem te acertou",
        news_combat   = "Registro de combate: as últimas 50 lutas com suas habilidades, quem te acertou, participantes e críticos — desligado (ligue em /farol combate)",
        hub_combat    = "Combates",
        cbt_diag      = "Combate: medidor de dano do jogo %s · lutas no medidor: %s · registro do Farol: %s · lutas guardadas: %d · registro de combate do jogo para addons: %s",
        cbt_diag_yes  = "disponível", cbt_diag_no = "indisponível", cbt_diag_on = "ligado", cbt_diag_off = "desligado",
        cbt_diag_restricted = "restrito", cbt_diag_free = "liberado",
    },
    en = {
        cbt_title      = "Combat",
        cbt_list       = "Recent fights",
        cbt_list_sub   = "%d saved", cbt_list_sub_1 = "%d saved",
        cbt_list_foot  = "damage done / damage taken",
        cbt_win        = "victory",
        cbt_loss       = "defeat",
        cbt_duel       = "duel",
        cbt_duel_vs    = "Duel: %s",
        cbt_more       = "%s (+%d)",
        cbt_fight      = "Fight",
        cbt_dur        = "Duration",
        cbt_done       = "Damage done",
        cbt_taken      = "Damage taken",
        cbt_heal       = "Healing",
        cbt_deaths     = "Deaths",
        cbt_per_sec    = "%s/s",
        cbt_pos        = "Positive",
        cbt_pos_sub    = "your abilities",
        cbt_neg        = "Negative",
        cbt_neg_sub    = "what hit you",
        cbt_crits      = "Critical hits",
        cbt_crits_v    = "%d of %d hits",
        cbt_avoid      = "Dodges and blocks",
        cbt_missed     = "Missed attacks",
        cbt_blocked    = "Blocked by the target",
        cbt_avoidable  = "avoidable",
        cbt_deadly     = "deadly",
        cbt_people     = "Participants",
        cbt_people_sub = "who fought",
        cbt_allies     = "ALLIES",
        cbt_enemies    = "OPPONENTS",
        cbt_you        = "you",
        cbt_other      = "another player",
        cbt_mob        = "creature",
        cbt_pet        = "pet",
        cbt_dealt_taken = "%s done · %s taken",
        cbt_no_spells  = "no ability did damage",
        cbt_no_hits    = "nothing hit you",
        cbt_none       = "--",
        cbt_off_title  = "Combat log is off",
        cbt_off_text   = "Turn it on to keep your last 50 fights: abilities, what hit you, participants, critical hits, misses and blocks. The numbers come from the game's own damage meter, read after each fight; nothing is sent.",
        cbt_turn_on    = "Turn on",
        cbt_turn_off   = "Turn off",
        cbt_empty      = "No fights recorded yet: fight a creature and it shows up here.",
        cbt_no_meter   = "The game's damage meter is not available in this client: the log has nothing to read.",
        cbt_clear      = "Clear",
        cbt_clear_ask  = "Delete %d fights?",
        cbt_clear_ask_1 = "Delete %d fight?",
        cbt_on         = "combat log on: the next fights show up in /farol combat.",
        cbt_off        = "combat log off (saved fights stay there).",
        cbt_cleared    = "fights deleted.",
        cbt_usage      = "usage: /farol combat || /farol combat on||off||clear",
        help_combat   = "  /farol combat        - combat log: recent fights, abilities and what hit you",
        tool_combat   = "Combat...",       tool_combat_desc = "recent fights: abilities, what hit you",
        news_combat   = "Combat log: your last 50 fights with your abilities, what hit you, participants and critical hits — off (turn it on in /farol combat)",
        hub_combat    = "Combat",
        cbt_diag      = "Combat: game damage meter %s · fights in the meter: %s · Farol log: %s · saved fights: %d · game combat log for addons: %s",
        cbt_diag_yes  = "available", cbt_diag_no = "unavailable", cbt_diag_on = "on", cbt_diag_off = "off",
        cbt_diag_restricted = "restricted", cbt_diag_free = "open",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do ns.STRINGS[lang][key] = value end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function DB() return ns.GetDB and ns.GetDB() end
function Combat.Enabled() local db = DB() return db and db.combatLog == true or false end

-- Nomes só desta sessão (outros jogadores): chave = tabela da luta/entrada; some no /reload ou ao sair.
local live = setmetatable({}, { __mode = "k" })

---------------------------------------------------------------------------
-- Validação (dados salvos e leituras do jogo)
---------------------------------------------------------------------------

local function Num(v, low, high)
    if type(v) ~= "number" or v ~= v or v < low or v > high then return nil end
    return v
end
local function Int(v, low, high) v = Num(v, low, high); return v and math.floor(v) or nil end

local function CleanName(text)
    if type(text) ~= "string" then return nil end
    if ns.IsSecret and ns.IsSecret(text) then return nil end
    text = string.gsub(ns.Trim(text, 1024), "[|%c]", "")
    text = ns.Trim(text)
    local out, count = {}, 0 -- corta em letras (UTF-8), nunca no meio de uma
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > NAME_MAX then break end
        out[#out + 1] = char
    end
    text = table.concat(out)
    if text == "" then return nil end
    return text
end

-- Nome da classe no idioma do jogo (tabela só de leitura do próprio jogo); sem ela, o código ("ROGUE").
local function ClassName(code)
    local names = LOCALIZED_CLASS_NAMES_MALE
    if type(code) == "string" and type(names) == "table" and type(names[code]) == "string" then return names[code] end
    return code or ""
end

local function CleanClass(text)
    if type(text) ~= "string" or #text > 20 or not string.find(text, "^[%u_]+$") then return nil end
    return text
end

local function CleanSpells(list, max)
    local out = {}
    if type(list) ~= "table" then return out end
    for i = 1, math.min(#list, max) do
        local e = list[i]
        if type(e) == "table" then
            local id, amount = Int(e.i, 1, 1e7), Int(e.a, 0, 1e12)
            if id and amount then out[#out + 1] = { i = id, a = amount } end
        end
    end
    return out
end

-- Entrada de quem te acertou / participante. pl = outro jogador: o nome NUNCA fica no disco.
local function CleanPerson(e, withSpell)
    if type(e) ~= "table" then return nil end
    local p = { a = Int(e.a, 0, 1e12) or 0 }
    if withSpell then
        p.i = Int(e.i, 1, 1e7)
        if not p.i then return nil end
        p.ev = e.ev == true or nil; p.dl = e.dl == true or nil
    else
        p.b = Int(e.b, 0, 1e12) or 0
        p.al = e.al == true or nil
    end
    p.me = e.me == true or nil
    p.pl = e.pl == true or nil
    p.pt = e.pt == true or nil
    p.c = CleanClass(e.c)
    if not p.pl and not p.me then p.n = CleanName(e.n) end
    return p
end

local function CleanFight(f)
    if type(f) ~= "table" then return nil end
    local t = Int(f.t, 0, 4e9)
    if not t then return nil end
    local c = {
        t = t, s = Int(f.s, 0, 86400) or 0,
        n = not f.np and CleanName(f.n) or nil, np = f.np == true or nil, x = Int(f.x, 0, 1000) or 0,
        k = f.k == "duel" and "duel" or nil, r = (f.r == "w" or f.r == "l") and f.r or nil,
        d = Int(f.d, 0, 1e12) or 0, tk = Int(f.tk, 0, 1e12) or 0, h = Int(f.h, 0, 1e12) or 0, dd = Int(f.dd, 0, 1000) or 0,
        sp = CleanSpells(f.sp, MAX_SPELLS), hits = {}, pa = {},
    }
    if type(f.hits) == "table" then
        for i = 1, math.min(#f.hits, MAX_HITS) do c.hits[#c.hits + 1] = CleanPerson(f.hits[i], true) end
    end
    if type(f.pa) == "table" then
        for i = 1, math.min(#f.pa, MAX_PEOPLE * 2) do c.pa[#c.pa + 1] = CleanPerson(f.pa[i], false) end
    end
    if type(f.u) == "table" then
        c.u = {}
        for _, key in ipairs({ "hit", "crit", "miss", "blk", "got", "gcrit", "avoid" }) do c.u[key] = Int(f.u[key], 0, 1e6) or 0 end
    end
    return c
end

function Combat.Sanitize(saved)
    local data = { list = {}, last = 0 }
    if type(saved) ~= "table" then return data end
    data.last = Int(saved.last, 0, 1e9) or 0
    if type(saved.list) == "table" then
        -- os mais recentes ficam no começo; arquivo adulterado enorme: só os primeiros MAX_FIGHTS são olhados
        for i = 1, math.min(#saved.list, MAX_FIGHTS) do
            local f = CleanFight(saved.list[i])
            if f then data.list[#data.list + 1] = f end
        end
    end
    return data
end

local function Data()
    if not FarolCharDB then return { list = {}, last = 0 } end
    if type(FarolCharDB.combat) ~= "table" then FarolCharDB.combat = { list = {}, last = 0 } end
    return FarolCharDB.combat
end
Combat.Data = Data

---------------------------------------------------------------------------
-- Leitura do medidor de dano do jogo (só leitura, depois da luta)
---------------------------------------------------------------------------

local function Meter()
    local D = C_DamageMeter
    if type(D) ~= "table" or type(D.GetAvailableCombatSessions) ~= "function" or type(D.GetCombatSessionFromID) ~= "function" then
        return nil
    end
    if type(D.IsDamageMeterAvailable) == "function" then
        local ok, on = pcall(D.IsDamageMeterAvailable)
        if ok and on == false then return nil end
    end
    return D
end
Combat.Meter = Meter

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a = pcall(fn, ...)
    if ok then return a end
    return nil
end

-- Lista das lutas do jogo: { {id, name, dur} } (só as válidas)
local function Sessions(D)
    local list = Call(D.GetAvailableCombatSessions)
    local out = {}
    if type(list) ~= "table" then return out end
    for i = 1, math.min(#list, 500) do
        local s = list[i]
        if type(s) == "table" then
            local id = Int(s.sessionID, 1, 1e9)
            if id then out[#out + 1] = { id = id, name = s.name, dur = s.durationSeconds } end
        end
    end
    return out
end

local function Sources(D, id, kind)
    local s = Call(D.GetCombatSessionFromID, id, kind)
    if type(s) ~= "table" or type(s.combatSources) ~= "table" then return {} end
    local out = {}
    for i = 1, math.min(#s.combatSources, 40) do
        local c = s.combatSources[i]
        if type(c) == "table" then out[#out + 1] = c end
    end
    return out
end

local function SourceSpells(D, id, kind, guid)
    if type(guid) ~= "string" or type(D.GetCombatSessionSourceFromID) ~= "function" then return {} end
    local s = Call(D.GetCombatSessionSourceFromID, id, kind, guid)
    if type(s) ~= "table" or type(s.combatSpells) ~= "table" then return {} end
    local out = {}
    for i = 1, math.min(#s.combatSpells, 60) do
        local c = s.combatSpells[i]
        if type(c) == "table" then out[#out + 1] = c end
    end
    return out
end

local function IsPlayerGUID(guid) return type(guid) == "string" and string.find(guid, "^Player%-") ~= nil end
local function Amount(v) return Int(v, 0, 1e12) or 0 end
local function ByAmount(a, b) return a.a > b.a end

local function MyGUID()
    local guid = Call(UnitGUID, "player")
    return type(guid) == "string" and not (ns.IsSecret and ns.IsSecret(guid)) and guid or nil
end

-- Monta uma luta a partir de uma sessão do medidor. names = nomes de outros jogadores (só memória).
local function ReadSession(D, session)
    local me = MyGUID()
    local fight = { t = math.floor(Call(time) or 0), s = Int(session.dur, 0, 86400) or 0, sp = {}, hits = {}, pa = {},
        d = 0, tk = 0, h = 0, dd = 0, x = 0 }
    local names = {}
    -- Quem causou dano: você e o seu lado (grupo, mascotes).
    local myEntry
    for _, c in ipairs(Sources(D, session.id, DMG)) do
        local p = { a = Amount(c.totalAmount), b = 0, al = true, c = CleanClass(c.classFilename),
            me = c.isLocalPlayer == true or (me and c.sourceGUID == me) or nil }
        if p.me then myEntry = c; fight.d = p.a
        elseif IsPlayerGUID(c.sourceGUID) then p.pl = true; names[p] = CleanName(c.name)
        else p.n = CleanName(c.name); p.pt = c.isPet == true or nil end
        if (Num(c.deathTimeSeconds, 0, 1e9) or 0) > 0 and p.me then fight.dd = fight.dd + 1 end
        fight.pa[#fight.pa + 1] = p
    end
    -- Dano recebido pelo seu lado.
    for _, c in ipairs(Sources(D, session.id, TAKEN)) do
        local isMe = c.isLocalPlayer == true or (me and c.sourceGUID == me)
        if isMe then fight.tk = Amount(c.totalAmount) end
        local name = CleanName(c.name)
        for _, p in ipairs(fight.pa) do
            if (isMe and p.me) or (not isMe and not p.me and (p.n or names[p]) == name) then p.b = Amount(c.totalAmount) end
        end
    end
    -- Oponentes (dano que os inimigos receberam).
    local enemies = {}
    for _, c in ipairs(Sources(D, session.id, ENEMY)) do
        local p = { a = 0, b = Amount(c.totalAmount), c = CleanClass(c.classFilename) }
        if IsPlayerGUID(c.sourceGUID) then p.pl = true; names[p] = CleanName(c.name) else p.n = CleanName(c.name) end
        enemies[#enemies + 1] = p
    end
    -- Suas habilidades.
    for _, s in ipairs(SourceSpells(D, session.id, DMG, me)) do
        local id = Int(s.spellID, 1, 1e7)
        if id then fight.sp[#fight.sp + 1] = { i = id, a = Amount(s.totalAmount) } end
    end
    table.sort(fight.sp, ByAmount)
    while #fight.sp > MAX_SPELLS do table.remove(fight.sp) end -- lista curta (≤ 60), feita agora
    -- Cura feita por você.
    for _, c in ipairs(Sources(D, session.id, HEAL)) do
        if c.isLocalPlayer == true or (me and c.sourceGUID == me) then fight.h = Amount(c.totalAmount) end
    end
    -- O que te acertou: cada habilidade tem os detalhes de quem bateu (nome, monstro ou jogador, valor).
    local byEnemy = {}
    for _, s in ipairs(SourceSpells(D, session.id, TAKEN, me)) do
        local id = Int(s.spellID, 1, 1e7)
        local details = type(s.combatSpellDetails) == "table" and s.combatSpellDetails or {}
        if id then
            local any = false
            for i = 1, math.min(#details, 20) do
                local d = details[i]
                if type(d) == "table" then
                    any = true
                    local h = { i = id, a = Amount(d.amount), c = CleanClass(d.unitClassFilename),
                        ev = s.isAvoidable == true or nil, dl = s.isDeadly == true or nil, pt = d.isPet == true or nil }
                    local name = CleanName(d.unitName)
                    if d.isMob == false and not d.isPet then h.pl = true; names[h] = name else h.n = name end
                    fight.hits[#fight.hits + 1] = h
                    if name then byEnemy[name] = (byEnemy[name] or 0) + h.a end
                end
            end
            if not any then
                fight.hits[#fight.hits + 1] = { i = id, a = Amount(s.totalAmount), ev = s.isAvoidable == true or nil,
                    dl = s.isDeadly == true or nil, n = CleanName(s.creatureName) }
            end
        end
    end
    table.sort(fight.hits, ByAmount)
    while #fight.hits > MAX_HITS do table.remove(fight.hits) end
    for _, p in ipairs(enemies) do p.a = byEnemy[p.n or names[p] or ""] or 0 end
    table.sort(enemies, function(a, b) return a.b > b.b end)
    for i = 1, math.min(#enemies, MAX_PEOPLE) do fight.pa[#fight.pa + 1] = enemies[i] end
    while #fight.pa > MAX_PEOPLE * 2 do table.remove(fight.pa) end
    -- Título: o nome que o jogo deu (o inimigo principal); se for outro jogador, fica só na memória.
    local main = enemies[1]
    fight.x = math.max(0, #enemies - 1)
    if main and main.pl then
        fight.np = true; names[fight] = names[main] or CleanName(session.name)
    else
        fight.n = CleanName(session.name) or (main and main.n)
    end
    if myEntry == nil and fight.d == 0 and fight.tk == 0 and #enemies == 0 then return nil end -- você não lutou
    return fight, names
end

---------------------------------------------------------------------------
-- Números de combate (UNIT_COMBAT): você e o alvo, só durante a luta
---------------------------------------------------------------------------

local counts       -- contagem da luta atual (nil fora de combate)
local lastKey      -- o jogo repete o mesmo evento: ignora a cópia no mesmo instante
local pending      -- luta acabou: ler o medidor no próximo segundo (até 5 tentativas)
local duelSeen     -- um duelo terminou durante a luta
local dead         -- você morreu durante a luta

local AVOID = { MISS = true, DODGE = true, PARRY = true, BLOCK = true, RESIST = true, EVADE = true, IMMUNE = true,
    DEFLECT = true, REFLECT = true, ABSORB = true }

function Combat.OnUnitCombat(unit, action, flag, amount)
    if not counts or not Combat.Enabled() then return end
    for _, v in ipairs({ unit or "", action or "", flag or "", amount or 0 }) do
        if ns.IsSecret and ns.IsSecret(v) then return end -- bloqueado pelo jogo: não conta
    end
    if type(unit) ~= "string" or type(action) ~= "string" then return end
    local now = Call(GetTime) or 0
    local key = unit .. action .. tostring(flag) .. tostring(amount) .. now
    if key == lastKey then return end
    lastKey = key
    local crit = flag == "CRITICAL"
    if unit == "target" then
        local hostile = Call(UnitCanAttack, "player", "target")
        if hostile ~= true then return end
        if action == "WOUND" then
            counts.hit = counts.hit + 1
            if crit then counts.crit = counts.crit + 1 end
            if flag == "BLOCK_REDUCED" then counts.blk = counts.blk + 1 end
        elseif AVOID[action] then
            counts.miss = counts.miss + 1
        end
    elseif unit == "player" then
        if action == "WOUND" then
            counts.got = counts.got + 1
            if crit then counts.gcrit = counts.gcrit + 1 end
        elseif AVOID[action] then
            counts.avoid = counts.avoid + 1
        end
    end
end

local function NewCounts() return { hit = 0, crit = 0, miss = 0, blk = 0, got = 0, gcrit = 0, avoid = 0 } end

local RefreshWindow -- definida abaixo

-- Lê as lutas novas do medidor (as de número maior que a última guardada).
function Combat.Collect()
    local D = Meter()
    if not D or not FarolCharDB then return false end
    local data = Data()
    local sessions = Sessions(D)
    local added = false
    local newest
    for _, s in ipairs(sessions) do
        if s.id > (data.last or 0) then
            local fight, names = ReadSession(D, s)
            data.last = math.max(data.last or 0, s.id)
            if fight then
                for k, v in pairs(names) do live[k] = v end -- só memória
                table.insert(data.list, 1, fight)
                newest = fight
                added = true
            end
        end
    end
    while #data.list > MAX_FIGHTS do table.remove(data.list) end
    if newest then
        if pending and pending.counts then newest.u = pending.counts end
        if pending and pending.duel then newest.k = "duel" end
        if newest.k ~= "duel" then
            newest.r = ((pending and pending.dead) or newest.dd > 0) and "l" or "w"
        end
        if pending and pending.dead and newest.dd == 0 then newest.dd = 1 end
    end
    if added and RefreshWindow then pcall(RefreshWindow) end
    return added
end

-- Ao entrar: lutas que já estavam no medidor não entram (só as desta vez em diante).
function Combat.Baseline()
    local D = Meter()
    if not D or not FarolCharDB then return end
    local data = Data()
    local maxID = 0
    for _, s in ipairs(Sessions(D)) do maxID = math.max(maxID, s.id) end
    if not data.last or data.last > maxID then data.last = maxID end -- o jogo recomeçou a contagem (relog)
    if not Combat.Enabled() then data.last = maxID end
end

function Combat.SetEnabled(value)
    local db = DB()
    if not db then return end
    db.combatLog = value == true
    Print(db.combatLog and T("cbt_on") or T("cbt_off"))
    if db.combatLog then Combat.Baseline() end
    if RefreshWindow then pcall(RefreshWindow) end
end

function Combat.Clear()
    Data().list = {}
    for k in pairs(live) do live[k] = nil end
    Print(T("cbt_cleared"))
    if RefreshWindow then pcall(RefreshWindow) end
end

---------------------------------------------------------------------------
-- Textos de uma luta
---------------------------------------------------------------------------

local function Short(n)
    n = math.floor(n or 0)
    if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
    if n >= 10000 then return string.format("%.1fk", n / 1000) end
    return tostring(n)
end
Combat.Short = Short

local function Duration(s)
    s = math.floor(s or 0)
    if s < 60 then return s .. "s" end
    if ns.FormatDuration then return ns.FormatDuration(s) end
    return math.floor(s / 60) .. "m"
end

function Combat.PersonName(p)
    if p.me then return T("cbt_you") end
    if p.pl then return live[p] or T("cbt_other") end
    return p.n or T("cbt_none")
end

function Combat.Title(f)
    local name
    if f.np then name = live[f] or T("cbt_other") else name = f.n or T("cbt_fight") end
    if f.k == "duel" then name = string.format(T("cbt_duel_vs"), name)
    elseif (f.x or 0) > 0 then name = string.format(T("cbt_more"), name, f.x) end
    return name
end

function Combat.Result(f)
    if f.k == "duel" then return ns.C.warn .. T("cbt_duel") .. "|r" end
    if f.r == "l" then return ns.C.bad .. T("cbt_loss") .. "|r" end
    return ns.C.good .. T("cbt_win") .. "|r"
end

local function SpellName(id)
    local name = C_Spell and C_Spell.GetSpellName and Call(C_Spell.GetSpellName, id)
    if not name and GetSpellInfo then name = Call(GetSpellInfo, id) end
    name = CleanName(name)
    return name or ("#" .. id)
end
Combat.SpellName = SpellName

local function SpellIcon(id)
    local icon = C_Spell and C_Spell.GetSpellTexture and Call(C_Spell.GetSpellTexture, id)
    if not icon and GetSpellTexture then icon = Call(GetSpellTexture, id) end
    if type(icon) == "number" or type(icon) == "string" then return icon end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- /farol diagnostico (3.35): o que o jogo libera para o registro (só leituras; nada é mudado no jogo).
function Combat.DiagLine()
    local D = Meter()
    local count = D and #Sessions(D) or nil
    local restricted = C_CombatLog and C_CombatLog.IsCombatLogRestricted and Call(C_CombatLog.IsCombatLogRestricted)
    local rText = restricted == true and T("cbt_diag_restricted") or (restricted == false and T("cbt_diag_free") or "--")
    return string.format(T("cbt_diag"), D and T("cbt_diag_yes") or T("cbt_diag_no"), count and tostring(count) or "--",
        Combat.Enabled() and T("cbt_diag_on") or T("cbt_diag_off"), #Data().list, rText)
end

-- Linha da barra / tooltip: a última luta.
function Combat.LastLine()
    local f = Data().list[1]
    if not f then return nil end
    return string.format("%s · %s · %s / %s", Combat.Title(f), Duration(f.s), Short(f.d), Short(f.tk))
end

---------------------------------------------------------------------------
-- Janela (cartões; dentro da Central perde a moldura e o título)
---------------------------------------------------------------------------

local window
local selected = 1
local offset = 0

local function Kit() return ns.Hub and ns.Hub.Kit end

local function ShowSpellTip(self)
    if not self.spellID or not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local ok = GameTooltip.SetSpellByID and pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
    if not ok then GameTooltip:AddLine(SpellName(self.spellID), 1, 1, 1) end
    GameTooltip:Show()
end
local function HideTip() if GameTooltip then GameTooltip:Hide() end end

-- Linha com ícone + nome da habilidade (o mouse mostra a explicação do jogo) + valor à direita.
local function SpellRow(frame, i)
    local row = CreateFrame("Button", nil, frame)
    row:SetSize(220, 16)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", 0, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetJustifyH("LEFT")
    if row.name.SetWordWrap then row.name:SetWordWrap(false) end
    -- o valor fica na linha de baixo, ao lado da barra: o nome da habilidade usa a linha toda
    row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -15)
    row.value:SetJustifyH("RIGHT")
    row:SetScript("OnEnter", ShowSpellTip)
    row:SetScript("OnLeave", HideTip)
    row.index = i
    return row
end

local function TextRow(frame)
    local row = {}
    row.left = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.left:SetJustifyH("LEFT")
    if row.left.SetWordWrap then row.left:SetWordWrap(false) end
    row.right = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.right:SetJustifyH("RIGHT")
    return row
end

-- rightFirst: o valor fica com a largura dele e o nome (de jogador/monstro) com o resto, terminando em "..." se
-- não couber; sem ele, o rótulo (texto do Farol) fica com a largura dele (FitPair).
local PlaceRow
PlaceRow = function(row, x, y, w, leftText, rightText, rightFirst)
    row.left:ClearAllPoints(); row.left:SetPoint("TOPLEFT", x, y)
    row.right:ClearAllPoints(); row.right:SetPoint("TOPRIGHT", row.left:GetParent(), "TOPLEFT", x + w, y)
    row.left:SetText(leftText or ""); row.right:SetText(rightText or "")
    row.left:Show(); row.right:Show()
    local K = Kit()
    if rightFirst then
        local ok, rw = pcall(row.right.GetStringWidth, row.right)
        rw = (ok and type(rw) == "number" and rw == rw) and math.ceil(rw * 1.12) + 6 or 120
        rw = math.max(1, math.min(rw, w - 40))
        row.right:SetWidth(rw); row.left:SetWidth(math.max(1, w - rw - 10))
    elseif K and K.FitPair then
        K.FitPair(row.left, row.right, w + 24)
        -- rótulo comprido demais (outro idioma): o valor nunca fica sem espaço; o rótulo termina em "..."
        local ok, rw = pcall(row.right.GetStringWidth, row.right)
        if ok and type(rw) == "number" and rw == rw and (row.right:GetWidth() or 0) < rw then
            return PlaceRow(row, x, y, w, leftText, rightText, true)
        end
    else
        row.left:SetWidth(w * 0.6); row.right:SetWidth(w * 0.4)
    end
end
local function HideRow(row) row.left:Hide(); row.right:Hide() end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolCombat", UIParent, ns.backdropTemplate)
    frame:SetSize(780, 580)
    frame:SetPoint("CENTER", 0, 20)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -18)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.farolClose = close
    close:SetPoint("TOPRIGHT", -6, -6)
    -- Lista de lutas: botões de 54 px (título, quando · duração, resultado + números)
    frame.fights = {}
    for i = 1, LIST_ROWS do
        local b = CreateFrame("Button", "FarolCombatFight" .. i, frame)
        b:SetSize(226, 50)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints()
        if b.bg.SetColorTexture then b.bg:SetColorTexture(0.14, 0.11, 0.06, 0.9) end
        b.title = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.title:SetPoint("TOPLEFT", 8, -5); b.title:SetWidth(210); b.title:SetJustifyH("LEFT")
        if b.title.SetWordWrap then b.title:SetWordWrap(false) end
        b.when = ns.Dim(b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        b.when:SetPoint("TOPLEFT", 8, -21); b.when:SetWidth(210); b.when:SetJustifyH("LEFT")
        b.result = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.result:SetPoint("BOTTOMLEFT", 8, 5); b.result:SetJustifyH("LEFT")
        b.nums = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b.nums:SetPoint("BOTTOMRIGHT", -8, 5); b.nums:SetJustifyH("RIGHT")
        b:SetScript("OnClick", function(self) selected = self.fightIndex or 1; RefreshWindow() end)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        frame.fights[i] = b
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        local total = #Data().list
        offset = math.max(0, math.min(math.max(0, total - LIST_ROWS), offset - (delta > 0 and 1 or -1)))
        RefreshWindow()
    end)
    frame.spells, frame.hits = {}, {}
    for i = 1, 4 do frame.spells[i] = SpellRow(frame, i) end
    for i = 1, 3 do
        frame.hits[i] = SpellRow(frame, i)
        frame.hits[i].who = TextRow(frame)
        frame.hits[i].who.right:SetFontObject("GameFontHighlightSmall")
    end
    frame.lines = {}
    for i = 1, 4 do frame.lines[i] = TextRow(frame) end
    frame.people = {}
    for i = 1, 6 do frame.people[i] = TextRow(frame) end
    frame.allies = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.enemies = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    -- Desligado / vazio
    frame.offText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.offText:SetJustifyH("LEFT"); frame.offText:SetJustifyV("TOP")
    frame.toggle = CreateFrame("Button", "FarolCombatToggle", frame, "UIPanelButtonTemplate")
    frame.toggle:SetSize(150, 22)
    frame.toggle:SetScript("OnClick", function() Combat.SetEnabled(not Combat.Enabled()) end)
    frame.clear = CreateFrame("Button", "FarolCombatClear", frame, "UIPanelButtonTemplate")
    frame.clear:SetSize(110, 22)
    frame.clear:SetScript("OnClick", function(self)
        if ns.ConfirmClick then ns.ConfirmClick(self, #Data().list, "cbt_clear_ask", Combat.Clear) else Combat.Clear() end
    end)
    frame.farolDetail = function(on) frame.farolInHub = on and true or false; pcall(RefreshWindow) end
    frame:SetScript("OnShow", function() pcall(RefreshWindow) end)
    frame:Hide()
    tinsert(UISpecialFrames, "FarolCombat")
    ns.MakeToplevel(frame)
    return frame
end

local function Layout(frame, f)
    local K = Kit()
    if not K then return end
    local top = frame.farolInHub and -10 or -44
    local listH = 30 + LIST_ROWS * 54 + 6
    local data = Data()
    local list = data.list
    -- Lista
    local p = K.Panel(frame, "list", 10, top, 250, listH)
    p.title:SetText(T("cbt_list")); p.sub:SetText(string.format(ns.TN and ns.TN("cbt_list_sub", #list) or T("cbt_list_sub"), #list))
    for i, b in ipairs(frame.fights) do
        local idx = offset + i
        local fight = list[idx]
        if fight then
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", 22, top - 32 - (i - 1) * 54)
            b.fightIndex = idx
            b.title:SetText(Combat.Title(fight))
            if idx == selected then b.title:SetTextColor(1, 1, 1) else b.title:SetTextColor(1, 0.82, 0) end
            b.when:SetText((ns.FormatWhen and ns.FormatWhen(fight.t) or "") .. " · " .. Duration(fight.s))
            b.result:SetText(Combat.Result(fight))
            b.nums:SetText(Short(fight.d) .. " / " .. Short(fight.tk))
            b:Show()
        else
            b:Hide()
        end
    end
    -- Detalhe da luta escolhida
    local x, w = 268, 502
    local head = K.Panel(frame, "head", x, top, w, 70)
    head.title:SetText(f and Combat.Title(f) or ""); head.sub:SetText(f and ((ns.FormatWhen and ns.FormatWhen(f.t) or "") .. " · " .. ns.T(f.k == "duel" and "cbt_duel" or (f.r == "l" and "cbt_loss" or "cbt_win"))) or "")
    local stats = {
        { "cbt_dur", Duration(f.s) },
        { "cbt_done", ns.C.good .. Short(f.d) .. "|r" },
        { "cbt_taken", ns.C.bad .. Short(f.tk) .. "|r" },
        { "cbt_heal", Short(f.h) },
        { "cbt_deaths", tostring(f.dd) },
    }
    for i, s in ipairs(stats) do K.Stat(frame, "st" .. i, x + 12 + (i - 1) * 98, top - 32, 92, T(s[1]), s[2]) end
    -- Positivo
    local py = top - 78
    local pos = K.Panel(frame, "pos", x, py, 248, 214)
    pos.title:SetText(ns.C.good .. "▲|r " .. T("cbt_pos")); pos.sub:SetText(T("cbt_pos_sub"))
    local total = math.max(1, f.d)
    for i, row in ipairs(frame.spells) do
        local s = f.sp[i]
        local bar = K.Bar(frame, "sp" .. i)
        if s then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", x + 12, py - 32 - (i - 1) * 28); row:SetWidth(224)
            row.spellID = s.i
            row.icon:SetTexture(SpellIcon(s.i))
            row.name:SetText(SpellName(s.i))
            row.value:SetText(string.format("%s · %d%%", Short(s.a), math.floor(s.a / total * 100 + 0.5)))
            row.name:SetWidth(206)
            row:Show()
            K.SetBar(bar, x + 12, py - 50 - (i - 1) * 28, 144, s.a / total, true, K.ColorOf(ns.C.good))
        else
            row:Hide(); K.SetBar(bar, x + 12, py - 50, 224, 0, false)
        end
    end
    local u = f.u
    local ly = py - 32 - 4 * 28 - 4
    if #f.sp == 0 then
        PlaceRow(frame.lines[1], x + 12, py - 32, 224, ns.C.dim .. T("cbt_no_spells") .. "|r", "")
    else
        PlaceRow(frame.lines[1], x + 12, ly, 224, T("cbt_crits"), u and string.format(T("cbt_crits_v"), u.crit, u.hit) or T("cbt_none"))
    end
    PlaceRow(frame.lines[2], x + 12, ly - 20, 224, T("cbt_avoid"), u and tostring(u.avoid) or T("cbt_none"))
    -- Negativo
    local nx = x + 254
    local neg = K.Panel(frame, "neg", nx, py, 248, 214)
    neg.title:SetText(ns.C.bad .. "▼|r " .. T("cbt_neg")); neg.sub:SetText(T("cbt_neg_sub"))
    local maxHit = math.max(1, f.hits[1] and f.hits[1].a or 1)
    for i, row in ipairs(frame.hits) do
        local h = f.hits[i]
        local bar = K.Bar(frame, "hit" .. i)
        if h then
            local y = py - 32 - (i - 1) * 42
            -- quem bateu (as marcas evitável / mortal à direita), a habilidade com ícone, e a barra com o valor
            local tags = (h.ev and (ns.C.warn .. T("cbt_avoidable") .. "|r") or "") .. ((h.ev and h.dl) and " " or "")
                .. (h.dl and (ns.C.bad .. T("cbt_deadly") .. "|r") or "")
            row.who.right = row.who.right or frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            PlaceRow(row.who, nx + 12, y, 224, Combat.PersonName(h), tags, true)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", nx + 12, y - 16); row:SetWidth(224)
            row.spellID = h.i
            row.icon:SetTexture(SpellIcon(h.i))
            row.name:SetText(SpellName(h.i))
            row.name:SetWidth(206)
            row.value:SetText(Short(h.a))
            row:Show()
            K.SetBar(bar, nx + 12, y - 34, 164, h.a / maxHit, true, K.ColorOf(ns.C.bad))
        else
            row:Hide(); HideRow(row.who); K.SetBar(bar, nx + 12, py - 50, 224, 0, false)
        end
    end
    local hy = py - 32 - 3 * 42 - 4
    if #f.hits == 0 then
        PlaceRow(frame.lines[3], nx + 12, py - 32, 224, ns.C.dim .. T("cbt_no_hits") .. "|r", "")
        PlaceRow(frame.lines[4], nx + 12, hy, 224, T("cbt_missed"), u and tostring(u.miss) or T("cbt_none"))
    else
        PlaceRow(frame.lines[3], nx + 12, hy, 224, T("cbt_missed"), u and tostring(u.miss) or T("cbt_none"))
        PlaceRow(frame.lines[4], nx + 12, hy - 20, 224, T("cbt_blocked"), u and tostring(u.blk) or T("cbt_none"))
    end
    -- Participantes
    local ay = py - 222
    local part = K.Panel(frame, "part", x, ay, w, listH - 300)
    part.title:SetText(T("cbt_people")); part.sub:SetText(T("cbt_people_sub"))
    local allies, enemies = {}, {}
    for _, pp in ipairs(f.pa) do if pp.al then allies[#allies + 1] = pp else enemies[#enemies + 1] = pp end end
    local function Who(pp)
        local kind = pp.pt and T("cbt_pet") or ((pp.pl or pp.me) and ClassName(pp.c) or T("cbt_mob"))
        local name = Combat.PersonName(pp)
        if kind ~= "" then name = name .. " · " .. kind end
        return name
    end
    frame.allies:ClearAllPoints(); frame.allies:SetPoint("TOPLEFT", x + 12, ay - 32); frame.allies:SetText(T("cbt_allies")); frame.allies:Show()
    local r = 1
    local y = ay - 46
    for i = 1, 2 do
        local pp = allies[i]
        if pp then PlaceRow(frame.people[r], x + 12, y, w - 24, Who(pp), string.format(T("cbt_dealt_taken"), Short(pp.a), Short(pp.b)), true); r = r + 1; y = y - 18 end
    end
    frame.enemies:ClearAllPoints(); frame.enemies:SetPoint("TOPLEFT", x + 12, y - 4); frame.enemies:SetText(T("cbt_enemies")); frame.enemies:Show()
    y = y - 18
    for _, pp in ipairs(enemies) do
        if r > 6 or y < ay - (listH - 300) + 22 then break end -- o que não cabe fica de fora (os maiores primeiro)
        PlaceRow(frame.people[r], x + 12, y, w - 24, Who(pp), string.format(T("cbt_dealt_taken"), Short(pp.a), Short(pp.b)), true)
        r = r + 1; y = y - 18
    end
    for i = r, 6 do HideRow(frame.people[i]) end
    frame.clear:ClearAllPoints(); frame.clear:SetPoint("TOPLEFT", 22, top - listH - 4)
end

local function HideDetail(frame)
    for _, b in ipairs(frame.fights) do b:Hide() end
    for _, r in ipairs(frame.spells) do r:Hide() end
    for _, r in ipairs(frame.hits) do r:Hide(); HideRow(r.who) end
    for _, r in ipairs(frame.lines) do HideRow(r) end
    for _, r in ipairs(frame.people) do HideRow(r) end
    frame.allies:Hide(); frame.enemies:Hide()
    for _, b in pairs(frame.farolBars or {}) do b.back:Hide(); b.fill:Hide() end
    local K = Kit()
    if K then K.ShowPanels(frame, false) end
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local frame = window
    frame.title:SetText(T("cbt_title"))
    if frame.farolInHub then frame.title:Hide() else frame.title:Show() end
    frame.toggle:SetText(Combat.Enabled() and T("cbt_turn_off") or T("cbt_turn_on"))
    frame.clear:SetText(T("cbt_clear"))
    if not frame.clear.farolAsk then frame.clear:SetText(T("cbt_clear")) end
    HideDetail(frame)
    local list = Data().list
    local top = frame.farolInHub and -10 or -44
    local K = Kit()
    if not Meter() or not Combat.Enabled() or #list == 0 then
        frame.clear:Hide()
        frame.toggle:ClearAllPoints()
        frame.offText:ClearAllPoints(); frame.offText:SetPoint("TOPLEFT", 30, top - 40); frame.offText:SetWidth(700)
        if K then
            local p = K.Panel(frame, "off", 10, top, 760, 150)
            K.ShowPanels(frame, false)
            for _, part in ipairs(p.parts) do part:Show() end
            p.title:SetText(Combat.Enabled() and T("cbt_title") or T("cbt_off_title")); p.sub:SetText("")
        end
        if not Meter() then
            frame.offText:SetText(T("cbt_no_meter")); frame.toggle:Hide()
        elseif not Combat.Enabled() then
            frame.offText:SetText(T("cbt_off_text"))
            frame.toggle:SetPoint("TOPLEFT", 30, top - 110); frame.toggle:Show()
        else
            frame.offText:SetText(T("cbt_empty"))
            frame.toggle:SetPoint("TOPLEFT", 30, top - 110); frame.toggle:Show()
        end
        frame.offText:Show()
        return
    end
    frame.offText:Hide()
    selected = math.max(1, math.min(selected, #list))
    offset = math.max(0, math.min(offset, math.max(0, #list - LIST_ROWS)))
    if K then
        K.ShowPanels(frame, true)
        local off = frame.farolPanels and frame.farolPanels.off
        if off then for _, part in ipairs(off.parts) do part:Hide() end end
        Layout(frame, list[selected])
    end
    frame.clear:Show()
    local listH = 30 + LIST_ROWS * 54 + 6
    frame.toggle:ClearAllPoints(); frame.toggle:SetPoint("LEFT", frame.clear, "RIGHT", 6, 0); frame.toggle:Show()
    frame.clear:ClearAllPoints(); frame.clear:SetPoint("TOPLEFT", 22, top - listH - 4)
end
Combat.Refresh = function() pcall(RefreshWindow) end

function Combat.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else selected, offset = 1, 0; window:Show() end
end

function Combat.HandleCommand(rest)
    local arg = string.lower(string.match(rest or "", "^%s*(%S*)") or "")
    if arg == "" then
        Combat.ToggleWindow()
    elseif arg == "ligar" or arg == "on" then
        Combat.SetEnabled(true)
    elseif arg == "desligar" or arg == "off" then
        Combat.SetEnabled(false)
    elseif arg == "limpar" or arg == "clear" then
        Combat.Clear()
    else
        Print(T("cbt_usage"))
    end
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_DEAD",
    "DUEL_FINISHED" }) do
    pcall(events.RegisterEvent, events, event)
end
if events.RegisterUnitEvent then
    pcall(events.RegisterUnitEvent, events, "UNIT_COMBAT", "player", "target")
else
    pcall(events.RegisterEvent, events, "UNIT_COMBAT")
end

local since, tries = 0, 0
events:SetScript("OnEvent", function(_, event, ...)
    if not ns.GetDB() or not FarolCharDB then return end
    if event == "UNIT_COMBAT" then
        pcall(Combat.OnUnitCombat, ...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        pcall(Combat.Baseline)
    elseif not Combat.Enabled() then
        counts, pending = nil, nil
    elseif event == "PLAYER_REGEN_DISABLED" then
        counts, duelSeen, dead = NewCounts(), false, false
    elseif event == "PLAYER_REGEN_ENABLED" then
        pending = { counts = counts, duel = duelSeen, dead = dead }
        counts, tries = nil, 0
    elseif event == "PLAYER_DEAD" then
        dead = true
        if pending then pending.dead = true end
    elseif event == "DUEL_FINISHED" then
        duelSeen = true
        if pending then pending.duel = true end
    end
end)
events:SetScript("OnUpdate", function(_, elapsed)
    since = since + elapsed
    if since < 1 then return end
    since = 0
    if not pending or not ns.GetDB() or not FarolCharDB then return end
    local okc, fighting = pcall(InCombatLockdown)
    if not okc or fighting then return end -- espera sair da luta de verdade
    local ok, added = pcall(Combat.Collect)
    tries = tries + 1
    if (ok and added) or tries >= 5 then pending = nil end
end)
