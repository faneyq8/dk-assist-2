-- DK Assist - compact card-based settings UI
-- This file intentionally replaces the legacy Config.lua panel while keeping
-- every existing saved variable and gameplay callback intact.

local addonName, addon = ...
local LCG = LibStub("LibCustomGlow-1.0")

local PAGE_ITEMS = {
    { text = "Festering Scythe", value = "festering" },
    { text = "Festering Scythe WA-Style", value = "festeringwa" },
    { text = "Sudden Doom", value = "suddendoom" },
    { text = "Sudden Doom WA-Style", value = "suddendoomwa" },
    { text = "Death Coil (Sudden Doom)", value = "deathcoil" },
    { text = "Epidemic (Sudden Doom)", value = "epidemic" },
    { text = "Putrefy", value = "putrefy" },
    { text = "Runic Power", value = "runic" },
    { text = "Death and Decay", value = "dnd" },
    { text = "Soul Reaper", value = "soulreaper" },
    { text = "Death and Decay (Blood)", value = "blooddnd" },
    { text = "Stand In Death and Decay (Blood)", value = "blooddndmissing" },
}

local BLOOD_ONLY_KEYS = { blooddnd = true, blooddndmissing = true }

local UNHOLY_PAGE_ITEMS = {}
for _, item in ipairs(PAGE_ITEMS) do
    if not BLOOD_ONLY_KEYS[item.value] then UNHOLY_PAGE_ITEMS[#UNHOLY_PAGE_ITEMS + 1] = item end
end
local BLOOD_PAGE_ITEMS = {
    { text = "Death and Decay", value = "blooddnd" },
    { text = "Stand In Death and Decay", value = "blooddndmissing" },
}

local PAGE_LABEL = {}
for _, item in ipairs(PAGE_ITEMS) do PAGE_LABEL[item.value] = item.text end

local THEME_ITEMS = {
    { text = "Classic", value = "classic" },
    { text = "Carbon Cyan", value = "carbon" },
    { text = "Graphite Red", value = "graphite" },
    { text = "Obsidian Lime", value = "obsidian" },
    { text = "Frosted Blue", value = "frosted" },
    { text = "Slate Orange", value = "slate" },
    { text = "Unholy Green", value = "unholy" },
}

local STANDALONE_THEMES = {
    carbon = {
        titleCode = "33d6e8", accent = { 0.20, 0.84, 0.91 },
        window = { 0.010, 0.020, 0.024 }, panel = { 0.014, 0.030, 0.035 },
        card = { 0.018, 0.040, 0.047 }, control = { 0.025, 0.080, 0.090 },
        border = { 0.12, 0.43, 0.48 }, text = { 0.78, 0.92, 0.94 }, subtext = { 0.62, 0.74, 0.77 },
    },
    graphite = {
        titleCode = "f0525a", accent = { 0.94, 0.25, 0.30 },
        window = { 0.025, 0.026, 0.029 }, panel = { 0.040, 0.041, 0.045 },
        card = { 0.055, 0.055, 0.060 }, control = { 0.090, 0.075, 0.080 },
        border = { 0.42, 0.17, 0.19 }, text = { 0.92, 0.88, 0.89 }, subtext = { 0.72, 0.68, 0.69 },
    },
    obsidian = {
        titleCode = "97df20", accent = { 0.58, 0.88, 0.12 },
        window = { 0.008, 0.012, 0.009 }, panel = { 0.014, 0.022, 0.016 },
        card = { 0.022, 0.035, 0.025 }, control = { 0.045, 0.075, 0.050 },
        border = { 0.24, 0.42, 0.18 }, text = { 0.86, 0.92, 0.84 }, subtext = { 0.66, 0.74, 0.64 },
    },
    frosted = {
        titleCode = "4da3ff", accent = { 0.30, 0.64, 1.00 },
        window = { 0.012, 0.024, 0.040 }, panel = { 0.018, 0.035, 0.055 },
        card = { 0.018, 0.043, 0.070 }, control = { 0.035, 0.075, 0.105 },
        border = { 0.10, 0.25, 0.40 }, text = { 0.82, 0.90, 1.00 }, subtext = { 0.67, 0.75, 0.84 },
    },
    slate = {
        titleCode = "ff861f", accent = { 1.00, 0.48, 0.08 },
        window = { 0.045, 0.052, 0.057 }, panel = { 0.060, 0.068, 0.074 },
        card = { 0.075, 0.083, 0.090 }, control = { 0.105, 0.105, 0.105 },
        border = { 0.40, 0.28, 0.16 }, text = { 0.92, 0.90, 0.87 }, subtext = { 0.72, 0.70, 0.67 },
    },
    unholy = {
        titleCode = "28e060", accent = { 0.16, 0.88, 0.38 },
        window = { 0.008, 0.022, 0.014 }, panel = { 0.012, 0.038, 0.023 },
        card = { 0.016, 0.052, 0.030 }, control = { 0.025, 0.090, 0.048 },
        border = { 0.10, 0.40, 0.22 }, text = { 0.80, 0.96, 0.85 }, subtext = { 0.62, 0.80, 0.68 },
    },
}

local PRESETS = {
    { 0.00, 0.90, 0.20 },
    { 0.40, 0.80, 1.00 },
    { 1.00, 0.20, 0.20 },
    { 0.70, 0.30, 1.00 },
    { 1.00, 0.85, 0.00 },
    { 1.00, 1.00, 1.00 },
}

local TEXT_FONTS = {
    { text = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
    { text = "Arial Narrow", value = "Fonts\\ARIALN.TTF" },
    { text = "Morpheus", value = "Fonts\\MORPHEUS.TTF" },
    { text = "Skurri", value = "Fonts\\SKURRI.TTF" },
    { text = "2002", value = "Fonts\\2002.TTF" },
}

local TEXT_OUTLINES = {
    { text = "No Outline", value = "" },
    { text = "Thin Outline", value = "OUTLINE" },
    { text = "Thick Outline", value = "THICKOUTLINE" },
}

local function GetSpellTextureSafe(spellID, fallback)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and texture then return texture end
    end
    return fallback or "Interface\\Icons\\Spell_DeathKnight_EmpowerRuneBlade2"
end

local function CreateCard(parent, titleText)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    card:SetBackdropColor(0.012, 0.012, 0.018, 0.98)
    card:SetBackdropBorderColor(0.25, 0.25, 0.27, 1)

    local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", card, "TOP", 0, -9)
    title:SetText(titleText)
    card.title = title

    local left = card:CreateTexture(nil, "OVERLAY")
    left:SetTexture("Interface\\Buttons\\WHITE8X8")
    left:SetHeight(1)
    -- Keep the ornamental dividers inside narrow cards, including the long
    -- Text Alert titles.
    left:SetWidth(40)
    left:SetVertexColor(0.68, 0.55, 0.10, 0.75)
    left:SetPoint("RIGHT", title, "LEFT", -7, 0)
    card.leftDivider = left
    local right = card:CreateTexture(nil, "OVERLAY")
    right:SetTexture("Interface\\Buttons\\WHITE8X8")
    right:SetHeight(1)
    right:SetWidth(40)
    right:SetVertexColor(0.68, 0.55, 0.10, 0.75)
    right:SetPoint("LEFT", title, "RIGHT", 7, 0)
    card.rightDivider = right
    return card
end

local function CreateText(parent, text, x, y, fontObject, width, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetJustifyH("LEFT")
    if width then fs:SetWidth(width) end
    fs:SetText(text or "")
    if color then fs:SetTextColor(color[1], color[2], color[3], color[4] or 1) end
    return fs
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check.Text:SetText(text)
    check.Text:SetFontObject("GameFontNormal")
    check:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
    end)
    check.refresh = function() check:SetChecked(getter() and true or false) end
    return check
end

local dropdownSerial = 0
local activeStandalonePanel

local function AttachModernDropdown(dd, parent, width, itemsProvider, currentProvider, setter)
    if not activeStandalonePanel then return end
    local panel = activeStandalonePanel
    panel.dkassistModernDropdowns = panel.dkassistModernDropdowns or {}

    local modern = CreateFrame("Button", nil, parent, "BackdropTemplate")
    modern:SetSize(width + 28, 25)
    modern:SetPoint("TOPLEFT", dd, "TOPLEFT", 17, -3)
    modern:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    modern:SetBackdropColor(0.035, 0.075, 0.105, 1)
    modern:SetBackdropBorderColor(0.20, 0.36, 0.48, 1)
    modern:Hide()

    modern.label = modern:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modern.label:SetPoint("LEFT", modern, "LEFT", 10, 0)
    modern.label:SetPoint("RIGHT", modern, "RIGHT", -25, 0)
    modern.label:SetJustifyH("LEFT")
    modern.arrow = modern:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    modern.arrow:SetPoint("RIGHT", modern, "RIGHT", -8, 1)
    modern.arrow:SetText("v")
    modern.arrow:SetTextColor(0.42, 0.69, 0.86, 1)

    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetClampedToScreen(true)
    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(0.025, 0.065, 0.090, 0.99)
    menu:SetBackdropBorderColor(0.18, 0.55, 0.68, 1)
    menu:SetPoint("TOPLEFT", modern, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(width + 28)
    menu:Hide()
    modern.menu = menu
    modern.rows = {}

    local function CloseMenu()
        menu:Hide()
        modern.arrow:SetText("v")
    end

    local function RefreshRows()
        local items = itemsProvider()
        local current = currentProvider()
        local palette = modern.palette or STANDALONE_THEMES.frosted
        local rowHeight = 22
        menu:SetHeight(math.max(8, (#items * rowHeight) + 6))
        for index, item in ipairs(items) do
            local itemValue = item.value
            local itemText = item.text
            local row = modern.rows[index]
            if not row then
                row = CreateFrame("Button", nil, menu, "BackdropTemplate")
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - ((index - 1) * rowHeight))
                row:SetPoint("RIGHT", menu, "RIGHT", -3, 0)
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                row.text:SetPoint("LEFT", row, "LEFT", 10, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row.text:SetJustifyH("LEFT")
                row:SetScript("OnEnter", function(self)
                    local p = modern.palette or STANDALONE_THEMES.frosted
                    self:SetBackdropColor(p.accent[1] * 0.20, p.accent[2] * 0.20, p.accent[3] * 0.20, 1)
                end)
                row:SetScript("OnLeave", function(self)
                    local p = modern.palette or STANDALONE_THEMES.frosted
                    self:SetBackdropColor(self.selected and p.accent[1] * 0.14 or 0,
                        self.selected and p.accent[2] * 0.14 or 0,
                        self.selected and p.accent[3] * 0.14 or 0, self.selected and 1 or 0)
                end)
                modern.rows[index] = row
            end
            row.selected = current == itemValue
            row.text:SetText(itemText)
            row.text:SetTextColor(row.selected and palette.accent[1] or palette.text[1],
                row.selected and palette.accent[2] or palette.text[2],
                row.selected and palette.accent[3] or palette.text[3], 1)
            row:SetBackdropColor(row.selected and palette.accent[1] * 0.14 or 0,
                row.selected and palette.accent[2] * 0.14 or 0,
                row.selected and palette.accent[3] * 0.14 or 0, row.selected and 1 or 0)
            row:SetScript("OnClick", function()
                setter(itemValue)
                UIDropDownMenu_SetText(dd, itemText)
                UIDropDownMenu_SetSelectedValue(dd, itemValue)
                modern.label:SetText(itemText)
                CloseMenu()
            end)
            row:Show()
        end
        for index = #items + 1, #modern.rows do modern.rows[index]:Hide() end
    end

    modern:SetScript("OnClick", function()
        if menu:IsShown() then
            CloseMenu()
        else
            for _, other in ipairs(panel.dkassistModernDropdowns) do
                if other ~= modern and other.menu then other.menu:Hide() end
            end
            RefreshRows()
            menu:Show()
            modern.arrow:SetText("^")
        end
    end)
    modern:SetScript("OnEnter", function(self)
        local p = modern.palette or STANDALONE_THEMES.frosted
        self:SetBackdropBorderColor(p.accent[1], p.accent[2], p.accent[3], 1)
    end)
    modern:SetScript("OnLeave", function(self)
        local p = modern.palette or STANDALONE_THEMES.frosted
        self:SetBackdropBorderColor(p.border[1], p.border[2], p.border[3], 1)
    end)

    modern.refresh = function()
        local current = currentProvider()
        local label = current
        for _, item in ipairs(itemsProvider()) do
            if item.value == current then label = item.text break end
        end
        modern.label:SetText(label or "")
        if menu:IsShown() then RefreshRows() end
    end
    modern.SetModernMode = function(_, enabled, palette)
        CloseMenu()
        if palette then
            modern.palette = palette
            modern:SetBackdropColor(palette.control[1], palette.control[2], palette.control[3], 1)
            modern:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], 1)
            modern.label:SetTextColor(palette.text[1], palette.text[2], palette.text[3], 1)
            modern.arrow:SetTextColor(palette.accent[1], palette.accent[2], palette.accent[3], 1)
            menu:SetBackdropColor(palette.control[1] * 0.72, palette.control[2] * 0.72, palette.control[3] * 0.72, 0.99)
            menu:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], 1)
        end
        dd:SetShown(not enabled)
        modern:SetShown(enabled)
        if enabled then modern.refresh() end
    end
    dd.dkassistModern = modern
    table.insert(panel.dkassistModernDropdowns, modern)
end

local function CreateDropdown(parent, x, y, width, itemsProvider, currentProvider, setter)
    dropdownSerial = dropdownSerial + 1
    local dd = CreateFrame("Frame", "DKAssistV2Dropdown" .. dropdownSerial, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    UIDropDownMenu_SetWidth(dd, width)
    local function Init()
        UIDropDownMenu_Initialize(dd, function()
            local current = currentProvider()
            for _, item in ipairs(itemsProvider()) do
                local value, text = item.value, item.text
                local info = UIDropDownMenu_CreateInfo()
                info.text = text
                info.value = value
                info.checked = current == value
                info.func = function()
                    setter(value)
                    UIDropDownMenu_SetText(dd, text)
                    UIDropDownMenu_SetSelectedValue(dd, value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
    end
    dd.refresh = function()
        Init()
        local current = currentProvider()
        local label = current
        for _, item in ipairs(itemsProvider()) do
            if item.value == current then label = item.text break end
        end
        UIDropDownMenu_SetText(dd, label or "")
        UIDropDownMenu_SetSelectedValue(dd, current)
        if dd.dkassistModern then dd.dkassistModern.refresh() end
    end
    AttachModernDropdown(dd, parent, width, itemsProvider, currentProvider, setter)
    return dd
end

local sliderSerial = 0
local function CreateSlider(parent, labelText, x, y, width, minValue, maxValue, step, getter, setter)
    sliderSerial = sliderSerial + 1
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    holder:SetSize(width + 62, 42)
    local label = CreateText(holder, "", 0, 0, "GameFontNormal")
    local slider = CreateFrame("Slider", "DKAssistV2Slider" .. sliderSerial, holder, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    slider:SetWidth(width)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(minValue)
    slider.High:SetText(maxValue)
    local edit = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    edit:SetSize(45, 20)
    edit:SetPoint("LEFT", slider, "RIGHT", 9, 0)
    edit:SetAutoFocus(false)
    local format = step < 1 and "%.2f" or "%d"
    local refreshing = false
    holder.refresh = function()
        local value = getter()
        if value == nil then return end
        refreshing = true
        slider:SetValue(value)
        label:SetText(labelText .. ": " .. string.format(format, value))
        edit:SetText(string.format(format, value))
        refreshing = false
    end
    slider:SetScript("OnValueChanged", function(_, value)
        if refreshing then return end
        setter(value)
        holder.refresh()
    end)
    edit:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.max(minValue, math.min(maxValue, value))
            setter(value)
        end
        self:ClearFocus()
        holder.refresh()
    end)
    return holder
end

local function CreateColorControl(parent, x, y, labelText, colorProvider, changed)
    local label = CreateText(parent, labelText, x, y, "GameFontNormal")
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(25, 25)
    swatch:SetPoint("LEFT", label, "RIGHT", 8, 0)
    swatch.bg = swatch:CreateTexture(nil, "BACKGROUND")
    swatch.bg:SetAllPoints()
    swatch.bg:SetColorTexture(0.2, 0.2, 0.2, 1)
    swatch.color = swatch:CreateTexture(nil, "ARTWORK")
    swatch.color:SetPoint("TOPLEFT", 2, -2)
    swatch.color:SetPoint("BOTTOMRIGHT", -2, 2)
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    hint:SetText("(click to change)")
    hint:SetTextColor(0.6, 0.6, 0.6)
    swatch.refresh = function()
        local color = colorProvider()
        swatch.color:SetColorTexture(color.r, color.g, color.b, 1)
    end
    swatch:SetScript("OnClick", function()
        local color = colorProvider()
        ColorPickerFrame:SetupColorPickerAndShow({
            r = color.r, g = color.g, b = color.b,
            swatchFunc = function()
                color.r, color.g, color.b = ColorPickerFrame:GetColorRGB()
                swatch.refresh()
                changed()
            end,
            cancelFunc = function(previous)
                color.r, color.g, color.b = previous.r, previous.g, previous.b
                swatch.refresh()
                changed()
            end,
        })
    end)
    return swatch
end

local function CreateEditControl(parent, labelText, x, y, width, getter, setter)
    local label = CreateText(parent, labelText, x, y, "GameFontNormal")
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 22)
    edit:SetPoint("LEFT", label, "RIGHT", 8, 0)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEnterPressed", function(self)
        setter(self:GetText())
        self:ClearFocus()
    end)
    edit:SetScript("OnEditFocusLost", function(self) setter(self:GetText()) end)
    edit.refresh = function() edit:SetText(getter() or "") end
    return edit
end

local function CreatePresetRow(parent, x, y, settingsProvider, changed)
    local label = CreateText(parent, "Presets:", x, y, "GameFontNormal")
    local buttons = {}
    for index, preset in ipairs(PRESETS) do
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(34, 18)
        if index == 1 then
            button:SetPoint("LEFT", label, "RIGHT", 8, 0)
        else
            button:SetPoint("LEFT", buttons[index - 1], "RIGHT", 4, 0)
        end
        local border = button:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        border:SetColorTexture(0.35, 0.35, 0.35, 1)
        local fill = button:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", -2, 2)
        fill:SetColorTexture(preset[1], preset[2], preset[3], 1)
        button:SetScript("OnClick", function()
            local settings = settingsProvider()
            settings.color.r, settings.color.g, settings.color.b = preset[1], preset[2], preset[3]
            changed()
        end)
        buttons[index] = button
    end
    return buttons
end

function addon:CreateConfigPanel(standalone)
    local panel = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    activeStandalonePanel = standalone and panel or nil
    panel.name = "DK Assist"
    local prefix = standalone and "DKAssistStandaloneV2" or "DKAssistSettingsV2"
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    panel:SetBackdropColor(0.008, 0.008, 0.012, standalone and 1 or 0)

    local title = CreateText(panel, "|cffcc0000DK Assist|r", 16, -14, "GameFontNormalLarge")
    local subtitle = CreateText(panel,
        "Death Knight alerts - Unholy combat tools and Blood Death and Decay reminder",
        16, -36, "GameFontHighlightSmall", nil, { 0.67, 0.67, 0.67 })
    panel.dkassistTitle = title
    panel.dkassistSubtitle = subtitle

    local selectedKey = "festering"
    local pages = {}
    local activePage
    local testActive = false

    local function ActiveConfigSpec()
        local view = DKAssistDB.configSpecView or "auto"
        if view == "blood" or view == "unholy" then return view end
        return addon:IsBloodSpec() and "blood" or "unholy"
    end

    local function ConfigPageItems()
        return ActiveConfigSpec() == "blood" and BLOOD_PAGE_ITEMS or UNHOLY_PAGE_ITEMS
    end

    -- Auto follows the character's live specialization when the panel is
    -- first created instead of retaining the Unholy default page.
    if ActiveConfigSpec() == "blood" then selectedKey = "blooddnd" end

    if not StaticPopupDialogs.DKASSIST_V2_RELOAD_MINIMAP then
        StaticPopupDialogs.DKASSIST_V2_RELOAD_MINIMAP = {
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

    local minimapCheck = CreateCheck(panel, "Show Minimap Button", 0, -14,
        function() return not DKAssistDB.minimapHidden end,
        function(enabled)
            if addon.SetMinimapButtonShown then addon:SetMinimapButtonShown(enabled) end
            StaticPopup_Show("DKASSIST_V2_RELOAD_MINIMAP")
        end)
    minimapCheck:ClearAllPoints()
    minimapCheck:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -170, -12)
    minimapCheck.Text:SetFontObject("GameFontHighlightSmall")

    -- The theme selector belongs only to the dedicated minimap window.  The
    -- embedded Blizzard Settings canvas remains completely untouched.
    local themeLabel, themeDropdown
    if standalone then
        themeLabel = CreateText(panel, "Theme:", 0, -16, "GameFontHighlightSmall")
        themeLabel:ClearAllPoints()
        themeLabel:SetPoint("LEFT", title, "RIGHT", 18, 0)
        themeDropdown = CreateDropdown(panel, 0, 0, 112,
            function() return THEME_ITEMS end,
            function() return DKAssistDB.standaloneTheme or "classic" end,
            function(value)
                DKAssistDB.standaloneTheme = value
                panel:ApplyStandaloneTheme(value)
            end)
        themeDropdown:ClearAllPoints()
        themeDropdown:SetPoint("LEFT", themeLabel, "RIGHT", -9, 0)
        panel.dkassistThemeLabel = themeLabel
        panel.dkassistThemeDropdown = themeDropdown
    end


    local specLabel = CreateText(panel, "Spec:", 0, -16, "GameFontHighlightSmall")
    specLabel:ClearAllPoints()
    specLabel:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -355, -18)
    local specDropdown = CreateDropdown(panel, 0, 0, 118,
        function()
            local active = addon:IsBloodSpec() and "Blood" or "Unholy"
            return {
                { text = "Auto (" .. active .. ")", value = "auto" },
                { text = "Unholy", value = "unholy" },
                { text = "Blood", value = "blood" },
            }
        end,
        function() return DKAssistDB.configSpecView or "auto" end,
        function(value)
            DKAssistDB.configSpecView = value
            panel:ShowPage(ActiveConfigSpec() == "blood" and "blooddnd" or "festering")
        end)
    specDropdown:ClearAllPoints()
    specDropdown:SetPoint("LEFT", specLabel, "RIGHT", -6, 0)
    panel.dkassistSpecLabel = specLabel
    panel.dkassistSpecDropdown = specDropdown

    local pageHolder = CreateFrame("Frame", nil, panel)
    pageHolder:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -58)
    pageHolder:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 82)

    local rescanButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rescanButton:SetSize(120, 24)
    rescanButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 17)
    rescanButton:SetText("Rescan Bars")
    rescanButton:SetScript("OnClick", function()
        addon:ScanAllButtons()
        addon:CreateCDMOverlays()
        if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
    end)

    local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testButton:SetSize(105, 24)
    testButton:SetPoint("LEFT", rescanButton, "RIGHT", 8, 0)
    testButton:SetText("Test")

    local cdmCheck = CreateCheck(panel, "Use Cooldown Manager (instead of action bars)", 16, -16,
        function()
            if selectedKey == "festering" then return DKAssistDB.trackCDMFestering end
            if selectedKey == "putrefy" then return DKAssistDB.trackCDMPutrefy end
            if selectedKey == "suddendoom" or selectedKey == "deathcoil" or selectedKey == "epidemic" then return DKAssistDB.trackCDMSuddenDoom end
            return false
        end,
        function(enabled)
            if selectedKey == "festering" then DKAssistDB.trackCDMFestering = enabled
            elseif selectedKey == "putrefy" then DKAssistDB.trackCDMPutrefy = enabled
            elseif selectedKey == "suddendoom" or selectedKey == "deathcoil" or selectedKey == "epidemic" then DKAssistDB.trackCDMSuddenDoom = enabled end
            addon:StopAll()
            addon:ScanAllButtons()
            if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
        end)
    cdmCheck:ClearAllPoints()
    cdmCheck:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -310, 43)
    cdmCheck.Text:SetFontObject("GameFontHighlightSmall")

    local function StopPreview(page)
        if not page then return end
        for _, glowType in ipairs(addon.GLOW_TYPES or {}) do
            if glowType.stop then
                if page.previewIcon then pcall(glowType.stop, page.previewIcon) end
                if page.previewBar then pcall(glowType.stop, page.previewBar) end
            end
        end
        if page.crossH then page.crossH:Hide() end
        if page.crossV then page.crossV:Hide() end
    end

    local function RefreshTracking()
        if selectedKey == "festering" and addon.RefreshFesteringGlows then addon:RefreshFesteringGlows() end
        if (selectedKey == "deathcoil" or selectedKey == "epidemic") and addon.RefreshSuddenDoomGlows then addon:RefreshSuddenDoomGlows() end
        if selectedKey == "suddendoom" and addon.RefreshSuddenDoomGlows then addon:RefreshSuddenDoomGlows() end
        if selectedKey == "putrefy" and addon.RefreshPutrefyWarnings then addon:RefreshPutrefyWarnings() end
        if selectedKey == "runic" and addon.UpdateRunicPowerGlow then addon:UpdateRunicPowerGlow() end
        if selectedKey == "blooddnd" and addon.RefreshBloodDnDReminder then addon:RefreshBloodDnDReminder() end
        if selectedKey == "blooddndmissing" and addon.RefreshDnDMissingGlows then addon:RefreshDnDMissingGlows() end
        if selectedKey == "bloodbone" and addon.RefreshBloodBoneReminder then addon:RefreshBloodBoneReminder() end
    end

    local function RefreshPreview(page)
        StopPreview(page)
        if not page then return end
        if page.previewIcon then page.previewIcon:Show() end
        if page.previewBar then page.previewBar:Hide() end
        if selectedKey == "putrefy" then
            local settings = DKAssistDB.putrefy
            if settings.warningType == "cross" and settings.enabled then
                page.crossH:SetColorTexture(settings.crossColor.r, settings.crossColor.g, settings.crossColor.b, settings.crossAlpha)
                page.crossV:SetColorTexture(settings.crossColor.r, settings.crossColor.g, settings.crossColor.b, settings.crossAlpha)
                page.crossH:SetHeight(math.max(2, 88 * settings.crossThickness))
                page.crossV:SetWidth(math.max(2, 88 * settings.crossThickness))
                page.crossH:Show(); page.crossV:Show()
            elseif settings.enabled and LCG and LCG.PixelGlow_Start then
                LCG.PixelGlow_Start(page.previewIcon,
                    { settings.glowColor.r, settings.glowColor.g, settings.glowColor.b, settings.glowAlpha },
                    settings.glowLines, settings.glowSpeed, nil, settings.glowThickness, 0, 0, false, "DKAssist")
            end
            return
        end
        local settings
        if selectedKey == "festering" then settings = DKAssistDB.spells.festeringScythe
        elseif selectedKey == "deathcoil" then settings = DKAssistDB.spells.deathCoil
        elseif selectedKey == "epidemic" then settings = DKAssistDB.spells.epidemic
        elseif selectedKey == "suddendoom" then settings = DKAssistDB.suddenDoomGlow
        elseif selectedKey == "runic" then settings = DKAssistDB.runicPower end
        if selectedKey == "blooddnd" then settings = DKAssistDB.bloodDnd end
        if selectedKey == "blooddndmissing" then settings = DKAssistDB.bloodDndMissing end
        if selectedKey == "bloodbone" then settings = DKAssistDB.bloodBone end
        if not settings or not settings.enabled then return end
        local target = page.previewIcon
        if selectedKey == "runic" then
            page.previewIcon:Hide()
            page.previewBar:Show()
            target = page.previewBar
        end
        local glowType = addon:GetGlowTypeByID(settings.glowType)
        if glowType and glowType.start then pcall(glowType.start, target, settings) end
    end

    local function CreatePreview(card, spellID, isRunic)
        local icon = CreateFrame("Frame", nil, card, "BackdropTemplate")
        icon:SetSize(88, 88)
        icon:SetPoint("CENTER", card, "CENTER", 0, -7)
        icon:SetBackdrop({
            bgFile = GetSpellTextureSafe(spellID),
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        icon:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        local bar = CreateFrame("StatusBar", nil, card, "BackdropTemplate")
        bar:SetSize(170, 22)
        bar:SetPoint("CENTER", card, "CENTER", 0, -7)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(0, 0.72, 1, 1)
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(100)
        bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        bar:SetBackdropColor(0, 0, 0, 1)
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        bar.text:SetPoint("CENTER")
        bar.text:SetText("100 Runic Power")
        bar:SetShown(isRunic)
        icon:SetShown(not isRunic)
        return icon, bar
    end

    local function AddSelector(page, card, fieldName)
        local selectorLabel = CreateText(card, "Configure:", 14, -38, "GameFontNormal")
        local selector = CreateDropdown(card, 0, 0, 148,
            function() return ConfigPageItems() end,
            function() return selectedKey end,
            function(value) panel:ShowPage(value) end)
        selector:ClearAllPoints()
        selector:SetPoint("LEFT", selectorLabel, "RIGHT", -8, -2)
        page[fieldName or "selector"] = selector
    end

    local function GlowSettingsFor(key)
        if key == "festering" then return DKAssistDB.spells.festeringScythe end
        if key == "deathcoil" then return DKAssistDB.spells.deathCoil end
        if key == "epidemic" then return DKAssistDB.spells.epidemic end
        if key == "suddendoom" then return DKAssistDB.suddenDoomGlow end
        if key == "blooddnd" then return DKAssistDB.bloodDnd end
        if key == "blooddndmissing" then return DKAssistDB.bloodDndMissing end
        if key == "bloodbone" then return DKAssistDB.bloodBone end
        return DKAssistDB.runicPower
    end

    local function BuildAppearance(page, card, key)
        page.appearanceControls = {}
        -- Leave enough room for the numeric edit box on the right.  The same
        -- page is used both standalone and inside Blizzard's narrower AddOns
        -- settings panel, so wide sliders can otherwise escape the card.
        local appearanceWidth = (key == "festering" or key == "runic") and 190 or 250
        local function settings() return GlowSettingsFor(key) end
        local function changed()
            RefreshTracking(); RefreshPreview(page)
        end
        local controls = {
            speed = CreateSlider(card, "Animation Speed", 14, -38, appearanceWidth, 0.05, 2, 0.05,
                function() return settings().speed end, function(v) settings().speed = v; changed() end),
            lines = CreateSlider(card, "Lines / Particles", 14, -88, appearanceWidth, 1, 16, 1,
                function() return settings().lines end, function(v) settings().lines = v; changed() end),
            thickness = CreateSlider(card, "Thickness", 14, -138, appearanceWidth, 1, 8, 1,
                function() return settings().thickness end, function(v) settings().thickness = v; changed() end),
            alpha = CreateSlider(card, "Opacity", 14, -188, appearanceWidth, 0.1, 1, 0.05,
                function() return settings().alpha end, function(v) settings().alpha = v; changed() end),
        }
        page.appearanceControls = controls
        page.refreshAppearance = function()
            local glowType = settings().glowType or "pixel"
            local visible = glowType == "pixel" and { "speed", "lines", "thickness", "alpha" }
                or (glowType == "autocast" or glowType == "button") and { "speed", "alpha" }
                or { "alpha" }
            local y = -38
            for _, control in pairs(controls) do control:Hide() end
            for _, name in ipairs(visible) do
                local control = controls[name]
                control:ClearAllPoints()
                control:SetPoint("TOPLEFT", card, "TOPLEFT", 14, y)
                control:Show(); control.refresh()
                y = y - 50
            end
            local glowName = addon:GetGlowTypeByID(glowType).name
            card.title:SetText(glowName .. " appearance")
        end
    end

    local function BuildGlowPage(key, titleText, spellID)
        local page = CreateFrame("Frame", nil, pageHolder)
        page:SetAllPoints()
        page.layoutKind = key == "festering" and "festering" or (key == "blooddnd" and "blooddnd" or "glow")
        page.settingsCard = CreateCard(page, titleText)
        page.previewCard = CreateCard(page, "Live Preview")
        page.appearanceCard = CreateCard(page, "Pixel Glow appearance")
        if key == "festering" or key == "deathcoil" or key == "epidemic" then
            page.warningCard = CreateCard(page, "Warning timing")
            page.ghoulCard = CreateCard(page, "Lesser Ghoul reminder")
        elseif key == "blooddnd" then
            page.warningCard = CreateCard(page, "Death and Decay Timer")
        end
        -- The three proc pages can show either the existing button glow
        -- configuration or a separate movable text alert.  They are separate
        -- toggles, so both visual cues may be enabled at the same time.
        if key == "festering" then
            page.hasTextAlerts = true
            page.glowCards = { page.settingsCard, page.previewCard, page.appearanceCard, page.warningCard, page.ghoulCard }
            page.textSettingsCard = CreateCard(page, "Festering Scythe WA-Style")
            page.textPreviewCard = CreateCard(page, "Text Alert Preview")

            local function textSettings()
                local spellKey = key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic")
                return DKAssistDB.spells[spellKey].textAlert
            end
            AddSelector(page, page.textSettingsCard, "textSelector")
            page.glowTab = CreateFrame("Button", nil, page.textSettingsCard, "UIPanelButtonTemplate")
            page.glowTab:SetSize(92, 22)
            page.glowTab:SetPoint("LEFT", page.textSelector, "RIGHT", -18, 1)
            page.glowTab:SetText("Glow")
            page.textEnable = CreateCheck(page.textSettingsCard, "Enable Text Alert", 14, -76,
                function() return textSettings().enabled end,
                function(value)
                    textSettings().enabled = value
                    addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
                end)
            page.textExpired = CreateCheck(page.textSettingsCard, "Show expired alert", 200, -76,
                function() return textSettings().expiredWarning end,
                function(value) textSettings().expiredWarning = value end)
            page.textGhoulMissing = CreateCheck(page.textSettingsCard, "Show Lesser Ghoul missing", 14, -104,
                function() return textSettings().ghoulMissingWarning end,
                function(value)
                    textSettings().ghoulMissingWarning = value
                    if addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
                end)
            page.textGhoulMissing.Text:SetFontObject("GameFontNormalSmall")
            page.textValue = CreateEditControl(page.textSettingsCard, "Display Text:", 14, -140, 160,
                function() return textSettings().text end,
                function(value)
                    textSettings().text = value
                    addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
                    page.RefreshTextPreview()
                end)
            page.textColor = CreateColorControl(page.textSettingsCard, 14, -178, "Text Color:",
                function() return textSettings().color end,
                function()
                    addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
                    page.RefreshTextPreview()
                end)
            CreatePresetRow(page.textSettingsCard, 14, -209, textSettings, function()
                page.textColor.refresh()
                addon:RefreshTextAlert("festeringScythe")
                page.RefreshTextPreview()
            end)
            page.textTiming = CreateSlider(page.textSettingsCard, "Alert when X sec remaining", 14, -248, 190, 1, 24, 1,
                function() return textSettings().secondsLeft or 5 end,
                function(value) textSettings().secondsLeft = value end)
            page.textPreview = CreateText(page.textPreviewCard, "", 0, 0, "GameFontNormalLarge", 250)
            page.textPreview:ClearAllPoints()
            page.textPreview:SetPoint("CENTER", page.textPreviewCard, "CENTER", 0, -6)
            page.textPreview:SetJustifyH("CENTER")
            page.textPreviewTimer = CreateText(page.textPreviewCard, "5.0s", 0, 0, "GameFontNormalLarge", 250)
            page.textPreviewTimer:ClearAllPoints()
            page.textPreviewTimer:SetPoint("TOP", page.textPreview, "BOTTOM", 0, -5)
            page.textPreviewTimer:SetJustifyH("CENTER")
            page.RefreshTextPreview = function()
                local ts = textSettings()
                page.textPreview:SetText(ts.text or "DK ASSIST")
                local previewFont = ts.font or STANDARD_TEXT_FONT
                local previewSize = math.min(32, ts.fontSize or 28)
                if not page.textPreview:SetFont(previewFont, previewSize, ts.outline or "OUTLINE") then
                    previewFont = STANDARD_TEXT_FONT
                    page.textPreview:SetFont(previewFont, previewSize, ts.outline or "OUTLINE")
                end
                page.textPreview:SetTextColor(ts.color.r, ts.color.g, ts.color.b, 1)
                page.textPreviewTimer:SetFont(previewFont, math.max(14, previewSize - 4), ts.outline or "OUTLINE")
                page.textPreviewTimer:SetTextColor(0.2, 1.0, 0.2, 1)
                page.textPreview:Show()
                page.textPreviewTimer:Show()
            end
            page.textLock = CreateCheck(page.textSettingsCard, "Lock position", 200, -104,
                function() return textSettings().locked end,
                function(value) textSettings().locked = value end)
            page.textSize = CreateSlider(page.textSettingsCard, "Font Size", 14, -298, 190, 12, 48, 1,
                function() return textSettings().fontSize or 28 end,
                function(value)
                    textSettings().fontSize = value
                    addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
                    page.RefreshTextPreview()
                end)
            local fontLabel = CreateText(page.textSettingsCard, "Font:", 14, -354, "GameFontNormal")
            page.textFont = CreateDropdown(page.textSettingsCard, 0, 0, 150,
                function() return TEXT_FONTS end,
                function() return textSettings().font or "Fonts\\FRIZQT__.TTF" end,
                function(value) textSettings().font = value; addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic")); page.RefreshTextPreview() end)
            page.textFont:ClearAllPoints(); page.textFont:SetPoint("LEFT", fontLabel, "RIGHT", -8, -2)
            local outlineLabel = CreateText(page.textSettingsCard, "Outline Style:", 14, -392, "GameFontNormal")
            page.textOutline = CreateDropdown(page.textSettingsCard, 0, 0, 150,
                function() return TEXT_OUTLINES end,
                function() return textSettings().outline or "OUTLINE" end,
                function(value) textSettings().outline = value; addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic")); page.RefreshTextPreview() end)
            page.textOutline:ClearAllPoints(); page.textOutline:SetPoint("LEFT", outlineLabel, "RIGHT", -8, -2)
            page.textTest = CreateFrame("Button", nil, page.textSettingsCard, "UIPanelButtonTemplate")
            page.textTest:SetSize(110, 24)
            page.textTest:SetPoint("TOPLEFT", page.textSettingsCard, "TOPLEFT", 14, -428)
            page.textTest:SetText("Test Text Alert")
            page.textTest:SetScript("OnClick", function()
                addon:TestTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
            end)
            page.textReset = CreateFrame("Button", nil, page.textSettingsCard, "UIPanelButtonTemplate")
            page.textReset:SetSize(110, 24)
            page.textReset:SetPoint("LEFT", page.textTest, "RIGHT", 8, 0)
            page.textReset:SetText("Reset Position")
            page.textReset:SetScript("OnClick", function()
                textSettings().point = nil
                addon:RefreshTextAlert(key == "festering" and "festeringScythe" or (key == "deathcoil" and "deathCoil" or "epidemic"))
            end)
            page.textCards = { page.textSettingsCard, page.textPreviewCard }

            page.SetMode = function(mode)
                local spellSettings = GlowSettingsFor(key)
                spellSettings.textAlertMode = mode
                for _, card in ipairs(page.glowCards) do if card then card:SetShown(mode == "glow") end end
                for _, card in ipairs(page.textCards) do if card then card:SetShown(mode == "text") end end
                page.glowTab:SetEnabled(mode ~= "glow")
                page.textTab:SetEnabled(mode ~= "text")
                cdmCheck:SetShown((mode == "glow") and (key == "festering" or key == "deathcoil" or key == "epidemic"))
            end
            page.glowTab:SetScript("OnClick", function() page.SetMode("glow") end)
        end
        AddSelector(page, page.settingsCard)
        if page.hasTextAlerts then
            page.textTab = CreateFrame("Button", nil, page.settingsCard, "UIPanelButtonTemplate")
            page.textTab:SetSize(92, 22)
            page.textTab:SetPoint("LEFT", page.selector, "RIGHT", -18, 1)
            page.textTab:SetText("Text Alert")
            page.textTab:SetScript("OnClick", function() page.SetMode("text") end)
            -- WA-Style is now a dedicated Configure entry, so the old
            -- secondary navigation buttons are intentionally hidden.
            page.textTab:Hide()
            page.glowTab:Hide()
        end
        local function settings() return GlowSettingsFor(key) end
        local function changed()
            if key == "festering" and addon.RefreshFesteringGlowStyle then addon:RefreshFesteringGlowStyle() end
            RefreshTracking(); RefreshPreview(page)
        end
        local ENABLE_LABELS = {
            runic           = "Enable Runic Power glow",
            festering       = "Enable glow",
            blooddnd        = "Glow when Death and Decay is ready",
            bloodbone       = "Glow when Bone Shield is missing",
            blooddndmissing = "Glow when you are outside your Death and Decay",
        }
        page.enable = CreateCheck(page.settingsCard,
            ENABLE_LABELS[key] or "Enable Sudden Doom glow",
            14, -76, function() return settings().enabled end,
            function(value)
                settings().enabled = value
                if (key == "blooddnd" or key == "bloodbone" or key == "blooddndmissing")
                    and addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
                -- This reminder also decorates action-bar copies, which are
                -- only built while it is enabled.
                if key == "blooddndmissing" and addon.ScanAllButtons then addon:ScanAllButtons() end
                changed()
            end)
        -- Sudden Doom is enabled once from its dedicated page.  The Death
        -- Coil and Epidemic pages remain only for their individual styling.
        if key == "deathcoil" or key == "epidemic" then page.enable:Hide() end
        local compactOffset = (key == "deathcoil" or key == "epidemic") and 36 or 0
        local glowStyleLabel = CreateText(page.settingsCard, "Glow Style:", 14, -112 + compactOffset, "GameFontNormal")
        page.glowDropdown = CreateDropdown(page.settingsCard, 0, 0, 145,
            function()
                local items = {}
                for _, glowType in ipairs(addon.GLOW_TYPES) do
                    items[#items + 1] = { text = glowType.name, value = glowType.id }
                end
                return items
            end,
            function() return settings().glowType end,
            function(value)
                settings().glowType = value
                page.refreshAppearance()
                changed()
            end)
        page.glowDropdown:ClearAllPoints()
        page.glowDropdown:SetPoint("LEFT", glowStyleLabel, "RIGHT", -8, -2)
        page.colorSwatch = CreateColorControl(page.settingsCard, 14, -149 + compactOffset, "Glow Color:",
            function() return settings().color end, changed)
        CreatePresetRow(page.settingsCard, 14, -181 + compactOffset, settings, function()
            page.colorSwatch.refresh(); changed()
        end)

        page.previewIcon, page.previewBar = CreatePreview(page.previewCard, spellID, key == "runic")
        BuildAppearance(page, page.appearanceCard, key)
        if key == "blooddndmissing" then
            page.missingHint = CreateText(page.appearanceCard,
                "Blood only, in combat.  Requires Death and Decay and its buff in the Cooldown "
                .. "Manager: the buff icon is how the reminder knows you left your patch.  Waits "
                .. "half a second so the Cleaving Strikes window does not flicker.",
                14, -250, "GameFontHighlightSmall", 300, { 0.64, 0.64, 0.64 })
        end

        if key == "festering" then
            page.combat = CreateCheck(page.warningCard, "Glow at combat start", 14, -38,
                function() return settings().combatGlow ~= false end,
                function(value) settings().combatGlow = value; if not value and addon.CancelFesteringCombatGlow then addon:CancelFesteringCombatGlow() end end)
            page.timing = CreateSlider(page.warningCard, "Glow when X sec remaining", 14, -72, 175, 1, 24, 1,
                function() return settings().glowTiming end,
                function(v) settings().glowTiming = v end)
            page.grace = CreateSlider(page.warningCard, "Combat start delay (sec)", 14, -122, 175, 0, 20, 1,
                function() return settings().combatGrace or 0 end,
                function(v) settings().combatGrace = v end)
            page.ghoul = CreateCheck(page.ghoulCard, "Also glow when Lesser Ghoul is missing", 14, -20,
                function() return settings().lesserGhoulGlow end,
                function(value)
                    settings().lesserGhoulGlow = value
                    if value and addon.RefreshCDMTrackedItems then addon:RefreshCDMTrackedItems() end
                end)
            page.ghoulHint = CreateText(page.ghoulCard,
                "Requires Lesser Ghoul in the Cooldown Manager, under either Tracked Buffs or Tracked Bars.",
                18, -49, "GameFontHighlightSmall", 310, { 0.64, 0.64, 0.64 })
        elseif key == "blooddnd" then
            page.dndTimerEnable = CreateCheck(page.warningCard, "Enable timer", 14, -38,
                function() return DKAssistDB.dnd.enabled end,
                function(value) DKAssistDB.dnd.enabled = value; addon:RefreshDnDTracker() end)
            page.dndTimerSize = CreateSlider(page.warningCard, "Timer Scale", 14, -72, 175, 24, 96, 1,
                function() return DKAssistDB.dnd.size end,
                function(value) DKAssistDB.dnd.size = value; addon:RefreshDnDTracker() end)
            page.dndTimerAlways = CreateCheck(page.warningCard, "Always show", 14, -126,
                function() return DKAssistDB.dnd.alwaysShow end,
                function(value) DKAssistDB.dnd.alwaysShow = value; addon:RefreshDnDAlwaysShow() end)
            page.dndTimerLock = CreateCheck(page.warningCard, "Lock position", 155, -126,
                function() return DKAssistDB.dnd.locked end,
                function(value) DKAssistDB.dnd.locked = value; addon:RefreshDnDTracker() end)
            page.dndTimerColor = CreateColorControl(page.warningCard, 14, -158, "Timer Color:",
                function() return DKAssistDB.dnd.color end,
                function() addon:RefreshDnDTracker() end)
            page.dndGraceColor = CreateColorControl(page.warningCard, 14, -194, "Grace Color:",
                function() return DKAssistDB.dnd.graceColor end,
                function() addon:RefreshDnDTracker() end)
            page.dndTimerTest = CreateFrame("Button", nil, page.warningCard, "UIPanelButtonTemplate")
            page.dndTimerTest:SetSize(105, 24)
            page.dndTimerTest:SetPoint("TOPLEFT", page.warningCard, "TOPLEFT", 14, -230)
            page.dndTimerTest:SetText("Test Timer")
            page.dndTimerTest:SetScript("OnClick", function() addon:TestDnDTracker() end)
            page.dndTimerHint = CreateText(page.warningCard,
                "Shows the remaining Death and Decay time after you cast it.",
                18, -265, "GameFontHighlightSmall", 300, { 0.64, 0.64, 0.64 })
        elseif key == "runic" then
            page.threshold = CreateSlider(page.settingsCard, "Glow at Runic Power", 14, -198, 175, 50, 100, 1,
                function() return settings().threshold end,
                function(v) settings().threshold = v; addon:UpdateRunicPowerGlow() end)
            page.settingsCard:SetHeight(248)
        end

        page.refresh = function()
            page.selector.refresh()
            if key ~= "deathcoil" and key ~= "epidemic" then page.enable.refresh() end
            page.glowDropdown.refresh(); page.colorSwatch.refresh()
            page.refreshAppearance()
            if page.timing then page.timing.refresh(); page.combat.refresh(); page.grace.refresh(); page.ghoul.refresh() end
            if page.dndTimerEnable then
                page.dndTimerEnable.refresh(); page.dndTimerSize.refresh()
                page.dndTimerAlways.refresh(); page.dndTimerLock.refresh()
                page.dndTimerColor.refresh(); page.dndGraceColor.refresh()
            end
            if page.threshold then page.threshold.refresh() end
            if page.hasTextAlerts then
                page.textSelector.refresh(); page.textEnable.refresh(); page.textExpired.refresh(); page.textGhoulMissing.refresh(); page.textValue.refresh(); page.textColor.refresh(); page.textTiming.refresh(); page.textLock.refresh(); page.textSize.refresh(); page.textFont.refresh(); page.textOutline.refresh()
                local ts = key == "festering" and DKAssistDB.spells.festeringScythe.textAlert or (key == "deathcoil" and DKAssistDB.spells.deathCoil.textAlert or DKAssistDB.spells.epidemic.textAlert)
                page.RefreshTextPreview()
                page.SetMode(GlowSettingsFor(key).textAlertMode or "glow")
            end
            RefreshPreview(page)
        end
        pages[key] = page
    end

    local function BuildSuddenDoomPage()
        local page = CreateFrame("Frame", nil, pageHolder)
        page:SetAllPoints(); page.layoutKind = "suddendoom"
        page.glowCard = CreateCard(page, "Sudden Doom Glow")
        page.previewCard = CreateCard(page, "Sudden Doom Preview")
        page.textCard = CreateCard(page, "Sudden Doom WA-Style")
        page.textPreviewCard = CreateCard(page, "Text Alert Preview")
        page.appearanceCard = CreateCard(page, "Pixel Glow appearance")
        AddSelector(page, page.glowCard)
        page.textTab = CreateFrame("Button", nil, page.glowCard, "UIPanelButtonTemplate")
        page.textTab:SetSize(90, 22)
        page.textTab:SetPoint("LEFT", page.selector, "RIGHT", -18, 0)
        page.textTab:SetText("Text Alert")
        local function settings() return DKAssistDB.suddenDoomGlow end
        local function changed()
            addon:RefreshSuddenDoomGlows(); RefreshPreview(page)
        end
        page.enable = CreateCheck(page.glowCard, "Enable Sudden Doom glow", 14, -76,
            function() return settings().enabled end, function(v) settings().enabled = v; changed() end)
        local styleLabel = CreateText(page.glowCard, "Glow Style:", 14, -112, "GameFontNormal")
        page.glowDropdown = CreateDropdown(page.glowCard, 0, 0, 145,
            function()
                local items = {}; for _, glowType in ipairs(addon.GLOW_TYPES) do items[#items + 1] = { text = glowType.name, value = glowType.id } end
                return items
            end,
            function() return settings().glowType end,
            function(v) settings().glowType = v; page.refreshAppearance(); changed() end)
        page.glowDropdown:ClearAllPoints(); page.glowDropdown:SetPoint("LEFT", styleLabel, "RIGHT", -8, -2)
        page.colorSwatch = CreateColorControl(page.glowCard, 14, -149, "Glow Color:", function() return settings().color end, changed)
        CreatePresetRow(page.glowCard, 14, -181, settings, function() page.colorSwatch.refresh(); changed() end)
        BuildAppearance(page, page.appearanceCard, "suddendoom")

        local function textSettings() return DKAssistDB.suddenDoomTextAlert end
        AddSelector(page, page.textCard, "textSelector")
        page.glowTab = CreateFrame("Button", nil, page.textCard, "UIPanelButtonTemplate")
        page.glowTab:SetSize(90, 22)
        page.glowTab:SetPoint("LEFT", page.textSelector, "RIGHT", -18, 0)
        page.glowTab:SetText("Glow")
        page.textEnable = CreateCheck(page.textCard, "Enable Text Alert", 14, -76,
            function() return textSettings().enabled end,
            function(v) textSettings().enabled = v; addon:RefreshTextAlert("suddenDoom") end)
        page.textValue = CreateEditControl(page.textCard, "Display Text:", 14, -112, 170,
            function() return textSettings().text end,
            function(v) textSettings().text = v; addon:RefreshTextAlert("suddenDoom"); page.RefreshTextPreview() end)
        page.textColor = CreateColorControl(page.textCard, 14, -148, "Text Color:",
            function() return textSettings().color end, function() addon:RefreshTextAlert("suddenDoom"); page.RefreshTextPreview() end)
        CreatePresetRow(page.textCard, 14, -179, textSettings, function()
            page.textColor.refresh()
            addon:RefreshTextAlert("suddenDoom")
            page.RefreshTextPreview()
        end)
        page.textLock = CreateCheck(page.textCard, "Lock position", 200, -76,
            function() return textSettings().locked end, function(v) textSettings().locked = v end)
        page.textSize = CreateSlider(page.textCard, "Font Size", 14, -256, 190, 12, 48, 1,
            function() return textSettings().fontSize or 28 end,
            function(v) textSettings().fontSize = v; addon:RefreshTextAlert("suddenDoom"); page.RefreshTextPreview() end)
        local fontLabel = CreateText(page.textCard, "Font:", 14, -312, "GameFontNormal")
        page.textFont = CreateDropdown(page.textCard, 0, 0, 150,
            function() return TEXT_FONTS end,
            function() return textSettings().font or "Fonts\\FRIZQT__.TTF" end,
            function(v) textSettings().font = v; addon:RefreshTextAlert("suddenDoom"); page.RefreshTextPreview() end)
        page.textFont:ClearAllPoints(); page.textFont:SetPoint("LEFT", fontLabel, "RIGHT", -8, -2)
        local outlineLabel = CreateText(page.textCard, "Outline Style:", 14, -348, "GameFontNormal")
        page.textOutline = CreateDropdown(page.textCard, 0, 0, 150,
            function() return TEXT_OUTLINES end,
            function() return textSettings().outline or "OUTLINE" end,
            function(v) textSettings().outline = v; addon:RefreshTextAlert("suddenDoom"); page.RefreshTextPreview() end)
        page.textOutline:ClearAllPoints(); page.textOutline:SetPoint("LEFT", outlineLabel, "RIGHT", -8, -2)
        page.textTest = CreateFrame("Button", nil, page.textCard, "UIPanelButtonTemplate")
        page.textTest:SetSize(110, 24); page.textTest:SetPoint("TOPLEFT", page.textCard, "TOPLEFT", 14, -382)
        page.textTest:SetText("Test Text Alert")
        page.textTest:SetScript("OnClick", function() addon:TestTextAlert("suddenDoom") end)
        page.textReset = CreateFrame("Button", nil, page.textCard, "UIPanelButtonTemplate")
        page.textReset:SetSize(110, 24); page.textReset:SetPoint("LEFT", page.textTest, "RIGHT", 8, 0)
        page.textReset:SetText("Reset Position")
        page.textReset:SetScript("OnClick", function() textSettings().point = nil; addon:RefreshTextAlert("suddenDoom") end)

        page.previewIcon, page.previewBar = CreatePreview(page.previewCard, 81340, false)
        page.textPreview = CreateText(page.textPreviewCard, "SUDDEN DOOM", 0, 0, "GameFontNormalLarge")
        page.textPreview:ClearAllPoints(); page.textPreview:SetPoint("CENTER", page.textPreviewCard, "CENTER", 0, -5)
        page.textPreview:SetJustifyH("CENTER")
        page.RefreshTextPreview = function()
            local ts = textSettings()
            page.textPreview:SetText(ts.text or "SUDDEN DOOM")
            page.textPreview:SetFont(ts.font or STANDARD_TEXT_FONT, math.min(42, ts.fontSize or 28), ts.outline or "OUTLINE")
            page.textPreview:SetTextColor(ts.color.r, ts.color.g, ts.color.b, 1)
            page.textPreview:Show()
        end
        page.SetMode = function(mode)
            mode = mode == "text" and "text" or "glow"
            DKAssistDB.suddenDoomTextMode = mode
            local glowMode = mode == "glow"
            page.glowCard:SetShown(glowMode)
            page.previewCard:SetShown(glowMode)
            page.appearanceCard:SetShown(glowMode)
            page.textCard:SetShown(not glowMode)
            page.textPreviewCard:SetShown(not glowMode)
            page.textPreview:SetShown(not glowMode)
            cdmCheck:SetShown(glowMode)
        end
        page.textTab:SetScript("OnClick", function() page.SetMode("text") end)
        page.glowTab:SetScript("OnClick", function() page.SetMode("glow") end)
        page.textTab:Hide()
        page.glowTab:Hide()
        page.refresh = function()
            page.selector.refresh(); page.textSelector.refresh()
            page.enable.refresh(); page.glowDropdown.refresh(); page.colorSwatch.refresh(); page.refreshAppearance()
            page.textEnable.refresh(); page.textValue.refresh(); page.textColor.refresh(); page.textLock.refresh(); page.textSize.refresh(); page.textFont.refresh(); page.textOutline.refresh()
            page.RefreshTextPreview()
            RefreshPreview(page)
            page.SetMode(DKAssistDB.suddenDoomTextMode or "glow")
        end
        pages.suddendoom = page
    end

    local function BuildPutrefyPage()
        local page = CreateFrame("Frame", nil, pageHolder)
        page:SetAllPoints(); page.layoutKind = "putrefy"
        page.settingsCard = CreateCard(page, "Putrefy Warning")
        page.previewCard = CreateCard(page, "Live Preview")
        page.appearanceCard = CreateCard(page, "Warning appearance")
        AddSelector(page, page.settingsCard)
        local function changed() addon:RefreshPutrefyWarnings(); RefreshPreview(page) end
        page.enable = CreateCheck(page.settingsCard, "Enable warning", 14, -76,
            function() return DKAssistDB.putrefy.enabled end,
            function(v) DKAssistDB.putrefy.enabled = v; changed() end)
        CreateText(page.settingsCard, "Warning Style:", 14, -112, "GameFontNormal")
        page.warningDropdown = CreateDropdown(page.settingsCard, 104, -121, 135,
            function()
                local items = {}
                for _, warning in ipairs(addon.PUTREFY_WARNING_TYPES) do
                    items[#items + 1] = { text = warning.name, value = warning.id }
                end
                return items
            end,
            function() return DKAssistDB.putrefy.warningType end,
            function(value)
                DKAssistDB.putrefy.warningType = value
                page.colorSwatch.refresh(); page.refreshAppearance(); changed()
            end)
        page.colorSwatch = CreateColorControl(page.settingsCard, 14, -154, "Color:",
            function()
                return DKAssistDB.putrefy.warningType == "cross" and DKAssistDB.putrefy.crossColor or DKAssistDB.putrefy.glowColor
            end, changed)
        page.previewIcon, page.previewBar = CreatePreview(page.previewCard, addon.SPELLS.PUTREFY.id, false)
        page.crossH = page.previewIcon:CreateTexture(nil, "OVERLAY")
        page.crossH:SetPoint("LEFT"); page.crossH:SetPoint("RIGHT")
        page.crossV = page.previewIcon:CreateTexture(nil, "OVERLAY")
        page.crossV:SetPoint("TOP"); page.crossV:SetPoint("BOTTOM")
        page.crossThickness = CreateSlider(page.appearanceCard, "Cross Thickness", 14, -38, 250, 0.05, 0.5, 0.01,
            function() return DKAssistDB.putrefy.crossThickness end,
            function(v) DKAssistDB.putrefy.crossThickness = v; changed() end)
        page.crossAlpha = CreateSlider(page.appearanceCard, "Cross Opacity", 14, -88, 250, 0.1, 1, 0.05,
            function() return DKAssistDB.putrefy.crossAlpha end,
            function(v) DKAssistDB.putrefy.crossAlpha = v; changed() end)
        page.glowSpeed = CreateSlider(page.appearanceCard, "Animation Speed", 14, -38, 250, 0.05, 2, 0.05,
            function() return DKAssistDB.putrefy.glowSpeed end,
            function(v) DKAssistDB.putrefy.glowSpeed = v; changed() end)
        page.glowLines = CreateSlider(page.appearanceCard, "Lines / Particles", 14, -88, 250, 1, 16, 1,
            function() return DKAssistDB.putrefy.glowLines end,
            function(v) DKAssistDB.putrefy.glowLines = v; changed() end)
        page.glowThickness = CreateSlider(page.appearanceCard, "Thickness", 14, -138, 250, 1, 8, 1,
            function() return DKAssistDB.putrefy.glowThickness end,
            function(v) DKAssistDB.putrefy.glowThickness = v; changed() end)
        page.glowAlpha = CreateSlider(page.appearanceCard, "Opacity", 14, -188, 250, 0.1, 1, 0.05,
            function() return DKAssistDB.putrefy.glowAlpha end,
            function(v) DKAssistDB.putrefy.glowAlpha = v; changed() end)
        page.refreshAppearance = function()
            local cross = DKAssistDB.putrefy.warningType == "cross"
            page.appearanceCard.title:SetText(cross and "Red Cross appearance" or "Red Glow appearance")
            page.crossThickness:SetShown(cross); page.crossAlpha:SetShown(cross)
            page.glowSpeed:SetShown(not cross); page.glowLines:SetShown(not cross)
            page.glowThickness:SetShown(not cross); page.glowAlpha:SetShown(not cross)
            if cross then page.crossThickness.refresh(); page.crossAlpha.refresh()
            else page.glowSpeed.refresh(); page.glowLines.refresh(); page.glowThickness.refresh(); page.glowAlpha.refresh() end
        end
        page.refresh = function()
            page.selector.refresh(); page.enable.refresh(); page.warningDropdown.refresh(); page.colorSwatch.refresh()
            page.refreshAppearance(); RefreshPreview(page)
        end
        pages.putrefy = page
    end

    local function BuildDnDPage()
        local page = CreateFrame("Frame", nil, pageHolder)
        page:SetAllPoints(); page.layoutKind = "dnd"
        page.settingsCard = CreateCard(page, "Death and Decay Tracker")
        page.previewCard = CreateCard(page, "Live Preview")
        AddSelector(page, page.settingsCard)
        page.enable = CreateCheck(page.settingsCard, "Enable tracker", 14, -76,
            function() return DKAssistDB.dnd.enabled end,
            function(v) DKAssistDB.dnd.enabled = v; addon:RefreshDnDTracker() end)
        page.size = CreateSlider(page.settingsCard, "Timer Scale", 14, -111, 190, 24, 96, 1,
            function() return DKAssistDB.dnd.size end,
            function(v) DKAssistDB.dnd.size = v; addon:RefreshDnDTracker() end)
        page.always = CreateCheck(page.settingsCard, "Always show", 14, -165,
            function() return DKAssistDB.dnd.alwaysShow end,
            function(v) DKAssistDB.dnd.alwaysShow = v; addon:RefreshDnDAlwaysShow() end)
        page.lock = CreateCheck(page.settingsCard, "Lock position", 14, -195,
            function() return DKAssistDB.dnd.locked end,
            function(v) DKAssistDB.dnd.locked = v; addon:RefreshDnDTracker() end)
        page.timerColor = CreateColorControl(page.settingsCard, 14, -235, "Timer Color:",
            function() return DKAssistDB.dnd.color end,
            function() addon:RefreshDnDTracker() end)
        page.graceColor = CreateColorControl(page.settingsCard, 14, -271, "Grace Color:",
            function() return DKAssistDB.dnd.graceColor end,
            function() addon:RefreshDnDTracker() end)
        page.hint = CreateText(page.settingsCard,
            "Use Test below to show the tracker, then drag it to your preferred position. Lock it when done.",
            18, -310, "GameFontHighlightSmall", 315, { 0.64, 0.64, 0.64 })
        page.previewIcon, page.previewBar = CreatePreview(page.previewCard, addon.SPELLS.DEATH_AND_DECAY.id, false)
        page.refresh = function()
            page.selector.refresh(); page.enable.refresh(); page.size.refresh(); page.always.refresh(); page.lock.refresh()
            page.timerColor.refresh(); page.graceColor.refresh()
        end
        pages.dnd = page
    end

    local function BuildSoulReaperPage()
        local page = CreateFrame("Frame", nil, pageHolder)
        page:SetAllPoints(); page.layoutKind = "soul"
        page.settingsCard = CreateCard(page, "Soul Reaper Mode")
        AddSelector(page, page.settingsCard)
        CreateText(page.settingsCard, "Suppress execute glow:", 14, -88, "GameFontNormal")
        page.mode = CreateDropdown(page.settingsCard, 146, -97, 155,
            function()
                return {
                    { text = "Off (default)", value = "off" },
                    { text = "Suppress always", value = "always" },
                }
            end,
            function() return DKAssistDB.soulReaper.suppressMode or "off" end,
            function(value) DKAssistDB.soulReaper.suppressMode = value; page.refresh() end)
        page.description = CreateText(page.settingsCard, "", 18, -138, "GameFontHighlightSmall", 540, { 0.68, 0.68, 0.68 })
        page.refresh = function()
            page.selector.refresh(); page.mode.refresh()
            if (DKAssistDB.soulReaper.suppressMode or "off") == "always" then
                page.description:SetText("The execute glow on Soul Reaper is completely suppressed at all times.")
            else
                page.description:SetText("Soul Reaper execute glow behaves normally using Blizzard's default behavior.")
            end
        end
        pages.soulreaper = page
    end

    BuildGlowPage("festering", "Festering Scythe Warning", addon.SPELLS.FESTERING_STRIKE.id)
    BuildGlowPage("deathcoil", "Death Coil - Sudden Doom", addon.SPELLS.DEATH_COIL.id)
    BuildGlowPage("epidemic", "Epidemic - Sudden Doom", addon.SPELLS.EPIDEMIC.id)
    BuildSuddenDoomPage()
    BuildPutrefyPage()
    BuildGlowPage("runic", "Runic Power Glow", nil)
    BuildGlowPage("blooddnd", "Blood - Death and Decay Reminder", addon.SPELLS.DEATH_AND_DECAY.id)
    BuildGlowPage("blooddndmissing", "Blood - Stand In Death and Decay", addon.SPELLS.DEATH_AND_DECAY.id)
    BuildDnDPage()
    BuildSoulReaperPage()

    local function LayoutPages()
        local width = pageHolder:GetWidth()
        local height = pageHolder:GetHeight()
        -- During the first layout pass an unparented Settings canvas can
        -- briefly report zero.  Once Blizzard supplies its real size, always
        -- use that size instead of forcing standalone dimensions onto it.
        if width < 10 then width = standalone and 724 or 700 end
        if height < 10 then height = standalone and 526 or 520 end
        local gap = 8
        local leftWidth = math.floor((width - gap) * 0.49)
        local rightWidth = width - gap - leftWidth
        local topHeight = 198
        local lowerY = -(topHeight + gap)
        local lowerHeight = height - topHeight - gap

        for key, page in pairs(pages) do
            for _, card in pairs({ page.settingsCard, page.previewCard, page.warningCard, page.ghoulCard, page.appearanceCard,
                page.textSettingsCard, page.textPreviewCard, page.textAppearanceCard, page.glowCard, page.textCard }) do
                if card then card:ClearAllPoints() end
            end
            if page.hasTextAlerts then
                local contentTop = 0
                local contentLowerY = contentTop - topHeight - gap
                page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, contentTop)
                page.settingsCard:SetSize(leftWidth, topHeight)
                page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, contentTop)
                page.previewCard:SetSize(rightWidth, topHeight)
                page.textSettingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, contentTop)
                page.textSettingsCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                page.textPreviewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, contentTop)
                page.textPreviewCard:SetSize(rightWidth, topHeight)
                if page.layoutKind == "festering" then
                    local warningHeight = math.max(174, math.floor((height - topHeight - gap) * 0.62))
                    page.warningCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, contentLowerY)
                    page.warningCard:SetSize(leftWidth, warningHeight)
                    page.ghoulCard:SetPoint("TOPLEFT", page.warningCard, "BOTTOMLEFT", 0, -gap)
                    page.ghoulCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                    page.appearanceCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, contentLowerY)
                    page.appearanceCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", leftWidth + gap, 0)
                    page.ghoulHint:SetWidth(math.max(230, leftWidth - 36))
                else
                    page.appearanceCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, contentLowerY)
                    page.appearanceCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
                end
            elseif page.layoutKind == "suddendoom" then
                page.glowCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.glowCard:SetSize(leftWidth, topHeight)
                page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                page.previewCard:SetSize(rightWidth, topHeight)
                page.appearanceCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, lowerY)
                page.appearanceCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
                page.textCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.textCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                page.textPreviewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                page.textPreviewCard:SetSize(rightWidth, topHeight)
            elseif page.layoutKind == "festering" then
                page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.settingsCard:SetSize(leftWidth, topHeight)
                page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                page.previewCard:SetSize(rightWidth, topHeight)
                local warningHeight = math.max(174, math.floor(lowerHeight * 0.62))
                page.warningCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, lowerY)
                page.warningCard:SetSize(leftWidth, warningHeight)
                page.ghoulCard:SetPoint("TOPLEFT", page.warningCard, "BOTTOMLEFT", 0, -gap)
                page.ghoulCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                page.appearanceCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, lowerY)
                page.appearanceCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", leftWidth + gap, 0)
                page.ghoulHint:SetWidth(math.max(230, leftWidth - 36))
            elseif page.layoutKind == "blooddnd" then
                page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.settingsCard:SetSize(leftWidth, topHeight)
                page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                page.previewCard:SetSize(rightWidth, topHeight)
                page.warningCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, lowerY)
                page.warningCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                page.appearanceCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, lowerY)
                page.appearanceCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", leftWidth + gap, 0)
                page.dndTimerHint:SetWidth(math.max(230, leftWidth - 36))
            elseif page.layoutKind == "glow" or page.layoutKind == "putrefy" then
                if key == "runic" then
                    page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                    page.settingsCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                    page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                    page.previewCard:SetSize(rightWidth, topHeight)
                    page.appearanceCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, lowerY)
                    page.appearanceCard:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", leftWidth + gap, 0)
                else
                    page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                    page.settingsCard:SetSize(leftWidth, topHeight)
                    page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                    page.previewCard:SetSize(rightWidth, topHeight)
                    page.appearanceCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, lowerY)
                    page.appearanceCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
                end
            elseif page.layoutKind == "dnd" then
                page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.settingsCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", leftWidth, 0)
                page.previewCard:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, 0)
                page.previewCard:SetSize(rightWidth, topHeight)
                page.hint:SetWidth(math.max(210, leftWidth - 36))
            elseif page.layoutKind == "soul" then
                page.settingsCard:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
                page.settingsCard:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
                page.description:SetWidth(math.max(300, width - 44))
            end
        end
    end

    function panel:ShowPage(key)
        local pageKey = key
        if key == "festeringwa" then pageKey = "festering"
        elseif key == "suddendoomwa" then pageKey = "suddendoom" end
        if not pages[pageKey] then key, pageKey = "festering", "festering" end
        if activePage then StopPreview(activePage); activePage:Hide() end
        selectedKey = key
        activePage = pages[pageKey]
        activePage:Show()
        for _, page in pairs(pages) do if page ~= activePage then page:Hide() end end
        testActive = false; testButton:SetText("Test")
        cdmCheck:SetShown(pageKey == "festering" or pageKey == "putrefy" or pageKey == "suddendoom" or pageKey == "deathcoil" or pageKey == "epidemic")
        cdmCheck.Text:SetText(key == "putrefy" and "Track on Cooldown Manager" or "Use Cooldown Manager (instead of action bars)")
        rescanButton:SetShown(key ~= "dnd" and key ~= "soulreaper")
        testButton:SetShown(key ~= "soulreaper")
        cdmCheck.refresh()
        activePage.refresh()
        if key == "festeringwa" or key == "suddendoomwa" then
            activePage.SetMode("text")
        elseif (key == "festering" or key == "suddendoom") and activePage.SetMode then
            activePage.SetMode("glow")
        end
    end

    function panel:RefreshControls()
        minimapCheck.refresh()
        if themeDropdown then themeDropdown.refresh() end
        specDropdown.refresh()
        local activeSpec = ActiveConfigSpec()
        if activeSpec == "blood" and not BLOOD_ONLY_KEYS[selectedKey] then
            selectedKey = "blooddnd"
        elseif activeSpec == "unholy" and BLOOD_ONLY_KEYS[selectedKey] then
            selectedKey = "festering"
        end
        LayoutPages()
        self:ShowPage(selectedKey)
    end

    -- Modern skinning is intentionally runtime-only: no command, position,
    -- page layout, or gameplay setting is changed.  It is applied solely to
    -- the standalone panel and can be switched back to Classic immediately.
    local function WalkRegions(frame, callback)
        if not frame then return end
        for _, region in ipairs({ frame:GetRegions() }) do callback(region) end
        for _, child in ipairs({ frame:GetChildren() }) do
            callback(child)
            WalkRegions(child, callback)
        end
    end

    local function SetButtonSkin(button, modern, palette)
        if not button or button:GetObjectType() ~= "Button" then return end
        if not button:GetText() or button:GetText() == "" then return end
        if not button._dkassistThemeReady then
            button._dkassistThemeReady = true
            -- UIPanelButtonTemplate also contains decorative texture regions
            -- that are not returned by GetNormal/Pushed/HighlightTexture().
            -- Preserve every stock layer so modern themes can hide the whole
            -- Classic button chrome instead of merely tinting it.
            button._dkassistOriginalButtonTextures = {}
            for _, region in ipairs({ button:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    table.insert(button._dkassistOriginalButtonTextures, {
                        texture = region,
                        alpha = region:GetAlpha(),
                    })
                end
            end
            button._dkassistOriginalNormal = button:GetNormalTexture()
            button._dkassistOriginalPushed = button:GetPushedTexture()
            button._dkassistOriginalHighlight = button:GetHighlightTexture()
            button._dkassistOriginalNormalAlpha = button._dkassistOriginalNormal and button._dkassistOriginalNormal:GetAlpha() or 1
            button._dkassistOriginalPushedAlpha = button._dkassistOriginalPushed and button._dkassistOriginalPushed:GetAlpha() or 1
            button._dkassistOriginalHighlightAlpha = button._dkassistOriginalHighlight and button._dkassistOriginalHighlight:GetAlpha() or 1
            if button:GetFontString() then
                button._dkassistOriginalFontColor = { button:GetFontString():GetTextColor() }
            end

            local background = button:CreateTexture(nil, "BACKGROUND")
            background:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            background:SetTexture("Interface\\Buttons\\WHITE8X8")
            background:Hide()
            button._dkassistModernButtonBackground = background

            local highlight = button:CreateTexture(nil, "ARTWORK")
            highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
            highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlight:Hide()
            button._dkassistModernButtonHighlight = highlight

            button:HookScript("OnEnter", function(self)
                if self._dkassistModernActive then self._dkassistModernButtonHighlight:Show() end
            end)
            button:HookScript("OnLeave", function(self)
                if self._dkassistModernActive then self._dkassistModernButtonHighlight:Hide() end
            end)
            button:HookScript("OnMouseDown", function(self)
                if self._dkassistModernActive and self._dkassistThemePalette then
                    local p = self._dkassistThemePalette
                    self._dkassistModernButtonBackground:SetVertexColor(
                        p.accent[1] * 0.42, p.accent[2] * 0.42, p.accent[3] * 0.42, 1)
                end
            end)
            button:HookScript("OnMouseUp", function(self)
                if self._dkassistModernActive and self._dkassistThemePalette then
                    local p = self._dkassistThemePalette
                    self._dkassistModernButtonBackground:SetVertexColor(
                        p.control[1], p.control[2], p.control[3], 1)
                end
            end)
        end
        if modern then
            palette = palette or STANDALONE_THEMES.frosted
            button._dkassistModernActive = true
            button._dkassistThemePalette = palette
            for _, entry in ipairs(button._dkassistOriginalButtonTextures or {}) do
                entry.texture:SetAlpha(0)
            end
            button._dkassistModernButtonBackground:SetVertexColor(
                palette.control[1], palette.control[2], palette.control[3], 1)
            button._dkassistModernButtonHighlight:SetVertexColor(
                palette.accent[1], palette.accent[2], palette.accent[3], 0.24)
            button._dkassistModernButtonBackground:Show()
            local fs = button:GetFontString()
            if fs then fs:SetTextColor(palette.text[1], palette.text[2], palette.text[3], 1) end
        else
            button._dkassistModernActive = false
            button._dkassistThemePalette = nil
            button._dkassistModernButtonBackground:Hide()
            button._dkassistModernButtonHighlight:Hide()
            for _, entry in ipairs(button._dkassistOriginalButtonTextures or {}) do
                entry.texture:SetAlpha(entry.alpha)
            end
            button:SetNormalFontObject("GameFontNormal")
            if button._dkassistOriginalFontColor and button:GetFontString() then
                button:GetFontString():SetTextColor(unpack(button._dkassistOriginalFontColor))
            end
        end
    end

    local function SetSliderSkin(slider, modern, palette)
        if not slider or slider:GetObjectType() ~= "Slider" then return end
        if not slider._dkassistOriginalTextures then
            slider._dkassistOriginalTextures = {}
            for _, region in ipairs({ slider:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    table.insert(slider._dkassistOriginalTextures, region)
                end
            end
            local thumb = slider:GetThumbTexture()
            if thumb then
                slider._dkassistOriginalThumb = {
                    texture = thumb:GetTexture(),
                    coords = { thumb:GetTexCoord() },
                    width = thumb:GetWidth(),
                    height = thumb:GetHeight(),
                }
            end
        end
        if not slider._dkassistModernTrack then
            local track = slider:CreateTexture(nil, "BACKGROUND")
            track:SetColorTexture(0.10, 0.18, 0.24, 1)
            track:SetHeight(4)
            track:SetPoint("LEFT", slider, "LEFT", 2, 0)
            track:SetPoint("RIGHT", slider, "RIGHT", -2, 0)
            track:Hide()
            slider._dkassistModernTrack = track
            local fill = slider:CreateTexture(nil, "BORDER")
            fill:SetColorTexture(0.16, 0.62, 0.90, 1)
            fill:SetHeight(4)
            fill:SetPoint("LEFT", slider, "LEFT", 2, 0)
            fill:Hide()
            slider._dkassistModernFill = fill
        end
        if modern then
            palette = palette or STANDALONE_THEMES.frosted
            for _, texture in ipairs(slider._dkassistOriginalTextures) do texture:Hide() end
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
            local thumb = slider:GetThumbTexture()
            if thumb then
                thumb:SetSize(10, 14)
                thumb:SetVertexColor(palette.accent[1], palette.accent[2], palette.accent[3], 1)
                thumb:Show()
            end
            slider._dkassistModernTrack:Show()
            slider._dkassistModernTrack:SetColorTexture(palette.border[1], palette.border[2], palette.border[3], 1)
            slider._dkassistModernFill:SetColorTexture(palette.accent[1], palette.accent[2], palette.accent[3], 1)
            slider._dkassistModernFill:ClearAllPoints()
            slider._dkassistModernFill:SetPoint("LEFT", slider, "LEFT", 2, 0)
            if thumb then
                slider._dkassistModernFill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
            else
                slider._dkassistModernFill:SetPoint("RIGHT", slider, "CENTER", 0, 0)
            end
            slider._dkassistModernFill:Show()
        else
            slider._dkassistModernTrack:Hide()
            slider._dkassistModernFill:Hide()
            for _, texture in ipairs(slider._dkassistOriginalTextures) do texture:Show() end
            local saved = slider._dkassistOriginalThumb
            if saved and saved.texture then
                slider:SetThumbTexture(saved.texture)
                local thumb = slider:GetThumbTexture()
                if thumb then
                    if saved.coords and #saved.coords >= 4 then thumb:SetTexCoord(unpack(saved.coords)) end
                    thumb:SetSize(saved.width, saved.height)
                    thumb:SetVertexColor(1, 1, 1, 1)
                    thumb:Show()
                end
            end
        end
    end

    local function SetEditBoxSkin(edit, modern, palette)
        if not edit or edit:GetObjectType() ~= "EditBox" then return end
        if not edit._dkassistOriginalTextures then
            edit._dkassistOriginalTextures = {}
            for _, region in ipairs({ edit:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    table.insert(edit._dkassistOriginalTextures, region)
                end
            end
        end
        if not edit._dkassistModernBackground then
            local bg = edit:CreateTexture(nil, "BACKGROUND")
            bg:SetPoint("TOPLEFT", edit, "TOPLEFT", -3, 2)
            bg:SetPoint("BOTTOMRIGHT", edit, "BOTTOMRIGHT", 3, -2)
            bg:SetColorTexture(0.035, 0.075, 0.105, 1)
            bg:Hide()
            edit._dkassistModernBackground = bg
            local border = edit:CreateTexture(nil, "BORDER")
            border:SetPoint("TOPLEFT", bg, "TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 1, -1)
            border:SetColorTexture(0.18, 0.36, 0.48, 1)
            bg:SetDrawLayer("BACKGROUND", 1)
            border:SetDrawLayer("BACKGROUND", 0)
            border:Hide()
            edit._dkassistModernBorder = border
        end
        if modern then
            palette = palette or STANDALONE_THEMES.frosted
            for _, texture in ipairs(edit._dkassistOriginalTextures) do texture:Hide() end
            edit._dkassistModernBackground:SetColorTexture(palette.control[1], palette.control[2], palette.control[3], 1)
            edit._dkassistModernBorder:SetColorTexture(palette.border[1], palette.border[2], palette.border[3], 1)
            edit._dkassistModernBorder:Show()
            edit._dkassistModernBackground:Show()
            edit:SetTextColor(palette.text[1], palette.text[2], palette.text[3], 1)
        else
            edit._dkassistModernBorder:Hide()
            edit._dkassistModernBackground:Hide()
            for _, texture in ipairs(edit._dkassistOriginalTextures) do texture:Show() end
            edit:SetTextColor(1, 1, 1, 1)
        end
    end

    function panel:ApplyStandaloneTheme(themeKey)
        if not standalone then return end
        if themeKey ~= "classic" and not STANDALONE_THEMES[themeKey] then themeKey = "classic" end
        DKAssistDB.standaloneTheme = themeKey
        local palette = STANDALONE_THEMES[themeKey]
        local modern = palette ~= nil
        local window = self:GetParent()

        if modern then
            self:SetBackdropColor(palette.panel[1], palette.panel[2], palette.panel[3], 1)
            if window and window.SetBackdrop then
                window:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                window:SetBackdropColor(palette.window[1], palette.window[2], palette.window[3], 1)
                window:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], 1)
                if window.dkassistBackgroundTexture then
                    window.dkassistBackgroundTexture:SetColorTexture(palette.window[1], palette.window[2], palette.window[3], 1)
                end
                if window.dkassistBackgroundPattern then window.dkassistBackgroundPattern:Hide() end
                if window.dkassistCloseButton then
                    local normal = window.dkassistCloseButton:GetNormalTexture()
                    local pushed = window.dkassistCloseButton:GetPushedTexture()
                    local highlight = window.dkassistCloseButton:GetHighlightTexture()
                    if normal then normal:Hide() end
                    if pushed then pushed:Hide() end
                    if highlight then highlight:Hide() end
                end
                if window.dkassistModernCloseText then
                    window.dkassistModernCloseText:SetTextColor(palette.accent[1], palette.accent[2], palette.accent[3], 1)
                    window.dkassistModernCloseText:Show()
                end
            end
            title:SetText("|cff" .. palette.titleCode .. "DK Assist|r")
            subtitle:SetTextColor(palette.subtext[1], palette.subtext[2], palette.subtext[3], 1)
        else
            self:SetBackdropColor(0.008, 0.008, 0.012, 1)
            if window and window.SetBackdrop then
                window:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    tile = true, tileSize = 32, edgeSize = 32,
                    insets = { left = 11, right = 12, top = 12, bottom = 11 },
                })
                window:SetBackdropColor(0.012, 0.012, 0.018, 1)
                window:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
                if window.dkassistBackgroundTexture then
                    window.dkassistBackgroundTexture:SetColorTexture(0.012, 0.012, 0.018, 1)
                end
                if window.dkassistBackgroundPattern then window.dkassistBackgroundPattern:Show() end
                if window.dkassistCloseButton then
                    local normal = window.dkassistCloseButton:GetNormalTexture()
                    local pushed = window.dkassistCloseButton:GetPushedTexture()
                    local highlight = window.dkassistCloseButton:GetHighlightTexture()
                    if normal then normal:Show() end
                    if pushed then pushed:Show() end
                    if highlight then highlight:Show() end
                end
                if window.dkassistModernCloseText then window.dkassistModernCloseText:Hide() end
            end
            title:SetText("|cffcc0000DK Assist|r")
            subtitle:SetTextColor(0.67, 0.67, 0.67, 1)
        end

        WalkRegions(self, function(object)
            local objectType = object.GetObjectType and object:GetObjectType()
            if objectType == "Button" then
                SetButtonSkin(object, modern, palette)
            elseif objectType == "Slider" then
                SetSliderSkin(object, modern, palette)
            elseif objectType == "EditBox" then
                SetEditBoxSkin(object, modern, palette)
            elseif objectType == "FontString" then
                local fontObject = object:GetFontObject()
                if modern then
                    if not object._dkassistOriginalTextColor then
                        object._dkassistOriginalTextColor = { object:GetTextColor() }
                    end
                    -- Keep colored preview alerts and user-selected alert
                    -- colors intact; only stock configuration fonts change.
                    if fontObject == GameFontNormal or fontObject == GameFontNormalSmall then
                        object:SetTextColor(palette.accent[1], palette.accent[2], palette.accent[3], 1)
                    elseif fontObject == GameFontHighlightSmall then
                        object:SetTextColor(palette.subtext[1], palette.subtext[2], palette.subtext[3], 1)
                    end
                elseif object._dkassistOriginalTextColor then
                    object:SetTextColor(unpack(object._dkassistOriginalTextColor))
                end
            end
        end)

        -- Cards are the only BackdropTemplate frames with these precise base
        -- colors, so they can be recolored without touching sliders/previews.
        for _, page in pairs(pages) do
            for _, card in pairs({ page.settingsCard, page.previewCard, page.warningCard, page.ghoulCard,
                page.appearanceCard, page.textSettingsCard, page.textPreviewCard,
                page.textAppearanceCard, page.glowCard, page.textCard }) do
                if card and card.SetBackdropColor then
                    if modern then
                        card:SetBackdropColor(palette.card[1], palette.card[2], palette.card[3], 0.98)
                        card:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], 1)
                        if card.title then card.title:SetTextColor(palette.accent[1], palette.accent[2], palette.accent[3], 1) end
                        if card.leftDivider then card.leftDivider:SetVertexColor(palette.accent[1], palette.accent[2], palette.accent[3], 0.72) end
                        if card.rightDivider then card.rightDivider:SetVertexColor(palette.accent[1], palette.accent[2], palette.accent[3], 0.72) end
                    else
                        card:SetBackdropColor(0.012, 0.012, 0.018, 0.98)
                        card:SetBackdropBorderColor(0.25, 0.25, 0.27, 1)
                        if card.title then card.title:SetTextColor(1.00, 0.82, 0.00, 1) end
                        if card.leftDivider then card.leftDivider:SetVertexColor(0.68, 0.55, 0.10, 0.75) end
                        if card.rightDivider then card.rightDivider:SetVertexColor(0.68, 0.55, 0.10, 0.75) end
                    end
                end
            end
        end
        for _, dropdown in ipairs(self.dkassistModernDropdowns or {}) do
            dropdown:SetModernMode(modern, palette)
        end
        if themeDropdown then themeDropdown.refresh() end
    end

    testButton:SetScript("OnClick", function()
        testActive = not testActive
        if testActive then
            if selectedKey == "festeringwa" then
                addon:TestTextAlert("festeringScythe")
            elseif selectedKey == "suddendoomwa" then
                addon:TestTextAlert("suddenDoom")
            elseif selectedKey == "festering" then addon:TestFesteringGlow()
            elseif selectedKey == "deathcoil" then addon:TestSuddenDoomGlow("deathCoil")
            elseif selectedKey == "epidemic" then addon:TestSuddenDoomGlow("epidemic")
            elseif selectedKey == "suddendoom" then
                addon:TestSuddenDoomGlow("deathCoil")
                addon:TestSuddenDoomGlow("epidemic")
            elseif selectedKey == "putrefy" then addon:TestPutrefyWarning()
            elseif selectedKey == "runic" then addon:TestRunicPowerGlow()
            elseif selectedKey == "blooddnd" then addon:TestBloodDnDReminder()
            elseif selectedKey == "blooddndmissing" then addon:TestDnDMissingGlow()
            elseif selectedKey == "bloodbone" then addon:TestBloodBoneReminder()
            elseif selectedKey == "dnd" then addon:TestDnDTracker() end
            testButton:SetText("Stop Test")
        else
            addon:StopAll(); addon:StopDnDTest(); addon:StopRunicPowerGlow(); addon:StopBloodDnDReminder(); addon:StopBloodBoneReminder(); addon:StopDnDMissingGlow()
            testButton:SetText("Test")
        end
    end)

    panel:SetScript("OnShow", function(self)
        C_Timer.After(0, function()
            if self:IsShown() then
                if standalone then self:ApplyStandaloneTheme(DKAssistDB.standaloneTheme or "classic") end
                self:RefreshControls()
            end
        end)
    end)
    panel:SetScript("OnHide", function()
        StopPreview(activePage)
        testActive = false; testButton:SetText("Test")
        for _, dropdown in ipairs(panel.dkassistModernDropdowns or {}) do
            if dropdown.menu then dropdown.menu:Hide() end
        end
    end)
    panel:SetScript("OnSizeChanged", function()
        if panel:IsShown() then LayoutPages() end
    end)

    for _, page in pairs(pages) do page:Hide() end
    activeStandalonePanel = nil
    return panel
end
