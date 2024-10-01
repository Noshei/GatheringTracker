GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local GT = GatheringTracker
GT.sender = {}
GT.count = {}
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

        --Register addon comm's
        GT:RegisterComm("GT_Data", "DataMessageReceived")
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

        --Unregister addon comm's
        GT:UnregisterComm("GT_Data")
    else
        GT:OnEnable()
    end
end

function GT:PLAYER_ENTERING_WORLD()
    GT.Debug("PLAYER_ENTERING_WORLD", 1)

    if GT.db.profile.General.instanceHide and IsInInstance() then
        GT.Debug("PLAYER_ENTERING_WORLD: Instance Hide", 2)
        GT.baseFrame.frame:Hide()
        return
    else
        GT.baseFrame.frame:Show()
    end

    GT:wait(6, "InventoryUpdate", "PLAYER_ENTERING_WORLD", false)
    GT:wait(7, "NotificationHandler", "PLAYER_ENTERING_WORLD")
    GT:wait(7, "AnchorFilterButton", "PLAYER_ENTERING_WORLD")
end

function GT:GROUP_ROSTER_UPDATE(event, wait)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, event, wait)

    --Check if we need to wait on doing the update.
    --If we do need to wait, determine if an existing wait table has already been created
    --If we dont need to wait, do the update.

    if wait then
        GT:wait(2, "GROUP_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", false)
        return
    end

    if GT.db.profile.General.instanceHide and IsInInstance() then
        GT.Debug("GROUP_ROSTER_UPDATE: Instance Hide", 2)
        GT.baseFrame.frame:Hide()
        return
    else
        GT.baseFrame.frame:Show()
    end

    GT:SetChatType()

    GT:CheckForPlayersLeavingGroup()
    GT:InventoryUpdate("GROUP_ROSTER_UPDATE", true)
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE", true)
        GT:RefreshPerHourDisplay(false, true)
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

        GT:SetChatType()

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
    GT.sender = {}
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

    for senderIndex, senderData in ipairs(GT.sender) do
        if senderData.inventoryData[itemID] then
            GT.Debug("Remove Item Data: remove Sender", 3, key, itemID, senderIndex)
            senderData.inventoryData[itemID] = nil
        end
    end

    if GT.Display.Frames[itemID] then
        GT:RemoveDiaplayRow(itemID)
        GT:AllignRows()
    end
end

function GT:CheckForPlayersLeavingGroup()
    GT.Debug("Check For Players Leaving Group", 2)
    if #GT.sender <= 1 then
        return
    end
    local groupList = GT:GetGroupList()

    if GT.db.profile.General.hideOthers then
        groupList = nil
    end

    for senderIndex, sender in ipairs(GT.sender) do
        if not (sender.name == GT.Player) then
            if groupList == nil then
                GT:RemoveSender(senderIndex)
            elseif not GT:TableFind(groupList, sender.name) then
                GT:RemoveSender(senderIndex)
            end
        end
    end
end

function GT:RemoveSender(senderIndex)
    GT.Debug("Remove Sender", 2, senderIndex)
    for itemID, inventoryData in pairs(GT.InventoryData) do
        table.remove(inventoryData.counts, senderIndex)
        table.remove(inventoryData.startAmount, senderIndex)
    end
    table.remove(GT.sender, senderIndex)
    GT:RebuildDisplay()
end

function GT:RemoveDiaplayRow(itemID --[[int]])
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

function GT:InitiateFrameProcess(id, iconId, iconQuality, iconRarity, displayText, totalItemCount,
                                 pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)
    GT.Debug("InitiateFrameProcess", 4, id, iconId, iconQuality, iconRarity, displayText, totalItemCount,
        pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)

    if GT.Display.Frames[id] then
        GT:UpdateDisplayFrame(id,
            displayText,
            totalItemCount,
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
            totalItemCount,
            pricePerItem,
            priceTotalItem,
            itemsPerHour,
            goldPerHour
        )
    end
end

function GT:UpdateDisplayFrame(id, displayText, totalItemCount, pricePerItem, priceTotalItem,
                               itemsPerHour, goldPerHour)
    GT.Debug("UpdateDisplayFrame", 4, id, unpack(displayText), totalItemCount, pricePerItem, priceTotalItem,
        itemsPerHour, goldPerHour)

    if displayText == nil then
        return
    end

    local frame = GT.Display.Frames[id]
    local frameHeight = frame:GetHeight()

    for textIndex, text in ipairs(displayText) do
        if type(text) == "number" then
            text = math.ceil(text - 0.5)
        end
        frame.text[textIndex]:SetText(text)
        GT:CheckColumnSize(textIndex, frame.text[textIndex])
    end

    if totalItemCount and GT:GroupDisplayCheck() then
        if frame.totalItemCount then
            frame.text[frame.totalItemCount]:SetText("[" .. math.ceil(totalItemCount - 0.5) .. "]")
            GT:CheckColumnSize(frame.totalItemCount, frame.text[frame.totalItemCount])
        end
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

    for senderIndex, senderData in ipairs(GT.sender) do
        if senderData.name == GT.Player and not GT.NotificationPause then
            GT.Debug("Trigger Notification Handler for all", 2)
            local countTotal = 0
            local valueTotal = 0
            if playerTotals and playerTotals.countTotal and playerTotals.countTotal[senderIndex] then
                countTotal = playerTotals.countTotal[senderIndex]
            end
            if playerTotals and playerTotals.valueTotal and playerTotals.valueTotal[senderIndex] then
                valueTotal = playerTotals.valueTotal[senderIndex]
            end
            GT:NotificationHandler("all", "all", countTotal, valueTotal)
        end
    end

    GT:CleanUpInventoryData()

    GT:SetupItemRows()

    GT:SetupTotalsRow()

    if GT.db.profile.General.characterValue and GT:GroupDisplayCheck() and GT.priceSources then
        local playerPriceTotals = {}
        for senderIndex, senderData in ipairs(GT.sender) do
            local playerTotal, playerPrice = GT:CalculateTotals(senderIndex, true)
            table.insert(playerPriceTotals, tostring(math.ceil(playerPrice - 0.5)) .. "g")
        end
        GT:InitiateFrameProcess(
            9999999999,
            133784,
            nil,
            nil,
            playerPriceTotals
        )
    end

    if GT.db.profile.General.displayAlias and GT:GroupDisplayCheck() then
        local aliases = GT:CreateAliasTable()
        if #aliases > 0 then
            GT:InitiateFrameProcess(
                0,
                413577,
                nil,
                nil,
                GT:CreateAliasTable()
            )
        end
    end

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
                itemData.counts
            )
        else
            local totalItemCount, priceTotalItem = GT:CalculateTotals(nil, nil, itemID, true)
            local pricePerItem = nil
            if GT.priceSources then
                pricePerItem = GT:GetItemPrice(itemID)
            end
            local itemsPerHour = GT:CalculateItemsPerHour(itemID)
            local goldPerHour = itemsPerHour * (pricePerItem or 0)

            GT:InitiateFrameProcess(
                tonumber(itemID),
                GetItemIcon(tonumber(itemID)),
                C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID),
                C_Item.GetItemQualityByID(itemID),
                itemData.counts,
                totalItemCount,
                pricePerItem,
                priceTotalItem,
                itemsPerHour,
                goldPerHour
            )
        end
    end
end

function GT:CalculateItemsPerHour(itemID)
    if itemID then
        local itemData = GT.InventoryData[itemID]
        local itemDiff = itemData.total - itemData.startTotal
        local timeDiff = time() - itemData.startTime

        --divind time diff in Seconds by 3600 to get time diff in hours
        local itemsPerHour = itemDiff / (timeDiff / 3600)
        GT.Debug("CalculateItemsPerHour", 3, itemsPerHour, itemData.total, itemData.startTotal, itemDiff, timeDiff)
        if itemsPerHour < 1 then
            itemsPerHour = 0
        end

        return itemsPerHour
    end
end

function GT:CalculateItemsPerHourTotal(playerTotals)
    local startAmount = 0
    local pricePerHour = 0
    for itemID, itemData in pairs(GT.InventoryData) do
        if itemID > #GT.ItemData.Other.Other then
            startAmount = startAmount + itemData.startTotal

            local itemPerHour = GT:CalculateItemsPerHour(itemID)
            if itemPerHour and GT.priceSources then
                pricePerHour = pricePerHour + (itemPerHour * GT:GetItemPrice(itemID))
            end
        end
    end
    local amountDiff = playerTotals - startAmount
    local timeDiff = time() - GT.GlobalStartTime

    --divind time diff in Seconds by 3600 to get time diff in hours
    local itemsPerHour = amountDiff / (timeDiff / 3600)
    GT.Debug("CalculateItemsPerHourTotal", 2, itemsPerHour, pricePerHour, playerTotals, startAmount, amountDiff, timeDiff)
    if itemsPerHour < 1 then
        itemsPerHour = 0
    end

    return itemsPerHour, pricePerHour
end

function GT:SetupTotalsRow()
    GT.Debug("SetupTotalsRow", 1)
    local playerTotals = {}
    local priceTotal = 0
    local totalItemCount = 0

    for senderIndex, senderData in ipairs(GT.sender) do
        local playerTotal, playerPrice = GT:CalculateTotals(senderIndex, true)
        table.insert(playerTotals, playerTotal)
        priceTotal = priceTotal + playerPrice
    end
    totalItemCount = GT:SumTable(playerTotals)
    if totalItemCount > 0 or GT.db.profile.General.collapseDisplay then
        local itemsPerHour, goldPerHour = GT:CalculateItemsPerHourTotal(totalItemCount)

        GT:InitiateFrameProcess(
            9999999998,
            133647,
            nil,
            nil,
            playerTotals,
            totalItemCount,
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

            for senderIndex, senderData in ipairs(GT.sender) do
                local playerTotal = GT:CalculateTotals(senderIndex)
                table.insert(playerTotals, playerTotal)
            end
            totalItemCount = GT:SumTable(playerTotals)
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
        -- adds 0 count for senders that are missing data for a displayed Item
        if not (#itemData.counts == #GT.sender) then
            repeat
                table.insert(itemData.counts, 0)
            until (#itemData.counts == #GT.sender)
        end

        -- adds 0 startAmount for senders that are missing data for a displayed Item
        if not (#itemData.startAmount == #GT.sender) then
            repeat
                table.insert(itemData.startAmount, 0)
            until (#itemData.startAmount == #GT.sender)
        end

        -- Removes Items that have a total count of 0
        if GT:SumTable(itemData.counts) == 0 and not GT.db.profile.General.allFiltered then
            GT.Debug("CleanUpInventoryData", 2, itemID, GT:SumTable(itemData.counts))
            GT:RemoveItemData(false, itemID)
        end
    end
end

function GT:CreateAliasTable()
    GT.Debug("CreateAliasTable", 1)
    local aliases = {}

    for senderIndex, senderData in ipairs(GT.sender) do
        if GT.db.profile.General.displayAlias and #GT.db.profile.Aliases > 0 then
            for index, aliasData in ipairs(GT.db.profile.Aliases) do
                if aliasData.name == senderData.name then
                    aliases[senderIndex] = aliasData.alias
                end
            end
            if aliases[senderIndex] == nil then
                aliases[senderIndex] = senderData.name
            end
        elseif GT.db.profile.General.displayAlias and #GT.db.profile.Aliases == 0 then
            aliases[senderIndex] = senderData.name
        end
    end

    return aliases
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
    if GT:CheckModeStatus() == false then
        GT.Debug("InventoryUpdate: CheckModeStatus", 2, GT:CheckModeStatus())
        return
    end
    if GT.db.profile.General.instanceHide and IsInInstance() then
        GT.Debug("InventoryUpdate: Instance Hide", 2)
        GT.baseFrame.frame:Hide()
        return
    else
        GT.baseFrame.frame:Show()
    end
    if GT.PlayerEnteringWorld == true then
        GT.PlayerEnteringWorld = false
    end

    GT:DisplayAllCheck()

    GT:ProcessSoloData(event)

    if GT.db.profile.General.groupType > 0 and IsInGroup() then
        GT:CreateDataMessage(event)
    end
end

function GT:ProcessSoloData(event)
    GT.Debug("ProcessSoloData", 2, event)
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
            itemCount = GetItemCount(id, GT.db.profile.General.includeBank, false)
        end

        if itemCount > 0 or GT.db.profile.General.allFiltered then
            itemTable[id] = itemCount
        end

        if event and (event == "InventoryUpdate" or event == "BAG_UPDATE") and itemCount > 0 then
            GT.Debug("Trigger Notification Handler for each", 5)
            GT.NotificationPause = false
            GT:NotificationHandler("each", id, itemCount)
        end
    end

    local senderIndex = GT:UpdateSenderTable(UnitName("player"))

    GT:UpdateInventoryData(senderIndex, itemTable)

    GT:PrepareDataForDisplay("Process Solo Data")
end

function GT:CreateDataMessage(event, wait)
    GT.Debug("CreateDataMessage", 2, event)
    if wait then
        GT:wait(0.1, "CreateDataMessage", "CreateDataMessage", false)
        return
    end
    local updateMessage = ""

    for index, id in ipairs(GT.IDs) do
        local itemCount = 0
        if id == GT.ItemData.Other.Other[1].id then
            itemCount = math.floor((GetMoney() / 10000) + 0.5)
        elseif id == GT.ItemData.Other.Other[2].id then
            for bagIndex = 0, 4 do
                itemCount = itemCount + C_Container.GetContainerNumFreeSlots(bagIndex)
            end
        else
            itemCount = GetItemCount(id, GT.db.profile.General.includeBank, false)
        end

        if itemCount > 0 then
            updateMessage = updateMessage .. id .. "=" .. itemCount .. " "
        end

        if event and (event == "InventoryUpdate" or event == "BAG_UPDATE") then
            GT.Debug("Trigger Notification Handler for each", 5)
            GT.NotificationPause = false
            GT:NotificationHandler("each", id, itemCount)
        end
    end

    GT.Debug("Inventory Update Data Message", 2, updateMessage)

    GT:SendDataMessage(updateMessage)
end

function GT:SendDataMessage(updateMessage)
    GT:SetChatType()

    GT.Debug("Sent Group Message", 2, updateMessage, GT.groupMode)
    GT:SendCommMessage("GT_Data", updateMessage, GT.groupMode, nil, "NORMAL")
end

function GT:DataMessageReceived(prefix, message, distribution, sender)
    GT.Debug("Data Message Received", 3, prefix, message, distribution, sender)

    if GT:CheckModeStatus() == false then
        GT.Debug("DataMessageReceived: CheckModeStatus", 2, GT:CheckModeStatus())
        return
    end
    if GT.db.profile.General.hideOthers and sender ~= GT.Player then
        GT.Debug("DataMessageReceived: hideOthers", 2, GT.db.profile.General.hideOthers, sender, GT.Player)
        return
    end
    if sender == GT.Player then
        GT.Debug("DataMessageReceived: LocalPlayer", 2, GT.Player, sender)
        return
    end

    GT.Debug("Data Message Starting Processing", 1)

    local senderIndex = GT:UpdateSenderTable(sender)

    local messageTable = GT:CreateItemTable(message)

    GT:UpdateInventoryData(senderIndex, messageTable)

    GT:PrepareDataForDisplay("Data Message Received")
end

function GT:UpdateSenderTable(sender)
    GT.Debug("UpdateSenderTable", 2, sender)
    local senderIndex = 0
    local SenderExists = false
    for index, data in ipairs(GT.sender) do
        if data.name == sender then
            SenderExists = true
            senderIndex = index
        end
    end
    if not SenderExists then
        local senderTable = {
            name = sender,
            inventoryData = {},
        }
        table.insert(GT.sender, senderTable)
        senderIndex = #GT.sender
        GT:DestroyDisplay()
    end
    return senderIndex
end

function GT:CreateItemTable(message)
    GT.Debug("CreateItemTable", 3, message)
    --create messageText table
    local str = " " .. message .. "\n"
    str = str:gsub("%s(%S-)=", "\n%1=")
    local itemTable = {}

    for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
        local itemID = tonumber(itemID)
        itemTable[itemID] = value
    end

    return itemTable
end

function GT:ItemDataConstructor(itemID, senderIndex)
    GT.Debug("ItemDataConstructor", 1, itemID, senderIndex)

    local itemData = {}
    itemData.counts = {}
    itemData.counts[senderIndex] = 0
    itemData.total = 0
    itemData.startTotal = 0
    itemData.startAmount = {}
    itemData.startAmount[senderIndex] = 0
    itemData.startTime = time()

    return itemData
end

function GT:UpdateInventoryData(senderIndex, itemTable)
    GT.Debug("UpdateInventoryData", 1, senderIndex, itemTable)
    for itemID, value in pairs(itemTable) do
        if GT:TableFind(GT.IDs, itemID) then
            GT.InventoryData[itemID] = GT.InventoryData[itemID] or GT:ItemDataConstructor(itemID, senderIndex)
            GT.InventoryData[itemID].counts[senderIndex] = tonumber(value)
            GT.sender[senderIndex].inventoryData[itemID] = tonumber(value)
            if not GT.InventoryData[itemID].startAmount[senderIndex] or
                GT.InventoryData[itemID].startAmount[senderIndex] == 0 then
                GT.InventoryData[itemID].startAmount[senderIndex] = tonumber(value)
            end
            GT.InventoryData[itemID].startTotal = GT:CalculateStartTotal(itemID)
        else
            --only matters for when getting data from party members
            --this removes items that we have disabled but were sent by party members
            itemTable[itemID] = nil
        end
    end

    --loop existing counts to update, set to 0 if not in table
    for itemID, data in pairs(GT.InventoryData) do
        if not itemTable[itemID] then
            GT.InventoryData[itemID].counts[senderIndex] = 0
            GT.sender[senderIndex].inventoryData[itemID] = 0
        end
    end

    if GT.GlobalStartTime == 0 then
        GT.GlobalStartTime = time()
    end
end

function GT:CalculateStartTotal(itemID)
    GT.Debug("CalculateStartTotal", 1, itemID)

    local total = 0

    for senderIndex, itemCount in pairs(GT.InventoryData[itemID].startAmount) do
        if itemCount - GT.db.profile.General.ignoreAmount > 0 then
            total = total + itemCount
        end
    end

    return total
end

function GT:CalculateTotals(senderIndex, calcSenderValue, itemID, calcItemValue)
    GT.Debug("CalculateTotals", 1, senderIndex, calcSenderValue, itemID, calcItemValue)

    if senderIndex then
        return GT:CalculatePlayerTotals(senderIndex, calcSenderValue)
    end

    if itemID then
        return GT:CalculateItemTotals(itemID, calcItemValue)
    end
end

function GT:CalculatePlayerTotals(senderIndex, calcSenderValue)
    GT.Debug("CalculatePlayerTotals", 1, senderIndex, calcSenderValue)

    local total = 0
    local value = 0
    for itemID, itemCount in pairs(GT.sender[senderIndex].inventoryData) do
        if itemID > #GT.ItemData.Other.Other and itemCount - GT.db.profile.General.ignoreAmount > 0 then
            total = total + itemCount
            if calcSenderValue and GT.priceSources then
                value = value + (itemCount * GT:GetItemPrice(itemID))
            end
        end
    end
    return total, math.ceil(value - 0.5) --rounds up to whole number
end

function GT:CalculateItemTotals(itemID, calcItemValue)
    GT.Debug("CalculateItemTotals", 1, itemID, calcItemValue)

    local total = 0
    local value = 0
    for senderIndex, itemCount in pairs(GT.InventoryData[itemID].counts) do
        if itemCount - GT.db.profile.General.ignoreAmount > 0 then
            total = total + itemCount
        end
    end
    if calcItemValue and GT.priceSources then
        value = (total * GT:GetItemPrice(itemID))
    end
    GT.InventoryData[itemID].total = total
    return total, math.ceil(value - 0.5) --rounds up to whole number
end
