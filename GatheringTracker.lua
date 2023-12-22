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

function GT:GROUP_ROSTER_UPDATE(event, dontWait)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, dontWait)

    --Check if we need to wait on doing the update.
    --If we do need to wait, determine if an existing wait table has already been created
    --If we dont need to wait, do the update.
    if dontWait then
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

        GT.sender = {}
        GT.InventoryData = {}

        GT:ResetDisplay()
        GT:InventoryUpdate("GROUP_ROSTER_UPDATE", false)
    else
        GT:wait(2, "GROUP_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", true)
    end
end

function GT:BAG_UPDATE()
    if GT.PlayerEnteringWorld == false then
        GT:InventoryUpdate("BAG_UPDATE")
    end
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

    local container = AceGUI:Create("SimpleGroup")
    container:SetLayout("Flow")
    container:SetPoint("TOPLEFT", backdrop, "TOPLEFT")
    container:SetWidth(math.floor(GetScreenWidth()))
    container.frame:SetFrameStrata("BACKGROUND")
    if GT.ElvUI then
        if container.frame.backdrop and container.frame.backdrop.SetBackdropBorderColor then
            container.frame.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
            container.frame.backdrop:SetBackdropColor(0, 0, 0, 0)
        elseif container.frame.SetBackdropBorderColor then
            container.frame:SetBackdropBorderColor(0, 0, 0, 0)
            container.frame:SetBackdropColor(0, 0, 0, 0)
        end
    end

    local baseFrame = {
        frame = frame,
        backdrop = backdrop,
        container = container,
    }
    GT.baseFrame = baseFrame

    GT:FiltersButton()
end

function GT:FiltersButton()
    if GT.db.profile.General.filtersButton and GT:GroupCheck() and GT.Enabled then --show setting button or create it if needed
        if GT.baseFrame.button then
            GT.Debug("Show Filters Button", 1)
            GT.baseFrame.button:Show()
            if GT.baseFrame.button.mouseOver then
                GT.baseFrame.button.mouseOver:Show()
            end
            GT:FiltersButtonFade()
        else
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
                                icon = tostring(GetItemIcon(tonumber(itemData.id)) or ""),
                                checked = function()
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        return true
                                    else
                                        return false
                                    end
                                end,
                                func = function()
                                    GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name)
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        GT.db.profile.Filters[itemData.id] = nil
                                    else
                                        GT.db.profile.Filters[itemData.id] = true
                                    end

                                    GT:ResetDisplay(false)
                                    GT:RebuildIDTables()
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
                        func = function()
                            GT.Debug("Category Button Clicked", 2, expansion, category)
                            local checked = 0
                            local count = 0
                            for _, itemData in ipairs(categoryData) do
                                if itemData.id ~= -1 then
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        checked = checked + 1
                                    end
                                    GT.db.profile.Filters[itemData.id] = nil
                                    count = count + 1
                                end
                            end
                            if checked == 0 or checked < count then
                                for _, itemData in ipairs(categoryData) do
                                    if itemData.id ~= -1 then
                                        GT.db.profile.Filters[itemData.id] = true
                                    end
                                end
                            end
                            GT.Debug("Category Button Clicked", 2, expansion, category, checked, count)

                            GT:ResetDisplay(false)
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
                    func = function()
                        GT.Debug("Expansion Button Clicked", 2, expansion)
                        local checked = 0
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
                        GT.Debug("Expansion Button Clicked", 2, expansion, checked, count)

                        GT:ResetDisplay(false)
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
    else --disable setting button
        GT.Debug("Hide Filters Button", 1)
        if GT.baseFrame.button then
            GT.baseFrame.button:Hide()
            if GT.baseFrame.button.mouseOver then
                GT.baseFrame.button.mouseOver:Hide()
            end
        end
    end
end

function GT:FiltersButtonFade(setAlpha)
    if GT.db.profile.General.filtersButton and GT.Enabled then
        if GT.baseFrame.button then
            if setAlpha then
                local alpha = GT.db.profile.General.buttonAlpha / 100
                GT.baseFrame.button:SetAlpha(alpha)
            else
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
        end
    end
end

function GT:CreateCustomFiltersList()
    if GT.baseFrame.filterMenu then
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
                        func = function()
                            GT.Debug("Custom Filter Item Button Clicked", 2, itemName)
                            if GT.db.profile.CustomFiltersTable[id] == true then
                                GT.db.profile.CustomFiltersTable[id] = false
                            else
                                GT.db.profile.CustomFiltersTable[id] = true
                            end

                            GT:ResetDisplay(false)
                            GT:RebuildIDTables()
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
            func = function()
                GT.Debug("Custom Filters Button Clicked", 2)
                local checked = 0
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
                GT.Debug("Custom Filters Button Clicked", 2, checked, count)

                GT:ResetDisplay(false)
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
end

function GT:CreateProfilesList()
    if GT.baseFrame.filterMenu then
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
                func = function(self, checked)
                    GT.Debug("Profile Button Clicked", 2, name, checked)
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

        --determine if a full or partial reset is needed after closing the Interface Options
        --false will clear everything and wipe the display
        --true will reset the data and recreate the GUI
        GT:ResetDisplay(GT:GroupCheck())
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

function GT:ResetDisplay(display)
    GT.Debug("Reset Display", 1, display)
    if display == nil then
        display = true
    end
    if GT.Display.overlayPool then --Release pool textures so that they dont show up on the wrong items
        GT.Display.overlayPool:ReleaseAll()
    end
    if GT.Display.rarityPool then
        GT.Display.rarityPool:ReleaseAll()
    end
    GT.baseFrame.container:ReleaseChildren()
    GT.Display.list = {}
    GT.Display.frames = {}
    GT:FiltersButton()

    if GT.db.profile.General.enable and display and GT:GroupCheck() then
        GT:PrepareForDisplayUpdate("Reset Display")
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
            if string.match(itemID, "(%d)") then --checks if itemID is numeric
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

    GT.testPlayerTotals = playerTotals
    GT.testItemTotals = itemTotals
    GT.testAliases = aliases

    for itemID, itemData in pairs(GT.InventoryData) do
        GT.Debug("Prepare Data for Display", 1, itemID)
        if string.match(itemID, "(%a)") then
            local index = 0
            for i, otherData in ipairs(GT.ItemData.Other.Other) do
                if otherData.id == itemID then
                    index = i
                end
            end
            GT:InitiateFrameProcess(
                GT.ItemData.Other.Other[index].order,
                GT.ItemData.Other.Other[index].icon,
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
end

function GT:InitiateFrameProcess(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("InitiateFrameProcess", 3, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

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

function GT:PrepareForDisplayUpdate(event)
    GT.Debug("Prepare for Display Update", 1, event)
    local globalPrice = 0
    local globalCounts = ""
    local globalTotal = 0
    GT.Display.length.perItemPrice = 0
    GT.Display.length.totalsLength = 0

    GT.baseFrame.backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
    --Why am I doing this set point?

    GT:SetTSMPriceSource()

    --create player total that is displayed at the end of each item label
    --any new itemIDs that were added will be set to 0 for all other characters.
    local playerTotals = {}
    for i = 1, table.getn(GT.sender) do
        local playerTotal = 0
        GT.sender[i].totalValue = 0
        GT.sender[i].playerLength = 0
        for itemID, data in pairs(GT.InventoryData) do
            if GT:TableFind(GT.IDs, tonumber(itemID)) then
                if not data[i] then
                    data[i] = 0
                end
                local value = 0
                if (data[i] - GT.db.profile.General.ignoreAmount) > 0 then
                    value = data[i] - GT.db.profile.General.ignoreAmount
                else
                    value = 0
                end
                playerTotal = playerTotal + value
                if GT.db.profile.General.tsmPrice > 0 then
                    local price = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(itemID)) or 0) / 10000
                    local totalPrice = value * price
                    GT.sender[i].totalValue = GT.sender[i].totalValue + totalPrice
                    --Calculate length for Per Item Price column
                    if string.len(tostring(math.ceil(price))) > GT.Display.length.perItemPrice then
                        GT.Display.length.perItemPrice = string.len(tostring(math.ceil(price)))
                    end
                end
            end
        end

        --if sender is player, call NotificationHandler
        if GT.sender[i].name == GT.Player and not GT.NotificationPause then
            GT.Debug("Trigger Notification Handler for all", 2)
            GT:NotificationHandler("all", "all", playerTotal, GT.sender[i].totalValue)
        end

        --[[Determines the length of the player column.
            If we are in a group and Per Character Value is enabled we use the length of the players total value
            Otherwise we use the length of the players total item count.]]
        GT.sender[i].totalValue = tonumber(string.format("%.0f", GT.sender[i].totalValue))
        if GT.db.profile.General.characterValue and GT:GroupCheck("Group") then
            if string.len(tostring(GT.sender[i].totalValue)) + math.ceil(string.len(tostring(GT.sender[i].totalValue)) / 3) >= GT.sender[i].playerLength then
                GT.sender[i].playerLength = string.len(tostring(GT.sender[i].totalValue)) + math.ceil(string.len(tostring(GT.sender[i].totalValue)) / 3) + 1
            end
        else
            if string.len(tostring(playerTotal)) + math.ceil(string.len(tostring(playerTotal)) / 3) > GT.sender[i].playerLength then
                GT.sender[i].playerLength = string.len(tostring(playerTotal)) + math.ceil(string.len(tostring(playerTotal)) / 3)
            end
        end
        --if gold filter is enabled check if it will be longer than the current length when we include the "g"
        if GT.InventoryData["gold"] and GT.InventoryData["gold"][i] then
            local gold = GT.InventoryData["gold"][i] .. "g"
            if string.len(tostring(gold)) + math.ceil(string.len(tostring(gold)) / 3) > GT.sender[i].playerLength then
                GT.sender[i].playerLength = string.len(tostring(gold)) + math.ceil(string.len(tostring(gold)) / 3)
            end
        end
        playerTotals[i] = playerTotal
        globalTotal = globalTotal + playerTotal
        GT.Debug("Display Length for " .. GT.sender[i].name .. ":", 2, GT.sender[i].playerLength)
    end
    --set the length for the totals items column
    GT.Display.length.totalsLength = string.len(tostring(globalTotal))
    --determines text for totals row for the player columns
    for i, t in ipairs(playerTotals) do
        globalCounts = globalCounts .. string.format("%-" .. GT.sender[i].playerLength .. "s", GT:AddComas(string.format("%.0f", t)))
    end
    GT.Debug("GT.Display.length.totalsLength", 2, GT.Display.length.totalsLength)
    GT.Debug("GT.Display.length.perItemPrice", 2, GT.Display.length.perItemPrice)

    --call method to determine if we need to reset or can update
    local update = GT:CheckIfDisplayResetNeeded(GT.InventoryData) --probably dont need with new methods, but need way to remove items that should be displayed.
    --release all of the container children so we can rebuild
    if not update then
        if GT.Display.overlayPool then --Release pool textures so that they dont show up on the wrong items
            GT.Display.overlayPool:ReleaseAll()
        end
        if GT.Display.rarityPool then
            GT.Display.rarityPool:ReleaseAll()
        end
        GT.baseFrame.container:ReleaseChildren()
        GT.Display.list = {}
        GT.Display.frames = {}
    end

    for _, id in ipairs(GT.IDs) do --create the data needed to create the item labels.  We loop the ID's table to prevent displaying items that are disabled, but that we have count data for.
        GT.Debug("Prepare for Display Update: Loop ID's", 3, id)
        if GT.InventoryData[tostring(id)] then
            if string.match(tostring(id), "(%a)") then
                GT.Debug("Prepare for Display Update: Process Gold and Bags", 3, id)
                --If the ID includes any letters, we need to handle it differently
                local data = GT.InventoryData[tostring(id)]
                local counts = ""
                for i, v in ipairs(data) do
                    counts = counts .. string.format("%-" .. GT.sender[i].playerLength .. "s", GT:AddComas(string.format("%.0f", v)) .. ((id == "gold" and "g") or ""))
                end
                local iconID, order
                for _, otherData in ipairs(GT.ItemData.Other.Other) do
                    if otherData.id == id then
                        iconID = otherData.icon
                        order = otherData.order * -1
                    end
                end
                GT:UpdateDisplay(order, counts, iconID)
            else
                GT.Debug("Prepare for Display Update: Process Normal Items", 3, id)
                local data = GT.InventoryData[tostring(id)]
                local counts = ""
                local total = 0
                for i, v in ipairs(data) do
                    local value = 0
                    if (v - GT.db.profile.General.ignoreAmount) > 0 then
                        value = v - GT.db.profile.General.ignoreAmount
                    else
                        value = 0
                    end
                    counts = counts .. string.format("%-" .. GT.sender[i].playerLength .. "s", GT:AddComas(string.format("%.0f", value)))
                    total = total + value
                end

                if total > 0 then
                    local text = counts
                    if GT:GroupCheck("Group") then
                        text = text .. "[" .. string.format("%-" .. (GT.Display.length.totalsLength + 2) .. "s", GT:AddComas(string.format("%.0f", total)) .. "]")
                    end
                    if GT.db.profile.General.tsmPrice > 0 then
                        local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(id)) or 0) / 10000
                        local tprice = total * eprice
                        globalPrice = globalPrice + tprice

                        if GT.db.profile.General.perItemPrice then
                            text = text .. "{" .. string.format("%-" .. (GT.Display.length.perItemPrice + 3) .. "s", GT:AddComas(string.format("%.0f", eprice)) .. "g}")
                        end

                        text = text .. "(" .. GT:AddComas(string.format("%.0f", tprice)) .. "g)"
                    end

                    local iconID = GetItemIcon(id)

                    local rarity = C_Item.GetItemQualityByID(id)

                    local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(tostring(id)) --Get the quality, returns nil if no quality

                    --call method to create frame
                    GT:UpdateDisplay(id, text, iconID, rarity, quality)
                end
            end
        end
    end

    if globalTotal > 0 then
        --create the text string for the totals row and create the widget
        local totalText = globalCounts
        local totalStack
        if GT:GroupCheck("Group") then
            totalText = totalText .. "[" .. string.format("%-" .. (GT.Display.length.totalsLength + 2) .. "s", GT:AddComas(string.format("%.0f", globalTotal)) .. "]")
        end
        if GT.db.profile.General.tsmPrice > 0 then
            if GT.db.profile.General.perItemPrice then
                totalText = totalText .. string.format("%-" .. (GT.Display.length.perItemPrice + 4) .. "s", "")
            end
            totalText = totalText .. "(" .. GT:AddComas(string.format("%.0f", globalPrice)) .. "g)"
        end
        if totalText == "" then
            totalText = "Setup"
        end
        GT:UpdateDisplay(9999999998, totalText, 133647)
    end

    --This is for the character gathered value row
    if GT.db.profile.General.characterValue and GT:GroupCheck("Group") then
        --create the text string for the per character value row and create widget
        local valueText = ""
        for i, senderData in ipairs(GT.sender) do
            valueText = valueText .. string.format("%-" .. senderData.playerLength .. "s", GT:AddComas(string.format("%.0f", senderData.totalValue)) .. "g")
        end
        if valueText == "" then
            valueText = "Setup"
        end
        GT:UpdateDisplay(9999999999, valueText, 133784) --old icon 133785
    end

    if GT.db.profile.General.displayAlias and GT:GroupCheck("Group") then
        --create the text string for the alias row and create the widget
        local nameText = ""
        for i, senderData in ipairs(GT.sender) do
            local exists = 0
            for index, aliases in pairs(GT.db.profile.Aliases) do
                if aliases.name == senderData.name then
                    exists = index
                end
            end
            if exists > 0 then
                local newText = string.sub(GT.db.profile.Aliases[exists].alias, 0, (senderData.playerLength - 1)) --should the -1 be removed?  This needs more testing.
                local extrsSpace = string.len(newText)
                nameText = nameText .. newText .. string.format("%-" .. (senderData.playerLength - extrsSpace) .. "s", "")
            else
                local newText = string.sub(senderData.name, 0, (senderData.playerLength - 1))
                local extrsSpace = string.len(newText)
                nameText = nameText .. newText .. string.format("%-" .. (senderData.playerLength - extrsSpace) .. "s", "")
            end
        end
        if nameText == "" then
            nameText = "Setup"
        end
        GT:UpdateDisplay(-9999999999, nameText, 413577) --change to id 0 or maybe 1 if zero causes issues
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
    GT.Debug("Check Column Size", 2, index, frame:GetText())
    local width = frame:GetUnboundedStringWidth()
    if GT.Display.ColumnSize[index] == nil or GT.Display.ColumnSize[index] < width then
        GT.Display.ColumnSize[index] = nil
        GT.Display.ColumnSize[index] = width
        return
    end
end

local function InsertDisplayColumn(itemFrame, index, columnFrame)
    GT.Debug("Insert Display Column", 2, index)
    table.insert(itemFrame.text, index, columnFrame)
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

local function SetAnchor(frame)
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
    GT.Debug("UpdateDisplayFrame", 3, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

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
            InsertDisplayColumn(frame, textIndex, textString)
            CheckColumnSize(textIndex, frame.text[textIndex])
        end
    end
    frame.displayedCharacters = #displayText

    --need to add options to create frames for the following 3

    if totalItemCount and GT:GroupDisplayCheck() then
        if frame.totalItemCount then
            frame.text[frame.totalItemCount]:SetText("[" .. math.ceil(totalItemCount - 0.5) .. "]")
            CheckColumnSize(frame.totalItemCount, frame.text[frame.totalItemCount])
        else
            local index = #displayText + 1
            local textString = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frameHeight, frame.text[#displayText])
            InsertDisplayColumn(frame, index, textString)
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
            InsertDisplayColumn(frame, index, textString)
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
            InsertDisplayColumn(frame, index, textString)
            CheckColumnSize(index, frame.text[index])
        end
    end

    SetAnchor(frame)
end

function GT:CreateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)
    GT.Debug("CreateDisplayFrame", 3, id, iconId, iconQuality, iconRarity, displayText, totalItemCount, pricePerItem, priceTotalItem)

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
        if i > 1 then
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

function GT:UpdateDisplay(index, name, icon, rarity, quality)
    GT.Debug("Update Display", 3, index, name, icon, rarity, quality)
    if not GT.Display.frames[index] then
        if index < 999999999 then
            --create labels for items
            local label = AceGUI:Create("Label")
            label:SetText(name)
            label:SetColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2], GT.db.profile.General.textColor[3])
            label:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
            label:SetImage(icon)
            label:SetImageSize(GT.db.profile.General.iconWidth, GT.db.profile.General.iconHeight)

            -- if quality exists add a texture to display the quality
            if quality then
                GT.Display.overlayPool = GT.Display.overlayPool or CreateTexturePool(GT.baseFrame.frame, "BACKGROUND", 2, nil)
                label.overlay = GT.Display.overlayPool:Acquire()
                label.overlay:SetParent(label.frame)
                if quality == 1 then
                    label.overlay:SetAtlas("professions-icon-quality-tier1-inv", true)
                elseif quality == 2 then
                    label.overlay:SetAtlas("professions-icon-quality-tier2-inv", true)
                elseif quality == 3 then
                    label.overlay:SetAtlas("professions-icon-quality-tier3-inv", true)
                end
                label.overlay:SetAllPoints(label.image)
                label.overlay:Show()
            end

            if GT.db.profile.General.rarityBorder and rarity then
                GT.Display.rarityPool = GT.Display.rarityPool or CreateTexturePool(GT.baseFrame.frame, "BACKGROUND", 1, nil)
                label.border = GT.Display.rarityPool:Acquire()
                label.border:SetParent(label.frame)
                local rarity = rarity or 1
                if rarity <= 1 then
                    label.border:SetTexture("Interface\\Common\\WhiteIconFrame")
                else
                    label.border:SetAtlas("bags-glow-white")
                end
                local R, G, B = GetItemQualityColor(rarity)
                label.border:SetVertexColor(R, G, B, 0.8)
                label.border:SetAllPoints(label.image)
                label.border:Show()
            end

            table.insert(GT.Display.list, index)
            table.sort(GT.Display.list)
            local position = GT:TableFind(GT.Display.list, index)
            local beforeWidget = nil
            if GT.Display.frames[GT.Display.list[(position + 1)]] then
                beforeWidget = GT.Display.frames[GT.Display.list[(position + 1)]]
            end
            GT.Display.frames[index] = label
            if beforeWidget then
                GT.baseFrame.container:AddChild(GT.Display.frames[index], beforeWidget)
            else
                GT.baseFrame.container:AddChild(GT.Display.frames[index])
            end
            GT.Display.frames[index]:SetFullWidth(true)
            GT.baseFrame.container:DoLayout()
        else
            --create totals label, may also use for additional labels that are not based on items (i.e. player total price)
            local label = AceGUI:Create("Label")
            label:SetText(name)
            label:SetColor(GT.db.profile.General.totalColor[1], GT.db.profile.General.totalColor[2], GT.db.profile.General.totalColor[3])
            label:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
            label:SetImage(icon)
            label:SetImageSize(GT.db.profile.General.iconWidth, GT.db.profile.General.iconHeight)

            table.insert(GT.Display.list, index) --adds our index to the list table.  This table is sorted and used to determine display order
            table.sort(GT.Display.list)
            local position = GT:TableFind(GT.Display.list, index)
            local beforeWidget = nil
            if GT.Display.frames[GT.Display.list[(position + 1)]] then --checks if there is a widget after our position
                beforeWidget = GT.Display.frames[GT.Display.list[(position + 1)]]
            end
            GT.Display.frames[index] = label --adds label to the frames table so we can keep track of it later on
            if beforeWidget then             --adds our widget to the container based on if there is another widget after us
                GT.baseFrame.container:AddChild(GT.Display.frames[index], beforeWidget)
            else
                GT.baseFrame.container:AddChild(GT.Display.frames[index])
            end
            GT.Display.frames[index]:SetFullWidth(true)
            GT.baseFrame.container:DoLayout()
        end
    else
        --update the text of existing labels
        GT.Display.frames[index]:SetText(name)
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
            itemID = tonumber(itemID)
            if not GT.db.profile.Filters[itemID] then
                if value then
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
        if tostring(id) == "gold" then
            count = math.floor((GetMoney() / 10000) + 0.5)
        elseif tostring(id) == "bag" then
            for bagIndex = 0, 4 do
                count = count + C_Container.GetContainerNumFreeSlots(bagIndex)
            end
        else
            count = GetItemCount(id, GT.db.profile.General.includeBank, false)
        end

        if count > 0 then
            totalUpdates = totalUpdates + 1
            updateMessage = updateMessage .. id .. "=" .. count .. " "
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

--[[function GT:InventoryUpdateOld(event, dontWait)
    GT.Debug("InventoryUpdate", 1, event, dontWait)
    if dontWait then
        if event ~= nil then
            if GT:GroupCheck() and GT.Enabled then
                local total = 0
                local messageText = ""

                for i, id in ipairs(GT.IDs) do
                    local count = 0
                    if string.match(tostring(id), "(%a)") then
                        if tostring(id) == "gold" then
                            count = math.floor((GetMoney() / 10000) + 0.5)
                        elseif tostring(id) == "bag" then
                            for i = 0, 4 do
                                count = count + C_Container.GetContainerNumFreeSlots(i)
                            end
                        end
                    else
                        count = (GetItemCount(id, GT.db.profile.General.includeBank, false))
                        if event and event == "InventoryUpdate" then
                            GT.Debug("Trigger Notification Handler for each", 2)
                            GT.NotificationPause = false
                            GT:NotificationHandler("each", id, count)
                        end
                    end

                    if count > 0 then
                        total = total + count
                        messageText = messageText .. id .. "=" .. count

                        local size = #GT.IDs
                        if i < size then
                            messageText = messageText .. " "
                        end
                    end
                end
                GT.Debug("Inventory Update Data", 2, total, messageText)

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

                if total > 0 then
                    if GT.groupMode == "WHISPER" then
                        GT.Debug("Sent Solo Message", 2, messageText, GT.groupMode, UnitName("player"))
                        GT:SendCommMessage("GT_Data", messageText, GT.groupMode, UnitName("player"), "NORMAL", GT.Debug, "AceComm Sent Solo Message")
                    else
                        GT.Debug("Sent Group Message", 2, messageText, GT.groupMode)
                        GT:SendCommMessage("GT_Data", messageText, GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Group Message")
                    end
                elseif total == 0 then
                    if GT.groupMode == "WHISPER" then
                        GT:SendCommMessage("GT_Data", "reset", GT.groupMode, UnitName("player"), "NORMAL", GT.Debug, "AceComm Sent Solo Reset Message")
                    else
                        GT:SendCommMessage("GT_Data", "reset", GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Group Reset Message")
                    end
                end
            else
                GT.Debug("Disabled or Group Check Failed, No Message Sent", 2)
            end
        else
            local traceback = debugstack()
            GT.Debug(traceback, 1, event)
        end
    else
        GT:wait(0.1, "InventoryUpdate", "InventoryUpdate", true)
    end
end]]

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

    GT:wait(0.4, "PrepareForDisplayUpdate", "Data Message Received", true)
end

--[[function GT:DataUpdateReceived(prefix, message, distribution, sender)
    GT.Debug("Data Update Received", 3, prefix, message, sender)
    --only process received messages if we are endabled and are in a group with group mode on or are solo with group mode off
    if GT:GroupCheck() and GT.Enabled then
        if (GT.db.profile.General.hideOthers and sender == GT.Player) or not GT.db.profile.General.hideOthers then
            --if hideOthers is Checked and sender is Player
            --or
            --if hideOthers is NOT checked
            GT.Debug("Data Update Being Processed", 1)
            --determine sender index or add sender if they dont exist
            local SenderExists = false
            local senderIndex
            for index, data in ipairs(GT.sender) do
                if data.name == sender then
                    SenderExists = true
                    senderIndex = index
                end
            end
            if not SenderExists then
                local senderTable = {
                    name = sender,
                    inGroup = false,
                    totalValue = 0,
                }
                if UnitInParty(sender) or UnitInRaid(sender) then
                    senderTable.inGroup = true
                end

                table.insert(GT.sender, senderTable)
                senderIndex = #GT.sender
            end

            if message == "reset" then
                for itemID, data in pairs(GT.count) do
                    if GT.count[itemID][senderIndex] then
                        GT.count[itemID][senderIndex] = 0
                    end
                end
            else
                --create messageText table
                local str = " " .. message .. "\n"
                str = str:gsub("%s(%S-)=", "\n%1=")
                local messageText = {}
                for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
                    messageText[itemID] = value

                    --add message data to counts
                    if GT.count[itemID] then
                        GT.count[itemID][senderIndex] = tonumber(messageText[itemID])
                    else
                        GT.count[itemID] = {}
                        GT.count[itemID][senderIndex] = tonumber(messageText[itemID])
                    end
                end

                --loop existing counts to update, set to 0 if not in message
                for itemID, data in pairs(GT.count) do
                    if not messageText[itemID] then
                        GT.count[itemID][senderIndex] = 0
                    end
                end
            end

            GT:wait(0.4, "PrepareForDisplayUpdate", "Data Update Received", true)
        end
    elseif GT.Enabled then --process reset messages if we are enabled but didn't pass the earlier check to display
        GT.Debug("Group Check Failed but Enabled, Process reset messages only", 1)
        local SenderExists = false
        local senderIndex
        for index, data in ipairs(GT.sender) do
            if data.name == sender then
                SenderExists = true
                senderIndex = index
            end
        end
        if not SenderExists then
            local senderTable = {
                name = sender,
                inGroup = false,
                totalValue = 0,
            }
            if UnitInParty(sender) or UnitInRaid(sender) then
                senderTable.inGroup = true
            end

            table.insert(GT.sender, senderTable)
            senderIndex = #GT.sender
        end
        if message == "reset" then
            for itemID, data in pairs(GT.count) do
                if GT.count[itemID][senderIndex] then
                    GT.count[itemID][senderIndex] = 0
                end
            end
        end
    end
end]]
