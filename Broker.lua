---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local ldb = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

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

function GT:InitializeBroker()
    GT.Debug("InitializeBroker", 1)
    -- Create LibDataBroker data object
    local dataObj = ldb:NewDataObject(GT.metaData.name, {
        type = "launcher",
        icon = "Interface\\Addons\\GatheringTracker\\Media\\GT_Icon",
        OnClick = function(frame, button)
            if button == "LeftButton" then
                GT:GenerateFiltersMenu(frame)
            elseif button == "RightButton" then
                Settings.OpenToCategory(GT.metaData.name, true)
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(GT.metaData.name .. " |cffff6f00v" .. GT.metaData.version .. "|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cff8080ffLeft-Click|r to open the Filter Menu")
            tooltip:AddLine("|cff8080ffRight-Click|r to open the addon options")
        end,
    })

    -- Register with LibDBIcon
    LibDBIcon:Register(GT.metaData.name, dataObj, GT.db.profile.miniMap)
end

function GT:MinimapHandler(key)
    GT.Debug("MinimapHandler", 1, key)
    if key then
        LibDBIcon:Show(GT.metaData.name)
    else
        LibDBIcon:Hide(GT.metaData.name)
    end
end
