---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

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
    local filterButton = CreateFrame("Button", "GT_baseFrame_filtersButton", UIParent, "UIPanelButtonTemplate")
    filterButton:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT")
    filterButton:SetWidth(25)
    filterButton:SetHeight(25)
    filterButton:SetText("F")
    filterButton:EnableMouse(true)
    filterButton:RegisterForClicks("AnyDown")
    filterButton:SetFrameStrata("BACKGROUND")
    filterButton:SetFrameLevel(1)
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

function GT:GenerateFiltersMenu(frame)
    local function FiltersMenu(frame, rootDescription)
        rootDescription:SetTag("GatheringTracker_Filter_Menu")
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
                        end
                    end

                    GT:InventoryUpdate(expansion .. " clicked", false)
                end

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
                            end

                            GT:InventoryUpdate(expansion .. " " .. category .. " clicked", false)
                        end

                        frame[expansion][category] = frame[expansion]:CreateCheckbox(category, IsSelected_Category, SetSelected_Category)
                        frame[expansion][category]:SetScrollMode(GetScreenHeight() * 0.75)
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
                                local key = not IsSelected_Item()
                                GT.db.profile.Filters[itemData.id] = key or nil

                                GT:UpdateIDTable(itemData.id, key)
                                GT:RemoveItemData(key, itemData.id)
                                GT:InventoryUpdate(expansion .. " " .. category .. " " .. itemData.name .. " menu clicked", false)
                            end

                            if itemData.id == -1 then
                                local divider = frame[expansion][category]:CreateTitle(itemData.name)
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

                                frame[expansion][category][itemData.name] = frame[expansion][category]:CreateCheckbox(name, IsSelected_Item, SetSelected_Item)
                                frame[expansion][category][itemData.name]:AddInitializer(function(text, description, menu)
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
                                    local rarity = C_Item.GetItemQualityByID(itemData.id) or 1
                                    if rarity <= 1 then
                                        leftTextureRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
                                    else
                                        leftTextureRarity:SetAtlas("bags-glow-white")
                                    end
                                    local R, G, B = C_Item.GetItemQualityColor(rarity)
                                    leftTextureRarity:SetVertexColor(R, G, B, 0.8)
                                    leftTextureRarity:SetAllPoints(leftTexture)

                                    if itemData.quality then
                                        local leftTextureQuality = text:AttachTexture()
                                        leftTextureQuality:SetDrawLayer("BACKGROUND", 2)
                                        if itemData.quality == 1 then
                                            leftTextureQuality:SetAtlas("professions-icon-quality-tier1-inv", true)
                                        elseif itemData.quality == 2 then
                                            leftTextureQuality:SetAtlas("professions-icon-quality-tier2-inv", true)
                                        elseif itemData.quality == 3 then
                                            leftTextureQuality:SetAtlas("professions-icon-quality-tier3-inv", true)
                                        end
                                        leftTextureQuality:SetAllPoints(leftTexture)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        --add Custom Filters to filterMenu
        GT:CreateCustomFiltersList(frame, rootDescription)

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
            mouseOver:SetFrameLevel(2)
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
            GT.baseFrame.button.mouseOver:SetMouseMotionEnabled(false)
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
                local itemDetails = {
                    id = tonumber(id),
                    text = item:GetItemName(),
                    icon = tostring(C_Item.GetItemIconByID(itemID) or "")
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

    frame["Custom Filters"] = rootDescription:CreateCheckbox("Custom Filters", IsSelected_CustomFilter, SetSelected_CustomFilter)

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

        frame["Custom Filters"][itemData.text] = frame["Custom Filters"]:CreateCheckbox(itemData.text, IsSelected_CustomFilterItem, SetSelected_CustomFilterItem)
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
    end
end

function GT:CreateProfilesList(frame, rootDescription)
    local function IsSelected_ProfilesCategory()
        return false
    end

    local function SetSelected_ProfilesCategory()
    end

    frame["Profiles"] = rootDescription:CreateCheckbox("Profiles", IsSelected_ProfilesCategory, SetSelected_ProfilesCategory)
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
