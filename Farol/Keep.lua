--[[
  Farol — Itens guardados / Items kept for later (3.26)

  Uma lista da CONTA de itens que o jogador quer guardar (ex.: material de uma receita que só aprende mais tarde),
  com o motivo e QUANDO o item vira útil: sem prazo, num nível do personagem ou num nível de profissão.
  O Farol só lembra: nunca vende, move, trava ou usa itens (o test_toc.lua proíbe essas funções).

  FarolDB.keep = { { id, n = nome (≤ 40 letras), r = motivo (≤ 40), k = "l" (nível) | "p" (profissão) | nil,
                     v = nível alvo, p = nome da profissão (≤ 40) }, ... } (máx. 50, sem id repetido; Keep.Sanitize)
  FarolCharDB.keepSeen = { [id] = true } (personagem: "já avisei que ficou pronto"; Keep.SanitizeSeen)
  FarolCharDB.keepBank = { t = quando, l = { {id, n ≤ 40, c, q}, ... } } (personagem: o que estava no banco na última
  vez que ele foi aberto — o jogo só mostra o banco aberto; máx. 1000; Keep.SanitizeBank). Só para a lista de escolha.
  Opções (Core DEFAULTS, desligadas — regra 8): keepMerchant (lembrar no comerciante), keepReady (avisar na hora
  certa) e keepTooltip (linha no tooltip do item).
  Nada é enviado e não há pedido ao servidor.
]]

local _, ns = ...

local MAX_ITEMS = 50
local MAX_BANK = 1000
local PICK_ROWS = 8
local MAX_TEXT = 40
local MAX_ID = 10000000
local MAX_LEVEL = 100
local MAX_SKILL = 1000
local ROWS = 10
local ROW_H = 24
local MERCHANT_LIST = 5

local Keep = {}
ns.Keep = Keep
-- "✓" não existe na fonte do jogo: usa a textura de "pronto" do próprio jogo.
Keep.CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14|t "

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_keep     = "Itens guardados",
        desc_keep     = "Itens que você guarda para depois (ex.: uma receita que só aprende mais tarde): quantos são e quantos já podem ser usados (abra com /farol guardar).",
        label_keep    = "Guardados",
        tt_keep       = "Itens guardados",
        tt_keep_click = "Abrir: /farol guardar ou Menu > Ferramentas",
        gear_keep     = "Abre a janela de itens guardados.",
        tool_keep     = "Guardados...",
        tool_keep_desc = "itens para depois, com motivo e lembrete",
        keep_title    = "Itens guardados",
        keep_title_n  = "Itens guardados (%d)",
        keep_ph_item  = "Nome do item (ou /farol guardar + Shift + clique no item)",
        keep_ph_reason = "Motivo (opcional): receita de Alquimia...",
        keep_when_none = "Quando: sem prazo",
        keep_when_level = "Quando: nível",
        keep_when_prof = "Quando: %s",
        keep_add      = "+ Guardar",
        keep_col_item = "Item",
        keep_col_have = "Tenho",
        keep_col_why  = "Para quê / quando",
        keep_bank     = "(%d banco)",
        keep_no_when  = "sem prazo",
        keep_level_left = "nível %d — faltam %d",
        keep_level_ok = "nível %d — já pode",
        keep_prof_left = "%s %d — faltam %d",
        keep_prof_ok  = "%s %d — já pode",
        keep_prof_none = "%s %d — você não tem",
        keep_empty    = "Nenhum item guardado. Escreva o nome acima (ou use /farol guardar e Shift + clique no item) e clique em Guardar.",
        keep_note     = "Itens guardados não entram no \"Lixo nas bolsas\". O Farol nunca vende, move nem trava itens.",
        keep_opt_merchant = "Lembrar ao abrir um comerciante (os guardados que estão nas bolsas)",
        keep_opt_ready = "Avisar quando chegar a hora (uma vez por personagem)",
        keep_opt_tooltip = "Mostrar \"guardado\" no tooltip do item",
        keep_scroll   = "%d–%d de %d (role com o mouse)",
        keep_undo     = "Desfazer",
        keep_undo_line = "Tirado da lista: %s",
        keep_added    = "guardado: %s.",
        keep_updated  = "atualizado: %s.",
        keep_removed  = "tirado da lista: %s (Desfazer na janela ou /farol guardar desfazer).",
        keep_restored = "de volta à lista: %s.",
        keep_nothing_undo = "nada para desfazer.",
        keep_full     = "a lista já tem 50 itens: tire algum antes.",
        keep_pick_all = "%d itens nas bolsas e no banco (rode o mouse para ver mais)",
        keep_pick_all_1 = "%d item nas bolsas e no banco",
        keep_pick_filter = "%d itens com \"%s\" (rode o mouse para ver mais)",
        keep_pick_filter_1 = "%d item com \"%s\"",
        keep_pick_none = "nenhum item com esse nome nas bolsas nem no banco anotado",
        keep_pick_bank = "banco anotado: %s",
        keep_pick_nobank = "abra o banco uma vez para os itens dele aparecerem aqui",
        keep_where_bags = "bolsas",
        keep_where_bank = "banco",
        keep_where_both = "bolsas + banco",
        keep_where_kept = "guardado",
        keep_form_title = "Guardar um item",
        keep_form_sub = "clique na caixa para escolher das bolsas e do banco",
        keep_opts_title = "Lembretes",
        keep_opts_sub = "só no seu chat; nada é enviado",
        keep_already  = "já está guardado: %s.",
        loot_keep     = "Guardar",
        loot_keep_tip = "Guardar este item para depois (Itens guardados: /farol guardar)",
        keep_not_found = "item não encontrado: use /farol guardar e Shift + clique no item (ou o item precisa estar nas bolsas ou nos saques).",
        keep_missing  = "esse item não está na lista.",
        keep_bad_value = "escreva o nível de 1 a %d.",
        keep_merchant = "guardados nas bolsas: %s",
        keep_more     = "e mais %d",
        keep_ready_level = "você chegou ao nível %d: já pode usar %s",
        keep_ready_prof = "%s chegou a %d: já pode usar %s",
        keep_in_bank  = "%d estão no banco.",
        keep_tip_line = "Farol: guardado",
        keep_tip_level = "nível %d",
        keep_list     = "Farol — itens guardados (%d):",
        keep_line     = "  %d. %s ×%d — %s",
        keep_opt_on   = "%s: ligado.",
        keep_opt_off  = "%s: desligado.",
        keep_usage    = "uso: /farol guardar || /farol guardar [item] || /farol guardar [item]: motivo || /farol guardar lista || /farol guardar tirar N || /farol guardar desfazer || /farol guardar comerciante||hora||tooltip on||off",
        help_keep     = "  /farol guardar       - itens guardados para depois (motivo, quando ficam úteis, lembretes)",
        news_keep     = "itens guardados: marque itens para depois (ex.: receita que só aprende mais tarde), com motivo, lembrete no comerciante e na hora certa (/farol guardar; lembretes e item da barra vêm desligados)",
    },
    en = {
        name_keep     = "Kept items",
        desc_keep     = "Items you keep for later (e.g. a recipe you only learn later): how many and how many you can already use (open with /farol keep).",
        label_keep    = "Kept",
        tt_keep       = "Kept items",
        tt_keep_click = "Open: /farol keep or Menu > Tools",
        gear_keep     = "Opens the kept items window.",
        tool_keep     = "Kept items...",
        tool_keep_desc = "items for later, with a reason and a reminder",
        keep_title    = "Kept items",
        keep_title_n  = "Kept items (%d)",
        keep_ph_item  = "Item name (or /farol keep + Shift-click the item)",
        keep_ph_reason = "Reason (optional): Alchemy recipe...",
        keep_when_none = "When: no deadline",
        keep_when_level = "When: level",
        keep_when_prof = "When: %s",
        keep_add      = "+ Keep",
        keep_col_item = "Item",
        keep_col_have = "Have",
        keep_col_why  = "What for / when",
        keep_bank     = "(%d bank)",
        keep_no_when  = "no deadline",
        keep_level_left = "level %d — %d to go",
        keep_level_ok = "level %d — ready",
        keep_prof_left = "%s %d — %d to go",
        keep_prof_ok  = "%s %d — ready",
        keep_prof_none = "%s %d — you don't have it",
        keep_empty    = "No kept items. Type the name above (or use /farol keep and Shift-click the item) and click Keep.",
        keep_note     = "Kept items are left out of \"Junk in bags\". Farol never sells, moves or locks items.",
        keep_opt_merchant = "Remind me when I open a merchant (kept items in my bags)",
        keep_opt_ready = "Tell me when the time comes (once per character)",
        keep_opt_tooltip = "Show \"kept\" in the item tooltip",
        keep_scroll   = "%d–%d of %d (scroll with the mouse)",
        keep_undo     = "Undo",
        keep_undo_line = "Removed from the list: %s",
        keep_added    = "kept: %s.",
        keep_updated  = "updated: %s.",
        keep_removed  = "removed from the list: %s (Undo in the window or /farol keep undo).",
        keep_restored = "back on the list: %s.",
        keep_nothing_undo = "nothing to undo.",
        keep_full     = "the list already has 50 items: remove one first.",
        keep_pick_all = "%d items in your bags and bank (scroll for more)",
        keep_pick_all_1 = "%d item in your bags and bank",
        keep_pick_filter = "%d items with \"%s\" (scroll for more)",
        keep_pick_filter_1 = "%d item with \"%s\"",
        keep_pick_none = "no item with that name in your bags or the noted bank",
        keep_pick_bank = "bank noted: %s",
        keep_pick_nobank = "open your bank once to see its items here",
        keep_where_bags = "bags",
        keep_where_bank = "bank",
        keep_where_both = "bags + bank",
        keep_where_kept = "kept",
        keep_form_title = "Keep an item",
        keep_form_sub = "click the box to pick from your bags and bank",
        keep_opts_title = "Reminders",
        keep_opts_sub = "only in your chat; nothing is sent",
        keep_already  = "already kept: %s.",
        loot_keep     = "Keep",
        loot_keep_tip = "Keep this item for later (Kept items: /farol keep)",
        keep_not_found = "item not found: use /farol keep and Shift-click the item (or the item must be in your bags or loot).",
        keep_missing  = "that item is not on the list.",
        keep_bad_value = "type a level from 1 to %d.",
        keep_merchant = "kept items in your bags: %s",
        keep_more     = "and %d more",
        keep_ready_level = "you reached level %d: you can now use %s",
        keep_ready_prof = "%s reached %d: you can now use %s",
        keep_in_bank  = "%d are in the bank.",
        keep_tip_line = "Farol: kept",
        keep_tip_level = "level %d",
        keep_list     = "Farol — kept items (%d):",
        keep_line     = "  %d. %s ×%d — %s",
        keep_opt_on   = "%s: on.",
        keep_opt_off  = "%s: off.",
        keep_usage    = "usage: /farol keep || /farol keep [item] || /farol keep [item]: reason || /farol keep list || /farol keep remove N || /farol keep undo || /farol keep merchant||ready||tooltip on||off",
        help_keep     = "  /farol keep          - items kept for later (reason, when they become useful, reminders)",
        news_keep     = "kept items: mark items for later (e.g. a recipe you learn later), with a reason and reminders at the merchant and when the time comes (/farol keep; reminders and bar item start off)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do ns.STRINGS[lang][key] = value end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end
local function DB() return ns.GetDB and ns.GetDB() end

---------------------------------------------------------------------------
-- Validação
---------------------------------------------------------------------------

local function Int(value, low, high)
    if type(value) ~= "number" or value ~= value or value ~= math.floor(value) or value < low or value > high then return nil end
    if ns.IsSecret and ns.IsSecret(value) then return nil end
    return value
end

-- Texto limpo: sem "|" nem controle, até "limit" letras (UTF-8 inteiro). Mesmo cuidado das metas de farm.
local function Clean(text, limit)
    if ns.Farm and ns.Farm.CleanName then return ns.Farm.CleanName(text, limit or MAX_TEXT) end
    return ""
end
Keep.Clean = Clean

local function CleanEntry(entry)
    if type(entry) ~= "table" then return nil end
    local id = Int(entry.id, 1, MAX_ID)
    local name = Clean(entry.n)
    if not id or name == "" then return nil end
    local clean = { id = id, n = name }
    local reason = Clean(entry.r)
    if reason ~= "" then clean.r = reason end
    if entry.k == "l" and Int(entry.v, 1, MAX_LEVEL) then
        clean.k, clean.v = "l", entry.v
    elseif entry.k == "p" and Int(entry.v, 1, MAX_SKILL) then
        local prof = Clean(entry.p)
        if prof ~= "" then clean.k, clean.v, clean.p = "p", entry.v, prof end
    end
    return clean
end

function Keep.Sanitize(saved)
    local clean, seen = {}, {}
    if type(saved) ~= "table" then return clean end
    for i = 1, MAX_ITEMS do -- só as primeiras posições (arquivo adulterado com milhares de itens carrega rápido)
        local entry = CleanEntry(saved[i])
        if entry == nil and saved[i] == nil then break end
        if entry and not seen[entry.id] then
            seen[entry.id] = true
            clean[#clean + 1] = entry
        end
    end
    return clean
end

function Keep.SanitizeSeen(saved)
    local clean, count = {}, 0
    if type(saved) ~= "table" then return clean end
    for id, value in pairs(saved) do
        if value == true and Int(id, 1, MAX_ID) then
            count = count + 1
            if count > 200 then break end
            clean[id] = true
        end
    end
    return clean
end

local function List()
    local db = DB()
    if not db then return {} end
    if type(db.keep) ~= "table" then db.keep = {} end
    return db.keep
end

local function Seen()
    if type(FarolCharDB) ~= "table" then return {} end
    if type(FarolCharDB.keepSeen) ~= "table" then FarolCharDB.keepSeen = {} end
    return FarolCharDB.keepSeen
end

local function IndexOf(id)
    for i, entry in ipairs(List()) do if entry.id == id then return i end end
    return nil
end

function Keep.Has(id)
    id = tonumber(id)
    if not id then return false end
    return IndexOf(id) ~= nil
end

function Keep.Entry(id)
    local i = IndexOf(tonumber(id) or -1)
    return i and List()[i] or nil
end

---------------------------------------------------------------------------
-- Leituras do jogo (protegidas: erro, valor bloqueado ou absurdo = nil)
---------------------------------------------------------------------------

local function CountOf(id, bank)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    if type(getCount) ~= "function" then return nil end
    local ok, n = pcall(getCount, id, bank and true or false)
    if not ok then return nil end
    n = Int(type(n) == "number" and math.floor(n) or nil, 0, 1000000)
    return n
end

-- Total (bolsas + banco quando o jogo informa) e só nas bolsas.
function Keep.Counts(id)
    local bags = CountOf(id, false) or 0
    local total = CountOf(id, true) or bags
    if total < bags then total = bags end
    return total, bags
end

local function PlayerLevel()
    if not UnitLevel then return nil end
    local ok, level = pcall(UnitLevel, "player")
    return ok and Int(level, 1, MAX_LEVEL) or nil
end

local function ProfLevel(name)
    if not (ns.ReadProfessions and name) then return nil end
    local ok, list = pcall(ns.ReadProfessions)
    if not ok or type(list) ~= "table" then return nil end
    local wanted = string.lower(name)
    for _, prof in ipairs(list) do
        if type(prof) == "table" and type(prof.name) == "string" and string.lower(prof.name) == wanted then
            return Int(prof.level, 0, MAX_SKILL)
        end
    end
    return nil
end

-- Profissões que o personagem tem agora (para o menu "Quando").
function Keep.Professions()
    local names = {}
    if not ns.ReadProfessions then return names end
    local ok, list = pcall(ns.ReadProfessions)
    if not ok or type(list) ~= "table" then return names end
    for _, prof in ipairs(list) do
        if type(prof) == "table" and type(prof.name) == "string" then
            local name = Clean(prof.name)
            if name ~= "" then names[#names + 1] = name end
        end
    end
    return names
end

-- Estado de um item: pronto? texto do "quando" (cor da paleta: atenção = falta, bom = pronto).
-- levelNow permite usar o nível que chega no PLAYER_LEVEL_UP (o UnitLevel pode ainda estar com o antigo).
function Keep.Status(entry, levelNow)
    if entry.k == "l" then
        local level = levelNow or PlayerLevel()
        if level and level >= entry.v then return true, ns.C.good .. string.format(T("keep_level_ok"), entry.v) .. "|r" end
        local left = level and (entry.v - level) or entry.v
        return false, ns.C.warn .. string.format(T("keep_level_left"), entry.v, left) .. "|r"
    elseif entry.k == "p" then
        local level = ProfLevel(entry.p)
        if level == nil then return false, ns.C.dim .. string.format(T("keep_prof_none"), entry.p, entry.v) .. "|r" end
        if level >= entry.v then return true, ns.C.good .. string.format(T("keep_prof_ok"), entry.p, entry.v) .. "|r" end
        return false, ns.C.warn .. string.format(T("keep_prof_left"), entry.p, entry.v, entry.v - level) .. "|r"
    end
    return false, ns.C.dim .. T("keep_no_when") .. "|r"
end

local function Why(entry, levelNow)
    local _, when = Keep.Status(entry, levelNow)
    return entry.r and (entry.r .. " · " .. when) or when
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo

local function Changed()
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
end

-- Guarda (ou atualiza, se o item já está na lista). when = { k = "l"|"p"|nil, v, p }.
function Keep.Set(id, name, reason, when)
    id = Int(tonumber(id), 1, MAX_ID)
    name = Clean(name)
    if not id then Print(T("keep_not_found")) return false end
    if name == "" then name = "#" .. id end
    when = when or {}
    local entry = CleanEntry({ id = id, n = name, r = reason, k = when.k, v = when.v, p = when.p })
    if not entry then Print(T("keep_not_found")) return false end
    local list, index = List(), IndexOf(id)
    if index then
        list[index] = entry
        Print(string.format(T("keep_updated"), entry.n))
    else
        if #list >= MAX_ITEMS then Print(T("keep_full")) return false end
        list[#list + 1] = entry
        Print(string.format(T("keep_added"), entry.n))
    end
    -- Já pronto ao guardar: não avisa depois ("já pode" aparece na janela). Senão, o aviso volta a valer.
    Seen()[id] = Keep.Status(entry) and true or nil
    Changed()
    return true
end

function Keep.Remove(index)
    local list = List()
    local entry = list[index]
    if not entry then Print(T("keep_missing")) return false end
    table.remove(list, index)
    local copy = {}
    for k, v in pairs(entry) do copy[k] = v end
    Keep.lastRemoved = { index = index, entry = copy }
    Print(string.format(T("keep_removed"), entry.n))
    Changed()
    return true
end

function Keep.Undo()
    local undo = Keep.lastRemoved
    if not undo then Print(T("keep_nothing_undo")) return false end
    local list = List()
    if #list >= MAX_ITEMS then Print(T("keep_full")) return false end
    if IndexOf(undo.entry.id) then Keep.lastRemoved = nil Changed() return false end
    local index = Int(undo.index, 1, #list + 1) or (#list + 1)
    table.insert(list, index, CleanEntry(undo.entry))
    Keep.lastRemoved = nil
    Print(string.format(T("keep_restored"), undo.entry.n))
    Changed()
    return true
end

-- Item de um texto: link (Shift + clique) ou nome (jogo, bolsas, histórico de saques — a mesma busca das metas).
function Keep.Resolve(text)
    if type(text) ~= "string" or #text > 400 then return nil end
    local farm = ns.Farm
    if not farm then return nil end
    local id, name = farm.ParseLink(text)
    if id then return id, name end
    -- Já na lista (ex.: clicou na linha para mudar o motivo): pelo nome guardado.
    local wanted = string.lower(Clean(text))
    for _, entry in ipairs(List()) do
        if wanted ~= "" and string.lower(entry.n) == wanted then return entry.id, entry.n end
    end
    if farm.FindByName then return farm.FindByName(text) end
    return nil
end

local function FindIndex(text)
    local list = List()
    local number = tonumber(text)
    if number and list[number] then return number end
    local id = Keep.Resolve(text)
    if id then return IndexOf(id) end
    local wanted = string.lower(Clean(text))
    for i, entry in ipairs(list) do
        if wanted ~= "" and string.lower(entry.n) == wanted then return i end
    end
    return nil
end

---------------------------------------------------------------------------
-- Barra e tooltip
---------------------------------------------------------------------------

function Keep.ReadyCount()
    local ready = 0
    for _, entry in ipairs(List()) do
        if Keep.Status(entry) then ready = ready + 1 end
    end
    return ready
end

function Keep.BarText()
    local list = List()
    local text = T("label_keep") .. " " .. #list
    local ready = #list > 0 and Keep.ReadyCount() or 0
    if ready > 0 then text = text .. " · " .. ns.C.good .. ready .. "|r" end
    return text
end

function Keep.Tooltip()
    local list = List()
    GameTooltip:AddDoubleLine(T("tt_keep"), tostring(#list), 1, 0.82, 0, 1, 1, 1)
    for i, entry in ipairs(list) do
        if i > 5 then
            GameTooltip:AddLine("   " .. string.format(T("tt_more"), #list - 5), 0.6, 0.6, 0.6)
            break
        end
        local total = Keep.Counts(entry.id)
        GameTooltip:AddLine("   " .. entry.n .. " ×" .. total .. " — " .. Why(entry), 0.9, 0.9, 0.9, true)
    end
    GameTooltip:AddLine(T("tt_keep_click"), 0.6, 0.6, 0.6)
end

---------------------------------------------------------------------------
-- Lembretes (só no chat do jogador; desligados por padrão)
---------------------------------------------------------------------------

function Keep.OnMerchant()
    local db = DB()
    if not (db and db.keepMerchant) then return end
    local parts, more = {}, 0
    for _, entry in ipairs(List()) do
        local _, bags = Keep.Counts(entry.id)
        if bags > 0 then
            if #parts < MERCHANT_LIST then
                parts[#parts + 1] = entry.n .. " ×" .. bags .. (entry.r and (" (" .. entry.r .. ")") or "")
            else
                more = more + 1
            end
        end
    end
    if #parts == 0 then return end
    local text = table.concat(parts, ", ")
    if more > 0 then text = text .. ", " .. string.format(T("keep_more"), more) end
    Print(ns.C.warn .. string.format(T("keep_merchant"), text) .. "|r")
end

-- Avisa uma vez por personagem quando um item fica pronto (nível ou profissão).
function Keep.CheckReady(levelNow)
    local db = DB()
    if not (db and db.keepReady) then return end
    local seen = Seen()
    for _, entry in ipairs(List()) do
        if entry.k and not seen[entry.id] and Keep.Status(entry, levelNow) then
            seen[entry.id] = true
            local total, bags = Keep.Counts(entry.id)
            local item = entry.n .. " ×" .. total .. (entry.r and (" (" .. entry.r .. ")") or "")
            local text = entry.k == "l" and string.format(T("keep_ready_level"), entry.v, item)
                or string.format(T("keep_ready_prof"), entry.p, entry.v, item)
            if total > bags then text = text .. ". " .. string.format(T("keep_in_bank"), total - bags) end
            Print(ns.C.good .. text .. "|r")
        end
    end
end

---------------------------------------------------------------------------
-- Linha no tooltip do item (opcional, desligada). Registrada só quando o jogador liga; cada chamada é protegida
-- (pcall) e só ACRESCENTA uma linha ao tooltip do jogo — nunca muda nada além disso.
---------------------------------------------------------------------------

local tooltipHooked = false

local function ItemIdFromTooltip(tooltip, data)
    if type(data) == "table" then
        local id = Int(data.id, 1, MAX_ID)
        if id then return id end
    end
    if tooltip and tooltip.GetItem then
        local ok, _, link = pcall(tooltip.GetItem, tooltip)
        if ok and type(link) == "string" and ns.Farm then return (ns.Farm.ParseLink(link)) end
    end
    return nil
end

function Keep.AddTooltipLine(tooltip, data)
    local db = DB()
    if not (db and db.keepTooltip and tooltip and tooltip.AddLine) then return end
    local entry = Keep.Entry(ItemIdFromTooltip(tooltip, data))
    if not entry then return end
    local line = T("keep_tip_line") .. (entry.r and (" — " .. entry.r) or "")
    if entry.k == "l" then line = line .. " (" .. string.format(T("keep_tip_level"), entry.v) .. ")"
    elseif entry.k == "p" then line = line .. " (" .. entry.p .. " " .. entry.v .. ")" end
    tooltip:AddLine(line, 1, 0.84, 0.35, true)
end

function Keep.HookTooltip()
    if tooltipHooked then return true end
    local function Safe(tooltip, data) pcall(Keep.AddTooltipLine, tooltip, data) end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType
        and Enum.TooltipDataType.Item then
        local ok = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip then Safe(tooltip, data) end
        end)
        tooltipHooked = ok
    elseif GameTooltip and GameTooltip.HookScript then
        local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetItem", function(tooltip) Safe(tooltip) end)
        tooltipHooked = ok
    end
    return tooltipHooked
end

---------------------------------------------------------------------------
-- Opções (janela e comando)
---------------------------------------------------------------------------

local OPTIONS = { keepMerchant = "keep_opt_merchant", keepReady = "keep_opt_ready", keepTooltip = "keep_opt_tooltip" }

function Keep.SetOption(key, value)
    local db = DB()
    if not (db and OPTIONS[key]) then return end
    db[key] = value and true or false
    if key == "keepTooltip" and db[key] then Keep.HookTooltip() end
    if key == "keepReady" and db[key] then
        -- Os que já estão prontos agora não geram aviso atrasado: só os que ficarem prontos daqui para frente.
        local seen = Seen()
        for _, entry in ipairs(List()) do if Keep.Status(entry) then seen[entry.id] = true end end
    end
    Print(string.format(T(db[key] and "keep_opt_on" or "keep_opt_off"), T(OPTIONS[key])))
    if RefreshWindow then RefreshWindow() end
end

---------------------------------------------------------------------------
-- O que o personagem tem (lista de escolha): bolsas agora + banco anotado na última vez que foi aberto.
-- Só lê. O jogo só mostra o banco enquanto ele está aberto; o Farol nunca abre o banco nem mexe em itens.
---------------------------------------------------------------------------

function Keep.SanitizeBank(saved)
    local clean = { l = {} }
    if type(saved) ~= "table" then return clean end
    clean.t = Int(saved.t, 0, 4e9)
    local list = type(saved.l) == "table" and saved.l or {}
    local seen = {}
    for i = 1, MAX_BANK do -- só as primeiras posições (arquivo adulterado enorme carrega rápido)
        local item = list[i]
        if item == nil then break end
        if type(item) == "table" then
            local id, name = Int(item.id, 1, MAX_ID), Clean(item.n)
            if id and name ~= "" and not seen[id] then
                seen[id] = true
                clean.l[#clean.l + 1] = { id = id, n = name, c = Int(item.c, 1, 1000000) or 1, q = Int(item.q, 0, 8) }
            end
        end
    end
    return clean
end

local function NumSlots(bag)
    local getSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if type(getSlots) ~= "function" then return 0 end
    local ok, n = pcall(getSlots, bag)
    return ok and Int(n, 0, 200) or 0
end

-- Um espaço de bolsa: número, nome, quantidade e qualidade do item (nil = vazio ou o jogo não respondeu).
local function SlotItem(bag, slot)
    if not ns.ReadBagSlot then return nil end
    local ok, item, count, quality = pcall(ns.ReadBagSlot, bag, slot)
    if not ok or item == nil then return nil end
    local id, name
    if type(item) == "string" and ns.Farm then id, name = ns.Farm.ParseLink(item)
    elseif type(item) == "number" then id = Int(item, 1, MAX_ID) end
    if not id then return nil end
    if not name then
        local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        if type(getInfo) == "function" then
            local okInfo, found, _, infoQuality = pcall(getInfo, id)
            if okInfo and type(found) == "string" then name = Clean(found); quality = quality or infoQuality end
        end
    end
    if not name or name == "" then return nil end
    return id, name, Int(count, 1, 100000) or 1, Int(quality, 0, 8)
end

local function AddTo(map, id, name, count, quality, field)
    local entry = map[id]
    if not entry then
        entry = { id = id, n = name, q = quality, bags = 0, bank = 0 }
        map[id] = entry
    end
    entry[field] = entry[field] + count
    if quality and not entry.q then entry.q = quality end
end

local function ReadBags(map)
    local last = 4
    if ns.LastBag then
        local ok, value = pcall(ns.LastBag)
        last = ok and Int(value, 0, 20) or 4
    end
    for bag = 0, last do
        for slot = 1, NumSlots(bag) do
            local id, name, count, quality = SlotItem(bag, slot)
            if id then AddTo(map, id, name, count, quality, "bags") end
        end
    end
    return last
end

-- Bolsas do banco: o espaço principal (-1) e as bolsas do banco depois das bolsas normais; nos clientes novos,
-- também as abas do banco do personagem (Enum.BagIndex.CharacterBankTab_N), se existirem.
local function BankBags(last)
    local bags, seen = {}, {}
    local function Add(bag) if type(bag) == "number" and not seen[bag] then seen[bag] = true; bags[#bags + 1] = bag end end
    Add(type(BANK_CONTAINER) == "number" and BANK_CONTAINER or -1)
    local extra = Int(NUM_BANKBAGSLOTS, 0, 12) or 7
    for bag = last + 1, last + extra do Add(bag) end
    local index = Enum and Enum.BagIndex
    if type(index) == "table" then
        for n = 1, 8 do Add(index["CharacterBankTab_" .. n]) end
    end
    return bags
end

local bankOpen = false

function Keep.ScanBank()
    if not bankOpen or type(FarolCharDB) ~= "table" then return false end
    local map, slots = {}, 0
    local last = 4
    if ns.LastBag then
        local ok, value = pcall(ns.LastBag)
        last = ok and Int(value, 0, 20) or 4
    end
    for _, bag in ipairs(BankBags(last)) do
        local n = NumSlots(bag)
        slots = slots + n
        for slot = 1, n do
            local id, name, count, quality = SlotItem(bag, slot)
            if id then AddTo(map, id, name, count, quality, "bank") end
        end
    end
    if slots == 0 then return false end -- o jogo não mostrou o banco: não apaga o que já estava anotado
    local list = {}
    for _, entry in pairs(map) do list[#list + 1] = { id = entry.id, n = entry.n, c = entry.bank, q = entry.q } end
    table.sort(list, function(a, b) return a.n < b.n or (a.n == b.n and a.id < b.id) end)
    while #list > MAX_BANK do list[#list] = nil end
    local now = time and time() or 0
    FarolCharDB.keepBank = { t = Int(now, 0, 4e9), l = list }
    return true
end

-- Tudo o que o personagem tem (bolsas + banco anotado), sem repetir, em ordem alfabética.
function Keep.Inventory()
    local map = {}
    ReadBags(map)
    local bank = type(FarolCharDB) == "table" and type(FarolCharDB.keepBank) == "table" and FarolCharDB.keepBank.l
    if type(bank) == "table" then
        for _, item in ipairs(bank) do AddTo(map, item.id, item.n, item.c, item.q, "bank") end
    end
    local list = {}
    for _, entry in pairs(map) do list[#list + 1] = entry end
    table.sort(list, function(a, b)
        local la, lb = string.lower(a.n), string.lower(b.n)
        return la < lb or (la == lb and a.id < b.id)
    end)
    return list
end

-- Botão "Guardar" da janela de saques.
function Keep.KeepLink(link)
    if not ns.Farm then return false end
    local id, name = ns.Farm.ParseLink(link)
    if not id then Print(T("keep_not_found")) return false end
    if Keep.Has(id) then Print(string.format(T("keep_already"), Keep.Entry(id).n)) return false end
    return Keep.Set(id, name)
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window
local offset = 0
local SimpleLayout, DetailLayout -- layouts da janela (definidos abaixo)
local when = { k = nil } -- escolha do menu "Quando" (só na sessão)

local function Button(parent, name, width, onClick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetScript("OnClick", onClick)
    return b
end

local function Box(parent, name, width, letters)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetSize(width, 20)
    box:SetAutoFocus(false)
    box:SetMaxLetters(letters)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function WhenLabel()
    if when.k == "l" then return T("keep_when_level") end
    if when.k == "p" then return string.format(T("keep_when_prof"), when.p) end
    return T("keep_when_none")
end

local function WhenItems()
    local items = {
        { text = T("keep_when_none"), checked = when.k == nil, onClick = function() when = { k = nil }; RefreshWindow() end },
        { text = T("keep_when_level"), checked = when.k == "l", onClick = function() when = { k = "l" }; RefreshWindow() end },
    }
    for _, prof in ipairs(Keep.Professions()) do
        items[#items + 1] = { text = string.format(T("keep_when_prof"), prof), checked = when.k == "p" and when.p == prof,
            onClick = function() when = { k = "p", p = prof }; RefreshWindow() end }
    end
    return items
end

local pickOffset, pickList = 0, {}

local function Quality(q)
    local colors = ITEM_QUALITY_COLORS
    local c = type(colors) == "table" and q and colors[q]
    if type(c) == "table" and type(c.r) == "number" then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function IconOf(id)
    local icon
    if C_Item and C_Item.GetItemIconByID then
        local ok, value = pcall(C_Item.GetItemIconByID, id)
        if ok then icon = value end
    end
    if not icon and GetItemIcon then
        local ok, value = pcall(GetItemIcon, id)
        if ok then icon = value end
    end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end
ns.ItemIcon = IconOf -- também usado pelos cartões de farm (Farm.lua) na Central

local function HidePicker() if window and window.pick then window.pick:Hide() end end

local function RefreshPicker()
    local pick = window and window.pick
    if not pick or not pick:IsShown() then return end
    local filter = string.lower(ns.Trim(window.item:GetText() or "", 200))
    if window.pickedName and window.item:GetText() == window.pickedName then filter = "" end
    pickList = {}
    for _, entry in ipairs(Keep.Inventory()) do
        if filter == "" or string.find(string.lower(entry.n), filter, 1, true) then pickList[#pickList + 1] = entry end
    end
    pickOffset = math.max(0, math.min(pickOffset, #pickList - PICK_ROWS))
    if #pickList == 0 then pick.head:SetText(T("keep_pick_none"))
    elseif filter == "" then pick.head:SetText(string.format(ns.TN("keep_pick_all", #pickList), #pickList))
    else pick.head:SetText(string.format(ns.TN("keep_pick_filter", #pickList), #pickList, filter)) end
    local bank = type(FarolCharDB) == "table" and FarolCharDB.keepBank
    pick.bank:SetText(bank and bank.t and string.format(T("keep_pick_bank"), ns.FormatWhen(bank.t)) or T("keep_pick_nobank"))
    for i, row in ipairs(pick.rows) do
        local entry = pickList[pickOffset + i]
        row.entry = entry
        if entry then
            row.icon:SetTexture(IconOf(entry.id))
            row.name:SetText(entry.n)
            row.name:SetTextColor(Quality(entry.q))
            row.count:SetText("×" .. (entry.bags + entry.bank))
            local where = entry.bags > 0 and entry.bank > 0 and T("keep_where_both")
                or (entry.bank > 0 and T("keep_where_bank") or T("keep_where_bags"))
            if Keep.Has(entry.id) then where = Keep.CHECK .. ns.C.good .. T("keep_where_kept") .. "|r" end
            row.where:SetText(where)
            row:Show()
        else
            row:Hide()
        end
    end
end

local function ShowPicker()
    if not (window and window.pick) then return end
    pickOffset = 0
    window.pick:Show()
    RefreshPicker()
end

local function Choose(entry)
    if not entry then return end
    window.pickedId, window.pickedName = entry.id, entry.n
    window.item:SetText(entry.n)
    local kept = Keep.Entry(entry.id)
    if kept then -- já guardado: traz o motivo e o "quando" para editar
        window.reason:SetText(kept.r or "")
        when = { k = kept.k, p = kept.p }
        window.value:SetText(kept.v and tostring(kept.v) or "")
    end
    HidePicker()
    window.reason:SetFocus()
    RefreshWindow()
end

local function AddFromForm()
    HidePicker()
    local text = window.item:GetText() or ""
    local id, name
    if window.pickedId and text == window.pickedName then id, name = window.pickedId, window.pickedName
    else id, name = Keep.Resolve(text) end
    if not id then Print(T("keep_not_found")) return end
    local spec = { k = when.k, p = when.p }
    if when.k then
        local value = tonumber(window.value:GetText())
        local max = when.k == "l" and MAX_LEVEL or MAX_SKILL
        if not Int(value, 1, max) then Print(string.format(T("keep_bad_value"), max)) return end
        spec.v = value
    end
    if Keep.Set(id, name or Clean(text), window.reason:GetText(), spec) then
        window.pickedId, window.pickedName = nil, nil
        window.item:SetText(""); window.reason:SetText(""); window.value:SetText("")
        window.item:ClearFocus(); window.reason:ClearFocus(); window.value:ClearFocus()
        RefreshWindow()
    end
end

-- Clicar numa linha leva o item para o formulário de cima (para mudar o motivo ou o "quando" e guardar de novo).
local function LoadIntoForm(entry)
    window.item:SetText(entry.n)
    window.reason:SetText(entry.r or "")
    when = { k = entry.k, p = entry.p }
    window.value:SetText(entry.v and tostring(entry.v) or "")
    RefreshWindow()
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolKeep", UIParent, ns.backdropTemplate)
    frame:SetSize(660, 520) -- lista de 10 + 3 opções + nota + faixa do Desfazer
    frame:SetPoint("CENTER", 20, 10)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -18)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- Criar no topo (padrão 3.24): item, motivo, quando, valor, Guardar.
    frame.item = Box(frame, "FarolKeepItem", 600, 200)
    frame.item:SetPoint("TOPLEFT", 30, -46)
    frame.item:SetScript("OnEnterPressed", function()
        if frame.pick:IsShown() and pickList[pickOffset + 1] and frame.item:GetText() ~= frame.pickedName then
            Choose(pickList[pickOffset + 1]) -- Enter = o primeiro da lista filtrada
        else
            HidePicker(); frame.reason:SetFocus()
        end
    end)
    frame.item:SetScript("OnEscapePressed", function(self) HidePicker(); self:ClearFocus() end)
    frame.item:SetScript("OnEditFocusGained", function() ShowPicker() end)
    frame.item:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            if self:GetText() ~= frame.pickedName then frame.pickedId, frame.pickedName = nil, nil end
            pickOffset = 0
            if not frame.pick:IsShown() then frame.pick:Show() end
            RefreshPicker()
        end
    end)
    ns.Placeholder(frame.item, "keep_ph_item")
    frame.reason = Box(frame, "FarolKeepReason", 250, MAX_TEXT)
    frame.reason:SetPoint("TOPLEFT", 30, -74)
    frame.reason:SetScript("OnEnterPressed", AddFromForm)
    frame.reason:SetScript("OnEditFocusGained", function() HidePicker() end)
    ns.Placeholder(frame.reason, "keep_ph_reason")
    frame.when = ns.CreateDropdown(frame, "FarolKeepWhen", 170, WhenItems)
    frame.when:SetPoint("LEFT", frame.reason, "RIGHT", 10, 0)
    frame.value = Box(frame, "FarolKeepValue", 44, 4)
    frame.value:SetPoint("LEFT", frame.when, "RIGHT", 10, 0)
    frame.value:SetScript("OnEnterPressed", AddFromForm)
    frame.value:SetScript("OnEditFocusGained", function() HidePicker() end)
    frame.add = Button(frame, "FarolKeepAdd", 110, AddFromForm)
    frame.add:SetPoint("LEFT", frame.value, "RIGHT", 8, 0)

    -- Lista de escolha (abre ao clicar na caixa do item; digitar filtra; rodinha rola; clique ou Enter escolhe).
    frame.pick = CreateFrame("Frame", "FarolKeepPick", frame, ns.backdropTemplate)
    frame.pick:SetSize(520, PICK_ROWS * 20 + 46)
    frame.pick:SetPoint("TOPLEFT", frame.item, "BOTTOMLEFT", -6, -2)
    if frame.pick.SetFrameLevel and frame.GetFrameLevel then frame.pick:SetFrameLevel(frame:GetFrameLevel() + 20) end
    frame.pick:EnableMouse(true)
    if frame.pick.SetBackdrop then
        frame.pick:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        frame.pick:SetBackdropColor(0.02, 0.02, 0.04, 0.97)
    end
    frame.pick.head = ns.Dim(frame.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.pick.head:SetPoint("TOPLEFT", 10, -7)
    frame.pick.bank = ns.Dim(frame.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.pick.bank:SetPoint("BOTTOMLEFT", 10, 7)
    frame.pick.rows = {}
    for i = 1, PICK_ROWS do
        local row = CreateFrame("Button", "FarolKeepPick" .. i, frame.pick)
        row:SetSize(500, 20)
        row:SetPoint("TOPLEFT", 8, -22 - (i - 1) * 20)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        row.icon:SetPoint("LEFT", 2, 0)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", 24, 0)
        row.name:SetWidth(300)
        row.name:SetJustifyH("LEFT")
        if row.name.SetWordWrap then row.name:SetWordWrap(false) end
        row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.count:SetPoint("LEFT", 330, 0)
        row.count:SetWidth(52)
        row.count:SetJustifyH("LEFT")
        row.where = ns.Dim(row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        row.where:SetPoint("LEFT", 386, 0)
        row:SetScript("OnClick", function(self) Choose(self.entry) end)
        frame.pick.rows[i] = row
    end
    frame.pick:EnableMouseWheel(true)
    frame.pick:SetScript("OnMouseWheel", function(_, delta)
        pickOffset = math.max(0, pickOffset - (delta or 0) * 3)
        RefreshPicker()
    end)
    frame.pick:Hide()

    frame.headItem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headItem:SetPoint("TOPLEFT", 26, -104)
    frame.headHave = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headHave:SetPoint("TOPLEFT", 236, -104)
    frame.headWhy = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.headWhy:SetPoint("TOPLEFT", 336, -104)
    frame.empty = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    frame.empty:SetPoint("TOPLEFT", 26, -126)
    frame.empty:SetWidth(600)
    frame.empty:SetJustifyH("LEFT")

    frame.rows = {}
    for i = 1, ROWS do
        local y = -120 - (i - 1) * ROW_H
        local row = {}
        row.pick = CreateFrame("Button", "FarolKeepRow" .. i, frame)
        row.pick:SetSize(570, 22)
        row.pick:SetPoint("TOPLEFT", 22, y)
        row.pick:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.pick:SetScript("OnClick", function() if row.entry then LoadIntoForm(row.entry) end end)
        row.name = row.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.name:SetPoint("LEFT", 4, 0)
        row.name:SetWidth(200)
        row.name:SetJustifyH("LEFT")
        row.have = row.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.have:SetPoint("LEFT", 214, 0)
        row.have:SetWidth(96)
        row.have:SetJustifyH("LEFT")
        row.why = row.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.why:SetPoint("LEFT", 314, 0)
        row.why:SetWidth(252)
        row.why:SetJustifyH("LEFT")
        if row.why.SetWordWrap then row.why:SetWordWrap(false) end
        row.remove = Button(frame, "FarolKeepRemove" .. i, 24, function() if row.index then Keep.Remove(row.index) end end)
        row.remove:SetPoint("TOPRIGHT", -30, y)
        row.remove:SetText("X")
        frame.rows[i] = row
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        offset = math.max(0, offset - (delta or 0) * 3)
        RefreshWindow()
    end)

    local bottom = -120 - ROWS * ROW_H - 4
    frame.scrollInfo = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.scrollInfo:SetPoint("TOPRIGHT", -30, bottom)
    frame.checks = {}
    local y = bottom - 16
    for _, key in ipairs({ "keepMerchant", "keepReady", "keepTooltip" }) do
        local check = CreateFrame("CheckButton", "FarolKeep_" .. key, frame, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 20, y)
        check.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
        check.key = key
        check:SetScript("OnClick", function(self) Keep.SetOption(key, self:GetChecked() and true or false) end)
        frame.checks[#frame.checks + 1] = check
        y = y - 24
    end
    frame.note = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.note:SetPoint("TOPLEFT", 26, y - 4)
    frame.note:SetWidth(600)
    frame.note:SetJustifyH("LEFT")

    frame.undoText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.undoText:SetPoint("BOTTOMLEFT", 30, 24)
    frame.undoText:SetWidth(460)
    frame.undoText:SetJustifyH("LEFT")
    if frame.undoText.SetWordWrap then frame.undoText:SetWordWrap(false) end
    frame.undo = Button(frame, "FarolKeepUndo", 96, function() Keep.Undo() end)
    frame.undo:SetPoint("BOTTOMRIGHT", -26, 18)
    ns.UndoBar(frame)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    frame:SetScript("OnHide", function() HidePicker() end)
    frame.farolDetail = function(on) -- Central do Farol: itens em cartões (Hub.Kit); fora dela, a janela de sempre
        local Kit = ns.Hub and ns.Hub.Kit
        if Kit then Kit.ShowPanels(frame, on) end
        if not on then SimpleLayout(frame); for _, row in ipairs(frame.rows) do row.name:SetTextColor(1, 1, 1) end end
        RefreshWindow()
    end
    tinsert(UISpecialFrames, "FarolKeep") -- Esc fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

-- Layout de sempre (estilo simples) e o de cartões na Central do Farol (estilo detalhado, 3.29).
SimpleLayout = function(frame)
    for _, h in ipairs({ frame.headItem, frame.headHave, frame.headWhy }) do h:Show() end
    frame.note:Show()
    for i, row in ipairs(frame.rows) do
        local y = -120 - (i - 1) * ROW_H
        row.pick:ClearAllPoints(); row.pick:SetPoint("TOPLEFT", 22, y); row.pick:SetSize(570, 22)
        row.name:ClearAllPoints(); row.name:SetPoint("LEFT", 4, 0); row.name:SetWidth(200)
        row.have:ClearAllPoints(); row.have:SetPoint("LEFT", 214, 0); row.have:SetWidth(96)
        row.why:ClearAllPoints(); row.why:SetPoint("LEFT", 314, 0); row.why:SetWidth(252); row.why:SetJustifyH("LEFT")
        row.remove:ClearAllPoints(); row.remove:SetPoint("TOPRIGHT", -30, y)
        if row.icon then row.icon:Hide() end
    end
    local y = -120 - ROWS * ROW_H - 4
    frame.scrollInfo:ClearAllPoints(); frame.scrollInfo:SetPoint("TOPRIGHT", -30, y)
    for i, check in ipairs(frame.checks) do check:ClearAllPoints(); check:SetPoint("TOPLEFT", 20, y - 16 - (i - 1) * 24) end
end

DetailLayout = function(frame, list)
    local Kit = ns.Hub and ns.Hub.Kit
    if not Kit then return end
    local form = Kit.Panel(frame, "form", 14, -12, 632, 92)
    form.title:SetText(T("keep_form_title")); form.sub:SetText(T("keep_form_sub"))
    for _, h in ipairs({ frame.headItem, frame.headHave, frame.headWhy }) do h:Hide() end
    frame.note:Hide()
    frame.scrollInfo:ClearAllPoints(); frame.scrollInfo:SetPoint("TOPRIGHT", -18, -106)
    for i, row in ipairs(frame.rows) do
        local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
        local x, y = 14 + col * 318, -122 - line * 46
        local card = Kit.Panel(frame, "card" .. i, x, y, 314, 42)
        row.pick:ClearAllPoints(); row.pick:SetPoint("TOPLEFT", x + 2, y - 2); row.pick:SetSize(278, 38)
        if not row.icon then
            row.icon = row.pick:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(30, 30); row.icon:SetPoint("LEFT", 4, 0)
        end
        -- Uma linha só em cada texto (nome comprido corta com "...", sem passar por cima da quantidade).
        for _, fs in ipairs({ row.name, row.have, row.why }) do
            if fs.SetWordWrap then fs:SetWordWrap(false) end
            if fs.SetMaxLines then fs:SetMaxLines(1) end
        end
        row.name:ClearAllPoints(); row.name:SetPoint("TOPLEFT", 42, -4); row.name:SetWidth(150)
        row.have:ClearAllPoints(); row.have:SetPoint("TOPLEFT", 42, -21); row.have:SetWidth(232)
        row.why:ClearAllPoints(); row.why:SetPoint("TOPRIGHT", -2, -5); row.why:SetWidth(84); row.why:SetJustifyH("RIGHT")
        row.remove:ClearAllPoints(); row.remove:SetPoint("TOPLEFT", x + 286, y - 10)
        local entry = list[offset + i]
        for _, part in ipairs(card.parts) do if entry then part:Show() else part:Hide() end end
        card.title:SetText(""); card.sub:SetText("")
        if entry then
            row.icon:SetTexture(IconOf(entry.id)); row.icon:Show()
            row.name:SetTextColor(Quality(entry.q))
            local total, bags = Keep.Counts(entry.id)
            local have = tostring(total)
            if total > bags then have = have .. " " .. string.format(T("keep_bank"), total - bags) end
            row.have:SetText(ns.C.dim .. have .. (entry.r and (" · " .. entry.r) or "") .. "|r")
            local _, state = Keep.Status(entry)
            row.why:SetText(state)
        elseif row.icon then
            row.icon:Hide()
        end
    end
    local opt = Kit.Panel(frame, "options", 14, -358, 632, 104)
    opt.title:SetText(T("keep_opts_title")); opt.sub:SetText(T("keep_opts_sub"))
    for i, check in ipairs(frame.checks) do check:ClearAllPoints(); check:SetPoint("TOPLEFT", 22, -384 - (i - 1) * 24) end
end

RefreshWindow = function()
    if not window or not window:IsShown() then return end
    local list = List()
    local db = DB() or {}
    window.title:SetText(#list > 0 and string.format(T("keep_title_n"), #list) or T("keep_title"))
    window.when:SetText(WhenLabel())
    if when.k then window.value:Show() else window.value:Hide() end
    window.add:SetText(T("keep_add"))
    window.headItem:SetText(T("keep_col_item"))
    window.headHave:SetText(T("keep_col_have"))
    window.headWhy:SetText(T("keep_col_why"))
    ns.UpdatePlaceholder(window.item); ns.UpdatePlaceholder(window.reason)
    offset = math.max(0, math.min(offset, #list - ROWS))
    for i, row in ipairs(window.rows) do
        local index = offset + i
        local entry = list[index]
        if entry then
            row.index, row.entry = index, entry
            local total, bags = Keep.Counts(entry.id)
            row.name:SetText(entry.n)
            local have = tostring(total)
            if total > bags then have = have .. " " .. ns.C.dim .. string.format(T("keep_bank"), total - bags) .. "|r" end
            row.have:SetText(have)
            row.why:SetText(Why(entry))
            row.pick:Show(); row.remove:Show()
        else
            row.index, row.entry = nil, nil
            row.pick:Hide(); row.remove:Hide()
        end
    end
    if #list == 0 then window.empty:SetText(T("keep_empty")); window.empty:Show() else window.empty:Hide() end
    window.scrollInfo:SetText(#list > ROWS and string.format(T("keep_scroll"), offset + 1, math.min(offset + ROWS, #list), #list) or "")
    for _, check in ipairs(window.checks) do
        check:SetChecked(db[check.key] and true or false)
        check.label:SetText(T(OPTIONS[check.key]))
    end
    window.note:SetText(T("keep_note"))
    local undo = Keep.lastRemoved
    ns.ShowUndo(window, undo and string.format(T("keep_undo_line"), undo.entry.n), T("keep_undo"))
    if window.farolDocked then DetailLayout(window, list) end
end

function Keep.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

function Keep.Refresh() if RefreshWindow then RefreshWindow() end end

---------------------------------------------------------------------------
-- Eventos: comerciante, nível e profissões
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
for _, event in ipairs({ "MERCHANT_SHOW", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "PLAYER_ENTERING_WORLD",
                         "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED", "BAG_UPDATE" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, arg1)
    if not DB() then return end
    if event == "BANKFRAME_OPENED" then
        bankOpen = true
        pcall(Keep.ScanBank)
    elseif event == "BANKFRAME_CLOSED" then
        bankOpen = false
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BAG_UPDATE" then
        if bankOpen then pcall(Keep.ScanBank) end
        if window and window.pick and window.pick:IsShown() then RefreshPicker() end
    elseif event == "MERCHANT_SHOW" then
        pcall(Keep.OnMerchant)
    elseif event == "PLAYER_LEVEL_UP" then
        pcall(Keep.CheckReady, Int(arg1, 1, MAX_LEVEL))
        Keep.Refresh()
    else
        if event == "PLAYER_ENTERING_WORLD" and DB().keepTooltip then Keep.HookTooltip() end
        pcall(Keep.CheckReady)
    end
end)

---------------------------------------------------------------------------
-- Comandos: /farol guardar ...
---------------------------------------------------------------------------

local WORDS = {
    lista = "list", listar = "list", list = "list",
    tirar = "remove", remover = "remove", apagar = "remove", remove = "remove", del = "remove",
    desfazer = "undo", undo = "undo", voltar = "undo",
    comerciante = "keepMerchant", merchant = "keepMerchant", vendedor = "keepMerchant",
    hora = "keepReady", ready = "keepReady", pronto = "keepReady",
    tooltip = "keepTooltip", dica = "keepTooltip",
}
local SWITCH = { on = true, ligar = true, ligado = true, sim = true, off = false, desligar = false, desligado = false, nao = false }

function Keep.HandleCommand(rest)
    rest = ns.Trim(rest or "")
    if #rest > 500 then Print(T("keep_usage")) return end
    local word, tail = string.match(rest, "^(%a*)%s*(.-)$")
    local action = WORDS[string.lower(word or "")]
    if rest == "" then
        Keep.ToggleWindow()
    elseif action == "list" and tail == "" then
        local list = List()
        Print(string.format(T("keep_list"), #list))
        for i, entry in ipairs(list) do
            Print(string.format(T("keep_line"), i, entry.n, (Keep.Counts(entry.id)), Why(entry)))
        end
    elseif action == "remove" and tail ~= "" then
        local index = FindIndex(tail)
        if index then Keep.Remove(index) else Print(T("keep_missing")) end
    elseif action == "undo" and tail == "" then
        Keep.Undo()
    elseif OPTIONS[action or ""] then
        local value = SWITCH[string.lower(tail)]
        if tail == "" then value = not (DB() or {})[action] end
        if value == nil then Print(T("keep_usage")) else Keep.SetOption(action, value) end
    else
        -- "[item]: motivo" — o motivo vem depois de ":" (o link pode ter "[" e "]", mas não ":" fora dele).
        local itemText, reason = rest, nil
        local linkEnd = select(2, string.find(rest, "|h|r", 1, true))
        local colon = string.find(rest, ":%s", (linkEnd or 0) + 1)
        if colon and (not linkEnd or colon > linkEnd) then
            itemText, reason = ns.Trim(string.sub(rest, 1, colon - 1)), ns.Trim(string.sub(rest, colon + 1))
        end
        local id, name = Keep.Resolve(itemText)
        if not id then Print(T("keep_not_found")) return end
        local old = Keep.Entry(id)
        local spec = old and { k = old.k, v = old.v, p = old.p } or nil
        Keep.Set(id, name or itemText, reason or (old and old.r), spec)
    end
end
