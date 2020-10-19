local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale
local C = D.config

local _G = _G
local pairs = _G.pairs

function P:GetRatingColor(rating)
    local color = D.YELLOW
    if rating ~= nil and rating >= -1 and rating <= 1 then
        local ratingInfo = D.RATING_OPTIONS[rating]
        if ratingInfo and ratingInfo[2] then
            color = ratingInfo[2]
        end
    end
    return color
end

-- Patch 5.4 will change the formatting of names with realms appended.
-- Remove the spaces surrounding the dash between the name and realm.
function P:RemoveSpacesFromRealm()
    if not D.db.realm.removedSpacesFromRealm then
        -- Find notes to be updated.
        local check
        local noteCount = 0
        local invalidNotes = {}
        for name, note in pairs(D.db.realm.notes) do
            check = name:gmatch("[ ][-][ ]")
            if check and check() then
                noteCount = noteCount + 1
                invalidNotes[name] = note
            end
        end
        if D.db.profile.verbose then
            local fmt = "Found %d notes with realm names to update."
            self:Print(fmt:format(noteCount))
        end
        local ratingCount = 0
        local invalidRatings = {}
        for name, rating in pairs(D.db.realm.ratings) do
            check = name:gmatch("[ ][-][ ]")
            if check and check() then
                ratingCount = ratingCount + 1
                invalidRatings[name] = rating
            end
        end
        if D.db.profile.verbose then
            local fmt = "Found %d ratings with realm names to update."
            self:Print(fmt:format(ratingCount))
        end

        if noteCount > 0 then
            -- Backup the notes to be safe.
            D.db.realm.oldNotes = {}
            for name, note in pairs(D.db.realm.notes) do
                D.db.realm.oldNotes[name] = note
            end
            -- Update notes.
            for name, note in pairs(invalidNotes) do
                local newName = name:gsub("[ ][-][ ]", "-", 1)
                D.db.realm.notes[name] = nil
                D.db.realm.notes[newName] = note
            end
        end

        if ratingCount > 0 then
            -- Backup the ratings to be safe.
            D.db.realm.oldRatings = {}
            for name, rating in pairs(D.db.realm.ratings) do
                D.db.realm.oldRatings[name] = rating
            end
            -- Update ratings.
            for name, rating in pairs(invalidRatings) do
                local newName = name:gsub("[ ][-][ ]", "-", 1)
                D.db.realm.ratings[name] = nil
                D.db.realm.ratings[newName] = rating
            end
        end

        D.db.realm.removedSpacesFromRealm = true
    end
end

function P:Wrap(str, limit, indent, indent1, offset)
    indent = indent or ""
    indent1 = indent1 or indent
    limit = limit or 72
    offset = offset or 0
    local here = 1 - #indent1 - offset
    return indent1 .. str:gsub("(%s+)()(%S+)()",
        function(sp, st, word, fi)
            if fi - here > limit then
                here = st - #indent
                return "\n" .. indent .. word
            end
        end)
end

function P:IsMaxLevel(level, fallback)
    if level and type(level) == "number" then
        return level >= D.MAX_LEVEL
    end
    return fallback
end

function P:GetNameRealmForBNetFriend(bnetIDAccount, separateRealmName)
    local index = BNGetFriendIndex(bnetIDAccount)
    if not index then
        return
    end
    local collection = {}
    local collectionIndex = 0
    for i = 1, C_BattleNet.GetFriendNumGameAccounts(index), 1 do
        local accountInfo = C_BattleNet.GetFriendGameAccountInfo(index, i)
        local realmName = ""
        if accountInfo and accountInfo.clientProgram == BNET_CLIENT_WOW and (not accountInfo.wowProjectID or accountInfo.wowProjectID ~= WOW_PROJECT_CLASSIC) then
            if accountInfo.realmName then
                realmName = accountInfo.realmName:gsub("%s+", "")
            end
            collectionIndex = collectionIndex + 1
            collection[collectionIndex] = {accountInfo.characterName, realmName, D.FACTION_TO_ID[accountInfo.factionName], tonumber(accountInfo.characterLevel)}
        end
    end

    for i = 1, collectionIndex do
        local profile = collection[collectionIndex]
        local name, realmName, faction, level = profile[1], profile[2], profile[3], profile[4]
        if separateRealmName then
            return name, realmName, faction, level
        else
            return name .. "-" .. realmName, faction, level
        end
    end

    return
end

function P:GetNameAndRealm(arg1, arg2)
    local name, realm, unit
    if UnitExists(arg1) then
        unit = arg1
        if UnitIsPlayer(arg1) then
            name, realm = UnitName(arg1)
            realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
        end
    elseif type(arg1) == "string" and arg1 ~= "" then
        if arg1:find("-", nil, true) then
            name, realm = ("-"):split(arg1)
        else
            name = arg1 -- assume this is the name
        end
        if not realm or realm == "" then
            if type(arg2) == "string" and arg2 ~= "" then
                realm = arg2
            else
                realm = GetNormalizedRealmName() -- assume they are on our realm
            end
        end
    end
    return name, realm, unit
end

function P:dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. P:dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function ElvUIDelayChatMessage(msg)
    local E, L, V, P, G = unpack(ElvUI)
    local C

    if E then C = E:GetModule("Chat") end
    if not C then return end

    if C.Initialized then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    else
        local delay, checks, delayFrame, chat = 0, 0, CreateFrame('Frame')

        delayFrame:SetScript('OnUpdate', function(df, elapsed)
            delay = delay + elapsed
            if delay < 5 then return end

            if C.Initialized then
                DEFAULT_CHAT_FRAME:AddMessage(msg)
                df:SetScript('OnUpdate', nil)
            else
                delay, checks = 0, checks + 1
                if checks >= 5 then
                    df:SetScript('OnUpdate', nil)
                end
            end
        end)
    end
end

function P:ChatMessage(msg)
    if IsAddOnLoaded("ElvUI") then
        ElvUIDelayChatMessage(msg)
    else
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end
end
