local addonName, addon = ...

local PUTREFY_SPELL_ID = 1247378
local FESTERING_SCYTHE_SPELL_ID = 458128
local FESTERING_STRIKE_SPELL_ID = 85948
local DEATH_COIL_SPELL_ID = 47541
local NECROTIC_COIL_SPELL_ID = 1242174
local EPIDEMIC_SPELL_ID = 207317
local GRAVEYARD_SPELL_ID = 383269
local SUDDEN_DOOM_BUFF_ID = 81340
-- CDM exposes the tracked Sudden Doom icon using its parent/passive spell ID,
-- while the live proc aura uses 81340.
local SUDDEN_DOOM_CDM_ID = 49530
local KILLING_MACHINE_IDS = { [51124] = true, [51128] = true }
local RIME_IDS = { [59052] = true, [59057] = true }
local BREATH_OF_SINDRAGOSA_ID = 1249658
local LESSER_GHOUL_SPELL_ID = 1254252
local DEATH_AND_DECAY_SPELL_ID = 43265
local DEATH_AND_DECAY_BUFF_ID = 188290
local MARROWREND_SPELL_ID = 195182
local DEATHS_CARESS_SPELL_ID = 195292
local hooked = false

local function GetCDMSpellID(item)
    if not (item and item.GetCooldownID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo) then
        return nil
    end
    local cooldownID = item:GetCooldownID()
    if not cooldownID then return nil end
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    return info and info.spellID
end

-- The tracked-buff icon identifies Lesser Ghoul safely outside combat; the
-- cached frame is then watched during combat without reading secret aura data.
local function GetCDMItemSpellID(item)
    if InCombatLockdown() or not (item and item.GetSpellID) then return nil end
    return item:GetSpellID()
end

local function LesserGhoulEnabled()
    local settings = DKAssistDB and DKAssistDB.spells and DKAssistDB.spells.festeringScythe
    local glowEnabled = settings and settings.enabled and settings.lesserGhoulGlow
    local textEnabled = settings and settings.textAlert and settings.textAlert.enabled
        and settings.textAlert.ghoulMissingWarning
    return glowEnabled or textEnabled or false
end

local function BloodDnDEnabled()
    return DKAssistDB and DKAssistDB.bloodDnd and DKAssistDB.bloodDnd.enabled
end

local function BloodDnDMissingEnabled()
    return DKAssistDB and DKAssistDB.bloodDndMissing and DKAssistDB.bloodDndMissing.enabled
end

local function AnyBloodDnDEnabled()
    -- The timer's Inside/Outside status also needs the secure Tracked Buff
    -- frame even though both legacy glow options are intentionally disabled.
    local timerEnabled = DKAssistDB and DKAssistDB.dnd and DKAssistDB.dnd.enabled
        and addon:IsBloodSpec()
    return BloodDnDEnabled() or BloodDnDMissingEnabled() or timerEnabled
end

local function IsBuffViewerItem(item)
    for _, viewer in ipairs({ BuffIconCooldownViewer, BuffBarCooldownViewer }) do
        if viewer and item and item.IsDescendantOf and item:IsDescendantOf(viewer) then return true end
    end
    return false
end

local function BloodBoneEnabled()
    return DKAssistDB and DKAssistDB.bloodBone and DKAssistDB.bloodBone.enabled
end

local function FrostProcCDMEnabled(key)
    local settings = DKAssistDB and DKAssistDB.burstTrackers and DKAssistDB.burstTrackers[key]
    -- The tracked-buff frame is also the reliable proc-state source for the
    -- movable icon. Register it regardless of the selected visual target.
    return settings ~= nil
end

local function BreathTrackerEnabled()
    local settings = DKAssistDB and DKAssistDB.breathTracker
    return settings and (settings.timelineEnabled or settings.iconEnabled) or false
end

local function RegisterItem(item)
    if not DKAssistDB or (not DKAssistDB.trackCDMPutrefy and not DKAssistDB.trackCDMFestering
        and not DKAssistDB.trackCDMSuddenDoom and not LesserGhoulEnabled() and not AnyBloodDnDEnabled()
        and not BloodBoneEnabled() and not FrostProcCDMEnabled("killingMachine")
        and not FrostProcCDMEnabled("rime") and not BreathTrackerEnabled()) then return end
    local ok, kind = pcall(function()
        -- Tracked Buffs may not expose a cooldown ID; cache their plain spell
        -- ID out of combat so their icon can still be decorated in combat.
        local spellID = GetCDMSpellID(item) or GetCDMItemSpellID(item)
        if addon:IsUnholySpec() and DKAssistDB.trackCDMPutrefy and spellID == PUTREFY_SPELL_ID then
            return "putrefy"
        elseif DKAssistDB.trackCDMFestering
            and (spellID == FESTERING_SCYTHE_SPELL_ID or spellID == FESTERING_STRIKE_SPELL_ID) then
            return "festering"
        elseif DKAssistDB.trackCDMSuddenDoom and (spellID == SUDDEN_DOOM_BUFF_ID or spellID == SUDDEN_DOOM_CDM_ID) then
            return "deathCoil"
        elseif LesserGhoulEnabled() and GetCDMItemSpellID(item) == LESSER_GHOUL_SPELL_ID then
            return "lesserGhoul"
        elseif AnyBloodDnDEnabled() and (spellID == DEATH_AND_DECAY_SPELL_ID
            or spellID == DEATH_AND_DECAY_BUFF_ID or GetCDMItemSpellID(item) == DEATH_AND_DECAY_BUFF_ID) then
            return (spellID == DEATH_AND_DECAY_BUFF_ID or IsBuffViewerItem(item))
                and "bloodDndBuff" or "bloodDndAbility"
        elseif BloodBoneEnabled() and (spellID == MARROWREND_SPELL_ID or spellID == DEATHS_CARESS_SPELL_ID) then
            return "bloodBoneAbility"
        elseif addon:IsFrostSpec() and FrostProcCDMEnabled("killingMachine")
            and KILLING_MACHINE_IDS[spellID] then
            return "killingMachine"
        elseif addon:IsFrostSpec() and FrostProcCDMEnabled("rime") and RIME_IDS[spellID] then
            return "rime"
        elseif addon:IsFrostSpec() and BreathTrackerEnabled() and IsBuffViewerItem(item)
            and spellID == BREATH_OF_SINDRAGOSA_ID then
            return "breath"
        end
    end)
    if not ok then return end

    if kind == "putrefy" then
        addon:RegisterCDMPutrefyFrame(item)
    elseif kind == "festering" then
        addon:RegisterCDMFesteringFrame(item)
    elseif kind == "deathCoil" or kind == "epidemic" then
        addon:RegisterCDMSuddenDoomFrame(item, kind)
    elseif kind == "lesserGhoul" then
        addon:RegisterCDMLesserGhoulFrame(item)
    elseif kind == "bloodDndAbility" then
        addon:RegisterCDMBloodDnDAbilityFrame(item)
        addon:RegisterCDMDnDMissingFrame(item)
    elseif kind == "bloodDndBuff" then
        addon:RegisterCDMBloodDnDBuffFrame(item)
        addon:ClearCDMDnDMissingFrame(item)
    elseif kind == "bloodBoneAbility" then
        addon:RegisterCDMBloodBoneAbilityFrame(item)
    elseif kind == "killingMachine" or kind == "rime" then
        addon:RegisterCDMFrostProcFrame(item, kind)
    elseif kind == "breath" then
        addon:RegisterCDMBreathFrame(item)
    end
end

-- EllesmereUI's CDM keeps the live Blizzard items in an itemFramePool and
-- exposes a canonical, cached spell ID helper.  Using it avoids reading
-- protected icon/texture values and works for its customised CDM layout.
local function RegisterEllesmereItem(item, euiCDM)
    if not euiCDM or not euiCDM.GetCanonicalSpellIDForFrame then return end
    local ok, kind = pcall(function()
        -- Ellesmere stores the resolved spell on its external frame data.
        -- Prefer that clean cached value; an active Blizzard CDM item can
        -- return a secret value from GetSpellID() during combat.
        local frameData = euiCDM._hookFrameData and euiCDM._hookFrameData[item]
        local spellID = frameData and frameData.spellID
            or euiCDM.GetCanonicalSpellIDForFrame(item)
            or item.spellID or item.overrideSpellID
        if addon:IsUnholySpec() and DKAssistDB.trackCDMPutrefy and spellID == PUTREFY_SPELL_ID then
            return "putrefy"
        elseif DKAssistDB.trackCDMFestering
            and (spellID == FESTERING_SCYTHE_SPELL_ID or spellID == FESTERING_STRIKE_SPELL_ID) then
            return "festering"
        elseif DKAssistDB.trackCDMSuddenDoom and (spellID == SUDDEN_DOOM_BUFF_ID or spellID == SUDDEN_DOOM_CDM_ID) then
            return "deathCoil"
        elseif LesserGhoulEnabled() and spellID == LESSER_GHOUL_SPELL_ID then
            return "lesserGhoul"
        elseif AnyBloodDnDEnabled() and (spellID == DEATH_AND_DECAY_SPELL_ID or spellID == DEATH_AND_DECAY_BUFF_ID) then
            return (spellID == DEATH_AND_DECAY_BUFF_ID or IsBuffViewerItem(item))
                and "bloodDndBuff" or "bloodDndAbility"
        elseif BloodBoneEnabled() and (spellID == MARROWREND_SPELL_ID or spellID == DEATHS_CARESS_SPELL_ID) then
            return "bloodBoneAbility"
        elseif addon:IsFrostSpec() and FrostProcCDMEnabled("killingMachine")
            and KILLING_MACHINE_IDS[spellID] then
            return "killingMachine"
        elseif addon:IsFrostSpec() and FrostProcCDMEnabled("rime") and RIME_IDS[spellID] then
            return "rime"
        end
    end)
    if not ok then return end
    if kind == "putrefy" then
        addon:RegisterCDMPutrefyFrame(item)
    elseif kind == "festering" then
        addon:RegisterCDMFesteringFrame(item)
    elseif kind == "deathCoil" or kind == "epidemic" then
        addon:RegisterCDMSuddenDoomFrame(item, kind)
    elseif kind == "lesserGhoul" then
        addon:RegisterCDMLesserGhoulFrame(item)
    elseif kind == "bloodDndAbility" then
        addon:RegisterCDMBloodDnDAbilityFrame(item)
        addon:RegisterCDMDnDMissingFrame(item)
    elseif kind == "bloodDndBuff" then
        -- Ellesmere's rendered bar icon is a persistent proxy, not the
        -- engine-driven aura frame.  Do not use it for Inside/Outside state.
        addon:ClearCDMDnDMissingFrame(item)
    elseif kind == "bloodBoneAbility" then
        addon:RegisterCDMBloodBoneAbilityFrame(item)
    elseif kind == "killingMachine" or kind == "rime" then
        addon:RegisterCDMFrostProcFrame(item, kind)
    end
end

local function InstallHook()
    if hooked or not CooldownViewerItemMixin then return end
    hooked = true
    hooksecurefunc(CooldownViewerItemMixin, "RefreshData", function(item)
        -- RefreshData participates in Blizzard's protected CDM update path.
        -- Never attach overlays from inside that call (especially in combat),
        -- because doing so taints the item and can later trigger
        -- ADDON_ACTION_FORBIDDEN on an unrelated protected Frame operation.
        if InCombatLockdown() then return end
        C_Timer.After(0, function()
            if not InCombatLockdown() then RegisterItem(item) end
        end)
    end)
end

-- The CDM may already have built its item pool before our hook is installed.
-- Register those current items directly, then the RefreshData hook handles
-- every later layout, talent, and cooldown update.
local function RegisterExistingItems()
    if InCombatLockdown() then return end
    local euiCDM = EllesmereUI and EllesmereUI._ModuleNS
        and EllesmereUI._ModuleNS["EllesmereUICooldownManager"]
    local viewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
    }

    -- EllesmereUI can re-anchor CDM icons into its own visible bars. Those
    -- icons are the correct frames to decorate, not necessarily the hidden
    -- Blizzard pool children beneath them.
    if euiCDM and euiCDM.cdmBarIcons then
        for _, icons in pairs(euiCDM.cdmBarIcons) do
            for _, icon in ipairs(icons) do
                RegisterEllesmereItem(icon, euiCDM)
            end
        end
    end

    for _, viewer in ipairs(viewers) do
        -- EllesmereUI (and current Blizzard CDM) keeps active items in this
        -- pool rather than exposing GetItemFrames().
        if viewer and viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
            for item in viewer.itemFramePool:EnumerateActive() do
                RegisterEllesmereItem(item, euiCDM)
                RegisterItem(item)
            end
        end
        if viewer and viewer.GetItemFrames then
            local ok, items = pcall(viewer.GetItemFrames, viewer)
            if ok and items then
                for _, item in ipairs(items) do
                    RegisterItem(item)
                end
            end
        end
    end
end

-- Used by the settings Rescan button.  It only asks Blizzard's Cooldown
-- Manager for its known item frames; it never enumerates the whole UI.
function addon:RefreshCDMTrackedItems()
    RegisterExistingItems()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED"
        and loadedAddon ~= "Blizzard_CooldownViewer"
        and loadedAddon ~= "EllesmereUICooldownManager" then return end
    C_Timer.After(0, function()
        InstallHook()
        RegisterExistingItems()
    end)
    C_Timer.After(2, RegisterExistingItems)
end)
