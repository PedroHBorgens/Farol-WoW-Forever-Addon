-- Verificador de layout (3.31.2): mede as janelas como o jogo (larguras de texto medidas em prints do WoW Forever,
-- com folga) e aponta texto cortado, texto que sai do quadro/cartão/janela, botão pequeno para o texto e sobreposição.
-- Layout checker: measures windows like the game does and reports clipped text, text leaving its panel, etc.
-- Usado por tests/test_layout.lua. Install() troca métodos do simulador e devolve a função que desfaz a troca.
local LC = {}
local Mock = require("wow_mock")
local F = Mock.Frame
local CHAR = { GameFontHighlight = 6.9, GameFontNormal = 6.9, GameFontHighlightSmall = 5.65, GameFontDisableSmall = 5.65,
  GameFontNormalSmall = 5.65, GameFontDisable = 6.9, GameFontNormalLarge = 8.5, GameFontHighlightLarge = 8.5 }
local LINE = { GameFontHighlightSmall = 11, GameFontDisableSmall = 11, GameFontNormalSmall = 11, GameFontNormalLarge = 16 }
local BUTTON_CHAR = 7.4 -- média medida nos botões do print (6,9 a 8,5)
local function strip(t)
  t = tostring(t or "")
  t = t:gsub("||", "|"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T[^|]*|t", "MM"):gsub("|H[^|]*|h", ""):gsub("|h", "")
  return t
end
local function ulen(t) local n = 0 for _ in t:gmatch("[\1-\127\194-\244][\128-\191]*") do n = n + 1 end return n end
local SAFETY = 1.15 -- margem: no jogo (escala da interface, fonte do cliente) o texto sai um pouco mais largo
local SMALL = { GameFontHighlightSmall = true, GameFontDisableSmall = true, GameFontNormalSmall = true }
local function textW(fs) return ulen(strip(fs._text)) * (CHAR[fs._font] or 6.9) * (SMALL[fs._font] and 1 or SAFETY) end

local UIP
local ROOT
local function isTop(f) return f == ROOT or f._parent == nil or f._parent == UIP or f._top end
local rectCache
local function size(f)
  if f._kind == "FontString" then
    local w = textW(f)
    local h = LINE[f._font] or 13
    if f._w and f._w > 0 then
      local lines = (f._nowrap or f._maxLines == 1) and 1 or math.max(1, math.ceil(w / f._w)); return f._w, h * lines, w
    end
    return w, h, w
  end
  return f._w or 0, f._h or 0
end
local function pointXY(r, p)
  local l, t, w, h = r[1], r[2], r[3], r[4]
  local px = (p:find("LEFT") and l) or (p:find("RIGHT") and l + w) or l + w / 2
  local py = (p:find("TOP") and t) or (p:find("BOTTOM") and t - h) or t - h / 2
  return px, py
end
local rect
rect = function(f, depth)
  depth = (depth or 0) + 1
  if depth > 30 then return { 0, 0, 0, 0 } end
  if rectCache[f] then return rectCache[f] end
  local w, h = size(f)
  if isTop(f) or not f._pts or #f._pts == 0 then
    local r
    if isTop(f) then r = { 0, 0, w, h } else local pr = rect(f._parent, depth); r = { pr[1], pr[2], w, h } end
    rectCache[f] = r; return r
  end
  local pt = f._pts[1]
  local rel = pt.rel or f._parent
  local rr = rect(rel, depth)
  local ax, ay = pointXY(rr, pt.rp)
  ax, ay = ax + pt.x, ay + pt.y
  -- segundo ponto horizontal (ex.: TOPLEFT + RIGHT) define a largura
  if f._pts[2] then
    local p2 = f._pts[2]; local r2 = rect(p2.rel or f._parent, depth)
    local bx = pointXY(r2, p2.rp) + p2.x
    if p2.p:find("RIGHT") and (pt.p:find("LEFT")) then w = bx - ax end
  end
  local l = (pt.p:find("LEFT") and ax) or (pt.p:find("RIGHT") and ax - w) or ax - w / 2
  local t = (pt.p:find("TOP") and ay) or (pt.p:find("BOTTOM") and ay + h) or ay + h / 2
  local r = { l, t, w, h }
  rectCache[f] = r
  return r
end
local function visible(f)
  local n = f
  for _ = 1, 40 do
    if not n or n == UIP then return true end
    if n._shown == false then return false end
    n = n._parent
  end
  return true
end
local function top(f) local n = f for _ = 1, 40 do if n == ROOT then return n end if not n._parent or n._parent == UIP then return n end n = n._parent end return n end
local function label(f)
  return (f._name or f._kind) .. (f._text and (" '" .. strip(f._text):sub(1, 90) .. "'") or "")
end
local problems = {}
local function report(win, msg) problems[#problems + 1] = win .. ": " .. msg end
function LC.Check(H, winName, opts)
  opts = opts or {}
  UIP = H.env.UIParent
  local win = H.env[winName]
  if not win or not win:IsShown() then report(winName, "não aberta") return end
  ROOT = win
  rectCache = {}
  local W = opts.width or win._w or 0
  local elems = {}
  for _, f in ipairs(H.frames) do
    if top(f) == win and visible(f) and f ~= win then elems[#elems + 1] = f end
    if f._fontStrings then for _, fs in ipairs(f._fontStrings) do if top(fs) == win and visible(fs) and fs._text and strip(fs._text) ~= "" then elems[#elems + 1] = fs end end end
  end
  local boxes = {}
  for _, f in ipairs(elems) do
    local r = rect(f)
    if f._kind == "FontString" then
      local w, h, tw = size(f)
      if f._w and f._w > 0 and (f._nowrap or f._maxLines == 1) and tw > f._w + 2 then
        report(winName, string.format("texto cortado: %s (texto %.0f, espaço %.0f)", label(f), tw, f._w))
      end
      if (not f._w or f._w == 0) and r[1] + r[3] > W - 8 and W > 0 then
        report(winName, string.format("texto passa da borda: %s (termina em %.0f, janela %.0f)", label(f), r[1] + r[3], W))
      end
      boxes[#boxes + 1] = { f, r }
    elseif f._kind == "Button" or f._kind == "CheckButton" or f._kind == "EditBox" then
      if (f._w or 0) > 0 then
        if f._kind == "Button" and f._text and f._template == "UIPanelButtonTemplate" then
          local tw = ulen(strip(f._text)) * BUTTON_CHAR
          if tw > f._w - 6 then report(winName, string.format("texto não cabe no botão: %s (texto %.0f, botão %.0f)", label(f), tw, f._w)) end
        end
        if W > 0 and r[1] + r[3] > W - 6 then report(winName, string.format("controle passa da borda: %s (termina em %.0f)", label(f), r[1] + r[3])) end
        boxes[#boxes + 1] = { f, r }
      end
    end
  end
  -- Quadros da Central (Kit.Panel / Kit.Card): o texto que começa dentro de um quadro tem de terminar dentro dele.
  local panels = {}
  local function addPanel(name, bg)
    if bg and bg._shown ~= false and bg._pts and bg._pts[1] and (bg._w or 0) > 0 then
      local p = bg._pts[1]
      local base = rect(p.rel or bg._parent)
      local bx, by = pointXY(base, p.rp)
      panels[#panels + 1] = { name = name, l = bx + p.x, t = by + p.y, w = bg._w, h = bg._h or 0 }
    end
  end
  for key, p in pairs(win.farolPanels or {}) do if p.bg and not tostring(key):find("^text:") then addPanel(key, p.bg) end end
  for _, b in ipairs(boxes) do
    local f, r = b[1], b[2]
    if f._kind == "FontString" or f._kind == "Button" or f._kind == "EditBox" or f._kind == "CheckButton" then
      local w = r[3]
      if f._kind == "FontString" and f._w and f._w > 0 and not f._nowrap then local _, _, tw = size(f); w = math.min(f._w, tw) end
      if f._kind == "FontString" and (not f._w or f._w == 0) then local _, _, tw = size(f); w = tw end
      local par = f._parent
      if f._kind == "FontString" and par and par ~= win and par._kind == "Frame" and (par._w or 0) > 0 and par.title then
        local pr = rect(par)
        if r[1] + w > pr[1] + pr[3] + 1 then
          report(winName, string.format("sai do cartão: %s (termina em %.0f, cartão até %.0f)", label(f), r[1] + w, pr[1] + pr[3]))
        end
      end
      for _, p in ipairs(panels) do
        local inside = r[1] >= p.l - 1 and r[1] < p.l + p.w and r[2] <= p.t + 1 and r[2] > p.t - p.h
        if inside and r[1] + w > p.l + p.w + 1 then
          report(winName, string.format("sai do quadro %s: %s (termina em %.0f, quadro até %.0f)", p.name, label(f), r[1] + w, p.l + p.w))
        end
      end
    end
  end
  for i = 1, #boxes do for j = i + 1, #boxes do
    local a, b = boxes[i], boxes[j]
    local ra, rb = a[2], b[2]
    local fa, fb = a[1], b[1]
    local related = fa._parent == fb or fb._parent == fa or (fa._parent == fb._parent and fa._parent and fa._parent._kind ~= "Frame" and fa._parent ~= win)
    if not related then
      local ox = math.min(ra[1] + ra[3], rb[1] + rb[3]) - math.max(ra[1], rb[1])
      local oy = math.min(ra[2], rb[2]) - math.max(ra[2] - ra[4], rb[2] - rb[4])
      if ox > 2 and oy > 2 then report(winName, string.format("sobreposição: %s  X  %s (%.0fx%.0f)", label(fa), label(fb), ox, oy)) end
    end
  end end
end
-- Devolve os problemas achados desde a última chamada (e limpa a lista).
function LC.Take()
  local out = problems
  problems = {}
  return out
end
function LC.Dump(H, winName)
  UIP = H.env.UIParent
  local win = H.env[winName]
  if not win or not win:IsShown() then return nil end
  rectCache = {}
  local out = { w = win._w or 0, h = win._h or 0, items = {} }
  for _, f in ipairs(H.frames) do
    if top(f) == win and visible(f) and f ~= win then
      local r = rect(f)
      out.items[#out.items + 1] = { k = f._kind, t = f._text and strip(f._text) or "", l = r[1], y = r[2], w = r[3], h = r[4],
        c = f._checked and true or false, tpl = f._template or "", name = f._name or "" }
    end
    if f._fontStrings then for _, fs in ipairs(f._fontStrings) do
      if top(fs) == win and visible(fs) and fs._text and strip(fs._text) ~= "" then
        local r = rect(fs); local _, _, tw = size(fs)
        out.items[#out.items + 1] = { k = "FontString", t = strip(fs._text), l = r[1], y = r[2], w = (fs._w and fs._w > 0) and fs._w or tw, h = r[4],
          f = fs._font, col = fs._color }
      end
    end end
  end
  return out
end


-- Troca os métodos do simulador pelos que guardam posições/fonte (como o jogo). Devolve a função que desfaz.
function LC.Install()
    local saved = {}
    for _, k in ipairs({ "CreateFontString", "SetFontObject", "SetWordWrap", "SetMaxLines", "CreateTexture", "ClearAllPoints", "SetPoint", "GetStringWidth" }) do
        saved[k] = rawget(F, k)
    end
local origCreateFS = F.CreateFontString
    function F:CreateFontString(name, layer, template)
      local fs = origCreateFS(self)
      fs._parent = self; fs._font = template or "GameFontHighlight"
      return fs
    end
    function F:SetFontObject(font) self._font = font end
    function F:SetWordWrap(v) self._nowrap = not v end
    function F:SetMaxLines(n) self._maxLines = n end
    local origTex = F.CreateTexture
    function F:CreateTexture(...) local t = origTex(self, ...); t._parent = self; return t end
    function F:ClearAllPoints() self._pts = {} ; self._anchor = nil end
    local origSetPoint = F.SetPoint
    function F:SetPoint(p, a, b, c, d)
      origSetPoint(self, p, a, b, c, d)
      self._pts = self._pts or {}
      local rel, rp, x, y
      if type(a) == "table" then rel, rp, x, y = a, b or p, c or 0, d or 0
      elseif type(a) == "number" then rel, rp, x, y = nil, p, a, b or 0
      elseif a == nil then rel, rp, x, y = nil, p, 0, 0
      else rel, rp, x, y = nil, b or p, c or 0, d or 0 end
      if type(rp) == "number" then rp, x, y = p, rp, x end
      table.insert(self._pts, { p = p, rel = rel, rp = rp, x = x or 0, y = y or 0 })
    end
    
    function F:GetStringWidth() return ulen(strip(self._text)) * (CHAR[self._font] or 6.9) end
    return function() for k, v in pairs(saved) do F[k] = v end end
end

return LC
