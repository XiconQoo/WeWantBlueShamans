local addonName,addonTable = ...

local strfind, format, gsub, strmatch, strsub = string.find, string.format, string.gsub, string.match, string.sub
local pairs, type = pairs, type

------------------------------------------------------------------------

local addonFuncs = {}

local blizzHexColors = {}
for class, color in pairs(RAID_CLASS_COLORS) do
    blizzHexColors[color.colorStr] = class
end


do
    local GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, UnitCanCooperate = GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, UnitCanCooperate
    local UnitClass, UnitRace, UnitLevel, UnitEffectiveLevel = UnitClass, UnitRace, UnitLevel, UnitEffectiveLevel
    ------------------------------------------------------------------------
    -- Blizzard_GuildUI/Blizzard_GuildRoster.lua

    addonFuncs["Blizzard_GuildUI"] = function()
        hooksecurefunc("GuildRosterButton_SetStringText", function(buttonString, text, isOnline, class)
            local color = isOnline and class and CUSTOM_CLASS_COLORS[class]
            if color then
                buttonString:SetTextColor(color.r, color.g, color.b)
            end
        end)
    end

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
            className = CUSTOM_CLASS_COLORS:ColorTextByClass(className, class)

            local level, effectiveLevel = UnitLevel(unit), UnitEffectiveLevel(unit)
            if level == -1 or effectiveLevel == -1 then
                level = "??"
            elseif ( effectiveLevel ~= level ) then
                level = EFFECTIVE_LEVEL_FORMAT:format(effectiveLevel, level)
            end
            InspectLevelText:SetFormattedText(PLAYER_LEVEL, level, race, className)
        end)
    end


    ------------------------------------------------------------------------
    -- Blizzard_RaidUI/Blizzard_RaidUI.lua

    addonFuncs["Blizzard_RaidUI"] = function()
        local _G = _G
        local min = math.min
        local MAX_RAID_MEMBERS, MEMBERS_PER_RAID_GROUP = MAX_RAID_MEMBERS, MEMBERS_PER_RAID_GROUP

        hooksecurefunc("RaidGroupFrame_Update", function()
            local isRaid = IsInRaid()
            if not isRaid then
                return
            end
            for i = 1, min(GetNumGroupMembers(), MAX_RAID_MEMBERS) do
                local name, _, subgroup, _, _, class, _, online, dead = GetRaidRosterInfo(i)
                local color = online and not dead and _G["RaidGroup" .. subgroup].nextIndex <= MEMBERS_PER_RAID_GROUP and class and CUSTOM_CLASS_COLORS[class]
                if color then
                    local button = _G["RaidGroupButton" .. i]
                    if button.subframes then
                        if button.subframes.name then
                            button.subframes.name:SetTextColor(color.r, color.g, color.b)
                        end
                        if button.subframes.class and button.subframes.class.text then
                            button.subframes.class.text:SetTextColor(color.r, color.g, color.b)
                        end
                        if button.subframes.level then
                            button.subframes.level:SetTextColor(1, 1, 1)
                        end
                    end
                end
            end
        end)

        hooksecurefunc("RaidGroupFrame_UpdateHealth", function(i)
            local _, _, _, _, _, class, _, online, dead = GetRaidRosterInfo(i)
            local color = online and not dead and class and CUSTOM_CLASS_COLORS[class]
            if color then
                local r, g, b = color.r, color.g, color.b
                _G["RaidGroupButton" .. i .. "Name"]:SetTextColor(r, g, b)
                _G["RaidGroupButton" .. i .. "Class"]:SetTextColor(r, g, b)
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

    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        if frame.healthBar then
            local opts = frame.optionTable
            if opts.healthBarColorOverride or not opts.useClassColors
                    or not (opts.allowClassColorsForNPCs or UnitIsPlayer(frame.unit))
                    or not UnitIsConnected(frame.unit) then
                return
            end

            local _, class = UnitClass(frame.unit)
            local color = class and CUSTOM_CLASS_COLORS[class]

            local texture = frame.healthBar:GetStatusBarTexture()
            if color and texture then
                frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
                if frame.optionTable.colorHealthWithExtendedColors then
                    frame.selectionHighlight:SetVertexColor(color.r, color.g, color.b)
                end
            end
        end
    end)
end

------------------------------------------------------------------------
-- FrameXML/FriendsFrame.lua

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

------------------------------------------------------------------------
-- FrameXML/LFDFrame.lua

hooksecurefunc("LFDQueueFrameRandomCooldownFrame_Update", function()
    for i = 1, GetNumSubgroupMembers() do
        local _, class = UnitClass("party"..i)
        local color = class and CUSTOM_CLASS_COLORS[class]
        if color then
            local name, server = UnitName("party"..i) -- skip call to GetUnitName wrapper func
            if server and server ~= "" then
                _G["LFDQueueFrameCooldownFrameName"..i]:SetFormattedText("|c%s%s-%s|r", color.colorStr, name, server)
            else
                _G["LFDQueueFrameCooldownFrameName"..i]:SetFormattedText("|c%s%s|r", color.colorStr, name)
            end
        end
    end
end)

------------------------------------------------------------------------
-- FrameXML/LFGFrame.lua

hooksecurefunc("LFGCooldownCover_Update", function(self)
    local nextIndex, numPlayers, prefix = 1
    if IsInRaid() then
        numPlayers = GetNumGroupMembers()
        prefix = "raid"
    else
        numPlayers = GetNumSubgroupMembers()
        prefix = "party"
    end

    for i = 1, numPlayers do
        if nextIndex > #self.Names then
            break
        end

        local unit = prefix..i
        if self.showAll or (self.showCooldown and UnitHasLFGRandomCooldown(unit)) or UnitHasLFGDeserter(unit) then
            local _, class = UnitName(unit)
            local color = class and CUSTOM_CLASS_COLORS[class]
            if color then
                local name, server = UnitName(unit) -- skip call to GetUnitName wrapper func
                if server and server ~= "" then
                    self.Names[nextIndex]:SetFormattedText("|c%s%s-%s|r", color.colorStr, name, server)
                else
                    self.Names[nextIndex]:SetFormattedText("|c%s%s|r", color.colorStr, name)
                end
            end
            nextIndex = nextIndex + 1
        end
    end
end)

------------------------------------------------------------------------
-- FrameXML/LFGList.lua

local grayedOutStatus = {
    failed = true,
    cancelled = true,
    declined = true,
    declined_full = true,
    declined_delisted = true,
    invitedeclined = true,
    timedout = true,
}

hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(member, appID, memberIdx, status, pendingStatus)
    if not pendingStatus and grayedOutStatus[status] then
        -- grayedOut
        return
    end

    local name, class = C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
    local color = name and class and CUSTOM_CLASS_COLORS[class]
    if color then
        member.Name:SetTextColor(color.r, color.g, color.b)
    end
end)

hooksecurefunc("LFGListApplicantMember_OnEnter", function(self)
    local applicantID = self:GetParent().applicantID
    local memberIdx = self.memberIdx
    local name, class = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
    local color = name and class and CUSTOM_CLASS_COLORS[class]
    if color then
        GameTooltipTextLeft1:SetTextColor(color.r, color.g, color.b)
    end
end)

local LFG_LIST_TOOLTIP_MEMBERS_SIMPLE = gsub(LFG_LIST_TOOLTIP_MEMBERS_SIMPLE, "%%d", "%%d+")

hooksecurefunc("LFGListSearchEntry_OnEnter", function(self)
    local resultID = self.resultID
    local _, activityID, _, _, _, _, _, _, _, _, _, _, numMembers = C_LFGList.GetSearchResultInfo(resultID)
    local _, _, _, _, _, _, _, _, displayType = C_LFGList.GetActivityInfo(activityID)
    if displayType ~= LE_LFG_LIST_DISPLAY_TYPE_CLASS_ENUMERATE then return end
    local start
    for i = 4, GameTooltip:NumLines() do
        if strfind(_G["GameTooltipTextLeft"..i]:GetText(), LFG_LIST_TOOLTIP_MEMBERS_SIMPLE) then
            start = i
            break
        end
    end
    if start then
        for i = 1, numMembers do
            local _, class = C_LFGList.GetSearchResultMemberInfo(resultID, i)
            local color = class and CUSTOM_CLASS_COLORS[class]
            if color then
                _G["GameTooltipTextLeft"..(start+i)]:SetTextColor(color.r, color.g, color.b)
            end
        end
    end
end)

------------------------------------------------------------------------
-- FrameXML/LootFrame.lua

hooksecurefunc("MasterLooterFrame_UpdatePlayers", function()
    -- TODO: Find a better way of doing this... Blizzard's way is frankly quite awful,
    --       creating multiple new local tables every time the function runs. :(
    for k, playerFrame in pairs(MasterLooterFrame) do
        if type(k) == "string" and strmatch(k, "^player%d+$") and type(playerFrame) == "table" and playerFrame.id and playerFrame.Name then
            local _, class
            if IsInRaid() then
                _, class = UnitClass("raid"..playerFrame.id)
            elseif playerFrame.id > 1 then
                _, class = UnitClass("party"..playerFrame.id)
            else
                _, class = UnitClass("player")
            end

            local color = class and CUSTOM_CLASS_COLORS[class]
            if color then
                playerFrame.Name:SetTextColor(color.r, color.g, color.b)
            end
        end
    end
end)

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
-- SharedXML/UnitPopupShared.lua

hooksecurefunc("UnitPopup_ShowMenu", function(dropdownMenu, which, unit, name, userData)
    -- TBD
    --[[
        see UnitPopupManager:AddDropDownTitle(unit, name, userData)
    --]]
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

