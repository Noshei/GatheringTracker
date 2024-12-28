---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

-- Localize global functions
local ipairs = ipairs
local math = math
local table = table
local type = type

local function FramePool_Resetter(framePool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    if frame.icon then
        frame.icon:SetScript("OnEnter", nil)
        frame.icon:SetScript("OnLeave", nil)
        frame.icon:SetMouseClickEnabled(false)
        frame.icon:SetMouseMotionEnabled(false)
        GT.Pools.texturePool:Release(frame.icon)
        frame.icon = nil
    end
    if frame.iconQuality then
        GT.Pools.texturePool:Release(frame.iconQuality)
        frame.iconQuality = nil
    end
    if frame.iconRarity then
        frame.iconRarity:SetVertexColor(1, 1, 1, 1)
        GT.Pools.texturePool:Release(frame.iconRarity)
        frame.iconRarity = nil
    end
    if frame.highlight then
        frame.highlight:SetVertexColor(1, 1, 1, 1)
        GT.Pools.texturePool:Release(frame.highlight)
        frame.highlight = nil
    end
    if frame.text == nil then
        return
    end
    for index, fontString in ipairs(frame.text) do
        GT.Pools.fontStringPool:Release(fontString)
    end
    frame.text = nil
    if frame.totalItemCount then
        frame.totalItemCount = nil
    end
    if frame.pricePerItem then
        frame.pricePerItem = nil
    end
    if frame.priceTotalItem then
        frame.priceTotalItem = nil
    end
    if frame.timer then
        frame.timer = nil
    end
    frame:SetScript("OnEnter", nil)
    frame:SetMouseClickEnabled(false)
    frame:SetMouseMotionEnabled(false)
end

function GT:InitializePools()
    GT.Pools.framePool = GT.Pools.framePool or CreateFramePool("Frame", GT.baseFrame.frame, nil, FramePool_Resetter)
    GT.Pools.texturePool = GT.Pools.texturePool or CreateTexturePool(GT.baseFrame.frame, "BACKGROUND")
    GT.Pools.fontStringPool = GT.Pools.fontStringPool or CreateFontStringPool(GT.baseFrame.frame, "BACKGROUND")
end

local function CreateTextDisplay(frame, id, text, type, height, anchor)
    local string = GT.Pools.fontStringPool:Acquire()
    string:SetParent(frame)
    if id < 9999999998 then
        string:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2],
            GT.db.profile.General.textColor[3])
    else
        string:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.totalColor[1], GT.db.profile.General.totalColor[2],
            GT.db.profile.General.totalColor[3])
    end
    string:SetHeight(height)
    local offset = 3
    if anchor ~= frame.icon then
        offset = 8 --make spacing fraction of height? (make this adjustable?)
    end
    string.textType = type

    string:SetPoint("LEFT", anchor, "RIGHT", offset, 0)
    string:SetJustifyH("LEFT") --add option for this?
    if id ~= 3 then
        string:SetText(text)
    end
    string:Show()
    if id == 3 then
        frame.timer = true
        string:SetText("00:00:00")
        GT:UpdateTimer(frame)
    end
    return string
end

function GT:CreateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText,
                               pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)
    GT.Debug("CreateDisplayFrame", 4, id, iconId, iconQuality, iconRarity, displayText,
        pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)

    if displayText == nil then
        return
    end

    local frame = GT:DisplayFrameBase(id)

    GT.Display.Frames[id] = frame

    GT:DisplayFrameHighlight(frame)

    GT:DisplayFrameIcon(frame, iconId, id)

    if iconQuality then
        GT:DisplayFrameQuality(frame, iconQuality)
    end

    GT:DisplayFrameRarity(frame, iconRarity)

    local frameHeight = frame:GetHeight()
    frame.text = {}

    if type(displayText) == "table" then
        for index, text in ipairs(displayText) do
            GT:DisplayFrameCounts(frame, id, text, index)
        end
    else
        GT:DisplayFrameCounts(frame, id, displayText)
    end

    if pricePerItem and GT.db.profile.General.perItemPrice then
        GT:DisplayFramePricePer(frame, id, pricePerItem)
    end

    if priceTotalItem and GT.db.profile.General.tsmPrice > 0 then
        GT:DisplayFramePriceTotal(frame, id, priceTotalItem)
    end

    if itemsPerHour and GT.db.profile.General.itemsPerHour then
        GT:DisplayFrameItemsPerHour(frame, id, itemsPerHour)
    end

    if goldPerHour and GT.db.profile.General.goldPerHour then
        GT:DisplayFrameGoldPerHour(frame, id, goldPerHour)
    end


    GT.Display.Order = GT.Display.Order or {}
    table.insert(GT.Display.Order, id)
    table.sort(GT.Display.Order)
end

function GT:DisplayFrameBase(id)
    local frame = GT.Pools.framePool:Acquire()
    frame:SetPoint("TOPLEFT", GT.baseFrame.backdrop, "TOPLEFT")
    frame:SetWidth(GT.db.profile.General.iconWidth)
    local frameHeight = math.max(GT.db.profile.General.iconHeight, GT.db.profile.General.totalSize)
    frame:SetHeight(frameHeight + 3)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(3)
    frame:Show()

    return frame
end

function GT:DisplayFrameIcon(frame, iconId, id)
    frame.icon = GT.Pools.texturePool:Acquire()
    frame.icon:SetParent(frame)
    frame.icon:SetDrawLayer("BACKGROUND", 0)
    frame.icon:SetTexture(iconId)
    frame.icon:SetPoint("LEFT", frame, "LEFT")
    frame.icon:SetWidth(GT.db.profile.General.iconWidth)
    frame.icon:SetHeight(GT.db.profile.General.iconHeight)
    frame.icon:Show()

    if id <= #GT.ItemData.Other.Other or id >= 9999999998 then
        return
    end
    if not GT.db.profile.General.itemTooltip then
        return
    end

    frame.icon:SetScript("OnEnter", function(self, motion)
        if motion then
            GameTooltip:SetOwner(self, self:GetTooltipAnchor())
            GameTooltip:SetItemByID(id)
            GameTooltip:Show()
        end
    end)

    frame.icon:SetScript("OnLeave", function(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)

    function frame.icon:GetTooltipAnchor()
        local x = self:GetRight() / GetScreenWidth() > 0.8
        return x and 'ANCHOR_LEFT' or 'ANCHOR_RIGHT'
    end
    frame.icon:SetMouseClickEnabled(false)
end

function GT:DisplayFrameQuality(frame, iconQuality)
    frame.iconQuality = GT.Pools.texturePool:Acquire()
    frame.iconQuality:SetParent(frame)
    frame.iconQuality:SetDrawLayer("BACKGROUND", 2)
    if iconQuality == 1 then
        frame.iconQuality:SetAtlas("professions-icon-quality-tier1-inv", true)
    elseif iconQuality == 2 then
        frame.iconQuality:SetAtlas("professions-icon-quality-tier2-inv", true)
    elseif iconQuality == 3 then
        frame.iconQuality:SetAtlas("professions-icon-quality-tier3-inv", true)
    end
    frame.iconQuality:SetAllPoints(frame.icon)
    frame.iconQuality:Show()
end

function GT:DisplayFrameRarity(frame, iconRarity)
    if not GT.db.profile.General.rarityBorder then
        return
    end

    frame.iconRarity = GT.Pools.texturePool:Acquire()
    frame.iconRarity:SetParent(frame)
    frame.iconRarity:SetDrawLayer("BACKGROUND", 1)
    local rarity = iconRarity or 1
    if rarity <= 1 then
        frame.iconRarity:SetTexture("Interface\\Common\\WhiteIconFrame")
    else
        frame.iconRarity:SetAtlas("bags-glow-white")
    end
    local R, G, B = C_Item.GetItemQualityColor(rarity)
    frame.iconRarity:SetVertexColor(R, G, B, 0.8)
    frame.iconRarity:SetAllPoints(frame.icon)
    frame.iconRarity:Show()
end

function GT:DisplayFrameHighlight(frame)
    frame.highlight = GT.Pools.texturePool:Acquire()
    frame.highlight:SetParent(frame)
    frame.highlight:SetDrawLayer("BACKGROUND", 7)
    frame.highlight:SetAllPoints(frame)
    frame.highlight:Hide()
end

function GT:DisplayFrameCounts(frame, id, text, index)
    index = index or 1
    local anchor = frame.icon
    if index > 1 then
        anchor = frame.text[index - 1]
    end
    if type(text) == "number" then
        text = math.ceil(text - 0.5)
    else
        text = text
    end
    frame.text[index] = CreateTextDisplay(frame, id, text, "count", frame:GetHeight(), anchor)

    if id <= #GT.ItemData.Other.Other then
        -- 3 is the offset from the icon, 8 is the offset to the next column
        local offset = GT.db.profile.General.iconWidth + 3 + 8
        local parentWidth = frame:GetWidth()
        local width = parentWidth - offset
        local stringWidth = frame.text[index]:GetUnboundedStringWidth()
        frame.text[index]:SetWidth(stringWidth)
    end

    GT:CheckColumnSize(index, frame.text[index], id)
end

function GT:DisplayFrameTotal(frame, id, totalItemCount)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text], id)
    frame.totalItemCount = #frame.text
end

function GT:DisplayFramePricePer(frame, id, pricePerItem)
    local text = ""
    if type(pricePerItem) == "number" then
        text = "{" .. math.ceil(pricePerItem - 0.5) .. "g}"
    else
        text = ""
    end
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, text, "pricePerItem", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text], id)
    frame.pricePerItem = #frame.text
end

function GT:DisplayFramePriceTotal(frame, id, priceTotalItem)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text], id)
    frame.priceTotalItem = #frame.text
end

function GT:DisplayFrameItemsPerHour(frame, id, itemsPerHour)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, math.ceil(itemsPerHour - 0.5) .. "/h", "itemsPerHour", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text], id)
    frame.itemsPerHour = #frame.text
end

function GT:DisplayFrameGoldPerHour(frame, id, goldPerHour)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, math.ceil(goldPerHour - 0.5) .. "g/h", "goldPerHour", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text], id)
    frame.goldPerHour = #frame.text
end
