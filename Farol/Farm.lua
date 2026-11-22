--[[
  Farol — Metas de farm (itens) / Farm goals (items)

  O jogador escolhe itens para juntar ("40 Tecido de Seda"); o Farol conta quantos tem (bolsas e, quando o jogo
  informa, banco), quanto pegou nesta sessão, o ritmo por hora e uma ESTIMATIVA de tempo.
  Só lê e mostra: contagem de itens do próprio personagem. Nunca move, vende, usa ou saqueia nada; nenhum pedido
  ao servidor; nada enviado. O link do item (Shift + clique) só é lido para tirar o número e o nome do item.
  Fica em FarolCharDB.farm = { { id = número do item, n = nome limpo, c = quantidade alvo, w = aviso já mostrado } }
  (máx. 10), validado ao carregar (Farm.Sanitize). A contagem do início da sessão fica só na memória.
]]

local _, ns = ...

local MAX_ITEMS = 10
local MAX_TARGET = 100000
local MAX_ID = 10000000
local MAX_NAME_CHARS = 40
local NAME_SHORT = 18            -- letras do nome na barra
local DEFAULT_TARGET = 20        -- botão "Acompanhar" da janela de saques
local RATE_MIN_SECONDS = 60      -- ritmo só depois de 1 minuto

local Farm = {}
ns.Farm = Farm

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_farm     = "Farm (metas de itens)", cmd_farm = "farm",
        desc_farm     = "Itens que você quer juntar: quantos tem, quantos pegou nesta sessão, ritmo por hora e estimativa.",
        label_farm    = "Farm",
        tt_farm       = "Farm (metas de itens)",
        tt_farm_none  = "nenhum item (/farol meta item [link] 40 ou o botão \"+ Meta\" nos saques)",
        tt_farm_session = "+%d nesta sessão (~%s/h) · faltam ~%s",
        tt_farm_session_only = "+%d nesta sessão (~%s/h)",
        tt_farm_norate = "sem ritmo ainda nesta sessão",
        tt_farm_bank  = "conta bolsas + banco (quando o jogo informa)",
        farm_added    = "meta de farm: %s %d/%d.",
        farm_changed  = "meta de farm: %s agora é %d.",
        farm_removed  = "meta de farm apagada: %s (Desfazer na janela de Metas ou /farol meta item desfazer).",
        farm_cleared  = "metas de farm apagadas.",
        farm_full     = "no máximo %d itens; apague um com /farol meta item remover <nome>.",
        farm_bad_target = "quantidade inválida: use de 1 a 100000.",
        farm_not_found = "item não encontrado: use Shift + clique no item (o item precisa estar nas bolsas ou nos saques).",
        farm_missing  = "nenhuma meta de farm com esse nome ou número.",
        farm_list     = "metas de farm:",
        farm_none     = "nenhuma meta de farm.",
        farm_reached  = "%s %d/%d",
        farm_usage    = "uso: /farol meta item [link] N || /farol meta item <nome> N || /farol meta item remover <nome||número> || /farol meta item desfazer || /farol meta item limpar",
        farm_header   = "Farm (itens):",
        farm_remove_tip = "Apagar esta meta (dá para desfazer)",
        farm_restored = "meta de farm de volta: %s.",
        farm_nothing_undo = "nada para desfazer.",
        farm_undo     = "Desfazer",
        farm_undo_line = "apagada: %s",
        loot_track    = "+ Meta",
        loot_track_tip = "Acompanhar este item (meta de farm de %d; mude na janela Metas)",
        help_farm     = "  /farol meta item     - metas de farm: quantos itens juntar (Shift + clique no item)",
        news_farm     = "metas de farm: quantos itens juntar, ritmo por hora e estimativa (/farol meta item)",
    },
    en = {
        name_farm     = "Farm (item goals)", cmd_farm = "farm",
        desc_farm     = "Items you want to gather: how many you have, how many this session, pace per hour and an estimate.",
        label_farm    = "Farm",
        tt_farm       = "Farm (item goals)",
        tt_farm_none  = "no items (/farol goal item [link] 40 or the \"+ Goal\" button in the loot window)",
        tt_farm_session = "+%d this session (~%s/h) · ~%s left",
        tt_farm_session_only = "+%d this session (~%s/h)",
        tt_farm_norate = "no pace yet this session",
        tt_farm_bank  = "counts bags + bank (when the game reports it)",
        farm_added    = "farm goal: %s %d/%d.",
        farm_changed  = "farm goal: %s is now %d.",
        farm_removed  = "farm goal removed: %s (Undo in the Goals window or /farol goal item undo).",
        farm_cleared  = "farm goals removed.",
        farm_full     = "at most %d items; remove one with /farol goal item remove <name>.",
        farm_bad_target = "invalid amount: use 1 to 100000.",
        farm_not_found = "item not found: shift-click the item (it must be in your bags or in the loot window).",
        farm_missing  = "no farm goal with that name or number.",
        farm_list     = "farm goals:",
        farm_none     = "no farm goals.",
        farm_reached  = "%s %d/%d",
        farm_usage    = "usage: /farol goal item [link] N || /farol goal item <name> N || /farol goal item remove <name||number> || /farol goal item undo || /farol goal item clear",
        farm_header   = "Farm (items):",
        farm_remove_tip = "Remove this goal (can be undone)",
        farm_restored = "farm goal back: %s.",
        farm_nothing_undo = "nothing to undo.",
        farm_undo     = "Undo",
        farm_undo_line = "removed: %s",
        loot_track    = "+ Goal",
        loot_track_tip = "Track this item (farm goal of %d; change it in the Goals window)",
        help_farm     = "  /farol goal item     - farm goals: how many items to gather (shift-click the item)",
        news_farm     = "farm goals: how many items to gather, pace per hour and an estimate (/farol goal item)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function List()
    if not FarolCharDB then return {} end
    if type(FarolCharDB.farm) ~= "table" then FarolCharDB.farm = {} end
    return FarolCharDB.farm
end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

local function Int(value, low, high)
    if type(value) ~= "number" or value ~= value or value ~= math.floor(value) or value < low or value > high then return nil end
    return value
end

-- Nome limpo: sem "|" (códigos do chat) nem caracteres de controle, até MAX_NAME_CHARS letras (UTF-8 inteiro).
local function CleanName(text, limit)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "|", "")
    text = string.gsub(text, "%c", "")
    text = string.match(text, "^%s*(.-)%s*$") or ""
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > (limit or MAX_NAME_CHARS) then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end
Farm.CleanName = CleanName

function Farm.Sanitize(saved)
    local clean, seen = {}, {}
    if type(saved) ~= "table" then return clean end
    for i = 1, MAX_ITEMS do
        local entry = saved[i]
        if type(entry) ~= "table" then break end
        local id, target = Int(entry.id, 1, MAX_ID), Int(entry.c, 1, MAX_TARGET)
        local name = CleanName(entry.n)
        if id and target and name ~= "" and not seen[id] then
            seen[id] = true
            clean[#clean + 1] = { id = id, n = name, c = target, w = entry.w == true or nil }
        end
    end
    return clean
end

---------------------------------------------------------------------------
-- Leituras do jogo (protegidas: erro, valor bloqueado ou absurdo = nil)
---------------------------------------------------------------------------

local function Num(value, max)
    if type(value) ~= "number" or value ~= value or value < 0 or value > max then return nil end
    if ns.IsSecret and ns.IsSecret(value) then return nil end
    return value
end

local function Now()
    if not GetTime then return nil end
    local ok, now = pcall(GetTime)
    if not ok then return nil end
    return Num(now, 1e10)
end

-- Quantos o personagem tem (bolsas + banco quando o jogo informa). nil se o jogo não responder.
local function Count(id)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    if type(getCount) ~= "function" then return nil end
    local ok, n = pcall(getCount, id, true)
    if not ok then return nil end
    n = Num(n, 1000000)
    return n and math.floor(n) or nil
end

-- Nome atual no idioma do jogo (o salvo fica de reserva).
local function LiveName(id)
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(getInfo) ~= "function" then return nil end
    local ok, name = pcall(getInfo, id)
    if not ok or type(name) ~= "string" then return nil end
    name = CleanName(name)
    return name ~= "" and name or nil
end

-- Número e nome de um link de item ("|cff...|Hitem:2996:...|h[Nome]|h|r"). Nada além disso é lido.
local function ParseLink(text)
    if type(text) ~= "string" or #text > 400 then return nil end
    local id = tonumber(string.match(text, "|Hitem:(%d+)"))
    if not Int(id, 1, MAX_ID) then return nil end
    local name = CleanName(string.match(text, "|h%[(.-)%]|h") or "")
    return id, name ~= "" and name or nil
end
Farm.ParseLink = ParseLink

-- Procura um item pelo nome: informação do jogo, bolsas e histórico de saques. Só lê.
local function FindByName(name)
    name = string.match(CleanName(name), "^%[?(.-)%]?$") or ""
    local wanted = string.lower(name)
    if wanted == "" then return nil end
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(getInfo) == "function" then
        local ok, found, link = pcall(getInfo, name)
        if ok and type(found) == "string" and string.lower(found) == wanted then
            local id = ParseLink(link)
            if id then return id, CleanName(found) end
        end
    end
    local function Try(link)
        local id, linkName = ParseLink(link)
        if id and linkName and string.lower(linkName) == wanted then return id, linkName end
    end
    if ns.ReadBagSlot and ns.LastBag then
        local okLast, last = pcall(ns.LastBag)
        last = okLast and Int(last, 0, 20) or 4
        for bag = 0, last do
            local slots = 0
            local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
            if type(numSlots) == "function" then
                local okSlots, value = pcall(numSlots, bag)
                slots = okSlots and Int(value, 0, 64) or 0
            end
            for slot = 1, slots do
                local okSlot, item = pcall(ns.ReadBagSlot, bag, slot)
                if okSlot then
                    local id, found = Try(item)
                    if id then return id, found end
                end
            end
        end
    end
    local history = FarolCharDB and FarolCharDB.items
    if type(history) == "table" then
        for i = #history, 1, -1 do
            local entry = history[i]
            if type(entry) == "table" then
                local id, found = Try(entry.link)
                if id then return id, found end
            end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Progresso, sessão e estimativa
---------------------------------------------------------------------------

local session = {} -- [id] = { start = contagem, t = GetTime() } (só na memória)

local function Duration(seconds)
    seconds = math.floor(seconds)
    if seconds >= 86400 then
        return string.format("%dd %dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
    end
    return ns.FormatDuration and ns.FormatDuration(seconds) or tostring(seconds)
end

-- Situação de uma meta: { id, name, have, target, done, pct, gained, rate, eta }
local function Status(entry)
    local status = { id = entry.id, name = LiveName(entry.id) or entry.n, target = entry.c, entry = entry }
    local have = Count(entry.id)
    if not have then return status end
    status.have = have
    status.done = have >= entry.c
    status.pct = math.min(100, math.floor(have / entry.c * 100))
    local now = Now()
    local base = session[entry.id]
    if now and (not base or have < base.start) then -- primeira leitura ou o jogador usou/vendeu: recomeça
        base = { start = have, t = now }
        session[entry.id] = base
    end
    if base and now then
        local gained, seconds = have - base.start, now - base.t
        status.gained = gained
        if gained > 0 and seconds >= RATE_MIN_SECONDS then
            status.rate = gained / seconds * 3600
            if not status.done then status.eta = (entry.c - have) / status.rate * 3600 end
        end
    end
    return status
end

function Farm.Statuses()
    local list = {}
    for i, entry in ipairs(List()) do list[i] = Status(entry) end
    return list
end

local function Short(name)
    local short = CleanName(name, NAME_SHORT)
    if short ~= CleanName(name) then short = short .. ".." end
    return short
end

local function Color(status)
    if status.done then return ns.C.good end
    if status.pct and status.pct < 25 then return ns.C.bad end
    return ns.C.warn
end

local function Progress(status)
    if not status.have then return "--/" .. status.target end
    return Color(status) .. status.have .. "/" .. status.target .. "|r"
end

function Farm.BarText()
    local list = Farm.Statuses()
    if #list == 0 then return T("label_farm") .. " " .. ns.C.dim .. "--|r" end
    if #list == 1 then return Short(list[1].name) .. " " .. Progress(list[1]) end
    local done = 0
    for _, status in ipairs(list) do if status.done then done = done + 1 end end
    local color = done >= #list and ns.C.good or ns.C.warn
    return string.format("%s %s%d/%d|r", T("label_farm"), color, done, #list)
end

local function Pace(rate)
    if rate >= 100 then return tostring(math.floor(rate + 0.5)) end
    return string.format("%.0f", rate)
end

function Farm.Tooltip()
    local list = Farm.Statuses()
    GameTooltip:AddLine(T("tt_farm"), 1, 0.82, 0)
    if #list == 0 then
        GameTooltip:AddLine("   " .. T("tt_farm_none"), 0.7, 0.7, 0.7)
        return
    end
    for _, status in ipairs(list) do
        GameTooltip:AddDoubleLine("   " .. status.name, Progress(status), 0.9, 0.9, 0.9, 1, 1, 1)
        if not status.done and status.have then
            local line
            if status.rate and status.eta then
                line = string.format(T("tt_farm_session"), status.gained, Pace(status.rate), Duration(status.eta))
            elseif status.rate then
                line = string.format(T("tt_farm_session_only"), status.gained, Pace(status.rate))
            else
                line = T("tt_farm_norate")
            end
            GameTooltip:AddLine("      " .. line, 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:AddLine("   " .. T("tt_farm_bank"), 0.5, 0.5, 0.5)
end

-- Para o aviso de metas: itens que chegaram à meta e ainda não foram avisados (marca como avisados).
function Farm.NewlyReached()
    local list = {}
    for _, status in ipairs(Farm.Statuses()) do
        if status.done and not status.entry.w then
            status.entry.w = true
            list[#list + 1] = string.format(T("farm_reached"), status.name, status.have, status.target)
        end
    end
    return list
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local function Changed()
    if ns.UpdateText then ns.UpdateText() end
    if ns.Goals and ns.Goals.Refresh then ns.Goals.Refresh() end
end

local function IndexOf(id)
    for i, entry in ipairs(List()) do if entry.id == id then return i end end
    return nil
end

-- Cria ou muda a meta de um item. keep = só cria (não muda uma meta que já existe).
function Farm.Set(id, name, target, keep)
    if not Int(id, 1, MAX_ID) then Print(T("farm_not_found")) return false end
    if not Int(target, 1, MAX_TARGET) then Print(T("farm_bad_target")) return false end
    local list = List()
    local index = IndexOf(id)
    if index then
        local entry = list[index]
        if not keep then
            entry.c, entry.w = target, nil
            Print(string.format(T("farm_changed"), LiveName(id) or entry.n, target))
        else
            local status = Status(entry)
            Print(string.format(T("farm_added"), status.name, status.have or 0, entry.c))
        end
        Changed()
        return true
    end
    if #list >= MAX_ITEMS then Print(string.format(T("farm_full"), MAX_ITEMS)) return false end
    name = CleanName(LiveName(id) or name or "")
    if name == "" then name = "#" .. id end
    local entry = { id = id, n = name, c = target }
    list[#list + 1] = entry
    session[id] = nil
    local status = Status(entry)
    Print(string.format(T("farm_added"), name, status.have or 0, target))
    Changed()
    return true
end

-- Botão "+ Meta" da janela de saques.
function Farm.TrackLink(link)
    local id, name = ParseLink(link)
    if not id then Print(T("farm_not_found")) return false end
    return Farm.Set(id, name, DEFAULT_TARGET, true)
end
Farm.DEFAULT_TARGET = DEFAULT_TARGET

local function Find(text)
    local list = List()
    local number = tonumber(text)
    if number and list[number] then return number end
    local id = ParseLink(text)
    if id then return IndexOf(id) end
    local wanted = string.lower(CleanName(text))
    if wanted == "" then return nil end
    for i, entry in ipairs(list) do
        if string.lower(entry.n) == wanted or string.lower(LiveName(entry.id) or "") == wanted then return i end
    end
    return nil
end

function Farm.Remove(index)
    local list = List()
    local entry = list[index]
    if not entry then Print(T("farm_missing")) return false end
    table.remove(list, index)
    session[entry.id] = nil
    -- Só na sessão: "Desfazer" devolve a meta ao mesmo lugar (cópia, nunca a mesma tabela).
    Farm.lastRemoved = { index = index, entry = { id = entry.id, n = entry.n, c = entry.c, w = entry.w } }
    Print(string.format(T("farm_removed"), LiveName(entry.id) or entry.n))
    Changed()
    return true
end

function Farm.Undo()
    local undo = Farm.lastRemoved
    if not undo then Print(T("farm_nothing_undo")) return false end
    local list = List()
    if #list >= MAX_ITEMS then Print(string.format(T("farm_full"), MAX_ITEMS)) return false end
    Farm.lastRemoved = nil
    local entry = undo.entry
    if not IndexOf(entry.id) then
        local index = tonumber(undo.index)
        if not index or index ~= index or index < 1 or index > #list + 1 then index = #list + 1 end -- NaN/fora da lista: no fim
        index = math.floor(index)
        table.insert(list, index, { id = entry.id, n = entry.n, c = entry.c, w = entry.w })
    end
    Print(string.format(T("farm_restored"), LiveName(entry.id) or entry.n))
    Changed()
    return true
end

function Farm.Clear()
    if FarolCharDB then FarolCharDB.farm = {} end
    session = {}
    Farm.lastRemoved = nil
    Print(T("farm_cleared"))
    Changed()
end

local function PrintList()
    local list = Farm.Statuses()
    if #list == 0 then Print(T("farm_none")) return end
    Print(T("farm_list"))
    for i, status in ipairs(list) do
        Print(string.format("  %d. %s %s", i, status.name, Progress(status)))
    end
end

---------------------------------------------------------------------------
-- Comandos: /farol meta item ... (e /farol farm ...)
---------------------------------------------------------------------------

local REMOVE = { remover = true, remove = true, apagar = true, tirar = true, delete = true }
local CLEAR = { limpar = true, clear = true }
local UNDO = { desfazer = true, undo = true, voltar = true }

function Farm.HandleCommand(rest)
    rest = string.match(rest or "", "^%s*(.-)%s*$") or ""
    if #rest > 500 then Print(T("farm_usage")) return end
    local word, tail = string.match(rest, "^(%a*)%s*(.-)$")
    word = string.lower(word or "")
    if rest == "" then
        PrintList()
        Print(T("farm_usage"))
    elseif CLEAR[word] and tail == "" then
        Farm.Clear()
    elseif UNDO[word] and tail == "" then
        Farm.Undo()
    elseif REMOVE[word] and tail ~= "" then
        local index = Find(tail)
        if index then Farm.Remove(index) else Print(T("farm_missing")) end
    else
        local spec, amount = string.match(rest, "^(.-)%s+(%d+)$")
        if not spec or spec == "" then Print(T("farm_usage")) return end
        local target = tonumber(amount)
        if not Int(target, 1, MAX_TARGET) then Print(T("farm_bad_target")) return end
        local id, name = ParseLink(spec)
        if not id then id, name = FindByName(spec) end
        if not id then Print(T("farm_not_found")) return end
        Farm.Set(id, name, target)
    end
end

---------------------------------------------------------------------------
-- Linhas na janela de Metas (Goals.lua chama Attach/Refresh)
---------------------------------------------------------------------------

local ROW_H = 24

function Farm.Attach(frame, top)
    frame.farmHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.farmHeader:SetPoint("TOPLEFT", 24, top)
    -- "Desfazer" ao lado do título, só depois de apagar uma meta.
    frame.farmUndo = CreateFrame("Button", "FarolFarmUndo", frame, "UIPanelButtonTemplate")
    frame.farmUndo:SetSize(92, 20)
    frame.farmUndo:SetPoint("TOPLEFT", 314, top + 3)
    frame.farmUndo:SetScript("OnClick", function() Farm.Undo() end)
    frame.farmRows = {}
    for i = 1, MAX_ITEMS do
        local y = top - 22 - (i - 1) * ROW_H
        local row = {}
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("TOPLEFT", 30, y - 4)
        row.text:SetWidth(200)
        row.text:SetJustifyH("LEFT")
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        row.box = CreateFrame("EditBox", "FarolFarmTarget" .. i, frame, "InputBoxTemplate")
        row.box:SetSize(62, 20)
        row.box:SetPoint("TOPLEFT", 244, y)
        row.box:SetAutoFocus(false)
        row.box:SetNumeric(true)
        row.box:SetMaxLetters(6)
        local function apply()
            local entry = List()[i]
            if entry and Farm.Set(entry.id, entry.n, tonumber(row.box:GetText())) then row.box:ClearFocus() end
        end
        row.box:SetScript("OnEnterPressed", apply)
        row.box.farolApply = function()
            local entry = List()[i]
            if entry then Farm.Set(entry.id, entry.n, tonumber(row.box:GetText())) end
        end
        row.box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        row.set = CreateFrame("Button", "FarolFarmSet" .. i, frame, "UIPanelButtonTemplate")
        row.set:SetSize(64, 20)
        row.set:SetPoint("TOPLEFT", 314, y)
        row.set:SetScript("OnClick", apply)
        row.remove = CreateFrame("Button", "FarolFarmRemove" .. i, frame, "UIPanelButtonTemplate")
        row.remove:SetSize(24, 20)
        row.remove:SetPoint("LEFT", row.set, "RIGHT", 4, 0)
        row.remove:SetText("X")
        row.remove:SetScript("OnClick", function() if List()[i] then Farm.Remove(i) end end)
        row.remove:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(T("farm_remove_tip"), 1, 1, 1)
            GameTooltip:Show()
        end)
        row.remove:SetScript("OnLeave", function() GameTooltip:Hide() end)
        frame.farmRows[i] = row
    end
end

-- Atualiza as linhas; devolve quantas estão em uso (para a janela ajustar a altura).
function Farm.RefreshRows(frame)
    if not frame or not frame.farmRows then return 0 end
    local undo = Farm.lastRemoved
    local note = undo and (ns.C.dim .. string.format(T("farm_undo_line"), Short(undo.entry.n)) .. "|r")
        or (#List() == 0 and (ns.C.dim .. T("farm_none") .. "|r") or "")
    frame.farmHeader:SetText(T("farm_header") .. " " .. note)
    if frame.farmUndo then
        frame.farmUndo:SetText(T("farm_undo"))
        if undo then frame.farmUndo:Show() else frame.farmUndo:Hide() end
    end
    local list = Farm.Statuses()
    for i, row in ipairs(frame.farmRows) do
        local status = list[i]
        local widgets = { row.text, row.box, row.set, row.remove }
        if status then
            row.text:SetText(Short(status.name) .. " " .. Progress(status))
            row.set:SetText(ns.T("goal_set"))
            if not row.box:HasFocus() then row.box:SetText(tostring(status.target)) end
            for _, widget in ipairs(widgets) do widget:Show() end
        else
            for _, widget in ipairs(widgets) do widget:Hide() end
        end
    end
    return #list
end
Farm.ROW_H = ROW_H
