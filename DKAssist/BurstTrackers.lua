-- DK Assist - independent Gargoyle and Dark Transformation trackers
local addonName, addon = ...

local GARGOYLE_SPELL_ID = 42650
local GARGOYLE_TALENT_ID = 1242147
local GARGOYLE_DURATION = 25
local DARK_TRANSFORMATION_ID = addon.SPELLS.DARK_TRANSFORMATION.id
local DARK_TRANSFORMATION_DURATION = 15
local DARK_TRANSFORMATION_EXTENSION = 1
local PILLAR_OF_FROST_ID = addon.SPELLS.PILLAR_OF_FROST.id
local PILLAR_OF_FROST_DURATION = 12
local KILLING_MACHINE_ID = addon.SPELLS.KILLING_MACHINE.id
local KILLING_MACHINE_AURA_ID = 51124
local KILLING_MACHINE_DURATION = 10
local RIME_ID = addon.SPELLS.RIME.id
local RIME_DURATION = 15
local KILLING_MACHINE_OVERLAY_IDS = { [49020] = true, [207230] = true, [51124] = true }
local RIME_OVERLAY_IDS = { [49184] = true, [59052] = true }
local COST_POLL_INTERVAL = 0.10
local GARGOYLE_TEXTURE = "Interface\\Icons\\Ability_DeathKnight_SummonGargoyle"
local LCG = LibStub("LibCustomGlow-1.0")

local RP_SPENDERS = {
    [47541] = true, [1242174] = true, [207317] = true, [383269] = true,
}

local function TrackerDefaults(showDamage)
    return {
        timelineEnabled = true, iconEnabled = false,
        timelineScale = 64, timelineOrientation = "horizontal", iconSize = 64, fontSize = 18,
        showTimelineInfo = true,
        showSpellName = true, showDamage = showDamage and true or false,
        timelineLocked = false, iconLocked = false,
        timelinePosition = nil, iconPosition = nil, bestPercent = 0, bestDuration = 0, bestDamage = 0,
    }
end

local function KillingMachineDefaults()
    local defaults = TrackerDefaults(false)
    defaults.timelineEnabled = false
    defaults.iconEnabled = true
    defaults.glowTarget = "icon"
    defaults.glowType = "pixel"
    defaults.color = { r = 0.30, g = 0.85, b = 1.00 }
    defaults.speed = 0.25
    defaults.lines = 8
    defaults.thickness = 2
    defaults.alpha = 1
    return defaults
end

addon.DEFAULT_DB.burstTrackers = {
    gargoyle = TrackerDefaults(true),
    darkTransformation = TrackerDefaults(false),
    pillarOfFrost = TrackerDefaults(false),
    killingMachine = KillingMachineDefaults(),
    rime = KillingMachineDefaults(),
}

local INFO = {
    gargoyle = { spellID = GARGOYLE_SPELL_ID, texture = GARGOYLE_TEXTURE, name = "Gargoyle", duration = GARGOYLE_DURATION, fallbackX = -170 },
    darkTransformation = { spellID = DARK_TRANSFORMATION_ID, name = "Dark Transformation", duration = DARK_TRANSFORMATION_DURATION, fallbackX = 170 },
    pillarOfFrost = { spellID = PILLAR_OF_FROST_ID, name = "Pillar of Frost", duration = PILLAR_OF_FROST_DURATION, fallbackX = 0 },
    killingMachine = { spellID = KILLING_MACHINE_ID, texture = "Interface\\Icons\\INV_Sword_122", name = "Killing Machine", duration = KILLING_MACHINE_DURATION, fallbackX = 0 },
    rime = { spellID = RIME_ID, name = "Rime", duration = RIME_DURATION, fallbackX = 100 },
}

local frames = {}
local states = {
    gargoyle = { active = false, endsAt = 0, rpSpent = 0, run = 0 },
    darkTransformation = { active = false, startedAt = 0, endsAt = 0, extensions = 0, run = 0 },
    pillarOfFrost = { active = false, startedAt = 0, endsAt = 0, auraPollElapsed = 0, run = 0 },
    killingMachine = { active = false, startedAt = 0, endsAt = 0, stacks = 0, run = 0 },
    rime = { active = false, startedAt = 0, endsAt = 0, stacks = 0, run = 0 },
}
local cachedCosts, costElapsed, testKeys = {}, 0, {}
local frostProcCDMFrames = { killingMachine = {}, rime = {} }
local frostProcHookedFrames = {}
local frostProcOverlayActive = { killingMachine = {}, rime = {} }
-- After a proc is consumed Blizzard can briefly recycle/show the same CDM
-- frame before its protected state catches up.  Do not treat that stale show
-- as a new proc; wait until Blizzard reports a real inactive/hide transition.
local frostProcNeedsClear = { killingMachine = false, rime = false }
local frostProcHideGeneration = { killingMachine = 0, rime = 0 }
local frostProcStopPending = { killingMachine = false, rime = false }
local procPollElapsed = 0
local StartTracker, StopTracker

local function CopyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then target[key] = type(value) == "table" and CopyTable(value) or value end
    end
end

local function EnsureSettingsSchema()
    if not DKAssistDB then return addon.DEFAULT_DB.burstTrackers end
    local old = DKAssistDB.burstTrackers
    if type(old) ~= "table" or type(old.gargoyle) ~= "table" or type(old.darkTransformation) ~= "table" then
        local migrated = CopyTable(addon.DEFAULT_DB.burstTrackers)
        if type(old) == "table" then
            migrated.gargoyle.timelineEnabled = old.gargoyleEnabled ~= false
            migrated.darkTransformation.timelineEnabled = old.darkTransformationEnabled ~= false
            migrated.gargoyle.iconSize = old.iconSize or migrated.gargoyle.iconSize
            migrated.darkTransformation.iconSize = old.iconSize or migrated.darkTransformation.iconSize
            migrated.gargoyle.fontSize = old.fontSize or migrated.gargoyle.fontSize
            migrated.darkTransformation.fontSize = old.fontSize or migrated.darkTransformation.fontSize
            migrated.gargoyle.showDamage = old.showGargoyleDamage ~= false
            migrated.gargoyle.bestPercent = old.bestGargoylePercent or 0
            migrated.gargoyle.timelinePosition = old.gargoylePosition
            migrated.darkTransformation.timelinePosition = old.darkTransformationPosition
        end
        DKAssistDB.burstTrackers = migrated
    else
        CopyDefaults(old.gargoyle, addon.DEFAULT_DB.burstTrackers.gargoyle)
        CopyDefaults(old.darkTransformation, addon.DEFAULT_DB.burstTrackers.darkTransformation)
        if type(old.pillarOfFrost) ~= "table" then old.pillarOfFrost = CopyTable(addon.DEFAULT_DB.burstTrackers.pillarOfFrost) end
        CopyDefaults(old.pillarOfFrost, addon.DEFAULT_DB.burstTrackers.pillarOfFrost)
        if type(old.killingMachine) ~= "table" then old.killingMachine = CopyTable(addon.DEFAULT_DB.burstTrackers.killingMachine) end
        CopyDefaults(old.killingMachine, addon.DEFAULT_DB.burstTrackers.killingMachine)
        if type(old.rime) ~= "table" then old.rime = CopyTable(addon.DEFAULT_DB.burstTrackers.rime) end
        CopyDefaults(old.rime, addon.DEFAULT_DB.burstTrackers.rime)
    end
    return DKAssistDB.burstTrackers
end

local function Settings(key)
    local root = EnsureSettingsSchema()
    return root[key] or addon.DEFAULT_DB.burstTrackers[key]
end

function addon:GetBurstTrackerSettings(key)
    return Settings(key)
end

function addon:IsFrostProcActive(key)
    if key ~= "killingMachine" and key ~= "rime" then return false end
    local state = states[key]
    if not state then return false end
    -- UNIT_AURA can report the proc removal just before the consuming cast's
    -- UNIT_SPELLCAST_SUCCEEDED event. Keep a very short consumption grace.
    return state.active == true or (state.lastEndedAt and GetTime() - state.lastEndedAt <= 0.35)
end

local function SpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return "Interface\\Icons\\Spell_Shadow_AnimateDead"
end

local function SavePosition(frame, key, field)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    Settings(key)[field] = { point, relativePoint, x, y }
end

local function RestorePosition(frame, key, field, fallbackX, fallbackY)
    local position = Settings(key)[field]
    frame:ClearAllPoints()
    if position then frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    else frame:SetPoint("CENTER", UIParent, "CENTER", fallbackX, fallbackY) end
end

local function MakeDraggable(frame, key, field, lockField)
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not Settings(key)[lockField] then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition(self, key, field) end)
end

local function CreateTimeline(key)
    local info = INFO[key]
    local frame = CreateFrame("Frame", "DKAssist" .. key .. "Timeline", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0.02, 0.03, 0.06, 0.78); frame:SetBackdropBorderColor(0.30, 0.30, 0.34, 1)
    MakeDraggable(frame, key, "timelinePosition", "timelineLocked")
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetPoint("TOP", frame, "TOP", 0, -3); frame.nameText:SetText(info.name); frame.nameText:SetTextColor(1, 0.82, 0, 1)
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetTexture(info.texture or SpellTexture(info.spellID)); frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93); frame.icon:SetPoint("LEFT", frame, "LEFT", 12, -6)
    frame.bar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    frame.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); frame.bar:SetStatusBarColor(0.42, 0.24, 0.70, 1)
    frame.bar:SetMinMaxValues(0, info.duration); frame.bar:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0); frame.bar:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    frame.bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); frame.bar:SetBackdropColor(0.18, 0.18, 0.21, 1)
    frame.timer = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.timer:SetPoint("CENTER"); frame.timer:SetShadowOffset(1, -1)
    frame.detail = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.detail:SetPoint("BOTTOM", frame, "BOTTOM", 0, 3); frame.detail:SetTextColor(0.65, 1, 0.25, 1)
    frame.infoBG = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.infoBG:SetColorTexture(0.01, 0.015, 0.025, 0.82)
    frame.divider = frame:CreateTexture(nil, "BORDER")
    frame.divider:SetColorTexture(0.38, 0.42, 0.48, 0.85)
    frame.unlock = frame:CreateTexture(nil, "OVERLAY"); frame.unlock:SetAllPoints(); frame.unlock:SetColorTexture(0, 0.75, 1, 0.10)
    frame:Hide(); RestorePosition(frame, key, "timelinePosition", info.fallbackX, 130)
    return frame
end

local function CreateIcon(key)
    local info = INFO[key]
    local frame = CreateFrame("Frame", "DKAssist" .. key .. "Icon", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({ bgFile = info.texture or SpellTexture(info.spellID), edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropBorderColor(0.35, 0.35, 0.38, 1); MakeDraggable(frame, key, "iconPosition", "iconLocked")
    frame.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.timer:SetPoint("TOP", frame, "BOTTOM", 0, -2); frame.timer:SetShadowOffset(1, -1)
    frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.nameText:SetPoint("TOP", frame.timer, "BOTTOM", 0, -1); frame.nameText:SetText(info.name); frame.nameText:SetTextColor(1, 0.82, 0, 1)
    frame.unlock = frame:CreateTexture(nil, "OVERLAY"); frame.unlock:SetAllPoints(); frame.unlock:SetColorTexture(0, 0.75, 1, 0.16)
    frame:Hide(); RestorePosition(frame, key, "iconPosition", info.fallbackX, 30)
    return frame
end

local function EnsureFrames(key)
    if not frames[key] then frames[key] = { timeline = CreateTimeline(key), icon = CreateIcon(key) } end
    return frames[key]
end

local function ApplyAppearance(key)
    local display, settings = EnsureFrames(key), Settings(key)
    local scale = (settings.timelineScale or 64) / 64
    local iconSide = math.floor(46 * scale + 0.5)
    local vertical = settings.timelineOrientation == "vertical"
    local showInfo = settings.showTimelineInfo ~= false
    display.timeline.icon:ClearAllPoints()
    display.timeline.bar:ClearAllPoints()
    display.timeline.timer:ClearAllPoints()
    display.timeline.detail:ClearAllPoints()
    display.timeline.infoBG:ClearAllPoints()
    display.timeline.divider:ClearAllPoints()
    display.timeline.infoBG:SetShown(showInfo)
    display.timeline.divider:SetShown(showInfo)
    if vertical then
        local frameWidth = 94
        local frameHeight = showInfo and 250 or 190
        display.timeline:SetSize(math.floor(frameWidth * scale + 0.5), math.floor(frameHeight * scale + 0.5))
        iconSide = math.floor(46 * scale + 0.5)
        display.timeline.icon:SetSize(iconSide, iconSide)
        display.timeline.icon:SetPoint("TOP", display.timeline, "TOP", 0, -8 * scale)
        display.timeline.timer:SetPoint("TOP", display.timeline.icon, "BOTTOM", 0, -4 * scale)
        display.timeline.bar:SetOrientation("VERTICAL")
        display.timeline.bar:SetWidth(math.max(8, math.floor(10 * scale + 0.5)))
        display.timeline.bar:SetPoint("TOP", display.timeline.timer, "BOTTOM", 0, -8 * scale)
        display.timeline.bar:SetPoint("BOTTOM", display.timeline, "BOTTOM", 0, (showInfo and 66 or 10) * scale)
        display.timeline.detail:SetPoint("BOTTOM", display.timeline, "BOTTOM", 0, 7 * scale)
        display.timeline.detail:SetWidth(math.floor(84 * scale + 0.5))
        display.timeline.detail:SetJustifyH("CENTER")
        if showInfo then
            display.timeline.infoBG:SetPoint("BOTTOMLEFT", display.timeline, "BOTTOMLEFT", 1, 1)
            display.timeline.infoBG:SetPoint("BOTTOMRIGHT", display.timeline, "BOTTOMRIGHT", -1, 1)
            display.timeline.infoBG:SetHeight(math.floor(58 * scale + 0.5))
            display.timeline.divider:SetPoint("BOTTOMLEFT", display.timeline, "BOTTOMLEFT", 5 * scale, 59 * scale)
            display.timeline.divider:SetPoint("BOTTOMRIGHT", display.timeline, "BOTTOMRIGHT", -5 * scale, 59 * scale)
            display.timeline.divider:SetHeight(1)
        end
    else
        local frameWidth = showInfo and 380 or 260
        local frameHeight = 64
        display.timeline:SetSize(math.floor(frameWidth * scale + 0.5), math.floor(frameHeight * scale + 0.5))
        iconSide = math.floor(48 * scale + 0.5)
        display.timeline.icon:SetSize(iconSide, iconSide)
        display.timeline.icon:SetPoint("LEFT", display.timeline, "LEFT", 8 * scale, 0)
        display.timeline.bar:SetOrientation("HORIZONTAL")
        display.timeline.bar:SetHeight(math.max(8, math.floor(8 * scale + 0.5)))
        display.timeline.bar:SetPoint("LEFT", display.timeline.icon, "RIGHT", 12 * scale, -9 * scale)
        display.timeline.bar:SetPoint("RIGHT", display.timeline, "RIGHT", (showInfo and -140 or -12) * scale, -9 * scale)
        display.timeline.timer:SetPoint("BOTTOM", display.timeline.bar, "TOP", 0, 2 * scale)
        display.timeline.detail:SetPoint("RIGHT", display.timeline, "RIGHT", -7 * scale, 0)
        display.timeline.detail:SetWidth(math.floor(120 * scale + 0.5))
        display.timeline.detail:SetJustifyH("CENTER")
        if showInfo then
            display.timeline.infoBG:SetPoint("TOPRIGHT", display.timeline, "TOPRIGHT", -1, -1)
            display.timeline.infoBG:SetPoint("BOTTOMRIGHT", display.timeline, "BOTTOMRIGHT", -1, 1)
            display.timeline.infoBG:SetWidth(math.floor(130 * scale + 0.5))
            display.timeline.divider:SetPoint("TOPRIGHT", display.timeline, "TOPRIGHT", -130 * scale, -5 * scale)
            display.timeline.divider:SetPoint("BOTTOMRIGHT", display.timeline, "BOTTOMRIGHT", -130 * scale, 5 * scale)
            display.timeline.divider:SetWidth(1)
        end
    end
    display.timeline.timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    display.timeline.nameText:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 4), "OUTLINE")
    display.timeline.detail:SetFont(STANDARD_TEXT_FONT, math.max(9, (settings.fontSize or 18) - 7), "OUTLINE")
    display.timeline.nameText:Hide(); display.timeline.unlock:SetShown(not settings.timelineLocked)
    display.timeline:EnableMouse(not settings.timelineLocked)
    local iconSize = settings.iconSize or 64
    display.icon:SetSize(iconSize, iconSize); display.icon.timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    display.icon.nameText:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 5), "OUTLINE")
    display.icon.nameText:SetShown(settings.showSpellName ~= false); display.icon.unlock:SetShown(not settings.iconLocked)
    display.icon:EnableMouse(not settings.iconLocked)
end

local function PollCosts()
    for spellID in pairs(RP_SPENDERS) do
        local ok, costs = pcall(C_Spell.GetSpellPowerCost, spellID)
        if ok and type(costs) == "table" then
            for _, costInfo in ipairs(costs) do
                if costInfo.type == 6 then local cost = tonumber(costInfo.cost); if cost then cachedCosts[spellID] = cost end end
            end
        end
    end
end

local function ReadDarkTransformationExpiration()
    -- Dark Transformation is an aura on the permanent ghoul, not the player.
    -- Reading the player aura always fails and leaves the tracker at a static
    -- fallback duration.  Prefer the pet aura when Blizzard exposes it.
    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, _, _, _, _, _, expirationTime = pcall(AuraUtil.FindAuraBySpellID, DARK_TRANSFORMATION_ID, "pet", "HELPFUL")
        if ok and tonumber(expirationTime) then return tonumber(expirationTime) end
    end
end

local function ReadPillarOfFrostExpiration()
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, PILLAR_OF_FROST_ID)
        if ok and aura and tonumber(aura.expirationTime) then return tonumber(aura.expirationTime) end
    end
    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, _, _, _, _, _, expirationTime = pcall(AuraUtil.FindAuraBySpellID, PILLAR_OF_FROST_ID, "player", "HELPFUL")
        if ok and tonumber(expirationTime) then return tonumber(expirationTime) end
    end
end

local function ReadPlayerAura(spellID)
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and aura then return aura end
    end
end

local function SetDisplaysShown(key, shown)
    local display, settings = EnsureFrames(key), Settings(key)
    if key == "killingMachine" or key == "rime" then
        display.timeline:Hide()
        display.icon:SetShown(shown and settings.iconEnabled ~= false and settings.glowTarget ~= "cdm")
        addon:SetTextAlertVisible(key, shown)
        addon:UpdateFrostTextAlertTimer(key, shown and states[key].endsAt or 0)
    else
        display.timeline:SetShown(shown and settings.timelineEnabled)
        display.icon:SetShown(shown and settings.iconEnabled)
    end
end

local function StopProcGlow(key)
    local display = frames[key]
    local function stop(frame)
        for _, glowType in ipairs(addon.GLOW_TYPES or {}) do
            if glowType.stop then pcall(glowType.stop, frame) end
        end
        if LCG and LCG.PixelGlow_Stop then pcall(LCG.PixelGlow_Stop, frame, "DKAssistFrostProc") end
    end
    if display then stop(display.icon) end
    for frame in pairs(frostProcCDMFrames[key] or {}) do
        if frame then stop(frame) end
    end
end

local function RefreshProcGlow(key)
    if key ~= "killingMachine" and key ~= "rime" then return end
    StopProcGlow(key)
    local settings = Settings(key)
    if not states[key].active or settings.iconEnabled == false then return end
    local glowType = addon:GetGlowTypeByID(settings.glowType or "pixel")
    if not glowType or not glowType.start then return end
    local opts = {
        color = settings.color or { r = 0.30, g = 0.85, b = 1.00 },
        alpha = settings.alpha or 1,
        lines = settings.lines or 8,
        speed = settings.speed or 0.25,
        thickness = settings.thickness or 2,
    }
    local function start(frame) pcall(glowType.start, frame, opts) end
    local targetFrames = settings.glowTarget == "cdm" and frostProcCDMFrames[key] or nil
    if targetFrames then
        for frame in pairs(targetFrames) do
            if frame then start(frame) end
        end
    else
        local display = EnsureFrames(key)
        start(display.icon)
    end
end

local function CancelPendingProcStop(key)
    frostProcHideGeneration[key] = (frostProcHideGeneration[key] or 0) + 1
    frostProcStopPending[key] = false
end

local function ScheduleProcStop(key)
    if frostProcStopPending[key] then return end
    frostProcStopPending[key] = true
    local generation = (frostProcHideGeneration[key] or 0) + 1
    frostProcHideGeneration[key] = generation
    C_Timer.After(0.20, function()
        if frostProcHideGeneration[key] ~= generation then return end
        frostProcStopPending[key] = false
        if not next(frostProcOverlayActive[key]) and states[key].active then
            StopTracker(key)
        end
    end)
end

function addon:RegisterCDMFrostProcFrame(frame, key)
    if not frostProcCDMFrames[key] or not frame then return end
    frostProcCDMFrames.killingMachine[frame] = nil
    frostProcCDMFrames.rime[frame] = nil
    frostProcCDMFrames[key][frame] = true
    local alreadyHooked = frostProcHookedFrames[frame] ~= nil
    frostProcHookedFrames[frame] = key
    if not alreadyHooked and frame.HookScript then
        frame:HookScript("OnShow", function()
            C_Timer.After(0, function()
                local currentKey = frostProcHookedFrames[frame]
                -- CDM frames are recycled and may be shown while their old
                -- proc state is still clearing.  An OnShow is presentation,
                -- not authoritative proc activation.
                if currentKey and states[currentKey].active then
                    RefreshProcGlow(currentKey)
                end
            end)
        end)
        frame:HookScript("OnHide", function()
            C_Timer.After(0, function()
                local currentKey = frostProcHookedFrames[frame]
                if currentKey then
                    frostProcNeedsClear[currentKey] = false
                    ScheduleProcStop(currentKey)
                end
            end)
        end)
    end
    RefreshProcGlow(key)
end

local function IsSecret(value)
    if not issecretvalue then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret or false
end

local function ReadCDMProcState(key)
    local readable = false
    for frame in pairs(frostProcCDMFrames[key] or {}) do
        if frame and frame.IsActive then
            local ok, active = pcall(frame.IsActive, frame)
            if ok and type(active) == "boolean" and not IsSecret(active) then
                readable = true
                if active then return true, true end
            end
        end
    end
    return false, readable
end

local function PollFrostProcFrames()
    if not addon:IsFrostSpec() then return end
    for _, key in ipairs({ "killingMachine", "rime" }) do
        local active, readable = ReadCDMProcState(key)
        if readable then
            if not active then
                frostProcNeedsClear[key] = false
                ScheduleProcStop(key)
            else
                CancelPendingProcStop(key)
            end
            if active and not frostProcNeedsClear[key] and not states[key].active then
                StartTracker(key, false)
            end
        end
    end
end

StartTracker = function(key, mock)
    local settings = Settings(key)
    local procOnly = key == "killingMachine" or key == "rime"
    local textSettings = procOnly and DKAssistDB and DKAssistDB[key .. "TextAlert"]
    if procOnly and settings.iconEnabled == false and not (textSettings and textSettings.enabled) then return end
    if not procOnly and not mock and not settings.timelineEnabled and not settings.iconEnabled then return end
    ApplyAppearance(key)
    local state, info = states[key], INFO[key]
    local now = GetTime()
    state.active = true; state.run = state.run + 1; state.startedAt = now; state.endsAt = now + info.duration
    if key == "darkTransformation" then state.extensions = 0 end
    if key == "pillarOfFrost" then state.auraPollElapsed = 0 end
    if key == "killingMachine" or key == "rime" then state.stacks = mock and 1 or 0 end
    if key == "gargoyle" then state.rpSpent = mock and 65 or 0; PollCosts() end
    if key == "darkTransformation" and not mock then
        C_Timer.After(0.10, function()
            local expiration = ReadDarkTransformationExpiration(); if expiration and state.active then state.endsAt = expiration end
        end)
    elseif key == "pillarOfFrost" and not mock then
        C_Timer.After(0.10, function()
            local expiration = ReadPillarOfFrostExpiration()
            if expiration and state.active then
                state.endsAt = math.max(state.endsAt, expiration)
            end
        end)
    elseif (key == "killingMachine" or key == "rime") and not mock then
        local aura = ReadPlayerAura(info.spellID)
        if aura then
            state.endsAt = tonumber(aura.expirationTime) or state.endsAt
            state.stacks = tonumber(aura.applications) or 1
        end
    end
    SetDisplaysShown(key, true)
    RefreshProcGlow(key)
end

StopTracker = function(key)
    StopProcGlow(key)
    if key == "killingMachine" or key == "rime" then states[key].lastEndedAt = GetTime() end
    states[key].active = false; states[key].startedAt = 0; states[key].endsAt = 0; SetDisplaysShown(key, false)
end

local function SetTimerColor(display, fraction)
    local r, g, b = 0.2, 1, 0.2
    if fraction <= 0.25 then r, g, b = 1, 0.2, 0.1 elseif fraction <= 0.5 then r, g, b = 1, 0.8, 0.1 end
    display.timeline.timer:SetTextColor(r, g, b, 1); display.icon.timer:SetTextColor(r, g, b, 1)
end

local function FinishGargoyle()
    local state, settings, display = states.gargoyle, Settings("gargoyle"), EnsureFrames("gargoyle")
    local finishedRun, finalPercent = state.run, state.rpSpent
    state.active = false; settings.bestPercent = math.max(settings.bestPercent or 0, finalPercent)
    display.timeline.detail:Hide()
    SetDisplaysShown("gargoyle", false)
end

local function FinishDurationTracker(key)
    local state = states[key]
    local settings, display = Settings(key), EnsureFrames(key)
    local finishedRun = state.run
    local finalDuration = math.max(INFO[key].duration, state.endsAt - state.startedAt)
    settings.bestDuration = math.max(settings.bestDuration or 0, finalDuration)
    state.active = false
    display.timeline.detail:Hide()
    SetDisplaysShown(key, false)
end

local function UpdateTracker(key)
    local state = states[key]
    if key == "killingMachine" or key == "rime" then
        addon:UpdateFrostTextAlertTimer(key, state.active and state.endsAt or 0)
    end
    if not state.active then return end
    local display, info, settings = EnsureFrames(key), INFO[key], Settings(key)
    local remaining = state.endsAt - GetTime()
    local elapsed = GetTime() - state.startedAt
    if remaining <= 0 then
        if key == "gargoyle" then FinishGargoyle()
        elseif key == "killingMachine" or key == "rime" then StopTracker(key)
        else FinishDurationTracker(key) end
        return
    end
    local text = string.format("%.1f", remaining)
    display.timeline.timer:SetText(text); display.icon.timer:SetText(text)
    display.timeline.bar:SetMinMaxValues(0, info.duration)
    display.timeline.bar:SetValue(math.min(info.duration, remaining))
    SetTimerColor(display, remaining / info.duration)
    if settings.showTimelineInfo == false then
        display.timeline.detail:Hide()
    elseif key == "gargoyle" then
        local damage = math.floor((state.rpSpent or 0) + 0.5)
        local bestDamage = math.max(settings.bestPercent or 0, damage)
        if settings.showDamage == false then
            display.timeline.detail:SetText(string.format("Active: %.1fs", elapsed))
        else
            display.timeline.detail:SetText(string.format("Active: %.1fs\nDamage: +%d%%\nBest: +%d%%", elapsed, damage, bestDamage))
        end
        display.timeline.detail:Show()
    elseif key == "darkTransformation" or key == "pillarOfFrost" then
        local totalDuration = math.max(info.duration, state.endsAt - state.startedAt)
        local extended = math.max(0, totalDuration - info.duration)
        local bestDuration = math.max(settings.bestDuration or 0, totalDuration)
        display.timeline.detail:SetText(string.format("Total: %.1fs\nExtend: +%.1fs\nBest: %.1fs", totalDuration, extended, bestDuration))
        display.timeline.detail:Show()
    elseif key == "killingMachine" or key == "rime" then
        display.timeline.detail:SetText(string.format("Proc active%s", state.stacks > 1 and (" x" .. state.stacks) or "")); display.timeline.detail:Show()
    else display.timeline.detail:Hide() end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    procPollElapsed = procPollElapsed + elapsed
    if procPollElapsed >= 0.10 then
        procPollElapsed = 0
        PollFrostProcFrames()
    end
    if states.gargoyle.active then costElapsed = costElapsed + elapsed; if costElapsed >= COST_POLL_INTERVAL then costElapsed = 0; PollCosts() end end
    if states.pillarOfFrost.active then
        local state = states.pillarOfFrost
        state.auraPollElapsed = (state.auraPollElapsed or 0) + elapsed
        if state.auraPollElapsed >= 0.10 then
            state.auraPollElapsed = 0
            local expiration = ReadPillarOfFrostExpiration()
            if expiration then state.endsAt = math.max(state.endsAt, expiration) end
        end
    end
    for key in pairs(INFO) do UpdateTracker(key) end
end)

function addon:RefreshBurstTrackers()
    -- Reuse known proc state when text is enabled after an overlay event.
    if addon:IsFrostSpec() then
        PollFrostProcFrames()
        for _, key in ipairs({ "killingMachine", "rime" }) do
            if not states[key].active and not frostProcNeedsClear[key] and next(frostProcOverlayActive[key]) then
                StartTracker(key, false)
            end
        end
    end
    for key in pairs(INFO) do
        ApplyAppearance(key)
        SetDisplaysShown(key, states[key].active or testKeys[key])
        RefreshProcGlow(key)
    end
end

function addon:TestBurstTracker(key)
    if INFO[key] then testKeys[key] = true; StartTracker(key, true) end
end

function addon:TestBurstTrackers()
    addon:TestBurstTracker("gargoyle"); addon:TestBurstTracker("darkTransformation")
end

function addon:StopBurstTrackerTest()
    wipe(testKeys)
    for key in pairs(INFO) do StopTracker(key) end
end

function addon:ResetBurstTrackerPositions(key)
    if not INFO[key] then return end
    local settings, info, display = Settings(key), INFO[key], EnsureFrames(key)
    settings.timelinePosition = nil; settings.iconPosition = nil
    RestorePosition(display.timeline, key, "timelinePosition", info.fallbackX, 130)
    RestorePosition(display.icon, key, "iconPosition", info.fallbackX, 30)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_TALENT_UPDATE"); events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED"); events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW"); events:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
events:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        EnsureSettingsSchema()
        addon:RefreshBurstTrackers()
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local overlaySpellID = unit
        local key = KILLING_MACHINE_OVERLAY_IDS[overlaySpellID] and "killingMachine"
            or (RIME_OVERLAY_IDS[overlaySpellID] and "rime")
        if not key or not addon:IsFrostSpec() then return end
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            CancelPendingProcStop(key)
            frostProcNeedsClear[key] = false
            frostProcOverlayActive[key][overlaySpellID] = true
            if not frostProcNeedsClear[key] and not states[key].active then StartTracker(key, false) end
        else
            frostProcOverlayActive[key][overlaySpellID] = nil
            if not next(frostProcOverlayActive[key]) then frostProcNeedsClear[key] = false end
            if not next(frostProcOverlayActive[key]) and states[key].active then ScheduleProcStop(key) end
        end
    elseif event == "UNIT_AURA" and unit == "pet" and states.darkTransformation.active then
        local expiration = ReadDarkTransformationExpiration(); if expiration then states.darkTransformation.endsAt = expiration end
    elseif event == "UNIT_AURA" and unit == "player" then
        if states.pillarOfFrost.active then
            local expiration = ReadPillarOfFrostExpiration()
            if expiration then
                local state = states.pillarOfFrost
                state.endsAt = math.max(state.endsAt, expiration)
            end
        end
        local killingAura = ReadPlayerAura(KILLING_MACHINE_ID) or ReadPlayerAura(KILLING_MACHINE_AURA_ID)
        if killingAura then
            if not frostProcNeedsClear.killingMachine and not states.killingMachine.active and addon:IsFrostSpec() then
                StartTracker("killingMachine", false)
            end
            if states.killingMachine.active then
                states.killingMachine.endsAt = tonumber(killingAura.expirationTime) or states.killingMachine.endsAt
                states.killingMachine.stacks = tonumber(killingAura.applications) or 1
            end
        end
        local rimeAura = ReadPlayerAura(RIME_ID)
        if rimeAura then
            if not states.rime.active and addon:IsFrostSpec() then StartTracker("rime", false) end
            if states.rime.active then
                states.rime.endsAt = tonumber(rimeAura.expirationTime) or states.rime.endsAt
                states.rime.stacks = tonumber(rimeAura.applications) or 1
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if spellID == GARGOYLE_SPELL_ID and IsPlayerSpell(GARGOYLE_TALENT_ID) then StartTracker("gargoyle", false)
        elseif spellID == DARK_TRANSFORMATION_ID then StartTracker("darkTransformation", false)
        elseif spellID == PILLAR_OF_FROST_ID and addon:IsFrostSpec() then StartTracker("pillarOfFrost", false)
        elseif RP_SPENDERS[spellID] then
            if states.gargoyle.active then
                states.gargoyle.rpSpent = states.gargoyle.rpSpent + (cachedCosts[spellID] or 0)
            end
            if states.darkTransformation.active and states.darkTransformation.endsAt > GetTime() then
                states.darkTransformation.endsAt = states.darkTransformation.endsAt + DARK_TRANSFORMATION_EXTENSION
                states.darkTransformation.extensions = states.darkTransformation.extensions + DARK_TRANSFORMATION_EXTENSION
            end
        end
    elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if not IsPlayerSpell(GARGOYLE_TALENT_ID) then StopTracker("gargoyle") end
        if not addon:IsFrostSpec() then StopTracker("pillarOfFrost") end
        if not addon:IsFrostSpec() then StopTracker("killingMachine"); StopTracker("rime") end
    end
end)
