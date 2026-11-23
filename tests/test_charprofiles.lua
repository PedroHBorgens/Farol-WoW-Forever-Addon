-- Versão 3.2: perfil da conta ou só deste personagem, e "Copiar de..." outro perfil (com desfazer).
-- Version 3.2: account profile or this character only, and "Copy from..." another profile (with undo).

local function rawcopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, inner in next, value do out[key] = rawcopy(inner) end
    return out
end
local function profiles(H) return rawget(H.env.FarolDB, "profiles") end
local function all(H) return H.strip(table.concat(H.msgs, "\n")) end

-- Personagem A (Garrosh, padrão do simulador) com perfil próprio sem FPS; devolve os dados salvos.
local function charA(Mock)
    local H = Mock.new():login(); H:update(1)
    H:slash("perfil personagem"); H:slash("esconder fps"); H:slash("aparencia escala 150")
    H:event("PLAYER_LOGOUT")
    return rawcopy(H.env.FarolDB), rawcopy(H.env.FarolCharDB), H
end

return {
    -- Os casos usam um reino e um nome fixos nos dados salvos; na passada "Forever real" eles seguem com essa
    -- identidade (o resto do comportamento real, como o ouro 0 ao sair, continua valendo). Ver test_forever_real.lua.
    fixedIdentity = true,
    { "default: every character uses the account profile", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        T.eq(H.env.FarolCharDB.profile, "account")
        T.eq(next(profiles(H).chars), nil, "no character profiles yet")
        H:slash("perfil"); T.has(all(H), "perfil: o da conta")
    end },

    { "own profile starts as a copy; changes stay in it; switching back restores the account bar", function(T, Mock)
        local H = Mock.new():login(); H:update(1)
        H:slash("perfil personagem")
        T.has(H:lastMsg(), "perfil só dele"); T.eq(H.env.FarolCharDB.profile, "char")
        local own = profiles(H).chars.Azralon.Garrosh
        T.ok(own and own.bars[1].items.fps, "copy of the account profile")
        H:slash("esconder fps"); H:slash("aparencia escala 150"); H:update(2)
        T.hasnt(H:bar(), "fps"); T.eq(H.env.FarolFrame._scale, 1.5)
        T.eq(profiles(H).account.bars[1].items.fps, true, "account profile untouched")
        T.eq(profiles(H).account.bars[1].scale, 1)
        H:slash("perfil conta"); H:update(2)
        T.has(H:bar(), "fps"); T.eq(H.env.FarolFrame._scale, 1)
        H:slash("perfil personagem"); H:update(2)
        T.hasnt(H:bar(), "fps", "own profile kept while using the account one")
    end },

    { "the choice is per character and survives reload", function(T, Mock)
        local disk, charDisk = charA(Mock)
        local A = Mock.new():login(rawcopy(disk), rawcopy(charDisk)); A:update(2)
        T.hasnt(A:bar(), "fps"); T.eq(A.env.FarolFrame._scale, 1.5)
        local B = Mock.new(); B.playerName = "Bruna"; B:login(rawcopy(disk)); B:update(2)
        T.eq(B.env.FarolCharDB.profile, "account"); T.has(B:bar(), "fps"); T.eq(B.env.FarolFrame._scale, 1)
    end },

    { "copy from another character, then undo", function(T, Mock)
        local disk = charA(Mock)
        local B = Mock.new(); B.playerName = "Bruna"; B:login(disk); B:update(2)
        B:slash("perfil"); T.has(all(B), "dá para copiar de: Garrosh")
        B:slash("perfil copiar garrosh"); B:update(2)
        T.has(B:lastMsg(), "copiadas de Garrosh"); T.hasnt(B:bar(), "fps"); T.eq(B.env.FarolFrame._scale, 1.5)
        local source = profiles(B).chars.Azralon.Garrosh.bars[1]
        T.ok(source ~= profiles(B).account.bars[1], "a copy, not the same table")
        B:slash("esconder ouro"); T.eq(source.items.gold, true, "changing the copy does not change Garrosh")
        B:slash("perfil desfazer"); B:update(2)
        T.has(B:bar(), "fps"); T.eq(B.env.FarolFrame._scale, 1); T.has(B:lastMsg(), "desfeita")
        B:slash("perfil desfazer"); T.has(B:lastMsg(), "nada para desfazer")
        B:slash("perfil copiar Ninguem"); T.has(B:lastMsg(), "não encontrado: Ninguem")
    end },

    { "menu: Profile dropdown and Copy from... dropdown", function(T, Mock)
        local disk = charA(Mock)
        local B = Mock.new(); B.playerName = "Bruna"; B:login(disk); B:update(1)
        B:slash("menu") -- janela própria = 2º conjunto de controles (o 1º é o painel das configurações do jogo)
        local drop = B.env.FarolProfile2
        T.eq(drop._text, "Conta")
        B:click(drop); B:click(B.env.FarolProfile2Entry2)
        T.eq(B.env.FarolCharDB.profile, "char"); T.eq(drop._text, "Este personagem")
        B:click(B.env.FarolProfileCopy2)
        T.eq(B.env.FarolProfileCopy2Entry1.text._text, "Conta"); T.eq(B.env.FarolProfileCopy2Entry2.text._text, "Garrosh")
        B:click(B.env.FarolProfileCopy2Entry2); B:update(2)
        T.hasnt(B:bar(), "fps")
        T.eq(profiles(B).chars.Azralon.Bruna.bars[1].items.fps, false, "copied into Bruna's own profile")
    end },

    { "bars 2 and 3 follow the profile", function(T, Mock)
        local H = Mock.new():login()
        H:slash("perfil personagem"); H:slash("barra 2 mostrar")
        T.ok(H.env.FarolBar2:IsShown())
        H:slash("perfil conta"); T.ok(not H.env.FarolBar2:IsShown(), "account profile has bar 2 off")
        H:slash("perfil personagem"); T.ok(H.env.FarolBar2:IsShown())
    end },

    { "forgetting a character also forgets its profile", function(T, Mock)
        local disk = charA(Mock)
        local B = Mock.new(); B.playerName = "Bruna"; B:login(disk)
        B:slash("ouro esquecer Garrosh")
        T.eq(profiles(B).chars.Azralon and profiles(B).chars.Azralon.Garrosh, nil)
    end },

    { "tampered profiles and choices fall back safely; limits 20 realms x 60 names", function(T, Mock)
        local chars = { ["Bad|Realm"] = { X = { bars = {} } }, Ok = { ["Bad|Name"] = { bars = {} }, Fine = { bars = "x" },
                        Good = { bars = { { scale = 0 / 0, items = 5, evil = true }, "x", { shown = true } } } } }
        for r = 1, 25 do
            local list = {}
            for c = 1, 70 do list[string.format("C%02d", c)] = { bars = {} } end
            chars[string.format("R%02d", r)] = list
        end
        local H = Mock.new():login({ profiles = { account = { bars = { {} } }, chars = chars } }, { profile = "evil" })
        T.eq(H.env.FarolCharDB.profile, "account")
        local p = profiles(H).chars
        T.eq(p["Bad|Realm"], nil); T.eq(p.Ok["Bad|Name"], nil); T.eq(p.Ok.Fine, nil)
        local good = p.Ok.Good.bars
        T.eq(good[1].scale, 1); T.eq(good[1].evil, nil); T.eq(type(good[1].items), "table"); T.eq(good[1].shown, true)
        T.eq(good[2].shown, false); T.eq(good[3].shown, true); T.eq(#good, 3)
        local realms, names = 0, 0
        for _, list in pairs(p) do realms = realms + 1 end
        for _ in pairs(p.R01) do names = names + 1 end
        T.eq(realms, 20); T.eq(names, 60)
    end },

    { "invalid profile commands are refused; English", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        for _, cmd in ipairs({ "profile fly", "profile account now", "profile copy", "profile undo x", "profile 3" }) do
            H:slash(cmd); T.has(H:lastMsg(), "usage: /farol profile", cmd)
        end
        T.eq(H.env.FarolCharDB.profile, "account")
        H:slash("profile character"); T.has(H:lastMsg(), "its own profile")
        H:slash("profile copy account"); T.has(H:lastMsg(), "copied from Account")
        H:slash("help"); T.has(all(H), "/farol profile")
    end },

    { "unknown character name: own profile waits and is applied at login", function(T, Mock)
        local disk, charDisk = charA(Mock)
        local H = Mock.new(); H.playerName = nil
        H:login(rawcopy(disk), rawcopy(charDisk))
        T.eq(H.env.FarolCharDB.profile, "char", "choice kept")
        H.playerName = "Garrosh"; H:event("PLAYER_ENTERING_WORLD"); H:update(2)
        T.hasnt(H:bar(), "fps", "own profile applied once the name is known")
        H.playerName = nil
        H:slash("perfil conta"); H:slash("perfil personagem"); T.has(H:lastMsg(), "ainda não informou")
    end },
}
