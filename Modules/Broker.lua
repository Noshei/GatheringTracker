---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local ldb = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local totalsID = 9999999998
local broker
local columnNames = { "count", "sessionCount", "totalItemCount", "pricePerItem", "priceTotalItem", "itemsPerHour", "goldPerHour" }
local measure
local space = "\194\160"

local function GetColorCode(color)
   return "|c" .. GT:RGBtoHex(color[1], color[2], color[3], color[4] or 1)
end

local function GetRowText(frame)
   local values = {}
   for _, column in ipairs(frame.text) do
      local value = column:GetText()
      if value and value ~= "" then
         table.insert(values, value)
      end
   end
   return table.concat(values, "  ")
end

local function GetRowName(id)
   local other = GT.ItemData.Other.Other[id]
   if other then
      return other.name
   end
   if GT.InventoryData[id].itemType == "Currency" then
      local currency = C_CurrencyInfo.GetBasicCurrencyInfo(id)
      return currency and currency.name or tostring(id)
   end
   return C_Item.GetItemInfo(id) or tostring(id)
end

local function AddTooltipRows(tooltip)
   local rows, widths = {}, {}
   local general = GT.db.profile.General
   local totalColor = GetColorCode(general.totalColor)
   local itemColor = GetColorCode(general.textColor)
   if not measure then
      measure = UIParent:CreateFontString(nil, "OVERLAY", "GameTooltipText")
      measure:Hide()
   end
   local function AddRow(id, name)
      local frame = GT.Display.Frames[id]
      local icon = frame.icon:GetTexture()
      if icon and icon ~= 0 then
         name = ("|T%s:16:16|t %s"):format(icon, name)
      end
      local row = { name = name, cells = {}, color = id == totalsID and totalColor or itemColor }
      for index, column in ipairs(frame.text) do
         local value = column:GetText()
         if value and value ~= "" then
            local key = column.textType
            if key == "count" and index == 2 then
               key = "sessionCount"
            end
            measure:SetText(value)
            local width = measure:GetUnboundedStringWidth()
            row.cells[key] = { value = value, width = width }
            widths[key] = math.max(widths[key] or 0, width)
         end
      end
      table.insert(rows, row)
   end

   if GT.Display.Frames[totalsID] then
      AddRow(totalsID, "Totals")
   end
   for _, id in ipairs(GT.Display.Order or {}) do
      if id < totalsID then
         AddRow(id, GetRowName(id))
      end
   end

   measure:SetText(space)
   local spaceWidth = measure:GetUnboundedStringWidth()
   if spaceWidth <= 0 then
      spaceWidth = 4
   end
   for _, row in ipairs(rows) do
      local values = {}
      for _, key in ipairs(columnNames) do
         if widths[key] then
            local cell = row.cells[key]
            local padding = math.floor((widths[key] - (cell and cell.width or 0)) / spaceWidth + 0.5)
            table.insert(values, space:rep(padding) .. (cell and cell.value or ""))
         end
      end
      tooltip:AddDoubleLine(row.color .. row.name .. "|r",
         row.color .. table.concat(values, space:rep(3)) .. "|r", 1, 1, 1, 1, 1, 1)
   end
   if #rows > 0 then
      tooltip:AddLine(" ")
   end
end

function GT:UpdateBrokerText()
   if broker then
      local general = GT.db.profile.General
      local totals = GT.Display.Frames[totalsID]
      local text = totals and GetRowText(totals) or ""
      if text ~= "" then
         text = GetColorCode(general.totalColor) .. text .. "|r"
      end
      broker.text = text
   end
end

function GT:InitializeBroker()
   GT.Debug("InitializeBroker", 1)
   -- Create LibDataBroker data object
   broker = ldb:NewDataObject(GT.metaData.name, {
      type = "data source",
      text = "",
      icon = "Interface\\Addons\\GatheringTracker\\Media\\GT_Icon",
      OnClick = function(frame, button)
         if button == "LeftButton" and IsShiftKeyDown() then
            GT:ResetSession()
         elseif button == "LeftButton" then
            GT:GenerateFiltersMenu(frame)
         elseif button == "RightButton" and IsShiftKeyDown() then
            GT.AlertSystem:ResetAlerts()
         elseif button == "RightButton" then
            Settings.OpenToCategory(GT.metaData.categoryID)
         end
      end,
      OnTooltipShow = function(tooltip)
         tooltip:AddLine(GT.metaData.name .. " |cffff6f00v" .. GT.metaData.version .. "|r")
         tooltip:AddLine(" ")
         AddTooltipRows(tooltip)
         tooltip:AddLine("|cff8080ffLeft-Click|r to open the Filter Menu")
         tooltip:AddLine("|cff8080ffShift + Left-Click|r to reset Session")
         tooltip:AddLine("|cff8080ffRight-Click|r to open the addon options")
         tooltip:AddLine("|cff8080ffShift + Right-Click|r to reset Alert Triggers")
      end,
   })

   -- Register with LibDBIcon
   LibDBIcon:Register(GT.metaData.name, broker, GT.db.profile.miniMap)
end

function GT:MinimapHandler(key)
   GT.Debug("MinimapHandler", 1, key)
   if key then
      LibDBIcon:Show(GT.metaData.name)
   else
      LibDBIcon:Hide(GT.metaData.name)
   end
end
