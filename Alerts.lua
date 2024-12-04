---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

-- Localize global functions
local ipairs = ipairs
local math = math
local max = max
local next = next
local pairs = pairs
local select = select
local string = string
local table = table
local time = time
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

GT.AlertSystem = {}
GT.AlertSystem.AllowAlertEffects = false
GT.Alerts = {}

function GT:AllowAlertEffects(event)
    GT.Debug("Allow Alert Effects", 1)
    if event == "AllowAlertEffects" then
        GT.AlertSystem.AllowAlertEffects = true
    end
end

function GT.AlertSystem:CreateAlertFrames()
    GT.Display.Alerts = GT.Display.Alerts or {}
    local flash = CreateFrame("Frame", "GT_Alerts_ScreenFlash", UIParent)
    flash:SetAllPoints(UIParent)
    flash:SetFrameStrata("TOOLTIP")
    flash:Hide()

    flash.texture = flash:CreateTexture("GT_Alerts_ScreenFlash_Texture")
    flash.texture:SetTexture("Interface\\Addons\\GatheringTracker\\Media\\ScreenFlash")
    flash.texture:SetAllPoints(flash)
    flash.texture:SetBlendMode("ADD")

    ---@class animGroup: AnimationGroup
    local animGroup = flash:CreateAnimationGroup()
    animGroup.FadeIn = animGroup:CreateAnimation("Alpha")
    animGroup.FadeIn:SetParent(animGroup, 1)
    animGroup.FadeOut = animGroup:CreateAnimation("Alpha")
    animGroup.FadeOut:SetParent(animGroup, 2)

    animGroup.FadeIn:SetFromAlpha(0)
    animGroup.FadeIn:SetToAlpha(1)

    animGroup.FadeOut:SetFromAlpha(1)
    animGroup.FadeOut:SetToAlpha(0)

    flash.animGroup = animGroup

    function flash.SetDuration(self, duration)
        animGroup.FadeIn:SetDuration(duration * (1 / 4))
        animGroup.FadeIn:SetStartDelay(0)
        animGroup.FadeIn:SetEndDelay(0)
        animGroup.FadeOut:SetDuration(duration * (3 / 4))
        animGroup.FadeOut:SetStartDelay(0)
        animGroup.FadeOut:SetEndDelay(0, true)
    end

    function flash.PlayAnimation()
        flash:Show()
        animGroup:Play()
        animGroup:SetToFinalAlpha(true)
    end

    GT.Display.Alerts.ScreenFlash = flash

    -- Commented this out as I'm not implmenting it right now, but will return to it in the future.
    --[[local text = CreateFrame("Frame", "GT_Alerts_TextPopup", GT.baseFrame.frame)
    text:SetPoint("CENTER")
    text:SetFrameStrata("TOOLTIP")

    text.texture = text:CreateFontString("GT_Alerts_TextPopup_Texture")
    text.texture:SetAllPoints(text)
    text.texture:Hide()

    text.mover = CreateFrame("Frame", "GT_Alerts_TextPopup_Mover", text, BackdropTemplateMixin and "BackdropTemplate")
    text.mover:SetWidth(300)
    text.mover:SetHeight(300)
    text.mover:SetAllPoints(text)
    text.mover:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 },
    })
    text.mover:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    text.mover:SetBackdropBorderColor(0.4, 0.4, 0.4)
    text.mover:SetFrameStrata("FULLSCREEN_DIALOG")
    text.mover:SetClampedToScreen(true)
    text.mover:SetMouseClickEnabled(false)

    GT.Display.Alerts.TextPopup = text]]
end

---Entry point to the Alert System
---@param itemID number ID of the item to run the alert system for
---@param displayText table|number
---@param priceTotalItem? number
function GT.AlertSystem:Alerts(itemID, displayText, priceTotalItem)
    if not GT.db.profile.General.alertsEnable then
        return
    end
    local itemValue = GT.AlertSystem:GetItemValue(displayText)
    GT.Debug("Alerts Initial", 3, itemID, itemValue, priceTotalItem)

    local item = GT.AlertSystem:GetItem(itemID, true)
    local allItems = GT.AlertSystem:GetItem(1, true)
    if not item and not allItems then
        return
    end

    local triggers = { itemValue, priceTotalItem }
    local triggeredAlerts = GT.AlertSystem:GetTriggeredAlerts(itemID, item, allItems, triggers)
    if #triggeredAlerts == 0 then
        return
    end
    for _, alert in ipairs(triggeredAlerts) do
        GT.AlertSystem:TriggerAlert(alert, triggers[alert:GetTriggerType()], itemID)
    end
end

---Simplifies the provided displayText to a single number instead of leaving it as a potential table
---@param displayText number|table
---@return number
function GT.AlertSystem:GetItemValue(displayText)
    local itemValue = 0
    if type(displayText) == "table" then
        itemValue = displayText[1]
    else
        itemValue = displayText
    end
    return itemValue
end

---checks if the item (or all items) has been enabled for alerts
---@param itemID number
---@return number
function GT.AlertSystem:CheckItemAlert(itemID)
    local trigger = 0
    if GT.db.profile.Alerts[itemID] and GT.db.profile.Alerts[itemID].enable then
        trigger = 1
    end
    if GT.db.profile.Alerts[1] and GT.db.profile.Alerts[1].enable then
        trigger = trigger + 2
    end
    GT.Debug("Check Item Alert", 4, itemID, trigger)
    return trigger
end

---checks the provided item and allItem objects for any alerts that should be triggered
---@param itemID number
---@param item AlertItem|nil
---@param allItems AlertItem|nil
---@param triggers table table of trigger values sorted by trigger type key
---@return table alertsToTrigger
function GT.AlertSystem:GetTriggeredAlerts(itemID, item, allItems, triggers)
    GT.Debug("GetTriggeredAlerts Initial", 2, triggers[1], triggers[2])
    local triggeredAlerts = {}

    if item then
        GT.Debug("GetTriggeredAlerts item", 4, item.itemID, #item.alerts, item.enable)
        for _, alert in ipairs(item:GetAllAlerts()) do
            if triggers[alert:GetTriggerType()] >= alert:GetTriggerValue() and alert:GetEnabled() and not alert:GetTriggered() then
                table.insert(triggeredAlerts, alert)
            end
            if alert:GetTriggered() and alert:GetAlertType() == "Highlight" and triggers[alert:GetTriggerType()] < alert:GetTriggerValue() then
                GT.AlertSystem:ClearAlert(alert)
            end
        end
    end

    if allItems then
        GT.Debug("GetTriggeredAlerts allItems", 4, allItems.itemID, #allItems.alerts, allItems.enable)
        for _, alert in ipairs(allItems:GetAllAlerts()) do
            local child = alert:GetChildAlert(itemID) or alert:AddChildAlert(itemID)
            local itemAlertExists = false
            if item and item:GetAlert(child:GetAlertType(), child:GetTypeCount()) then
                itemAlertExists = true
            end
            if not itemAlertExists and triggers[child:GetTriggerType()] >= child:GetTriggerValue() and
                child:GetEnabled() and not child:GetTriggered() then
                local alertType = child:GetAlertType()
                local triggerValue = child:GetTriggerValue()
                if #triggeredAlerts > 0 then
                    local match = false
                    for _, alertObject in ipairs(triggeredAlerts) do
                        if alertType == alertObject:GetAlertType() and triggerValue == alertObject:GetTriggerValue() then
                            match = true
                        end
                    end
                    if not match then
                        table.insert(triggeredAlerts, child)
                    end
                else
                    table.insert(triggeredAlerts, child)
                end
            end
            if child:GetTriggered() and child:GetAlertType() == "Highlight" and triggers[child:GetTriggerType()] < child:GetTriggerValue() then
                GT.AlertSystem:ClearAlert(child)
            end
        end
    end
    GT.Debug("GetTriggeredAlerts Final", 3, #triggeredAlerts)
    return triggeredAlerts
end

---comment
---@param alert Alert
---@param triggeredValue number
---@param itemID number
function GT.AlertSystem:TriggerAlert(alert, triggeredValue, itemID)
    GT.Debug("Trigger Alert", 2, alert.itemID, itemID, alert:GetAlertType(), alert:GetTriggerValue())
    alert:SetTriggered(true)

    local alertSettings = alert:GetAlertSettings()

    GT.AlertSystem:TriggerEffects(alert, alertSettings, itemID)

    if alert:GetTriggerMultiple() then
        GT.Debug("Trigger Alert: Trigger Multiple", 3, alert.itemID, alert:GetTriggerValue(), alert:GetTriggerMultiplier(), triggeredValue)
        local baseTriggerValue = alert:GetTriggerMultiplier()
        alert:SetTriggered(false)
        alert:SetTriggerValue(((math.floor(triggeredValue / baseTriggerValue) + 1) * baseTriggerValue))
    end
end

---@param alert Alert
---@param alertSettings table
---@param itemID number
function GT.AlertSystem:TriggerEffects(alert, alertSettings, itemID)
    if not GT.AlertSystem.AllowAlertEffects then
        return
    end
    if itemID == 2 then
        itemID = 9999999998
    end

    if alert:GetAlertType() == "Audio" then
        PlaySoundFile(tostring(media:Fetch("sound", alertSettings.tiggerSound)), "master")
    elseif alert:GetAlertType() == "Highlight" then
        GT.Display.Frames[itemID].highlight:SetTexture(GT.HighlightTextures[alertSettings.highlightBorder].atlas)
        GT.Display.Frames[itemID].highlight:SetVertexColor(unpack(alertSettings.highlightColor))
        GT.Display.Frames[itemID].highlight:Show()
    elseif alert:GetAlertType() == "Screen Flash" then
        GT.Display.Alerts.ScreenFlash.texture:SetVertexColor(unpack(alertSettings.flashColor))
        GT.Display.Alerts.ScreenFlash:SetDuration(alertSettings.flashDuration or 3)
        GT.Display.Alerts.ScreenFlash:PlayAnimation()
    end
end

---@param alert Alert
function GT.AlertSystem:ClearAlert(alert)
    GT.Debug("Clear Alert", 1, alert.itemID, alert:GetAlertType(), alert:GetTriggerValue())
    local itemID = alert.itemID
    if alert.itemID == 2 then
        itemID = 9999999998
    end
    GT.Display.Frames[itemID].highlight:Hide()
end

function GT.AlertSystem:ResetAlerts()
    GT.Debug("Reset Alerts", 1)
    for itemID, Item in pairs(GT.Alerts) do
        for _, Alert in ipairs(Item:GetAllAlerts(true)) do
            Alert:SetTriggered(false)
            if Alert:GetTriggerMultiple() then
                Alert:SetTriggerValue(Alert:GetTriggerMultiplier())
            end
        end
    end
end

---@param self Alert
---@param key boolean
local function SetEnabled(self, key)
    self.enable = key
end

---@param self Alert
---@return boolean enable
local function GetEnabled(self)
    return self.enable
end

---@param self Alert
---@param value number
local function SetTriggerValue(self, value)
    if value == nil then
        return
    end
    self.triggerValue = value
end

---@param self Alert
---@param triggerType number
local function SetTriggerType(self, triggerType)
    if triggerType == nil then
        return
    end
    self.triggerType = triggerType
end

---@param self Alert
---@param triggered boolean
local function SetTriggered(self, triggered)
    if triggered == nil then
        return
    end
    self.triggered = triggered
end

---@param self Alert
---@param typeCount number
local function SetTypeCount(self, typeCount)
    if typeCount == nil then
        return
    end
    self.typeCount = typeCount
end

---@param self Alert
---@param triggerMultiple boolean
local function SetTriggerMultiple(self, triggerMultiple)
    if triggerMultiple == nil then
        return
    end
    self.triggerMultiple = triggerMultiple
end

---@param self Alert
---@param triggerMultiplier number
local function SetTriggerMultiplier(self, triggerMultiplier)
    if triggerMultiplier == nil then
        return
    end
    self.triggerMultiplier = triggerMultiplier
end

---@param self Alert
---@param settings table
local function SetAlertSettings(self, settings)
    if settings == nil then
        return
    end
    self.alertSettings = settings
end

---@param self Alert
---@return number triggerValue
local function GetTriggerValue(self)
    return self.triggerValue
end

---@param self Alert
---@return number triggerType
local function GetTriggerType(self)
    return self.triggerType
end

---@param self Alert
---@return boolean triggered
local function GetTriggered(self)
    return self.triggered
end

---@param self Alert
---@return string alertType
local function GetAlertType(self)
    return self.alertType
end

---@param self Alert
---@return number typeCount
local function GetTypeCount(self)
    return self.typeCount
end

---@param self Alert
---@return boolean triggerMultiple
local function GetTriggerMultiple(self)
    return self.triggerMultiple
end

---@param self Alert
---@return number triggerMultiplier
local function GetTriggerMultiplier(self)
    return self.triggerMultiplier
end

---@param self Alert
---@return boolean enable
local function GetAlertSettings(self)
    return self.alertSettings
end

local function AddChildAlert(self, itemID)
    local child = {
        triggered = false,
        triggerValue = self:GetTriggerValue(),
        triggerMultiplier = self:GetTriggerMultiplier(),
        itemID = itemID,

        GetTriggered = GetTriggered,
        GetTriggerValue = GetTriggerValue,
        GetTriggerMultiplier = GetTriggerMultiplier,
        SetTriggered = SetTriggered,
        SetTriggerValue = SetTriggerValue
    }
    local metatable = {
        __index = {
            alertType = self.alertType,
            typeCount = self.typeCount,
            triggerMultiple = self.triggerMultiple,
            enable = self.enable,
            triggerType = self.triggerType,
            alertSettings = self.alertSettings,

            GetEnabled = self.GetEnabled,
            GetTriggerType = self.GetTriggerType,
            GetAlertType = self.GetAlertType,
            GetTypeCount = self.GetTypeCount,
            GetTriggerMultiple = self.GetTriggerMultiple,
            GetAlertSettings = self.GetAlertSettings,
        },
    }
    setmetatable(child, metatable)
    self.child[itemID] = child

    return child
end

local function GetChildAlert(self, itemID)
    return self.child[itemID]
end

---@alias Alert table
---@param self Alert
---@param alertType string
---@param typeCount number
---@param triggerValue number
---@return Alert
local function AddAlert(self, alertType, typeCount, triggerValue)
    local alert = {}
    alert.alertType = alertType
    alert.typeCount = typeCount
    alert.triggerValue = triggerValue
    alert.triggered = false
    alert.triggerMultiple = false
    alert.triggerMultiplier = 0
    alert.itemID = self.itemID
    alert.enable = false
    alert.triggerType = 1
    alert.alertSettings = {}
    alert.child = {}

    -- Methods
    alert.SetEnabled = SetEnabled
    alert.GetEnabled = GetEnabled
    alert.SetTriggerValue = SetTriggerValue
    alert.SetTriggerType = SetTriggerType
    alert.SetTriggered = SetTriggered
    alert.SetTypeCount = SetTypeCount
    alert.SetTriggerMultiple = SetTriggerMultiple
    alert.SetTriggerMultiplier = SetTriggerMultiplier
    alert.SetAlertSettings = SetAlertSettings
    alert.GetTriggerValue = GetTriggerValue
    alert.GetTriggerType = GetTriggerType
    alert.GetTriggered = GetTriggered
    alert.GetAlertType = GetAlertType
    alert.GetTypeCount = GetTypeCount
    alert.GetTriggerMultiple = GetTriggerMultiple
    alert.GetTriggerMultiplier = GetTriggerMultiplier
    alert.GetAlertSettings = GetAlertSettings

    alert.AddChildAlert = AddChildAlert
    alert.GetChildAlert = GetChildAlert

    table.insert(self.alerts, alert)
    return alert
end

local function RemoveAlert(self, alert)
    for index, alertObject in ipairs(self.alerts) do
        if alert == alertObject then
            alertObject = nil
            table.remove(self.alerts, index)
        end
    end
end

---@param self Alert
---@param alertType string
---@param typeCount number
---@return table|nil
local function GetAlert(self, alertType, typeCount)
    for _, alert in ipairs(self.alerts) do
        if alert.alertType == alertType and alert.typeCount == typeCount then
            return alert
        end
    end
end

---@param self AlertItem
---@param includeChildAlerts boolean
---@return table|nil
local function GetAllAlerts(self, includeChildAlerts)
    if includeChildAlerts then
        local alerts = {}
        for _, alert in ipairs(self.alerts) do
            table.insert(alerts, alert)
            if next(alert.child) ~= nil then
                for itemID, child in pairs(alert.child) do
                    table.insert(alerts, child)
                end
            end
        end
        return alerts
    end
    return self.alerts
end

---@alias AlertItem table
---@param itemID number
---@return AlertItem
function GT.AlertSystem:AddItem(itemID)
    local item = {}
    item.alerts = {}
    item.itemID = itemID
    item.enable = true

    -- Methods
    item.SetEnabled = SetEnabled
    item.GetEnabled = GetEnabled
    item.AddAlert = AddAlert
    item.RemoveAlert = RemoveAlert
    item.GetAlert = GetAlert
    item.GetAllAlerts = GetAllAlerts

    GT.Alerts[itemID] = item

    return item
end

---@param itemID number
---@param returnEnabledOnly? boolean
---@return AlertItem|nil
function GT.AlertSystem:GetItem(itemID, returnEnabledOnly)
    if not GT.Alerts[itemID] then
        return
    end
    if returnEnabledOnly and not GT.Alerts[itemID]:GetEnabled() then
        return
    end
    return GT.Alerts[itemID]
end

---@param itemID number
function GT.AlertSystem:RemoveItem(itemID)
    if not GT.Alerts[itemID] then
        return
    end
    GT.Alerts[itemID] = nil
end

function GT.AlertSystem:RemoveAllItems(event)
    if event ~= "Refresh Config" then
        return
    end
    GT.Alerts = {}
end
