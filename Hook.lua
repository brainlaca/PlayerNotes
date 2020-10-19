local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local N = D.NotesDb

local _G = _G
local uiHooks = D.uiHooks

do
    -- GameTooltip
    uiHooks[#uiHooks + 1] = function()
        local function OnTooltipSetUnit(self)
            if D.db.profile.showNotesInTooltips == false then
                return
            end
            local _, unit = self:GetUnit()
            P:showTooltip(GameTooltip, unit, 1)
        end

        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
        return 1
    end

    -- FriendsFrame
    uiHooks[#uiHooks + 1] = function()
        local function OnEnter(self)
            if D.db.profile.showNotesInTooltips == false then
                return
            end

            local fullName, faction, level

            if self.buttonType == FRIENDS_BUTTON_TYPE_BNET then
                local bnetIDAccount = C_FriendList.GetFriendInfoByIndex(self.id)
                if bnetIDAccount then
                    fullName, faction, level = P:GetNameRealmForBNetFriend(bnetIDAccount)
                end
            elseif self.buttonType == FRIENDS_BUTTON_TYPE_WOW then
                fullName, level = GetFriendInfo(self.id)
                faction = PLAYER_FACTION
            end

            if fullName then
                -- GameTooltip:SetOwner(FriendsTooltip, "ANCHOR_BOTTOMRIGHT", -FriendsTooltip:GetWidth(), -4)
                P:showTooltip(GameTooltip, fullName)
            else
                GameTooltip:Hide()
            end
        end

        local function FriendTooltip_Hide()
            if D.db.profile.showNotesInTooltips == false then
                return
            end
            GameTooltip:Hide()
        end

        local buttons = FriendsListFrameScrollFrame.buttons
        for i = 1, #buttons do
            local button = buttons[i]
            button:HookScript("OnEnter", OnEnter)
        end

        --hooksecurefunc("FriendsFrameTooltip_Show", OnEnter)
        hooksecurefunc(FriendsTooltip, "Hide", FriendTooltip_Hide)

        return 1
    end

    -- Guild_UI
    uiHooks[#uiHooks + 1] = function()
        if _G.GuildFrame then
            local function OnEnter(self)
                if D.db.profile.showNotesInTooltips == false then
                    return
                end

                if self.guildIndex then
                    local fullName, _, _, level = GetGuildRosterInfo(self.guildIndex)
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                    P:showTooltip(GameTooltip, fullName, 0, self)
                end
            end

            local function OnLeave(self)
                if self.guildIndex then
                    GameTooltip:Hide()
                end
            end

            for i = 1, 16 do
                local b = _G["GuildRosterContainerButton" .. i]
                b:HookScript("OnEnter", OnEnter)
                b:HookScript("OnLeave", OnLeave)
            end

            return 1
        end
    end

    -- Blizzard_Communities
    uiHooks[#uiHooks + 1] = function()
        if _G.CommunitiesFrame then
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

            local hooked = {}
            local completed

            local function HookButtons()
                if completed then
                    return
                end
                local buttons = _G.CommunitiesFrame.MemberList.ListScrollFrame.buttons
                if not buttons then
                    return
                end
                for _, b in pairs(buttons) do
                    if not hooked[b] then
                        hooked[b] = true
                        b:HookScript("OnEnter", OnEnter)
                        b:HookScript("OnLeave", OnLeave)
                    end
                end
                if next(hooked) then
                    completed = true -- one pass seems to create all the buttons
                end
            end

            HookButtons()
            hooksecurefunc(_G.CommunitiesFrame.MemberList, "RefreshLayout", HookButtons)

            return 1
        end
    end

    -- LFG
    uiHooks[#uiHooks + 1] = function()
        if _G.LFGListApplicationViewerScrollFrameButton1 then
            local hooked = {}
            local OnEnter, OnLeave

            -- application queue
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

            -- search results
            local function SetSearchEntryTooltip(tooltip, resultID, autoAcceptOption)
                if D.db.profile.showNotesInTooltips == false then
                    return
                end
                local results = C_LFGList.GetSearchResultInfo(resultID)
                if not results then
                    return
                end
                local activityID = results.activityID
                local leaderName = results.leaderName
                if leaderName then
                    P:showTooltip(GameTooltip, leaderName)
                end
            end

            hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetSearchEntryTooltip)

            -- execute delayed hooks
            for i = 1, 14 do
                local b = _G["LFGListApplicationViewerScrollFrameButton" .. i]
                b:HookScript("OnEnter", OnEnter)
                b:HookScript("OnLeave", OnLeave)
            end

            -- UnempoweredCover blocking removal
            do
                local f = LFGListFrame.ApplicationViewer.UnempoweredCover
                f:EnableMouse(false)
                f:EnableMouseWheel(false)
                f:SetToplevel(false)
            end

            return 1
        end
    end

    -- DropDownMenu (Units and LFD)
    --    uiHooks[#uiHooks + 1] = function()
    --        local function OnShow(self)
    --            local dropdown = self.dropdown
    --            if not dropdown then
    --                return
    --            end
    --            if dropdown.Button == _G.LFGListFrameDropDownButton then -- LFD
    --                print("clicked: " .. dropdown.menuList[2].arg1);
    --                -- P:updateLFGDropDowns()
    --            end
    --        end
    --
    --        local function OnHide()
    --        end
    --
    --        DropDownList1:HookScript("OnShow", OnShow)
    --        DropDownList1:HookScript("OnHide", OnHide)
    --
    --        return 1
    --    end
end

function P:showTooltip(tooltip, toonName, ...)
    local separatorBelow = ...
    local name, realm, unit = P:GetNameAndRealm(toonName)
    -- if no realm then just return, might be happening before PLAYER_LOGIN fire
    if not realm then return end

    local note, rating, main, nameFound = N:GetInfoForNameOrMain(name .. "-" .. realm)

    if note then
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
end
