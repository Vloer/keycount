local function flatten(data)
    local out = {}
    for col, v in pairs(data) do
        if col == "deaths" then
            --
        elseif col == "keyDetails" and type(v) == "table" then
            for _k, _v in pairs(v) do
                if _k == "affixes" then
                    local affixstring = ""
                    for i, affix in ipairs(_v) do
                        if i == 1 then
                            affixstring = string.format("%s", affix)
                        else
                            affixstring = string.format("%s,%s", affixstring, affix)
                        end
                    end
                    _v = affixstring
                end
                out[_k] = _v
            end
        elseif col == "party" and type(v) == "table" then
            local partydata = KeyCount.util.convertOldPartyFormat(v, data["deaths"])
            local i = 0
            for playername, playerdata in pairs(partydata) do
                i = i + 1
                for playerkey, playerval in pairs(playerdata) do
                    local colname = string.format("party%s%d", playerkey, i)
                    out[colname] = playerval
                end
            end
        elseif col == "date" and type(v) == "table" then
            out[col] = v.datetime
        else
            out[col] = v
        end
    end
    return out
end

local function formatDungeonString(dataIn, cols, output)
    local enclosure = '"'
    local delimiter = ','
    local data = flatten(dataIn)
    local line = ""

    for _, v in ipairs(cols) do
        if v.enabled then
            local d = data[v.value] or ""
            if (type(d) == "string") then
                d = d:gsub(enclosure, enclosure .. enclosure)
            end

            if type(d) == "boolean" then
                d = tostring(d)
            end

            line = string.format("%1$s%2$s%4$s%2$s%3$s", line, enclosure, delimiter, d)
        end
    end

    output = string.format("%1$s%2$s\n", output, line:sub(1, -2))
    return output
end

local function formatCSV(_dungeons)
    local dungeons = _dungeons or KeyCount:GetStoredDungeons()
    local output = ""
    local columns = {
        { enabled = true, name = "player",       value = "player" },
        { enabled = true, name = "dungeon",      value = "name" },
        { enabled = true, name = "level",        value = "level" },
        { enabled = true, name = "completed",    value = "completed" },
        { enabled = true, name = "inTime",       value = "completedInTime" },
        { enabled = true, name = "timeLimit",    value = "timeLimit" },
        { enabled = true, name = "time",         value = "time" },
        { enabled = true, name = "affixes",      value = "affixes" },
        { enabled = true, name = "deaths",       value = "totalDeaths" },
        { enabled = true, name = "date",         value = "date" },
        { enabled = true, name = "partyname1",   value = "partyname1" },
        { enabled = true, name = "partyname2",   value = "partyname2" },
        { enabled = true, name = "partyname3",   value = "partyname3" },
        { enabled = true, name = "partyname4",   value = "partyname4" },
        { enabled = true, name = "partyname5",   value = "partyname5" },
        { enabled = true, name = "partyrole1",   value = "partyrole1" },
        { enabled = true, name = "partyrole2",   value = "partyrole2" },
        { enabled = true, name = "partyrole3",   value = "partyrole3" },
        { enabled = true, name = "partyrole4",   value = "partyrole4" },
        { enabled = true, name = "partyrole5",   value = "partyrole5" },
        { enabled = true, name = "partyclass1",  value = "partyclass1" },
        { enabled = true, name = "partyclass2",  value = "partyclass2" },
        { enabled = true, name = "partyclass3",  value = "partyclass3" },
        { enabled = true, name = "partyclass4",  value = "partyclass4" },
        { enabled = true, name = "partyclass5",  value = "partyclass5" },
        { enabled = true, name = "partydeaths1", value = "partydeaths1" },
        { enabled = true, name = "partydeaths2", value = "partydeaths2" },
        { enabled = true, name = "partydeaths3", value = "partydeaths3" },
        { enabled = true, name = "partydeaths4", value = "partydeaths4" },
        { enabled = true, name = "partydeaths5", value = "partydeaths5" },
    }
    for k, v in pairs(columns) do
        if v.enabled then
            output = string.format("%s,%s", output, v.name)
        end
    end
    output = string.format("%s\n", output:sub(2))
    for _, dungeon in ipairs(dungeons) do
        output = formatDungeonString(dungeon, columns, output)
    end

    return output
end
local function createDataExportFrame(_data)
    if not _data or next(_data) == nil or #_data == 0 then return end
    local data = formatCSV(_data)
    local AceGUI = LibStub("AceGUI-3.0")
    local f = AceGUI:Create("Frame")
    f:SetTitle("KeyCount")
    f:SetStatusText("Export your data!")
    f:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    f:SetLayout("Flow")

    local e = AceGUI:Create("MultiLineEditBox")
    e:SetFullWidth(true)
    e:SetFullHeight(true)
    e:SetLabel("Press control-c to copy your data")
    e:SetText(data)
    e:SetFocus()
    e:HighlightText()
    e:SetCallback("OnEnterPressed", function(widget)
        widget:HighlightText()
    end)
    f:AddChild(e)
end

KeyCount.exportdata = {
    createFrame = createDataExportFrame
}