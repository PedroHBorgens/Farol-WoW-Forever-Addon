--[[
  Simulador mínimo da API do World of Warcraft para testar o Farol fora do jogo.
  Minimal World of Warcraft API mock used to test Farol outside the game.

  Cada teste cria um ambiente isolado com Mock.new{ ... }:
    mode   = "forever" (padrão: cliente moderno do WoW Forever) | "wotlk" (3.3.5a, APIs antigas)
    locale = "ptBR" | "enUS" ...
    secret = true  -> simula "secret values" do Midnight (valores bloqueados pelo jogo)

  O addon é carregado nesse ambiente (setfenv no Lua 5.1), então nada vaza entre testes.
]]

local Mock = {}

local ADDON_DIR = "Farol/"
local ADDON_FILES = { "Core.lua", "Alarm.lua", "Loot.lua", "Warnings.lua", "Appearance.lua", "Order.lua" }

local function noop() end

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------

local Frame = {}

function Frame:SetScript(name, fn) self._scripts[name] = fn end
function Frame:GetScript(name) return self._scripts[name] end
function Frame:RegisterEvent(name) self._events[name] = true end
function Frame:UnregisterEvent(name) self._events[name] = nil end

function Frame:Show()
    if self._shown then return end
    self._shown = true
    if self._scripts.OnShow then self._scripts.OnShow(self) end
end
function Frame:Hide()
    if not self._shown then return end
    self._shown = false
    if self._scripts.OnHide then self._scripts.OnHide(self) end
end
function Frame:IsShown() return self._shown end
function Frame:IsVisible() return self._shown end

function Frame:SetSize(w, h) self._w, self._h = w, h end
function Frame:SetWidth(w) self._w = w end
function Frame:SetHeight(h) self._h = h end
function Frame:GetWidth() return self._w or 0 end
function Frame:GetHeight() return self._h or 0 end
function Frame:GetPoint() return "CENTER", nil, "CENTER", 12.3, -4.6 end
function Frame:GetFrameLevel() return 1 end

function Frame:SetText(text)
    self._text = text
    if self._fontString then self._fontString._text = text end
end
function Frame:GetText() return self._text end
function Frame:GetStringWidth() return 150 end
function Frame:SetTextColor(r, g, b) self._color = { r, g, b } end

function Frame:SetChecked(value) self._checked = value and true or false end
function Frame:GetChecked() return self._checked and 1 or nil end -- como o 3.3.5a: 1/nil
function Frame:LockHighlight() self._highlight = true end
function Frame:UnlockHighlight() self._highlight = false end
function Frame:HasFocus() return false end
function Frame:SetTexture(texture) self._texture = texture end
function Frame:SetScale(scale) self._scale = scale end
-- Camadas: Raise() registra a ordem em que a janela veio para a frente (maior = mais na frente).
local raiseCounter = 0
function Frame:Raise() raiseCounter = raiseCounter + 1; self._raisedAt = raiseCounter end
function Frame:SetToplevel(value) self._toplevel = value end
function Frame:Enable() self._disabled = false end
function Frame:Disable() self._disabled = true end
function Frame:HookScript(name, fn)
    local original = self._scripts[name]
    self._scripts[name] = function(...)
        if original then original(...) end
        fn(...)
    end
end
function Frame:SetPoint(point, relativeTo, relativePoint, x, y)
    self._anchor = type(relativeTo) == "table" and relativeTo or nil
    self._anchorPoint = point
    self._x, self._y = x, y
end
function Frame:GetStringHeight() return self._stringHeight end -- os testes podem definir
function Frame:ClearAllPoints() self._anchor = nil end
function Frame:GetScale() return self._scale or 1 end
function Frame:SetBackdropColor(r, g, b, a) self._bgAlpha = a end
function Frame:SetBackdropBorderColor(r, g, b, a) self._borderAlpha = a end
function Frame:SetJustifyH(justify) self._justify = justify end
function Frame:GetFont() return self._fontPath or "Fonts\\FRIZQT__.TTF", self._fontSize or 10, "" end
function Frame:SetFont(path, size) self._fontPath, self._fontSize = path, size end

local function NewObject(env, kind, name)
    local object = { _scripts = {}, _events = {}, _kind = kind, _name = name, _shown = true, _env = env }
    return setmetatable(object, {
        __index = function(_, key)
            local method = Frame[key]
            if method then return method end
            -- Outros métodos do WoW (SetPoint, SetBackdrop...) viram no-op; campos comuns ficam nil.
            if type(key) == "string" and string.match(key, "^%u") then return noop end
            return nil
        end,
    })
end

function Frame:CreateFontString()
    local fs = NewObject(self._env, "FontString")
    self._fontStrings = self._fontStrings or {}
    table.insert(self._fontStrings, fs)
    return fs
end
function Frame:CreateTexture() return NewObject(self._env, "Texture") end
function Frame:GetFontString()
    self._fontString = self._fontString or NewObject(self._env, "FontString")
    return self._fontString
end

---------------------------------------------------------------------------
-- Ambiente
---------------------------------------------------------------------------

function Mock.new(opts)
    opts = opts or {}
    local mode = opts.mode or "forever"
    local env = setmetatable({}, { __index = _G })
    env._G = env

    local H = { env = env, msgs = {}, frames = {}, now = 1000, clock = { hour = 7, min = 29 },
                dailyReset = 5 * 3600 + 12 * 60, weeklyReset = 2 * 86400 + 4 * 3600,
                -- Profissões: { nome, nível, máximo do treinamento, principal? }
                profs = { { "Mineração", 148, 150, true }, { "Herborismo", 92, 150, true }, { "Culinária", 60, 75, false } } }

    -- Chat e frames
    env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) table.insert(H.msgs, msg) end }
    env.UIParent = NewObject(env, "Frame", "UIParent")
    env.CreateFrame = function(kind, name, parent, template)
        local frame = NewObject(env, kind, name)
        frame._template = template
        table.insert(H.frames, frame)
        if name then env[name] = frame end
        return frame
    end
    env.UISpecialFrames = {}
    env.tinsert = table.insert
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.SlashCmdList = {}
    env.InCombatLockdown = function() return H.inCombat or false end
    env.IsInInstance = function()
        if H.instanceType then return true, H.instanceType end
        return false, "none"
    end
    env.GetLocale = function() return opts.locale or "ptBR" end

    -- Tooltip
    local tooltip = { lines = {} }
    function tooltip:SetOwner(owner) self.owner = owner end
    function tooltip:ClearLines() self.lines = {} end
    function tooltip:AddLine(text) table.insert(self.lines, text) end
    function tooltip:AddDoubleLine(a, b) table.insert(self.lines, a .. " = " .. b) end
    function tooltip:SetHyperlink(link) self.link = link end
    function tooltip:Show() self.shown = true end
    function tooltip:Hide() self.shown = false end
    function tooltip:IsShown() return self.shown end
    function tooltip:IsOwned(frame) return self.owner == frame end
    env.GameTooltip = tooltip

    -- Tempo
    env.GetTime = function() return H.now end
    env.time = os.time
    env.date = function(fmt, t)
        if fmt == "*t" then return { hour = H.clock.hour, min = H.clock.min } end
        return os.date(fmt, t)
    end
    env.GetGameTime = function() return 21, 5 end

    -- Personagem e mundo
    env.GetFramerate = function() return 60.2 end
    env.GetMoney = function() return H.money or 1234567 end
    env.GetRealZoneText = function() return "Floresta de Elwynn" end
    env.GetSubZoneText = function() return "Vale Norte" end
    H.durability = { [1] = { 50, 100 }, [5] = { 15, 100 }, [16] = { 100, 100 } }
    env.GetInventoryItemDurability = function(slot)
        local d = H.durability[slot]
        if d then return d[1], d[2] end
    end
    env.GetInventoryItemLink = function(_, slot) if slot == 1 then return "[Elmo]" end end
    env.GetUnitSpeed = function() return 0, 7 end
    env.NUM_BAG_SLOTS = 4
    H.xp = { cur = 6200, max = 10000, level = 30, rested = 1500 } -- os testes podem alterar
    env.UnitXP = function() return H.xp.cur end
    env.UnitXPMax = function() return H.xp.max end
    env.GetXPExhaustion = function() return H.xp.rested end
    env.UnitLevel = function() return H.xp.level end
    env.GetMaxPlayerLevel = function() return 60 end
    env.BNGetNumFriends = function() return 10, 5 end
    env.IsInGuild = function() return true end
    H.rosterRequests = 0

    -- Sons e itens
    -- Sons: H.sounds conta o som do alarme (aviso de raide); H.warnSounds conta o dos avisos.
    H.sounds, H.warnSounds = 0, 0
    env.PlaySound = function(sound)
        if sound == 8959 or sound == "RaidWarning" then
            H.sounds = H.sounds + 1
        else
            H.warnSounds = H.warnSounds + 1
        end
    end
    env.UIErrorsFrame = { AddMessage = function(_, text) H.screen = text end }
    H.bagFree = { [0] = 2, 1, 1, 1, 1 } -- espaços livres por bolsa (total 6 de 80)

    -- Reputação: H.faction = { name, reaction, min, max, value, id } ou nil (nenhuma facção acompanhada)
    local standings = { "Odiado", "Hostil", "Inamistoso", "Neutro", "Amistoso", "Honrado", "Reverenciado", "Exaltado" }
    for i = 1, 8 do env["FACTION_STANDING_LABEL" .. i] = standings[i] end
    env.FACTION_BAR_COLORS = {}
    for i = 1, 8 do env.FACTION_BAR_COLORS[i] = { r = 0, g = 0.6, b = 0.1 } end

    -- Talentos, grimório e barras de ação (os testes podem alterar)
    H.talentPoints = 0
    H.spells = { [133] = { "Bola de Fogo", 1 }, [143] = { "Bola de Fogo", 2 }, [145] = { "Bola de Fogo", 3 },
                 [116] = { "Seta de Gelo", 1 }, [118] = { "Polimorfia", nil } }
    H.book = { 133, 143, 145, 116, 118 }  -- magias conhecidas
    H.actions = {}                         -- [espaço] = { "spell", id }
    env.HasAction = function(slot) return H.actions[slot] ~= nil end
    env.GetActionInfo = function(slot)
        local action = H.actions[slot]
        if action then return action[1], action[2] end
    end
    local function rankText(id, word)
        local spell = H.spells[id]
        return spell and spell[2] and (word .. " " .. spell[2]) or ""
    end
    env.LOOT_ITEM_SELF = "Você recebe saque: %s."
    env.LOOT_ITEM_SELF_MULTIPLE = "Você recebe saque: %sx%d."
    env.LOOT_ITEM_PUSHED_SELF = "Você recebe o item: %s."
    env.LOOT_ITEM_PUSHED_SELF_MULTIPLE = "Você recebe o item: %sx%d."
    local qualityNames = { "Inferior", "Comum", "Incomum", "Raro", "Épico", "Lendário", "Artefato", "Herança" }
    for i = 0, 7 do env["ITEM_QUALITY" .. i .. "_DESC"] = qualityNames[i + 1] end
    env.GetItemQualityColor = function() return 1, 0.5, 0 end
    H.itemQuality = { [19019] = 5, [2589] = 1 }
    env.HandleModifiedItemClick = function(link) H.clickedLink = link end

    if mode == "wotlk" then
        -- Cliente 3.3.5a: APIs antigas, sem C_* modernos.
        env.GetBuildInfo = function() return "3.3.5", "12340", "Jun 24 2010" end
        env.GetNetStats = function() return 1, 2, 87 end
        env.GetPlayerMapPosition = function() return 0.453, 0.611 end
        env.SetMapToCurrentZone = noop
        env.GetContainerNumSlots = function(bag) return bag <= 4 and 16 or 0 end
        env.GetContainerNumFreeSlots = function(bag) return H.bagFree[bag] or 0, 0 end
        env.GetItemInfo = function(link)
            local id = tonumber(string.match(link, "Hitem:(%d+)"))
            return "item", link, H.itemQuality[id]
        end
        env.GetItemIcon = function(id) return "icon" .. id end
        env.GetNumFriends = function() return 7, 3 end
        env.GetNumGuildMembers = function() return 3 end
        env.GetGuildRosterInfo = function(i) return nil, nil, nil, nil, nil, nil, nil, nil, i ~= 2 end
        env.GuildRoster = function() H.rosterRequests = H.rosterRequests + 1 end
        env.InterfaceOptions_AddCategory = function(panel) H.settingsPanel = panel end
        env.UnitCharacterPoints = function() return H.talentPoints, 0 end
        env.GetQuestResetTime = function() return H.dailyReset end -- 3.3.5a: só o diário
        -- 3.3.5a: lista de perícias com cabeçalhos; profissões principais podem ser abandonadas.
        env.GetNumSkillLines = function()
            H.skillLines = { { "Habilidades de classe", true }, { "Defesa", false, 290, 300, false } ,
                             { "Profissões", true } }
            for _, p in ipairs(H.profs) do if p[4] then table.insert(H.skillLines, { p[1], false, p[2], p[3], true }) end end
            table.insert(H.skillLines, { "Profissões secundárias", true })
            for _, p in ipairs(H.profs) do if not p[4] then table.insert(H.skillLines, { p[1], false, p[2], p[3], false }) end end
            table.insert(H.skillLines, { "Armas", true })
            table.insert(H.skillLines, { "Espadas", false, 150, 150, false })
            return #H.skillLines
        end
        env.GetSkillLineInfo = function(i)
            local line = H.skillLines[i]
            if not line then return nil end
            -- nome, cabeçalho?, expandido?, nível, temp, modificador, máximo, abandonável?
            return line[1], line[2], true, line[3] or 0, 0, 0, line[4] or 0, line[5] or false
        end
        env.GetWatchedFactionInfo = function()
            local f = H.faction
            if f then return f.name, f.reaction, f.min, f.max, f.value, f.id end
        end
        env.GetSpellInfo = function(id)
            local spell = H.spells[id]
            if spell then return spell[1], rankText(id, "Rank") end
        end
        env.BOOKTYPE_SPELL = "spell"
        env.GetNumSpellTabs = function() return 1 end
        env.GetSpellTabInfo = function() return "Geral", nil, 0, #H.book end
        env.GetSpellName = function(index)
            local id = H.book[index]
            local spell = H.spells[id]
            if spell then return spell[1], rankText(id, "Rank") end
        end
    else
        -- Cliente moderno (WoW Forever / Midnight).
        env.GetBuildInfo = function() return "1.60.1", "70862", "Nov 6 2026", 16001 end
        env.GetNetStats = function() return 1, 2, 40, 60 end
        env.BackdropTemplateMixin = {}
        env.SOUNDKIT = { RAID_WARNING = 8959, READY_CHECK = 8960 }
        env.C_Map = {
            GetBestMapForUnit = function() return 1 end,
            GetPlayerMapPosition = function()
                return { GetXY = function() return 0.45, 0.61 end }
            end,
        }
        env.C_Container = {
            GetContainerNumSlots = function(bag) return bag <= 4 and 16 or 0 end,
            GetContainerNumFreeSlots = function(bag) return H.bagFree[bag] or 0, 0 end,
        }
        env.C_Item = {
            GetItemQualityByID = function(link)
                return H.itemQuality[tonumber(string.match(link, "Hitem:(%d+)"))]
            end,
            GetItemIconByID = function(id) return "icon" .. id end,
        }
        env.C_FriendList = { GetNumOnlineFriends = function() return 3 end }
        env.GetNumGuildMembers = function() return 80, 12 end
        env.C_GuildInfo = { GuildRoster = function() H.rosterRequests = H.rosterRequests + 1 end }
        env.Settings = {
            RegisterCanvasLayoutCategory = function(panel, name)
                H.settingsPanel = panel
                return { name = name }
            end,
            RegisterAddOnCategory = function(category) H.settingsCategory = category end,
        }
        env.GetUnspentTalentPoints = function() return H.talentPoints end
        -- Resets: H.dailyReset / H.weeklyReset em segundos (nil = o jogo não informa)
        -- Cliente moderno: índices das profissões (prof1, prof2, arqueologia, pesca, culinária, primeiros socorros).
        env.GetProfessions = function()
            local primary, secondary = {}, {}
            for i, p in ipairs(H.profs) do if p[4] then primary[#primary + 1] = i else secondary[#secondary + 1] = i end end
            return primary[1], primary[2], nil, nil, secondary[1], secondary[2]
        end
        env.GetProfessionInfo = function(index)
            local p = H.profs[index]
            if not p then return nil end
            return p[1], 136248, p[2], p[3]
        end
        env.C_DateAndTime = {
            GetSecondsUntilDailyReset = function() return H.dailyReset end,
            GetSecondsUntilWeeklyReset = function() return H.weeklyReset end,
        }
        env.C_Reputation = {
            GetWatchedFactionData = function()
                local f = H.faction
                if not f then return nil end
                return { name = f.name, reaction = f.reaction, currentReactionThreshold = f.min,
                         nextReactionThreshold = f.max, currentStanding = f.value, factionID = f.id }
            end,
        }
        env.Enum = { SpellBookSpellBank = { Player = 0 } }
        env.C_Spell = {
            GetSpellName = function(id) local spell = H.spells[id]; return spell and spell[1] end,
            GetSpellSubtext = function(id) return rankText(id, "Grau") end,
        }
        env.C_SpellBook = {
            GetNumSpellBookSkillLines = function() return 1 end,
            GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #H.book } end,
            GetSpellBookItemInfo = function(index)
                local id = H.book[index]
                local spell = H.spells[id]
                if spell then return { spellID = id, name = spell[1], subName = rankText(id, "Grau") } end
            end,
        }
    end

    if opts.secret then
        -- Simula valores bloqueados: o número 15 (durabilidade) é "secreto" e a zona dá erro.
        env.issecretvalue = function(v) return v == 15 end
        env.GetRealZoneText = function() error("blocked by the game") end
    end

    ---------------------------------------------------------------------------
    -- Ajudantes para os testes
    ---------------------------------------------------------------------------

    function H:load()
        local ns = {}
        for _, file in ipairs(ADDON_FILES) do
            local chunk, err
            if setfenv then
                chunk, err = loadfile(ADDON_DIR .. file)
                if chunk then setfenv(chunk, env) end
            else
                chunk, err = loadfile(ADDON_DIR .. file, "t", env)
            end
            assert(chunk, err)
            chunk("Farol", ns)
        end
        self.ns = ns
        return self
    end

    function H:event(name, ...)
        for _, frame in ipairs(self.frames) do
            if frame._events[name] and frame._scripts.OnEvent then
                frame._scripts.OnEvent(frame, name, ...)
            end
        end
    end

    -- Carrega o addon e simula a entrada no mundo.
    function H:login(savedDB, savedCharDB)
        env.FarolDB = savedDB
        env.FarolCharDB = savedCharDB
        self:load()
        self:event("ADDON_LOADED", "Farol")
        self:event("PLAYER_ENTERING_WORLD")
        return self
    end

    -- Avança o relógio e roda OnUpdate dos frames visíveis (como o jogo faz).
    function H:update(seconds)
        self.now = self.now + seconds
        for _, frame in ipairs(self.frames) do
            if frame._shown and frame._scripts.OnUpdate then
                frame._scripts.OnUpdate(frame, seconds)
            end
        end
    end

    function H:slash(text) env.SlashCmdList.FAROL(text) end

    -- Mostra o texto como o chat do WoW: tira códigos de cor/ícone/link e "||" vira "|".
    function H.strip(text)
        text = tostring(text or "")
        text = string.gsub(text, "||", "\1")
        text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
        text = string.gsub(text, "|cnIQ%d:", "")
        text = string.gsub(text, "|r", "")
        text = string.gsub(text, "|T[^|]*|t", "")
        text = string.gsub(text, "|Hitem:[^|]*|h", "")
        text = string.gsub(text, "|h", "")
        text = string.gsub(text, "\1", "|")
        return text
    end

    -- Células visíveis da barra, na ordem (cada informação é um texto próprio, numa grade).
    function H:cells()
        local list = {}
        for _, fs in ipairs(env.FarolFrame._fontStrings) do
            if fs.farolCell and fs:IsShown() then list[#list + 1] = fs end
        end
        table.sort(list, function(a, b) return a.farolCell < b.farolCell end)
        return list
    end
    -- Texto da barra com códigos (ícones, cores), células separadas por "   ".
    function H:barRaw()
        local texts = {}
        for _, cell in ipairs(self:cells()) do texts[#texts + 1] = cell._text or "" end
        return table.concat(texts, "   ")
    end
    function H:bar() return H.strip(self:barRaw()) end
    function H:lastMsg() return H.strip(self.msgs[#self.msgs]) end
    function H:click(button, mouse) button._scripts.OnClick(button, mouse or "LeftButton") end
    function H:check(checkButton, value)
        checkButton._checked = value
        self:click(checkButton)
    end
    function H:text(object) return H.strip(object._text) end

    -- Frames por tipo, na ordem de criação.
    function H:framesOf(kind)
        local list = {}
        for _, frame in ipairs(self.frames) do
            if frame._kind == kind then table.insert(list, frame) end
        end
        return list
    end

    return H
end

return Mock
