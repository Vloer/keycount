local stats = KeyCount.utilstats

---Get the highest timed key from a list of keys
---@param dungeons table
---@return table Key table with key name and key level
local function getBestKeyTimed(dungeons)
    local best = 0
    local name
    for _, d in ipairs(dungeons) do
        if d.level > best and d.result == KeyCount.defaults.keyresult.intime.value then
            best = d.level
            name = d.name
        end
    end
    return { name = name, level = best }
end

---Helper function to re-order a table containing player data to the format {ROLE1 = {season1, season2, ...}, ROLE2 = {season1, season2, ...}}
---Expects data to be in the format {SEASON1 = {role1, role2, ...}, SEASON2 = {role1, role2, ...}, ...}
---This function is used in KeyCount.utilstats.getPlayerData
---@param playerdata table Player data object
---@param role string Role to filter. Defaults to all
---@param season string Season to filter. Accepts 'all'. Defaults to current season
---@return table|nil T Reformatted table or nil if invalid playerdata object supplied
local function getPlayerDataRoleSeason(playerdata, role, season)
    if not playerdata or next(playerdata) == nil then return nil end
    local seasondata = {}
    local roledata = {}
    local _season = season or KeyCount.defaults.dungeonDefault.season
    local _role = role or 'all'
    if _season == "all" then
        for _, v in pairs(playerdata) do
            table.insert(seasondata, v)
        end
    else
        table.insert(seasondata, playerdata[season])
    end
    if seasondata and next(seasondata) ~= nil then
        for _, seasonEntry in ipairs(seasondata) do
            if _role == "all" then
                for currentRole, roleEntry in pairs(seasonEntry) do
                    if not roledata[currentRole] then
                        roledata[currentRole] = {}
                    end
                    table.insert(roledata[currentRole], roleEntry)
                end
            else
                if not roledata[_role] then
                    roledata[_role] = {}
                end
                table.insert(roledata[_role], seasonEntry[_role])
            end
        end
    end
    return roledata
end

---Helper function to combine player data per role over multiple seasons.
---This function is used in KeyCount.utilstats.getPlayerData
---@param roledata table Data table containing all player data seperated by role
---@param skipDungeons boolean|nil Only returns player data. Defaults to returning player and dungeon dat
---@return table|nil, table|nil T [1] Combined table [2] List of all dungeons for the player. Nil for both if invalid data object supplied
local function combinePlayerDataPerRole(roledata, skipDungeons)
    if not roledata or next(roledata) == nil then return nil, nil end
    if not skipDungeons then skipDungeons = false end
    local dungeonsAll = {}
    local combinedData = {}
    for roleName, roleData in pairs(roledata) do
        local totalEntries = 0
        local intime = 0
        local outtime = 0
        local abandoned = 0
        local maxdps = 0
        local maxhps = 0
        local best = 0
        local median = {}
        local dungeonsForRole = {}
        local dungeon_ids_seen = {} -- Make sure not to store duplicates (shouldn't be possible)
        local playerClass = ""
        local playerName = ""
        for _, seasonEntry in ipairs(roleData) do
            totalEntries = totalEntries + seasonEntry["totalEntries"]
            intime = intime + seasonEntry["intime"]
            outtime = outtime + seasonEntry["outtime"]
            abandoned = abandoned + seasonEntry["abandoned"]
            maxdps = KeyCount.util.getMax(maxdps, seasonEntry["maxdps"])
            maxhps = KeyCount.util.getMax(maxhps, seasonEntry["maxhps"])
            best = KeyCount.util.getMax(best, seasonEntry["best"])
            if not skipDungeons then
                for _, dung in ipairs(seasonEntry["dungeons"]) do
                    local uuid = dung["uuid"]
                    dung.role = roleName
                    if not KeyCount.util.listContainsItem(uuid, dungeon_ids_seen) then
                        table.insert(dungeon_ids_seen, uuid)
                        table.insert(dungeonsForRole, dung)
                        table.insert(dungeonsAll, dung)
                        table.insert(median, dung["level"])
                    end
                end
            end
            if #playerClass == 0 then playerClass = seasonEntry["class"] or "" end
            if #playerName == 0 then playerName = seasonEntry["player"] or "" end
        end
        local _median = KeyCount.util.calculateMedian(median)
        combinedData[roleName] = {
            totalEntries = totalEntries,
            intime = intime,
            outtime = outtime,
            abandoned = abandoned,
            maxdps = maxdps,
            maxhps = maxhps,
            best = best,
            median = _median,
            dungeons = dungeonsForRole,
            class = playerClass,
            name = playerName,
        }
    end
    return combinedData, dungeonsAll
end

function KeyCount.utilstats.printDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        local result = dungeon.keyresult or dungeon.result
        local keydata = dungeon.keydata or {}
        local level = keydata.level or dungeon.level
        local deaths = dungeon.totalDeaths or dungeon.deaths
        if result == KeyCount.defaults.keyresult.intime.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, KeyCount.defaults.keyresult.intime
                    .name,
                    dungeon.name,
                    level, deaths), KeyCount.defaults.colors.rating[5].chat)
        elseif result == KeyCount.defaults.keyresult.outtime.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i,
                    KeyCount.defaults.keyresult.outtime.name,
                    dungeon.name,
                    level, deaths), KeyCount.defaults.colors.rating[3].chat)
        elseif result == KeyCount.defaults.keyresult.abandoned.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i,
                    KeyCount.defaults.keyresult.abandoned.name,
                    dungeon.name,
                    level, deaths), KeyCount.defaults.colors.rating[1].chat)
        end
    end
end

function KeyCount.utilstats.printDungeonSuccessRate(tbl)
    for _, d in ipairs(tbl) do
        local colorIdx = KeyCount.util.getColorIdx(d.successRate) 
        local fmt = KeyCount.defaults.colors.rating[colorIdx].chat
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.intime, d.intime + d.outtime + d.abandoned),
            fmt)
    end
end

---Prints player success rate per role to the chat window
---@param player string Player name
---@param summary table All data (retrieved from getPlayerDataSummary)
---@param onlySummary boolean Only print the summary
---@param dungeons table|nil All dungeons
function KeyCount.utilstats.printPlayerSuccessRate(player, summary, onlySummary, dungeons)
    onlySummary = onlySummary or false
    if dungeons and next(dungeons) ~= nil and not onlySummary then
        for i, dungeon in ipairs(dungeons) do
            local result = dungeon.result
            local level = dungeon.level
            local deaths = dungeon.deaths
            if result == KeyCount.defaults.keyresult.intime.value then
                printf(
                    string.format("[%s] %d: %s %s %d (%d deaths)", player, i, KeyCount.defaults.keyresult.intime
                        .name,
                        dungeon.name,
                        level, deaths), KeyCount.defaults.colors.rating[5].chat)
            elseif result == KeyCount.defaults.keyresult.outtime.value then
                printf(
                    string.format("[%s] %d: %s %s %d (%d deaths)", player, i,
                        KeyCount.defaults.keyresult.outtime.name,
                        dungeon.name,
                        level, deaths), KeyCount.defaults.colors.rating[3].chat)
            elseif result == KeyCount.defaults.keyresult.abandoned.value then
                printf(
                    string.format("[%s] %d: %s %s %d (%d deaths)", player, i,
                        KeyCount.defaults.keyresult.abandoned.name,
                        dungeon.name,
                        level, deaths), KeyCount.defaults.colors.rating[1].chat)
            end
        end
        printf('Summary: ')
    end
    for _, data in ipairs(summary) do
        local colorIdx = KeyCount.util.getColorIdx(data['rate'])
        local fmt = KeyCount.defaults.colors.rating[colorIdx].chat
        local level = data['best'] or 0
        local levelColor = KeyCount.util.getLevelColor(level).hex
        local levelString = string.format('|c%s%d', levelColor, level)
        local intime = string.format('%s%d', KeyCount.defaults.colors.rating[5].chat, data['intime'])
        local outtime = string.format('%s%d', KeyCount.defaults.colors.rating[3].chat, data['outtime'])
        local abandoned = string.format('%s%d', KeyCount.defaults.colors.rating[1].chat, data['abandoned'])
        printf(string.format("%s: %.2f%% [%s|r/%s|r/%s|r]. Best: %s",
            data['role'],
            data['rate'],
            intime,
            outtime,
            abandoned,
            levelString
        ), fmt)
    end
end

---Prints success rate to the appropriate chat window
---@param tbl table Data to print
---@param maxlines number|nil Maximum mount of lines to print (default 10)
function KeyCount.utilstats.chatSuccessRate(tbl, maxlines)
    maxlines = maxlines or 10
    local next = next
    if not tbl or next(tbl) == nil or #tbl == 0 then return end
    local outputchannel = "PARTY"
    local numgroup = GetNumGroupMembers()
    if numgroup == 0 then
        outputchannel = "SAY"
    elseif numgroup > 5 then
        outputchannel = "RAID"
    end
    SendChatMessage("KeyCount: ===Success Rate===", outputchannel)
    local filtermsg
    if #KeyCount.gui.key > 0 then
        filtermsg = "FILTER > " .. KeyCount.gui.key
        if KeyCount.gui.value and #KeyCount.gui.value > 0 then
            filtermsg = filtermsg .. ": " .. KeyCount.gui.value
        end
        SendChatMessage(filtermsg, outputchannel)
    end
    for i, d in ipairs(tbl) do
        if i > maxlines then break end
        local msg = string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.intime, d.totalEntries)
        SendChatMessage(msg, outputchannel)
    end
end

function KeyCount.utilstats.getDungeonSuccessRate(dungeons)
    local res = {}
    local resRate = {}
    for _, dungeon in ipairs(dungeons) do
        if not res[dungeon.name] then
            res[dungeon.name] = { intime = 0, outtime = 0, abandoned = 0, best = 0, maxdps = 0, allkeys = {} }
        end
        local keylevel = dungeon.keydata.level or 0
        if keylevel > 0 then
            table.insert(res[dungeon.name].allkeys, keylevel)
        end
        if dungeon.keyresult.value == KeyCount.defaults.keyresult.intime.value then
            res[dungeon.name].intime = (res[dungeon.name].intime or 0) + 1
            local level = dungeon.keydata.level
            if level > res[dungeon.name].best then
                res[dungeon.name].best = level
            end
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.outtime.value then
            res[dungeon.name].outtime = (res[dungeon.name].outtime or 0) + 1
        else
            res[dungeon.name].abandoned = (res[dungeon.name].abandoned or 0) + 1
        end
        local dps = KeyCount.utilstats.getPlayerDps(dungeon.party[dungeon.player])
        res[dungeon.name].maxdps = KeyCount.util.getMax(res[dungeon.name].maxdps, dps)
        --@debug@
        KeyCount.util.printTableOnSameLine(res[dungeon.name], "GetDungeonSuccessRate")
        --@end-debug@
    end
    for name, d in pairs(res) do
        local successRate = KeyCount.util.calculateSuccessRate(d.intime, d.outtime, d.abandoned)
        local total = d.intime + d.outtime + d.abandoned
        local median = KeyCount.util.calculateMedian(d.allkeys)
        table.insert(resRate,
            {
                name = name,
                successRate = successRate,
                intime = d.intime,
                outtime = d.outtime,
                abandoned = d.abandoned,
                best = d.best,
                median = median,
                totalEntries = total,
                maxdps = d.maxdps
            })
    end
    table.sort(resRate, function(a, b)
        return a.successRate > b.successRate
    end)
    return resRate
end

-- Get data for all players in specified dungeons, sorted by player
---@param dungeons table Dungeons to gather data format
---@return table|nil players List of all found players with some attributes
function KeyCount.utilstats.getPlayerList(dungeons)
    if not dungeons then return nil end
    local players = {}
    for _, dungeon in ipairs(dungeons) do
        local party = dungeon.party or {}
        for player, playerdata in pairs(party) do
            local role = playerdata.role
            if not players[player] then
                --@debug@
                Log(string.format("Adding %s to list of players", player))
                --@end-debug@
                players[player] = {}
            end
            if not players[player][role] then
                players[player][role] = table.copy({}, KeyCount.defaults.playerDefault)
            end
            players[player][role].player = player
            players[player][role].role = role
            players[player][role].class = playerdata.class
            players[player][role].totalEntries = players[player][role].totalEntries + 1
            local dps = KeyCount.utilstats.getPlayerDps(playerdata)
            local hps = KeyCount.utilstats.getPlayerHps(playerdata)
            if dps > players[player][role].maxdps then players[player][role].maxdps = dps end
            if dps > players[player][role].maxhps then players[player][role].maxhps = hps end
            local keydata = dungeon.keydata
            local key = {
                name = keydata.name,
                level = keydata.level,
                affixes = keydata.affixes,
                result = dungeon.keyresult.value,
                resultstring = dungeon.keyresult.name,
                season = dungeon.season,
            }
            if key.result == KeyCount.defaults.keyresult.intime.value then
                players[player][role].intime = players[player][role].intime + 1
            elseif key.result == KeyCount.defaults.keyresult.outtime.value then
                players[player][role].outtime = players[player][role].outtime + 1
            elseif key.result == KeyCount.defaults.keyresult.abandoned.value then
                players[player][role].abandoned = players[player][role].abandoned + 1
            end
            table.insert(players[player][role].dungeons, key)
        end
    end
    return players
end

-- Get the success rate of grouping with individual players
---@param dungeons table Dungeons to gather data format
---@return table|nil players List of all found players with some attributes
function KeyCount.utilstats.getPlayerSuccessRate(dungeons)
    local rate = {}
    local players = KeyCount.utilstats.getPlayerList(dungeons)
    if not players then
        printf("No players found in stored dungeons!", KeyCount.defaults.colors.chatError, true)
        return
    end
    for player, playerdata in pairs(players) do
        for role, d in pairs(playerdata) do
            local successRate = KeyCount.util.calculateSuccessRate(d.intime, d.outtime, d.abandoned)
            local listOfKeys = KeyCount.util.getListOfValues(d.dungeons, "level")
            local medianKey = 0
            if listOfKeys then
                medianKey = KeyCount.util.calculateMedian(listOfKeys)
            end
            local highestKey = getBestKeyTimed(d.dungeons)
            table.insert(rate,
                {
                    name = player,
                    totalEntries = d.totalEntries,
                    successRate = successRate,
                    intime = d.intime,
                    outtime = d.outtime,
                    abandoned = d.abandoned,
                    best = highestKey.level,
                    median = medianKey,
                    maxdps = d.maxdps,
                    maxhps = d.maxhps,
                    class = d.class,
                    role = role
                })
        end
    end
    table.sort(rate, function(a, b)
        return a.totalEntries > b.totalEntries
    end)
    return rate
end

function KeyCount.utilstats.showPastDungeons()
    PreviousRunsDB = PreviousRunsDB or {}
    local runs = C_MythicPlus.GetRunHistory(true, true) -- This only captures finished dungeons
    local previousDungeons = {}
    for i, run in ipairs(runs) do
        local map = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        local level = run.level
        local completed = run.completed
        Log(string.format("%d: %s level %s %s", i, map, level, tostring(completed)))
        local dungeon = KeyCount.defaults.dungeonDefault
        dungeon.name = map
        dungeon.keydata.level = level
        dungeon.completed = completed
        table.insert(previousDungeons, dungeon)
    end
end

-- Get the top dps of the party
---@param party table Table containing party data
---@return table T Table containing data of the player which had top dps
function KeyCount.utilstats.getTopDps(party)
    local dmg = {}
    for player, data in pairs(party) do
        local dps = KeyCount.utilstats.getPlayerDps(data)
        table.insert(dmg, { player = player, dps = dps })
    end
    table.sort(dmg, function(a, b) return a.dps > b.dps end)
    return dmg[1]
end

-- Get a single players dps
---@param data table The party table data for the specific player
---@return number dps Returns 0 if no data found
function KeyCount.utilstats.getPlayerDps(data)
    local _data = data or {}
    local d = _data.damage or {}
    local dps = d.dps or 0
    return dps
end

-- Get a single players hps
---@param data table The party table data for the specific player
---@return number hps Returns 0 if no data found
function KeyCount.utilstats.getPlayerHps(data)
    local _data = data or {}
    local h = _data.healing or {}
    local hps = h.hps or 0
    return hps
end

---Retrieve the data of a single player for the 'searchplayer' view in the GUI
---@param player table Player data
---@param season string|nil Specify season to retrieve. Defaults to all seasons.
---@param role string|nil Specify for which role we want to retrieve data. Defaults to all roles
---@return table|nil T1, table|nil T2 [T1] stats of the player, [T2] all dungeon stats for the player
function KeyCount.utilstats.getPlayerData(player, season, role)
    local _season = season or "all"
    local _role = KeyCount.util.formatRole(role) or "all"
    local dataByRole = getPlayerDataRoleSeason(player, _role, _season) or {}
    local playerdata, allDungeons = combinePlayerDataPerRole(dataByRole)
    local finalDataOverview = {}
    local finalDataDungeons = {}

    if playerdata then
        for playerRole, roleData in pairs(playerdata) do
            local successRate = KeyCount.util.calculateSuccessRate(roleData.intime, roleData.outtime, roleData.abandoned)
            table.insert(finalDataOverview,
                {
                    name = roleData.name,
                    amount = roleData.totalEntries,
                    rate = successRate,
                    intime = roleData.intime,
                    outtime = roleData.outtime,
                    abandoned = roleData.abandoned,
                    best = roleData.best,
                    median = roleData.median,
                    maxdps = roleData.maxdps,
                    maxhps = roleData.maxhps,
                    role = playerRole,
                    class = roleData.class,
                }
            )
        end
    end

    if allDungeons then
        for _, d in ipairs(allDungeons) do
            local dps = KeyCount.utilstats.getPlayerDps(d)
            local hps = KeyCount.utilstats.getPlayerHps(d)
            table.insert(finalDataDungeons,
                {
                    name = d.name,
                    level = d.level,
                    resultstring = d.resultstring,
                    result = d.result,
                    time = d.timeToComplete,
                    deaths = d.deaths,
                    dps = dps,
                    hps = hps,
                    date = d.date,
                    affixes = KeyCount.util.concatTable(d.affixes, ", "),
                    season = d.season,
                    role = d.role,
                }
            )
        end
    end

    local _r1 = finalDataOverview
    local _r2 = finalDataDungeons
    if next(_r1) == nil then _r1 = nil end
    if next(_r2) == nil then _r2 = nil end
    return _r1, _r2
end

---Retrieve the data summary of a single player. Returns counts and success rate per role
---@param player table All player data
---@param season string|nil Defaults to all seasons
---@param role string|nil Defaults to all roles
---@return table|nil T One row per role, nil if something went wrong
function KeyCount.utilstats.getPlayerDataSummary(player, season, role)
    --@debug@
    Log('Starting getPlayerDataSummary')
    --@end-debug@
    local _season = season or "all"
    local _role = KeyCount.util.formatRole(role) or "all"
    local dataByRole = getPlayerDataRoleSeason(player, _role, _season) or {}
    local playerdata = combinePlayerDataPerRole(dataByRole, true)
    local finalDataOverview = {}
    if playerdata then
        for playerRole, roleData in pairs(playerdata) do
            local successRate = KeyCount.util.calculateSuccessRate(roleData.intime, roleData.outtime, roleData.abandoned)
            table.insert(finalDataOverview,
                {
                    name = roleData.name,
                    amount = roleData.totalEntries,
                    rate = successRate,
                    intime = roleData.intime,
                    outtime = roleData.outtime,
                    abandoned = roleData.abandoned,
                    best = roleData.best,
                    median = roleData.median,
                    maxdps = roleData.maxdps,
                    maxhps = roleData.maxhps,
                    role = playerRole,
                    class = roleData.class,
                }
            )
        end
    end
    if next(finalDataOverview) ~= nil then
        return finalDataOverview
    end
    return nil
end

---Helper function to calculate wilson confidence score
---@param rate number Success rate
---@param total number Total number of runs
---@param Z number Z score
---@param direction number -1 for lowerbound, +1 for upperbound
---@return number S Confidence
local function calculateWilsonConfidence(rate, total, Z, direction)
    if not direction == -1 or not direction == 1 then return 0 end
    return (
            (rate + ((Z * Z) / (2 * total))) +
            (1 * direction) * (Z * math.sqrt(((rate * (1 - rate)) / total) + ((Z * Z) / (4 * (total * total)))))
        ) /
        (1 + ((Z * Z) / total))
end

---Calculates a weighted player score
---@param intime number Dungeons completed in time
---@param outtime number Dungeons completed out of time
---@param abandoned number Dungeons abandoned
---@param median number Median key level
---@param best number Best key completed
---@return number Score
function KeyCount.utilstats.calculatePlayerScore(intime, outtime, abandoned, median, best)
    intime = intime or 0
    outtime = outtime or 0
    abandoned = abandoned or 0
    local total = intime + outtime + abandoned
    local Z = 1.5
    local successRate = intime / total
    local lowerbound = calculateWilsonConfidence(successRate, total, Z, -1)
    local upperbound = calculateWilsonConfidence(successRate, total, Z, 1)
    local score = (upperbound + lowerbound) / 2 * 100
    local multiplier = 1 + ((best * ((best + median) / 2)) / 100) -- TODO fix multiplier to get more accurate score
    return score
end
