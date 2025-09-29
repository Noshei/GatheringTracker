---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local ldb = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

function GT:InitializeBroker()
    GT.Debug("InitializeBroker", 1)
    -- Create LibDataBroker data object
    local dataObj = ldb:NewDataObject(GT.metaData.name, {
        type = "launcher",
        icon = "Interface\\Addons\\GatheringTracker\\Media\\GT_Icon",
        OnClick = function(frame, button)
            if button == "LeftButton" and IsShiftKeyDown() then
                GT:ResetSession()
            elseif button == "LeftButton" then
                GT:GenerateFiltersMenu(frame)
            elseif button == "RightButton" and IsShiftKeyDown() then
                GT.AlertSystem:ResetAlerts()
            elseif button == "RightButton" then
                Settings.OpenToCategory(GT.metaData.name, true)
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(GT.metaData.name .. " |cffff6f00v" .. GT.metaData.version .. "|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cff8080ffLeft-Click|r to open the Filter Menu")
            tooltip:AddLine("|cff8080ffShift + Left-Click|r to reset Session")
            tooltip:AddLine("|cff8080ffRight-Click|r to open the addon options")
            tooltip:AddLine("|cff8080ffShift + Right-Click|r to reset Alert Triggers")
        end,
    })

    -- Register with LibDBIcon
    LibDBIcon:Register(GT.metaData.name, dataObj, GT.db.profile.miniMap)
    --LibDBIcon:Hide(GT.metaData.name)
end

function GT:MinimapHandler(key)
    GT.Debug("MinimapHandler", 1, key)
    if key then
        LibDBIcon:Show(GT.metaData.name)
    else
        LibDBIcon:Hide(GT.metaData.name)
    end
end
