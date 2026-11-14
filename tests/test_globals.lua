-- Regra do projeto: só nomes globais começando com "Farol" (janelas/botões), FarolDB, FarolCharDB,
-- SLASH_FAROL1, Farol_ToggleWarnHistory e BINDING_*. Nada de globais genéricos (evita conflito com outros addons).
-- Project rule: only globals starting with "Farol", SLASH_FAROL1 and BINDING_*.

local ALLOWED = { "^Farol", "^BINDING_", "^SLASH_FAROL1$" }

local function allowed(name)
    for _, pattern in ipairs(ALLOWED) do
        if string.find(name, pattern) then return true end
    end
    return false
end

local FILES = { "Core", "Alarm", "Loot", "Warnings", "Appearance", "Order" }

return {
    { "using every feature creates no global outside the Farol names", function(T, Mock)
        local H = Mock.new()
        local before = {}
        for k in pairs(H.env) do before[k] = true end
        H:login({ warnings = { pause = true, pauseMin = 15, water = true, waterMin = 15, pauseAnywhere = true } })
        for _, cmd in ipairs({ "menu", "alarme", "alarme add 07:30 Teste", "saque", "aviso", "aparencia", "historico",
                               "ordem", "aparencia coluna", "aparencia largura 400", "aviso status", "help", "version",
                               "sessao zerar", "show xph", "show rep", "show reset", "show prof", "show lixo", "ouro", "ouro total on", "ouro esquecer Ninguem", "aviso descansado on", "novidades", "aviso profissoes off", "aviso profissoes on", "resumo", "resumo off", "lang en",
                               "lock", "lock", "aviso padrao 5", "aviso agua 20", "aviso pausa lutas off" }) do
            H:slash(cmd)
        end
        H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff1eff00|Hitem:1|h[X]|h|r.")
        H.talentPoints = 2; H.clock.hour, H.clock.min = 7, 30
        for _ = 1, 16 do H:update(60) end
        H:click(H.env.FarolWarnRemindTime); H:click(H.env.FarolWarnRow1Time); H:click(H.env.FarolWarnRemind)
        H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
        H:event("PLAYER_LOGOUT")
        local bad = {}
        for k in pairs(H.env) do
            if not before[k] and type(k) == "string" and not allowed(k) then bad[#bad + 1] = k end
        end
        table.sort(bad)
        T.eq(table.concat(bad, ", "), "", "generic globals created")
    end },

    { "no file declares a global function outside the Farol names", function(T)
        for _, file in ipairs(FILES) do
            local handle = assert(io.open("Farol/" .. file .. ".lua", "r"))
            local number = 0
            for line in handle:lines() do
                number = number + 1
                local name = string.match(line, "^%s*function%s+([%w_]+)%s*%(")
                if name then T.ok(allowed(name), file .. ".lua:" .. number .. " global function " .. name) end
            end
            handle:close()
        end
    end },
}
