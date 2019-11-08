local ADDON_NAME, AddonData = ...
local PlayerNotes = LibStub("AceAddon-3.0"):GetAddon(ADDON_NAME)

do
    local function GrabElement(frame, element, parentName)
        local FrameName = parentName or frame:GetDebugName()
        return frame[element] or FrameName and (_G[FrameName..element] or strfind(FrameName, element)) or nil
    end

    local function SkinElvUI(frame)
        local E, L, V, P, G = unpack(ElvUI)
        local S
        if E then S = E:GetModule("Skins") end

        if S then
            if frame.StripTextures then
                frame:StripTextures()
            end
            if frame.SetTemplate then
                frame:SetTemplate("Transparent")
            end

            -- buttons
            local buttons = {
                'savebutton',
                'removebutton',
                'searchbutton',
                'clearbutton',
                'deletebutton',
                'editbutton',
                'addbutton',
                'cancelbutton'
            }

            for k, v in pairs (buttons) do
                if frame[v] and frame[v].SetAlpha then
                    S:HandleButton(frame[v])
                end
            end

            -- dropdown
            local ratingdropdown = frame.ratingdropdown
            if ratingdropdown then
                S:HandleDropDownBox(ratingdropdown)
            end

            -- scrolltable
            if frame.scrollframe then
                local scrollframe = frame.scrollframe.frame
                scrollframe:StripTextures()
                scrollframe:CreateBackdrop('Default')
                scrollframe.backdrop:Point('TOPLEFT', -4, 0)
                scrollframe.backdrop:Point('BOTTOMRIGHT', 0, -1)

                local realScrollFrame = frame.scrollframe.scrollframe
                local scrollThrough = GrabElement(realScrollFrame, "ScrollTrough", scrollframe:GetDebugName())
                if scrollThrough then
                    scrollThrough.background:Hide();
                end
                local scrollThroughBorder = GrabElement(realScrollFrame, "ScrollTroughBorder", scrollframe:GetDebugName())
                if scrollThroughBorder then
                    scrollThroughBorder.background:Hide();
                end

                local scrollBar = GrabElement(realScrollFrame, "ScrollBar")
                if scrollBar then
                    S:HandleScrollBar(scrollBar)
                end
            end

            -- string editbox
            local stringbox = frame.searchterm or frame.nameinput
            if stringbox then
                S:HandleEditBox(stringbox)
                stringbox:SetHeight(18)

                if frame.nameinput then
                    stringbox:SetPoint("TOPLEFT", frame.namelabel, "TOPRIGHT", 15, 3)
                end
            end

            -- scolleditbox
            local scrolleditframe = frame.scrolleditframe
            if scrolleditframe then
                if scrolleditframe.StripTextures then
                    scrolleditframe:StripTextures()
                    scrolleditframe:CreateBackdrop('Default')
                    scrolleditframe.backdrop:Point('TOPLEFT', 0, 0)
                    scrolleditframe.backdrop:Point('BOTTOMRIGHT', 0, 0)
                end
                if scrolleditframe.editboxframe then
                    S:HandleEditBox(scrolleditframe.editboxframe)
                    scrolleditframe.editboxframe.backdrop:SetAllPoints(scrolleditframe)
                end
                if scrolleditframe.editboxframe and scrolleditframe.editboxframe.scrollArea then
                    scrolleditframe.editboxframe.scrollArea:SetPoint("TOPLEFT", scrolleditframe, "TOPLEFT", 6, -2)
                    scrolleditframe.editboxframe.scrollArea:SetPoint("BOTTOMRIGHT", scrolleditframe, "BOTTOMRIGHT", -6, 2)
                    local editScrollBar = GrabElement(scrolleditframe.editboxframe.scrollArea, "ScrollBar")
                    if editScrollBar then
                        S:HandleScrollBar(editScrollBar)
                    end
                end
            end

            -- close button
            local close = frame.closebutton
            if close and close.SetAlpha then
                S:HandleCloseButton(close)
                close:SetAlpha(1)
                close:SetPoint("TOPRIGHT", 2, 1)
            end

            -- align editbox rating text
            local frameName = frame.GetName and frame:GetName()
            if frameName == "PlayerNotesEditWindow" then
                frame.charname:SetPoint("BOTTOM", frame.headertext, "BOTTOM", 0, -34)
                ratingdropdown:SetPoint("TOPLEFT", frame.ratinglabel, "TOPRIGHT", 30, 5)
            end

        end
    end

    function PlayerNotes:SkinFrame(frame)
        if IsAddOnLoaded("ElvUI") then
            SkinElvUI(frame)
        end
    end
end
