---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

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

function GT:ToggleGatheringTracker()
    GT.Debug("Toggle Gathering Tracker", 1, GT.db.profile.General.enable)
    local key = not GT.db.profile.General.enable
    GT.db.profile.General.enable = key
    GT.Enabled = key
    if key then
        GT:OnEnable()
        GT:FiltersButton()
        GT:InventoryUpdate("Toggle Gathering Tracker", true)
    elseif not key then
        GT:OnDisable()
        GT:ClearDisplay()
        GT:FiltersButton()
    end
end

function GT:ToggleGroupMode(settingKey)
    GT.Debug("Toggle Group Mode", 1, GT.db.profile.General.groupType, settingKey)
    if settingKey then
        GT.db.profile.General.groupType = settingKey
    else
        if GT.db.profile.General.groupType == 0 then
            GT.db.profile.General.groupType = 1
        elseif GT.db.profile.General.groupType > 0 then
            GT.db.profile.General.groupType = 0
        end
    end
    local key = GT.db.profile.General.groupType
    local mode = "Enabled"
    local color = "ff00ff"

    GT:SetChatType()

    if key > 0 then
        if IsInRaid() or IsInGroup() then
            mode = "Enabled"
            color = "00ff00"
        else
            mode = "Enabled, but you aren't in a group"
            color = "ff0000"
        end
    else
        mode = "Disabled"
        color = "ff0000"
    end

    if GT:CheckModeStatus() then
        GT:InventoryUpdate("Group Mode Toggle", true)
    else
        GT:ClearDisplay()
    end

    ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. ":|r |cff" .. color .. "Group Mode " .. mode .. "|r")
end

function GT:ToggleCountNotifications()
    GT.Debug("Toggle Count Notifications", 1, GT.db.profile.Notifications.Count.enable)
    local key = not GT.db.profile.Notifications.Count.enable
    GT.db.profile.Notifications.Count.enable = key
end

function GT:ToggleGoldNotifications()
    GT.Debug("Toggle Gold Notifications", 1, GT.db.profile.Notifications.Gold.enable)
    local key = not GT.db.profile.Notifications.Gold.enable
    GT.db.profile.Notifications.Gold.enable = key
end

function GT:ClearFilters()
    --disables all enabled filters
    GT.Debug("Clear Filters", 1)

    for id, value in pairs(GT.db.profile.Filters) do
        GT.db.profile.Filters[id] = nil
    end
    for id, value in pairs(GT.db.profile.CustomFiltersTable) do
        GT.db.profile.CustomFiltersTable[id] = false
    end

    GT:RebuildIDTables()
    GT:ClearDisplay()
end

function GT:ResetSession()
    --resets the per hour displays to current time and values
    GT.Debug("Reset Per Hour", 1)

    GT.GlobalStartTime = time()
    for itemID, itemData in pairs(GT.InventoryData) do
        itemData.startTime = time()
        itemData.startAmount = {}
        for senderIndex, value in ipairs(itemData.counts) do
            itemData.startAmount[senderIndex] = value
            itemData.sessionCounts[senderIndex] = 0
        end
        itemData.startTotal = GT:SumTable(itemData.startAmount)
    end
    for senderIndex, senderData in ipairs(GT.sender) do
        senderData.sessionData = {}
    end
    GT:RefreshPerHourDisplay(false, true)
    GT:RebuildDisplay("Reset Session")
end
