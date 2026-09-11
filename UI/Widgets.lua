-- K.I.S.S. -- UI/Widgets.lua
-- Shared theme constants and low-level widget helpers. Every other file in
-- this addon builds on top of what's defined here, so this loads first.
--
-- All files in this addon share one private table via the standard
-- "ADDON_NAME, ns = ..." pattern: WoW hands every file of the same addon
-- the SAME table as the second vararg, so fields set here (KISS.MakeButton,
-- KISS.GOLD, etc.) are visible from every other file without globals.
local ADDON_NAME, KISS = ...

-------------------------------------------------------------------------------
-- Color helpers
-------------------------------------------------------------------------------
local function Hex(r, g, b) return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255) end
KISS.GOLD  = Hex(1.00, 0.82, 0.00)
KISS.GREEN = Hex(0.40, 0.90, 0.40)
KISS.RED   = Hex(0.90, 0.30, 0.30)
KISS.WHITE = Hex(1.00, 1.00, 1.00)
KISS.RESET = "|r"

-------------------------------------------------------------------------------
-- UI constants
-------------------------------------------------------------------------------
KISS.VERSION = "0.1.1"  -- keep in sync with GRIP-EMS-KISS.toc's ## Version:

KISS.WIN_W, KISS.WIN_H = 760, 580
KISS.NAV_W             = 160
KISS.CONTENT_X         = KISS.NAV_W + 16
KISS.CONTENT_W         = KISS.WIN_W - KISS.NAV_W - 32  -- corrected to the real
                                                          -- measured width once
                                                          -- the wizard frame
                                                          -- actually exists
KISS.CONTENT_Y         = -50
KISS.CONTENT_H         = KISS.WIN_H - 110

-- Dark panel colours matching EMS aesthetic
KISS.COL_BG         = { 0.08, 0.08, 0.10, 0.97 }
KISS.COL_NAV        = { 0.05, 0.05, 0.07, 1.00 }
KISS.COL_BTN        = { 0.14, 0.14, 0.17, 1.00 }
KISS.COL_BTN_HL     = { 0.20, 0.19, 0.10, 1.00 }
KISS.COL_BTN_ACTIVE = { 0.25, 0.22, 0.06, 1.00 }
KISS.COL_SEQ_BTN    = { 0.11, 0.11, 0.14, 1.00 }
KISS.COL_SEQ_SEL    = { 0.22, 0.18, 0.04, 1.00 }
KISS.COL_BORDER     = { 0.30, 0.28, 0.10, 1.00 }
KISS.COL_ACCENT     = { 1.00, 0.82, 0.00, 1.00 }  -- gold
KISS.COL_GREEN_BTN  = { 0.10, 0.35, 0.12, 1.00 }
KISS.COL_RED_BTN    = { 0.35, 0.08, 0.08, 1.00 }

-------------------------------------------------------------------------------
-- Low-level widget helpers
-------------------------------------------------------------------------------
function KISS.SetBG(frame, r, g, b, a)
    if not frame._bg then
        frame._bg = frame:CreateTexture(nil, "BACKGROUND")
        frame._bg:SetAllPoints(frame)
    end
    frame._bg:SetColorTexture(r, g, b, a)
end

function KISS.SetBorder(frame, r, g, b, a, sz)
    sz = sz or 1
    local t = frame:CreateTexture(nil, "OVERLAY")
    t:SetColorTexture(r, g, b, a)
    t:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -sz,  sz)
    t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  sz, -sz)
    local t2 = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    t2:SetColorTexture(unpack(KISS.COL_BG))
    t2:SetAllPoints(frame)
end

function KISS.MakeButton(parent, label, w, h, col)
    col = col or KISS.COL_BTN
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    KISS.SetBG(btn, col[1], col[2], col[3], col[4] or 1)
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetAllPoints(btn)
    fs:SetText(label)
    fs:SetTextColor(1, 0.82, 0, 1)
    btn._label = fs
    return btn
end

function KISS.MakeSectionLabel(parent, text, yOff)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)
    fs:SetText(KISS.GOLD .. text .. KISS.RESET)
    fs:SetTextColor(1, 0.82, 0, 1)
    return fs
end

function KISS.MakeBodyText(parent, text, yOff, wrap)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)
    if wrap then fs:SetWidth(KISS.CONTENT_W) end
    fs:SetText(text)
    fs:SetTextColor(0.85, 0.85, 0.85, 1)
    return fs
end

-------------------------------------------------------------------------------
-- Content-area widget tracking (wiped on every page change)
-------------------------------------------------------------------------------
local contentWidgets = {}

function KISS.WipeContent(contentArea)
    for _, w in ipairs(contentWidgets) do
        w:Hide()
        w:SetParent(nil)
    end
    contentWidgets = {}
end

function KISS.Track(w)
    contentWidgets[#contentWidgets + 1] = w
    return w
end

-------------------------------------------------------------------------------
-- Slash-command name safety check
-------------------------------------------------------------------------------
-- CONFIRMED (in-game, 2026): GRIP-EMS's own /gems bind|unbind|delete parser
-- splits its argument string on the first whitespace with no quote support --
-- wrapping a name in quotes doesn't help, the leading quote just becomes part
-- of the truncated token. Any sequence name containing a space cannot be
-- bound, unbound, or deleted through the /gems slash interface, manually or
-- through this wizard. This only checks for the confirmed failure case
-- (whitespace); other punctuation in "DummyAnalyzer > Best (Solo)" did not
-- reproduce a separate failure in testing, so it isn't flagged here.
function KISS.HasSlashUnsafeName(name)
    return name ~= nil and name:find("%s") ~= nil
end
