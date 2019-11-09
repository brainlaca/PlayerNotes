local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G
local LibStub = _G.LibStub
local pairs = _G.pairs
local table = _G.table
local tinsert, tremove, tconcat = table.insert, table.remove, table.concat
local wipe = _G.wipe

local AGU = LibStub("AceGUI-3.0")
local notesExportBuffer = {}

local function escapeField(value, escapeChar)
    local strFmt = "%s%s%s"
    local doubleEscape = escapeChar .. escapeChar
    if escapeChar and escapeChar ~= "" then
        local escapedStr = value:gsub(escapeChar, doubleEscape)
        return strFmt:format(escapeChar, escapedStr, escapeChar)
    else
        return value
    end
end

local function GenerateNotesExport()
    local notesExportText = ""

    local delimiter = ","
    local fields = {}
    local quote = ""
    local rating
    if D.db.profile.exportEscape == true then
        quote = "\""
    end

    for name, note in pairs(D.db.realm.notes) do
        wipe(fields)
        if D.db.profile.exportUseName == true then
            tinsert(fields, escapeField(name, quote))
        end
        if D.db.profile.exportUseNote == true then
            tinsert(fields, escapeField(note, quote))
        end
        if D.db.profile.exportUseRating == true then
            rating = (N:GetRating(name) or 0)
            tinsert(fields, rating)
        end

        local line = tconcat(fields, delimiter)
        tinsert(notesExportBuffer, line)
    end

    -- Add a blank line so a final new line is added
    tinsert(notesExportBuffer, "")
    notesExportText = tconcat(notesExportBuffer, "\n")
    wipe(notesExportBuffer)
    return notesExportText
end

function P:ShowNotesExportFrame()
    if D.notesExportFrame then return end

    local frame = AGU:Create("Frame")
    frame:SetTitle(L["Notes Export"])
    frame:SetWidth(650)
    frame:SetHeight(400)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        D.notesExportFrame = nil
    end)

    D.notesExportFrame = frame

    local multiline = AGU:Create("MultiLineEditBox")
    multiline:SetLabel(L["NotesExport_ExportLabel"])
    multiline:SetNumLines(10)
    multiline:SetMaxLetters(0)
    multiline:SetFullWidth(true)
    multiline:DisableButton(true)
    frame:AddChild(multiline)
    frame.multiline = multiline

    local fieldsHeading = AGU:Create("Heading")
    fieldsHeading:SetText("Fields to Export")
    fieldsHeading:SetFullWidth(true)
    frame:AddChild(fieldsHeading)

    local nameOption = AGU:Create("CheckBox")
    nameOption:SetLabel(L["Character Name"])
    nameOption:SetCallback("OnValueChanged",
        function(widget, event, value)
            D.db.profile.exportUseName = value
        end)
    nameOption:SetValue(D.db.profile.exportUseName)
    frame:AddChild(nameOption)

    local noteOption = AGU:Create("CheckBox")
    noteOption:SetLabel(L["Note"])
    noteOption:SetCallback("OnValueChanged",
        function(widget, event, value)
            D.db.profile.exportUseNote = value
        end)
    noteOption:SetValue(D.db.profile.exportUseNote)
    frame:AddChild(noteOption)

    local ratingOption = AGU:Create("CheckBox")
    ratingOption:SetLabel(L["Rating"])
    ratingOption:SetCallback("OnValueChanged",
        function(widget, event, value)
            D.db.profile.exportUseRating = value
        end)
    ratingOption:SetValue(D.db.profile.exportUseRating)
    frame:AddChild(ratingOption)

    local optionsHeading = AGU:Create("Heading")
    optionsHeading:SetText("Options")
    optionsHeading:SetFullWidth(true)
    frame:AddChild(optionsHeading)

    local escapeOption = AGU:Create("CheckBox")
    escapeOption:SetLabel(L["NotesExport_Escape"])
    escapeOption:SetCallback("OnValueChanged",
        function(widget, event, value)
            D.db.profile.exportEscape = value
        end)
    escapeOption:SetValue(D.db.profile.exportEscape)
    frame:AddChild(escapeOption)

    local spacer = AGU:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)

    local exportButton = AGU:Create("Button")
    exportButton:SetText(L["Export"])
    exportButton:SetCallback("OnClick",
        function(widget)
            local notesExportText = GenerateNotesExport(D.db.profile.exportUseName,
                D.db.profile.exportUseNotes,
                D.db.profile.exportUseRating)
            frame.multiline:SetText(notesExportText)
        end)
    frame:AddChild(exportButton)
end
