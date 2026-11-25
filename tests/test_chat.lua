-- Janela de chat das mensagens do Farol (3.20): chat principal por padrão; uma aba que o jogador criou; volta ao
-- principal se a aba sumir; o Farol nunca cria nem configura abas; nome salvo validado.
-- Chat window for Farol messages: main chat by default, a tab the player made, fallback, validated saved name.

local function all(list) return table.concat(list or {}, "\n") end

local function withFarolTab(Mock, opts)
    local H = Mock.new(opts or { locale = "ptBR" })
    H.chatWindows[3] = { "Farol", docked = true }
    return H
end

return {
    { "only Core's Print writes to the chat (modules use ns.Print)", function(T)
        for _, file in ipairs({ "Alarm", "Loot", "Warnings", "Appearance", "Order", "Tasks", "Notes", "Goals", "Farm", "Quests",
                                "Hearth", "Runs", "Completed", "Sources", "Diag", "MinimapButton" }) do
            local f = assert(io.open("Farol/" .. file .. ".lua", "r")); local text = f:read("*a"); f:close()
            text = string.gsub(text, "%-%-[^\n]*", "")
            T.ok(not string.find(text, "DEFAULT_CHAT_FRAME", 1, true), file .. ": use ns.Print")
            T.ok(not string.find(text, "ChatFrame%d"), file .. ": use ns.Print")
        end
    end },

    { "default: main chat; /farol chat lists the player's chat windows", function(T, Mock)
        local H = Mock.new({ locale = "ptBR" }); H:login()
        T.eq(H.env.FarolDB.chatWindow, "")
        H:slash("chat")
        T.has(H:lastMsg(), "mensagens do Farol em: Chat principal (padrão). Janelas de chat: Geral, Registro de combate.")
        T.eq(H.chatMsgs[2], nil, "nothing written anywhere else")
    end },

    { "a 'Farol' tab made by the player receives every message; saved; survives reload", function(T, Mock)
        local H = withFarolTab(Mock); H:login()
        local before = #H.msgs
        H:slash("chat farol")
        T.has(H.strip(H.chatMsgs[3][1]), "mensagens do Farol agora em: Farol.")
        T.eq(H.env.FarolDB.chatWindow, "Farol")
        H:slash("diagnostico"); H:slash("ouro"); H:slash("resumo")
        T.eq(#H.msgs, before, "the main chat got nothing new")
        T.has(H.strip(all(H.chatMsgs[3])), "Diagnóstico (só leitura")
        -- Recarregar: a escolha continua.
        local B = withFarolTab(Mock); B:login(H.env.FarolDB, H.env.FarolCharDB)
        B:slash("diag"); T.has(B.strip(all(B.chatMsgs[3])), "Diagnóstico")
    end },

    { "the tab disappeared or was renamed: messages go to the main chat (never lost); back when it returns", function(T, Mock)
        local H = withFarolTab(Mock); H:login({ chatWindow = "Farol" })
        H.chatWindows[3] = nil
        H:slash("chat")
        T.has(H:lastMsg(), "a janela de chat \"Farol\" não existe agora: as mensagens vão para o chat principal.")
        T.has(H.strip(all(H.msgs)), "mensagens do Farol em: Farol (não encontrada).")
        H.chatWindows[3] = { "Farol", shown = true }
        H.msgs = {}; H:slash("diag"); T.eq(#H.msgs, 0); T.has(H.strip(all(H.chatMsgs[3])), "Diagnóstico")
        -- A aba existe mas dá erro ao escrever: o chat principal recebe.
        H.env.ChatFrame3.AddMessage = function() error("broken") end
        H:slash("diag"); T.has(H.strip(all(H.msgs)), "Diagnóstico")
    end },

    { "unknown name, back to main, choosing the main window itself; Farol never creates or renames tabs", function(T, Mock)
        local H = withFarolTab(Mock); H:login()
        H:slash("chat Comercio"); T.has(H:lastMsg(), "janela de chat não encontrada: Comercio. Crie uma aba com esse nome")
        T.eq(H.env.FarolDB.chatWindow, "")
        H:slash("chat Farol"); H:slash("chat principal")
        T.eq(H.env.FarolDB.chatWindow, ""); T.has(H:lastMsg(), "mensagens do Farol agora no chat principal.")
        H:slash("chat geral"); T.eq(H.env.FarolDB.chatWindow, "", "window 1 is the main chat")
        T.eq(#H.chatWindows, 3, "no tab created")
    end },

    { "menu: 'Farol messages in' dropdown (General tab) lists the windows and switches; both menus in sync", function(T, Mock)
        local H = withFarolTab(Mock); H:login()
        H:slash("menu"); local set = H.env.FarolOptions.controls
        T.eq(H:text(set.chatLabel), "Mensagens do Farol em:")
        T.eq(H:text(set.chat), "Chat principal (padrão)")
        H:click(set.chat)
        local list = set.chat._name .. "List"
        T.eq(H:text(H.env[set.chat._name .. "Entry1"].text), "Chat principal (padrão)")
        T.eq(H:text(H.env[set.chat._name .. "Entry2"].text), "Registro de combate")
        T.eq(H:text(H.env[set.chat._name .. "Entry3"].text), "Farol")
        T.eq(H:text(H.env[set.chat._name .. "Entry4"].text), "(nova aba: clique direito no chat)")
        H:click(H.env[set.chat._name .. "Entry3"])
        T.eq(H.env.FarolDB.chatWindow, "Farol"); T.eq(H:text(set.chat), "Farol")
        T.ok(H.env[list], "list exists")
        T.eq(H:text(H.env.FarolChatWindow1), "Farol", "settings panel synced")
        H:click(H.env[set.chat._name .. "Entry4"]); T.eq(H.env.FarolDB.chatWindow, "Farol", "the hint does nothing")
    end },

    { "saved name is validated; English texts", function(T, Mock)
        for _, bad in ipairs({ 5, true, {}, "|cffff0000x", "a\nb", string.rep("x", 49), string.rep(" ", 5000) .. "x" }) do
            T.eq(Mock.new():login({ chatWindow = bad }).env.FarolDB.chatWindow, "", "bad chat name -> main chat")
        end
        T.eq(Mock.new():login({ chatWindow = "  Farol  " }).env.FarolDB.chatWindow, "Farol")
        local E = withFarolTab(Mock, { locale = "enUS" }); E:login()
        E:slash("chat nope"); T.has(E:lastMsg(), "chat window not found: nope. Create a tab with that name")
        E:slash("chat Farol"); T.has(E.strip(E.chatMsgs[3][1]), "Farol messages now in: Farol.")
        E:slash("chat main"); T.has(E:lastMsg(), "Farol messages now in the main chat.")
        -- Cliente sem GetChatWindowInfo: só o chat principal, sem erro.
        local O = Mock.new(); O.env.GetChatWindowInfo = nil; O:login({ chatWindow = "Farol" }); O:slash("diag")
        T.has(O.strip(all(O.msgs)), "Diagnóstico")
    end },
}
