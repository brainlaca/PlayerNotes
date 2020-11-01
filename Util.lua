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

function P:ExecuteWidgetHandler(object, handler, ...)
    if type(object) ~= "table" or type(object.GetScript) ~= "function" then
        return false
    end
    local func = object:GetScript(handler)
    if type(func) ~= "function" then
        return
    end
    if not pcall(func, object, ...) then
        return false
    end
    return true
end

function P:SetOwnerSafely(object, owner, anchor, offsetX, offsetY)
    if type(object) ~= "table" or type(object.GetOwner) ~= "function" then
        return
    end
    local currentOwner = object:GetOwner()
    if not currentOwner then
        object:SetOwner(owner, anchor, offsetX, offsetY)
        return true
    end
    offsetX, offsetY = offsetX or 0, offsetY or 0
    local currentAnchor, currentOffsetX, currentOffsetY = object:GetAnchorType()
    currentOffsetX, currentOffsetY = currentOffsetX or 0, currentOffsetY or 0
    if currentAnchor ~= anchor or (currentOffsetX ~= offsetX and abs(currentOffsetX - offsetX) > 0.01) or (currentOffsetY ~= offsetY and abs(currentOffsetY - offsetY) > 0.01) then
        object:SetOwner(owner, anchor, offsetX, offsetY)
        return true
    end
    return false, true
end

do
  ---@type Module<string, Module>
    local modules = {}
    local moduleIndex = 0

    ---@class Module
    -- private properties for internal use only
    ---@field private id string @Required and unique string to identify the module.
    ---@field private index number @Automatically assigned a number based on the creation order.
    ---@field private loaded boolean @Flag indicates if the module is loaded.
    ---@field private enabled boolean @Flag indicates if the module is enabled.
    ---@field private dependencies string[] @List over dependencies before we can Load the module.
    -- private functions that should never be called
    ---@field private SetLoaded function @Internal function should not be called manually.
    ---@field private Load function @Internal function should not be called manually.
    ---@field private SetEnabled function @Internal function should not be called manually.
    -- protected functions that can be called but should never be overridden
    ---@field protected IsLoaded function @Internal function, can be called but do not override.
    ---@field protected IsEnabled function @Internal function, can be called but do not override.
    ---@field protected Enable function @Internal function, can be called but do not override.
    ---@field protected Disable function @Internal function, can be called but do not override.
    ---@field protected SetDependencies function @Internal function, can be called but do not override.
    ---@field protected HasDependencies function @Internal function, can be called but do not override.
    ---@field protected GetDependencies function @Internal function, can be called but do not override. Returns a table using the same order as the dependencies table. Returns the modules or nil depending if they are available or not.
    -- public functions that can be overridden
    ---@field public CanLoad function @If it returns true the module will be loaded, otherwise postponed for later. Override to define your modules load criteria that have to be met before loading.
    ---@field public OnLoad function @Once the module loads this function is executed. Use this to setup further logic for your module. The args provided are the module references as described in the dependencies table.
    ---@field public OnEnable function @This function is executed when the module is set to enabled state. Use this to setup and prepare.
    ---@field public OnDisable function @This function is executed when the module is set to disabled state. Use this for cleanup purposes.

    ---@type Module
    local module = {}

    ---@return nil
    function module:SetLoaded(state)
        self.loaded = state
    end

    ---@return boolean
    function module:Load()
        if not self:CanLoad() then
            return false
        end
        self:SetLoaded(true)
        self:OnLoad(unpack(self:GetDependencies()))
        return true
    end

    ---@return nil
    function module:SetEnabled(state)
        self.enabled = state
    end

    ---@return boolean
    function module:IsLoaded()
        return self.loaded
    end

    ---@return boolean
    function module:IsEnabled()
        return self.enabled
    end

    ---@return boolean
    function module:Enable()
        if self:IsEnabled() then
            return false
        end
        self:SetEnabled(true)
        self:OnEnable()
        return true
    end

    ---@return boolean
    function module:Disable()
        if not self:IsEnabled() then
            return false
        end
        self:SetEnabled(false)
        self:OnDisable()
        return true
    end

    ---@return nil
    function module:SetDependencies(dependencies)
        self.dependencies = dependencies
    end

    ---@return boolean
    function module:HasDependencies()
        if type(self.dependencies) == "string" then
            local m = modules[self.dependencies]
            return m and m:IsLoaded()
        end
        if type(self.dependencies) == "table" then
            for _, id in ipairs(self.dependencies) do
                local m = modules[id]
                if not m or not m:IsLoaded() then
                    return false
                end
            end
        end
        return true
    end

    ---@return Module[]
    function module:GetDependencies()
        local temp = {}
        local index = 0
        if type(self.dependencies) == "string" then
            index = index + 1
            temp[index] = modules[self.dependencies]
        end
        if type(self.dependencies) == "table" then
            for _, id in ipairs(self.dependencies) do
                index = index + 1
                temp[index] = modules[id]
            end
        end
        return temp
    end

    ---@return boolean
    function module:CanLoad()
        return not self:IsLoaded()
    end

    ---@vararg Module
    ---@return nil
    function module:OnLoad(...)
        self:Enable()
    end

    ---@return nil
    function module:OnEnable()
    end

    ---@return nil
    function module:OnDisable()
    end

    ---@param id string @Unique module ID reference.
    ---@param data Module @Optional table with properties to copy into the newly created module.
    function P:NewModule(id, data)
        assert(type(id) == "string", "Raider.IO Module expects NewModule(id[, data]) where id is a string, data is optional table.")
        assert(not modules[id], "Raider.IO Module expects NewModule(id[, data]) where id is a string, that is unique and not already taken.")
        ---@type Module
        local m = {}
        for k, v in pairs(module) do
            m[k] = v
        end
        moduleIndex = moduleIndex + 1
        m.index = moduleIndex
        m.id = id
        m:SetLoaded(false)
        m:SetEnabled(false)
        m:SetDependencies()
        if type(data) == "table" then
            for k, v in pairs(data) do
                m[k] = v
            end
        end
        modules[id] = m
        return m
    end

    ---@param a Module
    ---@param b Module
    local function SortModules(a, b)
        return a.index < b.index
    end

    ---@return Module[]
    function P:GetModules()
        local ordered = {}
        local index = 0
        for _, module in pairs(modules) do
            index = index + 1
            ordered[index] = module
        end
        table.sort(ordered, SortModules)
        return ordered
    end

    ---@param id string @Unique module ID reference.
    ---@param silent boolean @Ommit to throw if module doesn't exists.
    function P:GetModule(id, silent)
        assert(type(id) == "string", "Raider.IO Module expects GetModule(id) where id is a string.")
        for _, module in pairs(modules) do
            if module.id == id then
                return module
            end
        end
        assert(silent, "Raider.IO Module expects GetModule(id) where id is a string, and the module must exists, or the silent param must be set to avoid this throw.")
    end

end
