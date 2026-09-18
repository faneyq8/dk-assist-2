local addonName, addon = ...

local BONE_SHIELD_IDS = { [195181] = true }
local OSSUARY_IDS = { [219786] = true, [219788] = true }
local WARNING_AFTER = 25
local ALERT_DURATION = 3
local VIEWER_NAMES = {
    "BuffIconCooldownViewer", "BuffBarCooldownViewer",
    "EssentialCooldownViewer", "UtilityCooldownViewer",
}

local boneFrames, ossuaryFrames = {}, {}
local state = {
    boneUp = false,
    ossuaryUp = false,
    timerEnds = 0,
    expiresAt = 0,
    alerted = false,
    suppressUntil = 0,
    waitForInactive = false,
}
local alertFrame

local function Settings()
    if not DKAssistDB then return nil end
    DKAssistDB.bloodBone = DKAssistDB.bloodBone or {}
    local settings = DKAssistDB.bloodBone
    if settings.warningAfter == nil then settings.warningAfter = WARNING_AFTER end
    if settings.textAlert == nil then settings.textAlert = true end
    if settings.soundAlert == nil then settings.soundAlert = true end
    if settings.earlyWarning == nil then settings.earlyWarning = true end
    if settings.missingWarning == nil then settings.missingWarning = true end
    if settings.ossuaryWarning == nil then settings.ossuaryWarning = false end
    if settings.earlySound == nil then settings.earlySound = "READY_CHECK" end
    if settings.missingSound == nil then settings.missingSound = "RAID_WARNING" end
    return settings
end

local function IsSecret(value)
    if not issecretvalue then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret or false
end

local function IsBloodEnabled()
    local settings = Settings()
    return settings and settings.enabled and addon:IsBloodSpec()
end

local function CreateAlert()
    if alertFrame then return alertFrame end
    local frame = CreateFrame("Frame", "DKAssistBoneShieldAlert", UIParent, "BackdropTemplate")
    frame:SetSize(420, 82)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    frame:SetBackdropColor(0.04, 0.01, 0.01, 0.90)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    frame.text:SetPoint("CENTER")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        local settings = Settings()
        if settings then settings.alertPosition = { point, relativePoint, x, y } end
    end)
    frame:Hide()
    alertFrame = frame
    return frame
end

local function RestorePosition()
    local frame, settings = CreateAlert(), Settings()
    if settings and settings.alertPosition then
        frame:ClearAllPoints()
        frame:SetPoint(settings.alertPosition[1], UIParent, settings.alertPosition[2], settings.alertPosition[3], settings.alertPosition[4])
    end
end

local function HideAlert()
    if alertFrame then alertFrame:Hide() end
end

local function FireAlert(force, alertType)
    local settings = Settings()
    if not force and (not IsBloodEnabled() or state.alerted or GetTime() < state.suppressUntil) then return end
    state.alerted = true
    alertType = alertType or "missing"
    if not force and settings then
        if alertType == "early" and settings.earlyWarning == false then return end
        if alertType == "missing" and settings.missingWarning == false then return end
        if alertType == "ossuary" and settings.ossuaryWarning ~= true then return end
    end
    local color, message
    if alertType == "early" then
        local remaining = math.max(1, 30 - ((settings and settings.warningAfter) or WARNING_AFTER))
        color, message = { r = 1.00, g = 0.82, b = 0.05 }, ("BONE SHIELD: %ds"):format(remaining)
    elseif alertType == "ossuary" then
        color, message = { r = 1.00, g = 0.55, b = 0.05 }, "BONE SHIELD STACKS LOW!"
    else
        color, message = { r = 0.95, g = 0.08, b = 0.08 }, "BONE SHIELD MISSING!"
    end
    if force or not settings or settings.textAlert ~= false then
        RestorePosition()
        local frame = CreateAlert()
        frame:SetBackdropBorderColor(color.r, color.g, color.b, settings and settings.alpha or 1)
        frame.text:SetText(message)
        frame.text:SetTextColor(color.r, color.g, color.b, 1)
        frame:Show()
        local token = GetTime()
        frame.dkToken = token
        C_Timer.After(ALERT_DURATION, function()
            if frame.dkToken == token then frame:Hide() end
        end)
    end
    if force or not settings or settings.soundAlert ~= false then
        if SOUNDKIT then
            local soundKey = alertType == "early" and (settings and settings.earlySound or "READY_CHECK")
                or (settings and settings.missingSound or "RAID_WARNING")
            local sound = soundKey ~= "none" and (SOUNDKIT[soundKey] or SOUNDKIT.RAID_WARNING) or nil
            if sound then PlaySound(sound, "Master") end
        end
    end
end

local function CooldownMatches(cooldownID, wanted)
    if not cooldownID or IsSecret(cooldownID) then return false end
    local getInfo = C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo
    if not getInfo then return false end
    local ok, info = pcall(getInfo, cooldownID)
    if not ok or not info then return false end
    local function matches(value)
        return value and not IsSecret(value) and wanted[value] == true
    end
    if matches(info.spellID) or matches(info.linkedSpellID)
        or matches(info.overrideSpellID) or matches(info.overrideTooltipSpellID) then return true end
    if type(info.linkedSpellIDs) == "table" then
        for _, spellID in ipairs(info.linkedSpellIDs) do
            if matches(spellID) then return true end
        end
    end
    return false
end

local function FrameMatches(frame, wanted)
    if not frame then return false end
    local cooldownID = frame.cooldownID or (frame.cooldownInfo and frame.cooldownInfo.cooldownID)
    if cooldownID and CooldownMatches(cooldownID, wanted) then return true end
    if not frame.GetCooldownID then return false end
    local ok, methodID = pcall(frame.GetCooldownID, frame)
    return ok and CooldownMatches(methodID, wanted) or false
end

local function FrameActive(frame)
    if frame and frame.IsActive then
        local ok, active = pcall(frame.IsActive, frame)
        if ok and type(active) == "boolean" and not IsSecret(active) then return active end
    end
    local okShown, shown = pcall(frame.IsShown, frame)
    if not okShown or not shown or IsSecret(shown) then return false end
    local okAlpha, alpha = pcall(frame.GetAlpha, frame)
    if okAlpha and type(alpha) == "number" and not IsSecret(alpha) and alpha < 0.05 then return false end
    return true
end

local function AddUnique(list, frame)
    for _, existing in ipairs(list) do if existing == frame then return end end
    list[#list + 1] = frame
end

local function CollectViewerFrames(viewer, output, seen)
    if not viewer then return end
    if viewer.itemFramePool and viewer.itemFramePool.EnumerateActive then
        local ok, iterator = pcall(viewer.itemFramePool.EnumerateActive, viewer.itemFramePool)
        if ok and iterator then
            for frame in iterator do
                if frame and not seen[frame] then seen[frame] = true; output[#output + 1] = frame end
            end
        end
    end
    if viewer.GetItemFrames then
        local ok, frames = pcall(viewer.GetItemFrames, viewer)
        if ok and type(frames) == "table" then
            for _, frame in ipairs(frames) do
                if frame and not seen[frame] then seen[frame] = true; output[#output + 1] = frame end
            end
        end
    end
end

local function ScanCDM()
    for index = #boneFrames, 1, -1 do
        if not FrameMatches(boneFrames[index], BONE_SHIELD_IDS) then table.remove(boneFrames, index) end
    end
    for index = #ossuaryFrames, 1, -1 do
        if not FrameMatches(ossuaryFrames[index], OSSUARY_IDS) then table.remove(ossuaryFrames, index) end
    end
    local all, seen = {}, {}
    for _, viewerName in ipairs(VIEWER_NAMES) do CollectViewerFrames(_G[viewerName], all, seen) end
    for _, frame in ipairs(all) do
        if FrameMatches(frame, BONE_SHIELD_IDS) then AddUnique(boneFrames, frame) end
        if FrameMatches(frame, OSSUARY_IDS) then AddUnique(ossuaryFrames, frame) end
    end
end

local function AnyActive(frames)
    for _, frame in ipairs(frames) do if FrameActive(frame) then return true end end
    return false
end

local function ResetWindow()
    local settings = Settings()
    local now = GetTime()
    state.timerEnds = now + (settings and settings.warningAfter or WARNING_AFTER)
    state.expiresAt = now + 30
    state.alerted = false
end

local function ClearWindow()
    state.boneUp = false
    state.ossuaryUp = false
    state.timerEnds = 0
    state.expiresAt = 0
    state.alerted = false
    HideAlert()
end

local function UpdateState()
    if #boneFrames == 0 then
        state.boneUp, state.ossuaryUp = false, false
        state.timerEnds, state.alerted = 0, false
        HideAlert()
        return
    end
    local boneUp = AnyActive(boneFrames)
    if state.waitForInactive then
        if boneUp then
            boneUp = false
        else
            state.waitForInactive = false
        end
    end
    local ossuaryUp = #ossuaryFrames > 0 and AnyActive(ossuaryFrames) or false
    if boneUp and not state.boneUp then
        state.boneUp = true
        ResetWindow()
    elseif not boneUp and state.boneUp then
        local inCombat = InCombatLockdown()
        ClearWindow()
        if inCombat then FireAlert(false, "missing") end
        return
    end
    if #ossuaryFrames > 0 then
        if ossuaryUp and not state.ossuaryUp then
            state.ossuaryUp = true
        elseif not ossuaryUp and state.ossuaryUp then
            state.ossuaryUp = false
            if state.boneUp then FireAlert(false, "ossuary") end
        end
    else
        state.ossuaryUp = false
    end
end

function addon:OnBoneShieldGeneratorCast()
    if not IsBloodEnabled() then return end
    HideAlert()
    state.boneUp = true
    state.waitForInactive = false
    state.suppressUntil = GetTime() + 0.8
    ResetWindow()
end

function addon:RefreshBoneShieldReminder()
    if not IsBloodEnabled() then ClearWindow(); return end
    ScanCDM()
    UpdateState()
end

function addon:RescanBoneShieldReminder()
    ScanCDM()
    UpdateState()
    return #boneFrames > 0, #ossuaryFrames > 0
end

function addon:GetBoneShieldReminderStatus()
    return #boneFrames > 0, #ossuaryFrames > 0
end

function addon:OnBoneShieldCombatStart()
    if IsBloodEnabled() then ScanCDM(); UpdateState() end
end

function addon:OnBoneShieldCombatEnd()
    if alertFrame then alertFrame:Hide() end
end

function addon:TestBloodBoneReminder()
    state.alerted = false
    FireAlert(true, "missing")
    return 1
end

local driver = CreateFrame("Frame")
local accumulator = 0
driver:SetScript("OnUpdate", function(_, elapsed)
    accumulator = accumulator + elapsed
    if accumulator < 0.50 then return end
    accumulator = 0
    if not IsBloodEnabled() then return end
    ScanCDM()
    UpdateState()
    local now = GetTime()
    if state.boneUp and state.expiresAt > 0 and now >= state.expiresAt then
        ClearWindow()
        FireAlert(false, "missing")
        state.waitForInactive = true
        return
    end
    if state.boneUp and state.timerEnds > 0 and now >= state.timerEnds then FireAlert(false, "early") end
end)
