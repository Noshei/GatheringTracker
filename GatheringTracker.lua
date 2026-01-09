GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceEvent-3.0", "AceComm-3.0")
---@class GT : AceAddon-3.0, AceEvent-3.0, AceGUI-3.0
local GT = GatheringTracker

GT.InventoryData = {}
GT.Display = {}
GT.Display.Frames = {}
GT.Pools = {}
GT.PlayerEnteringWorld = true
GT.DebugCount = 0
GT.Options = {}


-- Localize global functions
local date = date
local ipairs = ipairs
local math = math
local pairs = pairs
local table = table
local time = time
local type = type

GT.metaData = {
    name = C_AddOns.GetAddOnMetadata("GatheringTracker", "Title"),
    version = C_AddOns.GetAddOnMetadata("GatheringTracker", "Version"),
    notes = C_AddOns.GetAddOnMetadata("GatheringTracker", "Notes"),
}

local gameVersions = {
    [WOW_PROJECT_MAINLINE or 1] = "retail",
    [WOW_PROJECT_CLASSIC or 2] = "era",
    [WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5] = "bc",
    [WOW_PROJECT_WRATH_CLASSIC or 11] = "wrath",
    [WOW_PROJECT_CATACLYSM_CLASSIC or 14] = "cata",
    [WOW_PROJECT_MISTS_CLASSIC or 19] = "mop"
}
GT.gameVersion = gameVersions[WOW_PROJECT_ID] or "retail"
if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and (C_Seasons.GetActiveSeason() == 2) then
    GT.gameVersion = "season"
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
        if GT.db.profile.General.combatHide then
            GT:RegisterEvent("PLAYER_REGEN_DISABLED")
            GT:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        EditModeManagerFrame:HookScript('OnShow', GT.EditModeShow)
        EditModeManagerFrame:HookScript('OnHide', GT.EditModeHide)

        GT:MinimapHandler(not GT.db.profile.miniMap.hide)
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
        GT:UnregisterEvent("PLAYER_REGEN_DISABLED")
        GT:UnregisterEvent("PLAYER_REGEN_ENABLED")

        GT:MinimapHandler(false)
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
    GT:wait(7, "AnchorButtons", "PLAYER_ENTERING_WORLD")
    GT:wait(8, "AllowAlertEffects", "AllowAlertEffects")
end

function GT:GROUP_ROSTER_UPDATE(event)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, event)

    GT:SetDisplayState()
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE", true)
        GT:RefreshPerHourDisplay(true)
    end
end

---Fires when the player enters combat
function GT:PLAYER_REGEN_DISABLED()
    GT.combat = true
    GT:SetDisplayState()
end

---Fires when the player exits combat
function GT:PLAYER_REGEN_ENABLED()
    GT.combat = false
    GT:SetDisplayState()
end

function GT:EditModeShow()
    GT:ToggleBaseLock(true)
end

function GT:EditModeHide()
    GT:ToggleBaseLock(false)
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

    local EditModeLayout =
    {
        ["TopRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
        ["TopLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = 8 },
        ["BottomLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
        ["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
        ["TopEdge"] = { atlas = "_%s-NineSlice-EdgeTop" },
        ["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
        ["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
        ["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
        ["Center"] = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8, },
    };

    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", UIParent, "NineSliceCodeTemplate")
    NineSliceUtil.ApplyLayout(backdrop, EditModeLayout, "editmode-actionbar-highlight")
    backdrop:SetWidth(300)
    backdrop:SetHeight(300)
    backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
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
end

function GT:UpdateBaseFrameSize()
    --Have to reset to 0 otherwise the size will never shrink
    GT.baseFrame.frame:SetHeight(0)
    GT.baseFrame.frame:SetWidth(0)

    local left, bottom, width, height = GT.baseFrame.frame:GetBoundsRect()
    GT.baseFrame.frame:SetHeight(height)
    GT.baseFrame.frame:SetWidth(width)

    --Update Filter Button Anchon in case it gets hidden if it is below the items displayed
    GT:AnchorButtons()
end

function GT:ToggleBaseLock(key)
    GT.Debug("Toggle Base Lock", 1, key)

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

        if GT.db.profile.General.filtersButton or GT.db.profile.General.sessionButtons then
            GT:AnchorButtons()
        end
    end

    if key then
        GT.Debug("Show baseFrame", 1)
        frame:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetMouseClickEnabled(true)
        local backdropWidth, backdropHeight = frame:GetSize()
        local baseWidth, baseHeight = GT.baseFrame.frame:GetSize()
        if backdropWidth < baseWidth or backdropHeight < baseHeight then
            frame:SetSize(baseWidth, baseHeight)
        end
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

    GT.Timer:ToggleControls()
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
    if key then
        return
    end

    GT.Debug("Remove Item Data", 3, key, itemID)

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
        if id > #GT.ItemData.Other.Other then
            for index, string in ipairs(GT.Display.Frames[id].text) do
                if not GT.Display.ColumnSize[index] then
                    GT:CheckColumnSize(index, GT.Display.Frames[id].text[index], id)
                end
                string:SetWidth(GT.Display.ColumnSize[index])
            end
        else
            -- 3 is the offset from the icon, 8 is the offset to the next column
            local offset = GT.db.profile.General.iconWidth + 3 + 8
            local parentWidth = GT.Display.Frames[id]:GetWidth()
            local width = GT.Display.Frames[id].text[1]:GetUnboundedStringWidth()
            if GT.Display.ColumnSize[1] and width < GT.Display.ColumnSize[1] then
                width = GT.Display.ColumnSize[1]
            end
            GT.Display.Frames[id].text[1]:SetWidth(width)
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
    if GT.Display.Frames[1] or GT.Display.Frames[3] then
        for i = 1, #GT.ItemData.Other.Other, 2 do
            if GT.Display.Frames[i] then
                local otherWidth = GT.Display.Frames[i].text[1]:GetUnboundedStringWidth()
                if otherWidth > textWidth then
                    textWidth = otherWidth
                    offsets = 11
                end
            end
        end
    end
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
            if id ~= 3 then
                frame.text[textIndex]:SetText(text)
            end
            GT:CheckColumnSize(textIndex, frame.text[textIndex], id)
        end
    else
        if type(displayText) == "number" then
            displayText = math.ceil(displayText - 0.5)
        end
        if id ~= 3 then
            frame.text[1]:SetText(displayText)
        end
        GT:CheckColumnSize(1, frame.text[1], id)
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
            GT:CheckColumnSize(frame.pricePerItem, frame.text[frame.pricePerItem], id)
        end
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        if frame.priceTotalItem then
            frame.text[frame.priceTotalItem]:SetText("(" .. math.ceil(priceTotalItem - 0.5) .. "g)")
            GT:CheckColumnSize(frame.priceTotalItem, frame.text[frame.priceTotalItem], id)
        end
    end

    if itemsPerHour and GT.db.profile.General.itemsPerHour then
        GT:UpdateItemsPerHour(frame, itemsPerHour, id)
    end

    if goldPerHour and GT.db.profile.General.goldPerHour then
        GT:UpdateGoldPerHour(frame, goldPerHour, id)
    end

    GT:SetAnchor(frame)
end

function GT:UpdateItemsPerHour(frame, itemsPerHour, id)
    if not frame.itemsPerHour then
        return
    end

    frame.text[frame.itemsPerHour]:SetText(math.ceil(itemsPerHour - 0.5) .. "/h")
    GT:CheckColumnSize(frame.itemsPerHour, frame.text[frame.itemsPerHour], id)
end

function GT:UpdateGoldPerHour(frame, goldPerHour, id)
    if not frame.goldPerHour then
        return
    end

    frame.text[frame.goldPerHour]:SetText(math.ceil(goldPerHour - 0.5) .. "g/h")
    GT:CheckColumnSize(frame.goldPerHour, frame.text[frame.goldPerHour], id)
end

function GT:PrepareDataForDisplay(event, wait)
    GT.Debug("Prepare Data for Display", 1, event, wait)
    if wait then
        GT:wait(0.1, "PrepareDataForDisplay", "PrepareDataForDisplay", false)
        return
    end

    GT.Display.ColumnSize = {}

    GT:SetTSMPriceSource()

    GT:SetupItemRows()

    GT:SetupTotalsRow()

    GT:AllignRows()
    GT:AllignColumns()
    GT:UpdateBaseFrameSize()
    if GT.db.profile.General.collapseDisplay then
        GT:CollapseManager(false)
    end

    GT.Timer:ToggleControls()
end

function GT:SetupItemRows()
    GT.Debug("SetupItemRows", 1)
    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Setup Item Row", 6, itemID)
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
            if GT.db.profile.General.sessionOnly and GT.db.profile.General.sessionItems then
                count = GT.InventoryData[itemID].sessionCount
            else
                count = GT.InventoryData[itemID].count
            end

            if (count > 0 and count > GT.db.profile.General.ignoreAmount) or GT.db.profile.General.allFiltered then
                local pricePerItem = nil
                local itemsPerHour = nil
                local goldPerHour = nil
                local displayText = GT:GetItemRowData(itemID)
                if GT.priceSources then
                    pricePerItem = GT:GetItemPrice(itemID)
                end
                local priceTotalItem = count * (pricePerItem or 0)

                if GT.db.profile.General.itemsPerHour or GT.db.profile.General.goldPerHour then
                    itemsPerHour = GT:CalculateItemsPerHour(itemID)
                    goldPerHour = itemsPerHour * (pricePerItem or 0)
                end

                local iconQuality = nil
                if GT.gameVersion == "retail" then
                    iconQuality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)
                end

                GT:InitiateFrameProcess(
                    itemID,
                    C_Item.GetItemIconByID(itemID),
                    iconQuality,
                    C_Item.GetItemQualityByID(itemID),
                    displayText,
                    pricePerItem,
                    priceTotalItem,
                    itemsPerHour,
                    goldPerHour
                )

                GT.AlertSystem:Alerts(itemID, displayText, priceTotalItem)
            elseif GT.Display.Frames[itemID] then
                GT:RemoveDiaplayRow(itemID)
            end
        end
    end
end

---generates the count data that will be displayed for a given item
---@param itemID number
---@return table|number displayText table if both session and total count are enabled, otherwise number
function GT:GetItemRowData(itemID)
    GT.Debug("GetItemRowData", 2, itemID)

    if GT.db.profile.General.sessionOnly and GT.db.profile.General.sessionItems then
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
        local timeDiff = time() - GT.Timer.StartTime

        --divind time diff in Seconds by 3600 to get time diff in hours
        local itemsPerHour = itemDiff / (timeDiff / 3600)
        GT.Debug("CalculateItemsPerHour", 3, itemID, itemsPerHour, itemData.total, itemDiff, timeDiff)
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
    local timeDiff = time() - GT.Timer.StartTime

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
    if not GT.db.profile.General.totalsRow then
        return
    end

    local playerTotals = {}
    local priceTotal = 0
    local itemsPerHour = nil
    local goldPerHour = nil

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
        if GT.db.profile.General.itemsPerHour or GT.db.profile.General.goldPerHour then
            itemsPerHour, goldPerHour = GT:CalculateItemsPerHourTotal(playerTotal)
        end

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
        GT.AlertSystem:Alerts(2, playerTotals, priceTotal)
    elseif GT.Display.Frames[9999999998] then
        GT:RemoveDiaplayRow(9999999998)
    end
end

function GT:RefreshPerHourDisplay(wait)
    GT.Debug("Refresh Per Hour Display", 1, wait)
    if not GT.db.profile.General.itemsPerHour and not GT.db.profile.General.goldPerHourthen then
        return
    end
    if not GT.Timer.Running then
        return
    end
    if GT.db.profile.General.hideSession then
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
                GT:UpdateItemsPerHour(itemFrame, itemsPerHour, itemID)
            end

            if itemFrame.goldPerHour and GT.db.profile.General.goldPerHour then
                goldPerHour = itemsPerHour * (pricePerItem or 0)
                GT:UpdateGoldPerHour(itemFrame, goldPerHour, itemID)
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
                GT:UpdateItemsPerHour(itemFrame, itemsPerHour, itemID)
            end

            if itemFrame.goldPerHour and GT.db.profile.General.goldPerHour then
                GT:UpdateGoldPerHour(itemFrame, goldPerHour, itemID)
            end
        end
    end

    if wait then
        GT:wait(5, "RefreshPerHourDisplay", true)
        return
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

    for index, data in ipairs(GT.IDs) do
        local itemCount = 0
        if data.id == GT.ItemData.Other.Other[1].id then
            itemCount = math.floor((GetMoney() / 10000) + 0.5)
        elseif data.id == GT.ItemData.Other.Other[2].id then
            for bagIndex = 0, 4 do
                itemCount = itemCount + C_Container.GetContainerNumFreeSlots(bagIndex)
            end
        elseif data.id == GT.ItemData.Other.Other[3].id then
            itemCount = 123456
        else
            itemCount = C_Item.GetItemCount(
                data.id,
                GT.db.profile.General.includeBank,
                false,
                false,
                GT.db.profile.General.includeWarband
            )
        end

        GT.InventoryData[data.id] = GT.InventoryData[data.id] or GT:ItemDataConstructor(data.id)
        GT.InventoryData[data.id].count = itemCount

        if not GT.IDs[index].processed then
            GT.InventoryData[data.id].startAmount = itemCount
            GT.IDs[index].processed = true
        end

        GT.InventoryData[data.id].sessionCount =
            GT.InventoryData[data.id].count - GT.InventoryData[data.id].startAmount

        if GT.InventoryData[data.id].sessionCount < 0 then
            GT.InventoryData[data.id].sessionCount = 0
            GT.InventoryData[data.id].startAmount = itemCount
        end
    end

    if GT.Timer.StartTime == 0 then
        GT.Timer.StartTime = time()
    end

    GT:PrepareDataForDisplay("Process Data")
end

--- Creates an itemData Construct
---@param itemID integer ID of the item to create
---@return table itemData
function GT:ItemDataConstructor(itemID)
    GT.Debug("ItemDataConstructor", 6, itemID)

    local itemData = {}
    itemData.count = 0
    itemData.startAmount = 0
    itemData.sessionCount = 0
    --itemData.startTime = time()

    return itemData
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
