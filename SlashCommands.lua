SLASH_KEYCOUNT1 = "/keycount"
SLASH_KEYCOUNT2 = "/kc"
function SlashCmdList.KEYCOUNT()
    if not KeyCount.gui then
        print(" ")
        printf("KeyCount: ===WELCOME===")
        local dungeons = KeyCount:GetStoredDungeons()
        if dungeons then
            printf(string.format("There are %d dungeons stored in your database.", #dungeons))
        end
        printf("Type /kch or /kchelp for available options, or use the GUI (opens on this command).")
        printf("This message will be hidden from now on.")

        KeyCount.gui = GUI
    end
    KeyCount.gui.frame = KeyCount.gui:ConstructGUI()
    KeyCount.gui.frame:Show()
end

SLASH_KEYCOUNT_LIST1 = "/keycount_list"
SLASH_KEYCOUNT_LIST2 = "/kc_list"
SLASH_KEYCOUNT_LIST3 = "/kcl"
SLASH_KEYCOUNT_LIST4 = "/kclist"
function SlashCmdList.KEYCOUNT_LIST()
    print(" ")
    printf("===PRINTING DUNGEONS===", nil, true)
    KeyCount.filterfunctions.print.list()
end

SLASH_KEYCOUNT_FILTER1 = "/kcfilter"
SLASH_KEYCOUNT_FILTER2 = "/kcf"
function SlashCmdList.KEYCOUNT_FILTER(msg)
    print(" ")
    printf("===PRINTING DUNGEONS===", nil, true)
    local key, value = KeyCount.util.parseMsg(msg)
    KeyCount.filterfunctions.print.filter(key, value)
end

SLASH_KEYCOUNT_PLAYERSUCCESSRATE1 = "/kcplayer"
SLASH_KEYCOUNT_PLAYERSUCCESSRATE2 = "/kcp"
function SlashCmdList.KEYCOUNT_PLAYERSUCCESSRATE(msg)
    print(" ")
    local player = msg or ''
    if #player == 0 then
        printf('Invalid data supplied for player search!', KeyCount.defaults.colors.chatWarning, true)
    end
    KeyCount.filterfunctions.print.searchplayer(player, false)
end

SLASH_KEYCOUNT_PLAYERSUCCESSRATESUMMARY1 = "/kcsummary"
SLASH_KEYCOUNT_PLAYERSUCCESSRATESUMMARY2 = "/kcs"
function SlashCmdList.KEYCOUNT_PLAYERSUCCESSRATESUMMARY(msg)
    print(" ")
    local player = msg or ''
    if #player == 0 then
        printf('Invalid data supplied for player search!', KeyCount.defaults.colors.chatWarning, true)
    end
    KeyCount.filterfunctions.print.searchplayer(player, true)
end

SLASH_KEYCOUNT_SUCCESSRATE1 = "/kcrate"
SLASH_KEYCOUNT_SUCCESSRATE2 = "/kcr"
function SlashCmdList.KEYCOUNT_SUCCESSRATE(msg)
    print(" ")
    printf("===PRINTING STATS===", nil, true)
    local key, value = KeyCount.util.parseMsg(msg)
    KeyCount.filterfunctions.print.rate(key, value)
end

SLASH_KEYCOUNT_EXPORT1 = "/kcexport"
SLASH_KEYCOUNT_EXPORT2 = "/kce"
function SlashCmdList.KEYCOUNT_EXPORT(msg)
    print(" ")
    printf("===CREATING DATA EXPORT===", nil, true)
    KeyCount.exportdata.createFrame()
end

SLASH_KEYCOUNT_FAIL1 = "/kcfail"
function SlashCmdList.KEYCOUNT_FAIL(msg)
    KeyCount:SetKeyFailed()
end

SLASH_KEYCOUNT_HELP1 = "/kchelp"
SLASH_KEYCOUNT_HELP2 = "/kch"
function SlashCmdList.KEYCOUNT_HELP(msg)
    print(" ")
    printf("===OPTIONS===", nil, true)
    printf(" ")
    printf(" [/kcl]  |  [/kclist]")
    printf(" List all dungeons without filtering", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcf]  |  [/kcfilter]")
    printf(
        " List all dungeons with applied filter. You can filter for any key/value pair present in the dungeon object. Example:",
        KeyCount.defaults.colors.chatWarning)
    printf(" /kcf player YOURNAME", KeyCount.defaults.colors.chatWarning)
    printf(" For specific dungeon filtering, only type the dungeon abbreviation like so: ",
        KeyCount.defaults.colors.chatWarning)
    printf(" /kcf ULD", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcr]  |  [/kcrate]")
    printf(" Show the success rate of all dungeons. Can be paired with filters.", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kce]  |  [/kcexport]")
    printf(" Export all dungeon data to csv format", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcfail]")
    printf(" Set the current dungeon run to 'abandoned'.", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcp]  |  [/kcplayer]")
    printf(" Quickly look up a player's dungeon runs.", KeyCount.defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcs]  |  [/kcsummary]")
    printf(" Quickly look up a player's stat summary.", KeyCount.defaults.colors.chatWarning)
end

SLASH_KEYCOUNT_FILTEROPTS1 = "/kcfilteroptions"
SLASH_KEYCOUNT_FILTEROPTS2 = "/kco"
SLASH_KEYCOUNT_FILTEROPTS3 = "/kcoptions"
function SlashCmdList.KEYCOUNT_FILTEROPTS(msg)
    print(" ")
    printf("===FILTER OPTIONS===", nil, true)
    printf(" Format is /kcf or /kcrate <key> <value>")
    print(string.format("%s [<nothing>] %sDungeon name or abbreviation (ex: RLP)|r",
        KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [season] %sMythic+ season (ex: Dragonflight-1)|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [player] %sPlayer name|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [name] %sDungeon name|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [dungeon] %sDungeon name|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [completed] %sOnly completed runs|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [inTime] %sOnly runs completed in time|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [time] %sOnly runs longer than x seconds|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [deathsGT] %sOnly runs more than x deaths|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [deathsLT] %sOnly runs less than x deaths|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [level] %sOnly runs above specific level|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [date] %sSpecific date (format 1999-12-31)|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s [affix] %sSpecific affix (comma = AND, | = OR)|r", KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s Example: %saffix raging,quaking = raging AND quaking|r",
        KeyCount.defaults.colors.chatAnnounce,
        KeyCount.defaults.colors.chatWarning))
    print(string.format("%s Example: %saffix volcanic||necrotic = either volcanic or necrotic or both|r",
        KeyCount.defaults.colors.chatAnnounce, KeyCount.defaults.colors.chatWarning))
end
