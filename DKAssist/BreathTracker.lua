-- Breath of Sindragosa elapsed-uptime prototype.
local addonName, addon = ...

local BREATH_ID = 1249658
local BASE_DURATION = 8
local EXTENSION = 0.8
local OBLITERATE_IDS = { [49020] = true }
local FROSTSCYTHE_IDS = { [207230] = true }
local HOWLING_BLAST_IDS = { [49184] = true }
local KILLING_MACHINE_CONSUMER_IDS = { [49020] = true, [207230] = true }
local PROC_AURA_IDS = {
    killingMachine = { 59052, 51124 },
    rime = { 59057 },
}
local DEFAULTS = {
    timelineEnabled = true,
    iconEnabled = false,
    timelineScale = 64,
    timelineOrientation = "horizontal",
    iconSize = 64,
    fontSize = 18,
    showSpellName = true,
    showInfo = false,
    timelineLocked = false,
    iconLocked = false,
    timelinePosition = nil,
    iconPosition = nil,
}
addon.DEFAULT_DB.breathTracker = CopyTable(DEFAULTS)

local frame
local iconFrame
local nativeTimelineHost
local nativeIconHost
local nativeTimelineContainer
local nativeIconContainer
local nativeTimelineButton
local nativeIconButton
local nativeInfoOverlay
local nativeElapsedFormatter
local nativeElapsedBinding
local nativeElapsedOptions
local nativeAuraReady = false
local nativeAuraDeferred = false
local nativeHostsSuppressed = false
local nativeLastTotal
local FinishBreath
local active = false
local startedAt = 0
local endsAt = 0
local extendedBy = 0
local runID = 0
local testMode = false
local lastProcResult = "Waiting for proc"
local pendingProc = { killingMachine = 0, rime = 0 }
local scytheCastToken = 0
local pendingScytheUntil = 0
local pendingScytheExtended = false
local breathAuraSeen = false
local breathAuraMissingSince = 0
local breathCDMSeen = false
local breathCDMMissingSince = 0
local breathCDMFrames = setmetatable({}, { __mode = "k" })
local procGlow = {
    killingMachine = { active = false, hiddenAt = 0 },
    rime = { active = false, hiddenAt = 0 },
}

local function Settings()
    if not DKAssistDB then return DEFAULTS end
    if type(DKAssistDB.breathTracker) ~= "table" then DKAssistDB.breathTracker = CopyTable(DEFAULTS) end
    local saved = DKAssistDB.breathTracker
    if saved.timelineEnabled == nil and saved.enabled ~= nil then saved.timelineEnabled = saved.enabled ~= false end
    if saved.timelineLocked == nil and saved.locked ~= nil then saved.timelineLocked = saved.locked end
    if saved.timelinePosition == nil and saved.position ~= nil then saved.timelinePosition = saved.position end
    if saved.timelineScale == nil and saved.scale then
        saved.timelineScale = math.floor(saved.scale * 0.64 + 0.5)
    end
    for key, value in pairs(DEFAULTS) do
        if DKAssistDB.breathTracker[key] == nil then DKAssistDB.breathTracker[key] = value end
    end
    return DKAssistDB.breathTracker
end

function addon:GetBreathTrackerSettings()
    return Settings()
end

function addon:RegisterCDMBreathFrame(cdmFrame)
    if cdmFrame then breathCDMFrames[cdmFrame] = true end
end

local function GetBreathCDMActive()
    local foundState = false
    for cdmFrame in pairs(breathCDMFrames) do
        if cdmFrame and cdmFrame.IsActive then
            local ok, isActive = pcall(function()
                return cdmFrame:IsActive() and true or false
            end)
            if ok then
                foundState = true
                if isActive then return true end
            end
        end
    end
    return foundState and false or nil
end

local function SpellNameIs(spellID, expected)
    if not spellID or not C_Spell or not C_Spell.GetSpellName then return false end
    local ok, name = pcall(C_Spell.GetSpellName, spellID)
    return ok and name == expected
end

local function SetInfoText(display, total, extension)
    display.info:SetText(string.format("Total: %.1fs\nExtend: +%.1fs", total, extension))
end

local function HasProcAura(key)
    local spellIDs = PROC_AURA_IDS[key]
    if not spellIDs or not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return false end
    for _, spellID in ipairs(spellIDs) do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and aura ~= nil then return true end
    end
    return false
end

local function HasBreathAura()
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return false end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, BREATH_ID)
    return ok and aura ~= nil
end

local function ProcWasReady(key)
    local proc = procGlow[key]
    return HasProcAura(key)
        or addon:IsFrostProcActive(key)
        or proc.active
        or (proc.hiddenAt > 0 and GetTime() - proc.hiddenAt <= 0.50)
end

local function PollOverlays(key, spellIDs)
    if not C_SpellActivationOverlay or not C_SpellActivationOverlay.IsSpellOverlayed then return end
    local shown, gotResult = false, false
    for spellID in pairs(spellIDs) do
        local ok, value = pcall(C_SpellActivationOverlay.IsSpellOverlayed, spellID)
        if ok and type(value) == "boolean" then
            gotResult = true
            if value then shown = true end
        end
    end
    if not gotResult then return end
    local proc = procGlow[key]
    if proc.active and not shown then proc.hiddenAt = GetTime() end
    proc.active = shown
end

local function CreateDisplay()
    if frame then return frame end
    frame = CreateFrame("Frame", "DKAssistBreathElapsedTracker", UIParent, "BackdropTemplate")
    frame:SetSize(380, 64)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not Settings().timelineLocked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Settings().timelinePosition = { point, relativePoint, x, y }
    end)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.02, 0.03, 0.06, 0.78)
    frame:SetBackdropBorderColor(0.30, 0.30, 0.34, 1)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetTexture("Interface\\Icons\\Spell_DeathKnight_BreathOfSindragosa")
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    frame.bar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.bar:SetStatusBarColor(0.42, 0.24, 0.70, 1)
    frame.bar:SetMinMaxValues(0, BASE_DURATION)
    frame.bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    frame.bar:SetBackdropColor(0.18, 0.18, 0.21, 1)

    frame.timer = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.timer:SetTextColor(0.20, 1.00, 0.25, 1)

    frame.info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.info:SetTextColor(0.65, 1.00, 0.25, 1)
    frame.infoBG = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.infoBG:SetColorTexture(0.01, 0.015, 0.025, 0.82)
    frame.divider = frame:CreateTexture(nil, "BORDER")
    frame.divider:SetColorTexture(0.38, 0.42, 0.48, 0.85)
    frame.unlock = frame:CreateTexture(nil, "OVERLAY")
    frame.unlock:SetAllPoints()
    frame.unlock:SetColorTexture(0, 0.75, 1, 0.10)
    frame:Hide()
    return frame
end

local function CreateIconDisplay()
    if iconFrame then return iconFrame end
    iconFrame = CreateFrame("Frame", "DKAssistBreathElapsedIcon", UIParent, "BackdropTemplate")
    iconFrame:SetPoint("CENTER", UIParent, "CENTER", 120, 100)
    iconFrame:SetFrameStrata("MEDIUM")
    iconFrame:SetClampedToScreen(true)
    iconFrame:SetMovable(true); iconFrame:EnableMouse(true); iconFrame:RegisterForDrag("LeftButton")
    iconFrame:SetBackdrop({ bgFile = "Interface\\Icons\\Spell_DeathKnight_BreathOfSindragosa", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    iconFrame:SetBackdropBorderColor(0.35, 0.35, 0.38, 1)
    iconFrame:SetScript("OnDragStart", function(self) if not Settings().iconLocked then self:StartMoving() end end)
    iconFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Settings().iconPosition = { point, relativePoint, x, y }
    end)
    iconFrame.timer = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    iconFrame.timer:SetPoint("TOP", iconFrame, "BOTTOM", 0, -2)
    iconFrame.timer:SetTextColor(0.20, 1.00, 0.25, 1)
    iconFrame.nameText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    iconFrame.nameText:SetPoint("TOP", iconFrame.timer, "BOTTOM", 0, -1)
    iconFrame.nameText:SetText("Breath of Sindragosa")
    iconFrame.nameText:SetTextColor(1, 0.82, 0, 1)
    iconFrame.stats = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    iconFrame.stats:SetPoint("TOP", iconFrame.nameText, "BOTTOM", 0, -1)
    iconFrame.stats:SetTextColor(1, 0.92, 0.15, 1)
    iconFrame.stats:SetText("Total: 0.0s  Extend: +0.0s")
    iconFrame.unlock = iconFrame:CreateTexture(nil, "OVERLAY")
    iconFrame.unlock:SetAllPoints(); iconFrame.unlock:SetColorTexture(0, 0.75, 1, 0.16)
    iconFrame:Hide()
    return iconFrame
end

-- Midnight 12.1 keeps the identity and timing of combat auras protected from
-- ordinary Lua.  AuraContainer/AuraButton is Blizzard's supported display
-- path: the client owns the Breath assignment and drives these regions from
-- the protected Duration object.  In particular, ElapsedDuration cannot
-- freeze just because one of our fallback end signals was missed or arrived
-- early.
local function GetNativeElapsedOptions()
    if nativeElapsedOptions then return nativeElapsedOptions end
    if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter
        and C_DurationUtil and C_DurationUtil.CreateDurationTextBinding
        and Enum and Enum.DurationTextBindingProperty
        and Enum.NumericRuleFormatRounding) then
        return nil
    end

    nativeElapsedFormatter = C_StringUtil.CreateNumericRuleFormatter()
    nativeElapsedFormatter:SetBreakpoints({
        {
            threshold = 0,
            step = 0.1,
            rounding = Enum.NumericRuleFormatRounding.Down,
            format = "%.1f",
        },
    })

    nativeElapsedBinding = C_DurationUtil.CreateDurationTextBinding()
    nativeElapsedBinding:SetUpdateInterval(0.05)
    nativeElapsedBinding:SetEnabled(true)
    nativeElapsedOptions = {
        binding = nativeElapsedBinding,
        textFormat = {
            formatString = "{}",
            components = {
                {
                    property = Enum.DurationTextBindingProperty.ElapsedDuration,
                    formatter = nativeElapsedFormatter,
                },
            },
        },
    }
    return nativeElapsedOptions
end

local function LayoutNativeTimelineButton(button)
    if not (button and button.dkVisual) then return end
    local settings = Settings()
    local scale = (settings.timelineScale or 64) / 64
    local vertical = settings.timelineOrientation == "vertical"
    -- This only controls the native button's presentation. Aura lifetime,
    -- elapsed text, and the status bar remain owned by Blizzard.
    local showInfo = false
    local visual = button.dkVisual
    local icon = button.dkIcon
    local bar = button.dkBar
    local timer = button.dkTimer
    local info = button.dkInfo
    local divider = button.dkDivider

    icon:ClearAllPoints()
    bar:ClearAllPoints()
    timer:ClearAllPoints()
    timer:Show()
    button.dkMainBG:ClearAllPoints()
    -- The text itself is drawn by a plain overlay outside AuraContainer's
    -- clipped child region. Geometry is still reserved here.
    if info then info:ClearAllPoints(); info:Hide() end
    if divider then divider:ClearAllPoints(); divider:Hide() end

    if vertical then
        local iconSide = math.floor(46 * scale + 0.5)
        icon:SetSize(iconSide, iconSide)
        icon:SetPoint("TOP", visual, "TOP", 0, -8 * scale)
        timer:SetPoint("TOP", icon, "BOTTOM", 0, -4 * scale)
        bar:SetOrientation("VERTICAL")
        bar:SetWidth(math.max(8, math.floor(10 * scale + 0.5)))
        bar:SetPoint("TOP", timer, "BOTTOM", 0, -8 * scale)
        bar:SetPoint("BOTTOM", visual, "BOTTOM", 0, (showInfo and 66 or 10) * scale)
        button.dkMainBG:SetPoint("TOPLEFT", visual, "TOPLEFT", 1, -1)
        button.dkMainBG:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", -1, (showInfo and 59 or 1) * scale)
        if divider then
            divider:SetPoint("BOTTOMLEFT", visual, "BOTTOMLEFT", 6 * scale, 59 * scale)
            divider:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", -6 * scale, 59 * scale)
        end
        if info then
            info:SetPoint("BOTTOM", visual, "BOTTOM", 0, 8 * scale)
            info:SetWidth(84 * scale)
            info:SetJustifyH("CENTER")
        end
    else
        local iconSide = math.floor(48 * scale + 0.5)
        icon:SetSize(iconSide, iconSide)
        icon:SetPoint("LEFT", visual, "LEFT", 8 * scale, 0)
        bar:SetOrientation("HORIZONTAL")
        bar:SetHeight(math.max(8, math.floor(8 * scale + 0.5)))
        bar:SetPoint("LEFT", icon, "RIGHT", 12 * scale, -9 * scale)
        bar:SetPoint("RIGHT", visual, "RIGHT", (showInfo and -140 or -12) * scale, -9 * scale)
        timer:SetPoint("BOTTOM", bar, "TOP", 0, 2 * scale)
        button.dkMainBG:SetPoint("TOPLEFT", visual, "TOPLEFT", 1, -1)
        button.dkMainBG:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", (showInfo and -130 or -1) * scale, 1)
        if divider then
            divider:SetPoint("TOPRIGHT", visual, "TOPRIGHT", -130 * scale, -6 * scale)
            divider:SetPoint("BOTTOMRIGHT", visual, "BOTTOMRIGHT", -130 * scale, 6 * scale)
        end
        if info then
            info:SetPoint("RIGHT", visual, "RIGHT", -8 * scale, 0)
            info:SetWidth(114 * scale)
            info:SetJustifyH("CENTER")
        end
    end

    timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    if info then info:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 4), "OUTLINE") end
end

local function LayoutNativeIconButton(button)
    if not (button and button.dkVisual) then return end
    local settings = Settings()
    button.dkTimer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    button.dkName:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 5), "OUTLINE")
    button.dkName:SetShown(settings.showSpellName ~= false)
    if button.dkStats then
        button.dkStats:SetFont(STANDARD_TEXT_FONT, math.max(9, (settings.fontSize or 18) - 6), "OUTLINE")
        button.dkStats:Hide()
    end
end

local function InitializeNativeTimelineButton(button)
    button:SetAllPoints(button:GetParent())

    local visual = CreateFrame("Frame", nil, button, "BackdropTemplate")
    visual:SetAllPoints(button)
    visual:EnableMouse(false)
    visual:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    visual:SetBackdropColor(0.02, 0.03, 0.06, 0.08)
    visual:SetBackdropBorderColor(0.00, 0.78, 0.92, 1)

    local mainBG = visual:CreateTexture(nil, "BACKGROUND")
    mainBG:SetColorTexture(0.02, 0.03, 0.06, 0.94)

    local icon = visual:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Spell_DeathKnight_BreathOfSindragosa")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local bar = CreateFrame("StatusBar", nil, visual, "BackdropTemplate")
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.42, 0.24, 0.70, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    bar:SetBackdropColor(0.18, 0.18, 0.21, 1)

    local timer = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    timer:SetTextColor(0.20, 1.00, 0.25, 1)

    local divider = visual:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.00, 0.78, 0.92, 0.45)
    divider:SetWidth(1)

    local info = visual:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetTextColor(1, 0.92, 0.15, 1)
    info:SetText("Total: 0.0s\nExtend: +0.0s")

    button.dkVisual = visual
    button.dkMainBG = mainBG
    button.dkIcon = icon
    button.dkBar = bar
    button.dkTimer = timer
    button.dkDivider = divider
    button.dkInfo = info
    nativeTimelineButton = button

    -- Read Blizzard's bound elapsed label only for companion statistics. This
    -- never starts, stops, or extends the native timeline.
    visual:SetScript("OnUpdate", function(self, elapsed)
        self.dkInfoTick = (self.dkInfoTick or 0) + elapsed
        if self.dkInfoTick < 0.05 then return end
        self.dkInfoTick = 0
        local value = active and not testMode and math.max(0, GetTime() - startedAt) or nil
        if value then
            info:SetFormattedText("Total: %.1fs\nExtend: +%.1fs", value, math.max(0, value - BASE_DURATION))
        end
    end)

    button:SetIcon(icon)
    local barOptions = {}
    if Enum and Enum.StatusBarTimerDirection then
        barOptions.direction = Enum.StatusBarTimerDirection.ElapsedTime
    end
    button:SetDurationBar(bar, barOptions)
    button:SetDurationText(timer, GetNativeElapsedOptions())
    LayoutNativeTimelineButton(button)
end

local function InitializeNativeIconButton(button)
    button:SetAllPoints(button:GetParent())

    local visual = CreateFrame("Frame", nil, button, "BackdropTemplate")
    visual:SetAllPoints(button)
    visual:EnableMouse(false)
    visual:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    visual:SetBackdropBorderColor(0.00, 0.78, 0.92, 1)

    local icon = visual:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(visual)
    icon:SetTexture("Interface\\Icons\\Spell_DeathKnight_BreathOfSindragosa")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local timer = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timer:SetPoint("TOP", visual, "BOTTOM", 0, -2)
    timer:SetTextColor(0.20, 1.00, 0.25, 1)
    timer:Show()
    local nameText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOP", timer, "BOTTOM", 0, -1)
    nameText:SetText("Breath of Sindragosa")
    nameText:SetTextColor(1, 0.82, 0, 1)
    local statsText = visual:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsText:SetPoint("TOP", nameText, "BOTTOM", 0, -1)
    statsText:SetTextColor(1, 0.92, 0.15, 1)
    statsText:SetText("Total: 0.0s  Extend: +0.0s")

    button.dkVisual = visual
    button.dkIcon = icon
    button.dkTimer = timer
    button.dkName = nameText
    button.dkStats = statsText
    nativeIconButton = button

    visual:SetScript("OnUpdate", function(self, elapsed)
        self.dkStatsTick = (self.dkStatsTick or 0) + elapsed
        if self.dkStatsTick < 0.05 then return end
        self.dkStatsTick = 0
        statsText:Hide()
        local value = active and not testMode and math.max(0, GetTime() - startedAt) or nil
        if value then
            statsText:SetFormattedText("Total: %.1fs  Extend: +%.1fs", value, math.max(0, value - BASE_DURATION))
        end
    end)

    button:SetIcon(icon)
    button:SetDurationText(timer, GetNativeElapsedOptions())
    LayoutNativeIconButton(button)
end

local function CreateNativeInfoOverlay()
    if nativeInfoOverlay then return nativeInfoOverlay end
    local overlay = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    overlay:SetFrameStrata("HIGH")
    overlay:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    overlay:SetBackdropColor(0.02, 0.03, 0.06, 0.94)
    overlay:EnableMouse(false)

    local divider = overlay:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.00, 0.78, 0.92, 0.45)
    local info = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetTextColor(1, 0.92, 0.15, 1)
    info:SetJustifyH("CENTER")
    info:SetText("Total: 0.0s\nExtend: +0.0s")
    overlay.divider = divider
    overlay.info = info

    overlay:SetScript("OnUpdate", function(self, elapsed)
        local settings = Settings()
        -- AuraButtons are protected in Midnight; even IsVisible() taints and
        -- throws in combat. Never inspect their frame state from addon code.
        local tracking = active and not testMode and not nativeHostsSuppressed
        local showTimelineInfo = tracking
            and settings.timelineEnabled ~= false
            and settings.showInfo ~= false
        self:SetAlpha(showTimelineInfo and 1 or 0)
        if not tracking then return end
        self.dkInfoTick = (self.dkInfoTick or 0) + elapsed
        if self.dkInfoTick < 0.05 then return end
        self.dkInfoTick = 0
        local value = math.max(0, GetTime() - startedAt)
        nativeLastTotal = value
        info:SetFormattedText("Total: %.1fs\nExtend: +%.1fs", value, math.max(0, value - BASE_DURATION))
    end)
    overlay:SetAlpha(0)
    overlay:Show()
    nativeInfoOverlay = overlay
    return overlay
end

local function CreateNativeAuraContainer(host, key, initializer)
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, host, "CustomAuraContainerTemplate")
    if not ok or not container then return nil end

    local configured = pcall(function()
        container:SetAllPoints(host)
        container:AddAuraSlot(key, "HELPFUL|PLAYER", {
            candidateFilters = {
                includeSpellIDs = { [BREATH_ID] = true },
            },
            initializeFrame = initializer,
        })
        -- Unit assignment comes after the slot declaration so the container
        -- registers UNIT_AURA with real content already present.
        container:SetUnit("player")
        container:SetEnabled(true)
        container:Show()
        container:UpdateAllAuras()
    end)
    if not configured then
        pcall(container.Hide, container)
        return nil
    end
    return container
end

local function RefreshNativeAuraHosts()
    local settings = Settings()
    if nativeTimelineHost and frame then
        local scale = (settings.timelineScale or 64) / 64
        nativeTimelineHost:ClearAllPoints()
        if settings.timelineOrientation == "vertical" then
            nativeTimelineHost:SetPoint("TOP", frame, "TOP", 0, 0)
            nativeTimelineHost:SetSize(math.floor(94 * scale + 0.5), math.floor(190 * scale + 0.5))
        else
            nativeTimelineHost:SetPoint("LEFT", frame, "LEFT", 0, 0)
            nativeTimelineHost:SetSize(math.floor(260 * scale + 0.5), math.floor(64 * scale + 0.5))
        end
        nativeTimelineHost:SetShown(settings.timelineEnabled ~= false and not nativeHostsSuppressed)
    end
    if nativeIconHost then nativeIconHost:SetShown(settings.iconEnabled == true and not nativeHostsSuppressed) end
    -- Styling an AuraButton subtree is only safe before combat lockdown.  The
    -- protected engine continues updating its already-bound timer in combat.
    if not (InCombatLockdown and InCombatLockdown()) then
        if nativeTimelineButton then pcall(LayoutNativeTimelineButton, nativeTimelineButton) end
        if nativeIconButton then pcall(LayoutNativeIconButton, nativeIconButton) end
    end
end

local function EnsureNativeAuraDisplays()
    if nativeAuraReady then
        RefreshNativeAuraHosts()
        return true
    end
    if InCombatLockdown and InCombatLockdown() then
        nativeAuraDeferred = true
        return false
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
    end
    if not GetNativeElapsedOptions() then return false end

    local display = CreateDisplay()
    local icon = CreateIconDisplay()
    if not nativeTimelineHost then
        nativeTimelineHost = CreateFrame("Frame", "DKAssistBreathNativeTimelineHost", UIParent)
        nativeTimelineHost:SetAllPoints(display)
        nativeTimelineHost:SetFrameStrata("HIGH")
        nativeTimelineHost:EnableMouse(false)
    end
    if not nativeIconHost then
        nativeIconHost = CreateFrame("Frame", "DKAssistBreathNativeIconHost", UIParent)
        nativeIconHost:SetAllPoints(icon)
        nativeIconHost:SetFrameStrata("HIGH")
        nativeIconHost:EnableMouse(false)
    end

    if not nativeTimelineContainer then
        nativeTimelineContainer = CreateNativeAuraContainer(
            nativeTimelineHost, "dkassist_breath_timeline", InitializeNativeTimelineButton)
    end
    if not nativeIconContainer then
        nativeIconContainer = CreateNativeAuraContainer(
            nativeIconHost, "dkassist_breath_icon", InitializeNativeIconButton)
    end

    nativeAuraReady = nativeTimelineContainer ~= nil and nativeIconContainer ~= nil
    nativeAuraDeferred = not nativeAuraReady
    RefreshNativeAuraHosts()
    addon.breathNativeAuraReady = nativeAuraReady
    return nativeAuraReady
end

local function ApplySettings()
    local display, icon, settings = CreateDisplay(), CreateIconDisplay(), Settings()
    local scale = (settings.timelineScale or 64) / 64
    local vertical = settings.timelineOrientation == "vertical"
    local showInfo = false
    display.icon:ClearAllPoints(); display.bar:ClearAllPoints(); display.timer:ClearAllPoints()
    display.info:ClearAllPoints(); display.infoBG:ClearAllPoints(); display.divider:ClearAllPoints()
    display.infoBG:SetShown(showInfo); display.divider:SetShown(showInfo); display.info:SetShown(showInfo)
    display.timer:Show()
    if vertical then
        display:SetSize(math.floor(94 * scale + 0.5), math.floor((showInfo and 250 or 190) * scale + 0.5))
        local iconSide = math.floor(46 * scale + 0.5)
        display.icon:SetSize(iconSide, iconSide)
        display.icon:SetPoint("TOP", display, "TOP", 0, -8 * scale)
        display.timer:SetPoint("TOP", display.icon, "BOTTOM", 0, -4 * scale)
        display.bar:SetOrientation("VERTICAL")
        display.bar:SetWidth(math.max(8, math.floor(10 * scale + 0.5)))
        display.bar:SetPoint("TOP", display.timer, "BOTTOM", 0, -8 * scale)
        display.bar:SetPoint("BOTTOM", display, "BOTTOM", 0, (showInfo and 66 or 10) * scale)
        display.info:SetPoint("BOTTOM", display, "BOTTOM", 0, 7 * scale)
        display.info:SetWidth(math.floor(84 * scale + 0.5)); display.info:SetJustifyH("CENTER")
        if showInfo then
            display.infoBG:SetPoint("BOTTOMLEFT", display, "BOTTOMLEFT", 1, 1)
            display.infoBG:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -1, 1)
            display.infoBG:SetHeight(math.floor(58 * scale + 0.5))
            display.divider:SetPoint("BOTTOMLEFT", display, "BOTTOMLEFT", 5 * scale, 59 * scale)
            display.divider:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -5 * scale, 59 * scale)
            display.divider:SetHeight(1)
        end
    else
        display:SetSize(math.floor((showInfo and 380 or 260) * scale + 0.5), math.floor(64 * scale + 0.5))
        local iconSide = math.floor(48 * scale + 0.5)
        display.icon:SetSize(iconSide, iconSide)
        display.icon:SetPoint("LEFT", display, "LEFT", 8 * scale, 0)
        display.bar:SetOrientation("HORIZONTAL")
        display.bar:SetHeight(math.max(8, math.floor(8 * scale + 0.5)))
        display.bar:SetPoint("LEFT", display.icon, "RIGHT", 12 * scale, -9 * scale)
        display.bar:SetPoint("RIGHT", display, "RIGHT", (showInfo and -140 or -12) * scale, -9 * scale)
        display.timer:SetPoint("BOTTOM", display.bar, "TOP", 0, 2 * scale)
        display.info:SetPoint("RIGHT", display, "RIGHT", -7 * scale, 0)
        display.info:SetWidth(math.floor(120 * scale + 0.5)); display.info:SetJustifyH("CENTER")
        if showInfo then
            display.infoBG:SetPoint("TOPRIGHT", display, "TOPRIGHT", -1, -1)
            display.infoBG:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -1, 1)
            display.infoBG:SetWidth(math.floor(130 * scale + 0.5))
            display.divider:SetPoint("TOPRIGHT", display, "TOPRIGHT", -130 * scale, -5 * scale)
            display.divider:SetPoint("BOTTOMRIGHT", display, "BOTTOMRIGHT", -130 * scale, 5 * scale)
            display.divider:SetWidth(1)
        end
    end
    display.timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    display.info:SetFont(STANDARD_TEXT_FONT, math.max(9, (settings.fontSize or 18) - 7), "OUTLINE")
    display:EnableMouse(not settings.timelineLocked)
    display.unlock:SetShown(not settings.timelineLocked)
    if settings.timelinePosition then
        display:ClearAllPoints()
        display:SetPoint(settings.timelinePosition[1], UIParent, settings.timelinePosition[2], settings.timelinePosition[3], settings.timelinePosition[4])
    end
    icon:SetSize(settings.iconSize or 64, settings.iconSize or 64)
    icon.timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    icon.timer:Show()
    icon.nameText:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 5), "OUTLINE")
    icon.nameText:SetShown(settings.showSpellName ~= false)
    icon.stats:SetFont(STANDARD_TEXT_FONT, math.max(9, (settings.fontSize or 18) - 6), "OUTLINE")
    icon.stats:Hide()
    icon:EnableMouse(not settings.iconLocked); icon.unlock:SetShown(not settings.iconLocked)
    if settings.iconPosition then
        icon:ClearAllPoints()
        icon:SetPoint(settings.iconPosition[1], UIParent, settings.iconPosition[2], settings.iconPosition[3], settings.iconPosition[4])
    end
    RefreshNativeAuraHosts()
end

local function StartBreath(force)
    local settings = Settings()
    if not force and not settings.timelineEnabled and not settings.iconEnabled then return end
    local now = GetTime()
    nativeHostsSuppressed = false
    nativeLastTotal = nil
    testMode = false
    runID = runID + 1
    active = true
    startedAt = now
    endsAt = now + BASE_DURATION
    extendedBy = 0
    breathAuraSeen = false
    breathAuraMissingSince = 0
    breathCDMSeen = false
    breathCDMMissingSince = 0
    lastProcResult = "Waiting for proc"
    local display = CreateDisplay()
    ApplySettings()
    display.timer:SetText("0.0")
    CreateIconDisplay().timer:SetText("0.0")
    display.bar:SetMinMaxValues(0, BASE_DURATION); display.bar:SetValue(BASE_DURATION)
    SetInfoText(display, 0, 0)
    -- A real Breath uses only the AuraContainer presentation.  Keeping the
    -- legacy timer behind it made that old timer reappear and run forever as
    -- soon as the protected AuraButton correctly hid at aura removal.
    display:SetShown(force or (settings.timelineEnabled and not nativeTimelineContainer))
    CreateIconDisplay():SetShown(force or (settings.iconEnabled and not nativeIconContainer))
end

local function ExtendBreath()
    if not active or endsAt <= GetTime() then return end
    endsAt = endsAt + EXTENSION
    extendedBy = extendedBy + EXTENSION
    if frame then frame.bar:SetMinMaxValues(0, endsAt - startedAt) end
end

local function StopBreath()
    active = false
    testMode = false
    runID = runID + 1
    if frame then frame:Hide() end
    if iconFrame then iconFrame:Hide() end
end

FinishBreath = function(actualTotal)
    if not active then return end
    active = false
    nativeHostsSuppressed = true
    RefreshNativeAuraHosts()
    if frame then frame:Hide() end
    if iconFrame then iconFrame:Hide() end
end

function addon:RefreshBreathTracker()
    ApplySettings()
    EnsureNativeAuraDisplays()
    local settings = Settings()
    if not settings.timelineEnabled and not settings.iconEnabled then StopBreath()
    elseif active then
        if frame then frame:SetShown(settings.timelineEnabled and (testMode or not nativeTimelineContainer)) end
        if iconFrame then iconFrame:SetShown(settings.iconEnabled and (testMode or not nativeIconContainer)) end
    end
end

function addon:TestBreathTracker()
    StartBreath(true)
    testMode = true
    endsAt = startedAt + 12
    extendedBy = 4
end

function addon:StopBreathTrackerTest()
    if testMode then StopBreath() end
end

function addon:ResetBreathTrackerPosition()
    Settings().timelinePosition = nil
    Settings().iconPosition = nil
    local display = CreateDisplay()
    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, "CENTER", 0, 220)
    local icon = CreateIconDisplay()
    icon:ClearAllPoints(); icon:SetPoint("CENTER", UIParent, "CENTER", 120, 100)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterEvent("UNIT_SPELLCAST_SENT")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
events:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
events:SetScript("OnEvent", function(_, event, unit, arg2, arg3, arg4)
    if event == "PLAYER_LOGIN" then
        -- Let Core finish SavedVariables migration before freezing the native
        -- button geometry inside initializeFrame.
        C_Timer.After(0, function()
            ApplySettings()
            EnsureNativeAuraDisplays()
        end)
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if nativeAuraDeferred or not nativeAuraReady then EnsureNativeAuraDisplays() end
        if active and not testMode then
            FinishBreath(nativeLastTotal or (GetTime() - startedAt))
        end
        return
    end
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local overlaySpellID = unit
        local key
        if OBLITERATE_IDS[overlaySpellID] or FROSTSCYTHE_IDS[overlaySpellID]
            or SpellNameIs(overlaySpellID, "Obliterate") or SpellNameIs(overlaySpellID, "Frostscythe") then key = "killingMachine"
        elseif HOWLING_BLAST_IDS[overlaySpellID] or SpellNameIs(overlaySpellID, "Howling Blast") then key = "rime" end
        if key then
            local shown = event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"
            procGlow[key].active = shown
            if not shown then procGlow[key].hiddenAt = GetTime() end
        end
        return
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        if unit == "player" then StopBreath() end
        return
    end
    if unit ~= "player" then return end
    if event == "UNIT_SPELLCAST_SENT" then
        local sentSpellID = arg4
        if sentSpellID == BREATH_ID or SpellNameIs(sentSpellID, "Breath of Sindragosa") then
            return
        elseif OBLITERATE_IDS[sentSpellID] or FROSTSCYTHE_IDS[sentSpellID]
            or SpellNameIs(sentSpellID, "Obliterate") or SpellNameIs(sentSpellID, "Frostscythe") then
            if ProcWasReady("killingMachine") then pendingProc.killingMachine = GetTime() + 1.0 end
            if FROSTSCYTHE_IDS[sentSpellID] or SpellNameIs(sentSpellID, "Frostscythe") then
                scytheCastToken = scytheCastToken + 1
                pendingScytheUntil = GetTime() + 1.0
                pendingScytheExtended = false
            end
        elseif HOWLING_BLAST_IDS[sentSpellID] or SpellNameIs(sentSpellID, "Howling Blast") then
            if ProcWasReady("rime") then pendingProc.rime = GetTime() + 1.0 end
        end
        return
    end
    local spellID = arg3
    if spellID == BREATH_ID or SpellNameIs(spellID, "Breath of Sindragosa") then
        StartBreath()
    elseif active and (OBLITERATE_IDS[spellID] or SpellNameIs(spellID, "Obliterate")) then
        local ready = ProcWasReady("killingMachine") or pendingProc.killingMachine >= GetTime()
        pendingProc.killingMachine = 0
        if ready then ExtendBreath(); lastProcResult = "KM YES +0.8"
        else lastProcResult = "KM NO" end
    elseif active and (FROSTSCYTHE_IDS[spellID] or SpellNameIs(spellID, "Frostscythe")) then
        local ready = ProcWasReady("killingMachine") or pendingProc.killingMachine >= GetTime()
        pendingProc.killingMachine = 0
        if ready and not pendingScytheExtended then
            pendingScytheExtended = true
            ExtendBreath()
            lastProcResult = "Scythe YES +0.8"
        elseif not ready and not pendingScytheExtended then
            local token = scytheCastToken
            C_Timer.After(0.30, function()
                if token == scytheCastToken and not pendingScytheExtended then
                    lastProcResult = "Scythe NO"
                end
            end)
        end
    elseif active and (HOWLING_BLAST_IDS[spellID] or SpellNameIs(spellID, "Howling Blast")) then
        local ready = ProcWasReady("rime") or pendingProc.rime >= GetTime()
        pendingProc.rime = 0
        if ready then ExtendBreath(); lastProcResult = "Rime YES +0.8"
        else lastProcResult = "Rime NO" end
    end
end)

local driver = CreateFrame("Frame")
local accumulator = 0
driver:SetScript("OnUpdate", function(_, delta)
    if not active then return end
    PollOverlays("killingMachine", KILLING_MACHINE_CONSUMER_IDS)
    PollOverlays("rime", HOWLING_BLAST_IDS)
    local now = GetTime()
    accumulator = accumulator + delta
    if accumulator < 0.05 then return end
    accumulator = 0
    if not testMode then
        local cdmActive = GetBreathCDMActive()
        if cdmActive == true then
            breathCDMSeen = true
            breathCDMMissingSince = 0
            breathAuraSeen = true
            breathAuraMissingSince = 0
        elseif cdmActive == false and breathCDMSeen then
            if breathCDMMissingSince == 0 then breathCDMMissingSince = now end
            if now - breathCDMMissingSince >= 0.50 then
                FinishBreath(nativeLastTotal or (now - startedAt))
                return
            end
        elseif HasBreathAura() then
            breathAuraSeen = true
            breathAuraMissingSince = 0
        elseif breathAuraSeen then
            -- A single negative read can be transient under Midnight's aura
            -- restrictions. Require one continuous second of absence after a
            -- confirmed positive read before ending the run.
            if breathAuraMissingSince == 0 then breathAuraMissingSince = now end
            if now - breathAuraMissingSince >= 1.00 then
                FinishBreath(breathAuraMissingSince - startedAt)
                return
            end
        end
        -- PLAYER_REGEN_ENABLED can be delayed or missed by restricted event
        -- handling. This read-only state is an independent cleanup guarantee.
        if now - startedAt >= 0.50 and UnitAffectingCombat and not UnitAffectingCombat("player") then
            FinishBreath(nativeLastTotal or (now - startedAt))
            return
        end
        if now >= startedAt + 120 then
            -- Emergency cleanup only; never use the predicted duration as an
            -- end signal because proc aura reads are restricted in combat.
            FinishBreath(now - startedAt)
            return
        end
    elseif now >= endsAt then
        FinishBreath(now - startedAt)
        return
    end
    local display = CreateDisplay()
    display.timer:SetText(string.format("%.1f", now - startedAt))
    CreateIconDisplay().timer:SetText(string.format("%.1f", now - startedAt))
    local elapsed = now - startedAt
    local total = math.max(endsAt - startedAt, elapsed)
    display.bar:SetMinMaxValues(0, total)
    display.bar:SetValue(math.max(0, endsAt - now))
    SetInfoText(display, elapsed, math.max(extendedBy, elapsed - BASE_DURATION))
    CreateIconDisplay().stats:SetFormattedText("Total: %.1fs  Extend: +%.1fs", elapsed, math.max(extendedBy, elapsed - BASE_DURATION))
end)
