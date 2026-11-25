-- Bloco de notas (3.22): até 10 anotações da conta, título + texto, caixinha de concluída, apagar com confirmação e
-- Desfazer, item opcional na barra; dados salvos validados.
-- Notes: up to 10 account-wide notes, done checkbox, delete with confirmation and Undo, optional bar item.

local function chat(H) return H.strip(table.concat(H.msgs, "\n")) end
local function tip(H)
    H.env.GameTooltip.lines = {}
    H.env.FarolFrame._scripts.OnEnter(H.env.FarolFrame)
    return H.strip(table.concat(H.env.GameTooltip.lines, " / "))
end
local function typeIn(box, text) box:SetText(text); box._scripts.OnTextChanged(box, true) end

local function withNotes(Mock, notes, opts)
    return Mock.new(opts or { locale = "ptBR" }):login({ notes = notes })
end

return {
    { "off by default; /farol notas opens the window; a new note is typed and saved in the account", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }):login()
        T.eq(H.env.FarolDB.items.notes, false, "bar item off")
        T.hasnt(H:bar(), "Notas")
        H:slash("notas")
        local w = H.env.FarolNotes
        T.ok(w:IsShown()); T.eq(H:text(w.title), "Anotações"); T.eq(H:text(w.empty), "Nenhuma anotação ainda: clique em + Nova nota.")
        H:click(H.env.FarolNoteNew)
        typeIn(H.env.FarolNoteTitle, "Rota de farm"); typeIn(H.env.FarolNoteText, "1. colinas\n2. rio")
        local saved = H.env.FarolDB.notes[1]
        T.eq(saved.t, "Rota de farm"); T.eq(saved.x, "1. colinas\n2. rio"); T.eq(saved.d, false)
        T.eq(H:text(w.counter), "17 / 500 · salva sozinha ao digitar")
        T.eq(H:text(w.title), "Anotações (1/1 pendentes)")
        -- Conta inteira: outro personagem vê a mesma nota.
        local B = Mock.new({ locale = "ptBR" }); B.playerName = "Outro"; B:login(H.env.FarolDB)
        T.eq(B.env.FarolDB.notes[1].t, "Rota de farm")
    end },

    { "done checkbox: pending first, done below; bar item and tooltip", function(T, Mock)
        local H = withNotes(Mock, { { t = "A", x = "" }, { t = "B", x = "" }, { t = "C", x = "" } })
        H:slash("show notas"); H:update(1)
        T.has(H:bar(), "Notas 3/3")
        H:slash("notas")
        H:check(H.env.FarolNoteDone1, true) -- linha 1 = nota A
        T.eq(H.env.FarolDB.notes[1].d, true); T.has(H:lastMsg(), "anotação A: concluída.")
        local rows = H.env.FarolNotes.rows
        T.eq(rows[1].index, 2); T.eq(rows[2].index, 3); T.eq(rows[3].index, 1, "done note goes below")
        T.eq(H:text(H.env.FarolNotes.doneSep), "Concluídas")
        H:update(1); T.has(H:bar(), "Notas 2/3")
        T.has(tip(H), "Anotações = 2 pendentes de 3 /    B /    C / Abrir: /farol notas ou Menu > Ferramentas")
        H:click(H.env.FarolNotePick3); H:click(H.env.FarolNoteDoneButton)
        T.eq(H.env.FarolDB.notes[1].d, false, "Reopen")
    end },

    { "delete asks first and has Undo; clear done; at most 10 notes", function(T, Mock)
        local H = withNotes(Mock, { { t = "A", x = "a" }, { t = "B", x = "b", d = true }, { t = "C", x = "c", d = true } })
        H:slash("notas")
        H:click(H.env.FarolNotePick1)
        H:click(H.env.FarolNoteDelete); T.eq(#H.env.FarolDB.notes, 3, "first click only asks")
        T.eq(H:text(H.env.FarolNoteDelete), "Apagar 1 nota?")
        H:click(H.env.FarolNoteDelete); T.eq(#H.env.FarolDB.notes, 2)
        T.eq(H:text(H.env.FarolNotes.undoText), "Apagada: A")
        H:click(H.env.FarolNoteUndo); T.eq(H.env.FarolDB.notes[1].t, "A", "back in its place"); T.eq(H.env.FarolDB.notes[1].x, "a")
        T.ok(not H.env.FarolNoteUndo:IsShown(), "nothing left to undo")
        H:click(H.env.FarolNoteClear); T.eq(H:text(H.env.FarolNoteClear), "Apagar 2 notas concluídas?")
        H:click(H.env.FarolNoteClear); T.eq(#H.env.FarolDB.notes, 1)
        H:slash("notas desfazer"); T.eq(#H.env.FarolDB.notes, 3); T.eq(H.env.FarolDB.notes[3].t, "C")
        H:slash("notas desfazer"); T.has(H:lastMsg(), "nada para desfazer.")
        for i = 4, 10 do H:slash("notas nova Nota " .. i) end
        T.eq(#H.env.FarolDB.notes, 10); H:slash("notas nova Demais"); T.has(H:lastMsg(), "já existem 10 anotações")
        H:slash("notas lista"); T.has(chat(H), "Farol — anotações (")
        H:slash("notas xyz"); T.has(H:lastMsg(), "uso: /farol notas")
    end },

    { "typed and saved text is cleaned: no chat codes, no control characters, limits; tampered files load fast", function(T, Mock)
        local H = withNotes(Mock, {})
        H:slash("notas"); H:click(H.env.FarolNoteNew)
        typeIn(H.env.FarolNoteTitle, "Ti||cffff0000tulo")
        T.eq(H.env.FarolDB.notes[1].t, "Ticffff0000tulo", "no '|'"); T.eq(H:text(H.env.FarolNoteTitle), "Ticffff0000tulo")
        typeIn(H.env.FarolNoteText, string.rep("é", 600))
        T.eq(select(2, string.gsub(H.env.FarolDB.notes[1].x, "é", "")), 500, "at most 500 letters")
        typeIn(H.env.FarolNoteText, "a\r\nb\0c\tz")
        T.eq(H.env.FarolDB.notes[1].x, "a\nbcz", "line breaks kept, control characters dropped")
        -- Arquivo adulterado: tipos errados, lixo, texto enorme, mais de 10 notas.
        local big = string.rep(" ", 200000) .. "x"
        local saved = { "lixo", { t = 5, x = {} }, { t = "|cffff0000Mau|r", x = "ok", d = "sim", m = 0 / 0 }, { t = big, x = big } }
        for i = 1, 3000 do saved[#saved + 1] = { t = "N" .. i, x = "" } end
        local started = os.clock()
        local Z = withNotes(Mock, saved)
        T.ok(os.clock() - started < 2, "loads fast")
        local notes = Z.env.FarolDB.notes
        T.eq(#notes, 10, "at most 10")
        T.eq(notes[1].t, "cffff0000Maur"); T.eq(notes[1].d, false); T.eq(notes[1].m, nil)
        T.eq(notes[2].t, "N1", "a note with only spaces is dropped")
        for _, bad in ipairs({ "x", 5, true, 0 / 0 }) do T.eq(#withNotes(Mock, bad).env.FarolDB.notes, 0) end
    end },

    { "English texts", function(T, Mock)
        local E = withNotes(Mock, { { t = "Shopping", x = "linen", d = true } }, { locale = "enUS" })
        E:slash("notes")
        T.eq(E:text(E.env.FarolNotes.title), "Notes (0/1 pending)")
        T.eq(E:text(E.env.FarolNoteNew), "+ New note"); T.eq(E:text(E.env.FarolNoteDoneButton), "Reopen")
        E:slash("notes list"); T.has(chat(E), "1. Shopping — done")
    end },
}
