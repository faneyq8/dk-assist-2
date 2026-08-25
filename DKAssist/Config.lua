-- DK Assist - Configuration Panel
-- Modelled on DC Glows: single spell-selector dropdown switches between
-- Festering Scythe and Putrefy config pages. No scroll. No desc walls.

local addonName, addon = ...
local LCG = LibStub("LibCustomGlow-1.0")

function addon:CreateConfigPanel(standalone)
    local panel = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    panel.name = "DK Assist"
    local framePrefix = standalone and "DKAssistStandalone" or "DKAssist"

    -- The standalone window needs its own solid canvas.  The parent window's
    -- backdrop is not sufficient with some UI replacements, which otherwise
    -- lets the game world show through the settings content.
    if standalone then
        panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        panel:SetBackdropColor(0.008, 0.008, 0.014, 1)
        local panelPattern = panel:CreateTexture(nil, "BACKGROUND", nil, -7)
        panelPattern:SetAllPoints()
        panelPattern:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
        panelPattern:SetVertexColor(0.13, 0.13, 0.18, 0.32)
    end

    -- -------------------------------------------------------
    -- Layout constants
    -- -------------------------------------------------------
    local PADDING       = 16
    local SLIDER_WIDTH  = 200
    local DD_WIDTH      = 150

    -- -------------------------------------------------------
    -- Which feature is being configured.
    -- -------------------------------------------------------
    local selectedKey = "festering"
    local function GetSelectedGlowSettings()
        if selectedKey == "runic" then return DKAssistDB.runicPower end
        if selectedKey == "deathcoil" then return DKAssistDB.spells.deathCoil end
        if selectedKey == "epidemic" then return DKAssistDB.spells.epidemic end
        return DKAssistDB.spells.festeringScythe
    end

    -- Forward-declare so sub-sections can reference it
    local UpdateSliderVisibility
    local UpdatePutrefySubSections
    local previewFrame   -- single shared preview button

    -- -------------------------------------------------------
    -- Title
    -- -------------------------------------------------------
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", PADDING, -PADDING)
    title:SetText("|cffcc0000DK Assist|r")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Unholy Death Knight — Festering Scythe, Putrefy, Death and Decay & Soul Reaper")
    subtitle:SetTextColor(0.65, 0.65, 0.65)

    -- -------------------------------------------------------
    -- Live Preview (top-right, same as DC Glows)
    -- -------------------------------------------------------
    local previewContainer = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    -- Blizzard's AddOns host is narrower than the standalone DK Assist
    -- window.  Keep the same card grid, scaled to the host width.
    local hostLeftWidth = standalone and 356 or 300
    local hostRightWidth = standalone and 388 or 300
    previewContainer:SetSize(hostRightWidth, 220)
    previewContainer:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -70)
    previewContainer:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    previewContainer:SetBackdropColor(0.055, 0.055, 0.065, 0.98)
    previewContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local previewLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    previewLabel:SetPoint("BOTTOM", previewContainer, "TOP", 0, 4)
    previewLabel:SetText("Live Preview")

    previewFrame = CreateFrame("Frame", framePrefix .. "PreviewButton", previewContainer, "BackdropTemplate")
    previewFrame:SetSize(96, 96)
    previewFrame:SetPoint("CENTER")
    previewFrame:SetBackdrop({
        bgFile   = "Interface\\Icons\\Spell_DeathKnight_EmpowerRuneBlade2",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    previewFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Runic Power uses a real status bar in the preview instead of a spell icon.
    local previewRunicBar = CreateFrame("StatusBar", nil, previewContainer, "BackdropTemplate")
    previewRunicBar:SetSize(170, 22)
    previewRunicBar:SetPoint("CENTER")
    previewRunicBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    previewRunicBar:SetStatusBarColor(0.0, 0.72, 1.0, 1)
    previewRunicBar:SetMinMaxValues(0, 100)
    previewRunicBar:SetValue(100)
    previewRunicBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    previewRunicBar:SetBackdropColor(0, 0, 0, 1)
    previewRunicBar:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    previewRunicBar.text = previewRunicBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    previewRunicBar.text:SetPoint("CENTER")
    previewRunicBar.text:SetText("100 Runic Power")
    previewRunicBar:Hide()

    -- Cross textures for Putrefy preview (hidden by default)
    local pCrossH = previewFrame:CreateTexture(nil, "OVERLAY")
    local pCrossV = previewFrame:CreateTexture(nil, "OVERLAY")
    pCrossH:SetColorTexture(1, 0, 0, 0.9)
    pCrossV:SetColorTexture(1, 0, 0, 0.9)
    pCrossH:Hide() pCrossV:Hide()

    local function HidePreviewCross()
        pCrossH:Hide() pCrossV:Hide()
    end

    local function UpdatePreviewCross()
        local s = DKAssistDB.putrefy
        local th = s.crossThickness or 0.25
        local r, g, b, a = s.crossColor.r, s.crossColor.g, s.crossColor.b, s.crossAlpha or 0.9
        pCrossH:SetColorTexture(r, g, b, a)
        pCrossV:SetColorTexture(r, g, b, a)
        pCrossH:ClearAllPoints()
        pCrossH:SetPoint("LEFT",  previewFrame, "LEFT",  0, 0)
        pCrossH:SetPoint("RIGHT", previewFrame, "RIGHT", 0, 0)
        pCrossH:SetHeight(math.max(2, 96 * th))
        pCrossV:ClearAllPoints()
        pCrossV:SetPoint("TOP",    previewFrame, "TOP",    0, 0)
        pCrossV:SetPoint("BOTTOM", previewFrame, "BOTTOM", 0, 0)
        pCrossV:SetWidth(math.max(2, 96 * th))
        pCrossH:Show() pCrossV:Show()
    end

    -- Update preview icon texture when switching spell
    local function UpdatePreviewIcon()
        local iconID
        if selectedKey == "festering" then
            iconID = C_Spell.GetSpellTexture(addon.SPELLS.FESTERING_STRIKE.id)
        elseif selectedKey == "putrefy" then
            iconID = C_Spell.GetSpellTexture(addon.SPELLS.PUTREFY.id)
        elseif selectedKey == "dnd" then
            iconID = addon.SPELLS.DEATH_AND_DECAY.icon
        elseif selectedKey == "soulreaper" then
            iconID = C_Spell.GetSpellTexture(addon.SPELLS.SOUL_REAPER.id)
        elseif selectedKey == "runic" then
            iconID = "Interface\\Icons\\Spell_DeathKnight_BloodPresence"
        elseif selectedKey == "deathcoil" then
            iconID = C_Spell.GetSpellTexture(addon.SPELLS.DEATH_COIL.id)
        elseif selectedKey == "epidemic" then
            iconID = C_Spell.GetSpellTexture(addon.SPELLS.EPIDEMIC.id)
        end
        previewFrame:SetShown(selectedKey ~= "runic")
        previewRunicBar:SetShown(selectedKey == "runic")
        previewFrame:SetBackdrop({
            bgFile   = iconID or "Interface\\Icons\\Spell_DeathKnight_EmpowerRuneBlade2",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        previewFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end

    -- -------------------------------------------------------
    -- Spell selector dropdown  (same position as DCGlows)
    -- -------------------------------------------------------
    local selectorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectorLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -24)
    selectorLabel:SetText("Configure:")

    local selectorDD = CreateFrame("Frame", framePrefix .. "SelectorDD", panel, "UIDropDownMenuTemplate")
    selectorDD:SetPoint("LEFT", selectorLabel, "RIGHT", -8, -2)

    -- -------------------------------------------------------
    -- All controls parented directly to panel (no scroll)
    -- -------------------------------------------------------

    -- Enable checkbox
    local enableCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", selectorLabel, "BOTTOMLEFT", 0, -16)
    enableCheck.Text:SetText("Enable")
    enableCheck:SetScript("OnClick", function(self)
        if selectedKey == "festering" then
            DKAssistDB.spells.festeringScythe.enabled = self:GetChecked()
            addon:RefreshFesteringGlows()
        elseif selectedKey == "deathcoil" then
            DKAssistDB.spells.deathCoil.enabled = self:GetChecked()
            addon:RefreshSuddenDoomGlows()
        elseif selectedKey == "epidemic" then
            DKAssistDB.spells.epidemic.enabled = self:GetChecked()
            addon:RefreshSuddenDoomGlows()
        elseif selectedKey == "runic" then
            DKAssistDB.runicPower.enabled = self:GetChecked()
            addon:UpdateRunicPowerGlow()
        elseif selectedKey == "putrefy" then
            DKAssistDB.putrefy.enabled = self:GetChecked()
            addon:RefreshPutrefyWarnings()
        elseif selectedKey == "dnd" then
            DKAssistDB.dnd.enabled = self:GetChecked()
        end
        panel:UpdatePreview()
    end)

    -- -------------------------------------------------------
    -- FESTERING SCYTHE section widgets
    -- -------------------------------------------------------

    -- Description
    local festeringDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    festeringDesc:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -6)
    festeringDesc:SetWidth(380)
    festeringDesc:SetJustifyH("LEFT")
    festeringDesc:SetText("Glows your Festering Strike/Scythe button when the Festering Scythe buff is about to expire or is missing. Only glows in combat.")
    festeringDesc:SetTextColor(0.65, 0.65, 0.65)

    -- Glow style dropdown
    local glowStyleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    glowStyleLabel:SetPoint("TOPLEFT", festeringDesc, "BOTTOMLEFT", 0, -12)
    glowStyleLabel:SetText("Glow Style:")

    local glowStyleDD = CreateFrame("Frame", framePrefix .. "GlowStyleDD", panel, "UIDropDownMenuTemplate")
    glowStyleDD:SetPoint("LEFT", glowStyleLabel, "RIGHT", -8, -2)

    -- Glow color
    local glowColorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    glowColorLabel:SetPoint("TOPLEFT", glowStyleLabel, "BOTTOMLEFT", 0, -30)
    glowColorLabel:SetText("Glow Color:")

    local glowSwatch = CreateFrame("Button", nil, panel)
    glowSwatch:SetSize(24, 24)
    glowSwatch:SetPoint("LEFT", glowColorLabel, "RIGHT", 8, 0)
    glowSwatch.bg = glowSwatch:CreateTexture(nil, "BACKGROUND")
    glowSwatch.bg:SetAllPoints()
    glowSwatch.bg:SetColorTexture(0, 0, 0, 1)
    glowSwatch.color = glowSwatch:CreateTexture(nil, "ARTWORK")
    glowSwatch.color:SetPoint("TOPLEFT", 2, -2)
    glowSwatch.color:SetPoint("BOTTOMRIGHT", -2, 2)
    glowSwatch.color:SetColorTexture(1, 1, 1, 1)
    local glowColorHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    glowColorHint:SetPoint("LEFT", glowSwatch, "RIGHT", 6, 0)
    glowColorHint:SetText("(click to change)")
    glowColorHint:SetTextColor(0.55, 0.55, 0.55)

    glowSwatch:SetScript("OnClick", function()
        local s = GetSelectedGlowSettings()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = s.color.r, g = s.color.g, b = s.color.b,
            hasOpacity = true, opacity = s.alpha,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                s.color.r = r ; s.color.g = g ; s.color.b = b
                glowSwatch.color:SetColorTexture(r, g, b, 1)
                if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
                panel:UpdatePreview()
            end,
            opacityFunc = function()
                s.alpha = ColorPickerFrame:GetColorAlpha()
                if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
                panel:UpdatePreview()
            end,
            cancelFunc = function(prev)
            s.color.r = prev.r ; s.color.g = prev.g ; s.color.b = prev.b ; s.alpha = prev.a
            glowSwatch.color:SetColorTexture(prev.r, prev.g, prev.b, 1)
            if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
            panel:UpdatePreview()
            end,
        })
    end)

    -- Glow presets
    local glowPresetLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    glowPresetLabel:SetPoint("TOPLEFT", glowColorLabel, "BOTTOMLEFT", 0, -20)
    glowPresetLabel:SetText("Presets:")

    local DK_PRESETS = {
        {name="Unholy Green",  r=0.0, g=0.9, b=0.2},
        {name="Frost Blue",    r=0.4, g=0.8, b=1.0},
        {name="Blood Red",     r=1.0, g=0.2, b=0.2},
        {name="Shadow Purple", r=0.7, g=0.3, b=1.0},
        {name="Gold",          r=1.0, g=0.85,b=0.0},
        {name="White",         r=1.0, g=1.0, b=1.0},
    }
    local glowPresetBtns = {}
    for i, p in ipairs(DK_PRESETS) do
        local btn = CreateFrame("Button", nil, panel)
        btn:SetSize(40, 18)
        btn:SetPoint("LEFT", i==1 and glowPresetLabel or glowPresetBtns[i-1], "RIGHT", i==1 and 8 or 4, 0)
        btn.bg = btn:CreateTexture(nil, "BACKGROUND") ; btn.bg:SetAllPoints() ; btn.bg:SetColorTexture(0.2,0.2,0.2,1)
        btn.color = btn:CreateTexture(nil, "ARTWORK")
        btn.color:SetPoint("TOPLEFT",2,-2) ; btn.color:SetPoint("BOTTOMRIGHT",-2,2)
        btn.color:SetColorTexture(p.r, p.g, p.b, 1)
        btn:SetScript("OnClick", function()
            local s = GetSelectedGlowSettings()
            s.color.r=p.r ; s.color.g=p.g ; s.color.b=p.b
            glowSwatch.color:SetColorTexture(p.r,p.g,p.b,1)
            if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
            panel:UpdatePreview()
        end)
        btn:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP") GameTooltip:SetText(p.name) GameTooltip:Show() end)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        table.insert(glowPresetBtns, btn)
    end

    -- Visual group frames sit behind normal Blizzard controls and make the
    -- two-column layout readable without changing control behavior.
    local function CreateSectionFrame()
        local section = CreateFrame("Frame", nil, panel, "BackdropTemplate")
        section:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        section:SetBackdropColor(0.018, 0.018, 0.024, 0.96)
        section:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
        section:SetFrameLevel(panel:GetFrameLevel())
        return section
    end

    -- A small gold divider on both sides makes section headings read like
    -- the framed WoW UI treatment, without needing additional artwork.
    local function CreateOrnamentTitle(owner, text)
        local title = owner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetText(text)
        local left = owner:CreateTexture(nil, "OVERLAY")
        left:SetTexture("Interface\\Buttons\\WHITE8X8")
        left:SetSize(66, 1)
        left:SetVertexColor(0.75, 0.62, 0.10, 0.75)
        local right = owner:CreateTexture(nil, "OVERLAY")
        right:SetTexture("Interface\\Buttons\\WHITE8X8")
        right:SetSize(66, 1)
        right:SetVertexColor(0.75, 0.62, 0.10, 0.75)
        left:SetPoint("RIGHT", title, "LEFT", -7, 0)
        right:SetPoint("LEFT", title, "RIGHT", 7, 0)
        return title
    end

    local styleSection = CreateSectionFrame()
    styleSection:SetPoint("TOPLEFT", selectorLabel, "TOPLEFT", -12, 20)
    styleSection:SetPoint("BOTTOMRIGHT", glowPresetBtns[#glowPresetBtns], "BOTTOMRIGHT", 14, -14)
    local styleSectionTitle = CreateOrnamentTitle(styleSection, "Glow settings")
    styleSectionTitle:SetPoint("TOP", styleSection, "TOP", 0, -10)

    -- Glow sliders
    local sliderContainer = CreateFrame("Frame", nil, panel)
    sliderContainer:SetPoint("TOPLEFT", glowPresetLabel, "BOTTOMLEFT", 0, -24)
    sliderContainer:SetSize(400, 250)

    -- A dedicated right column keeps style-specific sliders away from the
    -- Festering warnings. Pixel Glow has four sliders and cannot share the
    -- left column without colliding with the target selector/footer.
    local appearanceContainer = CreateFrame("Frame", nil, panel)
    appearanceContainer:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -32, -375)
    appearanceContainer:SetSize(290, 260)
    local appearanceHeader = CreateOrnamentTitle(appearanceContainer, "Pixel Glow appearance")
    appearanceHeader:SetPoint("TOP", appearanceContainer, "TOP", 0, 0)
    local appearanceSection = CreateSectionFrame()
    appearanceSection:SetPoint("TOPLEFT", appearanceContainer, "TOPLEFT", -12, 18)
    appearanceSection:SetSize(314, 266)

    local warningSection = CreateSectionFrame()
    warningSection:SetPoint("TOPLEFT", sliderContainer, "TOPLEFT", -12, 18)
    warningSection:SetSize(405, 168)
    local ghoulSection = CreateSectionFrame()
    ghoulSection:SetSize(405, 68)
    local warningTimingHeader = CreateOrnamentTitle(warningSection, "Warning timing")
    local ghoulReminderHeader = CreateOrnamentTitle(ghoulSection, "Lesser Ghoul reminder")

    local glowSliders = {}
    local sliderSerial = 0

    local function CreateSlider(parent, label, min, max, step, getter, setter, yOff)
        sliderSerial = sliderSerial + 1
        local c = CreateFrame("Frame", nil, parent)
        c:SetSize(SLIDER_WIDTH + 80, 40)
        c:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)

        local lbl = c:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", 0, 0)

        local sl = CreateFrame("Slider", framePrefix .. "Slider"..sliderSerial, c, "OptionsSliderTemplate")
        sl:SetWidth(SLIDER_WIDTH)
        sl:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -4)
        sl:SetMinMaxValues(min, max)
        sl:SetValueStep(step)
        sl:SetObeyStepOnDrag(true)
        sl.Low:SetText(min) ; sl.High:SetText(max)

        local eb = CreateFrame("EditBox", nil, c, "InputBoxTemplate")
        eb:SetSize(46, 20) ; eb:SetPoint("LEFT", sl, "RIGHT", 10, 0) ; eb:SetAutoFocus(false)

        local fmt = step < 1 and "%.2f" or "%d"
        local function Refresh()
            local v = getter()
            if not v then return end
            sl:SetValue(v)
            lbl:SetText(label..": "..string.format(fmt, v))
            eb:SetText(string.format(fmt, v))
        end
        sl:SetScript("OnValueChanged", function(_, v)
            setter(v)
            Refresh()
            if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
            panel:UpdatePreview()
        end)
        eb:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then
                v=math.max(min,math.min(max,v))
                setter(v)
                Refresh()
                if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
                panel:UpdatePreview()
            end
            self:ClearFocus()
        end)

        return {container=c, refresh=Refresh}
    end

    -- Timing slider — always visible, not glow-type dependent
    local gsTiming = CreateSlider(sliderContainer,"Glow when X sec remaining",1,24,1,
        function() return DKAssistDB.spells.festeringScythe.glowTiming end,
        function(v) DKAssistDB.spells.festeringScythe.glowTiming=v end, 0)

    local combatGlowCheck = CreateFrame("CheckButton", nil, sliderContainer, "UICheckButtonTemplate")
    combatGlowCheck.Text:SetText("Glow at combat start")
    combatGlowCheck.Text:SetFontObject("GameFontNormal")
    combatGlowCheck:SetScript("OnClick", function(self)
        DKAssistDB.spells.festeringScythe.combatGlow = self:GetChecked()
        if not self:GetChecked() and addon.CancelFesteringCombatGlow then
            addon:CancelFesteringCombatGlow()
        end
        UpdateSliderVisibility()
    end)
    combatGlowCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Glow at combat start", 1, 1, 1)
        GameTooltip:AddLine("Warn when you enter combat without the Festering Scythe buff.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    combatGlowCheck:SetScript("OnLeave", GameTooltip_Hide)

    local gsGrace = CreateSlider(sliderContainer,"Combat start delay (sec)",0,20,1,
        function() return DKAssistDB.spells.festeringScythe.combatGrace or 0 end,
        function(v) DKAssistDB.spells.festeringScythe.combatGrace=v end, 0)

    local ghoulGlowCheck = CreateFrame("CheckButton", nil, sliderContainer, "UICheckButtonTemplate")
    ghoulGlowCheck.Text:SetText("Also glow when Lesser Ghoul is missing")
    ghoulGlowCheck.Text:SetFontObject("GameFontNormal")
    ghoulGlowCheck:SetScript("OnClick", function(self)
        DKAssistDB.spells.festeringScythe.lesserGhoulGlow = self:GetChecked()
        if self:GetChecked() and addon.RefreshCDMTrackedItems then
            addon:RefreshCDMTrackedItems()
        end
    end)
    ghoulGlowCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Lesser Ghoul reminder", 1, 1, 1)
        GameTooltip:AddLine("Glow in combat whenever the Lesser Ghoul buff is not on you, so you know to rebuild stacks. Requires Lesser Ghoul in the Cooldown Manager, under either Tracked Buffs or Tracked Bars.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    ghoulGlowCheck:SetScript("OnLeave", GameTooltip_Hide)

    local ghoulHint = sliderContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ghoulHint:SetWidth(hostLeftWidth - 32)
    ghoulHint:SetJustifyH("LEFT")
    ghoulHint:SetText("Requires Lesser Ghoul in the Cooldown Manager.")
    ghoulHint:SetTextColor(0.65, 0.65, 0.65)

    local gsSpeed = CreateSlider(appearanceContainer,"Animation Speed",0.05,2.0,0.05,
        function() return GetSelectedGlowSettings().speed end,
        function(v) GetSelectedGlowSettings().speed=v end, -50)
    local gsLines = CreateSlider(appearanceContainer,"Lines / Particles",1,16,1,
        function() return GetSelectedGlowSettings().lines end,
        function(v) GetSelectedGlowSettings().lines=v end, -100)
    local gsThick = CreateSlider(appearanceContainer,"Thickness",1,8,1,
        function() return GetSelectedGlowSettings().thickness end,
        function(v) GetSelectedGlowSettings().thickness=v end, -150)
    local gsAlpha = CreateSlider(appearanceContainer,"Opacity",0.1,1.0,0.05,
        function() return GetSelectedGlowSettings().alpha end,
        function(v) GetSelectedGlowSettings().alpha=v end, -200)

    local rpThreshold = CreateSlider(sliderContainer,"Glow at Runic Power",50,100,1,
        function() return DKAssistDB.runicPower.threshold end,
        function(v) DKAssistDB.runicPower.threshold=v addon:UpdateRunicPowerGlow() end, 0)

    glowSliders = {gsSpeed, gsLines, gsThick, gsAlpha}

    local glowSliderSets = {
        pixel    = {gsSpeed, gsLines, gsThick, gsAlpha},
        autocast = {gsSpeed, gsAlpha},
        button   = {gsSpeed, gsAlpha},
        proc     = {gsAlpha},
    }

    UpdateSliderVisibility = function()
        local gt = GetSelectedGlowSettings().glowType or "pixel"
        local vis = {}
        for _, s in ipairs(glowSliderSets[gt] or glowSliderSets.pixel) do vis[s]=true end
        local y = 0
        local function PlaceSlider(s)
            s.container:Show()
            s.container:ClearAllPoints()
            s.container:SetPoint("TOPLEFT", sliderContainer, "TOPLEFT", 0, y)
            y = y - (selectedKey == "festering" and 44 or 50)
        end
        local appearanceY = -30
        local function PlaceAppearanceSlider(s)
            s.container:Show()
            s.container:ClearAllPoints()
            s.container:SetPoint("TOPLEFT", appearanceContainer, "TOPLEFT", 0, appearanceY)
            appearanceY = appearanceY - 50
        end
        if selectedKey == "festering" then
            rpThreshold.container:Hide()
            warningSection:Show()
            ghoulSection:Show()
            warningTimingHeader:SetText("Warning timing")
            warningTimingHeader:Show()
            warningTimingHeader:ClearAllPoints()
            warningTimingHeader:SetPoint("TOP", warningSection, "TOP", 0, -13)
            -- Keep the controls close to the section heading; the previous
            -- offsets left an unnecessary empty band in the warning card.
            y = -16
            PlaceSlider(gsTiming)
            combatGlowCheck:Show()
            combatGlowCheck:ClearAllPoints()
            combatGlowCheck:SetPoint("TOPLEFT", sliderContainer, "TOPLEFT", 0, y)
            y = y - 26
            if DKAssistDB.spells.festeringScythe.combatGlow ~= false then
                PlaceSlider(gsGrace)
            else
                gsGrace.container:Hide()
            end
            ghoulSection:ClearAllPoints()
            ghoulSection:SetPoint("TOPLEFT", warningSection, "BOTTOMLEFT", 0, -10)
            ghoulReminderHeader:Show()
            ghoulReminderHeader:ClearAllPoints()
            ghoulReminderHeader:SetPoint("TOP", ghoulSection, "TOP", 0, -12)
            ghoulGlowCheck:Show()
            ghoulGlowCheck:ClearAllPoints()
            ghoulGlowCheck:SetPoint("TOPLEFT", ghoulSection, "TOPLEFT", 16, -24)
            ghoulHint:Show()
            ghoulHint:ClearAllPoints()
            ghoulHint:SetPoint("TOPLEFT", ghoulSection, "TOPLEFT", 16, -48)
        elseif selectedKey == "runic" then
            gsTiming.container:Hide()
            warningSection:Show()
            ghoulSection:Hide()
            warningTimingHeader:SetText("Runic Power threshold")
            warningTimingHeader:Show()
            warningTimingHeader:ClearAllPoints()
            warningTimingHeader:SetPoint("TOP", warningSection, "TOP", 0, -13)
            y = -16
            ghoulReminderHeader:Hide()
            combatGlowCheck:Hide()
            ghoulGlowCheck:Hide()
            ghoulHint:Hide()
            gsGrace.container:Hide()
            PlaceSlider(rpThreshold)
        else
            gsTiming.container:Hide()
            rpThreshold.container:Hide()
            warningSection:Hide()
            ghoulSection:Hide()
            warningTimingHeader:Hide()
            ghoulReminderHeader:Hide()
            combatGlowCheck:Hide()
            ghoulGlowCheck:Hide()
            ghoulHint:Hide()
            gsGrace.container:Hide()
        end
        for _, s in ipairs(glowSliders) do
            if vis[s] then PlaceAppearanceSlider(s) else s.container:Hide() end
        end
        sliderContainer:SetHeight(math.max(40, -y))
        appearanceContainer:SetHeight(math.max(40, -appearanceY))
        appearanceSection:SetHeight(math.max(100, -appearanceY + 40))
        local appearanceNames = {
            pixel = "Pixel Glow",
            autocast = "Autocast Shine",
            button = "Button Glow",
            proc = "Proc Border",
        }
        appearanceHeader:SetText((appearanceNames[gt] or "Glow") .. " appearance")
        appearanceHeader:SetShown(next(vis) ~= nil)
        appearanceSection:SetShown(next(vis) ~= nil)
    end

    -- Keep the target selector in a reserved footer row.  The Festering page
    -- has more controls than other pages, so anchoring it to the variable
    -- height slider container made it collide with Rescan/Test.
    local cdmFesteringCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cdmFesteringCheck:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PADDING, 36)
    cdmFesteringCheck.Text:SetText("Use Cooldown Manager (instead of action bars)")
    cdmFesteringCheck.Text:SetFontObject("GameFontHighlightSmall")

    local reloadBtnFestering = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadBtnFestering:SetSize(90, 22)
    reloadBtnFestering:SetText("Reload UI")
    reloadBtnFestering:SetPoint("LEFT", cdmFesteringCheck.Text, "RIGHT", 12, 0)
    reloadBtnFestering:Hide()
    reloadBtnFestering:SetScript("OnClick", function() ReloadUI() end)

    if not StaticPopupDialogs.DKASSIST_RELOAD_FESTERING then
        StaticPopupDialogs.DKASSIST_RELOAD_FESTERING = {
            text = "Reload UI now to apply the Festering Scythe target change?",
            button1 = "Reload UI",
            button2 = CANCEL,
            OnAccept = ReloadUI,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    if not StaticPopupDialogs.DKASSIST_RELOAD_SUDDEN_DOOM then
        StaticPopupDialogs.DKASSIST_RELOAD_SUDDEN_DOOM = {
            text = "Reload UI now to apply the Sudden Doom target change?",
            button1 = "Reload UI",
            button2 = CANCEL,
            OnAccept = ReloadUI,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    cdmFesteringCheck:SetScript("OnClick", function(self)
        if selectedKey == "deathcoil" or selectedKey == "epidemic" then
            addon:StopSuddenDoomGlows()
            DKAssistDB.trackCDMSuddenDoom = self:GetChecked()
            if addon.ClearCDMSuddenDoomOverlays then addon:ClearCDMSuddenDoomOverlays() end
            addon:ScanAllButtons()
            if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
            reloadBtnFestering:Show()
            StaticPopup_Show("DKASSIST_RELOAD_SUDDEN_DOOM")
        else
            DKAssistDB.trackCDMFestering = self:GetChecked()
            addon:StopAll()
            addon:ScanAllButtons()
            if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
            reloadBtnFestering:Show()
            StaticPopup_Show("DKASSIST_RELOAD_FESTERING")
        end
    end)
    cdmFesteringCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Cooldown Manager", 1, 1, 1)
        GameTooltip:AddLine("Checked: glow the Cooldown Manager button. Unchecked: glow your action-bar button.", 1, 0.82, 0, true)
        GameTooltip:AddLine("Click Rescan Bars if the Cooldown Manager button was added after login.", 1, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    cdmFesteringCheck:SetScript("OnLeave", GameTooltip_Hide)

    -- Collect all festering-specific widgets for show/hide
    local festeringWidgets = {
        festeringDesc,
        glowStyleLabel, glowStyleDD,
        glowColorLabel, glowSwatch, glowColorHint, glowPresetLabel,
        sliderContainer, appearanceContainer, styleSection, warningSection,
        ghoulSection, appearanceSection, cdmFesteringCheck,
    }
    for _, b in ipairs(glowPresetBtns) do table.insert(festeringWidgets, b) end

    -- The glow pages use a fixed card layout.  This is intentionally explicit
    -- instead of chaining cards to variable-height controls: every selector
    -- page (Festering, Sudden Doom and Runic Power) gets the same clean grid.
    local function LayoutGlowCards(cardTitle)
        styleSection:ClearAllPoints()
        styleSection:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -70)
        styleSection:SetSize(hostLeftWidth, 220)
        styleSectionTitle:SetText(cardTitle)

        selectorLabel:ClearAllPoints()
        selectorLabel:SetPoint("TOPLEFT", styleSection, "TOPLEFT", 16, -42)
        selectorDD:ClearAllPoints()
        selectorDD:SetPoint("LEFT", selectorLabel, "RIGHT", -8, -2)
        enableCheck:ClearAllPoints()
        enableCheck:SetPoint("TOPLEFT", selectorLabel, "BOTTOMLEFT", 0, -10)
        -- The compact reference layout does not use an in-card description.
        festeringDesc:Hide()
        glowStyleLabel:ClearAllPoints()
        glowStyleLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -12)
        glowStyleDD:ClearAllPoints()
        glowStyleDD:SetPoint("LEFT", glowStyleLabel, "RIGHT", -8, -2)
        glowColorLabel:ClearAllPoints()
        glowColorLabel:SetPoint("TOPLEFT", glowStyleLabel, "BOTTOMLEFT", 0, -30)
        glowPresetLabel:ClearAllPoints()
        glowPresetLabel:SetPoint("TOPLEFT", glowColorLabel, "BOTTOMLEFT", 0, -20)

        warningSection:ClearAllPoints()
        warningSection:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -302)
        warningSection:SetSize(hostLeftWidth, 184)
        ghoulSection:SetSize(hostLeftWidth, 68)
        sliderContainer:ClearAllPoints()
        sliderContainer:SetPoint("TOPLEFT", warningSection, "TOPLEFT", 16, -26)

        appearanceContainer:ClearAllPoints()
        appearanceContainer:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -310)
        appearanceContainer:SetSize(hostRightWidth, 250)
        appearanceSection:ClearAllPoints()
        appearanceSection:SetPoint("TOPLEFT", appearanceContainer, "TOPLEFT", -12, 18)
        appearanceSection:SetSize(hostRightWidth + 24, 256)
    end

    local function LayoutStandardControls()
        styleSection:ClearAllPoints()
        styleSection:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -70)
        styleSection:SetSize(hostLeftWidth, 500)
        styleSection:Show()
        local titles = {
            putrefy = "Putrefy Warning",
            dnd = "Death and Decay Tracker",
            soulreaper = "Soul Reaper",
        }
        styleSectionTitle:SetText(titles[selectedKey] or "DK Assist Settings")
        selectorLabel:ClearAllPoints()
        selectorLabel:SetPoint("TOPLEFT", styleSection, "TOPLEFT", 16, -46)
        selectorDD:ClearAllPoints()
        selectorDD:SetPoint("LEFT", selectorLabel, "RIGHT", -8, -2)
        enableCheck:ClearAllPoints()
        enableCheck:SetPoint("TOPLEFT", selectorLabel, "BOTTOMLEFT", 0, -16)
    end

    -- -------------------------------------------------------
    -- PUTREFY section widgets
    -- -------------------------------------------------------

    -- Description
    local putrefyDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    putrefyDesc:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -6)
    -- Match the active left card width so the description never spills into
    -- the preview column (especially in Blizzard's narrower AddOns panel).
    putrefyDesc:SetWidth(hostLeftWidth - 32)
    putrefyDesc:SetJustifyH("LEFT")
    putrefyDesc:SetText("Shows a warning on your Putrefy button when Dark Transformation has less than 15 seconds remaining on its cooldown, reminding you to hold Putrefy.")
    putrefyDesc:SetTextColor(0.65, 0.65, 0.65)

    -- Warning style dropdown
    local warnStyleLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warnStyleLabel:SetPoint("TOPLEFT", putrefyDesc, "BOTTOMLEFT", 0, -12)
    warnStyleLabel:SetText("Warning Style:")

    local warnStyleDD = CreateFrame("Frame", framePrefix .. "WarnStyleDD", panel, "UIDropDownMenuTemplate")
    warnStyleDD:SetPoint("LEFT", warnStyleLabel, "RIGHT", -8, -2)

    -- Cross color
    local crossColorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    crossColorLabel:SetPoint("TOPLEFT", warnStyleLabel, "BOTTOMLEFT", 0, -30)
    crossColorLabel:SetText("Color:")

    local crossSwatch = CreateFrame("Button", nil, panel)
    crossSwatch:SetSize(24, 24)
    crossSwatch:SetPoint("LEFT", crossColorLabel, "RIGHT", 8, 0)
    crossSwatch.bg = crossSwatch:CreateTexture(nil, "BACKGROUND") ; crossSwatch.bg:SetAllPoints() ; crossSwatch.bg:SetColorTexture(0,0,0,1)
    crossSwatch.color = crossSwatch:CreateTexture(nil, "ARTWORK")
    crossSwatch.color:SetPoint("TOPLEFT",2,-2) ; crossSwatch.color:SetPoint("BOTTOMRIGHT",-2,2)
    crossSwatch.color:SetColorTexture(1,1,1,1)
    local crossColorHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    crossColorHint:SetPoint("LEFT", crossSwatch, "RIGHT", 6, 0)
    crossColorHint:SetText("(click to change)")
    crossColorHint:SetTextColor(0.55,0.55,0.55)

    local function OpenCrossColorPicker()
        local s = DKAssistDB.putrefy
        ColorPickerFrame:SetupColorPickerAndShow({
            r=s.crossColor.r, g=s.crossColor.g, b=s.crossColor.b,
            hasOpacity=true, opacity=s.crossAlpha,
            swatchFunc=function()
                local r,g,b=ColorPickerFrame:GetColorRGB()
                s.crossColor.r=r ; s.crossColor.g=g ; s.crossColor.b=b
                crossSwatch.color:SetColorTexture(r,g,b,1)
                panel:UpdatePreview()
            end,
            opacityFunc=function() s.crossAlpha=ColorPickerFrame:GetColorAlpha() panel:UpdatePreview() end,
            cancelFunc=function(prev)
                s.crossColor.r=prev.r ; s.crossColor.g=prev.g ; s.crossColor.b=prev.b ; s.crossAlpha=prev.a
                crossSwatch.color:SetColorTexture(prev.r,prev.g,prev.b,1)
                panel:UpdatePreview()
            end,
        })
    end
    crossSwatch:SetScript("OnClick", OpenCrossColorPicker)

    -- Cross sliders
    local crossSliderContainer = CreateFrame("Frame", nil, panel)
    crossSliderContainer:SetPoint("TOPLEFT", crossColorLabel, "BOTTOMLEFT", 0, -20)
    crossSliderContainer:SetSize(400, 100)

    local csThick = CreateSlider(crossSliderContainer,"Cross Thickness",0.05,0.50,0.01,
        function() return DKAssistDB.putrefy.crossThickness end,
        function(v) DKAssistDB.putrefy.crossThickness=v end, 0)
    local csAlpha = CreateSlider(crossSliderContainer,"Cross Opacity",0.1,1.0,0.05,
        function() return DKAssistDB.putrefy.crossAlpha end,
        function(v) DKAssistDB.putrefy.crossAlpha=v end, -50)

    -- Glow warning color
    local gwColorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gwColorLabel:SetPoint("TOPLEFT", warnStyleLabel, "BOTTOMLEFT", 0, -30)
    gwColorLabel:SetText("Color:")

    local gwSwatch = CreateFrame("Button", nil, panel)
    gwSwatch:SetSize(24, 24)
    gwSwatch:SetPoint("LEFT", gwColorLabel, "RIGHT", 8, 0)
    gwSwatch.bg = gwSwatch:CreateTexture(nil, "BACKGROUND") ; gwSwatch.bg:SetAllPoints() ; gwSwatch.bg:SetColorTexture(0,0,0,1)
    gwSwatch.color = gwSwatch:CreateTexture(nil, "ARTWORK")
    gwSwatch.color:SetPoint("TOPLEFT",2,-2) ; gwSwatch.color:SetPoint("BOTTOMRIGHT",-2,2)
    gwSwatch.color:SetColorTexture(1,1,1,1)
    local gwColorHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    gwColorHint:SetPoint("LEFT", gwSwatch, "RIGHT", 6, 0)
    gwColorHint:SetText("(click to change)")
    gwColorHint:SetTextColor(0.55,0.55,0.55)

    local function OpenGwColorPicker()
        local s = DKAssistDB.putrefy
        ColorPickerFrame:SetupColorPickerAndShow({
            r=s.glowColor.r, g=s.glowColor.g, b=s.glowColor.b,
            hasOpacity=true, opacity=s.glowAlpha,
            swatchFunc=function()
                local r,g,b=ColorPickerFrame:GetColorRGB()
                s.glowColor.r=r ; s.glowColor.g=g ; s.glowColor.b=b
                gwSwatch.color:SetColorTexture(r,g,b,1)
                panel:UpdatePreview()
            end,
            opacityFunc=function() s.glowAlpha=ColorPickerFrame:GetColorAlpha() panel:UpdatePreview() end,
            cancelFunc=function(prev)
                s.glowColor.r=prev.r ; s.glowColor.g=prev.g ; s.glowColor.b=prev.b ; s.glowAlpha=prev.a
                gwSwatch.color:SetColorTexture(prev.r,prev.g,prev.b,1)
                panel:UpdatePreview()
            end,
        })
    end
    gwSwatch:SetScript("OnClick", OpenGwColorPicker)

    -- Glow warning sliders
    local gwSliderContainer = CreateFrame("Frame", nil, panel)
    gwSliderContainer:SetPoint("TOPLEFT", gwColorLabel, "BOTTOMLEFT", 0, -20)
    gwSliderContainer:SetSize(400, 200)

    local gwSpeed = CreateSlider(gwSliderContainer,"Animation Speed",0.05,2.0,0.05,
        function() return DKAssistDB.putrefy.glowSpeed end,
        function(v) DKAssistDB.putrefy.glowSpeed=v end, 0)
    local gwLines = CreateSlider(gwSliderContainer,"Lines",1,16,1,
        function() return DKAssistDB.putrefy.glowLines end,
        function(v) DKAssistDB.putrefy.glowLines=v end, -50)
    local gwThick = CreateSlider(gwSliderContainer,"Thickness",1,8,1,
        function() return DKAssistDB.putrefy.glowThickness end,
        function(v) DKAssistDB.putrefy.glowThickness=v end, -100)
    local gwAlpha = CreateSlider(gwSliderContainer,"Opacity",0.1,1.0,0.05,
        function() return DKAssistDB.putrefy.glowAlpha end,
        function(v) DKAssistDB.putrefy.glowAlpha=v end, -150)

    -- Cross sub-widgets
    local crossSubWidgets = {
        crossColorLabel, crossSwatch, crossColorHint, crossSliderContainer,
    }
    -- Glow-warning sub-widgets
    local gwSubWidgets = {
        gwColorLabel, gwSwatch, gwColorHint, gwSliderContainer,
    }

    UpdatePutrefySubSections = function()
        local isCross = (DKAssistDB.putrefy.warningType or "cross") == "cross"
        for _, w in ipairs(crossSubWidgets) do if isCross then w:Show() else w:Hide() end end
        for _, w in ipairs(gwSubWidgets)    do if not isCross then w:Show() else w:Hide() end end
        panel:UpdatePreview()
    end

    -- Collect all putrefy-specific top-level widgets
    local cdmPutrefyCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cdmPutrefyCheck:SetPoint("TOPLEFT", gwSliderContainer, "BOTTOMLEFT", 0, -8)
    cdmPutrefyCheck.Text:SetText("Track on Cooldown Manager")
    cdmPutrefyCheck.Text:SetFontObject("GameFontHighlightSmall")

    local reloadBtnPutrefy = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadBtnPutrefy:SetSize(90, 22)
    reloadBtnPutrefy:SetText("Reload UI")
    reloadBtnPutrefy:SetPoint("LEFT", cdmPutrefyCheck.Text, "RIGHT", 12, 0)
    reloadBtnPutrefy:Hide()
    reloadBtnPutrefy:SetScript("OnClick", function() ReloadUI() end)

    cdmPutrefyCheck:SetScript("OnClick", function(self)
        DKAssistDB.trackCDMPutrefy = self:GetChecked()
        -- Switch targets immediately: CDM when checked, normal action bars
        -- when unchecked.  Existing overlays are hidden before rescanning.
        addon:StopAll()
        addon:ScanAllButtons()
        if DKAssistDB.trackCDMPutrefy then
            addon:CreateCDMOverlays()
        end
        addon:ShowPutrefyHoldWarning()
        reloadBtnPutrefy:Hide()
    end)
    cdmPutrefyCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Cooldown Manager", 1, 1, 1)
        GameTooltip:AddLine("Enable if Putrefy is visible in your Cooldown Manager.", 1, 0.82, 0, true)
        GameTooltip:AddLine("Switches immediately between Cooldown Manager and normal action bars.", 1, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    cdmPutrefyCheck:SetScript("OnLeave", GameTooltip_Hide)

    local putrefyWidgets = {
        putrefyDesc,
        warnStyleLabel, warnStyleDD, cdmPutrefyCheck,
    }
    -- sub-widgets will be shown/hidden by UpdatePutrefySubSections

    -- -------------------------------------------------------
    -- DEATH AND DECAY section widgets
    -- -------------------------------------------------------

    -- Size slider
    local dndSizeContainer = CreateFrame("Frame", nil, panel)
    dndSizeContainer:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -16)
    dndSizeContainer:SetSize(400, 50)

    local dndSizeSlider = CreateSlider(dndSizeContainer, "Icon Size", 24, 96, 1,
        function() return DKAssistDB.dnd.size end,
        function(v) DKAssistDB.dnd.size = v ; addon:RefreshDnDTracker() end, 0)

    -- Always show checkbox
    local dndAlwaysShowCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    dndAlwaysShowCheck:SetPoint("TOPLEFT", dndSizeContainer, "BOTTOMLEFT", 0, -12)
    dndAlwaysShowCheck.Text:SetText("Always show")
    dndAlwaysShowCheck:SetScript("OnClick", function(self)
        DKAssistDB.dnd.alwaysShow = self:GetChecked()
        addon:RefreshDnDAlwaysShow()
    end)
    dndAlwaysShowCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Always Show", 1, 1, 1)
        GameTooltip:AddLine("Keep the Death and Decay icon visible at all times. The icon will be desaturated when the timer is not active.", 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    dndAlwaysShowCheck:SetScript("OnLeave", GameTooltip_Hide)

    -- Lock checkbox
    local dndLockCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    dndLockCheck:SetPoint("TOPLEFT", dndAlwaysShowCheck, "BOTTOMLEFT", 0, -4)
    dndLockCheck.Text:SetText("Lock position")
    dndLockCheck:SetScript("OnClick", function(self)
        DKAssistDB.dnd.locked = self:GetChecked()
        addon:RefreshDnDTracker()
    end)

    local dndHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dndHint:SetPoint("TOPLEFT", dndLockCheck, "BOTTOMLEFT", 0, -8)
    dndHint:SetWidth(350)
    dndHint:SetJustifyH("LEFT")
    dndHint:SetText("|cffaaaaaaTip:|r Use Test below to show the tracker, then drag it to your preferred position. Lock it when done.")
    dndHint:SetTextColor(0.6, 0.6, 0.6)

    local dndWidgets = {
        dndSizeContainer, dndAlwaysShowCheck, dndLockCheck, dndHint,
    }

    -- -------------------------------------------------------
    -- SOUL REAPER section widgets
    -- -------------------------------------------------------
    local srLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    srLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -16)
    srLabel:SetText("Suppress execute glow:")

    local srModeDD = CreateFrame("Frame", framePrefix .. "SRModeDD", panel, "UIDropDownMenuTemplate")
    srModeDD:SetPoint("LEFT", srLabel, "RIGHT", -8, -2)

    local srDescription = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    srDescription:SetPoint("TOPLEFT", srLabel, "BOTTOMLEFT", 0, -30)
    srDescription:SetWidth(380)
    srDescription:SetJustifyH("LEFT")
    srDescription:SetTextColor(0.65, 0.65, 0.65)

    local SR_MODE_INFO = {
        off    = "Soul Reaper execute glow will behave normally (Blizzard default).",
        always = "The execute glow on Soul Reaper is completely suppressed at all times.",
    }

    local function UpdateSRDescription()
        local mode = DKAssistDB.soulReaper.suppressMode or "off"
        srDescription:SetText(SR_MODE_INFO[mode] or "")
    end

    local function InitSRModeDD()
        UIDropDownMenu_SetWidth(srModeDD, DD_WIDTH)
        UIDropDownMenu_Initialize(srModeDD, function()
            local items = {
                {text = "Off (default)",    value = "off"},
                {text = "Suppress always",  value = "always"},
            }
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text  = item.text
                info.value = item.value
                info.func  = function(self)
                    DKAssistDB.soulReaper.suppressMode = self.value
                    UIDropDownMenu_SetText(srModeDD, item.text)
                    UpdateSRDescription()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        local mode = DKAssistDB.soulReaper.suppressMode or "off"
        local labels = {off = "Off (default)", always = "Suppress always"}
        UIDropDownMenu_SetText(srModeDD, labels[mode] or "Off (default)")
    end

    local srWidgets = {
        srLabel, srModeDD, srDescription,
    }

    -- -------------------------------------------------------
    -- Bottom buttons (Rescan / Test)
    -- -------------------------------------------------------
    local rescanBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rescanBtn:SetSize(120, 24)
    -- Fixed bottom action row; the Cooldown Manager checkbox has its own row
    -- directly above this one on every settings page.
    rescanBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PADDING, 18)
    rescanBtn:SetText("Rescan Bars")
    rescanBtn:SetScript("OnClick", function()
        addon:ScanAllButtons()
        addon:CreateCDMOverlays()
        if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    end)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(100, 24)
    testBtn:SetPoint("LEFT", rescanBtn, "RIGHT", 8, 0)
    testBtn:SetText("Test")
    local testActive = false

    local minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimapCheck:SetPoint("BOTTOM", previewLabel, "TOP", -80, 14)
    minimapCheck.Text:SetText("Show Minimap Button")
    minimapCheck.Text:SetFontObject("GameFontHighlightSmall")
    if not StaticPopupDialogs.DKASSIST_RELOAD_MINIMAP then
        StaticPopupDialogs.DKASSIST_RELOAD_MINIMAP = {
            text = "Reload UI now to apply the Minimap Button change?",
            button1 = "Reload UI",
            button2 = CANCEL,
            OnAccept = ReloadUI,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    minimapCheck:SetScript("OnClick", function(self)
        if addon.SetMinimapButtonShown then
            addon:SetMinimapButtonShown(self:GetChecked())
        end
        StaticPopup_Show("DKASSIST_RELOAD_MINIMAP")
    end)

    -- -------------------------------------------------------
    -- Show / hide DnD section
    -- -------------------------------------------------------
    local function ShowDnDSection()
        for _, w in ipairs(festeringWidgets) do w:Hide() end
        for _, w in ipairs(putrefyWidgets)   do w:Hide() end
        for _, w in ipairs(crossSubWidgets)  do w:Hide() end
        for _, w in ipairs(gwSubWidgets)     do w:Hide() end
        for _, w in ipairs(dndWidgets)       do w:Show() end
        for _, w in ipairs(srWidgets)        do w:Hide() end
        styleSection:Show()
        rescanBtn:Hide()
        testBtn:Show()
    end

    -- -------------------------------------------------------
    -- Show / hide Soul Reaper section
    -- -------------------------------------------------------
    local function ShowSoulReaperSection()
        for _, w in ipairs(festeringWidgets) do w:Hide() end
        for _, w in ipairs(putrefyWidgets)   do w:Hide() end
        for _, w in ipairs(crossSubWidgets)  do w:Hide() end
        for _, w in ipairs(gwSubWidgets)     do w:Hide() end
        for _, w in ipairs(dndWidgets)       do w:Hide() end
        for _, w in ipairs(srWidgets)        do w:Show() end
        styleSection:Show()
        rescanBtn:Hide()
        testBtn:Hide()
    end

    -- -------------------------------------------------------
    -- DnD floating lock frame (shown during DnD test mode)
    -- -------------------------------------------------------
    local dndTestFrame = CreateFrame("Frame", framePrefix .. "DnDTestFrame", UIParent, "BackdropTemplate")
    dndTestFrame:SetSize(220, 80)
    dndTestFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    dndTestFrame:SetFrameStrata("DIALOG")
    dndTestFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    dndTestFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    dndTestFrame:SetBackdropBorderColor(0.8, 0.0, 0.0, 1)
    dndTestFrame:SetMovable(true)
    dndTestFrame:EnableMouse(true)
    dndTestFrame:RegisterForDrag("LeftButton")
    dndTestFrame:SetScript("OnDragStart", dndTestFrame.StartMoving)
    dndTestFrame:SetScript("OnDragStop", dndTestFrame.StopMovingOrSizing)
    dndTestFrame:Hide()

    local dndTestTitle = dndTestFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dndTestTitle:SetPoint("TOP", dndTestFrame, "TOP", 0, -12)
    dndTestTitle:SetText("|cffcc0000DK Assist|r — Positioning DnD")

    local dndTestHint = dndTestFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dndTestHint:SetPoint("TOP", dndTestTitle, "BOTTOM", 0, -4)
    dndTestHint:SetText("Drag the icon to your preferred position")
    dndTestHint:SetTextColor(0.7, 0.7, 0.7)

    local dndTestLockCheck = CreateFrame("CheckButton", nil, dndTestFrame, "UICheckButtonTemplate")
    dndTestLockCheck:SetPoint("BOTTOM", dndTestFrame, "BOTTOM", -10, 8)
    dndTestLockCheck.Text:SetText("Lock position")
    dndTestLockCheck:SetChecked(false)

    -- Track whether we're in DnD test/positioning mode
    local dndTestModeActive = false

    local function StopDnDTestMode()
        dndTestModeActive = false
        testActive = false
        testBtn:SetText("Test")
        addon:StopDnDTest()
        dndTestFrame:Hide()
        -- Reopen settings on the DnD page
        selectedKey = "dnd"
        if addon.OpenStandaloneSettings then
            addon:OpenStandaloneSettings()
        end
    end

    dndTestLockCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
            DKAssistDB.dnd.locked = true
            addon:RefreshDnDTracker()
            dndLockCheck:SetChecked(true)
            C_Timer.After(0.1, function()
                StopDnDTestMode()
            end)
        end
    end)

    testBtn:SetScript("OnClick", function()
        testActive = not testActive
        if testActive then
            if selectedKey == "festering" then
                addon:TestFesteringGlow()
            elseif selectedKey == "deathcoil" then
                addon:TestSuddenDoomGlow("deathCoil")
            elseif selectedKey == "epidemic" then
                addon:TestSuddenDoomGlow("epidemic")
            elseif selectedKey == "putrefy" then
                addon:TestPutrefyWarning()
            elseif selectedKey == "runic" then
                addon:TestRunicPowerGlow()
            elseif selectedKey == "dnd" then
                DKAssistDB.dnd.locked = false
                dndLockCheck:SetChecked(false)
                addon:TestDnDTracker()
                dndTestLockCheck:SetChecked(false)
                dndTestModeActive = true
                dndTestFrame:Show()
            end
            testBtn:SetText("Stop Test")
        else
            dndTestModeActive = false
            addon:StopAll()
            addon:StopDnDTest()
            addon:StopRunicPowerGlow()
            dndTestFrame:Hide()
            testBtn:SetText("Test")
        end
    end)

    -- -------------------------------------------------------
    -- Show / hide entire feature sections
    -- -------------------------------------------------------
    local function ShowFesteringSection()
        for _, w in ipairs(festeringWidgets) do w:Show() end
        for _, w in ipairs(putrefyWidgets)   do w:Hide() end
        for _, w in ipairs(crossSubWidgets)  do w:Hide() end
        for _, w in ipairs(gwSubWidgets)     do w:Hide() end
        for _, w in ipairs(dndWidgets)       do w:Hide() end
        for _, w in ipairs(srWidgets)        do w:Hide() end
        rescanBtn:Show()
        testBtn:Show()
        UpdateSliderVisibility()
    end

    local function ShowPutrefySection()
        for _, w in ipairs(festeringWidgets) do w:Hide() end
        for _, w in ipairs(putrefyWidgets)   do w:Show() end
        for _, w in ipairs(dndWidgets)       do w:Hide() end
        for _, w in ipairs(srWidgets)        do w:Hide() end
        styleSection:Show()
        cdmPutrefyCheck:ClearAllPoints()
        cdmPutrefyCheck:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PADDING, 46)
        rescanBtn:Show()
        testBtn:Show()
        UpdatePutrefySubSections()
    end

    -- -------------------------------------------------------
    -- Dropdown initializers
    -- -------------------------------------------------------

    local function InitSelectorDD()
        UIDropDownMenu_SetWidth(selectorDD, DD_WIDTH)
        UIDropDownMenu_Initialize(selectorDD, function()
            local items = {
                {text = "Festering Scythe", value = "festering"},
                {text = "Death Coil (Sudden Doom)", value = "deathcoil"},
                {text = "Epidemic (Sudden Doom)", value = "epidemic"},
                {text = "Putrefy",          value = "putrefy"},
                {text = "Runic Power",      value = "runic"},
                {text = "Death and Decay",  value = "dnd"},
                {text = "Soul Reaper",      value = "soulreaper"},
            }
            for _, item in ipairs(items) do
                local itemText, itemValue = item.text, item.value
                local info = UIDropDownMenu_CreateInfo()
                info.text  = itemText
                info.value = itemValue
                info.checked = (selectedKey == itemValue)
                info.func  = function()
                    selectedKey = itemValue
                    UIDropDownMenu_SetText(selectorDD, itemText)
                    UpdatePreviewIcon()
                    panel:RefreshControls()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        local label = selectedKey == "festering" and "Festering Scythe"
                  or selectedKey == "deathcoil" and "Death Coil (Sudden Doom)"
                  or selectedKey == "epidemic" and "Epidemic (Sudden Doom)"
                  or selectedKey == "putrefy" and "Putrefy"
                  or selectedKey == "runic" and "Runic Power"
                  or selectedKey == "dnd" and "Death and Decay"
                  or selectedKey == "soulreaper" and "Soul Reaper"
                  or "Festering Scythe"
        UIDropDownMenu_SetText(selectorDD, label)
    end

    local function InitGlowStyleDD()
        UIDropDownMenu_SetWidth(glowStyleDD, DD_WIDTH)
        UIDropDownMenu_Initialize(glowStyleDD, function()
            for _, gt in ipairs(addon.GLOW_TYPES) do
                local glowID, glowName, glowDescription = gt.id, gt.name, gt.description
                local info = UIDropDownMenu_CreateInfo()
                info.text = glowName ; info.value = glowID
                info.checked = (GetSelectedGlowSettings().glowType == glowID)
                info.tooltipTitle = glowName ; info.tooltipText = glowDescription
                info.func = function()
                    GetSelectedGlowSettings().glowType = glowID
                    if selectedKey == "runic" then addon:UpdateRunicPowerGlow() end
                    if selectedKey == "festering" and addon.RefreshFesteringGlowStyle then
                        addon:RefreshFesteringGlowStyle()
                    end
                    UIDropDownMenu_SetText(glowStyleDD, glowName)
                    UIDropDownMenu_SetSelectedValue(glowStyleDD, glowID)
                    UpdateSliderVisibility()
                    panel:UpdatePreview()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        local cur = addon:GetGlowTypeByID(GetSelectedGlowSettings().glowType)
        UIDropDownMenu_SetText(glowStyleDD, cur and cur.name or "Pixel Glow")
    end

    local function InitWarnStyleDD()
        UIDropDownMenu_SetWidth(warnStyleDD, DD_WIDTH)
        UIDropDownMenu_Initialize(warnStyleDD, function()
            for _, wt in ipairs(addon.PUTREFY_WARNING_TYPES) do
                local warningID, warningName, warningDescription = wt.id, wt.name, wt.description
                local info = UIDropDownMenu_CreateInfo()
                info.text = warningName ; info.value = warningID
                info.checked = (DKAssistDB.putrefy.warningType == warningID)
                info.tooltipTitle = warningName ; info.tooltipText = warningDescription
                info.func = function()
                    DKAssistDB.putrefy.warningType = warningID
                    UIDropDownMenu_SetText(warnStyleDD, warningName)
                    UpdatePutrefySubSections()
                    addon:RefreshPutrefyWarnings()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        local found = addon.PUTREFY_WARNING_TYPE_MAP[DKAssistDB.putrefy.warningType or "cross"]
        UIDropDownMenu_SetText(warnStyleDD, found and found.name or "Red Cross")
    end

    -- -------------------------------------------------------
    -- Preview update
    -- -------------------------------------------------------
    function panel:UpdatePreview()
        -- Stop everything on the preview frame
        for _, gt in ipairs(addon.GLOW_TYPES) do
            if gt.stop then pcall(gt.stop, previewFrame) end
            if gt.stop then pcall(gt.stop, previewRunicBar) end
        end
        if LCG and LCG.PixelGlow_Stop then
            pcall(LCG.PixelGlow_Stop, previewFrame, "DKAssistPreview")
            pcall(LCG.PixelGlow_Stop, previewRunicBar, "DKAssistPreview")
        end
        addon:StopRunicBarGlowFor(previewRunicBar)
        HidePreviewCross()

        if selectedKey == "festering" or selectedKey == "deathcoil" or selectedKey == "epidemic" then
            local s = GetSelectedGlowSettings()
            if s.enabled then
                local gt = addon:GetGlowTypeByID(s.glowType)
                if gt and gt.start then gt.start(previewFrame, s) end
            end
        elseif selectedKey == "runic" then
            local s = GetSelectedGlowSettings()
            if s.enabled then
                local gt = addon:GetGlowTypeByID(s.glowType)
                if s.glowType == "pixel" or s.glowType == "button" then
                    addon:StartRunicBarGlow(previewRunicBar, s)
                elseif gt and gt.start then
                    gt.start(previewRunicBar, s)
                end
            end
        elseif selectedKey == "putrefy" then
            local s = DKAssistDB.putrefy
            if s.enabled then
                if s.warningType == "cross" then
                    UpdatePreviewCross()
                elseif s.warningType == "glow" then
                    if LCG and LCG.PixelGlow_Start then
                        LCG.PixelGlow_Start(previewFrame,
                            {s.glowColor.r, s.glowColor.g, s.glowColor.b, s.glowAlpha},
                            s.glowLines or 8, s.glowSpeed or 0.25, nil,
                            s.glowThickness or 3, 0, 0, false, "DKAssistPreview")
                    end
                end
            end
        end
        -- DnD: no glow/cross preview needed, just the icon is shown
    end

    -- -------------------------------------------------------
    -- RefreshControls — called on show and when selector changes
    -- -------------------------------------------------------
    function panel:RefreshControls()
        local gs = DKAssistDB.spells.festeringScythe
        local ps = DKAssistDB.putrefy
        local ds = DKAssistDB.dnd
        local rs = DKAssistDB.runicPower

        InitSelectorDD()
        minimapCheck:SetChecked(not DKAssistDB.minimapHidden)
        testActive = false ; testBtn:SetText("Test")
        dndTestModeActive = false
        dndTestFrame:Hide()
        addon:StopDnDTest()

        if selectedKey == "festering" then
            LayoutGlowCards("Festering Scythe Warning")
            enableCheck.Text:SetText("Enable glow")
            enableCheck:SetChecked(gs.enabled)
            enableCheck:Show()
            InitGlowStyleDD()
            glowSwatch.color:SetColorTexture(gs.color.r, gs.color.g, gs.color.b, 1)
            gsTiming.refresh()
            gsGrace.refresh()
            combatGlowCheck:SetChecked(gs.combatGlow ~= false)
            ghoulGlowCheck:SetChecked(gs.lesserGhoulGlow or false)
            for _, s in ipairs(glowSliders) do s.refresh() end
            cdmFesteringCheck:SetChecked(DKAssistDB.trackCDMFestering or false)
            festeringDesc:SetText("Glows Festering Strike/Scythe when its warning is ready. Choose action bars or the Cooldown Manager below.")
            ShowFesteringSection()
            festeringDesc:Hide()
        elseif selectedKey == "deathcoil" or selectedKey == "epidemic" then
            LayoutGlowCards(selectedKey == "deathcoil" and "Death Coil Glow" or "Epidemic Glow")
            local s = GetSelectedGlowSettings()
            local name = selectedKey == "deathcoil" and "Death Coil" or "Epidemic"
            enableCheck.Text:SetText("Enable Sudden Doom glow")
            enableCheck:SetChecked(s.enabled)
            enableCheck:Show()
            InitGlowStyleDD()
            glowSwatch.color:SetColorTexture(s.color.r, s.color.g, s.color.b, 1)
            for _, slider in ipairs(glowSliders) do slider.refresh() end
            festeringDesc:SetText("Glows " .. name .. " when Sudden Doom procs. Choose either your action bar or the Cooldown Manager below.")
            ShowFesteringSection()
            festeringDesc:Hide()
            gsTiming.container:Hide()
            cdmFesteringCheck:SetChecked(DKAssistDB.trackCDMSuddenDoom or false)
            cdmFesteringCheck:Show()
        elseif selectedKey == "runic" then
            LayoutGlowCards("Runic Power Warning")
            enableCheck.Text:SetText("Enable Runic Power glow")
            enableCheck:SetChecked(rs.enabled)
            enableCheck:Show()
            festeringDesc:SetText("Glows your Runic Power bar when it reaches the selected cap threshold, helping you avoid overcapping.")
            InitGlowStyleDD()
            glowSwatch.color:SetColorTexture(rs.color.r, rs.color.g, rs.color.b, 1)
            rpThreshold.refresh()
            for _, s in ipairs(glowSliders) do s.refresh() end
            ShowFesteringSection()
            festeringDesc:Hide()
            cdmFesteringCheck:Hide()
        elseif selectedKey == "putrefy" then
            LayoutStandardControls()
            enableCheck.Text:SetText("Enable warning")
            enableCheck:SetChecked(ps.enabled)
            enableCheck:Show()
            InitWarnStyleDD()
            crossSwatch.color:SetColorTexture(ps.crossColor.r, ps.crossColor.g, ps.crossColor.b, 1)
            gwSwatch.color:SetColorTexture(ps.glowColor.r, ps.glowColor.g, ps.glowColor.b, 1)
            csThick.refresh() csAlpha.refresh()
            gwSpeed.refresh() gwLines.refresh() gwThick.refresh() gwAlpha.refresh()
            cdmPutrefyCheck:SetChecked(DKAssistDB.trackCDMPutrefy or false)
            ShowPutrefySection()
        elseif selectedKey == "dnd" then
            LayoutStandardControls()
            enableCheck.Text:SetText("Enable tracker")
            enableCheck:SetChecked(ds.enabled)
            enableCheck:Show()
            dndSizeSlider.refresh()
            dndAlwaysShowCheck:SetChecked(ds.alwaysShow or false)
            dndLockCheck:SetChecked(ds.locked or false)
            ShowDnDSection()
        elseif selectedKey == "soulreaper" then
            LayoutStandardControls()
            enableCheck:Hide()
            InitSRModeDD()
            UpdateSRDescription()
            ShowSoulReaperSection()
        end

        UpdatePreviewIcon()
        self:UpdatePreview()
    end

    -- -------------------------------------------------------
    -- Panel lifecycle
    -- -------------------------------------------------------
    panel:SetScript("OnShow", function(self)
        -- Keep selectedKey if returning from DnD test mode, otherwise default to festering
        if selectedKey ~= "dnd" and selectedKey ~= "putrefy" and selectedKey ~= "soulreaper" and selectedKey ~= "runic" and selectedKey ~= "deathcoil" and selectedKey ~= "epidemic" then
            selectedKey = "festering"
        end
        self:RefreshControls()
    end)

    panel:SetScript("OnHide", function()
        for _, gt in ipairs(addon.GLOW_TYPES) do
            if gt.stop then pcall(gt.stop, previewFrame) end
        end
        if LCG and LCG.PixelGlow_Stop then
            pcall(LCG.PixelGlow_Stop, previewFrame, "DKAssistPreview")
        end
        addon:StopRunicPowerGlow()
        HidePreviewCross()
        -- Don't kill DnD test if we're in positioning mode (settings was minimized on purpose)
        if not dndTestModeActive then
            testActive = false ; testBtn:SetText("Test")
            addon:StopDnDTest()
        end
    end)

    return panel
end
