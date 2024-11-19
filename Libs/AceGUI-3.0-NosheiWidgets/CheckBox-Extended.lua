--[[-----------------------------------------------------------------------------
Checkbox Extended Widget
Widget is an extension of the Checkbox Widget from AceGUI-3.0
Updated to use newer checkbox atlas files instead of old textures
We've hijacked ImageCoords from AceConfDisplay to be able to extend the new functions to AceConfig
This Lib is not for general use outside of my own addons.
Adds additional image options:
    SetImageSize
    SetImageBorder - allows for adding a border, such as a rarity border
    SetImageBorderColor - sets the color for the image border
    SetImageOverlay - allows for adding overlays, such as a quality overlay
-------------------------------------------------------------------------------]]
local AGNW = LibStub:NewLibrary("AceGUINosheiWidgets-1.0", 110002)

local Type, Version = "NW_CheckBox", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local select, pairs = select, pairs

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function AlignImage(self)
    local img = self.image:GetTexture()
    self.text:ClearAllPoints()
    if not img then
        self.text:SetPoint("LEFT", self.checkbg, "RIGHT")
        self.text:SetPoint("RIGHT")
    else
        self.text:SetPoint("LEFT", self.image, "RIGHT", 1, 0)
        self.text:SetPoint("RIGHT")
    end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
    local self = frame.obj
    self.background:SetVertexColor(0.35, 0.35, 0.35, 1)
    frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
    local self = frame.obj
    self.background:SetVertexColor(0, 0, 0, 0)
    frame.obj:Fire("OnLeave")
end

local function CheckBox_OnMouseDown(frame)
    local self = frame.obj
    if not self.disabled then
        if self.image:GetTexture() then
            self.text:SetPoint("LEFT", self.image, "RIGHT", 2, -1)
        else
            self.text:SetPoint("LEFT", self.checkbg, "RIGHT", 1, -1)
        end
    end
    AceGUI:ClearFocus()
end

local function CheckBox_OnMouseUp(frame)
    local self = frame.obj
    if not self.disabled then
        self:ToggleChecked()

        if self.checked then
            PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
        else               -- for both nil and false (tristate)
            PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
        end

        self:Fire("OnValueChanged", self.checked)
        AlignImage(self)
    end
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
    ["OnAcquire"] = function(self)
        self:SetType()
        self:SetValue(false)
        self:SetTriState(nil)
        -- height is calculated from the width and required space for the description
        self:SetWidth(200)
        self:SetImage()
        self:SetDisabled(nil)
        self:SetDescription(nil)
    end,

    -- ["OnRelease"] = nil,

    ["OnWidthSet"] = function(self, width)
        if self.desc then
            self.desc:SetWidth(width - 30)
            if self.desc:GetText() and self.desc:GetText() ~= "" then
                self:SetHeight(28 + self.desc:GetStringHeight())
            end
        end
    end,

    ["SetDisabled"] = function(self, disabled)
        self.disabled = disabled
        if disabled then
            self.frame:Disable()
            self.text:SetTextColor(0.5, 0.5, 0.5)
            SetDesaturation(self.check, true)
            if self.desc then
                self.desc:SetTextColor(0.5, 0.5, 0.5)
            end
        else
            self.frame:Enable()
            self.text:SetTextColor(1, 1, 1)
            if self.tristate and self.checked == nil then
                SetDesaturation(self.check, true)
            else
                SetDesaturation(self.check, false)
            end
            if self.desc then
                self.desc:SetTextColor(1, 1, 1)
            end
        end
    end,

    ["SetValue"] = function(self, value)
        local check = self.check
        self.checked = value
        if value then
            SetDesaturation(check, false)
            check:Show()
        else
            --Nil is the unknown tristate value
            if self.tristate and value == nil then
                SetDesaturation(check, true)
                check:Show()
            else
                SetDesaturation(check, false)
                check:Hide()
            end
        end
        self:SetDisabled(self.disabled)
    end,

    ["GetValue"] = function(self)
        return self.checked
    end,

    ["SetTriState"] = function(self, enabled)
        self.tristate = enabled
        self:SetValue(self:GetValue())
    end,

    ["SetType"] = function(self, type)
        local checkbg = self.checkbg
        local check = self.check
        local highlight = self.highlight

        local size
        if type == "radio" then
            size = 16
            checkbg:SetTexture(130843) -- Interface\\Buttons\\UI-RadioButton
            checkbg:SetTexCoord(0, 0.25, 0, 1)
            check:SetTexture(130843)   -- Interface\\Buttons\\UI-RadioButton
            check:SetTexCoord(0.25, 0.5, 0, 1)
            check:SetBlendMode("ADD")
            highlight:SetTexture(130843) -- Interface\\Buttons\\UI-RadioButton
            highlight:SetTexCoord(0.5, 0.75, 0, 1)
        else
            size = 24
            --checkbg:SetTexture(130755) -- Interface\\Buttons\\UI-CheckBox-Up
            --checkbg:SetTexCoord(0, 1, 0, 1)
            checkbg:SetAtlas("checkbox-minimal", true)
            check:SetAtlas("checkmark-minimal", true)
            --check:SetTexture(130751)   -- Interface\\Buttons\\UI-CheckBox-Check
            --check:SetTexCoord(0, 1, 0, 1)
            check:SetBlendMode("BLEND")
            highlight:SetAtlas("checkbox-minimal", true)
            --highlight:SetTexture(130753) -- Interface\\Buttons\\UI-CheckBox-Highlight
            --highlight:SetTexCoord(0, 1, 0, 1)
        end
        checkbg:SetHeight(size)
        checkbg:SetWidth(size)
    end,

    ["ToggleChecked"] = function(self)
        local value = self:GetValue()
        if self.tristate then
            --cycle in true, nil, false order
            if value then
                self:SetValue(nil)
            elseif value == nil then
                self:SetValue(false)
            else
                self:SetValue(true)
            end
        else
            self:SetValue(not self:GetValue())
        end
    end,

    ["SetLabel"] = function(self, label)
        self.text:SetText(label)
    end,

    ["SetDescription"] = function(self, desc)
        if desc then
            if not self.desc then
                local f = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", self.checkbg, "TOPRIGHT", 5, -21)
                f:SetWidth(self.frame.width - 30)
                f:SetPoint("RIGHT", self.frame, "RIGHT", -30, 0)
                f:SetJustifyH("LEFT")
                f:SetJustifyV("TOP")
                self.desc = f
            end
            self.desc:Show()
            --self.text:SetFontObject(GameFontNormal)
            self.desc:SetText(desc)
            self:SetHeight(28 + self.desc:GetStringHeight())
        else
            if self.desc then
                self.desc:SetText("")
                self.desc:Hide()
            end
            --self.text:SetFontObject(GameFontHighlight)
            self:SetHeight(24)
        end
    end,

    ["SetImage"] = function(self, path, imageSize, border, borderColor, overlay)
        local image = self.image
        image:SetTexture(path)
        AlignImage(self)

        if imageSize then
            self:SetImageSize(unpack(imageSize))
        end
        if border then
            self:SetImageBorder(unpack(border))
        end
        if borderColor then
            self:SetImageBorderColor(unpack(borderColor))
        end
        if overlay then
            self:SetImageOverlay(unpack(overlay))
        end
    end,

    ["SetImageSize"] = function(self, width, height)
        local image = self.image
        image:SetWidth(width)
        image:SetHeight(height)
    end,

    ["SetImageBorder"] = function(self, path, type)
        local border = self.border
        if type == "texture" then
            border:SetTexture(path)
        elseif type == "atlas" then
            border:SetAtlas(path)
        end
    end,

    ["SetImageBorderColor"] = function(self, R, G, B, A)
        local border = self.border
        local R, G, B, A = R or 1, G or 1, B or 1, A or 1
        border:SetVertexColor(R, G, B, A)
    end,

    ["SetImageOverlay"] = function(self, path, type)
        local overlay = self.overlay
        if type == "texture" then
            overlay:SetTexture(path)
        elseif type == "atlas" then
            overlay:SetAtlas(path, true)
        end
    end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", Control_OnEnter)
    frame:SetScript("OnLeave", Control_OnLeave)
    frame:SetScript("OnMouseDown", CheckBox_OnMouseDown)
    frame:SetScript("OnMouseUp", CheckBox_OnMouseUp)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
    background:SetVertexColor(0, 0, 0, 0)

    local checkbg = frame:CreateTexture(nil, "ARTWORK")
    checkbg:SetWidth(24)
    checkbg:SetHeight(24)
    checkbg:SetPoint("TOPLEFT")
    checkbg:SetAtlas("checkbox-minimal", true)
    --checkbg:SetTexture(130755) -- Interface\\Buttons\\UI-CheckBox-Up

    local check = frame:CreateTexture(nil, "OVERLAY")
    check:SetAllPoints(checkbg)
    check:SetAtlas("checkmark-minimal", true)
    --check:SetTexture(130751) -- Interface\\Buttons\\UI-CheckBox-Check

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetHeight(18)
    text:SetPoint("LEFT", checkbg, "RIGHT")
    text:SetPoint("RIGHT")

    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAtlas("checkbox-minimal", true)
    --highlight:SetTexture(130753) -- Interface\\Buttons\\UI-CheckBox-Highlight
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(checkbg)

    local image = frame:CreateTexture(nil, "OVERLAY", nil, 0)
    image:SetHeight(18)
    image:SetWidth(18)
    image:SetPoint("LEFT", checkbg, "RIGHT", 1, 0)

    local border = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    border:SetAllPoints(image)

    local overlay = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    overlay:SetAllPoints(image)

    local widget = {
        checkbg = checkbg,
        background = background,
        check = check,
        text = text,
        highlight = highlight,
        image = image,
        border = border,
        overlay = overlay,
        frame = frame,
        type = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
