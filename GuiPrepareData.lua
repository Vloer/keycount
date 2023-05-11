local function getRoleIcon(role)
    if role == "DAMAGER" then
        return "|TInterface\\AddOns\\KeyCount\\Icons\\roles:14:14:0:0:64:64:0:18:0:18|t"
    elseif role == "HEALER" then
        return "|TInterface\\AddOns\\KeyCount\\Icons\\roles:14:14:0:0:64:64:19:37:0:18|t"
    elseif role == "TANK" then
        return "|TInterface\\AddOns\\KeyCount\\Icons\\roles:14:14:0:0:64:64:38:56:0:18|t"
    else
        return nil
    end
end

local function getPlayerRoleAndColor(dungeon)
    local party = ConvertOldPartyFormat(dungeon.party)
    local player = party[dungeon.player]
    local _class = player.class
    local classUppercase = string.upper(_class)
    local class = string.gsub(classUppercase, " ", "")
    local tbl = RAID_CLASS_COLORS[class]
    local color = { r = tbl.r, g = tbl.g, b = tbl.b, a = 1 }
    local role = player.role
    local roleIcon = getRoleIcon(role)
    if role == "TANK" then
        role = "Tank"
    elseif role == "DAMAGER" then
        role = "DPS"
    else
        role = "Heal"
    end
    return { color = color, hex = tbl.colorStr, role = role, roleIcon = roleIcon }
end

local function getLevelColor(level)
    local idx = 0
    if level > 0 then
        idx = math.floor(level / 5) + 1
    end
    local r, g, b, hex = GetItemQualityColor(idx)
    local color = { r = r, g = g, b = b, a = 1 }
    return { color = color, hex = hex }
end

local function getResultString(dungeon)
    if dungeon.completedInTime then
        return { result = "Timed", color = ConvertRgb(Defaults.colors.rating[5]) }
    elseif dungeon.completed then
        return { result = "Failed to time", color = ConvertRgb(Defaults.colors.rating[3]) }
    else
        return { result = "Abandoned", color = ConvertRgb(Defaults.colors.rating[1]) }
    end
end

local function getDeathsColor(deaths)
    local idx
    if deaths == 0 then
        idx = 5
    else
        idx = math.floor(6 - deaths / 4)
        if idx <= 0 then idx = 1 end
    end
    return ConvertRgb(Defaults.colors.rating[idx])
end

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
    return ConvertRgb(Defaults.colors.rating[idx])
end



local function prepareRowList(dungeon)
    local row = {}
    local player = dungeon.player
    local name = dungeon.name
    local level = dungeon.keyDetails.level
    local result = getResultString(dungeon)
    local deaths = dungeon.totalDeaths or 0
    local time = dungeon.timeToComplete
    local date = ConvertOldDateFormat(dungeon.date)
    local affixes = ConcatTable(dungeon.keyDetails.affixes, ", ")
    local p = getPlayerRoleAndColor(dungeon)
    local playerString = string.format("%s%s", p.roleIcon, player)
    --@debug@
    Log(string.format("prepareRowList: [%s] [%s] [%s] [%s] [%s] [%s] [%s]", player, name, level, result.result, deaths,
        time, date.date))
    --@end-debug@
    table.insert(row, { value = playerString, color = p.color })
    table.insert(row, { value = name })
    table.insert(row, { value = level, color = getLevelColor(level).color })
    table.insert(row, { value = result.result, color = result.color })
    table.insert(row, { value = deaths, color = getDeathsColor(deaths) })
    table.insert(row, { value = time, color = result.color })
    table.insert(row, { value = date.date })
    table.insert(row, { value = affixes })
    return { cols = row }
end

local function prepareRowRate(dungeon)
    local row = {}
    local name = dungeon.name
    local rate = dungeon.successRate
    local rateString = string.format("%.2f%%", rate)
    local intime = dungeon.success
    local outtime = dungeon.outOfTime
    local failed = dungeon.failed
    local best = dungeon.best
    --@debug@
    Log(string.format("prepareRowRate: [%s] [%s] [%s] [%s] [%s] [%s] [%s]", name, rate, rateString, intime, outtime,
        failed, best))
    --@end-debug@
    table.insert(row, { value = name })
    table.insert(row, { value = rateString, color = getSuccessRateColor(rate) })
    table.insert(row, { value = intime })
    table.insert(row, { value = outtime })
    table.insert(row, { value = failed })
    table.insert(row, { value = best, color = getLevelColor(best).color })
    return { cols = row }
end

local function prepareList(dungeons)
    local data = {}
    for _, dungeon in ipairs(dungeons) do
        local row = prepareRowList(dungeon)
        table.insert(data, row)
    end
    return data
end

local function prepareRate(dungeons)
    local data = {}
    for _, dungeon in ipairs(dungeons) do
        local row = prepareRowRate(dungeon)
        table.insert(data, row)
    end
    return data
end

PrepareData = {
    list = prepareList,
    filter = prepareList,
    rate = prepareRate
}
