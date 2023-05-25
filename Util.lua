local util = KeyCount.util

function Log(message)
    if DLAPI then
        DLAPI.DebugLog("KeyCount", message)
    end
end

---Prints a colored chat message
---@param msg string Message to print
---@param fmt string Color format. Defaults to cyan
function printf(msg, fmt)
    fmt = fmt or KeyCount.defaults.colors.chatAnnounce
    print(string.format("%s%s|r", fmt, msg))
end

-- Checks two tables for equality
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

--- Shallow copy: table.copy(destination_tbl, source_tbl)
---
--- Deep copy: destination_tbl = table.copy({}, source_tbl)
---@param destination table
---@param source table
---@return table
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

util.parseMsg = function(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    return key, value
end

util.formatTimestamp = function(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

util.formatK = function(num)
    num = tonumber(num)
    if num >= 1000 then
        local formatted = string.format("%.1fK", num / 1000)
        return formatted
    else
        return tostring(num)
    end
end

util.sumTbl = function(tbl)
    if type(tbl) ~= "table" then return end
    local res = 0
    for k, v in pairs(tbl) do
        if type(v) == "number" then
            res = res + v
        end
    end
    return res
end

util.convertRgb = function(colorTable)
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

util.orderListByPlayer = function(dungeons)
    local dl = {}
    for _, dungeon in pairs(dungeons) do
        local player = dungeon.player
        if not dl[player] then dl[player] = {} end
        table.insert(dl[player], dungeon)
    end
    return dl
end

util.concatTable = function(table, delimiter)
    local concatenatedString = ""
    for i, value in ipairs(table) do
        concatenatedString = concatenatedString .. tostring(value)
        if i < #table then
            concatenatedString = concatenatedString .. delimiter
        end
    end
    return concatenatedString
end

util.colorText = function(text, color)
    return color .. text .. KeyCount.defaults.colors.reset
end

util.getKeyForValue = function(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

-- Call this function to ensure that the code after it is still executed
---@param name string Name to display in print statement
---@param func function Function to executed
---@param ... any Function arguments seperated by comma
util.safeExec = function(name, func, ...)
    local success, result = pcall(func, ...)
    if success then
        return result
    end
    print(string.format(
        "%sKeyCount: %sWarning! an error occurred in function '%s'! Data may not be correct, check your SavedVariables file.%s",
        KeyCount.defaults.colors.chatAnnounce, KeyCount.defaults.colors.chatError, name, KeyCount.defaults.colors.reset))
    print(string.format("%sKeyCount: %sError: %s%s. Please report the error on the addon's curse page.",
        KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatError, result, KeyCount.defaults.colors.reset))
    return success
end

-- Add symbol to the end of a string
---@param text string Base string
---@param amount number Amount of symbols to add
---@param symbol string Symbol to add. Defaults to *
---@param color string Formatted color hex string. Defaults to gold
util.addSymbol = function(text, amount, symbol, color)
    color = color or KeyCount.defaults.colors.gold.chat
    symbol = symbol or KeyCount.defaults.dungeonPlusChar
    local symbols = util.colorText(symbol:rep(amount), color)
    return text .. symbols
end

-- Print all key,value pairs to the log
---@param table table Data
---@param name string Name of the table or function to display
util.printTableOnSameLine = function(table, name)
    local output = ""
    name = name or ""
    for key, value in pairs(table) do
        if type(value) == "string" then
            output = output .. key .. ": " .. value .. ", "
        else
            output = output .. key .. ": " .. type(value) .. ", "
        end
    end
    output = output:sub(1, -3)
    Log(string.format("%s: %s", name, output))
end

-- Calculate the median of a list of values
---@param list table List that should not contain nil or nan values
util.calculateMedian = function(list)
    table.sort(list)

    local length = #list
    local middleIndex = math.floor(length / 2)

    if length % 2 == 1 then
        return list[middleIndex + 1]
    else
        return math.ceil((list[middleIndex] + list[middleIndex + 1]) / 2)
    end
end
