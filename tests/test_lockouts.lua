-- Instâncias salvas (bloqueios de raide): lista do jogo, pedido ao servidor com limite, outros personagens, validação.
-- Saved instances (raid lockouts): game list, rate-limited server request, other characters, validation.

local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end

local function login(Mock, opts, saved)
    local H = Mock.new(opts)
    H:login(saved)
    H:event("PLAYER_ENTERING_WORLD", true, false)
    H:event("UPDATE_INSTANCE_INFO")
    H:slash("show reset"); H:update(1)
    return H
end

return {
    { "asks the server once at login and at most once a minute after that", function(T, Mock)
        local H = Mock.new():login()
        local after = H.raidInfoRequests
        T.ok(after >= 1, "requested at login")
        H:slash("show reset")
        for _ = 1, 10 do tip(H) end
        T.eq(H.raidInfoRequests, after, "tooltip within a minute: no new request")
        H:event("PLAYER_ENTERING_WORLD", false, false) -- troca de zona
        T.eq(H.raidInfoRequests, after, "zone change within a minute: no new request")
        H:update(61); tip(H)
        T.eq(H.raidInfoRequests, after + 1, "after a minute the tooltip may ask again")
    end },

    { "resets tooltip lists the saved instances with bosses and time to reset", function(T, Mock)
        local H = login(Mock)
        local text = tip(H)
        T.has(text, "Instâncias salvas")
        T.has(text, "Núcleo Derretido = 7/10 chefes  reset em 2d 4h")
        T.has(text, "Covil de Onyxia = 1/1 chefes  reset em 2d 4h")
        H.lockouts = {}; H:update(1)
        T.has(tip(H), "Instâncias salvas = nenhuma")
    end },

    { "before the server answers it says 'loading', never wrong data", function(T, Mock)
        local H = Mock.new()
        H.env.RequestRaidInfo = function() end -- servidor ainda não respondeu
        H:login(); H:slash("show reset"); H:update(1)
        T.has(tip(H), "Instâncias salvas = carregando...")
    end },

    { "old client (3.3.5a, no boss count) and English texts", function(T, Mock)
        local H = login(Mock, { mode = "wotlk", locale = "enUS" })
        local text = tip(H)
        T.has(text, "Saved instances")
        T.has(text, "Núcleo Derretido = reset in 2d 4h")
        T.hasnt(text, "bosses", "no boss count on old clients")
        H:slash("warn status")
        T.has(chat(H), "saved instances: 2 (function: GetSavedInstanceInfo).")
    end },

    { "other characters' lockouts are saved on logout and shown until they expire", function(T, Mock)
        local H = login(Mock)
        H:event("PLAYER_LOGOUT")
        local me = H.env.FarolDB.chars.Azralon.Garrosh
        T.eq(#me.locks, 2)
        local mc
        for _, l in ipairs(me.locks) do if l.n == "Núcleo Derretido" then mc = l end end
        T.eq(mc.k, 7); T.eq(mc.b, 10)
        T.ok(mc.r > os.time(), "saved as the date the lockout ends")
        local saved, char = H.env.FarolDB, H.env.FarolCharDB
        local N = Mock.new(); N.playerName = "Jaina"
        N.env.FarolDB, N.env.FarolCharDB = saved, char
        N:load(); N:event("ADDON_LOADED", "Farol"); N:event("PLAYER_ENTERING_WORLD", true, false); N:update(1)
        local text = tip(N)
        T.has(text, "Instâncias salvas dos seus personagens")
        T.has(text, "Garrosh (30): Covil de Onyxia, Núcleo Derretido")
        N.msgs = {}; N:slash("instancias")
        T.has(chat(N), "outros personagens deste reino:")
        T.has(chat(N), "Garrosh (30): Covil de Onyxia, Núcleo Derretido")
        local live = N.env.FarolDB.chars.Azralon.Garrosh.locks -- os dados limpos ao carregar
        live[1].r = os.time() - 10
        live[2].r = os.time() - 10
        T.hasnt(tip(N), "Garrosh (30): ", "expired lockouts disappear by themselves")
    end },

    { "/farol instancias lists the current character; nothing saved says so", function(T, Mock)
        local H = login(Mock)
        H.msgs = {}; H:slash("instancias")
        T.has(chat(H), "instâncias salvas deste personagem:")
        T.has(chat(H), "Núcleo Derretido — 7/10 chefes · reset em 2d 4h")
        H.lockouts = {}; H.msgs = {}; H:slash("lockouts")
        T.has(chat(H), "este personagem não está salvo em nenhuma instância.")
    end },

    { "bad values from the game or a tampered file are ignored", function(T, Mock)
        local H = Mock.new()
        H.lockouts = { { "Evil|Hitem:1|h", 1, 1, 100 }, { string.rep("A", 65), 1, 1, 100 }, { "NaN", 1, 1, 0 / 0 },
                       { "Neg", 1, 1, -5 }, { "Huge", 1, 1, 1e12 }, { "Ok", 5, 3, 3600 }, { "Absurdo", 99, 3, 5400 }, { "Ok2", 0 / 0, math.huge, 7200 } }
        H:login(); H:event("PLAYER_ENTERING_WORLD", true, false); H:event("UPDATE_INSTANCE_INFO")
        H:slash("show reset"); H:update(1)
        local text = tip(H)
        T.has(text, "Ok = 3/3 chefes", "killed never above total")
        T.has(text, "Ok2 = reset em 2h 00m", "invalid boss counts are dropped")
        T.has(text, "Absurdo = reset em 1h 30m", "99 bosses is invalid: count dropped, lockout kept")
        for _, bad in ipairs({ "Evil", "AAAA", "NaN", "Neg", "Huge" }) do T.hasnt(text, bad .. " =", "ignored " .. bad) end
        H.env.GetSavedInstanceInfo = function() error("blocked") end
        tip(H)
        local now = os.time()
        local saved = { chars = { Azralon = { Jaina = { gold = 1, level = 60, t = now, locks = {
            { n = "Bom", r = now + 3600, k = 2, b = 5 }, { n = "Mau|c", r = now + 3600 }, { n = "Sem data", r = 0 / 0 },
            { n = "Futuro", r = 1e13 }, "lixo", { n = "Contas", r = now + 3600, k = 9, b = 5 } } } } } }
        local L = Mock.new():login(saved)
        local locks = L.env.FarolDB.chars.Azralon.Jaina.locks
        T.eq(#locks, 2); T.eq(locks[1].n, "Bom"); T.eq(locks[2].k, 5, "killed clamped to total")
    end },
}
