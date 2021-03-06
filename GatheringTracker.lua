GatheringTracker = LibStub("AceAddon-3.0"):NewAddon("GatheringTracker", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local media = LibStub("LibSharedMedia-3.0")
local GT = GatheringTracker
GT.sender = {}
GT.count = {}
GT.Display = {}
GT.Display.frames = {}
GT.Display.list = {}
GT.Display.length = 0
GT.DebugCount = 0

GT.metaData = {
    name = GetAddOnMetadata("GatheringTracker", "Title"),
    version = GetAddOnMetadata("GatheringTracker", "Version"),
    notes = GetAddOnMetadata("GatheringTracker", "Notes"),
}

BINDING_HEADER_GATHERINGTRACKER = GT.metaData.name .. " v" .. GT.metaData.version

function GT:OnInitialize()
--may not be used as OnEnable is likely to be better so that we can handle enable/disable without requiring a full UI reload.
end

function GT:OnEnable()
    if GT.Enabled then
        --use this for both initial setup on UI load and when the addon is enabled from the settings
        ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 ENABLED|r")
        
        --Register events for updating item details
        GT:RegisterEvent("BAG_UPDATE")
        GT:RegisterEvent("PLAYER_MONEY", "InventoryUpdate")
        GT:RegisterEvent("GROUP_ROSTER_UPDATE")
        GT:RegisterEvent("PLAYER_ENTERING_WORLD")
        
        --Register addon comm's
        GT:RegisterComm("GT_Data", "DataUpdateReceived")
        GT:RegisterComm("GT_Config", "ConfigUpdateReceived")
    else
        GT:OnDisable()
    end
end

function GT:OnDisable()
    if not GT.Enabled then
        --Use this for disabling the addon from the settings
        --stop event tracking and turn off display
        ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cffff0000 DISABLED|r")
        
        --Unregister events so that we can stop working when disabled
        GT:UnregisterEvent("BAG_UPDATE")
        GT:UnregisterEvent("PLAYER_MONEY")
        GT:UnregisterEvent("GROUP_ROSTER_UPDATE")
        GT:UnregisterEvent("PLAYER_ENTERING_WORLD")
        
        --Unregister addon comm's
        GT:UnregisterComm("GT_Data")
        GT:UnregisterComm("GT_Config")
    else
        GT:OnEnable()
    end
end

function GT:AddComas(str)
    return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

function GT:TableFind(list, str)
    for i, v in ipairs(list) do
        if str == v then
            return i
        end
    end
end

function GT:CheckIfDisplayResetNeeded(data)
    --checks if any items need to be removed from the display.
    --if an item needs to be removed from the display a full reset is required
    for _, itemData in pairs(data) do
        local total = 0
        for _, v in ipairs(itemData) do
            total = total + v
        end
        if total == 0 then
            return false
        end
    end
    return true
end

function GT.Debug(text, level, ...)
    if not GT.db.profile or GT.db.profile.General.debugOption == 0 then return end

    if level == nil then 
        level = 2
    end

    if text and level <= GT.db.profile.General.debugOption then
        GT.DebugCount = GT.DebugCount + 1
        local color = "89FF9A"
        if level == 2 then
            color = "FFD270"
        elseif level == 3 then
            color = "FF8080"
        end
        ChatFrame1:AddMessage("|cffff6f00"..GT.metaData.name..":|r |cffff0000" .. date("%X") .. "|r |cff00a0a3" .. tostring(GT.DebugCount) .. ": |r " .. strjoin(" |cff00ff00:|r ", "|cff"..color..text.."|r", tostringall(...)))
    end
end

local waitTable = {}
local waitFrame = nil

function GT:wait(delay, func, ...)
    GT.Debug("Wait Function Called", 1, delay, func)
    local timer = {
        object = self,
        func = func,
        argsCount = select("#", ...),
        delay = delay,
        args = {...}
    }

    --check if a wait timer has already been created for the called function
    for _, waitEvent in pairs(waitTable) do
        if waitEvent.func == timer.func and waitEvent.delay == timer.delay then
            GT.Debug("Wait Function Exists", 2, timer.delay, timer.func)
            return
        end
    end

    waitTable[timer] = timer

    --create the callback function so that we can pass along arguements
    timer.callback = function()
        GT.Debug("Wait Function Complete", 1, timer.delay, timer.func)
        --remove wait table entry since the timer is complete
        waitTable[timer] = nil
        --we need to know the number of args incase we ever have a use case where we need to pass a nil arg
        GT[timer.func](timer.object, unpack(timer.args, 1, timer.argsCount))
    end

    C_Timer.After(delay, timer.callback)
end

function GT:PLAYER_ENTERING_WORLD()
    GT.Debug("PLAYER_ENTERING_WORLD", 1)
    if GT.Enabled then
        GT:wait(6, "InventoryUpdate", "PLAYER_ENTERING_WORLD", true)
    end
end

function GT:GROUP_ROSTER_UPDATE(event, dontWait)
    GT.Debug("GROUP_ROSTER_UPDATE", 1, dontWait)

    --Check if we need to wait on doing the update.
    --If we do need to wait, determine if an existing wait table has already been created
    --If we dont need to wait, do the update.
    if GT.Enabled then
        if dontWait then
            if GT.db.profile.General.groupType then
                if IsInRaid() then
                    GT.groupMode = "RAID"
                else
                    GT.groupMode = "PARTY"
                end
            else
                GT.groupMode = "WHISPER"
            end

            GT.sender = {}
            GT.count = {}

            if UnitIsGroupLeader("player") then  --Only the party leader will share their settings
                GT:ShareSettings()
            end

            GT:ResetDisplay()
            GT:InventoryUpdate("GROUP_ROSTER_UPDATE", true)
        else
            GT:wait(2, "GROUP_ROSTER_UPDATE", "GROUP_ROSTER_UPDATE", true)
        end
    end
end

function GT:CreateBaseFrame()
    --this creates the basic frame structure that the addon uses.
    --the backdrop is used for positioning through the addon options.
    local frame = CreateFrame("Frame", "GT_baseFrame", UIParent)
    
    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", frame, BackdropTemplateMixin and "BackdropTemplate")
    backdrop:SetWidth(300)
    backdrop:SetHeight(300)
    backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
    backdrop:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 3, right = 3, top = 5, bottom = 3}})
    backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    backdrop:SetBackdropBorderColor(0.4, 0.4, 0.4)
    backdrop:SetFrameStrata("FULLSCREEN_DIALOG")
    
    backdrop:Hide()
    
    local container = AceGUI:Create("SimpleGroup")
    container:SetLayout("Flow")
    container:SetPoint("TOPLEFT", backdrop, "TOPLEFT")
    container:SetWidth(math.floor(GetScreenWidth()))
    container.frame:SetFrameStrata("BACKGROUND")
    if GT.ElvUI then
        if container.frame.backdrop and container.frame.backdrop.SetBackdropBorderColor then
            container.frame.backdrop:SetBackdropBorderColor(0,0,0,0)
            container.frame.backdrop:SetBackdropColor(0,0,0,0)
        elseif container.frame.SetBackdropBorderColor then
            container.frame:SetBackdropBorderColor(0,0,0,0)
            container.frame:SetBackdropColor(0,0,0,0)
        end
    end
    
    local baseFrame = {
        frame = frame,
        backdrop = backdrop,
        container = container
    }
    GT.baseFrame = baseFrame

    GT:FiltersButton()
end

function GT:FiltersButton()
    if GT.db.profile.General.filtersButton and GT:GroupCheck() and GT.Enabled then --show setting button or create it if needed
        if GT.baseFrame.button then
            GT.Debug("Show Filters Button", 1)
            GT.baseFrame.button:Show()
        else
            GT.Debug("Create Filters Button", 1)
            local filterButton = CreateFrame("Button", "GT_baseFrame_filtersButton", GT.baseFrame.frame, "UIPanelButtonTemplate")
            filterButton:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT")
            filterButton:SetWidth(25)
            filterButton:SetHeight(25)
            filterButton:SetText("F")
            filterButton:EnableMouse(true)
            filterButton:RegisterForClicks("AnyDown")
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
                                icon = tostring(GetItemIcon(tonumber(itemData.id)) or ""),
                                checked = function()
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        return true
                                    else
                                        return false
                                    end
                                end,
                                func = function()
                                    GT.Debug("Item Button Clicked", 2, expansion, category, itemData.name)
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        GT.db.profile.Filters[itemData.id] = nil
                                    else
                                        GT.db.profile.Filters[itemData.id] = true 
                                    end

                                    if GT.db.profile.General.shareSettings then
                                        GT:ShareSettings("Filters")
                                    end

                                    GT:ResetDisplay(false)
                                    GT:RebuildIDTables()
                                    GT:InventoryUpdate(expansion.." "..category.." "..itemData.name.." menu clicked", true)
                                end,
                            }
                        end
                        categoryMenuList[itemData.order] = itemDetails
                    end

                    expansionMenuList[GT.categories[category]] = {
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
                                    end
                                end
                            end
                            return checked
                        end,
                        func = function()
                            GT.Debug("Category Button Clicked", 2, expansion, category)
                            local checked = 0
                            local count = 0
                            for _, itemData in ipairs(categoryData) do
                                if itemData.id ~= -1 then
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        checked = checked + 1
                                    end
                                    GT.db.profile.Filters[itemData.id] = nil
                                    count = count + 1
                                end
                            end
                            if checked == 0 or checked < count then
                                for _, itemData in ipairs(categoryData) do
                                    if itemData.id ~= -1 then
                                        GT.db.profile.Filters[itemData.id] = true
                                    end
                                end
                            end
                            if GT.db.profile.General.shareSettings then
                                GT:ShareSettings("Filters")
                            end

                            GT:ResetDisplay(false)
                            GT:RebuildIDTables()
                            GT:InventoryUpdate(expansion.." "..category.." clicked", true)
                        end,
                    }
                end

                filterMenu[GT.expansions[expansion]] = {
                    text = expansion,
                    keepShownOnClick = true,
                    hasArrow = true,
                    notCheckable = 1,
                    menuList = expansionMenuList,
                }
            end

            menuFrame:SetPoint("CENTER", UIParent, "CENTER")
            menuFrame:Hide()

            GT.baseFrame.menu = menuFrame

            filterButton:SetScript("OnClick", 
                function (self, button, down)
                    if button == "LeftButton" then
                        EasyMenu(filterMenu, menuFrame, "cursor", 0 , 0, "MENU");
                    end
                end
            )

            GT.baseFrame.button = filterButton
        end
    else --disable setting button
        GT.Debug("Hide Filters Button", 1)
        if GT.baseFrame.button then
            GT.baseFrame.button:Hide()
        end
    end
end

function GT:ToggleBaseLock(key)
    --used to toggle if the base frame should be shown and interactable.
    --the base frame should only be shown when unlocked so that the user can position it on screen where they want.
    local frame = GT.baseFrame.backdrop
    if key then
        GT.Debug("Show baseFrame", 1)
        frame:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving();
                self.isMoving = true;
            end
        end)
        frame:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                self:StopMovingOrSizing();
                self.isMoving = false;
                local rel, _, _, xPos, yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
        frame:SetScript("OnHide", function(self)
            if (self.isMoving) then
                self:StopMovingOrSizing();
                self.isMoving = false;
                local rel, _, _, xPos, yPos = self:GetPoint()
                GT.db.profile.General.xPos = xPos
                GT.db.profile.General.yPos = yPos
                GT.db.profile.General.relativePoint = rel
            end
        end)
    else
        GT.Debug("Hide baseFrame", 1)
        frame:Hide()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
        frame:SetScript("OnHide", nil)
    end
end

InterfaceOptionsFrame:HookScript("OnHide", function()
    --[[This is called when the Interface Options Panel is closed.]]--

    --locks the base frame if the options are closed without first locking it.
    if GT.db.profile.General.unlock then
        GT.db.profile.General.unlock = false
        GT:ToggleBaseLock(false)
    end

    if GT.db.profile.General.groupType then
        if IsInRaid() then
            GT.groupMode = "RAID"
        else
            GT.groupMode = "PARTY"
        end
    else
        GT.groupMode = "WHISPER"
    end

    --call method to share settings with party
    GT:ShareSettings()

    --Do an inventory update if we dont have any information
    if #GT.count == 0 then
        GT:InventoryUpdate("InterfaceOptionsFrame:OnHide", true)
    end

    --determine if a full or partial reset is needed after closing the Interface Options
    --false will clear everything and wipe the display
    --true will reset the data and recreate the GUI
    GT:ResetDisplay(GT:GroupCheck())
end)

function GT:GroupCheck(mode)
    GT.Debug("Group Check", 2, mode)
    if mode == "Group" then
        if GT.db.profile.General.groupType and not IsInGroup() then --if Group Mode is ENABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, false)
            return false
        elseif GT.db.profile.General.groupType and IsInGroup() then --if Group Mode is ENABLED and player IS in a group
            GT.Debug("Group Check Result", 2, true)
            return true
        end
    elseif mode == "Solo" then
        if not GT.db.profile.General.groupType and IsInGroup() then  --if Group Mode is DISABLED and player IS in a group
            GT.Debug("Group Check Result", 2, false)
            return false
        elseif not GT.db.profile.General.groupType and not IsInGroup() then  --if Group Mode is DISABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, true)
            return true
        end
    elseif mode == nil then
        if GT.db.profile.General.groupType and not IsInGroup() then --if Group Mode is ENABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, false)
            return false
        elseif GT.db.profile.General.groupType and IsInGroup() then --if Group Mode is ENABLED and player IS in a group
            GT.Debug("Group Check Result", 2, true)
            return true
        elseif not GT.db.profile.General.groupType and IsInGroup() then  --if Group Mode is DISABLED and player IS in a group
            GT.Debug("Group Check Result", 2, false)
            return false
        elseif not GT.db.profile.General.groupType and not IsInGroup() then  --if Group Mode is DISABLED and player is NOT in a group
            GT.Debug("Group Check Result", 2, true)
            return true
        end
    end
end

function GT:ResetDisplay(display)
    GT.Debug("Reset Display", 1, display)
    if display == nil then display = true end
    GT.baseFrame.container:ReleaseChildren()
    GT.Display.list = {}
    GT.Display.frames = {}
    GT:FiltersButton()

    if GT.db.profile.General.enable and display and GT:GroupCheck() then
        GT:PrepareForDisplayUpdate()
    end
end

function GT:PrepareForDisplayUpdate()
    GT.Debug("Prepare for Display Update", 1)
    local globalPrice = 0
    local globalCounts = ""
    local globalTotal = 0

    GT.baseFrame.backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)

    GT.TSM = ""
    if GT.db.profile.General.tsmPrice == 0 then
        GT.TSM = "none"
    elseif GT.db.profile.General.tsmPrice == 1 then
        GT.TSM = "DBMarket"
    elseif GT.db.profile.General.tsmPrice == 2 then
        GT.TSM = "DBMinBuyout"
    elseif GT.db.profile.General.tsmPrice == 3 then
        GT.TSM = "DBHistorical"
    elseif GT.db.profile.General.tsmPrice == 4 then
        GT.TSM = "DBRegionMinBuyoutAvg"
    elseif GT.db.profile.General.tsmPrice == 5 then
        GT.TSM = "DBRegionMarketAvg"
    elseif GT.db.profile.General.tsmPrice == 6 then
        GT.TSM = "DBRegionHistorical"
    end
    
    --create player total that is displayed at the end of each item label
    --any new itemIDs that were added will be set to 0 for all other characters.
    local playerTotals = {}
    for i = 1, table.getn(GT.sender) do
        local playerTotal = 0
        GT.sender[i].totalValue = 0
        for itemID, data in pairs(GT.count) do
            if GT:TableFind(GT.IDs, tonumber(itemID)) then
                if not data[i] then
                    data[i] = 0
                end
                local value = 0
                if (data[i]-GT.db.profile.General.ignoreAmount) > 0 then
                    value = data[i]-GT.db.profile.General.ignoreAmount
                else
                    value = 0
                end
                playerTotal = playerTotal + value
                if GT.db.profile.General.tsmPrice > 0 then
                    local price = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(itemID)) or 0) / 10000
                    local totalPrice = value * price
                    GT.sender[i].totalValue = GT.sender[i].totalValue + totalPrice
                end
            end
        end
        GT.sender[i].totalValue = tonumber(string.format("%.0f", GT.sender[i].totalValue))
        if GT.db.profile.General.characterValue then
            if string.len(tostring(GT.sender[i].totalValue)) + math.ceil(string.len(tostring(GT.sender[i].totalValue))/3) >= GT.Display.length then
                GT.Display.length = string.len(tostring(GT.sender[i].totalValue)) + math.ceil(string.len(tostring(GT.sender[i].totalValue))/3) + 1
            end
        else
            if string.len(tostring(playerTotal)) + math.ceil(string.len(tostring(playerTotal))/3) > GT.Display.length  then
                GT.Display.length = string.len(tostring(playerTotal)) + math.ceil(string.len(tostring(playerTotal))/3)
            end
        end
        if GT.count["gold"] and GT.count["gold"][i] then
            local gold = GT.count["gold"][i] .. "g"
            if string.len(tostring(gold)) + math.ceil(string.len(tostring(gold))/3) > GT.Display.length  then
                GT.Display.length = string.len(tostring(gold)) + math.ceil(string.len(tostring(gold))/3)
            end
        end
        playerTotals[i] = playerTotal
        globalTotal = globalTotal + playerTotal
    end
    for i, t in ipairs(playerTotals) do
        globalCounts = globalCounts .. string.format("%-" .. GT.Display.length  .. "s", GT:AddComas(string.format("%.0f", (t))))
    end

    --call method to determine if we need to reset or can update
    local update = GT:CheckIfDisplayResetNeeded(GT.count)
    --release all of the container children so we can rebuild
    if not update then
        GT.baseFrame.container:ReleaseChildren()
        GT.Display.list = {}
        GT.Display.frames = {}
    end

    for _, id in ipairs(GT.IDs) do  --create the data needed to create the item labels
        if GT.count[tostring(id)] then
            if string.match(tostring(id), "(%a)") then
                --If the ID includes any letters, we need to handle it differently
                local data = GT.count[tostring(id)]
                local counts = ""
                for i, v in ipairs(data) do
                    counts = counts .. string.format("%-" .. GT.Display.length  .. "s", GT:AddComas(string.format("%.0f", (v))) .. ((id == "gold" and "g") or ""))
                end
                local iconID, order
                for _, otherData in ipairs(GT.ItemData.Other.Other) do
                    if otherData.id == id then
                        iconID = otherData.icon
                        order = otherData.order * -1
                    end
                end
                GT:UpdateDisplay(order, counts, iconID)
            else
                local data = GT.count[tostring(id)]
                local counts = ""
                local total = 0
                for i, v in ipairs(data) do
                    local value = 0
                    if (v-GT.db.profile.General.ignoreAmount) > 0 then
                        value = v-GT.db.profile.General.ignoreAmount
                    else
                        value = 0
                    end
                    counts = counts .. string.format("%-" .. GT.Display.length  .. "s", GT:AddComas(string.format("%.0f", (value))))
                    total = total + value
                end
                
                if total > 0 then
                    local text = counts
                    if GT.db.profile.General.groupType == true then
                        text = text .. "[" .. string.format("%-" .. (GT.Display.length  + 2) .. "s", GT:AddComas(string.format("%.0f", (total))) .. "]")
                    end
                    if GT.db.profile.General.tsmPrice > 0 then
                        local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(id)) or 0) / 10000
                        local tprice = total * eprice
                        globalPrice = globalPrice + tprice
                        
                        if GT.db.profile.General.perItemPrice then
                            text = text .. "{" .. string.format("%-" .. (GT.Display.length  + 2) .. "s", GT:AddComas(string.format("%.0f", (eprice))) .. "g}")
                        end
                        
                        text = text .. "(" .. GT:AddComas(string.format("%.0f", (tprice))) .. "g)"
                    end
                    
                    local iconID = GetItemIcon(id)

                    --call method to create frame
                    GT:UpdateDisplay(id, text, iconID)
                end
            end
        end
    end

    
    if globalTotal > 0 then
        --create the text string for the totals row and create the widget
        local totalText = globalCounts
        local totalStack
        if GT.db.profile.General.groupType == true then
            totalText = totalText.."["  .. string.format("%-"..(GT.Display.length +2).."s",GT:AddComas(string.format("%.0f",(globalTotal))) .. "]")
        end
        if GT.db.profile.General.tsmPrice > 0 then
            if GT.db.profile.General.perItemPrice then
                totalText = totalText .. string.format("%-"..(GT.Display.length +3).."s","")
            end
            totalText = totalText.."(" .. GT:AddComas(string.format("%.0f",(globalPrice))) .. "g)"
        end
        if totalText == "" then
            totalText = "Setup"
        end
        GT:UpdateDisplay(9999999998, totalText, 133647)
    end

    --This is for the character gathered value row
    if GT.db.profile.General.characterValue and GT:GroupCheck("Group") then
        --create the text string for the per character value row and create widget
        local valueText = ""
        for i, senderData in ipairs(GT.sender) do
            valueText = valueText .. string.format("%-" .. GT.Display.length  .. "s", GT:AddComas(string.format("%.0f", (senderData.totalValue))) .. "g")
        end
        if valueText == "" then
            valueText = "Setup"
        end
        GT:UpdateDisplay(9999999999, valueText, 133784)  --old icon 133785
    end

    if GT.db.profile.General.displayAlias and GT:GroupCheck("Group") then
        --create the text string for the alias row and create the widget
        local nameText = ""
        for i, senderData in ipairs(GT.sender) do
            local exists = 0
            for index, aliases in pairs(GT.db.profile.Aliases) do
                if aliases.name == senderData.name then
                    exists = index
                end
            end
            if exists > 0 then
                local newText = string.sub(GT.db.profile.Aliases[exists].alias, 0, (GT.Display.length-1))  --should the -1 be removed?  This needs more testing.
                local extrsSpace = string.len(newText)
                nameText = nameText..newText..string.format("%-"..(GT.Display.length - extrsSpace).."s","")
            else
                local newText = string.sub(senderData.name, 0, (GT.Display.length-1))
                local extrsSpace = string.len(newText)
                nameText = nameText..newText..string.format("%-"..(GT.Display.length - extrsSpace).."s","")
            end
        end
        if nameText == "" then
            nameText = "Setup"
        end
        GT:UpdateDisplay(-9999999999, nameText, 413577)
    end
end

function GT:UpdateDisplay(index, name, icon)
    GT.Debug("Update Display", 3, index, name, icon)
    if not GT.Display.frames[index] then
        if index < 999999999 then
            --create labels for items
            local label = AceGUI:Create("Label")
            label:SetText(name)
            label:SetColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2], GT.db.profile.General.textColor[3])
            label:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
            label:SetImage(icon)
            label:SetImageSize(GT.db.profile.General.iconWidth, GT.db.profile.General.iconHeight)
            
            table.insert(GT.Display.list, index)
            table.sort(GT.Display.list)
            local position = GT:TableFind(GT.Display.list, index)
            local beforeWidget = nil
            if GT.Display.frames[GT.Display.list[(position+1)]] then
                beforeWidget = GT.Display.frames[GT.Display.list[(position+1)]]
            end
            GT.Display.frames[index] = label
            if beforeWidget then
                GT.baseFrame.container:AddChild(GT.Display.frames[index], beforeWidget)
            else
                GT.baseFrame.container:AddChild(GT.Display.frames[index])
            end
            GT.Display.frames[index]:SetFullWidth(true)
            GT.baseFrame.container:DoLayout()
        else
            --create totals label, may also use for additional labels that are not based on items (i.e. player total price)
            local label = AceGUI:Create("Label")
            label:SetText(name)
            label:SetColor(GT.db.profile.General.totalColor[1], GT.db.profile.General.totalColor[2], GT.db.profile.General.totalColor[3])
            label:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
            label:SetImage(icon)
            label:SetImageSize(GT.db.profile.General.iconWidth, GT.db.profile.General.iconHeight)
            
            table.insert(GT.Display.list, index) --adds our index to the list table.  This table is sorted and used to determine display order
            table.sort(GT.Display.list)
            local position = GT:TableFind(GT.Display.list, index)
            local beforeWidget = nil
            if GT.Display.frames[GT.Display.list[(position+1)]] then  --checks if there is a widget after our position
                beforeWidget = GT.Display.frames[GT.Display.list[(position+1)]]
            end
            GT.Display.frames[index] = label  --adds label to the frames table so we can keep track of it later on
            if beforeWidget then  --adds our widget to the container based on if there is another widget after us
                GT.baseFrame.container:AddChild(GT.Display.frames[index], beforeWidget)
            else
                GT.baseFrame.container:AddChild(GT.Display.frames[index])
            end
            GT.Display.frames[index]:SetFullWidth(true)
            GT.baseFrame.container:DoLayout()
        end
    else
        --update the text of existing labels
        GT.Display.frames[index]:SetText(name)
    end
end

function GT:RebuildIDTables()
    GT.Debug("Rebuild ID Table", 1)
    GT.IDs = {}
    for key, value in pairs(GT.db.profile.Filters) do
        table.insert(GT.IDs, key)
    end
    if GT.db.profile.CustomFilters then
        for itemID in string.gmatch(GT.db.profile.CustomFilters, "%S+") do
            itemID = tonumber(itemID)
            if not GT.db.profile.Filters[itemID] then
                table.insert(GT.IDs, itemID)
            end
        end
    end
end

function GT:BAG_UPDATE()
    GT:InventoryUpdate("BAG_UPDATE")
end

function GT:InventoryUpdate(event, dontWait)
    GT.Debug("InventoryUpdate", 1, event, dontWait)
    if dontWait then
        if event ~= nil then
            if GT:GroupCheck() and GT.Enabled then
                local total = 0
                local messageText = ""
                
                for i, id in ipairs(GT.IDs) do
                    local count = 0
                    if string.match(tostring(id), "(%a)") then
                        if tostring(id) == "gold" then
                            count = math.floor((GetMoney()/10000)+0.5)
                        elseif tostring(id) == "bag" then
                            for i = 0, 4 do
                                count = count + GetContainerNumFreeSlots(i)
                            end
                        end
                    else
                        count = (GetItemCount(id, GT.db.profile.General.includeBank, false))
                    end

                    if count > 0 then
                        total = total + count
                        messageText = messageText .. id .. "=" .. count
                        
                        local size = #GT.IDs
                        if i < size then
                            messageText = messageText .. " "
                        end
                    end
                end

                if GT.db.profile.General.groupType then
                    if IsInRaid() then
                        GT.groupMode = "RAID"
                    else
                        GT.groupMode = "PARTY"
                    end
                else
                    GT.groupMode = "WHISPER"
                end

                if total > 0 then
                    if GT.groupMode == "WHISPER" then
                        GT.Debug("Sent Solo Message", 2, messageText, GT.groupMode, UnitName("player"))
                        GT:SendCommMessage("GT_Data", messageText, GT.groupMode, UnitName("player"), "NORMAL", GT.Debug, "AceComm Sent Solo Message")
                    else
                        GT.Debug("Sent Group Message", 2, messageText, GT.groupMode)
                        GT:SendCommMessage("GT_Data", messageText, GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Group Message")
                    end
                elseif total == 0 then
                    if GT.groupMode == "WHISPER" then
                        GT:SendCommMessage("GT_Data", "reset", GT.groupMode, UnitName("player"), "NORMAL", GT.Debug, "AceComm Sent Solo Reset Message")
                    else
                        GT:SendCommMessage("GT_Data", "reset", GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Group Reset Message")
                    end
                end
            else
                GT.Debug("Disabled or Group Check Failed, No Message Sent", 2)
            end
        else
            local traceback = debugstack()
            GT.Debug(traceback, 1, event)
        end
    else
        GT:wait(0.1, "InventoryUpdate", "InventoryUpdate", true)
    end
end

function GT:DataUpdateReceived(prefix, message, distribution, sender)
    GT.Debug("Data Update Received", 3, prefix, message)
    --only process received messages if we are endabled and are in a group with group mode on or are solo with group mode off
    if GT:GroupCheck() and GT.Enabled then
        GT.Debug("Data Update Being Processed", 1)
        GT.Display.length = 0
        --determine sender index or add sender if they dont exist
        local SenderExists = false
        local senderIndex
        for index, data in ipairs(GT.sender) do
            if data.name == sender then
                SenderExists = true
                senderIndex = index
            end
        end
        if not SenderExists then
            local senderTable = {
                name = sender,
                inGroup = false,
                totalValue = 0,
            }
            if UnitInParty(sender) or UnitInRaid(sender) then
                senderTable.inGroup = true
            end

            table.insert(GT.sender, senderTable)
            senderIndex = #GT.sender
        end
        
        if message == "reset" then
            for itemID, data in pairs(GT.count) do
                if GT.count[itemID][senderIndex] then
                    GT.count[itemID][senderIndex] = 0
                end
            end
        else
            --create messageText table
            local str = " " .. message .. "\n"
            str = str:gsub("%s(%S-)=", "\n%1=")
            local messageText = {}
            for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
                messageText[itemID] = value

                --add message data to counts
                if GT.count[itemID] then
                    GT.count[itemID][senderIndex] = tonumber(messageText[itemID])
                else
                    GT.count[itemID] = {}
                    GT.count[itemID][senderIndex] = tonumber(messageText[itemID])
                end
            end

            --loop existing counts to update, set to 0 if not in message
            for itemID, data in pairs(GT.count) do
                if not messageText[itemID] then
                    GT.count[itemID][senderIndex] = 0
                end
            end
        end

        GT:wait(0.4, "PrepareForDisplayUpdate", "Data Update Received", true)
    elseif GT.Enabled then  --process reset messages if we are enabled but didn't pass the earlier check to display
        GT.Debug("Group Check Failed but Enabled, Process reset messages only", 1)
        local SenderExists = false
        local senderIndex
        for index, data in ipairs(GT.sender) do
            if data.name == sender then
                SenderExists = true
                senderIndex = index
            end
        end
        if not SenderExists then
            local senderTable = {
                name = sender,
                inGroup = false,
                totalValue = 0,
            }
            if UnitInParty(sender) or UnitInRaid(sender) > 0 then
                senderTable.inGroup = true
            end

            table.insert(GT.sender, senderTable)
            senderIndex = #GT.sender
        end
        if message == "reset" then
            for itemID, data in pairs(GT.count) do
                if GT.count[itemID][senderIndex] then
                    GT.count[itemID][senderIndex] = 0
                end
            end
        end
    end
end

function GT:ShareSettings(mode)
    if GT.Enabled and GT.db.profile.General.shareSettings and GT:GroupCheck("Group") then
        --loop through the setting categories, create a string, and send that string to the party
        GT.Debug("Prepare to share settings", 1)
        if mode == nil then 
            mode = "All" 
        end
        GT.Debug("Send Settings Mode", 2, mode)
        for category,categoryData in pairs(GT.db.profile) do
            GT.Debug("Send Settings category", 2, category)
            if mode == "All" or mode == category then
                local messageText = tostring(category) .. ":"
                if category == "CustomFilters" then
                    messageText = messageText .. categoryData
                elseif category == "Aliases" then
                    for _, data in ipairs(categoryData) do
                        messageText = messageText .. " " .. data.name .. "=" .. data.alias
                    end
                else
                    for setting, value in pairs(categoryData) do
                        if type(value) == "table" then
                            local tableText = ""
                            for _,v in ipairs(value) do
                                tableText = tableText .. v .. ","
                            end
                            tableText = string.sub(tableText,0, string.len(tableText)-1)
                            messageText = messageText .. " " .. setting .. "=" .. tableText
                        else
                            messageText = messageText .. " " .. setting .. "=" .. tostring(value)
                        end
                    end
                end
            GT.Debug("Send Settings", 3, messageText, GT.groupMode)
            GT:SendCommMessage("GT_Config", messageText, GT.groupMode, nil, "NORMAL", GT.Debug, "AceComm Sent Config Message")
            end
        end
    end
end

function GT:ConfigUpdateReceived(prefix, message, distribution, sender)
    GT.Debug("Received Config Message", 3, prefix, message, sender)

    if sender ~= GT.Player then  --ignores settings sent from the player
        GT.Debug("Processing Config Message", 2, sender)
        --determine the category so we can save the settings to the right place
        local category = message:sub(0, string.find(message, ":")-1)
        --remove the category from the settings
        message = string.sub(message, string.find(message, ":")+1)

        if category == "CustomFilters" then
            GT.db.profile[category] = message
        else
            local str = message .. "\n"
            str = str:gsub("%s(%S-)=", "\n%1=")
            local messageText = {}

            if category == "General" then
                for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
                    messageText[itemID] = value
                end

                for setting,value in pairs(messageText) do
                    if tonumber(value) then
                        GT.db.profile.General[setting] = tonumber(value)
                    elseif value == "true" then
                        GT.db.profile.General[setting] = true
                    elseif value == "false" then
                        GT.db.profile.General[setting] = false
                    elseif string.find(value, ",") then
                        GT.db.profile.General[setting] = {}
                        for v in string.gmatch(value, "([^,]+)") do
                            table.insert(GT.db.profile.General[setting], tonumber(v))
                        end
                    else
                        GT.db.profile.General[setting] = value
                    end
                end
            elseif category == "Filters" then
                for itemID, value in string.gmatch(str, "(%S-)=(.-)\n") do
                    if string.match(tostring(itemID), "(%a)") then
                        messageText[itemID] = true
                    else
                        messageText[tonumber(itemID)] = true
                    end
                end
                GT.db.profile[category] = messageText
            elseif category == "Aliases" then
                for n, a in string.gmatch(str, "(%S-)=(.-)\n") do
                    table.insert(messageText,{name = n, alias = a})
                end
                GT.db.profile[category] = messageText
            end
        end
        if GT.db.profile.General.xPos ~= GT.db.defaults.profile.General.xPos or GT.db.profile.General.yPos ~= GT.db.defaults.profile.General.yPos then
            GT.baseFrame.backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)
        end
        
        GT:ResetDisplay(false)
        GT:RebuildIDTables()
        GT:InventoryUpdate("Config Update Received")
    end
end
