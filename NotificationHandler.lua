local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

function GT:NotificationHandler(mode, id, amount, value)
    GT.Debug("Notifications Handler", 2, mode, id, amount, value)

    local NotificationTriggered = false

    if value then
        value = math.ceil(value)
    end

    local function NotificationCheck(notiType, buildTable)
        local threshold = tonumber(GT.db.profile.Notifications[notiType].threshold)

        local passedValue
        if notiType == "Count" then
            passedValue = amount
        else
            passedValue = value
        end

        if passedValue >= threshold then
            GT.Debug(notiType .. " Notifications Threshold Exceeded", 2, mode, id, amount, value)
            if GT.db.profile.Notifications[notiType].interval == 1 then --Interval
                if GT.Notifications[id] and GT.Notifications[id][notiType] > 0 then
                    if (passedValue - GT.Notifications[id][notiType]) >= threshold then
                        GT.Debug(notiType .. " Notifications Interval Threshold Exceeded", 2, mode, id, amount, value, GT.Notifications[id][notiType])
                        GT.Notifications[id][notiType] = math.floor(passedValue / threshold) * threshold
                        if not buildTable then
                            NotificationTriggered = true
                            GT:TriggerNotification(notiType)
                        end
                    end
                else
                    if GT.Notifications[id] then
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = math.floor(passedValue / threshold) * threshold,
                                Gold = (GT.Notifications[id].Gold or 0),
                            }
                        else
                            GT.Notifications[id] = {
                                Count = (GT.Notifications[id].Count or 0),
                                Gold = math.floor(passedValue / threshold) * threshold,
                            }
                        end
                    else
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = math.floor(passedValue / threshold) * threshold,
                                Gold = 0,
                            }
                        else
                            GT.Notifications[id] = {
                                Count = 0,
                                Gold = math.floor(passedValue / threshold) * threshold,
                            }
                        end
                    end
                    if not buildTable then
                        NotificationTriggered = true
                        GT:TriggerNotification(notiType)
                    end
                end
            end
            if GT.db.profile.Notifications[notiType].interval == 0 then --Exact
                if not GT.Notifications[id] or GT.Notifications[id][notiType] < threshold then
                    GT.Debug(notiType .. " Notifications Exact Threshold Exceeded", 2, mode, id, amount, value, GT.Notifications[id][notiType])
                    if GT.Notifications[id] then
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = threshold,
                                Gold = (GT.Notifications[id].Gold or 0),
                            }
                        else
                            GT.Notifications[id] = {
                                Count = (GT.Notifications[id].Count or 0),
                                Gold = threshold,
                            }
                        end
                    else
                        if notiType == "Count" then
                            GT.Notifications[id] = {
                                Count = threshold,
                                Gold = 0,
                            }
                        else
                            GT.Notifications[id] = {
                                Count = 0,
                                Gold = threshold,
                            }
                        end
                    end
                    if not buildTable then
                        NotificationTriggered = true
                        GT:TriggerNotification(notiType)
                    end
                end
            end
        end
    end

    if GT.db.profile.Notifications.Count.enable then
        if mode == "all" and (GT.db.profile.Notifications.Count.itemAll == 1 or GT.db.profile.Notifications.Count.itemAll == 2) then --All Items or Both
            NotificationCheck("Count", false)
        end
        if mode == "each" and (GT.db.profile.Notifications.Count.itemAll == 0 or GT.db.profile.Notifications.Count.itemAll == 2) then --Each Item or Both
            NotificationCheck("Count", false)
        end
    end

    if GT.db.profile.Notifications.Gold.enable and GT.tsmLoaded and GT.db.profile.General.tsmPrice > 0 then
        if mode == "all" and (GT.db.profile.Notifications.Gold.itemAll == 1 or GT.db.profile.Notifications.Gold.itemAll == 2) then --All Items or Both
            NotificationCheck("Gold", false)
        end
        if mode == "each" and (GT.db.profile.Notifications.Gold.itemAll == 0 or GT.db.profile.Notifications.Gold.itemAll == 2) then --Each Item or Both
            if GT.db.profile.General.tsmPrice > 0 then
                local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(id)) or 0) / 10000
                value = math.ceil(eprice * amount)
                NotificationCheck("Gold", false)
            end
        end
    end

    if mode == "PLAYER_ENTERING_WORLD" then
        GT.Debug("Generate Notification Table", 1)
        for i = 1, table.getn(GT.sender) do
            if GT.sender[1].name == GT.Player then
                local playerTotal = 0
                for itemID, data in pairs(GT.InventoryData) do
                    if GT:TableFind(GT.IDs, tonumber(itemID)) then
                        id = tonumber(itemID)
                        amount = data[i]
                        playerTotal = playerTotal + amount
                        NotificationCheck("Count", true)
                        if GT.db.profile.General.tsmPrice > 0 then
                            local eprice = (TSM_API.GetCustomPriceValue(GT.TSM, "i:" .. tostring(itemID)) or 0) / 10000
                            value = math.ceil(eprice * amount)
                            NotificationCheck("Gold", true)
                        end
                    end
                end
                id = "all"
                amount = playerTotal
                NotificationCheck("Count", true)
                value = GT.sender[i].totalValue
                NotificationCheck("Gold", true)
            end
        end
    end
end

function GT:TriggerNotification(alertType)
    GT.Debug("Trigger Notifications", 1, alertType, GT.NotificationPause)
    if not GT.NotificationPause then
        --GT.Debug("|cffff6f00" .. GT.metaData.name .. " v" .. GT.metaData.version .. "|r|cff00ff00 Notifications |r" .. alertType, 1)
        if media:IsValid("sound", GT.db.profile.Notifications[alertType].sound) then
            PlaySoundFile(media:Fetch("sound", GT.db.profile.Notifications[alertType].sound), "master")
        else
            GT.Debug("Trigger Notifications: Play Default Sound", 1, alertType, GT.NotificationPause, GT.db.profile.Notifications[alertType].sound, GT.defaults.profile.Notifications[alertType].sound)
            PlaySoundFile(media:Fetch("sound", GT.defaults.profile.Notifications[alertType].sound), "master")
        end
    end
end
