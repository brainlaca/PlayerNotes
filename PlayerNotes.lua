local Addon, ns = ...

local _G = _G
local LibStub = _G.LibStub
local PlayerNotes = LibStub("AceAddon-3.0"):NewAddon(Addon, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0")
local D = {}
local L = LibStub("AceLocale-3.0"):GetLocale(Addon, true)

-- Extra data
D.noteLDB = nil
D.notesData = {}
D.config = nil
D.uiHooks = {}
D.options = {}

-- Colors
D.GREEN = "|cff00ff00"
D.YELLOW = "|cffffff00"
D.RED = "|cffff0000"
D.BLUE = "|cff0198e1"
D.ORANGE = "|cffff9933"
D.WHITE = "|cffffffff"
D.RED_COLOR = { ["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1 }
D.YELLOW_COLOR = { ["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 1 }
D.GREEN_COLOR = { ["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1 }

-- Ratings
D.RATING_OPTIONS = {
    [-1] = { "Negative", D.RED, D.RED_COLOR, "Interface\\RAIDFRAME\\ReadyCheck-NotReady.blp" },
    [0] = { "Neutral", D.YELLOW, D.YELLOW_COLOR, "" },
    [1] = { "Positive", D.GREEN, D.GREEN_COLOR, "Interface\\RAIDFRAME\\ReadyCheck-Ready.blp" },
}

-- String formats
D.chatNoteFormat = "%s%s: " .. D.WHITE .. "%s" .. "|r"
D.chatNoteWithMainFormat = "%s%s (%s): " .. D.WHITE .. "%s" .. "|r"
D.tooltipNoteFormat = "%s" .. L["Note: "] .. D.WHITE .. "%s" .. "|r"
D.tooltipNoteWithMainFormat = "%s" .. L["Note"] .. " (%s): " .. D.WHITE .. "%s" .. "|r"

D.defaults = {
    profile = {
        minimap = {
            hide = true,
        },
        verbose = true,
        debug = false,
        mouseoverHighlighting = true,
        showNotesOnWho = true,
        showNotesOnLogon = false,
        showNotesInTooltips = true,
        noteLinksInChat = false,
        useLibAlts = true,
        wrapTooltip = true,
        wrapTooltipLength = 50,
        notesForRaidMembers = false,
        notesForPartyMembers = false,
        lock_main_window = false,
        remember_main_pos = true,
        notes_window_x = 0,
        notes_window_y = 0,
        remember_tooltip_pos = true,
        lock_tooltip = false,
        note_tooltip_x = nil,
        note_tooltip_y = nil,
        exportUseName = true,
        exportUseNote = true,
        exportUseRating = true,
        exportEscape = true,
        multilineNotes = false,
        menusToModify = {
            ["PLAYER"] = true,
            ["PARTY"] = true,
            ["FRIEND"] = true,
            ["FRIEND_OFFLINE"] = true,
            ["BN_FRIEND"] = true,
            ["RAID_PLAYER"] = true,
            ["CHAT_ROSTER"] = true,
            ["COMMUNITIES_GUILD_MEMBER"] = true
        },
    },
    realm = {
        notes = {},
        ratings = {}
    }
}

ns[1] = PlayerNotes
ns[2] = D
ns[3] = L
