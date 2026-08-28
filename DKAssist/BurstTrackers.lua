-- DK Assist - independent Gargoyle and Dark Transformation trackers
local addonName, addon = ...

local GARGOYLE_SPELL_ID = 42650
local GARGOYLE_TALENT_ID = 1242147
local GARGOYLE_DURATION = 25
local DARK_TRANSFORMATION_ID = addon.SPELLS.DARK_TRANSFORMATION.id
local DARK_TRANSFORMATION_DURATION = 30
local COST_POLL_INTERVAL = 0.10
local GARGOYLE_TEXTURE = "Interface\\Icons\\Ability_DeathKnight_SummonGargoyle"

local RP_SPENDERS = {
    [47541] = true, [1242174] = true, [207317] = true, [383269] = true,
}

local function TrackerDefaults(showDamage)
    return {
        timelineEnabled = true, iconEnabled = false,
        timelineScale = 64, timelineOrientation = "horizontal", iconSize = 64, fontSize = 18,
        showSpellName = true, showDamage = showDamage and true or false,
        timelineLocked = false, iconLocked = false,
        timelinePosition = nil, iconPosition = nil, bestPercent = 0,
    }
end

addon.DEFAULT_DB.burstTrackers = {
    gargoyle = TrackerDefaults(true),
    darkTransformation = TrackerDefaults(false),
}

local INFO = {
    gargoyle = { spellID = GARGOYLE_SPELL_ID, texture = GARGOYLE_TEXTURE, name = "Gargoyle", duration = GARGOYLE_DURATION, fallbackX = -170 },
    darkTransformation = { spellID = DARK_TRANSFORMATION_ID, name = "Dark Transformation", duration = DARK_TRANSFORMATION_DURATION, fallbackX = 170 },
}

local frames = {}
local states = {
    gargoyle = { active = false, endsAt = 0, rpSpent = 0, run = 0 },
    darkTransformation = { active = false, endsAt = 0, run = 0 },
}
local cachedCosts, costElapsed, testKeys = {}, 0, {}

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
    display.timeline.icon:ClearAllPoints()
    display.timeline.bar:ClearAllPoints()
    display.timeline.detail:ClearAllPoints()
    if vertical then
        display.timeline:SetSize(math.floor(126 * scale + 0.5), math.floor(340 * scale + 0.5))
        display.timeline.icon:SetSize(iconSide, iconSide)
        display.timeline.icon:SetPoint("TOP", display.timeline, "TOP", 0, -25 * scale)
        display.timeline.bar:SetOrientation("VERTICAL")
        display.timeline.bar:SetWidth(math.max(8, math.floor(10 * scale + 0.5)))
        display.timeline.bar:SetPoint("TOP", display.timeline.icon, "BOTTOM", 0, -10 * scale)
        display.timeline.bar:SetPoint("BOTTOM", display.timeline, "BOTTOM", 0, 25 * scale)
        display.timeline.detail:SetPoint("BOTTOM", display.timeline, "BOTTOM", 0, 4 * scale)
        display.timeline.detail:SetWidth(math.floor(118 * scale + 0.5))
        display.timeline.detail:SetJustifyH("CENTER")
    else
        display.timeline:SetSize(math.floor(360 * scale + 0.5), math.floor(70 * scale + 0.5))
        display.timeline.icon:SetSize(iconSide, iconSide)
        display.timeline.icon:SetPoint("LEFT", display.timeline, "LEFT", 12 * scale, -6 * scale)
        display.timeline.bar:SetOrientation("HORIZONTAL")
        display.timeline.bar:SetHeight(math.max(8, math.floor(8 * scale + 0.5)))
        display.timeline.bar:SetPoint("LEFT", display.timeline.icon, "RIGHT", 10 * scale, 0)
        display.timeline.bar:SetPoint("RIGHT", display.timeline, "RIGHT", -12 * scale, 0)
        display.timeline.detail:SetPoint("BOTTOM", display.timeline, "BOTTOM", 0, 3 * scale)
        display.timeline.detail:SetWidth(math.floor(330 * scale + 0.5))
        display.timeline.detail:SetJustifyH("CENTER")
    end
    display.timeline.timer:SetFont(STANDARD_TEXT_FONT, settings.fontSize or 18, "OUTLINE")
    display.timeline.nameText:SetFont(STANDARD_TEXT_FONT, math.max(10, (settings.fontSize or 18) - 4), "OUTLINE")
    display.timeline.detail:SetFont(STANDARD_TEXT_FONT, math.max(9, (settings.fontSize or 18) - 6), "OUTLINE")
    display.timeline.nameText:SetShown(settings.showSpellName ~= false); display.timeline.unlock:SetShown(not settings.timelineLocked)
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
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, DARK_TRANSFORMATION_ID)
        if ok and aura and tonumber(aura.expirationTime) then return tonumber(aura.expirationTime) end
    end
    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local ok, _, _, _, _, _, expirationTime = pcall(AuraUtil.FindAuraBySpellID, DARK_TRANSFORMATION_ID, "player", "HELPFUL")
        if ok and tonumber(expirationTime) then return tonumber(expirationTime) end
    end
end

local function SetDisplaysShown(key, shown)
    local display, settings = EnsureFrames(key), Settings(key)
    display.timeline:SetShown(shown and settings.timelineEnabled); display.icon:SetShown(shown and settings.iconEnabled)
end

local function StartTracker(key, mock)
    local settings = Settings(key)
    if not mock and not settings.timelineEnabled and not settings.iconEnabled then return end
    ApplyAppearance(key)
    local state, info = states[key], INFO[key]
    state.active = true; state.run = state.run + 1; state.endsAt = GetTime() + info.duration
    if key == "gargoyle" then state.rpSpent = mock and 65 or 0; PollCosts() end
    if key == "darkTransformation" and not mock then
        C_Timer.After(0.10, function()
            local expiration = ReadDarkTransformationExpiration(); if expiration and state.active then state.endsAt = expiration end
        end)
    end
    SetDisplaysShown(key, true)
end

local function StopTracker(key)
    states[key].active = false; states[key].endsAt = 0; SetDisplaysShown(key, false)
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
    display.timeline.timer:SetText(""); display.icon.timer:SetText("")
    display.timeline.detail:SetText(string.format("Final: +%d%%   Best: +%d%%", finalPercent, settings.bestPercent)); display.timeline.detail:Show()
    C_Timer.After(3, function() if not state.active and state.run == finishedRun then SetDisplaysShown("gargoyle", false) end end)
end

local function UpdateTracker(key)
    local state = states[key]; if not state.active then return end
    local display, info, settings = EnsureFrames(key), INFO[key], Settings(key)
    local remaining = state.endsAt - GetTime()
    if remaining <= 0 then if key == "gargoyle" then FinishGargoyle() else StopTracker(key) end; return end
    local text = string.format("%.1f", remaining)
    display.timeline.timer:SetText(text); display.icon.timer:SetText(text); display.timeline.bar:SetValue(math.min(info.duration, remaining))
    SetTimerColor(display, remaining / info.duration)
    if key == "gargoyle" and settings.showDamage then
        display.timeline.detail:SetText(string.format("+%d%% Gargoyle Damage", state.rpSpent)); display.timeline.detail:Show()
    else display.timeline.detail:Hide() end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, elapsed)
    if states.gargoyle.active then costElapsed = costElapsed + elapsed; if costElapsed >= COST_POLL_INTERVAL then costElapsed = 0; PollCosts() end end
    UpdateTracker("gargoyle"); UpdateTracker("darkTransformation")
end)

function addon:RefreshBurstTrackers()
    for key in pairs(INFO) do
        ApplyAppearance(key)
        SetDisplaysShown(key, states[key].active or testKeys[key])
    end
end

function addon:TestBurstTracker(key)
    if INFO[key] then testKeys[key] = true; StartTracker(key, true) end
end

function addon:TestBurstTrackers()
    addon:TestBurstTracker("gargoyle"); addon:TestBurstTracker("darkTransformation")
end

function addon:StopBurstTrackerTest()
    wipe(testKeys); StopTracker("gargoyle"); StopTracker("darkTransformation")
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
events:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        EnsureSettingsSchema()
        addon:RefreshBurstTrackers()
    elseif event == "UNIT_AURA" and unit == "player" and states.darkTransformation.active then
        local expiration = ReadDarkTransformationExpiration(); if expiration then states.darkTransformation.endsAt = expiration end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if spellID == GARGOYLE_SPELL_ID and IsPlayerSpell(GARGOYLE_TALENT_ID) then StartTracker("gargoyle", false)
        elseif spellID == DARK_TRANSFORMATION_ID then StartTracker("darkTransformation", false)
        elseif states.gargoyle.active and RP_SPENDERS[spellID] then states.gargoyle.rpSpent = states.gargoyle.rpSpent + (cachedCosts[spellID] or 0) end
    elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if not IsPlayerSpell(GARGOYLE_TALENT_ID) then StopTracker("gargoyle") end
    end
end)
