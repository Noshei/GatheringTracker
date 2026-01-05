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
    GT.Debug("Reset Session", 1)

    GT.Timer:Stop()
    for itemID, itemData in pairs(GT.InventoryData) do
        itemData.startAmount = itemData.count
        itemData.sessionCount = 0
    end

    if GT.db.profile.General.sessionOnly then
        GT.AlertSystem:ResetAlerts()
    end

    GT:RefreshPerHourDisplay(false)
    GT:RebuildDisplay("Reset Session")
end

function GT:StartSession()
    GT.Debug("Start Session", 1)

    GT.Timer:Start()
end

function GT:PauseSession()
    GT.Debug("Pause Session", 1)

    GT.Timer:Pause()
end

function GT:ToggleSessionDisplay()
    GT.Debug("Toggle Hide Session Display", 1)

    GT.db.profile.General.hideSession = not GT.db.profile.General.hideSession
    GT:RebuildDisplay("Toggle Hide Session Displays")
    GT.Timer:ToggleControls()
end
