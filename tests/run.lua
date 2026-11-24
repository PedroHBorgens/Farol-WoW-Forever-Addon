--[[
  Executa todos os testes do Farol fora do jogo.
  Runs all Farol tests outside the game.

  Uso / usage (na raiz do repositório / from the repository root):
      lua5.1 tests/run.lua

  Sai com código 1 se algum teste falhar (o GitHub Actions marca a execução como falha).
]]

package.path = "./tests/?.lua;" .. package.path

local Mock = require("wow_mock")

-- Asserções / assertions
local T = {}

local function fail(message, level)
    error(message, (level or 1) + 2)
end

function T.ok(condition, message)
    if not condition then fail(message or "expected true", 1) end
end

function T.eq(actual, expected, message)
    if actual ~= expected then
        fail(string.format("%s: expected %s, got %s", message or "values differ",
            tostring(expected), tostring(actual)), 1)
    end
end

function T.has(text, fragment, message)
    text = tostring(text)
    if not string.find(text, fragment, 1, true) then
        fail(string.format("%s: %q not found in %q", message or "missing text", fragment, text), 1)
    end
end

function T.hasnt(text, fragment, message)
    text = tostring(text)
    if string.find(text, fragment, 1, true) then
        fail(string.format("%s: %q should not be in %q", message or "unexpected text", fragment, text), 1)
    end
end

local SUITES = {
    "test_toc",
    "test_bar",
    "test_options",
    "test_alarms",
    "test_loot",
    "test_rates",
    "test_warnings",
    "test_appearance",
    "test_reminders",
    "test_history",
    "test_quickbuttons",
    "test_layers",
    "test_order",
    "test_layout",
    "test_fuzz",
    "test_rep",
    "test_reset",
    "test_summary",
    "test_breaks",
    "test_prof",
    "test_junk",
    "test_alts",
    "test_rest",
    "test_onboarding",
    "test_lockouts",
    "test_tooltip",
    "test_supplies",
    "test_profiles",
    "test_bars",
    "test_charprofiles",
    "test_tasks",
    "test_menu",
    "test_goals",
    "test_runs",
    "test_minimap", "test_farm", "test_quests", "test_defaults", "test_hearth", "test_menu2", "test_a11y", "test_undo", "test_copy", "test_hardening", "test_completed", "test_realm", "test_forever_real", "test_sources", "test_chat",
    "test_globals",
}

local passed, failed = 0, 0
local failures = {}

-- Duas passadas: a 1ª com o simulador "de livro" (reino com nome, nome sem sobrenome); a 2ª, "forever-real", como o
-- WoW Forever responde de verdade (reino vazio e sobrenome). Ouro 0 ao sair vale nas duas. Suítes com
-- fixedIdentity = true usam um reino e um nome fixos nos dados salvos e mantêm essa identidade na 2ª passada.
-- FAROL_PASS=1 ou FAROL_PASS=2 roda só uma delas.
local onlyPass = tonumber(os.getenv and os.getenv("FAROL_PASS") or nil)
for pass = 1, 2 do
    if not onlyPass or onlyPass == pass then
        local label = pass == 1 and "" or " [forever-real]"
        if pass == 2 then print("\n######## forever-real: reino vazio + sobrenome ########") end
        for _, suiteName in ipairs(SUITES) do
            local suite = require(suiteName)
            Mock.REAL = pass == 2 and not suite.fixedIdentity
            print("== " .. suiteName .. label)
            for _, case in ipairs(suite) do
                local ok, err = pcall(case[2], T, Mock)
                if ok then
                    passed = passed + 1
                    print("  ok    " .. case[1])
                else
                    failed = failed + 1
                    print("  FAIL  " .. case[1])
                    print("        " .. tostring(err))
                    table.insert(failures, suiteName .. label .. " / " .. case[1])
                end
            end
        end
        Mock.REAL = false
    end
end

print(string.format("\n%d passed, %d failed (%s)", passed, failed, _VERSION))
if failed > 0 then
    for _, name in ipairs(failures) do print("  - " .. name) end
    os.exit(1)
end
