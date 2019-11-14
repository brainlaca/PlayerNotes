local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G

local function editLFGPlayerNote(_, name)
    P:EditNoteHandler(name)
end

local function addEditNoteButton(menuArr, playerName)
    local cancelIndex, foundMenuIndex

    for i = 0, #menuArr do
        if menuArr[i] and not cancelIndex then
            if menuArr[i].func == editLFGPlayerNote then
                foundMenuIndex = i
            elseif menuArr[i].text == CANCEL then
                cancelIndex = i
            end
        end
    end

    if foundMenuIndex then
        menuArr[foundMenuIndex].arg1 = playerName
        menuArr[foundMenuIndex].disabled = not playerName
    elseif cancelIndex then
        menuArr[cancelIndex] = {}
        menuArr[cancelIndex].text = L["Edit Note"]
        menuArr[cancelIndex].func = editLFGPlayerNote
        menuArr[cancelIndex].arg1 = playerName
        menuArr[cancelIndex].disabled = not playerName
        menuArr[cancelIndex].notCheckable = true

        cancelIndex = cancelIndex + 1
        menuArr[cancelIndex] = {}
        menuArr[cancelIndex].text = CANCEL
        menuArr[cancelIndex].notCheckable = true
    end

    return menuArr;
end

function P:updateLFGDropDowns()
    local LFGListUtil_GetSearchEntryMenu_Old = LFGListUtil_GetSearchEntryMenu
    LFGListUtil_GetSearchEntryMenu = function(resultID)
        local menuArr = LFGListUtil_GetSearchEntryMenu_Old(resultID)
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

        return addEditNoteButton(menuArr, searchResultInfo.leaderName)
    end

    local LFGListUtil_GetApplicantMemberMenu_Old = LFGListUtil_GetApplicantMemberMenu
    LFGListUtil_GetApplicantMemberMenu = function(applicantID, memberIdx)
        local menuArr = LFGListUtil_GetApplicantMemberMenu_Old(applicantID, memberIdx)
        local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole =
        C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)

        return addEditNoteButton(menuArr, name)
    end
end
