---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

-- Localize global functions
local ipairs = ipairs
local pairs = pairs
local string = string
local table = table
local tonumber = tonumber
local tostring = tostring

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

local function ButtonOnEnter(self, motion)
    if motion then
        GT.baseFrame.button:SetAlpha(1)
        GT:wait(nil, "FiltersButtonFade")
    end
end

local function ButtonOnLeave(self, motion)
    if motion then
        GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", GT.db.profile.General.buttonAlpha)
    end
end

function GT:FiltersButton(reMakeButton)
    if not GT.db.profile.General.filtersButton then
        GT:ToggleFilterButton(false)
        return
    end
    if not GT.Enabled then
        GT:ToggleFilterButton(false)
        return
    end
    if GT.baseFrame.button and not reMakeButton then
        GT:ToggleFilterButton(true)
        return
    end

    GT.Debug("Create Filters Button", 1)
    local filterButton = GT.Skins:CreateButtonSkinned("GT_baseFrame_filtersButton", GT.baseFrame.frame)
    filterButton:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", -2, 0)
    filterButton:SetWidth(25)
    filterButton:SetHeight(25)
    filterButton:SetText("F")
    filterButton:EnableMouse(true)
    filterButton:RegisterForClicks("AnyDown")
    filterButton:SetFrameStrata("BACKGROUND")
    filterButton:SetFrameLevel(2)
    filterButton:Show()

    filterButton:SetScript("OnClick", function(self, button, down)
        if button == "LeftButton" and IsShiftKeyDown() then
            GT:ResetSession()
        elseif button == "LeftButton" then
            GT:GenerateFiltersMenu(self)
        elseif button == "RightButton" and IsShiftKeyDown() then
            GT.AlertSystem:ResetAlerts()
        elseif button == "RightButton" then
            GT:ClearFilters()
        end
    end)

    GT.baseFrame.button = filterButton
    GT:FiltersButtonFade()
end

function GT:AnchorFilterButton()
    if not GT.baseFrame.button then
        return
    end

    -- 25 is the size of the filter button, so if any part of the button is off screen it will be moved
    local UITop = UIParent:GetTop() - 25
    local UILeft = UIParent:GetLeft() + 25
    local backdropTop = GT.baseFrame.backdrop:GetTop()
    local backdropLeft = GT.baseFrame.backdrop:GetLeft()

    if backdropTop >= UITop and backdropLeft <= UILeft then
        GT.Debug("Display Location", 1, "Top Left", UITop, UILeft, backdropTop, backdropLeft)
        local left, bottom, width, height = GT.baseFrame.frame:GetBoundsRect()
        GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, -1 * (height + 25))
    elseif backdropTop >= UITop then
        GT.Debug("Display Location", 1, "Top", UITop, UILeft, backdropTop, backdropLeft)
        GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 0, -25)
    elseif backdropLeft <= UILeft then
        GT.Debug("Display Location", 1, "Left", UITop, UILeft, backdropTop, backdropLeft)
        GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, 0)
    else
        GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT")
    end
end

---Creates an item in the menu
---Requires the Menu Frame and itemData
local function CreateItemCheckBox(frame, itemData)
    if itemData.id == -1 then
        local divider = frame:CreateTitle(itemData.name)
    elseif itemData.id == -2 then
        local divider = frame:CreateDivider()
        divider:AddInitializer(function(dividerFrame, description, menu)
            dividerFrame.dividerRight = dividerFrame:AttachTexture()

            dividerFrame.text = dividerFrame:AttachFontString()
            dividerFrame.text:SetTextToFit(itemData.name)
            dividerFrame.text:SetHeight(25)
            dividerFrame.text:SetTextScale(1.5)
            dividerFrame.text:SetPoint("CENTER")
            dividerFrame.text:SetTextColor(CreateColor(1, 0.8235, 0):GetRGBA())

            dividerFrame.divider:ClearAllPoints()
            dividerFrame.divider:SetPoint("LEFT")
            dividerFrame.divider:SetPoint("RIGHT", dividerFrame.text, "LEFT", -10, 0)
            dividerFrame.divider:SetHeight(25)

            dividerFrame.dividerRight:SetPoint("RIGHT")
            dividerFrame.dividerRight:SetPoint("LEFT", dividerFrame.text, "RIGHT", 10, 0)
            dividerFrame.dividerRight:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
            dividerFrame.dividerRight:SetHeight(25)
        end)
        divider:AddResetter(function(dividerFrame)
            dividerFrame.text:SetTextScale(1)
        end)
    else
        local expansion = itemData.expansion
        local category = itemData.category
        local function IsSelected_Item()
            if GT.db.profile.Filters[itemData.id] == true then
                return true
            else
                return false
            end
        end
        local function SetSelected_Item()
            GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name)
            local key = not IsSelected_Item()
            GT.db.profile.Filters[itemData.id] = key or nil

            GT:UpdateIDTable(itemData.id, key)
            GT:RemoveItemData(key, itemData.id)
            if itemData.id == 3 then
                GT.Timer:ToggleControls()
            end
            GT:InventoryUpdate(expansion .. " " .. category .. " " .. itemData.name .. " menu clicked", false)
        end

        local rarity = C_Item.GetItemQualityByID(itemData.id) or 1
        local R, G, B = C_Item.GetItemQualityColor(rarity)
        local qualityHex = GT:RGBtoHex(R or 1, G or 1, B or 1, 1)
        local name = "|c" .. qualityHex .. "|Hitem:" .. itemData.id .. "::::::::::::::::::|h" .. itemData.name
        if itemData.id == 242610 then
            GT.test = name
        elseif itemData.id == 242726 then
            GT.test2 = name
        end

        if itemData.quality then
            if itemData.expansion == "Midnight" then
                if itemData.quality == 1 then
                    name = name .. " |A:Professions-ChatIcon-Quality-12-Tier1:17:18::1|a|h|r"
                elseif itemData.quality == 2 then
                    name = name .. " |A:Professions-ChatIcon-Quality-12-Tier2:17:18::1|a|h|r"
                end
            elseif itemData.quality == 1 then
                name = name .. " |A:Professions-ChatIcon-Quality-Tier1:17:15::1|a|h|r"
            elseif itemData.quality == 2 then
                name = name .. " |A:Professions-ChatIcon-Quality-Tier2:17:23::|a|h|r"
            elseif itemData.quality == 3 then
                name = name .. " |A:Professions-ChatIcon-Quality-Tier3:17:18::1|a|h|r"
            end
        else
            name = name .. "|h|r"
        end

        frame[itemData.name] = frame:CreateCheckbox(name, IsSelected_Item, SetSelected_Item)
        frame[itemData.name]:AddInitializer(function(text, description, menu)
            local leftTexture = text:AttachTexture()

            leftTexture:SetDrawLayer("BACKGROUND", 0)
            leftTexture:SetPoint("LEFT", text.leftTexture1, "RIGHT", 7, 1)

            text:SetHeight(26)
            leftTexture:SetSize(24, 24)

            if itemData.icon then
                leftTexture:SetTexture(itemData.icon)
            else
                leftTexture:SetTexture(C_Item.GetItemIconByID(itemData.id))
            end

            text.fontString:SetPoint("LEFT", leftTexture, "RIGHT", 7, 1)

            local leftTextureRarity = text:AttachTexture()
            leftTextureRarity:SetDrawLayer("BACKGROUND", 1)
            if rarity <= 1 then
                leftTextureRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
            else
                leftTextureRarity:SetAtlas("bags-glow-white")
            end
            leftTextureRarity:SetVertexColor(R, G, B, 0.8)
            leftTextureRarity:SetAllPoints(leftTexture)

            if itemData.quality then
                local leftTextureQuality = text:AttachTexture()
                leftTextureQuality:SetDrawLayer("BACKGROUND", 2)
                if itemData.expansion == "Midnight" then
                    if itemData.quality == 1 then
                        leftTextureQuality:SetAtlas("Professions-Icon-Quality-12-Tier1-Inv", true)
                    elseif itemData.quality == 2 then
                        leftTextureQuality:SetAtlas("Professions-Icon-Quality-12-Tier2-Inv", true)
                    end
                elseif itemData.quality == 1 then
                    leftTextureQuality:SetAtlas("professions-icon-quality-tier1-inv", true)
                elseif itemData.quality == 2 then
                    leftTextureQuality:SetAtlas("professions-icon-quality-tier2-inv", true)
                elseif itemData.quality == 3 then
                    leftTextureQuality:SetAtlas("professions-icon-quality-tier3-inv", true)
                end
                leftTextureQuality:SetPoint("TOPLEFT", leftTexture, "TOPLEFT")
                leftTextureQuality:SetPoint("BOTTOMRIGHT", leftTexture, "BOTTOMRIGHT", 4, 0)
            end
        end)
        frame[itemData.name]:SetTooltip(function(tooltip, elementDescription)
            tooltip:SetHyperlink(name)
        end)
    end
end

function GT:GenerateFiltersMenu(frame)
    local function FiltersMenu(frame, rootDescription)
        rootDescription:SetTag("GatheringTracker_Filter_Menu")
        --GT:CreateSearchMenu(frame, rootDescription)
        for expansionIndex, expansion in ipairs(GT.expansionsOrder) do
            if GT.ItemData[expansion] then
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
                                GT:UpdateIDTable(itemData.id, key)
                                GT:RemoveItemData(key, itemData.id)
                            end
                            if itemData.expansion == "Other" then
                                GT.Timer:ToggleControls()
                            end
                        end
                    end

                    GT:InventoryUpdate(expansion .. " clicked", false)
                end

                -- Creates the checkbox for the Expansion using the above local functions
                frame[expansion] = rootDescription:CreateCheckbox(expansion, IsSelected_Expansion, SetSelected_Expansion)
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
                                    GT:UpdateIDTable(itemData.id, key)
                                    GT:RemoveItemData(key, itemData.id)
                                end
                                if itemData.expansion == "Other" then
                                    GT.Timer:ToggleControls()
                                end
                            end

                            GT:InventoryUpdate(expansion .. " " .. category .. " clicked", false)
                        end

                        -- Creates the checkbox for the Category using the above local functions
                        frame[expansion][category] = frame[expansion]:CreateCheckbox(category, IsSelected_Category, SetSelected_Category)
                        frame[expansion][category]:SetScrollMode(GetScreenHeight() * 0.75)

                        -- Creates each item in the Category
                        for _, itemData in ipairs(GT.ItemData[expansion][category]) do
                            CreateItemCheckBox(frame[expansion][category], itemData)
                        end
                    end
                end
            end
        end

        --add All Expansion section to filterMenu
        GT:CreateAllExpansionFiltersList(frame, rootDescription)

        --add Custom Filters to filterMenu
        GT:CreateCustomFiltersList(frame, rootDescription)

        --add Inventory Filters to the filterMenu
        --these will use existing filters or add an item to custom filters is a normal filter doesn't exist
        GT:CreateInventoryFilters(frame, rootDescription)

        --add Profiles to filterMenu
        GT:CreateProfilesList(frame, rootDescription)

        GT.baseFrame.menu.rootDescription = rootDescription
    end

    ---@class GT.baseFrame.menu: MenuProxy
    GT.baseFrame.menu = GT.baseFrame.menu or {}
    GT.baseFrame.menu = MenuUtil.CreateContextMenu(frame, FiltersMenu)
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
            mouseOver:SetFrameStrata("BACKGROUND")
            mouseOver:SetFrameLevel(1)
            GT.baseFrame.button.mouseOver = mouseOver
        end
        GT.baseFrame.button:SetIgnoreParentAlpha(GT.db.profile.General.buttonFade)
        GT.baseFrame.button:HookScript("OnEnter", ButtonOnEnter)
        GT.baseFrame.button:HookScript("OnLeave", ButtonOnLeave)
        GT.baseFrame.button.mouseOver:HookScript("OnEnter", ButtonOnEnter)
        GT.baseFrame.button.mouseOver:HookScript("OnLeave", ButtonOnLeave)
        GT.baseFrame.button.mouseOver:SetMouseClickEnabled(false)
        GT:wait(GT.db.profile.General.buttonDelay, "FiltersButtonFade", GT.db.profile.General.buttonAlpha)
    else
        GT.baseFrame.button:SetIgnoreParentAlpha(GT.db.profile.General.buttonFade)
        GT.baseFrame.button:SetAlpha(1)
        if GT.baseFrame.button.mouseOver then
            GT.baseFrame.button.mouseOver:SetScript("OnEnter", nil)
            GT.baseFrame.button.mouseOver:SetScript("OnLeave", nil)
            GT.baseFrame.button.mouseOver:SetMouseMotionEnabled(false)
        end
    end
end

function GT:CreateAllExpansionFiltersList(frame, rootDescription)
    local allExpansion = {}

    local function IsSelected_AllExp()
        local checked = true
        for category, categoryData in pairs(GT.ItemDataCategory) do
            for _, itemData in ipairs(categoryData) do
                if not (itemData.id == -1 or itemData.expansion == "Other") and checked == true then
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
    local function SetSelected_AllExp()
        GT.Debug("All Expansions Button Clicked", 2)
        local key = not IsSelected_AllExp()
        for category, categoryData in pairs(GT.ItemDataCategory) do
            for _, itemData in ipairs(categoryData) do
                if not (itemData.id == -1 or itemData.expansion == "Other") then
                    GT.db.profile.Filters[itemData.id] = key or nil
                    GT:UpdateIDTable(itemData.id, key)
                    GT:RemoveItemData(key, itemData.id)
                end
            end
        end

        GT:InventoryUpdate("All Expansions clicked", false)
    end

    frame["All Expansions"] = rootDescription:CreateCheckbox("All Expansions", IsSelected_AllExp,
        SetSelected_AllExp)

    for categoryIndex, category in ipairs(GT.categoriesOrder) do
        if GT.ItemDataCategory[category] then
            local function IsSelected_AllExp_Category()
                local checked = true
                for _, itemData in ipairs(GT.ItemDataCategory[category]) do
                    if not (itemData.id == -1 or itemData.expansion == "Other") and checked == true then
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

            local function SetSelected_AllExp_Category()
                GT.Debug("AllExp Category Button Clicked", 2, category)
                local key = not IsSelected_AllExp_Category()
                for _, itemData in ipairs(GT.ItemDataCategory[category]) do
                    if not (itemData.id == -1 or itemData.expansion == "Other") then
                        GT.db.profile.Filters[itemData.id] = key or nil
                        GT:UpdateIDTable(itemData.id, key)
                        GT:RemoveItemData(key, itemData.id)
                    end
                end

                GT:InventoryUpdate("All Expansion " .. category .. " clicked", false)
            end

            -- Creates the checkbox for the Category using the above local functions
            frame["All Expansions"][category] = frame["All Expansions"]:CreateCheckbox(category, IsSelected_AllExp_Category, SetSelected_AllExp_Category)
            frame["All Expansions"][category]:SetScrollMode(GetScreenHeight() * 0.75)

            -- Creates each item in the Category
            local currentExpac = ""
            for _, itemData in ipairs(GT.ItemDataCategory[category]) do
                if itemData.expansion ~= "Other" then
                    if itemData.expansion ~= currentExpac then
                        local header = {
                            id = -2,
                            name = itemData.expansion,
                        }
                        currentExpac = itemData.expansion
                        CreateItemCheckBox(frame["All Expansions"][category], header)
                    end
                    CreateItemCheckBox(frame["All Expansions"][category], itemData)
                end
            end
        end
    end
end

function GT:CreateCustomFiltersList(frame, rootDescription)
    local customFiltersList = {}
    for id, data in pairs(GT.db.profile.CustomFiltersTable) do
        local itemID = tonumber(id) or 1
        local item = Item:CreateFromItemID(itemID)
        --Waits for the data to be returned from the server
        if not item:IsItemEmpty() then
            item:ContinueOnItemLoad(function()
                local itemLink = string.gsub(item:GetItemLink(), "[%[%]]", "")
                local itemDetails = {
                    id = tonumber(id),
                    text = item:GetItemName(),
                    icon = tostring(C_Item.GetItemIconByID(itemID) or ""),
                    link = itemLink,
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
            GT.db.profile.CustomFiltersTable[id] = key
            GT:UpdateIDTable(id, key)
            GT:RemoveItemData(key, id)
        end

        GT:InventoryUpdate("Custom Filters clicked", false)
    end

    frame["Custom Filters"] = rootDescription:CreateCheckbox("Custom Filters", IsSelected_CustomFilter,
        SetSelected_CustomFilter)

    for itemIndex, itemData in ipairs(customFiltersList) do
        local function IsSelected_CustomFilterItem()
            return GT.db.profile.CustomFiltersTable[itemData.id]
        end
        local function SetSelected_CustomFilterItem()
            GT.Debug("Custom Filter Item Button Clicked", 2, itemData.text)
            local key = not IsSelected_CustomFilterItem()
            GT.db.profile.CustomFiltersTable[itemData.id] = key

            GT:UpdateIDTable(itemData.id, key)
            GT:RemoveItemData(IsSelected_CustomFilterItem(), itemData.id)
            GT:InventoryUpdate("Custom Filter " .. itemData.text .. " menu clicked", false)
        end

        frame["Custom Filters"][itemData.text] = frame["Custom Filters"]:CreateCheckbox(itemData.link,
            IsSelected_CustomFilterItem, SetSelected_CustomFilterItem)
        frame["Custom Filters"][itemData.text]:AddInitializer(function(text, description, menu)
            local leftTexture = text:AttachTexture()

            leftTexture:SetDrawLayer("BACKGROUND", 0)
            leftTexture:SetPoint("LEFT", text.leftTexture1, "RIGHT", 7, 1)
            text:SetHeight(26)
            leftTexture:SetSize(24, 24)
            leftTexture:SetTexture(tonumber(itemData.icon))

            text.fontString:SetPoint("LEFT", leftTexture, "RIGHT", 7, 1)

            local leftTextureRarity = text:AttachTexture()
            leftTextureRarity:SetDrawLayer("BACKGROUND", 1)
            local rarity = C_Item.GetItemQualityByID(itemData.id) or 1
            if rarity <= 1 then
                leftTextureRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
            else
                leftTextureRarity:SetAtlas("bags-glow-white")
            end
            local R, G, B = C_Item.GetItemQualityColor(rarity)
            leftTextureRarity:SetVertexColor(R, G, B, 0.8)
            leftTextureRarity:SetAllPoints(leftTexture)
        end)
        frame["Custom Filters"][itemData.text]:SetTooltip(function(tooltip, elementDescription)
            tooltip:SetHyperlink(itemData.link)
        end)
    end
end

function GT:CreateInventoryFilters(frame, rootDescription)
    local BagStart = BACKPACK_CONTAINER
    local BagEnd = BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1
    local inventoryItems = {}
    local itemlist = {}
    local normalFilter = {}
    local customFilter = {}

    for bag = BagStart, BagEnd do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and not itemlist[itemInfo.itemID] then
                itemlist[itemInfo.itemID] = true
                table.insert(inventoryItems, itemInfo)
            end
        end
    end

    if #inventoryItems > 0 then
        for _, itemInfo in ipairs(inventoryItems) do
            local itemFound = false
            for _, itemData in ipairs(GT.ItemDataFlat) do
                if itemData[GT.gameVersion] then
                    if itemInfo.itemID == itemData.id then
                        itemFound = true
                        table.insert(normalFilter, itemData)
                    end
                end
            end
            if not itemFound then
                table.insert(customFilter, itemInfo)
            end
        end

        frame.Inventory = rootDescription:CreateButton("Inventory", function() end)
        frame.Inventory:SetScrollMode(GetScreenHeight() * 0.75)

        if #normalFilter > 0 then
            local header = frame.Inventory:CreateTitle("Normal Filters Available")
            header:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, "Normal Filters Available")
                GameTooltip_AddNormalLine(tooltip, "Normal filters exist for the following items.", false)
                GameTooltip_AddNormalLine(tooltip, "When toggled, the normal filter will also be toggled.", false)
                GameTooltip_AddNormalLine(tooltip, "If the item is removed from your inventory the normal filter will remain available under the appropriate expansion and category.")
            end)
            table.sort(normalFilter, function(a, b)
                return a.name < b.name
            end)
            for _, itemData in ipairs(normalFilter) do
                CreateItemCheckBox(frame.Inventory, itemData)
            end
        end
        if #customFilter > 0 then
            local header = frame.Inventory:CreateTitle("Add Custom Filter")
            header:SetTooltip(function(tooltip)
                GameTooltip_SetTitle(tooltip, "Add Custom Filter")
                GameTooltip_AddNormalLine(tooltip, "Normal filters do |cffff0000NOT|r exist for the following items.", false)
                GameTooltip_AddNormalLine(tooltip, "A |cff0dd110Checkmark|r means that a custom filter exists and is |cff0dd110Enabled|r for the item.", false)
                GameTooltip_AddNormalLine(tooltip, "A |cffcf2929Dot|r means that a custom filter exists and is |cffcf2929Disabled|r for the item.", false)
                GameTooltip_AddNormalLine(tooltip, "Unchecking an item will remove the custom filter for that item", false)
                GameTooltip_AddNormalLine(tooltip, "If the item is removed from inventory while checked, the Custom Filter will |cffff0000NOT|r be removed.", false)
            end)
            table.sort(customFilter, function(a, b)
                return a.itemName < b.itemName
            end)
            for _, itemInfo in ipairs(customFilter) do
                frame.Inventory[itemInfo.itemName] = frame.Inventory:CreateTemplate("GTTriStateButtonTemplate")
                frame.Inventory[itemInfo.itemName]:AddInitializer(function(checkbox)
                    checkbox:SetPoint("LEFT")

                    local itemLink = string.gsub(itemInfo.hyperlink, "[%[%]]", "")
                    checkbox:SetText(itemLink)

                    checkbox.icon:SetTexture(itemInfo.iconFileID)
                    if itemInfo.quality and itemInfo.quality <= 1 then
                        checkbox.iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
                    else
                        checkbox.iconBorder:SetAtlas("bags-glow-white")
                    end
                    local R, G, B = C_Item.GetItemQualityColor(itemInfo.quality)
                    checkbox.iconBorder:SetVertexColor(R, G, B, 0.8)

                    checkbox.checkBoxFill = checkbox:AttachTexture()
                    checkbox.checkBoxFill:SetPoint("CENTER", checkbox.checkBox)

                    function checkbox:SetCheckedTexture()
                        if checkbox.checked == 0 then
                            checkbox.checkBoxFill:SetAtlas(nil)
                        elseif checkbox.checked == 1 then
                            checkbox.checkBoxFill:SetAtlas("common-dropdown-icon-checkmark-yellow", true)
                            checkbox.checkBoxFill:SetPoint("CENTER", checkbox.checkBox, "CENTER", 2, 1)
                        elseif checkbox.checked == 2 then
                            checkbox.checkBoxFill:SetAtlas("common-dropdown-icon-radialtick-yellow", true)
                            checkbox.checkBoxFill:SetPoint("CENTER", checkbox.checkBox, "CENTER")
                        end
                    end

                    if GT.db.profile.CustomFiltersTable[itemInfo.itemID] ~= nil then
                        if GT.db.profile.CustomFiltersTable[itemInfo.itemID] then
                            checkbox.checked = 1
                        else
                            checkbox.checked = 2
                        end
                        checkbox:SetCheckedTexture()
                    end
                    checkbox:SetScript("OnClick", function()
                        if checkbox.checked == 0 then
                            GT:CreateCustomFilterItem(itemInfo.itemID, true)
                            GT:UpdateIDTable(itemInfo.itemID, true)
                            GT:InventoryUpdate("Inventory Custom Filter " .. itemInfo.itemName .. " option clicked", true)

                            checkbox.checked = 1
                        elseif checkbox.checked == 1 then
                            GT.db.profile.CustomFiltersTable[itemInfo.itemID] = false
                            GT:UpdateIDTable(itemInfo.itemID, false)
                            GT:RemoveItemData(false, itemInfo.itemID)
                            GT:InventoryUpdate("Inventory Custom Filter " .. itemInfo.itemName .. " option clicked", true)

                            checkbox.checked = 2
                        elseif checkbox.checked == 2 then
                            GT:DeleteCustomFilter(itemInfo.itemID, itemInfo.itemName)

                            checkbox.checked = 0
                        end
                        checkbox:SetCheckedTexture()
                    end)

                    local height = 26
                    local width = checkbox.checkBox:GetWidth() + checkbox.icon:GetWidth() + checkbox.text:GetUnboundedStringWidth()
                    return width, height
                end)
                frame.Inventory[itemInfo.itemName]:SetTooltip(function(tooltip, elementDescription)
                    tooltip:SetHyperlink(itemInfo.hyperlink)
                end)
            end
        end
    end
end

function GT:CreateProfilesList(frame, rootDescription)
    frame["Profiles"] = rootDescription:CreateButton("Profiles", function() end)
    frame["Profiles"]:SetSelectionIgnored()

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
            GT.Debug("Profile Button Clicked", 2, name)
            GT.db:SetProfile(name)
            GT.baseFrame.menu:Close()
        end

        frame["Profiles"][name] = frame["Profiles"]:CreateCheckbox(name, IsSelected_Profile, SetSelected_Profile)
    end
end

function GT:DisplayAllCheck()
    if not GT.db.profile.General.allFiltered then
        return
    end

    if #GT.IDs > 500 then
        GT.db.profile.General.allFiltered = false
    end
end


--[[
function GT:CreateSearchMenu(frame, rootDescription)
    GT.baseFrame.menu.SearchResults = GT.baseFrame.menu.SearchResults or {}
    local frame = frame or {}
    frame.Search = rootDescription:CreateButton("Search", function() end)
    frame.Search:SetScrollMode(GetScreenHeight() * 0.75)
    frame.Search.searchBar = frame.Search:CreateFrame()
    frame.Search.searchBar:AddInitializer(function(searchBar)
        local editbox = searchBar:AttachTemplate("SearchBoxTemplate")
        editbox:SetPoint("TOPLEFT")
        editbox:SetSize(200, 22)
        editbox:HookScript("OnEnterPressed", function()
            GT.baseFrame.menu.SearchResults = {}
            for _, itemData in ipairs(GT.ItemDataFlat) do
                if itemData[GT.gameVersion] then
                    if string.find(string.lower(itemData.name), string.lower(editbox:GetText())) then
                        GT.Debug("Filter Menu Search", 2, editbox:GetText(), itemData.name)
                        table.insert(GT.baseFrame.menu.SearchResults, itemData)
                    end
                end
            end
            GT:GenerateFiltersMenu(GT.baseFrame.button)
            --GT.baseFrame.menu:ReinitializeAll()
        end)
        editbox.clearButton:HookScript("OnClick", function()

        end)
    end)
    if #GT.baseFrame.menu.SearchResults > 0 then
        for index, itemData in ipairs(GT.baseFrame.menu.SearchResults) do
            CreateItemCheckBox(frame.Search, itemData)
        end
    end
end
]]
