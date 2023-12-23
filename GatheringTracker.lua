GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")
local GT = GatheringTracker
GT.sender = {}
GT.count = {}
GT.InventoryData = {}
GT.Display = {}
GT.Display.frames = {}
GT.Display.list = {}
GT.Display.length = {}
GT.Display.Frames = {}
GT.Pools = {}
GT.PlayerEnteringWorld = true
GT.DebugCount = 0
GT.Options = {}
GT.Notifications = {}
GT.NotificationPause = true

GT.metaData = {
    name = GetAddOnMetadata("GatheringTracker", "Title"),
    version = GetAddOnMetadata("GatheringTracker", "Version"),
    notes = GetAddOnMetadata("GatheringTracker", "Notes"),
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

    GT:wait(6, "InventoryUpdate", "PLAYER_ENTERING_WORLD", false)
    GT:wait(7, "NotificationHandler", "PLAYER_ENTERING_WORLD")
end

function GT:GROUP_ROSTER_UPDATE(event, wait)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, wait)

    --Check if we need to wait on doing the update.
    --If we do need to wait, determine if an existing wait table has already been created
    --If we dont need to wait, do the update.

    if wait then
        GT:wait(2, "GROUP_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", false)
        return
    end

    GT:SetChatType()

    GT:CheckForPlayersLeavingGroup()
    GT:InventoryUpdate("GROUP_ROSTER_UPDATE", false)
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE")
    end
end

function GT:CheckForPlayersLeavingGroup()
    GT.Debug("Check For Players Leaving Group", 2)
    if #GT.sender <= 1 then
        return
    end
    local groupList = GT:GetGroupList()

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
        table.remove(GT.Display.ColumnSize, 2)
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

        if itemFrame.displayedCharacters == 1 then
            GT.Pools.fontStringPool:Release(itemFrame.text[2])
            GT:AddRemoveDisplayCell("remove", itemFrame, 2)
            itemFrame.totalItemCount = nil
        end

        GT:SetAnchor(itemFrame)
    end
    for itemID, inventoryData in pairs(GT.InventoryData) do
        table.remove(inventoryData, senderIndex)
    end
    table.remove(GT.Display.ColumnSize, senderIndex)
    table.remove(GT.sender, senderIndex)
end

function GT:CheckIfDisplayResetNeeded(data)
    --checks if any items need to be removed from the display.
    --if an item needs to be removed from the display a full reset is required
    for _, itemData in pairs(data) do
        local total = 0
        for _, v in ipairs(itemData) do
            total = total + v
        end
        if total == 0 then
            return false
        end
    end
    return true
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

    backdrop:Hide()

    local baseFrame = {
        frame = frame,
        backdrop = backdrop,
    }
    GT.baseFrame = baseFrame

    GT:FiltersButton()
end

function GT:ToggleFilterButton(show)
    if show then
        GT.Debug("Show Filters Button", 1)
        GT.baseFrame.button:Show()
        if GT.baseFrame.button.mouseOver then
            GT.baseFrame.button.mouseOver:Show()
        end
        GT:FiltersButtonFade()
        return
    end

    if not show then
        GT.Debug("Hide Filters Button", 1)
        if GT.baseFrame.button then
            GT.baseFrame.button:Hide()
            if GT.baseFrame.button.mouseOver then
                GT.baseFrame.button.mouseOver:Hide()
            end
        end
        return
    end
end

function GT:FiltersButton()
    if not GT.db.profile.General.filtersButton then
        GT:ToggleFilterButton(false)
        return
    end
    if not GT.Enabled then
        GT:ToggleFilterButton(false)
        return
    end
    if GT.baseFrame.button then
        GT:ToggleFilterButton(true)
        return
    end

    GT.Debug("Create Filters Button", 1)
    local filterButton = CreateFrame("Button", "GT_baseFrame_filtersButton", GT.baseFrame.frame, "UIPanelButtonTemplate")
    filterButton:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT")
    filterButton:SetWidth(25)
    filterButton:SetHeight(25)
    filterButton:SetText("F")
    filterButton:EnableMouse(true)
    filterButton:RegisterForClicks("AnyDown")
    filterButton:SetFrameStrata("BACKGROUND")
    filterButton:Show()

    local menuFrame = CreateFrame("Frame", "GT_baseFrame_filtersMenu", UIParent, "UIDropDownMenuTemplate")

    local filterMenu = {}
    for expansion, expansionData in pairs(GT.ItemData) do
        local expansionMenuList = {}

        for category, categoryData in pairs(expansionData) do
            local categoryMenuList = {}

            for _, itemData in ipairs(categoryData) do
                local itemDetails = {}
                if itemData.id == -1 then
                    itemDetails = {
                        text = itemData.name,
                        notCheckable = 1,
                        disabled = true,
                    }
                else
                    itemDetails = {
                        text = itemData.name,
                        isNotRadio = true,
                        keepShownOnClick = true,
                        icon = tostring(itemData.icon or GetItemIcon(tonumber(itemData.id)) or ""),
                        checked = function()
                            if GT.db.profile.Filters[itemData.id] == true then
                                return true
                            else
                                return false
                            end
                        end,
                        func = function(_, _, _, key)
                            GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name, key)
                            if GT.db.profile.Filters[itemData.id] == true then
                                GT.db.profile.Filters[itemData.id] = nil
                            else
                                GT.db.profile.Filters[itemData.id] = true
                            end

                            GT:RebuildIDTables()
                            GT:RemoveDisabledItemData(key, itemData.id)
                            GT:InventoryUpdate(expansion .. " " .. category .. " " .. itemData.name .. " menu clicked", false)
                        end,
                    }
                    -- Add asterics to the name to distinguish between the different qualities
                    if itemData.quality then
                        if itemData.quality == 1 then
                            itemDetails.text = "|cff784335" .. itemDetails.text .. "*"
                        elseif itemData.quality == 2 then
                            itemDetails.text = "|cff96979E" .. itemDetails.text .. "**"
                        elseif itemData.quality == 3 then
                            itemDetails.text = "|cffDCC15F" .. itemDetails.text .. "***"
                        end
                    end
                end
                categoryMenuList[itemData.order] = itemDetails
            end

            local categoryMenuData = {}
            categoryMenuData = {
                text = category,
                keepShownOnClick = false,
                hasArrow = true,
                isNotRadio = true,
                menuList = categoryMenuList,
                checked = function()
                    local checked = true
                    for _, itemData in ipairs(categoryData) do
                        if itemData.id ~= -1 and checked == true then
                            if GT.db.profile.Filters[itemData.id] == true then
                                checked = GT.db.profile.Filters[itemData.id]
                            else
                                checked = false
                                break
                            end
                        end
                    end
                    return checked
                end,
                func = function(_, _, _, key)
                    GT.Debug("Category Button Clicked", 2, expansion, category, key)
                    local key = not key
                    for _, itemData in ipairs(categoryData) do
                        if not (itemData.id == -1) then
                            GT.db.profile.Filters[itemData.id] = key or nil
                            GT:RemoveDisabledItemData(key, itemData.id)
                        end
                    end

                    GT:RebuildIDTables()
                    GT:InventoryUpdate(expansion .. " " .. category .. " clicked", false)
                end,
            }
            table.insert(expansionMenuList, categoryMenuData)
        end

        table.sort(expansionMenuList, function(k1, k2)
            return GT.categories[k1.text] < GT.categories[k2.text]
        end)

        filterMenu[GT.expansions[expansion]] = {
            text = expansion,
            keepShownOnClick = false,
            hasArrow = true,
            isNotRadio = true,
            menuList = expansionMenuList,
            checked = function()
                local checked = true
                for category, categoryData in pairs(expansionData) do
                    for _, itemData in ipairs(categoryData) do
                        if itemData.id ~= -1 and checked == true then
                            if GT.db.profile.Filters[itemData.id] == true then
                                checked = GT.db.profile.Filters[itemData.id]
                            else
                                checked = false
                                break
                            end
                        end
                    end
                end
                return checked
            end,
            func = function(_, _, _, key)
                GT.Debug("Expansion Button Clicked", 2, expansion, key)
                local key = not key
                for category, categoryData in pairs(expansionData) do
                    for _, itemData in ipairs(categoryData) do
                        if not (itemData.id == -1) then
                            GT.db.profile.Filters[itemData.id] = key or nil
                            GT:RemoveDisabledItemData(key, itemData.id)
                        end
                    end
                end
                --[[local checked = 0
                local count = 0
                for category, categoryData in pairs(expansionData) do
                    for _, itemData in ipairs(categoryData) do
                        if itemData.id ~= -1 then
                            if GT.db.profile.Filters[itemData.id] == true then
                                checked = checked + 1
                            end
                            GT.db.profile.Filters[itemData.id] = nil
                            count = count + 1
                        end
                    end
                end
                if checked == 0 or checked < count then
                    for category, categoryData in pairs(expansionData) do
                        for _, itemData in ipairs(categoryData) do
                            if itemData.id ~= -1 then
                                GT.db.profile.Filters[itemData.id] = true
                            end
                        end
                    end
                end
                GT.Debug("Expansion Button Clicked", 2, expansion, key, checked, count)]]

                GT:RebuildIDTables()
                GT:InventoryUpdate(expansion .. " clicked", false)
            end,
        }
    end

    menuFrame:SetPoint("CENTER", UIParent, "CENTER")
    menuFrame:Hide()

    GT.baseFrame.menu = menuFrame
    GT.baseFrame.filterMenu = filterMenu

    --add Custom Filters to filterMenu
    GT:CreateCustomFiltersList()

    --add Profiles to filterMenu
    GT:CreateProfilesList()

    filterButton:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            EasyMenu(GT.baseFrame.filterMenu, GT.baseFrame.menu, "cursor", 0, 0, "MENU")
        elseif button == "RightButton" then
            GT:ClearFilters()
        end
    end)

    GT.baseFrame.button = filterButton
    GT:FiltersButtonFade()
end

function GT:FiltersButtonFade(setAlpha)
    if not GT.Enabled then
        return
    end
    if not GT.db.profile.General.filtersButton then
        return
    end
    if not GT.baseFrame.button then
        return
    end
    if setAlpha then
        local alpha = GT.db.profile.General.buttonAlpha / 100
        GT.baseFrame.button:SetAlpha(alpha)
        return
    end

    if GT.db.profile.General.buttonFade then
        if not GT.baseFrame.button.mouseOver then
            local mouseOver = CreateFrame("Frame", "GT_baseFrame_filterButton_mouseOver", UIParent)
            mouseOver:SetWidth(75)
            mouseOver:SetHeight(75)
            mouseOver:SetPoint("CENTER", GT.baseFrame.button, "CENTER")
            mouseOver:SetMouseClickEnabled(false)
            mouseOver:SetFrameStrata("LOW")
            GT.baseFrame.button.mouseOver = mouseOver
        end
        GT.baseFrame.button:SetIgnoreParentAlpha(GT.db.profile.General.buttonFade)
        GT.baseFrame.button:LockHighlight()
        GT.baseFrame.button.mouseOver:SetScript("OnEnter", function(self, motion)
            if motion then
                GT.baseFrame.button:SetAlpha(1)
                GT:wait(nil, "FiltersButtonFade")
            end
        end)
        GT.baseFrame.button.mouseOver:SetScript("OnLeave", function(self, motion)
            if motion then
                GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", true)
            end
        end)
        GT.baseFrame.button.mouseOver:SetMouseClickEnabled(false)
        GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", true)
    else
        GT.baseFrame.button:SetIgnoreParentAlpha(GT.db.profile.General.buttonFade)
        GT.baseFrame.button:SetAlpha(1)
        GT.baseFrame.button:UnlockHighlight()
        if GT.baseFrame.button.mouseOver then
            GT.baseFrame.button.mouseOver:SetScript("OnEnter", nil)
            GT.baseFrame.button.mouseOver:SetScript("OnLeave", nil)
        end
    end
end

function GT:CreateCustomFiltersList()
    if not GT.baseFrame.filterMenu then
        return
    end

    local customFiltersMenuList = {}
    for id, data in pairs(GT.db.profile.CustomFiltersTable) do
        local itemID = tonumber(id)
        local item = Item:CreateFromItemID(itemID)
        --Waits for the data to be returned from the server
        if not item:IsItemEmpty() then
            item:ContinueOnItemLoad(function()
                local itemName = item:GetItemName()
                local itemDetails = {
                    text = itemName,
                    isNotRadio = true,
                    keepShownOnClick = true,
                    icon = tostring(GetItemIcon(itemID) or ""),
                    checked = function()
                        return GT.db.profile.CustomFiltersTable[id]
                    end,
                    func = function(_, _, _, key)
                        GT.Debug("Custom Filter Item Button Clicked", 2, itemName, key)
                        if GT.db.profile.CustomFiltersTable[id] == true then
                            GT.db.profile.CustomFiltersTable[id] = false
                        else
                            GT.db.profile.CustomFiltersTable[id] = true
                        end

                        GT:RebuildIDTables()
                        GT:RemoveDisabledItemData(key, itemID)
                        GT:InventoryUpdate("Custom Filter " .. itemName .. " menu clicked", false)
                    end,
                }
                table.insert(customFiltersMenuList, itemDetails)
            end)
        end
    end
    table.sort(customFiltersMenuList, function(a, b)
        return a.text < b.text
    end)
    local customFilters = {
        text = "Custom Filters",
        keepShownOnClick = false,
        hasArrow = true,
        isNotRadio = true,
        menuList = customFiltersMenuList,
        checked = function()
            local checked = true
            for id, data in pairs(GT.db.profile.CustomFiltersTable) do
                if data == true then
                    checked = true
                else
                    checked = false
                    break
                end
            end
            return checked
        end,
        func = function(_, _, _, key)
            GT.Debug("Custom Filters Button Clicked", 2, key)
            local key = not key
            for id, data in pairs(GT.db.profile.CustomFiltersTable) do
                GT.db.profile.CustomFiltersTable[id] = key
                GT:RemoveDisabledItemData(key, id)
            end
            --[[local checked = 0
            local count = 0
            for id, data in pairs(GT.db.profile.CustomFiltersTable) do
                if data == true then
                    checked = checked + 1
                end
                GT.db.profile.CustomFiltersTable[id] = false
                count = count + 1
            end
            if checked == 0 or checked < count then
                for id, data in pairs(GT.db.profile.CustomFiltersTable) do
                    GT.db.profile.CustomFiltersTable[id] = true
                end
            end
            GT.Debug("Custom Filters Button Clicked", 2, key, checked, count)]]

            GT:RebuildIDTables()
            GT:InventoryUpdate("Custom Filters clicked", false)
        end,
    }
    local position = 0

    for index, data in ipairs(GT.baseFrame.filterMenu) do
        if data.text == customFilters.text then
            position = index
        end
    end
    if position == 0 then
        position = #GT.baseFrame.filterMenu + 1
    end
    GT.baseFrame.filterMenu[position] = customFilters
end

function GT:CreateProfilesList()
    if not GT.baseFrame.filterMenu then
        return
    end
    local profilesMenuList = {}
    local profiles = GT.db:GetProfiles()
    for _, name in ipairs(profiles) do
        local profileDetails = {
            text = name,
            isNotRadio = false,
            keepShownOnClick = false,
            checked = function()
                local current = GT.db:GetCurrentProfile()
                if current == name then
                    return true
                else
                    return false
                end
            end,
            func = function(_, _, _, key)
                GT.Debug("Profile Button Clicked", 2, name, key)
                GT.db:SetProfile(name)
            end,
        }
        table.insert(profilesMenuList, profileDetails)
    end
    table.sort(profilesMenuList, function(a, b)
        return a.text < b.text
    end)
    local profiles = {
        text = "Profiles",
        keepShownOnClick = true,
        hasArrow = true,
        notCheckable = 1,
        menuList = profilesMenuList,
    }
    local position = 0
    for index, data in ipairs(GT.baseFrame.filterMenu) do
        if data.text == profiles.text then
            position = index
        end
    end
    if position == 0 then
        position = #GT.baseFrame.filterMenu + 1
    end
    GT.baseFrame.filterMenu[position] = profiles
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

        if GT.db.profile.General.groupType > 0 then
            if IsInRaid() then
                GT.groupMode = "RAID"
            elseif IsInGroup() then
                GT.groupMode = "PARTY"
            else
                GT.groupMode = "WHISPER"
            end
        else
            GT.groupMode = "WHISPER"
        end

        --Pause Notifications to prevent spam after closing the settings
        GT.NotificationPause = true

        --Do an inventory update if we dont have any information
        if #GT.InventoryData == 0 then
            GT:InventoryUpdate("InterfaceOptionsFrame:OnHide", false)
        end
    end
end

function GT:GroupCheck(mode)
    -- this is used to determine if the addon display should be shown.
    -- this is decided by the addon configuration and if the player is in a group in game.
    -- within the addon this is used to decide if certain operations should happen
    -- it is also used as a check to prevent major addon functions that are unnecessary when the display is hidden
    -- should refactor this to be better foir the different use cases
    GT.Debug("Group Check", 2, mode, GT.db.profile.General.groupType)
    if mode == "Group" then
        if GT.db.profile.General.groupType == 1 and not IsInGroup() then --if Group Mode is ENABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, false)
            return false
        elseif GT.db.profile.General.groupType >= 1 and IsInGroup() then --if Group Mode is ENABLED and player IS in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, true)
            return true
        end
    elseif mode == "Solo" then
        if not GT.db.profile.General.groupType == 1 and IsInGroup() then --if Group Mode is DISABLED and player IS in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, false)
            return false
        elseif GT.db.profile.General.groupType ~= 1 and not IsInGroup() then --if Group Mode is DISABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, true)
            return true
        end
    elseif mode == nil then
        if GT.db.profile.General.groupType == 1 and not IsInGroup() then --if Group Mode is ENABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, false)
            return false
        elseif GT.db.profile.General.groupType >= 1 and IsInGroup() then --if Group Mode is ENABLED and player IS in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, true)
            return true
        elseif GT.db.profile.General.groupType ~= 1 and IsInGroup() then --if Group Mode is DISABLED and player IS in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, false)
            return false
        elseif GT.db.profile.General.groupType ~= 1 and not IsInGroup() then --if Group Mode is DISABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, mode, GT.db.profile.General.groupType, true)
            return true
        end
    end
end

function GT:NotificationHandler(mode, id, amount, value)
    GT.Debug("Notifications Handler", 2, mode, id, amount, value)

    local NotificationTriggered = false

    if value then
        value = math.ceil(value)
    end

    local function NotificationCheck(notiType, buildTable)
        local threshold = tonumber(GT.db.profile.Notifications[notiType].threshold)

        local passedValue
        if notiType == "Count" then
            passedValue = amount
        else
            passedValue = value
        end

        if passedValue >= threshold then
            GT.Debug(notiType .. " Notifications Threshold Exceeded", 2, mode, id, amount, value)
            if GT.db.profile.Notifications[notiType].interval == 1 then --Interval
                if GT.Notifications[id] and GT.Notifications[id][notiType] > 0 then
                    if (passedValue - GT.Notifications[id][notiType]) >= threshold then
                        GT.Debug(notiType .. " Notifications Interval Threshold Exceeded", 2, mode, id, amount, value, GT.Notifications[id][notiType])
                        GT.Notifications[id][notiType] = math.floor(passedValue / threshold) * threshold
                        if not buildTable then
                            NotificationTriggered = true
                            GT:TriggerNotification(notiType)
                        end
                    end
                else
                    if GT.Notifications[id] then
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = math.floor(passedValue / threshold) * threshold,
                                Gold = (GT.Notifications[id].Gold or 0),
                            }
                        else
                            GT.Notifications[id] = {
                                Count = (GT.Notifications[id].Count or 0),
                                Gold = math.floor(passedValue / threshold) * threshold,
                            }
                        end
                    else
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = math.floor(passedValue / threshold) * threshold,
                                Gold = 0,
                            }
                        else
                            GT.Notifications[id] = {
                                Count = 0,
                                Gold = math.floor(passedValue / threshold) * threshold,
                            }
                        end
                    end
                    if not buildTable then
                        NotificationTriggered = true
                        GT:TriggerNotification(notiType)
                    end
                end
            end
            if GT.db.profile.Notifications[notiType].interval == 0 then --Exact
                if not GT.Notifications[id] or GT.Notifications[id][notiType] < threshold then
                    GT.Debug(notiType .. " Notifications Exact Threshold Exceeded", 2, mode, id, amount, value, GT.Notifications[id][notiType])
                    if GT.Notifications[id] then
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = threshold,
                                Gold = (GT.Notifications[id].Gold or 0),
                            }
                        else
                            GT.Notifications[id] = {
                                Count = (GT.Notifications[id].Count or 0),
                                Gold = threshold,
                            }
                        end
                    else
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = threshold,
                                Gold = 0,
                            }
                        else
                            GT.Notifications[id] = {
                                Count = 0,
                                Gold = threshold,
                            }
                        end
                    end
                    if not buildTable then
                        NotificationTriggered = true
                        GT:TriggerNotification(notiType)
                    end
                end
            end
        end
    end

    if GT.db.profile.Notifications.Count.enable then
        if mode == "all" and (GT.db.profile.Notifications.Count.itemAll == 1 or GT.db.profile.Notifications.Count.itemAll == 2) then --All Items or Both
            NotificationCheck("Count", false)
        end
        if mode == "each" and (GT.db.profile.Notifications.Count.itemAll == 0 or GT.db.profile.Notifications.Count.itemAll == 2) then --Each Item or Both
            NotificationCheck("Count", false)
        end
    end

    if GT.db.profile.Notifications.Gold.enable and GT.tsmLoaded and GT.db.profile.General.tsmPrice > 0 then
        if mode == "all" and (GT.db.profile.Notifications.Gold.itemAll == 1 or GT.db.profile.Notifications.Gold.itemAll == 2) then --All Items or Both
            NotificationCheck("Gold", false)
        end
        if mode == "each" and (GT.db.profile.Notifications.Gold.itemAll == 0 or GT.db.profile.Notifications.Gold.itemAll == 2) then --Each Item or Both
            if GT.db.profile.General.tsmPrice > 0 then
                local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(id)) or 0) / 10000
                value = math.ceil(eprice * amount)
                NotificationCheck("Gold", false)
            end
        end
    end

    if mode == "PLAYER_ENTERING_WORLD" then
        GT.Debug("Generate Notification Table", 1)
        for i = 1, table.getn(GT.sender) do
            if GT.sender[1].name == GT.Player then
                local playerTotal = 0
                for itemID, data in pairs(GT.InventoryData) do
                    if GT:TableFind(GT.IDs, tonumber(itemID)) then
                        id = tonumber(itemID)
                        amount = data[i]
                        playerTotal = playerTotal + amount
                        NotificationCheck("Count", true)
                        if GT.db.profile.General.tsmPrice > 0 then
                            local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(itemID)) or 0) / 10000
                            value = math.ceil(eprice * amount)
                            NotificationCheck("Gold", true)
                        end
                    end
                end
                id = "all"
                amount = playerTotal
                NotificationCheck("Count", true)
                value = GT.sender[i].totalValue
                NotificationCheck("Gold", true)
            end
        end
    end
end

function GT:TriggerNotification(alertType)
    GT.Debug("Trigger Notifications", 1, alertType, GT.NotificationPause)
    if not GT.NotificationPause then
        --GT.Debug("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 Notifications |r" .. alertType, 1)
        if media:IsValid("sound", GT.db.profile.Notifications[alertType].sound) then
            PlaySoundFile(media:Fetch("sound", GT.db.profile.Notifications[alertType].sound), "master")
        else
            GT.Debug("Trigger Notifications: Play Default Sound", 1, alertType, GT.NotificationPause, GT.db.profile.Notifications[alertType].sound, GT.defaults.profile.Notifications[alertType].sound)
            PlaySoundFile(media:Fetch("sound", GT.defaults.profile.Notifications[alertType].sound), "master")
        end
    end
end

function GT:RemoveDisabledItemData(key, itemID)
    GT.Debug("Remove Disabled Item Data", 3, key, itemID)
    if key then
        return
    end
    local itemID = tostring(itemID)

    if GT.InventoryData[itemID] then
        GT.Debug("Remove Disabled Item Data: remove Inventory", 3, key, itemID)
        GT.InventoryData[itemID] = nil
    end

    for senderIndex, senderData in ipairs(GT.sender) do
        if senderData.inventoryData[itemID] then
            GT.Debug("Remove Disabled Item Data: remove Sender", 3, key, itemID, senderIndex)
            senderData.inventoryData[itemID] = nil
        end
    end

    if GT.Display.Frames[tonumber(itemID)] then
        GT:RemoveDiaplayRow(tonumber(itemID))
        GT:AllignRows()
    end
end

function GT:PrepareDataForDisplay(event)
    GT.Debug("Prepare Data for Display", 1, event)

    GT.Display.ColumnSize = {}

    local playerTotals = {}
    local itemTotals = {}
    local aliases = {}
    local totalItems = 0
    local totalPrice = 0

    GT:SetTSMPriceSource()

    for senderIndex, senderData in ipairs(GT.sender) do
        for itemID, itemCount in pairs(senderData.inventoryData) do
            if itemID > #GT.ItemData.Other.Other then --checks if itemID is numeric
                local calculatedItemCount = 0

                calculatedItemCount = itemCount - GT.db.profile.General.ignoreAmount
                if calculatedItemCount < 0 then
                    calculatedItemCount = 0
                end

                itemTotals.countTotal = itemTotals.countTotal or {}
                itemTotals.countTotal[itemID] = itemTotals.countTotal[itemID] or 0
                itemTotals.countTotal[itemID] = itemTotals.countTotal[itemID] + calculatedItemCount

                playerTotals.countTotal = playerTotals.countTotal or {}
                playerTotals.countTotal[senderIndex] = playerTotals.countTotal[senderIndex] or 0
                playerTotals.countTotal[senderIndex] = playerTotals.countTotal[senderIndex] + calculatedItemCount

                totalItems = totalItems + calculatedItemCount

                local pricePerItem = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000
                local totalItemValue = calculatedItemCount * pricePerItem

                itemTotals.valueTotal = itemTotals.valueTotal or {}
                itemTotals.valueTotal[itemID] = itemTotals.valueTotal[itemID] or 0
                itemTotals.valueTotal[itemID] = itemTotals.valueTotal[itemID] + totalItemValue

                playerTotals.valueTotal = playerTotals.valueTotal or {}
                playerTotals.valueTotal[senderIndex] = playerTotals.valueTotal[senderIndex] or 0
                playerTotals.valueTotal[senderIndex] = playerTotals.valueTotal[senderIndex] + totalItemValue

                totalPrice = totalPrice + totalItemValue
            end
        end

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

    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Check for Items to remove from Display", 4, itemID)
        if GT:SumTable(itemData) == 0 then
            GT.InventoryData[itemID] = nil
            if GT.Display.Frames[tonumber(itemID)] then
                GT:RemoveDiaplayRow(tonumber(itemID))
            end
        end
        if not (#itemData == #GT.sender) then
            local diff = #GT.sender - #itemData
            if diff > 0 then
                for iterator = 1, diff do
                    table.insert(itemData, 0)
                end
            end
        end
    end

    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Prepare Data for Display", 1, itemID)
        if itemID <= #GT.ItemData.Other.Other then
            --[[local index = 0
            for i, otherData in ipairs(GT.ItemData.Other.Other) do
                if otherData.id == itemID then
                    index = i
                end
            end]]
            GT:InitiateFrameProcess(
                itemID,
                GT.ItemData.Other.Other[itemID].icon,
                nil,
                nil,
                itemData
            )
        else
            GT:InitiateFrameProcess(
                tonumber(itemID),
                GetItemIcon(tonumber(itemID)),
                C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID),
                C_Item.GetItemQualityByID(itemID),
                itemData,
                itemTotals.countTotal[itemID],
                (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000,
                itemTotals.valueTotal[itemID]
            )
        end
    end

    GT:InitiateFrameProcess(
        9999999998,
        133647,
        nil,
        nil,
        playerTotals.countTotal,
        totalItems,
        "",
        totalPrice
    )

    if GT.db.profile.General.characterValue and GT:GroupDisplayCheck() then
        for index, value in ipairs(playerTotals.valueTotal) do
            playerTotals.valueTotal[index] = tostring(math.ceil(value - 0.5)) .. "g"
        end
        GT:InitiateFrameProcess(
            9999999999,
            133784,
            nil,
            nil,
            playerTotals.valueTotal
        )
    end

    if GT.db.profile.General.displayAlias and GT:GroupDisplayCheck() then
        GT:InitiateFrameProcess(
            0,
            413577,
            nil,
            nil,
            aliases
        )
    end

    GT:AllignRows()
    GT:AllignColumns()
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

local function FramePool_Resetter(framePool, frame)
    --[[
        Still need to remove the frame from the GT.Display.Frames and GT.Display.Order Arrays
        Will need to do those outside of the resetter function, as we dont have the information
            to do it in this function.
    ]]
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
    string:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
    if id < 999999999 then
        string:SetVertexColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2], GT.db.profile.General.textColor[3])
    else
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

local function CheckColumnSize(index, frame)
    GT.Debug("Check Column Size", 3, index, frame:GetText())
    local width = frame:GetUnboundedStringWidth()
    if GT.Display.ColumnSize[index] == nil or GT.Display.ColumnSize[index] < width then
        GT.Display.ColumnSize[index] = nil
        GT.Display.ColumnSize[index] = width
        return
    end
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

function GT:UpdateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("UpdateDisplayFrame", 4, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

    if displayText == nil then
        return
    end

    local frame = GT.Display.Frames[id]
    local frameHeight = frame:GetHeight()

    for textIndex, text in ipairs(displayText) do
        if type(text) == "number" then
            text = math.ceil(text - 0.5)
        else
            text = text
        end
        if textIndex <= frame.displayedCharacters then
            frame.text[textIndex]:SetText(text)
            CheckColumnSize(textIndex, frame.text[textIndex])
        else
            local anchor = frame.icon
            if textIndex > 1 then
                anchor = frame.text[textIndex - 1]
            end
            local textString = CreateTextDisplay(frame, id, text, "count", frameHeight, anchor)
            GT:AddRemoveDisplayCell("add", frame, textIndex, textString)
            CheckColumnSize(textIndex, frame.text[textIndex])
        end
    end
    frame.displayedCharacters = #displayText

    if totalItemCount and GT:GroupDisplayCheck() then
        if frame.totalItemCount then
            frame.text[frame.totalItemCount]:SetText("[" .. math.ceil(totalItemCount - 0.5) .. "]")
            CheckColumnSize(frame.totalItemCount, frame.text[frame.totalItemCount])
        else
            local index = #displayText + 1
            local textString = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frameHeight, frame.text[#displayText])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            CheckColumnSize(index, frame.text[index])
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
            CheckColumnSize(frame.pricePerItem, frame.text[frame.pricePerItem])
        else
            local index = 0
            if frame.priceTotalItem then
                index = #frame.text
            else
                index = #frame.text + 1
            end
            local textString = CreateTextDisplay(frame, id, text, "pricePerItem", frameHeight, frame.text[index - 1])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            CheckColumnSize(index, frame.text[index])
        end
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        if frame.priceTotalItem then
            frame.text[frame.priceTotalItem]:SetText("(" .. math.ceil(priceTotalItem - 0.5) .. "g)")
            CheckColumnSize(frame.priceTotalItem, frame.text[frame.priceTotalItem])
        else
            local index = #frame.text + 1
            local textString = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frameHeight, frame.text[index - 1])
            GT:AddRemoveDisplayCell("add", frame, index, textString)
            CheckColumnSize(index, frame.text[index])
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
    frame:SetHeight(GT.db.profile.General.iconHeight + 3)
    frame:Show()

    frame.displayedCharacters = #displayText

    GT.Display.Frames[id] = frame

    frame.icon = GT.Pools.texturePool:Acquire()
    frame.icon:SetDrawLayer("BACKGROUND", 0)
    frame.icon:SetTexture(iconId)
    frame.icon:SetPoint("LEFT", frame, "LEFT")
    frame.icon:SetWidth(GT.db.profile.General.iconWidth)
    frame.icon:SetHeight(GT.db.profile.General.iconHeight)
    frame.icon:Show()

    if iconQuality then
        frame.iconQuality = GT.Pools.texturePool:Acquire()
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

    if GT.db.profile.General.rarityBorder and iconRarity then
        frame.iconRarity = GT.Pools.texturePool:Acquire()
        frame.iconRarity:SetDrawLayer("BACKGROUND", 1)
        local rarity = iconRarity or 1
        if rarity <= 1 then
            frame.iconRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
        else
            frame.iconRarity:SetAtlas("bags-glow-white")
        end
        local R, G, B = GetItemQualityColor(rarity)
        frame.iconRarity:SetVertexColor(R, G, B, 0.8)
        frame.iconRarity:SetAllPoints(frame.icon)
        frame.iconRarity:Show()
    end

    local frameHeight = frame:GetHeight()
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
        CheckColumnSize(i, frame.text[i])
    end

    if totalItemCount and GT:GroupDisplayCheck() then --Should I be running group checks here or before calling the function (such as when creating the data that is passed to this function)?
        frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frameHeight, frame.text[#frame.text])
        CheckColumnSize(#frame.text, frame.text[#frame.text])
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
        CheckColumnSize(#frame.text, frame.text[#frame.text])
        frame.pricePerItem = #frame.text
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frameHeight, frame.text[#frame.text])
        CheckColumnSize(#frame.text, frame.text[#frame.text])
        frame.priceTotalItem = #frame.text
    end

    GT.Display.Order = GT.Display.Order or {}
    table.insert(GT.Display.Order, id)
    table.sort(GT.Display.Order)
end

function GT:AllignRows()
    for i, id in ipairs(GT.Display.Order) do
        if i == 1 then
            GT.Display.Frames[id]:SetPoint("TOPLEFT", GT.baseFrame.backdrop, "TOPLEFT")
        else
            GT.Display.Frames[id]:SetPoint("TOPLEFT", GT.Display.Frames[GT.Display.Order[i - 1]], "BOTTOMLEFT")
        end
    end
end

function GT:AllignColumns()
    for i, id in ipairs(GT.Display.Order) do
        for index, string in ipairs(GT.Display.Frames[id].text) do
            string:SetWidth(GT.Display.ColumnSize[index])
        end
    end
end

function GT:RebuildIDTables()
    GT.Debug("Rebuild ID Table", 1)
    GT.IDs = {}
    for key, value in pairs(GT.db.profile.Filters) do
        table.insert(GT.IDs, key)
    end
    if GT.db.profile.CustomFiltersTable then
        for itemID, value in pairs(GT.db.profile.CustomFiltersTable) do
            if value then
                itemID = tonumber(itemID)
                if not GT.db.profile.Filters[itemID] then
                    table.insert(GT.IDs, itemID)
                end
            end
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
    if GT:CheckModeStatus() == false then
        GT.Debug("InventoryUpdate: CheckModeStatus", 2, GT:CheckModeStatus())
        return
    end
    if GT.PlayerEnteringWorld == true then
        GT.PlayerEnteringWorld = false
    end

    local totalUpdates = 0 --do we still need total?  Was used for reset message before but I think I can do that better on its own.
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
            totalUpdates = totalUpdates + 1
            updateMessage = updateMessage .. id .. "=" .. itemCount .. " "
        end
    end
    GT.Debug("Inventory Update Data", 2, totalUpdates, updateMessage)

    GT:SetChatType()

    if GT.groupMode == "WHISPER" then
        GT.Debug("Sent Solo Message", 2, updateMessage, GT.groupMode, UnitName("player"))
        GT:SendCommMessage("GT_Data", updateMessage, GT.groupMode, UnitName("player"), "NORMAL", GT.Debug, "AceComm Sent Solo Message")
    else
        GT.Debug("Sent Group Message", 2, updateMessage, GT.groupMode)
        GT:SendCommMessage("GT_Data", updateMessage, GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Group Message")
    end
end

function GT:DataMessageReceived(prefix, message, distribution, sender)
    GT.Debug("Data Message Received", 3, prefix, message, distribution, sender)

    if GT:CheckModeStatus() == false then
        GT.Debug("DataMessageReceived: CheckModeStatus", 2, GT:CheckModeStatus())
        return
    end
    if GT.db.profile.General.hideOthers and sender ~= GT.Player then
        GT.Debug("DataMessageReceived: hideOthers", 2, GT.db.profile.General.hideOthers, GT.Player)
        return
    end

    GT.Debug("Data Message Starting Processing", 1)

    local senderIndex = ""
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
            totalValue = 0, --can be removed once mvoed to new data display function
            inventoryData = {},
        }
        table.insert(GT.sender, senderTable)
        senderIndex = #GT.sender
    end

    --create messageText table
    local str = " " .. message .. "\n"
    str = str:gsub("%s(%S-)=", "\n%1=")
    local messageText = {}

    for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
        local itemID = tonumber(itemID)
        if GT:TableFind(GT.IDs, itemID) then
            messageText[itemID] = value
            GT.InventoryData[itemID] = GT.InventoryData[itemID] or {}
            GT.InventoryData[itemID][senderIndex] = tonumber(value)
            GT.sender[senderIndex].inventoryData[itemID] = tonumber(value)
        end
    end

    --loop existing counts to update, set to 0 if not in message
    for itemID, data in pairs(GT.InventoryData) do
        if not messageText[itemID] then
            GT.InventoryData[itemID][senderIndex] = 0
            GT.sender[senderIndex].inventoryData[itemID] = 0
        end
    end

    GT:wait(0.4, "PrepareDataForDisplay", "Data Message Received", true)
end
