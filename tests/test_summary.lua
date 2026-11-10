-- Resumo da sessão: /farol resumo, salvar ao sair, mostrar a última sessão ao entrar, opção, dados adulterados.
-- Session summary: /farol summary, save on logout, show the last session at login, option, tampered data.

local LINK = { [2] = "1eff00", [3] = "0070dd", [4] = "a335ee", [5] = "ff8000" }

local function loot(H, quality, id)
    H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff" .. LINK[quality] .. "|Hitem:" .. id .. "|h[Item " .. id .. "]|h|r.")
end

-- Uma sessão de 1 hora: +10g, +5000 XP, +600 de reputação (Honrado -> Reverenciado), 4 saques, 1 aviso.
local function playHour(Mock, opts)
    local H = Mock.new(opts)
    H.faction = { name = "Orgrimmar", reaction = 6, min = 9000, max = 21000, value = 20700, id = 76 }
    H:login()
    H:update(1)
    H.money = 1234567 + 100000
    H.xp.cur = 6200 + 3800
    H:update(1)
    H.xp.level, H.xp.cur, H.xp.max = 31, 1200, 11000 -- subiu de nível: +3800 + 1200 = 5000
    H.faction.value, H.faction.reaction, H.faction.min, H.faction.max = 21300, 7, 21000, 42000
    H:event("UPDATE_FACTION")
    loot(H, 2, 1); loot(H, 3, 2); loot(H, 4, 3); loot(H, 5, 4)
    H:slash("aviso teste")
    H:update(3598)
    return H
end

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

-- Novo login com os dados salvos de H (o que o jogo guarda no disco ao sair).
local function relog(H, Mock, opts, isInitialLogin, isReloadingUi)
    local saved, savedChar = H.env.FarolDB, H.env.FarolCharDB
    local N = Mock.new(opts)
    N.env.FarolDB, N.env.FarolCharDB = saved, savedChar
    N:load()
    N:event("ADDON_LOADED", "Farol")
    N.msgs = {}
    N:event("PLAYER_ENTERING_WORLD", isInitialLogin, isReloadingUi)
    return N
end

return {
    { "/farol resumo shows the current session only in your own chat", function(T, Mock)
        local H = playHour(Mock)
        H.msgs = {}
        H:slash("resumo")
        local text = chat(H)
        T.has(text, "resumo da sessão (1h 00m):")
        T.has(text, "Ouro: +10g 0s (+10g 0s/h)")
        T.has(text, "XP: +5.0k (1 nível, 5.0k/h)")
        T.has(text, "Reputação: +600 Orgrimmar (Honrado → Reverenciado)")
        T.has(text, "Saques: 4 (1 raro, 1 épico, 1 lendário) · Avisos: 1")
        T.eq(H.sent or nil, nil, "nothing is sent to anyone")
    end },

    { "English summary", function(T, Mock)
        local H = playHour(Mock, { locale = "enUS" })
        H.msgs = {}
        H:slash("summary")
        local text = chat(H)
        T.has(text, "session summary (1h 00m):")
        T.has(text, "Gold: +10g 0s (+10g 0s/h) · XP: +5.0k (1 level, 5.0k/h)")
        T.has(text, "Loot: 4 (1 rare, 1 epic, 1 legendary) · Warnings: 1")
    end },

    { "an empty session shows gold and counts without errors", function(T, Mock)
        local H = Mock.new():login()
        H.msgs = {}
        H:slash("resumo")
        local text = chat(H)
        T.has(text, "resumo da sessão (0m):")
        T.has(text, "Ouro: +0c"); T.hasnt(text, "XP:"); T.hasnt(text, "Reputação")
        T.has(text, "Saques: 0 · Avisos: 0")
    end },

    { "logout saves the session; the next real login shows it once and clears it", function(T, Mock)
        local H = playHour(Mock)
        H:event("PLAYER_LOGOUT")
        local saved = H.env.FarolCharDB.lastSession
        T.ok(saved, "saved on logout")
        T.eq(saved.secs, 3600); T.eq(saved.money, 100000); T.eq(saved.loot, 4); T.eq(saved.levels, 1)
        local N = relog(H, Mock, nil, true, false)
        local text = chat(N)
        T.has(text, "última sessão (Hoje ")
        T.has(text, ", 1h 00m):")
        T.has(text, "Reputação: +600 Orgrimmar (Honrado → Reverenciado)")
        T.eq(N.env.FarolCharDB.lastSession, nil, "shown once, then cleared")
        N.msgs = {}
        N:event("PLAYER_ENTERING_WORLD", false, false) -- trocar de zona / entrar em instância
        T.hasnt(chat(N), "última sessão")
    end },

    { "not shown after /reload; not saved for sessions under 5 minutes", function(T, Mock)
        local H = playHour(Mock)
        H:event("PLAYER_LOGOUT")
        local N = relog(H, Mock, nil, false, true)                  -- /reload no cliente moderno
        T.hasnt(chat(N), "última sessão")
        T.ok(N.env.FarolCharDB.lastSession, "kept for the next real login")
        local old = relog(H, Mock, { mode = "wotlk" }, nil, nil)    -- cliente antigo: /reload logo depois de salvar
        T.hasnt(chat(old), "última sessão")
        local S = Mock.new():login()
        S:update(299)
        S:event("PLAYER_LOGOUT")
        T.eq(S.env.FarolCharDB.lastSession, nil, "4 min 59 s is not saved")
    end },

    { "old clients show the last session when it is older than 2 minutes", function(T, Mock)
        local H = playHour(Mock, { mode = "wotlk" })
        H:event("PLAYER_LOGOUT")
        H.env.FarolCharDB.lastSession.t = os.time() - 3600
        local N = relog(H, Mock, { mode = "wotlk" }, nil, nil)
        T.has(chat(N), "última sessão (")
    end },

    { "the option turns the login summary off (menu and command)", function(T, Mock)
        local H = playHour(Mock)
        H:slash("resumo off")
        T.has(H:lastMsg(), "desligado"); T.eq(H.env.FarolDB.summary, false)
        H:event("PLAYER_LOGOUT")
        local N = relog(H, Mock, nil, true, false)
        T.hasnt(chat(N), "última sessão")
        N:slash("resumo on"); T.eq(N.env.FarolDB.summary, true)
        N.env.FarolFrame._scripts.OnMouseUp(N.env.FarolFrame, "RightButton")
        local found
        for _, check in ipairs(N:framesOf("CheckButton")) do
            if check.label and N:text(check.label) == "Resumo da sessão ao entrar" then found = check end
        end
        T.ok(found, "checkbox in the options menu")
        N:check(found, false); T.eq(N.env.FarolDB.summary, false)
    end },

    { "a tampered saved summary is cleaned or discarded on load", function(T, Mock)
        local function load(lastSession)
            local H = Mock.new()
            H.env.FarolCharDB = { lastSession = lastSession }
            H:load(); H:event("ADDON_LOADED", "Farol")
            return H.env.FarolCharDB.lastSession
        end
        T.eq(load("lixo"), nil); T.eq(load({ t = 0 / 0 }), nil); T.eq(load({ t = math.huge }), nil)
        local s = load({ t = 1e9, secs = -5, money = 0 / 0, xp = math.huge, levels = 1e6, rep = "x",
                         repName = string.rep("A", 500), repFrom = 99, loot = -1, warns = 11, evil = "|Hurl|h" })
        T.eq(s.secs, 0); T.eq(s.money, 0); T.eq(s.xp, 0); T.eq(s.levels, 0); T.eq(s.rep, 0)
        T.eq(s.repName, nil, "name too long"); T.eq(s.repFrom, nil); T.eq(s.loot, 0); T.eq(s.warns, 0)
        T.eq(s.evil, nil, "unknown keys are dropped")
        local H = Mock.new()
        H.env.FarolCharDB = { lastSession = { t = os.time() - 7200, secs = 3600, repName = "Evil|Hitem:1|h[x]|h",
                                              rep = 10, repFrom = 6, repTo = 6 } }
        H:load(); H:event("ADDON_LOADED", "Farol"); H.msgs = {}
        H:event("PLAYER_ENTERING_WORLD", true, false)
        T.has(table.concat(H.msgs, "\n"), "Evil||Hitem:1||h[x]||h", "faction name cannot create links")
    end },
}
