--[[
  Farol — Bloco de notas / Notes

  Até 10 anotações da CONTA (as mesmas em todos os personagens): título curto + texto de várias linhas, com caixinha
  de "concluída" que fica até o jogador apagar (nada zera sozinho). Fica só neste computador; nada é enviado.
  FarolDB.notes = { { t = título (≤ 40 letras), x = texto (≤ 500 letras, com quebras de linha), d = concluída?,
  m = quando mudou (time()) }, ... }, validado ao carregar (Notes.Sanitize): sem "|" (códigos do chat) nem
  caracteres de controle (só a quebra de linha), tamanhos máximos, no máximo 10.
]]

local _, ns = ...

local MAX_NOTES = 10
local MAX_TITLE = 40
local MAX_TEXT = 500
local ROW_HEIGHT = 24

local Notes = {}
ns.Notes = Notes

---------------------------------------------------------------------------
-- Textos / Strings
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        name_notes    = "Anotações (bloco de notas)", cmd_notes = "notas",
        desc_notes    = "Seu bloco de notas da conta: até 10 anotações com caixinha de concluída (abra com /farol notas).",
        label_notes   = "Notas",
        tt_notes      = "Anotações",
        tt_notes_pending = "%d pendentes de %d",
        tt_notes_none = "nenhuma anotação (/farol notas)",
        tt_notes_click = "Abrir: /farol notas ou Menu > Ferramentas (⚙)",
        note_title    = "Anotações",
        note_title_n  = "Anotações (%d/%d pendentes)",
        note_empty    = "Nenhuma anotação ainda: clique em + Nova nota.",
        note_pick     = "Escolha uma anotação à esquerda (ou crie uma nova).",
        note_untitled = "(sem título)",
        note_done_sep = "Concluídas",
        note_new      = "+ Nova nota",
        note_clear    = "Limpar concluídas",
        note_done_btn = "✓ Concluída",
        note_reopen   = "Reabrir",
        note_delete   = "Apagar",
        note_counter  = "%d / %d · salva sozinha ao digitar",
        note_full     = "já existem 10 anotações; apague uma antes.",
        note_added    = "nova anotação criada (escreva o título e o texto na janela).",
        note_del_ask  = "Apagar %d notas?",
        note_del_ask_1 = "Apagar %d nota?",
        note_clear_ask = "Apagar %d notas concluídas?",
        note_clear_ask_1 = "Apagar %d nota concluída?",
        note_removed  = "anotação apagada: %s (Desfazer na janela ou /farol notas desfazer).",
        note_removed_n = "%d anotações concluídas apagadas (Desfazer na janela ou /farol notas desfazer).",
        note_removed_n_1 = "%d anotação concluída apagada (Desfazer na janela ou /farol notas desfazer).",
        note_restored = "anotação de volta: %s.",
        note_restored_n = "%d anotações de volta.",
        note_restored_n_1 = "%d anotação de volta.",
        note_nothing_undo = "nada para desfazer.",
        note_undo     = "Desfazer",
        note_undo_line = "Apagada: %s",
        note_marked   = "anotação %s: %s.",
        note_done_word = "concluída",
        note_open_word = "pendente",
        note_list     = "Farol — anotações (%d pendentes de %d):",
        note_line     = "  %d. %s%s",
        note_usage    = "uso: /farol notas || /farol notas nova Título || /farol notas lista || /farol notas desfazer",
        help_notes    = "  /farol notas         - bloco de notas da conta: até 10 anotações com caixinha de concluída",
        tool_notes    = "Anotações...",    tool_notes_desc = "bloco de notas da conta, com caixinhas",
        news_notes    = "bloco de notas da conta: até 10 anotações com caixinha de concluída (/farol notas)",
    },
    en = {
        name_notes    = "Notes (notepad)", cmd_notes = "notes",
        desc_notes    = "Your account notepad: up to 10 notes with a done checkbox (open with /farol notes).",
        label_notes   = "Notes",
        tt_notes      = "Notes",
        tt_notes_pending = "%d pending of %d",
        tt_notes_none = "no notes (/farol notes)",
        tt_notes_click = "Open: /farol notes or Menu > Tools (⚙)",
        note_title    = "Notes",
        note_title_n  = "Notes (%d/%d pending)",
        note_empty    = "No notes yet: click + New note.",
        note_pick     = "Pick a note on the left (or create a new one).",
        note_untitled = "(untitled)",
        note_done_sep = "Done",
        note_new      = "+ New note",
        note_clear    = "Clear done",
        note_done_btn = "✓ Done",
        note_reopen   = "Reopen",
        note_delete   = "Delete",
        note_counter  = "%d / %d · saved as you type",
        note_full     = "there are already 10 notes; delete one first.",
        note_added    = "new note created (type the title and the text in the window).",
        note_del_ask  = "Delete %d notes?",
        note_del_ask_1 = "Delete %d note?",
        note_clear_ask = "Delete %d done notes?",
        note_clear_ask_1 = "Delete %d done note?",
        note_removed  = "note deleted: %s (Undo in the window or /farol notes undo).",
        note_removed_n = "%d done notes deleted (Undo in the window or /farol notes undo).",
        note_removed_n_1 = "%d done note deleted (Undo in the window or /farol notes undo).",
        note_restored = "note back: %s.",
        note_restored_n = "%d notes back.",
        note_restored_n_1 = "%d note back.",
        note_nothing_undo = "nothing to undo.",
        note_undo     = "Undo",
        note_undo_line = "Deleted: %s",
        note_marked   = "note %s: %s.",
        note_done_word = "done",
        note_open_word = "pending",
        note_list     = "Farol — notes (%d pending of %d):",
        note_line     = "  %d. %s%s",
        note_usage    = "usage: /farol notes || /farol notes new Title || /farol notes list || /farol notes undo",
        help_notes    = "  /farol notes         - account notepad: up to 10 notes with a done checkbox",
        tool_notes    = "Notes...",        tool_notes_desc = "account notepad, with checkboxes",
        news_notes    = "account notepad: up to 10 notes with a done checkbox (/farol notes)",
    },
}
for lang, entries in pairs(STRINGS) do
    for key, value in pairs(entries) do
        ns.STRINGS[lang][key] = value
    end
end

local function T(key) return ns.T(key) end
local function Print(msg) ns.Print(msg) end

-- Lista salva (na conta). Sem dados carregados: lista vazia de mentira (nada é gravado).
local function List()
    local db = ns.GetDB and ns.GetDB()
    if not db then return {} end
    if type(db.notes) ~= "table" then db.notes = {} end
    return db.notes
end

---------------------------------------------------------------------------
-- Validação (linear: um arquivo adulterado com textos enormes não trava)
---------------------------------------------------------------------------

-- Corta em "max" letras (UTF-8), sem quebrar uma letra no meio.
local function Cap(text, max)
    local out, count = {}, 0
    for char in string.gmatch(text, "[\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > max then break end
        out[#out + 1] = char
    end
    return table.concat(out)
end

-- Título: sem "|" nem controle, até MAX_TITLE letras. "trim" apara as pontas (ao carregar, não ao digitar).
local function CleanTitle(text, trim)
    if type(text) ~= "string" then return "" end
    text = string.sub(text, 1, 1024)
    text = string.gsub(text, "|", "")
    text = string.gsub(text, "%c", "")
    if trim then text = ns.Trim(text) end
    return Cap(text, MAX_TITLE)
end

-- Texto: sem "|" nem controle, menos a quebra de linha; até MAX_TEXT letras.
local function CleanText(text)
    if type(text) ~= "string" then return "" end
    text = string.sub(text, 1, 4096)
    text = string.gsub(text, "|", "")
    text = string.gsub(text, "\r\n?", "\n")
    text = string.gsub(text, "[%z\1-\9\11-\31\127]", "")
    return Cap(text, MAX_TEXT)
end
Notes.CleanTitle, Notes.CleanText = CleanTitle, CleanText

local function Now()
    local ok, now = pcall(time)
    if ok and type(now) == "number" and now == now and now > 0 and now < 4102444800 then return math.floor(now) end
    return nil
end

local function Copy(note) return { t = note.t, x = note.x, d = note.d, m = note.m } end

function Notes.Sanitize(saved)
    if type(saved) ~= "table" then return {} end
    -- As MAX_NOTES do começo da lista (a ordem é a do jogador), percorrendo no máximo um número fixo de entradas.
    local clean = {}
    local n = #saved
    if type(n) ~= "number" or n ~= n then return clean end
    for i = 1, math.min(n, 1000) do
        if #clean >= MAX_NOTES then break end
        local entry = saved[i]
        if type(entry) == "table" then
            local title, text = CleanTitle(entry.t, true), CleanText(entry.x)
            if title ~= "" or ns.Trim(text) ~= "" then
                local m = entry.m
                if type(m) ~= "number" or m ~= m or m <= 0 or m > 4102444800 then m = nil end
                clean[#clean + 1] = { t = title, x = text, d = entry.d == true, m = m and math.floor(m) or nil }
            end
        end
    end
    return clean
end

---------------------------------------------------------------------------
-- Contagem, barra e tooltip
---------------------------------------------------------------------------

function Notes.Counts()
    local pending, total = 0, 0
    for _, note in ipairs(List()) do
        total = total + 1
        if not note.d then pending = pending + 1 end
    end
    return pending, total
end

local function Title(note)
    if not note or note.t == "" then return T("note_untitled") end
    return note.t
end

-- Ordem de exibição: pendentes primeiro, depois as concluídas (cada grupo na ordem do jogador).
local function DisplayOrder()
    local order = {}
    local list = List()
    for i, note in ipairs(list) do if not note.d then order[#order + 1] = i end end
    for i, note in ipairs(list) do if note.d then order[#order + 1] = i end end
    return order
end

function Notes.BarText()
    local pending, total = Notes.Counts()
    if total == 0 then return T("label_notes") .. " " .. ns.C.dim .. "--|r" end
    local color = pending > 0 and ns.C.warn or ns.C.good
    return string.format("%s %s%d|r/%d", T("label_notes"), color, pending, total)
end

function Notes.Tooltip()
    local pending, total = Notes.Counts()
    GameTooltip:AddDoubleLine(T("tt_notes"), total > 0 and string.format(T("tt_notes_pending"), pending, total) or "--",
        1, 0.82, 0, 1, 1, 1)
    if total == 0 then
        GameTooltip:AddLine("   " .. T("tt_notes_none"), 0.7, 0.7, 0.7)
    else
        local shown = 0
        for _, i in ipairs(DisplayOrder()) do
            local note = List()[i]
            if not note.d then
                shown = shown + 1
                if shown <= 5 then GameTooltip:AddLine("   " .. Title(note), 0.9, 0.9, 0.9) end
            end
        end
        if shown > 5 then GameTooltip:AddLine("   " .. string.format(T("tt_more"), shown - 5), 0.6, 0.6, 0.6) end
    end
    GameTooltip:AddLine(T("tt_notes_click"), 0.6, 0.6, 0.6)
end

---------------------------------------------------------------------------
-- Ações
---------------------------------------------------------------------------

local RefreshWindow -- definida abaixo
local selected      -- índice (na lista salva) da anotação aberta na janela

local function Changed()
    if ns.UpdateText then ns.UpdateText() end
    if RefreshWindow then RefreshWindow() end
end

function Notes.Add(title)
    local list = List()
    if #list >= MAX_NOTES then Print(T("note_full")) return nil end
    list[#list + 1] = { t = CleanTitle(title or "", true), x = "", d = false, m = Now() }
    selected = #list
    Print(T("note_added"))
    Changed()
    return #list
end

function Notes.SetDone(index, value)
    local note = List()[index]
    if not note then return end
    if value == nil then value = not note.d end
    note.d = value and true or false
    note.m = Now()
    Print(string.format(T("note_marked"), Title(note), note.d and T("note_done_word") or T("note_open_word")))
    Changed()
end

-- Apaga as anotações dos índices dados; "Desfazer" (só na sessão) devolve cópias nos mesmos lugares.
local function RemoveIndexes(indexes)
    local list = List()
    table.sort(indexes)
    local removed = {}
    for k = #indexes, 1, -1 do
        local i = indexes[k]
        if list[i] then
            table.insert(removed, 1, { index = i, note = Copy(list[i]) })
            table.remove(list, i)
        end
    end
    if #removed == 0 then return 0 end
    Notes.lastRemoved = removed
    selected = nil
    return #removed
end

function Notes.Remove(index)
    local note = List()[index]
    if not note then return end
    local title = Title(note)
    RemoveIndexes({ index })
    Print(string.format(T("note_removed"), title))
    Changed()
end

function Notes.ClearDone()
    local indexes = {}
    for i, note in ipairs(List()) do if note.d then indexes[#indexes + 1] = i end end
    local n = RemoveIndexes(indexes)
    if n > 0 then Print(string.format(ns.TN("note_removed_n", n), n)) end
    Changed()
end

function Notes.Undo()
    local undo = Notes.lastRemoved
    if not undo then Print(T("note_nothing_undo")) return false end
    local list = List()
    if #list + #undo > MAX_NOTES then Print(T("note_full")) return false end
    Notes.lastRemoved = nil
    for _, item in ipairs(undo) do -- em ordem crescente: cada uma volta ao seu lugar
        local i = tonumber(item.index)
        if not i or i ~= i or i < 1 or i > #list + 1 then i = #list + 1 end
        table.insert(list, math.floor(i), Copy(item.note))
    end
    if #undo == 1 then Print(string.format(T("note_restored"), Title(undo[1].note)))
    else Print(string.format(ns.TN("note_restored_n", #undo), #undo)) end
    Changed()
    return true
end

-- Ao digitar: grava o título/texto limpo da anotação aberta.
function Notes.SetTitle(index, text)
    local note = List()[index]
    if not note then return end
    note.t, note.m = CleanTitle(text, false), Now()
    if ns.UpdateText then ns.UpdateText() end
end

function Notes.SetText(index, text)
    local note = List()[index]
    if not note then return end
    note.x, note.m = CleanText(text), Now()
end

---------------------------------------------------------------------------
-- Janela
---------------------------------------------------------------------------

local window

local function Button(parent, name, width, text, onClick)
    local b = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetScript("OnClick", onClick)
    if text then b:SetText(text) end
    return b
end

-- Texto colado/digitado com "|" ou controle: a caixa mostra a versão limpa (sem repetir o OnTextChanged).
local function KeepClean(box, clean)
    if box:GetText() ~= clean then
        box.farolSetting = true
        box:SetText(clean)
        box.farolSetting = nil
    end
end

local function CreateWindow()
    local frame = CreateFrame("Frame", "FarolNotes", UIParent, ns.backdropTemplate)
    frame:SetSize(820, 400)
    frame:SetPoint("CENTER", 0, 20)
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
    frame.empty = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.empty:SetPoint("TOPLEFT", 26, -54)
    frame.empty:SetWidth(250)
    frame.empty:SetJustifyH("LEFT")

    -- Esquerda: lista (caixinha + título clicável).
    frame.rows = {}
    for r = 1, MAX_NOTES do
        local y = -48 - (r - 1) * ROW_HEIGHT
        local row = {}
        row.check = CreateFrame("CheckButton", "FarolNoteDone" .. r, frame, "UICheckButtonTemplate")
        row.check:SetSize(24, 24)
        row.check:SetPoint("TOPLEFT", 20, y)
        row.check:SetScript("OnClick", function(self)
            if row.index then Notes.SetDone(row.index, self:GetChecked() and true or false) end
        end)
        row.pick = CreateFrame("Button", "FarolNotePick" .. r, frame)
        row.pick:SetSize(226, 22)
        row.pick:SetPoint("TOPLEFT", 46, y - 1)
        row.pick:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.text = row.pick:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", 4, 0)
        row.text:SetWidth(218)
        row.text:SetJustifyH("LEFT")
        if row.text.SetWordWrap then row.text:SetWordWrap(false) end
        row.pick:SetScript("OnClick", function() if row.index then selected = row.index; RefreshWindow() end end)
        frame.rows[r] = row
    end
    frame.doneSep = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.new = Button(frame, "FarolNoteNew", 120, nil, function() Notes.Add("") end)
    frame.new:SetPoint("BOTTOMLEFT", 22, 18)
    frame.clear = Button(frame, "FarolNoteClear", 140, nil, function(self)
        local done = 0
        for _, note in ipairs(List()) do if note.d then done = done + 1 end end
        ns.ConfirmClick(self, done, "note_clear_ask", Notes.ClearDone)
    end)
    frame.clear:SetPoint("LEFT", frame.new, "RIGHT", 6, 0)

    -- Direita: título e texto da anotação aberta.
    frame.pickHint = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    frame.pickHint:SetPoint("TOPLEFT", 300, -60)
    frame.titleBox = CreateFrame("EditBox", "FarolNoteTitle", frame, "InputBoxTemplate")
    frame.titleBox:SetSize(490, 22)
    frame.titleBox:SetPoint("TOPLEFT", 304, -46)
    frame.titleBox:SetAutoFocus(false)
    frame.titleBox:SetMaxLetters(MAX_TITLE)
    frame.titleBox:SetScript("OnTextChanged", function(self, userInput)
        if self.farolSetting or not userInput or not selected then return end
        local clean = CleanTitle(self:GetText(), false)
        KeepClean(self, clean)
        Notes.SetTitle(selected, clean)
        if RefreshWindow then RefreshWindow(true) end
    end)
    frame.titleBox:SetScript("OnEnterPressed", function() frame.textBox:SetFocus() end)
    frame.titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    frame.textBack = CreateFrame("Frame", nil, frame, ns.backdropTemplate)
    frame.textBack:SetSize(496, 232)
    frame.textBack:SetPoint("TOPLEFT", 298, -76)
    if frame.textBack.SetBackdrop then
        frame.textBack:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        frame.textBack:SetBackdropColor(0, 0, 0, 0.9)
    end
    frame.textBox = CreateFrame("EditBox", "FarolNoteText", frame)
    frame.textBox:SetMultiLine(true)
    frame.textBox:SetFontObject("GameFontHighlight")
    frame.textBox:SetSize(476, 216)
    frame.textBox:SetPoint("TOPLEFT", frame.textBack, "TOPLEFT", 10, -8)
    frame.textBox:SetAutoFocus(false)
    frame.textBox:SetMaxLetters(MAX_TEXT)
    frame.textBox:SetScript("OnTextChanged", function(self, userInput)
        if self.farolSetting or not userInput or not selected then return end
        local clean = CleanText(self:GetText())
        KeepClean(self, clean)
        Notes.SetText(selected, clean)
        if RefreshWindow then RefreshWindow(true) end
    end)
    frame.textBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.counter = ns.Dim(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    frame.counter:SetPoint("TOPLEFT", frame.textBack, "BOTTOMLEFT", 2, -8)
    frame.delete = Button(frame, "FarolNoteDelete", 96, nil, function(self)
        if selected then ns.ConfirmClick(self, 1, "note_del_ask", function() Notes.Remove(selected) end) end
    end)
    frame.delete:SetPoint("TOPRIGHT", frame.textBack, "BOTTOMRIGHT", 0, -4)
    frame.done = Button(frame, "FarolNoteDoneButton", 120, nil, function()
        if selected then Notes.SetDone(selected) end
    end)
    frame.done:SetPoint("RIGHT", frame.delete, "LEFT", -6, 0)
    -- Faixa "Apagada: X [Desfazer]" (só depois de apagar).
    frame.undoText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.undoText:SetPoint("BOTTOMLEFT", 302, 24)
    frame.undoText:SetWidth(360)
    frame.undoText:SetJustifyH("LEFT")
    if frame.undoText.SetWordWrap then frame.undoText:SetWordWrap(false) end
    frame.undo = Button(frame, "FarolNoteUndo", 96, nil, function() Notes.Undo() end)
    frame.undo:SetPoint("BOTTOMRIGHT", -26, 18)

    frame:SetScript("OnShow", function() RefreshWindow() end)
    tinsert(UISpecialFrames, "FarolNotes") -- ESC fecha
    ns.MakeToplevel(frame)
    frame:Hide()
    return frame
end

-- "typing" = só o contador, a lista e a barra mudam (não reescreve as caixas em que o jogador está digitando).
RefreshWindow = function(typing)
    if not window or not window:IsShown() then return end
    local list = List()
    local pending, total = Notes.Counts()
    window.title:SetText(total > 0 and string.format(T("note_title_n"), pending, total) or T("note_title"))
    window.empty:SetText(T("note_empty"))
    if total == 0 then window.empty:Show() else window.empty:Hide() end
    if selected and not list[selected] then selected = nil end
    local order = DisplayOrder()
    local sepShown = false
    window.doneSep:Hide()
    local y = -48
    for r, row in ipairs(window.rows) do
        local i = order[r]
        local note = i and list[i]
        if note then
            if note.d and not sepShown and r > 1 then
                sepShown = true
                window.doneSep:SetText(T("note_done_sep"))
                window.doneSep:ClearAllPoints()
                window.doneSep:SetPoint("TOPLEFT", 26, y - 4)
                window.doneSep:Show()
                y = y - 18
            end
            row.index = i
            row.check:ClearAllPoints(); row.check:SetPoint("TOPLEFT", 20, y)
            row.pick:ClearAllPoints(); row.pick:SetPoint("TOPLEFT", 46, y - 1)
            row.check:SetChecked(note.d)
            local text = Title(note)
            if note.d then text = ns.C.dim .. text .. "|r" end
            row.text:SetText(text)
            if i == selected then row.pick:LockHighlight() else row.pick:UnlockHighlight() end
            row.check:Show(); row.pick:Show()
            y = y - ROW_HEIGHT
        else
            row.index = nil
            row.check:Hide(); row.pick:Hide()
        end
    end
    window.new:SetText(T("note_new"))
    if not window.clear.farolAsk then window.clear:SetText(T("note_clear")) end
    local note = selected and list[selected]
    if note then
        window.pickHint:Hide()
        window.titleBox:Show(); window.textBack:Show(); window.textBox:Show(); window.counter:Show()
        window.done:Show(); window.delete:Show()
        if not typing then
            KeepClean(window.titleBox, note.t)
            KeepClean(window.textBox, note.x)
            window.delete.farolAsk = nil
        end
        local letters = select(2, string.gsub(note.x, "[\1-\127\194-\244][\128-\191]*", ""))
        window.counter:SetText(string.format(T("note_counter"), letters, MAX_TEXT))
        window.done:SetText(note.d and T("note_reopen") or T("note_done_btn"))
        if not window.delete.farolAsk then window.delete:SetText(T("note_delete")) end
    else
        window.pickHint:SetText(total > 0 and T("note_pick") or "")
        window.pickHint:Show()
        window.titleBox:Hide(); window.textBack:Hide(); window.textBox:Hide(); window.counter:Hide()
        window.done:Hide(); window.delete:Hide()
    end
    local undo = Notes.lastRemoved
    if undo then
        local label = #undo == 1 and Title(undo[1].note) or string.format(ns.TN("note_restored_n", #undo), #undo)
        window.undoText:SetText(string.format(T("note_undo_line"), label))
        window.undo:SetText(T("note_undo"))
        window.undoText:Show(); window.undo:Show()
    else
        window.undoText:Hide(); window.undo:Hide()
    end
end

function Notes.ToggleWindow()
    window = window or CreateWindow()
    if window:IsShown() then
        window:Hide()
    else
        if not selected then selected = DisplayOrder()[1] end
        window:Show()
    end
end

function Notes.Select(index) selected = index; Changed() end
function Notes.Refresh() if RefreshWindow then RefreshWindow() end end

---------------------------------------------------------------------------
-- Comandos: /farol notas ...
---------------------------------------------------------------------------

local WORDS = {
    nova = "new", novo = "new", new = "new", add = "new", adicionar = "new",
    lista = "list", listar = "list", list = "list",
    desfazer = "undo", undo = "undo", voltar = "undo",
}

function Notes.HandleCommand(rest)
    local word, tail = string.match(rest or "", "^%s*(%a*)%s*(.-)%s*$")
    word = string.lower(word or "")
    local action = WORDS[word]
    if word == "" then
        Notes.ToggleWindow()
    elseif action == "new" then
        if Notes.Add(string.sub(tail or "", 1, 200)) then
            window = window or CreateWindow()
            if not window:IsShown() then window:Show() end
        end
    elseif action == "list" and tail == "" then
        local pending, total = Notes.Counts()
        Print(string.format(T("note_list"), pending, total))
        if total == 0 then Print("  " .. T("tt_notes_none")) return end
        for n, i in ipairs(DisplayOrder()) do
            local note = List()[i]
            Print(string.format(T("note_line"), n, Title(note), note.d and (" — " .. T("note_done_word")) or ""))
        end
    elseif action == "undo" and tail == "" then
        Notes.Undo()
    else
        Print(T("note_usage"))
    end
end
