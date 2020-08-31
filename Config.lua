local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local Config = GT:NewModule("Config","AceEvent-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")

local GTDB

local defaults = {
    profile = {
        General = {
            xPos = 200,
            yPos = 150,
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
            includeBank = false,
            tsmPrice = 1,
            ignoreAmount = 0,
            perItemPrice = false,
        },
        Filters = {
        },
    },
}

local generalOptions = {
    type = "group",
    args = {
        header1 = {
            type = "header",
            name = "Size and Position",
            order = 100
        },
        xPos = {
            type = "range",
            name = "X Offset",
            min = 0,
            max = math.floor(GetScreenWidth()),
            step = 1,
            width = 1.77,
            get = function() return GTDB.profile.General.xPos or 1 end,
            set = function(_, key) GTDB.profile.General.xPos = key end,
            order = 101
        },
        yPos = {
            type = "range",
            name = "Y Offset",
            min = 0,
            max = math.floor(GetScreenHeight()),
            step = 1,
            width = 1.77,
            get = function() return GTDB.profile.General.yPos or 1 end,
            set = function(_, key) GTDB.profile.General.yPos = key end,
            order = 102
        },
        iconWidth = {
            type = "range",
            name = "Icon Width",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GTDB.profile.General.iconWidth or 1 end,
            set = function(_, key) GTDB.profile.General.iconWidth = key end,
            order = 103
        },
        iconHeight = {
            type = "range",
            name = "Icon Height",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GTDB.profile.General.iconHeight or 1 end,
            set = function(_, key) GTDB.profile.General.iconHeight = key end,
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
            get = function() local c = GTDB.profile.General.textColor return c[1], c[2], c[3], c[4] or 1,1,1,1 end,
            set = function(_,r,g,b,a) GTDB.profile.General.textColor = {r,g,b,a} end,
            order = 111
        },
        textSize = {
            type = "range",
            name = "Text Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GTDB.profile.General.textSize or 1 end,
            set = function(_, key) GTDB.profile.General.textSize = key end,
            order = 112
        },
        textFont = {
            type = "select",
            name = "Text Font",
            width = 1.25,
            itemControl = "DDI-Font",
            values = media:List("font"),
            get = function() return GTDB.profile.General.textFont end,
            set = function(_, key) GTDB.profile.General.textFont = key end,
            order = 113
        },
        totalColor = {
            type = "color",
            name = "Total Color",
            hasAlpha = true,
            get = function() local c = GTDB.profile.General.totalColor return c[1], c[2], c[3], c[4] or 1,1,1,1 end,
            set = function(_,r,g,b,a) GTDB.profile.General.totalColor = {r,g,b,a} end,
            order = 114
        },
        totalSize = {
            type = "range",
            name = "Total Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GTDB.profile.General.totalSize or 1 end,
            set = function(_, key) GTDB.profile.General.totalSize = key end,
            order = 115
        },
        totalFont = {
            type = "select",
            name = "Total Font",
            width = 1.25,
            itemControl = "DDI-Font",
            values = media:List("font"),
            get = function() return GTDB.profile.General.totalFont end,
            set = function(_, key) GTDB.profile.General.totalFont = key end,
            order = 116
        },
        header3 = {
            type = "header",
            name = "Display Options",
            order = 120
        },
        groupType = {
            type = "toggle",
            name = "Display Group Information",
            desc  = "Select this if you are a multiboxer",
            width = 1.77,
            get = function() return GTDB.profile.General.groupType end,
            set = function(_, key) GTDB.profile.General.groupType = key end,
            order = 121
        },
        stacksOnIcon = {
            type = "toggle",
            name = "Display Stack Count over Icon",
            desc  = "When selected the stack count will be displayed over the icon.  This is only available when Group is disabled.",
            width = 1.77,
            disabled = function() return GTDB.profile.General.groupType end,
            get = function() return GTDB.profile.General.stacksOnIcon end,
            set = function(_, key) GTDB.profile.General.stacksOnIcon = key end,
            order = 122
        },
        includeBank = {
            type = "toggle",
            name = "Include Bank",
            desc = "If selected displayed values will include items in your bank",
            width = 1.77,
            get = function() return GTDB.profile.General.includeBank end,
            set = function(_, key) GTDB.profile.General.includeBank = key end,
            order = 123
        },
        tsmPrice = {
            type = "select",
            name = "TSM Price Source",
            desc = "Select the desired TSM price source, or none to disable price information",
            width = 1.77,
            values = {[0] = "None", [1] = "DBMarket", [2] = "DBMinBuyout", [3] = "DBHistorical", [4] = "DBRegionMinBuyoutAvg", [5] = "DBRegionMarketAvg", [6] = "DBRegionHistorical"},
            get = function() return GTDB.profile.General.tsmPrice end,
            set = function(_, key) GTDB.profile.General.tsmPrice = key end,
            order = 124
        },
        ignoreAmount = {
            type = "range",
            name = "Ignore Amount",
            desc = "Use this option to ignore a specific amount, this value will be subtracted from the totals.",
            min = 0,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GTDB.profile.General.ignoreAmount or 1 end,
            set = function(_, key) GTDB.profile.General.ignoreAmount = key end,
            order = 125
        },
        perItemPrice = {
            type = "toggle",
            name = "Display Per Item Price",
            desc = "If selected the price for 1 of each item will be displayed",
            width = 1.77,
            get = function() return GTDB.profile.General.perItemPrice end,
            set = function(_, key) GTDB.profile.General.perItemPrice = key end,
            order = 126
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
            args = {}
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
            filterOptions.args[expansion].args[category].args[itemData.name] = {
                type = "toggle",
                name = itemData.name,
                get = function() return GTDB.profile.Filters[itemData.id] end,
                set = function(_, key) if key then GTDB.profile.Filters[itemData.id] = key else GTDB.profile.Filters[itemData.id] = nil end end,
                order = itemData.order
            }
        end
    end
end

function Config:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GatheringTrackerDB", defaults, true)
    GTDB = self.db

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
end
