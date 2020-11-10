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

D.CharNoteTooltip = nil
D.notesExportFrame = nil
D.notesImportFrame = nil

local options
local previousGroup = {}
local playerName = _G.GetUnitName("player", true)

local RATING_COL = 1
local NAME_COL = 2
local NOTE_COL = 3

local loadingAgainSoon

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

    P:RegisterChatCommand("setpn", "SetNoteHandler")
    P:RegisterChatCommand("delpn", "DelNoteHandler")
    P:RegisterChatCommand("delpr", "DelRatingHandler")
    P:RegisterChatCommand("getpn", "GetNoteHandler")
    P:RegisterChatCommand("editpn", "EditNoteHandler")
    P:RegisterChatCommand("pn", "NotesHandler")
    P:RegisterChatCommand("pnoptions", "NotesOptionsHandler")
    P:RegisterChatCommand("searchpn", "NotesHandler")
    P:RegisterChatCommand("pnexport", "NotesExportHandler")
    P:RegisterChatCommand("pnimport", "NotesImportHandler")
    P:RegisterChatCommand("pndbcheck", "NotesDBCheckHandler")

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

    P:ChatMessage(GREEN_FONT_COLOR_CODE.."Loaded PlayerNotes " .. ADDON_VERSION .. ". "
        .. "Type '/pn help' to show the command line tools.")
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
            print("/pn help - Shows this message")
            print("/pn - Brings up the GUI")
            print("/searchpn <searchterm> - Brings up the GUI. Optional search term allows filtering the list of notes.")
            print("/setpn <charname[-realm]> <note> - Sets a note for the character name specified.")
            print("/delpn <charname[-realm]> - Deletes the note for the character name specified.")
            print("/getpn <charname[-realm]> - Prints the note for the character name specified.")
            print("/editpn [charname[-realm]] - Brings up a window to edit the note for the name specified or your target if no name if specified.")
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
                self:Print("Debugging on.  Use '/pnoptions debug off' to disable.")
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

        -- P:ReskinFrame(editwindow, child)
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

    -- P:ReskinFrame(addwindow, child)
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
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

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

    if not D.CharNoteTooltip then
        P:CreateCharNoteTooltip()
    end

    P:SkinFrames({
        notesFrame, editNoteFrame, addNoteFrame, confirmDeleteFrame, D.CharNoteTooltip
    });

    playerName = _G.GetUnitName("player", true)
end

function P:OnDisable()
    return
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

function P:GetNoteForPlayer(name)
    local pName, realm, unit = P:GetNameAndRealm(name)
    name = N:FormatUnitName(pName .. "-" .. realm)

    local note, _ = N:GetNote(name)
    if note then
        return note
    end

    return nil
end

function P:GetRatingColorForPlayer(name)
    local pName, realm, unit = P:GetNameAndRealm(name)
    name = N:FormatUnitName(pName .. "-" .. realm)

    local note, nameFound = N:GetNote(name)
    if not nameFound then
        return
    end

    local rating = N:GetRating(nameFound)
    return P:GetRatingColor(rating)
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

function P:ADDON_LOADED(event, name)
    -- because of blizzard ui addon dependencies retry loading not-yet-loaded modules whenever an addon is loaded
    P:LoadModules()
end

function P:PLAYER_ENTERING_WORLD(event, name)
    P:LoadModules()
end

function P:LoadModules()
    local modules = P:GetModules()
    local numLoaded = 0
    local numPending = 0

    for _, module in ipairs(modules) do
        if not module:IsLoaded() and module:CanLoad() then
            if module:HasDependencies() then
                numLoaded = numLoaded + 1
                module:Load()
            else
                numPending = numPending + 1
            end
        end
    end
    if not loadingAgainSoon and numLoaded > 0 and numPending > 0 then
        loadingAgainSoon = true
        C_Timer.After(1, function()
            loadingAgainSoon = false
            P:LoadModules()
        end)
    end
end
