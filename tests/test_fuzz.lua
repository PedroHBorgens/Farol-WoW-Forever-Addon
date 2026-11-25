-- Robustez: entradas aleatórias e maliciosas não podem causar erro no addon.
-- Robustness: random and malicious input must never raise a Lua error.
-- (Versão menor do fuzzing usado na análise de segurança; semente fixa = sempre o mesmo teste.)

local ALPHA = { "a", "0", "9", " ", ":", "%", "|", "c", "H", "T", "\n", "\0", "é", "[", "]", "(", ".", "-",
                "%s", "%d", "%1$s", "|cff", "|H", "|T", "|A", "|r" }
local WORDS = { "alarme", "add", "soneca", "parar", "saque", "limpar", "aviso", "durab", "bolsas", "talentos",
                "pausa", "agua", "lutas", "padrao", "lembrar", "resumo", "profissoes", "prof", "lixo", "junk", "ouro", "gold", "esquecer", "forget", "total", "descansado", "rested", "novidades", "news", "instancias", "lockouts", "tooltip", "dica", "municao", "reagentes", "400", "5000", "15", "240", "2",
                "graus", "som", "status", "concluidas", "completed", "registrar", "diagnostico", "diag", "origem", "source", "chat", "notas", "nova", "guardar", "tirar", "comerciante", "hora", "tooltip", "silenciar", "lembrar", "aparencia", "escala", "fundo", "texto", "icones",
                "largura", "coluna", "linha", "ordem", "padrao", "show", "hide", "lang", "menu", "lock", "reset",
                "sessao", "zerar", "historico", "barra", "bar", "1", "3", "mostrar", "esconder", "perfil", "profile", "personagem", "conta", "copiar", "desfazer", "undo", "voltar", "pacote", "Garrosh", "tarefa", "task", "feita", "apagar", "semanal", "diaria", "meta", "goal", "nivel", "limpar", "item", "farm", "remover", "missoes", "prontas", "aviso", "quests", "19", "regresso", "hearth", "pedra", "|cffffffff|Hitem:4306::|h[Seda]|h|r", "[Seda]", "|Hitem:abc|h", "40", "1000000", "masmorra", "dungeon", "resumo", "minimapa", "minimap", "travar", "on", "off", "07:30", "25:99", "-1", "99999" }
local BAD = { "x", 1e309, -1e309, 0 / 0, true, false, {}, { 1, 2 }, -5, 3.7, "" }

local seed = 1
local function random(n) -- gerador próprio e determinístico (não depende de math.random)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return seed % n + 1
end
local function pick(list) return list[random(#list)] end
local function junk(n)
    local parts = {}
    for i = 1, n do parts[i] = random(2) == 1 and pick(ALPHA) or pick(WORDS) end
    return table.concat(parts, random(2) == 1 and " " or "")
end

return {
    { "500 random/malicious slash commands raise no error", function(T, Mock)
        local H = Mock.new():login()
        for i = 1, 500 do
            local input = i == 250 and string.rep("%s|H", 2000) or junk(random(8))
            local ok, err = pcall(H.slash, H, input)
            T.ok(ok, "command '" .. input:sub(1, 30) .. "': " .. tostring(err))
            if i % 25 == 0 then H:update(1) end
        end
    end },

    { "malformed loot messages raise no error and record nothing invalid", function(T, Mock)
        local H = Mock.new():login()
        for _ = 1, 300 do
            local msg = "Você recebe saque: |cff1eff00|Hitem:" .. junk(2) .. "|h[" .. junk(3) .. "]|h|r" .. junk(1)
            T.ok(pcall(H.event, H, "CHAT_MSG_LOOT", msg))
        end
        T.ok(pcall(H.event, H, "CHAT_MSG_LOOT", nil)); T.ok(pcall(H.event, H, "CHAT_MSG_LOOT", 42))
        for _, entry in ipairs(H.env.FarolCharDB.items) do
            T.hasnt(string.match(entry.link, "%[(.-)%]") or "", "|H", "no hidden links stored")
        end
        T.ok(pcall(H.slash, H, "saque"))
    end },

    { "tampered saved data with wrong types never breaks any window", function(T, Mock)
        local KEYS = { "x", "y", "point", "lang", "scale", "bgAlpha", "fontSize", "iconSize", "barWidth", "items",
                       "alarms", "loot", "warnings", "order", "snoozeMinutes", "shown", "locked", "icons", "vertical",
                       "summary", "serverTime", "goldTotal", "chars", "newsSeen", "tooltipFull", "minimap", "runSummary", "colorblind", "questRecord", "questShowOld", "completed", "questNames", "notesButton", "keep", "keepMerchant", "keepReady", "keepTooltip" }
        for i = 1, 60 do
            local db = {}
            for _, key in ipairs(KEYS) do if random(3) > 1 then db[key] = pick(BAD) end end
            if random(2) == 1 then db.chatWindow = pick({ "Farol", "|cffx", string.rep("a", 60), "a\0b", pick(BAD) }) end
            if random(2) == 1 then db.notes = random(3) == 1 and pick(BAD) or { { t = pick(BAD), x = pick(BAD), d = pick(BAD), m = pick(BAD) }, pick(BAD), { t = "Ok|cff", x = "a\0b\n", d = true } } end
            if random(2) == 1 then -- avisos com cada campo adulterado (inclusive pausa, água e "Lembrar em")
                db.warnings = {}
                for _, key in ipairs({ "durab", "durabPct", "bags", "bagSlots", "sound", "talents", "ranks", "prof", "restFull", "remindMin",
                                       "ammo", "ammoYellow", "ammoRed", "reag", "reagYellow", "reagRed",
                                       "pause", "pauseMin", "pauseAnywhere", "water", "waterMin", "waterAnywhere", "tasks", "goals", "questFull", "questMin", "questReady", "hearthReady", "popupW", "questValue", "questLevel" }) do
                    db.warnings[key] = pick(BAD)
                end
            end
            if random(3) == 1 then -- personagens: lugar da Pedra de Regresso adulterado
                db.chars = { Azralon = { Mira = { gold = 100, level = 20, t = 1700000000, bind = pick(BAD) }, [pick({ "x", 1 })] = pick(BAD) } }
                db.completed = random(3) == 1 and pick(BAD) or { Azralon = { Garrosh = { t = pick(BAD), tt = pick(BAD),
                    list = { { i = pick(BAD), n = pick(BAD), l = pick(BAD), z = pick(BAD), t = pick(BAD) }, pick(BAD) },
                    a = random(2) == 1 and pick(BAD) or { pick(BAD), 5, pick(BAD) } },
                    [pick({ "x", 1 })] = pick(BAD) }, [pick({ "y", 2 })] = pick(BAD) }
            end
            if random(2) == 1 then -- perfis da 3.x: estrutura e cada campo da barra adulterados
                local bar = {}
                for _, key in ipairs(KEYS) do if random(2) == 1 then bar[key] = pick(BAD) end end
                local shape = random(5)
                db.profiles = shape == 1 and pick(BAD) or shape == 2 and { account = pick(BAD) }
                    or shape == 3 and { account = { bars = pick(BAD) } }
                    or shape == 4 and { account = { bars = { pick(BAD), bar } } }
                    or { account = { bars = { bar } }, [pick({ "x", 1, true })] = pick(BAD) }
                db.activeBar, db.dataVersion = pick(BAD), pick(BAD)
                db.keep = random(3) == 1 and pick(BAD) or { { id = pick(BAD), n = pick(BAD), r = pick(BAD), k = pick({ "l", "p", pick(BAD) }),
                    v = pick(BAD), p = pick(BAD) }, pick(BAD), { id = 7001, n = "Ok", k = "p", v = 10, p = pick(BAD) } }
                if type(db.profiles) == "table" then -- perfis por personagem (3.2) adulterados
                    db.profiles.chars = random(3) == 1 and pick(BAD) or { Azralon = { Garrosh = random(2) == 1 and pick(BAD) or { bars = { bar, pick(BAD) } },
                        [pick({ "x", 1, true })] = pick(BAD) }, [pick({ "y", 2, false })] = pick(BAD) }
                end
            end
            local char = {
                profile = pick({ "char", "account", 5, true, "evil" }),
                keepSeen = random(2) == 1 and pick(BAD) or { [pick({ "x", 1, true, -5, 3.7 })] = pick(BAD), [7001] = true },
                runs = random(3) == 1 and pick(BAD) or { list = { { n = pick(BAD), k = pick({ "party", "raid", pick(BAD) }), t = pick(BAD), s = pick(BAD),
                    x = pick(BAD), g = pick(BAD), l = pick(BAD), r = pick(BAD), e = pick(BAD), d = pick(BAD) }, pick(BAD) },
                    cur = random(2) == 1 and pick(BAD) or { n = "Ok", k = "party", t = pick(BAD), u = pick(BAD), x = pick(BAD) } },
                diag = random(3) == 1 and pick(BAD) or { lz = pick(BAD), t = pick(BAD) },
                goals = random(3) == 1 and pick(BAD) or { gold = pick(BAD), level = pick(BAD), ls = pick(BAD), gw = pick(BAD), lw = pick(BAD) },
                tasks = random(3) == 1 and pick(BAD) or { { n = pick(BAD), w = pick(BAD), d = pick(BAD) }, pick(BAD), { n = "Ok", d = pick(BAD) } },
                farm = random(3) == 1 and pick(BAD) or { { id = pick(BAD), n = pick(BAD), c = pick(BAD), w = pick(BAD) }, pick(BAD),
                    { id = 4306, n = "Ok", c = pick(BAD) } },
                items = { { link = "|cff1eff00|Hitem:1|h[Ok]|h|r", count = pick(BAD), q = pick(BAD), t = pick(BAD) } },
                warnHistory = { { t = pick(BAD), text = "Aviso " .. i }, pick(BAD) },
                lastSession = random(4) == 1 and pick(BAD) or {
                    t = random(2) == 1 and pick(BAD) or 1e9, secs = pick(BAD), money = pick(BAD), xp = pick(BAD),
                    levels = pick(BAD), rep = pick(BAD), repName = pick(BAD), repFrom = pick(BAD), repTo = pick(BAD),
                    loot = pick(BAD), rare = pick(BAD), epic = pick(BAD), legend = pick(BAD), warns = pick(BAD),
                    src = random(2) == 1 and pick(BAD) or { qx = pick(BAD), mx = pick(BAD), ox = pick(BAD), qn = pick(BAD), qg = pick(BAD), lg = pick(BAD), sg = pick(BAD), bg = pick(BAD), og = pick(BAD) },
                },
            }
            local ok, err = pcall(function()
                local H = Mock.new():login(db, char)
                H:event("PLAYER_ENTERING_WORLD", true, false) -- mostra o resumo salvo (se ficou válido)
                H:update(1)
                for _, cmd in ipairs({ "menu", "saque", "historico", "ordem", "alarme", "aviso", "aparencia", "resumo", "meta", "farm", "diagnostico", "chat", "notas", "guardar" }) do
                    H:slash(cmd)
                end
            end)
            T.ok(ok, "saved data #" .. i .. ": " .. tostring(err))
            if ok then
                local saved = Mock.new():login(db, char).env.FarolDB
                T.eq(rawget(saved, "activeBar"), 1, "active bar reset #" .. i)
                T.eq(type(rawget(saved, "profiles").account.bars[1].items), "table", "bar items #" .. i)
            end
        end
    end },

    { "infinite or NaN dates in saved history are dropped or reset", function(T, Mock)
        local H = Mock.new():login(nil, {
            items = { { link = "|cff1eff00|Hitem:1|h[Ok]|h|r", count = 1, t = 1e309 } },
            warnHistory = { { t = 0 / 0, text = "ruim" }, { t = 1e309, text = "ruim" }, { t = 1700000000, text = "bom" } },
        })
        T.eq(#H.env.FarolCharDB.warnHistory, 1, "only the valid date is kept")
        T.eq(H.env.FarolCharDB.items[1].t, 0, "invalid loot date reset to 0")
        H:slash("historico"); H:slash("saque") -- abrir as janelas não pode dar erro
    end },
}
