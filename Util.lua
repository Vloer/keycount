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

KeyCount.util.welcomeMessage = function(name)
    local s = KeyCountDB.sessions or 0
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
    if s <= 5 or (s > 5 and KeyCount.util.checkIfPrintMessage(5)) then
        printf(string.format("Loaded %s for the %s time.", name, num))
    end
end

-- Call this function to ensure that the code after it is still executed
---@param name string Name to display in print statement
---@param func function Function to executed
---@param ... any Function arguments seperated by comma
---@return any|boolean Result First result is the result of execution (bool), following results are the outcome(s) of the called function
KeyCount.util.safeExec = function(name, func, ...)
    local pack = table.pack or function(...) return { n = select("#", ...), ... } end
    local unpack = table.unpack or unpack
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
        KeyCount.defaults.colors.chatError, result[2], KeyCount.defaults.colors.reset))
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
---@param table table|any Data
---@param name string|nil Name of the table or function to display
KeyCount.util.printTableOnSameLine = function(table, name)
    if type(table) ~= 'table' then return end
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
    Log(string.format("%s: %s", tostring(name), tostring(output)))
end

-- Calculate the median of a list of values
---@param list table List that should not contain nil or nan values
---@return integer median
KeyCount.util.calculateMedian = function(list)
    table.sort(list)

    local length = #list
    local middleIndex = math.floor(length / 2)
    if length % 2 == 1 then
        return list[middleIndex + 1]
    elseif length == 0 then
        return 0
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

---Checks if list contains an item
---@param item any Item to check for
---@param list table List to check in
---@return boolean R True if list contains item
KeyCount.util.listContainsItem = function(item, list)
    for _, i in ipairs(list) do
        if item == i then
            return true
        end
    end
    return false
end

---Generates a random UUID
---@return string UUID
KeyCount.util.uuid = function()
    local random = math.random
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return (string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end))
end

---Calculate dungeon success rate
---@param intime integer Timed dungeons
---@param outtime integer Out of time dungeons
---@param abandoned integer Abandoned dungeons
---@return number rate Success rate 0-100
KeyCount.util.calculateSuccessRate = function(intime, outtime, abandoned)
    local total = intime + outtime + abandoned
    if (abandoned + outtime) == 0 then
        return 100
    elseif intime == 0 then
        return 0
    else
        return intime / total * 100
    end
end

---Check if a table contains a set of keys
---@param tbl table Table to check for keys
---@param dataTable table Data table with required keys
KeyCount.util.checkKeysInTable = function(tbl, dataTable, additionalMsg)
    local _msg = additionalMsg or ''
    local keys = {}
    for k, v in pairs(dataTable) do
        table.insert(keys, k)
    end
    for _, key in ipairs(keys) do
        local msg = "'" .. key .. "' not found in the table"
        if #_msg > 0 then
            msg = "[" .. _msg .. "] " .. msg
        end
        if tbl[key] == nil then
            error(msg, 2)
        end
    end
end

---Adds own realm name to a character name if no realm is specified
---@param name string Name to edit
---@return string updatedName Name with realm attached
KeyCount.util.addRealmToName = function(name)
    local containsRealm = string.find(name, "-")
    if not containsRealm then
        local realm = GetRealmName()
        realm = string.gsub(realm, "%s+", "")
        name = name .. "-" .. realm
    end
    return name
end

---Formats supplied player role
---@param role string|nil Role to format
---@return string|nil formattedRole Options: TANK | HEALER | DAMAGER | nil
KeyCount.util.formatRole = function(role)
    if not role then return nil end
    local _role = nil
    if type(role) == "string" then
        _role = string.lower(role)
    end
    if _role == "dps" or _role == "damager" or _role == "damage" then
        _role = "DAMAGER"
    elseif _role == "tank" then
        _role = "TANK"
    elseif _role == "heal" or _role == "healer" or _role == "healing" then
        _role = "HEALER"
    else
        printf(string.format("Unknown role supplied: %s. Options are 'tank', 'heal' or 'dps'!", role),
            KeyCount.defaults.colors.chatWarning)
        return nil
    end
    return _role
end

---Get max of 2 numbers. Returns 0 if invalid arguments are supplied
---@param v1 number
---@param v2 number
---@return number highestNum
KeyCount.util.getMax = function(v1, v2)
    if type(v1) == "number" and type(v2) == "number" then
        if v1 > v2 then return v1 end
        return v2
    end
    return 0
end

---Split a string and return the first part
---@param s string String to split
---@param sep string|nil Separator. Defaults to '-'
---@return string All characters before the separator
KeyCount.util.splitString = function(s, sep)
    s = tostring(s) or ""
    sep = sep or "-"
    for part in s:gmatch("([^%-]+)") do
        return part
    end
end

---Return todays date in the default format yyyy-mm-dd
---@return string D Todays date
KeyCount.util.getDateToday = function()
    return date(KeyCount.defaults.dateFormat)
end

---Adds leading zeroes to a date if required
---@param date string
---@return string
KeyCount.util.normalizeDate = function(date)
    local year, month, day = date:match("(%d+)-(%d+)-(%d+)")

    if year and month and day then
        month = string.format("%02d", tonumber(month))
        day = string.format("%02d", tonumber(day))

        return year .. "-" .. month .. "-" .. day
    else
        return date
    end
end

---Converts a date string (yyyy-mm-dd) to a timestamp (epoch time)
---@param dateString string Formatted date string: yyyy-mm-dd
---@return integer timestamp Epoch time
KeyCount.util.dateToTimestamp = function(dateString)
    local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
    if not year or not month or not day then return 0 end
    local dateTable = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 0,
        min = 0,
        sec = 0,
        isdst = false,
    }
    return time(dateTable)
end

---Returns the date of the start of the week (adjusted for player locale)
---@return string StartOfWeek
KeyCount.util.getStartOfWeekDate = function()
    local now = C_DateAndTime.GetCurrentCalendarTime()
    local secsInWeek = 604800
    local secsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    local secsUntilWeekStart = secsInWeek - secsUntilReset
    local minsUntilWeekStart = math.floor(secsUntilWeekStart / 60)
    local start = C_DateAndTime.AdjustTimeByMinutes(now, -minsUntilWeekStart)
    local startDate = string.format("%s-%s-%s", start.year, start.month, start.monthDay)
    return KeyCount.util.normalizeDate(startDate)
end

---Gets a list of all dates in between start date and current date
---@param startDate string
---@return table ListOfDates
KeyCount.util.getAllDatesInRange = function(startDate)
    local dateList = {}
    local currentDate = "2024-01-20"
    local startYear, startMonth, startDay = startDate:match("(%d+)-(%d+)-(%d+)")
    local currentYear, currentMonth, currentDay = currentDate:match("(%d+)-(%d+)-(%d+)")

    if not startYear or not startMonth or not startDay then return dateList end

    startYear, startMonth, startDay = tonumber(startYear), tonumber(startMonth), tonumber(startDay)
    local iDate = string.format("%04d-%02d-%02d", startYear, startMonth, startDay)

    local maxDates = 10
    local i = 0

    while true do
        i = i + 1
        if i > maxDates then break end

        table.insert(dateList, iDate)
        local iYear, iMonth, iDay = iDate:match("(%d+)-(%d+)-(%d+)")

        if iYear == currentYear and iMonth == currentMonth and iDay == currentDay then
            break
        end

        iYear, iMonth, iDay = tonumber(iYear), tonumber(iMonth), tonumber(iDay)
        iDay = iDay + 1

        if iDay > 31 or (iMonth == 4 or iMonth == 6 or iMonth == 9 or iMonth == 11) and iDay > 30 or (iMonth == 2 and ((iYear % 4 == 0 and iYear % 100 ~= 0) or (iYear % 400 == 0)) and iDay > 29 or iDay > 28) then
            iDay = 1
            iMonth = iMonth + 1
        end

        if iMonth > 12 then
            iMonth = 1
            iYear = iYear + 1
        end

        iDate = string.format("%04d-%02d-%02d", iYear, iMonth, iDay)
    end

    return dateList
end

---Check if we have to print a message. Occurs once every 10 (default), or specified, addon loads
---@param freq number|nil
---@return boolean
KeyCount.util.checkIfPrintMessage = function(freq)
    local _freq = freq or KeyCount.defaults.databaseCheckMessageFreq or 0
    local sessions = KeyCountDB.sessions or 0
    return math.fmod(sessions, _freq) == 0
end

---Shows a popup ingame with the latest update message. Will trigger if the message being sent in KeyCount:InitSelf() is different from the message stored in the DB.
---@param msg string
KeyCount.util.checkUpdateMessage = function(msg)
    local oldMessage = KeyCountDB.updateMessage or ""
    if msg == oldMessage then return end
    StaticPopupDialogs["updateMessage"] = {
        text = string.format("%sKeyCount has been updated!\n--\n%s%s\n%s--|r", KeyCount.defaults.colors.chatAnnounce,
            KeyCount.defaults.colors.chatSuccess, msg, KeyCount.defaults.colors.chatAnnounce),
        button1 = OKAY,
        OnAccept = function()
            KeyCountDB.updateMessage = msg
            Log(string.format('updateMessage set to: %s', msg))
        end,
        timeout = 0,
        whileDead = true,
    }
    StaticPopup_Show("updateMessage")
end

---Converts all words in string to Titlecase
---@param s string|nil
KeyCount.util.titleCase = function(s)
    if not s then
        return ''
    end
    if type(s) ~= "string" then
        s = tostring(s)
    end
    s = string.lower(s)
    local titleCase = s:gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)
    return titleCase
end

---Get an index between 1 and 5 to use to decide which color to choose. Defaults to 1.
---@param num number Any number, usually success rate
---@return number index
KeyCount.util.getColorIdx = function(num)
    if type(num) ~= "number" then return 1 end
    local idx = math.floor(num / 20) + 1
    if idx > 5 then
        return 5
    end
    return idx
end

---Get the color format for a given level
---@param level number
---@return table T {color: contains rgb(a) values, hex: hex string that can be used in string formatting}
KeyCount.util.getLevelColor = function(level)
    local idx = 0
    if type(level) == "number" and level > 0 then
        idx = math.floor(level / 2.5) + 1
        if idx >= 6 then
            idx = 6
        end
    end
    local r, g, b, hex = GetItemQualityColor(idx)
    local color = { r = r, g = g, b = b, a = 1 }
    return { color = color, hex = hex }
end

---Checks if there is a new member in your party. Excludes yourself and players below max level
---@return table PlayerNames Names of the new members that joined. Only returned if we haven't seen them yet
KeyCount.util.findNewGroupMember = function()
    local players = {}
    for n=1, GetNumGroupMembers() do
        local pname, prealm  = UnitName("Party"..n)
        local plevel = UnitLevel("Party"..n)
        if pname and not KeyCount.util.listContainsItem(pname, KeyCount.playersInGroup) then
            table.insert(KeyCount.playersInGroup, pname)
            table.insert(players, pname)
        end
    end
    return players
end

---Count the amount of keys in a table that has k:v pairs instead of nameless entries.
---@param t table?
---@return number
KeyCount.util.countKeysInTable = function(t)
    if type(t) == "nil" then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end