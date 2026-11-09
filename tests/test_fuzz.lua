-- Robustez: entradas aleatórias e maliciosas não podem causar erro no addon.
-- Robustness: random and malicious input must never raise a Lua error.
-- (Versão menor do fuzzing usado na análise de segurança; semente fixa = sempre o mesmo teste.)

local ALPHA = { "a", "0", "9", " ", ":", "%", "|", "c", "H", "T", "\n", "\0", "é", "[", "]", "(", ".", "-",
                "%s", "%d", "%1$s", "|cff", "|H", "|T", "|A", "|r" }
local WORDS = { "alarme", "add", "soneca", "parar", "saque", "limpar", "aviso", "durab", "bolsas", "talentos",
                "graus", "som", "status", "silenciar", "lembrar", "aparencia", "escala", "fundo", "texto", "icones",
                "largura", "coluna", "linha", "ordem", "padrao", "show", "hide", "lang", "menu", "lock", "reset",
                "sessao", "zerar", "historico", "on", "off", "07:30", "25:99", "-1", "99999" }
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
                       "alarms", "loot", "warnings", "order", "snoozeMinutes", "shown", "locked", "icons", "vertical" }
        for i = 1, 60 do
            local db = {}
            for _, key in ipairs(KEYS) do if random(3) > 1 then db[key] = pick(BAD) end end
            local char = {
                items = { { link = "|cff1eff00|Hitem:1|h[Ok]|h|r", count = pick(BAD), q = pick(BAD), t = pick(BAD) } },
                warnHistory = { { t = pick(BAD), text = "Aviso " .. i }, pick(BAD) },
            }
            local ok, err = pcall(function()
                local H = Mock.new():login(db, char)
                H:update(1)
                for _, cmd in ipairs({ "menu", "saque", "historico", "ordem", "alarme", "aviso", "aparencia" }) do
                    H:slash(cmd)
                end
            end)
            T.ok(ok, "saved data #" .. i .. ": " .. tostring(err))
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
