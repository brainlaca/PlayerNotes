local P, D, L = unpack(select(2, ...)); -- P: addon, D: data, L: locale

local NotesDb = {}
D.NotesDb = NotesDb

-- Use local versions of standard LUA items for performance
local _G = _G
local string = _G.string
local select = _G.select

local LibAlts = LibStub("LibAlts-1.0")

NotesDb.playerRealm = nil
NotesDb.playerRealmAbbr = nil

local realmNames = {
    ["Aeriepeak"] = "AeriePeak",
    ["Altarofstorms"] = "AltarofStorms",
    ["Alteracmountains"] = "AlteracMountains",
    ["Aman'thul"] = "Aman'Thul",
    ["Argentdawn"] = "ArgentDawn",
    ["Azjolnerub"] = "AzjolNerub",
    ["Blackdragonflight"] = "BlackDragonflight",
    ["Blackwaterraiders"] = "BlackwaterRaiders",
    ["Blackwinglair"] = "BlackwingLair",
    ["Blade'sedge"] = "Blade'sEdge",
    ["Bleedinghollow"] = "BleedingHollow",
    ["Bloodfurnace"] = "BloodFurnace",
    ["Bloodsailbuccaneers"] = "BloodsailBuccaneers",
    ["Boreantundra"] = "BoreanTundra",
    ["Burningblade"] = "BurningBlade",
    ["Burninglegion"] = "BurningLegion",
    ["Cenarioncircle"] = "CenarionCircle",
    ["Darkiron"] = "DarkIron",
    ["Darkmoonfaire"] = "DarkmoonFaire",
    ["Dath'remar"] = "Dath'Remar",
    ["Demonsoul"] = "DemonSoul",
    ["Drak'tharon"] = "Drak'Tharon",
    ["Earthenring"] = "EarthenRing",
    ["Echoisles"] = "EchoIsles",
    ["Eldre'thalas"] = "Eldre'Thalas",
    ["Emeralddream"] = "EmeraldDream",
    ["Grizzlyhills"] = "GrizzlyHills",
    ["Jubei'thos"] = "Jubei'Thos",
    ["Kel'thuzad"] = "Kel'Thuzad",
    ["Khazmodan"] = "KhazModan",
    ["Kirintor"] = "KirinTor",
    ["Kultiras"] = "KulTiras",
    ["Laughingskull"] = "LaughingSkull",
    ["Lightning'sblade"] = "Lightning'sBlade",
    ["Mal'ganis"] = "Mal'Ganis",
    ["Mok'nathal"] = "Mok'Nathal",
    ["Moonguard"] = "MoonGuard",
    ["Quel'thalas"] = "Quel'Thalas",
    ["Scarletcrusade"] = "ScarletCrusade",
    ["Shadowcouncil"] = "ShadowCouncil",
    ["Shatteredhalls"] = "ShatteredHalls",
    ["Shatteredhand"] = "ShatteredHand",
    ["Silverhand"] = "SilverHand",
    ["Sistersofelune"] = "SistersofElune",
    ["Steamwheedlecartel"] = "SteamwheedleCartel",
    ["Theforgottencoast"] = "TheForgottenCoast",
    ["Thescryers"] = "TheScryers",
    ["Theunderbog"] = "TheUnderbog",
    ["Theventureco"] = "TheVentureCo",
    ["Thoriumbrotherhood"] = "ThoriumBrotherhood",
    ["Tolbarad"] = "TolBarad",
    ["Twistingnether"] = "TwistingNether",
    ["Wyrmrestaccord"] = "WyrmrestAccord",
}

local MULTIBYTE_FIRST_CHAR = "^([\192-\255]?%a?[\128-\191]*)"

--- Returns a name formatted in title case (i.e., first character upper case, the rest lower).
-- @name :TitleCase
-- @param name The name to be converted.
-- @return string The converted name.
function NotesDb:TitleCase(name)
    if not name then return "" end
    if #name == 0 then return "" end
    name = name:lower()
    return name:gsub(MULTIBYTE_FIRST_CHAR, string.upper, 1)
end

function NotesDb:GetProperRealmName(realm)
    if not realm then return end
    realm = self:TitleCase(realm:gsub("[ -]", ""))
    return realmNames[realm] or realm
end

function NotesDb:FormatNameWithRealm(name, realm, relative)
    if not name then return end
    name = self:TitleCase(name)
    realm = self:GetProperRealmName(realm)
    if relative and realm and realm == self.playerRealmAbbr then
        return name
    elseif realm and #realm > 0 then
        return name .. "-" .. realm
    else
        return name
    end
end

function NotesDb:FormatRealmName(realm)
    -- Spaces are removed.
    -- Dashes are removed. (e.g., Azjol-Nerub)
    -- Apostrophe / single quotes are not removed.
    if not realm then return end
    return realm:gsub("[ -]", "")
end

function NotesDb:HasRealm(name)
    if not name then return end
    local matches = name:gmatch("[-]")
    return matches and matches()
end

function NotesDb:ParseName(name)
    if not name then return end
    local matches = name:gmatch("([^%-]+)")
    if matches then
        local nameOnly = matches()
        local realm = matches()
        return nameOnly, realm
    end
    return nil
end

function NotesDb:FormatUnitName(name, relative)
    local nameOnly, realm = self:ParseName(name)
    return self:FormatNameWithRealm(nameOnly, realm, relative)
end

function NotesDb:FormatUnitList(sep, relative, ...)
    local str = ""
    local first = true
    local v
    for i = 1, select('#', ...), 1 do
        v = select(i, ...)
        if v and #v > 0 then
            if not first then str = str .. sep end
            str = str .. self:FormatUnitName(v, relative)
            if first then first = false end
        end
    end
    return str
end

function NotesDb:GetAlternateName(name)
    local nameOnly, realm = self:ParseName(name)
    return realm and self:TitleCase(nameOnly) or
            self:FormatNameWithRealm(self:TitleCase(nameOnly), self.playerRealmAbbr)
end

function NotesDb:GetNote(name)
    if D.db.realm.notes and name then
        local nameFound = self:FormatUnitName(name)
        local note = D.db.realm.notes[nameFound]
        if not note then
            local altName = self:GetAlternateName(name)
            note = D.db.realm.notes[altName]
            if note then nameFound = altName end
        end
        return note, nameFound
    end
end

function NotesDb:GetRating(name)
    if D.db.realm.ratings and name then
        local nameFound = self:FormatUnitName(name)
        local rating = D.db.realm.ratings[nameFound]
        if not rating then
            local altName = self:GetAlternateName(name)
            rating = D.db.realm.ratings[altName]
            if rating then nameFound = altName end
        end
        return rating, nameFound
    end
end

function NotesDb:SetNote(name, note)
    if D.db.realm.notes and name then
        name = self:FormatUnitName(name)
        D.db.realm.notes[name] = note

        if self.PlayerNotes and self.PlayerNotes.UpdateNote then
            self.PlayerNotes:UpdateNote(name, note)
        end
    end
end

function NotesDb:SetRating(name, rating)
    if D.db.realm.ratings and name and rating >= -1 and rating <= 1 then
        name = self:FormatUnitName(name)
        D.db.realm.ratings[name] = rating

        if self.PlayerNotes and self.PlayerNotes.UpdateRating then
            self.PlayerNotes:UpdateRating(name, rating)
        end
    end
end

function NotesDb:SetNoteAndRating(name, note, rating)
    NotesDb:SetNote(name, note)
    NotesDb:SetRating(name, rating)
end

function NotesDb:DeleteNote(name)
    if D.db.realm.notes and name then
        name = self:FormatUnitName(name)

        -- Delete both the note and the rating.
        D.db.realm.notes[name] = nil
        D.db.realm.ratings[name] = nil

        if self.PlayerNotes and self.PlayerNotes.RemoveNote then
            self.PlayerNotes:RemoveNote(name)
        end
    end
end

function NotesDb:DeleteRating(name)
    if D.db.realm.ratings and name then
        name = self:FormatUnitName(name)
        D.db.realm.ratings[name] = nil

        if self.PlayerNotes and self.PlayerNotes.RemoveRating then
            self.PlayerNotes:RemoveRating(name)
        end
    end
end

function NotesDb:GetInfoForNameOrMain(name)
    name = self:FormatUnitName(name)
    local note, nameFound = self:GetNote(name)
    local rating = self:GetRating(nameFound)
    local main = nil
    -- If there is no note then check if this character has a main
    -- and if so if there is a note for that character.
    if not note then
        if D.db.profile.useLibAlts == true and LibAlts and LibAlts.GetMain then
            main = LibAlts:GetMain(name)
            if main and #main > 0 then
                main = self:FormatUnitName(main)
                note, nameFound = self:GetNote(main)
                rating = self:GetRating(nameFound)
            else
                main = LibAlts:GetMain(self:GetAlternateName(name))
                if main and #main > 0 then
                    main = self:FormatUnitName(main)
                    note, nameFound = self:GetNote(main)
                    rating = self:GetRating(nameFound)
                end
            end
        end
    end

    return note, rating, main, nameFound
end

function NotesDb:OnInitialize(PlayerNotes)
    self.PlayerNotes = PlayerNotes
    self.playerRealm = _G.GetRealmName()
    self.playerRealmAbbr = self:FormatRealmName(self.playerRealm)
end

function NotesDb:OnEnable()
end
