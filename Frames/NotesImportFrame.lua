local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G
local LibStub = _G.LibStub
local AGU = LibStub("AceGUI-3.0")

local function ImportNotesFromText(importData)
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
