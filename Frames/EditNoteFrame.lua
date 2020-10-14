local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G

local function SaveEditNote(self, frame)
    local rating = _G.UIDropDownMenu_GetSelectedValue(frame.ratingDropdown)

    self:SendMessage('PN_EVENT_SAVENOTE', frame.charname:GetText(), frame.editbox:GetText(), rating)

    frame.charname:SetText("")
    frame.editbox:SetText("")
    frame:Hide()
end

function P:CreateEditNoteFrame()
    local editwindow = _G.CreateFrame("Frame", "PlayerNotesEditWindow", _G.UIParent, "BackdropTemplate")
    editwindow:SetFrameStrata("DIALOG")
    editwindow:SetToplevel(true)
    editwindow:SetWidth(400)
    editwindow:SetHeight(280)
    editwindow:SetPoint("CENTER", _G.UIParent)
    editwindow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    editwindow:SetBackdropColor(0, 0, 0, 1)

    local savebutton = _G.CreateFrame("Button", nil, editwindow, "UIPanelButtonTemplate")
    savebutton:SetText(L["Save"])
    savebutton:SetWidth(100)
    savebutton:SetHeight(20)
    savebutton:SetPoint("BOTTOM", editwindow, "BOTTOM", -120, 20)
    savebutton:SetScript("OnClick",
        function(this)
            local frame = this:GetParent()
            SaveEditNote(self, frame)
        end)
    editwindow.savebutton = savebutton

    local removebutton = _G.CreateFrame("Button", nil, editwindow, "UIPanelButtonTemplate")
    removebutton:SetText(L["Remove"])
    removebutton:SetWidth(100)
    removebutton:SetHeight(20)
    removebutton:SetPoint("BOTTOM", editwindow, "BOTTOM", 0, 20)
    removebutton:SetScript("OnClick",
        function(this)
            local frame = this:GetParent()
            self:SendMessage('PN_EVENT_DELETENOTECLICK', frame.charname:GetText(), frame)
        end)
    editwindow.removebutton = removebutton

    local cancelbutton = _G.CreateFrame("Button", nil, editwindow, "UIPanelButtonTemplate")
    cancelbutton:SetText(L["Cancel"])
    cancelbutton:SetWidth(100)
    cancelbutton:SetHeight(20)
    cancelbutton:SetPoint("BOTTOM", editwindow, "BOTTOM", 120, 20)
    cancelbutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)
    editwindow.cancelbutton = cancelbutton

    local headertext = editwindow:CreateFontString("CN_HeaderText", editwindow, "GameFontNormalLarge")
    headertext:SetPoint("TOP", editwindow, "TOP", 0, -20)
    headertext:SetText(L["Edit Note"])

    local charname = editwindow:CreateFontString("CN_CharName", editwindow, "GameFontNormal")
    charname:SetPoint("BOTTOM", headertext, "BOTTOM", 0, -40)
    charname:SetFont(charname:GetFont(), 14)
    charname:SetTextColor(1.0, 1.0, 1.0, 1)

    local ratingLabel = editwindow:CreateFontString("CN_RatingLabel", editwindow, "GameFontNormal")
    ratingLabel:SetPoint("TOP", charname, "BOTTOM", 0, -30)
    ratingLabel:SetPoint("LEFT", editwindow, "LEFT", 20, 0)
    ratingLabel:SetTextColor(1.0, 1.0, 1.0, 1)
    ratingLabel:SetText(L["Rating"] .. ":")

    local ratingDropdown = _G.CreateFrame("Button", "CN_RatingDropDown", editwindow, "UIDropDownMenuTemplate")
    ratingDropdown:ClearAllPoints()
    ratingDropdown:SetPoint("TOPLEFT", ratingLabel, "TOPRIGHT", 7, 5)
    ratingDropdown:Show()
    _G.UIDropDownMenu_Initialize(ratingDropdown, function(self, level)
        for i = -1, 1 do
            local info = _G.UIDropDownMenu_CreateInfo()
            local ratingInfo = D.RATING_OPTIONS[i]
            info.text = ratingInfo[1]
            info.value = i
            info.colorCode = ratingInfo[2]
            info.func = function(self)
                _G.UIDropDownMenu_SetSelectedValue(ratingDropdown, self.value)
            end
            _G.UIDropDownMenu_AddButton(info, level)
        end
    end)
    _G.UIDropDownMenu_SetWidth(ratingDropdown, 100);
    _G.UIDropDownMenu_SetButtonWidth(ratingDropdown, 124)
    _G.UIDropDownMenu_SetSelectedValue(ratingDropdown, 0)
    _G.UIDropDownMenu_JustifyText(ratingDropdown, "LEFT")
    editwindow.ratingdropdown = ratingDropdown

    local editBoxContainer = _G.CreateFrame("Frame", nil, editwindow, "BackdropTemplate")
    editBoxContainer:SetPoint("TOPLEFT", editwindow, "TOPLEFT", 20, -150)
    editBoxContainer:SetPoint("BOTTOMRIGHT", editwindow, "BOTTOMRIGHT", -40, 50)
    editBoxContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 3, top = 4, bottom = 3 }
    })
    editBoxContainer:SetBackdropColor(0, 0, 0, 0.9)
    editwindow.scrolleditframe = editBoxContainer

    local scrollArea = _G.CreateFrame("ScrollFrame", "CN_EditNote_EditScroll", editwindow, "UIPanelScrollFrameTemplate")
    scrollArea:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 6, -6)
    scrollArea:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", -6, 6)

    local editbox = _G.CreateFrame("EditBox", "CN_EditNote_EditBox", editwindow, "BackdropTemplate")
    editbox:SetFontObject(_G.ChatFontNormal)
    editbox:SetPoint("TOPLEFT")
    editbox:SetPoint("BOTTOMLEFT")
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(true)
    editbox:SetWidth(300)
    editbox:SetHeight(5 * 14)
    editbox:SetMaxLetters(0)
    editbox:SetScript("OnShow", function(this) editbox:SetFocus() end)
    editbox:SetScript("OnTextChanged",
        function(this)
            local text = editbox:GetText():gsub("%s*", "")
            if text == "" then
                savebutton:Disable()
            else
                savebutton:Enable()
            end
        end
    )
    editwindow.scrolleditframe.editboxframe = editbox

    if not D.db.profile.multilineNotes then
        editbox:SetScript("OnEnterPressed",
            function(this)
                local frame = this:GetParent():GetParent()
                SaveEditNote(self, frame)
            end)
    end

    editbox:SetScript("OnEscapePressed",
        function(this)
            this:SetText("")
            this:GetParent():GetParent():Hide()
        end)
    editbox.scrollArea = scrollArea
    editbox:SetScript("OnCursorChanged", function(self, _, y, _, cursorHeight)
        self, y = self.scrollArea, -y
        local offset = self:GetVerticalScroll()
        if y < offset then
            self:SetVerticalScroll(y)
        else
            y = y + cursorHeight - self:GetHeight()
            if y > offset then
                self:SetVerticalScroll(y)
            end
        end
    end)
    scrollArea:SetScrollChild(editbox)

    editwindow.charname = charname
    editwindow.editbox = editbox
    editwindow.ratingDropdown = ratingDropdown
    editwindow.removeButton = removebutton
    editwindow.saveButton = savebutton
    editwindow.headertext = headertext
    editwindow.ratinglabel = ratingLabel

    editwindow:SetMovable(true)
    editwindow:RegisterForDrag("LeftButton")
    editwindow:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    editwindow:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
        end)
    editwindow:EnableMouse(true)
    editwindow:Hide()

    return editwindow
end
