-- Format the dungeon storage object to the most recent version to avoid any data errors
---@param dungeonIn table Dungeon data
---@return table dungeon Updated dungeon data
---@return boolean updated True if dungeon was updated
function KeyCount.formatdata.formatdungeon(dungeonIn, _new)
    local dungeon = table.copy({}, dungeonIn)
    local old = dungeon["version"] or 0
    local new = _new or KeyCount.defaults.dungeonDefault.version
    if old == new then return dungeon, false end
    local _data = dungeon.keyDetails or dungeon.keydata or {}
    local level = _data.level or 0
    local debuglog = string.format("Formatted data for [%s %s] from version %s", tostring(dungeon.name), tostring(level),
        tostring(old))

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

    -- 2 to 3
    if old == 2 and new >= 3 then
        -- Add UUID
        if not dungeon["uuid"] or #dungeon["uuid"] == 0 then
            dungeon["uuid"] = KeyCount.util.uuid()
        end

        -- Add realmname to player names
        dungeon["player"] = KeyCount.util.addRealmToName(dungeon["player"])
        local updatedParty = {}
        for k, v in pairs(dungeon["party"]) do
            local newName = KeyCount.util.addRealmToName(k)
            v["name"] = newName
            updatedParty[newName] = v
        end
        dungeon["party"] = updatedParty
        if type(dungeon["deaths"]) == "table" then
            local updatedDeaths = {}
            for k, v in pairs(dungeon["deaths"]) do
                local newName = KeyCount.util.addRealmToName(k)
                updatedDeaths[newName] = v
            end
            dungeon["deaths"] = updatedDeaths
        end

        -- Check keydata name
        if dungeon.keydata.name == "" then
            dungeon.keydata.name = dungeon.name
        end

        -- Check that damage exists (has been bugged in the past)
        for player, data in pairs(dungeon["party"]) do
            local damage = data["damage"] or KeyCount.defaults.partymember.damage
            local healing = data["healing"] or KeyCount.defaults.partymember.healing
            dungeon["party"][player]["damage"] = damage
            dungeon["party"][player]["healing"] = healing
        end

        old = 3
        dungeon["version"] = old
        debuglog = string.format("%s to version %s", debuglog, old)
    end

    -- Final sanity check
    --KeyCount.util.safeExec('checktable', KeyCount.util.checkKeysInTable, dungeon, KeyCount.defaults.dungeonDefault, 'FormatDungeon')
    --@debug@
    Log("Performing final sanity check on dungeon " .. dungeon["uuid"])
    --@end-debug@
    KeyCount.util.checkKeysInTable(dungeon, KeyCount.defaults.dungeonDefault, 'FormatDungeon')

    --@debug@
    Log(debuglog)
    --@end-debug@
    return dungeon, true
end

---Format player data to the latest version. If data for one player is off, everything is off and an update occurs. If data is updated we always rebuild the whole player database.
---The purpose of this function if to check if the database needs to be rebuilt.
---@param dungeons table All dungeon data
---@param playersIn table All player data
function KeyCount.formatdata.formatplayers(dungeons, playersIn)
    local players = table.copy({}, playersIn)
    local rebuild = false

    for player, playerdata in pairs(players) do
        if not string.find(player, "-") then
            rebuild = true
            break
        end
        for season, seasondata in pairs(playerdata) do
            for role, roledata in pairs(seasondata) do
                if roledata["version"] == 1 then
                    rebuild = true
                    local uuid = roledata["dungeons"][1]["uuid"] or nil
                    Log(string.format("Checking %s %s %s", player, season, role))
                    if not uuid or #uuid == 0 then
                        rebuild = true
                        --@debug@
                        Log(string.format("Found that %s %s %s was not compliant with the latest database version",
                            player, season, role))
                        --@end-debug@
                    end
                end
                if rebuild then break end
            end
            if rebuild then break end
        end
        if rebuild then break end
    end

    if rebuild then
        --@debug@
        Log("Rebuilding player database")
        --@end-debug@
        KeyCountDB.players = {}
        KeyCount:SaveAllPlayers(dungeons)
    else
        if KeyCount.util.checkIfPrintMessage() then
            printf("Player database check completed", nil, true)
        end
    end
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
    - Changed keyDetails to keydata and added name
    - Changed timeLimit to timelimit
    - Removed completedintime and added keyresult
3 -
    - Added UUID to dungeon
    - Force realm name on all players
    - Check if Keydata contains name (sometimes doesn't) and fill it in if needed
    - Make sure damage and healing are added to partymember data
]]

--[[
PLayer storage version changelog:
1 - Initial
2 -
    - Added dungeon UUID, timeToComplete, player deaths, date, damage and healing to dungeons in player[dungeons]
    - Added median and best key to player data
    - Actually filled role and class
]]
