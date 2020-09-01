GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local GT = GatheringTracker

GT.metaData = {
    name = GetAddOnMetadata("GatheringTracker", "Title"),
    version = GetAddOnMetadata("GatheringTracker", "Version"),
    notes = GetAddOnMetadata("GatheringTracker", "Notes"),
}

function GT:OnInitialize()
--may not be used as OnEnable is likely to be better so that we can handle enable/disable without requiring a full UI reload.
end

function GT:OnEnable()
    GT.Enabled = true
    --use this for both initial setup on UI load and when the addon is enabled from the settings
    print("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 ENABLED|r")
    
    --Register events for updating item details
    GT:RegisterEvent("BAG_UPDATE", "InventoryUpdate")
    GT:RegisterEvent("PLAYER_ENTERING_WORLD", "InventoryUpdate")
    
    --Register addon comm's
    GT:RegisterComm("GT_Data", "DataUpdateReceived")
    GT:RegisterComm("GT_Config", "ConfigUpdateReceived")

end

function GT:OnDisable()
    GT.Enabled = false
    --Use this for disabling the addon from the settings
    --stop event tracking and turn off display
    print("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cffff0000 DISABLED|r")
    
    --Unregister events so that we can stop working when disabled
    GT:UnregisterEvent("BAG_UPDATE")
    GT:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    --Unregister addon comm's
    GT:UnregisterComm("GT_Data")
    GT:UnregisterComm("GT_Config")
end

function GT:CreateBaseFrame()
    local frame = CreateFrame("Frame", "GT_baseFrame", UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    
    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", frame)
    backdrop:SetWidth(GT.db.profile.General.iconWidth * 10)
    backdrop:SetHeight(GT.db.profile.General.iconHeight * 10)
    backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
    backdrop:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 3, right = 3, top = 5, bottom = 3}})
    backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    backdrop:SetBackdropBorderColor(0.4, 0.4, 0.4)
    
    backdrop:Hide()
    
    local baseFrame = {
        frame = frame,
        backdrop = backdrop
    }
    GT.baseFrame = baseFrame
end

function GT:ToggleBaseLock(key)
    --used to toggle if the base frame should be shown and interactable.
    --the base frame should only be shown when unlocked so that the user can position it on screen where they want.
    local frame = GT.baseFrame.backdrop
    if key then
        frame:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving();
                self.isMoving = true;
            end
        end)
        frame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                self:StopMovingOrSizing();
                self.isMoving = false;
                local rel,_,_,xPos,yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
        frame:SetScript("OnHide", function(self)
            if (self.isMoving) then
                self:StopMovingOrSizing();
                self.isMoving = false;
                local rel,_,_,xPos,yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
    else
        frame:Hide()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
        frame:SetScript("OnHide", nil)
    end
end

InterfaceOptionsFrame:HookScript("OnHide", function()
        --locks the base frame if the options are closed without first locking it.
        if GT.db.profile.General.unlock then
            GT.db.profile.General.unlock = false
            GT:ToggleBaseLock(false)
        end
end)

function GT:RebuildIDTables()
    --Not using IDsArray from WA as it will be replaced by the frame structure
    GT.IDs = {}
    for key, value in pairs(GT.db.profile.Filters) do
        table.insert(GT.IDs, key)
    end
    for itemID in string.gmatch(GT.db.profile.CustomFilters, "%S+") do
        itemID = tonumber(itemID)
        if not GT.db.profile.Filters[itemID] then
            table.insert(GT.IDs, itemID)
        end
    end
end

function GT:InventoryUpdate()
    local total = 0
    local messageText = ""

    for i,id in ipairs(GT.IDs) do
        local count = (GetItemCount(id, GT.db.profile.General.includeBank, false)-GT.db.profile.General.ignoreAmount)

        if count > 0 then
            total = total + count
            messageText = messageText..id.."="..count
            
            local size = #GT.IDs
            if i < size then
                messageText = messageText.." "
            end
        end
    end
    if total > 0 then
        if GT.groupMode == "WHISPER" then
            GT:SendCommMessage("GT_Data", messageText, GT.groupMode, UnitName("player"))
        else
            GT:SendCommMessage("GT_Data", messageText, GT.groupMode)
        end
    elseif total == 0 then
        if GT.groupMode == "WHISPER" then
            GT:SendCommMessage("GT_Data", "reset", GT.groupMode, UnitName("player"))
        else
            GT:SendCommMessage("GT_Data", "reset", GT.groupMode)
        end
    end
end

function GT:DataUpdateReceived(prefix, message, distribution, sender)
--print("addon messaged received on GT_Data")
    print(message)
end

function GT:ConfigUpdateReceived(prefix, message, distribution, sender)
--print("addon messaged received on GT_Config")
end

function GT:SendAddonComm(prefix, message, distribution, target)
    --Use this for sending addon comms with AceComm
end
