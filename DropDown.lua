local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local _G = _G
local N = D.NotesDb

do
    local dropdown = P:NewModule("DropDown")

    local validTypes = {
        ARENAENEMY = true,
        BN_FRIEND = true,
        CHAT_ROSTER = true,
        COMMUNITIES_GUILD_MEMBER = true,
        COMMUNITIES_WOW_MEMBER = true,
        FOCUS = true,
        FRIEND = true,
        GUILD = true,
        GUILD_OFFLINE = true,
        PARTY = true,
        PLAYER = true,
        RAID = true,
        RAID_PLAYER = true,
        TARGET = true,
        SELF = false,
        WORLD_STATE_SCORE = true
    }

    local function IsValidDropDown(bdropdown)
        return bdropdown == LFGListFrameDropDown or (type(bdropdown.which) == "string" and validTypes[bdropdown.which])
    end

    -- get name and realm from dropdown or nil if it's not applicable
    local function GetNameRealmForDropDown(bdropdown)
        local unit = bdropdown.unit
        local bnetIDAccount = bdropdown.bnetIDAccount
        local menuList = bdropdown.menuList
        local quickJoinMember = bdropdown.quickJoinMember
        local quickJoinButton = bdropdown.quickJoinButton
        local clubMemberInfo = bdropdown.clubMemberInfo
        local tempName, tempRealm = bdropdown.name, bdropdown.server
        local name, realm, level
        -- unit
        if not name and UnitExists(unit) then
            if UnitIsPlayer(unit) then
                name, realm = P:GetNameAndRealm(unit)
                level = UnitLevel(unit)
            end
            -- if it's not a player it's pointless to check further
            return name, realm, level
        end
        -- bnet friend
        if not name and bnetIDAccount then
            local fullName, _, charLevel = P:GetNameRealmForBNetFriend(bnetIDAccount)
            if fullName then
                name, realm = P:GetNameAndRealm(fullName)
                level = charLevel
            end
            -- if it's a bnet friend we assume if eligible the name and realm is set, otherwise we assume it's not eligible for a url
            return name, realm, level
        end
        -- lfd
        if not name and menuList then
            for i = 1, #menuList do
                local whisperButton = menuList[i]
                if whisperButton and (whisperButton.text == _G.WHISPER_LEADER or whisperButton.text == _G.WHISPER) then
                    name, realm = P:GetNameAndRealm(whisperButton.arg1)
                    break
                end
            end
        end
        -- quick join
        if not name and (quickJoinMember or quickJoinButton) then
            local memberInfo = quickJoinMember or quickJoinButton.Members[1]
            if memberInfo.playerLink then
                name, realm, level = P:GetNameRealmFromPlayerLink(memberInfo.playerLink)
            end
        end
        -- dropdown by name and realm
        if not name and tempName then
            name, realm = P:GetNameAndRealm(tempName, tempRealm)
            if clubMemberInfo and clubMemberInfo.level and (clubMemberInfo.clubType == Enum.ClubType.Guild or clubMemberInfo.clubType == Enum.ClubType.Character) then
                level = clubMemberInfo.level
            end
        end
        -- if we don't got both we return nothing
        if not name or not realm then
            return
        end
        return name, realm, level
    end

    -- tracks the currently active dropdown name and realm for lookup
    local selectedName, selectedRealm, selectedLevel

    ---@type CustomDropDownOption[]
    local unitOptions

    ---@param options CustomDropDownOption[]
    local function OnToggle(bdropdown, event, options, level, data)
        if event == "OnShow" then
            if not IsValidDropDown(bdropdown) then
                return
            end
            selectedName, selectedRealm, selectedLevel = GetNameRealmForDropDown(bdropdown)
            if not selectedName then
                return
            end
            if not options[1] then
                for i = 1, #unitOptions do
                    options[i] = unitOptions[i]
                end
                return true
            end
        elseif event == "OnHide" then
            if options[1] then
                for i = #options, 1, -1 do
                    options[i] = nil
                end
                return true
            end
        end
    end

    ---@type LibDropDownExtension
    local LibDropDownExtension = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)

    function dropdown:CanLoad()
        return LibDropDownExtension
    end

    function dropdown:OnLoad()
        self:Enable()
        unitOptions = {
            LibDropDownExtension.Option.Separator,
            {
                text = L["Player Notes"],
                hasArrow = false,
                dist = 0,
                isTitle = true,
                isUninteractable = true,
                notCheckable = true
            },
            {
                text = L["Edit Note"],
                func = function()
                    P:EditNoteHandler(N:FormatNameWithRealm(selectedName, selectedRealm))
                end
            }
        }
        LibDropDownExtension:RegisterEvent("OnShow OnHide", OnToggle, 1, dropdown)
    end
end
