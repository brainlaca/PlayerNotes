local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G

function P:CreateCharNoteTooltip()
    local tooltip = _G.CreateFrame("GameTooltip", "CharNoteTooltip", _G.UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
    tooltip:SetFrameStrata("DIALOG")
    tooltip:SetSize(100, 100)
    tooltip:SetPadding(16, 0)
    if D.db.profile.remember_tooltip_pos == false or D.db.profile.tooltip_x == nil or D.db.profile.tooltip_y == nil then
        tooltip:SetPoint("TOPLEFT", "ChatFrame1", "TOPRIGHT", 20, 0)
    else
        tooltip:SetPoint("CENTER", _G.UIParent, "CENTER", D.db.profile.tooltip_x, D.db.profile.tooltip_y)
    end
    tooltip:EnableMouse(true)
    tooltip:SetToplevel(true)
    tooltip:SetMovable(true)
    _G.GameTooltip_OnLoad(tooltip)
    tooltip:SetUserPlaced(false)

    tooltip:RegisterForDrag("LeftButton")
    tooltip:SetScript("OnDragStart", function(self)
        if not D.db.profile.lock_tooltip then
            self:StartMoving()
        end
    end)
    tooltip:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local scale = self:GetEffectiveScale() / _G.UIParent:GetEffectiveScale()
        local x, y = self:GetCenter()
        x, y = x * scale, y * scale
        x = x - _G.GetScreenWidth() / 2
        y = y - _G.GetScreenHeight() / 2
        x = x / self:GetScale()
        y = y / self:GetScale()
        D.db.profile.tooltip_x, D.db.profile.tooltip_y = x, y
        self:SetUserPlaced(false);
    end)

    local closebutton = _G.CreateFrame("Button", "tooltipCloseButton", tooltip)
    closebutton:SetSize(32, 32)
    closebutton:SetPoint("TOPRIGHT", 1, 0)

    closebutton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closebutton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closebutton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

    closebutton:SetScript("OnClick", function(self)
        _G.HideUIPanel(tooltip)
    end)

    return tooltip
end
