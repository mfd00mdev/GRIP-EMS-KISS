-- K.I.S.S. -- Core/Init.lua
-- Plugin lifecycle: version handshake, RegisterPlugin, slash command, and the
-- persistent event listeners. Loads last so every KISS.* piece it references
-- (all only inside deferred callbacks, never at file-load time) already exists.
local ADDON_NAME, KISS = ...

-- NOTE: GEMS_UI_READY is NOT a real WoW client event -- it's a custom signal
-- fired through EMS's own callback bus. frame:RegisterEvent() only accepts
-- real Blizzard events; passing it a custom name throws a Lua error immediately.
-- Custom GEMS_* signals must be subscribed via API:On(), not RegisterEvent().
-- Our wizard is a fully standalone frame (never mounted into EMS's own window/
-- hosts), so we don't need GEMS_UI_READY at all -- everything below runs
-- straight off PLAYER_LOGIN.
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

local kissHandle  -- plugin handle, set after RegisterPlugin; only used in this file

-- Wizard state (shared with every other file via the KISS namespace table)
KISS.currentPage  = "home"       -- home | step1 | step2 | step3
KISS.selectedSeq  = nil          -- name string of chosen sequence
KISS.keybind      = nil          -- key string chosen by user
KISS.listeningKey = false        -- are we capturing a key right now?

-------------------------------------------------------------------------------
-- SavedVariables schema
-------------------------------------------------------------------------------
local function InitDB()
    if not KISS_DB then
        KISS_DB = {
            completed   = false,   -- wizard finished at least once
            selectedSeq = nil,
            keybind     = nil,
        }
    end
    KISS.selectedSeq = KISS_DB.selectedSeq
    KISS.keybind     = KISS_DB.keybind
end

function KISS.SaveState()
    KISS_DB.selectedSeq = KISS.selectedSeq
    KISS_DB.keybind     = KISS.keybind
end

-------------------------------------------------------------------------------
-- PLAYER_LOGIN — handshake, register plugin, register slash command
-------------------------------------------------------------------------------
local function OnLogin()
    KISS.API = GRIPEMS and GRIPEMS.API
    if not KISS.API then
        print("|cFFFF6644KISS:|r GRIP-EMS not found. K.I.S.S. requires GRIP-EMS to be installed and enabled.")
        return
    end

    local ok, reason = KISS.API:RequireVersion(2)
    if not ok then
        print("|cFFFF6644KISS:|r " .. tostring(reason))
        return
    end

    InitDB()

    kissHandle = KISS.API:RegisterPlugin("kiss_wizard", {
        name    = "K.I.S.S. Setup Wizard",
        version = "1.0.0",
        OnEnable = function(h)
            -- Nothing to author on enable; wizard is UI-only
        end,
        OnDisable = function(h)
            if KISS.WizardFrame then KISS.WizardFrame:Hide() end
            if KISS.keyListenFrame then KISS.keyListenFrame:Hide() end
        end,
    })

    if not kissHandle then
        print("|cFFFF6644KISS:|r Failed to register plugin handle: " .. tostring(reason))
        return
    end

    -- Register /gems kiss subcommand right away -- our wizard is a standalone
    -- frame, not mounted into EMS's own window, so no need to wait on GEMS_UI_READY.
    local slashOk, slashReason = kissHandle:RegisterSlashCommand("kiss", function(_)
        KISS.ToggleWizard()
    end, "Open the K.I.S.S. setup wizard")

    if slashOk then
        print("|cFF82E882K.I.S.S. loaded.|r Type |cFFFFD700/gems kiss|r to open the setup wizard.")
    else
        print("|cFFFF6644KISS:|r Failed to register /gems kiss: " .. tostring(slashReason))
    end

    -- When EMS finishes an import, and the user is currently on Step 1's
    -- "No -- I need one" panel, show the same selectable grid the "Yes" panel
    -- uses so the freshly imported sequence can actually be picked.
    KISS.API:On("SEQUENCE_IMPORTED", function(results)
        if not (KISS.WizardFrame and KISS.WizardFrame:IsShown()) then return end
        if KISS.currentPage ~= "step1" then return end
        local host = KISS.WizardFrame._importGridHost
        local panel = KISS.WizardFrame._importPanelRef
        if not (host and panel and panel:IsShown()) then return end

        if KISS.WizardFrame._importedLabel then
            KISS.WizardFrame._importedLabel:SetText(KISS.GREEN .. "Sequence imported! Select it below:" .. KISS.RESET)
        end
        KISS.PopulateSequenceGrid(host)
        KISS.UpdateArrows()
    end)

    -- When a sequence is deleted -- by our own delete button, EMS's own list,
    -- or a manual /gems delete -- refresh whichever grid is currently visible
    -- so it never shows a stale, already-deleted entry.
    KISS.API:On("SEQUENCE_DELETED", function(name)
        if KISS.selectedSeq == name then
            KISS.selectedSeq = nil
            KISS.SaveState()
        end
        if not (KISS.WizardFrame and KISS.WizardFrame:IsShown()) then return end
        if KISS.currentPage ~= "step1" then return end

        if KISS.WizardFrame._seqPanelRef and KISS.WizardFrame._seqPanelRef:IsShown() and KISS.WizardFrame._seqGridHost then
            KISS.PopulateSequenceGrid(KISS.WizardFrame._seqGridHost)
        end
        if KISS.WizardFrame._importGridHost and KISS.WizardFrame._importPanelRef
           and KISS.WizardFrame._importPanelRef:IsShown() then
            KISS.PopulateSequenceGrid(KISS.WizardFrame._importGridHost)
        end
        KISS.UpdateArrows()
    end)

    -- Auto-open wizard on first install
    if not KISS_DB.completed then
        C_Timer.After(2.0, function()
            KISS.ShowWizard()
        end)
    end
end

-------------------------------------------------------------------------------
-- Event dispatcher
-------------------------------------------------------------------------------
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        OnLogin()
    end
end)
