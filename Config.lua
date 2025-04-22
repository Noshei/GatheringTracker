---@class GT : AceAddon-3.0, AceEvent-3.0, AceConfigRegistry-3.0, AceConfigDialog-3.0
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

GT.media = media

-- Localize global functions
local ipairs = ipairs
local math = math
local next = next
local pairs = pairs
local string = string
local table = table
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

GT.defaults = {
    profile = {
        General = {
            fixSettings = 0,
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
            iconOpacity = 100,
            textColor = { 1, 1, 1, 1 },
            textSize = 20,
            textFont = "Fira Mono Medium",
            totalColor = { 0.098, 1, 0.078, 1 },
            totalSize = 20,
            totalFont = "Fira Mono Medium",
            includeBank = false,
            includeReagent = false,
            includeWarband = false,
            tsmPrice = 0,
            ignoreAmount = 0,
            perItemPrice = false,
            debugOption = 0,
            rarityBorder = true,
            multiColumn = false,
            numRows = 1,
            instanceHide = false,
            groupHide = false,
            showDelve = false,
            showFollower = false,
            combatHide = false,
            itemsPerHour = false,
            goldPerHour = false,
            collapseDisplay = false,
            collapseTime = 2,
            sessionItems = false,
            sessionOnly = false,
            itemTooltip = false,
            alertsEnable = false,
            totalsRow = true,
        },
        Alerts = {
        },
        Filters = {
        },
        CustomFiltersTable = {
        },
        miniMap = {
            enable = false,
        },
        GroupMode = {
            enable = false,
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
                    dialogControl = "NW_CheckBox",
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
                    dialogControl = "NW_CheckBox",
                    name = "Unlock Frame",
                    width = 1.70,
                    get = function() return GT.db.profile.General.unlock end,
                    set = function(_, key)
                        GT.db.profile.General.unlock = key
                        GT:ToggleBaseLock(key)
                    end,
                    order = 2
                },
                miniMap = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Minimap Button",
                    desc = "Enable this to show the minimap button.\n" ..
                        "|cff8080ffLeft Click|r shows filters menu.\n" ..
                        "|cff8080ffRight Click|r opens the addon options.\n" ..
                        "|cff8080ffShift + Left Click|r resets Session Data.\n" ..
                        "|cff8080ffShift + Right-Click|r to reset Alert Triggers",
                    width = 1.70,
                    get = function() return GT.db.profile.miniMap.enable end,
                    set = function(_, key)
                        GT.db.profile.miniMap.enable = key
                        GT:MinimapHandler(key)
                    end,
                    order = 3
                },
                buttonHeader = {
                    type = "header",
                    name = "Filter Button",
                    order = 10
                },
                filtersButton = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Filters Button",
                    desc = "If Enabled a button will be shown on screen that can be used to quickly change filters.\n" ..
                        "|cff8080ffLeft Click|r shows filters menu.\n" ..
                        "|cff8080ffRight Click|r clears all filters.\n" ..
                        "|cff8080ffShift + Left Click|r resets Session Data.\n" ..
                        "|cff8080ffShift + Right-Click|r to reset Alert Triggers",
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
                    dialogControl = "NW_CheckBox",
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
                    dialogControl = "NW_Slider",
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
                    dialogControl = "NW_Slider",
                    name = "Fade Out Delay",
                    desc = "This configures how long after the mouse leaves the button before it fades out.\n" ..
                        "Default is 0.5.",
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
                    name = "Auto Hide Options",
                    order = 100
                },
                groupHide = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Hide in Group",
                    desc = "When selected the display will be hidden when you are in a group.\n" ..
                        "Delves and Follower Dungeons count as groups.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.groupHide end,
                    set = function(_, key)
                        GT.db.profile.General.groupHide = key
                        GT:SetDisplayState()
                    end,
                    order = 110
                },
                instanceHide = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Hide in Instance Content",
                    desc = "When selected the display will be hidden in instance content.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.instanceHide end,
                    set = function(_, key)
                        GT.db.profile.General.instanceHide = key
                        GT:SetDisplayState()
                    end,
                    order = 120
                },
                showDelve = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Show In Delves",
                    desc = "When selected the display will be shown in Delves regardless of how Hide in Instance Content and Hide in Group are configured.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.showDelve end,
                    set = function(_, key)
                        GT.db.profile.General.showDelve = key
                        GT:SetDisplayState()
                    end,
                    disabled = function()
                        if GT.db.profile.General.instanceHide or GT.db.profile.General.groupHide then
                            return false
                        else
                            return true
                        end
                    end,
                    hidden = function()
                        if GT.gameVersion == "retail" then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 120
                },
                showFollower = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Show in Follower Dungeons",
                    desc = "When selected the display will be shown in Follower Dungeons regardless of how Hide in Instance Content and Hide in Group are configured.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.showFollower end,
                    set = function(_, key)
                        GT.db.profile.General.showFollower = key
                        GT:SetDisplayState()
                    end,
                    disabled = function()
                        if GT.db.profile.General.instanceHide or GT.db.profile.General.groupHide then
                            return false
                        else
                            return true
                        end
                    end,
                    hidden = function()
                        if GT.gameVersion == "retail" then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 130
                },
                combatHide = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Hide in Combat",
                    desc = "When selected the display will be hidden when you enter combat.\n" ..
                        "This overrides the options for Show in Delves and Show in Follower Dungeons.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.combatHide end,
                    set = function(_, key)
                        GT.db.profile.General.combatHide = key
                        if key then
                            GT:RegisterEvent("PLAYER_REGEN_DISABLED")
                            GT:RegisterEvent("PLAYER_REGEN_ENABLED")
                        end
                    end,
                    order = 140
                },
                header2 = {
                    type = "header",
                    name = "Collapse Display",
                    order = 200
                },
                collapseDisplay = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Collapse Display",
                    desc = "When selected the display will be collapsed to only display the total rows.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.collapseDisplay end,
                    set = function(_, key)
                        GT.db.profile.General.collapseDisplay = key
                        GT:CollapseManager(key)
                    end,
                    disabled = function()
                        if GT.db.profile.General.totalsRow then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 210
                },
                collapseTime = {
                    type = "range",
                    dialogControl = "NW_Slider",
                    name = "Collapse Delay",
                    desc = "This configures how long after the mouse leaves the display area before it clopases to the total rows.\nDefault is 2.",
                    min = 0,
                    max = 10,
                    step = 0.5,
                    width = 1.40,
                    get = function() return GT.db.profile.General.collapseTime or 2 end,
                    set = function(_, key) GT.db.profile.General.collapseTime = key end,
                    disabled = function()
                        if GT.db.profile.General.collapseDisplay then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 215
                },
                header3 = {
                    type = "header",
                    name = "Other",
                    order = 300
                },
                totalsRow = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Totals Row",
                    desc = "If selected the totals row will be displayed.\n\n" ..
                        "|cffff0000When disabled the following options will also be disabled:|r\n" ..
                        " - Collapse Delay\n" ..
                        " - Totals Color/Size/Font\n" ..
                        " - Total Items Alerts",
                    width = 1.70,
                    get = function() return GT.db.profile.General.totalsRow end,
                    set = function(_, key)
                        GT.db.profile.General.totalsRow = key
                        if not key then
                            GT.db.profile.General.collapseDisplay = key
                            GT:CollapseManager(key)
                        end
                        GT:RebuildDisplay("Display Totals Row Changed")
                    end,
                    order = 320
                },
                allFiltered = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display All Filtered Items",
                    desc =
                        "When selected all selected filtered items will be displayed, including those with 0 count.\n\n" ..
                        "Not recommended to be used with a large number of enabled filters as it will cause significant lag.\n\n" ..
                        "|cffff0000Automatically disables with over 500 filters selected.|r",
                    width = 1.70,
                    get = function() return GT.db.profile.General.allFiltered end,
                    set = function(_, key)
                        GT.db.profile.General.allFiltered = key
                        GT:InventoryUpdate("Toggle Display All", false)
                    end,
                    disabled = function()
                        if #GT.IDs > 500 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 321
                },
                itemTooltip = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Item Tooltip",
                    desc =
                        "When selected the item tooltip will be displayed when mousing over an items icon.\n\n" ..
                        "Interacts poorly with the Collapse Display option, not recommended to use both.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.itemTooltip end,
                    set = function(_, key)
                        GT.db.profile.General.itemTooltip = key
                        GT:RebuildDisplay("Item Tooltip Option Changed")
                    end,
                    order = 322
                },
            },
        },
        LookandFeel = {
            type = "group",
            name = "Look and Feel",
            order = 2,
            args = {
                header3 = {
                    type = "header",
                    name = "Display Options",
                    order = 200
                },
                tsmPrice = {
                    type = "select",
                    dialogControl = "NW_Dropdown",
                    name = "Price Source",
                    desc = "Select the desired price source, or none to disable price information.\n" ..
                        "|cffff0000Supported addon required.|r\n\n" ..
                        "Supports:\n" ..
                        "TradeSkillMaster\n" ..
                        "RECrystallize\n" ..
                        "Auctionator",
                    width = 1.70,
                    values = function()
                        local options = {}
                        options[0] = "None"
                        if not GT.priceSources then
                            return options
                        end
                        if GT.priceSources["TradeSkillMaster"] then
                            options[1] = "TSM - DBMarket"
                            options[2] = "TSM - DBMinBuyout"
                            options[3] = "TSM - DBHistorical"
                            options[4] = "TSM - DBRegionMinBuyoutAvg"
                            options[5] = "TSM - DBRegionMarketAvg"
                            options[6] = "TSM - DBRegionHistorical"
                        end
                        if GT.priceSources["RECrystallize"] then
                            options[10] = "RECrystallize"
                        end
                        if GT.priceSources["Auctionator"] then
                            options[20] = "Auctionator"
                        end
                        return options
                    end,
                    get = function() return GT.db.profile.General.tsmPrice end,
                    set = function(_, key)
                        GT.db.profile.General.tsmPrice = key
                        if GT.db.profile.General.tsmPrice == 0 then
                            GT.db.profile.General.perItemPrice = false
                            GT.db.profile.General.goldPerHour = false
                        end
                        GT:RebuildDisplay("TSM Price Source Option Changed")
                    end,
                    disabled = function()
                        if not GT.priceSources then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 201
                },
                perItemPrice = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Per Item Price",
                    desc = "If selected the price for 1 of each item will be displayed.\n" ..
                        "Price Source is required for this option to be enabled.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.perItemPrice end,
                    set = function(_, key)
                        GT.db.profile.General.perItemPrice = key
                        GT:RebuildDisplay("Display Per Item Price Changed")
                    end,
                    disabled = function()
                        if not GT.priceSources or GT.db.profile.General.tsmPrice == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 202
                },
                ignoreAmount = {
                    type = "range",
                    dialogControl = "NW_Slider",
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
                    dialogControl = "NW_CheckBox",
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
                includeReagent = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Include Reagent Bank",
                    desc = "If selected displayed values will include items in your reagent bank.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.includeReagent end,
                    set = function(_, key)
                        GT.db.profile.General.includeReagent = key
                        GT:InventoryUpdate("Include Reagent", true)
                    end,
                    hidden = function()
                        if GT.gameVersion == "retail" then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 205
                },
                includeWarband = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Include Warband Bank",
                    desc = "If selected displayed values will include items in your Warband bank.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.includeWarband end,
                    set = function(_, key)
                        GT.db.profile.General.includeWarband = key
                        GT:InventoryUpdate("Include Warband", true)
                    end,
                    hidden = function()
                        if GT.gameVersion == "retail" then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 206
                },
                header2 = {
                    type = "header",
                    name = "Session Display Options",
                    order = 250
                },
                sessionItems = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Session Item Counts",
                    desc = "If selected session item counts will be displayed in the column to the right of the item count.\n" ..
                        "Price data (if enabled) is not displayed for session data.\n\n" ..
                        "|cffff0000Session data not displayed in group mode.|r",
                    width = 1.70,
                    get = function() return GT.db.profile.General.sessionItems end,
                    set = function(_, key)
                        GT.db.profile.General.sessionItems = key
                        if not key then
                            GT.db.profile.General.sessionOnly = false
                        end
                        GT:RebuildDisplay("Display Session Item Counts Changed")
                    end,
                    order = 251
                },
                sessionOnly = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Only Display Session Data",
                    desc = "If selected only the session data will be displayed and selected items will only display if collected during the session.\n" ..
                        "Price data (if enabled) is displayed for the session data.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.sessionOnly end,
                    set = function(_, key)
                        GT.db.profile.General.sessionOnly = key
                        GT:RebuildDisplay("Only Display Session Data Changed")
                    end,
                    disabled = function()
                        if not GT.db.profile.General.sessionItems then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 252
                },
                itemsPerHour = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Items Per Hour",
                    desc = "If selected an estimated items gathered per hour will be displayed.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.itemsPerHour end,
                    set = function(_, key)
                        GT.db.profile.General.itemsPerHour = key
                        GT:RebuildDisplay("Items Per Hour Changed")
                    end,
                    order = 255
                },
                goldPerHour = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Display Gold Per Hour",
                    desc = "If selected an estimated gold per hour will be displayed based on the value of items gathered.\n" ..
                        "Price Source is required for this option to be enabled.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.goldPerHour end,
                    set = function(_, key)
                        GT.db.profile.General.goldPerHour = key
                        GT:RebuildDisplay("Gold Per Hour Changed")
                    end,
                    disabled = function()
                        if not GT.priceSources or GT.db.profile.General.tsmPrice == 0 then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 256
                },
                perHourReset = {
                    type = "execute",
                    name = "Reset Session Data",
                    desc = "Clicking this will reset the session data.",
                    width = 1.70,
                    func = function()
                        GT:ResetSession()
                    end,
                    disabled = function()
                        if GT.db.profile.General.itemsPerHour or GT.db.profile.General.goldPerHour or
                            GT.db.profile.General.sessionItems then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 257
                },
                header4 = {
                    type = "header",
                    name = "Columns",
                    order = 300
                },
                multiColumn = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Multiple Columns",
                    desc = "Enables the display to use multiple columns.",
                    width = 1.70,
                    get = function() return GT.db.profile.General.multiColumn end,
                    set = function(_, key)
                        GT.db.profile.General.multiColumn = key
                        GT:AllignRows()
                        GT:AllignColumns()
                    end,
                    order = 301
                },
                numRows = {
                    type = "range",
                    dialogControl = "NW_Slider",
                    name = "Max Rows Per Column",
                    desc = "Set the maximum number of rows to be displayed per column.",
                    min = 1,
                    max = 50,
                    step = 1,
                    width = 1.70,
                    get = function() return GT.db.profile.General.numRows or 1 end,
                    set = function(_, key)
                        GT.db.profile.General.numRows = key
                        if not GT.db.profile.General.collapseDisplay then
                            GT:AllignRows()
                            GT:AllignColumns()
                        end
                    end,
                    disabled = function()
                        if not GT.db.profile.General.multiColumn then
                            return true
                        else
                            return false
                        end
                    end,
                    order = 302
                },
                header5 = {
                    type = "header",
                    name = "Icon",
                    order = 400
                },
                iconWidth = {
                    type = "range",
                    dialogControl = "NW_Slider",
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
                            GT:SetDisplayFrameWidth()
                        end
                    end,
                    order = 401
                },
                iconHeight = {
                    type = "range",
                    dialogControl = "NW_Slider",
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
                    order = 402
                },
                iconOpacity = {
                    type = "range",
                    dialogControl = "NW_Slider",
                    name = "Icon Opacity",
                    min = 0,
                    max = 100,
                    step = 1,
                    width = 1.70,
                    get = function() return GT.db.profile.General.iconOpacity or 100 end,
                    set = function(_, key)
                        GT.db.profile.General.iconOpacity = key
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            itemFrame.icon:SetAlpha(GT.db.profile.General.iconOpacity / 100)

                            if itemFrame.iconRarity then
                                itemFrame.iconRarity:SetAlpha(GT.db.profile.General.iconOpacity / 100)
                            end

                            if itemFrame.iconQuality then
                                itemFrame.iconQuality:SetAlpha(GT.db.profile.General.iconOpacity / 100)
                            end
                        end
                    end,
                    order = 403
                },
                rarityBorder = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
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
                                    GT:DisplayFrameRarity(itemFrame, iconRarity)
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
                    order = 404
                },
                header6 = {
                    type = "header",
                    name = "Text",
                    order = 500
                },
                textColor = {
                    type = "color",
                    name = "Text Color",
                    hasAlpha = true,
                    get = function()
                        local c = GT.db.profile.General.textColor
                        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        GT.db.profile.General.textColor = { r, g, b, a }
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID < 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetVertexColor(unpack(GT.db.profile.General.textColor))
                                end
                            end
                        end
                    end,
                    order = 501
                },
                textSize = {
                    type = "range",
                    dialogControl = "NW_Slider",
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
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end

                                local frameHeight = math.max(GT.db.profile.General.iconHeight, key)
                                itemFrame:SetHeight(frameHeight + 3)
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 502
                },
                textFont = {
                    type = "select",
                    dialogControl = 'NW_Font',
                    name = "Text Font",
                    width = 1.20,
                    values = media:HashTable("font"),
                    get = function() return GT.db.profile.General.textFont end,
                    set = function(_, key)
                        GT.db.profile.General.textFont = key
                        GT.Display.ColumnSize = {}
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID < 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    order = 503
                },
                totalColor = {
                    type = "color",
                    name = "Total Color",
                    hasAlpha = true,
                    get = function()
                        local c = GT.db.profile.General.totalColor
                        return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1
                    end,
                    set = function(_, r, g, b, a)
                        GT.db.profile.General.totalColor = { r, g, b, a }
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID >= 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetVertexColor(unpack(GT.db.profile.General.totalColor))
                                end
                            end
                        end
                    end,
                    disabled = function()
                        if GT.db.profile.General.totalsRow then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 504
                },
                totalSize = {
                    type = "range",
                    dialogControl = "NW_Slider",
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
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end

                                local frameHeight = math.max(GT.db.profile.General.iconHeight, key)
                                itemFrame:SetHeight(frameHeight + 3)
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    disabled = function()
                        if GT.db.profile.General.totalsRow then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 505
                },
                totalFont = {
                    type = "select",
                    dialogControl = 'NW_Font',
                    name = "Total Font",
                    width = 1.20,
                    values = media:HashTable("font"),
                    get = function() return GT.db.profile.General.totalFont end,
                    set = function(_, key)
                        GT.db.profile.General.totalFont = key
                        GT.Display.ColumnSize = {}
                        for itemID, itemFrame in pairs(GT.Display.Frames) do
                            if itemID >= 9999999998 then
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    textFrame:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            else
                                for textIndex, textFrame in ipairs(itemFrame.text) do
                                    GT:CheckColumnSize(textIndex, textFrame, itemID)
                                end
                            end
                        end
                        GT:AllignColumns()
                    end,
                    disabled = function()
                        if GT.db.profile.General.totalsRow then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 506
                },
            },
        },
        Alerts = {
            type = "group",
            name = "Alerts",
            childGroups = "tree",
            order = 4,
            args = {
                alertsEnable = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = "Enable Alerts",
                    desc = "Check to enable Alerts",
                    width = 1.7,
                    get = function() return GT.db.profile.General.alertsEnable end,
                    set = function(_, key)
                        GT.db.profile.General.alertsEnable = key
                    end,
                    order = 101,
                },
                addItem = {
                    type = "execute",
                    name = "Select Item for Alerts",
                    desc = "Click to select what item to enable for Alerts.",
                    width = 1.7,
                    func = function()
                        GT:GenerateAlertsMenu()
                    end,
                    disabled = function()
                        if GT.db.profile.General.alertsEnable then
                            return false
                        else
                            return true
                        end
                    end,
                    order = 102,
                },
            },
        },
        Debug = {
            type = "group",
            name = "Debug",
            order = 5,
            args = {
                header5 = {
                    type = "header",
                    name = "Debug",
                    order = 10000
                },
                debugOption = {
                    type = "select",
                    dialogControl = "NW_Dropdown",
                    name = "Debug",
                    desc = "This is for debugging the addon, do NOT enable, it is spammy.",
                    width = 1.70,
                    values = {
                        [0] = "Off",
                        [1] = "Limited",
                        [2] = "Info",
                        [3] = "Debug",
                        [4] = "Trace (Very Spammy)",
                        [5] = "Notification Spam",
                        [6] = "Mass Item Spam"
                    },
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

local function InitializeAlert(Item, alertType, typeCount, DB)
    local Alert = Item:AddAlert(alertType, typeCount, DB.triggerValue)
    Alert:SetEnabled(DB.enable)
    Alert:SetTriggerType(DB.triggerType)
    Alert:SetTriggerMultiple(DB.triggerMultiple)
    Alert:SetTriggerMultiplier(DB.triggerValue)
    if alertType == "Audio" then
        Alert:SetAlertSettings({ tiggerSound = DB.tiggerSound or "Auction Window Open" })
    elseif alertType == "Highlight" then
        Alert:SetAlertSettings({ highlightBorder = DB.highlightBorder, highlightColor = DB.highlightColor })
    elseif alertType == "Screen Flash" then
        Alert:SetAlertSettings({ flashDuration = DB.flashDuration, flashColor = DB.flashColor })
    end

    return Alert
end

local function GetAlertOptionsTable(itemData, alertType, typeCount, Item, Alert)
    local DB = GT.db.profile.Alerts[itemData.id].alerts[alertType][typeCount]
    local typeName = alertType .. "_" .. typeCount

    local options = {
        type = "group",
        name = alertType .. " Alert " .. typeCount,
        order = DB.order + typeCount,
        inline = true,
        disabled = function()
            if not GT.db.profile.General.alertsEnable then
                return true
            end
            if not GT.db.profile.Alerts[itemData.id].enable then
                return true
            end
            if not DB.enable then
                return true
            end
            return false
        end,
        args = {
            enableAlert = {
                type = "toggle",
                dialogControl = "NW_CheckBox",
                name = "Enable " .. alertType .. " Alert",
                desc = "Check to enable " .. alertType .. " alert for " .. itemData.name,
                width = "normal",
                get = function()
                    if DB.enable then
                        return DB.enable
                    end
                    return false
                end,
                set = function(_, key)
                    DB.enable = key
                    Alert:SetEnabled(key)
                end,
                disabled = function()
                    if not GT.db.profile.General.alertsEnable then
                        return true
                    end
                    if not GT.db.profile.Alerts[itemData.id].enable then
                        return true
                    end
                    return false
                end,
                order = 1
            },
            removeAlert = {
                type = "execute",
                name = "Delete Alert",
                desc = "Click to delete " .. alertType .. " Alert " .. typeCount,
                width = "normal",
                confirm = true,
                func = function()
                    local alertOptions = generalOptions.args.Alerts.args[tostring(itemData.id)].args
                    local alertTypeCount = #GT.db.profile.Alerts[itemData.id].alerts[alertType]
                    alertOptions[typeName] = nil
                    table.remove(GT.db.profile.Alerts[itemData.id].alerts[alertType], typeCount)
                    if #GT.db.profile.Alerts[itemData.id].alerts[alertType] == 0 then
                        GT.db.profile.Alerts[itemData.id].alerts[alertType] = nil
                    end

                    Item:RemoveAlert(Alert)

                    if typeCount < alertTypeCount then
                        for index = typeCount + 1, alertTypeCount do
                            local alertToUpdate = Item:GetAlert(alertType, index)
                            alertToUpdate:SetTypeCount(index - 1)
                            alertOptions[alertType .. "_" .. index] = nil
                            alertOptions[alertType .. "_" .. (index - 1)] = GetAlertOptionsTable(itemData, alertType, (index - 1), Item, Alert)
                        end
                    end
                    AceConfigRegistry:NotifyChange(GT.metaData.name)
                end,
                disabled = function()
                    if not GT.db.profile.General.alertsEnable then
                        return true
                    end
                    if not GT.db.profile.Alerts[itemData.id].enable then
                        return true
                    end
                    return false
                end,
                order = 2,
            },
            triggerValue = {
                type = "input",
                name = "Trigger Value",
                width = "Normal",
                desc = "Enter value the alert should trigger at.\n\n" ..
                    "Uses session value when |cffffd100Only Display Session Data|r is enabled.\n\n",
                usage = "Must be a whole number",
                validate = function(_, key)
                    if (string.match(key, "[^%d]") or key == '') then
                        return false
                    end
                    return true
                end,
                get = function() return tostring(DB.triggerValue) end,
                set = function(_, key)
                    if key == '' or key == nil then
                        key = 0
                    end
                    DB.triggerValue = tonumber(key)
                    Alert:SetTriggerValue(tonumber(key))
                end,
                order = 3
            },
            triggerType = {
                type = "select",
                dialogControl = "NW_Dropdown",
                name = "Trigger Type",
                width = "Normal",
                desc = "Select which type of value should be triggered off of.",
                values = function()
                    local values = {}
                    values[1] = "Item Count"
                    if GT.priceSources and GT.db.profile.General.tsmPrice > 0 then
                        values[2] = "Gold Value"
                    end
                    return values
                end,
                get = function() return DB.triggerType end,
                set = function(_, key)
                    DB.triggerType = key
                    Alert:SetTriggerType(key)
                end,
                order = 4
            },
            triggerMultiple = {
                type = "toggle",
                dialogControl = "NW_CheckBox",
                name = "Trigger on Multiplier",
                desc = "When enabled the alert will trigger on multiples of the Trigger Value.\n\n" ..
                    "Example: If Trigger Value is 100, this option will cause the alert to trigger on 100, 200, 300, etc.",
                width = "Normal",
                get = function() return DB.triggerMultiple end,
                set = function(_, key)
                    DB.triggerMultiple = key
                    Alert:SetTriggerMultiple(key)
                    Alert:SetTriggerMultiplier(DB.triggerValue)
                end,
                order = 5
            },
        },
    }
    if alertType == "Audio" then
        options.args.tiggerSound = {
            type = "select",
            dialogControl = "NW_Sound",
            name = "Alert Sound",
            desc = "The sound that plays when the alert is triggered.\n\n" ..
                "Default: Auction Window Open",
            width = "Normal",
            values = media:HashTable("sound"),
            get = function()
                local sound = "Auction Window Open"
                if media:IsValid("sound", DB.tiggerSound) then
                    sound = DB.tiggerSound
                end
                return sound
            end,
            set = function(_, key)
                DB.tiggerSound = key
                Alert:SetAlertSettings({ tiggerSound = DB.tiggerSound })
            end,
            order = 100
        }
    elseif alertType == "Highlight" then
        options.args.highlightBorder = {
            type = "select",
            dialogControl = "NW_Highlight",
            name = "Highlight Texture",
            desc = "The highlight texture that is displayed when an the alert is triggered.",
            width = "Normal",
            values = {
                ["Border 1"] = "Interface\\Addons\\GatheringTracker\\Media\\border1",
                ["Border 2"] = "Interface\\Addons\\GatheringTracker\\Media\\border2",
                ["Top/Bottom 1"] = "Interface\\Addons\\GatheringTracker\\Media\\border3",
                ["Top/Bottom 2"] = "Interface\\Addons\\GatheringTracker\\Media\\border4",
            },
            get = function() return DB.highlightBorder end,
            set = function(_, key)
                DB.highlightBorder = key
                Alert:SetAlertSettings({ highlightBorder = DB.highlightBorder, highlightColor = DB.highlightColor })
            end,
            order = 101
        }
        options.args.highlightColor = {
            type = "color",
            name = "Highlight Color",
            width = "Normal",
            hasAlpha = true,
            get = function()
                local c = DB.highlightColor
                return c[1], c[2], c[3], c[4]
            end,
            set = function(_, r, g, b, a)
                DB.highlightColor = { r, g, b, a }
                Alert:SetAlertSettings({ highlightBorder = DB.highlightBorder, highlightColor = DB.highlightColor })
                AceConfigRegistry:NotifyChange(GT.metaData.name)
            end,
            order = 102
        }
        options.args.highlightPreview = {
            type = "description",
            dialogControl = "NW_Label",
            name = "",
            width = "Normal",
            image = function()
                local atlas = GT.HighlightTextures[DB.highlightBorder].atlas
                return atlas, 108, 27
            end,
            imageCoords = function()
                local data = {}
                table.insert(data, "texture")
                table.insert(data, DB.highlightColor)
                return data
            end,
            order = 103
        }
    elseif alertType == "Screen Flash" then
        options.args.flashDuration = {
            type = "range",
            dialogControl = "NW_Slider",
            name = "Screen Flash Duration",
            min = 0.5,
            max = 20,
            softMax = 10,
            step = 0.1,
            width = "Normal",
            get = function() return DB.flashDuration end,
            set = function(_, key)
                DB.flashDuration = key
                Alert:SetAlertSettings({ flashDuration = DB.flashDuration, flashColor = DB.flashColor })
            end,
            order = 100
        }
        options.args.flashColor = {
            type = "color",
            name = "Screen Flash Color",
            width = "Normal",
            hasAlpha = true,
            get = function()
                local c = DB.flashColor
                return unpack(c)
            end,
            set = function(_, r, g, b, a)
                DB.flashColor = { r, g, b, a }
                Alert:SetAlertSettings({ flashDuration = DB.flashDuration, flashColor = DB.flashColor })
                AceConfigRegistry:NotifyChange(GT.metaData.name)
            end,
            order = 101
        }
        options.args.flashPreview = {
            type = "description",
            dialogControl = "NW_Label",
            name = "",
            width = "Normal",
            image = function()
                local texture = "Interface\\Addons\\GatheringTracker\\Media\\ScreenFlash"
                return texture, 128, 128
            end,
            imageCoords = function()
                local data = {}
                table.insert(data, "texture")
                table.insert(data, DB.flashColor)
                return data
            end,
            order = 102
        }
        --removing text option for now, may revisit after Alerts is released
        --[[elseif alertType == "Text" then
        options.args.textDuration = {
            type = "range",
            dialogControl = "NW_Slider",
            name = "Display Text Duration",
            min = 0.5,
            max = 20,
            softMax = 10,
            step = 0.1,
            width = "Normal",
            get = function() return DB.textDuration or 1 end,
            set = function(_, key)
                DB.textDuration = key
            end,
            order = 100
        }
        options.args.textColor = {
            type = "color",
            name = "Display Text Color",
            width = "Normal",
            get = function()
                local c = DB.textColor or { 1, 1, 1 }
                return unpack(c)
            end,
            set = function(_, r, g, b)
                DB.textColor = { r, g, b }
                AceConfigRegistry:NotifyChange(GT.metaData.name)
            end,
            order = 101
        }
        options.args.textString = {
            type = "input",
            name = "Display Text",
            width = "full",
            multiline = 2,
            desc = "Enter what text will be displayed on screen.\n\n" ..
                "#item# - will display the Item Name.\n" ..
                "#value# - will display the current value for the item based on the trigger type." ..
                "#trigger# - will display the trigger value for the alert.",
            get = function() return DB.textString or "#item# exceeded #trigger# items" end,
            set = function(_, key)
                DB.textString = key
            end,
            order = 103
        }
        options.args.textPreview = {
            type = "description",
            dialogControl = "NW_Label",
            name = function()
                local text = DB.textString or "#item# exceeded #trigger# items"
                text = string.gsub(text, "#item#", itemData.name)
                text = string.gsub(text, "#value#", function()
                    if GT.InventoryData[itemData.id] then
                        return GT.InventoryData[itemData.id].count
                    end
                    return 0
                end)
                text = string.gsub(text, "#trigger#", DB.triggerValue or 0)
                local data = {
                    text,
                    DB.textColor or { 1, 1, 1 }
                }
                return data
            end,
            width = "full",
            fontSize = "medium",
            order = 104
        }]]
    end

    return options
end

local function AddAlertConfig(itemData, Item, alertType, alertIndex)
    GT.Debug("AddAlertConfig", 4, itemData.id, itemData.name, alertType, alertIndex)
    local alertOptions = generalOptions.args.Alerts.args[tostring(itemData.id)].args
    local typeCount = alertIndex or #GT.db.profile.Alerts[itemData.id].alerts[alertType]
    local DB = GT.db.profile.Alerts[itemData.id].alerts[alertType][typeCount]
    local typeName = alertType .. "_" .. typeCount

    local Alert = InitializeAlert(Item, alertType, typeCount, DB)

    alertOptions[typeName] = GetAlertOptionsTable(itemData, alertType, typeCount, Item, Alert)
    AceConfigRegistry:NotifyChange(GT.metaData.name)
end

local function SetupAlertDefaults(itemData, data)
    GT.db.profile.Alerts[itemData.id].alerts[data[1]] = GT.db.profile.Alerts[itemData.id].alerts[data[1]] or {}
    local typeCount = #GT.db.profile.Alerts[itemData.id].alerts[data[1]] + 1
    GT.db.profile.Alerts[itemData.id].alerts[data[1]][typeCount] = {
        enable = true,
        order = data[2],
        triggerValue = 0,
        triggerType = 1,
        triggerMultiple = false,
    }
    local DB = GT.db.profile.Alerts[itemData.id].alerts[data[1]][typeCount]

    if data[1] == "Audio" then
        DB.tiggerSound = "Auction Window Open"
    elseif data[1] == "Highlight" then
        DB.highlightBorder = "Border 1"
        DB.highlightColor = { 1, 1, 1, 1 }
    elseif data[1] == "Screen Flash" then
        DB.flashDuration = 3
        DB.flashColor = { 1, 0, 0, 1 }
    end
end

local function AlertMenu(frame, itemData, Item)
    MenuUtil.CreateContextMenu(frame, function(ownerRegion, rootDescription)
        local function OnClick(data)
            SetupAlertDefaults(itemData, data)
            AddAlertConfig(itemData, Item, data[1])
        end
        rootDescription:CreateButton("Audio", OnClick, { "Audio", 10 })
        rootDescription:CreateButton("Highlight", OnClick, { "Highlight", 20 })
        rootDescription:CreateButton("Screen Flash", OnClick, { "Screen Flash", 30 })
    end)
end

local function AddAlertsFromDB(itemData)
    if not GT.db.profile.Alerts[itemData.id].alerts then
        return
    end

    for type, alerts in pairs(GT.db.profile.Alerts[itemData.id].alerts) do
        local Item = GT.AlertSystem:GetItem(itemData.id)
        for index, alertData in ipairs(alerts) do
            AddAlertConfig(itemData, Item, type, index)
        end
    end
end

function GT:InitializeAlertOptions(event, itemData)
    GT.Debug("Initialize Alert Options", 1, event, itemData)
    if event == "Refresh Config" then
        for name, data in pairs(generalOptions.args.Alerts.args) do
            if name ~= "addItem" and name ~= "alertsEnable" then
                generalOptions.args.Alerts.args[name] = nil
            end
        end
    end

    for id, data in pairs(GT.db.profile.Alerts) do
        local itemData = {}
        if id > 2 then
            GT.Debug("Create Alerts Table", 2, "Normal Item", id)
            local item = Item:CreateFromItemID(id)
            item:ContinueOnItemLoad(function()
                local itemInfo = { C_Item.GetItemInfo(id) }
                itemData = {
                    id = id,
                    name = itemInfo[1],
                    icon = itemInfo[10],
                    rarity = itemInfo[3],
                }
                if GT.gameVersion == "retail" then
                    itemData.quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(id)
                end
                GT:CreateAlertOptions(itemData)
                AddAlertsFromDB(itemData)
            end)
        else
            GT.Debug("Create Alerts Table", 2, "Special Item", id)
            itemData = {
                id = id,
                name = data.itemData.name,
                icon = data.itemData.icon,
            }
            GT:CreateAlertOptions(itemData)
            AddAlertsFromDB(itemData)
        end
    end
    AceConfigRegistry:NotifyChange(GT.metaData.name)
end

function GT:CreateAlertOptions(itemData)
    GT.Debug("Create Alert Options", 3, itemData.id, itemData.name)
    local alertOptions = generalOptions.args.Alerts.args
    local Item = GT.AlertSystem:GetItem(itemData.id) or GT.AlertSystem:AddItem(itemData.id)
    Item:SetEnabled(GT.db.profile.Alerts[itemData.id].enable)

    alertOptions[tostring(itemData.id)] = {
        type = "group",
        name = itemData.name,
        order = itemData.id,
        icon = function()
            if itemData.icon then
                return itemData.icon
            end
        end,
        args = {
            enableAlert = {
                type = "toggle",
                dialogControl = "NW_CheckBox",
                name = "Enable " .. itemData.name .. " Alert(s)",
                desc = "Check to enable alert(s) for " .. itemData.name,
                width = 1.4,
                get = function()
                    if GT.db.profile.Alerts[itemData.id].enable then
                        return GT.db.profile.Alerts[itemData.id].enable
                    end
                    return false
                end,
                set = function(_, key)
                    GT.db.profile.Alerts[itemData.id].enable = key
                    Item:SetEnabled(key)
                end,
                disabled = function()
                    if GT.db.profile.General.alertsEnable then
                        return false
                    end
                    return true
                end,
                order = 1
            },
            addAlert = {
                type = "execute",
                name = "Add Alert",
                desc = "Click to select what type of alert to add.",
                width = "normal",
                func = function()
                    AlertMenu(GT.Options.Main, itemData, Item)
                end,
                disabled = function()
                    if not GT.db.profile.General.alertsEnable then
                        return true
                    end
                    if not GT.db.profile.Alerts[itemData.id].enable then
                        return true
                    end
                    return false
                end,
                order = 2,
            },
            removeItem = {
                type = "execute",
                name = "Remove Item",
                desc = "Click to remove " .. itemData.name,
                width = "normal",
                confirm = true,
                func = function()
                    alertOptions[tostring(itemData.id)] = nil
                    GT.db.profile.Alerts[itemData.id] = nil
                    GT.AlertSystem:RemoveItem(itemData.id)
                    AceConfigRegistry:NotifyChange(GT.metaData.name)
                end,
                disabled = function()
                    if GT.db.profile.General.alertsEnable then
                        return false
                    end
                    return true
                end,
                order = 3,
            },
        },
    }
    AceConfigRegistry:NotifyChange(GT.metaData.name)
end

function GT:RemoveItemAlerts(id)
    generalOptions.args.Alerts.args[tostring(id)] = nil
    AceConfigRegistry:NotifyChange(GT.metaData.name)
end

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
                    name = "Use this field to add additional items (by ID only) to be tracked.",
                    width = "full",
                    order = 1
                },
                customInput = {
                    type = "input",
                    name = "Item ID",
                    width = "full",
                    usage = "Please only enter item ID's (aka numbers)",
                    get = function() end,
                    set = function(_, key)
                        if not string.match(key, "[%D]+") then
                            local id = tonumber(key) or 0
                            GT:CreateCustomFilterItem(id)
                        end
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
                local rarity = C_Item.GetItemQualityByID(itemData.id) or 1
                local R, G, B = C_Item.GetItemQualityColor(rarity)
                filterOptions.args[expansion].args[category].args[tostring(itemData.id)] = {
                    type = "toggle",
                    dialogControl = "NW_CheckBox",
                    name = function()
                        local qualityHex = GT:RGBtoHex(R or 1, G or 1, B or 1, 1)
                        local name = "|c" .. qualityHex .. "|Hitem:" .. itemData.id .. "::::::::::::::::::|h" .. itemData.name

                        if itemData.quality then
                            if itemData.quality == 1 then
                                name = name .. " |A:Professions-ChatIcon-Quality-Tier1:17:15::1|a|h|r"
                            elseif itemData.quality == 2 then
                                name = name .. " |A:Professions-ChatIcon-Quality-Tier2:17:23::|a|h|r"
                            elseif itemData.quality == 3 then
                                name = name .. " |A:Professions-ChatIcon-Quality-Tier3:17:18::1|a|h|r"
                            end
                        else
                            name = name .. "|h|r"
                        end

                        return name
                    end,
                    image = function()
                        if itemData.id <= #GT.ItemData.Other.Other then
                            return itemData.icon
                        else
                            return C_Item.GetItemIconByID(itemData.id)
                        end
                    end,
                    imageCoords = function()
                        local data = {}
                        local imageSize = { 24, 24 }
                        local border = {}
                        local borderColor = {}
                        local overlay = {}

                        if tonumber(itemData.id) <= #GT.ItemData.Other.Other then
                            border = { "Interface\\Common\\WhiteIconFrame", "texture" }
                            borderColor = { 1, 1, 1, 0.8 }
                            overlay = nil
                        else
                            if rarity <= 1 then
                                border = { "Interface\\Common\\WhiteIconFrame", "texture" }
                            else
                                border = { "bags-glow-white", "atlas" }
                            end

                            borderColor = { R, G, B, 0.8 }

                            if itemData.quality then
                                if itemData.quality == 1 then
                                    overlay = { "professions-icon-quality-tier1-inv", "atlas" }
                                elseif itemData.quality == 2 then
                                    overlay = { "professions-icon-quality-tier2-inv", "atlas" }
                                elseif itemData.quality == 3 then
                                    overlay = { "professions-icon-quality-tier3-inv", "atlas" }
                                end
                            else
                                overlay = nil
                            end
                        end

                        data = { imageSize, border, borderColor, overlay }

                        return data
                    end,
                    get = function() return GT.db.profile.Filters[itemData.id] end,
                    set = function(_, key)
                        if key then
                            GT.db.profile.Filters[itemData.id] = key
                        else
                            GT.db.profile.Filters[itemData.id] = nil
                        end

                        GT:UpdateIDTable(itemData.id, key)
                        GT:RemoveItemData(key, itemData.id)
                        GT:InventoryUpdate("Filters " .. expansion .. " " .. category .. " " .. itemData.name .. " option clicked", true)
                    end,
                    width = 1.2,
                    order = itemData.order
                }
                if itemData.desc then
                    filterOptions.args[expansion].args[category].args[tostring(itemData.id)].desc = itemData.desc
                end
            end
        end
    end
end

function GT:DeleteCustomFilter(itemID, itemName)
    GT.Debug("Delete Custom Filter", 1, itemID, itemName)

    GT.db.profile.CustomFiltersTable[itemID] = nil

    filterOptions.args.custom.args[itemName] = nil
    AceConfigRegistry:NotifyChange("GT/Filter")

    GT:RebuildIDTables()
    GT:InventoryUpdate("Custom Filter Deleted", true)
end

function GT:CreateCustomFilterItem(id, enable)
    --Create a local item to get data from the server
    local item = Item:CreateFromItemID(id)
    GT.Debug("Create Custom Filter Options", 2, id)
    --Waits for the data to be returned from the server
    if not item:IsItemEmpty() then
        item:ContinueOnItemLoad(function()
            GT.Debug("Create Custom Filter Options", 3, id)
            if GT.db.profile.CustomFiltersTable[id] == nil then
                GT.db.profile.CustomFiltersTable[id] = false
            end
            if enable then
                GT.db.profile.CustomFiltersTable[id] = true
            end
            local itemName = item:GetItemName() or ""
            local itemLink = item:GetItemLink() or ""
            itemLink = itemLink:gsub("[%[%]]", "")
            filterOptions.args.custom.args[itemName] = {
                type = "toggle",
                dialogControl = "NW_CheckBox",
                name = itemLink,
                image = function() return C_Item.GetItemIconByID(id) end,
                get = function() return GT.db.profile.CustomFiltersTable[id] end,
                set = function(_, key)
                    if key then
                        GT.db.profile.CustomFiltersTable[id] = key
                    else
                        GT.db.profile.CustomFiltersTable[id] = false
                    end

                    GT:UpdateIDTable(id, key)
                    GT:RemoveItemData(key, id)
                    GT:InventoryUpdate("Filters Custom " .. itemName .. " option clicked", true)
                end,
                imageCoords = function()
                    local data = {}
                    local imageSize = { 24, 24 }
                    local border = {}
                    local borderColor = {}
                    local overlay = {}

                    if id <= #GT.ItemData.Other.Other then
                        border = { "Interface\\Common\\WhiteIconFrame", "texture" }
                        borderColor = { 1, 1, 1, 0.8 }
                        overlay = nil
                    else
                        local rarity = C_Item.GetItemQualityByID(id) or 1
                        if rarity <= 1 then
                            border = { "Interface\\Common\\WhiteIconFrame", "texture" }
                        else
                            border = { "bags-glow-white", "atlas" }
                        end

                        local R, G, B = C_Item.GetItemQualityColor(rarity)
                        borderColor = { R, G, B, 0.8 }

                        overlay = nil
                    end

                    local deleteFunc = function(self)
                        GT:DeleteCustomFilter(id, itemName)
                    end

                    data = { imageSize, border, borderColor, overlay, deleteFunc }

                    return data
                end,
                width = 1.2,
                order = (id + 1000)
            }
            AceConfigRegistry:NotifyChange("GT/Filter")
        end)
    else
        ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. ":|r " .. id .. " is not a valid item ID")
    end
end

function GT:CreateCustomFilterOptions()
    if GT.db.profile.CustomFiltersTable then
        for arg, data in pairs(filterOptions.args.custom.args) do
            if data.order > 1000 then
                filterOptions.args.custom.args[arg] = nil
            end
        end
        for id in pairs(GT.db.profile.CustomFiltersTable) do
            GT:CreateCustomFilterItem(id)
        end
    end
end

local GroupModeOptions = {
    type = "group",
    name = "Group Mode",
    childGroups = "tab",
    args = {
        heading = {
            type = "description",
            name = "Group mode allows for displayed data to be sent between players in your group.  When enabled data received from other players will be displayed.",
            width = "full",
            order = 1
        },
    }
}

function GatheringTracker_OnAddonCompartmentClick(addonName, button)
    if (button == "LeftButton") then
        GT:ToggleGatheringTracker()
    elseif (button == "RightButton") then
        Settings.OpenToCategory(GT.metaData.name, true)
    end
end

local function UpdateChangedorRemovedSavedVariables()
    if GT.db.profile.General.fixSettings then
        GT.db.profile.General.fixSettings = nil
    end
    if GT.db.profile.Notifications then
        GT.db.profile.Notifications = nil
    end
    if GT.db.profile.CustomFilters then
        GT.db.profile.CustomFilters = nil
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
    if event == "OnProfileChanged" then
        UpdateChangedorRemovedSavedVariables()
    end

    GT.baseFrame.backdrop:ClearAllPoints()
    GT.baseFrame.backdrop:SetPoint(
        GT.db.profile.General.relativePoint,
        UIParent,
        GT.db.profile.General.relativePoint,
        GT.db.profile.General.xPos,
        GT.db.profile.General.yPos
    )
    GT.AlertSystem.AllowAlertEffects = false

    GT.AlertSystem:RemoveAllItems("Refresh Config")
    GT:RebuildIDTables()
    GT:ClearDisplay()
    GT:FiltersButton()
    GT:InventoryUpdate("Refresh Config", true)
    GT:CreateCustomFilterOptions()
    GT:InitializeAlertOptions("Refresh Config")
    GT:MinimapHandler(GT.db.profile.miniMap.enable)

    GT:wait(2, "AllowAlertEffects", "AllowAlertEffects")
end

local function InitializePriceSource()
    local priceSources = { "TradeSkillMaster", "RECrystallize", "Auctionator" }
    local priceSourcesLoaded = {}

    for _, source in ipairs(priceSources) do
        local loaded = C_AddOns.IsAddOnLoaded(source)
        if loaded then
            priceSourcesLoaded[source] = true
        end
    end

    if next(priceSourcesLoaded) == nil then
        priceSourcesLoaded = nil
    end

    return priceSourcesLoaded
end

local function ValidatePriceSourceOption()
    local priceSources = { "TradeSkillMaster", "RECrystallize", "Auctionator" }
    local priceSourceOption = {
        ["TradeSkillMaster"] = { 1, 6 },
        ["RECrystallize"] = { 10, 10 },
        ["Auctionator"] = { 20, 20 },
    }

    for _, source in ipairs(priceSources) do
        if not GT.priceSources then
            GT.db.profile.General.tsmPrice = 0
        elseif not GT.priceSources[source] then
            if GT.db.profile.General.tsmPrice >= priceSourceOption[source][1] and
                GT.db.profile.General.tsmPrice <= priceSourceOption[source][2] then
                GT.db.profile.General.tsmPrice = 0
            end
        end
    end
end

function GT:OnInitialize()
    --have to check if tsm is loaded before we create the options so that we can use that variable in the options.
    GT.priceSources = InitializePriceSource()
    GT.GeneralOptions = generalOptions

    GT.db = LibStub("AceDB-3.0"):New("GatheringTrackerDB", GT.defaults, true)
    GT.db.RegisterCallback(GT, "OnProfileChanged", "RefreshConfig")
    GT.db.RegisterCallback(GT, "OnProfileCopied", "RefreshConfig")
    GT.db.RegisterCallback(GT, "OnProfileReset", "RefreshConfig")

    if GT.db.profile.General.unlock then
        GT.db.profile.General.unlock = false
    end

    ValidatePriceSourceOption()

    --if TSM is not loaded set tsmPrice Option to none.
    if not GT.priceSources then
        GT.db.profile.General.tsmPrice = 0
        GT.db.profile.General.perItemPrice = false
    elseif GT.priceSources["TradeSkillMaster"] then
        GT:SetTSMPriceSource()
    end

    UpdateChangedorRemovedSavedVariables()


    AceConfigRegistry:RegisterOptionsTable(GT.metaData.name, generalOptions)
    GT.Options.Main = AceConfigDialog:AddToBlizOptions(GT.metaData.name, GT.metaData.name)
    GT.Options.Main:SetScript("OnHide", GT.OptionsHide)

    AceConfigRegistry:RegisterOptionsTable("GT/Filter", filterOptions)
    GT.Options.Filter = AceConfigDialog:AddToBlizOptions("GT/Filter", "Filter", GT.metaData.name)
    GT.Options.Filter:SetScript("OnHide", GT.OptionsHide)

    --[[AceConfigRegistry:RegisterOptionsTable("GT/Group", GroupModeOptions)
    GT.Options.Group = AceConfigDialog:AddToBlizOptions("GT/Group", "Group Mode", GT.metaData.name)
    GT.Options.Group:SetScript("OnHide", GT.OptionsHide)]]

    AceConfigRegistry:RegisterOptionsTable("GT/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(GT.db))
    GT.Options.Profiles = AceConfigDialog:AddToBlizOptions("GT/Profiles", "Profiles", GT.metaData.name)
    GT.Options.Profiles:SetScript("OnHide", GT.OptionsHide)

    GT:CreateCustomFilterOptions()

    local function openOptions()
        Settings.OpenToCategory(GT.metaData.name, true)
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
    media:Register("sound", "Turtle Water", 109068)

    GT.Enabled = GT.db.profile.General.enable
    if not GT.Enabled then
        GT:OnDisable()
    end

    GT:InitializeBroker()
    GT:RebuildIDTables()
    GT:CreateBaseFrame()
    GT:FiltersButton()
    GT:InitializePools()

    GT.AlertSystem:CreateAlertFrames()
    GT:InitializeAlertOptions("OnInitialize")

    GT:RunAnalytics()
end
