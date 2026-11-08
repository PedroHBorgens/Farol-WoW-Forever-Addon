-- Arquivos .toc: versão consistente, Interface do WoW Forever e arquivos listados existentes.
-- .toc files: consistent version, WoW Forever Interface number and listed files present.

local TOCS = { "Farol.toc", "Farol_Mainline.toc", "Farol_Camelot.toc", "Farol_Vanilla.toc" }

local function read(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function field(content, name)
    return string.match(content, "\n## " .. name .. ": ([^\r\n]+)") or
           string.match(content, "^## " .. name .. ": ([^\r\n]+)")
end

return {
    { "all .toc files exist and share the same version and metadata", function(T)
        local version, title
        for _, toc in ipairs(TOCS) do
            local content = read("Farol/" .. toc)
            T.ok(content, toc .. " missing")
            local v = field(content, "Version")
            T.ok(v and string.match(v, "^%d+%.%d+%.%d+$"), toc .. " has an invalid version: " .. tostring(v))
            version = version or v
            T.eq(v, version, toc .. " version")
            title = title or field(content, "Title")
            T.eq(field(content, "Title"), "Farol", toc .. " title")
            T.eq(field(content, "SavedVariables"), "FarolDB", toc .. " SavedVariables")
            T.eq(field(content, "SavedVariablesPerCharacter"), "FarolCharDB", toc .. " per-character SavedVariables")
        end
    end },

    { "WoW Forever clients get Interface 16001", function(T)
        -- O WoW Forever lê o _Mainline.toc (ver README); o _Camelot é reserva.
        for _, toc in ipairs({ "Farol_Mainline.toc", "Farol_Camelot.toc", "Farol.toc" }) do
            T.has(field(read("Farol/" .. toc), "Interface"), "16001", toc)
        end
    end },

    { "every file listed in the .toc exists, and the icon is present", function(T)
        for _, toc in ipairs(TOCS) do
            local content = read("Farol/" .. toc)
            for line in string.gmatch(content, "[^\r\n]+") do
                if not string.match(line, "^#") and string.match(line, "%S") then
                    T.ok(read("Farol/" .. line), toc .. " lists a missing file: " .. line)
                end
            end
            T.eq(field(content, "IconTexture"), "Interface\\AddOns\\Farol\\Media\\Farol", toc .. " icon")
        end
        T.ok(read("Farol/Media/Farol.tga"), "icon file missing")
    end },

    { "addon code never uses automation, messaging or dynamic code APIs", function(T)
        -- Regra nº 1 do projeto: só ler e mostrar. Comentários são ignorados.
        local forbidden = {
            "SendAddonMessage", "SendChatMessage", "C_ChatInfo", "loadstring", "RunScript",
            "CastSpell", "UseAction", "RunMacro", "TargetUnit", "MoveForward", "JumpOrAscend",
            "SecureActionButton", "hooksecurefunc", "setfenv", "getfenv", "C_Timer", "DoEmote",
            "AcceptTrade", "PickupItem", "UseContainerItem", "BuyMerchant", "SellItem", "InviteUnit",
            "LootSlot", "ConfirmLootSlot", "RollOnLoot", "SetCVar", "RepairAllItems",
        }
        for _, file in ipairs({ "Core.lua", "Alarm.lua", "Loot.lua", "Warnings.lua" }) do
            local code = read("Farol/" .. file)
            code = string.gsub(code, "%-%-%[%[.-%]%]", "") -- comentários de bloco
            code = string.gsub(code, "%-%-[^\n]*", "")     -- comentários de linha
            for _, name in ipairs(forbidden) do
                T.hasnt(code, name, file .. " uses a forbidden API")
            end
        end
    end },
}
