local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G
local LibStub = _G.LibStub
local notesData = D.notesData

local function GetRatingColorObj(rating)
    local color = D.YELLOW_COLOR
    if rating ~= nil and rating >= -1 and rating <= 1 then
        local ratingInfo = D.RATING_OPTIONS[rating]
        if ratingInfo and ratingInfo[3] then
            color = ratingInfo[3]
        end
    end
    return color
end

local function GetRatingImage(rating)
    local image = ""
    if rating ~= nil and rating >= -1 and rating <= 1 then
        local ratingInfo = D.RATING_OPTIONS[rating]
        if ratingInfo and ratingInfo[4] then
            image = ratingInfo[4]
        end
    end
    return image
end

function P:CreateNotesFrame()
    local noteswindow = _G.CreateFrame("Frame", "PlayerNotesWindow", _G.UIParent, "BackdropTemplate")
    noteswindow:SetFrameStrata("DIALOG")
    noteswindow:SetToplevel(true)
    noteswindow:SetWidth(630)
    noteswindow:SetHeight(390)
    if D.db.profile.remember_main_pos then
        noteswindow:SetPoint("CENTER", _G.UIParent, "CENTER",
            D.db.profile.notes_window_x, D.db.profile.notes_window_y)
    else
        noteswindow:SetPoint("CENTER", _G.UIParent)
    end
    noteswindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    noteswindow:SetScript("OnShow", function()
        PlaySound(844) -- SOUNDKIT.IG_QUEST_LOG_OPEN
    end)

    local ScrollingTable = LibStub("ScrollingTable");

    local RATING_COL = 1
    local NAME_COL = 2
    local NOTE_COL = 3

    local cols = {}
    cols[RATING_COL] = {
        ["name"] = L["RATING_COLUMN_NAME"],
        ["width"] = 15,
        ["colorargs"] = nil,
        ["bgcolor"] = {
            ["r"] = 0.0,
            ["g"] = 0.0,
            ["b"] = 0.0,
            ["a"] = 1.0
        },
        ["sortnext"] = NAME_COL,
        ["DoCellUpdate"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
            if fShow then
                local image = GetRatingImage(data[realrow][RATING_COL])
                if image and #image > 0 then
                    cellFrame:SetBackdrop({ bgFile = image })
                else
                    cellFrame:SetBackdrop(nil)
                end
            end
        end,
    }
    cols[NAME_COL] = {
        ["name"] = L["Character Name"],
        ["width"] = 150,
        ["align"] = "LEFT",
        ["color"] = function(data, cols, realrow, column, table)
            return GetRatingColorObj(data[realrow][RATING_COL])
        end,
        ["colorargs"] = nil,
        ["bgcolor"] = {
            ["r"] = 0.0,
            ["g"] = 0.0,
            ["b"] = 0.0,
            ["a"] = 1.0
        },
        ["defaultsort"] = "dsc",
        ["sort"] = "dsc",
        ["DoCellUpdate"] = nil,
    }
    cols[NOTE_COL] = {
        ["name"] = L["Note"],
        ["width"] = 400,
        ["align"] = "LEFT",
        ["color"] = {
            ["r"] = 1.0,
            ["g"] = 1.0,
            ["b"] = 1.0,
            ["a"] = 1.0
        },
        ["colorargs"] = nil,
        ["bgcolor"] = {
            ["r"] = 0.0,
            ["g"] = 0.0,
            ["b"] = 0.0,
            ["a"] = 1.0
        },
        ["sortnext"] = NAME_COL,
        ["DoCellUpdate"] = nil,
    }

    local table = ScrollingTable:CreateST(cols, 15, nil, nil, noteswindow);
    noteswindow.scrollframe = table

    local headertext = noteswindow:CreateFontString("PN_Notes_HeaderText", noteswindow, "GameFontNormalLarge")
    headertext:SetPoint("TOP", noteswindow, "TOP", 0, -10)
    headertext:SetText(L["Player Notes"])

    local searchterm = _G.CreateFrame("EditBox", nil, noteswindow, "InputBoxTemplate")
    searchterm:SetFontObject(_G.ChatFontNormal)
    searchterm:SetWidth(300)
    searchterm:SetHeight(35)
    searchterm:SetPoint("TOPLEFT", noteswindow, "TOPLEFT", 25, -40)
    searchterm:SetScript("OnShow", function(this) this:SetFocus() end)
    searchterm:SetScript("OnEnterPressed", function(this) this:GetParent().table:SortData() end)
    searchterm:SetScript("OnEscapePressed",
        function(this)
            this:SetText("")
            this:GetParent():Hide()
        end)

    table.frame:SetPoint("TOP", searchterm, "BOTTOM", 0, -30)
    table.frame:SetPoint("LEFT", noteswindow, "LEFT", 20, 0)

    local closebutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelCloseButton")
    closebutton:SetPoint("TOPRIGHT", -4, -4)
    closebutton:SetScript("OnClick", function(this) this:GetParent():Hide(); end)
    noteswindow.closebutton = closebutton

    local searchbutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelButtonTemplate")
    searchbutton:SetText(L["Search"])
    searchbutton:SetWidth(100)
    searchbutton:SetHeight(20)
    searchbutton:SetPoint("LEFT", searchterm, "RIGHT", 10, 0)
    searchbutton:SetScript("OnClick", function(this) this:GetParent().table:SortData() end)
    noteswindow.searchbutton = searchbutton

    local clearbutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelButtonTemplate")
    clearbutton:SetText(L["Clear"])
    clearbutton:SetWidth(100)
    clearbutton:SetHeight(20)
    clearbutton:SetPoint("LEFT", searchbutton, "RIGHT", 10, 0)
    clearbutton:SetScript("OnClick",
        function(this)
            searchterm:SetText("")
            this:GetParent().table:SortData()
        end)
    noteswindow.clearbutton = clearbutton

    local deletebutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelButtonTemplate")
    deletebutton:SetText(L["Delete"])
    deletebutton:SetWidth(90)
    deletebutton:SetHeight(20)
    deletebutton:SetPoint("BOTTOM", noteswindow, "BOTTOM", 120, 30)
    deletebutton:SetScript("OnClick",
        function(this)
            local frame = this:GetParent()
            if frame.table:GetSelection() then
                local row = frame.table:GetRow(frame.table:GetSelection())
                if row and row[NAME_COL] and #row[NAME_COL] > 0 then
                    self:SendMessage('PN_EVENT_DELETENOTECLICK', row[NAME_COL])
                end
            end
        end)
    noteswindow.deletebutton = deletebutton

    local editbutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelButtonTemplate")
    editbutton:SetText(L["Edit"])
    editbutton:SetWidth(90)
    editbutton:SetHeight(20)
    editbutton:SetPoint("BOTTOM", noteswindow, "BOTTOM", 0, 30)
    editbutton:SetScript("OnClick",
        function(this)
            local frame = this:GetParent()
            if frame.table:GetSelection() then
                local row = frame.table:GetRow(frame.table:GetSelection())
                if row and row[NAME_COL] and #row[NAME_COL] > 0 then
                    self:SendMessage('PN_EVENT_EDITNOTECLICK', row[NAME_COL], true)
                end
            end
        end)
    noteswindow.editbutton = editbutton

    local addbutton = _G.CreateFrame("Button", nil, noteswindow, "UIPanelButtonTemplate")
    addbutton:SetText(L["Add"])
    addbutton:SetWidth(90)
    addbutton:SetHeight(20)
    addbutton:SetPoint("BOTTOM", noteswindow, "BOTTOM", -120, 30)
    addbutton:SetScript("OnClick",
        function(this)
            self:SendMessage('PN_EVENT_ADDNOTECLICK', true)
        end)
    noteswindow.addbutton = addbutton

    noteswindow.table = table
    noteswindow.searchterm = searchterm

    if D.db.profile.mouseoverHighlighting then
        table:RegisterEvents(table.DefaultEvents)
    else
        table:RegisterEvents({
            ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
                return true;
            end,
            ["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, table, ...)
                return true;
            end
        })
    end

    table:EnableSelection(true)
    table:SetData(notesData, true)
    table:SetFilter(function(self, row)
        local searchterm = searchterm:GetText():lower()
        if searchterm and #searchterm > 0 then
            local term = searchterm:lower()
            if row[NAME_COL]:lower():find(term) or row[NOTE_COL]:lower():find(term) then
                return true
            end

            return false
        else
            return true
        end
    end)

    noteswindow.lock = D.db.profile.lock_main_window

    noteswindow:SetMovable(true)
    noteswindow:RegisterForDrag("LeftButton")
    noteswindow:SetScript("OnDragStart",
        function(self, button)
            if not self.lock then
                self:StartMoving()
            end
        end)
    noteswindow:SetScript("OnDragStop",
        function(self)
            self:StopMovingOrSizing()
            if D.db.profile.remember_main_pos then
                local scale = self:GetEffectiveScale() / _G.UIParent:GetEffectiveScale()
                local x, y = self:GetCenter()
                x, y = x * scale, y * scale
                x = x - _G.GetScreenWidth() / 2
                y = y - _G.GetScreenHeight() / 2
                x = x / self:GetScale()
                y = y / self:GetScale()
                D.db.profile.notes_window_x,
                D.db.profile.notes_window_y = x, y
                self:SetUserPlaced(false);
            end
        end)
    noteswindow:EnableMouse(true)
    noteswindow:Hide()

    return noteswindow
end
