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

function KeyCount.utilstats.printDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        if dungeon.keyresult.value == KeyCount.defaults.keyresult.intime.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, KeyCount.defaults.keyresult.intime
                    .name,
                    dungeon.name,
                    dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[5].chat)
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.outtime.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i,
                    KeyCount.defaults.keyresult.outtime.name,
                    dungeon.name,
                    dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[3].chat)
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.abandoned.value then
            printf(
                string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i,
                    KeyCount.defaults.keyresult.abandoned.name,
                    dungeon.name,
                    dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[1].chat)
        end
    end
end

function KeyCount.utilstats.printDungeonSuccessRate(tbl)
    for _, d in ipairs(tbl) do
        local colorIdx = math.floor(d.successRate / 20) + 1
        local fmt = KeyCount.defaults.colors.rating[colorIdx].chat
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.intime, d.intime + d.outtime + d.abandoned),
            fmt)
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
        if dps > res[dungeon.name].maxdps then
            res[dungeon.name].maxdps = dps
        end
        --@debug@
        KeyCount.util.printTableOnSameLine(res[dungeon.name], "GetDungeonSuccessRate")
        --@end-debug@
    end
    for name, d in pairs(res) do
        local successRate = 0
        local total = d.intime + d.outtime + d.abandoned
        local median = KeyCount.util.calculateMedian(d.allkeys)
        if (d.outtime + d.abandoned) == 0 then
            successRate = 100
        elseif d.intime == 0 then
            successRate = 0
        else
            successRate = d.intime / total * 100
        end
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
            local successrate = 0
            local listOfKeys = KeyCount.util.getListOfValues(d.dungeons, "level")
            local medianKey = KeyCount.util.calculateMedian(listOfKeys)
            local highestKey = getBestKeyTimed(d.dungeons)
            if (d.abandoned + d.outtime) == 0 then
                successrate = 100
            elseif d.intime == 0 then
                successrate = 0
            else
                successrate = d.intime / d.totalEntries * 100
            end
            table.insert(rate,
                {
                    name = player,
                    totalEntries = d.totalEntries,
                    successRate = successrate,
                    intime = d.intime,
                    outtime = d.outtime,
                    abandoned = d.abandoned,
                    best = highestKey.level,
                    median = medianKey,
                    maxdps = d.maxdps,
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
---@return number dps
function KeyCount.utilstats.getTopDps(party)
    local dmg = {}
    for player, data in pairs(party) do
        local d = data.damage or {}
        local dps = d.dps or 0
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
