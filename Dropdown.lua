---@class ModifyMenuCallbackContextData
---@field public fromPlayerFrame? boolean
---@field public isMobile? boolean
---@field public isRafRecruit? boolean
---@field public name? string
---@field public server? string
---@field public unit? string
---@field public which? string
---@field public accountInfo? any
---@field public playerLocation? any
---@field public friendsList? number

---@class ModifyMenuCallbackRootDescription
---@field public tag string
---@field public contextData? ModifyMenuCallbackContextData
---@field public CreateDivider fun(self: ModifyMenuCallbackRootDescription)
---@field public CreateTitle fun(self: ModifyMenuCallbackRootDescription, text: string)
---@field public CreateButton fun(self: ModifyMenuCallbackRootDescription, text: string, callback: fun())

local ModifyMenu = Menu and Menu.ModifyMenu
local addonName = "KeyCount"
local validMenuTags = {
    "MENU_LFG_FRAME_SEARCH_ENTRY",
    "MENU_LFG_FRAME_MEMBER_APPLY",
}
local validTypes = {
    ARENAENEMY = true,
    BN_FRIEND = true,
    CHAT_ROSTER = true,
    COMMUNITIES_GUILD_MEMBER = true,
    COMMUNITIES_WOW_MEMBER = true,
    ENEMY_PLAYER = true,
    FOCUS = true,
    FRIEND = true,
    GUILD = true,
    GUILD_OFFLINE = true,
    PARTY = true,
    PLAYER = true,
    RAID = true,
    RAID_PLAYER = true,
    SELF = true,
    TARGET = true,
    WORLD_STATE_SCORE = true,
}
-- TODO move to textutils
local availablePlayerRoleAndIcon = {
    DAMAGER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:0:18:0:18|t',
    HEALER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:19:37:0:18|t',
    TANK = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:38:56:0:18|t'
}

---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
local function isValidMenu(rootDescription, contextData)
    if not contextData then
        return KeyCount.util.listContainsItem(rootDescription.tag, validMenuTags)
    end
    local which = contextData.which
    return which and validTypes[which]
end

---@return string? name, nil, number? level
local function getLFGListInfo(owner)
    local resultID = owner.resultID
    if resultID then
        local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
        local name = searchResultInfo.leaderName
        return name, nil, nil
    end
    local memberIdx = owner.memberIdx
    if not memberIdx then
        return
    end
    local parent = owner:GetParent()
    if not parent then
        return
    end
    local applicantID = parent.applicantID
    if not applicantID then
        return
    end
    local fullName, _, _, level = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
    return fullName, nil, level
end

---@param owner any
---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
---@return string? name, string? realm, number? level, string? unit
local function getPlayerNameForMenu(owner, rootDescription, contextData)
    local name, realm, level
    if not contextData then
        if KeyCount.util.listContainsItem(rootDescription.tag, validMenuTags) then
            return getLFGListInfo(owner)
        end
        return
    end
    local unit = contextData.unit
    if unit and UnitExists(unit) then
        name = GetUnitName(unit, true)
        level = UnitLevel(unit)
        --@debug
        Log(string.format('getPlayerNameForMenu found in unit: %s %s %s', tostring(name), tostring(realm),
            tostring(level)))
        --@end-debug@
        return name, realm, level, unit
    end
    local accountInfo = contextData.accountInfo
    if accountInfo then
        local gameAccountInfo = accountInfo.gameAccountInfo
        name = gameAccountInfo.characterName
        realm = gameAccountInfo.realmName
        level = gameAccountInfo.characterLevel
        --@debug
        Log(string.format('getPlayerNameForMenu found in accountInfo: %s %s %s', tostring(name), tostring(realm),
            tostring(level)))
        --@end-debug@
        return name, realm, level, unit
    end
    name = contextData.name
    realm = contextData.server
    if name then
        --@debug
        Log(string.format('getPlayerNameForMenu found in contextData: %s %s', tostring(name), tostring(realm)))
        --@end-debug@
        return name, realm
    end
end

-- TODO move to textutils
local function getSuccessRateColor(rate)
    local idx
    if rate == 0 then
        idx = 1
    elseif rate == 100 then
        idx = 5
    else
        idx = math.floor(rate / 20) + 1
        if idx <= 0 then idx = 1 end
    end
    return KeyCount.defaults.colors.rating[idx].chat
end

local function getStringForRole(data)
    local score = KeyCount.utilstats.calculatePlayerScore(data.intime, data.outtime, data.abandoned, data.median,
        data.best)
    local scoreString = string.format("%.0f", score)
    local color = getSuccessRateColor(score)
    return string.format('%s%s%s', color, scoreString, KeyCount.defaults.colors.reset)
end

local function getStringForRoleWithText(data)
    local score = KeyCount.utilstats.calculatePlayerScore(data.intime, data.outtime, data.abandoned, data.median,
        data.best)
    local scoreString = string.format('Timed %s of %s', data.intime, data.totalEntries)
    local color = getSuccessRateColor(score)
    return string.format('%s%s%s', color, scoreString, KeyCount.defaults.colors.reset)
end

local function getPlayerDropdownString(data)
    local playerRoleString = ''
    for role, icon in pairs(availablePlayerRoleAndIcon) do
        local _data = data[role] or nil
        if _data then
            playerRoleString = playerRoleString .. icon .. getStringForRole(_data)
        end
    end
    return playerRoleString
end

---@param rootDescription ModifyMenuCallbackRootDescription
---@param data table
---@param name string Player name
---@param buttonPerRole boolean?
local function createButton(rootDescription, data, name, buttonPerRole)
    if not buttonPerRole then
        buttonPerRole = false
    end
    if buttonPerRole then
        for role, icon in pairs(availablePlayerRoleAndIcon) do
            local _data = data[role] or nil
            if _data then
                local roleString = icon .. getStringForRoleWithText(_data)
                rootDescription:CreateButton(roleString, function()
                    GUI:Init()
                    KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, name)
                end)
            end
        end
    else
        local dropdownString = getPlayerDropdownString(data)
        rootDescription:CreateButton(dropdownString, function()
            GUI:Init()
            KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, name)
        end)
    end
end

---@param rootDescription ModifyMenuCallbackRootDescription
local function createButtonNoData(rootDescription)
    rootDescription:CreateButton('No data available', function() end)
end

---@param owner any
---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
local function OnMenuShow(owner, rootDescription, contextData)
    if not isValidMenu(rootDescription, contextData) then
        return
    end
    local name, realm, level, unit = getPlayerNameForMenu(owner, rootDescription, contextData)
    local dataSeason, dataPreviousSeason
    if not name then
        return
    end
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    local players = KeyCount:GetStoredPlayers()
    if not players then
        return
    end
    local _data, playerName = KeyCount.filterfunctions.searchPlayerGetData(name, players)
    if not _data then
        createButtonNoData(rootDescription)
        return
    end
    dataSeason = _data[KeyCount.defaults.season]
    if dataSeason then
        createButton(rootDescription, dataSeason, name, true)
    else
        createButtonNoData(rootDescription)
    end
    if KeyCount.defaults.enablePreviousSeason.enabled then
        dataPreviousSeason = _data[KeyCount.defaults.enablePreviousSeason.season]
    end
    if dataPreviousSeason then
        rootDescription:CreateDivider()
        rootDescription:CreateTitle(string.format('%s season %s', addonName, KeyCount.defaults.enablePreviousSeason.season))
        createButton(rootDescription, dataPreviousSeason, name, true)
    end
end

if ModifyMenu then
    for name, enabled in pairs(validTypes) do
        if enabled then
            local tag = string.format('MENU_UNIT_%s', name)
            ModifyMenu(tag, OnMenuShow)
        end
    end
    for _, tag in ipairs(validMenuTags) do
        ModifyMenu(tag, GenerateClosure(OnMenuShow))
    end
end
