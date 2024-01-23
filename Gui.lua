GUI = {}
function GUI:ConstructGUI()
    self.widgets = {}
    self.tables = {}
    self.buttons = {}
    self.checkboxes = {}
    self.players = {}
    self.dungeons = {}
    self.data = {}
    self.dataPlayers = {}
    self.dataLoadedForExport = false
    self.key = ""
    self.value = ""
    self.filter = KeyCount.filterkeys[KeyCount.defaults.gui.filter]
    self.view = KeyCount.defaults.gui.view
    local AceGUI = LibStub("AceGUI-3.0")

    --#region Helper functions
    local function resetFilters()
        self.key = ""
        self.value = ""
        self.filter = KeyCount.filterkeys[KeyCount.defaults.gui.filter]
        self.view = KeyCount.defaults.gui.view
    end

    local function disableFilters(setting)
        self.widgets.filterKey:SetDisabled(setting)
        self.widgets.filterKey:SetText("")
        self.widgets.filterValue:SetDisabled(setting)
        self.widgets.filterValue:SetText("")
    end

    local function setFilterKeyValue()
        self.widgets.filterKey:SetText(self.filter.name)
        self.widgets.filterKey:SetValue(self.filter.key)
        self.widgets.filterValue:SetText(self.value)
    end

    local function resetFilterValue()
        self.widgets.filterValue:SetText("")
        self.value = ""
    end

    local function hideAllTables()
        self.tables.list:Hide()
        self.tables.grouped:Hide()
        self.tables.rate:Hide()
        self.tables.searchplayer.dungeons:Hide()
        self.tables.searchplayer.player:Hide()
    end

    ---Set the status text to the amount of dungeons in your filter result
    ---@param data table Data to be shown
    local function setStatusText(data)
        local len
        local txt
        if type(data) == "table" then
            len = #data or 0
        end
        if len > 0 then
            txt = string.format("Found %s results!", tostring(len))
        else
            txt = self.defaults.frame.defaultStatusText
        end
        self.frame:SetStatusText(txt)
    end

    local function showTableSetData(tbl, data)
        data = data or self.data
        tbl:Show()
        tbl:SetData(data)
        tbl:SortData()
        tbl:Refresh()
        setStatusText(data)
    end

    local function checkDisableFilterValue()
        if self.filter.key == "intime" or
            self.filter.key == "outtime" or
            self.filter.key == "abandoned" or
            self.filter.key == "completed" or
            self.filter.key == "currentweek" or
            self.filter.key == "alldata" then
            self.widgets.filterValue:SetDisabled(true)
        elseif self.view == self.views.searchplayer.type then
            self.filter.key = "player"
            self.widgets.filterKey:SetText(self.filter.name)
        else
            self.widgets.filterValue:SetDisabled(false)
        end
    end

    ---Disables or enables all checkboxes
    ---@param flag boolean True to disable
    local function disableCheckboxes(flag)
        self.checkboxes.character:SetDisabled(flag)
        self.checkboxes.currentweek:SetDisabled(flag)
        --self.checkboxes.currentseason:SetDisabled(flag)
        self.checkboxes.intime:SetDisabled(flag)
    end

    ---Applies additional filters to dataset based on active checkboxes
    ---@param data table
    ---@return table
    local function applyCheckboxFilters(data)
        --@debug@
        Log(string.format("Checkboxes: character %s, week %s, season %s, intime %s",
            tostring(self.checkboxes.character:GetValue()),
            tostring(self.checkboxes.currentweek:GetValue()),
            tostring(self.checkboxes.currentseason:GetValue()),
            tostring(self.checkboxes.intime:GetValue())
        ))
        --@end-debug@
        if self.checkboxes.character:GetValue() then
            data = KeyCount.filterfunctions.applyfilter(data, self.defaults.checkboxes.character.filter.key) or {}
        end
        if self.checkboxes.currentweek:GetValue() then
            data = KeyCount.filterfunctions.applyfilter(data, self.defaults.checkboxes.currentweek.filter.key) or {}
        end
        if self.checkboxes.currentseason:GetValue() then
            data = KeyCount.filterfunctions.applyfilter(data, self.defaults.checkboxes.currentseason.filter.key) or {}
        end
        if self.checkboxes.intime:GetValue() then
            data = KeyCount.filterfunctions.applyfilter(data, self.defaults.checkboxes.intime.filter.key) or {}
        end
        return data
    end

    local function fillTable()
        hideAllTables()
        --@debug@
        Log(string.format("fillTable: Calling filterfunc with [%s] [%s] [%s]", self.view, tostring(self.key),
            tostring(self.value)))
        --@end-debug@
        local dungeons = KeyCount:GetStoredDungeons() or {}
        if self.view == self.views.searchplayer.type then
            -- Check if current season checkbox is enabled
            local currentSeasonOrAll
            if self.checkboxes.currentseason:GetValue() then
                currentSeasonOrAll = KeyCount.defaults.dungeonDefault.season
            end
            self.players, self.dungeons = KeyCount.filterfunctions[self.view](self.key, self.value, currentSeasonOrAll)
            if self.players and self.dungeons then
                self.dataPlayers, self.data = KeyCount.guipreparedata[self.view](self.players, self.dungeons)
            else
                self.dataPlayers = {}
                self.data = {}
            end
        else
            dungeons = applyCheckboxFilters(dungeons)
            self.dungeons = KeyCount.filterfunctions[self.view](dungeons, self.key, self.value)
            if not self.dungeons then
                self.data = {}
            else
                --@debug@
                Log(string.format("Found %s dungeons after applying checkboxes", #self.dungeons))
                --@end-debug@
                self.data = KeyCount.guipreparedata[self.view](self.dungeons)
            end
        end
        --@debug@
        Log(string.format("Data has %s entries", #self.data))
        --@end-debug@
        if self.view == self.views.rate.type then
            showTableSetData(self.tables.rate)
        elseif self.view == self.views.grouped.type then
            showTableSetData(self.tables.grouped)
        elseif self.view == self.views.searchplayer.type then
            showTableSetData(self.tables.searchplayer.player, self.dataPlayers)
            showTableSetData(self.tables.searchplayer.dungeons, self.data)
        else
            showTableSetData(self.tables.list)
        end
        self.dataLoadedForExport = true
    end
    --#endregion

    --#region Callback functions
    local function c_ChangeView(item)
        hideAllTables()
        self.view = item
        self.dataLoadedForExport = false

        disableFilters(false)
        disableCheckboxes(false)
        setFilterKeyValue()
        self.key = self.filter.value
        if self.view == self.views.filter.type then
            self.tables.list:Show()
            self.buttons.exportdata:SetText("Export to CSV")
        elseif self.view == self.views.rate.type then
            self.tables.rate:Show()
            self.buttons.exportdata:SetText("Export to party")
        elseif self.view == self.views.grouped.type then
            self.tables.grouped:Show()
            self.buttons.exportdata:SetText("Export to party")
        elseif self.view == self.views.searchplayer.type then
            disableCheckboxes(true)
            self.tables.searchplayer.player:Show()
            self.tables.searchplayer.dungeons:Show()
            self.buttons.exportdata:SetText("")
            self.filter = KeyCount.filterkeys["player"]
            self.key = self.filter.value
            self.widgets.filterKey:SetText(self.filter.name)
            self.widgets.filterKey:SetDisabled(true)
            resetFilterValue()
        end
    end

    local function c_FilterKey(item)
        self.filter = KeyCount.filterkeys[item]
        self.widgets.filterKey:SetText(self.filter.name)
        self.key = self.filter.value
        resetFilterValue()
        checkDisableFilterValue()
    end

    local function c_FilterValue(text)
        self.value = text
    end

    local function c_ShowData()
        setFilterKeyValue()
        fillTable()
    end

    local function c_ExportData()
        if self.view == self.views.searchplayer.type then return end
        if not self.dataLoadedForExport then
            printf("No data is loaded to be exported! Press 'show data' first!",
                KeyCount.defaults.colors.chatWarning,
                true)
            return
        end
        if self.view == self.views.rate.type or self.view == self.views.grouped.type then
            KeyCount.utilstats.chatSuccessRate(self.dungeons)
        else
            KeyCount.exportdata.createFrame(self.dungeons)
        end
    end

    ---Callback function to enable current character only in filter view
    local function c_CharacterOnly(flag)
        c_ShowData()
    end

    ---Callback function to enable current week only in filter view
    local function c_CurrentWeekOnly(flag)
        c_ShowData()
    end

    ---Callback function to enable season week only in filter view
    local function c_CurrentSeasonOnly(flag)
        c_ShowData()
    end

    ---Callback function to enable in time only in filter view
    local function c_InTimeOnly(flag)
        c_ShowData()
    end
    --#endregion

    --#region Frames
    resetFilters()
    self.frame = AceGUI:Create("Frame")
    local frame = self.frame
    frame:SetTitle("KeyCount")
    frame:SetStatusText(self.defaults.frame.defaultStatusText)
    frame:SetWidth(self.defaults.frame.size.width)
    frame:SetHeight(self.defaults.frame.size.height)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        resetFilters()
    end)
    frame:SetCallback("OnClose", function()
        hideAllTables()
    end)
    --#endregion

    --#region Widgets
    self.widgets.view = AceGUI:Create("Dropdown")
    self.widgets.view:SetLabel(self.defaults.widgets.view.text)
    self.widgets.view:SetWidth(self.defaults.widgets.view.width)
    for _, view in ipairs(self.defaults.viewOrder) do
        self.widgets.view:AddItem(self.views[view].type, self.views[view].name)
    end
    self.widgets.view:SetValue(self.defaults.view)

    self.widgets.filterKey = AceGUI:Create("Dropdown")
    self.widgets.filterKey:SetLabel(self.defaults.widgets.filterKey.text)
    self.widgets.filterKey:SetWidth(self.defaults.widgets.filterKey.width)
    for _, key in pairs(KeyCount.filterorder) do
        local f = KeyCount.filterkeys[key].key
        local name = KeyCount.filterkeys[key].name
        self.widgets.filterKey:AddItem(f, name)
    end
    self.widgets.filterKey:SetDisabled(true)

    self.widgets.filterValue = AceGUI:Create("EditBox")
    self.widgets.filterValue:SetLabel(self.defaults.widgets.filterValue.text)
    self.widgets.filterValue:SetWidth(self.defaults.widgets.filterValue.width)
    self.widgets.filterValue:SetDisabled(true)

    self.checkboxes.character = AceGUI:Create("CheckBox")
    self.checkboxes.character:SetLabel(self.defaults.checkboxes.character.text)
    self.checkboxes.character:SetValue(self.defaults.checkboxes.character.state)

    self.checkboxes.currentweek = AceGUI:Create("CheckBox")
    self.checkboxes.currentweek:SetLabel(self.defaults.checkboxes.currentweek.text)
    self.checkboxes.currentweek:SetValue(self.defaults.checkboxes.currentweek.state)

    self.checkboxes.currentseason = AceGUI:Create("CheckBox")
    self.checkboxes.currentseason:SetLabel(self.defaults.checkboxes.currentseason.text)
    self.checkboxes.currentseason:SetValue(self.defaults.checkboxes.currentseason.state)

    self.checkboxes.intime = AceGUI:Create("CheckBox")
    self.checkboxes.intime:SetLabel(self.defaults.checkboxes.intime.text)
    self.checkboxes.intime:SetValue(self.defaults.checkboxes.intime.state)

    self.buttons.showdata = AceGUI:Create("Button")
    self.buttons.showdata:SetText(self.defaults.buttons.showdata.text)
    self.buttons.showdata:SetWidth(self.defaults.buttons.showdata.width)

    self.buttons.exportdata = AceGUI:Create("Button")
    self.buttons.exportdata:SetText(self.defaults.buttons.exportdata.text)
    self.buttons.exportdata:SetWidth(self.defaults.buttons.exportdata.width)

    self.widgets.view:SetCallback("OnValueChanged", function(widget, event, item) c_ChangeView(item) end)
    self.widgets.filterKey:SetCallback("OnValueChanged", function(widget, event, item) c_FilterKey(item) end)
    self.widgets.filterValue:SetCallback("OnEnterPressed", function(widget, event, text) c_FilterValue(text) end)
    self.buttons.showdata:SetCallback("OnClick", c_ShowData)
    self.buttons.exportdata:SetCallback("OnClick", c_ExportData)
    self.checkboxes.character:SetCallback("OnValueChanged", function(widget, event, value) c_CharacterOnly(value) end)
    self.checkboxes.currentweek:SetCallback("OnValueChanged", function(widget, event, value) c_CurrentWeekOnly(value) end)
    self.checkboxes.currentseason:SetCallback("OnValueChanged",
        function(widget, event, value) c_CurrentSeasonOnly(value) end)
    self.checkboxes.intime:SetCallback("OnValueChanged", function(widget, event, value) c_InTimeOnly(value) end)

    frame:AddChild(self.widgets.view)
    frame:AddChild(self.widgets.filterKey)
    frame:AddChild(self.widgets.filterValue)
    frame:AddChild(self.buttons.showdata)
    frame:AddChild(self.buttons.exportdata)
    frame:AddChild(self.checkboxes.character)
    frame:AddChild(self.checkboxes.currentweek)
    frame:AddChild(self.checkboxes.currentseason)
    frame:AddChild(self.checkboxes.intime)
    disableFilters(false)
    setFilterKeyValue()
    --#endregion

    --#region Tables
    local window = frame.frame
    local ScrollingTable = LibStub("ScrollingTable");
    --#region Table columns
    local columnsList = {
        { ["name"] = "Name",    ["width"] = 150 },
        { ["name"] = "Dungeon", ["width"] = 150, },
        { ["name"] = "Level",   ["width"] = 55, },
        { ["name"] = "Result",  ["width"] = 90, },
        { ["name"] = "Deaths",  ["width"] = 55, },
        { ["name"] = "Time",    ["width"] = 60, },
        { ["name"] = "Dps",     ["width"] = 55 },
        { ["name"] = "Date",    ["width"] = 90,  ["defaultsort"] = "dsc" },
        { ["name"] = "Affixes", ["width"] = 200, },
    }
    local columnsRate = {
        { ["name"] = "Dungeon",      ["width"] = 150, },
        { ["name"] = "Attempts",     ["width"] = 55, },
        { ["name"] = "Success rate", ["width"] = 75, },
        {
            ["name"] = KeyCount.defaults.keyresult.intime.name,
            ["width"] = 55,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [5].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.outtime.name,
            ["width"] = 75,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [3].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.abandoned.name,
            ["width"] = 60,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [1].rgb)
        },
        { ["name"] = "Best",    ["width"] = 55, },
        { ["name"] = "Median",  ["width"] = 55, },
        { ["name"] = "Max dps", ["width"] = 55, },
    }

    local columnsGrouped = {
        { ["name"] = "Player",       ["width"] = 150, },
        { ["name"] = "Score",        ["width"] = 55, },
        { ["name"] = "Amount",       ["width"] = 55, },
        { ["name"] = "Success rate", ["width"] = 75, },
        {
            ["name"] = KeyCount.defaults.keyresult.intime.name,
            ["width"] = 55,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [5].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.outtime.name,
            ["width"] = 75,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [3].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.abandoned.name,
            ["width"] = 60,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [1].rgb)
        },
        { ["name"] = "Best",    ["width"] = 55, },
        { ["name"] = "Median",  ["width"] = 55, },
        { ["name"] = "Max dps", ["width"] = 55, },
        { ["name"] = "Max hps", ["width"] = 55, },
    }

    local columnsSearchPlayerPlayer = {
        { ["name"] = "Player",       ["width"] = 150, },
        { ["name"] = "Score",        ["width"] = 55, },
        { ["name"] = "Amount",       ["width"] = 55, },
        { ["name"] = "Success rate", ["width"] = 75, },
        {
            ["name"] = KeyCount.defaults.keyresult.intime.name,
            ["width"] = 55,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [5].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.outtime.name,
            ["width"] = 75,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [3].rgb)
        },
        {
            ["name"] = KeyCount.defaults.keyresult.abandoned.name,
            ["width"] = 60,
            ["color"] = KeyCount.util.convertRgb(KeyCount.defaults.colors.rating
                [1].rgb)
        },
        { ["name"] = "Best",    ["width"] = 55, },
        { ["name"] = "Median",  ["width"] = 55, },
        { ["name"] = "Max dps", ["width"] = 55, },
        { ["name"] = "Max hps", ["width"] = 55, },
    }

    local columnsSearchPlayerDungeons = {
        { ["name"] = "Season",  ["width"] = 100, },
        { ["name"] = "Dungeon", ["width"] = 150, },
        { ["name"] = "Level",   ["width"] = 55, },
        { ["name"] = "Result",  ["width"] = 90, },
        { ["name"] = "Time",    ["width"] = 60, },
        { ["name"] = "Deaths",  ["width"] = 55, },
        { ["name"] = "Dps",     ["width"] = 55, },
        { ["name"] = "Hps",     ["width"] = 55, },
        { ["name"] = "Date",    ["width"] = 90, },
        { ["name"] = "Affixes", ["width"] = 200, },
    }
    --#endregion

    --#region Create tables
    self.tables.list = ScrollingTable:CreateST(columnsList, 16, 16, nil, window);
    self.tables.list.frame:SetPoint("TOP", window, "TOP", self.defaults.tables.anchors.top.x,
        self.defaults.tables.anchors.top.y);
    self.tables.list.frame:SetPoint("LEFT", window, "LEFT", self.defaults.tables.anchors.left.x,
        self.defaults.tables.anchors.left.y);
    self.tables.list:EnableSelection(true)
    self.tables.list:SortData()
    self.tables.list:Hide()

    self.tables.rate = ScrollingTable:CreateST(columnsRate, 16, 16, nil, window);
    self.tables.rate.frame:SetPoint("TOP", window, "TOP", self.defaults.tables.anchors.top.x,
        self.defaults.tables.anchors.top.y);
    self.tables.rate.frame:SetPoint("LEFT", window, "LEFT", self.defaults.tables.anchors.left.x,
        self.defaults.tables.anchors.left.y);
    self.tables.rate:EnableSelection(true)
    self.tables.rate:Hide()

    self.tables.grouped = ScrollingTable:CreateST(columnsGrouped, 16, 16, nil, window);
    self.tables.grouped.frame:SetPoint("TOP", window, "TOP", self.defaults.tables.anchors.top.x,
        self.defaults.tables.anchors.top.y);
    self.tables.grouped.frame:SetPoint("LEFT", window, "LEFT", self.defaults.tables.anchors.left.x,
        self.defaults.tables.anchors.left.y);
    self.tables.grouped:EnableSelection(true)
    self.tables.grouped:Hide()

    self.tables.searchplayer = {}
    self.tables.searchplayer.player = ScrollingTable:CreateST(columnsSearchPlayerPlayer, 3, 16, nil, window);
    self.tables.searchplayer.player.frame:SetPoint("TOP", window, "TOP", self.defaults.tables.anchors.top.x,
        self.defaults.tables.anchors.top.y);
    self.tables.searchplayer.player.frame:SetPoint("LEFT", window, "LEFT", self.defaults.tables.anchors.left.x,
        self.defaults.tables.anchors.left.y);
    self.tables.searchplayer.player:EnableSelection(true)
    self.tables.searchplayer.player:Hide()

    self.tables.searchplayer.dungeons = ScrollingTable:CreateST(columnsSearchPlayerDungeons, 11, 16, nil, window);
    self.tables.searchplayer.dungeons.frame:SetPoint("TOP", window, "TOP", self.defaults.tables.anchors.top.x, -210);
    self.tables.searchplayer.dungeons.frame:SetPoint("LEFT", window, "LEFT", self.defaults.tables.anchors.left.x,
        self.defaults.tables.anchors.left.y);
    self.tables.searchplayer.dungeons:EnableSelection(true)
    self.tables.searchplayer.dungeons:Hide()
    --#endregion
    --#endregion

    -- Required to exit interface on escape press
    _G["KeyCountFrame"] = frame.frame
    tinsert(UISpecialFrames, "KeyCountFrame")

    frame:Hide()
    return frame
end

GUI.defaults = {
    frame = {
        size = {
            height = 450,
            width = 1000,
        },
        defaultStatusText = "Retrieve some data for your mythic+ runs!"
    },
    widgets = {
        view = {
            width = 140,
            text = "Show view"
        },
        filterKey = {
            width = 200,
            text = "Filter key"
        },
        filterValue = {
            text = "Filter value",
            width = 200
        }
    },
    buttons = {
        exportdata = {
            width = 140,
            text = "Export to CSV"
        },
        showdata = {
            width = 140,
            text = "Show data"
        }
    },
    checkboxes = {
        character = {
            text = "Current character",
            state = false,
            filter = {
                key = "player",
                value = ""
            }
        },
        currentweek = {
            text = "Current week",
            state = false,
            filter = {
                key = "currentweek",
                value = ""
            }
        },
        currentseason = {
            text = "Current season",
            state = true,
            filter = {
                key = "season",
                value = KeyCount.defaults.dungeonDefault.season
            }
        },
        intime = {
            text = "Completed in time",
            state = false,
            filter = {
                key = "intime",
                value = ""
            }
        }
    },
    tables = {
        anchors = {
            top = {
                x = 0,
                y = -130
            },
            left = {
                x = 15,
                y = 0
            }
        }
    },
    view = "filter",
    viewOrder = { "filter", "rate", "grouped", "searchplayer" },
}

GUI.views = {
    filter = {
        type = "filter",
        name = "Filter"
    },
    rate = {
        type = "rate",
        name = "Success rate"
    },
    grouped = {
        type = "grouped",
        name = "Player success rate"
    },
    searchplayer = {
        type = "searchplayer",
        name = "Player lookup"
    },
}


g = GUI:ConstructGUI()
g:Show()
