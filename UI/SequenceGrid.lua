-- K.I.S.S. -- UI/SequenceGrid.lua
-- The shared sequence-selection grid used by both the "Yes" panel (existing
-- sequences) and the "No" panel (after an import completes), so both paths
-- lead to the same selectable grid instead of duplicating the UI. Also owns
-- the delete-confirmation popup routed through EMS's own /gems delete.
local ADDON_NAME, KISS = ...

-- Filter the full sequence list down to the player's class
local function GetClassSequences()
    local classID = select(3, UnitClass("player")) -- numeric class id

    local all = KISS.API:GetSequenceList()
    local filtered = {}
    for _, s in ipairs(all) do
        local info = KISS.API:GetSequenceInfo(s.name)
        if info then
            -- Include if untagged (nil classID) or matches current class
            if not info.classID or info.classID == classID then
                filtered[#filtered + 1] = {
                    name        = s.name,
                    stepCount   = s.stepCount,
                    description = info.description or "",
                    author      = info.author or "Unknown",
                    specID      = info.specID,
                }
            end
        end
    end
    return filtered
end

-------------------------------------------------------------------------------
-- Delete confirmation -- routed through EMS's own public "/gems delete <name>"
-- command. There's no API method for a plugin to delete a sequence it doesn't
-- own (by design -- a plugin deleting a user's data without that guardrail
-- would be dangerous), so this does exactly what the user could type
-- themselves, just with a confirmation step first since it's destructive.
-------------------------------------------------------------------------------
StaticPopupDialogs["KISS_CONFIRM_DELETE_SEQ"] = {
    text = "Delete sequence %s?\nThis cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        -- Just issue the delete; the SEQUENCE_DELETED event listener (Core/Init.lua)
        -- handles clearing the selection and refreshing whichever grid is visible.
        SlashCmdList["GRIPEMS"]("delete " .. data.name)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function KISS.PopulateSequenceGrid(hostFrame)
    -- Clear any boxes this specific host previously built
    if hostFrame._boxes then
        for _, b in ipairs(hostFrame._boxes) do b:Hide(); b:SetParent(nil) end
    end
    if hostFrame._noneLabel then
        hostFrame._noneLabel:Hide()
        hostFrame._noneLabel = nil
    end
    hostFrame._boxes = {}

    local seqs = GetClassSequences()

    if #seqs == 0 then
        local none = hostFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        none:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", 0, 0)
        none:SetPoint("TOPRIGHT", hostFrame, "TOPRIGHT", 0, 0)
        none:SetText("No sequences found for your class yet.")
        none:SetTextColor(0.80, 0.80, 0.80, 1)
        none:SetJustifyH("LEFT")
        hostFrame._noneLabel = none
        hostFrame:SetHeight(30)
        return
    end

    local panelW = hostFrame:GetWidth()
    if not panelW or panelW <= 0 then panelW = KISS.CONTENT_W end
    local colGap, rowGap = 10, 10
    local colW = (panelW - colGap) / 2
    local rowH = 64
    local col, row = 0, 0

    for i, s in ipairs(seqs) do
        local box = CreateFrame("Button", nil, hostFrame)
        box:SetSize(colW, rowH)
        local xOff = col * (colW + colGap)
        local yOff = -(row * (rowH + rowGap))
        box:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", xOff, yOff)

        local isSelected = (KISS.selectedSeq == s.name)
        KISS.SetBG(box, unpack(isSelected and { 0.30, 0.24, 0.02, 1.00 } or KISS.COL_SEQ_BTN))
        box:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        -- Border: a thin neutral outline normally, or a thick bright gold
        -- outline that stays visible whether or not the mouse is hovering,
        -- so selection state doesn't depend on the hover glow.
        local bdr = box:CreateTexture(nil, "BORDER")
        local borderThickness = isSelected and 2 or 1
        if isSelected then
            bdr:SetColorTexture(1, 0.82, 0, 1)  -- bright gold, always visible
        else
            bdr:SetColorTexture(unpack(KISS.COL_BORDER))
        end
        bdr:SetPoint("TOPLEFT", box, "TOPLEFT", -borderThickness, borderThickness)
        bdr:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", borderThickness, -borderThickness)

        -- Persistent checkmark badge in the corner when selected
        if isSelected then
            local check = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            check:SetPoint("TOPRIGHT", box, "TOPRIGHT", -6, -6)
            check:SetText(KISS.GREEN .. "\226\156\147" .. KISS.RESET)  -- checkmark
            check:SetTextColor(0.40, 0.90, 0.40, 1)
        end

        -- Delete button (bottom-right corner, away from the checkmark) --
        -- smaller icon, solid red at rest (not just on hover).
        local delBtn = CreateFrame("Button", nil, box)
        delBtn:SetSize(15, 15)
        delBtn:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 4)
        local delIcon = delBtn:CreateTexture(nil, "ARTWORK")
        delIcon:SetAllPoints(delBtn)
        delIcon:SetTexture("Interface\\Buttons\\UI-StopButton")
        delIcon:SetVertexColor(0.85, 0.12, 0.12)
        delBtn:SetScript("OnEnter", function() delIcon:SetVertexColor(1.0, 0.30, 0.30) end)
        delBtn:SetScript("OnLeave", function() delIcon:SetVertexColor(0.85, 0.12, 0.12) end)
        delBtn:SetScript("OnClick", function()
            StaticPopup_Show("KISS_CONFIRM_DELETE_SEQ", s.name, nil, { name = s.name, host = hostFrame })
        end)

        local nameFS = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameFS:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -8)
        nameFS:SetWidth(colW - 12)
        nameFS:SetText(s.name)
        nameFS:SetTextColor(1, 0.82, 0, 1)
        nameFS:SetJustifyH("LEFT")

        local descFS = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        descFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -2)
        descFS:SetWidth(colW - 12)
        local desc = s.description ~= "" and s.description or ("By " .. s.author)
        if #desc > 60 then desc = desc:sub(1, 57) .. "..." end
        descFS:SetText(desc)
        descFS:SetTextColor(0.65, 0.65, 0.65, 1)
        descFS:SetJustifyH("LEFT")

        box:SetScript("OnClick", function()
            KISS.selectedSeq = s.name
            KISS.SaveState()
            KISS.PopulateSequenceGrid(hostFrame)  -- re-render to update selection highlight
            KISS.UpdateArrows()                    -- Next may now be selectable
        end)

        hostFrame._boxes[#hostFrame._boxes + 1] = box

        col = col + 1
        if col >= 2 then col = 0; row = row + 1 end
    end

    -- Tell the scroll child its real content height so a ScrollFrame parent
    -- knows how far it can actually scroll.
    local totalRows = row + (col > 0 and 1 or 0)
    hostFrame:SetHeight(math.max(1, totalRows * (rowH + rowGap)))
end
