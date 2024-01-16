local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

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

function GT:FiltersButton(profileChanged)
    if not GT.db.profile.General.filtersButton then
        GT:ToggleFilterButton(false)
        return
    end
    if not GT.Enabled then
        GT:ToggleFilterButton(false)
        return
    end
    if profileChanged then
        --add Custom Filters to filterMenu
        GT:CreateCustomFiltersList()

        --add Profiles to filterMenu
        GT:CreateProfilesList()
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

function GT:FiltersButtonFade(alpha)
    GT.Debug("Filters Button Fade", 2, alpha)
    if not GT.Enabled then
        return
    end
    if not GT.db.profile.General.filtersButton then
        return
    end
    if not GT.baseFrame.button then
        return
    end
    if alpha then
        local alpha = alpha / 100
        if not GT.db.profile.General.buttonFade then
            alpha = 1
        end
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
                GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", GT.db.profile.General.buttonAlpha)
            end
        end)
        GT.baseFrame.button.mouseOver:SetMouseClickEnabled(false)
        GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", GT.db.profile.General.buttonAlpha)
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
                --this closes the menu when the profile is changed
                ToggleDropDownMenu(1, nil, GT.baseFrame.menu, "cursor", 0, 0, GT.baseFrame.filterMenu, nil)
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
