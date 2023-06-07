local function flatten(data)
    local out = {}
    for col, v in pairs(data) do
        if col == "deaths" then
            --
        elseif col == "keydata" and type(v) == "table" then
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
            local partydata = v
            local i = 0
            for playername, playerdata in pairs(partydata) do
                i = i + 1
                for playerkey, playerval in pairs(playerdata) do
                    if type(playerval) == "table" then
                        for playervalkey, playervalval in pairs(playerval) do
                            local colname = string.format("party_%s_%s_%d", playerkey, playervalkey, i)
                            out[colname] = playervalval
                        end
                    else
                        local colname = string.format("party_%s_%d", playerkey, i)
                        out[colname] = playerval
                    end
                end
            end
        elseif col == "date" and type(v) == "table" then
            out[col] = v.datetime
        elseif col == "keyresult" and type(v) == "table" then
            out[col] = v.name
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
        { enabled = true, name = "player",                value = "player" },
        { enabled = true, name = "dungeon",               value = "name" },
        { enabled = true, name = "level",                 value = "level" },
        { enabled = true, name = "result",                value = "keyresult" },
        { enabled = true, name = "timelimit",             value = "timelimit" },
        { enabled = true, name = "time",                  value = "time" },
        { enabled = true, name = "affixes",               value = "affixes" },
        { enabled = true, name = "deaths",                value = "totalDeaths" },
        { enabled = true, name = "date",                  value = "date" },
        { enabled = true, name = "season",                value = "season" },
        { enabled = true, name = "party_name_1",          value = "party_name_1" },
        { enabled = true, name = "party_name_2",          value = "party_name_2" },
        { enabled = true, name = "party_name_3",          value = "party_name_3" },
        { enabled = true, name = "party_name_4",          value = "party_name_4" },
        { enabled = true, name = "party_name_5",          value = "party_name_5" },
        { enabled = true, name = "party_role_1",          value = "party_role_1" },
        { enabled = true, name = "party_role_2",          value = "party_role_2" },
        { enabled = true, name = "party_role_3",          value = "party_role_3" },
        { enabled = true, name = "party_role_4",          value = "party_role_4" },
        { enabled = true, name = "party_role_5",          value = "party_role_5" },
        { enabled = true, name = "party_class_1",         value = "party_class_1" },
        { enabled = true, name = "party_class_2",         value = "party_class_2" },
        { enabled = true, name = "party_class_3",         value = "party_class_3" },
        { enabled = true, name = "party_class_4",         value = "party_class_4" },
        { enabled = true, name = "party_class_5",         value = "party_class_5" },
        { enabled = true, name = "party_deaths_1",        value = "party_deaths_1" },
        { enabled = true, name = "party_deaths_2",        value = "party_deaths_2" },
        { enabled = true, name = "party_deaths_3",        value = "party_deaths_3" },
        { enabled = true, name = "party_deaths_4",        value = "party_deaths_4" },
        { enabled = true, name = "party_deaths_5",        value = "party_deaths_5" },
        { enabled = true, name = "party_damage_total_1",  value = "party_damage_total_1" },
        { enabled = true, name = "party_damage_total_2",  value = "party_damage_total_2" },
        { enabled = true, name = "party_damage_total_3",  value = "party_damage_total_3" },
        { enabled = true, name = "party_damage_total_4",  value = "party_damage_total_4" },
        { enabled = true, name = "party_damage_total_5",  value = "party_damage_total_5" },
        { enabled = true, name = "party_damage_dps_1",    value = "party_damage_dps_1" },
        { enabled = true, name = "party_damage_dps_2",    value = "party_damage_dps_2" },
        { enabled = true, name = "party_damage_dps_3",    value = "party_damage_dps_3" },
        { enabled = true, name = "party_damage_dps_4",    value = "party_damage_dps_4" },
        { enabled = true, name = "party_damage_dps_5",    value = "party_damage_dps_5" },
        { enabled = true, name = "party_healing_total_1", value = "party_healing_total_1" },
        { enabled = true, name = "party_healing_total_2", value = "party_healing_total_2" },
        { enabled = true, name = "party_healing_total_3", value = "party_healing_total_3" },
        { enabled = true, name = "party_healing_total_4", value = "party_healing_total_4" },
        { enabled = true, name = "party_healing_total_5", value = "party_healing_total_5" },
        { enabled = true, name = "party_healing_hps_1",   value = "party_healing_hps_1" },
        { enabled = true, name = "party_healing_hps_2",   value = "party_healing_hps_2" },
        { enabled = true, name = "party_healing_hps_3",   value = "party_healing_hps_3" },
        { enabled = true, name = "party_healing_hps_4",   value = "party_healing_hps_4" },
        { enabled = true, name = "party_healing_hps_5",   value = "party_healing_hps_5" },
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

function KeyCount.exportdata.createFrame(_data)
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
