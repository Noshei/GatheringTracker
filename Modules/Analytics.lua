---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

function GT:RunAnalytics()
    if not WagoAnalytics then
        return
    end
    local WagoAnalytics = LibStub("WagoAnalytics"):Register("Xb6XQbKp")

    WagoAnalytics:Switch("FiltersButton", GT.db.profile.General.filtersButton)
    WagoAnalytics:Switch("MinimapButton", GT.db.profile.miniMap.hide)
    WagoAnalytics:Switch("ButtonFade", GT.db.profile.General.buttonFade)
    WagoAnalytics:Switch("IncludeBank", GT.db.profile.General.includeBank)
    WagoAnalytics:Switch("IncludeWarband", GT.db.profile.General.includeWarband)
    WagoAnalytics:Switch("PerItemPrice", GT.db.profile.General.perItemPrice)
    WagoAnalytics:Switch("RarityBorder", GT.db.profile.General.rarityBorder)
    WagoAnalytics:Switch("MultiColumn", GT.db.profile.General.multiColumn)
    WagoAnalytics:Switch("InstanceHide", GT.db.profile.General.instanceHide)
    WagoAnalytics:Switch("GroupHide", GT.db.profile.General.groupHide)
    WagoAnalytics:Switch("ShowDelve", GT.db.profile.General.showDelve)
    WagoAnalytics:Switch("ShowFollower", GT.db.profile.General.showFollower)
    WagoAnalytics:Switch("CombatHide", GT.db.profile.General.combatHide)
    WagoAnalytics:Switch("ItemsPerHour", GT.db.profile.General.itemsPerHour)
    WagoAnalytics:Switch("GoldPerHour", GT.db.profile.General.goldPerHour)
    WagoAnalytics:Switch("CollapseDisplay", GT.db.profile.General.collapseDisplay)
    WagoAnalytics:Switch("SessionItems", GT.db.profile.General.sessionItems)
    WagoAnalytics:Switch("SessionOnly", GT.db.profile.General.sessionOnly)
    WagoAnalytics:Switch("ItemTooltip", GT.db.profile.General.itemTooltip)
    WagoAnalytics:Switch("AlertsEnable", GT.db.profile.General.alertsEnable)
    WagoAnalytics:Switch("TotalsRow", GT.db.profile.General.totalsRow)

    WagoAnalytics:SetCounter("iconWidth", GT.db.profile.General.iconWidth)
    WagoAnalytics:SetCounter("iconHeight", GT.db.profile.General.iconHeight)
    WagoAnalytics:SetCounter("textSize", GT.db.profile.General.textSize)
    WagoAnalytics:SetCounter("totalSize", GT.db.profile.General.totalSize)
    WagoAnalytics:SetCounter("tsmPrice", GT.db.profile.General.tsmPrice)


    local numCustomFilters = 0
    if next(GT.db.profile.CustomFiltersTable) then
        for k, v in pairs(GT.db.profile.CustomFiltersTable) do
            numCustomFilters = numCustomFilters + 1
        end
    end
    WagoAnalytics:SetCounter("NumberOfCustomFilters", numCustomFilters)

    local numAlertItems = 0
    if next(GT.db.profile.Alerts) then
        for k, v in pairs(GT.db.profile.Alerts) do
            numAlertItems = numAlertItems + 1
        end
    end
    WagoAnalytics:SetCounter("NumberOfAlertItems", numAlertItems)
end
