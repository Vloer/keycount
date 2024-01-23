KeyCount.filterfunctions.print = {}

--#region Local helper functions
local function noResult(key, value)
    local msg = ""
    key = key or ""
    value = value or ""
    if #key > 0 then
        msg = string.format(" [%s: '%s']", key, value)
    end
    printf(string.format("No dungeons matched your filter criteria%s!", msg), KeyCount.defaults.colors.chatWarning, true)
    return nil
end

local filterConditions = {
    ["alldata"] = function(entry, value)
        -- return entry["season"] == KeyCount.defaults.dungeonDefault.season
        return
    end,
    ["player"] = function(entry, value)
        local _value = KeyCount.util.addRealmToName(value)
        return string.lower(entry["player"]) == string.lower(_value)
    end,
    ["currentweek"] = function(entry, value)
        local dateInList = KeyCount.util.listContainsItem(entry.date.date, value)
        return dateInList
    end,
    ["name"] = function(entry, value)
        return string.lower(entry["name"]) == string.lower(value)
    end,
    ["dungeon"] = function(entry, value)
        return string.lower(entry["name"]) == string.lower(value)
    end,
    ["completed"] = function(entry, value)
        return entry["completed"] == value
    end,
    ["keyresult"] = function(entry, value)
        return entry["keyresult"]["value"] == value
    end,
    ["time"] = function(entry, value)
        local res = entry["time"] or 0
        return res >= value
    end,
    ["deathsgt"] = function(entry, value)
        local res = entry["totalDeaths"] or 0
        return res >= value
    end,
    ["deathslt"] = function(entry, value)
        local res = entry["totalDeaths"] or 0
        return res <= value
    end,
    ["level"] = function(entry, value)
        return entry.keydata.level >= value
    end,
    ["date"] = function(entry, value)
        return entry.date.date == value
    end,
    ["affix"] = function(entry, value)
        local affixes = string.lower(table.concat(entry.keydata.affixes))
        local found = 0
        for i = 2, #value do
            if string.find(affixes, value[i]) then
                if value[1] == "OR" then
                    found = (#value - 1)
                    break
                elseif value[1] == "AND" then
                    found = found + 1
                end
            end
        end
        return found == (#value - 1)
    end,
    ["role"] = function(entry, value)
        local player = entry.player
        local partydata = entry.party[player] or {}
        local role = partydata.role or ""
        if value == "all" then return true end
        return string.lower(role) == string.lower(value)
    end,
    ["season"] = function(entry, value)
        return entry.season == value
    end,
}

---Gets the correct key and values for specified keys and values
---@param key string
---@param value any
---@return string|nil cleanedKey, any cleanedValue
local function cleanFilterArgs(key, value)
    if #key == 0 and #value == 0 then
        return KeyCount.defaults.filter.key, KeyCount.defaults.filter.value
    end

    local _key = string.lower(key)
    if _key == "player" and #value == 0 then
        value = UnitName("player")
    elseif #_key <= 3 and #value == 0 then
        value = KeyCount.defaults.dungeonNamesShort[string.upper(key)]
        if not value then return nil, nil end
        _key = "name"
    elseif _key == "name" and #value <= 3 and #value > 0 then
        value = KeyCount.defaults.dungeonNamesShort[string.upper(value)]
        if not value then return nil, nil end
    elseif _key == "completed" then
        value = true
    elseif _key == "intime" then
        _key = "keyresult"
        value = KeyCount.defaults.keyresult.intime.value
    elseif _key == "outtime" then
        _key = "keyresult"
        value = KeyCount.defaults.keyresult.outtime.value
    elseif _key == "abandoned" then
        _key = "keyresult"
        value = KeyCount.defaults.keyresult.abandoned.value
    elseif _key == "time" or _key == "deathsgt" or _key == "deathslt" or _key == "level" then
        value = tonumber(value) or 0
    elseif _key == "affix" and #value ~= 0 then
        local values = {}
        Log(string.format("FILTER <%s> <%s>", key, tostring(value)))
        if string.find(value, ',') then
            values[1] = "AND"
        else
            values[1] = "OR"
        end

        for substring in string.gmatch(value, "[^|,]+") do
            table.insert(values, string.lower(substring))
        end
        value = values
    elseif _key == "season" then
        if #value == 0 then
            value = KeyCount.defaults.dungeonDefault.season
        elseif KeyCount.util.listContainsItem(value, { "1", "2", "3" }) then
            local seasonNumber = tonumber(value)
            local expansion = KeyCount.defaults.expansion
            value = KeyCount.defaults.seasons[expansion][seasonNumber] or KeyCount.defaults.dungeonDefault.season
        end
    elseif _key == "date" then
        if #value == 0 then
            value = KeyCount.util.getDateToday()
        else
            value = KeyCount.util.normalizeDate(value)
        end
    elseif _key == "role" then
        if #value == 0 then
            value = "all"
        else
            value = KeyCount.util.formatRole(value)
            if not value then
                printf("Role filter only accepts valid roles!", KeyCount.defaults.colors.chatWarning)
                return nil, nil
            end
        end
    elseif _key == "currentweek" then
        local startDate = KeyCount.util.getStartOfWeekDate()
        value = KeyCount.util.getAllDatesInRange(startDate)
    end
    if _key ~= "affix" then
        Log(string.format("FILTER <%s> <%s>", _key, tostring(value)))
    end
    return _key, value
end

---Filters data based on key (filter type) and value (filter value)
---@param tbl table
---@param key string
---@param value string | number | table | nil
---@return table | nil
local function filterData(tbl, key, value)
    local result = {}
    local _key, _value = cleanFilterArgs(key, value)
    if not _key and not _value then return noResult() end
    --@debug@
    Log(string.format("FilterData: cleaned args are [%s] [%s]", _key, tostring(_value)))
    --@end-debug@

    -- Table filtering
    for _, entry in ipairs(tbl) do
        if _key == "alldata" then
            table.insert(result, entry)
        else
            --@debug@
            Log(string.format("FilterData: dungeon [%s] _key [%s] _value [%s]", entry.name, _key, tostring(_value)))
            --@end-debug@
            for conditionKey, conditionFunc in pairs(filterConditions) do
                if _key == conditionKey then
                    if conditionFunc(entry, _value) then
                        table.insert(result, entry)
                    end
                end
            end
        end
    end
    if #result == 0 then
        return noResult(key, value)
    end
    return result
end

---Search a list of playernames for a specific player.
---Checks name-realm first, then name only and returns the first match if there are multiple.
---@param playername string Name to search
---@param db table Database containing all player data
---@return table|nil T All data for a single player
local function searchPlayerGetData(playername, db)
    if not db or next(db) == 0 then return nil end
    if not playername or #playername == 0 then return nil end
    if type(playername) ~= "string" then
        playername = tostring(playername)
    end
    local playernameRealm = KeyCount.util.addRealmToName(playername)
    local _playername = string.lower(playernameRealm)
    --@debug@
    Log("Searching player " .. _playername)
    --@end-debug@

    -- First pass: name-realm
    for p, data in pairs(db) do
        if string.lower(p) == _playername then return data end
    end
    -- Data is not found, using name only
    _playername = KeyCount.util.splitString(_playername)
    for p, data in pairs(db) do
        p = KeyCount.util.splitString(p)
        if string.lower(p) == _playername then return data end
    end
    printf(string.format("No data found for player %s!", playername), KeyCount.defaults.colors.chatWarning, true)
    return nil
end
--#endregion

--#region Filter functions
---Apply filter to dungeons
---@param dungeons table|nil
---@param key string Filter key
---@param value any Filter value
---@return table|nil T
local function filterDungeons(dungeons, key, value)
    local _dungeons = dungeons or KeyCount:GetStoredDungeons()
    if not _dungeons then return end
    local filteredDungeons = filterData(_dungeons, key, value)
    if not filteredDungeons then return end
    return filteredDungeons
end

local function filterDungeonsSuccessRate(dungeons, key, value)
    local _dungeons = filterDungeons(dungeons, key, value)
    if _dungeons then return KeyCount.utilstats.getDungeonSuccessRate(_dungeons) end
end

local function filterDungeonsPlayersGroupedWith(dungeons, key, value)
    local _dungeons = filterDungeons(dungeons, key, value)
    if _dungeons then return KeyCount.utilstats.getPlayerSuccessRate(_dungeons) end
end

---Get data required for the 'searchplayer' view in the GUI
---@param key string Always set to 'player'. Unused
---@param value string Player name to search
---@param season string | nil Season to search. Defaults to all seasons further in the code if nothing is supplied
---@return table|nil T1, table|nil T2 [T1] Stats for the player, [T2] All dungeon stats for the player
local function filterPlayersSearchPlayer(key, value, season)
    local players = KeyCount:GetStoredPlayers()
    if not players then return end
    local player = searchPlayerGetData(value, players)
    if not player then return end
    local playerdata, dungeondata = KeyCount.utilstats.getPlayerData(player, season)
    return playerdata, dungeondata
end

local function filterDungeonsListPrint(key, value)
    local d = KeyCount:GetStoredDungeons()
    local _dungeons = filterDungeons(d, "", "")
    if not _dungeons then return end
    local dl = KeyCount.util.orderListByPlayer(_dungeons)
    for _, dungeons in pairs(dl) do
        KeyCount.utilstats.printDungeons(dungeons)
    end
end

local function filterDungeonsFilterPrint(key, value)
    local d = KeyCount:GetStoredDungeons()
    local _dungeons = filterDungeons(d, key, value)
    if not _dungeons then return end
    local dl = KeyCount.util.orderListByPlayer(_dungeons)
    for _, dungeons in pairs(dl) do
        KeyCount.utilstats.printDungeons(dungeons)
    end
end

local function filterDungeonsSuccessRatePrint(key, value)
    local d = KeyCount:GetStoredDungeons()
    local dungeons = KeyCount.filterfunctions.rate(d, key, value)
    if dungeons then KeyCount.utilstats.printDungeonSuccessRate(dungeons) end
end

---Apply any filter to a set of data
---@param data table
---@param key string | nil
---@param value string | number | table | nil
---@return table | nil filteredData
function KeyCount.filterfunctions.applyfilter(data, key, value)
    key = key or ""
    value = value or ""
    return filterData(data, key, value)
end
--#endregion

KeyCount.filterfunctions.list = filterDungeons
KeyCount.filterfunctions.filter = filterDungeons
KeyCount.filterfunctions.rate = filterDungeonsSuccessRate
KeyCount.filterfunctions.grouped = filterDungeonsPlayersGroupedWith
KeyCount.filterfunctions.searchplayer = filterPlayersSearchPlayer
KeyCount.filterfunctions.print.list = filterDungeonsListPrint
KeyCount.filterfunctions.print.filter = filterDungeonsFilterPrint
KeyCount.filterfunctions.print.rate = filterDungeonsSuccessRatePrint

KeyCount.filterkeys = {
    ["alldata"] = { key = "alldata", value = "", name = "All data" },
    ["player"] = { key = "player", value = "player", name = "Player" },
    ["currentweek"] = { key = "currentweek", value = "currentweek", name = "Current Week" },
    ["dungeon"] = { key = "dungeon", value = "name", name = "Dungeon" },
    ["role"] = { key = "role", value = "role", name = "Player role" },
    ["season"] = { key = "season", value = "season", name = "Season" },
    ["completed"] = { key = "completed", value = "completed", name = "Completed" },
    ["intime"] = { key = "intime", value = "intime", name = "Completed in time" },
    ["outtime"] = { key = "outtime", value = "outtime", name = "Completed out of time" },
    ["abandoned"] = { key = "abandoned", value = "abandoned", name = "Abandoned" },
    ["level"] = { key = "level", value = "level", name = "Minimum key level" },
    ["time"] = { key = "time", value = "time", name = "Time" },
    ["deathsgt"] = { key = "deathsgt", value = "deathsgt", name = "Minimum amount of deaths" },
    ["deathslt"] = { key = "deathslt", value = "deathslt", name = "Maximum amount of deaths" },
    ["date"] = { key = "date", value = "date", name = "Date" },
    ["affix"] = { key = "affix", value = "affix", name = "Affixes" },
}

KeyCount.filterorder = {
    "alldata", "player", "dungeon", "role", "season",
    "completed", "outtime", "abandoned", "level",
    "time", "deathsgt", "deathslt", "date", "affix"
}
