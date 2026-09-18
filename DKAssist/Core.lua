local addonName, addon = ...
DKAssist = addon

local LCG = LibStub("LibCustomGlow-1.0")

addon.SPELLS = {
    FESTERING_SCYTHE = {
        id   = 458128,
        name = "Festering Scythe",
        key  = "festeringScythe",
    },
    FESTERING_STRIKE = {
        id   = 85948,
        name = "Festering Strike",
        key  = "festeringScythe",
    },
    DARK_TRANSFORMATION = {
        id   = 1233448,
        name = "Dark Transformation",
        key  = nil,
    },
    PILLAR_OF_FROST = {
        id   = 51271,
        name = "Pillar of Frost",
        key  = nil,
    },
    KILLING_MACHINE = {
        id   = 51124,
        name = "Killing Machine",
        key  = nil,
    },
    RIME = {
        id   = 59052,
        name = "Rime",
        key  = nil,
    },
    PUTREFY = {
        id   = 1247378,
        name = "Putrefy",
        key  = "putrefy",
    },
    DEATH_AND_DECAY = {
        id   = 43265,
        name = "Death and Decay",
        icon = 136144,
        key  = "deathAndDecay",
    },
    DEATH_AND_DECAY_BUFF = {
        id   = 188290,
        name = "Death and Decay Buff",
        key  = nil,
    },
    BONE_SHIELD = {
        id   = 195181,
        name = "Bone Shield",
        key  = nil,
    },
    BLOOD_SHIELD = {
        id   = 77535,
        name = "Blood Shield",
        key  = nil,
    },
    MARROWREND = {
        id   = 195182,
        name = "Marrowrend",
        key  = nil,
    },
    DEATHS_CARESS = {
        id   = 195292,
        name = "Death's Caress",
        key  = nil,
    },
    SOUL_REAPER = {
        id   = 343294,
        name = "Soul Reaper",
        key  = nil,
    },
    BLIGHTFALL = {
        id   = 1271967,
        name = "Blightfall",
        icon = 5976940,
        key  = nil,
    },
    DEATH_COIL = { id = 47541, name = "Death Coil", key = "deathCoil" },
    NECROTIC_COIL = { id = 1242174, name = "Necrotic Coil", key = "deathCoil" },
    EPIDEMIC = { id = 207317, name = "Epidemic", key = "epidemic" },
    GRAVEYARD = { id = 383269, name = "Graveyard", key = "epidemic" },
}

addon.GLOW_TYPES = {
    {
        id = "pixel",
        name = "Pixel Glow",
        description = "Rotating pixel lines around the button",
        start = function(frame, opts)
            if LCG and LCG.PixelGlow_Start then
                LCG.PixelGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.lines or 8, opts.speed or 0.25, opts.length,
                    opts.thickness or 2, 0, 0, opts.border, "DKAssist")
            end
        end,
        stop = function(frame)
            if LCG and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(frame, "DKAssist") end
        end,
    },
    {
        id = "autocast",
        name = "Autocast Shine",
        description = "Sparkling particles at corners",
        start = function(frame, opts)
            if LCG and LCG.AutoCastGlow_Start then
                LCG.AutoCastGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.particles or 4, opts.speed or 0.125, opts.scale or 1,
                    0, 0, "DKAssist")
            end
        end,
        stop = function(frame)
            if LCG and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(frame, "DKAssist") end
        end,
    },
    {
        id = "button",
        name = "Button Glow",
        description = "Classic WoW proc glow overlay",
        start = function(frame, opts)
            if LCG and LCG.ButtonGlow_Start then
                LCG.ButtonGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.speed or 0.5)
            end
        end,
        stop = function(frame)
            if LCG and LCG.ButtonGlow_Stop then LCG.ButtonGlow_Stop(frame) end
        end,
    },
    {
        id = "proc",
        name = "Proc Border",
        description = "Animated glowing border",
        start = function(frame, opts)
            if LCG and LCG.ProcGlow_Start then
                LCG.ProcGlow_Start(frame, {
                    key = "DKAssist",
                    color = {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    frequency = opts.speed or 0.25,
                    thickness = opts.thickness or 2,
                    startAnim = false,
                })
            end
        end,
        stop = function(frame)
            if LCG and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(frame, "DKAssist") end
        end,
    },
}

addon.GLOW_TYPE_MAP = {}
for _, glowType in ipairs(addon.GLOW_TYPES) do
    addon.GLOW_TYPE_MAP[glowType.id] = glowType
end

addon.PUTREFY_WARNING_TYPES = {
    {
        id = "cross",
        name = "Red Cross",
        description = "A bold red + cross drawn over the button",
    },
    {
        id = "glow",
        name = "Red Glow Border",
        description = "Pulsing red pixel glow border around the button",
    },
}

addon.PUTREFY_WARNING_TYPE_MAP = {}
for _, wt in ipairs(addon.PUTREFY_WARNING_TYPES) do
    addon.PUTREFY_WARNING_TYPE_MAP[wt.id] = wt
end

local DEFAULT_GLOW_SETTINGS = {
    enabled    = true,
    glowType   = "pixel",
    color      = {r = 0.0, g = 0.9, b = 0.2},
    alpha      = 1.0,
    speed      = 0.25,
    lines      = 8,
    thickness  = 2,
    particles  = 4,
    scale      = 1.0,
    border     = false,
    glowTiming = 5,
    -- When entering combat without the Festering Scythe buff, remind the
    -- player after this optional grace period.
    combatGlow  = true,
    combatGrace = 0,
    -- Independent reminder while Lesser Ghoul is absent in combat.
    lesserGhoulGlow = false,
}

local DEFAULT_PUTREFY_SETTINGS = {
    enabled        = true,
    warningType    = "cross",
    crossColor     = {r = 1.0, g = 0.0, b = 0.0},
    crossAlpha     = 0.9,
    crossThickness = 0.25,
    glowColor      = {r = 1.0, g = 0.0, b = 0.0},
    glowAlpha      = 1.0,
    glowSpeed      = 0.25,
    glowLines      = 8,
    glowThickness  = 3,
}

addon.DEFAULT_DB = {
    seenWelcome       = false,
    -- Visual skin for the dedicated minimap window only.  Blizzard's
    -- Settings > AddOns canvas deliberately keeps its native appearance.
    standaloneTheme   = "classic",
    trackCDMFestering = false,
    trackCDMPutrefy   = false,
    trackCDMSuddenDoom = false,
    configSpecView    = "auto",
    runicPowerWarning = true,
    runicPower = {
        enabled = true,
        glowType = "pixel",
        color = {r = 0.0, g = 0.72, b = 1.0},
        alpha = 1.0,
        speed = 0.25,
        lines = 8,
        thickness = 2,
        threshold = 85,
    },
    spells = {
        festeringScythe = CopyTable(DEFAULT_GLOW_SETTINGS),
        deathCoil       = CopyTable(DEFAULT_GLOW_SETTINGS),
        epidemic        = CopyTable(DEFAULT_GLOW_SETTINGS),
    },
    -- This is the separate style for the Sudden Doom proc icon when it is
    -- tracked in the Cooldown Manager.  It must not share colors with either
    -- Death Coil or Epidemic action-bar glows.
    suddenDoomGlow = CopyTable(DEFAULT_GLOW_SETTINGS),
    putrefy = CopyTable(DEFAULT_PUTREFY_SETTINGS),
    dnd = {
        enabled    = true,
        size       = 48,
        locked     = false,
        alwaysShow = false,
        color      = {r = 0.20, g = 1.00, b = 0.25},
        graceColor = {r = 1.00, g = 0.45, b = 0.08},
        position   = nil,  -- {point, relPoint, x, y}
    },
    blightfallChain = {
        enabled         = false,
        iconEnabled     = false,
        soundEnabled    = true,
        soundVolume     = 100,
        soulReaperDelay = 6.0,
        blightfallDelay = 7.5,
        size            = 48,
        timelineOrientation = "horizontal",
        locked          = false,
        position        = nil,
        iconSize        = 64,
        iconLocked      = false,
        iconPosition    = nil,
        fontSize        = 18,
        showSpellNames  = true,
        glowType        = "button",
        color           = { r = 0.72, g = 0.40, b = 1.00 },
        speed           = 0.25,
        lines           = 8,
        thickness       = 2,
        alpha           = 1.00,
    },
    bloodDnd = {
        enabled   = false,
        glowType  = "pixel",
        color     = {r = 0.85, g = 0.10, b = 0.10},
        alpha     = 1.0,
        speed     = 0.25,
        lines     = 8,
        thickness = 2,
        particles = 4,
        scale     = 1.0,
        border    = false,
    },
    bloodDndMissing = {
        enabled   = false,
        glowType  = "pixel",
        color     = {r = 0.85, g = 0.10, b = 0.10},
        alpha     = 1.0,
        speed     = 0.25,
        lines     = 8,
        thickness = 2,
        particles = 4,
        scale     = 1.0,
        border    = false,
    },
    bloodBone = {
        enabled   = false,
        warningAfter = 25,
        textAlert = true,
        soundAlert = true,
        earlyWarning = true,
        missingWarning = true,
        ossuaryWarning = false,
        earlySound = "READY_CHECK",
        missingSound = "RAID_WARNING",
        glowType  = "pixel",
        color     = {r = 0.85, g = 0.10, b = 0.10},
        alpha     = 1.0,
        speed     = 0.25,
        lines     = 8,
        thickness = 2,
        particles = 4,
        scale     = 1.0,
        border    = false,
    },
    bloodShield = {
        enabled = false,
        showIcon = true,
        showDuration = true,
        width = 260,
        height = 36,
        iconSize = 52,
        locked = false,
        color = { r = 0.90, g = 0.05, b = 0.20 },
    },
    soulReaper = {
        suppressMode = "off",  -- "off", "cooldown", "always"
    },
}

-- Text alerts deliberately use the same state DK Assist already calculates
-- for its glows.  This avoids DKQoL's old spell-cost polling approach, which
-- can receive secret values in 12.1.
local function DefaultTextAlert(text, color)
    return {
        enabled = false,
        text = text,
        expiredWarning = false,
        ghoulMissingWarning = false,
        secondsLeft = 5,
        fontSize = 28,
        font = "Fonts\\FRIZQT__.TTF",
        outline = "OUTLINE",
        color = color or { r = 1.00, g = 0.82, b = 0.10 },
        locked = false,
        point = nil,
    }
end
addon.DEFAULT_DB.spells.festeringScythe.textAlert = DefaultTextAlert("FESTERING SCYTHE", { r = 1.00, g = 1.00, b = 1.00 })
addon.DEFAULT_DB.spells.deathCoil.textAlert = DefaultTextAlert("SUDDEN DOOM - DEATH COIL")
addon.DEFAULT_DB.spells.epidemic.textAlert = DefaultTextAlert("SUDDEN DOOM - EPIDEMIC")
addon.DEFAULT_DB.suddenDoomTextAlert = DefaultTextAlert("SUDDEN DOOM", { r = 0.00, g = 0.90, b = 0.20 })
addon.DEFAULT_DB.killingMachineTextAlert = DefaultTextAlert("KILLING MACHINE", { r = 0.30, g = 0.85, b = 1.00 })
addon.DEFAULT_DB.rimeTextAlert = DefaultTextAlert("RIME", { r = 0.30, g = 0.85, b = 1.00 })
addon.DEFAULT_DB.killingMachineTextAlert.showTimer = false
addon.DEFAULT_DB.rimeTextAlert.showTimer = false

local REMOVED_TEXT_FONTS = {
    ["Fonts\\2002B.TTF"] = true,
    ["Fonts\\BLEIWEIS.TTF"] = true,
    ["Fonts\\K_Pagetext.TTF"] = true,
}

local function NormalizeTextAlertFont(settings)
    if settings and REMOVED_TEXT_FONTS[settings.font] then
        settings.font = STANDARD_TEXT_FONT
    end
end

local textAlertFrames = {}
local textAlertTimers = {}
local frostTextTestEnds = {}
local festeringTextTicker = nil
local festeringTextEndTime = nil
local festeringTextNormalWanted = false
local festeringTextGhoulMissing = false

local function GetTextAlertSettings(key)
    if key == "suddenDoom" or key == "killingMachine" or key == "rime" then
        return DKAssistDB and DKAssistDB[key .. "TextAlert"]
    end
    return DKAssistDB and DKAssistDB.spells and DKAssistDB.spells[key] and DKAssistDB.spells[key].textAlert
end

local function EnsureTextAlertFrame(key)
    if textAlertFrames[key] then return textAlertFrames[key] end
    local frame = CreateFrame("Frame", "DKAssistTextAlert" .. key, UIParent, "BackdropTemplate")
    frame:SetSize(280, 48)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        local settings = GetTextAlertSettings(key)
        if settings and not settings.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local settings = GetTextAlertSettings(key)
        if settings then
            local point, _, relativePoint, x, y = self:GetPoint()
            settings.point = { point, relativePoint, x, y }
        end
    end)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("TOP", frame, "TOP", 0, -2)
    frame.text:SetJustifyH("CENTER")
    frame.text:SetJustifyV("MIDDLE")
    frame.timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.timerText:SetPoint("TOP", frame.text, "BOTTOM", 0, -4)
    frame.timerText:SetJustifyH("CENTER")
    frame.timerText:SetJustifyV("MIDDLE")
    frame:Hide()
    textAlertFrames[key] = frame
    return frame
end

function addon:RefreshTextAlert(key)
    local settings = GetTextAlertSettings(key)
    if not settings then return end
    local frame = EnsureTextAlertFrame(key)
    frame:ClearAllPoints()
    if settings.point then
        frame:SetPoint(settings.point[1], UIParent, settings.point[2], settings.point[3], settings.point[4])
    else
        local offset = key == "festeringScythe" and 145 or (key == "rime" and 60 or 100)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, offset)
    end
    frame.text:SetText(settings.text or "DK ASSIST")
    local font = settings.font or STANDARD_TEXT_FONT
    local fontSize = settings.fontSize or 28
    local outline = settings.outline or "OUTLINE"
    if not frame.text:SetFont(font, fontSize, outline) then
        settings.font = STANDARD_TEXT_FONT
        font = STANDARD_TEXT_FONT
        frame.text:SetFont(font, fontSize, outline)
    end
    frame.timerText:SetFont(font, math.max(14, fontSize - 4), outline)
    local c = settings.color or { r = 1, g = 0.82, b = 0.1 }
    frame.text:SetTextColor(c.r, c.g, c.b, 1)
    if key == "festeringScythe" and festeringTextGhoulMissing then
        -- The missing-ghoul reminder has priority over the normal Scythe
        -- countdown, because rebuilding Lesser Ghoul stacks is the action the
        -- player needs to take first.
        frame.text:SetText("LESSER GHOUL MISSING")
        frame.timerText:SetText("")
    end
    local width = math.max(280, frame.text:GetStringWidth() + 32, frame.timerText:GetStringWidth() + 32)
    frame:SetSize(width, key == "festeringScythe" and (fontSize * 2 + 18) or (fontSize + 20))
    frame.timerText:SetShown(key == "festeringScythe" and frame.timerText:GetText() ~= "")
    if key == "killingMachine" or key == "rime" then
        frame.timerText:SetTextColor(c.r, c.g, c.b, 1)
        frame._frostTimerShown = nil
        addon:UpdateFrostTextAlertTimer(key)
    end
    frame:SetShown(settings.enabled and frame._dkAssistWanted)
end

-- Called by the existing burst tracker driver, with no new aura scan or ticker.
function addon:UpdateFrostTextAlertTimer(key, expiration)
    if key ~= "killingMachine" and key ~= "rime" then return end
    local frame, settings = textAlertFrames[key], GetTextAlertSettings(key)
    if not frame or not settings then return end
    if type(expiration) ~= "nil" then frame._frostExpiration = expiration end
    local expires = frostTextTestEnds[key] or frame._frostExpiration
    local readable = not (issecretvalue and issecretvalue(expires)) and type(expires) == "number"
    local show = settings.enabled and settings.showTimer and frame._dkAssistWanted and readable
    local remaining = show and math.max(0, expires - GetTime()) or 0
    show = show and remaining > 0 or false
    if frame._frostTimerShown ~= show then
        frame._frostTimerShown = show
        frame.timerText:SetShown(show)
        local size = settings.fontSize or 28
        frame:SetHeight(show and (size * 2 + 18) or (size + 20))
    end
    local text = show and string.format("%.1fs", remaining) or ""
    if frame._frostTimerText ~= text then
        frame._frostTimerText = text
        frame.timerText:SetText(text)
    end
end

local function StopFesteringTextTicker()
    if festeringTextTicker then
        festeringTextTicker:Cancel()
        festeringTextTicker = nil
    end
end

local function UpdateFesteringTextCountdown()
    local frame = EnsureTextAlertFrame("festeringScythe")
    if not festeringTextEndTime then
        frame.timerText:SetText("")
        return
    end
    local remaining = math.max(0, festeringTextEndTime - GetTime())
    if remaining <= 0 then
        local settings = GetTextAlertSettings("festeringScythe")
        if settings and settings.expiredWarning then
            frame.text:SetText(settings.text or "FESTERING SCYTHE")
            frame.timerText:SetText("EXPIRED")
            frame.timerText:SetTextColor(1.0, 0.2, 0.2, 1)
        else
            frame._dkAssistWanted = false
            frame:Hide()
        end
        StopFesteringTextTicker()
    else
        local r, g, b
        if remaining > 5 then r, g, b = 0.2, 1.0, 0.2
        elseif remaining > 2 then r, g, b = 1.0, 0.78, 0.0
        else r, g, b = 1.0, 0.2, 0.2 end
        frame.timerText:SetTextColor(r, g, b, 1)
        frame.timerText:SetText(string.format("%.1fs", remaining))
    end
end

local function StartFesteringTextTicker()
    StopFesteringTextTicker()
    UpdateFesteringTextCountdown()
    festeringTextTicker = C_Timer.NewTicker(0.05, UpdateFesteringTextCountdown)
end

function addon:SetTextAlertVisible(key, visible)
    local settings = GetTextAlertSettings(key)
    if not settings then return end
    local frame = EnsureTextAlertFrame(key)
    if not visible and (key == "killingMachine" or key == "rime") then
        frostTextTestEnds[key] = nil
        frame._frostExpiration = nil
    end
    if key == "festeringScythe" then
        festeringTextNormalWanted = visible and true or false
        frame._dkAssistWanted = festeringTextNormalWanted or festeringTextGhoulMissing
    else
        frame._dkAssistWanted = visible and true or false
    end
    if key == "festeringScythe" then
        if festeringTextNormalWanted and not festeringTextGhoulMissing and festeringTextEndTime then
            StartFesteringTextTicker()
        else
            StopFesteringTextTicker()
        end
    end
    addon:RefreshTextAlert(key)
end

local function SetFesteringGhoulTextAlert(missing)
    missing = missing and true or false
    if festeringTextGhoulMissing == missing then return end
    festeringTextGhoulMissing = missing

    local frame = EnsureTextAlertFrame("festeringScythe")
    frame._dkAssistWanted = festeringTextNormalWanted or festeringTextGhoulMissing
    if festeringTextGhoulMissing then
        StopFesteringTextTicker()
    elseif festeringTextNormalWanted and festeringTextEndTime then
        StartFesteringTextTicker()
    end
    addon:RefreshTextAlert("festeringScythe")
end

function addon:TestTextAlert(key)
    local settings = GetTextAlertSettings(key)
    if not settings then return end
    if textAlertTimers[key] then textAlertTimers[key]:Cancel() end
    if key == "festeringScythe" then festeringTextEndTime = GetTime() + 5 end
    if key == "killingMachine" or key == "rime" then frostTextTestEnds[key] = GetTime() + 5 end
    addon:SetTextAlertVisible(key, true)
    textAlertTimers[key] = C_Timer.NewTimer(5, function()
        textAlertTimers[key] = nil
        addon:SetTextAlertVisible(key, false)
    end)
end

function addon:ShowTemporaryTextAlert(key, text, duration)
    local settings = GetTextAlertSettings(key)
    if not settings then return end
    if textAlertTimers[key] then textAlertTimers[key]:Cancel() end
    addon:SetTextAlertVisible(key, true)
    local frame = EnsureTextAlertFrame(key)
    frame.text:SetText(text)
    if key == "festeringScythe" then
        StopFesteringTextTicker()
        frame.timerText:SetText("EXPIRED")
        frame.timerText:SetTextColor(1.0, 0.2, 0.2, 1)
    end
    textAlertTimers[key] = C_Timer.NewTimer(duration or 3, function()
        textAlertTimers[key] = nil
        addon:SetTextAlertVisible(key, false)
    end)
end

function addon:GetGlowTypeByID(id)
    return addon.GLOW_TYPE_MAP[id] or addon.GLOW_TYPES[1]
end

local festeringOverlays    = {}
local putrefyOverlays      = {}
local cdmFesteringOverlays = {}
local cdmPutrefyOverlays   = {}
local suddenDoomOverlays   = {}
local cdmSuddenDoomOverlays = {}
local cdmBloodDnDOverlays = {}
local dndMissingBarOverlays = {}
local cdmDnDMissingOverlays = {}
local cdmBloodBoneOverlays = {}
-- Keep only Blizzard's engine-driven Tracked Buff frames here.  Ellesmere's
-- visual bar icons are persistent placeholders, so their :IsShown() state
-- cannot tell whether the player is actually standing in Death and Decay.
local bloodDnDBuffFrames = {}
local bloodDnDTestActive = false
local bloodDnDReady = true
local bloodDnDReadyTimer = nil
-- Shared with the early Blood watcher and the later timeline controller.
local dndActive = false
local dndAuraKnownInside = false
local dndLastAuraAppliedAt = 0
local dndMissingGlowActive = false
local BLOOD_DND_COOLDOWN = 15
local CRIMSON_SCOURGE_AURA_ID = 81141
local suddenDoomActive = false
local putrefyWarningActive = false

function addon:GetActiveSpecID()
    if not (GetSpecialization and GetSpecializationInfo) then return nil end
    local index = GetSpecialization()
    if not index then return nil end
    return GetSpecializationInfo(index)
end

function addon:IsBloodSpec()
    return self:GetActiveSpecID() == 250
end

function addon:IsFrostSpec()
    return self:GetActiveSpecID() == 251
end

function addon:IsUnholySpec()
    return self:GetActiveSpecID() == 252
end

function addon:IsSanlaynHeroSpec()
    if not (C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec) then return false end
    local ok, heroSpecID = pcall(C_ClassTalents.GetActiveHeroTalentSpec)
    return ok and heroSpecID == 31
end

local function GetSuddenDoomOverlaySettings(overlay)
    if DKAssistDB.trackCDMSuddenDoom then return DKAssistDB.suddenDoomGlow end
    return DKAssistDB.spells[overlay._spellKey]
end

local function CreateOverlay(targetFrame, spellKey)
    -- Keep the direct-child arrangement used by the original effects, but
    -- inherit the target's strata.  A fixed HIGH strata made the glow draw on
    -- top of the map, bags and other Blizzard panels.
    local overlay = CreateFrame("Frame", nil, targetFrame)
    overlay:SetFrameStrata(targetFrame:GetFrameStrata())
    -- Cooldown-manager skins (notably EllesmereUI) can use a large container
    -- frame around a much smaller spell icon.  Anchoring the glow to that
    -- container stretches Button/Autocast glows into a giant rectangle.
    -- Prefer the actual icon region whenever the target exposes one.
    local icon = targetFrame.Icon or targetFrame.icon
    if icon and icon.GetObjectType and icon:GetObjectType() == "Texture" then
        overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    else
        overlay:SetAllPoints(targetFrame)
    end
    overlay:SetFrameLevel(targetFrame:GetFrameLevel() + 10)
    overlay._targetFrame = targetFrame
    overlay._spellKey    = spellKey
    overlay._glowActive  = false
    overlay:Hide()
    return overlay
end

local function AttachCrossToOverlay(overlay)
    if overlay._crossH then return end
    local h = overlay:CreateTexture(nil, "OVERLAY")
    h:SetColorTexture(1, 0, 0, 0.9)
    overlay._crossH = h
    local v = overlay:CreateTexture(nil, "OVERLAY")
    v:SetColorTexture(1, 0, 0, 0.9)
    overlay._crossV = v
end

-- Festering uses a self-contained border effect rather than a library glow.
-- This stays visible on custom Cooldown Manager buttons (including
-- EllesmereUI) where external glow libraries can be clipped or hidden.
local function StartFesteringBorder(overlay, settings)
    if not overlay._festeringBorder then
        local border = {}
        border.top = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        border.bottom = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        border.left = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        border.right = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        border.art = overlay:CreateTexture(nil, "OVERLAY", nil, 6)
        border.sparks = {}
        for i = 1, 8 do
            -- WoW permits draw sublevels only from -8 through 7.
            border.sparks[i] = overlay:CreateTexture(nil, "OVERLAY", nil, 7)
        end
        overlay._festeringBorder = border

        overlay._festeringPulse = overlay:CreateAnimationGroup()
        overlay._festeringPulse:SetLooping("BOUNCE")
        local pulse = overlay._festeringPulse:CreateAnimation("Alpha")
        pulse:SetOrder(1)
        overlay._festeringPulseAlpha = pulse

        -- The Autocast artwork has its own scale animation.  Keeping it on
        -- the texture (rather than the target button) makes it work safely
        -- on Blizzard and custom Cooldown Manager frames.
        border.artPulse = border.art:CreateAnimationGroup()
        border.artPulse:SetLooping("BOUNCE")
        local artScale = border.artPulse:CreateAnimation("Scale")
        artScale:SetOrder(1)
        artScale:SetOrigin("CENTER", 0, 0)
        border.artPulseScale = artScale
    end

    local c = settings.color or { r = 0, g = 0.9, b = 0.2 }
    local alpha = settings.alpha or 1
    local thickness = math.max(2, settings.thickness or 2)
    local pad = math.max(2, math.floor(thickness * 1.5))
    local border = overlay._festeringBorder
    local edges = { border.top, border.bottom, border.left, border.right }
    local style = settings.glowType or "pixel"

    for _, edge in ipairs(edges) do
        edge:SetColorTexture(c.r, c.g, c.b, alpha)
        edge:Hide()
    end
    border.art:Hide()
    border.artPulse:Stop()
    for _, spark in ipairs(border.sparks) do spark:Hide() end
    border.top:ClearAllPoints()
    border.top:SetPoint("TOPLEFT", overlay, "TOPLEFT", -pad, pad)
    border.top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", pad, pad)
    border.top:SetHeight(thickness)
    border.bottom:ClearAllPoints()
    border.bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", -pad, -pad)
    border.bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", pad, -pad)
    border.bottom:SetHeight(thickness)
    border.left:ClearAllPoints()
    border.left:SetPoint("TOPLEFT", overlay, "TOPLEFT", -pad, pad)
    border.left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", -pad, -pad)
    border.left:SetWidth(thickness)
    border.right:ClearAllPoints()
    border.right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", pad, pad)
    border.right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", pad, -pad)
    border.right:SetWidth(thickness)

    -- Classic DK Assist effect: a clear pulsing perimeter drawn directly on
    -- the button.  It is the proven version for Blizzard CDM and EllesmereUI;
    -- the experimental external artwork was too subtle on several UI packs.
    for _, edge in ipairs(edges) do edge:Show() end

    local pulse = overlay._festeringPulseAlpha
    pulse:SetDuration(math.max(0.15, settings.speed or 0.25))
    pulse:SetFromAlpha(math.max(0.25, alpha * 0.35))
    pulse:SetToAlpha(alpha)
    overlay:SetAlpha(alpha)
    overlay._festeringPulse:Stop()
    overlay._festeringPulse:Play()
    overlay._customFesteringActive = true
end

local function StopFesteringBorder(overlay)
    if not overlay._customFesteringActive then return end
    if overlay._festeringPulse then overlay._festeringPulse:Stop() end
    if overlay._festeringBorder then
        local border = overlay._festeringBorder
        -- `sparks` is a table, not a texture.  Hide each layer explicitly;
        -- iterating the whole border table tried to call :Hide() on that
        -- table and could stop the effect after its first use.
        for _, edge in ipairs({ border.top, border.bottom, border.left, border.right }) do
            edge:Hide()
        end
        if border.art then border.art:Hide() end
        if border.artPulse then border.artPulse:Stop() end
        if border.sparks then
            for _, spark in ipairs(border.sparks) do spark:Hide() end
        end
    end
    overlay:SetAlpha(1)
    overlay._customFesteringActive = false
end

local function UpdateCrossAppearance(overlay)
    if not overlay._crossH then return end
    local settings  = DKAssistDB.putrefy
    local thickness = settings.crossThickness or 0.25
    local r = settings.crossColor.r
    local g = settings.crossColor.g
    local b = settings.crossColor.b
    local a = settings.crossAlpha or 0.9

    overlay._crossH:SetColorTexture(r, g, b, a)
    overlay._crossH:ClearAllPoints()
    overlay._crossH:SetPoint("LEFT",  overlay, "LEFT",  0, 0)
    overlay._crossH:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)

    overlay._crossV:SetColorTexture(r, g, b, a)
    overlay._crossV:ClearAllPoints()
    overlay._crossV:SetPoint("TOP",    overlay, "TOP",    0, 0)
    overlay._crossV:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 0)

    -- Cooldown Manager dimensions can be secret values in 12.1.  Performing
    -- arithmetic on GetSize()/OnSizeChanged arguments taints execution and
    -- throws an error in combat.  Convert the user-facing percentage slider
    -- to a safe fixed pixel width instead; the textures remain anchored to
    -- all four sides, so the cross still scales to every button.
    local crossPixels = math.max(2, math.floor(2 + (thickness * 28)))
    overlay._crossH:SetHeight(crossPixels)
    overlay._crossV:SetWidth(crossPixels)
    overlay:SetScript("OnSizeChanged", nil)
end

function addon:CreateFesteringOverlays()
    for _, overlay in pairs(festeringOverlays) do
        StopFesteringBorder(overlay)
        if overlay._glowActive then
            local gt = self:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(festeringOverlays)

    -- Use one target at a time.  When the Cooldown Manager option is on,
    -- Festering is intentionally tracked there instead of on action bars.
    if DKAssistDB.trackCDMFestering then return end

    for spellKey, buttons in pairs(addon.trackedButtons or {}) do
        if spellKey == "festeringScythe" then
            for _, button in ipairs(buttons) do
                festeringOverlays[button] = CreateOverlay(button, spellKey)
            end
        end
    end
end

function addon:CreateSuddenDoomOverlays()
    for _, overlay in pairs(suddenDoomOverlays) do
        if overlay._glowActive then
            local s = GetSuddenDoomOverlaySettings(overlay)
            local gt = s and addon:GetGlowTypeByID(s.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(suddenDoomOverlays)

    if DKAssistDB.trackCDMSuddenDoom then return end

    for spellKey, buttons in pairs(addon.trackedButtons or {}) do
        if spellKey == "deathCoil" or spellKey == "epidemic" then
            for _, button in ipairs(buttons) do
                suddenDoomOverlays[button] = CreateOverlay(button, spellKey)
            end
        end
    end
end

function addon:RegisterCDMSuddenDoomFrame(frame, spellKey)
    if not DKAssistDB.trackCDMSuddenDoom or cdmSuddenDoomOverlays[frame] then return end
    local overlay = CreateOverlay(frame, spellKey)
    cdmSuddenDoomOverlays[frame] = overlay
    if suddenDoomActive then addon:ShowSuddenDoomGlows() end
end

local function StopBloodDnDOverlay(overlay)
    if overlay._glowActive then
        local settings = DKAssistDB and DKAssistDB.bloodDnd
        local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
        if glowType and glowType.stop then pcall(glowType.stop, overlay) end
        overlay._glowActive = false
    end
    overlay:Hide()
end

function addon:StopBloodDnDReminder()
    bloodDnDTestActive = false
    for _, overlay in pairs(cdmBloodDnDOverlays) do
        StopBloodDnDOverlay(overlay)
    end
end

function addon:RegisterCDMBloodDnDAbilityFrame(frame)
    if not (DKAssistDB and DKAssistDB.bloodDnd and DKAssistDB.bloodDnd.enabled) then return end
    if cdmBloodDnDOverlays[frame] then return end
    cdmBloodDnDOverlays[frame] = CreateOverlay(frame, "bloodDnd")
end

function addon:RegisterCDMBloodDnDBuffFrame(frame)
    if frame then bloodDnDBuffFrames[frame] = true end
end

local function DnDMissingSettings()
    return DKAssistDB and DKAssistDB.bloodDndMissing
end

local function StopDnDMissingOverlay(overlay)
    if not overlay then return end
    if overlay._glowActive then
        local settings = DnDMissingSettings()
        local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
        if glowType and glowType.stop then pcall(glowType.stop, overlay) end
        overlay._glowActive = false
    end
    overlay:Hide()
end

local function StartDnDMissingOverlay(overlay)
    if not overlay or not overlay._targetFrame or not overlay._targetFrame:IsVisible() then return false end
    local settings = DnDMissingSettings()
    overlay:Show()
    if not overlay._glowActive then
        local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
        if glowType and glowType.start and pcall(glowType.start, overlay, settings) then
            overlay._glowActive = true
        end
    end
    return true
end

function addon:StopDnDMissingGlow()
    dndMissingGlowActive = false
    for _, overlay in pairs(dndMissingBarOverlays) do StopDnDMissingOverlay(overlay) end
    for _, overlay in pairs(cdmDnDMissingOverlays) do StopDnDMissingOverlay(overlay) end
end

function addon:ShowDnDMissingGlow()
    local settings = DnDMissingSettings()
    if not (settings and settings.enabled) then return end
    dndMissingGlowActive = true
    for _, overlay in pairs(dndMissingBarOverlays) do StartDnDMissingOverlay(overlay) end
    for _, overlay in pairs(cdmDnDMissingOverlays) do StartDnDMissingOverlay(overlay) end
end

function addon:CreateDnDMissingOverlays()
    for _, overlay in pairs(dndMissingBarOverlays) do
        StopDnDMissingOverlay(overlay)
        overlay:SetParent(nil)
    end
    wipe(dndMissingBarOverlays)
    local settings = DnDMissingSettings()
    if not (settings and settings.enabled) then return end
    local buttons = (addon.trackedButtons or {}).deathAndDecay
    if buttons then
        for _, button in ipairs(buttons) do
            dndMissingBarOverlays[button] = CreateOverlay(button, "deathAndDecay")
        end
    end
    if dndMissingGlowActive then addon:ShowDnDMissingGlow() end
end

function addon:RegisterCDMDnDMissingFrame(frame)
    local settings = DnDMissingSettings()
    if not (settings and settings.enabled) or cdmDnDMissingOverlays[frame] then return end
    cdmDnDMissingOverlays[frame] = CreateOverlay(frame, "deathAndDecay")
    if dndMissingGlowActive then addon:ShowDnDMissingGlow() end
end

function addon:ClearCDMDnDMissingFrame(frame)
    local overlay = cdmDnDMissingOverlays[frame]
    if not overlay then return end
    StopDnDMissingOverlay(overlay)
    overlay:SetParent(nil)
    cdmDnDMissingOverlays[frame] = nil
end

function addon:RefreshDnDMissingGlows()
    if dndMissingGlowActive then
        addon:StopDnDMissingGlow()
        addon:ShowDnDMissingGlow()
    end
end

function addon:TestDnDMissingGlow()
    local shown = 0
    for _, overlays in ipairs({ dndMissingBarOverlays, cdmDnDMissingOverlays }) do
        for _, overlay in pairs(overlays) do
            if StartDnDMissingOverlay(overlay) then shown = shown + 1 end
        end
    end
    if shown == 0 then
        print("|cffcc0000DK Assist:|r Put Death and Decay on an action bar, or add it and its buff to the Cooldown Manager, then use Rescan Bars.")
    end
    return shown
end

function addon:RefreshBloodDnDReminder()
    local settings = DKAssistDB and DKAssistDB.bloodDnd
    local crimsonScourgeActive = false
    -- Crimson Scourge immediately resets Death and Decay. Only test whether
    -- Blizzard returned the aura; its other fields may be secret in 12.1.
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, CRIMSON_SCOURGE_AURA_ID)
        crimsonScourgeActive = ok and aura ~= nil
    end
    if crimsonScourgeActive then bloodDnDReady = true end
    local active = bloodDnDTestActive or (settings and settings.enabled and addon:IsBloodSpec()
        and InCombatLockdown() and bloodDnDReady)
    for _, overlay in pairs(cdmBloodDnDOverlays) do
        local target = overlay._targetFrame
        if active and target and target:IsVisible() then
            overlay:Show()
            if not overlay._glowActive then
                local glowType = addon:GetGlowTypeByID(settings.glowType)
                if glowType and glowType.start and pcall(glowType.start, overlay, settings) then
                    overlay._glowActive = true
                end
            end
        else
            StopBloodDnDOverlay(overlay)
        end
    end
end

function addon:TestBloodDnDReminder()
    local settings = DKAssistDB and DKAssistDB.bloodDnd
    bloodDnDTestActive = true
    local shown = 0
    for _, overlay in pairs(cdmBloodDnDOverlays) do
        if overlay._targetFrame and overlay._targetFrame:IsVisible() then
            overlay:Show()
            local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
            if glowType and glowType.start then pcall(glowType.start, overlay, settings) end
            overlay._glowActive = true
            shown = shown + 1
        end
    end
    if shown == 0 then
        bloodDnDTestActive = false
        print("|cffcc0000DK Assist:|r Add Death and Decay and its buff to the Cooldown Manager, then use Rescan Bars.")
    end
    return shown
end

local function StopBloodBoneOverlay(overlay)
    if overlay._glowActive then
        local settings = DKAssistDB and DKAssistDB.bloodBone
        local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
        if glowType and glowType.stop then pcall(glowType.stop, overlay) end
        overlay._glowActive = false
    end
    overlay:Hide()
end

function addon:RegisterCDMBloodBoneAbilityFrame(frame)
    if not (DKAssistDB and DKAssistDB.bloodBone and DKAssistDB.bloodBone.enabled) then return end
    if cdmBloodBoneOverlays[frame] then return end
    cdmBloodBoneOverlays[frame] = CreateOverlay(frame, "bloodBone")
end

function addon:StopBloodBoneReminder()
    for _, overlay in pairs(cdmBloodBoneOverlays) do StopBloodBoneOverlay(overlay) end
end

function addon:RefreshBloodBoneReminder(testing)
    -- Midnight protects CDM frame visibility. The replacement reminder in
    -- BoneShieldReminder.lua never reads protected frame state.
    for _, overlay in pairs(cdmBloodBoneOverlays) do StopBloodBoneOverlay(overlay) end
    if addon.RefreshBoneShieldReminder then addon:RefreshBoneShieldReminder() end
end

function addon:TestBloodBoneReminder()
    local shown = 0
    local settings = DKAssistDB and DKAssistDB.bloodBone
    for _, overlay in pairs(cdmBloodBoneOverlays) do
        if overlay._targetFrame and overlay._targetFrame:IsVisible() then
            overlay:Show()
            local glowType = settings and addon:GetGlowTypeByID(settings.glowType)
            if glowType and glowType.start then pcall(glowType.start, overlay, settings) end
            overlay._glowActive = true
            shown = shown + 1
        end
    end
    if shown == 0 then
        print("|cffcc0000DK Assist:|r Add Marrowrend or Death's Caress to the Cooldown Manager, then use Rescan Bars.")
    end
    return shown
end

local bloodDnDWatcher = CreateFrame("Frame")
local bloodDnDElapsed = 0
local dndMissingFor = 0

local function IsPlayerInsideDeathAndDecay()
    -- Cooldown Manager skins can keep the tracked-buff frame visible even
    -- when the aura is inactive.  Checking only :IsShown() therefore never
    -- triggers the warning in layouts such as EllesmereUI.  Aura presence is
    -- safe here: no duration, stack count, or other secret numeric value is
    -- read or compared.
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, addon.SPELLS.DEATH_AND_DECAY_BUFF.id)
        -- A nil result is ambiguous in 12.1 restricted combat: it can mean
        -- either "missing" or "secret aura not readable". Only trust a
        -- positive result here; otherwise continue to the secure CDM frame.
        if ok and aura ~= nil then return true end
    end

    -- Ellesmere replaces an inactive tracked buff with its own persistent
    -- placeholder frame, then swaps the real Blizzard aura frame back into
    -- the same buff bar when it becomes active.  Reading the bar's clean,
    -- out-of-combat identity cache plus that placeholder marker gives us the
    -- live state without touching secret aura values.
    local euiCDM = EllesmereUI and EllesmereUI._ModuleNS
        and EllesmereUI._ModuleNS["EllesmereUICooldownManager"]
    if euiCDM and euiCDM.cdmBarIcons and euiCDM._ecmeFC then
        local foundTrackedSlot = false
        for barKey, icons in pairs(euiCDM.cdmBarIcons) do
            local barData = euiCDM.GetBarData and euiCDM.GetBarData(barKey)
            if barData and barData.barType == "buffs" then
                for _, frame in ipairs(icons) do
                    local fc = euiCDM._ecmeFC[frame]
                    local spellID = (fc and fc.spellID) or frame._phSpellID
                    if spellID == addon.SPELLS.DEATH_AND_DECAY_BUFF.id
                        or spellID == addon.SPELLS.DEATH_AND_DECAY.id then
                        foundTrackedSlot = true
                        -- Membership in Ellesmere's live icon list is already
                        -- the active-state signal. The real Blizzard frame can
                        -- report IsShown()==false briefly because its original
                        -- viewer is parked while Ellesmere renders it elsewhere.
                        if not frame._isPlaceholderFrame then
                            return true
                        end
                    end
                end
            end
        end
        if foundTrackedSlot then return false end
    end

    -- In 12.1 this aura can be secret-flagged during combat, making the direct
    -- lookup return nil even while it is active. Blizzard's own Tracked Buff
    -- frame is still driven by the secure aura engine, so its shown state is
    -- the reliable fallback. Do not use Ellesmere's persistent proxy icons.
    for frame in pairs(bloodDnDBuffFrames) do
        if frame and frame.IsShown and frame:IsShown() then return true end
    end
    return false
end

bloodDnDWatcher:SetScript("OnUpdate", function(_, elapsed)
    bloodDnDElapsed = bloodDnDElapsed + elapsed
    if bloodDnDElapsed < 0.10 then return end
    local sincePoll = bloodDnDElapsed
    bloodDnDElapsed = 0
    addon:RefreshBloodDnDReminder()
    addon:RefreshBloodBoneReminder()
    local settings = DnDMissingSettings()
    -- The combat-log aura edge is public in restricted combat, unlike the
    -- direct 12.1 aura query. Only glow during an active Blood DnD window.
    local missing = settings and settings.enabled and addon:IsBloodSpec()
        and InCombatLockdown() and dndActive and not dndAuraKnownInside or false
    if missing then dndMissingFor = dndMissingFor + sincePoll else dndMissingFor = 0 end
    if missing and dndMissingFor >= 0.5 then
        addon:ShowDnDMissingGlow()
    elseif dndMissingGlowActive then
        addon:StopDnDMissingGlow()
    end
end)

function addon:ClearCDMSuddenDoomOverlays()
    for _, overlay in pairs(cdmSuddenDoomOverlays) do
        if overlay._glowActive then
            local s = GetSuddenDoomOverlaySettings(overlay)
            local gt = s and addon:GetGlowTypeByID(s.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(cdmSuddenDoomOverlays)
end

-- Called by CDMHook.lua after Blizzard refreshes a specific Cooldown Manager
-- item.  This avoids walking arbitrary UI frames (which taints in 12.1).
function addon:RegisterCDMFesteringFrame(frame)
    if not DKAssistDB.trackCDMFestering or cdmFesteringOverlays[frame] then return end
    local overlay = CreateOverlay(frame, "festeringScythe")
    cdmFesteringOverlays[frame] = overlay
    addon:RefreshFesteringGlows()
end

function addon:CreatePutrefyOverlays()
    for _, overlay in pairs(putrefyOverlays) do
        addon:_StopPutrefyOverlay(overlay)
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(putrefyOverlays)

    -- Putrefy is Unholy-only.  Spec changes can leave old Cooldown Manager
    -- frames alive, so never recreate their overlays while playing Blood.
    if not addon:IsUnholySpec() then return end

    -- When Cooldown Manager tracking is enabled, Putrefy is intentionally a
    -- CDM-only indicator.  Do not also attach a cross to normal action-bar
    -- buttons; those buttons can sit behind unrelated UI windows and make
    -- the warning look like it belongs to another addon.
    if DKAssistDB.trackCDMPutrefy then return end

    for spellKey, buttons in pairs(addon.trackedButtons or {}) do
        if spellKey == "putrefy" then
            for _, button in ipairs(buttons) do
                local overlay = CreateOverlay(button, "putrefy")
                AttachCrossToOverlay(overlay)
                putrefyOverlays[button] = overlay
            end
        end
    end
end

-- Called by CDMHook.lua after Blizzard refreshes a specific CDM item. This
-- never inspects textures or enumerates arbitrary UI frames.
function addon:RegisterCDMPutrefyFrame(frame)
    if not addon:IsUnholySpec() or not DKAssistDB.trackCDMPutrefy or cdmPutrefyOverlays[frame] then return end
    local overlay = CreateOverlay(frame, "putrefy")
    AttachCrossToOverlay(overlay)
    cdmPutrefyOverlays[frame] = overlay
    if putrefyWarningActive then addon:RefreshPutrefyWarnings() end
end

-- 12.1 can contain thousands of UI frames. Keep discovery bounded so a scan
-- cannot monopolize a rendered frame after login, zoning, or a spec change.
local cdmScanRunning = false
local cdmDisabledFor121 = false

function addon:CreateCDMOverlays()
    for _, overlay in pairs(cdmFesteringOverlays) do
        if overlay._glowActive then
            local gt = self:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(cdmFesteringOverlays)

    for _, overlay in pairs(cdmPutrefyOverlays) do
        addon:_StopPutrefyOverlay(overlay)
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(cdmPutrefyOverlays)

    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return end

    local scStr  = "3997563"
    local fsStr  = "879926"
    local putStr = "7439191"

    local frame = EnumerateFrames()
    while frame do
        if frame.Icon and type(frame.Icon) == "table" and frame.Icon.GetTexture then
            local ok, matched = pcall(function()
                local tex = frame.Icon:GetTexture()
                if tex then
                    local texStr = tostring(tex)
                    if DKAssistDB.trackCDMFestering and (texStr == scStr or texStr == fsStr) then
                        return "festering"
                    elseif DKAssistDB.trackCDMPutrefy and texStr == putStr then
                        return "putrefy"
                    end
                end
                return nil
            end)
            if ok and matched == "festering" then
                local overlay = CreateFrame("Frame", nil, frame)
                overlay:SetFrameStrata("HIGH")
                overlay:SetAllPoints(frame)
                overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                overlay._targetFrame = frame
                overlay._glowActive  = false
                overlay:Hide()
                cdmFesteringOverlays[frame] = overlay
            elseif ok and matched == "putrefy" then
                local overlay = CreateFrame("Frame", nil, frame)
                overlay:SetFrameStrata("HIGH")
                overlay:SetAllPoints(frame)
                overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                overlay._targetFrame = frame
                overlay._glowActive  = false
                AttachCrossToOverlay(overlay)
                overlay:Hide()
                cdmPutrefyOverlays[frame] = overlay
            end
        end
        frame = EnumerateFrames(frame)
    end
end

-- Additive CDM overlay creation — only creates overlays for frames not already tracked
-- Called by ScanCDMSafe() to avoid disrupting active glows
function addon:CreateCDMOverlaysAdditive()
    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return 0 end

    local scStr  = "3997563"
    local fsStr  = "879926"
    local putStr = "7439191"
    local added  = 0

    local frame = EnumerateFrames()
    while frame do
        if frame.Icon and type(frame.Icon) == "table" and frame.Icon.GetTexture then
            -- Skip frames already tracked
            if not cdmFesteringOverlays[frame] and not cdmPutrefyOverlays[frame] then
                local ok, matched = pcall(function()
                    local tex = frame.Icon:GetTexture()
                    if tex then
                        local texStr = tostring(tex)
                        if DKAssistDB.trackCDMFestering and (texStr == scStr or texStr == fsStr) then
                            return "festering"
                        elseif DKAssistDB.trackCDMPutrefy and texStr == putStr then
                            return "putrefy"
                        end
                    end
                    return nil
                end)
                if ok and matched == "festering" then
                    local overlay = CreateFrame("Frame", nil, frame)
                    overlay:SetFrameStrata("HIGH")
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                    overlay._targetFrame = frame
                    overlay._glowActive  = false
                    overlay:Hide()
                    cdmFesteringOverlays[frame] = overlay
                    added = added + 1
                elseif ok and matched == "putrefy" then
                    local overlay = CreateFrame("Frame", nil, frame)
                    overlay:SetFrameStrata("HIGH")
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                    overlay._targetFrame = frame
                    overlay._glowActive  = false
                    AttachCrossToOverlay(overlay)
                    overlay:Hide()
                    cdmPutrefyOverlays[frame] = overlay
                    added = added + 1
                end
            end
        end
        frame = EnumerateFrames(frame)
    end

    return added
end

-- Override the legacy synchronous frame walk above.  The scan is deliberately
-- incremental: 40 frames per game tick keeps this compatible with the larger
-- 12.1 UI frame tree without causing a client-wide hitch.
local function StartSafeCDMScan(reset)
    -- CDM items are registered by CDMHook.lua as Blizzard refreshes them.
    -- Do not enumerate UI frames or read protected texture identifiers.
    -- Keep the legacy code below syntactically isolated while the supported
    -- CDM hook path in CDMHook.lua performs registration.
    if true then return 0 end

    -- Legacy implementation retained below for future API support.
    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return 0 end
    if cdmScanRunning then return 0 end

    if reset then
        for _, overlay in pairs(cdmFesteringOverlays) do
            if overlay._glowActive then
                local gt = addon:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
                if gt and gt.stop then pcall(gt.stop, overlay) end
            end
            overlay:Hide(); overlay:SetParent(nil)
        end
        for _, overlay in pairs(cdmPutrefyOverlays) do
            addon:_StopPutrefyOverlay(overlay); overlay:SetParent(nil)
        end
        wipe(cdmFesteringOverlays); wipe(cdmPutrefyOverlays)
    end

    cdmScanRunning = true
    local current, added = nil, 0
    local function ScanBatch()
        for _ = 1, 40 do
            current = EnumerateFrames(current)
            if not current then
                cdmScanRunning = false
                addon._lastCDMScanAdded = added
                return
            end
            if not cdmFesteringOverlays[current] and not cdmPutrefyOverlays[current]
                and current.Icon and type(current.Icon) == "table" and current.Icon.GetTexture then
                local ok, texture = pcall(current.Icon.GetTexture, current.Icon)
                local id = ok and texture and tostring(texture)
                local kind = nil
                if DKAssistDB.trackCDMFestering and (id == "3997563" or id == "879926") then kind = "festering" end
                if DKAssistDB.trackCDMPutrefy and id == "7439191" then kind = "putrefy" end
                if kind then
                    local overlay = CreateFrame("Frame", nil, current)
                    overlay:SetFrameStrata("HIGH"); overlay:SetAllPoints(current)
                    overlay:SetFrameLevel(current:GetFrameLevel() + 10)
                    overlay._targetFrame, overlay._glowActive = current, false
                    overlay:Hide()
                    if kind == "festering" then
                        cdmFesteringOverlays[current] = overlay
                    else
                        AttachCrossToOverlay(overlay)
                        cdmPutrefyOverlays[current] = overlay
                    end
                    added = added + 1
                end
            end
        end
        C_Timer.After(0, ScanBatch)
    end
    C_Timer.After(0, ScanBatch)
    return 0
end

-- Keep the public rescan functions used by the settings button, slash command,
-- and retry loop. CDMHook owns discovery through Blizzard's item API.
function addon:CreateCDMOverlays()
    if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    return 0
end

function addon:CreateCDMOverlaysAdditive()
    if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    return 0
end

local FESTERING_BUFF_DURATION = 25
local festeringTimer      = nil
local festeringGraceTimer = nil
local festeringExpiredTimer = nil
local festeringGlowActive = false
local festeringSuppressed = false
local festeringReasons = { expiry = false, ghoul = false }

local function HideFesteringGlow()
    festeringGlowActive = false
    local function hideOverlay(overlay)
        StopFesteringBorder(overlay)
        if overlay._glowActive then
            local gt = addon:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
            overlay._glowActive = false
        end
        overlay:Hide()
    end
    for _, overlay in pairs(festeringOverlays)    do hideOverlay(overlay) end
    for _, overlay in pairs(cdmFesteringOverlays) do hideOverlay(overlay) end
end

local function CancelFesteringGrace()
    if festeringGraceTimer then
        festeringGraceTimer:Cancel()
        festeringGraceTimer = nil
    end
end

local function StopFesteringGlow()
    if festeringTimer then
        festeringTimer:Cancel()
        festeringTimer = nil
    end
    if festeringExpiredTimer then
        festeringExpiredTimer:Cancel()
        festeringExpiredTimer = nil
    end
    CancelFesteringGrace()
    festeringSuppressed = false
    festeringReasons.expiry = false
    festeringReasons.ghoul = false
    HideFesteringGlow()
    if textAlertTimers.festeringScythe then
        textAlertTimers.festeringScythe:Cancel()
        textAlertTimers.festeringScythe = nil
    end
    addon:SetTextAlertVisible("festeringScythe", false)
    SetFesteringGhoulTextAlert(false)
end

local function ShowFesteringGlow()
    festeringGlowActive = true
    local settings = DKAssistDB.spells.festeringScythe
    if not settings.enabled then return 0 end
    local applied = 0

    local function applyGlow(overlay)
        local target = overlay._targetFrame
        -- Never show an overlay for a hidden/recycled UI frame.  In 12.1 the
        -- Cooldown Manager can keep its item frames alive while another full
        -- screen UI (such as the world map) is open.
        if target and target:IsVisible() then
            overlay:Show()
            if not overlay._glowActive then
                -- Original DK Assist effects: Pixel Glow, Autocast Shine,
                -- Button Glow and Proc Border from LibCustomGlow.
                local glowType = addon:GetGlowTypeByID(settings.glowType)
                if glowType and glowType.start then
                    local ok = pcall(glowType.start, overlay, settings)
                    if ok then overlay._glowActive = true end
                end
            end
            applied = applied + 1
        end
    end

    if DKAssistDB.trackCDMFestering then
        for _, overlay in pairs(cdmFesteringOverlays) do applyGlow(overlay) end
    else
        for _, overlay in pairs(festeringOverlays) do applyGlow(overlay) end
    end
    return applied
end

-- Festering can have two independent glow reasons.  Do not let one clear the
-- other (for example, casting Scythe must not hide the Lesser Ghoul warning).
local function ApplyFesteringGlow()
    if festeringReasons.expiry or festeringReasons.ghoul then
        ShowFesteringGlow()
    else
        HideFesteringGlow()
    end
end

local function SetFesteringReason(reason, value)
    value = value and true or false
    if festeringReasons[reason] == value then return end
    festeringReasons[reason] = value
    ApplyFesteringGlow()
end

-- Called by the options dropdown.  If a Festering test or warning is already
-- visible, redraw it immediately with the newly selected direct-overlay style.
function addon:RefreshFesteringGlowStyle()
    if not festeringGlowActive then return end
    for _, overlay in pairs(festeringOverlays) do
        StopFesteringBorder(overlay)
        overlay._glowActive = false
    end
    for _, overlay in pairs(cdmFesteringOverlays) do
        StopFesteringBorder(overlay)
        overlay._glowActive = false
    end
    ShowFesteringGlow()
end

local function StartFesteringTimer()
    if festeringTimer then
        festeringTimer:Cancel()
        festeringTimer = nil
    end
    if festeringExpiredTimer then
        festeringExpiredTimer:Cancel()
        festeringExpiredTimer = nil
    end
    CancelFesteringGrace()
    SetFesteringReason("expiry", false)

    local settings = DKAssistDB.spells.festeringScythe
    local timing = settings.glowTiming or 5
    local delay  = math.max(1, FESTERING_BUFF_DURATION - timing)
    local textTiming = math.min(24, math.max(1, (settings.textAlert and settings.textAlert.secondsLeft) or 5))
    local textDelay = math.max(1, FESTERING_BUFF_DURATION - textTiming)
    festeringTextEndTime = GetTime() + FESTERING_BUFF_DURATION
    festeringSuppressed = true
    if textAlertTimers.festeringScythe then textAlertTimers.festeringScythe:Cancel() end
    addon:SetTextAlertVisible("festeringScythe", false)
    textAlertTimers.festeringScythe = C_Timer.NewTimer(textDelay, function()
        textAlertTimers.festeringScythe = nil
        if InCombatLockdown() then addon:SetTextAlertVisible("festeringScythe", true) end
    end)
    if not settings.enabled then return end
    festeringTimer = C_Timer.NewTimer(delay, function()
        festeringTimer = nil
        festeringSuppressed = false
        -- The buff keeps expiring out of combat, but the visual reminder is
        -- deliberately shown only during combat.
        if InCombatLockdown() then SetFesteringReason("expiry", true) end
    end)
end

function addon:OnFesteringScytheCast()
    -- The 25-second Festering Scythe buff has been refreshed.  Hide the
    -- warning until it is close to expiring again.
    StartFesteringTimer()
end

function addon:OnFesteringStrikeCast()
    -- The transformed button may be rebuilt by the Cooldown Manager. Refresh
    -- the registration, but do not glow it immediately: Festering Scythe is
    -- an expiry/missing-buff reminder, not a conversion-ready reminder.
    C_Timer.After(0.05, function()
        if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    end)
end

local function OnFesteringCombatEnd()
    CancelFesteringGrace()
    SetFesteringReason("ghoul", false)
    SetFesteringReason("expiry", false)
    addon:SetTextAlertVisible("festeringScythe", false)
    SetFesteringGhoulTextAlert(false)
end

local function OnFesteringCombatStart()
    if festeringSuppressed then return end
    CancelFesteringGrace()
    local settings = DKAssistDB.spells.festeringScythe
    if not settings.enabled or settings.combatGlow == false then return end

    local grace = settings.combatGrace or 0
    if grace <= 0 then
        SetFesteringReason("expiry", true)
        return
    end
    festeringGraceTimer = C_Timer.NewTimer(grace, function()
        festeringGraceTimer = nil
        if not festeringSuppressed and InCombatLockdown() then
            SetFesteringReason("expiry", true)
        end
    end)
end

function addon:CancelFesteringCombatGlow()
    CancelFesteringGrace()
end

-- Lesser Ghoul aura stacks are secret in 12.1, so watch the visibility of its
-- tracked Cooldown Manager icon instead of reading the aura directly.
local lesserGhoulFrame = nil

function addon:RegisterCDMLesserGhoulFrame(frame)
    lesserGhoulFrame = frame
end

local ghoulWatcher = CreateFrame("Frame")
local ghoulElapsed = 0
ghoulWatcher:SetScript("OnUpdate", function(_, elapsed)
    ghoulElapsed = ghoulElapsed + elapsed
    if ghoulElapsed < 0.10 then return end
    ghoulElapsed = 0

    local settings = DKAssistDB and DKAssistDB.spells and DKAssistDB.spells.festeringScythe
    local glowEnabled = settings and settings.enabled and settings.lesserGhoulGlow
    local textEnabled = settings and settings.textAlert and settings.textAlert.enabled
        and settings.textAlert.ghoulMissingWarning
    if not settings or (not glowEnabled and not textEnabled)
        or not lesserGhoulFrame or not InCombatLockdown() then
        SetFesteringReason("ghoul", false)
        SetFesteringGhoulTextAlert(false)
        return
    end

    local missing = not lesserGhoulFrame:IsShown()
    SetFesteringReason("ghoul", glowEnabled and missing)
    SetFesteringGhoulTextAlert(textEnabled and missing)
end)

function addon:RefreshFesteringGlows()
    if festeringGlowActive then
        HideFesteringGlow()
        ShowFesteringGlow()
    end
end

local putrefyWarningTimer  = nil
local putrefyDurationTimer = nil
putrefyWarningActive = false
local darkTransformationEndsAt = 0
local darkTransformationReadyAt = 0
local DARK_TRANSFORMATION_BASE_DURATION = 15
local DARK_TRANSFORMATION_COOLDOWN = 45

function addon:_StopPutrefyOverlay(overlay)
    local settings = DKAssistDB.putrefy
    if overlay._glowActive then
        if settings.warningType == "glow" and LCG and LCG.PixelGlow_Stop then
            pcall(LCG.PixelGlow_Stop, overlay, "DKAssistPutrefy")
        end
        overlay._glowActive = false
    end
    if overlay._crossH then
        overlay._crossH:Hide()
        overlay._crossV:Hide()
    end
    overlay:Hide()
end

local function StopPutrefyWarning()
    putrefyWarningActive = false
    if putrefyWarningTimer then
        putrefyWarningTimer:Cancel()
        putrefyWarningTimer = nil
    end
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end
    for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
    for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end
end

local function ShowPutrefyWarning(duration)
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end

    if not addon:IsUnholySpec() then
        StopPutrefyWarning()
        return
    end
    putrefyWarningActive = true
    local settings = DKAssistDB.putrefy
    if not settings.enabled then return end

    local function applyWarning(overlay)
        local target = overlay._targetFrame
        -- CDM frames are reused by Blizzard UI.  Do not force an overlay to
        -- show when its target is hidden; that can leave the red cross over
        -- unrelated full-screen frames such as the world map.
        if target and target:IsVisible() then
            overlay:Show()
            if settings.warningType == "cross" then
                UpdateCrossAppearance(overlay)
                if overlay._crossH then overlay._crossH:Show() end
                if overlay._crossV then overlay._crossV:Show() end
                overlay._glowActive = true
            elseif settings.warningType == "glow" then
                if not overlay._glowActive then
                    if LCG and LCG.PixelGlow_Start then
                        LCG.PixelGlow_Start(overlay,
                            {settings.glowColor.r, settings.glowColor.g, settings.glowColor.b, settings.glowAlpha},
                            settings.glowLines or 8, settings.glowSpeed or 0.25, nil,
                            settings.glowThickness or 3, 0, 0, false, "DKAssistPutrefy")
                        overlay._glowActive = true
                    end
                end
            end
        end
    end

    if not DKAssistDB.trackCDMPutrefy then
        for _, overlay in pairs(putrefyOverlays) do applyWarning(overlay) end
    else
        for _, overlay in pairs(cdmPutrefyOverlays) do applyWarning(overlay) end
    end

    if duration then
        putrefyDurationTimer = C_Timer.NewTimer(math.max(0.1, duration), function()
            putrefyDurationTimer = nil
            StopPutrefyWarning()
        end)
    end
end

function addon:ShowPutrefyHoldWarning()
    if addon:IsUnholySpec() and DKAssistDB and DKAssistDB.putrefy and DKAssistDB.putrefy.enabled then
        ShowPutrefyWarning()
    end
end

function addon:OnDarkTransformationCast()
    if putrefyWarningTimer then
        putrefyWarningTimer:Cancel()
        putrefyWarningTimer = nil
    end
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end
    putrefyWarningActive = false
    for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
    for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end

    darkTransformationEndsAt = GetTime() + DARK_TRANSFORMATION_BASE_DURATION
    addon:RefreshDarkTransformationWindow()
end

function addon:RefreshDarkTransformationWindow()
    if putrefyWarningTimer then putrefyWarningTimer:Cancel(); putrefyWarningTimer = nil end
    if putrefyDurationTimer then putrefyDurationTimer:Cancel(); putrefyDurationTimer = nil end

    local now = GetTime()
    local activeRemaining = darkTransformationEndsAt - now
    if activeRemaining <= 0 then
        ShowPutrefyWarning()
        return
    end

    putrefyWarningTimer = C_Timer.NewTimer(activeRemaining, function()
        putrefyWarningTimer = nil
        ShowPutrefyWarning()
    end)
end

function addon:OnDarkTransformationExtended()
    if darkTransformationEndsAt <= GetTime() then return end
    darkTransformationEndsAt = darkTransformationEndsAt + 1
    addon:RefreshDarkTransformationWindow()
end

function addon:RefreshPutrefyWarnings()
    if putrefyWarningActive then
        for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
        for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end
        ShowPutrefyWarning()
    end
end

function addon:TestFesteringGlow()
    local count = ShowFesteringGlow()
    if count == 0 then
        local target = DKAssistDB.trackCDMFestering and "Cooldown Manager" or "action bars"
        print("|cffcc0000DK Assist:|r No visible Festering Scythe button found on " .. target .. ". Reload UI, then use Rescan Bars.")
    else
        print("|cffcc0000DK Assist:|r Festering Scythe test glow applied to " .. count .. " button(s).")
    end
    return count
end

-- Sudden Doom is an aura, so track the aura itself instead of polling Death
-- Coil's Runic Power cost.  The latter may be secret in modern client builds.
local SUDDEN_DOOM_AURA_ID = 81340
function addon:IsSuddenDoomActive()
    -- The proc aura can be hidden by Blizzard's restricted-aura system in
    -- combat.  Prefer it when visible, then safely fall back to the actual
    -- Death Coil Runic Power cost, which is the live gameplay effect.
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, SUDDEN_DOOM_AURA_ID)
        if ok and aura ~= nil then return true end
    end
    local ok, active = pcall(function()
        -- Include every Sudden Doom spender/variant.  The proc is represented
        -- by a Runic Power cost of 15 or less, not necessarily exactly 15.
        for _, spellID in ipairs({ 47541, 1242174, 207317, 383269 }) do
            local costs = C_Spell.GetSpellPowerCost(spellID)
            if costs then
                for _, cost in ipairs(costs) do
                    if cost.type == Enum.PowerType.RunicPower and cost.cost <= 15 then return true end
                end
            end
        end
        return false
    end)
    return ok and active or false
end

function addon:StopSuddenDoomGlows()
    suddenDoomActive = false
    local overlays = DKAssistDB.trackCDMSuddenDoom and cdmSuddenDoomOverlays or suddenDoomOverlays
    for _, overlay in pairs(overlays) do
        if overlay._glowActive then
            local s = GetSuddenDoomOverlaySettings(overlay)
            local gt = s and addon:GetGlowTypeByID(s.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
            overlay._glowActive = false
        end
        overlay:Hide()
    end
    -- These two were legacy per-spender text alerts.  Sudden Doom now has
    -- one dedicated alert, so always hide the legacy frames to avoid three
    -- messages being displayed for the same proc.
    addon:SetTextAlertVisible("deathCoil", false)
    addon:SetTextAlertVisible("epidemic", false)
    addon:SetTextAlertVisible("suddenDoom", false)
end

function addon:ShowSuddenDoomGlows()
    suddenDoomActive = true
    local overlays = DKAssistDB.trackCDMSuddenDoom and cdmSuddenDoomOverlays or suddenDoomOverlays
    for _, overlay in pairs(overlays) do
        local target = overlay._targetFrame
        local s = GetSuddenDoomOverlaySettings(overlay)
        if target and target:IsVisible() and s and s.enabled then
            overlay:Show()
            if not overlay._glowActive then
                local gt = addon:GetGlowTypeByID(s.glowType)
                if gt and gt.start then
                    local ok = pcall(gt.start, overlay, s)
                    if ok then overlay._glowActive = true end
                end
            end
        end
    end
    -- A Sudden Doom proc gets one text alert only.  Death Coil and Epidemic
    -- remain separate glow configurations, not separate text messages.
    addon:SetTextAlertVisible("deathCoil", false)
    addon:SetTextAlertVisible("epidemic", false)
    addon:SetTextAlertVisible("suddenDoom", true)
end

function addon:RefreshSuddenDoomGlows()
    if suddenDoomActive then
        addon:StopSuddenDoomGlows()
        if addon:IsSuddenDoomActive() then addon:ShowSuddenDoomGlows() end
    end
end

function addon:TestSuddenDoomGlow(spellKey)
    local shown = 0
    local overlays = DKAssistDB.trackCDMSuddenDoom and cdmSuddenDoomOverlays or suddenDoomOverlays
    for _, overlay in pairs(overlays) do
        if overlay._spellKey == spellKey and overlay._targetFrame and overlay._targetFrame:IsVisible() then
            local s = GetSuddenDoomOverlaySettings(overlay)
            overlay:Show()
            local gt = addon:GetGlowTypeByID(s.glowType)
            if gt and gt.start then pcall(gt.start, overlay, s) end
            overlay._glowActive = true
            shown = shown + 1
        end
    end
    return shown
end

function addon:TestPutrefyWarning()
    ShowPutrefyWarning()
end

function addon:StopAll()
    StopFesteringGlow()
    StopPutrefyWarning()
    addon:StopSuddenDoomGlows()
    addon:StopBloodDnDReminder()
    addon:StopDnDMissingGlow()
    addon:StopBloodBoneReminder()
end

-- -------------------------------------------------------
-- Death and Decay Tracker
-- -------------------------------------------------------
local DND_DURATION  = 10
-- -------------------------------------------------------
-- Unholy: Dark Transformation -> Soul Reaper -> Blightfall
-- -------------------------------------------------------
local BLIGHTFALL_GRACE = 5
local BLIGHTFALL_TEST_READY = 2
local blightFrame
local blightIconFrame
local blightState
local blightTest = false
local blightLastCue
local blightVoiceID

local function BlightfallSettings()
    return DKAssistDB and DKAssistDB.blightfallChain
end

local function BlightfallFallbackSound(now)
    if now then
        PlaySound(SOUNDKIT.READY_CHECK, "Master")
    else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "Master")
    end
end

local function BlightfallSpeak(text, now)
    local s = BlightfallSettings()
    if not s or not s.soundEnabled then return end
    if C_VoiceChat and C_VoiceChat.GetTtsVoices and C_VoiceChat.SpeakText then
        if not blightVoiceID then
            local voices = C_VoiceChat.GetTtsVoices()
            blightVoiceID = voices and voices[1] and voices[1].voiceID
        end
        if blightVoiceID then
            if C_VoiceChat.StopSpeakingText then pcall(C_VoiceChat.StopSpeakingText) end
            C_Timer.After(0, function()
                local volume = math.max(0, math.min(100, s.soundVolume or 100))
                local ok = pcall(C_VoiceChat.SpeakText, blightVoiceID, text, 0, volume, true)
                if not ok then BlightfallFallbackSound(now) end
            end)
            return
        end
    end
    BlightfallFallbackSound(now)
end

local function BlightfallStepInfo(step)
    if step == "BLIGHTFALL" then
        return addon.SPELLS.BLIGHTFALL.id, "Blightfall", addon.SPELLS.BLIGHTFALL.icon
    end
    return addon.SPELLS.SOUL_REAPER.id, "Soul Reaper", 636333
end

local function StopBlightfallReadyGlow(frame)
    if not (frame and frame._glowActive) then return end
    for _, glowType in ipairs(addon.GLOW_TYPES or {}) do
        if glowType.stop then pcall(glowType.stop, frame) end
    end
    frame._glowActive = false
end

local function StartBlightfallReadyGlow(frame)
    if not frame then return end
    local settings = BlightfallSettings()
    local glowType = settings and addon:GetGlowTypeByID(settings.glowType or "button")
    if not (glowType and glowType.start) then return end
    StopBlightfallReadyGlow(frame)
    if pcall(glowType.start, frame, settings) then frame._glowActive = true end
end

local function UpdateBlightfallIcon(self)
    if not blightState then StopBlightfallReadyGlow(self); self:Hide(); return end
    local raw = blightState.delay - (GetTime() - blightState.started)
    if blightTest and raw < -BLIGHTFALL_TEST_READY then
        local s = BlightfallSettings()
        local nextStep = blightState.step == "SOUL_REAPER" and "BLIGHTFALL" or "SOUL_REAPER"
        local delay = nextStep == "SOUL_REAPER" and s.soulReaperDelay or s.blightfallDelay
        blightState = { step = nextStep, delay = delay, started = GetTime() }
        blightLastCue = nil
        raw = delay
    elseif raw < -BLIGHTFALL_GRACE then
        blightState = nil
        StopBlightfallReadyGlow(self)
        self:Hide()
        if blightFrame then StopBlightfallReadyGlow(blightFrame.marker.glowTarget); blightFrame:Hide() end
        return
    end
    local _, label, iconID = BlightfallStepInfo(blightState.step)
    self.icon:SetTexture(iconID)
    if raw <= 0 then
        self.time:SetText("NOW")
        self.label:SetText(label)
        if not self._glowActive then StartBlightfallReadyGlow(self) end
    else
        self.time:SetText(string.format("%.1f", raw))
        self.label:SetText(label)
        StopBlightfallReadyGlow(self)
    end
    local cue
    if raw <= 0.05 then cue = 0
    else
        local rounded = math.ceil(raw)
        if rounded == 5 or rounded == 3 or rounded == 2 or rounded == 1 then cue = rounded end
    end
    if cue ~= nil and cue ~= blightLastCue then
        blightLastCue = cue
        if cue == 5 then BlightfallSpeak(label .. " in", false)
        elseif cue == 0 then BlightfallSpeak("Now", true)
        else BlightfallSpeak(tostring(cue), false) end
    end
end

local function CreateBlightfallIconFrame()
    if blightIconFrame then return blightIconFrame end
    local f = CreateFrame("Frame", "DKAssistBlightfallIconAlert", UIParent, "BackdropTemplate")
    f:SetSize(64, 64)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -70)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    f:SetBackdropBorderColor(0.72, 0.40, 1.00, 0.95)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints(f)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.time = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.time:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.time:SetTextColor(1, 1, 1, 1)
    f.time:SetShadowColor(0, 0, 0, 1)
    f.time:SetShadowOffset(1, -1)
    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.label:SetPoint("TOP", f, "BOTTOM", 0, -4)
    f.label:SetTextColor(0.82, 0.55, 1.00, 1)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        local s = BlightfallSettings()
        if s and not s.iconLocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local s = BlightfallSettings()
        if s then s.iconPosition = { point, relPoint, x, y } end
    end)
    f:SetScript("OnUpdate", UpdateBlightfallIcon)
    f:Hide()
    blightIconFrame = f
    return f
end

local function CreateBlightfallFrame()
    if blightFrame then return blightFrame end
    local f = CreateFrame("Frame", "DKAssistBlightfallTimeline", UIParent, "BackdropTemplate")
    f:SetSize(420, 44)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -145)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetClipsChildren(true)
    f:SetMovable(true)
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.015, 0.02, 0.025, 0.48)
    f:SetBackdropBorderColor(0.28, 0.18, 0.38, 0.75)

    f.track = f:CreateTexture(nil, "BACKGROUND")
    f.track:SetPoint("LEFT", f, "LEFT", 34, 0)
    f.track:SetPoint("RIGHT", f, "RIGHT", -12, 0)
    f.track:SetHeight(3)
    f.track:SetColorTexture(1, 1, 1, 0.42)
    f.hit = f:CreateTexture(nil, "OVERLAY")
    f.hit:SetSize(2, 34)
    f.hit:SetPoint("CENTER", f, "LEFT", 34, 0)
    f.hit:SetColorTexture(0.72, 0.40, 1.00, 0.95)

    f.marker = CreateFrame("Frame", nil, f)
    f.marker:SetSize(190, 40)
    f.marker.icon = f.marker:CreateTexture(nil, "ARTWORK")
    f.marker.icon:SetSize(34, 34)
    f.marker.icon:SetPoint("LEFT", f.marker, "LEFT", 4, 0)
    f.marker.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Glow only the spell icon. Applying LibCustomGlow to the timeline frame
    -- itself decorates the entire 420px lane instead of the current ability.
    f.marker.glowTarget = CreateFrame("Frame", nil, f.marker)
    f.marker.glowTarget:SetAllPoints(f.marker.icon)
    f.marker.glowTarget:SetFrameLevel(f.marker:GetFrameLevel() + 5)
    f.marker.text = f.marker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.marker.text:SetPoint("LEFT", f.marker.icon, "RIGHT", 6, 0)
    f.marker.text:SetTextColor(0.82, 0.55, 1.00, 1)

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        local s = BlightfallSettings()
        if s and not s.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local s = BlightfallSettings()
        if s then s.position = { point, relPoint, x, y } end
    end)
    f:SetScript("OnUpdate", function(self)
        if not blightState then StopBlightfallReadyGlow(self.marker.glowTarget); self:Hide(); return end
        local raw = blightState.delay - (GetTime() - blightState.started)
        if blightTest and raw < -BLIGHTFALL_TEST_READY then
            local s = BlightfallSettings()
            local nextStep = blightState.step == "SOUL_REAPER" and "BLIGHTFALL" or "SOUL_REAPER"
            local delay = nextStep == "SOUL_REAPER" and s.soulReaperDelay or s.blightfallDelay
            blightState = { step = nextStep, delay = delay, started = GetTime() }
            blightLastCue = nil
            raw = delay
        elseif raw < -BLIGHTFALL_GRACE then
            blightState = nil
            StopBlightfallReadyGlow(self.marker.glowTarget)
            self:Hide()
            if blightIconFrame then StopBlightfallReadyGlow(blightIconFrame); blightIconFrame:Hide() end
            return
        end
        local eta = math.max(0, raw)
        local spellID, label, iconID = BlightfallStepInfo(blightState.step)
        self.marker.icon:SetTexture(iconID)
        local settings = BlightfallSettings()
        if settings and settings.showSpellNames == false then
            self.marker.text:SetText(string.format("%.1f", eta))
        else
            self.marker.text:SetText(string.format("%s %.1f", label, eta))
        end
        local secondsWide = math.max(8, blightState.delay)
        local pct = math.max(0, math.min(1, eta / secondsWide))
        self.marker:ClearAllPoints()
        if settings and settings.timelineOrientation == "vertical" then
            local y = 34 + ((self:GetHeight() - 144) * pct)
            self.marker:SetPoint("CENTER", self, "BOTTOM", 0, y)
        else
            -- Align the icon's center, not the whole icon-and-label marker,
            -- with the ready line. Keep the marker inside the clipped lane.
            local iconCenterOffset = 4 + self.marker.icon:GetWidth() / 2
            local startX = 34 - iconCenterOffset
            local endX = math.max(startX, self:GetWidth() - self.marker:GetWidth() - 8)
            self.marker:SetPoint("LEFT", self, "LEFT", startX + (endX - startX) * pct, 0)
        end
        if raw <= 0 then
            if not self.marker.glowTarget._glowActive then StartBlightfallReadyGlow(self.marker.glowTarget) end
        else
            StopBlightfallReadyGlow(self.marker.glowTarget)
        end

        local cue
        if raw <= 0.05 then cue = 0
        else
            local rounded = math.ceil(raw)
            if rounded == 5 or rounded == 3 or rounded == 2 or rounded == 1 then cue = rounded end
        end
        if cue ~= nil and cue ~= blightLastCue then
            blightLastCue = cue
            if cue == 5 then BlightfallSpeak(label .. " in", false)
            elseif cue == 0 then BlightfallSpeak("Now", true)
            else BlightfallSpeak(tostring(cue), false) end
        end
    end)
    f:Hide()
    blightFrame = f
    return f
end

local function ApplyBlightfallSettings()
    local s = BlightfallSettings()
    if not s then return end
    local f = CreateBlightfallFrame()
    local iconFrame = CreateBlightfallIconFrame()
    local fontSize = math.max(10, math.min(32, s.fontSize or 18))
    f.marker.text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    iconFrame.time:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    iconFrame.label:SetFont(STANDARD_TEXT_FONT, math.max(10, fontSize - 4), "OUTLINE")
    iconFrame.label:SetShown(s.showSpellNames ~= false)
    f.marker.text:Show()
    local vertical = s.timelineOrientation == "vertical"
    f.track:ClearAllPoints()
    f.hit:ClearAllPoints()
    f.marker.icon:ClearAllPoints()
    f.marker.text:ClearAllPoints()
    if vertical then
        f:SetSize(120, 420)
        f.track:SetSize(3, 1)
        f.track:SetPoint("BOTTOM", f, "BOTTOM", 0, 34)
        f.track:SetPoint("TOP", f, "TOP", 0, -12)
        f.hit:SetSize(100, 2)
        f.hit:SetPoint("CENTER", f, "BOTTOM", 0, 34)
        f.marker:SetSize(116, 76)
        f.marker.icon:SetPoint("TOP", f.marker, "TOP", 0, -2)
        f.marker.text:SetPoint("TOP", f.marker.icon, "BOTTOM", 0, -4)
        f.marker.text:SetJustifyH("CENTER")
    else
        f:SetSize(420, 44)
        f.track:SetSize(1, 3)
        f.track:SetPoint("LEFT", f, "LEFT", 34, 0)
        f.track:SetPoint("RIGHT", f, "RIGHT", -12, 0)
        f.hit:SetSize(2, 34)
        f.hit:SetPoint("CENTER", f, "LEFT", 34, 0)
        f.marker:SetSize(190, 40)
        f.marker.icon:SetPoint("LEFT", f.marker, "LEFT", 4, 0)
        f.marker.text:SetPoint("LEFT", f.marker.icon, "RIGHT", 6, 0)
        f.marker.text:SetJustifyH("LEFT")
    end
    f:SetScale(math.max(0.65, math.min(1.60, (s.size or 48) / 48)))
    f:EnableMouse(not s.locked or blightTest)
    if s.position then
        f:ClearAllPoints()
        f:SetPoint(s.position[1], UIParent, s.position[2], s.position[3], s.position[4])
    end
    local iconSize = math.max(36, math.min(128, s.iconSize or 64))
    iconFrame:SetSize(iconSize, iconSize)
    iconFrame:EnableMouse(not s.iconLocked or blightTest)
    if s.iconPosition then
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint(s.iconPosition[1], UIParent, s.iconPosition[2], s.iconPosition[3], s.iconPosition[4])
    end
    if blightState then
        local raw = blightState.delay - (GetTime() - blightState.started)
        if not blightTest and raw < -BLIGHTFALL_GRACE then blightState = nil end
    end
    if blightState then
        f:SetShown(s.enabled or (blightTest and not s.iconEnabled))
        iconFrame:SetShown(s.iconEnabled)
        local raw = blightState.delay - (GetTime() - blightState.started)
        if raw <= 0 then
            if s.enabled then StartBlightfallReadyGlow(f.marker.glowTarget) end
            if s.iconEnabled then StartBlightfallReadyGlow(iconFrame) end
        else
            StopBlightfallReadyGlow(f.marker.glowTarget)
            StopBlightfallReadyGlow(iconFrame)
        end
    end
    if not blightState or (not s.enabled and not (blightTest and not s.iconEnabled)) then
        StopBlightfallReadyGlow(f.marker.glowTarget); f:Hide()
    end
    if not blightState or not s.iconEnabled then StopBlightfallReadyGlow(iconFrame); iconFrame:Hide() end
    if (not s.enabled and not s.iconEnabled and not blightTest)
        or (not blightTest and not addon:IsSanlaynHeroSpec()) then
        StopBlightfallReadyGlow(f.marker.glowTarget)
        StopBlightfallReadyGlow(iconFrame)
        f:Hide(); iconFrame:Hide(); blightState = nil
    end
end

function addon:OnBlightfallChainSpellCast(spellID)
    local s = BlightfallSettings()
    if not s or (not s.enabled and not s.iconEnabled) or not addon:IsUnholySpec()
        or not addon:IsSanlaynHeroSpec() then return end
    if spellID == addon.SPELLS.DARK_TRANSFORMATION.id then
        blightState = { step = "SOUL_REAPER", delay = s.soulReaperDelay or 6, started = GetTime() }
    elseif spellID == addon.SPELLS.SOUL_REAPER.id and blightState and blightState.step == "SOUL_REAPER" then
        blightState = { step = "BLIGHTFALL", delay = s.blightfallDelay or 7.5, started = GetTime() }
    -- Blightfall always completes/resets the chain. It can be cast without the
    -- tracked Soul Reaper step, so never leave an older countdown running.
    elseif spellID == addon.SPELLS.BLIGHTFALL.id then
        blightState = nil
    else
        return
    end
    blightLastCue = nil
    local f = CreateBlightfallFrame()
    ApplyBlightfallSettings()
    local iconFrame = CreateBlightfallIconFrame()
    if blightState then
        f:SetShown(s.enabled)
        iconFrame:SetShown(s.iconEnabled)
    else
        StopBlightfallReadyGlow(f.marker.glowTarget)
        f:Hide()
        StopBlightfallReadyGlow(iconFrame)
        iconFrame:Hide()
    end
end

function addon:RefreshBlightfallTracker() ApplyBlightfallSettings() end
function addon:TestBlightfallTracker()
    local s = BlightfallSettings()
    if not s then return end
    blightTest = true
    blightState = { step = "SOUL_REAPER", delay = s.soulReaperDelay or 6, started = GetTime() }
    blightLastCue = nil
    local f = CreateBlightfallFrame()
    local iconFrame = CreateBlightfallIconFrame()
    ApplyBlightfallSettings()
    f:SetShown(s.enabled or not s.iconEnabled)
    iconFrame:SetShown(s.iconEnabled)
end
function addon:StopBlightfallTest()
    blightTest = false
    blightState = nil
    if blightFrame then StopBlightfallReadyGlow(blightFrame.marker.glowTarget); blightFrame:Hide(); ApplyBlightfallSettings() end
    if blightIconFrame then StopBlightfallReadyGlow(blightIconFrame); blightIconFrame:Hide() end
end

local BLOOD_DND_GRACE_DURATION = 4
local dndFrame      = nil
local dndHideTimer  = nil
local dndGraceTimer = nil
local dndPhaseStart = nil
local dndPhaseDuration = nil
local dndPhaseLabel = nil
local dndOutsideFor = 0
local dndPlayerOutside = false
local dndGroundExpires = nil
local dndInsideProxy = nil
local dndInsideContainer = nil
local DND_TIMER_ICON = "|T136144:32:32:0:0|t"

local function FormatDnDTimerLabel(label, remaining)
    if label == "Cleaving Strikes" then
        return string.format("%s Cleaving Strikes %.1f", DND_TIMER_ICON, remaining)
    end
    return string.format("%s %.1f", DND_TIMER_ICON, remaining)
end

-- WoW 12.1 makes aura 188290 secret while combat restrictions are active.
-- Do not ask Lua whether it exists.  A Blizzard AuraContainer owns this
-- overlay and shows/hides it directly, so the inside state remains reliable
-- in combat without comparing or branching on a secret value.
local function CreateSecureDnDInsideOverlay(owner)
    if dndInsideContainer or not owner then return end

    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
    end
    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then return end

    local proxy = CreateFrame("Frame", nil, owner)
    proxy:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", 0, 0)
    proxy:SetPoint("BOTTOMRIGHT", owner, "TOPRIGHT", 0, 0)
    proxy:SetHeight(25)
    proxy:SetFrameLevel(owner:GetFrameLevel() + 30)
    proxy:Hide()

    local container = CreateFrame("AuraContainer", nil, proxy, "CustomAuraContainerTemplate")
    container:SetPoint("CENTER", proxy, "CENTER")
    container:SetSize(1, 1)
    container:AddAuraSlot("dndInside", "HELPFUL", {
        candidateFilters = { includeSpellIDs = { [188290] = true } },
        initializeFrame = function(button)
            button:SetAllPoints(proxy)
            button:SetFrameLevel(proxy:GetFrameLevel() + 1)
            if button.SetMouseMotionEnabled then button:SetMouseMotionEnabled(false) end

            local cover = button:CreateTexture(nil, "BACKGROUND")
            cover:SetSize(240, 25)
            cover:SetPoint("CENTER", button, "CENTER", 0, 0)
            -- The permanent status plate below uses the same opaque color.
            -- This hides the opposite label without changing appearance.
            cover:SetColorTexture(0.015, 0.02, 0.025, 1)

            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            text:SetPoint("CENTER", button, "CENTER", 0, 0)
            text:SetText("Cleaving Active")
            text:SetTextColor(0.20, 1.00, 0.25, 1)
            text:SetShadowColor(0, 0, 0, 1)
            text:SetShadowOffset(1, -1)
        end,
    })
    container:SetUnit("player")
    container:UpdateAllAuras()

    dndInsideProxy = proxy
    dndInsideContainer = container
end

local function CreateDnDFrame()
    if dndFrame then return dndFrame end

    local f = CreateFrame("Frame", "DKAssistDnDTracker", UIParent, "BackdropTemplate")
    f:SetSize(300, 40)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    -- The secure inside/outside status sits just above the timer while the
    -- timer itself keeps its original compact dimensions.
    f:SetClipsChildren(false)
    f:SetMovable(true)
    f:EnableMouse(false)

    -- Blightfall-style timeline lane with no duplicated spell icon.
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.015, 0.02, 0.025, 0.45)
    f:SetBackdropBorderColor(0.12, 0.18, 0.20, 0.50)

    f.track = f:CreateTexture(nil, "BACKGROUND")
    f.track:SetPoint("LEFT", f, "LEFT", 34, 0)
    f.track:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.track:SetHeight(3)
    f.track:SetColorTexture(1, 1, 1, 0.38)

    f.nowGlow = f:CreateTexture(nil, "BACKGROUND")
    f.nowGlow:SetSize(18, 34)
    f.nowGlow:SetPoint("CENTER", f, "LEFT", 34, 0)
    f.nowGlow:SetColorTexture(1.00, 0.10, 0.10, 0.07)

    f.nowLine = f:CreateTexture(nil, "OVERLAY")
    f.nowLine:SetSize(2, 30)
    f.nowLine:SetPoint("CENTER", f, "LEFT", 34, 0)
    f.nowLine:SetColorTexture(1, 1, 1, 0.95)

    f.nowText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.nowText:SetPoint("BOTTOM", f, "TOP", 0, 5)
    f.nowText:SetFontObject(GameFontNormalLarge)
    f.nowText:SetShadowColor(0, 0, 0, 1)
    f.nowText:SetShadowOffset(1, -1)
    f.nowText:SetText("")
    f.nowText:SetTextColor(1.00, 0.10, 0.10, 1)

    -- A small permanent status plate keeps the secure Inside overlay and
    -- the normal Outside label visually identical, with no stacked text.
    f.statusBg = f:CreateTexture(nil, "ARTWORK")
    f.statusBg:SetSize(240, 25)
    f.statusBg:SetPoint("BOTTOM", f, "TOP", 0, 0)
    f.statusBg:SetColorTexture(0.015, 0.02, 0.025, 1)
    f.nowText:SetDrawLayer("OVERLAY", 2)

    CreateSecureDnDInsideOverlay(f)

    f.marker = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.marker:SetSize(200, 36)
    f.marker:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f.marker:SetBackdropColor(0, 0, 0, 0)
    f.marker:SetBackdropBorderColor(0, 0, 0, 0)
    f.marker.text = f.marker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.marker.text:SetPoint("CENTER")
    f.marker.text:SetText(FormatDnDTimerLabel("Death and Decay", 10))
    f.marker.text:SetTextColor(1.00, 0.10, 0.10, 1)

    -- Drag handling (only when unlocked)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if DKAssistDB.dnd and not DKAssistDB.dnd.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        if DKAssistDB.dnd then
            DKAssistDB.dnd.position = {point, relPoint, x, y}
        end
    end)

    f:SetScript("OnUpdate", function(self, elapsed)
        if not dndActive or not dndPhaseStart or not dndPhaseDuration then return end
        local remaining = math.max(0, dndPhaseDuration - (GetTime() - dndPhaseStart))
        if remaining <= 0 then
            self.marker:Hide()
            return
        end
        self.marker:Show()
        local pct = math.max(0, math.min(1, remaining / dndPhaseDuration))
        local hitX = 34
        local farX = self:GetWidth() - 110
        local x = hitX + ((farX - hitX) * pct)
        self.marker:ClearAllPoints()
        self.marker:SetPoint("CENTER", self, "LEFT", x, 0)
        self.marker.text:SetText(FormatDnDTimerLabel(dndPhaseLabel or "Death and Decay", remaining))

        if addon:IsBloodSpec() and dndPhaseLabel == "Cleaving Strikes" then
            if dndInsideProxy then dndInsideProxy:Hide() end
            dndOutsideFor = 0
            dndPlayerOutside = false
            self.nowText:SetText("Cleaving")
            local c = DKAssistDB.dnd.graceColor or { r = 1.00, g = 0.45, b = 0.08 }
            self.nowText:SetTextColor(c.r, c.g, c.b, 1)
            self.marker.text:SetTextColor(c.r, c.g, c.b, 1)
        elseif addon:IsBloodSpec() then
            -- Outside is the default layer.  When 188290 is active the
            -- secure engine-owned slot above covers it with "Cleaving Active".
            -- This deliberately contains no protected aura read.
            if dndInsideProxy and not dndInsideProxy:IsShown() then
                dndInsideProxy:Show()
                if dndInsideContainer then pcall(dndInsideContainer.UpdateAllAuras, dndInsideContainer) end
            end
            dndOutsideFor = dndOutsideFor + (elapsed or 0)
            if dndOutsideFor >= 0.5 then
                dndPlayerOutside = true
                self.nowText:SetText("Cleaving Missing")
                self.nowText:SetTextColor(1.00, 0.08, 0.08, 1)
                self.marker.text:SetTextColor(1.00, 0.08, 0.08, 1)
            end
        else
            if dndInsideProxy then dndInsideProxy:Hide() end
            dndOutsideFor = 0
            dndPlayerOutside = false
            self.nowText:SetText("")
        end
    end)

    f:Hide()
    dndFrame = f
    return f
end

local function UpdateDnDDesaturation()
    if not dndFrame then return end
    if dndActive then
        dndFrame.marker:Show()
        dndFrame.marker:SetAlpha(1)
    else
        dndFrame.marker:Show()
        dndFrame.marker:SetAlpha(0.45)
        dndFrame.marker.text:SetText(DND_TIMER_ICON .. " Ready")
        dndFrame.marker:ClearAllPoints()
        dndFrame.marker:SetPoint("CENTER", dndFrame, "LEFT", 120, 0)
    end
end

local ApplyDnDTimelineColor

local function ShowDnDAlwaysShow()
    if not dndFrame then return end
    local s = DKAssistDB.dnd
    if addon:IsBloodSpec() and s.alwaysShow and s.enabled then
        dndFrame:Show()
        UpdateDnDDesaturation()
    elseif not dndActive then
        dndFrame:Hide()
    end
end

local function FinishDnDTrackerState()
    if dndHideTimer then dndHideTimer:Cancel(); dndHideTimer = nil end
    if dndGraceTimer then dndGraceTimer:Cancel(); dndGraceTimer = nil end
    dndActive = false
    dndPhaseStart = nil
    dndPhaseDuration = nil
    dndPhaseLabel = nil
    dndGroundExpires = nil
    dndAuraKnownInside = (GetTime() - (dndLastAuraAppliedAt or 0)) <= 0.75
    dndOutsideFor = 0
    dndPlayerOutside = false
    if dndInsideProxy then dndInsideProxy:Hide() end
    addon:StopDnDMissingGlow()
    if dndFrame then
        dndFrame.nowText:SetText("")
        if DKAssistDB.dnd.alwaysShow and addon:IsBloodSpec() then
            UpdateDnDDesaturation()
        else
            dndFrame:Hide()
        end
    end
end

function addon:StartDnDCleavingPhase()
    if not (dndActive and addon:IsBloodSpec()) then return end
    if dndPhaseLabel == "Cleaving Strikes" then return end
    if dndGraceTimer then dndGraceTimer:Cancel(); dndGraceTimer = nil end
    if dndHideTimer then dndHideTimer:Cancel(); dndHideTimer = nil end
    dndAuraKnownInside = false
    dndOutsideFor = 0
    dndPhaseStart = GetTime()
    dndPhaseDuration = BLOOD_DND_GRACE_DURATION
    dndPhaseLabel = "Cleaving Strikes"
    if dndInsideProxy then dndInsideProxy:Hide() end
    dndFrame.nowText:SetText("")
    dndFrame.marker:Show()
    ApplyDnDTimelineColor(true)
    dndHideTimer = C_Timer.NewTimer(BLOOD_DND_GRACE_DURATION, FinishDnDTrackerState)
end

function addon:ResumeDnDGroundPhase()
    if not (dndActive and addon:IsBloodSpec() and dndGroundExpires) then return end
    local remaining = dndGroundExpires - GetTime()
    if remaining <= 0 then return end
    if dndHideTimer then dndHideTimer:Cancel(); dndHideTimer = nil end
    if dndGraceTimer then dndGraceTimer:Cancel(); dndGraceTimer = nil end
    dndAuraKnownInside = true
    dndOutsideFor = 0
    addon:StopDnDMissingGlow()
    dndPhaseStart = GetTime()
    dndPhaseDuration = remaining
    dndPhaseLabel = "Death and Decay"
    ApplyDnDTimelineColor(false)
    dndGraceTimer = C_Timer.NewTimer(remaining, function()
        dndGraceTimer = nil
        addon:StartDnDCleavingPhase()
    end)
end

ApplyDnDTimelineColor = function(grace)
    if not dndFrame or not DKAssistDB or not DKAssistDB.dnd then return end
    local s = DKAssistDB.dnd
    local c = grace and s.graceColor or s.color
    c = c or (grace and {r = 1, g = 0.45, b = 0.08} or {r = 1, g = 0.10, b = 0.10})
    dndFrame.track:SetColorTexture(1, 1, 1, 0.38)
    dndFrame.nowGlow:SetColorTexture(c.r, c.g, c.b, 0.07)
    dndFrame.nowLine:SetColorTexture(1, 1, 1, 0.95)
    -- The labels keep the selected timer/grace color; only the timeline is white.
    dndFrame.nowText:SetTextColor(c.r, c.g, c.b, 1)
    dndFrame.marker.text:SetTextColor(c.r, c.g, c.b, 1)
end

local function ApplyDnDSettings()
    if not dndFrame then return end
    local s = DKAssistDB.dnd
    local size = s.size or 48
    dndFrame:SetScale(math.max(0.65, math.min(1.60, size / 48)))
    ApplyDnDTimelineColor(dndPhaseLabel == "Cleaving Strikes")

    if s.position then
        dndFrame:ClearAllPoints()
        dndFrame:SetPoint(s.position[1], UIParent, s.position[2], s.position[3], s.position[4])
    end

    -- Enable/disable mouse for dragging based on lock state
    dndFrame:EnableMouse(not s.locked)

    ShowDnDAlwaysShow()
end

function addon:InitDnDTracker()
    CreateDnDFrame()
    ApplyDnDSettings()
end

function addon:OnDeathAndDecayCast()
    local s = DKAssistDB.dnd
    -- This tracker is intentionally Blood-only; Unholy has its own combat
    -- tools and no longer shares this saved toggle.
    if not addon:IsBloodSpec() then return end
    local glowEnabled = DKAssistDB.bloodDndMissing and DKAssistDB.bloodDndMissing.enabled
    if not s or (not s.enabled and not glowEnabled) then return end

    if not dndFrame then CreateDnDFrame() ApplyDnDSettings() end

    -- Cancel any pending hide timer (handles recast within 10s)
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end
    if dndGraceTimer then
        dndGraceTimer:Cancel()
        dndGraceTimer = nil
    end

    -- Mark active and show with full color
    dndActive = true
    UpdateDnDDesaturation()

    dndPhaseStart = GetTime()
    dndPhaseDuration = DND_DURATION
    dndPhaseLabel = "Death and Decay"
    dndGroundExpires = GetTime() + DND_DURATION
    dndAuraKnownInside = false
    dndOutsideFor = 0
    dndPlayerOutside = false
    dndFrame.nowText:SetText("")
    dndFrame.marker:Show()
    dndFrame.marker:SetBackdropColor(0, 0, 0, 0)
    dndFrame.marker:SetBackdropBorderColor(0, 0, 0, 0)
    ApplyDnDTimelineColor(false)
    dndFrame:SetShown(s.enabled)

    -- Fallback for clients that do not deliver the aura removal combat-log
    -- edge: the grace phase still starts when the ground effect expires.
    dndGraceTimer = C_Timer.NewTimer(DND_DURATION, function()
        dndGraceTimer = nil
        addon:StartDnDCleavingPhase()
    end)
end

function addon:TestDnDTracker()
    if not dndFrame then CreateDnDFrame() ApplyDnDSettings() end

    -- Cancel any existing hide timer
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end
    if dndGraceTimer then
        dndGraceTimer:Cancel()
        dndGraceTimer = nil
    end

    -- Show the frame with no swipe during test — just the icon for positioning
    dndActive = false
    dndPhaseStart = nil
    dndPhaseDuration = nil
    dndPhaseLabel = nil
    dndOutsideFor = 0
    dndPlayerOutside = false
    dndFrame.nowText:SetText("Cleaving Active")
    dndFrame.nowText:SetTextColor(0.20, 1.00, 0.25, 1)
    dndFrame.marker:SetAlpha(1)
    dndFrame.marker.text:SetText(DND_TIMER_ICON .. " Timer")
    dndFrame.marker:ClearAllPoints()
    dndFrame.marker:SetPoint("CENTER", dndFrame, "CENTER", 20, 0)
    dndFrame:Show()
    dndFrame:EnableMouse(true) -- always draggable during test
end

function addon:StopDnDTest()
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end
    if dndGraceTimer then
        dndGraceTimer:Cancel()
        dndGraceTimer = nil
    end
    if dndFrame then
        dndActive = false
        dndPhaseStart = nil
        dndPhaseDuration = nil
        dndPhaseLabel = nil
        dndOutsideFor = 0
        dndPlayerOutside = false
        dndFrame.nowText:SetText("")
        -- Restore lock state and alwaysShow behavior
        ApplyDnDSettings()
        if not DKAssistDB.dnd.alwaysShow then
            dndFrame:Hide()
        end
    end
end

function addon:RefreshDnDTracker()
    if not addon:IsBloodSpec() then
        FinishDnDTrackerState()
        return
    end
    if dndFrame then
        ApplyDnDSettings()
        if dndActive then dndFrame:SetShown(DKAssistDB.dnd.enabled) end
    end
end

function addon:RefreshDnDAlwaysShow()
    if not dndFrame then CreateDnDFrame() end
    ApplyDnDSettings()
end

-- -------------------------------------------------------
-- Soul Reaper Glow Suppression
-- -------------------------------------------------------
local SOUL_REAPER_ID = 343294

local function ShouldSuppressSoulReaperGlow()
    local s = DKAssistDB and DKAssistDB.soulReaper
    if not s then return false end
    return s.suppressMode == "always"
end

local function GetButtonSpellIDForGlow(button)
    -- Try GetSpellId (Blizzard default bars)
    if button.GetSpellId then
        local ok, id = pcall(button.GetSpellId, button)
        if ok and id then return id end
    end
    -- Try action slot lookup
    local actionSlot = nil
    if button.action and type(button.action) == "number" then
        actionSlot = button.action
    elseif button._state_action and type(button._state_action) == "number" then
        actionSlot = button._state_action
    end
    if actionSlot then
        local ok, aType, aId = pcall(GetActionInfo, actionSlot)
        if ok and aType == "spell" then return aId end
    end
    return nil
end

function addon:SetupSoulReaperHook()
    -- Disabled on 12.1. Hiding Blizzard or LibButtonGlow overlays from a hook
    -- taints protected action-button frames and triggers ADDON_ACTION_FORBIDDEN
    -- in combat. The timeline and icon reminders do not depend on this hook.
end

local castFrame = CreateFrame("Frame")
castFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
castFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
castFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
castFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

castFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_TALENT_UPDATE" then
        if not addon:IsSanlaynHeroSpec() then addon:StopBlightfallTest() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then return end
        if spellID == addon.SPELLS.FESTERING_STRIKE.id then
            addon:OnFesteringStrikeCast()
        elseif spellID == addon.SPELLS.FESTERING_SCYTHE.id then
            addon:OnFesteringScytheCast()
        elseif spellID == addon.SPELLS.DARK_TRANSFORMATION.id then
            addon:OnDarkTransformationCast()
        elseif spellID == 47541 or spellID == 207317 then -- Death Coil / Epidemic
            addon:OnDarkTransformationExtended()
        elseif spellID == addon.SPELLS.DEATH_AND_DECAY.id then
            addon:OnDeathAndDecayCast()
        elseif spellID == addon.SPELLS.MARROWREND.id or spellID == addon.SPELLS.DEATHS_CARESS.id
            or spellID == 108199 or spellID == 49028 or spellID == 439843 then
            if addon.OnBoneShieldGeneratorCast then addon:OnBoneShieldGeneratorCast() end
        end
        addon:OnBlightfallChainSpellCast(spellID)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Do not call StopAll here: it cancels the Festering Scythe expiry
        -- timer, even though that buff continues ticking out of combat.
        StopPutrefyWarning()
        addon:StopSuddenDoomGlows()
        OnFesteringCombatEnd()
        addon:ShowPutrefyHoldWarning()
        if addon.OnBoneShieldCombatEnd then addon:OnBoneShieldCombatEnd() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnFesteringCombatStart()
        if addon.OnBoneShieldCombatStart then addon:OnBoneShieldCombatStart() end
    end
end)

-- Sudden Doom changes Death Coil's Runic Power cost.  Check only ten times
-- per second and update glows only when that state changes.
local suddenDoomWatcher = CreateFrame("Frame")
local suddenDoomElapsed = 0
suddenDoomWatcher:SetScript("OnUpdate", function(_, elapsed)
    suddenDoomElapsed = suddenDoomElapsed + elapsed
    if suddenDoomElapsed < 0.10 then return end
    suddenDoomElapsed = 0
    local active = addon:IsSuddenDoomActive()
    if active and not suddenDoomActive then
        addon:ShowSuddenDoomGlows()
    elseif not active and suddenDoomActive then
        addon:StopSuddenDoomGlows()
    end
end)

function addon:ShowWelcomePopup()
    local popup = CreateFrame("Frame", "DKAssistWelcomePopup", UIParent, "BackdropTemplate")
    popup:SetSize(420, 210)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    popup:SetBackdropColor(0.08, 0.08, 0.08, 0.96)
    popup:SetBackdropBorderColor(0.8, 0.0, 0.0, 1)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -16)
    title:SetText("|cffcc0000DK Assist|r")

    local message = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("TOP", title, "BOTTOM", 0, -12)
    message:SetWidth(380)
    message:SetJustifyH("CENTER")
    message:SetText(
        "Welcome to DK Assist!\n\n" ..
        "|cffaaff44Festering Scythe:|r Glows Festering Strike/Scythe when <5 seconds remaining on the buff.\n" ..
        "|cffff4444Putrefy Warning:|r Shows a warning on Putrefy when Dark Transformation has less than 15 seconds cooldown remaining.\n\n" ..
        "Open settings to configure glow styles and colors."
    )

    local settingsBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    settingsBtn:SetSize(130, 26)
    settingsBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 50, 20)
    settingsBtn:SetText("Open Settings")
    settingsBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
        if addon.OpenStandaloneSettings then
            addon:OpenStandaloneSettings()
        end
    end)

    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 26)
    closeBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -50, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
    end)

    local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 2, 2)
    xBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
    end)

    popup:Show()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

initFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not DKAssistDB then
            DKAssistDB = CopyTable(addon.DEFAULT_DB)
        end

        if not DKAssistDB.spells then DKAssistDB.spells = {} end
        if not DKAssistDB.spells.festeringScythe then
            DKAssistDB.spells.festeringScythe = CopyTable(addon.DEFAULT_DB.spells.festeringScythe)
        else
            for k, v in pairs(addon.DEFAULT_DB.spells.festeringScythe) do
                if DKAssistDB.spells.festeringScythe[k] == nil then
                    DKAssistDB.spells.festeringScythe[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        NormalizeTextAlertFont(DKAssistDB.spells.festeringScythe.textAlert)
        for _, spellKey in ipairs({ "deathCoil", "epidemic" }) do
            if not DKAssistDB.spells[spellKey] then
                DKAssistDB.spells[spellKey] = CopyTable(addon.DEFAULT_DB.spells[spellKey])
            else
                for k, v in pairs(addon.DEFAULT_DB.spells[spellKey]) do
                    if DKAssistDB.spells[spellKey][k] == nil then
                        DKAssistDB.spells[spellKey][k] = type(v) == "table" and CopyTable(v) or v
                    end
                end
            end
            NormalizeTextAlertFont(DKAssistDB.spells[spellKey].textAlert)
        end
        if not DKAssistDB.putrefy then
            DKAssistDB.putrefy = CopyTable(addon.DEFAULT_DB.putrefy)
        else
            for k, v in pairs(addon.DEFAULT_DB.putrefy) do
                if DKAssistDB.putrefy[k] == nil then DKAssistDB.putrefy[k] = v end
            end
        end
        if DKAssistDB.trackCDMFestering == nil then DKAssistDB.trackCDMFestering = false end
        if DKAssistDB.trackCDMPutrefy   == nil then DKAssistDB.trackCDMPutrefy   = false end
        if DKAssistDB.trackCDMSuddenDoom == nil then DKAssistDB.trackCDMSuddenDoom = false end
        if not DKAssistDB.suddenDoomGlow then
            DKAssistDB.suddenDoomGlow = CopyTable(addon.DEFAULT_DB.suddenDoomGlow)
        else
            for k, v in pairs(addon.DEFAULT_DB.suddenDoomGlow) do
                if DKAssistDB.suddenDoomGlow[k] == nil then
                    DKAssistDB.suddenDoomGlow[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        if not DKAssistDB.suddenDoomTextAlert then
            DKAssistDB.suddenDoomTextAlert = CopyTable(addon.DEFAULT_DB.suddenDoomTextAlert)
        else
            for k, v in pairs(addon.DEFAULT_DB.suddenDoomTextAlert) do
                if DKAssistDB.suddenDoomTextAlert[k] == nil then
                    DKAssistDB.suddenDoomTextAlert[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        NormalizeTextAlertFont(DKAssistDB.suddenDoomTextAlert)
        for _, key in ipairs({ "killingMachineTextAlert", "rimeTextAlert" }) do
            if not DKAssistDB[key] then DKAssistDB[key] = CopyTable(addon.DEFAULT_DB[key]) end
            for field, value in pairs(addon.DEFAULT_DB[key]) do
                if DKAssistDB[key][field] == nil then
                    DKAssistDB[key][field] = type(value) == "table" and CopyTable(value) or value
                end
            end
            NormalizeTextAlertFont(DKAssistDB[key])
        end
        if DKAssistDB.runicPowerWarning == nil then DKAssistDB.runicPowerWarning = true end
        if not DKAssistDB.runicPower then
            DKAssistDB.runicPower = CopyTable(addon.DEFAULT_DB.runicPower)
            DKAssistDB.runicPower.enabled = DKAssistDB.runicPowerWarning
        else
            for k, v in pairs(addon.DEFAULT_DB.runicPower) do
                if DKAssistDB.runicPower[k] == nil then DKAssistDB.runicPower[k] = v end
            end
        end

        -- Death and Decay tracker defaults
        if not DKAssistDB.dnd then
            DKAssistDB.dnd = CopyTable(addon.DEFAULT_DB.dnd)
        else
            for k, v in pairs(addon.DEFAULT_DB.dnd) do
                if DKAssistDB.dnd[k] == nil then DKAssistDB.dnd[k] = v end
            end
        end

        if not DKAssistDB.blightfallChain then
            DKAssistDB.blightfallChain = CopyTable(addon.DEFAULT_DB.blightfallChain)
        else
            for k, v in pairs(addon.DEFAULT_DB.blightfallChain) do
                if DKAssistDB.blightfallChain[k] == nil then
                    DKAssistDB.blightfallChain[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end

        if not DKAssistDB.bloodDnd then
            DKAssistDB.bloodDnd = CopyTable(addon.DEFAULT_DB.bloodDnd)
        else
            for k, v in pairs(addon.DEFAULT_DB.bloodDnd) do
                if DKAssistDB.bloodDnd[k] == nil then
                    DKAssistDB.bloodDnd[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        if not DKAssistDB.bloodDndMissing then
            DKAssistDB.bloodDndMissing = CopyTable(addon.DEFAULT_DB.bloodDndMissing)
        else
            for k, v in pairs(addon.DEFAULT_DB.bloodDndMissing) do
                if DKAssistDB.bloodDndMissing[k] == nil then
                    DKAssistDB.bloodDndMissing[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        -- Migrate the short-lived development option that stored this
        -- reminder inside the Death and Decay timer settings.
        if DKAssistDB.dnd and DKAssistDB.dnd.buffGlow ~= nil then
            DKAssistDB.bloodDndMissing.enabled = DKAssistDB.dnd.buffGlow and true or false
            DKAssistDB.dnd.buffGlow = nil
        end
        -- The old "ready" glow remains retired. The outside glow is now an
        -- explicit optional companion to the timeline and must preserve the
        -- user's checkbox across reloads.
        DKAssistDB.bloodDnd.enabled = false

        -- Earlier builds used red as the normal timer color.  Migrate that
        -- legacy default once so the new Inside (normal) -> Outside (red)
        -- state change is immediately visible without overwriting later
        -- user color choices.
        if not DKAssistDB.dnd.insideOutsideColorMigrated then
            local c = DKAssistDB.dnd.color
            if c and math.abs((c.r or 0) - 1.00) < 0.01
                and math.abs((c.g or 0) - 0.10) < 0.01
                and math.abs((c.b or 0) - 0.10) < 0.01 then
                DKAssistDB.dnd.color = { r = 0.20, g = 1.00, b = 0.25 }
            end
            DKAssistDB.dnd.insideOutsideColorMigrated = true
        end
        if not DKAssistDB.bloodBone then
            DKAssistDB.bloodBone = CopyTable(addon.DEFAULT_DB.bloodBone)
        else
            for k, v in pairs(addon.DEFAULT_DB.bloodBone) do
                if DKAssistDB.bloodBone[k] == nil then
                    DKAssistDB.bloodBone[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        if not DKAssistDB.bloodShield then
            DKAssistDB.bloodShield = CopyTable(addon.DEFAULT_DB.bloodShield)
        else
            for k, v in pairs(addon.DEFAULT_DB.bloodShield) do
                if DKAssistDB.bloodShield[k] == nil then
                    DKAssistDB.bloodShield[k] = type(v) == "table" and CopyTable(v) or v
                end
            end
        end
        if DKAssistDB.configSpecView == nil then DKAssistDB.configSpecView = "auto" end

        -- Soul Reaper defaults
        if not DKAssistDB.soulReaper then
            DKAssistDB.soulReaper = CopyTable(addon.DEFAULT_DB.soulReaper)
        else
            for k, v in pairs(addon.DEFAULT_DB.soulReaper) do
                if DKAssistDB.soulReaper[k] == nil then DKAssistDB.soulReaper[k] = v end
            end
        end

        C_Timer.After(1, function() addon:ScanAllButtons() end)
        C_Timer.After(1, function() addon:InitDnDTracker() end)
        -- Soul Reaper overlay suppression is intentionally disabled on 12.1;
        -- hooking protected action-button glow paths causes forbidden actions.
        C_Timer.After(2, function() addon:ShowPutrefyHoldWarning() end)

        if addon.CreateConfigPanel then
            local panel = addon:CreateConfigPanel()
            local category = Settings.RegisterCanvasLayoutCategory(panel, "DK Assist")
            Settings.RegisterAddOnCategory(category)
            addon.settingsCategory = category

            -- The minimap button uses a dedicated DK Assist window; the same
            -- configuration remains available in Blizzard's AddOns settings.
            local window = CreateFrame("Frame", "DKAssistSettingsWindow", UIParent, "BackdropTemplate")
            -- Treat the standalone window like Blizzard's other panels: Esc
            -- closes it, without affecting the embedded AddOns settings page.
            if UISpecialFrames then
                local registered = false
                for _, frameName in ipairs(UISpecialFrames) do
                    if frameName == "DKAssistSettingsWindow" then
                        registered = true
                        break
                    end
                end
                if not registered then
                    table.insert(UISpecialFrames, "DKAssistSettingsWindow")
                end
            end
            -- The standalone window uses the navigation-first layout.  The
            -- extra width belongs to the persistent section sidebar; feature
            -- cards keep the same comfortable two-column working area.
            window:SetSize(1040, 720)
            window:SetPoint("CENTER")
            window:SetFrameStrata("DIALOG")
            window:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
            window:SetBackdropColor(0.012, 0.012, 0.018, 1)
            window:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
            -- Keep the standalone settings window fully opaque, then add a
            -- restrained dark pattern above the black base.
            local backgroundTexture = window:CreateTexture(nil, "BACKGROUND", nil, -8)
            backgroundTexture:SetAllPoints()
            backgroundTexture:SetColorTexture(0.012, 0.012, 0.018, 1)
            local backgroundPattern = window:CreateTexture(nil, "BACKGROUND", nil, -7)
            backgroundPattern:SetAllPoints()
            backgroundPattern:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
            backgroundPattern:SetVertexColor(0.16, 0.16, 0.20, 0.42)
            window.dkassistBackgroundTexture = backgroundTexture
            window.dkassistBackgroundPattern = backgroundPattern
            window:EnableMouse(true)
            window:SetMovable(true)
            window:RegisterForDrag("LeftButton")
            window:SetScript("OnDragStart", window.StartMoving)
            window:SetScript("OnDragStop", window.StopMovingOrSizing)
            window:Hide()

            local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
            close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -4)
            close:SetScript("OnClick", function() window:Hide() end)
            window.dkassistCloseButton = close
            local modernCloseText = close:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            modernCloseText:SetPoint("CENTER", close, "CENTER", 0, 1)
            modernCloseText:SetText("X")
            modernCloseText:SetTextColor(0.62, 0.79, 1.00, 1)
            modernCloseText:Hide()
            window.dkassistModernCloseText = modernCloseText

            local standalonePanel = addon:CreateConfigPanel(true)
            standalonePanel:SetParent(window)
            standalonePanel:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -18)
            standalonePanel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -18, 18)
            addon.standaloneSettingsWindow = window
            addon.standaloneSettingsPanel = standalonePanel
            if standalonePanel.ApplyStandaloneTheme then
                standalonePanel:ApplyStandaloneTheme(DKAssistDB.standaloneTheme or "classic")
            end
            function addon:OpenStandaloneSettings()
                window:Show()
                standalonePanel:Show()
                standalonePanel:RefreshControls()
            end
        end

        if not DKAssistDB.seenWelcome then
            C_Timer.After(2, function() addon:ShowWelcomePopup() end)
        end

        print("|cffcc0000DK Assist|r loaded — |cffaaaaaa/dka|r for options")

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        addon:StopAll()
        addon:RefreshDnDTracker()
        C_Timer.After(0.5, function() addon:ScanAllButtons() end)
        C_Timer.After(1, function()
            if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
            addon:RefreshBloodDnDReminder()
        end)
        -- CDM rescan is handled by ButtonScanner's PLAYER_SPECIALIZATION_CHANGED handler
    end
end)

SLASH_DKASSIST1 = "/dka"
SLASH_DKASSIST2 = "/dkassist"

SlashCmdList["DKASSIST"] = function(msg)
    local cmd = (msg or ""):lower():trim()

    if cmd == "scan" then
        addon:ScanAllButtons()
        print("|cffcc0000DK Assist:|r Rescanned action bars")
    elseif cmd == "cdmscan" then
        if DKAssistDB and (DKAssistDB.trackCDMFestering or DKAssistDB.trackCDMPutrefy) then
            addon:CreateCDMOverlays()
            print("|cffcc0000DK Assist:|r Rescanned Cooldown Manager frames")
        else
            print("|cffcc0000DK Assist:|r Cooldown Manager tracking is disabled")
        end
    elseif cmd == "debug" then
        addon:ToggleDebug()
    elseif cmd == "minimap" then
        if addon.CreateMinimapButton then
            DKAssistDB.minimapHidden = false
            addon:CreateMinimapButton()
            if addon.minimapButton then
                addon.minimapButton:Show()
                print("|cffcc0000DK Assist:|r Minimap button shown")
            end
        end
    else
        if addon.OpenStandaloneSettings then
            addon:OpenStandaloneSettings()
        else
            print("|cffcc0000DK Assist:|r /dka scan - Rescan action bars")
            print("|cffcc0000DK Assist:|r /dka cdmscan - Rescan Cooldown Manager")
            print("|cffcc0000DK Assist:|r /dka debug - Toggle debug logging")
            print("|cffcc0000DK Assist:|r /dka minimap - Show Minimap button")
        end
    end
end
