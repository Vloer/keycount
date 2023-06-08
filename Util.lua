function Log(message)
    if DLAPI then
        DLAPI.DebugLog("KeyCount", message)
    end
end

---Prints a colored chat message
---@param msg string Message to print
---@param fmt string|nil Color format (default cyan)
---@param includeKeycount boolean|nil Set to true to add "Keycount: " to start of the message (default false)
function printf(msg, fmt, includeKeycount)
    fmt = fmt or KeyCount.defaults.colors.chatAnnounce
    includeKeycount = includeKeycount or false
    if includeKeycount then
        print(string.format("%sKeyCount: %s%s|r", KeyCount.defaults.colors.chatAnnounce, fmt, msg))
    else
        print(string.format("%s%s|r", fmt, msg))
    end
end

local function pack(...)
    return { n = select("#", ...), ... }
end

KeyCount.util.welcomeMessage = function(name)
    local s = KeyCountDB.sessions
    local num
    if s == 3 then
        num = "third"
    elseif s == 2 then
        num = "second"
    elseif s == 1 then
        num = "first"
    else
        num = s .. "th"
    end
    printf(string.format("Loaded %s for the %s time.", name, num))
end

-- Call this function to ensure that the code after it is still executed
---@param name string Name to display in print statement
---@param func function Function to executed
---@param ... any Function arguments seperated by comma
---@return any|boolean Result First result is the result of execution (bool), following results are the outcome(s) of the called function
KeyCount.util.safeExec = function(name, func, ...)
    local result = pack(pcall(func, ...))
    -- local success, result = pcall(func, ...)
    local success = result[1]
    if success then
        return unpack(result)
    end
    print(string.format(
        "%sKeyCount: %sWarning! an error occurred in function '%s'! Data may not be correct, check your SavedVariables file.%s",
        KeyCount.defaults.colors.chatAnnounce, KeyCount.defaults.colors.chatError, name, KeyCount.defaults.colors.reset))
    print(string.format("%sKeyCount: %sError: %s%s. Please report the error on the addon's curse page.",
        KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatError, result, KeyCount.defaults.colors.reset))
    return success
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

KeyCount.util.parseMsg = function(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    return key, value
end

KeyCount.util.formatTimestamp = function(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

KeyCount.util.formatK = function(num)
    num = tonumber(num)
    if num >= 1000 then
        local formatted = string.format("%.1fK", num / 1000)
        return formatted
    else
        return tostring(num)
    end
end

KeyCount.util.sumTbl = function(tbl)
    if type(tbl) ~= "table" then return end
    local res = 0
    for k, v in pairs(tbl) do
        if type(v) == "number" then
            res = res + v
        end
    end
    return res
end

KeyCount.util.convertRgb = function(colorTable)
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

KeyCount.util.orderListByPlayer = function(dungeons)
    local dl = {}
    for _, dungeon in pairs(dungeons) do
        local player = dungeon.player
        if not dl[player] then dl[player] = {} end
        table.insert(dl[player], dungeon)
    end
    return dl
end

KeyCount.util.concatTable = function(table, delimiter)
    local concatenatedString = ""
    for i, value in ipairs(table) do
        concatenatedString = concatenatedString .. tostring(value)
        if i < #table then
            concatenatedString = concatenatedString .. delimiter
        end
    end
    return concatenatedString
end

KeyCount.util.colorText = function(text, color)
    return color .. text .. KeyCount.defaults.colors.reset
end

KeyCount.util.getKeyForValue = function(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end


-- Add symbol to the end of a string
---@param text string Base string
---@param amount number Amount of symbols to add
---@param symbol string|nil Symbol to add. Defaults to *
---@param color string|nil Formatted color hex string. Defaults to gold
KeyCount.util.addSymbol = function(text, amount, symbol, color)
    color = color or KeyCount.defaults.colors.gold.chat
    symbol = symbol or KeyCount.defaults.dungeonPlusChar
    local symbols = KeyCount.util.colorText(symbol:rep(amount), color)
    return text .. symbols
end

-- Print all key,value pairs to the log
---@param table table Data
---@param name string Name of the table or function to display
KeyCount.util.printTableOnSameLine = function(table, name)
    local output = ""
    name = name or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            output = output .. key .. ": " .. type(value) .. ", "
        else
            output = output .. key .. ": " .. tostring(value) .. ", "
        end
    end
    output = output:sub(1, -3)
    Log(string.format("%s: %s", name, output))
end

-- Calculate the median of a list of values
---@param list table List that should not contain nil or nan values
KeyCount.util.calculateMedian = function(list)
    table.sort(list)

    local length = #list
    local middleIndex = math.floor(length / 2)

    if length % 2 == 1 then
        return list[middleIndex + 1]
    else
        return math.ceil((list[middleIndex] + list[middleIndex + 1]) / 2)
    end
end

-- Extract all values of a single key in a list of tables
---@param tbl table The list of tables too look in
---@param key string The key in the table to get data from
---@return table|nil ListOfValues
KeyCount.util.getListOfValues = function(tbl, key)
    local res = {}
    for _, data in ipairs(tbl) do
        local d = data[key]
        if d then table.insert(res, d) end
    end
    if not next(res) then return nil end
    return res
end
