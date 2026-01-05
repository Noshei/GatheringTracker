---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

-- Localize global functions
local ipairs = ipairs
local pairs = pairs
local select = select
local table = table
local tonumber = tonumber
local tostring = tostring
local tostringall = tostringall
local type = type
local unpack = unpack

function GT:AddComas(str)
    return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

---Simple table find function to find a value in a table and return the teble index of the item
---@param list table The table to search in
---@param str integer|string the value to search for in the table
---@param key? integer|string if the table values are tables as well this is the key to check in the inner table for the search string
---@return integer|nil index the table index for the search string or nil if it isn't found
function GT:TableFind(list, str, key)
    for i, v in ipairs(list) do
        if type(v) == "table" then
            if tostring(str) == tostring(v[key]) then
                return i
            end
        else
            if tostring(str) == tostring(v) then
                return i
            end
        end
    end
end

---Gets the number of key,value pairs in an array
---@param array table
---@return number
function GT:GetArraySize(array)
    local size = 0
    for _, _ in pairs(array) do
        size = size + 1
    end
    return size
end

---Converts decimal RGB to Hexcode
---@param r number
---@param g number
---@param b number
---@param a? number
---@return string Hexcode
function GT:RGBtoHex(r, g, b, a)
    r = Round(r * 255)
    g = Round(g * 255)
    b = Round(b * 255)
    local hex = ("%.2X%.2X%.2X"):format(r, g, b)
    if a then
        a = Round(a * 255)
        hex = ("%.2X%.2X%.2X%.2X"):format(a, r, g, b)
    end
    return hex
end

function GT.Debug(text, level, ...)
    if not GT.db.profile or GT.db.profile.General.debugOption == 0 then
        return
    end

    if level == nil then
        level = 2
    end

    if text and level <= GT.db.profile.General.debugOption then
        GT.DebugCount = GT.DebugCount + 1
        local color = "89FF9A" --#89FF9A
        if level == 2 then
            color = "FFD270"   --#FFD270
        elseif level == 3 then
            color = "FF8080"   --#FF8080
        elseif level == 4 then
            color = "E300DB"   --#E300DB
        elseif level == 5 then
            color = "3990FA"   --#3990FA
        elseif level == 6 then
            color = "D9041D"   --#D9041D
        end
        ChatFrame1:AddMessage(
            "|cffff6f00"        --#ff6f00
            .. GT.metaData.name
            .. ":|r |cffff0000" --#ff0000
            .. date("%X")
            .. "|r |cff00a0a3"  --#00a0a3
            .. tostring(GT.DebugCount)
            .. ": |r "
            .. strjoin(" |cff00ff00:|r ", "|cff" .. color .. text .. "|r", tostringall(...)) --#00ff00
        )
    end
end

function GT:wait(delay, func, ...)
    GT.waitTable = GT.waitTable or {}

    GT.Debug("Wait Function Called", 1, delay, func)
    local timer = {
        object = self,
        func = func,
        argsCount = select("#", ...),
        delay = delay,
        args = { ... },
    }

    --if delay is nil, cancel existing wait function
    if delay == nil then
        for _, waitEvent in pairs(GT.waitTable) do
            if waitEvent.func == timer.func then
                GT.Debug("Wait Function Cancelled", 2, timer.delay, timer.func, waitEvent)
                GT.waitTable[waitEvent] = nil
                return
            end
        end
        GT.Debug("Wait Function: Nothing to Cancel ", 2, timer.delay, timer.func)
        return
    end

    --check if a wait timer has already been created for the called function
    for _, waitEvent in pairs(GT.waitTable) do
        if waitEvent.func == timer.func and waitEvent.delay >= timer.delay then
            GT.Debug("Wait Function Exists", 2, timer.delay, timer.func)
            return
        end
    end

    GT.waitTable[timer] = timer

    --create the callback function so that we can pass along arguements
    timer.callback = function()
        if GT.waitTable[timer] then --check if the wait table exists, if it doesn't then this timer was cancelled.
            GT.Debug("Wait Function Complete", 1, timer.delay, timer.func, GT.waitTable[timer])
            --remove wait table entry since the timer is complete
            GT.waitTable[timer] = nil
            --we need to know the number of args incase we ever have a use case where we need to pass a nil arg
            GT[timer.func](timer.object, unpack(timer.args, 1, timer.argsCount))
        end
    end

    C_Timer.After(delay, timer.callback)
end

function GT:SetTSMPriceSource()
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
    elseif GT.db.profile.General.tsmPrice == 7 then
        GT.TSM = "DBRecent"
    end
end

function GT:IsInGroup()
    -- Extention of IsInGroup to return false when in follower dungeons
    if C_LFGInfo.IsInLFGFollowerDungeon() == true then
        return false
    end
    if select(3, GetInstanceInfo()) == 208 then
        return false
    end
    return IsInGroup()
end

---Determins if the display should be shown or hidden based on the Auto Hide Options
---@return boolean DisplayVisibility true to show the display or false to hide it
function GT:DisplayVisibility()
    local instance = IsInInstance()
    local group = IsInGroup()
    local follower = C_LFGInfo.IsInLFGFollowerDungeon()
    local delve = select(3, GetInstanceInfo()) == 208

    if GT.db.profile.General.combatHide and GT.combat then
        return false
    end

    if group and GT.db.profile.General.groupHide then
        if delve and GT.db.profile.General.showDelve then
            GT.Debug("DisplayVisibility", 1, "Group", "Delve", group,
                GT.db.profile.General.groupHide, delve, GT.db.profile.General.showDelve)
            return true
        end
        if follower and GT.db.profile.General.showFollower then
            GT.Debug("DisplayVisibility", 1, "Group", "Follower", group,
                GT.db.profile.General.groupHide, follower, GT.db.profile.General.showFollower)
            return true
        end
        GT.Debug("DisplayVisibility", 1, "Group", group,
            GT.db.profile.General.groupHide)
        return false
    end
    if instance and GT.db.profile.General.instanceHide then
        if delve and GT.db.profile.General.showDelve then
            GT.Debug("DisplayVisibility", 1, "Instance", "Delve", instance,
                GT.db.profile.General.instanceHide, delve, GT.db.profile.General.showDelve)
            return true
        end
        if follower and GT.db.profile.General.showFollower then
            GT.Debug("DisplayVisibility", 1, "Instance", "Follower", instance,
                GT.db.profile.General.instanceHide, follower, GT.db.profile.General.showFollower)
            return true
        end
        GT.Debug("DisplayVisibility", 1, "Instance", instance,
            GT.db.profile.General.instanceHide)
        return false
    end
    GT.Debug("DisplayVisibility", 1, "fallback", instance, GT.db.profile.General.instanceHide,
        group, GT.db.profile.General.groupHide, follower,
        GT.db.profile.General.showFollower, delve, GT.db.profile.General.showDelve)
    return true
end

function GT:GetUnitFullName(UnitId)
    local name, realm = UnitNameUnmodified(UnitId)
    local fullName = name
    if realm then
        fullName = fullName .. "-" .. realm
    end
    return fullName
end

function GT:GetGroupList()
    local plist = {}
    if IsInRaid() then
        for i = 1, 40 do
            local fullName = GT:GetUnitFullName('raid' .. i)
            if fullName then
                table.insert(plist, fullName)
            end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            local fullName = GT:GetUnitFullName('party' .. i)
            if fullName then
                table.insert(plist, fullName)
            end
        end
    end
    if #plist == 0 then
        return nil
    end
    return plist
end

function GT:SumTable(table)
    local sum = 0
    for index, number in ipairs(table) do
        sum = sum + number
    end
    return sum
end

---This function adds or removes a single item from the GT.IDs table
---@param itemID integer Id of the item to take action on
---@param action boolean true to add an item to the IDs table, false to remove and item from the table
function GT:UpdateIDTable(itemID, action)
    GT.Debug("Update ID Table", 1, itemID, action)
    local position = GT:TableFind(GT.IDs, itemID, "id")
    if action and not position then
        local item = {
            id = itemID,
            processed = false
        }
        table.insert(GT.IDs, item)
    elseif not action and position then
        table.remove(GT.IDs, position)
    end
end

function GT:RebuildIDTables()
    GT.Debug("Rebuild ID Table", 1)
    GT.IDs = {}
    for key in pairs(GT.db.profile.Filters) do
        local item = {
            id = key,
            processed = false
        }
        table.insert(GT.IDs, item)
    end
    if GT.db.profile.CustomFiltersTable then
        for itemID, value in pairs(GT.db.profile.CustomFiltersTable) do
            if value then
                itemID = tonumber(itemID)
                local item = {
                    id = itemID,
                    processed = false
                }
                if not GT.db.profile.Filters[itemID] then
                    table.insert(GT.IDs, item)
                end
            end
        end
    end
end

function GT:CheckColumnSize(index, frame, itemID)
    local width = frame:GetUnboundedStringWidth()
    if itemID <= #GT.ItemData.Other.Other then
        return
    end
    if GT.Display.ColumnSize[index] == nil or GT.Display.ColumnSize[index] < width then
        GT.Display.ColumnSize[index] = width
        return
    end
end

function GT:GetItemPrice(itemID)
    if not GT.priceSources then
        return
    end
    if GT.db.profile.General.tsmPrice == 0 then
        return 0
    end
    local itemID = tonumber(itemID)
    local price = nil

    if GT.priceSources["RECrystallize"] and GT.db.profile.General.tsmPrice == 10 then
        price = (RECrystallize_PriceCheckItemID(itemID) or 0) / 10000
    end
    if GT.priceSources["Auctionator"] and GT.db.profile.General.tsmPrice == 20 then
        price = (Auctionator.API.v1.GetAuctionPriceByItemID("GatheringTracker", itemID) or 0) / 10000
    end
    if GT.priceSources["TradeSkillMaster"] and price == nil then
        price = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. itemID) or 0) / 10000
    end
    return price
end

function GT:AnchorButtons()
    -- 25 is the size of the filter button, so if any part of the button is off screen it will be moved
    local UITop = UIParent:GetTop() - 25
    local UILeft = UIParent:GetLeft() + 25
    local backdropTop = GT.baseFrame.backdrop:GetTop()
    local backdropLeft = GT.baseFrame.backdrop:GetLeft()

    if backdropTop >= UITop and backdropLeft <= UILeft then
        GT.Debug("Display Location", 1, "Top Left", UITop, UILeft, backdropTop, backdropLeft)
        local left, bottom, width, height = GT.baseFrame.frame:GetBoundsRect()
        if GT.baseFrame.button and GT.baseFrame.controls then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, -1 * (height + 25))
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", 27, -1 * (height + 25))
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        elseif GT.baseFrame.button then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, -1 * (height + 25))
        elseif GT.baseFrame.controls then
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", 27, -1 * (height + 25))
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        end
    elseif backdropTop >= UITop then
        GT.Debug("Display Location", 1, "Top", UITop, UILeft, backdropTop, backdropLeft)
        if GT.baseFrame.button and GT.baseFrame.controls then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", -2, -26)
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", -27, -53)
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT", -25, -25)
        elseif GT.baseFrame.button then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", -2, -26)
        elseif GT.baseFrame.controls then
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", -27, -26)
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT", -25, -25)
        end
    elseif backdropLeft <= UILeft then
        GT.Debug("Display Location", 1, "Left", UITop, UILeft, backdropTop, backdropLeft)
        if GT.baseFrame.button and GT.baseFrame.controls then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, 0)
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", 27, 0)
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        elseif GT.baseFrame.button then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", 25, 0)
        elseif GT.baseFrame.controls then
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT", 27, 0)
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        end
    else
        if GT.baseFrame.button and GT.baseFrame.controls then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", -2, 0)
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT")
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        elseif GT.baseFrame.button then
            GT.baseFrame.button:SetPoint("BOTTOMRIGHT", GT.baseFrame.backdrop, "TOPLEFT", -2, 0)
        elseif GT.baseFrame.controls then
            GT.baseFrame.controls.play:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT")
            GT.baseFrame.controls.reset:SetPoint("TOPLEFT", GT.baseFrame.controls.play, "TOPRIGHT")
        end
    end
end
