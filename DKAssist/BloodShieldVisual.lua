local addonName, addon = ...

-- Blood Shield display for the 12.x secret-value API.  Combat values are
-- forwarded directly to Blizzard widgets and are never inspected by Lua.
local BLOOD_SHIELD_ID = 77535
local DEATH_STRIKE_ID = 49998
local BLOOD_SHIELD_DURATION = 10
local frame
local testMode = false
local testDuration
local dragging = false
local fallbackDuration
local fallbackExpires
local fallbackTimer
local cdmFrames = setmetatable({}, { __mode = "k" })
local cdmHooks = setmetatable({}, { __mode = "k" })
local refreshQueued = false
local Refresh

local function Plain(value)
    return not (issecretvalue and issecretvalue(value))
end

local function QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0, function()
        refreshQueued = false
        if DKAssistDB and Refresh then Refresh() end
    end)
end

-- Called by the existing CDM discovery path, outside combat only. Keep our
-- routing state external; never write fields onto Blizzard's protected items.
function addon:RegisterBloodShieldCDMFrame(item)
    if InCombatLockdown() or not item then return end
    if not (DKAssistDB and DKAssistDB.bloodShield and DKAssistDB.bloodShield.enabled)
        or not addon:IsBloodSpec() then return end
    local ok, matched = pcall(function()
        local info = item.cooldownInfo
        local function matches(id) return Plain(id) and id == BLOOD_SHIELD_ID end
        if type(item.GetAuraSpellID) == "function" and matches(item:GetAuraSpellID()) then return true end
        if type(item.GetSpellID) == "function" and matches(item:GetSpellID()) then return true end
        if info and Plain(info) then
            if matches(info.spellID) or matches(info.overrideSpellID) or matches(info.overrideTooltipSpellID) then return true end
            -- Only an unambiguous linked aura can identify the duration.
            local linked = info.linkedSpellIDs
            if Plain(linked) and type(linked) == "table" and #linked == 1 and matches(linked[1]) then return true end
        end
        return false
    end)
    local wasTracked = cdmFrames[item]
    cdmFrames[item] = ok and matched or nil
    if not cdmFrames[item] then
        if wasTracked then QueueRefresh() end
        return
    end
    if not cdmHooks[item] then
        cdmHooks[item] = true
        for _, method in ipairs({ "RefreshData", "OnAuraInstanceInfoSet", "OnAuraInstanceInfoCleared" }) do
            if type(item[method]) == "function" then
                hooksecurefunc(item, method, function()
                    if cdmFrames[item] then QueueRefresh() end
                end)
            end
        end
        for _, method in ipairs({ "SetCooldownID", "ClearCooldownID" }) do
            if type(item[method]) == "function" then
                hooksecurefunc(item, method, function()
                    cdmFrames[item] = nil
                    if not InCombatLockdown() then addon:RegisterBloodShieldCDMFrame(item) end
                    QueueRefresh()
                end)
            end
        end
    end
    QueueRefresh()
end

local function CDMDuration()
    for item in pairs(cdmFrames) do
        local ok, duration = pcall(function()
            -- Do not use visibility: Ellesmere can hide/reparent the source.
            local data = item.auraDataCached
            local unit = item.auraDataUnit
            if not Plain(unit) or unit ~= "player" or not Plain(data) or type(data) ~= "table" then return end
            -- Reject an unrelated readable aura on a recycled/linked item.
            if Plain(data.spellId) and data.spellId ~= nil and data.spellId ~= BLOOD_SHIELD_ID then return end
            if C_UnitAuras and C_UnitAuras.GetAuraDuration then
                local found, value = pcall(C_UnitAuras.GetAuraDuration, "player", item.auraInstanceID)
                if found and value then return value end
            end
            -- Restricted unit queries may fail even with a known instance.
            -- Feed cached timestamps to the native duration setter unchanged.
            if C_DurationUtil and C_DurationUtil.CreateDuration then
                local value = C_DurationUtil.CreateDuration()
                value:SetTimeFromEnd(data.expirationTime, data.duration, data.timeMod)
                return value
            end
        end)
        if ok and duration then return duration end
    end
end

local function Settings()
    DKAssistDB.bloodShield = DKAssistDB.bloodShield or {}
    local s = DKAssistDB.bloodShield
    if s.enabled == nil then s.enabled = false end
    if s.alwaysShow == nil then s.alwaysShow = false end
    if s.showIcon == nil then s.showIcon = true end
    if s.showDuration == nil then s.showDuration = true end
    if s.showTimerText == nil then s.showTimerText = true end
    if s.estimateDuration == nil then s.estimateDuration = false end
    if s.width == nil then s.width = 260 end
    if s.height == nil then s.height = 36 end
    if s.iconSize == nil then s.iconSize = 52 end
    if s.locked == nil then s.locked = false end
    if not s.color then s.color = { r = 0.90, g = 0.05, b = 0.20 } end
    return s
end

local function SpellTexture()
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(BLOOD_SHIELD_ID)
    end
    return 132278
end

local function FindAura()
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return nil end
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, BLOOD_SHIELD_ID)
    if ok then return aura end
end

local function CreateDisplay()
    if frame then return frame end

    frame = CreateFrame("Frame", "DKAssistBloodShieldVisual", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.015, 0.025, 0.045, 0.92)
    frame:SetBackdropBorderColor(0.18, 0.70, 1.00, 1)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.icon:SetTexture(SpellTexture())
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetDrawEdge(false)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:SetHideCountdownNumbers(false)

    -- This StatusBar is deliberately isolated from all text and decision code.
    -- Once it receives a secret value, we only call secret-safe display sinks.
    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(0)
    frame.bar.bg = frame.bar:CreateTexture(nil, "BACKGROUND")
    frame.bar.bg:SetAllPoints()
    frame.bar.bg:SetColorTexture(0.12, 0.13, 0.16, 0.95)

    -- Native widgets consume the duration without inspecting secret times.
    -- The Death Strike estimate is opt-in and visibly labelled.
    frame.durationBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.durationBar:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", 0, 0)
    frame.durationBar:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", 0, 0)
    frame.durationBar:SetHeight(5)
    frame.durationBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.durationBar:SetStatusBarColor(1.00, 0.82, 0.05, 1)
    frame.durationBar:SetMinMaxValues(0, BLOOD_SHIELD_DURATION)
    frame.durationBar:SetValue(0)

    frame.timerText = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.timerText:ClearAllPoints()
    frame.timerText:SetSize(32, 20)
    frame.timerText:SetPoint("LEFT", frame.durationBar, "RIGHT", 4, -7.5)
    frame.timerText:SetDrawSwipe(false)
    frame.timerText:SetDrawEdge(false)
    frame.timerText:SetDrawBling(false)
    frame.timerText:SetHideCountdownNumbers(false)
    frame.timerText:EnableMouse(false)
    frame.cooldown:EnableMouse(false)
    local timerFont = frame.timerText:GetCountdownFontString()
    if timerFont then
        timerFont:ClearAllPoints()
        timerFont:SetPoint("CENTER", frame.timerText, "CENTER", 0, 0)
        timerFont:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        timerFont:SetTextColor(1, 0.82, 0.05)
    end

    frame.estimateLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.estimateLabel:SetPoint("TOP", frame.timerText, "BOTTOM", 0, 0)
    frame.estimateLabel:SetText("Est.")
    frame.estimateLabel:Hide()

    frame.label = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.label:SetPoint("CENTER", frame.bar, "CENTER", 0, 0)
    frame.label:SetText("Total Absorbs")
    frame.label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    frame.label:SetTextColor(1, 1, 1, 1)
    frame.label:SetShadowColor(0, 0, 0, 1)
    frame.label:SetShadowOffset(1, -1)

    frame:SetScript("OnDragStart", function(self)
        if not Settings().locked and not InCombatLockdown() then
            dragging = true
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        if not dragging then return end
        dragging = false
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Settings().position = { point, relativePoint, x, y }
    end)
    frame:Hide()
    return frame
end

local function ApplyAppearance()
    local f, s = CreateDisplay(), Settings()
    local timerWidth = (s.showDuration ~= false and s.showTimerText ~= false) and 36 or 0
    f:SetSize(timerWidth + (s.width or 260) + ((s.showIcon ~= false) and (s.iconSize or 52) + 8 or 0), math.max(s.height or 36, timerWidth > 0 and 40 or 0, (s.showIcon ~= false) and (s.iconSize or 52) + 8 or 0))
    f:EnableMouse(not s.locked and not InCombatLockdown())
    f:ClearAllPoints()
    local p = s.position
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, -175) end

    f.icon:SetShown(s.showIcon ~= false)
    f.cooldown:SetShown(s.showIcon ~= false and s.showDuration ~= false)
    f.durationBar:SetShown(s.showDuration ~= false)
    f.timerText:SetShown(s.showDuration ~= false and s.showTimerText ~= false)
    f.icon:SetSize(s.iconSize or 52, s.iconSize or 52)
    f.bar:ClearAllPoints()
    if s.showIcon ~= false then f.bar:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    else f.bar:SetPoint("LEFT", f, "LEFT", 4, 0) end
    f.bar:SetPoint("RIGHT", f, "RIGHT", -4 - timerWidth, 0)
    f.bar:SetHeight(s.height or 36)
    local c = s.color or { r = 0.90, g = 0.05, b = 0.20 }
    f.bar:SetStatusBarColor(c.r, c.g, c.b, 0.95)
end

local function ClearFallback()
    if fallbackTimer then fallbackTimer:Cancel(); fallbackTimer = nil end
    fallbackDuration, fallbackExpires = nil, nil
end

local function ClearDuration()
    if frame then
        frame.cooldown:Clear()
        frame.timerText:Clear()
        frame.cooldown:Hide()
        frame.timerText:Hide()
        frame.durationBar:Hide()
        frame.estimateLabel:Hide()
    end
    ClearFallback()
end

local function ShowDuration(duration, estimated)
    local f, s = CreateDisplay(), Settings()
    if s.showDuration == false then ClearDuration(); return end
    local okBar = pcall(f.durationBar.SetTimerDuration, f.durationBar, duration,
        Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
    local okIcon = pcall(f.cooldown.SetCooldownFromDurationObject, f.cooldown, duration)
    local okText = pcall(f.timerText.SetCooldownFromDurationObject, f.timerText, duration)
    f.durationBar:SetShown(okBar)
    f.cooldown:SetShown(okIcon and s.showIcon ~= false)
    f.timerText:SetShown(okText and s.showTimerText ~= false)
    f.estimateLabel:SetShown(estimated and (okBar or okText))
    -- Keep the estimate label visible even with countdown numbers disabled.
    f.estimateLabel:ClearAllPoints()
    if s.showTimerText ~= false then
        f.estimateLabel:SetPoint("TOP", f.timerText, "BOTTOM", 0, 0)
    else
        f.estimateLabel:SetPoint("BOTTOMRIGHT", f.durationBar, "TOPRIGHT", 0, 2)
    end
end

local function StartFallbackDuration()
    local s = Settings()
    if testMode or not s.enabled or not addon:IsBloodSpec() or s.showDuration == false
        or not s.estimateDuration or not C_DurationUtil or not C_DurationUtil.CreateDuration then return end
    ClearFallback()
    fallbackDuration = C_DurationUtil.CreateDuration()
    fallbackExpires = GetTime() + BLOOD_SHIELD_DURATION
    fallbackDuration:SetTimeFromStart(GetTime(), BLOOD_SHIELD_DURATION, 1)
    fallbackTimer = C_Timer.NewTimer(BLOOD_SHIELD_DURATION, function()
        ClearDuration()
        QueueRefresh()
    end)
end

Refresh = function()
    local f, s = CreateDisplay(), Settings()
    if testMode then
        f.bar:SetMinMaxValues(0, 100)
        f.bar:SetValue(72)
        if s.showDuration ~= false and C_DurationUtil and C_DurationUtil.CreateDuration then
            if not testDuration then
                testDuration = C_DurationUtil.CreateDuration()
                testDuration:SetTimeFromStart(GetTime(), BLOOD_SHIELD_DURATION, 1)
            end
            ShowDuration(testDuration, false)
        else
            ClearDuration()
        end
        f:SetAlpha(1)
        f:Show()
        return
    end
    if not s.enabled or not addon:IsBloodSpec() then
        ClearDuration()
        f:SetAlpha(0)
        f:Hide()
        return
    end

    -- Aura identity and absorb comparisons are restricted in combat in 12.x.
    -- Combat state safely controls visibility; the protected absorb number is
    -- used only as StatusBar display data.
    local aura = FindAura()
    local cdmDuration = not aura and CDMDuration() or nil
    local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    -- SPELLCAST_SUCCEEDED can precede the combat-state/aura updates. A fresh
    -- opt-in estimate is valid during that transition; do not erase it here.
    local hasEstimate = s.estimateDuration and fallbackDuration and fallbackExpires
        and GetTime() < fallbackExpires
    if not s.alwaysShow and not inCombat and not aura and not cdmDuration and not hasEstimate then
        ClearDuration()
        f:SetAlpha(0)
        f:Hide()
        return
    end

    f:SetAlpha(1)
    f:Show()
    if UnitGetTotalAbsorbs then
        local rawAbsorb = UnitGetTotalAbsorbs("player")
        if UnitHealthMax then
            pcall(f.bar.SetMinMaxValues, f.bar, 0, UnitHealthMax("player"))
        end
        pcall(f.bar.SetValue, f.bar, rawAbsorb)
    end

    if s.showDuration == false then ClearDuration(); return end

    -- Pass Blizzard's duration object directly to native widgets. Never do
    -- arithmetic, comparisons, or formatting on aura duration/absorb values.
    if aura and C_UnitAuras.GetAuraDuration then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, "player", aura.auraInstanceID)
        if ok and duration then
            ClearFallback()
            ShowDuration(duration, false)
            return
        end
    end

    cdmDuration = cdmDuration or CDMDuration()
    if cdmDuration then
        ClearFallback()
        ShowDuration(cdmDuration, false)
        return
    end

    if hasEstimate then
        ShowDuration(fallbackDuration, true)
    else
        -- No confirmed duration: do not leave the previous aura's timer up.
        ClearDuration()
    end

end

function addon:RefreshBloodShieldVisual()
    ApplyAppearance()
    if not InCombatLockdown() and addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    Refresh()
end

function addon:ResetBloodShieldVisualPosition()
    Settings().position = nil
    ApplyAppearance()
    Refresh()
end

function addon:TestBloodShieldVisual()
    ClearDuration()
    testDuration = nil
    testMode = not testMode
    ApplyAppearance()
    Refresh()
end

function addon:StopBloodShieldVisualTest()
    ClearDuration()
    testDuration = nil
    testMode = false
    Refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
events:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if not DKAssistDB then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if issecretvalue and issecretvalue(spellID) then return end
        if spellID ~= DEATH_STRIKE_ID then return end
        StartFallbackDuration()
        QueueRefresh()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- A completed fight must not leave an unconfirmed estimate visible.
        -- Refresh below can still display a real surviving aura.
        ClearFallback()
    end
    -- Aura/absorb events only update data, not layout or the saved position.
    if not frame or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        if frame and event == "PLAYER_REGEN_DISABLED" then
            local stopDrag = frame:GetScript("OnDragStop")
            if stopDrag then stopDrag(frame) end
        end
        ApplyAppearance()
    end
    Refresh()
end)
