-- Widget is based on the AceGUIWidget-DropDown.lua supplied with AceGUI-3.0
-- Widget created by Yssaril
-- Forked from AceGUISharedMediaWidgets-1.0 to modify for my own use by Noshei

local AceGUI = LibStub("AceGUI-3.0")
local Media = LibStub("LibSharedMedia-3.0")

local AGNW = LibStub("AceGUI-3.0-NosheiWidgets-1.0")

do
    local widgetType = "NW_Sound"
    local widgetVersion = 1

    local contentFrameCache = {}
    local function ReturnSelf(self)
        self:ClearAllPoints()
        self:Hide()
        --self.check:Hide()
        table.insert(contentFrameCache, self)
    end

    local function ContentOnClick(this, button)
        local self = this.obj
        self:Fire("OnValueChanged", this.text:GetText())
        if self.dropdown then
            self.dropdown = AGNW:ReturnDropDownFrame(self.dropdown)
        end
    end

    local function ContentSpeakerOnClick(this, button)
        local self = this.frame.obj
        local sound = this.frame.text:GetText()
        PlaySoundFile(self.list[sound] ~= sound and self.list[sound] or Media:Fetch('sound', sound), "Master")
    end

    local function GetContentLine()
        local frame
        if next(contentFrameCache) then
            frame = table.remove(contentFrameCache)
        else
            frame = CreateFrame("Button", nil, UIParent)
            --frame:SetWidth(200)
            frame:SetHeight(18)
            --frame:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")
            frame:SetScript("OnClick", ContentOnClick)
            --[[local check = frame:CreateTexture("OVERLAY")
            check:SetWidth(16)
            check:SetHeight(16)
            check:SetPoint("LEFT", frame, "LEFT", 1, -1)
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:Hide()
            frame.check = check]]

            local highlight = frame:CreateTexture(nil, "OVERLAY")
            highlight:SetAtlas("common-dropdown-customize-mouseover", true)
            highlight:SetHeight(18)
            highlight:ClearAllPoints()
            highlight:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
            highlight:SetPoint("LEFT", frame, "LEFT", 1, 0)
            highlight:SetAlpha(0)
            frame.highlight = highlight

            local soundbutton = CreateFrame("Button", nil, frame)
            soundbutton:SetWidth(16)
            soundbutton:SetHeight(16)
            soundbutton:SetPoint("RIGHT", frame, "RIGHT", -3, 0)
            soundbutton.frame = frame
            soundbutton:SetScript("OnClick", ContentSpeakerOnClick)
            frame.soundbutton = soundbutton

            local speaker = soundbutton:CreateTexture(nil, "BACKGROUND")
            speaker:SetTexture("Interface\\Common\\VoiceChat-Speaker")
            speaker:SetAllPoints(soundbutton)
            frame.speaker = speaker
            local speakeron = soundbutton:CreateTexture(nil, "HIGHLIGHT")
            speakeron:SetTexture("Interface\\Common\\VoiceChat-On")
            speakeron:SetAllPoints(soundbutton)
            frame.speakeron = speakeron

            local text = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            text:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, 0)
            text:SetPoint("BOTTOMRIGHT", soundbutton, "BOTTOMLEFT", -2, 0)
            text:SetJustifyH("LEFT")
            text:SetText("Test Test Test Test Test Test Test")
            frame.text = text
            frame.ReturnSelf = ReturnSelf

            frame:SetScript("OnEnter", function(self)
                self.highlight:SetAlpha(0.25)
            end)
            frame:SetScript("OnLeave", function(self)
                self.highlight:SetAlpha(0)
            end)
        end
        frame:Show()
        return frame
    end

    local function OnAcquire(self)
        self:SetHeight(44)
        self:SetWidth(200)
    end

    local function OnRelease(self)
        self:SetText("")
        self:SetLabel("")
        self:SetDisabled(false)

        self.value = nil
        self.list = nil
        self.open = nil
        self.hasClose = nil

        self.frame:ClearAllPoints()
        self.frame:Hide()
    end

    local function SetValue(self, value) -- Set the value to an item in the List.
        if self.list then
            self:SetText(value or "")
        end
        self.value = value
    end

    local function GetValue(self)
        return self.value
    end

    local function SetList(self, list) -- Set the list of values for the dropdown (key => value pairs)
        self.list = list or Media:HashTable("sound")
    end

    local function SetText(self, text) -- Set the text displayed in the box.
        --self.frame.text:SetText(text or "")
        self.frame.dropButton.Text:SetText(text or "")
    end

    local function SetLabel(self, text) -- Set the text for the label.
        self.frame.label:SetText(text or "")
    end

    local function AddItem(self, key, value) -- Add an item to the list.
        self.list = self.list or {}
        self.list[key] = value
    end
    local SetItemValue = AddItem                     -- Set the value of a item in the list. <<same as adding a new item>>

    local function SetMultiselect(self, flag) end    -- Toggle multi-selecting. <<Dummy function to stay inline with the dropdown API>>
    local function GetMultiselect() return false end -- Query the multi-select flag. <<Dummy function to stay inline with the dropdown API>>
    local function SetItemDisabled(self, key) end    -- Disable one item in the list. <<Dummy function to stay inline with the dropdown API>>

    local function SetDisabled(self, disabled)       -- Disable the widget.
        self.disabled = disabled
        if disabled then
            self.frame:Disable()
            self.speaker:SetDesaturated(true)
            self.speakeron:SetDesaturated(true)
        else
            self.frame:Enable()
            self.speaker:SetDesaturated(false)
            self.speakeron:SetDesaturated(false)
        end
    end

    local function textSort(a, b)
        return string.upper(a) < string.upper(b)
    end

    local sortedlist = {}
    local function ToggleDrop(this)
        local self = this.obj
        if self.dropdown then
            self.dropdown = AGNW:ReturnDropDownFrame(self.dropdown)
            AceGUI:ClearFocus()
        else
            AceGUI:SetFocus(self)
            self.dropdown = AGNW:GetDropDownFrame()
            local width = self.frame:GetWidth()
            self.dropdown:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT")
            self.dropdown:SetPoint("TOPRIGHT", self.frame, "BOTTOMRIGHT", width < 160 and (160 - width) or 0, 0)
            for k, v in pairs(self.list) do
                sortedlist[#sortedlist + 1] = k
            end
            table.sort(sortedlist, textSort)
            for i, k in ipairs(sortedlist) do
                local f = GetContentLine()
                f.text:SetText(k)
                if k == self.value then
                    --f.check:Show()
                    f.text:SetTextColor(1, .82, 0)
                else
                    f.text:SetTextColor(1, 1, 1)
                end
                f.obj = self
                self.dropdown:AddFrame(f)
            end
            wipe(sortedlist)
        end
    end

    local function ClearFocus(self)
        if self.dropdown then
            self.dropdown = AGNW:ReturnDropDownFrame(self.dropdown)
        end
    end

    local function OnHide(this)
        local self = this.obj
        if self.dropdown then
            self.dropdown = AGNW:ReturnDropDownFrame(self.dropdown)
        end
    end

    local function Drop_OnEnter(this)
        if this.obj.frame.dropButton:IsEnabled() then
            this.obj.frame.dropButton.over = true;
            this.obj.frame.dropButton:OnButtonStateChanged();
        end
        this.obj:Fire("OnEnter")
    end

    local function Drop_OnLeave(this)
        if this.obj.frame.dropButton:IsEnabled() then
            this.obj.frame.dropButton.over = nil;
            this.obj.frame.dropButton:OnButtonStateChanged();
        end
        this.obj:Fire("OnLeave")
    end

    local function WidgetPlaySound(this)
        local self = this.obj
        local sound = self.frame.dropButton.Text:GetText()
        PlaySoundFile(self.list[sound] ~= sound and self.list[sound] or Media:Fetch('sound', sound), "Master")
    end

    local function Constructor()
        local frame = AGNW:GetBaseFrame()
        local self = {}

        self.type = widgetType
        self.frame = frame
        frame.obj = self
        frame.dropButton.obj = self
        frame.dropButton:SetScript("OnEnter", Drop_OnEnter)
        frame.dropButton:SetScript("OnLeave", Drop_OnLeave)
        frame.dropButton:SetScript("OnClick", ToggleDrop)
        frame:SetScript("OnHide", OnHide)


        local soundbutton = CreateFrame("Button", nil, frame)
        soundbutton:SetWidth(16)
        soundbutton:SetHeight(16)
        soundbutton:SetFrameStrata("HIGH")
        soundbutton:SetPoint("LEFT", frame.dropButton, "LEFT", 10, 0)
        soundbutton:SetScript("OnClick", WidgetPlaySound)
        soundbutton.obj = self
        self.soundbutton = soundbutton
        frame.dropButton.Text:SetPoint("LEFT", soundbutton, "RIGHT", 2, 0)


        local speaker = soundbutton:CreateTexture(nil, "BACKGROUND")
        speaker:SetTexture("Interface\\Common\\VoiceChat-Speaker")
        speaker:SetAllPoints(soundbutton)
        self.speaker = speaker
        local speakeron = soundbutton:CreateTexture(nil, "HIGHLIGHT")
        speakeron:SetTexture("Interface\\Common\\VoiceChat-On")
        speakeron:SetAllPoints(soundbutton)
        self.speakeron = speakeron

        self.alignoffset = 31

        self.OnRelease = OnRelease
        self.OnAcquire = OnAcquire
        self.ClearFocus = ClearFocus
        self.SetText = SetText
        self.SetValue = SetValue
        self.GetValue = GetValue
        self.SetList = SetList
        self.SetLabel = SetLabel
        self.SetDisabled = SetDisabled
        self.AddItem = AddItem
        self.SetMultiselect = SetMultiselect
        self.GetMultiselect = GetMultiselect
        self.SetItemValue = SetItemValue
        self.SetItemDisabled = SetItemDisabled
        self.ToggleDrop = ToggleDrop

        AceGUI:RegisterAsWidget(self)
        return self
    end

    AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
