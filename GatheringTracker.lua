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

GT.metaData = {
    name = GetAddOnMetadata("GatheringTracker", "Title"),
    version = GetAddOnMetadata("GatheringTracker", "Version"),
    notes = GetAddOnMetadata("GatheringTracker", "Notes"),
}

function GT:OnInitialize()
--may not be used as OnEnable is likely to be better so that we can handle enable/disable without requiring a full UI reload.
end

function GT:OnEnable()
    GT.Enabled = true
    --use this for both initial setup on UI load and when the addon is enabled from the settings
    ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 ENABLED|r")
    
    --Register events for updating item details
    GT:RegisterEvent("BAG_UPDATE", "InventoryUpdate")
    GT:RegisterEvent("GROUP_ROSTER_UPDATE")
    GT:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    --Register addon comm's
    GT:RegisterComm("GT_Data", "DataUpdateReceived")
    GT:RegisterComm("GT_Config", "ConfigUpdateReceived")
end

function GT:OnDisable()
    GT.Enabled = false
    --Use this for disabling the addon from the settings
    --stop event tracking and turn off display
    ChatFrame1:AddMessage("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cffff0000 DISABLED|r")
    
    --Unregister events so that we can stop working when disabled
    GT:UnregisterEvent("BAG_UPDATE")
    GT:UnregisterEvent("GROUP_ROSTER_UPDATE")
    GT:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    --Unregister addon comm's
    GT:UnregisterComm("GT_Data")
    GT:UnregisterComm("GT_Config")
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

function GT:Debug(text, ...)
    if not GT.db.profile or not GT.db.profile.General.debugOption then return end

    if text then
        ChatFrame1:AddMessage("|cffff6f00"..GT.metaData.name..":|r |cffff0000" .. date("%X") .. "|r " .. strjoin(" |cff00ff00:|r ", text, tostringall(...)))
    end
end

local waitTable = {}
local waitFrame = nil

function GT:wait(delay, func, ...)
    GT:Debug("Wait Function Called", delay, func)
    if type(delay) ~= "number" then
        GT:Debug("Wait Function return false", type(delay), type(func))
        return false
    end
    if not waitFrame then
        GT:Debug("Wait Function create frame")
        waitFrame = CreateFrame("Frame", nil, UIParent)
        waitFrame:SetScript("OnUpdate", function (self, elapse)
            for i = 1, #waitTable do
            local waitRecord = tremove(waitTable, i)
            local d = tremove(waitRecord, 1)
            local f = tremove(waitRecord, 1)
            local p = tremove(waitRecord, 1)
            if d > elapse then
                tinsert(waitTable, i, {d - elapse, f, p})
                i = i + 1
            else
                --count = count - 1
                GT:Debug("Wait Function call function",f, unpack(p))
                GT[f](self,unpack(p))
            end
            end
        end)
    end
    tinsert(waitTable, {delay, func, {...}})
    return true
end

function GT:PLAYER_ENTERING_WORLD()
    GT:Debug("PLAYER_ENTERING_WORLD")
    GT:wait(6, "InventoryUpdate", "PLAYER_ENTERING_WORLD")
end

function GT:GROUP_ROSTER_UPDATE()
    GT:Debug("GROUP_ROSTER_UPDATE")
    GT:ResetDisplay()
    GT:InventoryUpdate("GROUP_ROSTER_UPDATE")
end

function GT:CreateBaseFrame()
    --this creates the basic frame structure that the addon uses.
    --the backdrop is used for positioning through the addon options.
    local frame = CreateFrame("Frame", "GT_baseFrame", UIParent)
    
    local backdrop = CreateFrame("Frame", "GT_baseFrame_backdrop", frame)
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
        if container.frame.SetBackdropBorderColor then
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
    --(GT.db.profile.General.groupType and IsInGroup() and GT.Enabled) or (not GT.db.profile.General.groupType and not IsInGroup() and GT.Enabled)
    if GT.db.profile.General.filtersButton and GT:GroupCheck() and GT.Enabled then --show setting button or create it if needed
        if GT.baseFrame.button then
            GT:Debug("Show Filters Button")
            GT.baseFrame.button:Show()
        else
            GT:Debug("Create Filters Button")
            local filterButton = CreateFrame("Button", "GT_baseFrame_filtersButton", GT.baseFrame.frame, "UIPanelButtonTemplate")
            filterButton:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT")
            filterButton:SetWidth(25)
            filterButton:SetHeight(25)
            filterButton:SetText("F")
            filterButton:EnableMouse(true)
            filterButton:RegisterForClicks("AnyDown")
            filterButton:Show()

            local menuFrame = CreateFrame("Frame", "GT_baseFrame_filtersMenu", UIParent, "UIDropDownMenuTemplate")

            filterMenu = {}
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
                                checked = function()
                                    if GT.db.profile.Filters[itemData.id] == true then
                                        return true
                                    else
                                        return false
                                    end
                                end,
                                func = function()
                                    GT:Debug("Item Button Clicked", expansion, category, itemData.name)
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
                                    GT:InventoryUpdate(expansion.." "..category.." "..itemData.name.." menu clicked")
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
                            GT:Debug("Category Button Clicked", expansion, category)
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
                            GT:InventoryUpdate(expansion.." "..category.." clicked")
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
        GT:Debug("Hide Filters Button")
        GT.baseFrame.button:Hide()
    end
end

function GT:ToggleBaseLock(key)
    --used to toggle if the base frame should be shown and interactable.
    --the base frame should only be shown when unlocked so that the user can position it on screen where they want.
    local frame = GT.baseFrame.backdrop
    if key then
        GT:Debug("Show baseFrame")
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
        GT:Debug("Hide baseFrame")
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

    --call method to share settings with party
    GT:ShareSettings()

    --determine if a full or partial reset is needed after closing the Interface Options
    --false will clear everything and wipe the display
    --true will reset the data and recreate the GUI
    GT:ResetDisplay(GT:GroupCheck())
end)

function GT:GroupCheck()
    if GT.db.profile.General.groupType and not IsInGroup() then --if Group Mode is ENABLED and player is NOT in a group
        return false
    elseif GT.db.profile.General.groupType and IsInGroup() then --if Group Mode is ENABLED and player IS in a group
        return true
    elseif not GT.db.profile.General.groupType and IsInGroup() then  --if Group Mode is DISABLED and player IS in a group
        return false
    elseif not GT.db.profile.General.groupType and not IsInGroup() then  --if Group Mode is DISABLED and player is NOT in a group
        return true
    end
end

function GT:ResetDisplay(display)
    if display == nil then display = true end
    GT:Debug("Reset Display")
    GT.baseFrame.container:ReleaseChildren()
    GT.Display.list = {}
    GT.Display.frames = {}
    GT:FiltersButton()

    if GT.db.profile.General.enable and display and GT:GroupCheck() then
        GT:PrepareForDisplayUpdate()
    end
end

function GT:PrepareForDisplayUpdate()
    GT:Debug("Prepare for Display Update")
    local globalPrice = 0
    local globalCounts = ""
    local globalTotal = 0

    GT.baseFrame.backdrop:SetPoint(GT.db.profile.General.relativePoint, UIParent, GT.db.profile.General.relativePoint, GT.db.profile.General.xPos, GT.db.profile.General.yPos)

    --set length if not yet set
    if GT.Display.length == 0 then
        GT.Display.length = 4
    end

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
            end
        end
        if string.len(tostring(playerTotal)) + 1 > GT.Display.length  then
            GT.Display.length  = string.len(tostring(playerTotal)) + 1
        end
        playerTotals[i] = playerTotal
        globalTotal = globalTotal + playerTotal
    end
    for i, t in ipairs(playerTotals) do
        globalCounts = globalCounts .. string.format("%-" .. GT.Display.length  .. "s", t)
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
                counts = counts .. string.format("%-" .. GT.Display.length  .. "s", value)
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

    
    if globalTotal > 0 then
        --create the text string for the totals row and create it
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
        GT:UpdateDisplay(9999999999, totalText, 133785)
    end
    --consider adding logic to add header row, and character total earned row.
end

function GT:UpdateDisplay(index, name, icon)
    GT:Debug("Update Display", index, name, icon)
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
        end
    else
        --update the text of existing labels
        GT.Display.frames[index]:SetText(name)
    end
end

function GT:RebuildIDTables()
    GT:Debug("Rebuild ID Table")
    --Not using IDsArray from WA as it will be replaced by the frame structure
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

function GT:InventoryUpdate(event)
    if event ~= nil then
        GT:Debug("InventoryUpdate", event)
        local total = 0
        local messageText = ""
        
        for i, id in ipairs(GT.IDs) do
            local count = (GetItemCount(id, GT.db.profile.General.includeBank, false))
            
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
            GT.groupMode = "RAID"
        else
            GT.groupMode = "WHISPER"
        end

        if total > 0 then
            if GT.groupMode == "WHISPER" then
                GT:Debug("Sent Solo Message")
                GT:SendCommMessage("GT_Data", messageText, GT.groupMode, UnitName("player"))
            else
                GT:Debug("Sent Group Message")
                GT:SendCommMessage("GT_Data", messageText, GT.groupMode)
            end
        elseif total == 0 then
            if GT.groupMode == "WHISPER" then
                GT:SendCommMessage("GT_Data", "reset", GT.groupMode, UnitName("player"))
            else
                GT:SendCommMessage("GT_Data", "reset", GT.groupMode)
            end
        end
    else
        local traceback = debugstack()
        GT:Debug(traceback, event)
    end
end

function GT:DataUpdateReceived(prefix, message, distribution, sender)
    GT:Debug("Data Update Received", prefix, message)
    --only process received messages if we are endabled and are in a group with group mode on or are solo with group mode off
    if (GT.db.profile.General.groupType and IsInGroup() and GT.Enabled) or (not GT.db.profile.General.groupType and not IsInGroup() and GT.Enabled) then
        GT:Debug("Data Update Being Processed")
        GT.Display.length = 0
        --determine sender index or add sender if they dont exist
        local SenderExists = false
        local senderIndex
        for i, s in ipairs(GT.sender) do
            if s == sender then
                SenderExists = true
                senderIndex = i
            end
        end
        if not SenderExists then
            table.insert(GT.sender, sender)
            senderIndex = table.getn(GT.sender)
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

                --set length for display
                if string.len(tostring(value)) + 1 > GT.Display.length  then
                    GT.Display.length  = string.len(tostring(value)) + 1
                end
            end

            --loop existing counts to update, set to 0 if not in message
            for itemID, data in pairs(GT.count) do
                if not messageText[itemID] then
                    GT.count[itemID][senderIndex] = 0
                end
            end
        end
        GT:PrepareForDisplayUpdate()
    elseif GT.Enabled then  --process reset messages if we are enabled but didn't pass the earlier check to display
        local SenderExists = false
        local senderIndex
        for i, s in ipairs(GT.sender) do
            if s == sender then
                SenderExists = true
                senderIndex = i
            end
        end
        if not SenderExists then
            table.insert(GT.sender, sender)
            senderIndex = table.getn(GT.sender)
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
    if GT.Enabled and GT.db.profile.General.shareSettings then
        --loop through the setting categories, create a string, and send that string to the party
        GT:Debug("Prepare to share settings")
        if mode == nil then 
            mode = "All" 
        end
        for category,categoryData in pairs(GT.db.profile) do
            if mode == "All" or mode == category then
                local messageText = tostring(category) .. ":"
                if category == "CustomFilters" then
                    messageText = messageText .. categoryData
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
            GT:Debug("Send Settings")
            GT:SendCommMessage("GT_Config", messageText, GT.groupMode)
            end
        end
    end
end

function GT:ConfigUpdateReceived(prefix, message, distribution, sender)
    GT:Debug("Received message", prefix, message)

    if not (sender == UnitName("player")) then  --ignores settings sent from the player
        GT:Debug("Processing Config Message")
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
                    messageText[tonumber(itemID)] = true
                end
                GT.db.profile[category] = messageText
            end
        end
        GT:ResetDisplay(false)
        GT:RebuildIDTables()
        GT:InventoryUpdate("Config Update Received")
    end
end

function GT:SendAddonComm(prefix, message, distribution, target)
    --Use this for sending addon comms with AceComm
end
