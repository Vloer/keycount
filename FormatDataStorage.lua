-- Format the dungeon storage object to the most recent version to avoid any errors
---@param dungeonIn table Dungeon data
---@return table dungeon Updated dungeon data
function KeyCount.formatdata.format(dungeonIn)
    local dungeon = table.copy({}, dungeonIn)
    local old = dungeon["version"] or 0
    local new = KeyCount.defaults.dungeonDefault.version
    if old == new then return dungeon end
    local level = dungeon.keyDetails.level or dungeon.keydata.level or 0
    local debuglog = string.format("Formatted data for [%s %s] from version %s", dungeon.name, level, old)

    -- 0 to 1
    if old == 0 and new >= 1 then
        dungeon["version"] = old

        -- Fix party
        local newparty = {}
        local k
        for _k, v in pairs(dungeon["party"]) do
            if type(_k) == "number" then
                k = v.name
            else
                k = _k
            end
            newparty[k] = v
            newparty[k]["damage"] = newparty[k]["damage"] or {}
            newparty[k]["damage"]["total"] = newparty[k]["damage"]["total"] or 0
            newparty[k]["damage"]["dps"] = newparty[k]["damage"]["dps"] or 0
            newparty[k]["healing"] = newparty[k]["healing"] or {}
            newparty[k]["healing"]["total"] = newparty[k]["healing"]["total"] or 0
            newparty[k]["healing"]["hps"] = newparty[k]["healing"]["hps"] or 0
        end

        -- Fix deaths
        if type(dungeon["deaths"]) == "number" then
            dungeon["totalDeaths"] = dungeon["deaths"]
        elseif type(dungeon["deaths"]) == "table" then
            for player, _ in pairs(newparty) do
                newparty[player]["deaths"] = dungeon["deaths"][player] or 0
            end
        end
        dungeon.party = table.copy({}, newparty)

        -- Fix date
        local newdate = {}
        local date = dungeon["date"]
        if not date or date == "1900-01-01" then
            newdate = { date = "1900-01-01", datetime = "1900-01-01 00:00:00", datestring = "" }
        elseif #date == 10 and type(date) ~= table then
            newdate = { date = date, datetime = string.format("%s 00:00:00", date) }
        elseif type(date) == "table" then
            newdate = {
                date = date.date or "1900-01-01",
                datetime = date.datetime or "1900-01-01 00:00:00",
                datestring = date.datestring or ""
            }
        else
            newdate = KeyCount.defaults.dungeonDefault.date
        end
        dungeon["date"] = newdate

        -- Add stars
        if dungeon.completedInTime and dungeon.keyDetails.timeLimit then
            local s
            local symbol = KeyCount.defaults.dungeonPlusChar
            if dungeon.time < (dungeon.keyDetails.timeLimit * 0.6) then
                s = symbol .. symbol .. symbol
            elseif dungeon.time < (dungeon.keyDetails.timeLimit * 0.8) then
                s = symbol .. symbol
            else
                s = symbol
            end
            dungeon["stars"] = s
        else
            dungeon["stars"] = ""
        end

        -- Set old version to new so the transformation can continue if needed
        old = 1
        dungeon["version"] = old
        debuglog = string.format("%s to version %s", debuglog, old)
    end

    -- 1 to 2
    if old == 1 and new >= 2 then
        -- Rename keyDetails and timeLimit
        if not dungeon["keydata"] then
            local keydata = {}
            keydata["name"] = dungeon.name
            keydata["level"] = dungeon.keyDetails.level
            keydata["timelimit"] = dungeon.keyDetails.timeLimit
            keydata["affixes"] = dungeon.keyDetails.affixes
            dungeon["keydata"] = keydata
        end

        -- Store dungeon result
        if not dungeon["keyresult"] then
            local dungeonresult
            if dungeon.completedInTime then
                dungeonresult = KeyCount.defaults.keyresult.intime
            elseif dungeon.completed then
                dungeonresult = KeyCount.defaults.keyresult.outtime
            else
                dungeonresult = KeyCount.defaults.keyresult.abandoned
            end
            dungeon["keyresult"] = dungeonresult
        end

        dungeon["completedInTime"] = nil
        dungeon["keyDetails"] = nil

        old = 2
        dungeon["version"] = old
        debuglog = string.format("%s to version %s", debuglog, old)
    end
    --@debug@
    Log(debuglog)
    --@end-debug@
    return dungeon
end

--[[
Dungeon storage version changelog:
0 - Everything before implementation of version system
1 -
    - Added party member name as table name of the party data
    - Added deaths per party member
    - Added damage and healing per party member
    - Changed deaths from number to table
    - Added totalDeaths
    - Changed/added date from string to table of [date, datestring, datetime]
    - Removed usedOwnKey
    - Added stars
    - Added version
2 -
    - Changed keyDetails to keydata
    - Changed timeLimit to timelimit
    - Removed completed/completedintime and added keyresult
]]
