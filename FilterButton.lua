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

    local function FiltersMenu(filterButton, rootDescription)
        for expansionIndex, expansion in ipairs(GT.expansionsOrder) do
            local function IsSelected_Expansion()
                local checked = true
                for category, categoryData in pairs(GT.ItemData[expansion]) do
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
            end

            local function SetSelected_Expansion()
                GT.Debug("Expansion Button Clicked", 2, expansion)
                local key = not IsSelected_Expansion()
                for category, categoryData in pairs(GT.ItemData[expansion]) do
                    for _, itemData in ipairs(categoryData) do
                        if not (itemData.id == -1) then
                            GT.db.profile.Filters[itemData.id] = key or nil
                            GT:RemoveDisabledItemData(key, itemData.id)
                        end
                    end
                end

                GT:RebuildIDTables()
                GT:InventoryUpdate(expansion .. " clicked", false)
            end

            GT.baseFrame.button[expansion] = rootDescription:CreateCheckbox(expansion, IsSelected_Expansion, SetSelected_Expansion)
            for categoryIndex, category in ipairs(GT.categoriesOrder) do
                if GT.ItemData[expansion][category] then
                    local function IsSelected_Category()
                        local checked = true
                        for _, itemData in ipairs(GT.ItemData[expansion][category]) do
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
                    end
                    local function SetSelected_Category()
                        GT.Debug("Category Button Clicked", 2, expansion, category)
                        local key = not IsSelected_Category()
                        for _, itemData in ipairs(GT.ItemData[expansion][category]) do
                            if not (itemData.id == -1) then
                                GT.db.profile.Filters[itemData.id] = key or nil
                                GT:RemoveDisabledItemData(key, itemData.id)
                            end
                        end

                        GT:RebuildIDTables()
                        GT:InventoryUpdate(expansion .. " " .. category .. " clicked", false)
                    end

                    GT.baseFrame.button[expansion][category] = GT.baseFrame.button[expansion]:CreateCheckbox(category, IsSelected_Category, SetSelected_Category)
                    for _, itemData in ipairs(GT.ItemData[expansion][category]) do
                        local function IsSelected_Item()
                            if GT.db.profile.Filters[itemData.id] == true then
                                return true
                            else
                                return false
                            end
                        end
                        local function SetSelected_Item()
                            GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name)
                            if GT.db.profile.Filters[itemData.id] == true then
                                GT.db.profile.Filters[itemData.id] = nil
                            else
                                GT.db.profile.Filters[itemData.id] = true
                            end

                            GT:RebuildIDTables()
                            GT:RemoveDisabledItemData(IsSelected_Item(), itemData.id)
                            GT:InventoryUpdate(expansion .. " " .. category .. " " .. itemData.name .. " menu clicked", false)
                        end

                        if itemData.id == -1 then
                            local divider = GT.baseFrame.button[expansion][category]:CreateDivider()
                        else
                            local name = itemData.name

                            if itemData.quality then
                                if itemData.quality == 1 then
                                    name = "|cff784335" .. name .. "*"
                                elseif itemData.quality == 2 then
                                    name = "|cff96979E" .. name .. "**"
                                elseif itemData.quality == 3 then
                                    name = "|cffDCC15F" .. name .. "***"
                                end
                            end

                            GT.baseFrame.button[expansion][category][itemData.name] = GT.baseFrame.button[expansion][category]:CreateCheckbox(name, IsSelected_Item, SetSelected_Item)
                            GT.baseFrame.button[expansion][category][itemData.name]:AddInitializer(function(text, description, menu)
                                local leftTexture = text:AttachTexture()
                                leftTexture:SetSize(18, 18)
                                leftTexture:SetPoint("LEFT", text.leftTexture1, "RIGHT", 7, 1);

                                if itemData.icon then
                                    leftTexture:SetTexture(itemData.icon)
                                else
                                    leftTexture:SetTexture(GetItemIcon(tonumber(itemData.id)))
                                end

                                text.fontString:SetPoint("LEFT", leftTexture, "RIGHT", 7, 1);
                            end)
                        end
                    end
                end
            end
        end

        --add Custom Filters to filterMenu
        GT:CreateCustomFiltersList(rootDescription)

        --add Profiles to filterMenu
        GT:CreateProfilesList(rootDescription)
    end

    filterButton:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" then
            --EasyMenu(GT.baseFrame.filterMenu, GT.baseFrame.menu, "cursor", 0, 0, "MENU")
            MenuUtil.CreateContextMenu(filterButton, FiltersMenu)
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

function GT:CreateCustomFiltersList(rootDescription)
    local customFiltersList = {}
    for id, data in pairs(GT.db.profile.CustomFiltersTable) do
        local itemID = tonumber(id)
        local item = Item:CreateFromItemID(itemID)
        --Waits for the data to be returned from the server
        if not item:IsItemEmpty() then
            item:ContinueOnItemLoad(function()
                local itemDetails = {
                    id = tonumber(id),
                    text = item:GetItemName(),
                    icon = tostring(GetItemIcon(itemID) or "")
                }
                table.insert(customFiltersList, itemDetails)
            end)
        end
    end

    table.sort(customFiltersList, function(a, b)
        return a.text < b.text
    end)

    local function IsSelected_CustomFilter()
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
    end
    local function SetSelected_CustomFilter()
        GT.Debug("Custom Filters Button Clicked", 2)
        local key = not IsSelected_CustomFilter()
        for id, data in pairs(GT.db.profile.CustomFiltersTable) do
            GT.db.profile.CustomFiltersTable[tostring(id)] = key
            GT:RemoveDisabledItemData(key, id)
        end

        GT:RebuildIDTables()
        GT:InventoryUpdate("Custom Filters clicked", false)
    end

    GT.baseFrame.button["Custom Filters"] = rootDescription:CreateCheckbox("Custom Filters", IsSelected_CustomFilter, SetSelected_CustomFilter)

    for itemIndex, itemData in ipairs(customFiltersList) do
        local function IsSelected_CustomFilterItem()
            return GT.db.profile.CustomFiltersTable[tostring(itemData.id)]
        end
        local function SetSelected_CustomFilterItem()
            GT.Debug("Custom Filter Item Button Clicked", 2, itemData.text)
            if GT.db.profile.CustomFiltersTable[tostring(itemData.id)] == true then
                GT.db.profile.CustomFiltersTable[tostring(itemData.id)] = false
            else
                GT.db.profile.CustomFiltersTable[tostring(itemData.id)] = true
            end

            GT:RebuildIDTables()
            GT:RemoveDisabledItemData(IsSelected_CustomFilterItem(), itemData.id)
            GT:InventoryUpdate("Custom Filter " .. itemData.text .. " menu clicked", false)
        end

        GT.baseFrame.button["Custom Filters"][itemData.text] = GT.baseFrame.button["Custom Filters"]:CreateCheckbox(itemData.text, IsSelected_CustomFilterItem, SetSelected_CustomFilterItem)
        GT.baseFrame.button["Custom Filters"][itemData.text]:AddInitializer(function(text, description, menu)
            local leftTexture = text:AttachTexture()
            leftTexture:SetSize(18, 18)
            leftTexture:SetPoint("LEFT", text.leftTexture1, "RIGHT", 7, 1)
            leftTexture:SetTexture(tonumber(itemData.icon))

            text.fontString:SetPoint("LEFT", leftTexture, "RIGHT", 7, 1)
        end)
    end
end

function GT:CreateProfilesList(rootDescription)
    local function IsSelected_ProfilesCategory()
        return false
    end

    local function SetSelected_ProfilesCategory()
    end

    GT.baseFrame.button["Profiles"] = rootDescription:CreateCheckbox("Profiles", IsSelected_ProfilesCategory, SetSelected_ProfilesCategory)
    GT.baseFrame.button["Profiles"]:SetSelectionIgnored()

    for _, name in ipairs(GT.db:GetProfiles()) do
        local function IsSelected_Profile()
            local current = GT.db:GetCurrentProfile()
            if current == name then
                return true
            else
                return false
            end
        end

        local function SetSelected_Profile()
            GT.Debug("Profile Button Clicked", 2, name, key)
            --this closes the menu when the profile is changed
            --ToggleDropDownMenu(1, nil, GT.baseFrame.menu, "cursor", 0, 0, GT.baseFrame.filterMenu, nil)
            GT.db:SetProfile(name)
        end

        GT.baseFrame.button["Profiles"][name] = GT.baseFrame.button["Profiles"]:CreateCheckbox(name, IsSelected_Profile, SetSelected_Profile)
    end
end
