GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceEvent-3.0")
---@class GT : AceAddon-3.0, AceEvent-3.0, AceGUI-3.0
local GT = GatheringTracker

GT.InventoryData = {}
GT.Display = {}
GT.Display.Frames = {}
GT.Pools = {}
GT.PlayerEnteringWorld = true
GT.DebugCount = 0
GT.Options = {}
GT.Notifications = {}
GT.NotificationPause = true
GT.GlobalStartTime = 0

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

GT.metaData = {
    name = C_AddOns.GetAddOnMetadata("GatheringTracker", "Title"),
    version = C_AddOns.GetAddOnMetadata("GatheringTracker", "Version"),
    notes = C_AddOns.GetAddOnMetadata("GatheringTracker", "Notes"),
}

GT.gameVersion = "retail"
if WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
    GT.gameVersion = "classic"
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and (C_Seasons.GetActiveSeason() == 2) then
    GT.gameVersion = "season"
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    GT.gameVersion = "era"
else
    GT.gameVersion = "retail"
end

BINDING_HEADER_GATHERINGTRACKER = GT.metaData.name .. " v" .. GT.metaData.version

function GT:OnEnable()
    if GT.Enabled then
        --use this for both initial setup on UI load and when the addon is enabled from the settings
        ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 ENABLED|r")

        --Register events for updating item details
        GT:RegisterEvent("BAG_UPDATE")
        GT:RegisterEvent("PLAYER_MONEY", "InventoryUpdate")
        GT:RegisterEvent("GROUP_ROSTER_UPDATE")
        GT:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        GT:OnDisable()
    end
end

function GT:OnDisable()
    if not GT.Enabled then
        --Use this for disabling the addon from the settings
        --stop event tracking
        ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cffff0000 DISABLED|r")

        --Unregister events so that we can stop working when disabled
        GT:UnregisterEvent("BAG_UPDATE")
        GT:UnregisterEvent("PLAYER_MONEY")
        GT:UnregisterEvent("GROUP_ROSTER_UPDATE")
        GT:UnregisterEvent("PLAYER_ENTERING_WORLD")
    else
        GT:OnEnable()
    end
end

function GT:PLAYER_ENTERING_WORLD()
    GT.Debug("PLAYER_ENTERING_WORLD", 1)

    if GT:DisplayVisibility() then
        GT.baseFrame.frame:Show()
    else
        GT.Debug("PLAYER_ENTERING_WORLD: SetDisplayState Hide", 2)
        GT.baseFrame.frame:Hide()
        return
    end

    GT:wait(6, "InventoryUpdate", "PLAYER_ENTERING_WORLD", false)
    GT:wait(7, "NotificationHandler", "PLAYER_ENTERING_WORLD")
    GT:wait(7, "AnchorFilterButton", "PLAYER_ENTERING_WORLD")
end

function GT:GROUP_ROSTER_UPDATE(event)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, event)

    GT:SetDisplayState()
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE", true)
        GT:RefreshPerHourDisplay(false, true)
    end
end

function GT:SetDisplayState()
    if GT:DisplayVisibility() then
        GT.baseFrame.frame:Show()
    else
        GT.baseFrame.frame:Hide()
    end
end

function GT:CreateBaseFrame()
    --this creates the basic frame structure that the addon uses.
    --the backdrop is used for positioning through the addon options.
    local frame = CreateFrame("Frame", "GT_baseFrame", UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(0)
    frame:SetMouseClickEnabled(false)

    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    backdrop:SetWidth(300)
    backdrop:SetHeight(300)
    backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
    backdrop:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 5, bottom = 3 },
    })
    backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    backdrop:SetBackdropBorderColor(0.4, 0.4, 0.4)
    backdrop:SetFrameStrata("FULLSCREEN_DIALOG")
    backdrop:SetClampedToScreen(true)
    backdrop:SetMouseClickEnabled(false)

    backdrop:Hide()

    frame:SetPoint("TOPLEFT", backdrop, "TOPLEFT")
    frame:Show()
    frame:SetMouseClickEnabled(false)

    local baseFrame = {
        frame = frame,
        backdrop = backdrop,
    }
    GT.baseFrame = baseFrame

    GT:FiltersButton()
    GT:InitializePools()
end

function GT:UpdateBaseFrameSize()
    --Have to reset to 0 otherwise the size will never shrink
    GT.baseFrame.frame:SetHeight(0)
    GT.baseFrame.frame:SetWidth(0)

    local left, bottom, width, height = GT.baseFrame.frame:GetBoundsRect()
    GT.baseFrame.frame:SetHeight(height)
    GT.baseFrame.frame:SetWidth(width)
end

function GT:ToggleBaseLock(key)
    --used to toggle if the base frame should be shown and interactable.
    --the base frame should only be shown when unlocked so that the user can position it on screen where they want.
    local frame = GT.baseFrame.backdrop

    local function stoppedMoving(self)
        self:StopMovingOrSizing()
        self.isMoving = false
        local rel, _, _, xPos, yPos = self:GetPoint()
        GT.db.profile.General.xPos = xPos
        GT.db.profile.General.yPos = yPos
        GT.db.profile.General.relativePoint = rel

        --Return if Filter Button is disabled, we only need to do the rest if it is enabled
        if not GT.db.profile.General.filtersButton then
            return
        end
        GT:AnchorFilterButton()
    end

    if key then
        GT.Debug("Show baseFrame", 1)
        frame:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetMouseClickEnabled(true)
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving()
                self.isMoving = true
            end
        end)
        frame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                stoppedMoving(self)
            end
        end)
        frame:SetScript("OnHide", function(self)
            if self.isMoving then
                stoppedMoving(self)
            end
        end)
    else
        GT.Debug("Hide baseFrame", 1)
        frame:Hide()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetMouseClickEnabled(false)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
        frame:SetScript("OnHide", nil)
    end
end

function GT:OptionsHide()
    if GT.baseFrame then
        --This is called when the Interface Options Panel is closed.
        --locks the base frame if the options are closed without first locking it.
        if GT.db.profile.General.unlock then
            GT.db.profile.General.unlock = false
            GT:ToggleBaseLock(false)
        end

        --Pause Notifications to prevent spam after closing the settings
        GT.NotificationPause = true

        --Do an inventory update if we dont have any information
        if #GT.InventoryData == 0 and GT.Enabled then
            GT:InventoryUpdate("InterfaceOptionsFrame:OnHide", false)
        end
    end
end

function GT:ClearDisplay()
    GT.Debug("Clear Display", 1)
    GT:DestroyDisplay()

    GT.InventoryData = {}
    GT.Display.ColumnSize = {}
    GT.Display.Order = {}
end

function GT:RebuildDisplay(event)
    GT.Debug("Rebuild Display Start", 1, event)

    GT:DestroyDisplay()

    GT:PrepareDataForDisplay("Rebuild Display")
end

function GT:DestroyDisplay()
    GT.Debug("Destroy Display", 1)
    for itemID, itemFrame in pairs(GT.Display.Frames) do
        GT:RemoveDiaplayRow(itemID)
    end
end

function GT:RemoveItemData(key, itemID)
    GT.Debug("Remove Item Data", 3, key, itemID)
    if key then
        return
    end

    if GT.InventoryData[itemID] then
        GT.Debug("Remove Item Data: remove Inventory", 3, key, itemID)
        GT.InventoryData[itemID] = nil
    end

    if GT.Display.Frames[itemID] then
        GT:RemoveDiaplayRow(itemID)
        GT:AllignRows()
    end
end

--- Removes an item from the display
---@param itemID integer
function GT:RemoveDiaplayRow(itemID)
    GT.Debug("Remove Diaplay Row", 3, itemID)
    GT.Pools.framePool:Release(GT.Display.Frames[itemID])
    local order = GT:TableFind(GT.Display.Order, itemID)
    table.remove(GT.Display.Order, order)
    GT.Display.Frames[itemID] = nil
end

function GT:SetAnchor(frame)
    for textIndex, textFrame in ipairs(frame.text) do
        local offset = 8
        local anchor = {}
        if textIndex == 1 then
            offset = 3
            anchor = frame.icon
        else
            anchor = frame.text[textIndex - 1]
        end
        textFrame:ClearAllPoints()
        textFrame:SetPoint("LEFT", anchor, "RIGHT", offset, 0)
    end
end

function GT:AllignRows()
    if not GT.Display.Order then
        return
    end
    for i, id in ipairs(GT.Display.Order) do
        if i == 1 then
            GT.Display.Frames[id]:SetPoint("TOPLEFT", GT.baseFrame.backdrop, "TOPLEFT")
        else
            if GT.db.profile.General.multiColumn and ((i - 1) % GT.db.profile.General.numRows == 0) then
                GT.Display.Frames[id]:SetPoint("TOPLEFT", GT.Display.Frames[GT.Display.Order[i - GT.db.profile.General.numRows]], "TOPRIGHT")
            else
                GT.Display.Frames[id]:SetPoint("TOPLEFT", GT.Display.Frames[GT.Display.Order[i - 1]], "BOTTOMLEFT")
            end
        end
    end
    GT:UpdateBaseFrameSize()
end

function GT:AllignColumns()
    if not GT.Display.Order then
        return
    end
    for i, id in ipairs(GT.Display.Order) do
        for index, string in ipairs(GT.Display.Frames[id].text) do
            if not GT.Display.ColumnSize[index] then
                GT:CheckColumnSize(index, GT.Display.Frames[id].text[index])
            end
            string:SetWidth(GT.Display.ColumnSize[index])
        end
    end
    GT:SetDisplayFrameWidth()
    GT:UpdateBaseFrameSize()
end

function GT:SetDisplayFrameWidth()
    -- could also use Frame:GetBoundsRect() if needed in the future
    local textWidth = GT:SumTable(GT.Display.ColumnSize)
    local offsets = (#GT.Display.ColumnSize * 8) + 3
    local iconWidth = GT.db.profile.General.iconWidth
    local width = iconWidth + textWidth + offsets
    for i, id in ipairs(GT.Display.Order) do
        GT.Display.Frames[id]:SetWidth(width)
    end
end

function GT:InitiateFrameProcess(id, iconId, iconQuality, iconRarity, displayText,
                                 pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)
    GT.Debug("InitiateFrameProcess", 4, id, iconId, iconQuality, iconRarity, displayText,
        pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)

    if GT.Display.Frames[id] then
        GT:UpdateDisplayFrame(id,
            displayText,
            pricePerItem,
            priceTotalItem,
            itemsPerHour,
            goldPerHour
        )
    else
        GT:CreateDisplayFrame(id,
            iconId,
            iconQuality,
            iconRarity,
            displayText,
            pricePerItem,
            priceTotalItem,
            itemsPerHour,
            goldPerHour
        )
    end
end

function GT:UpdateDisplayFrame(id, displayText, pricePerItem, priceTotalItem,
                               itemsPerHour, goldPerHour)
    GT.Debug("UpdateDisplayFrame", 4, id, displayText, pricePerItem, priceTotalItem,
        itemsPerHour, goldPerHour)

    if displayText == nil then
        return
    end

    local frame = GT.Display.Frames[id]
    local frameHeight = frame:GetHeight()

    if type(displayText) == "table" then
        for textIndex, text in ipairs(displayText) do
            if type(text) == "number" then
                text = math.ceil(text - 0.5)
            end
            frame.text[textIndex]:SetText(text)
            GT:CheckColumnSize(textIndex, frame.text[textIndex])
        end
    else
        if type(displayText) == "number" then
            displayText = math.ceil(displayText - 0.5)
        end
        frame.text[1]:SetText(displayText)
        GT:CheckColumnSize(1, frame.text[1])
    end

    if pricePerItem and GT.db.profile.General.perItemPrice then
        local text = ""
        if type(pricePerItem) == "number" then
            text = "{" .. math.ceil(pricePerItem - 0.5) .. "g}"
        else
            text = ""
        end
        if frame.pricePerItem then
            frame.text[frame.pricePerItem]:SetText(text)
            GT:CheckColumnSize(frame.pricePerItem, frame.text[frame.pricePerItem])
        end
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        if frame.priceTotalItem then
            frame.text[frame.priceTotalItem]:SetText("(" .. math.ceil(priceTotalItem - 0.5) .. "g)")
            GT:CheckColumnSize(frame.priceTotalItem, frame.text[frame.priceTotalItem])
        end
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        if frame.priceTotalItem then
            frame.text[frame.priceTotalItem]:SetText("(" .. math.ceil(priceTotalItem - 0.5) .. "g)")
            GT:CheckColumnSize(frame.priceTotalItem, frame.text[frame.priceTotalItem])
        end
    end

    if itemsPerHour and GT.db.profile.General.itemsPerHour then
        GT:UpdateItemsPerHour(frame, itemsPerHour)
    end

    if goldPerHour and GT.db.profile.General.goldPerHour then
        GT:UpdateGoldPerHour(frame, goldPerHour)
    end

    GT:SetAnchor(frame)
end

function GT:UpdateItemsPerHour(frame, itemsPerHour)
    if not frame.itemsPerHour then
        return
    end

    frame.text[frame.itemsPerHour]:SetText(math.ceil(itemsPerHour - 0.5) .. "/h")
    GT:CheckColumnSize(frame.itemsPerHour, frame.text[frame.itemsPerHour])
end

function GT:UpdateGoldPerHour(frame, goldPerHour)
    if not frame.goldPerHour then
        return
    end

    frame.text[frame.goldPerHour]:SetText(math.ceil(goldPerHour - 0.5) .. "g/h")
    GT:CheckColumnSize(frame.goldPerHour, frame.text[frame.goldPerHour])
end

function GT:PrepareDataForDisplay(event, wait)
    GT.Debug("Prepare Data for Display", 1, event, wait)
    if wait then
        GT:wait(0.1, "PrepareDataForDisplay", "PrepareDataForDisplay", false)
        return
    end

    GT.Display.ColumnSize = {}

    GT:SetTSMPriceSource()

    if not GT.NotificationPause then
        GT.Debug("Trigger Notification Handler for all", 2)
        local count, value = GT:CalculatePlayerTotal(true, GT.db.profile.General.sessionOnly)
        GT:NotificationHandler("all", "all", count, value)
    end

    GT:CleanUpInventoryData()

    GT:SetupItemRows()

    GT:SetupTotalsRow()

    GT:AllignRows()
    GT:AllignColumns()
    GT:UpdateBaseFrameSize()
    if GT.db.profile.General.collapseDisplay then
        GT:CollapseManager(false)
    end
end

function GT:SetupItemRows()
    GT.Debug("SetupItemRows", 1)
    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Setup Item Row", 2, itemID)
        if itemID <= #GT.ItemData.Other.Other then
            GT:InitiateFrameProcess(
                itemID,
                GT.ItemData.Other.Other[itemID].icon,
                nil,
                nil,
                itemData.count
            )
        else
            local count = 0
            if GT.db.profile.General.sessionOnly then
                count = GT.InventoryData[itemID].sessionCount
            else
                count = GT.InventoryData[itemID].count
            end

            local pricePerItem = nil
            if GT.priceSources then
                pricePerItem = GT:GetItemPrice(itemID)
            end
            local priceTotalItem = count * (pricePerItem or 0)
            local itemsPerHour = GT:CalculateItemsPerHour(itemID)
            local goldPerHour = itemsPerHour * (pricePerItem or 0)

            local iconQuality = nil
            if GT.gameVersion == "retail" then
                iconQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)
            end

            if count > 0 or GT.db.profile.General.allFiltered then
                GT:InitiateFrameProcess(
                    tonumber(itemID),
                    C_Item.GetItemIconByID(itemID),
                    iconQuality,
                    C_Item.GetItemQualityByID(itemID),
                    GT:GetItemRowData(itemID),
                    pricePerItem,
                    priceTotalItem,
                    itemsPerHour,
                    goldPerHour
                )
            elseif GT.Display.Frames[itemID] then
                GT:RemoveDiaplayRow(itemID)
            end
        end
    end
end

function GT:GetItemRowData(itemID)
    GT.Debug("GetItemRowData", 2, itemID)

    if GT.db.profile.General.sessionOnly then
        GT.Debug("GetItemRowData", 3, "Session Counts", itemID)
        return GT.InventoryData[itemID].sessionCount
    elseif GT.db.profile.General.sessionItems and not GT:IsInGroup() then
        local data = {}
        table.insert(data, GT.InventoryData[itemID].count)
        table.insert(data, GT.InventoryData[itemID].sessionCount)
        GT.Debug("GetItemRowData", 3, "Normal Counts & Session Counts", itemID)
        return data
    else
        GT.Debug("GetItemRowData", 3, "Normal Counts", itemID)
        return GT.InventoryData[itemID].count
    end
end

function GT:CalculateItemsPerHour(itemID)
    if itemID then
        local itemData = GT.InventoryData[itemID]
        local itemDiff = itemData.sessionCount
        local timeDiff = time() - itemData.startTime

        --divind time diff in Seconds by 3600 to get time diff in hours
        local itemsPerHour = itemDiff / (timeDiff / 3600)
        GT.Debug("CalculateItemsPerHour", 3, itemsPerHour, itemData.total, itemDiff, timeDiff)
        if itemsPerHour < 1 then
            itemsPerHour = 0
        end

        return itemsPerHour
    end
end

function GT:CalculateItemsPerHourTotal(playerTotal)
    local sessionAmount = 0
    local pricePerHour = 0
    for itemID, itemData in pairs(GT.InventoryData) do
        if itemID > #GT.ItemData.Other.Other then
            sessionAmount = sessionAmount + itemData.sessionCount

            local itemPerHour = GT:CalculateItemsPerHour(itemID)
            if itemPerHour and GT.priceSources then
                pricePerHour = pricePerHour + (itemPerHour * GT:GetItemPrice(itemID))
            end
        end
    end
    local timeDiff = time() - GT.GlobalStartTime

    --divind time diff in Seconds by 3600 to get time diff in hours
    local itemsPerHour = sessionAmount / (timeDiff / 3600)
    GT.Debug("CalculateItemsPerHourTotal", 2, itemsPerHour, pricePerHour, playerTotal, sessionAmount, timeDiff)
    if itemsPerHour < 1 then
        itemsPerHour = 0
    end

    return itemsPerHour, pricePerHour
end

function GT:SetupTotalsRow()
    GT.Debug("SetupTotalsRow", 1)
    local playerTotals = {}
    local priceTotal = 0

    local playerTotal, playerPrice = GT:CalculatePlayerTotal(
        true,
        GT.db.profile.General.sessionOnly
    )
    priceTotal = playerPrice
    table.insert(playerTotals, playerTotal)
    if GT.db.profile.General.sessionItems and not GT.db.profile.General.sessionOnly then
        local playerTotalSession, playerPriceSession = GT:CalculatePlayerTotal(
            true,
            true
        )
        table.insert(playerTotals, playerTotalSession)
    end
    if playerTotal > 0 or GT.db.profile.General.collapseDisplay then
        local itemsPerHour, goldPerHour = GT:CalculateItemsPerHourTotal(playerTotal)

        GT:InitiateFrameProcess(
            9999999998,
            133647,
            nil,
            nil,
            playerTotals,
            "",
            priceTotal,
            itemsPerHour,
            goldPerHour
        )
    elseif GT.Display.Frames[9999999998] then
        GT:RemoveDiaplayRow(9999999998)
    end
end

function GT:RefreshPerHourDisplay(stop, wait)
    GT.Debug("Refresh Per Hour Display", 1, stop, wait)
    if not GT.db.profile.General.itemsPerHour and not GT.db.profile.General.goldPerHourthen then
        return
    end
    if stop then
        return
    end

    for itemID, itemFrame in pairs(GT.Display.Frames) do
        if itemID > #GT.ItemData.Other.Other and itemID < 9999999998 then
            local itemsPerHour = 0
            local goldPerHour = 0
            local pricePerItem = nil
            if GT.priceSources then
                pricePerItem = GT:GetItemPrice(itemID)
            end

            if itemFrame.itemsPerHour and GT.db.profile.General.itemsPerHour then
                itemsPerHour = GT:CalculateItemsPerHour(itemID)
                GT:UpdateItemsPerHour(itemFrame, itemsPerHour)
            end

            if itemFrame.goldPerHour and GT.db.profile.General.goldPerHour then
                goldPerHour = itemsPerHour * (pricePerItem or 0)
                GT:UpdateGoldPerHour(itemFrame, goldPerHour)
            end
        elseif itemID == 9999999998 then
            local playerTotals = {}
            local totalItemCount = 0

            local totalItemCount = GT:CalculatePlayerTotal(
                false,
                GT.db.profile.General.sessionOnly
            )

            local itemsPerHour, goldPerHour = GT:CalculateItemsPerHourTotal(totalItemCount)
            if itemFrame.itemsPerHour and GT.db.profile.General.itemsPerHour then
                GT:UpdateItemsPerHour(itemFrame, itemsPerHour)
            end

            if itemFrame.goldPerHour and GT.db.profile.General.goldPerHour then
                GT:UpdateGoldPerHour(itemFrame, goldPerHour)
            end
        end
    end

    if wait then
        GT:wait(5, "RefreshPerHourDisplay", false, true)
        return
    end
end

function GT:CleanUpInventoryData()
    GT.Debug("CleanUpInventoryData", 1)
    for itemID, itemData in pairs(GT.InventoryData) do
        -- Removes Items that have a total count of 0
        if itemData.count == 0 and not GT.db.profile.General.allFiltered then
            GT.Debug("CleanUpInventoryData", 2, itemID, itemData.count)
            GT:RemoveItemData(false, itemID)
        end
    end
end

function GT:InventoryUpdate(event, wait)
    GT.Debug("InventoryUpdate", 1, event, wait)
    if wait then
        GT:wait(0.1, "InventoryUpdate", "InventoryUpdate", false)
        return
    end
    if event == nil then
        local traceback = debugstack()
        GT.Debug(traceback, 1, event)
        return
    end
    if not GT.Enabled then
        return
    end
    if GT:DisplayVisibility() then
        GT.baseFrame.frame:Show()
    else
        GT.Debug("InventoryUpdate: Instance Hide", 2)
        GT.baseFrame.frame:Hide()
        return
    end
    if GT.PlayerEnteringWorld == true then
        GT.PlayerEnteringWorld = false
    end

    GT:DisplayAllCheck()

    GT:ProcessData(event)
end

function GT:ProcessData(event)
    GT.Debug("ProcessData", 1, event)
    local itemTable = {}

    for index, id in ipairs(GT.IDs) do
        local itemCount = 0
        if id == GT.ItemData.Other.Other[1].id then
            itemCount = math.floor((GetMoney() / 10000) + 0.5)
        elseif id == GT.ItemData.Other.Other[2].id then
            for bagIndex = 0, 4 do
                itemCount = itemCount + C_Container.GetContainerNumFreeSlots(bagIndex)
            end
        else
            itemCount = C_Item.GetItemCount(
                id,
                GT.db.profile.General.includeBank,
                false,
                GT.db.profile.General.includeReagent,
                GT.db.profile.General.includeWarband
            )
        end

        if itemCount > 0 or (itemCount == 0 and GT.InventoryData[id]) or GT.db.profile.General.allFiltered then
            itemTable[id] = itemCount
        end

        if event and (event == "InventoryUpdate" or event == "BAG_UPDATE") and itemCount > 0 then
            GT.Debug("Trigger Notification Handler for each", 5)
            GT.NotificationPause = false
            GT:NotificationHandler("each", id, itemCount)
        end
    end

    GT:UpdateInventoryData(itemTable)

    GT:PrepareDataForDisplay("Process Solo Data")
end

--- Creates a table from a string that is formatted with id=count and space seperated
---@param message string Message string
---@return table itemTable
function GT:CreateItemTable(message)
    GT.Debug("CreateItemTable", 3, message)
    --create messageText table
    local str = " " .. message .. "\n"
    str = str:gsub("%s(%S-)=", "\n%1=")
    local itemTable = {}

    for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
        local itemID = tonumber(itemID)
        ---@diagnostic disable-next-line: need-check-nil
        itemTable[itemID] = value
    end

    return itemTable
end

--- Creates an itemData Construct
---@param itemID integer ID of the item to create
---@return table itemData
function GT:ItemDataConstructor(itemID)
    GT.Debug("ItemDataConstructor", 1, itemID)

    local itemData = {}
    itemData.count = 0
    itemData.startAmount = -1
    itemData.sessionCount = 0
    itemData.startTime = time()

    return itemData
end

--- Updates the Inventory data for a Sender
---@param itemTable table
function GT:UpdateInventoryData(itemTable)
    GT.Debug("UpdateInventoryData", 1)
    for itemID, value in pairs(itemTable) do
        GT.Debug("UpdateInventoryData", 3, itemID, value)
        local value = tonumber(value)
        if GT:TableFind(GT.IDs, itemID) then
            GT.InventoryData[itemID] = GT.InventoryData[itemID] or GT:ItemDataConstructor(itemID)
            GT.InventoryData[itemID].count = value
            if GT.InventoryData[itemID].startAmount == -1 then
                GT.InventoryData[itemID].startAmount = value
            end

            GT.InventoryData[itemID].sessionCount =
                GT.InventoryData[itemID].count - GT.InventoryData[itemID].startAmount
        else
            itemTable[itemID] = nil
        end
    end

    if GT.GlobalStartTime == 0 then
        GT.GlobalStartTime = time()
    end
end

---@param calcSenderValue boolean If true calculates value of all filtered items from sender
---@param useSessionData boolean If true only uses session data for calculations
---@return integer total Total count of items for sender
---@return integer value Total gold value of items for sender
function GT:CalculatePlayerTotal(calcSenderValue, useSessionData)
    GT.Debug("CalculatePlayerTotal", 1, calcSenderValue, useSessionData)

    local total = 0
    local value = 0

    for itemID, itemData in pairs(GT.InventoryData) do
        local count = 0
        if useSessionData then
            count = itemData.sessionCount
        else
            count = itemData.count
        end
        if itemID > #GT.ItemData.Other.Other and count - GT.db.profile.General.ignoreAmount > 0 then
            total = total + count
            if calcSenderValue and GT.priceSources then
                value = value + (count * GT:GetItemPrice(itemID))
            end
        end
    end
    return total, math.ceil(value - 0.5) --rounds up to whole number
end
