local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local Config = GT:NewModule("Config","AceEvent-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")

local defaults = {
    profile = {
        General = {
            enable = true,
            unlock = false,
            xPos = 200,
            yPos = -150,
            relativePoint = "TOPLEFT",
            iconWidth = 27,
            iconHeight = 27,
            textColor = {1, 1, 1, 1},
            textSize = 20,
            textFont = 19,
            totalColor = {0.098, 1, 0.078, 1},
            totalSize = 20,
            totalFont = 19,
            groupType = false,
            stacksOnIcon = false,
            shareSettings = false,
            includeBank = false,
            tsmPrice = 1,
            ignoreAmount = 0,
            perItemPrice = false,
        },
        Filters = {
        },
        CustomFilters = "",
    },
}

local generalOptions = {
    type = "group",
    args = {
        enable = {
            type = "toggle",
            name = "Enabled",
            desc = "Uncheck to disable the addon, this will effectively turn off the addon.",
            width = 1.77,
            get = function() return GT.db.profile.General.enable end,
            set = function(_, key) 
                GT.db.profile.General.enable = key
                if key and not GT.Enabled then
                    GT:OnEnable()
                elseif not key and GT.Enabled then
                    GT:OnDisable()
                end
            end,
            order = 1
        },
        unlock = {
            type = "toggle",
            name = "Unlock Frame",
            width = 1.77,
            get = function() return GT.db.profile.General.unlock end,
            set = function(_, key) GT.db.profile.General.unlock = key GT:ToggleBaseLock(key) end,
            order = 2
        },
        header1 = {
            type = "header",
            name = "Icon Size",
            order = 100
        },
        iconWidth = {
            type = "range",
            name = "Icon Width",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GT.db.profile.General.iconWidth or 1 end,
            set = function(_, key) GT.db.profile.General.iconWidth = key end,
            order = 103
        },
        iconHeight = {
            type = "range",
            name = "Icon Height",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GT.db.profile.General.iconHeight or 1 end,
            set = function(_, key) GT.db.profile.General.iconHeight = key end,
            order = 104
        },
        header2 = {
            type = "header",
            name = "Text",
            order = 110
        },
        textColor = {
            type = "color",
            name = "Text Color",
            hasAlpha = true,
            get = function() local c = GT.db.profile.General.textColor return c[1], c[2], c[3], c[4] or 1,1,1,1 end,
            set = function(_,r,g,b,a) GT.db.profile.General.textColor = {r,g,b,a} end,
            order = 111
        },
        textSize = {
            type = "range",
            name = "Text Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GT.db.profile.General.textSize or 1 end,
            set = function(_, key) GT.db.profile.General.textSize = key end,
            order = 112
        },
        textFont = {
            type = "select",
            name = "Text Font",
            width = 1.25,
            itemControl = "DDI-Font",
            values = media:List("font"),
            get = function() return GT.db.profile.General.textFont end,
            set = function(_, key) GT.db.profile.General.textFont = key end,
            order = 113
        },
        totalColor = {
            type = "color",
            name = "Total Color",
            hasAlpha = true,
            get = function() local c = GT.db.profile.General.totalColor return c[1], c[2], c[3], c[4] or 1,1,1,1 end,
            set = function(_,r,g,b,a) GT.db.profile.General.totalColor = {r,g,b,a} end,
            order = 114
        },
        totalSize = {
            type = "range",
            name = "Total Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GT.db.profile.General.totalSize or 1 end,
            set = function(_, key) GT.db.profile.General.totalSize = key end,
            order = 115
        },
        totalFont = {
            type = "select",
            name = "Total Font",
            width = 1.25,
            itemControl = "DDI-Font",
            values = media:List("font"),
            get = function() return GT.db.profile.General.totalFont end,
            set = function(_, key) GT.db.profile.General.totalFont = key end,
            order = 116
        },
        header3 = {
            type = "header",
            name = "Display Options",
            order = 120
        },
        groupType = {
            type = "toggle",
            name = "Group Mode",
            desc  = "Select this if you want to share information with your group and display the groups information.",
            width = 1.77,
            get = function() return GT.db.profile.General.groupType end,
            set = function(_, key) 
                GT.db.profile.General.groupType = key
                if key then
                    GT.groupMode = "RAID"
                else
                    GT.groupMode = "WHISPER"
                end
            end,
            order = 121
        },
        stacksOnIcon = {
            type = "toggle",
            name = "Display Stack Count over Icon",
            desc  = "When selected the stack count will be displayed over the icon.  This is only available when Group Mode is disabled.",
            width = 1.77,
            disabled = function() return GT.db.profile.General.groupType end,
            get = function() return GT.db.profile.General.stacksOnIcon end,
            set = function(_, key) GT.db.profile.General.stacksOnIcon = key end,
            order = 122
        },
        shareSettings = {
            type = "toggle",
            name = "Share Settings with Group",
            desc  = "When selected any changed to settings or Filters will be shared with your group.  This is only available when Group Mode is Enabled.",
            width = 1.77,
            disabled = function() return not GT.db.profile.General.groupType end,
            get = function() return GT.db.profile.General.shareSettings end,
            set = function(_, key) GT.db.profile.General.shareSettings = key end,
            order = 123
        },
        includeBank = {
            type = "toggle",
            name = "Include Bank",
            desc = "If selected displayed values will include items in your bank",
            width = 1.77,
            get = function() return GT.db.profile.General.includeBank end,
            set = function(_, key) GT.db.profile.General.includeBank = key end,
            order = 124
        },
        tsmPrice = {
            type = "select",
            name = "TSM Price Source",
            desc = "Select the desired TSM price source, or none to disable price information",
            width = 1.77,
            values = {[0] = "None", [1] = "DBMarket", [2] = "DBMinBuyout", [3] = "DBHistorical", [4] = "DBRegionMinBuyoutAvg", [5] = "DBRegionMarketAvg", [6] = "DBRegionHistorical"},
            get = function() return GT.db.profile.General.tsmPrice end,
            set = function(_, key) GT.db.profile.General.tsmPrice = key end,
            order = 125
        },
        ignoreAmount = {
            type = "range",
            name = "Ignore Amount",
            desc = "Use this option to ignore a specific amount, this value will be subtracted from the totals.",
            min = 0,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GT.db.profile.General.ignoreAmount or 1 end,
            set = function(_, key) GT.db.profile.General.ignoreAmount = key end,
            order = 126
        },
        perItemPrice = {
            type = "toggle",
            name = "Display Per Item Price",
            desc = "If selected the price for 1 of each item will be displayed",
            width = 1.77,
            get = function() return GT.db.profile.General.perItemPrice end,
            set = function(_, key) GT.db.profile.General.perItemPrice = key end,
            order = 127
        },
    }
}

local filterOptions = {
    type = "group",
    name = "Filters",
    childGroups = "tab",
    args = {
        heading = {
            type = "description",
            name = "Select all items you wish to display.",
            width = "full",
            order = 0
        },
        custom = {
            type = "group",
            name = "Custom",
            order = -1,
            args = {
                heading = {
                    type = "description",
                    name = "Use this field to add additional items (by ID only) to be tracked.  One ID per line!",
                    width = "full",
                    order = 0
                },
                customInput = {
                    type = "input",
                    name = "Custom Input",
                    multiline = true,
                    width = "full",
                    usage = "Please only enter item ID's (aka numbers)",
                    validate = function(_, key) if string.match(key, "[^%d\n]+") then return false end return true end,
                    get = function() return GT.db.profile.CustomFilters end,
                    set = function(_, key) GT.db.profile.CustomFilters = key GT:RebuildIDTables() end,
                    order = 1
                },
            }
        }
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
                filterOptions.args[expansion].args[category].args[expansion.." "..itemData.name] = {
                    type = "header",
                    name = itemData.name,
                    order = itemData.order
                }
            else
                filterOptions.args[expansion].args[category].args[itemData.name] = {
                    type = "toggle",
                    name = itemData.name,
                    get = function() return GT.db.profile.Filters[itemData.id] end,
                    set = function(_, key) if key then GT.db.profile.Filters[itemData.id] = key else GT.db.profile.Filters[itemData.id] = nil end GT:RebuildIDTables() end,
                    order = itemData.order
                }
            end
        end
    end
end

function Config:OnInitialize()
    GT.db = LibStub("AceDB-3.0"):New("GatheringTrackerDB", defaults, true)
    if GT.db.profile.General.unlock then
        GT.db.profile.General.unlock = false
    end

    AceConfigRegistry:RegisterOptionsTable("Gathering Tracker", generalOptions)
    local options = AceConfigDialog:AddToBlizOptions("Gathering Tracker", "Gathering Tracker")

    AceConfigRegistry:RegisterOptionsTable("GT/Filter", filterOptions)
    AceConfigDialog:AddToBlizOptions("GT/Filter", "Filter", "Gathering Tracker")

    local function openOptions()
		InterfaceOptionsFrame_OpenToCategory("Gathering Tracker")
    end
    
    SLASH_GatheringTracker1 = "/gatheringtracker"
    SLASH_GatheringTracker2 = "/gt"
    SlashCmdList.GatheringTracker = openOptions

    if GT.db.profile.General.groupType then
        GT.groupMode = "RAID"
    else
        GT.groupMode = "WHISPER"
    end
    
    GT:RebuildIDTables()
    GT:CreateBaseFrame()
end
