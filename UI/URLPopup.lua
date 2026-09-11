-- K.I.S.S. -- UI/URLPopup.lua
-- Copyable URL popup -- WoW addons have no way to open a system browser, so
-- this shows the full link (with https://) in a pre-selected, copyable edit
-- box instead of just printing it to chat.
local ADDON_NAME, KISS = ...

local urlPopup  -- file-local; only ShowURLPopup below ever touches this

function KISS.ShowURLPopup(url)
    if not urlPopup then
        local p = CreateFrame("Frame", "KISS_URLPopup", UIParent, "BackdropTemplate")
        p:SetSize(420, 120)
        p:SetPoint("CENTER")
        p:SetFrameStrata("DIALOG")
        p:SetMovable(true)
        p:EnableMouse(true)
        p:RegisterForDrag("LeftButton")
        p:SetScript("OnDragStart", p.StartMoving)
        p:SetScript("OnDragStop",  p.StopMovingOrSizing)
        KISS.SetBG(p, 0.07, 0.07, 0.09, 1)

        local bdr = p:CreateTexture(nil, "OVERLAY")
        bdr:SetColorTexture(unpack(KISS.COL_BORDER))
        bdr:SetPoint("TOPLEFT",     p, "TOPLEFT",     -1,  1)
        bdr:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT",  1, -1)

        local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", p, "TOP", 0, -14)
        title:SetText(KISS.GOLD .. "Copy this link" .. KISS.RESET)
        title:SetTextColor(1, 0.82, 0, 1)

        local eb = CreateFrame("EditBox", "KISS_URLPopupEditBox", p, "InputBoxTemplate")
        eb:SetSize(360, 24)
        eb:SetPoint("TOP", title, "BOTTOM", 0, -16)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
        p._editBox = eb

        local hint = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOP", eb, "BOTTOM", 0, -10)
        hint:SetText("Press Ctrl+C to copy, then paste it into your browser.")
        hint:SetTextColor(0.65, 0.65, 0.65, 1)

        local closeBtn = CreateFrame("Button", nil, p, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", p, "TOPRIGHT", -2, -2)
        closeBtn:SetScript("OnClick", function() p:Hide() end)

        p:Hide()
        urlPopup = p
    end

    urlPopup._editBox:SetText(url)
    urlPopup._editBox:HighlightText()
    urlPopup._editBox:SetFocus()
    urlPopup:Show()
end
