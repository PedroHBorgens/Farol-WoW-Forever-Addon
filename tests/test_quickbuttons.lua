-- Botões rápidos ao lado da barra: histórico de avisos e saques.
-- Quick buttons next to the bar: warning history and loot.

local function loot(H, i)
    H:event("CHAT_MSG_LOOT", "Você recebe saque: |cff1eff00|Hitem:" .. (8000 + i) .. "|h[Erva " .. i .. "]|h|r.")
end

return {
    { "loot button sits next to the history button and opens the loot window", function(T, Mock)
        local H = Mock.new():login()
        local history, lootButton = H.env.FarolWarnHistoryButton, H.env.FarolLootButton
        T.ok(lootButton and lootButton:IsShown(), "loot button shown")
        T.eq(history._anchor, H.env.FarolFrame, "history button next to the bar")
        T.eq(lootButton._anchor, history, "loot button next to the history button")
        H:click(lootButton)
        T.ok(H.env.FarolLoot:IsShown(), "loot window open")
        H:click(lootButton)
        T.ok(not H.env.FarolLoot:IsShown(), "click again closes it")
    end },

    { "green counter shows items looted since the window was last opened", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login()
        local button = H.env.FarolLootButton
        T.eq(H:text(button.badge), "")
        loot(H, 1); loot(H, 2); loot(H, 3)
        T.eq(H:text(button.badge), "3")
        button._scripts.OnEnter(button)
        T.has(table.concat(H.env.GameTooltip.lines, " "), "3 new item(s)")
        H:click(button)
        T.eq(H:text(button.badge), "", "opening the window clears the counter")
        loot(H, 4)
        T.eq(H:text(button.badge), "", "window open: items are already seen")
    end },

    { "hiding one button moves the other next to the bar", function(T, Mock)
        local H = Mock.new():login()
        H:slash("aparencia botao") -- esconde o botão do histórico
        T.ok(not H.env.FarolWarnHistoryButton:IsShown())
        T.eq(H.env.FarolLootButton._anchor, H.env.FarolFrame, "loot button moves next to the bar")
        H:slash("aparencia botaosaques")
        T.ok(not H.env.FarolLootButton:IsShown(), "loot button hidden")
        T.eq(H.env.FarolDB.lootButton, false)
        H:slash("aparencia botao"); H:slash("aparencia botaosaques")
        T.eq(H.env.FarolLootButton._anchor, H.env.FarolWarnHistoryButton, "order restored")
    end },

    { "appearance window has the loot button option; restore defaults turns it back on", function(T, Mock)
        local H = Mock.new({ locale = "enUS" }):login({ lootButton = false })
        T.ok(not H.env.FarolLootButton or not H.env.FarolLootButton:IsShown(), "saved option respected")
        H:slash("appearance")
        T.eq(H:text(H.env.FarolApp_lootButton.label), "Show the loot button")
        H:click(H.env.FarolAppReset)
        T.eq(H.env.FarolDB.lootButton, true)
        T.ok(H.env.FarolLootButton:IsShown())
    end },
}
