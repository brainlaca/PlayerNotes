local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G
local LibStub = _G.LibStub
local AGU = LibStub("AceGUI-3.0")
local string = _G.string
local table = _G.table
local ipairs = _G.ipairs

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function ParseNoteLine(s, lineIndex)
    s = s .. ','
    local t = {}
    local fieldstart = 1
    repeat
        if string.find(s, '^"', fieldstart) then
            local a, c
            local i  = fieldstart
            repeat
                a, i, c = string.find(s, '"("?)', i+1)
            until c ~= '"'

            if not i then
                print('ERROR: unmatched " in line: ' .. lineIndex)
                return nil
            end

            local f = string.sub(s, fieldstart+1, i-1)
            table.insert(t, (string.gsub(f, '""', '"')))
            fieldstart = string.find(s, ',', i) + 1
        else
            local nexti = string.find(s, ',', fieldstart)
            table.insert(t, string.sub(s, fieldstart, nexti-1))
            fieldstart = nexti + 1
        end
    until fieldstart > string.len(s)
    return t
end

local function ImportNotesFromText(importData)
    local i = 1
    local notesData = {}

    for line in importData:gmatch("([^\n]*)\n?") do
        local data = ParseNoteLine(line, i)
        if not data then return end

        table.insert(notesData, data)
        i = i + 1
    end

    print("Importing:")
    for i, v in ipairs(notesData) do
        if v[1] and v[2] and v[3] then
            print("name: " .. v[1] .. " - note: " .. v[2] .. " - rating: " .. v[3])
            N:SetNoteAndRating(trim(v[1]), v[2], tonumber(trim(v[3])))
        end
    end
end

function P:ShowNotesImportFrame()
    if D.notesImportFrame then return end

    local frame = AGU:Create("Frame")
    frame:SetTitle(L["Notes Import"])
    frame:SetWidth(650)
    frame:SetHeight(400)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        D.notesImportFrame = nil
    end)

    D.notesImportFrame = frame

    local multiline = AGU:Create("MultiLineEditBox")
    multiline:SetLabel(L["NotesImport_ImportLabel"])
    multiline:SetNumLines(10)
    multiline:SetMaxLetters(0)
    multiline:SetFullWidth(true)
    multiline:DisableButton(true)
    frame:AddChild(multiline)
    frame.multiline = multiline

    local spacer = AGU:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    frame:AddChild(spacer)

    local importButton = AGU:Create("Button")
    importButton:SetText(L["Import"])
    importButton:SetCallback("OnClick",
        function(widget)
            ImportNotesFromText(D.notesImportFrame.multiline:GetText())
        end)
    frame:AddChild(importButton)
end
