---@class GT : AceEvent-3.0, AceComm-3.0
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

-- Localize global functions
local pairs = pairs

GT.GroupMode = {}

function GT.GroupMode:Enable()
    GT:RegisterComm("GT_Data", "DataMessageReceived")
end

function GT.GroupMode:Disable()
    GT:UnregisterComm("GT_Data")
end

function GT.GroupMode:SetChatType()
    if IsInRaid() then
        return "RAID"
    end
    if IsInGroup() then
        return "PARTY"
    end
end

--- Creates the message string to send to other party members
---@param event any calling function
---@param wait any if true we will wait a bit to avoid issues
function GT:CreateDataMessage(event, wait)
    GT.Debug("CreateDataMessage", 1, event)
    if wait then
        GT:wait(0.1, "CreateDataMessage", "CreateDataMessage", false)
        return
    end
    local updateMessage = ""

    for id, itemData in pairs(GT.InventoryData) do
        if not id == 3 then
            updateMessage = updateMessage .. id .. "=" .. itemData.count
        end
    end

    GT.Debug("Inventory Update Data Message", 2, updateMessage)

    GT:SendDataMessage(updateMessage)
end

--- Send addon message to other characters in group
---@param updateMessage string message string to send to group that is formatted with id=count and space seperated
function GT:SendDataMessage(updateMessage)
    local chatType = GT.GroupMode:SetChatType()

    GT.Debug("Sent Group Message", 2, updateMessage, chatType)
    GT:SendCommMessage("GT_Data", updateMessage, chatType, nil, "NORMAL")
end
