local addonName, addon = ...

-- Blood Shield display for the 12.x secret-value API.  Combat values are
-- forwarded directly to Blizzard widgets and are never inspected by Lua.
local BLOOD_SHIELD_ID = 77535
local DEATH_STRIKE_ID = 49998
local BLOOD_SHIELD_DURATION = 10
local frame
local testMode = false
local fallbackDuration

local function Settings()
    DKAssistDB.bloodShield = DKAssistDB.bloodShield or {}
    local s = DKAssistDB.bloodShield
    if s.enabled == nil then s.enabled = false end
    if s.showIcon == nil then s.showIcon = true end
    if s.showDuration == nil then s.showDuration = true end
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

    -- Thin duration layer. The actual aura DurationObject is preferred; a
    -- successful Death Strike provides the 10-second fallback when aura
    -- identity is restricted during combat.
    frame.durationBar = CreateFrame("StatusBar", nil, frame.bar)
    frame.durationBar:SetPoint("TOPLEFT", frame.bar, "TOPLEFT", 0, 0)
    frame.durationBar:SetPoint("TOPRIGHT", frame.bar, "TOPRIGHT", 0, 0)
    frame.durationBar:SetHeight(5)
    frame.durationBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.durationBar:SetStatusBarColor(1.00, 0.82, 0.05, 1)
    frame.durationBar:SetMinMaxValues(0, BLOOD_SHIELD_DURATION)
    frame.durationBar:SetValue(0)

    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.label:SetPoint("CENTER", frame.bar, "CENTER", 0, 0)
    frame.label:SetText("Blood Shield")

    frame:SetScript("OnDragStart", function(self)
        if not Settings().locked and not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Settings().position = { point, relativePoint, x, y }
    end)
    frame:Hide()
    return frame
end

local function ApplyAppearance()
    local f, s = CreateDisplay(), Settings()
    f:SetSize((s.width or 260) + ((s.showIcon ~= false) and (s.iconSize or 52) + 8 or 0), math.max(s.height or 36, (s.showIcon ~= false) and (s.iconSize or 52) + 8 or 0))
    f:EnableMouse(not s.locked)
    f:ClearAllPoints()
    local p = s.position
    if p then f:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, -175) end

    f.icon:SetShown(s.showIcon ~= false)
    f.cooldown:SetShown(s.showIcon ~= false and s.showDuration ~= false)
    f.durationBar:SetShown(s.showDuration ~= false)
    f.icon:SetSize(s.iconSize or 52, s.iconSize or 52)
    f.bar:ClearAllPoints()
    if s.showIcon ~= false then f.bar:SetPoint("LEFT", f.icon, "RIGHT", 4, 0)
    else f.bar:SetPoint("LEFT", f, "LEFT", 4, 0) end
    f.bar:SetPoint("RIGHT", f, "RIGHT", -4, 0)
    f.bar:SetHeight(s.height or 36)
    local c = s.color or { r = 0.90, g = 0.05, b = 0.20 }
    f.bar:SetStatusBarColor(c.r, c.g, c.b, 0.95)
end

local function ClearDuration()
    if frame and frame.cooldown.Clear then frame.cooldown:Clear() end
    if frame and frame.durationBar and C_DurationUtil and C_DurationUtil.CreateDuration then
        local empty = C_DurationUtil.CreateDuration()
        frame.durationBar:SetTimerDuration(empty, Enum.StatusBarInterpolation.Immediate,
            Enum.StatusBarTimerDirection.RemainingTime)
    end
    fallbackDuration = nil
end

local function StartFallbackDuration()
    if not C_DurationUtil or not C_DurationUtil.CreateDuration then return end
    fallbackDuration = C_DurationUtil.CreateDuration()
    fallbackDuration:SetTimeFromStart(GetTime(), BLOOD_SHIELD_DURATION, 1)
    local f = CreateDisplay()
    f.durationBar:SetTimerDuration(fallbackDuration, Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.RemainingTime)
    if Settings().showDuration ~= false then
        f.cooldown:SetCooldownFromDurationObject(fallbackDuration)
    end
end

local function Refresh()
    local f, s = CreateDisplay(), Settings()
    if testMode then
        f.bar:SetMinMaxValues(0, 100)
        f.bar:SetValue(72)
        f.durationBar:SetMinMaxValues(0, BLOOD_SHIELD_DURATION)
        f.durationBar:SetValue(7.2)
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
    local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    if not inCombat and not aura then
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

    -- Keep the direct player-aura lookup only for the optional cooldown
    -- display. Failure to identify the aura must never hide the absorb bar.
    if not aura then
        if not fallbackDuration then ClearDuration() end
        return
    end

    -- auraInstanceID is explicitly NeverSecret. It is used only to request a
    -- DurationObject, which is passed straight to the Cooldown widget.
    if s.showDuration ~= false and C_UnitAuras.GetAuraDuration then
        local ok, duration = pcall(C_UnitAuras.GetAuraDuration, "player", aura.auraInstanceID)
        if ok and duration then
            pcall(f.durationBar.SetTimerDuration, f.durationBar, duration,
                Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            pcall(f.cooldown.SetCooldownFromDurationObject, f.cooldown, duration)
        end
    else
        if not fallbackDuration then ClearDuration() end
    end

end

function addon:RefreshBloodShieldVisual()
    ApplyAppearance()
    Refresh()
end

function addon:ResetBloodShieldVisualPosition()
    Settings().position = nil
    ApplyAppearance()
end

function addon:TestBloodShieldVisual()
    testMode = not testMode
    ApplyAppearance()
    Refresh()
end

function addon:StopBloodShieldVisualTest()
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
    if event == "UNIT_SPELLCAST_SUCCEEDED" and spellID == DEATH_STRIKE_ID then
        StartFallbackDuration()
    end
    ApplyAppearance()
    Refresh()
end)
