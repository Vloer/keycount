local f = KeyCount.filterfunctions
KeyCount.filterfunctions.print = {}

local function noResult()
    printf("No dungeons matched your filter criteria!", KeyCount.defaults.colors.chatWarning, true)
    return nil
end

local filterConditions = {
    ["alldata"] = function(entry, value)
        return entry["season"] == KeyCount.defaults.dungeonDefault.season
    end,
    ["player"] = function(entry, value)
        return string.lower(entry["player"]) == string.lower(value)
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
        local role = entry.party[player].role or ""
        if value == "all" then return true end
        return string.lower(role) == string.lower(value)
    end
}

---Gets the correct key and values for specified keys and values
---@param key string
---@param value any
---@return string|nil key
---@return any value
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
        if #value == 0 then value = KeyCount.defaults.dungeonDefault.season end
    elseif _key == "date" then
        if #value == 0 then value = date(KeyCount.defaults.dateFormat) end
    elseif _key == "role" then
        if #value == 0  then value = "all"
        else
            value = string.lower(value)
            if value == "dps" or value == "damager" or value == "damage" then
                value = "DAMAGER"
            elseif value == "tank" then
                value = "TANK"
            elseif value == "heal" or value == "healer" or value == "healing" then
                value = "HEALER"
            else
                printf("Role filter accepts values 'tank', 'heal' or 'dps'!", KeyCount.defaults.colors.chatWarning)
                return nil, nil
            end
        end
    end
    if _key ~= "affix" then
        Log(string.format("FILTER <%s> <%s>", _key, tostring(value)))
    end
    return _key, value
end

local function filterData(tbl, key, value)
    local result = {}
    local _key, _value = cleanFilterArgs(key, value)
    if not _key and not _value then return noResult() end
    --@debug@
    Log(string.format("FilterData: cleaned args are [%s] [%s]", _key, tostring(_value)))
    --@end-debug@

    -- Table filtering
    for _, entry in ipairs(tbl) do
        if _key == "season" and entry[_key] ~= nil then
            --@debug@
            Log(string.format("FilterData: dungeon [%s] season [%s]", entry.name, entry.season))
            --@end-debug@
            if _value == "all" or string.lower(entry[_key]) == string.lower(_value) then
                table.insert(result, entry)
            end
        elseif entry["season"] == KeyCount.defaults.dungeonDefault.season then
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
        return noResult()
    end
    return result
end

local function filterDungeons(key, value)
    local _dungeons = KeyCount:GetStoredDungeons()
    if not _dungeons then return end
    local filteredDungeons = filterData(_dungeons, key, value)
    if not filteredDungeons then return end
    return filteredDungeons
end

KeyCount.filterfunctions.list = filterDungeons
KeyCount.filterfunctions.filter = filterDungeons

function KeyCount.filterfunctions.print.list()
    local _dungeons = filterDungeons("", "")
    if not _dungeons then return end
    local dl = KeyCount.util.orderListByPlayer(_dungeons)
    for _, dungeons in pairs(dl) do
        KeyCount.utilstats.printDungeons(dungeons)
    end
end

function KeyCount.filterfunctions.print.filter(key, value)
    local _dungeons = filterDungeons(key, value)
    if not _dungeons then return end
    local dl = KeyCount.util.orderListByPlayer(_dungeons)
    for _, dungeons in pairs(dl) do
        KeyCount.utilstats.printDungeons(dungeons)
    end
end

function KeyCount.filterfunctions.rate(key, value)
    local dungeons = filterDungeons(key, value)
    if dungeons then return KeyCount.utilstats.getDungeonSuccessRate(dungeons) end
end

function KeyCount.filterfunctions.print.rate(key, value)
    local dungeons = KeyCount.filterfunctions.rate(key, value)
    if dungeons then KeyCount.utilstats.printDungeonSuccessRate(dungeons) end
end

function KeyCount.filterfunctions.grouped(key, value)
    local dungeons = filterDungeons(key, value)
    if dungeons then return KeyCount.utilstats.getPlayerSuccessRate(dungeons) end
end

KeyCount.filterkeys = {
    ["alldata"] = { key = "alldata", value = "", name = "All data" },
    ["player"] = { key = "player", value = "player", name = "Player" },
    ["dungeon"] = { key = "dungeon", value = "name", name = "Dungeon" },
    ["role"] = { key = "role", value = "role", name = "Player role" },
    ["season"] = { key = "season", value = "season", name = "Season" },
    ["completed"] = { key = "completed", value = "completed", name = "Completed" },
    ["intime"] = { key = "intime", value = "intime", name = "Completed in time" },
    ["outtime"] = { key = "outtime", value = "outtime", name = "Completed out of time" },
    ["abandoned"] = { key = "abandoned", value = "abandoned", name = "Abandoned" },
    ["level"] = { key = "level", value = "level", name = "Key level" },
    ["time"] = { key = "time", value = "time", name = "Time" },
    ["deathsgt"] = { key = "deathsgt", value = "deathsgt", name = "Minimum amount of deaths" },
    ["deathslt"] = { key = "deathslt", value = "deathslt", name = "Maximum amount of deaths" },
    ["date"] = { key = "date", value = "date", name = "Date" },
    ["affix"] = { key = "affix", value = "affix", name = "Affixes" },
}

KeyCount.filterorder = {
    "alldata", "player", "dungeon", "role", "season",
    "completed", "inTime", "outTime", "failed", "level",
    "time", "deathsgt", "deathslt", "date", "affix" }
