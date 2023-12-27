local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local Config = GT:NewModule("Config", "AceEvent-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

GT.media = media

GT.defaults = {
    profile = {
        General = {
            enable = true,
            unlock = false,
            filtersButton = false,
            buttonFade = false,
            buttonAlpha = 0,
            buttonDelay = 0.5,
            xPos = 200,
            yPos = -150,
            relativePoint = "TOPLEFT",
            iconWidth = 27,
            iconHeight = 27,
            textColor = { 1, 1, 1 },
            textSize = 20,
            textFont = "Fira Mono Medium",
            totalColor = { 0.098, 1, 0.078 },
            totalSize = 20,
            totalFont = "Fira Mono Medium",
            groupType = 0,
            stacksOnIcon = false,
            includeBank = false,
            tsmPrice = 1,
            ignoreAmount = 0,
            perItemPrice = false,
            debugOption = 0,
            characterValue = false,
            hideOthers = false,
            displayAlias = false,
            rarityBorder = true,
        },
        Notifications = {
            Count = {
                enable = false,
                threshold = "100",
                itemAll = 1,
                interval = 1,
                sound = "Auction Window Close"
            },
            Gold = {
                enable = false,
                threshold = "1000",
                itemAll = 1,
                interval = 1,
                sound = "Auction Window Open"
            },
        },
        Filters = {
        },
        CustomFilters = "",
        CustomFiltersTable = {
        },
        Aliases = {
        },
    },
}

local generalOptions = {
    type = "group",
    childGroups = "tab",
    args = {
        General = {
            type = "group",
            name = "General",
            order = 1,
            args = {
                enable = {
                    type = "toggle",
                    name = "Enabled",
                    desc = "Uncheck to disable the addon, this will effectively turn off the addon.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.enable end,
                    set = function(_, key)
                        GT:ToggleGatheringTracker()
                    end,
                    order = 1
                },
                unlock = {
                    type = "toggle",
                    name = "Unlock Frame",
                    width = 1.70,
                    get = function() return GT.db.profile.General.unlock end,
                    set = function(_, key)
                        GT.db.profile.General.unlock = key
                        GT:ToggleBaseLock(key)
                    end,
                    order = 2
                },
                buttonHeader = {
                    type = "header",
                    name = "Filter Button",
                    order = 10
                },
                filtersButton = {
                    type = "toggle",
                    name = "Filters Button",
                    desc = "Left Click shows filters menu.\nRight Click clears all filters.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.filtersButton end,
                    set = function(_, key)
                        GT.db.profile.General.filtersButton = key
                        GT:FiltersButton()
                    end,
                    order = 11
                },
                buttonFade = {
                    type = "toggle",
                    name = "Fade Out",
                    desc = "When Enabled the Filter Button will fade out, but will show up again on mouse over.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.buttonFade end,
                    set = function(_, key)
                        GT.db.profile.General.buttonFade = key
                        local alpha = GT.db.profile.General.buttonAlpha
                        if not key then
                            alpha = 100
                        end
                        GT:FiltersButtonFade(alpha)
                    end,
                    disabled = function()
                        if GT.db.profile.General.filtersButton then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 12
                },
                buttonAlpha = {
                    type = "range",
                    name = "Fade Out Alpha",
                    desc = "0% is not visible, 100% is fully visible.\nDefault is 0",
                    min = 0,
                    max = 100,
                    step = 1,
                    width = 1.40,
                    get = function() return GT.db.profile.General.buttonAlpha or 0 end,
                    set = function(_, key)
                        GT.db.profile.General.buttonAlpha = key
                        GT:FiltersButtonFade(key)
                    end,
                    disabled = function()
                        if GT.db.profile.General.filtersButton then
                            if GT.db.profile.General.buttonFade then
                                return false
                            else
                                return true
                            end
                        else
                            return true
                        end
                    end,
                    order = 13
                },
                spacer2 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 14
                },
                buttonDelay = {
                    type = "range",
                    name = "Fade Out Delay",
                    desc = "This configures how long after the mouse leaves the button before it fades out.\nDefault is 0.5.",
                    min = 0,
                    max = 1,
                    step = 0.02,
                    width = 1.40,
                    get = function() return GT.db.profile.General.buttonDelay or 0 end,
                    set = function(_, key) GT.db.profile.General.buttonDelay = key end,
                    disabled = function()
                        if GT.db.profile.General.filtersButton then
                            if GT.db.profile.General.buttonFade then
                                return false
                            else
                                return true
                            end
                        else
                            return true
                        end
                    end,
                    order = 15
                },
                header1 = {
                    type = "header",
                    name = "Group Options",
                    order = 100
                },
                groupType = {
                    type = "select",
                    name = "Group Mode",
                    desc = "Disabled: Hides the display when in a group\nGroup Only: Only shows the display when in a group\nGroup and Solo: Shows the display when in a group or Solo",
                    width = 1.40,
                    values = { [0] = "Disabled", [1] = "Group Only", [2] = "Group and Solo" },
                    get = function() return GT.db.profile.General.groupType end,
                    set = function(_, key)
                        GT:ToggleGroupMode(key)
                    end,
                    order = 101
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 102
                },
                hideOthers = {
                    type = "toggle",
                    name = "Hide Other Party Members",
                    desc = "When selected only your character will be displayed when you are in a group.\nInformation will still be sent to and received from party members.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.hideOthers end,
                    set = function(_, key)
                        GT.db.profile.General.hideOthers = key
                        if key then
                            GT:ClearDisplay()
                            GT:GROUP_ROSTER_UPDATE("Hide Other Party Members", false)
                        else
                            GT:InventoryUpdate("Toggle Hide Other Party Members", false)
                        end
                    end,
                    disabled = function()
                        if GT.db.profile.General.groupType == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 103
                },
                displayAlias = {
                    type = "toggle",
                    name = "Display Characters Alias",
                    desc = "When selected the character aliases will be displayed above their count column.",
                    width = 1.70,
                    image = function() return 413577 end,
                    get = function() return GT.db.profile.General.displayAlias end,
                    set = function(_, key)
                        GT.db.profile.General.displayAlias = key
                        if not GT:GroupDisplayCheck() then
                            return
                        end
                        if not key then
                            GT:RemoveDiaplayRow(0)
                            GT:AllignRows()
                        end
                        GT:InventoryUpdate("Toggle Characters Alias", false)
                    end,
                    disabled = function()
                        if GT.db.profile.General.groupType == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 105
                },
                characterValue = {
                    type = "toggle",
                    name = "Display Per Character Value",
                    desc = "When selected the gold value of the items gathered per character will be displayed above the totals row.",
                    width = 1.70,
                    image = function() return 133784 end,
                    get = function() return GT.db.profile.General.characterValue end,
                    set = function(_, key)
                        GT.db.profile.General.characterValue = key
                        if not GT:GroupDisplayCheck() then
                            return
                        end
                        if not key then
                            GT:RemoveDiaplayRow(9999999999)
                        end
                        GT:InventoryUpdate("Toggle Per Character Value", false)
                    end,
                    disabled = function()
                        if GT.db.profile.General.groupType == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 106
                },
            },
        },
        LookandFeel = {
            type = "group",
            name = "Look and Feel",
            order = 2,
            args = {
                header2 = {
                    type = "header",
                    name = "Display Options",
                    order = 200
                },
                tsmPrice = {
                    type = "select",
                    name = "TSM Price Source",
                    desc = "Select the desired TSM price source, or none to disable price information.  TSM is required for this option to be enabled.",
                    width = 1.70,
                    values = { [0] = "None", [1] = "DBMarket", [2] = "DBMinBuyout", [3] = "DBHistorical", [4] = "DBRegionMinBuyoutAvg", [5] = "DBRegionMarketAvg", [6] = "DBRegionHistorical" },
                    get = function() return GT.db.profile.General.tsmPrice end,
                    set = function(_, key)
                        GT.db.profile.General.tsmPrice = key
                        if GT.db.profile.General.tsmPrice == 0 then
                            GT.db.profile.General.perItemPrice = false
                            for itemID, itemFrame in pairs(GT.Display.Frames) do
                                local cellsToRemove = #itemFrame.text - itemFrame.displayedCharacters
                                for iterator = 1, cellsToRemove, 1 do
                                    GT.Pools.fontStringPool:Release(itemFrame.text[#itemFrame.text])
                                    GT:AddRemoveDisplayCell("remove", itemFrame, #itemFrame.text)
                                end
                                itemFrame.pricePerItem = nil
                                itemFrame.priceTotalItem = nil
                            end
                            local cellsToRemove = #GT.Display.ColumnSize - #GT.sender
                            for iterator = 1, cellsToRemove, 1 do
                                table.remove(GT.Display.ColumnSize, #GT.Display.ColumnSize)
                            end
                        else
                            GT:PrepareDataForDisplay("TSM Price Source Option Changed")
                        end
                    end,
                    disabled = function()
                        if not GT.tsmLoaded then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 201
                },
                perItemPrice = {
                    type = "toggle",
                    name = "Display Per Item Price",
                    desc = "If selected the price for 1 of each item will be displayed",
                    width = 1.70,
                    get = function() return GT.db.profile.General.perItemPrice end,
                    set = function(_, key)
                        GT.db.profile.General.perItemPrice = key
                        if not key then
                            local columnToRemove
                            for itemID, itemFrame in pairs(GT.Display.Frames) do
                                if itemFrame.pricePerItem then
                                    columnToRemove = columnToRemove or itemFrame.pricePerItem

                                    GT.Pools.fontStringPool:Release(itemFrame.text[columnToRemove])
                                    GT:AddRemoveDisplayCell("remove", itemFrame, columnToRemove)

                                    itemFrame.pricePerItem = nil
                                    GT:SetAnchor(itemFrame)
                                end
                            end
                            table.remove(GT.Display.ColumnSize, columnToRemove)
                        else
                            GT:PrepareDataForDisplay("Display Per Item Price Enabled")
                        end
                    end,
                    disabled = function()
                        if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 202
                },
                ignoreAmount = {
                    type = "range",
                    name = "Ignore Amount",
                    desc = "Use this option to ignore a specific amount, this value will be subtracted from the totals.",
                    min = 0,
                    max = 100,
                    step = 1,
                    width = 1.70,
                    get = function() return GT.db.profile.General.ignoreAmount or 0 end,
                    set = function(_, key)
                        GT.db.profile.General.ignoreAmount = key
                        GT:InventoryUpdate("Ignore Amount Changed", true)
                    end,
                    order = 203
                },
                includeBank = {
                    type = "toggle",
                    name = "Include Bank",
                    desc = "If selected displayed values will include items in your bank.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.includeBank end,
                    set = function(_, key)
                        GT.db.profile.General.includeBank = key
                        GT:InventoryUpdate("Include Bank", true)
                    end,
                    order = 204
                },
                header3 = {
                    type = "header",
                    name = "Icon",
                    order = 300
                },
                iconWidth = {
                    type = "range",
                    name = "Icon Width",
                    min = 10,
                    max = 100,
                    step = 1,
                    width = 1.70,
                    get = function() return GT.db.profile.General.iconWidth or 1 end,
                    set = function(_, key)
                        GT.db.profile.General.iconWidth = key
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            itemFrame.icon:SetWidth(GT.db.profile.General.iconWidth)
                        end
                    end,
                    order = 301
                },
                iconHeight = {
                    type = "range",
                    name = "Icon Height",
                    min = 10,
                    max = 100,
                    step = 1,
                    width = 1.70,
                    get = function() return GT.db.profile.General.iconHeight or 1 end,
                    set = function(_, key)
                        GT.db.profile.General.iconHeight = key
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            itemFrame.icon:SetHeight(GT.db.profile.General.iconHeight)

                            local frameHeight = GT.db.profile.General.iconHeight + 3

                            if frameHeight < itemFrame.text[1]:GetStringHeight() then
                                itemFrame:SetHeight(itemFrame.text[1]:GetStringHeight() + 3)
                            else
                                itemFrame:SetHeight(frameHeight)
                            end
                        end
                    end,
                    order = 302
                },
                rarityBorder = {
                    type = "toggle",
                    name = "Show Rarity Border",
                    desc = "Will display a colored border based on item rarity.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.rarityBorder end,
                    set = function(_, key)
                        GT.db.profile.General.rarityBorder = key

                        if key then
                            for itemID, itemFrame in pairs(GT.Display.Frames) do
                                if itemID > 2 and itemID < 9999999998 then
                                    local iconRarity = C_Item.GetItemQualityByID(itemID)
                                    GT:CreateRarityBorder(itemFrame, iconRarity)
                                end
                            end
                        else
                            for itemID, itemFrame in pairs(GT.Display.Frames) do
                                if itemFrame.iconRarity then
                                    itemFrame.iconRarity:SetVertexColor(1, 1, 1, 1)
                                    GT.Pools.texturePool:Release(itemFrame.iconRarity)
                                    itemFrame.iconRarity = nil
                                end
                            end
                        end
                    end,
                    order = 303
                },
                header4 = {
                    type = "header",
                    name = "Text",
                    order = 400
                },
                textColor = {
                    type = "color",
                    name = "Text Color",
                    hasAlpha = false,
                    get = function()
                        local c = GT.db.profile.General.textColor
                        return c[1], c[2], c[3] or 1, 1, 1
                    end,
                    set = function(_, r, g, b)
                        GT.db.profile.General.textColor = { r, g, b }
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID < 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetVertexColor(unpack(GT.db.profile.General.textColor))
                                end
                            end
                        end
                    end,
                    order = 401
                },
                textSize = {
                    type = "range",
                    name = "Text Size",
                    min = 10,
                    max = 70,
                    step = 1,
                    width = 1.20,
                    get = function() return GT.db.profile.General.textSize or 1 end,
                    set = function(_, key)
                        if key < GT.db.profile.General.textSize then
                            GT.Display.ColumnSize = {}
                        end
                        GT.db.profile.General.textSize = key
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID < 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end

                                local frameHeight = GT.db.profile.General.iconHeight + 3

                                if frameHeight < itemFrame.text[1]:GetStringHeight() then
                                    itemFrame:SetHeight(itemFrame.text[1]:GetStringHeight() + 3)
                                else
                                    itemFrame:SetHeight(frameHeight)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 402
                },
                textFont = {
                    type = "select",
                    name = "Text Font",
                    width = 1.20,
                    dialogControl = 'LSM30_Font',
                    values = media:HashTable("font"),
                    get = function() return GT.db.profile.General.textFont end,
                    set = function(_, key)
                        GT.db.profile.General.textFont = key
                        GT.Display.ColumnSize = {}
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID < 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 403
                },
                totalColor = {
                    type = "color",
                    name = "Total Color",
                    hasAlpha = false,
                    get = function()
                        local c = GT.db.profile.General.totalColor
                        return c[1], c[2], c[3] or 1, 1, 1
                    end,
                    set = function(_, r, g, b)
                        GT.db.profile.General.totalColor = { r, g, b }
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID >= 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetVertexColor(unpack(GT.db.profile.General.totalColor[1]))
                                end
                            end
                        end
                    end,
                    order = 404
                },
                totalSize = {
                    type = "range",
                    name = "Total Size",
                    min = 10,
                    max = 70,
                    step = 1,
                    width = 1.20,
                    get = function() return GT.db.profile.General.totalSize or 1 end,
                    set = function(_, key)
                        if key < GT.db.profile.General.totalSize then
                            GT.Display.ColumnSize = {}
                        end
                        GT.db.profile.General.totalSize = key
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID >= 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end

                                local frameHeight = GT.db.profile.General.iconHeight + 3

                                if frameHeight < itemFrame.text[1]:GetStringHeight() then
                                    itemFrame:SetHeight(itemFrame.text[1]:GetStringHeight() + 3)
                                else
                                    itemFrame:SetHeight(frameHeight)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 405
                },
                totalFont = {
                    type = "select",
                    name = "Total Font",
                    width = 1.20,
                    dialogControl = 'LSM30_Font',
                    values = media:HashTable("font"),
                    get = function() return GT.db.profile.General.totalFont end,
                    set = function(_, key)
                        GT.db.profile.General.totalFont = key
                        GT.Display.ColumnSize = {}
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID >= 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 406
                },
            },
        },
        Notifications = {
            type = "group",
            name = "Notifications",
            order = 3,
            args = {
                header1 = {
                    type = "header",
                    name = "Count Notification",
                    order = 1
                },
                countEnable = {
                    type = "toggle",
                    name = "Enable Count Notification",
                    desc = "Check to enable Count notification.",
                    width = "full",
                    get = function() return GT.db.profile.Notifications.Count.enable end,
                    set = function(_, key)
                        GT:ToggleCountNotifications()
                    end,
                    order = 2
                },
                countSound = {
                    type = "select",
                    name = "Alert Sound",
                    desc = "The sound that plays when the notification is triggered.\nDefault: Auction Window Close",
                    width = 1.40,
                    dialogControl = "LSM30_Sound",
                    values = media:HashTable("sound"),
                    get = function() return GT.db.profile.Notifications.Count.sound end,
                    set = function(_, key) GT.db.profile.Notifications.Count.sound = key end,
                    disabled = function() return not GT.db.profile.Notifications.Count.enable end,
                    order = 3
                },
                spacer1 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 4
                },
                countThreshold = {
                    type = "input",
                    name = "Count Threshold",
                    width = "Normal",
                    usage = "Enter threshold for alert\n\nDefault: 100",
                    validate = function(_, key)
                        if not (string.match(key, "[%d]+") or key == '') then
                            return false
                        end
                        return true
                    end,
                    get = function() return GT.db.profile.Notifications.Count.threshold end,
                    set = function(_, key)
                        if key == '' or key == nil then
                            key = '0'
                        end
                        GT.db.profile.Notifications.Count.threshold = key
                    end,
                    disabled = function() return not GT.db.profile.Notifications.Count.enable end,
                    order = 5
                },
                countItemAll = {
                    type = "select",
                    name = "Notify for each item, all items, or both",
                    desc = "This controls if the notification triggers when each filtered item hits the threshold, when all items hits the threshold, or both.\n\nDefault: All Items",
                    width = 1.40,
                    values = { [0] = "Each Item", [1] = "All Items", [2] = "Both" },
                    get = function() return GT.db.profile.Notifications.Count.itemAll end,
                    set = function(_, key) GT.db.profile.Notifications.Count.itemAll = key end,
                    disabled = function() return not GT.db.profile.Notifications.Count.enable end,
                    order = 6
                },
                spacer2 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 7
                },
                countInterval = {
                    type = "select",
                    name = "Exact or Interval",
                    desc =
                    "This controls if the notification only triggers when exceeding the exact threshold, an interval of the threshold, or both.\n For an Example, if the threshold is 100:\n Exact: only triggers once after exceeding 100\n Interval: Triggers after exceeding 100, 200, 300, etc\n\nDefault: Exact",
                    width = 1.40,
                    values = { [0] = "Exact", [1] = "Interval" },
                    get = function() return GT.db.profile.Notifications.Count.interval end,
                    set = function(_, key) GT.db.profile.Notifications.Count.interval = key end,
                    disabled = function() return not GT.db.profile.Notifications.Count.enable end,
                    order = 8
                },

                --Gold Notification Settings
                header2 = {
                    type = "header",
                    name = "Gold Notification",
                    order = 101
                },
                goldEnable = {
                    type = "toggle",
                    name = "Enable Gold Notification",
                    desc = "Check to enable gold notification.\n\nRequires TSM.",
                    width = "full",
                    get = function() return GT.db.profile.Notifications.Gold.enable end,
                    set = function(_, key)
                        GT:ToggleGoldNotifications()
                    end,
                    disabled = function()
                        if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 102
                },
                goldSound = {
                    type = "select",
                    name = "Alert Sound",
                    desc = "The sound that plays when the notification is triggered.\nDefault: Auction Window Open",
                    width = 1.40,
                    dialogControl = "LSM30_Sound",
                    values = media:HashTable("sound"),
                    get = function() return GT.db.profile.Notifications.Gold.sound end,
                    set = function(_, key) GT.db.profile.Notifications.Gold.sound = key end,
                    disabled = function()
                        if GT.db.profile.Notifications.Gold.enable then
                            if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                                return true
                            else
                                return false
                            end
                        else
                            return true
                        end
                    end,
                    order = 103
                },
                spacer3 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 104
                },
                goldThreshold = {
                    type = "input",
                    name = "Gold Threshold",
                    width = "Normal",
                    usage = "Enter threshold for alert in gold value\n\nDefault: 1000",
                    validate = function(_, key)
                        if not (string.match(key, "[%d]+") or key == '') then
                            return false
                        end
                        return true
                    end,
                    get = function() return GT.db.profile.Notifications.Gold.threshold end,
                    set = function(_, key)
                        if key == '' or key == nil then
                            key = '0'
                        end
                        GT.db.profile.Notifications.Gold.threshold = key
                    end,
                    disabled = function()
                        if GT.db.profile.Notifications.Gold.enable then
                            if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                                return true
                            else
                                return false
                            end
                        else
                            return true
                        end
                    end,
                    order = 105
                },
                goldItemAll = {
                    type = "select",
                    name = "Notify for each item, all items, or both",
                    desc = "This controls if the notification triggers when each filtered item hits the threshold, when all items hits the threshold, or both.\n\nDefault: All Items",
                    width = 1.40,
                    values = { [0] = "Each Item", [1] = "All Items", [2] = "Both" },
                    get = function() return GT.db.profile.Notifications.Gold.itemAll end,
                    set = function(_, key) GT.db.profile.Notifications.Gold.itemAll = key end,
                    disabled = function()
                        if GT.db.profile.Notifications.Gold.enable then
                            if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                                return true
                            else
                                return false
                            end
                        else
                            return true
                        end
                    end,
                    order = 106
                },
                spacer4 = {
                    type = "description",
                    name = " ",
                    width = 0.3,
                    order = 107
                },
                goldInterval = {
                    type = "select",
                    name = "Exact or Interval",
                    desc =
                    "This controls if the notification only triggers when exceeding the exact threshold, an interval of the threshold, or both.\n For an Example, if the threshold is 100:\n Exact: only triggers once after exceeding 100\n Interval: Triggers after exceeding 100, 200, 300, etc\n\nDefault: Exact",
                    width = 1.40,
                    values = { [0] = "Exact", [1] = "Interval" },
                    get = function() return GT.db.profile.Notifications.Gold.interval end,
                    set = function(_, key) GT.db.profile.Notifications.Gold.interval = key end,
                    disabled = function()
                        if GT.db.profile.Notifications.Gold.enable then
                            if not GT.tsmLoaded or GT.db.profile.General.tsmPrice == 0 then
                                return true
                            else
                                return false
                            end
                        else
                            return true
                        end
                    end,
                    order = 108
                },
            }
        },
        Debug = {
            type = "group",
            name = "Debug",
            order = 4,
            args = {
                header5 = {
                    type = "header",
                    name = "Debug",
                    order = 10000
                },
                debugOption = {
                    type = "select",
                    name = "Debug",
                    desc = "This is for debugging the addon, do NOT enable, it is spammy.",
                    width = 1.70,
                    values = { [0] = "Off", [1] = "Limites", [2] = "Info", [3] = "Debug", [4] = "Trace (Very Spammy)" },
                    get = function()
                        if type(GT.db.profile.General.debugOption) == "boolean" then
                            GT.db.profile.General.debugOption = 0
                        end
                        return GT.db.profile.General.debugOption
                    end,
                    set = function(_, key) GT.db.profile.General.debugOption = key end,
                    order = 10001
                },
            }
        }
    }
}

local filterOptions = {
    type = "group",
    name = "Filters",
    childGroups = "tab",
    args = {
        filtersHeading = {
            type = "description",
            name = "Select all items you wish to display.",
            width = "full",
            order = 1
        },
        custom = {
            type = "group",
            name = "Custom",
            order = 1000000,
            args = {
                customHeading = {
                    type = "description",
                    name = "Use this field to add additional items (by ID only) to be tracked.  One ID per line!",
                    width = "full",
                    order = 1
                },
                customInput = {
                    type = "input",
                    name = "Custom Input",
                    multiline = true,
                    width = "full",
                    usage = "Please only enter item ID's (aka numbers)",
                    --validate = function(_, key) if string.match(key, "[^%d\n]+") then return false end return true end,
                    get = function() return GT.db.profile.CustomFilters end,
                    set = function(_, key)
                        GT.db.profile.CustomFilters = key
                        local tempFilterTable = {}
                        for itemID in string.gmatch(GT.db.profile.CustomFilters, "[%d]+") do
                            if GT.db.profile.CustomFiltersTable[itemID] then
                                tempFilterTable[itemID] = GT.db.profile.CustomFiltersTable[itemID]
                            else
                                tempFilterTable[itemID] = true
                            end
                        end
                        GT.db.profile.CustomFiltersTable = tempFilterTable
                        GT:CreateCustomFilterOptions()
                        GT:RebuildIDTables()
                        GT:InventoryUpdate("Custom Filter Changed", true)
                        GT:CreateCustomFiltersList()
                    end,
                    order = 2
                },
                header1 = {
                    type = "header",
                    name = "Custom Options",
                    order = 100
                },
            }
        },
    }
}

for expansion, expansionData in pairs(GT.ItemData) do
    filterOptions.args[expansion] = {
        type = "group",
        name = expansion,
        childGroups = "tree",
        order = (GT.expansions[expansion] * 1000),
        args = {}
    }
    for category, categoryData in pairs(expansionData) do
        filterOptions.args[expansion].args[category] = {
            type = "group",
            name = category,
            order = (GT.categories[category] * 100),
            args = {}
        }
        for _, itemData in ipairs(categoryData) do
            if itemData.id == -1 then
                filterOptions.args[expansion].args[category].args[expansion .. " " .. itemData.name] = {
                    type = "header",
                    name = itemData.name,
                    order = itemData.order
                }
            else
                filterOptions.args[expansion].args[category].args[tostring(itemData.id)] = {
                    type = "toggle",
                    name = function()
                        if itemData.quality then
                            if itemData.quality == 1 then
                                return "|cff784335" .. itemData.name .. "*"
                            elseif itemData.quality == 2 then
                                return "|cff96979E" .. itemData.name .. "**"
                            elseif itemData.quality == 3 then
                                return "|cffDCC15F" .. itemData.name .. "***"
                            end
                        else
                            return itemData.name
                        end
                    end,
                    image = function()
                        if itemData.id <= #GT.ItemData.Other.Other then
                            return itemData.icon
                        else
                            return GetItemIcon(tonumber(itemData.id))
                        end
                    end,
                    get = function() return GT.db.profile.Filters[itemData.id] end,
                    set = function(_, key)
                        if key then
                            GT.db.profile.Filters[itemData.id] = key
                        else
                            GT.db.profile.Filters[itemData.id] = nil
                        end

                        GT:RebuildIDTables()
                        GT:InventoryUpdate("Filters " .. expansion .. " " .. category .. " " .. itemData.name .. " option clicked", true)
                    end,
                    order = itemData.order
                }
                if itemData.desc then
                    filterOptions.args[expansion].args[category].args[tostring(itemData.id)].desc = itemData.desc
                end
            end
        end
    end
end

local tempAliasCharacter = ""
local tempAliasName = ""

local aliasOptions = {
    type = "group",
    name = "Alias",
    args = {
        aliasHeading = {
            type = "description",
            name =
            "Input desired character aliases below.\n\nIf enabled, the alias will be displayed above each character column.\n\nIt is recommended that the first character of each alias be distinct, as in some situations only the first character of an alias will be displayed.\n",
            width = "full",
            fontSize = "medium",
            order = 1
        },
        aliasHeading2 = {
            type = "description",
            name = "Leave alias field blank to remove a characters alias.",
            width = "full",
            fontSize = "medium",
            order = 2
        },
        characterInput = {
            type = "input",
            name = "Character Name",
            width = "Normal",
            usage = "Enter character name",
            validate = function(_, key)
                if string.match(key, "[%p%s%d]+") then return false end
                return true
            end,
            get = function() return tempAliasCharacter end,
            set = function(_, key)
                tempAliasCharacter = key
            end,
            order = 10
        },
        aliasInput = {
            type = "input",
            name = "Alias",
            width = "Normal",
            usage = "Enter alias",
            get = function() return tempAliasName end,
            set = function(_, key)
                if key == "" then
                    tempAliasName = "Reset This Alias"
                else
                    tempAliasName = key
                end
            end,
            order = 11
        },
        addAlias = {
            type = "execute",
            name = "Add Alias",
            width = "Normal",
            func = function()
                --check if any aliases exist, if none exist, add the alias to the table.
                --If there are any aliases, we find check if the requested alias exists and update or remove it.
                --if no alias was supplied, check if an alias exists for that character and remove it.
                if tempAliasCharacter ~= "" and tempAliasName ~= "" then
                    if #GT.db.profile.Aliases > 0 then
                        local exists = 0
                        for index, aliases in pairs(GT.db.profile.Aliases) do
                            if aliases.name == tempAliasCharacter then
                                exists = index
                            end
                        end
                        if exists > 0 then
                            if tempAliasName == "Reset This Alias" then
                                table.remove(GT.db.profile.Aliases, index)
                                GT:UpdateAliases(tempAliasCharacter)
                            else
                                GT.db.profile.Aliases[exists].alias = tempAliasName
                                GT:UpdateAliases()
                            end
                        else
                            local aliasTable = { name = tempAliasCharacter, alias = tempAliasName }
                            table.insert(GT.db.profile.Aliases, aliasTable)
                            GT:UpdateAliases()
                        end
                    else
                        local aliasTable = { name = tempAliasCharacter, alias = tempAliasName }
                        table.insert(GT.db.profile.Aliases, aliasTable)
                        GT:UpdateAliases()
                    end
                    tempAliasCharacter = ""
                    tempAliasName = ""
                elseif tempAliasCharacter ~= "" and tempAliasName == "" then
                    for index, aliases in pairs(GT.db.profile.Aliases) do
                        if aliases.name == tempAliasCharacter then
                            table.remove(GT.db.profile.Aliases, index)
                            GT:UpdateAliases(tempAliasCharacter)
                            AceConfigRegistry:NotifyChange("GT/Alias")
                        end
                    end
                end
            end,
            order = 12
        },
        aliasHeader = {
            type = "header",
            name = "Active Aliases",
            order = 14
        },
    }
}

function GT:UpdateAliases(removeCharacter)
    if removeCharacter then
        aliasOptions.args[removeCharacter] = nil
    else
        for index, aliasInfo in ipairs(GT.db.profile.Aliases) do
            aliasOptions.args[aliasInfo.name] = {
                type = "description",
                name = aliasInfo.name .. " = " .. aliasInfo.alias,
                fontSize = "large",
                order = (1000 + index)
            }
        end
    end
    AceConfigRegistry:NotifyChange("GT/Alias")
end

function GT:CreateCustomFilterOptions()
    if GT.db.profile.CustomFilters then
        for arg, data in pairs(filterOptions.args.custom.args) do
            if data.order > 1000 then
                filterOptions.args.custom.args[arg] = nil
            end
        end
        for id, value in pairs(GT.db.profile.CustomFiltersTable) do
            --Create a local item to get data from the server
            local itemID = tonumber(id)
            local item = Item:CreateFromItemID(itemID)
            GT.Debug("Create Custom Filter Options", 2, itemID)
            --Waits for the data to be returned from the server
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(function()
                    local itemName = item:GetItemName()
                    filterOptions.args.custom.args[itemName] = {
                        type = "toggle",
                        name = itemName,
                        image = function() return GetItemIcon(tonumber(id)) end,
                        get = function() return GT.db.profile.CustomFiltersTable[id] end,
                        set = function(_, key)
                            if key then
                                GT.db.profile.CustomFiltersTable[id] = key
                            else
                                GT.db.profile.CustomFiltersTable[id] = false
                            end

                            GT:RebuildIDTables()
                            GT:InventoryUpdate("Filters Custom " .. itemName .. " option clicked", true)
                        end,
                        order = (id + 1000)
                    }
                    AceConfigRegistry:NotifyChange("GT/Filter")
                end)
            else
                ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. ":|r " .. id .. " is not a valid item ID")
            end
        end
    end
end

function GT:RefreshConfig(event, db, profile)
    GT.Debug("Refresh Config", 1, event, profile, db.profile.General.enable, GT.Enabled)
    if db.profile.General.enable and not GT.Enabled and event == "OnProfileChanged" then
        GT.Enabled = true
        GT:OnEnable()
    end
    if not db.profile.General.enable and GT.Enabled and event == "OnProfileChanged" then
        GT.Enabled = false
        GT:OnDisable()
    end

    GT.baseFrame.backdrop:ClearAllPoints()
    GT.baseFrame.backdrop:SetPoint(
        GT.db.profile.General.relativePoint,
        UIParent,
        GT.db.profile.General.relativePoint,
        GT.db.profile.General.xPos,
        GT.db.profile.General.yPos
    )

    GT:RebuildIDTables()
    GT:ClearDisplay()
    GT:FiltersButton()
    GT:InventoryUpdate("Refresh Config", true)
    GT:CreateProfilesList()
end

function GatheringTracker_OnAddonCompartmentClick(addonName, button)
    if (button == "LeftButton") then
        GT:ToggleGatheringTracker()
    elseif (button == "RightButton") then
        InterfaceOptionsFrame_OpenToCategory(GT.metaData.name)
        InterfaceOptionsFrame_OpenToCategory(GT.metaData.name)
    end
end

local function UpdateChangedorRemovedSavedVariables()
    --Change debug to int instead of bool
    if type(GT.db.profile.General.debugOption) == "boolean" then
        GT.db.profile.General.debugOption = 0
    end

    --Change groupType to int from bool
    if type(GT.db.profile.General.groupType) == "boolean" then
        if GT.db.profile.General.groupType then
            GT.db.profile.General.groupType = 1
        else
            GT.db.profile.General.groupType = 0
        end
    end

    if GT.db.profile.Filters["gold"] then
        GT.db.profile.Filters["gold"] = nil
        GT.db.profile.Filters[1] = true
    end

    if GT.db.profile.Filters["bag"] then
        GT.db.profile.Filters["bag"] = nil
        GT.db.profile.Filters[2] = true
    end
end

function Config:OnInitialize()
    --have to check if tsm is loaded before we create the options so that we can use that variable in the options.
    GT.tsmLoaded = IsAddOnLoaded("TradeSkillMaster")
    GT.ElvUI = IsAddOnLoaded("ElvUI")

    GT.db = LibStub("AceDB-3.0"):New("GatheringTrackerDB", GT.defaults, true)
    GT.db.RegisterCallback(GT, "OnProfileChanged", "RefreshConfig")
    GT.db.RegisterCallback(GT, "OnProfileDeleted", "CreateProfilesList")
    GT.db.RegisterCallback(GT, "OnProfileCopied", "RefreshConfig")
    GT.db.RegisterCallback(GT, "OnProfileReset", "RefreshConfig")

    if GT.db.profile.General.unlock then
        GT.db.profile.General.unlock = false
    end

    --if TSM is not loaded set tsmPrice Option to none.
    if not GT.tsmLoaded then
        GT.db.profile.General.tsmPrice = 0
        GT.db.profile.General.perItemPrice = false
    else
        GT:SetTSMPriceSource()
    end

    UpdateChangedorRemovedSavedVariables()

    AceConfigRegistry:RegisterOptionsTable(GT.metaData.name, generalOptions)
    GT.Options.Main = AceConfigDialog:AddToBlizOptions(GT.metaData.name, GT.metaData.name)
    GT.Options.Main:SetScript("OnHide", GT.OptionsHide)

    AceConfigRegistry:RegisterOptionsTable("GT/Filter", filterOptions)
    GT.Options.Filter = AceConfigDialog:AddToBlizOptions("GT/Filter", "Filter", GT.metaData.name)
    GT.Options.Filter:SetScript("OnHide", GT.OptionsHide)

    AceConfigRegistry:RegisterOptionsTable("GT/Alias", aliasOptions)
    GT.Options.Alias = AceConfigDialog:AddToBlizOptions("GT/Alias", "Alias", GT.metaData.name)
    GT.Options.Alias:SetScript("OnHide", GT.OptionsHide)

    AceConfigRegistry:RegisterOptionsTable("GT/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(GT.db))
    GT.Options.Profiles = AceConfigDialog:AddToBlizOptions("GT/Profiles", "Profiles", GT.metaData.name)
    GT.Options.Profiles:SetScript("OnHide", GT.OptionsHide)

    GT:UpdateAliases()
    GT:CreateCustomFilterOptions()

    local function openOptions()
        InterfaceOptionsFrame_OpenToCategory(GT.metaData.name)
        InterfaceOptionsFrame_OpenToCategory(GT.metaData.name)
    end

    SLASH_GatheringTracker1 = "/gatheringtracker"
    SLASH_GatheringTracker2 = "/gt"
    SlashCmdList.GatheringTracker = openOptions

    GT.Player = UnitName("player")

    --register font and sound with LSM
    media:Register("font", "Fira Mono Medium", "Interface\\Addons\\GatheringTracker\\Media\\Fonts\\FiraMono-Medium.ttf", media.LOCALE_BIT_western + media.LOCALE_BIT_ruRU)
    media:Register("sound", "Auction Window Open", 567482)
    media:Register("sound", "Auction Window Close", 567499)
    media:Register("sound", "Auto Quest Complete", 567476)
    media:Register("sound", "Level Up", 567431)
    media:Register("sound", "Player Invite", 567451)
    media:Register("sound", "Raid Warning", 567397)
    media:Register("sound", "Ready Check", 567409)
    media:Register("sound", "Murloc Aggro", 556000)
    media:Register("sound", "Map Ping", 567416)
    media:Register("sound", "Bonk 1", 568956)
    media:Register("sound", "Bonk 2", 569179)
    media:Register("sound", "Bonk 3", 569569)

    GT.Enabled = GT.db.profile.General.enable
    if not GT.Enabled then
        GT:OnDisable()
    end

    GT:SetChatType()

    --Pause Notifications to prevent spam after reloading the UI
    GT.NotificationPause = true

    GT:RebuildIDTables()
    GT:CreateBaseFrame("Config:OnInitialize")
end
