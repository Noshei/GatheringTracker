local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local Config = GT:NewModule("Config","AceEvent-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local media = LibStub("LibSharedMedia-3.0")

GT.media = media

--register font with LSM
media:Register("font", "Fira Mono Medium", "Interface\\Addons\\GatheringTracker\\Media\\Fonts\\FiraMono-Medium.ttf", media.LOCALE_BIT_western + media.LOCALE_BIT_ruRU)

local defaults = {
    profile = {
        General = {
            enable = true,
            unlock = false,
            filtersButton = false,
            xPos = 200,
            yPos = -150,
            relativePoint = "TOPLEFT",
            iconWidth = 27,
            iconHeight = 27,
            textColor = {1, 1, 1},
            textSize = 20,
            textFont = "Fira Mono Medium",
            totalColor = {0.098, 1, 0.078},
            totalSize = 20,
            totalFont = "Fira Mono Medium",
            groupType = false,
            stacksOnIcon = false,
            shareSettings = false,
            includeBank = false,
            tsmPrice = 1,
            ignoreAmount = 0,
            perItemPrice = false,
            debugOption = false,
            displayAlias = false,
        },
        Filters = {
        },
        CustomFilters = "",
        Aliases = {
        },
    },
}

local generalOptions = {
    type = "group",
    args = {
        header0 = {
            type = "header",
            name = "v"..tostring(GT.metaData.version),
            order = 0
        },
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
                    GT:ResetDisplay(true)
                    GT:FiltersButton()
                elseif not key and GT.Enabled then
                    GT:OnDisable()
                    GT:ResetDisplay(true)
                    GT:FiltersButton()
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
        filtersButton = {
            type = "toggle",
            name = "Filters Button",
            width = 1.77,
            get = function() return GT.db.profile.General.filtersButton end,
            set = function(_, key) GT.db.profile.General.filtersButton = key GT:FiltersButton() end,
            order = 3
        },
        header1 = {
            type = "header",
            name = "Group Options",
            order = 100
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
                    GT.db.profile.General.shareSettings = false
                    GT.db.profile.General.displayAlias = false
                end
                if key and not IsInGroup() then
                    GT:ResetDisplay(false)
                elseif key and IsInGroup() then
                    GT:InventoryUpdate("Group Mode 1")
                    GT:ResetDisplay(true)
                elseif not key and IsInGroup() then
                    GT:ResetDisplay(false)
                elseif not key and not IsInGroup() then
                    GT:InventoryUpdate("Group Mode 2")
                    GT:ResetDisplay(true)
                end
            end,
            order = 101
        },
        shareSettings = {
            type = "toggle",
            name = "Share Settings with Group",
            desc  = "When selected any changed to settings or Filters will be shared with your group.  This is only available when Group Mode is Enabled.  When a party is formed or changed the party leader will share their settings.",
            width = 1.77,
            get = function() return GT.db.profile.General.shareSettings end,
            set = function(_, key) GT.db.profile.General.shareSettings = key end,
            disabled = function() return not GT.db.profile.General.groupType end,
            order = 102
        },
        displayAlias = {
            type = "toggle",
            name = "Display Characters Alias",
            desc  = "When selected the character aliases will be displayed above their count column.",
            width = 1.77,
            get = function() return GT.db.profile.General.displayAlias end,
            set = function(_, key) GT.db.profile.General.displayAlias = key end,
            disabled = function() return not GT.db.profile.General.groupType end,
            order = 103
        },
        header2 = {
            type = "header",
            name = "Display Options",
            order = 200
        },
        tsmPrice = {
            type = "select",
            name = "TSM Price Source",
            desc = "Select the desired TSM price source, or none to disable price information.  TSM is required for this option to be enabled.",
            width = 1.77,
            values = {[0] = "None", [1] = "DBMarket", [2] = "DBMinBuyout", [3] = "DBHistorical", [4] = "DBRegionMinBuyoutAvg", [5] = "DBRegionMarketAvg", [6] = "DBRegionHistorical"},
            get = function() return GT.db.profile.General.tsmPrice end,
            set = function(_, key) 
                GT.db.profile.General.tsmPrice = key
                if GT.db.profile.General.tsmPrice == 0 then
                    GT.db.profile.General.perItemPrice = false
                end
                GT:ResetDisplay(true) end,
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
            width = 1.77,
            get = function() return GT.db.profile.General.perItemPrice end,
            set = function(_, key) GT.db.profile.General.perItemPrice = key GT:ResetDisplay(true) end,
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
            width = 1.77,
            get = function() return GT.db.profile.General.ignoreAmount or 1 end,
            set = function(_, key) GT.db.profile.General.ignoreAmount = key GT:ResetDisplay(true) end,
            order = 203
        },
        includeBank = {
            type = "toggle",
            name = "Include Bank",
            desc = "If selected displayed values will include items in your bank.",
            width = 1.77,
            get = function() return GT.db.profile.General.includeBank end,
            set = function(_, key) GT.db.profile.General.includeBank = key GT:InventoryUpdate("Include Bank") end,
            order = 204
        },
        header3 = {
            type = "header",
            name = "Icon Size",
            order = 300
        },
        iconWidth = {
            type = "range",
            name = "Icon Width",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GT.db.profile.General.iconWidth or 1 end,
            set = function(_, key) GT.db.profile.General.iconWidth = key GT:ResetDisplay(true) end,
            order = 301
        },
        iconHeight = {
            type = "range",
            name = "Icon Height",
            min = 10,
            max = 100,
            step = 1,
            width = 1.77,
            get = function() return GT.db.profile.General.iconHeight or 1 end,
            set = function(_, key) GT.db.profile.General.iconHeight = key GT:ResetDisplay(true) end,
            order = 302
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
            get = function() local c = GT.db.profile.General.textColor return c[1], c[2], c[3] or 1,1,1 end,
            set = function(_,r,g,b) GT.db.profile.General.textColor = {r,g,b} GT:ResetDisplay(true) end,
            order = 401
        },
        textSize = {
            type = "range",
            name = "Text Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GT.db.profile.General.textSize or 1 end,
            set = function(_, key) GT.db.profile.General.textSize = key GT:ResetDisplay(true) end,
            order = 402
        },
        textFont = {
            type = "select",
            name = "Text Font",
            width = 1.25,
            dialogControl = 'LSM30_Font',
            values = media:HashTable("font"),
            get = function() return GT.db.profile.General.textFont end,
            set = function(_, key) GT.db.profile.General.textFont = key GT:ResetDisplay(true) end,
            order = 403
        },
        totalColor = {
            type = "color",
            name = "Total Color",
            hasAlpha = false,
            get = function() local c = GT.db.profile.General.totalColor return c[1], c[2], c[3] or 1,1,1 end,
            set = function(_,r,g,b,a) GT.db.profile.General.totalColor = {r,g,b,a} GT:ResetDisplay(true) end,
            order = 404
        },
        totalSize = {
            type = "range",
            name = "Total Size",
            min = 10,
            max = 70,
            step = 1,
            width = 1.25,
            get = function() return GT.db.profile.General.totalSize or 1 end,
            set = function(_, key) GT.db.profile.General.totalSize = key GT:ResetDisplay(true) end,
            order = 405
        },
        totalFont = {
            type = "select",
            name = "Total Font",
            width = 1.25,
            dialogControl = 'LSM30_Font',
            values = media:HashTable("font"),
            get = function() return GT.db.profile.General.totalFont end,
            set = function(_, key) GT.db.profile.General.totalFont = key GT:ResetDisplay(true) end,
            order = 406
        },
        header5 = {
            type = "header",
            name = "Debug",
            order = 10000
        },
        debugOption = {
            type = "toggle",
            name = "Debug",
            desc = "This is for debugging the addon, do NOT enable, it is spammy.",
            width = 1.77,
            get = function() return GT.db.profile.General.debugOption end,
            set = function(_, key) GT.db.profile.General.debugOption = key end,
            order = 10001
        },
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
            order = -1,
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
                    validate = function(_, key) if string.match(key, "[^%d\n]+") then return false end return true end,
                    get = function() return GT.db.profile.CustomFilters end,
                    set = function(_, key) GT.db.profile.CustomFilters = key GT:RebuildIDTables() GT:InventoryUpdate("Custom Filter Changed") end,
                    order = 2
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
                    set = function(_, key) 
                        if key then 
                            GT.db.profile.Filters[itemData.id] = key 
                        else 
                            GT.db.profile.Filters[itemData.id] = nil
                        end

                        GT:RebuildIDTables()

                        if GT.count[tostring(itemData.id)] == nil then
                            GT:InventoryUpdate(expansion.." "..category.." "..itemData.name.." option clicked")
                        else
                            GT:ResetDisplay(true)
                        end
                    end,
                    order = itemData.order
                }
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
            name = "Input desired character aliases below.\n\nIf enabled, the alias will be displayed above each character column.\n\nIt is recommended that the first character of each alias be distinct, as in some situations only the first character of an alias will be displayed.\n",
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
            validate = function(_, key) if string.match(key, "[%p%s%d]+") then return false end return true end,
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
                            local aliasTable = {name = tempAliasCharacter, alias = tempAliasName}
                            table.insert(GT.db.profile.Aliases, aliasTable)
                            GT:UpdateAliases()
                        end
                    else
                        local aliasTable = {name = tempAliasCharacter, alias = tempAliasName}
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
                name = aliasInfo.name.." = "..aliasInfo.alias,
                fontSize = "large",
                order = (1000 + index)
            }
        end
    end
    AceConfigRegistry:NotifyChange("GT/Alias")
end

function Config:OnInitialize()
    --have to check if tsm is loaded before we create the options so that we can use that variable in the options.
    GT.tsmLoaded = IsAddOnLoaded("TradeSkillMaster")
    GT.ElvUI = IsAddOnLoaded("ElvUI")

    GT.db = LibStub("AceDB-3.0"):New("GatheringTrackerDB", defaults, true)
    if GT.db.profile.General.unlock then
        GT.db.profile.General.unlock = false
    end

    --if TSM is not loaded set tsmPrice Option to none.
    if not GT.tsmLoaded then
        GT.db.profile.General.tsmPrice = 0
        GT.db.profile.General.perItemPrice = false
    end

    AceConfigRegistry:RegisterOptionsTable(GT.metaData.name, generalOptions)
    local options = AceConfigDialog:AddToBlizOptions(GT.metaData.name, GT.metaData.name)

    AceConfigRegistry:RegisterOptionsTable("GT/Filter", filterOptions)
    AceConfigDialog:AddToBlizOptions("GT/Filter", "Filter", GT.metaData.name)
    
    AceConfigRegistry:RegisterOptionsTable("GT/Alias", aliasOptions)
    AceConfigDialog:AddToBlizOptions("GT/Alias", "Alias", GT.metaData.name)

    AceConfigRegistry:RegisterOptionsTable("GT/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(GT.db))
    AceConfigDialog:AddToBlizOptions("GT/Profiles", "Profiles", GT.metaData.name)

    GT:UpdateAliases()

    local function openOptions()
		InterfaceOptionsFrame_OpenToCategory(GT.metaData.name)
    end
    
    SLASH_GatheringTracker1 = "/gatheringtracker"
    SLASH_GatheringTracker2 = "/gt"
    SlashCmdList.GatheringTracker = openOptions

    GT.Player = UnitName("player")

    GT.Enabled = GT.db.profile.General.enable

    if GT.db.profile.General.groupType then
        GT.groupMode = "RAID"
    else
        GT.groupMode = "WHISPER"
    end
    
    GT:RebuildIDTables()
    GT:CreateBaseFrame("Config:OnInitialize")
end
