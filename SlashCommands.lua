SLASH_KEYCOUNT1 = "/keycount"
SLASH_KEYCOUNT2 = "/kc"
function SlashCmdList.KEYCOUNT()
    print(" ")
    printf("KeyCount: ===WELCOME===")
    printf("Type /kch or /kchelp for available options!")
    local dungeons = GetStoredDungeons()
    if dungeons then
        printf(string.format("There are %d dungeons stored in your database.", #dungeons))
    end
end

SLASH_KEYCOUNT_LIST1 = "/keycount_list"
SLASH_KEYCOUNT_LIST2 = "/kc_list"
SLASH_KEYCOUNT_LIST3 = "/kcl"
SLASH_KEYCOUNT_LIST4 = "/kclist"
function SlashCmdList.KEYCOUNT_LIST()
    print(" ")
    local dungeons = GetStoredDungeons()
    local dl = {}
    if dungeons then
        printf("KeyCount: ===PRINTING DUNGEONS===")
        for _, dungeon in pairs(dungeons) do
            local player = dungeon.player
            if not dl[player] then dl[player] = {} end
            table.insert(dl[player], dungeon)
        end
        for _, dungeons in pairs(dl) do
            ListDungeons(dungeons)
        end
    end
end

SLASH_KEYCOUNT_FILTER1 = "/kcfilter"
SLASH_KEYCOUNT_FILTER2 = "/kcf"
function SlashCmdList.KEYCOUNT_FILTER(msg)
    print(" ")
    local key, value = ParseMsg(msg)
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        printf("KeyCount: ===PRINTING DUNGEONS===")
        local dungeons = Filter(_dungeons, key, value)
        ListDungeons(dungeons)
    end
end

SLASH_KEYCOUNT_SUCCESSRATE1 = "/kcrate"
function SlashCmdList.KEYCOUNT_SUCCESSRATE(msg)
    print(" ")
    printf("KeyCount: ===PRINTING STATS===")
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        local key, value = ParseMsg(msg)
        local dungeons = Filter(_dungeons, key, value)
        GetDungeonSuccessRate(dungeons)
    end
end

SLASH_KEYCOUNT_HELP1 = "/kchelp"
SLASH_KEYCOUNT_HELP2 = "/kch"
function SlashCmdList.KEYCOUNT_HELP(msg)
    print(" ")
    printf("KeyCount: ===OPTIONS===")
    printf(" ")
    printf(" [/kcl]  |  [/kclist]")
    printf(" List all dungeons without filtering", Defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcf]  |  [/kcfilter]")
    printf(" List all dungeons with applied filter. You can filter for any key/value pair present in the dungeon object. Example:",
    Defaults.colors.chatWarning)
    printf(" /kcf player YOURNAME", Defaults.colors.chatWarning)
    printf(" For specific dungeon filtering, only type the dungeon abbreviation like so: ",
    Defaults.colors.chatWarning)
    printf(" /kcf ULD", Defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcr]  |  [/kcrate]")
    printf(" Show the success rate of all dungeons. Can be paired with filters.", Defaults.colors.chatWarning)
end
