local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G

function P:CreateCharNoteTooltip()
    local profile = D.db.profile

    local CharNoteTooltip = _G.CreateFrame("GameTooltip", "CharNoteTooltip", _G.UIParent, "GameTooltipTemplate")
    CharNoteTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
	CharNoteTooltip:SetFrameStrata("DIALOG")
    CharNoteTooltip:SetSize(100, 100)
    CharNoteTooltip:SetPadding(16, 0)
    if profile.remember_tooltip_pos == false or profile.tooltip_x == nil or profile.tooltip_y == nil then
        CharNoteTooltip:SetPoint("TOPLEFT", "ChatFrame1", "TOPRIGHT", 20, 0)
    else
        CharNoteTooltip:SetPoint("CENTER", _G.UIParent, "CENTER", profile.tooltip_x, profile.tooltip_y)
    end
	CharNoteTooltip:EnableMouse(true)
	CharNoteTooltip:SetToplevel(true)
    CharNoteTooltip:SetMovable(true)
    _G.GameTooltip_OnLoad(CharNoteTooltip)
    CharNoteTooltip:SetUserPlaced(false)

	CharNoteTooltip:RegisterForDrag("LeftButton")
	CharNoteTooltip:SetScript("OnDragStart", function(self)
	    if not profile.lock_tooltip then
		    self:StartMoving()
		end
	end)
	CharNoteTooltip:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local scale = self:GetEffectiveScale() / _G.UIParent:GetEffectiveScale()
		local x, y = self:GetCenter()
		x, y = x * scale, y * scale
		x = x - _G.GetScreenWidth() / 2
		y = y - _G.GetScreenHeight() / 2
		x = x / self:GetScale()
		y = y / self:GetScale()
		profile.tooltip_x, profile.tooltip_y = x, y
		self:SetUserPlaced(false);
	end)

	local closebutton = _G.CreateFrame("Button", "CharNoteTooltipCloseButton", CharNoteTooltip)
	closebutton:SetSize(32, 32)
	closebutton:SetPoint("TOPRIGHT", 1, 0)

	closebutton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	closebutton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	closebutton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

	closebutton:SetScript("OnClick", function(self)
	    _G.HideUIPanel(CharNoteTooltip)
    end)

    CharNoteTooltip.closebutton = closebutton

    D.CharNoteTooltip = CharNoteTooltip
end
