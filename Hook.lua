local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G

function P:showTooltip(tooltip, toonName, ...)
    local separatorBelow = ...
    local name, realm, unit = P:GetNameAndRealm(toonName)
    -- if no realm then just return, might be happening before PLAYER_LOGIN fire
    if not realm then return end

    local note, rating, main, nameFound = N:GetInfoForNameOrMain(name .. "-" .. realm)
    if not note then return end

    if D.db.profile.wrapTooltip == true then
        note = P:Wrap(note, D.db.profile.wrapTooltipLength, "    ", "", 4)
    end

    tooltip:AddLine(" ")
    if main and #main > 0 then
        tooltip:AddLine(D.tooltipNoteWithMainFormat:format(P:GetRatingColor(rating), nameFound, note))
    else
        tooltip:AddLine(D.tooltipNoteFormat:format(P:GetRatingColor(rating), note),
            1, 1, 1, not D.db.profile.wrapTooltip)
    end

    if separatorBelow then
        tooltip:AddLine(" ")
    end

    tooltip:Show()
end

-- GameTooltip
do
    local tooltip = P:NewModule("GameTooltip")

    local function OnTooltipSetUnit(self)
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        local _, unit = self:GetUnit()
        P:showTooltip(GameTooltip, unit, 1)
    end

    function tooltip:OnLoad()
        self:Enable()
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    end
end

-- Guild Tooltip (not used, -> community)
do
    local tooltip = P:NewModule("GuildTooltip")

    local function OnEnter(self)
        if not self.guildIndex or D.db.profile.showNotesInTooltips == false then
            return
        end

        local fullName = GetGuildRosterInfo(self.guildIndex)
        if not fullName then
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        P:showTooltip(GameTooltip, fullName, 0, self)
    end

    local function OnLeave(self)
        if not self.guildIndex or D.db.profile.showNotesInTooltips == false then
            return
        end
        GameTooltip:Hide()
    end

    local function OnScroll()
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        GameTooltip:Hide()
        P:ExecuteWidgetHandler(GetMouseFocus(), "OnEnter")
    end

    function tooltip:CanLoad()
        return _G.GuildFrame
    end

    function tooltip:OnLoad()
        self:Enable()
        for i = 1, #GuildRosterContainer.buttons do
            local button = GuildRosterContainer.buttons[i]
            button:HookScript("OnEnter", OnEnter)
            button:HookScript("OnLeave", OnLeave)
        end
        hooksecurefunc(GuildRosterContainer, "update", OnScroll)
    end
end

-- CommunityTooltip
do
    local tooltip = P:NewModule("CommunityTooltip")

    local hooked = {}
    local completed

    local function OnEnter(self)
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        local info = self:GetMemberInfo()
        if not info or (info.clubType ~= Enum.ClubType.Guild and info.clubType ~= Enum.ClubType.Character) then
            return
        end
        if info.name then
            local hasOwner = GameTooltip:GetOwner()
            if not hasOwner then
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            end
            P:showTooltip(GameTooltip, info.name)
        end
    end

    local function OnLeave(self)
        GameTooltip:Hide()
    end

    local function SmartHookButtons(buttons)
        if not buttons then
            return
        end
        local numButtons = 0
        for _, button in pairs(buttons) do
            numButtons = numButtons + 1
            if not hooked[button] then
                hooked[button] = true
                button:HookScript("OnEnter", OnEnter)
                button:HookScript("OnLeave", OnLeave)
                if type(button.OnEnter) == "function" then hooksecurefunc(button, "OnEnter", OnEnter) end
                if type(button.OnLeave) == "function" then hooksecurefunc(button, "OnLeave", OnLeave) end
            end
        end
        return numButtons > 0
    end

    local function OnRefreshApplyHooks()
        if completed then
            return
        end
        SmartHookButtons(_G.CommunitiesFrame.MemberList.ListScrollFrame.buttons)
        SmartHookButtons(_G.ClubFinderGuildFinderFrame.CommunityCards.ListScrollFrame.buttons)
        SmartHookButtons(_G.ClubFinderGuildFinderFrame.PendingCommunityCards.ListScrollFrame.buttons)
        SmartHookButtons(_G.ClubFinderGuildFinderFrame.GuildCards.Cards)
        SmartHookButtons(_G.ClubFinderGuildFinderFrame.PendingGuildCards.Cards)
        SmartHookButtons(_G.ClubFinderCommunityAndGuildFinderFrame.CommunityCards.ListScrollFrame.buttons)
        SmartHookButtons(_G.ClubFinderCommunityAndGuildFinderFrame.PendingCommunityCards.ListScrollFrame.buttons)
        SmartHookButtons(_G.ClubFinderCommunityAndGuildFinderFrame.GuildCards.Cards)
        SmartHookButtons(_G.ClubFinderCommunityAndGuildFinderFrame.PendingGuildCards.Cards)
        return true
    end

    local function OnScroll()
        if not D.db.profile.showNotesInTooltips == false then
            return
        end
        GameTooltip:Hide()
        P:ExecuteWidgetHandler(GetMouseFocus(), "OnEnter")
    end

    function tooltip:CanLoad()
        return _G.CommunitiesFrame and _G.ClubFinderGuildFinderFrame and _G.ClubFinderCommunityAndGuildFinderFrame
    end

    function tooltip:OnLoad()
        self:Enable()
        hooksecurefunc(_G.CommunitiesFrame.MemberList, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.CommunitiesFrame.MemberList, "Update", OnScroll)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.CommunityCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.CommunityCards.ListScrollFrame, "update", OnScroll)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.PendingCommunityCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.PendingCommunityCards.ListScrollFrame, "update", OnScroll)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.GuildCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderGuildFinderFrame.PendingGuildCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.CommunityCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.CommunityCards.ListScrollFrame, "update", OnScroll)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.PendingCommunityCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.PendingCommunityCards.ListScrollFrame, "update", OnScroll)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.GuildCards, "RefreshLayout", OnRefreshApplyHooks)
        hooksecurefunc(_G.ClubFinderCommunityAndGuildFinderFrame.PendingGuildCards, "RefreshLayout", OnRefreshApplyHooks)
    end

end

-- Friends List Tooltip
do
    local tooltip = P:NewModule("FriendTooltip")

    local function FriendsTooltip_Show(self)
        if D.db.profile.showNotesInTooltips == false then
            return
        end

        local fullName
        local button = self.button

        if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
            local bnetIDAccountInfo = C_BattleNet.GetFriendAccountInfo(button.id)
            if bnetIDAccountInfo then
                fullName = P:GetNameRealmForBNetFriend(bnetIDAccountInfo.bnetAccountID)
            end
        elseif button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
            local friendInfo = C_FriendList.GetFriendInfoByIndex(button.id)
            if friendInfo then
                fullName = friendInfo.name
            end
        end

        if fullName then
            P:showTooltip(GameTooltip, fullName)
        else
            GameTooltip:Hide()
        end
    end

    local function FriendsTooltip_Hide()
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        GameTooltip:Hide()
    end

    function tooltip:OnLoad()
        self:Enable()
        hooksecurefunc(FriendsTooltip, "Show", FriendsTooltip_Show)
        hooksecurefunc(FriendsTooltip, "Hide", FriendsTooltip_Hide)
    end
end

-- Lfg Tooltip
do
    local tooltip = P:NewModule("LfgTooltip")

    local currentResult = {}
    local hooked = {}
    local OnEnter
    local OnLeave

    local function SetSearchEntry(tooltip, resultID, autoAcceptOption)
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        local entry = C_LFGList.GetSearchResultInfo(resultID)
        if not entry then
            table.wipe(currentResult)
            return
        end

        currentResult.activityID = entry.activityID
        currentResult.leaderName = entry.leaderName

        if entry.leaderName then
            P:showTooltip(GameTooltip, entry.leaderName)
        end
    end

    local function HookApplicantButtons(buttons)
        for _, button in pairs(buttons) do
            if not hooked[button] then
                hooked[button] = true
                button:HookScript("OnEnter", OnEnter)
                button:HookScript("OnLeave", OnLeave)
            end
        end
    end

    local function ShowApplicantProfile(parent, applicantID, memberIdx)
        local fullName = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
        if not fullName then
            return false
        end
        local hasOwner = GameTooltip:GetOwner()
        if not hasOwner then
            GameTooltip:SetOwner(parent, "ANCHOR_TOPLEFT", 0, 0)
        end
        P:showTooltip(GameTooltip, fullName)

        return true
    end

    function OnEnter(self)
        if D.db.profile.showNotesInTooltips == false then
            return
        end
        if self.applicantID and self.Members then
            for i = 1, #self.Members do
                local b = self.Members[i]
                if not hooked[b] then
                    hooked[b] = 1
                    b:HookScript("OnEnter", OnEnter)
                    b:HookScript("OnLeave", OnLeave)
                end
            end
        elseif self.memberIdx then
            local fullName = C_LFGList.GetApplicantMemberInfo(self:GetParent().applicantID, self.memberIdx)
            if fullName then
                local hasOwner = GameTooltip:GetOwner()
                if not hasOwner then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                end
                P:showTooltip(GameTooltip, fullName)
            end
        end
    end

    function OnLeave(self)
        if self.applicantID or self.memberIdx then
            GameTooltip:Hide()
        end
    end


    function OnEnter(self)
        if D.db.profile.showNotesInTooltips == false then
            return
        end

        local entry = C_LFGList.GetActiveEntryInfo()
        if entry then
            currentResult.activityID = entry.activityID
        end
        if not currentResult.activityID then
            return
        end
        if self.applicantID and self.Members then
            HookApplicantButtons(self.Members)
        elseif self.memberIdx then
            ShowApplicantProfile(self, self:GetParent().applicantID, self.memberIdx)
        end
    end

    function OnLeave(self)
        GameTooltip:Hide()
    end

    function tooltip:CanLoad()
        return _G.LFGListSearchPanelScrollFrameButton1 and _G.LFGListApplicationViewerScrollFrameButton1
    end

    function tooltip:OnLoad()
        self:Enable()
        -- the player looking at groups
        hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntry)
        for i = 1, 10 do
            local button = _G["LFGListSearchPanelScrollFrameButton" .. i]
            button:HookScript("OnLeave", OnLeave)
        end
        -- the player hosting a group looking at applicants
        for i = 1, 14 do
            local button = _G["LFGListApplicationViewerScrollFrameButton" .. i]
            button:HookScript("OnEnter", OnEnter)
            button:HookScript("OnLeave", OnLeave)
        end
        -- remove the shroud and allow hovering over people even when not the group leader
        do
            local f = _G.LFGListFrame.ApplicationViewer.UnempoweredCover
            f:EnableMouse(false)
            f:EnableMouseWheel(false)
            f:SetToplevel(false)
        end
    end
end

-- text href tooltip
do
    local chatTooltip = P:NewModule("CharNoteTooltip")
    local noteLinkFmt = "%s|Hnote%s|h[%s]|h|r"

    local function SetItemRef(link, text, button, ...)
        if link and link:match("^note") then
            local name = string.sub(link, 5)
            name = N:FormatUnitName(name)
            local note, nameFound = N:GetNote(name)

            -- Display a link
            _G.ShowUIPanel(D.CharNoteTooltip)
            if (not D.CharNoteTooltip:IsVisible()) then
                D.CharNoteTooltip:SetOwner(_G.UIParent, "ANCHOR_PRESERVE")
            end

            D.CharNoteTooltip:SetPadding(16, 0)
            D.CharNoteTooltip:ClearLines()
            D.CharNoteTooltip:AddLine(nameFound, 1, 1, 0)
            D.CharNoteTooltip:AddLine(note or "", 1, 1, 1, true)
            D.CharNoteTooltip:SetBackdropBorderColor(1, 1, 1, 1)
            D.CharNoteTooltip:Show()

            return nil
        end

        return P.hooks.SetItemRef(link, text, button, ...)
    end

    local function SetHyperlink(frame, link, ...)
      if link and link:match("^note") then return end

      return P.hooks[frame].SetHyperlink(frame, link, ...)
    end

    local function CreateNoteLink(name, text)
        local rating = D.db.realm.ratings[name]

        return noteLinkFmt:format(P:GetRatingColor(rating), name, text)
    end

    local function AddNoteForChat(message, name)
        if name and #name > 0 then
            local note, nameFound = N:GetNote(name)
            if note and #note > 0 then
                local messageFmt = "%s %s"
                return messageFmt:format(message, CreateNoteLink(nameFound, "note"))
            end
        end

        return message
    end

    local function AddMessage(frame, text, r, g, b, id, ...)
        if text and _G.type(text) == "string" and D.db.profile.noteLinksInChat == true then
            -- If no charnotes are present then insert one.
            if text:find("|Hnote") == nil then
                text = text:gsub("(|Hplayer:([^:]+).-|h.-|h)", AddNoteForChat)
            end
        end

        return P.hooks[frame].AddMessage(frame, text, r, g, b, id, ...)
    end

    local function HookChatFrames()
        for i = 1, _G.NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame" .. i]
            if chatFrame ~= _G.COMBATLOG then
                if not P:IsHooked(chatFrame, "AddMessage") then
                    P:RawHook(chatFrame, "AddMessage", AddMessage, true)
                end
            end
        end
    end

    local function UnhookChatFrames()
        for i = 1, _G.NUM_CHAT_WINDOWS do
            local chatFrame = _G["ChatFrame" .. i]
            if chatFrame ~= _G.COMBATLOG then
                P:Unhook(chatFrame, "AddMessage")
            end
        end
    end

    local function EnableNoteLinks()
        if D.db.profile.noteLinksInChat == false then
            return
        end

        -- Hook SetItemRef to create our own hyperlinks
        if not P:IsHooked(nil, "SetItemRef") then
    	    P:RawHook(nil, "SetItemRef", SetItemRef, true)
        end

        -- Hook SetHyperlink so we can redirect charnote links
        if not P:IsHooked(_G.ItemRefTooltip, "SetHyperlink") then
    	    P:RawHook(_G.ItemRefTooltip, "SetHyperlink", SetHyperlink, true)
        end

        -- Hook chat frames so we can edit the messages
        HookChatFrames()
    end

    local function DisableNoteLinks()
        P:Unhook(nil, "SetItemRef")
        P:Unhook(_G.ItemRefTooltip, "SetHyperlink")
        UnhookChatFrames()
    end

    local function FCF_SetTemporaryWindowType(chatFrame, chatType, chatTarget)
        if chatFrame and not P:IsHooked(chatFrame, "AddMessage") then
            P:RawHook(chatFrame, "AddMessage", AddMessage, true)
        end
    end

    local function FCF_Close(frame, fallback)
        if frame and P:IsHooked(frame, "AddMessage") then
            P:Unhook(frame, "AddMessage", AddMessage)
        end
    end

    function chatTooltip:CanLoad()
        return D.CharNoteTooltip
    end

    function chatTooltip:OnLoad()
        self:Enable()

        EnableNoteLinks()

        P:SecureHook("FCF_SetTemporaryWindowType", FCF_SetTemporaryWindowType)
	    P:SecureHook("FCF_Close", FCF_Close)

        P:RegisterMessage('PN_EVENT_ENABLENOTELINKS', function(_, name)
            EnableNoteLinks()
        end)

        P:RegisterMessage('PN_EVENT_DISABLENOTELINKS', function(_, name)
            DisableNoteLinks()
        end)
    end
end
