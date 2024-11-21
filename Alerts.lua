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
GT.Alerts = {}

---Entry point to the Alert System
---@param itemID number ID of the item to run the alert system for
---@param displayText table|number
---@param priceTotalItem? number
function GT.AlertSystem:Alerts(itemID, displayText, priceTotalItem)
    GT.Debug("Alerts Initial", 3, itemID, displayText, priceTotalItem)
    local checkAlerts = GT.AlertSystem:CheckItemAlert(itemID)
    if checkAlerts == 0 then
        return
    end
    local triggeredAlerts = {}
    if checkAlerts == 1 or checkAlerts == 3 then
        triggeredAlerts = GT.AlertSystem:GetTriggeredAlerts(itemID, displayText, priceTotalItem)
    end
    --If the "All Items" alert is enabled, this will add the enabled alerts to the triggeredAlerts table to be triggered
    if checkAlerts == 2 or checkAlerts == 3 then
        local allItemAlerts = GT.AlertSystem:GetTriggeredAlerts(1, displayText, priceTotalItem)
        if #allItemAlerts > 0 then
            for _, alertTable in ipairs(allItemAlerts) do
                table.insert(triggeredAlerts, alertTable)
            end
        end
    end
    if #triggeredAlerts == 0 then
        return
    end
    GT.Debug("Alerts", 1, itemID, displayText, priceTotalItem)
    for _, alertTable in ipairs(triggeredAlerts) do
        GT.AlertSystem:TriggerAlert(itemID, alertTable)
    end
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

function GT.AlertSystem:GetTriggeredAlerts(itemID, displayText, priceTotalItem)
    GT.Debug("GetTriggeredAlerts Initial", 2, itemID, displayText, priceTotalItem)
    local triggered = {}
    if GT:GetArraySize(GT.db.profile.Alerts[itemID].alerts) > 0 then
        GT.Debug("GetTriggeredAlerts 1", 3, itemID)
        for alertType, alerts in pairs(GT.db.profile.Alerts[itemID].alerts) do
            for index, alert in ipairs(alerts) do
                if alert.enable and GT.AlertSystem:CheckTrigger(alert, displayText, priceTotalItem) then
                    GT.Debug("GetTriggeredAlerts 2", 4, itemID)
                    local alertData = {
                        type = alertType,
                        index = index,
                        data = alert,
                    }
                    table.insert(triggered, alertData)
                end
            end
        end
    end
    GT.Debug("GetTriggeredAlerts", 2, itemID, displayText, priceTotalItem)
    return triggered
end

function GT.AlertSystem:CheckTrigger(alert, displayText, priceTotalItem)
    GT.Debug("CheckTrigger", 2, displayText, priceTotalItem)
    local itemValue = 0
    if alert.triggerType == 1 then
        if type(displayText) == "table" then
            itemValue = displayText[1]
        else
            itemValue = displayText
        end
    elseif alert.triggerType == 2 then
        itemValue = priceTotalItem
    end

    if itemValue >= alert.triggerValue then
        if alert.triggerMultiple then
            if itemValue >= alert.triggerValueMultiple then
                local triggerDiff = itemValue - alert.triggerValueMultiple
                if triggerDiff <= alert.triggerValue then
                    alert.triggerValueMultiple = alert.triggerValueMultiple + alert.triggerValue
                else
                    alert.triggerValueMultiple = alert.triggerValueMultiple +
                        ((math.floor(triggerDiff / alert.triggerValue) + 1) * alert.triggerValue)
                end
            else
                return false
            end
        end
        return true
    end
    return false
end

function GT.AlertSystem:TriggerAlert(itemID, alertTable)
    GT.Debug("Trigger Alert", 2, itemID, alertTable.type, alertTable.index)
end

---@param self Alert
---@param value number
local function SetAlertTriggerValue(self, value)
    self.triggerValue = value
end

---@param self Alert
---@param triggered boolean
local function SetAlertTriggered(self, triggered)
    self.triggered = triggered
end


local function CreateAlertFrame(self)

end


local function GetAlertFrame(self)

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

    -- Methods
    alert.SetAlertTriggerValue = SetAlertTriggerValue
    alert.SetAlertTriggered = SetAlertTriggered
    alert.CreateAlertFrame = CreateAlertFrame
    alert.GetAlertFrame = GetAlertFrame

    self[alertType] = self[alertType] or {}
    self[alertType][typeCount] = alert

    return alert
end

---@param self Alert
---@param alertType string
---@param typeCount number
---@return table|nil
local function GetAlert(self, alertType, typeCount)
    if not self[alertType] then
        return nil
    end
    if not self[alertType][typeCount] then
        return nil
    end
    return self[alertType][typeCount]
end

---@alias AlertItem table
---@param itemID number
---@return AlertItem
function GT.AlertSystem:AddItem(itemID)
    local item = {}

    -- Methods
    item.AddAlert = AddAlert
    item.GetAlert = GetAlert

    GT.Alerts[itemID] = item

    return item
end

---@param itemID number
---@return AlertItem|nil
function GT.AlertSystem:GetItem(itemID)
    if not GT.Alerts[itemID] then
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
