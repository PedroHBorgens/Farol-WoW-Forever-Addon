--[[
  Farol — Pedra de Regresso / Hearthstone

  Onde a Pedra de Regresso está vinculada (GetBindLocation) e quanto falta da recarga (C_Container.GetItemCooldown
  ou GetItemCooldown do item 6948). Aviso opcional quando a recarga termina (Warnings.lua). O lugar de cada
  personagem é guardado pelo Core ao sair (FarolDB.chars[reino][nome].bind) e aparece no tooltip do ouro.
  Só lê: nunca usa a pedra nem vincula em outro lugar (as funções de usar itens são proibidas pelo test_toc).
  Nada é enviado.
]]

local _, ns = ...

local HEARTHSTONE = 6948  -- item da Pedra de Regresso (estilo clássico)
local GCD = 1.5           -- recargas curtas (recarga global) não contam
local PLACE_MAX = 40      -- letras do lugar guardadas/mostradas
local PLACE_SHORT = 24    -- letras do lugar na barra

local Hearth = {}
ns.Hearth = Hearth

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_hearth   = "Pedra de Regresso", cmd_hearth = "regresso",
        desc_hearth   = "Onde a sua Pedra de Regresso está vinculada e quanto falta para poder usá-la de novo.",
        hearth_ready  = "pronta",
        hearth_none   = "sem pedra",
        tt_hearth     = "Pedra de Regresso",
        tt_hearth_bind = "Vinculada em",
        tt_hearth_cd  = "Recarga",
        tt_hearth_at  = "pronta às",
        tt_hearth_nostone = "a pedra não está nas suas bolsas",
        tt_hearth_unknown = "o jogo não informou o lugar",
        news_hearth   = "Pedra de Regresso na barra: onde está vinculada e quanto falta da recarga",
    },
    en = {
        name_hearth   = "Hearthstone", cmd_hearth = "hearth",
        desc_hearth   = "Where your Hearthstone is bound and how long until you can use it again.",
        hearth_ready  = "ready",
        hearth_none   = "no stone",
        tt_hearth     = "Hearthstone",
        tt_hearth_bind = "Bound to",
        tt_hearth_cd  = "Cooldown",
        tt_hearth_at  = "ready at",
        tt_hearth_nostone = "the stone is not in your bags",
        tt_hearth_unknown = "the game did not report the place",
        news_hearth   = "Hearthstone on the bar: where it is bound and how long until it is ready",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end

---------------------------------------------------------------------------
-- Leituras do jogo (protegidas: erro, valor bloqueado ou absurdo = nil)
---------------------------------------------------------------------------

local function Secret(value) return ns.IsSecret and ns.IsSecret(value) end
local function Number(value, low, high)
    if type(value) ~= "number" or Secret(value) or value ~= value or value < low or value > high then return nil end
    return value
end

-- Texto limpo: sem "|" nem controle, até `limit` letras (UTF-8 inteiro).
local function Clean(text, limit)
    if type(text) ~= "string" or Secret(text) then return nil end
    text = string.gsub(string.gsub(text, "|", ""), "%c", "")
    text = ns.Trim(text) -- linear (nome enorme num arquivo adulterado não trava)
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > limit then break end
        out[#out + 1] = char
    end
    text = table.concat(out)
    return text ~= "" and text or nil
end
Hearth.Clean = function(text) return Clean(text, PLACE_MAX) end

function Hearth.BindLocation()
    if type(GetBindLocation) ~= "function" then return nil end
    local ok, place = pcall(GetBindLocation)
    if not ok then return nil end
    return Clean(place, PLACE_MAX)
end

-- true/false se o jogo informou; nil se não deu para ler.
local function HasStone()
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    if type(getCount) ~= "function" then return nil end
    local ok, n = pcall(getCount, HEARTHSTONE)
    n = ok and Number(n, 0, 100000) or nil
    if n == nil then return nil end
    return n > 0
end

-- Segundos que faltam (0 = pronta) ou nil se o jogo não informar.
local function Remaining()
    local getCooldown = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if type(getCooldown) ~= "function" or type(GetTime) ~= "function" then return nil end
    local ok, start, duration = pcall(getCooldown, HEARTHSTONE)
    if not ok then return nil end
    start, duration = Number(start, 0, 1e10), Number(duration, 0, 86400)
    local okNow, now = pcall(GetTime)
    now = okNow and Number(now, 0, 1e10) or nil
    if not start or not duration or not now then return nil end
    if start == 0 or duration <= GCD then return 0 end
    local left = start + duration - now
    if left <= 0 then return 0 end
    return left
end

-- { place, stone (true/false/nil), left (s, 0 = pronta, nil = sem leitura) }
function Hearth.Status()
    return { place = Hearth.BindLocation(), stone = HasStone(), left = Remaining() }
end

-- Para o aviso: pronta agora (com a pedra nas bolsas)?
function Hearth.Ready()
    local status = Hearth.Status()
    if status.stone == false or status.left == nil then return nil, status end
    return status.left == 0, status
end

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

local function Duration(seconds)
    seconds = math.max(1, math.floor(seconds + 0.5))
    if seconds < 60 then return seconds .. "s" end
    return ns.FormatDuration and ns.FormatDuration(seconds) or (math.floor(seconds / 60) .. "m")
end

local function State(status)
    if status.stone == false then return ns.C.dim .. T("hearth_none") .. "|r" end
    if status.left == nil then return ns.C.dim .. "--|r" end
    if status.left == 0 then return ns.C.good .. T("hearth_ready") .. "|r" end
    return ns.C.warn .. Duration(status.left) .. "|r"
end

-- Sem o lugar (o jogo não informou), o item some da barra, como a corrida fora de masmorras.
function Hearth.BarText()
    local status = Hearth.Status()
    if not status.place then return nil end
    return Clean(status.place, PLACE_SHORT) .. (status.place ~= Clean(status.place, PLACE_SHORT) and ".." or "")
        .. " · " .. State(status)
end

function Hearth.Tooltip()
    local status = Hearth.Status()
    GameTooltip:AddLine(T("tt_hearth"), 1, 0.82, 0)
    GameTooltip:AddDoubleLine("   " .. T("tt_hearth_bind"), status.place or T("tt_hearth_unknown"), 1, 0.82, 0, 1, 1, 1)
    if status.stone == false then
        GameTooltip:AddLine("   " .. T("tt_hearth_nostone"), 0.6, 0.6, 0.6)
        return
    end
    GameTooltip:AddDoubleLine("   " .. T("tt_hearth_cd"), State(status), 1, 0.82, 0, 1, 1, 1)
    if status.left and status.left > 0 and type(time) == "function" and type(date) == "function" then
        local okNow, now = pcall(time)
        if okNow and Number(now, 0, 1e10) then
            local ok, at = pcall(date, "%H:%M", math.floor(now + status.left))
            if ok and type(at) == "string" then
                GameTooltip:AddDoubleLine("      " .. T("tt_hearth_at"), at, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
            end
        end
    end
end
