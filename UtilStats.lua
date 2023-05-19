local function printDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        if dungeon.completedInTime then
            printf(string.format("[%s] %d: Timed %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.chatRating[5])
        elseif dungeon.completed then
            printf(string.format("[%s] %d: Failed to time %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.chatRating[3])
        else
            printf(string.format("[%s] %d: Abandoned %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.chatRating[1])
        end
    end
end

local function printDungeonSuccessRate(tbl)
    for _, d in ipairs(tbl) do
        local colorIdx = math.floor(d.successRate / 20) + 1
        local fmt = KeyCount.defaults.colors.chatRating[colorIdx]
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.success, d.success + d.failed), fmt)
    end
end

local function chatDungeonSuccessRate(tbl)
    local outputchannel = "PARTY"
    local numgroup = GetNumGroupMembers()
    local next = next
    if not tbl or next(tbl) == nil or #tbl == 0 then return end
    if numgroup == 0 then
        outputchannel = "SAY"
    elseif numgroup > 5 then
        outputchannel = "RAID"
    end
    for _, d in ipairs(tbl) do
        SendChatMessage(
            string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.success, d.success + d.failed + d.outOfTime),
            outputchannel)
    end
end

local function getDungeonSuccessRate(dungeons)
    local res = {}
    local resRate = {}
    for _, dungeon in ipairs(dungeons) do
        if not res[dungeon.name] then
            res[dungeon.name] = { success = 0, failed = 0, outOfTime = 0, best = 0 }
        end
        if dungeon.completedInTime then
            res[dungeon.name].success = (res[dungeon.name].success or 0) + 1
            local level = dungeon.keyDetails.level
            if level > res[dungeon.name].best then
                res[dungeon.name].best = level
            end
        else
            if dungeon.completed then
                res[dungeon.name].outOfTime = (res[dungeon.name].outOfTime or 0) + 1
            else
                res[dungeon.name].failed = (res[dungeon.name].failed or 0) + 1
            end
        end
    end
    for name, d in pairs(res) do
        local successRate = 0
        if (d.failed + d.outOfTime) == 0 then
            successRate = 100
        elseif d.success == 0 then
            successRate = 0
        else
            successRate = d.success / (d.success + d.failed + d.outOfTime) * 100
        end
        table.insert(resRate,
            {
                name = name,
                successRate = successRate,
                success = d.success,
                outOfTime = d.outOfTime,
                failed = d.failed,
                best = d.best
            })
    end
    table.sort(resRate, function(a, b)
        return a.successRate > b.successRate
    end)
    return resRate
end

local function showPastDungeons()
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
        dungeon.completedInTime = completed
        dungeon.keyDetails.level = level
        dungeon.completed = completed
        table.insert(previousDungeons, dungeon)
    end
end

KeyCount.utilstats = {
    printDungeons = printDungeons,
    printDungeonSuccessRate = printDungeonSuccessRate,
    chatDungeonSuccessRate = chatDungeonSuccessRate,
    getDungeonSuccessRate = getDungeonSuccessRate,
    showPastDungeons = showPastDungeons,
}
