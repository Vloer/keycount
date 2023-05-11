function Log(message)
    if DLAPI then
        DLAPI.DebugLog("KeyCount", message)
    end
end

function ParseMsg(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    return key, value
end

function FormatTimestamp(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

table.equal = function(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end

    for k, v in pairs(t2) do
        if t1[k] ~= v then
            return false
        end
    end

    return true
end

table.copy = function(destination, source)
    destination = destination or {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = {}
            table.copy(destination[key], value)
        else
            destination[key] = value
        end
    end
    return destination
end

function printf(msg, fmt)
    fmt = fmt or Defaults.colors.chatAnnounce
    print(string.format("%s%s|r", fmt, msg))
end

function SumTbl(tbl)
    if type(tbl) ~= "table" then return end
    local res = 0
    for k, v in pairs(tbl) do
        if type(v) == "number" then
            res = res + v
        end
    end
    return res
end

function ConvertRgb(colorTable)
    local normalizedTable = {}
    for key, value in pairs(colorTable) do
        if type(value) == "number" and value > 1 then
            normalizedTable[key] = value / 255
        else
            normalizedTable[key] = value
        end
    end
    return normalizedTable
end

function OrderListByPlayer(dungeons)
    local dl = {}
    for _, dungeon in pairs(dungeons) do
        local player = dungeon.player
        if not dl[player] then dl[player] = {} end
        table.insert(dl[player], dungeon)
    end
    return dl
end

function ConcatTable(table, delimiter)
    local concatenatedString = ""
    for i, value in ipairs(table) do
        concatenatedString = concatenatedString .. tostring(value)
        if i < #table then
            concatenatedString = concatenatedString .. delimiter
        end
    end
    return concatenatedString
end

function ConvertOldPartyFormat(party)
    local _party = {}
    for k, v in pairs(party) do
        if type(k) == "number" then
            _party[v.name] = v
        else
            _party[k] = v
        end
    end
    return _party
end

function ConvertOldDateFormat(date)
    local res = {}
    if not date or date == "1900-01-01" then
        res = {date = "1900-01-01", datetime = "1900-01-01 00:00:00", datestring = ""}
    elseif #date == 10 and type(date) ~= table then
        res = {date = date, datetime = string.format("%s 00:00:00", date)}
    elseif type(date) == "table" then
        res = {date = date.date or "1900-01-01", datetime = date.datetime or "1900-01-01 00:00:00", datestring = date.datestring or ""}
    else
        res = Defaults.dungeonDefault.date
    end
    return res
end