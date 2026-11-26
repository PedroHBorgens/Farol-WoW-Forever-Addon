-- Regra 8: função nova vem DESLIGADA. Só liga por padrão o que está nas listas abaixo (aprovadas pelo dono do
-- projeto). Ligar outra coisa por padrão exige mudar este teste de propósito.
-- Rule 8: new features start OFF. Only what is listed below (approved by the project owner) is on by default.

local ON_ITEMS = { fps = true, ms = true, coords = true, zone = true, durab = true, gold = true,
                   hearth = true } -- Pedra de Regresso: aprovada pelo dono (3.10), só em instalação nova
local ON_WARNINGS = { durab = true, bags = true, sound = true, talents = true, ranks = true, prof = true }
local ON_GENERAL = { shown = true, summary = true, runSummary = true, border = true, icons = true,
                     warnButton = true, lootButton = true }
-- Ligado só em INSTALAÇÃO NOVA (quem já usa continua desligado), aprovado pelo dono: Central do Farol (3.28).
local ON_NEW_INSTALL = { hub = true }
-- Padrões "ligado se não estiver salvo" (x ~= false) permitidos: arquivo → quantos.
local DEFAULT_TRUE_PATTERNS = { ["Alarm.lua"] = 1, ["Loot.lua"] = 1, ["MinimapButton.lua"] = 1 }
local FILES = { "Core.lua", "Alarm.lua", "Loot.lua", "Warnings.lua", "Appearance.lua", "Order.lua", "Tasks.lua", "Notes.lua",
                "Goals.lua", "Farm.lua", "Keep.lua", "Quests.lua", "Hearth.lua", "Runs.lua", "Completed.lua", "Sources.lua", "Diag.lua", "Hub.lua", "MinimapButton.lua" }

local function read(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end
local function sorted(set)
    local list = {}
    for k in pairs(set) do list[#list + 1] = k end
    table.sort(list)
    return table.concat(list, ", ")
end
-- Chaves "= true" de uma tabela do código-fonte (ex.: "local DEFAULTS = {").
local function trueKeys(code, header)
    local start = string.find(code, header, 1, true)
    if not start then return nil end
    local body = string.match(code, "%b{}", start)
    body = string.gsub(body, "%-%-[^\n]*", "")
    local keys = {}
    for key in string.gmatch(body, "([%w_]+)%s*=%s*true") do keys[key] = true end
    return keys
end

return {
    { "a fresh install turns on only the approved items, warnings and options", function(T, Mock)
        for _, mode in ipairs({ "forever", "wotlk" }) do
            local H = Mock.new({ mode = mode }):login()
            local db = H.env.FarolDB
            local on = {}
            for _, key in ipairs(H.ns.ITEM_ORDER) do if db.items[key] then on[key] = true end end
            T.eq(sorted(on), sorted(ON_ITEMS), mode .. ": bar items on by default")
            on = {}
            for key, value in pairs(db.warnings) do if value == true then on[key] = true end end
            T.eq(sorted(on), sorted(ON_WARNINGS), mode .. ": warnings on by default")
            for _, key in ipairs({ "shown", "summary", "runSummary", "border", "icons", "warnButton", "lootButton",
                                   "serverTime", "goldTotal", "tooltipFull", "hideCombat", "hideInstance", "locked" }) do
                T.eq(db[key] == true, ON_GENERAL[key] == true, mode .. ": option " .. key)
            end
            T.eq(db.minimap.show, true, "minimap button shown (approved)"); T.eq(db.minimap.locked, false)
            T.eq(H.env.FarolCharDB.profile ~= "char", true, "account profile by default")
            T.ok(not H.env.FarolBar2 or not H.env.FarolBar2:IsShown(), "bar 2 off"); T.ok(not H.env.FarolBar3 or not H.env.FarolBar3:IsShown(), "bar 3 off")
            T.eq(#H.env.FarolDB.alarms, 0, "no alarms"); T.eq(#H.env.FarolCharDB.tasks, 0, "no tasks")
            T.eq(#H.env.FarolCharDB.farm, 0, "no farm goals"); T.eq(H.env.FarolCharDB.goals.gold, nil, "no goals")
        end
    end },

    { "on only in a new install (owner-approved list); updating never turns them on", function(T, Mock)
        local fresh = Mock.new():login()
        local used = Mock.new():login({ items = { fps = true } })
        for key in pairs(ON_NEW_INSTALL) do
            T.eq(fresh.env.FarolDB[key], true, key .. ": on in a new install")
            T.eq(used.env.FarolDB[key], false, key .. ": off for players who already use Farol")
        end
    end },

    { "the source code has no other default that is on (new feature = off)", function(T)
        local core, warnings = read("Farol/Core.lua"), read("Farol/Warnings.lua")
        T.eq(sorted(trueKeys(core, "local ITEM_DEFAULTS = {")), sorted(ON_ITEMS), "ITEM_DEFAULTS in Core.lua")
        T.eq(sorted(trueKeys(core, "local DEFAULTS = {")), sorted(ON_GENERAL), "DEFAULTS in Core.lua")
        T.eq(sorted(trueKeys(warnings, "local DEFAULTS = {")), sorted(ON_WARNINGS), "DEFAULTS in Warnings.lua")
        for _, file in ipairs(FILES) do
            local code = string.gsub(read("Farol/" .. file), "%-%-[^\n]*", "")
            local _, count = string.gsub(code, "~=%s*false", "")
            T.eq(count, DEFAULT_TRUE_PATTERNS[file] or 0, file .. ": 'x ~= false' turns something on by default")
        end
    end },

    { "the player is told that everything is optional, and where to turn new things on", function(T, Mock)
        local H = Mock.new():login()
        T.has(H.strip(table.concat(H.msgs, "\n")), "informações e vários avisos desligados")
        H:slash("menu")
        local hint = H:text(H.env.FarolOptions.controls.hint)
        T.has(hint, "tudo é opcional")
        -- Quem atualiza vê as novidades com "desligado" e onde ligar.
        local saved = { newsSeen = #H.ns.NEWS - 17, items = { fps = true } }
        H = Mock.new():login(saved)
        local text = H.strip(table.concat(H.msgs, "\n"))
        T.has(text, "metas de farm"); T.has(text, "desligado (ligue em Menu > Barra)")
        T.has(text, "diário de missões na barra")
    end },
}
