local Addon, ns = ...
local P, D, L = unpack(ns); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G
local string = _G.string
local table = _G.table
local math = _G.math
local pairs = _G.pairs
local ipairs = _G.ipairs
local select = _G.select
local LibStub = _G.LibStub

local ADDON_VERSION = GetAddOnMetadata(Addon, "Version")

-- Local versions for performance
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local sub = string.sub
local wipe = _G.wipe

local AGU = LibStub("AceGUI-3.0")
local LibDeformat = LibStub("LibDeformat-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local LibAlts = LibStub("LibAlts-1.0")

-- Frames
local notesFrame = nil
local editNoteFrame = nil
local addNoteFrame = nil
local confirmDeleteFrame = nil
local charNoteTooltip = nil

D.notesExportFrame = nil
D.notesImportFrame = nil

local options
local previousGroup = {}
local playerName = _G.GetUnitName("player", true)
local uiHooks = {}

local RATING_COL = 1
local NAME_COL = 2
local NOTE_COL = 3

function P:ShowOptions()
    _G.InterfaceOptionsFrame_OpenToCategory(self.optionsFrame.Main)
end

function P:OnInitialize()
    -- Called when the addon is loaded
    D.db = LibStub("AceDB-3.0"):New("PlayerNotesDB", D.defaults, "Default")

    N:OnInitialize(self)

    -- Migrate the names for patch 5.4
    P:RemoveSpacesFromRealm()

    -- Build the table data for the Notes window
    P:BuildTableData()

    -- Register the options table
    local displayName = _G.GetAddOnMetadata(Addon, "Title")
    options = options or P:GetOptions(Addon)
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(displayName, options)
    self.optionsFrame = {}
    local ACD = LibStub("AceConfigDialog-3.0")
    self.optionsFrame.Main = ACD:AddToBlizOptions(displayName, displayName, nil, "core")
    self.optionsFrame.Notes = ACD:AddToBlizOptions(displayName, L["Import/Export"], displayName, "export")

    P:RegisterChatCommand("setnote", "SetNoteHandler")
    P:RegisterChatCommand("delnote", "DelNoteHandler")
    P:RegisterChatCommand("delrating", "DelRatingHandler")
    P:RegisterChatCommand("getnote", "GetNoteHandler")
    P:RegisterChatCommand("editnote", "EditNoteHandler")
    P:RegisterChatCommand("notes", "NotesHandler")
    P:RegisterChatCommand("notesoptions", "NotesOptionsHandler")
    P:RegisterChatCommand("searchnote", "NotesHandler")
    P:RegisterChatCommand("notesexport", "NotesExportHandler")
    P:RegisterChatCommand("notesimport", "NotesImportHandler")
    P:RegisterChatCommand("notesdbcheck", "NotesDBCheckHandler")

    -- Create the LDB launcher
    D.noteLDB = LDB:NewDataObject("PlayerNotes", {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Note_06.blp",
        OnClick = function(clickedframe, button)
            if button == "RightButton" then
                local optionsFrame = _G.InterfaceOptionsFrame

                if optionsFrame:IsVisible() then
                    optionsFrame:Hide()
                else
                    P:HideNotesWindow()
                    P:ShowOptions()
                end
            elseif button == "LeftButton" then
                if P:IsNotesVisible() then
                    P:HideNotesWindow()
                else
                    local optionsFrame = _G.InterfaceOptionsFrame
                    optionsFrame:Hide()
                    P:NotesHandler("")
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            if tooltip and tooltip.AddLine then
                tooltip:AddLine(D.GREEN .. L["Player Notes"] .. " " .. ADDON_VERSION)
                tooltip:AddLine(D.YELLOW .. L["Left click"] .. " " .. D.WHITE
                        .. L["to open/close the window"])
                tooltip:AddLine(D.YELLOW .. L["Right click"] .. " " .. D.WHITE
                        .. L["to open/close the configuration."])
            end
        end
    })
    icon:Register("PlayerNotesLDB", D.noteLDB, D.db.profile.minimap)

    if not charNoteTooltip then
        charNoteTooltip = P:CreateCharNoteTooltip()
    end

    -- Hook any new temporary windows
    self:SecureHook("FCF_SetTemporaryWindowType")
    self:SecureHook("FCF_Close")

    P:ChatMessage(GREEN_FONT_COLOR_CODE.."Loaded PlayerNotes " .. ADDON_VERSION .. ".")
end

function P:FCF_SetTemporaryWindowType(chatFrame, chatType, chatTarget)
    if chatFrame and not self:IsHooked(chatFrame, "AddMessage") then
        self:RawHook(chatFrame, "AddMessage", true)
    end
end

function P:FCF_Close(frame, fallback)
    if frame and self:IsHooked(frame, "AddMessage") then
        self:Unhook(frame, "AddMessage")
    end
end

function P:SetNoteHandler(input)
    if input and #input > 0 then
        local name, note = input:match("^(%S+) *(.*)")
        name = N:FormatUnitName(name)
        if note and #note > 0 then
            N:SetNote(name, note)
            if D.db.profile.verbose == true then
                local strFormat = L["Set note for %s: %s"]
                self:Print(strFormat:format(name, note))
            end
        else
            self:Print(L["You must supply a note."])
        end
    end
end

function P:DelNoteHandler(input)
    local name, note

    if input and #input > 0 then
        name, note = input:match("^(%S+) *(.*)")
    else
        if _G.UnitExists("target") and _G.UnitIsPlayer("target") then
            local target = _G.GetUnitName("target", true)
            if target and #target > 0 then
                name = target
            end
        end
    end

    if name and #name > 0 then
        name = N:FormatUnitName(name)
        N:DeleteNote(name)
        if D.db.profile.verbose == true then
            local strFormat = L["Deleted note for %s"]
            self:Print(strFormat:format(name))
        end
    end
end

function P:DelRatingHandler(input)
    local name, note

    if input and #input > 0 then
        name, note = input:match("^(%S+) *(.*)")
    else
        if _G.UnitExists("target") and _G.UnitIsPlayer("target") then
            local target = _G.GetUnitName("target", true)
            if target and #target > 0 then
                name = target
            end
        end
    end

    if name and #name > 0 then
        name = N:FormatUnitName(name)
        N:DeleteRating(name)
        if D.db.profile.verbose == true then
            local strFormat = L["Deleted rating for %s"]
            self:Print(strFormat:format(name))
        end
    end
end

function P:UpdateNote(name, note)
    local found = false
    for i, v in ipairs(D.notesData) do
        if v[NAME_COL] == name then
            D.notesData[i][NOTE_COL] = note
            found = true
        end
    end

    if found == false then
        tinsert(D.notesData, {
            [RATING_COL] = (N:GetRating(name) or 0),
            [NAME_COL] = name,
            [NOTE_COL] = note
        })
    end

    -- If the Notes window is shown then we need to update it
    if notesFrame:IsVisible() then
        notesFrame.table:SortData()
    end
end

function P:UpdateRating(name, rating)
    local found = false
    for i, v in ipairs(D.notesData) do
        if v[NAME_COL] == name then
            D.notesData[i][RATING_COL] = rating
            found = true
        end
    end

    if found == false then
        tinsert(D.notesData, {
            [RATING_COL] = rating,
            [NAME_COL] = name,
            [NOTE_COL] = N:GetNote(name)
        })
    end

    -- If the Notes window is shown then we need to update it
    if notesFrame:IsVisible() then
        notesFrame.table:SortData()
    end
end

function P:RemoveNote(name)
    for i, v in ipairs(D.notesData) do
        if v[NAME_COL] == name then
            tremove(D.notesData, i)
        end
    end

    -- If the Notes window is shown then we need to update it
    if notesFrame:IsVisible() then
        notesFrame.table:SortData()
    end
end

function P:RemoveRating(name)
    for i, v in ipairs(D.notesData) do
        if v[NAME_COL] == name then
            if v[NOTE_COL] == nil then
                tremove(D.notesData, i)
            else
                v[RATING_COL] = 0
            end
        end
    end

    -- If the Notes window is shown then we need to update it
    if notesFrame:IsVisible() then
        notesFrame.table:SortData()
    end
end

function P:GetNoteHandler(input)
    if input and #input > 0 then
        local name, note = input:match("^(%S+) *(.*)")
        name = N:FormatUnitName(name)

        local note, rating, main, nameFound = N:GetInfoForNameOrMain(name)

        if note then
            if main and #main > 0 then
                self:Print(D.chatNoteWithMainFormat:format(P:GetRatingColor(rating), name, nameFound, note or ""))
            else
                self:Print(D.chatNoteFormat:format(P:GetRatingColor(rating), nameFound, note or ""))
            end
        else
            self:Print(L["No note found for "] .. name)
        end
    end
end

function P:NotesExportHandler(input)
    P:ShowNotesExportFrame()
end

function P:NotesImportHandler(input)
    P:ShowNotesImportFrame()
end

function P:UpdateMouseoverHighlighting(enabled)
    if notesFrame and notesFrame.table then
        local table = notesFrame.table
        if enabled then
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
    end
end

function P:NotesHandler(input)
    if input and #input > 0 then
        if input == "help" then
            print("Chat commands:")
            print("--------------------------------")
            print("/notes help - Shows this message")
            print("/notes - Brings up the GUI")
            print("/searchnote <searchterm> - Brings up the GUI. Optional search term allows filtering the list of notes.")
            print("/setnote <charname[-realm]> <note> - Sets a note for the character name specified.")
            print("/delnote <charname[-realm]> - Deletes the note for the character name specified.")
            print("/getnote <charname[-realm]> - Prints the note for the character name specified.")
            print("/editnote [charname[-realm]] - Brings up a window to edit the note for the name specified or your target if no name if specified.")
            return
        end
        notesFrame.searchterm:SetText(input)
    else
        notesFrame.searchterm:SetText("")
    end

    notesFrame.table:SortData()
    notesFrame:Show()
    notesFrame:Raise()
end

local function splitWords(str)
    local w = {}
    local function helper(word) table.insert(w, word) return nil end

    str:gsub("(%w+)", helper)
    return w
end

function P:NotesOptionsHandler(input)
    if input and #input > 0 then
        local cmds = splitWords(input)
        if cmds[1] and cmds[1] == "debug" then
            if cmds[2] and cmds[2] == "on" then
                D.db.profile.debug = true
                self:Print("Debugging on.  Use '/notesoptions debug off' to disable.")
            elseif cmds[2] and cmds[2] == "off" then
                D.db.profile.debug = false
                self:Print("Debugging off.")
            else
                self:Print("Debugging is " .. (D.db.profile.debug and "on." or "off."))
            end
        end
    else
        P:ShowOptions()
    end
end

function P:NotesDBCheckHandler(input)
    for name, note in pairs(D.db.realm.notes) do
        if name then
            if name ~= N:FormatUnitName(name) then
                self:Print("Name " .. name .. " doesn't match the formatted name.")
            end
        else
            self:Print("Found a note with a nil name value. [" .. note or "nil" .. "]")
        end
    end

    self:Print("Note DB Check finished.")
end

function P:EditNoteHandler(input, child)
    local name = nil
    if input and #input > 0 then
        name = input
    else
        if _G.UnitExists("target") and _G.UnitIsPlayer("target") then
            local target = _G.GetUnitName("target", true)
            if target and #target > 0 then
                name = target
            end
        end
    end

    if name and #name > 0 then
        local playerName, realm, unit = P:GetNameAndRealm(name)
        name = N:FormatUnitName(playerName .. "-" .. realm)

        local charNote, nameFound = N:GetNote(name)
        local rating = N:GetRating(nameFound) or 0

        local editwindow = editNoteFrame
        editwindow.charname:SetText(charNote and nameFound or name)
        editwindow.editbox:SetText(charNote or "")

        if not charNote then
            editwindow.removeButton:Disable()
        else
            editwindow.removeButton:Enable()
        end

        P:ReskinFrame(editwindow, child)
        editwindow:Show()
        editwindow:Raise()

        _G.UIDropDownMenu_SetSelectedValue(editwindow.ratingDropdown, rating)
        local ratingInfo = D.RATING_OPTIONS[rating]
        if ratingInfo and ratingInfo[1] and ratingInfo[2] then
            _G.UIDropDownMenu_SetText(editwindow.ratingDropdown, ratingInfo[2] .. ratingInfo[1] .. "|r")
        end
    end
end

function P:AddNoteHandler(child)
    local addwindow = addNoteFrame
    local rating = 0

    addwindow.charname:SetText("")
    addwindow.editbox:SetText("")

    P:ReskinFrame(addwindow, child)
    addwindow:Show()
    addwindow:Raise()

    _G.UIDropDownMenu_SetSelectedValue(addwindow.ratingDropdown, rating)
    local ratingInfo = D.RATING_OPTIONS[rating]
    if ratingInfo and ratingInfo[1] and ratingInfo[2] then
        _G.UIDropDownMenu_SetText(addwindow.ratingDropdown, ratingInfo[2] .. ratingInfo[1] .. "|r")
    end
end

function P:DeleteNoteHandler(name, frame)
    confirmDeleteFrame.charname:SetText(name);
    confirmDeleteFrame.parentFrame = frame;
    confirmDeleteFrame:Show();
    confirmDeleteFrame:Raise();
end

function P:SaveEditNote(name, note, rating)
    if name and #name > 0 and note and #note > 0 then
        N:SetNote(name, note)

        if rating then
            N:SetRating(name, rating)
        end
    end
end

function P:OnEnable()
    N:OnEnable()

    -- Register to receive the chat messages to watch for logons and who requests
    self:RegisterEvent("CHAT_MSG_SYSTEM")

    -- Register for party and raid roster updates
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("ADDON_LOADED")

    -- Create the Notes frame for later use
    notesFrame = P:CreateNotesFrame()
    D.notesFrame = notesFrame

    -- Create the Edit Note frame to use later
    editNoteFrame = P:CreateEditNoteFrame()
    P:RegisterMessage('PN_EVENT_EDITNOTECLICK', function(_, name, child)
        P:EditNoteHandler(name, child)
    end)

    -- Create the Confirm Delete frame for later use
    addNoteFrame = P:CreateAddNoteFrame()
    P:RegisterMessage('PN_EVENT_ADDNOTECLICK', function(_, child)
        P:AddNoteHandler(child)
    end)

    -- Create the Confirm Delete frame for later use
    confirmDeleteFrame = P:CreateConfirmDeleteFrame()
    P:RegisterMessage('PN_EVENT_DELETENOTECLICK', function(_, name, frame)
        P:DeleteNoteHandler(name, frame)
    end)

    P:RegisterMessage('PN_EVENT_SAVENOTE', function(_, name, text, rating)
        P:SaveEditNote(name, text, rating)
        if notesFrame:IsVisible() then
            notesFrame.table:SortData()
        end
    end)

    P:SkinFrames({
        notesFrame, editNoteFrame, addNoteFrame, confirmDeleteFrame
    });

    -- Add the Edit Note menu item on unit frames
    P:AddToUnitPopupMenu()

    -- Enable note links
    P:EnableNoteLinks()

    playerName = _G.GetUnitName("player", true)
    P:ApplyHooks()
end

function P:EnableNoteLinks()
    if D.db.profile.noteLinksInChat then
        -- Hook SetItemRef to create our own hyperlinks
        if not self:IsHooked(nil, "SetItemRef") then
            self:RawHook(nil, "SetItemRef", true)
        end
        -- Hook SetHyperlink so we can redirect charnote links
        if not self:IsHooked(_G.ItemRefTooltip, "SetHyperlink") then
            self:RawHook(_G.ItemRefTooltip, "SetHyperlink", true)
        end
        -- Hook chat frames so we can edit the messages
        self:HookChatFrames()
    end
end

function P:DisableNoteLinks()
    self:Unhook(nil, "SetItemRef")
    self:Unhook(_G.ItemRefTooltip, "SetHyperlink")
    self:UnhookChatFrames()
end

function P:OnDisable()
    -- Called when the addon is disabled
    P:UnregisterEvent("CHAT_MSG_SYSTEM")
    P:UnregisterEvent("GROUP_ROSTER_UPDATE")

    -- Remove the menu items
    P:RemoveFromUnitPopupMenu()
end

function P:SetItemRef(link, text, button, ...)
    if link and link:match("^charnote:") then
        local name = sub(link, 10)
        name = N:FormatUnitName(name)
        local note, nameFound = N:GetNote(name)
        -- Display a link
        _G.ShowUIPanel(charNoteTooltip)
        if (not charNoteTooltip:IsVisible()) then
            charNoteTooltip:SetOwner(_G.UIParent, "ANCHOR_PRESERVE")
        end
        charNoteTooltip:ClearLines()
        charNoteTooltip:AddLine(nameFound, 1, 1, 0)
        charNoteTooltip:AddLine(note or "", 1, 1, 1, true)
        charNoteTooltip:SetBackdropBorderColor(1, 1, 1, 1)
        charNoteTooltip:Show()
        return nil
    end
    return self.hooks.SetItemRef(link, text, button, ...)
end

function P:SetHyperlink(frame, link, ...)
    if link and link:match("^charnote:") then return end
    return self.hooks[frame].SetHyperlink(frame, link, ...)
end

function P:AddToUnitPopupMenu()
    self:SecureHook("UnitPopup_ShowMenu")
end

function P:RemoveFromUnitPopupMenu()
    self:Unhook("UnitPopup_ShowMenu")

    for menu in pairs(_G.UnitPopupMenus) do
        for i = #_G.UnitPopupMenus[menu], 1, -1 do
            if _G.UnitPopupMenus[menu][i] == "CN_EDIT_NOTE" then
                tremove(_G.UnitPopupMenus[menu], i)
                break
            end
        end
    end

    _G.UnitPopupButtons["CN_EDIT_NOTE"] = nil
end

function P:UnitPopup_ShowMenu(dropdownMenu, which, unit, name, userData, ...)
    if (_G.UIDROPDOWNMENU_MENU_LEVEL > 1) then return end

    local menuFound
    for menu, enabled in pairs(D.db.profile.menusToModify) do
        if menu == which and enabled then
            menuFound = true
        end
    end
    if not menuFound then return end

    local found
    for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList" .. _G.UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
        if button.value == "CN_EDIT_NOTE" then
            found = true
            button.owner = which
            button.arg1 = dropdownMenu
            button.arg2 = which
            button.func = P.EditNoteMenuClick
        end
    end

    if not found == true then
        local info = UIDropDownMenu_CreateInfo()
        info.text = L["Edit Note"]
        info.owner = which
        info.notCheckable = 1
        info.func = P.EditNoteMenuClick
        info.value = "CN_EDIT_NOTE"
        info.arg1 = dropdownMenu
        info.arg2 = which
        UIDropDownMenu_AddButton(info)
    end

    local noteButton, noteButtonIndex, cancelButton, cancelIndex
    for i = 1, _G.UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList" .. _G.UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i]
        if button.value == "CN_EDIT_NOTE" then
            noteButton = button
            noteButtonIndex = i
        end
        if button.value == CANCEL then
            cancelButton = button
            cancelIndex = i
        end
    end

    if noteButtonIndex > cancelIndex and noteButton and cancelButton then
        local noteText, cancelText, noteValue, cancelValue
        -- this is a shitty workaround to let the cancel button be the last one
        -- if the notebutton is after the cancel, then swap their places
        noteText = noteButton:GetText()
        cancelText = cancelButton:GetText()
        noteValue = noteButton.value
        cancelValue = cancelButton.value

        cancelButton.arg1 = noteButton.dropdownMenu
        cancelButton.arg2 = noteButton.which
        cancelButton.func = function()
            P:EditNoteMenuClick(dropdownMenu, which)
        end
        cancelButton:SetText(noteText)
        cancelButton.value = noteButton.value

        noteButton.func = nil
        noteButton.arg1 = nil
        noteButton.arg2 = nil
        noteButton:SetText(cancelText)
        noteButton.value = cancelValue
    end
end

function P:EditNoteMenuClick(dropdownMenu, which)
    local menu = _G.UIDROPDOWNMENU_INIT_MENU
    local name, realm, unit

    if which == "BN_FRIEND" and menu.accountInfo and menu.accountInfo.bnetAccountID then
        name, realm = P:GetNameRealmForBNetFriend(menu.accountInfo.bnetAccountID)
    else
        local dropdownFullName
        if dropdownMenu.name then
            if dropdownMenu.server and not dropdownMenu.name:find("-") then
                dropdownFullName = dropdownMenu.name .. "-" .. dropdownMenu.server
            else
                dropdownFullName = dropdownMenu.name
            end
        end

        name, realm, unit = P:GetNameAndRealm(dropdownMenu.chatTarget or dropdownFullName)
    end

    local fullname = N:FormatNameWithRealm(name, realm)
    if not fullname then
        print("Player not found/not logged in.")
        return
    end

    if D.db.profile.debug then
        local strFormat = "Menu Click: %s - %s -> %s"
        P:Print(strFormat:format(_G.tostring(name), _G.tostring(realm),
            _G.tostring(fullname)))
    end
    P:EditNoteHandler(fullname)
end

function P:IsNotesVisible()
    if notesFrame then
        return notesFrame:IsVisible()
    end
end

function P:HideNotesWindow()
    if notesFrame then
        notesFrame:Hide()
    end
end

function P:BuildTableData()
    local key, value

    for key, value in pairs(D.db.realm.notes) do
        tinsert(D.notesData, {
            [RATING_COL] = (N:GetRating(key) or 0),
            [NAME_COL] = key,
            [NOTE_COL] = value
        })
    end
end

function P:DisplayNote(name, type)
    local main
    name = N:FormatUnitName(name)

    local note, rating, main, nameFound = N:GetInfoForNameOrMain(name)
    if note then
        if main and #main > 0 then
            self:Print(D.chatNoteWithMainFormat:format(P:GetRatingColor(rating), name, nameFound, note))
        else
            self:Print(D.chatNoteFormat:format(P:GetRatingColor(rating), nameFound, note))
        end
    end
end

function P:HookChatFrames()
    for i = 1, _G.NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame ~= _G.COMBATLOG then
            if not self:IsHooked(chatFrame, "AddMessage") then
                self:RawHook(chatFrame, "AddMessage", true)
            end
        end
    end
end

function P:UnhookChatFrames()
    for i = 1, _G.NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame ~= _G.COMBATLOG then
            self:Unhook(chatFrame, "AddMessage")
        end
    end
end

local noteLinkFmt = "%s|Hcharnote:%s|h[%s]|h|r"
function P:CreateNoteLink(name, text)
    local rating = D.db.realm.ratings[name]
    return noteLinkFmt:format(P:GetRatingColor(rating), name, text)
end

local function AddNoteForChat(message, name)
    if name and #name > 0 then
        local note, nameFound = N:GetNote(name)
        if note and #note > 0 then
            local messageFmt = "%s %s"
            return messageFmt:format(message, P:CreateNoteLink(nameFound, "note"))
        end
    end

    return message
end

function P:AddMessage(frame, text, r, g, b, id, ...)
    if text and _G.type(text) == "string" and D.db.profile.noteLinksInChat == true then
        -- If no charnotes are present then insert one.
        if text:find("|Hcharnote:") == nil then
            text = text:gsub("(|Hplayer:([^:]+).-|h.-|h)", AddNoteForChat)
        end
    end
    return self.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
end

function P:CHAT_MSG_SYSTEM(event, message)
    local name, type

    if D.db.profile.showNotesOnWho == true then
        name = LibDeformat(message, _G.WHO_LIST_FORMAT)
        type = "WHO"
    end

    if not name and D.db.profile.showNotesOnWho == true then
        name = LibDeformat(message, _G.WHO_LIST_GUILD_FORMAT)
        type = "WHO"
    end

    if not name and D.db.profile.showNotesOnLogon == true then
        name = LibDeformat(message, _G.ERR_FRIEND_ONLINE_SS)
        type = "LOGON"
    end

    if name then
        self:ScheduleTimer("DisplayNote", 0.1, name, type)
    end
end

function P:ProcessGroupRosterUpdate()
    local groupType = "party"
    local numMembers = 0

    numMembers = _G.GetNumGroupMembers()
    if _G.IsInRaid() then
        groupType = "raid"
    end

    if groupType == "raid" then
        if D.db.profile.notesForRaidMembers ~= true then return end
    else
        if D.db.profile.notesForPartyMembers ~= true then return end
    end

    if numMembers == 0 then
        -- Left a group
        wipe(previousGroup)
    else
        local currentGroup = {}
        local name

        for i = 1, numMembers do
            name = _G.GetUnitName(groupType .. i, true)
            if name then
                currentGroup[name] = true

                if name ~= playerName and not previousGroup[name] == true then
                    --if D.db.profile.debug then
                    --    self:Print(name.." joined the group.")
                    --end
                    P:DisplayNote(name)
                end
            end
        end

        -- Set previous group to the current group
        wipe(previousGroup)
        for name in pairs(currentGroup) do
            previousGroup[name] = true
        end
    end
end

function P:RAID_ROSTER_UPDATE(event, message)
    P:ProcessGroupRosterUpdate()
end

function P:PARTY_MEMBERS_CHANGED(event, message)
    P:ProcessGroupRosterUpdate()
end

function P:GROUP_ROSTER_UPDATE(event, message)
    P:ProcessGroupRosterUpdate()
end

function P:ApplyHooks()
    local uiHooks = D.uiHooks

    for i = #uiHooks, 1, -1 do
        local func = uiHooks[i]
        if func() then
            table.remove(uiHooks, i)
        end
    end
end

function P:ADDON_LOADED(event, name)
    -- update after every addon load to make sure nothing removes the menu item
    P:updateLFGDropDowns()
end
