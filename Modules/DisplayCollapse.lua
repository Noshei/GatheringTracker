---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

-- Localize global functions
local pairs = pairs

function GT:CollapseDisplay()
    GT.Debug("CollapseDisplay", 1)
    for itemID, itemFrame in pairs(GT.Display.Frames) do
        if itemID < 9999999998 then
            itemFrame:Hide()
        end
        if itemID == 9999999998 then
            itemFrame:SetPoint("TOPLEFT", GT.baseFrame.backdrop, "TOPLEFT")
        end
        if itemID == 9999999999 then
            itemFrame:SetPoint("TOPLEFT", GT.Display.Frames[9999999998], "BOTTOMLEFT")
        end
    end
end

function GT:ExpandDisplay()
    GT.Debug("ExpandDisplay", 1)
    for itemID, itemFrame in pairs(GT.Display.Frames) do
        if itemID < 9999999998 then
            itemFrame:Show()
        end
    end
    GT:AllignRows()
end

function GT:CollapseManager(wait)
    GT.Debug("CollapseManager", 1, wait, GT.db.profile.General.collapseDisplay, GT.db.profile.General.collapseTime)
    if wait then
        GT:wait(GT.db.profile.General.collapseTime, "CollapseManager", false)
        return
    end

    if GT.db.profile.General.collapseDisplay then
        GT:CollapseDisplay()
        if GT.Display.Frames[9999999998] then
            GT.Display.Frames[9999999998]:SetScript("OnEnter", function(self, motion)
                if motion then
                    GT:ExpandDisplay()
                    GT.baseFrame.frame:SetScript("OnLeave", function(self, motion)
                        GT:wait(GT.db.profile.General.collapseTime, "CollapseManager", false)
                        GT.baseFrame.frame:SetScript("OnLeave", nil)
                        GT.baseFrame.frame:SetMouseClickEnabled(false)
                    end)
                    GT:ClearMouse()
                end
            end)
        else
            GT:SetupTotalsRow()
            GT:AllignRows()
            GT:AllignColumns()
            GT:UpdateBaseFrameSize()
            GT:CollapseManager(false)
        end
        if GT.Display.Frames[9999999999] then
            GT.Display.Frames[9999999999]:SetScript("OnEnter", function(self, motion)
                if motion then
                    GT:ExpandDisplay()
                    GT.baseFrame.frame:SetScript("OnLeave", function(self, motion)
                        GT:wait(GT.db.profile.General.collapseTime, "CollapseManager", false)
                        GT.baseFrame.frame:SetScript("OnLeave", nil)
                        GT.baseFrame.frame:SetMouseClickEnabled(false)
                    end)
                    GT:ClearMouse()
                end
            end)
        end
    else
        GT:ExpandDisplay()
        GT:wait(nil, "CollapseManager")

        GT.baseFrame.frame:SetScript("OnLeave", nil)

        GT:ClearMouse()

        if GT.Display.Order and #GT.Display.Order == 1 then
            GT:PrepareDataForDisplay("CollapseManager", false)
        end
    end
end

function GT:ClearMouse()
    GT.baseFrame.frame:SetMouseClickEnabled(false)

    if GT.Display.Frames[9999999998] then
        GT.Display.Frames[9999999998]:SetScript("OnEnter", nil)
        GT.Display.Frames[9999999998]:SetMouseClickEnabled(false)
        GT.Display.Frames[9999999998]:SetMouseMotionEnabled(false)
    end

    if GT.Display.Frames[9999999999] then
        GT.Display.Frames[9999999999]:SetScript("OnEnter", nil)
        GT.Display.Frames[9999999999]:SetMouseClickEnabled(false)
        GT.Display.Frames[9999999999]:SetMouseMotionEnabled(false)
    end
end
