function Log(message)
    if DLAPI then
        DLAPI.DebugLog(AddonName, message)
    end
end

function Filter(tbl, key, value)
    if #key == 0 and #value == 0 then return tbl end
    local result = {}
    if string.lower(key) == "name" and #value <= 3 then
        value = Defaults.dungeonNamesShort[value]
    end
    for _, entry in ipairs(tbl) do
        if string.lower(key) == "season" then
            if string.lower(entry[key]) == string.lower(value) then
                table.insert(result, entry)
            end
        else
            if string.lower(entry[key]) == string.lower(value) and entry["season"] == Defaults.dungeonDefault.season then
                table.insert(result, entry)
            end
        end
    end
    return result
end

function ParseMsg(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    if #value == 0 then
        value = key
        key = "name"
    end
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
        if type(value) == "table" and type(destination[key]) == "table" and destination[key] ~= {} then
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
