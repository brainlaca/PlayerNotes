local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G

function P:CreateConfirmDeleteFrame()
    local deletewindow = _G.CreateFrame("Frame", "PlayerNotesConfirmDeleteWindow", _G.UIParent)
    deletewindow:SetFrameStrata("DIALOG")
    deletewindow:SetToplevel(true)
    deletewindow:SetWidth(400)
    deletewindow:SetHeight(200)
    deletewindow:SetPoint("CENTER", _G.UIParent)
    deletewindow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    deletewindow:SetBackdropColor(0, 0, 0, 1)

    local headertext = deletewindow:CreateFontString("CN_Confirm_HeaderText", deletewindow, "GameFontNormalLarge")
    headertext:SetPoint("TOP", deletewindow, "TOP", 0, -20)
    headertext:SetText(L["Delete Note"])

    local warningtext = deletewindow:CreateFontString("CN_Confirm_WarningText", deletewindow, "GameFontNormalLarge")
    warningtext:SetPoint("TOP", headertext, "TOP", 0, -40)
    warningtext:SetText(L["Are you sure you wish to delete the note for:"])

    local charname = deletewindow:CreateFontString("CN_Confirm_CharName", deletewindow, "GameFontNormal")
    charname:SetPoint("BOTTOM", warningtext, "BOTTOM", 0, -40)
    charname:SetFont(charname:GetFont(), 14)
    charname:SetTextColor(1.0, 1.0, 1.0, 1)

    local deletebutton = _G.CreateFrame("Button", nil, deletewindow, "UIPanelButtonTemplate")
    deletebutton:SetText(L["Delete"])
    deletebutton:SetWidth(100)
    deletebutton:SetHeight(20)
    deletebutton:SetPoint("BOTTOM", deletewindow, "BOTTOM", -60, 20)
    deletebutton:SetScript("OnClick",
        function(this)
            N:DeleteNote(charname:GetText())
            this:GetParent():Hide()
            if this:GetParent().parentFrame then
                this:GetParent().parentFrame:Hide()
            end
        end)
    deletewindow.deletebutton = deletebutton

    local cancelbutton = _G.CreateFrame("Button", nil, deletewindow, "UIPanelButtonTemplate")
    cancelbutton:SetText(L["Cancel"])
    cancelbutton:SetWidth(100)
    cancelbutton:SetHeight(20)
    cancelbutton:SetPoint("BOTTOM", deletewindow, "BOTTOM", 60, 20)
    cancelbutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)
    deletewindow.cancelbutton = cancelbutton

    deletewindow.charname = charname
    deletewindow.parentFrame = nil

    deletewindow:SetMovable(true)
    deletewindow:RegisterForDrag("LeftButton")
    deletewindow:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    deletewindow:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
        end)
    deletewindow:EnableMouse(true)
    deletewindow:Hide()

    return deletewindow
end
