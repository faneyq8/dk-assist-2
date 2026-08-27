local addonName, addon = ...

local VERSION = "1.7.0"
local DARK_TRANSFORMATION = 1233448

-- Patch 12.1 marks live cooldown, aura-stack and power values as secret.
-- Reading or comparing them taints an addon, so this tracker deliberately
-- uses only events and its own safe local timer.
local burstEndsAt = 0
local DARK_TRANSFORMATION_DURATION = 15

function addon:CreateCombatTracker()
    if self.combatTracker then return end
    local frame = CreateFrame("Frame", "DKAssistCombatTracker", UIParent, "BackdropTemplate")
    frame:SetSize(220, 98)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.88)
    frame:SetBackdropBorderColor(0.1, 0.8, 0.2, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -9)
    title:SetText("|cff00dd55DK Assist|r  Combat")

    local burst = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    burst:SetPoint("TOPLEFT", 12, -31)
    frame.burst = burst
    local doom = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    doom:SetPoint("TOPLEFT", 12, -51)
    frame.doom = doom
    local power = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    power:SetPoint("TOPLEFT", 12, -71)
    frame.power = power

    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("DK Assist Combat Tracker")
        GameTooltip:AddLine("Drag to move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
    self.combatTracker = frame
end

function addon:UpdateCombatTracker()
    local frame = self.combatTracker
    if not frame or not DKAssistDB or not DKAssistDB.enhancements.enabled then return end
    local remaining = math.max(0, burstEndsAt - GetTime())
    if remaining > 0.1 then
        frame.burst:SetText(string.format("Burst (Dark Transformation): |cffffcc00%.0fs active|r", remaining))
    else
        frame.burst:SetText("Burst (Dark Transformation): |cff00ff00READY|r")
    end

    frame.doom:SetText("Sudden Doom: |cff00ff00Use the Blizzard proc glow|r")
    frame.power:SetText("Runic Power: |cffaaaaaaUse the Blizzard resource bar|r")
    frame:SetShown(DKAssistDB.enhancements.enabled)
end

function addon:ShowWhatsNew()
    if not DKAssistDB or DKAssistDB.lastSeenVersion == VERSION then return end
    DKAssistDB.lastSeenVersion = VERSION
    local popup = CreateFrame("Frame", "DKAssistWhatsNew", UIParent, "BackdropTemplate")
    popup:SetSize(390, 235)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = {left = 11, right = 12, top = 12, bottom = 11} })
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -24)
    title:SetText("|cff00dd55DK Assist 1.7.0|r — What's New")
    local text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 34, -62)
    text:SetWidth(320)
    text:SetJustifyH("LEFT")
    text:SetText("• Added Blood Death and Decay / Cleaving tracker\n• Optional glow when the Cleaving buff is missing\n• Added Blightfall and Soul Reaper timeline and icon modes\n• Configurable countdown voice, timing, font size and glow\n• Improved layouts, live previews and Midnight 12.1 safety")
    local close = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    close:SetSize(110, 24)
    close:SetPoint("BOTTOM", 0, 20)
    close:SetText("Got it")
    close:SetScript("OnClick", function() popup:Hide() end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        DKAssistDB.enhancements = DKAssistDB.enhancements or { enabled = true }
        addon:CreateCombatTracker()
        addon:UpdateCombatTracker()
        C_Timer.After(3, function() addon:ShowWhatsNew() end)
    elseif unit == "player" and spellID == DARK_TRANSFORMATION then
        burstEndsAt = GetTime() + DARK_TRANSFORMATION_DURATION
        addon:UpdateCombatTracker()
        C_Timer.After(DARK_TRANSFORMATION_DURATION, function() addon:UpdateCombatTracker() end)
    end
end)

local timer = CreateFrame("Frame")
timer:SetScript("OnUpdate", function(_, elapsed)
    if addon.combatTracker and burstEndsAt > GetTime() then addon:UpdateCombatTracker() end
end)
