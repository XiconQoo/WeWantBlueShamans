local addonName,addonTable = ...

local strfind, format, gsub, strmatch, strsub = string.find, string.format, string.gsub, string.match, string.sub
local pairs, type = pairs, type

------------------------------------------------------------------------

local addonFuncs = {}

local blizzHexColors = {}
for class, color in pairs(CUSTOM_CLASS_COLORS) do
    blizzHexColors[color.colorStr] = class
end


do
    local GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, UnitCanCooperate = GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, UnitCanCooperate
    local UnitClass, UnitRace, UnitLevel, UnitEffectiveLevel, UnitName = UnitClass, UnitRace, UnitLevel, UnitEffectiveLevel, UnitName
    local GetNumSubgroupMembers = GetNumSubgroupMembers
    local UnitIsPlayer = UnitIsPlayer
    local select = select

    ------------------------------------------------------------------------
    -- Blizzard_GuildUI
    addonFuncs["Blizzard_GuildUI"] = function()
        -- Blizzard_GuildRoster.lua
        hooksecurefunc("GuildRosterButton_SetStringText", function(buttonString, text, isOnline, class)
            local color = isOnline and class and CUSTOM_CLASS_COLORS[class]
            if color then
                buttonString:SetTextColor(color.r, color.g, color.b)
            end
        end)
    end

    ------------------------------------------------------------------------
    -- Blizzard_Communities
    addonFuncs["Blizzard_Communities"] = function()
        -- CommunitiesMemberList.lua
        CommunitiesFrame.Chat.FormatMessage = function(self, clubId, streamId, message)
            local name = message.author.name or " ";
            local displayName = name;
            if message.author.timerunningSeasonID then
                displayName = TimerunningUtil.AddSmallIcon(name);
            end
            local link;
            if message.author.clubType == Enum.ClubType.BattleNet then
                link = GetBNPlayerCommunityLink(name, displayName, message.author.bnetAccountId, clubId, streamId, message.messageId.epoch, message.messageId.position);
            elseif message.author.clubType == Enum.ClubType.Character or message.author.clubType == Enum.ClubType.Guild then
                local classInfo = message.author.classID and C_CreatureInfo.GetClassInfo(message.author.classID);
                if classInfo and classInfo.classFile then
                    local color = CUSTOM_CLASS_COLORS[classInfo.classFile];
                    link = GetPlayerCommunityLink(name, color:WrapTextInColorCode(displayName), clubId, streamId, message.messageId.epoch, message.messageId.position);
                else
                    link = GetPlayerCommunityLink(name, displayName, clubId, streamId, message.messageId.epoch, message.messageId.position);
                end
            end

            local content;
            if message.destroyed then
                if message.destroyer and message.destroyer.name then
                    content = GRAY_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CHAT_MESSAGE_DESTROYED_BY:format(message.destroyer.name));
                else
                    content = GRAY_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CHAT_MESSAGE_DESTROYED);
                end
            elseif message.edited then
                content = COMMUNITIES_CHAT_MESSAGE_EDITED_FMT:format(message.content, GRAY_FONT_COLOR:WrapTextInColorCode(COMMUNITIES_CHAT_MESSAGE_EDITED));
            else
                content = message.content;
            end

            local format = GetChatTimestampFormat();
            if format then
                return BetterDate(format, message.messageId.epoch / 1000000)..COMMUNITIES_CHAT_MESSAGE_FORMAT:format(link or name, content);
            else
                return COMMUNITIES_CHAT_MESSAGE_FORMAT:format(link or name, content);
            end
        end

        hooksecurefunc(CommunitiesMemberListEntryMixin, "UpdatePresence", function(self)
            local memberInfo = self:GetMemberInfo()
            if memberInfo then
                if memberInfo.classID then
                    local classInfo = C_CreatureInfo.GetClassInfo(memberInfo.classID)
                    local color = classInfo and CUSTOM_CLASS_COLORS[classInfo.classFile]
                    if color then
                        if memberInfo.presence ~= Enum.ClubMemberPresence.Offline then
                            self.NameFrame.Name:SetTextColor(color.r, color.g, color.b);
                        end
                        if CommunitiesFrame:GetDisplayMode() == COMMUNITIES_FRAME_DISPLAY_MODES.CHAT then
                            self.NameFrame.Name:SetText(memberInfo.level .. " " .. memberInfo.name);
                        end
                    end
                end
            end
        end)

        hooksecurefunc(CommunitiesMemberListEntryMixin, "OnEnter", function(self)
            local memberInfo = self:GetMemberInfo()
            if memberInfo and GameTooltip:IsShown() then
                --DevTools_Dump(memberInfo)
                if memberInfo.profession1ID or memberInfo.profession2ID then
                    GameTooltip:AddLine(" ")
                    if memberInfo.profession1ID then
                        GameTooltip:AddLine(memberInfo.profession1Name .. " " .. memberInfo.profession1Rank)
                    end
                    if memberInfo.profession2ID then
                        GameTooltip:AddLine(memberInfo.profession2Name .. " " .. memberInfo.profession2Rank)
                    end
                    GameTooltip:Show()
                end
            end
        end)
    end

    ------------------------------------------------------------------------
    -- Blizzard_GroupFinder_VanillaStyle
    addonFuncs["Blizzard_GroupFinder_VanillaStyle"] = function()

        hooksecurefunc("LFGBrowseSearchEntryTooltip_UpdateAndShow", function(self, resultID)

            local leaderInfo = C_LFGList.GetSearchResultLeaderInfo(resultID);

            if (leaderInfo and leaderInfo.name) then
                local classColor = CUSTOM_CLASS_COLORS[leaderInfo.classFilename];
                if classColor then
                    self.Leader.Name:SetTextColor(classColor.r, classColor.g, classColor.b)
                end
            end

            for frame in self.memberPool:EnumerateActive() do
                for i=1, 10 do
                    local memberInfo = C_LFGList.GetSearchResultPlayerInfo(resultID, i);
                    if (memberInfo and memberInfo.name and not memberInfo.isLeader and memberInfo.name == frame.Name:GetText()) then
                        classColor = CUSTOM_CLASS_COLORS[memberInfo.classFilename];
                        if classColor then
                            frame.Name:SetTextColor(classColor.r, classColor.g, classColor.b)
                        end
                    end
                end
            end
        end)

        hooksecurefunc("LFGBrowseSearchEntry_Update", function(self)
            local classColor
            local searchResultInfo = C_LFGList.GetSearchResultInfo(self.resultID);
            local leaderInfo = C_LFGList.GetSearchResultLeaderInfo(self.resultID);
            if (leaderInfo and leaderInfo.classFilename) then
                classColor = CUSTOM_CLASS_COLORS[leaderInfo.classFilename];
            end
            local matchesFilters = true;
            if( #LFGBrowseFrame.ActivityDropDown.selectedValues > 0) then
                matchesFilters = false;
                for i=1, #searchResultInfo.activityIDs do
                    if (LFGBrowseActivityDropDown_ValueIsSelected(LFGBrowseFrame.ActivityDropDown, searchResultInfo.activityIDs[i])) then
                        matchesFilters = true;
                        break;
                    end
                end
            end
            if ( searchResultInfo.isDelisted or not matchesFilters) then
                classColor = LFGBROWSE_DELISTED_FONT_COLOR;
            end
            if classColor then
                self.Name:SetTextColor(classColor.r, classColor.g, classColor.b);
            end
        end)
    end

    ------------------------------------------------------------------------
    -- Blizzard_Menu
    -- UnitPopupShared.lua
    hooksecurefunc(UnitPopupManager, 'OpenMenu', function(self, which, contextData)
        if UnitIsPlayer(contextData.unit) then
            local coloredName, class = UnitClass(contextData.unit)
            if class then
                coloredName = CUSTOM_CLASS_COLORS:ColorTextByClass(contextData.name, class)

                local children = Menu.GetManager():GetOpenMenu():GetLayoutChildren()
                if #children >= 1 then
                    local title = children[1]
                    if title and title:IsShown() and title:IsObjectType("Frame") then
                        for i=1, select("#", title:GetRegions()) do
                            local region = select(i, title:GetRegions())
                            if region:IsObjectType("FontString") then
                                region:SetText(coloredName)
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    ------------------------------------------------------------------------
    -- Blizzard_InspectUI/InspectPaperDollFrame.lua

    addonFuncs["Blizzard_InspectUI"] = function()
        hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
            local unit = InspectFrame.unit
            if not unit then
                return
            end

            local className, class = UnitClass(unit)
            local race = UnitRace(unit)
            local color = class and CUSTOM_CLASS_COLORS[class]
            if not color then
                return
            end

            local level, effectiveLevel = UnitLevel(unit), UnitEffectiveLevel(unit)
            if level == -1 or effectiveLevel == -1 then
                level = "??"
            elseif ( effectiveLevel ~= level ) then
                level = EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level)
            end
            InspectLevelText:SetFormattedText(PLAYER_LEVEL, level, race, color:WrapTextInColorCode(className))
        end)
    end


    ------------------------------------------------------------------------
    -- Blizzard_RaidUI/Blizzard_RaidUI.lua

    addonFuncs["Blizzard_RaidUI"] = function()
        local _G = _G
        local min = math.min
        local MAX_RAID_MEMBERS, MEMBERS_PER_RAID_GROUP = MAX_RAID_MEMBERS, MEMBERS_PER_RAID_GROUP

        hooksecurefunc("RaidGroupFrame_Update", function()
            if not IsInRaid() then
                return
            end

            for i = 1, MAX_RAID_MEMBERS do
                local _, _, _, _, _, class, _, online, isDead = GetRaidRosterInfo(i);
                local color = online and not isDead and class and CUSTOM_CLASS_COLORS[class]
                if color then
                    _G["RaidGroupButton" .. i .. "Name"]:SetTextColor(color.r, color.g, color.b)
                    _G["RaidGroupButton" .. i .. "Class"].text:SetTextColor(color.r, color.g, color.b)
                    _G["RaidGroupButton" .. i .. "Level"]:SetTextColor(color.r, color.g, color.b)
                end
            end
        end)

        hooksecurefunc("RaidGroupFrame_UpdateHealth", function(i)
            local _, _, _, _, _, class, _, online, isDead = GetRaidRosterInfo(i);
            local color = online and not isDead and class and CUSTOM_CLASS_COLORS[class]
            if color then
                local r, g, b = color.r, color.g, color.b
                _G["RaidGroupButton" .. i .. "Name"]:SetTextColor(r, g, b)
                _G["RaidGroupButton" .. i .. "Class"].text:SetTextColor(r, g, b)
                _G["RaidGroupButton" .. i .. "Level"]:SetTextColor(r, g, b)
            end
        end)

        hooksecurefunc("RaidPullout_UpdateTarget", function(frame, button, unit, which)
            if _G[frame]["show" .. which] and UnitCanCooperate("player", unit) then
                local _, class = UnitClass(unit)
                local color = class and CUSTOM_CLASS_COLORS[class]
                if color then
                    _G[button .. which .. "Name"]:SetTextColor(color.r, color.g, color.b)
                end
            end
        end)

        local petowners = {}
        for i = 1, 40 do
            petowners["raidpet" .. i] = "raid" .. i
        end
        hooksecurefunc("RaidPulloutButton_UpdateDead", function(button, dead, class)
            local color = not dead and class and CUSTOM_CLASS_COLORS[class]
            if color then
                if class == "PETS" then
                    class, class = UnitClass(petowners[button.unit])
                end
                button.nameLabel:SetVertexColor(color.r, color.g, color.b)
            end
        end)
    end

    ------------------------------------------------------------------------
    -- Blizzard_UIPanels_Game/LootFrame.lua

    addonFuncs["Blizzard_UIPanels_Game"] = function()
        hooksecurefunc("MasterLooterFrame_UpdatePlayers", function()
            -- TODO: Find a better way of doing this... Blizzard's way is frankly quite awful,
            --       creating multiple new local tables every time the function runs. :(
            for k, playerFrame in pairs(MasterLooterFrame) do
                if type(k) == "string" and strmatch(k, "^player%d+$") and type(playerFrame) == "table" and playerFrame.id and playerFrame.Name then
                    local _, _, className = GetMasterLootCandidate(LootFrame.selectedSlot, playerFrame.id);
                    local color = className and CUSTOM_CLASS_COLORS[className]
                    if color then
                        playerFrame.Name:SetTextColor(color.r, color.g, color.b)
                    end
                end
            end
        end)
    end

    ------------------------------------------------------------------------
    -- SharedXML/UnitPositionFrameTemplate.lua

    local function updatePin(self, unit, appearanceData)
        if appearanceData.shouldShow and appearanceData.useClassColor then
            local _, class = UnitClass(unit)
            local color = CUSTOM_CLASS_COLORS[class]
            if color then
                self:SetUnitColor(unit, color.r, color.g, color.b, 1);
            end
        end
    end

    ------------------------------------------------------------------------
    -- Blizzard_WorldMap/Blizzard_WorldMap.lua

    addonFuncs["Blizzard_WorldMap"] = function()
        for k, _ in pairs(WorldMapFrame.dataProviders) do
            if k.pin and k.pin.SetUnitAppearanceInternal then
                hooksecurefunc(k.pin, 'SetUnitAppearanceInternal', function(self, timeNow, unit, appearanceData)
                    updatePin(self, unit, appearanceData)
                end)
                hooksecurefunc(k.pin, 'AddUnitInternal', function(self, timeNow, unit, appearanceData)
                    updatePin(self, unit, appearanceData)
                end)
            end
        end
    end

    ------------------------------------------------------------------------
    -- Blizzard_BattlefieldMap/Blizzard_BattlefieldMap.lua

    addonFuncs["Blizzard_BattlefieldMap"] = function()
        for k, _ in pairs(BattlefieldMapFrame.dataProviders) do
            if k.pin and k.pin.SetUnitAppearanceInternal then
                hooksecurefunc(k.pin, 'SetUnitAppearanceInternal', function(self, timeNow, unit, appearanceData)
                    updatePin(self, unit, appearanceData)
                end)
                hooksecurefunc(k.pin, 'AddUnitInternal', function(self, timeNow, unit, appearanceData)
                    updatePin(self, unit, appearanceData)
                end)
            end
        end
    end
end
------------------------------------------------------------------------
-- FrameXML/ChatFrame.lua

function GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
    if not arg2 then
        return arg2
    end

    local chatType = strsub(event, 10)
    if strsub(chatType, 1, 7) == "WHISPER" then
        chatType = "WHISPER"
    elseif strsub(chatType, 1, 7) == "CHANNEL" then
        chatType = "CHANNEL"..arg8
    end

    if chatType == "GUILD" then
        arg2 = Ambiguate(arg2, "guild")
    else
        arg2 = Ambiguate(arg2, "none")
    end

    local info = ChatTypeInfo[chatType]
    if info and info.colorNameByClass and arg12 and arg12 ~= "" and arg12 ~= 0 then
        local _, class = GetPlayerInfoByGUID(arg12)
        local color = class and CUSTOM_CLASS_COLORS[class]
        if color then
            return format("|c%s%s|r", color.colorStr, arg2)
        end
    end

    return arg2
end

do
    local AddMessage = {}

    local function FixClassColors(frame, message, ...)
        if type(message) == "string" and strfind(message, "|cff") then -- type check required for shitty addons that pass nil or non-string values
            for hex, class in pairs(blizzHexColors) do

                local color = CUSTOM_CLASS_COLORS[class]
                message = color and gsub(message, hex, color.colorStr) or message -- color check required for Warmup, maybe others
            end
        end
        return AddMessage[frame](frame, message, ...)
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        AddMessage[frame] = frame.AddMessage
        frame.AddMessage = FixClassColors
    end
end

------------------------------------------------------------------------
-- FrameXML/ChatConfigFrame.xml

do
    addonTable.postLoadFunctions["FrameXML/ChatConfigFrame.xml"] = function()
        local frames = {_G["ChatConfigChatSettingsClassColorLegend"],_G["ChatConfigChannelSettingsClassColorLegend"]}
        for _,frame in ipairs(frames) do
            for index,fontString in pairs(frame.classStrings) do
                local class = CLASS_SORT_ORDER[index]
                local color = CUSTOM_CLASS_COLORS[class]
                if color and fontString then
                    fontString:SetFormattedText("|cff%.2x%.2x%.2x%s|r\n", color.r*255, color.g*255, color.b*255, LOCALIZED_CLASS_NAMES_MALE[class])
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- FrameXML/CompactUnitFrame.lua

do
    local UnitClass, UnitIsConnected, UnitIsPlayer
    = UnitClass, UnitIsConnected, UnitIsPlayer
    local CompactUnitFrame_GetHideHealth = CompactUnitFrame_GetHideHealth

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        if frame.healthBar then
            if frame:IsForbidden() or CompactUnitFrame_GetHideHealth(frame) then
                return
            end

            local opts = frame.optionTable
            if opts.healthBarColorOverride or not opts.useClassColors
                    or not (opts.allowClassColorsForNPCs or UnitIsPlayer(frame.unit))
                    or not UnitIsConnected(frame.unit) then
                return
            end

            local _, class = UnitClass(frame.unit)
            local color = class and CUSTOM_CLASS_COLORS[class]

            if color then
                local texture = frame.healthBar:GetStatusBarTexture()
                if texture then
                    frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
                    if frame.optionTable.colorHealthWithExtendedColors then
                        frame.selectionHighlight:SetVertexColor(color.r, color.g, color.b)
                    end
                end
            end
        end
    end)
end

------------------------------------------------------------------------
-- FrameXML/FriendsFrame.lua
do
    local memberInfos = {}
    local customTooltip = CreateFrame("GameTooltip", "WWBS_Tooltip", UIParent, "GameTooltipTemplate")
    customTooltip:RegisterEvent("GUILD_ROSTER_UPDATE")
    customTooltip:RegisterEvent("CLUB_UPDATED")
    customTooltip:SetScript("OnEvent", function(self, ...)
        local memberIdInfos = CommunitiesUtil.GetAndSortMemberInfo(CommunitiesUtil.FindGuildStreamByType(Enum.ClubStreamType.Guild))
        if memberIdInfos then
            wipe(memberInfos)
            for _,memberInfo in pairs(memberIdInfos) do
                if memberInfo and memberInfo.name then
                    memberInfos[memberInfo.name] = memberInfo
                end
            end
        end
    end)

    local function ShowCustomTooltip(self)
        local fullName, rank, rankIndex, level, classLoc, zone, note, officernote, online, isAway, class = GetGuildRosterInfo(self.guildIndex)

        if fullName then
            local fullNameNoRealm = fullName:gsub("-.*", "")
            if memberInfos[fullNameNoRealm] then
                local memberInfo = memberInfos[fullNameNoRealm]
                customTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local color = CUSTOM_CLASS_COLORS[class]
                if color then
                    customTooltip:AddLine(color:WrapTextInColorCode(fullNameNoRealm) .. " (" .. memberInfo.level .. ")" .. " - " .. memberInfo.guildRank)
                else
                    customTooltip:AddLine(fullNameNoRealm .. " (" .. memberInfo.level .. ")" .. " - " .. memberInfo.guildRank)
                end

                if memberInfo.memberNote then
                    customTooltip:AddLine(" ")
                    customTooltip:AddLine(memberInfo.memberNote)
                end

                if memberInfo.officerNote then
                    customTooltip:AddLine(memberInfo.officerNote)
                end

                if memberInfo.profession1ID or memberInfo.profession2ID then
                    customTooltip:AddLine(" ")
                    if memberInfo.profession1ID then
                        customTooltip:AddLine(memberInfo.profession1Name .. " " .. memberInfo.profession1Rank)
                    end
                    if memberInfo.profession2ID then
                        customTooltip:AddLine(memberInfo.profession2Name .. " " .. memberInfo.profession2Rank)
                    end
                else
                    customTooltip:AddLine("no professions")
                end
                customTooltip:Show()
            end
        end
    end

    local function HideCustomTooltip()
        customTooltip:Hide()
    end


    for i=1, GUILDMEMBERS_TO_DISPLAY do
        _G["GuildFrameButton"..i]:HookScript("OnEnter", function(self)
            ShowCustomTooltip(self)
        end)
        _G["GuildFrameButton"..i]:HookScript("OnLeave", function(self)
            HideCustomTooltip()
        end)
        _G["GuildFrameGuildStatusButton"..i]:HookScript("OnEnter", function(self)
            ShowCustomTooltip(self)
        end)
        _G["GuildFrameGuildStatusButton"..i]:HookScript("OnLeave", function(self)
            HideCustomTooltip()
        end)
    end


    hooksecurefunc("WhoList_Update", function()
        local offset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
        for i = 1, WHOS_TO_DISPLAY do
            local info = C_FriendList.GetWhoInfo(i + offset)
            if (info and info.filename) then
                local class = info.filename
                local color = class and CUSTOM_CLASS_COLORS[class]
                if color then
                    _G["WhoFrameButton"..i.."Class"]:SetTextColor(1, 1, 1)
                    _G["WhoFrameButton"..i.."Name"]:SetTextColor(color.r, color.g, color.b)
                end
            end
        end
    end)

    hooksecurefunc("GuildStatus_Update", function()
        local offset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
        for i=1, GUILDMEMBERS_TO_DISPLAY, 1 do
            local guildIndex = offset + i
            local fullName, rank, rankIndex, level, classLoc, zone, note, officernote, online, isAway, class = GetGuildRosterInfo(guildIndex)
            if (fullName and class and online) then
                local color = class and CUSTOM_CLASS_COLORS[class]
                if color then
                    _G["GuildFrameButton"..i.."Class"]:SetTextColor(1, 1, 1)
                    _G["GuildFrameButton"..i.."Name"]:SetTextColor(color.r, color.g, color.b)
                end
            end
        end
    end)

    hooksecurefunc("FriendsFrame_UpdateFriendButton", function(button)
        local id = button.id
        if ( button.buttonType == FRIENDS_BUTTON_TYPE_WOW ) then
            local info = C_FriendList.GetFriendInfoByIndex(id)
            local name = button.name:GetText()
            if (info and info.className and name and type(name) == "string") then
                local className = info.className
                local pattern = className .. "$"
                local coloredResult = CUSTOM_CLASS_COLORS:ColorTextByClassToken(className, className)
                if coloredResult then
                    button.name:SetText(name:gsub(pattern, coloredResult))
                end
            end
        end
    end)
end

------------------------------------------------------------------------
-- FrameXML/LootHistory.lua

hooksecurefunc("LootHistoryFrame_UpdateItemFrame", function(self, itemFrame)
    local itemID = itemFrame.itemIdx
    local rollID, _, _, done, winnerID = C_LootHistory.GetItem(itemID)
    local expanded = self.expandedRolls[rollID]
    if done and winnerID and not expanded then
        local _, class = C_LootHistory.GetPlayerInfo(itemID, winnerID)
        local color = class and CUSTOM_CLASS_COLORS[class]
        if color then
            itemFrame.WinnerName:SetVertexColor(color.r, color.g, color.b)
        end
    end
end)

hooksecurefunc("LootHistoryFrame_UpdatePlayerFrame", function(self, playerFrame)
    if playerFrame.playerIdx then
        local name, class = C_LootHistory.GetPlayerInfo(playerFrame.itemIdx, playerFrame.playerIdx)
        local color = name and class and CUSTOM_CLASS_COLORS[class]
        if color then
            playerFrame.PlayerName:SetVertexColor(color.r, color.g, color.b)
        end
    end
end)

function LootHistoryDropDown_Initialize(self)
    local info = UIDropDownMenu_CreateInfo()
    info.text = MASTER_LOOTER
    info.fontObject = GameFontNormalLeft
    info.isTitle = 1
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)

    local name, class = C_LootHistory.GetPlayerInfo(self.itemIdx, self.playerIdx)
    local color = CUSTOM_CLASS_COLORS[class]

    info = UIDropDownMenu_CreateInfo()
    info.text = format(MASTER_LOOTER_GIVE_TO, format("|c%s%s|r", color.colorStr, name))
    info.func = LootHistoryDropDown_OnClick
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)
end

------------------------------------------------------------------------
-- FrameXML/RaidWarning.lua

do
    local AddMessage = RaidNotice_AddMessage
    RaidNotice_AddMessage = function(frame, message, ...)
        if strfind(message, "|cff") then
            for hex, class in pairs(blizzHexColors) do
                local color = CUSTOM_CLASS_COLORS[class]
                message = gsub(message, hex, color.colorStr)
            end
        end
        return AddMessage(frame, message, ...)
    end
end

------------------------------------------------------------------------
-- FrameXML/StaticPopup.lua (via GetClassColor)

hooksecurefunc("StaticPopup_OnUpdate", function(self, elapsed)
    if self.which ~= "GROUP_INVITE_CONFIRMATION" or self.timeLeft <= 0 then return end

    if not self.linkRegion or not self.nextUpdateTime then return end
    if self.nextUpdateTime > GetTime() then return end

    local _, _, guid = GetInviteConfirmationInfo(self.data)
    local _, class, _, _, _, name = GetPlayerInfoByGUID(guid)
    local color = class and CUSTOM_CLASS_COLORS[class]
    if color then
        GameTooltipTextLeft1:SetFormattedText("|c%s%s|r", color.colorStr, name)
    end
end)

------------------------------------------------------------------------

addonTable.postLoadFunctions["WeWantBlueShamansPostLoad"] = function()
    local numAddons = 0

    for addon, func in pairs(addonFuncs) do
        if IsAddOnLoaded(addon) then
            addonFuncs[addon] = nil
            func()
        else
            numAddons = numAddons + 1
        end
    end

    if numAddons > 0 then
        local f = CreateFrame("Frame")
        f:RegisterEvent("ADDON_LOADED")
        f:SetScript("OnEvent", function(self, event, addon)
            local func = addonFuncs[addon]
            if func then
                addonFuncs[addon] = nil
                numAddons = numAddons - 1
                func()
            end
            if numAddons == 0 then
                self:UnregisterEvent("ADDON_LOADED")
                self:SetScript("OnEvent", nil)
            end
        end)
    end
end

