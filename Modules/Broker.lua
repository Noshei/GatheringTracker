---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local ldb = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local totalsID = 9999999998
local broker

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

function GT:UpdateBrokerText()
   if broker then
      local totals = GT.Display.Frames[totalsID]
      broker.text = totals and GetRowText(totals) or GT.metaData.name
   end
end

function GT:InitializeBroker()
   GT.Debug("InitializeBroker", 1)
   -- Create LibDataBroker data object
   broker = ldb:NewDataObject(GT.metaData.name, {
      type = "data source",
      text = GT.metaData.name,
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
         local totals = GT.Display.Frames[totalsID]
         if totals then
            tooltip:AddDoubleLine("Totals", GetRowText(totals), 1, 1, 1, 1, 1, 1)
         end
         local hasRows = totals ~= nil
         for _, id in ipairs(GT.Display.Order or {}) do
            if id < totalsID then
               tooltip:AddDoubleLine(GetRowName(id), GetRowText(GT.Display.Frames[id]), 1, 1, 1, 1, 1, 1)
               hasRows = true
            end
         end
         if hasRows then
            tooltip:AddLine(" ")
         end
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
