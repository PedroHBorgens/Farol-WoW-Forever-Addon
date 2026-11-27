-- Layout das janelas e da Central (3.31.2): nenhum texto da interface cortado, saindo do quadro/cartão/janela,
-- botão pequeno para o texto ou sobreposição — em português e em inglês, com dados cheios e com tudo vazio.
-- Window and hub layout: no interface text clipped or leaving its panel, in PT and EN, full and empty.
-- Nomes digitados pelo jogador (de propósito compridos aqui) podem terminar com "..." e ficam de fora.
local LC = require("layout_check")

local LONG = { "comprido", "compr", "Longo", "Alternativo", "Porto Antigo", "Excepcional", "Item Com Um Nome", "Alquimia para o nível alto" }
local function Real(list)
    local out = {}
    for _, p in ipairs(list) do
        local user = false
        for _, word in ipairs(LONG) do if string.find(p, word, 1, true) then user = true end end
        if not user then out[#out + 1] = p end
    end
    return out
end

local function Scenario(T, Mock, locale)
    local undo = LC.Install()
    local ok, err = pcall(function()
        local bad = {}
        local function check(H, name, title)
            LC.Check(H, name)
            for _, p in ipairs(Real(LC.Take())) do bad[#bad + 1] = title .. " → " .. p end
        end
        local H = Mock.new({ locale = locale })
        H.items[4306] = { "Tecido de Seda", 1, 150 }; H.itemCounts[4306] = 12
        H:login({ hub = false })
        H:slash("menu")
        local set = H.env.FarolOptions.controls
        for _, tab in ipairs({ "bar", "warnings", "tools", "general" }) do H:click(set.tabs[tab]); check(H, "FarolOptions", "menu " .. tab) end
        H:slash("menu")
        local function open(cmd, name, setup)
            if setup then setup() end
            H:slash(cmd); check(H, name, name)
            if H.env[name] and H.env[name]:IsShown() then H.env[name]:Hide() end
        end
        open("aparencia", "FarolAppearance")
        open("ordem", "FarolOrder")
        open("alarme", "FarolAlarms", function() H:slash("alarme add 07:30 servidor Raide da guilda com nome comprido"); H:slash("alarme add 21:00") end)
        open("saque", "FarolLoot", function()
            for _ = 1, 6 do H:event("CHAT_MSG_LOOT", "Você recebe saque: |cffffffff|Hitem:4306::::|h[Tecido de Seda de Qualidade Excepcional]|h|rx12.") end end)
        open("meta", "FarolGoals", function()
            H:slash("meta ouro 500"); H:slash("meta nivel 40")
            for id = 1, 10 do H:slash("meta item |cffffffff|Hitem:" .. (7000 + id) .. "::|h[Item Com Um Nome Bem Comprido " .. id .. "]|h|r 40") end end)
        open("tarefa", "FarolTasks", function() for i = 1, 10 do H:slash("tarefa add " .. (i % 2 == 0 and "semanal " or "") .. "Tarefa de nome bem comprido " .. i) end end)
        open("masmorra", "FarolRuns")
        open("notas", "FarolNotes", function() H:slash("notas nova Rota de farm de couro com nome comprido"); H:slash("notas nova Comprar"); H:slash("notas") end)
        open("guardar", "FarolKeep", function()
            H.items[7001] = { "Erva-de-luar com um nome bem comprido", 2, 25 }; H.itemCounts[7001] = 4
            H:slash("guardar |cff1eff00|Hitem:7001::|h[Erva-de-luar com um nome bem comprido]|h|r: receita de Alquimia para o nível alto")
            for i = 1, 11 do H:slash("guardar |cffffffff|Hitem:" .. (7100 + i) .. "::|h[Item " .. i .. "]|h|r: motivo " .. i) end end)
        H.env.FarolDB.hub = true; H.ns.Hub.Open("home"); check(H, "FarolHub", "hub home")
        -- 3.34: valor das missões prontas ligado e uma corrida de masmorra com nome comprido no cartão "Agora"
        H.quests = { { title = "Pronta", level = 20, done = true, xp = 123456, money = 987654 } }
        H.env.FarolDB.warnings.questValue = true
        H.env.GetInstanceInfo = function() return "Profundezas da Fortaleza de nome comprido", "party" end
        H.instanceType = "party"; H:event("PLAYER_ENTERING_WORLD"); H.ns.Runs.Update()
        H.ns.Hub.Refresh(); check(H, "FarolHub", "hub home in a run")
        H.instanceType = nil; H:event("PLAYER_ENTERING_WORLD"); H.ns.Runs.Update(); H.ns.Hub.Refresh()
        H:click(H.env.FarolHubNavprofs); check(H, "FarolHub", "hub profs")
        H:click(H.env.FarolHubNavchars); check(H, "FarolHub", "hub chars")
        local SECTIONS = { { "tasks", "FarolTasks" }, { "notes", "FarolNotes" }, { "keep", "FarolKeep" }, { "goals", "FarolGoals" },
            { "quests", "FarolCompleted" }, { "runs", "FarolRuns" }, { "loot", "FarolLoot" }, { "alarms", "FarolAlarms" },
            { "warnings", "FarolWarnHistory" }, { "settings", "FarolOptions" } }
        for _, sec in ipairs(SECTIONS) do H.ns.Hub.Select(sec[1]); check(H, sec[2], "hub " .. sec[1]) end
        -- 3.32: as 4 abas da Configurações em cartões
        H.ns.Hub.Select("settings")
        local detail = H.env.FarolOptions.detailControls
        T.ok(detail, "settings in cards inside the hub")
        for _, tab in ipairs({ "bar", "warnings", "tools", "general" }) do
            H:click(detail.tabs[tab]); check(H, "FarolOptions", "hub settings " .. tab)
        end
        -- Central vazia (instalação nova) e um personagem visto hoje
        local E = Mock.new({ locale = locale }); E:login({ hub = true })
        local n, r = E.ns.CurrentCharacter()
        E.env.FarolDB.chars[r] = E.env.FarolDB.chars[r] or {}
        E.env.FarolDB.chars[r]["Personagem Alternativo Longo"] = { gold = 1234567, level = 12, t = os.time() - 3 * 3600, rest = 100, max = 1000, inn = true, bind = "Vila do Porto Antigo" }
        E:slash("central"); check(E, "FarolHub", "empty home")
        E:click(E.env.FarolHubNavchars); check(E, "FarolHub", "empty chars")
        for _, sec in ipairs(SECTIONS) do E.ns.Hub.Select(sec[1]); check(E, sec[2], "empty " .. sec[1]) end
        -- 3.33: janelinhas no visual da Central (um aviso, vários, alarme)
        local Pp = Mock.new({ locale = locale }); Pp:login({ hub = true })
        Pp:update(1); check(Pp, "FarolWarnPopup", "popup one warning")
        Pp.talentPoints = 1; Pp.bagFree = { [0] = 0, 0, 0, 0, 1 }; Pp:update(1); check(Pp, "FarolWarnPopup", "popup several warnings")
        Pp:slash("alarme add 07:30 Raide"); Pp:update(1); Pp.clock.hour, Pp.clock.min = 7, 30; Pp:update(1)
        check(Pp, "FarolAlarmPopup", "alarm popup")
        T.eq(#bad, 0, locale .. ": " .. table.concat(bad, "\n    "))
    end)
    undo()
    if not ok then error(err, 0) end
end

-- 3.34.1: telas de vários tamanhos. A área útil (UIParent) depende da resolução e da escala da interface: numa tela
-- 5:4 com a escala no máximo ela tem só ~835 x 668. Toda janela (e a Central, mesmo a 130%) tem de caber nela.
local SCREENS = { { 835, 668 }, { 1024, 768 }, { 1365, 768 }, { 1229, 768 }, { 2560, 1080 } }
local WINDOWS = { { "menu", "FarolOptions" }, { "aparencia", "FarolAppearance" }, { "ordem", "FarolOrder" },
    { "alarme", "FarolAlarms" }, { "saque", "FarolLoot" }, { "meta", "FarolGoals" }, { "tarefa", "FarolTasks" },
    { "masmorra", "FarolRuns" }, { "notas", "FarolNotes" }, { "guardar", "FarolKeep" }, { "concluidas", "FarolCompleted" } }
local function Screens(T, Mock, locale)
    local bad = {}
    for _, screen in ipairs(SCREENS) do
        local sw, sh = screen[1], screen[2]
        local function fits(H, name, title)
            local f = H.env[name]
            if not (f and f:IsShown()) then bad[#bad + 1] = title .. ": não abriu" return end
            local s = f:GetScale()
            local w, h = f:GetWidth() * s, f:GetHeight() * s
            if w > sw + 0.5 or h > sh + 0.5 then
                bad[#bad + 1] = string.format("%s em %dx%d: %.0f x %.0f não cabe", title, sw, sh, w, h)
            end
        end
        local H = Mock.new({ locale = locale }); H.env.UIParent:SetSize(sw, sh); H:login({ hub = false })
        for _, w in ipairs(WINDOWS) do
            H:slash(w[1]); fits(H, w[2], w[2])
            if H.env[w[2]] and H.env[w[2]]:IsShown() then H.env[w[2]]:Hide() end
        end
        H.env.FarolDB.hubScale = 1.3
        H:slash("central"); fits(H, "FarolHub", "Central 130%")
        H.ns.Hub.Select("settings"); fits(H, "FarolHub", "Central 130% (Configurações)")
        H.env.FarolHub:Hide(); H:slash("central tamanho 70"); H:slash("central"); fits(H, "FarolHub", "Central 70%")
        T.ok(H.env.FarolHub:GetScale() <= 0.7 + 1e-9, "the hub never gets bigger than asked")
        H.env.FarolHub:Hide()
    end
    T.eq(#bad, 0, locale .. ": " .. table.concat(bad, "\n    "))
end

return {
    { "3.31.2: no interface text clipped or leaving its panel (Portuguese)", function(T, Mock) Scenario(T, Mock, "ptBR") end },
    { "3.31.2: no interface text clipped or leaving its panel (English)", function(T, Mock) Scenario(T, Mock, "enUS") end },
    { "3.34.1: every window and the hub fit small and large screens (Portuguese)", function(T, Mock) Screens(T, Mock, "ptBR") end },
    { "3.34.1: every window and the hub fit small and large screens (English)", function(T, Mock) Screens(T, Mock, "enUS") end },
}
