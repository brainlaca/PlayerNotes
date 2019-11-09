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

function P:GetNameAndRealmForBNetFriend(bnetIDAccount)
    local index = BNGetFriendIndex(bnetIDAccount)
    if index then
        local numGameAccounts = BNGetNumFriendGameAccounts(index)
        for i = 1, numGameAccounts do
            local _, characterName, client, realmName, _, faction, _, _, _, _, level = BNGetFriendGameAccountInfo(index, i)
            if client == BNET_CLIENT_WOW then
                if realmName then
                    characterName = characterName .. "-" .. realmName:gsub("%s+", "")
                end
                return characterName, FACTION[faction], tonumber(level)
            end
        end
    end
end

function P:GetNameRealmForBNetFriend(bnetIDAccount)
    local index = BNGetFriendIndex(bnetIDAccount)
    if index then
        local numGameAccounts = BNGetNumFriendGameAccounts(index)
        for i = 1, numGameAccounts do
            local _, characterName, client, realmName, _, faction, _, _, _, _, level = BNGetFriendGameAccountInfo(index, i)
            if client == BNET_CLIENT_WOW then
                return characterName, realmName
            end
        end
    end
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
