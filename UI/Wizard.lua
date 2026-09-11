-- K.I.S.S. -- UI/Wizard.lua
-- The wizard window shell: frame, left nav, bottom bar, and page dispatch.
local ADDON_NAME, KISS = ...

-------------------------------------------------------------------------------
-- Nav button state management
-------------------------------------------------------------------------------
local navButtons = {}

local function SetNavActive(id)
    for _, nb in pairs(navButtons) do
        if nb._id == id then
            KISS.SetBG(nb, KISS.COL_BTN_ACTIVE[1], KISS.COL_BTN_ACTIVE[2], KISS.COL_BTN_ACTIVE[3], 1)
            nb._label:SetTextColor(1, 0.82, 0, 1)
        else
            KISS.SetBG(nb, KISS.COL_NAV[1], KISS.COL_NAV[2], KISS.COL_NAV[3], 1)
            nb._label:SetTextColor(0.65, 0.65, 0.65, 1)
        end
    end
end

-------------------------------------------------------------------------------
-- Bottom navigation arrows
-------------------------------------------------------------------------------
local bottomPrev, bottomNext
local bottomVersionLabel, bottomCreditLabel

local PAGE_ORDER = { "home", "step1", "step2", "step3" }

local function GetPageIndex(id)
    for i, v in ipairs(PAGE_ORDER) do if v == id then return i end end
    return 1
end

function KISS.UpdateArrows()
    local idx = GetPageIndex(KISS.currentPage)

    if KISS.currentPage == "home" then
        -- Home is the entry point -- no Previous, and it has its own
        -- "Begin Guided Install" button instead of a Next arrow.
        bottomPrev:Hide()
        bottomNext:Hide()
        if bottomVersionLabel then bottomVersionLabel:Show() end
        if bottomCreditLabel then bottomCreditLabel:Show() end
    else
        bottomPrev:Show()
        bottomPrev:SetEnabled(idx > 1)
        bottomPrev:SetAlpha(idx > 1 and 1 or 0.3)

        bottomNext:Show()
        if bottomVersionLabel then bottomVersionLabel:Hide() end
        if bottomCreditLabel then bottomCreditLabel:Hide() end
        local canAdvance = idx < #PAGE_ORDER
        if KISS.currentPage == "step1" and not KISS.selectedSeq then
            -- No sequence chosen yet (via either Yes or No path) -- stay put.
            canAdvance = false
        end

        if KISS.currentPage == "step3" then
            -- Last page: Next becomes a "Finished" action that closes the wizard.
            bottomNext._label:SetText("Finished")
            bottomNext:SetEnabled(true)
            bottomNext:SetAlpha(1)
        else
            bottomNext._label:SetText("Next  ▶")
            bottomNext:SetEnabled(canAdvance)
            bottomNext:SetAlpha(canAdvance and 1 or 0.3)
        end
    end
end

-------------------------------------------------------------------------------
-- ShowPage dispatcher
-------------------------------------------------------------------------------
function KISS.ShowPage(pageId)
    KISS.currentPage = pageId
    SetNavActive(pageId)
    KISS.UpdateArrows()

    local ca = KISS.WizardFrame._contentArea
    KISS.WipeContent(ca)

    if pageId == "home"  then KISS.RenderHome(ca)
    elseif pageId == "step1" then KISS.RenderStep1(ca)
    elseif pageId == "step2" then KISS.RenderStep2(ca)
    elseif pageId == "step3" then KISS.RenderStep3(ca)
    end
end

-------------------------------------------------------------------------------
-- Build the wizard window
-------------------------------------------------------------------------------
local function BuildWizard()
    if KISS.WizardFrame then return end

    local frame = CreateFrame("Frame", "KISS_WizardFrame", UIParent, "BackdropTemplate")
    frame:SetSize(KISS.WIN_W, KISS.WIN_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:Hide()
    KISS.WizardFrame = frame

    -- Background
    KISS.SetBG(frame, unpack(KISS.COL_BG))

    -- Top border accent
    local topBar = frame:CreateTexture(nil, "OVERLAY")
    topBar:SetColorTexture(unpack(KISS.COL_ACCENT))
    topBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0,  0)
    topBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0,  0)
    topBar:SetHeight(2)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, -2)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
    titleBar:SetHeight(36)
    KISS.SetBG(titleBar, 0.05, 0.05, 0.07, 1)

    local titleFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleFS:SetPoint("LEFT", titleBar, "LEFT", KISS.NAV_W + 12, 0)
    titleFS:SetText(KISS.GOLD .. "K.I.S.S." .. KISS.RESET .. "  |  Keep It Simple, Stupid")
    titleFS:SetTextColor(1, 0.82, 0, 1)

    local versionFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionFS:SetPoint("RIGHT", titleBar, "RIGHT", -36, 0)
    versionFS:SetText("v" .. KISS.VERSION)
    versionFS:SetTextColor(0.50, 0.50, 0.50, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -6)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- Nav panel
    local navPanel = CreateFrame("Frame", nil, frame)
    navPanel:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, -38)
    navPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0,  0)
    navPanel:SetWidth(KISS.NAV_W)
    KISS.SetBG(navPanel, unpack(KISS.COL_NAV))

    -- Right border on nav
    local navBorder = navPanel:CreateTexture(nil, "OVERLAY")
    navBorder:SetColorTexture(unpack(KISS.COL_BORDER))
    navBorder:SetPoint("TOPRIGHT",    navPanel, "TOPRIGHT",    0,  0)
    navBorder:SetPoint("BOTTOMRIGHT", navPanel, "BOTTOMRIGHT", 0,  0)
    navBorder:SetWidth(1)

    -- Nav buttons
    local navDefs = {
        { id = "home",  label = "Home"    },
        { id = "step1", label = "Step 1\nSequence" },
        { id = "step2", label = "Step 2\nKeybind"  },
        { id = "step3", label = "Step 3\nTest"     },
    }

    local navY = -8
    for _, nd in ipairs(navDefs) do
        local nb = CreateFrame("Button", nil, navPanel)
        nb:SetSize(KISS.NAV_W, 44)
        nb:SetPoint("TOPLEFT", navPanel, "TOPLEFT", 0, navY)
        KISS.SetBG(nb, unpack(KISS.COL_NAV))
        nb:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        nb._id = nd.id

        local fs = nb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetAllPoints(nb)
        fs:SetText(nd.label)
        fs:SetTextColor(0.65, 0.65, 0.65, 1)
        nb._label = fs

        nb:SetScript("OnClick", function() KISS.ShowPage(nd.id) end)

        navButtons[nd.id] = nb
        navY = navY - 46
    end

    -- Nav bottom buttons
    local function NavBotBtn(label, col, yFromBottom)
        local btn = CreateFrame("Button", nil, navPanel)
        btn:SetSize(KISS.NAV_W - 8, 26)
        btn:SetPoint("BOTTOMLEFT", navPanel, "BOTTOMLEFT", 4, yFromBottom)
        KISS.SetBG(btn, col[1], col[2], col[3], col[4] or 1)
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetAllPoints(btn)
        fs:SetText(label)
        fs:SetTextColor(0.75, 0.75, 0.75, 1)
        btn._label = fs
        return btn
    end

    local closeBtn2 = NavBotBtn("CLOSE K.I.S.S.", KISS.COL_RED_BTN, 8)
    closeBtn2._label:SetTextColor(0.85, 0.30, 0.30, 1)
    closeBtn2:SetScript("OnClick", function()
        frame:Hide()
        print("|cFFFFD700KISS:|r Closed. To bring K.I.S.S. back, type |cFFFFFFFF/gems kiss|r.")
    end)

    local reloadBtn = NavBotBtn("RELOAD UI",    KISS.COL_BTN, 38)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

    local optionsBtn = NavBotBtn("OPTIONS",      KISS.COL_BTN, 68)
    optionsBtn:SetScript("OnClick", function()
        frame:Hide()
        SlashCmdList["GRIPEMS"]("options")
    end)

    -- Divider above bottom nav buttons
    local navDivider = navPanel:CreateTexture(nil, "OVERLAY")
    navDivider:SetColorTexture(unpack(KISS.COL_BORDER))
    navDivider:SetPoint("BOTTOMLEFT",  navPanel, "BOTTOMLEFT",  0, 98)
    navDivider:SetPoint("BOTTOMRIGHT", navPanel, "BOTTOMRIGHT", 0, 98)
    navDivider:SetHeight(1)

    -- Content area
    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT",     frame, "TOPLEFT",     KISS.NAV_W + 16, -50)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16,             40)
    KISS.WizardFrame._contentArea = contentArea

    -- CONTENT_W was an assumed constant computed before the frame existed. Correct
    -- it now to the real measured width of the live frame, so every page that sizes
    -- a widget off CONTENT_W (sequence boxes, wrapped text) actually matches the
    -- space it renders into instead of drifting from it.
    local measuredW = contentArea:GetWidth()
    if measuredW and measuredW > 10 then
        KISS.CONTENT_W = measuredW
    end

    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, frame)
    bottomBar:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  KISS.NAV_W, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0,          0)
    bottomBar:SetHeight(36)
    KISS.SetBG(bottomBar, 0.05, 0.05, 0.07, 1)

    local topLine = bottomBar:CreateTexture(nil, "OVERLAY")
    topLine:SetColorTexture(unpack(KISS.COL_BORDER))
    topLine:SetPoint("TOPLEFT",  bottomBar, "TOPLEFT",  0, 0)
    topLine:SetPoint("TOPRIGHT", bottomBar, "TOPRIGHT", 0, 0)
    topLine:SetHeight(1)

    -- Prev / Next arrows
    bottomPrev = KISS.MakeButton(bottomBar, "◀  Previous", 110, 24, KISS.COL_BTN)
    bottomPrev:SetPoint("LEFT", bottomBar, "LEFT", 12, 0)
    bottomPrev:SetScript("OnClick", function()
        local idx = GetPageIndex(KISS.currentPage)
        if idx > 1 then KISS.ShowPage(PAGE_ORDER[idx - 1]) end
    end)

    bottomNext = KISS.MakeButton(bottomBar, "Next  ▶", 110, 24, KISS.COL_BTN)
    bottomNext:SetPoint("RIGHT", bottomBar, "RIGHT", -12, 0)
    bottomNext._label:SetTextColor(1, 0.82, 0, 1)
    bottomNext:SetScript("OnClick", function()
        local idx = GetPageIndex(KISS.currentPage)
        if KISS.currentPage == "step3" then
            KISS.WizardFrame:Hide()
        elseif idx < #PAGE_ORDER then
            KISS.ShowPage(PAGE_ORDER[idx + 1])
        end
    end)

    local stepLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    stepLabel:SetPoint("CENTER", bottomBar, "CENTER", 0, 0)
    stepLabel:SetText("Use arrows or the left panel to navigate.")
    stepLabel:SetTextColor(0.45, 0.45, 0.45, 1)

    -- Version (left) and credit (right) -- same slots the Prev/Next arrows use,
    -- shown only when those are hidden (Home page) so nothing overlaps.
    bottomVersionLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bottomVersionLabel:SetPoint("LEFT", bottomBar, "LEFT", 12, 0)
    bottomVersionLabel:SetText("K.I.S.S. v" .. KISS.VERSION)
    bottomVersionLabel:SetTextColor(0.45, 0.45, 0.45, 1)

    bottomCreditLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bottomCreditLabel:SetPoint("RIGHT", bottomBar, "RIGHT", -12, 0)
    bottomCreditLabel:SetText("Made by MFDOOM with love.")
    bottomCreditLabel:SetTextColor(0.45, 0.45, 0.45, 1)
end

-------------------------------------------------------------------------------
-- Show / toggle the wizard
-------------------------------------------------------------------------------
function KISS.ShowWizard()
    if not KISS.WizardFrame then BuildWizard() end
    KISS.WizardFrame:Show()
    KISS.ShowPage(KISS.currentPage ~= "done" and KISS.currentPage or "home")
end

function KISS.ToggleWizard()
    if KISS.WizardFrame and KISS.WizardFrame:IsShown() then
        KISS.WizardFrame:Hide()
    else
        KISS.ShowWizard()
    end
end
