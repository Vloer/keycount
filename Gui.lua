GUI = {}
function GUI:ConstructGUI()
    self.key = ""
    self.value = ""
    self.filtertype = Defaults.guiDefaultFilterType
    self.widgets = {}
    self.tables = {}
    local fillTable = function()
        local dungs = FilterFunc[self.filtertype](self.key, self.value)
        if not dungs then return end
        local data = PrepareData[self.filtertype](dungs)
        if self.filtertype == "rate" then
            self.tables.stL:Hide()
            self.tables.stR:Show()
            self.tables.stR:SetData(data)
            self.tables.stR:Refresh()
        else
            self.tables.stR:Hide()
            self.tables.stL:Show()
            self.tables.stL:SetData(data)
            self.tables.stL:Refresh()
        end
    end

    local function disableWidgets(setting)
        for _, w in pairs(self.widgets) do
            w:SetDisabled(setting)
            w:SetText("")
        end
    end

    AceGUI = LibStub("AceGUI-3.0")
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("KeyCount")
    frame:SetStatusText("Retrieve some data for your mythic+ runs!")
    frame:SetWidth(750)
    frame:SetHeight(420)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    frame:SetLayout("Flow")

    local dropdownBox = AceGUI:Create("Dropdown")
    dropdownBox:SetLabel("Filter type")
    dropdownBox:SetWidth(100)
    dropdownBox:AddItem("list", "All data")
    dropdownBox:AddItem("filter", "Filter")
    dropdownBox:AddItem("rate", "Success rate")
    dropdownBox:SetCallback("OnValueChanged", function(widget, event, item)
        self.filtertype = item
        if item == "list" then
            disableWidgets(true)
            self.tables.stL:Show()
            self.tables.stR:Hide()
            self.key = ""
            self.value = ""
        else
            disableWidgets(false)
            if item == "filter" then
                self.tables.stL:Show()
                self.tables.stR:Hide()
            elseif item == "rate" then
                self.tables.stL:Hide()
                self.tables.stR:Show()
            end
        end
    end)
    dropdownBox:SetValue("list")
    frame:AddChild(dropdownBox)

    self.widgets.editboxKey = AceGUI:Create("EditBox")
    self.widgets.editboxKey:SetLabel("Filter key")
    self.widgets.editboxKey:SetWidth(200)
    self.widgets.editboxKey:SetCallback("OnEnterPressed", function(widget, event, text) self.key = text end)
    self.widgets.editboxKey:SetDisabled(true)
    frame:AddChild(self.widgets.editboxKey)

    self.widgets.editboxVal = AceGUI:Create("EditBox")
    self.widgets.editboxVal:SetLabel("Filter value")
    self.widgets.editboxVal:SetWidth(200)
    self.widgets.editboxVal:SetCallback("OnEnterPressed", function(widget, event, text) self.value = text end)
    self.widgets.editboxVal:SetDisabled(true)
    frame:AddChild(self.widgets.editboxVal)

    local button = AceGUI:Create("Button")
    button:SetText("Show data")
    button:SetWidth(185)
    button:SetCallback("OnClick", fillTable)
    frame:AddChild(button)

    -- Tables
    local window = frame.frame
    local ScrollingTable = LibStub("ScrollingTable");
    local columnsList = {
        { ["name"] = "Name",    ["width"] = 100 },
        { ["name"] = "Dungeon", ["width"] = 150, },
        { ["name"] = "Level",   ["width"] = 55, },
        { ["name"] = "Result",  ["width"] = 90, },
        { ["name"] = "Deaths",  ["width"] = 55,  ["defaultsort"] = "dsc" },
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
