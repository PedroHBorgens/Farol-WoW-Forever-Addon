--[[
  WoW Forever Info
  Painel na tela com FPS, latência, coordenadas e ouro.
  On-screen panel with FPS, latency, coordinates and gold. (PT / EN)

  Princípios de segurança deste addon:
    * Não usa loadstring/RunScript nem executa código vindo de chat, arquivos ou outros jogadores.
    * Não envia nem recebe mensagens de addon (SendAddonMessage) — nenhum dado sai do seu cliente.
    * Não automatiza ações de jogo (nada de bot); apenas LÊ informações e as mostra.
    * Só grava a posição/estado do painel em SavedVariables, e valida esses dados ao carregar.
]]

local ADDON_NAME = ...
local PREFIX = "|cff33ccffWoW Forever Info|r: "
local UPDATE_INTERVAL = 0.5 -- segundos entre atualizações do painel

local DEFAULTS = {
    shown = true,
    locked = false,
    point = "TOP",
    relPoint = "TOP",
    x = 0,
    y = -20,
    lang = "auto", -- "auto" (segue o idioma do cliente), "pt" ou "en"
}

local VALID_LANGS = { auto = true, pt = true, en = true }

---------------------------------------------------------------------------
-- Textos / Strings (Português e English)
---------------------------------------------------------------------------

local STRINGS = {
    pt = {
        help_title   = "comandos:",
        help_toggle  = "  /wfi               - mostrar/ocultar o painel",
        help_lock    = "  /wfi lock          - travar/destravar o painel (arraste com o botão esquerdo)",
        help_reset   = "  /wfi reset         - voltar o painel à posição padrão",
        help_version = "  /wfi version       - mostrar a versão do cliente e o número de Interface",
        help_lang    = "  /wfi lang pt|en|auto - escolher o idioma (auto = idioma do cliente)",
        shown        = "painel visível.",
        hidden       = "painel oculto.",
        locked       = "painel travado.",
        unlocked     = "painel destravado — arraste para mover.",
        reset        = "posição restaurada.",
        version      = "cliente %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use esse número na linha '## Interface:' do arquivo .toc.",
        lang_set     = "idioma: Português.",
        lang_auto    = "idioma: automático (segue o cliente).",
        lang_usage   = "uso: /wfi lang pt | en | auto",
    },
    en = {
        help_title   = "commands:",
        help_toggle  = "  /wfi               - show/hide the panel",
        help_lock    = "  /wfi lock          - lock/unlock the panel (drag with left mouse button)",
        help_reset   = "  /wfi reset         - move the panel back to its default position",
        help_version = "  /wfi version       - show the client version and Interface number",
        help_lang    = "  /wfi lang pt|en|auto - choose the language (auto = client language)",
        shown        = "panel shown.",
        hidden       = "panel hidden.",
        locked       = "panel locked.",
        unlocked     = "panel unlocked — drag to move.",
        reset        = "position restored.",
        version      = "client %s (build %s, %s) — Interface: |cffffff00%s|r",
        version_hint = "use this number on the '## Interface:' line of the .toc file.",
        lang_set     = "language: English.",
        lang_auto    = "language: automatic (follows the client).",
        lang_usage   = "usage: /wfi lang pt | en | auto",
    },
}

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local db -- configurações validadas (preenchida em ADDON_LOADED)

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

-- Idioma ativo: escolha do usuário, ou o idioma do cliente quando "auto".
local function CurrentLang()
    local lang = db and db.lang or "auto"
    if lang == "auto" then
        local locale = GetLocale and GetLocale() or "enUS"
        return (locale == "ptBR" or locale == "ptPT") and "pt" or "en"
    end
    return lang
end

-- Busca um texto traduzido; cai para inglês se faltar.
local function T(key)
    local lang = STRINGS[CurrentLang()] or STRINGS.en
    return lang[key] or STRINGS.en[key] or key
end

-- Garante que SavedVariables tenham só os tipos/valores esperados.
-- Um arquivo corrompido ou editado à mão nunca quebra o addon.
local function SanitizeDB(saved)
    local clean = {}
    if type(saved) ~= "table" then saved = {} end

    for key, default in pairs(DEFAULTS) do
        local value = saved[key]
        if type(value) ~= type(default) then
            value = default
        end
        clean[key] = value
    end

    if not VALID_POINTS[clean.point] then clean.point = DEFAULTS.point end
    if not VALID_POINTS[clean.relPoint] then clean.relPoint = DEFAULTS.relPoint end
    if not VALID_LANGS[clean.lang] then clean.lang = DEFAULTS.lang end

    -- Limita deslocamentos a valores razoáveis.
    local limit = 5000
    if clean.x ~= clean.x or clean.x > limit or clean.x < -limit then clean.x = DEFAULTS.x end
    if clean.y ~= clean.y or clean.y > limit or clean.y < -limit then clean.y = DEFAULTS.y end

    return clean
end

local function FormatMoney(copper)
    copper = tonumber(copper) or 0
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    return string.format("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", gold, silver, cop)
end

local function ColorByValue(value, good, ok)
    -- verde se bom, amarelo se médio, vermelho se ruim
    if value <= good then return "|cff00ff00" end
    if value <= ok then return "|cffffff00" end
    return "|cffff3333"
end

---------------------------------------------------------------------------
-- Leitura de dados compatível com várias versões do cliente
---------------------------------------------------------------------------

local function GetLatency()
    -- 3.3.5a retorna (entrada, saída, latência); Classic/Retail retornam também latencyWorld.
    local _, _, home, world = GetNetStats()
    home = tonumber(home) or 0
    world = tonumber(world) or 0
    return math.max(home, world)
end

local function GetCoordsRaw()
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        -- Classic / Retail
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                local x, y = pos:GetXY()
                if x and y and (x > 0 or y > 0) then return x, y end
            end
        end
    elseif GetPlayerMapPosition then
        -- 3.3.5a e anteriores
        local x, y = GetPlayerMapPosition("player")
        if x and y and (x > 0 or y > 0) then return x, y end
    end
    return nil -- instâncias e alguns mapas não informam posição
end

-- WoW Forever / Midnight podem marcar valores como "secretos" (secret values) em certas situações;
-- nesse caso não podemos fazer contas com eles. Qualquer bloqueio vira "sem coordenadas", nunca um erro.
local function IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

local function GetCoords()
    local ok, x, y = pcall(GetCoordsRaw)
    if not ok or IsSecret(x) or IsSecret(y) then return nil end
    return x, y
end

-- No 3.3.5a as coordenadas dependem do mapa "ativo"; ao trocar de zona,
-- voltamos o mapa para a zona atual (sem mexer se o jogador estiver com o mapa aberto).
local function ResetMapToCurrentZone()
    if SetMapToCurrentZone and not (C_Map and C_Map.GetBestMapForUnit) then
        if not (WorldMapFrame and WorldMapFrame:IsShown()) then
            SetMapToCurrentZone()
        end
    end
end

---------------------------------------------------------------------------
-- Painel
---------------------------------------------------------------------------

-- Retail exige o template "BackdropTemplate" para usar SetBackdrop; clientes antigos não o possuem.
local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil

local frame = CreateFrame("Frame", "WoWForeverInfoFrame", UIParent, backdropTemplate)
frame:SetSize(330, 26)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

if frame.SetBackdrop then
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
end

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("CENTER")
text:SetText("...")

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    db.point, db.relPoint = point, relPoint
    db.x, db.y = math.floor(x + 0.5), math.floor(y + 0.5)
    WoWForeverInfoDB = db
end

local function ApplyPosition()
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

frame:SetScript("OnDragStart", function(self)
    if db and not db.locked and not InCombatLockdown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then SavePosition() end
end)

local function UpdateText()
    local fps = math.floor((GetFramerate() or 0) + 0.5)
    local ms = GetLatency()

    local coords
    local x, y = GetCoords()
    if x then
        coords = string.format("%.1f, %.1f", x * 100, y * 100)
    else
        coords = "--, --"
    end

    -- FPS: quanto maior melhor, então invertemos a lógica de cor.
    local fpsColor = (fps >= 50 and "|cff00ff00") or (fps >= 25 and "|cffffff00") or "|cffff3333"

    text:SetText(string.format("%s%d|r fps   %s%d|r ms   %s   %s",
        fpsColor, fps,
        ColorByValue(ms, 100, 250), ms,
        coords,
        FormatMoney(GetMoney())))

    frame:SetWidth(math.max(200, text:GetStringWidth() + 20))
end

local elapsedSinceUpdate = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate >= UPDATE_INTERVAL then
        elapsedSinceUpdate = 0
        UpdateText()
    end
end)

local function ApplyVisibility()
    if db.shown then frame:Show() else frame:Hide() end
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        db = SanitizeDB(WoWForeverInfoDB)
        WoWForeverInfoDB = db
        ApplyPosition()
        ApplyVisibility()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        ResetMapToCurrentZone()
        if db then UpdateText() end
    end
end)

---------------------------------------------------------------------------
-- Comandos: /wfi
---------------------------------------------------------------------------

local function ShowHelp()
    Print(T("help_title"))
    Print(T("help_toggle"))
    Print(T("help_lock"))
    Print(T("help_reset"))
    Print(T("help_version"))
    Print(T("help_lang"))
end

SLASH_WOWFOREVERINFO1 = "/wfi"
SLASH_WOWFOREVERINFO2 = "/wfinfo"
SlashCmdList["WOWFOREVERINFO"] = function(msg)
    if not db then return end
    -- Aceita só palavras simples (letras); qualquer outra coisa mostra a ajuda.
    local cmd, arg = string.match(msg or "", "^%s*(%a*)%s*(%a*)")
    cmd, arg = string.lower(cmd or ""), string.lower(arg or "")

    if cmd == "" then
        db.shown = not db.shown
        ApplyVisibility()
        Print(db.shown and T("shown") or T("hidden"))
    elseif cmd == "lock" then
        db.locked = not db.locked
        Print(db.locked and T("locked") or T("unlocked"))
    elseif cmd == "reset" then
        db.point, db.relPoint, db.x, db.y = DEFAULTS.point, DEFAULTS.relPoint, DEFAULTS.x, DEFAULTS.y
        ApplyPosition()
        Print(T("reset"))
    elseif cmd == "lang" or cmd == "idioma" then
        if VALID_LANGS[arg] then
            db.lang = arg
            Print(arg == "auto" and T("lang_auto") or T("lang_set"))
        else
            Print(T("lang_usage"))
        end
    elseif cmd == "version" or cmd == "versao" then
        local version, build, date, interface = GetBuildInfo()
        -- Clientes muito antigos não retornam o 4º valor; deduzimos pela versão.
        if not interface and type(version) == "string" then
            local major, minor = string.match(version, "^(%d+)%.(%d+)")
            if major then interface = string.format("%d%02d00", tonumber(major), tonumber(minor)) end
        end
        Print(string.format(T("version"),
            tostring(version), tostring(build), tostring(date), tostring(interface)))
        Print(T("version_hint"))
    else
        ShowHelp()
    end
end
