---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

-- Localize global functions
local ipairs = ipairs
local pairs = pairs
local table = table
local tonumber = tonumber

function GT:GenerateAlertsMenu(frame)
    local function AlertsMenu(frame, rootDescription)
        rootDescription:SetTag("GatheringTracker_Alerts_Menu")
        for expansionIndex, expansion in ipairs(GT.expansionsOrder) do
            if GT.ItemData[expansion] and expansion ~= "Other" then
                frame[expansion] = rootDescription:CreateButton(expansion, function() end)
                for categoryIndex, category in ipairs(GT.categoriesOrder) do
                    if GT.ItemData[expansion][category] then
                        frame[expansion][category] = frame[expansion]:CreateButton(category, function() end)
                        frame[expansion][category]:SetScrollMode(GetScreenHeight() * 0.75)
                        for _, itemData in ipairs(GT.ItemData[expansion][category]) do
                            local function IsSelected_Item()
                                if GT.db.profile.Alerts[itemData.id] then
                                    return true
                                else
                                    return false
                                end
                            end
                            local function SetSelected_Item()
                                GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name)
                                local key = not IsSelected_Item()
                                if key then
                                    local alertItemData = {
                                        id = itemData.id,
                                        name = itemData.name,
                                        icon = itemData.icon or C_Item.GetItemIconByID(itemData.id),
                                        rarity = C_Item.GetItemQualityByID(itemData.id) or 1,
                                    }
                                    if GT.gameVersion == "retail" then
                                        alertItemData.quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemData.id)
                                    end

                                    GT.AlertSystem:AddItem(alertItemData.id)
                                    GT.db.profile.Alerts[alertItemData.id] = {}
                                    GT.db.profile.Alerts[alertItemData.id].enable = true
                                    GT.db.profile.Alerts[alertItemData.id].alerts = {}
                                    GT.db.profile.Alerts[itemData.id].itemData = alertItemData
                                    GT:CreateAlertOptions(alertItemData)
                                else
                                    GT.db.profile.Alerts[itemData.id] = nil
                                    GT:RemoveItemAlerts(itemData.id)
                                end
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
        GT:CreateCustomFiltersAlertsList(frame, rootDescription)

        local special = {
            {
                id = 1,
                name = "All Items",
            },
            {
                id = 2,
                name = "Total Items",
                icon = 133647,
            },
        }

        for _, itemData in ipairs(special) do
            local function IsSelected_Item()
                if GT.db.profile.Alerts[itemData.id] then
                    return true
                else
                    return false
                end
            end
            local function SetSelected_Item()
                GT.Debug("Item Button Clicked", 2, itemData.name)
                local key = not IsSelected_Item()
                if key then
                    GT.AlertSystem:AddItem(itemData.id)
                    GT.db.profile.Alerts[itemData.id] = {}
                    GT.db.profile.Alerts[itemData.id].enable = true
                    GT.db.profile.Alerts[itemData.id].alerts = {}
                    GT.db.profile.Alerts[itemData.id].itemData = itemData
                    GT:CreateAlertOptions(itemData)
                else
                    GT.db.profile.Alerts[itemData.id] = nil
                    GT:RemoveItemAlerts(itemData.id)
                end
            end

            frame[itemData.name] = rootDescription:CreateCheckbox(itemData.name, IsSelected_Item, SetSelected_Item)
        end

        GT.AlertSystem.Menu.rootDescription = rootDescription
    end

    ---@class GT.AlertSystem.Menu: MenuProxy
    GT.AlertSystem.Menu = GT.AlertSystem.Menu or {}
    GT.AlertSystem.Menu = MenuUtil.CreateContextMenu(frame, AlertsMenu)
end

function GT:CreateCustomFiltersAlertsList(frame, rootDescription)
    local customFiltersList = {}
    for id, data in pairs(GT.db.profile.CustomFiltersTable) do
        local itemID = tonumber(id) or 1
        local item = Item:CreateFromItemID(itemID)
        --Waits for the data to be returned from the server
        item:ContinueOnItemLoad(function()
            local itemInfo = { C_Item.GetItemInfo(id) }
            local itemData = {
                id = id,
                name = itemInfo[1],
                icon = itemInfo[10],
                rarity = itemInfo[3],
            }
            if GT.gameVersion == "retail" then
                itemData.quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)
            end
            table.insert(customFiltersList, itemData)
        end)
    end

    table.sort(customFiltersList, function(a, b)
        return a.name < b.name
    end)

    frame["Custom Filters"] = rootDescription:CreateButton("Custom Filters", function() end)

    for itemIndex, itemData in ipairs(customFiltersList) do
        local function IsSelected_CustomFilterItem()
            if GT.db.profile.Alerts[itemData.id] then
                return true
            else
                return false
            end
        end
        local function SetSelected_CustomFilterItem()
            GT.Debug("Item Button Clicked", 2, itemData.name)
            local key = not IsSelected_CustomFilterItem()
            if key then
                GT.AlertSystem:AddItem(itemData.id)
                GT.db.profile.Alerts[itemData.id] = {}
                GT.db.profile.Alerts[itemData.id].enable = true
                GT.db.profile.Alerts[itemData.id].alerts = {}
                GT.db.profile.Alerts[itemData.id].itemData = itemData
                GT:CreateAlertOptions(itemData)
            else
                GT.db.profile.Alerts[itemData.id] = nil
                GT:RemoveItemAlerts(itemData.id)
            end
        end

        frame["Custom Filters"][itemData.name] = frame["Custom Filters"]:CreateCheckbox(itemData.name, IsSelected_CustomFilterItem, SetSelected_CustomFilterItem)
        frame["Custom Filters"][itemData.name]:AddInitializer(function(text, description, menu)
            local leftTexture = text:AttachTexture()
            leftTexture:SetDrawLayer("BACKGROUND", 0)
            text:SetHeight(26)
            leftTexture:SetSize(24, 24)
            leftTexture:SetPoint("LEFT", text.leftTexture1, "RIGHT", 7, 1)
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
