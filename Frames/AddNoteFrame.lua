local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G

local function SaveAddedNote(self, frame)
    local rating = _G.UIDropDownMenu_GetSelectedValue(frame.ratingDropdown)

    self:SendMessage('PN_EVENT_SAVENOTE', frame.charname:GetText(), frame.editbox:GetText(), rating)

    frame.charname:SetText("")
    frame.editbox:SetText("")
    frame:Hide()
end

function P:CreateAddNoteFrame()
    local addwindow = _G.CreateFrame("Frame", "PlayerNotesAddWindow", _G.UIParent)
    addwindow:SetFrameStrata("DIALOG")
    addwindow:SetToplevel(true)
    addwindow:SetWidth(400)
    addwindow:SetHeight(280)
    addwindow:SetPoint("CENTER", _G.UIParent)
    addwindow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    addwindow:SetBackdropColor(0, 0, 0, 1)

    local savebutton = _G.CreateFrame("Button", nil, addwindow, "UIPanelButtonTemplate")
    savebutton:SetText(L["Save"])
    savebutton:SetWidth(100)
    savebutton:SetHeight(20)
    savebutton:SetPoint("BOTTOM", addwindow, "BOTTOM", -60, 20)
    savebutton:SetScript("OnClick",
        function(this)
            local frame = this:GetParent()
            SaveAddedNote(self, frame)
        end)
    addwindow.savebutton = savebutton

    local cancelbutton = _G.CreateFrame("Button", nil, addwindow, "UIPanelButtonTemplate")
    cancelbutton:SetText(L["Cancel"])
    cancelbutton:SetWidth(100)
    cancelbutton:SetHeight(20)
    cancelbutton:SetPoint("BOTTOM", addwindow, "BOTTOM", 60, 20)
    cancelbutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)
    addwindow.cancelbutton = cancelbutton

    local headertext = addwindow:CreateFontString("CN_HeaderText", addwindow, "GameFontNormalLarge")
    headertext:SetPoint("TOP", addwindow, "TOP", 0, -20)
    headertext:SetText(L["Add Note"])

    local nameLabel = addwindow:CreateFontString("CN_CharNameLabel", addwindow, "GameFontNormal")
    nameLabel:SetPoint("TOP", headertext, "BOTTOM", 0, -30)
    nameLabel:SetPoint("LEFT", addwindow, "LEFT", 20, 0)
    nameLabel:SetTextColor(1.0, 1.0, 1.0, 1)
    nameLabel:SetText(L["Player Name"] .. ":")

    local charname = _G.CreateFrame("EditBox", nil, addwindow, "InputBoxTemplate")
    charname:SetFontObject(_G.ChatFontNormal)
    charname:SetWidth(200)
    charname:SetHeight(35)
    charname:SetPoint("TOPLEFT", nameLabel, "TOPRIGHT", 20, 11)
    charname:SetScript("OnShow", function(this) this:SetFocus() end)
    charname:SetScript("OnEnterPressed", function(this) this:GetParent().table:SortData() end)
    charname:SetScript("OnEscapePressed",
        function(this)
            this:SetText("")
            this:GetParent():Hide()
        end)

    local ratingLabel = addwindow:CreateFontString("CN_RatingLabel", addwindow, "GameFontNormal")
    ratingLabel:SetPoint("TOP", charname, "BOTTOM", 0, -20)
    ratingLabel:SetPoint("LEFT", addwindow, "LEFT", 20, 0)
    ratingLabel:SetTextColor(1.0, 1.0, 1.0, 1)
    ratingLabel:SetText(L["Rating"] .. ":")

    local ratingDropdown = _G.CreateFrame("Button", "CN_RatingDropDown", addwindow, "UIDropDownMenuTemplate")
    ratingDropdown:ClearAllPoints()
    ratingDropdown:SetPoint("TOPLEFT", ratingLabel, "TOPRIGHT", 20, 6)
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
    addwindow.ratingdropdown = ratingDropdown

    local editBoxContainer = _G.CreateFrame("Frame", nil, addwindow)
    editBoxContainer:SetPoint("TOPLEFT", addwindow, "TOPLEFT", 20, -150)
    editBoxContainer:SetPoint("BOTTOMRIGHT", addwindow, "BOTTOMRIGHT", -40, 50)
    editBoxContainer:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 3, top = 4, bottom = 3 }
    })
    editBoxContainer:SetBackdropColor(0, 0, 0, 0.9)
    addwindow.scrolleditframe = editBoxContainer

    local scrollArea = _G.CreateFrame("ScrollFrame", "CN_EditNote_EditScroll", addwindow, "UIPanelScrollFrameTemplate")
    scrollArea:SetPoint("TOPLEFT", editBoxContainer, "TOPLEFT", 6, -6)
    scrollArea:SetPoint("BOTTOMRIGHT", editBoxContainer, "BOTTOMRIGHT", -6, 6)

    local editbox = _G.CreateFrame("EditBox", "CN_EditNote_EditBox", addwindow)
    editbox:SetFontObject(_G.ChatFontNormal)
    editbox:SetMultiLine(true)
    editbox:SetAutoFocus(true)
    editbox:SetWidth(300)
    editbox:SetHeight(5 * 14)
    editbox:SetMaxLetters(0)
    editbox:SetScript("OnTextChanged",
        function(this)
            local text = editbox:GetText():gsub("%s*", "")
            local name = charname:GetText():gsub("%s*", "")
            if text == "" or name == "" then
                savebutton:Disable()
            else
                savebutton:Enable()
            end
        end
    )
    addwindow.scrolleditframe.editboxframe = editbox

    charname:SetScript("OnTextChanged",
        function(this)
            local text = editbox:GetText():gsub("%s*", "")
            local name = charname:GetText():gsub("%s*", "")
            if text == "" or name == "" then
                savebutton:Disable()
            else
                savebutton:Enable()
            end
        end
    )

    if not D.db.profile.multilineNotes then
        editbox:SetScript("OnEnterPressed",
            function(this)
                local frame = this:GetParent():GetParent()
                SaveAddedNote(self, frame)
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

    addwindow.charname = charname
    addwindow.nameinput = charname
    addwindow.namelabel = nameLabel
    addwindow.editbox = editbox
    addwindow.ratingDropdown = ratingDropdown

    addwindow:SetMovable(true)
    addwindow:RegisterForDrag("LeftButton")
    addwindow:SetScript("OnDragStart",
        function(this, button)
            this:StartMoving()
        end)
    addwindow:SetScript("OnDragStop",
        function(this)
            this:StopMovingOrSizing()
        end)
    addwindow:EnableMouse(true)
    addwindow:Hide()

    return addwindow
end
