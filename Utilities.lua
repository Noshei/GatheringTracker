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

function GT:AddComas(str)
    return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

function GT:TableFind(list, str)
    for i, v in ipairs(list) do
        if tostring(str) == tostring(v) then
            return i
        end
    end
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
        if GT.waitTable[timer] then --check if the wait table exists, if it dopesn't then this timer was cancelled.
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
    end
end

function GT:GroupDisplayCheck()
    GT.Debug("Group Display Check", 2, GT.db.profile.General.groupType)
    --Checks if we should display group data
    if GT.SimulateGroupRunning then
        GT.Debug("Group Display Check Result", 3, "Simulate Group")
        return true
    end
    if GT.db.profile.General.groupType == 0 then
        GT.Debug("Group Display Check Result", 3, "Group Mode Off")
        return false
    end

    if IsInGroup() == false then
        GT.Debug("Group Display Check Result", 3, "Not in Group")
        return false
    end

    if GT.db.profile.General.hideOthers == true then
        GT.Debug("Group Display Check Result", 3, "Hide Others Enabled")
        return false
    end

    -- follower dungeons act like normal groups, but we dont want to treat them like a group
    if C_LFGInfo.IsInLFGFollowerDungeon() == true then
        GT.Debug("Group Display Check Result", 3, "In Follower Dungeon")
        return false
    end

    -- if we are in a group, but dont have data from group members, then remain in solo display
    if #GT.sender < 2 then
        GT.Debug("Group Display Check Result", 3, "No Group Data")
        return false
    end

    GT.Debug("Group Display Check Result", 3, "Display Group")
    return true
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

function GT:SetChatType()
    local soloMode = GT.db.profile.General.groupType == 0 or GT.db.profile.General.groupType == 2
    local groupMode = GT.db.profile.General.groupType > 0
    if GT.SimulateGroupRunning then --used to simulate being in a group
        GT.groupMode = "PARTY"
        return
    end
    if IsInGroup() == false and soloMode then
        GT.groupMode = "WHISPER"
        return
    end
    if IsInRaid() and groupMode then
        GT.groupMode = "RAID"
        return
    end
    if IsInGroup() and groupMode then
        GT.groupMode = "PARTY"
        return
    end
end

function GT:CheckModeStatus()
    --returns TRUE when we should process an inventory update
    local soloMode = GT.db.profile.General.groupType == 0
    local groupMode = GT.db.profile.General.groupType == 1
    GT.Debug("Check Mode Status", 2, soloMode, groupMode, IsInGroup())
    if GT.SimulateGroupRunning then --used to simulate being in a group
        return true
    end
    if GT.db.profile.General.groupType == 2 then --group mode set to Both
        return true
    end
    if soloMode == IsInGroup() then --group mode Disabled and we are IN a group
        return false
    end
    if groupMode ~= IsInGroup() then --group mode Enabled and we are NOT in a group
        return false
    end
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

function GT:RebuildIDTables()
    GT.Debug("Rebuild ID Table", 1)
    GT.IDs = {}
    for key, value in pairs(GT.db.profile.Filters) do
        table.insert(GT.IDs, key)
    end
    if GT.db.profile.CustomFiltersTable then
        for itemID, value in pairs(GT.db.profile.CustomFiltersTable) do
            if value then
                itemID = tonumber(itemID)
                if not GT.db.profile.Filters[itemID] then
                    table.insert(GT.IDs, itemID)
                end
            end
        end
    end
end

function GT:CheckColumnSize(index, frame)
    local width = frame:GetUnboundedStringWidth()
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

function GT:SimulateGroup(case)
    --[[
        This is for testing purposes only.
        It will simulate the effects of another player being in a group with you that also has the addon.
    ]]
    GT.Debug("Simulate Group", 1)
    GT.SimulateGroupRunning = true

    local message = ""
    if case == 1 then
        GT:GROUP_ROSTER_UPDATE("Simulate Group", false)
        message = "1=4824 2=1 2447=452 2449=483 2450=85 2452=10 785=60 " ..
            "765=490 2592=10 3685=10 2589=80 7100=40 6663=10 39354=50 171831=45"
    elseif case == 2 then
        message = "1=4824 2=2 2447=4520 2449=4830 2450=850 2452=10 785=600 " ..
            "765=4900 2592=100 3685=10 2589=80 7100=400 6663=10 39354=50 171831=450"
    elseif case == 3 then
        message = "1=4824 2=3 2447=45200 2449=4830 2450=850 2452=100 785=600 " ..
            "765=4900 2592=1000 3685=10 2589=800 7100=400 6663=100 39354=50 171831=450"
    end
    if case then
        GT:DataMessageReceived("GT_Data", message, "GROUP", "SimulatedGroup")
    else
        GT.SimulateGroupRunning = nil
        GT:GROUP_ROSTER_UPDATE("Simulate Group", false)
    end
end
