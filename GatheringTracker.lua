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

    GT:SetChatType()

    GT:CheckForPlayersLeavingGroup()
    GT:InventoryUpdate("GROUP_ROSTER_UPDATE", true)
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE", true)
    end
end

function GT:CreateBaseFrame()
    --this creates the basic frame structure that the addon uses.
    --the backdrop is used for positioning through the addon options.
    local frame = CreateFrame("Frame", "GT_baseFrame", UIParent)

    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", frame, BackdropTemplateMixin and "BackdropTemplate")
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

    backdrop:Hide()

    local baseFrame = {
        frame = frame,
        backdrop = backdrop,
    }
    GT.baseFrame = baseFrame

    GT:FiltersButton()
end

function GT:ToggleBaseLock(key)
    --used to toggle if the base frame should be shown and interactable.
    --the base frame should only be shown when unlocked so that the user can position it on screen where they want.
    local frame = GT.baseFrame.backdrop
    if key then
        GT.Debug("Show baseFrame", 1)
        frame:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving()
                self.isMoving = true
            end
        end)
        frame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false
                local rel, _, _, xPos, yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
        frame:SetScript("OnHide", function(self)
            if self.isMoving then
                self:StopMovingOrSizing()
                self.isMoving = false
                local rel, _, _, xPos, yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
    else
        GT.Debug("Hide baseFrame", 1)
        frame:Hide()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
        frame:SetScript("OnHide", nil)
    end
end

function GT:OptionsHide()
    if GT.baseFrame then
        --[[This is called when the Interface Options Panel is closed.]]
        --locks the base frame if the options are closed without first locking it.
        if GT.db.profile.General.unlock then
            GT.db.profile.General.unlock = false
            GT:ToggleBaseLock(false)
        end

        GT:SetChatType()

        --Pause Notifications to prevent spam after closing the settings
        GT.NotificationPause = true

        --Do an inventory update if we dont have any information
        if #GT.InventoryData == 0 then
            GT:InventoryUpdate("InterfaceOptionsFrame:OnHide", false)
        end
    end
end

function GT:ClearDisplay()
    GT.Debug("Clear Display", 1)
    for itemID, itemFrame in pairs(GT.Display.Frames) do
        GT:RemoveDiaplayRow(itemID)
    end
    GT.InventoryData = {}
    GT.sender = {}
    GT.Display.ColumnSize = {}
    GT.Display.Order = {}
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
    if groupList == nil then
        --table.remove(GT.Display.ColumnSize, 2)
        if GT.db.profile.General.characterValue and GT.Display.Frames[9999999999] then
            GT:RemoveDiaplayRow(9999999999)
        end
        if GT.db.profile.General.displayAlias and GT.Display.Frames[0] then
            GT:RemoveDiaplayRow(0)
        end
    end
end

function GT:RemoveSender(senderIndex)
    GT.Debug("Remove Sender", 2, senderIndex)
    for itemID, itemFrame in pairs(GT.Display.Frames) do
        GT.Pools.fontStringPool:Release(itemFrame.text[senderIndex])
        GT:AddRemoveDisplayCell("remove", itemFrame, senderIndex)
        itemFrame.displayedCharacters = itemFrame.displayedCharacters - 1

        if itemFrame.displayedCharacters == 1 and itemID > 2 and itemID < 9999999999 then
            GT.Pools.fontStringPool:Release(itemFrame.text[2])
            GT:AddRemoveDisplayCell("remove", itemFrame, 2)
            itemFrame.totalItemCount = nil
        end

        GT:SetAnchor(itemFrame)
    end
    for itemID, inventoryData in pairs(GT.InventoryData) do
        table.remove(inventoryData.counts, senderIndex)
        table.remove(inventoryData.startAmount, senderIndex)
    end
    table.remove(GT.Display.ColumnSize, senderIndex)
    table.remove(GT.sender, senderIndex)
end

function GT:AddRemoveDisplayCell(actionType, itemFrame, index, columnFrame)
    GT.Debug("Add Remove Display Cell", 3, actionType, index)
    if actionType == "add" then
        table.insert(itemFrame.text, index, columnFrame)
    elseif actionType == "remove" then
        table.remove(itemFrame.text, index)
    end

    for textIndex, textFrame in ipairs(itemFrame.text) do
        if textFrame.textType == "totalItemCount" then
            itemFrame.totalItemCount = textIndex
        end
        if textFrame.textType == "pricePerItem" then
            itemFrame.pricePerItem = textIndex
        end
        if textFrame.textType == "priceTotalItem" then
            itemFrame.priceTotalItem = textIndex
        end
    end
end

function GT:RemoveDiaplayRow(itemID --[[int]])
    GT.Debug("Remove Diaplay Row", 3, itemID)
    GT.Pools.framePool:Release(GT.Display.Frames[itemID])
    local order = GT:TableFind(GT.Display.Order, itemID)
    table.remove(GT.Display.Order, order)
    GT.Display.Frames[itemID] = nil
end

local function FramePool_Resetter(framePool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    if frame.icon then
        GT.Pools.texturePool:Release(frame.icon)
        frame.icon = nil
    end
    if frame.iconQuality then
        GT.Pools.texturePool:Release(frame.iconQuality)
        frame.iconQuality = nil
    end
    if frame.iconRarity then
        frame.iconRarity:SetVertexColor(1, 1, 1, 1)
        GT.Pools.texturePool:Release(frame.iconRarity)
        frame.iconRarity = nil
    end
    if frame.text == nil then
        return
    end
    for index, fontString in ipairs(frame.text) do
        GT.Pools.fontStringPool:Release(fontString)
    end
    frame.text = nil
    if frame.totalItemCount then
        frame.totalItemCount = nil
    end
    if frame.pricePerItem then
        frame.pricePerItem = nil
    end
    if frame.priceTotalItem then
        frame.priceTotalItem = nil
    end
end

local function InitializePools()
    GT.Pools.framePool = GT.Pools.framePool or CreateFramePool("Frame", GT.baseFrame.frame, nil, FramePool_Resetter)
    GT.Pools.texturePool = GT.Pools.texturePool or CreateTexturePool(GT.baseFrame.frame, "BACKGROUND")
    GT.Pools.fontStringPool = GT.Pools.fontStringPool or CreateFontStringPool(GT.baseFrame.frame, "BACKGROUND")
end

local function CreateTextDisplay(frame, id, text, type, height, anchor)
    local string = GT.Pools.fontStringPool:Acquire()
    string:SetParent(frame)
    if id < 9999999998 then
        string:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2], GT.db.profile.General.textColor[3])
    else
        string:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.totalColor[1], GT.db.profile.General.totalColor[2], GT.db.profile.General.totalColor[3])
    end
    string:SetHeight(height)
    local offset = 3
    if anchor ~= frame.icon then
        offset = 8 --make spacing fraction of height? (make this adjustable?)
    end
    string.textType = type

    string:SetPoint("LEFT", anchor, "RIGHT", offset, 0)
    string:SetJustifyH("LEFT") --add option for this?
    string:SetText(text)
    string:Show()
    return string
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

function GT:InitiateFrameProcess(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("InitiateFrameProcess", 4, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

    if GT.Display.Frames[id] then
        GT:UpdateDisplayFrame(id,
            iconId,
            iconQuality,
            iconRarity,
            displayText,
            totalItemCount,
            pricePerItem,
            priceTotalItem
        )
    else
        GT:CreateDisplayFrame(id,
            iconId,
            iconQuality,
            iconRarity,
            displayText,
            totalItemCount,
            pricePerItem,
            priceTotalItem
        )
    end
end

function GT:UpdateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("UpdateDisplayFrame", 4, id, iconId, iconQuality, iconRarity, unpack(displayText), totalItemCount, pricePerItem, priceTotalItem)

    if displayText == nil then
        return
    end

    local frame = GT.Display.Frames[id]
    local frameHeight = frame:GetHeight()

    for textIndex, text in ipairs(displayText) do
        if type(text) == "number" then
            text = math.ceil(text - 0.5)
        end
        if textIndex <= frame.displayedCharacters then
            frame.text[textIndex]:SetText(text)
            GT:CheckColumnSize(textIndex, frame.text[textIndex])
        else
            local anchor = frame.icon
            if textIndex > 1 then
                anchor = frame.text[textIndex - 1]
            end
            local textString = CreateTextDisplay(frame, id, text, "count", frameHeight, anchor)
            GT:AddRemoveDisplayCell("add", frame, textIndex, textString)
            GT:CheckColumnSize(textIndex, frame.text[textIndex])
        end
    end
    frame.displayedCharacters = #displayText

    if totalItemCount and GT:GroupDisplayCheck() then
        if frame.totalItemCount then
            frame.text[frame.totalItemCount]:SetText("[" .. math.ceil(totalItemCount - 0.5) .. "]")
            GT:CheckColumnSize(frame.totalItemCount, frame.text[frame.totalItemCount])
        else
            local index = #displayText + 1
            local textString = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frameHeight, frame.text[#displayText])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            GT:CheckColumnSize(index, frame.text[index])
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
        else
            local index = 0
            if frame.priceTotalItem then
                index = #frame.text
            else
                index = #frame.text + 1
            end
            local textString = CreateTextDisplay(frame, id, text, "pricePerItem", frameHeight, frame.text[index - 1])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            GT:CheckColumnSize(index, frame.text[index])
        end
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        if frame.priceTotalItem then
            frame.text[frame.priceTotalItem]:SetText("(" .. math.ceil(priceTotalItem - 0.5) .. "g)")
            GT:CheckColumnSize(frame.priceTotalItem, frame.text[frame.priceTotalItem])
        else
            local index = #frame.text + 1
            local textString = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frameHeight, frame.text[index - 1])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            GT:CheckColumnSize(index, frame.text[index])
        end
    end

    GT:SetAnchor(frame)
end

function GT:CreateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("CreateDisplayFrame", 4, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

    if displayText == nil then
        return
    end

    InitializePools()

    local frame = GT.Pools.framePool:Acquire()
    frame:SetPoint("TOPLEFT", GT.baseFrame.backdrop, "TOPLEFT")
    frame:SetWidth(GT.db.profile.General.iconWidth)
    local frameHeight = math.max(GT.db.profile.General.iconHeight, GT.db.profile.General.totalSize)
    frame:SetHeight(frameHeight + 3)
    frame:Show()

    frame.displayedCharacters = #displayText

    GT.Display.Frames[id] = frame

    frame.icon = GT.Pools.texturePool:Acquire()
    frame.icon:SetParent(frame)
    frame.icon:SetDrawLayer("BACKGROUND", 0)
    frame.icon:SetTexture(iconId)
    frame.icon:SetPoint("LEFT", frame, "LEFT")
    frame.icon:SetWidth(GT.db.profile.General.iconWidth)
    frame.icon:SetHeight(GT.db.profile.General.iconHeight)
    frame.icon:Show()

    if iconQuality then
        frame.iconQuality = GT.Pools.texturePool:Acquire()
        frame.iconQuality:SetParent(frame)
        frame.iconQuality:SetDrawLayer("BACKGROUND", 2)
        if iconQuality == 1 then
            frame.iconQuality:SetAtlas("professions-icon-quality-tier1-inv", true)
        elseif iconQuality == 2 then
            frame.iconQuality:SetAtlas("professions-icon-quality-tier2-inv", true)
        elseif iconQuality == 3 then
            frame.iconQuality:SetAtlas("professions-icon-quality-tier3-inv", true)
        end
        frame.iconQuality:SetAllPoints(frame.icon)
        frame.iconQuality:Show()
    end

    GT:CreateRarityBorder(frame, iconRarity)

    frameHeight = frame:GetHeight()
    frame.text = {}

    for i, text in ipairs(displayText) do
        local anchor = frame.icon
        if i > 1 then
            anchor = frame.text[i - 1]
        end
        if type(text) == "number" then
            text = math.ceil(text - 0.5)
        else
            text = text
        end
        frame.text[i] = CreateTextDisplay(frame, id, text, "count", frameHeight, anchor)
        GT:CheckColumnSize(i, frame.text[i])
    end

    if totalItemCount and GT:GroupDisplayCheck() then --Should I be running group checks here or before calling the function (such as when creating the data that is passed to this function)?
        frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frameHeight, frame.text[#frame.text])
        GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
        frame.totalItemCount = #frame.text
    end

    if pricePerItem and GT.db.profile.General.perItemPrice then
        local text = ""
        if type(pricePerItem) == "number" then
            text = "{" .. math.ceil(pricePerItem - 0.5) .. "g}"
        else
            text = ""
        end
        frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, text, "pricePerItem", frameHeight, frame.text[#frame.text])
        GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
        frame.pricePerItem = #frame.text
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frameHeight, frame.text[#frame.text])
        GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
        frame.priceTotalItem = #frame.text
    end


    GT.Display.Order = GT.Display.Order or {}
    table.insert(GT.Display.Order, id)
    table.sort(GT.Display.Order)
end

function GT:CreateRarityBorder(frame, iconRarity)
    if not GT.db.profile.General.rarityBorder then
        return
    end
    if not frame then
        return
    end
    if not iconRarity then
        return
    end

    frame.iconRarity = GT.Pools.texturePool:Acquire()
    frame.iconRarity:SetParent(frame)
    frame.iconRarity:SetDrawLayer("BACKGROUND", 1)
    local rarity = iconRarity or 1
    if rarity <= 1 then
        frame.iconRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
    else
        frame.iconRarity:SetAtlas("bags-glow-white")
    end
    local R, G, B = C_Item.GetItemQualityColor(rarity)
    frame.iconRarity:SetVertexColor(R, G, B, 0.8)
    frame.iconRarity:SetAllPoints(frame.icon)
    frame.iconRarity:Show()
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

    if GT.db.profile.General.characterValue and GT:GroupDisplayCheck() and GT.tsmLoaded then
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

    if GT.db.profile.General.displayAlias and GT:GroupDisplayCheck() and aliases then
        GT:InitiateFrameProcess(
            0,
            413577,
            nil,
            nil,
            GT:CreateAliasTable()
        )
    end

    GT:AllignRows()
    GT:AllignColumns()
end

function GT:SetupItemRows()
    GT.Debug("SetupItemRows", 1)
    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Prepare Data for Display", 2, itemID)
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
            if GT.tsmLoaded then
                pricePerItem = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000
            end

            GT:InitiateFrameProcess(
                tonumber(itemID),
                GetItemIcon(tonumber(itemID)),
                C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID),
                C_Item.GetItemQualityByID(itemID),
                itemData.counts,
                totalItemCount,
                pricePerItem,
                priceTotalItem
            )
        end
    end
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
    if totalItemCount > 0 then
        GT:InitiateFrameProcess(
            9999999998,
            133647,
            nil,
            nil,
            playerTotals,
            GT:SumTable(playerTotals),
            "",
            priceTotal
        )
    elseif GT.Display.Frames[9999999998] then
        GT:RemoveDiaplayRow(9999999998)
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
        if GT:SumTable(itemData.counts) == 0 then
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
        if id == 1 then
            itemCount = math.floor((GetMoney() / 10000) + 0.5)
        elseif id == 2 then
            for bagIndex = 0, 4 do
                itemCount = itemCount + C_Container.GetContainerNumFreeSlots(bagIndex)
            end
        else
            itemCount = GetItemCount(id, GT.db.profile.General.includeBank, false)
        end

        if itemCount > 0 then
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

function GT:CreateDataMessage(event)
    GT.Debug("CreateDataMessage", 2, event)
    local updateMessage = ""

    for index, id in ipairs(GT.IDs) do
        local itemCount = 0
        if id == 1 then
            itemCount = math.floor((GetMoney() / 10000) + 0.5)
        elseif id == 2 then
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

    GT.Debug("Data Message Starting Processing", 1)

    local senderIndex = GT:UpdateSenderTable(sender)

    local messageTable = GT:CreateItemTable(message)

    GT:UpdateInventoryData(senderIndex, messageTable)

    GT:wait(0.4, "PrepareDataForDisplay", "Data Message Received", true)
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
            GT.InventoryData[itemID].startTotal = GT:CalculateTotals(nil, nil, itemID)
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
            if calcSenderValue and GT.tsmLoaded then
                value = value + (itemCount * (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000)
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
    if calcItemValue and GT.tsmLoaded then
        value = (total * (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000)
    end
    GT.InventoryData[itemID].total = total
    return total, math.ceil(value - 0.5) --rounds up to whole number
end
