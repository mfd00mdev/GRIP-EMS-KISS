-- K.I.S.S. -- UI/Pages.lua
-- The four wizard pages: Home, Step 1 (sequence), Step 2 (keybind), Step 3 (test).
local ADDON_NAME, KISS = ...

-------------------------------------------------------------------------------
-- Page: Home
-------------------------------------------------------------------------------
function KISS.RenderHome(ca)
    local title = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    title:SetPoint("TOP", ca, "TOP", 0, 0)
    title:SetText(KISS.GOLD .. "Welcome to the K.I.S.S. Onboarding Guide" .. KISS.RESET)
    title:SetTextColor(1, 0.82, 0, 1)

    local sub = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    sub:SetPoint("TOP", title, "BOTTOM", 0, -12)
    sub:SetWidth(KISS.CONTENT_W)
    sub:SetText("K.I.S.S. stands for Keep It Simple, Stupid.\n\nThis quick guide will walk you through the three steps needed to get the GRIP-EMS addon firing your rotation.")
    sub:SetTextColor(0.85, 0.85, 0.85, 1)
    sub:SetJustifyH("CENTER")

    local step1 = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    step1:SetPoint("TOP", sub, "BOTTOM", 0, -24)
    step1:SetText(KISS.GOLD .. "Step 1:" .. KISS.RESET .. "  Select or import a rotation sequence.")
    step1:SetTextColor(0.85, 0.85, 0.85, 1)
    step1:SetJustifyH("CENTER")

    local step2 = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    step2:SetPoint("TOP", step1, "BOTTOM", 0, -10)
    step2:SetText(KISS.GOLD .. "Step 2:" .. KISS.RESET .. "  Bind a key to fire it.")
    step2:SetTextColor(0.85, 0.85, 0.85, 1)
    step2:SetJustifyH("CENTER")

    local step3 = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    step3:SetPoint("TOP", step2, "BOTTOM", 0, -10)
    step3:SetText(KISS.GOLD .. "Step 3:" .. KISS.RESET .. "  Test at the target dummies.")
    step3:SetTextColor(0.85, 0.85, 0.85, 1)
    step3:SetJustifyH("CENTER")

    local goBtn = KISS.Track(KISS.MakeButton(ca, "Begin Guided Install", 200, 32, KISS.COL_GREEN_BTN))
    goBtn:SetPoint("TOP", step3, "BOTTOM", 0, -30)
    goBtn._label:SetTextColor(0.40, 0.90, 0.40, 1)
    goBtn:SetScript("OnClick", function() KISS.ShowPage("step1") end)

    -- Mascot image, top-right corner (near the gold accent line above).
    -- The BLP was padded to a power-of-two 1024x1024 canvas during conversion,
    -- leaving transparent margin around the actual artwork (content sits at
    -- roughly 1.9%-98.1% horizontally, 3.2%-96.9% vertically). SetTexCoord
    -- crops straight to the real content so that padding never renders as
    -- a visible gap.
    local mascot = KISS.Track(ca:CreateTexture(nil, "ARTWORK"))
    mascot:SetTexture("Interface\\AddOns\\GRIP-EMS-KISS\\Media\\opai")
    mascot:SetTexCoord(0.0186, 0.9805, 0.0322, 0.9688)
    mascot:SetSize(189, 184)  -- 1.35x scale-up, aspect ratio preserved
    -- Anchored to the outer window frame (not the content area) so it sits
    -- flush with the true right edge -- ca has a 16px right-side margin that
    -- would otherwise leave a gap here. Vertical offset (40) is kept the same
    -- as ca's own bottom margin: going lower would tuck the image behind the
    -- footer bar's background, which sits on a higher layer and would clip it.
    mascot:SetPoint("BOTTOMRIGHT", KISS.WizardFrame, "BOTTOMRIGHT", 0, 40)
end

-------------------------------------------------------------------------------
-- Page: Step 1 - Sequence
-------------------------------------------------------------------------------
function KISS.RenderStep1(ca)
    local title = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    title:SetPoint("TOP", ca, "TOP", 0, 0)
    title:SetText(KISS.GOLD .. "Step 1 of 3 — Select Your Sequence" .. KISS.RESET)
    title:SetTextColor(1, 0.82, 0, 1)

    local question = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    question:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    question:SetWidth(KISS.CONTENT_W)
    question:SetText("Do you have a sequence imported already?")
    question:SetTextColor(0.85, 0.85, 0.85, 1)
    question:SetJustifyH("LEFT")

    -- Yes / No toggle buttons
    local yesBtn = KISS.Track(KISS.MakeButton(ca, "Yes — I have one", 140, 28))
    yesBtn:SetPoint("TOPLEFT", question, "BOTTOMLEFT", 0, -14)

    local noBtn = KISS.Track(KISS.MakeButton(ca, "No — I need one", 140, 28))
    noBtn:SetPoint("LEFT", yesBtn, "RIGHT", 10, 0)

    -- Sequence list panel (shown when YES) -- scrollable so any number of
    -- sequences can be reached, not just the first couple of rows.
    local seqPanel = KISS.Track(CreateFrame("ScrollFrame", nil, ca, "UIPanelScrollFrameTemplate"))
    seqPanel:SetPoint("TOPLEFT", yesBtn, "BOTTOMLEFT", 0, -16)
    seqPanel:SetPoint("TOPRIGHT", ca, "TOPRIGHT", -26, 0)      -- room for the scrollbar
    seqPanel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -26, 0)
    seqPanel:Hide()
    KISS.WizardFrame._seqPanelRef = seqPanel

    local seqGridHost = CreateFrame("Frame", nil, seqPanel)
    seqGridHost:SetHeight(1)
    seqPanel:SetScrollChild(seqGridHost)
    seqPanel:SetScript("OnSizeChanged", function(self, w)
        if w and w > 0 then seqGridHost:SetWidth(w) end
    end)
    KISS.WizardFrame._seqGridHost = seqGridHost

    -- Import panel (shown when NO)
    local importPanel = KISS.Track(CreateFrame("Frame", nil, ca))
    importPanel:SetPoint("TOPLEFT", yesBtn, "BOTTOMLEFT", 0, -16)
    importPanel:SetPoint("TOPRIGHT", ca, "TOPRIGHT", 0, 0)
    importPanel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", 0, 0)
    importPanel:SetClipsChildren(true)
    importPanel:Hide()

    -- Build sequence grid (Yes path) -- shared logic lives in KISS.PopulateSequenceGrid
    local function BuildSeqGrid()
        KISS.PopulateSequenceGrid(seqGridHost)
    end

    -- Build import panel content
    local function BuildImportPanel()
        if importPanel._built then return end
        importPanel._built = true

        local note = importPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", importPanel, "TOPLEFT", 0, 0)
        note:SetPoint("TOPRIGHT", importPanel, "TOPRIGHT", 0, 0)
        note:SetJustifyH("LEFT")
        note:SetText("GRIP-EMS handles importing sequences (strings starting with !EMS1!...) through its own import window.\n\nClick below to open it, then paste your string there and click Import.")
        note:SetTextColor(0.85, 0.85, 0.85, 1)
        note:SetSpacing(4)

        local openBtn = KISS.MakeButton(importPanel, "Open GRIP-EMS Import Window", 260, 32, KISS.COL_GREEN_BTN)
        openBtn:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -18)
        openBtn._label:SetTextColor(0.40, 0.90, 0.40, 1)
        openBtn:SetScript("OnClick", function()
            SlashCmdList["GRIPEMS"]("import")
        end)

        -- Resource buttons: houseofmacros.com on the left, lazygrip.net on the right, lowercase labels.
        local resLabel = importPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        resLabel:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -20)
        resLabel:SetText("Need a sequence? Find one-button macros at:")
        resLabel:SetTextColor(0.85, 0.85, 0.85, 1)

        local homBtn = KISS.MakeButton(importPanel, "houseofmacros.com", 150, 26)
        homBtn:SetPoint("TOPLEFT", resLabel, "BOTTOMLEFT", 0, -8)
        homBtn:SetScript("OnClick", function()
            KISS.ShowURLPopup("https://houseofmacros.com")
        end)

        local lgBtn = KISS.MakeButton(importPanel, "lazygrip.net", 130, 26)
        lgBtn:SetPoint("LEFT", homBtn, "RIGHT", 10, 0)
        lgBtn:SetScript("OnClick", function()
            KISS.ShowURLPopup("https://lazygrip.net")
        end)

        -- Once a sequence is imported through EMS's own window, it should be
        -- pickable right here too -- same grid the Yes panel uses, so the
        -- user isn't left with an imported sequence and no way to select it.
        local importedLabel = importPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        importedLabel:SetPoint("TOPLEFT", homBtn, "BOTTOMLEFT", 0, -20)
        importedLabel:SetText("Available sequences:")
        importedLabel:SetTextColor(0.85, 0.85, 0.85, 1)

        local importScrollFrame = CreateFrame("ScrollFrame", nil, importPanel, "UIPanelScrollFrameTemplate")
        importScrollFrame:SetPoint("TOPLEFT",  importedLabel, "BOTTOMLEFT", 0, -8)
        importScrollFrame:SetPoint("TOPRIGHT", importPanel,   "TOPRIGHT",  -26, 0)
        importScrollFrame:SetHeight(160)

        local importGridHost = CreateFrame("Frame", nil, importScrollFrame)
        importGridHost:SetHeight(1)
        importScrollFrame:SetScrollChild(importGridHost)
        importScrollFrame:SetScript("OnSizeChanged", function(self, w)
            if w and w > 0 then importGridHost:SetWidth(w) end
        end)

        -- Store on the persistent WizardFrame so the SEQUENCE_IMPORTED handler
        -- (registered once, outside this per-render closure, in Core/Init.lua)
        -- can reach it.
        KISS.WizardFrame._importGridHost  = importGridHost
        KISS.WizardFrame._importedLabel   = importedLabel
        KISS.WizardFrame._importPanelRef  = importPanel

        -- Show whatever's already available right away, not just newly imported ones
        KISS.PopulateSequenceGrid(importGridHost)
    end

    -- Wire Yes/No buttons
    yesBtn:SetScript("OnClick", function()
        seqPanel:Show()
        importPanel:Hide()
        KISS.SetBG(yesBtn, 0.22, 0.18, 0.04, 1)
        KISS.SetBG(noBtn, KISS.COL_BTN[1], KISS.COL_BTN[2], KISS.COL_BTN[3], 1)
        BuildSeqGrid()
    end)

    noBtn:SetScript("OnClick", function()
        importPanel:Show()
        seqPanel:Hide()
        KISS.SetBG(noBtn, 0.22, 0.18, 0.04, 1)
        KISS.SetBG(yesBtn, KISS.COL_BTN[1], KISS.COL_BTN[2], KISS.COL_BTN[3], 1)
        BuildImportPanel()
    end)

    -- Auto-show yes panel if a sequence is already selected
    if KISS.selectedSeq then
        seqPanel:Show()
        KISS.SetBG(yesBtn, 0.22, 0.18, 0.04, 1)
        BuildSeqGrid()
    end
end

-------------------------------------------------------------------------------
-- Page: Step 2 — Keybind
-------------------------------------------------------------------------------
function KISS.RenderStep2(ca)
    local title = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    title:SetPoint("TOP", ca, "TOP", 0, 0)
    title:SetText(KISS.GOLD .. "Step 2 of 3 — Set Your Keybind" .. KISS.RESET)
    title:SetTextColor(1, 0.82, 0, 1)

    local seqNote = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    seqNote:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    seqNote:SetWidth(KISS.CONTENT_W)
    local seqDisplay = KISS.selectedSeq and (KISS.GOLD .. KISS.selectedSeq .. KISS.RESET)
                        or (KISS.RED .. "None selected — go back to Step 1" .. KISS.RESET)
    seqNote:SetText("Selected sequence: " .. seqDisplay)
    seqNote:SetTextColor(0.85, 0.85, 0.85, 1)
    seqNote:SetJustifyH("LEFT")

    -- Confirmed in testing: a space in the sequence name breaks GRIP-EMS's
    -- own /gems bind parser, quoted or not. If the selected sequence has
    -- one, warn here instead of letting the user hit the same wall Step 2's
    -- bind button can't get around either.
    local anchorAbove = seqNote
    if KISS.selectedSeq and KISS.HasSlashUnsafeName(KISS.selectedSeq) then
        local nameWarning = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        nameWarning:SetPoint("TOPLEFT", seqNote, "BOTTOMLEFT", 0, -8)
        nameWarning:SetPoint("TOPRIGHT", ca, "TOPRIGHT", 0, 0)   -- anchor to the live frame, not a copied width constant
        nameWarning:SetText("This sequence's name has a space in it, which GRIP-EMS's bind command can't handle. Give it a one-word name, or bind it manually from GRIP-EMS's Keybind tab instead.")
        nameWarning:SetTextColor(0.90, 0.30, 0.30, 1)
        nameWarning:SetJustifyH("LEFT")
        anchorAbove = nameWarning
    end

    local question = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    question:SetPoint("TOPLEFT", anchorAbove, "BOTTOMLEFT", 0, -18)
    question:SetWidth(KISS.CONTENT_W)
    question:SetText("What key do you want to press to fire your sequence?")
    question:SetTextColor(0.85, 0.85, 0.85, 1)
    question:SetJustifyH("LEFT")

    local instructions = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    instructions:SetPoint("TOPLEFT", question, "BOTTOMLEFT", 0, -8)
    instructions:SetWidth(KISS.CONTENT_W)
    instructions:SetText("Click the button below, then press any key (or mouse button) to assign it.")
    instructions:SetTextColor(0.65, 0.65, 0.65, 1)
    instructions:SetJustifyH("LEFT")

    -- Current binding display
    local currentLabel = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    currentLabel:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -18)
    currentLabel:SetText("Current binding: " .. (KISS.keybind and (KISS.GREEN .. KISS.keybind .. KISS.RESET) or "None"))
    currentLabel:SetTextColor(0.85, 0.85, 0.85, 1)

    -- Key capture button (mimics EMS keybind button)
    local keybindBtn = KISS.Track(KISS.MakeButton(ca, KISS.keybind and ("[ " .. KISS.keybind .. " ]") or "[ Click to bind ]", 200, 36))
    keybindBtn:SetPoint("TOPLEFT", currentLabel, "BOTTOMLEFT", 0, -14)
    KISS.SetBG(keybindBtn, 0.06, 0.06, 0.08, 1)

    -- Invisible overlay frame to capture key input
    if KISS.keyListenFrame then
        KISS.keyListenFrame:Hide()
        KISS.keyListenFrame:SetScript("OnKeyDown", nil)
        KISS.keyListenFrame:SetScript("OnMouseDown", nil)
    end

    local keyListenFrame = KISS.Track(CreateFrame("Frame", "KISS_KeyListener", UIParent, "BackdropTemplate"))
    keyListenFrame:SetAllPoints(UIParent)
    keyListenFrame:SetFrameStrata("DIALOG")
    keyListenFrame:EnableKeyboard(true)
    keyListenFrame:EnableMouse(true)
    keyListenFrame:Hide()
    KISS.keyListenFrame = keyListenFrame

    local listeningLabel = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    listeningLabel:SetPoint("LEFT", keybindBtn, "RIGHT", 12, 0)
    listeningLabel:SetText("")
    listeningLabel:SetTextColor(1, 0.82, 0, 1)

    local function StopListening()
        KISS.listeningKey = false
        keyListenFrame:Hide()
        listeningLabel:SetText("")
        KISS.SetBG(keybindBtn, 0.06, 0.06, 0.08, 1)
    end

    local function CaptureKey(key)
        -- Ignore pure modifiers
        if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
            or key == "LALT" or key == "RALT" or key == "ESCAPE" then
            if key == "ESCAPE" then StopListening() end
            return
        end

        -- Build modifier prefix
        local prefix = ""
        if IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
        if IsControlKeyDown() then prefix = prefix .. "CTRL-" end
        if IsAltKeyDown() then prefix = prefix .. "ALT-" end

        -- OnKeyDown hands us the raw internal binding token (e.g. "PERIOD"),
        -- not the character it displays as. Letters/numbers/F-keys happen to
        -- match their display text, but punctuation doesn't, and EMS's own
        -- /gems bind parses the same human-readable text its keybind UI would
        -- show. GetBindingText converts the raw token to that display form
        -- (PERIOD -> ".") before we hand it off.
        local displayKey = GetBindingText(key, "KEY_") or key
        local fullKey = prefix .. displayKey
        StopListening()

        -- Apply via EMS: /gems bind <seqName> <key>. State is only committed
        -- (KISS.keybind, SavedVariables, button label) in the success branch --
        -- showing "[ F10 ]" as bound when GRIP-EMS never actually accepted it
        -- would just be a second version of the false-success bug this guard
        -- exists to close.
        if not KISS.selectedSeq then
            print("|cFFFF6644KISS:|r No sequence selected — go back to Step 1 first.")
        elseif KISS.HasSlashUnsafeName(KISS.selectedSeq) then
            -- Confirmed in testing: GRIP-EMS's own /gems bind parser splits on
            -- the first space with no quote support, so sending this would
            -- have it look for a truncated, wrong sequence name and fail
            -- silently as far as this wizard is concerned. Don't send it, and
            -- don't claim a bind that didn't happen.
            print("|cFFFF6644KISS:|r '" .. KISS.selectedSeq .. "' has a space in its name, so GRIP-EMS can't bind it through /gems bind. Rename it without spaces, or bind it from GRIP-EMS's own Keybind tab.")
        else
            KISS.keybind = fullKey
            KISS.SaveState()
            keybindBtn._label:SetText("[ " .. fullKey .. " ]")
            currentLabel:SetText("Current binding: " .. KISS.GREEN .. fullKey .. KISS.RESET)
            SlashCmdList["GRIPEMS"]("bind " .. KISS.selectedSeq .. " " .. fullKey)
            print("|cFF82E882KISS:|r Bound [" .. fullKey .. "] to sequence: " .. KISS.selectedSeq)
        end
    end

    keyListenFrame:SetScript("OnKeyDown", function(_, key)
        if KISS.listeningKey then CaptureKey(key) end
    end)

    keyListenFrame:SetScript("OnMouseDown", function(_, btn)
        if KISS.listeningKey then
            local map = { LeftButton = "BUTTON1", RightButton = "BUTTON2",
                          MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
            CaptureKey(map[btn] or btn)
        end
    end)

    keybindBtn:SetScript("OnClick", function()
        if KISS.listeningKey then
            StopListening()
        else
            KISS.listeningKey = true
            keyListenFrame:Show()
            listeningLabel:SetText("Press a key...")
            KISS.SetBG(keybindBtn, 0.20, 0.16, 0.02, 1)
            keybindBtn._label:SetText("[ Press a key... ]")
        end
    end)

    -- Clear button
    local clearBtn = KISS.Track(KISS.MakeButton(ca, "Clear", 80, 26, KISS.COL_RED_BTN))
    clearBtn:SetPoint("TOP", keybindBtn, "BOTTOM", 0, -10)
    clearBtn._label:SetTextColor(0.90, 0.30, 0.30, 1)
    clearBtn:SetScript("OnClick", function()
        if KISS.selectedSeq and KISS.keybind and not KISS.HasSlashUnsafeName(KISS.selectedSeq) then
            SlashCmdList["GRIPEMS"]("unbind " .. KISS.selectedSeq)
        end
        KISS.keybind = nil
        KISS.SaveState()
        keybindBtn._label:SetText("[ Click to bind ]")
        currentLabel:SetText("Current binding: None")
    end)
end

-------------------------------------------------------------------------------
-- Page: Step 3 — Test
-------------------------------------------------------------------------------
function KISS.RenderStep3(ca)
    local title = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
    title:SetPoint("TOP", ca, "TOP", 0, 0)
    title:SetText(KISS.GOLD .. "Step 3 of 3 — Test Your Setup" .. KISS.RESET)
    title:SetTextColor(1, 0.82, 0, 1)

    local seq = KISS.selectedSeq and (KISS.GOLD .. KISS.selectedSeq .. KISS.RESET) or (KISS.RED .. "No sequence selected" .. KISS.RESET)
    local key = KISS.keybind   and (KISS.GREEN .. KISS.keybind .. KISS.RESET)   or (KISS.RED .. "No keybind set" .. KISS.RESET)

    local summary = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    summary:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    summary:SetWidth(KISS.CONTENT_W)
    summary:SetText("Sequence: " .. seq .. "\nKeybind:  " .. key)
    summary:SetTextColor(0.85, 0.85, 0.85, 1)
    summary:SetJustifyH("LEFT")

    local divider = KISS.Track(ca:CreateTexture(nil, "OVERLAY"))
    divider:SetColorTexture(unpack(KISS.COL_BORDER))
    divider:SetPoint("TOPLEFT",  summary, "BOTTOMLEFT",  0, -14)
    divider:SetPoint("TOPRIGHT", summary, "BOTTOMRIGHT", 0, -14)
    divider:SetHeight(1)

    local instr1 = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
    instr1:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -14)
    instr1:SetWidth(KISS.CONTENT_W)
    instr1:SetText("Go to the nearest target dummies and spam your bound key.")
    instr1:SetTextColor(0.85, 0.85, 0.85, 1)
    instr1:SetJustifyH("LEFT")

    local instr2 = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    instr2:SetPoint("TOPLEFT", instr1, "BOTTOMLEFT", 0, -8)
    instr2:SetWidth(KISS.CONTENT_W)
    instr2:SetText("Your sequence should cycle through its skills automatically.\n\nIf abilities are " .. KISS.RED .. "not firing" .. KISS.RESET .. ", check that:")
    instr2:SetTextColor(0.80, 0.80, 0.80, 1)
    instr2:SetJustifyH("LEFT")

    local checks = {
        "• You are pressing the correct keybind: " .. (KISS.keybind and (KISS.GREEN .. KISS.keybind .. KISS.RESET) or KISS.RED .. "none set" .. KISS.RESET) .. ".",
        "• Your character is high enough level to know all the spells in the sequence. Missing even one can break it.",
    }
    local prev = instr2
    for _, line in ipairs(checks) do
        local fs = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
        fs:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
        fs:SetPoint("RIGHT", ca, "RIGHT", -6, 0)
        fs:SetText(line)
        fs:SetTextColor(0.80, 0.80, 0.80, 1)
        fs:SetJustifyH("LEFT")
        prev = fs
    end

    local bugNote = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
    bugNote:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -18)
    bugNote:SetWidth(KISS.CONTENT_W)
    bugNote:SetText("Still not working? Report a bug in the GRIP-EMS Discord:")
    bugNote:SetTextColor(0.85, 0.85, 0.85, 1)
    bugNote:SetJustifyH("LEFT")

    local discordBtn = KISS.Track(KISS.MakeButton(ca, "Open GRIP-EMS Discord", 200, 28))
    discordBtn:SetPoint("TOPLEFT", bugNote, "BOTTOMLEFT", 0, -8)
    discordBtn:SetScript("OnClick", function()
        KISS.ShowURLPopup("https://discord.gg/XQXH3nt2X8")
    end)

    local doneLabel = KISS.Track(ca:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    doneLabel:SetPoint("TOPLEFT", discordBtn, "BOTTOMLEFT", 0, -24)
    doneLabel:SetText(KISS.GREEN .. "Setup complete! Click Finished to close this window." .. KISS.RESET)
    doneLabel:SetTextColor(0.40, 0.90, 0.40, 1)

    KISS_DB.completed = true
end
