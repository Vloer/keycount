GUI = {}
function GUI:ConstructGUI()
    self.widgets = {}
    self.tables = {}
    self.boxes = {}
    self.buttons = {}
    self.dungeons = {}
    self.data = {}
    local AceGUI = LibStub("AceGUI-3.0")

    local function resetFilters()
        self.key = ""
        self.value = ""
        self.filter = FilterKeys[Defaults.gui.filter]
        self.filtertype = Defaults.gui.filterType
    end

    resetFilters()

    local function disableFilters(setting)
        self.boxes.filterKey:SetDisabled(setting)
        self.boxes.filterKey:SetText("")
        self.widgets.filterValue:SetDisabled(setting)
        self.widgets.filterValue:SetText("")
    end

    local function setFilterKeyValue()
        self.boxes.filterKey:SetText(self.filter.name)
        self.boxes.filterKey:SetValue(self.filter.key)
        self.widgets.filterValue:SetText(self.value)
    end

    local function resetFilterValue()
        self.widgets.filterValue:SetText("")
        self.value = ""
    end

    local function fillTable()
        --@debug@
        Log(string.format("fillTable: Calling filterfunc with [%s] [%s] [%s]", self.filtertype, tostring(self.key), tostring(self.value)))
        --@end-debug@
        self.dungeons = FilterFunc[self.filtertype](self.key, self.value)
        if not self.dungeons then return end
        self.data = PrepareData[self.filtertype](self.dungeons)
        if self.filtertype == "rate" then
            self.tables.stL:Hide()
            self.tables.stR:Show()
            self.tables.stR:SetData(self.data)
            self.tables.stR:Refresh()
        else
            self.tables.stR:Hide()
            self.tables.stL:Show()
            self.tables.stL:SetData(self.data)
            self.tables.stL:Refresh()
        end
    end

    local function c_FilterType(item)
        self.filtertype = item
        if self.filtertype == "list" then
            disableFilters(true)
            self.tables.stR:Hide()
            self.tables.stL:Show()
            self.buttons.exportdata:SetDisabled(false)
        else
            disableFilters(false)
            setFilterKeyValue()
            self.key = self.filter.value
            if self.filtertype == "filter" then
                self.tables.stR:Hide()
                self.tables.stL:Show()
                self.buttons.exportdata:SetDisabled(false)
            else --rate
                self.tables.stL:Hide()
                self.tables.stR:Show()
                self.buttons.exportdata:SetDisabled(true)
            end
        end
    end

    local function c_FilterKey(item)
        self.filter = FilterKeys[item]
        self.boxes.filterKey:SetText(self.filter.name)
        self.key = self.filter.value
        resetFilterValue()
    end

    local function c_FilterValue(text)
        self.value = text
    end

    local function c_ShowData()
        if self.filtertype == "list" then
            self.key = ""
            self.value = ""
        else
            setFilterKeyValue()
        end
        fillTable()
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("KeyCount")
    frame:SetStatusText("Retrieve some data for your mythic+ runs!")
    frame:SetWidth(850)
    frame:SetHeight(420)
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        resetFilters()
    end)
    frame:SetLayout("Flow")

    self.boxes.filterType = AceGUI:Create("Dropdown")
    self.boxes.filterType:SetLabel("Filter type")
    self.boxes.filterType:SetWidth(100)
    self.boxes.filterType:AddItem("list", "All data")
    self.boxes.filterType:AddItem("filter", "Filter")
    self.boxes.filterType:AddItem("rate", "Success rate")
    self.boxes.filterType:SetCallback("OnValueChanged", function(widget, event, item) c_FilterType(item) end)
    self.boxes.filterType:SetValue("list")
    frame:AddChild(self.boxes.filterType)

    self.boxes.filterKey = AceGUI:Create("Dropdown")
    self.boxes.filterKey:SetLabel("Filter key")
    self.boxes.filterKey:SetWidth(200)
    for f, v in pairs(FilterKeys) do
        self.boxes.filterKey:AddItem(f, v.name)
    end
    self.boxes.filterKey:SetCallback("OnValueChanged", function(widget, event, item) c_FilterKey(item) end)
    self.boxes.filterKey:SetDisabled(true)
    frame:AddChild(self.boxes.filterKey)

    self.widgets.filterValue = AceGUI:Create("EditBox")
    self.widgets.filterValue:SetLabel("Filter value")
    self.widgets.filterValue:SetWidth(200)
    self.widgets.filterValue:SetCallback("OnEnterPressed", function(widget, event, text) c_FilterValue(text) end)
    self.widgets.filterValue:SetDisabled(true)
    frame:AddChild(self.widgets.filterValue)

    self.buttons.showdata = AceGUI:Create("Button")
    self.buttons.showdata:SetText("Show data")
    self.buttons.showdata:SetWidth(140)
    self.buttons.showdata:SetCallback("OnClick", c_ShowData)
    frame:AddChild(self.buttons.showdata)

    self.buttons.exportdata = AceGUI:Create("Button")
    self.buttons.exportdata:SetText("Export data")
    self.buttons.exportdata:SetWidth(140)
    self.buttons.exportdata:SetCallback("OnClick", function() CreateDataExportFrame(self.dungeons) end)
    frame:AddChild(self.buttons.exportdata)

    -- Tables
    local window = frame.frame
    local ScrollingTable = LibStub("ScrollingTable");
    local columnsList = {
        { ["name"] = "Name",    ["width"] = 100 },
        { ["name"] = "Dungeon", ["width"] = 150, },
        { ["name"] = "Level",   ["width"] = 55, },
        { ["name"] = "Result",  ["width"] = 90, },
        { ["name"] = "Deaths",  ["width"] = 55,  ["defaultsort"] = "dsc" },
        { ["name"] = "Time",    ["width"] = 55, },
        { ["name"] = "Date",    ["width"] = 80, },
        { ["name"] = "Affixes", ["width"] = 200, },
    }
    local columnsRate = {
        { ["name"] = "Dungeon",      ["width"] = 150, },
        { ["name"] = "Success rate", ["width"] = 75, },
        { ["name"] = "In time",      ["width"] = 55,  color = ConvertRgb(Defaults.colors.rating[5]) },
        { ["name"] = "Out of time",  ["width"] = 75,  color = ConvertRgb(Defaults.colors.rating[3]) },
        { ["name"] = "Abandoned",    ["width"] = 60,  color = ConvertRgb(Defaults.colors.rating[1]) },
        { ["name"] = "Best",         ["width"] = 55, },
    }

    self.tables.stL = ScrollingTable:CreateST(columnsList, 16, 16, nil, window);
    self.tables.stL.frame:SetPoint("TOP", window, "TOP", 0, -100);
    self.tables.stL.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
    self.tables.stL:EnableSelection(true)
    self.tables.stL:Hide()

    self.tables.stR = ScrollingTable:CreateST(columnsRate, 8, 16, nil, window);
    self.tables.stR.frame:SetPoint("TOP", window, "TOP", 0, -100);
    self.tables.stR.frame:SetPoint("LEFT", window, "LEFT", 15, 0);
    self.tables.stR:EnableSelection(true)
    self.tables.stR:Hide()

    frame:SetCallback("OnClose", function()
        self.tables.stL:Hide()
        self.tables.stR:Hide()
    end)

    -- Required to exit interface on escape press
    _G["KeyCountFrame"] = frame.frame
    tinsert(UISpecialFrames, "KeyCountFrame")

    frame:Hide()
    return frame
end
