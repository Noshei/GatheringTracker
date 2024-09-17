local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

local function FramePool_Resetter(framePool, frame)
    frame:Hide()
    frame:ClearAllPoints()
    if frame.icon then
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
end

local function InitializePools()
    GT.Pools.framePool = GT.Pools.framePool or CreateFramePool("Frame", GT.baseFrame.frame, nil, FramePool_Resetter)
    GT.Pools.texturePool = GT.Pools.texturePool or CreateTexturePool(GT.baseFrame.frame, "BACKGROUND")
    GT.Pools.fontStringPool = GT.Pools.fontStringPool or CreateFontStringPool(GT.baseFrame.frame, "BACKGROUND")
end

local function CreateTextDisplay(frame, id, text, type, height, anchor)
    local string = GT.Pools.fontStringPool:Acquire()
    string:SetParent(frame)
    if id < 9999999998 then
        string:SetFont(media:Fetch("font", GT.db.profile.General.textFont), GT.db.profile.General.textSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.textColor[1], GT.db.profile.General.textColor[2], GT.db.profile.General.textColor[3])
    else
        string:SetFont(media:Fetch("font", GT.db.profile.General.totalFont), GT.db.profile.General.totalSize, "OUTLINE")
        string:SetVertexColor(GT.db.profile.General.totalColor[1], GT.db.profile.General.totalColor[2], GT.db.profile.General.totalColor[3])
    end
    string:SetHeight(height)
    local offset = 3
    if anchor ~= frame.icon then
        offset = 8 --make spacing fraction of height? (make this adjustable?)
    end
    string.textType = type

    string:SetPoint("LEFT", anchor, "RIGHT", offset, 0)
    string:SetJustifyH("LEFT") --add option for this?
    string:SetText(text)
    string:Show()
    return string
end

function GT:CreateDisplayFrame(id, iconId, iconQuality, iconRarity, displayText,
                               totalItemCount, pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)
    GT.Debug("CreateDisplayFrame", 4, id, iconId, iconQuality, iconRarity, displayText,
        totalItemCount, pricePerItem, priceTotalItem, itemsPerHour, goldPerHour)

    if displayText == nil then
        return
    end

    InitializePools()

    local frame = GT:DisplayFrameBase(id)

    frame.displayedCharacters = #displayText

    GT.Display.Frames[id] = frame

    GT:DisplayFrameIcon(frame, iconId)

    if iconQuality then
        GT:DisplayFrameQuality(frame, iconQuality)
    end

    GT:DisplayFrameRarity(frame, iconRarity)

    frameHeight = frame:GetHeight()
    frame.text = {}

    GT:DisplayFrameCounts(frame, id, displayText)

    if totalItemCount and GT:GroupDisplayCheck() then
        GT:DisplayFrameTotal(frame, id, totalItemCount)
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
    frame:Show()

    return frame
end

function GT:DisplayFrameIcon(frame, iconId)
    frame.icon = GT.Pools.texturePool:Acquire()
    frame.icon:SetParent(frame)
    frame.icon:SetDrawLayer("BACKGROUND", 0)
    frame.icon:SetTexture(iconId)
    frame.icon:SetPoint("LEFT", frame, "LEFT")
    frame.icon:SetWidth(GT.db.profile.General.iconWidth)
    frame.icon:SetHeight(GT.db.profile.General.iconHeight)
    frame.icon:Show()
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
    --[[if not frame then
        return
    end
    if not iconRarity then
        return
    end]]

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

function GT:DisplayFrameCounts(frame, id, displayText)
    for i, text in ipairs(displayText) do
        local anchor = frame.icon
        if i > 1 then
            anchor = frame.text[i - 1]
        end
        if type(text) == "number" then
            text = math.ceil(text - 0.5)
        else
            text = text
        end
        frame.text[i] = CreateTextDisplay(frame, id, text, "count", frame:GetHeight(), anchor)
        GT:CheckColumnSize(i, frame.text[i])
    end
end

function GT:DisplayFrameTotal(frame, id, totalItemCount)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "[" .. math.ceil(totalItemCount - 0.5) .. "]", "totalItemCount", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
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
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
    frame.pricePerItem = #frame.text
end

function GT:DisplayFramePriceTotal(frame, id, priceTotalItem)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, "(" .. math.ceil(priceTotalItem - 0.5) .. "g)", "priceTotalItem", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
    frame.priceTotalItem = #frame.text
end

function GT:DisplayFrameItemsPerHour(frame, id, itemsPerHour)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, math.ceil(itemsPerHour - 0.5) .. "/h", "itemsPerHour", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
    frame.itemsPerHour = #frame.text
end

function GT:DisplayFrameGoldPerHour(frame, id, goldPerHour)
    frame.text[#frame.text + 1] = CreateTextDisplay(frame, id, math.ceil(goldPerHour - 0.5) .. "g/h", "goldPerHour", frame:GetHeight(), frame.text[#frame.text])
    GT:CheckColumnSize(#frame.text, frame.text[#frame.text])
    frame.goldPerHour = #frame.text
end
