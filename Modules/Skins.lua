---@class GT
local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")


GT.Skins = {}

GT.Skins.List = {
    [1] = {
        name = "Blizzard",
        button = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardRed\\redbutton",
        highlightTexture = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardRed\\redhighlight",
        pushed = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardRed\\reddown",
        font = "GameFontNormalMed1",
        highlightfont = "GameFontHighlightMedium"
    },
    [2] = {
        name = "Modern",
        button = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardNew\\button",
        highlight = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardNew\\hover",
        pushed = "Interface\\Addons\\GatheringTracker\\Media\\Buttons\\BlizzardNew\\down",
        font = "GameFontNormalMed1",
        highlightfont = "GameFontHighlightMedium"
    },
    [3] = {
        name = "ElvUI",
        template = "BackdropTemplate",
        backdrop = {
            bgFile = "Interface\\Addons\\GatheringTracker\\Media\\WhiteBorder",
            edgeFile = "Interface\\Addons\\GatheringTracker\\Media\\WhiteBorder",
            edgeSize = 2
        },
        backgroundColor = {
            r = 0.07,
            g = 0.07,
            b = 0.07,
            a = 0.9
        },
        borderColor = {
            r = 0,
            g = 0,
            b = 0
        },
        highlightColor = {
            r = 1,
            g = 0.82,
            b = 0,
            a = 0.6
        },
        highlightType = "border",
        font = "GameFontNormalMed1",
    },
    [4] = {
        name = "GW2 UI",
        template = "BackdropTemplate",
        backdrop = {
            bgFile = "Interface\\Addons\\GatheringTracker\\Media\\WhiteBorder",
            edgeFile = "Interface\\Addons\\GatheringTracker\\Media\\WhiteBorder",
            edgeSize = 1
        },
        backgroundColor = {
            r = 201 / 255,
            g = 192 / 255,
            b = 171 / 255,
            a = 1
        },
        borderColor = {
            r = 0,
            g = 0,
            b = 0
        },
        highlightColor = {
            r = 244 / 255,
            g = 243 / 255,
            b = 240 / 255,
            a = 1
        },
        highlightType = "background",
        font = "GameFontBlackMedium",
    }
}

function GT.Skins:CreateButtonSkinned(name, parent)
    local skin = GT.Skins.List[GT.db.profile.General.buttonTheme]

    local button
    if skin.template then
        button = CreateFrame("Button", name, parent, skin.template)
    else
        button = CreateFrame("Button", name, parent)
    end

    if skin.button then
        button:SetNormalTexture(skin.button)
        button:HookScript("OnLeave", function()
            button:SetNormalTexture(skin.button)
        end)
        button:HookScript("OnMouseUp", function()
            button:SetNormalTexture(skin.button)
        end)
    end

    if skin.highlight then
        button:HookScript("OnEnter", function()
            button:SetNormalTexture(skin.highlight)
        end)
    end

    if skin.highlightTexture then
        button:SetHighlightTexture(skin.highlightTexture, "ADD")
    end

    if skin.pushed then
        button:HookScript("OnMouseDown", function()
            button:SetNormalTexture(skin.pushed)
        end)
    end


    if skin.backdrop then
        button:SetBackdrop(skin.backdrop)
    end

    if skin.backgroundColor then
        button:SetBackdropColor(skin.backgroundColor.r, skin.backgroundColor.g, skin.backgroundColor.b, skin.backgroundColor.a or 1)
    end

    if skin.borderColor then
        button:SetBackdropBorderColor(skin.borderColor.r, skin.borderColor.g, skin.borderColor.b, skin.borderColor.a or 1)
    end

    if skin.highlightColor then
        if skin.highlightType and skin.highlightType == "border" then
            button:HookScript("OnEnter", function()
                button:SetBackdropBorderColor(skin.highlightColor.r, skin.highlightColor.g, skin.highlightColor.b, skin.highlightColor.a or 1)
            end)
            button:HookScript("OnLeave", function()
                button:SetBackdropBorderColor(skin.borderColor.r, skin.borderColor.g, skin.borderColor.b, skin.borderColor.a or 1)
            end)
        elseif skin.highlightType and skin.highlightType == "background" then
            button:HookScript("OnEnter", function()
                button:SetBackdropColor(skin.highlightColor.r, skin.highlightColor.g, skin.highlightColor.b, skin.highlightColor.a or 1)
            end)
            button:HookScript("OnLeave", function()
                button:SetBackdropColor(skin.backgroundColor.r, skin.backgroundColor.g, skin.backgroundColor.b, skin.backgroundColor.a or 1)
            end)
        end
    end


    if skin.font then
        button:SetNormalFontObject(skin.font)
    end

    if skin.highlightfont then
        button:SetHighlightFontObject(skin.highlightfont)
    end

    return button
end
