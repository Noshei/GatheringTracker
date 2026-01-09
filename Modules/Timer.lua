---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

GT.Timer = {}
GT.Timer.StartTime = 0
GT.Timer.Running = true
GT.Timer.Paused = false

function GT.Timer.CreateTimerText(sesstionTime)
    local hours, minutes, seconds = 0, 0, 0
    hours = floor(sesstionTime / 3600)
    minutes = floor((sesstionTime / 60) % 60)
    seconds = floor(sesstionTime % 60)

    local timer = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    if GT.db.profile.General.shortTimer then
        if hours > 0 then
            timer = timer
        elseif minutes > 0 then
            timer = string.format("%02d:%02d", minutes, seconds)
        else
            timer = string.format("%02d", seconds)
        end
    end
    return timer
end

function GT.Timer:Start()
    GT.Debug("Timer:Start", 1, GT.Timer.Running, GT.Timer.Paused)
    if not GT.Timer.Frame then
        return
    end
    if GT.Timer.Running then
        return
    end

    GT.Timer.Running = true

    if GT.Timer.Paused then
        GT.Timer.Paused = false
    else
        GT.Timer.StartTime = time()
        GT:UpdateTimer(GT.Timer.Frame)
    end
    GT:RefreshPerHourDisplay(true)
end

function GT.Timer:Stop()
    GT.Debug("Timer:Stop", 1, GT.Timer.Running, GT.Timer.Paused)
    if not GT.Timer.Frame then
        return
    end
    GT.Timer.Running = false
    GT.Timer.Paused = false
    GT.Timer.StartTime = 0
    GT.Timer.Frame.text[1]:SetText(GT.Timer.CreateTimerText(0))
    GT:wait(nil, "RefreshPerHourDisplay")
end

function GT.Timer:Pause()
    GT.Debug("Timer:Pause", 1, GT.Timer.Running, GT.Timer.Paused)
    if not GT.Timer.Frame then
        return
    end
    if not GT.Timer.Running then
        return
    end
    GT.Timer.Running = false
    GT.Timer.Paused = true
    GT:wait(nil, "RefreshPerHourDisplay")
end

function GT:UpdateTimer(frame)
    if frame and frame.timer then
        C_Timer.After(1, function()
            if not frame.timer then
                return
            end
            if GT.Timer.Paused and not GT.Timer.Running then
                GT.Timer.StartTime = GT.Timer.StartTime + 1
                GT:UpdateTimer(frame)
                return
            end
            if not GT.Timer.Running and not GT.Timer.Paused then
                return
            end
            local sesstionTime = time() - GT.Timer.StartTime

            local timer = GT.Timer.CreateTimerText(sesstionTime)

            frame.text[1]:SetText(timer)

            local width = frame.text[1]:GetUnboundedStringWidth()
            if GT.Display.ColumnSize[1] and width < GT.Display.ColumnSize[1] then
                width = GT.Display.ColumnSize[1]
            end
            frame.text[1]:SetWidth(width)
            GT:UpdateTimer(frame)
        end)
    end
end

function GT.Timer:ToggleControls()
    if not GT.Enabled then
        GT.Timer:HideControls()
        return
    end
    if not GT.baseFrame.controls then
        GT.Timer:CreateControls()
    end
    GT.Debug("Toggle Controls", 1, GT.db.profile.General.sessionButtons, GT.db.profile.General.itemsPerHour,
        GT.db.profile.General.goldPerHour, GT.db.profile.Filters[3], GT.db.profile.General.sessionItems)

    if GT.db.profile.General.sessionButtons and
        (GT.db.profile.General.itemsPerHour or GT.db.profile.General.goldPerHour
            or GT.db.profile.Filters[3] or GT.db.profile.General.sessionItems)
        and (GT.Display.Order and #GT.Display.Order > 0) then
        GT.Timer:ShowControls()
    else
        GT.Timer:HideControls()
    end
end

function GT.Timer:ShowControls()
    if not GT.baseFrame.controls then
        return
    end
    if not GT.Timer.ControlsVisible then
        GT.baseFrame.controls.play:Show()
        GT.baseFrame.controls.reset:Show()
        GT.Timer.ControlsVisible = true
    end
end

function GT.Timer:HideControls()
    if not GT.baseFrame.controls then
        return
    end
    if GT.Timer.ControlsVisible then
        GT.baseFrame.controls.play:Hide()
        GT.baseFrame.controls.reset:Hide()
        GT.Timer.ControlsVisible = false
    end
end

function GT.Timer:CreateControls()
    if GT.baseFrame.controls then
        return
    end
    GT.baseFrame.controls = {}

    local play, pause, reset
    if GT.db.profile.General.buttonTheme == 4 then
        play = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\playBlack"
        pause = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\pauseBlack"
        reset = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\resetBlack"
    else
        play = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\play"
        pause = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\pause"
        reset = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\Controls\\reset"
    end

    GT.Debug("Create Session Controls", 1)
    local playButton = GT.Skins:CreateButtonSkinned("GT_timer_rlayButton", GT.baseFrame.frame)
    playButton:SetPoint("BOTTOMLEFT", GT.baseFrame.backdrop, "TOPLEFT")
    playButton:SetWidth(25)
    playButton:SetHeight(25)
    playButton:EnableMouse(true)
    playButton:RegisterForClicks("AnyDown")
    playButton:SetFrameStrata("BACKGROUND")
    playButton:SetFrameLevel(2)
    playButton:Show()

    playButton.icon = playButton:CreateTexture()
    if GT.Timer.Running then
        playButton.icon:SetTexture(pause)
    else
        playButton.icon:SetTexture(play)
    end
    playButton.icon:SetDrawLayer("OVERLAY")
    playButton.icon:SetWidth(10)
    playButton.icon:SetHeight(10)
    playButton.icon:SetPoint("CENTER")

    playButton:HookScript("OnMouseDown", function(self, button, down)
        if button == "LeftButton" then
            playButton.icon:SetPoint("CENTER", playButton, "CENTER", 1, -1)
        end
    end)

    playButton:HookScript("OnMouseUp", function(self, button, down)
        if button == "LeftButton" then
            playButton.icon:SetPoint("CENTER", playButton, "CENTER")
            if GT.Timer.Running then
                GT:PauseSession()
                playButton.icon:SetTexture(play)
            else
                GT:StartSession()
                playButton.icon:SetTexture(pause)
            end
        end
    end)


    GT.baseFrame.controls.play = playButton

    local resetButton = GT.Skins:CreateButtonSkinned("GT_timer_resetButton", GT.baseFrame.frame)
    resetButton:SetPoint("TOPLEFT", playButton, "TOPRIGHT")
    resetButton:SetWidth(25)
    resetButton:SetHeight(25)
    resetButton:EnableMouse(true)
    resetButton:RegisterForClicks("AnyDown")
    resetButton:SetFrameStrata("BACKGROUND")
    resetButton:SetFrameLevel(2)
    resetButton:Show()

    resetButton.icon = resetButton:CreateTexture()
    resetButton.icon:SetTexture(reset)
    resetButton.icon:SetDrawLayer("OVERLAY")
    resetButton.icon:SetWidth(12)
    resetButton.icon:SetHeight(12)
    resetButton.icon:SetPoint("CENTER")

    resetButton:HookScript("OnMouseDown", function(self, button, down)
        if button == "LeftButton" then
            resetButton.icon:SetPoint("CENTER", resetButton, "CENTER", 1, -1)
        end
    end)

    resetButton:HookScript("OnMouseUp", function(self, button, down)
        if button == "LeftButton" then
            resetButton.icon:SetPoint("CENTER", resetButton, "CENTER")
            if GT.Timer.Running then
                playButton.icon:SetTexture(play)
            end
            GT:ResetSession()
        end
    end)

    GT.baseFrame.controls.reset = resetButton

    GT.Timer.ControlsVisible = true
end
