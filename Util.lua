function Log(message)
    if DLAPI then
        DLAPI.DebugLog("KeyCount", message)
    end
end

function printf(msg, fmt)
    fmt = fmt or KeyCount.defaults.colors.chatAnnounce
    print(string.format("%s%s|r", fmt, msg))
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

local function parseMsg(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    return key, value
end

local function formatTimestamp(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function sumTbl(tbl)
    if type(tbl) ~= "table" then return end
    local res = 0
    for k, v in pairs(tbl) do
        if type(v) == "number" then
            res = res + v
        end
    end
    return res
end

local function convertRgb(colorTable)
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

local function orderListByPlayer(dungeons)
    local dl = {}
    for _, dungeon in pairs(dungeons) do
        local player = dungeon.player
        if not dl[player] then dl[player] = {} end
        table.insert(dl[player], dungeon)
    end
    return dl
end

local function concatTable(table, delimiter)
    local concatenatedString = ""
    for i, value in ipairs(table) do
        concatenatedString = concatenatedString .. tostring(value)
        if i < #table then
            concatenatedString = concatenatedString .. delimiter
        end
    end
    return concatenatedString
end

local function convertOldPartyFormat(_party, _deaths)
    local party = {}
    local deaths = _deaths or {}
    for k, v in pairs(_party) do
        if type(k) == "number" then
            party[v.name] = v
        else
            party[k] = v
        end
    end
    if type(deaths) == "table" then
        for player, _ in pairs(party) do
            party[player].deaths = deaths[player] or 0
        end
    end
    return party
end

local function convertOldDateFormat(date)
    local res = {}
    if not date or date == "1900-01-01" then
        res = { date = "1900-01-01", datetime = "1900-01-01 00:00:00", datestring = "" }
    elseif #date == 10 and type(date) ~= table then
        res = { date = date, datetime = string.format("%s 00:00:00", date) }
    elseif type(date) == "table" then
        res = {
            date = date.date or "1900-01-01",
            datetime = date.datetime or "1900-01-01 00:00:00",
            datestring = date.datestring or ""
        }
    else
        res = KeyCount.defaults.dungeonDefault.date
    end
    return res
end

local function colorText(text, color)
    return color..text..KeyCount.defaults.colors.reset
end

local function getKeyForValue(t, value)
    for k,v in pairs(t) do
      if v==value then return k end
    end
    return nil
  end

KeyCount.util = {
    parseMsg=parseMsg,
    formatTimestamp=formatTimestamp,
    sumTbl=sumTbl,
    convertRgb=convertRgb,
    orderListByPlayer=orderListByPlayer,
    convertOldDateFormat=convertOldDateFormat,
    convertOldPartyFormat=convertOldPartyFormat,
    concatTable=concatTable,
    colorText=colorText,
    getKeyForValue=getKeyForValue,
}
