KeyCount = CreateFrame("Frame", "KeyCount")
KeyCount.defaults = {}
KeyCount.exportdata = {}
KeyCount.filterfunctions = {}
KeyCount.filterkeys = {}
KeyCount.guipreparedata = {}
KeyCount.util = {}
KeyCount.utilstats = {}
KeyCount.details = {}
KeyCount.formatdata = {}

-- TODO player lookup shows wrong best dungeon - includes untimed dungeons
--

-- Event behaviour
function KeyCount:OnEvent(event, ...)
    self[event](self, event, ...)
end

function KeyCount:PLAYER_LOGOUT(event)
    -- Update current table in DB if it is not set to the default values
    KeyCount:SetUnknownToAbandoned()
    KeyCount:SaveAllPlayers(self.dungeons)
    KeyCount:SaveDungeons()
    if self.keystoneActive then KeyCountDB.keystoneActive = true else KeyCountDB.keystoneActive = false end
    if self.current and not table.equal(self.current, self.defaults.dungeonDefault) then
        table.copy(KeyCountDB.current, self.current)
    end
end

function KeyCount:ADDON_LOADED(event, addonName)
    if addonName == "KeyCount" then
        KeyCount:InitSelf()
        KeyCountDB.sessions = (KeyCountDB.sessions or 0) + 1
        KeyCount.util.welcomeMessage(addonName)
    end
end

function KeyCount:ZONE_CHANGED_NEW_AREA(event)
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end
    self.mapInfo = C_Map.GetMapInfo(mapID)
    KeyCount:CheckIfInDungeon()
end

function KeyCount:CHALLENGE_MODE_START(event, mapID)
    if self.keystoneActive then return end -- allow player to re-enter
    self.keystoneActive = true
    KeyCount:SetKeyStart()
end

function KeyCount:CHALLENGE_MODE_COMPLETED(event)
    KeyCount:SetKeyEnd()
end

function KeyCount:GROUP_LEFT(event)
    if not self.keystoneActive then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:GROUP_ROSTER_UPDATE(event)
    if not self.keystoneActive then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName =
        CombatLogGetCurrentEventInfo()
    if event == "UNIT_DIED" and UnitInParty(destName) then
        if AuraUtil.FindAuraByName("Feign Death", destName) then return end
        destName = KeyCount.util.addRealmToName(destName)
        self.current.deaths[destName] = (self.current.deaths[destName] or 0) + 1
        self.current.party[destName].deaths = (self.current.party[destName].deaths or 0) + 1
        printf(string.format("%s died!", destName), self.defaults.colors.chatError, true)
    end
end

-- Register events
function KeyCount:AddDungeonEvents()
    KeyCount:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    KeyCount:RegisterEvent("GROUP_ROSTER_UPDATE")
    KeyCount:RegisterEvent("GROUP_LEFT")
    KeyCount:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function KeyCount:RemoveDungeonEvents()
    KeyCount:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
    KeyCount:UnregisterEvent("GROUP_ROSTER_UPDATE")
    KeyCount:UnregisterEvent("GROUP_LEFT")
    KeyCount:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

KeyCount:RegisterEvent("PLAYER_LOGOUT")
KeyCount:RegisterEvent("ADDON_LOADED")
KeyCount:RegisterEvent("ZONE_CHANGED_NEW_AREA")
KeyCount:RegisterEvent("CHALLENGE_MODE_START")
KeyCount:SetScript("OnEvent", KeyCount.OnEvent)

function KeyCount:InitSelf()
    Log("Called InitSelf")
    self.party = self.party or {}
    self.current = self.current or table.copy({}, self.defaults.dungeonDefault)
    self.dungeons = self.dungeons or {}
    KeyCountDB = KeyCountDB or {}
    KeyCountDB.current = KeyCountDB.current or {}
    KeyCountDB.dungeons = KeyCountDB.dungeons or {}
    KeyCountDB.players = KeyCountDB.players or {}
    C_Timer.After(2, KeyCount.InitDatabase)
    C_Timer.After(3, KeyCount.InitPlayerList)
    if KeyCountDB.keystoneActive then self.keystoneActive = true else self.keystoneActive = false end
    if not table.equal(KeyCountDB.current, self.defaults.dungeonDefault) and self.keystoneActive then
        Log("Setting current dungeon to value from DB")
        table.copy(self.current, KeyCountDB.current)
    end
    local updateMessage = "·Defaulting to showing data for all seasons during the first week of the new season·"
    C_Timer.After(15, function() KeyCount.util.checkUpdateMessage(updateMessage) end)
    Log("Finished InitSelf")
end

function KeyCount:CheckIfInDungeon()
    Log("Called CheckIfInDungeon")
    -- For some reason dalaran has maptype dungeon
    if self.mapInfo and self.mapInfo.mapType == Enum.UIMapType.Dungeon and self.mapInfo.name ~= "Dalaran" and self.mapInfo.name ~= "Aberrus, the Shadowed Crucible" then
        Log("Entered dungeon: " .. self.mapInfo.name)
        KeyCount:InitDungeon()
    else
        Log("Finished CheckIfInDungeon")
    end
end

function KeyCount:InitDungeon()
    Log("Called InitDungeon")
    local keystoneStillRunning = C_ChallengeMode.IsChallengeModeActive()
    if self.keystoneActive then
        if not keystoneStillRunning then
            -- Likely reset instance without ending key
            KeyCount:FinishDungeon()
            return
        else
            Log("Keystone still active!")
            return
        end
    end
    if KeyCountDB.current ~= {} and not table.equal(self.current, self.defaults.dungeonDefault) then
        Log("Dungeon state restored from db")
        table.copy(self.current, KeyCountDB.current)
    else
        Log("Dungeon state set to default values")
        self.current = table.copy({}, self.defaults.dungeonDefault)
    end
    Log("Finished InitDungeon")
end

function KeyCount:SetKeyStart()
    Log("Called SetKeyStart")
    KeyCount:AddDungeonEvents()
    local activeKeystoneLevel, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
    local name, _, timelimit = C_ChallengeMode.GetMapUIInfo(challengeMapID)
    Log(string.format("Started %s on level %d.", name, activeKeystoneLevel))
    printf(string.format("started recording for %s %d.", name, activeKeystoneLevel), nil, true)
    self.current.keydata.name = name
    self.current.keydata.level = activeKeystoneLevel
    self.current.startedTimestamp = time()
    self.current.party = self:GetPartyMemberInfo()
    self.current.keydata.affixes = {}
    self.current.keydata.timelimit = timelimit
    self.current.name = name
    self.current.uuid = self.util.uuid()
    if self.current.player == "" then
        local playername = KeyCount.util.addRealmToName(UnitName("player"))
        self.current.player = playername
    end
    for _, affixID in ipairs(activeAffixIDs) do
        local affixName = C_ChallengeMode.GetAffixInfo(affixID)
        table.insert(self.current.keydata.affixes, affixName)
    end
    Log("Finished SetKeyStart")
end

function KeyCount:CheckIfKeyFailed(party)
    Log("Called CheckIfKeyFailed")
    if party == nil then party = self:GetPartyMemberInfo() end
    local partysize = 0
    for i in pairs(party) do partysize = partysize + 1 end
    if partysize < 5 then
        Log("Key failed!")
        return true
    end
    Log("Key not failed!")
end

function KeyCount:SetKeyFailed()
    if not self.keystoneActive then
        Log("SetKeyFailed was called but no dungeon is currently active")
        return
    end
    Log("Called SetKeyFailed")
    self.current.completedTimestamp = time()
    self.current.completed = false
    self.current.keyresult = self.defaults.keyresult.abandoned
    self.current.totalDeaths = self.util.sumTbl(self.current.deaths) or 0
    KeyCount:FinishDungeon()
    Log("Finished SetKeyFailed")
end

function KeyCount:SetKeyEnd()
    Log("Called SetKeyEnd")
    local mapChallengeModeID, level, finalTime, onTime, keystoneUpgradeLevels, practiceRun,
    oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord,
    PrimaryAffix, isEligibleForScore, members = C_ChallengeMode.GetCompletionInfo()
    self.keystoneActive = false
    local totalTime = math.floor(finalTime / 1000 + 0.5)
    self.current.completed = true
    self.current.completedTimestamp = time()
    if onTime then
        self.current.keyresult = self.defaults.keyresult.intime
    else
        self.current.keyresult = self.defaults.keyresult.outtime
    end
    self.current.time = totalTime
    self.current.totalDeaths = self.util.sumTbl(self.current.deaths) or 0
    if self.current.keydata.timelimit == 0 then
        _, _, self.current.keydata.timelimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
    end
    KeyCount.util.safeExec("SetDetailsData", KeyCount.SetDetailsData, KeyCount)
    KeyCount:FinishDungeon()
    Log("Finished SetKeyEnd")
end

function KeyCount:FinishDungeon()
    Log("Called FinishDungeon")
    self.keystoneActive = false
    KeyCountDB.keystoneActive = false
    KeyCount:SetTimeToComplete()
    Log(string.format("Key %s %s %s", self.current.name, self.current.keydata.level, self.current.timeToComplete))
    KeyCount:SaveAndReset()
    KeyCount:RemoveDungeonEvents()
    Log("Finished FinishDungeon")
end

function KeyCount:SetTimeToComplete()
    self.current.date = {
        date = date(self.defaults.dateFormat),
        datestring = date(),
        datetime = date(self.defaults.datetimeFormat)
    }
    if self.current.time == 0 then
        local timeStart = self.current.startedTimestamp
        local timeEnd = self.current.completedTimestamp
        if timeEnd == 0 then
            timeEnd = time()
        end
        local timeLost = select(2, C_ChallengeMode.GetDeathCount())
        if self.current.totalDeaths > 0 and timeLost == 0 then
            timeLost = self.current.totalDeaths * 5
        end
        -- Safety checks
        timeEnd = timeEnd or 0
        timeStart = timeStart or 0
        timeLost = timeLost or 0
        if timeStart == 0 or timeEnd == 0 then
            local errorMsg = string.format(
                "Error in collecting dungeon time. Dungeon time will not be saved. TimeStart (%s), TimeEnd (%s), TimeLost (%s). Please report the error to the author!", tostring(timeStart), tostring(timeEnd), tostring(timeLost))
            printf(errorMsg, KeyCount.defaults.colors.chatError, true)
            Log(errorMsg)
            self.current.time = 0
        else
            self.current.time = timeEnd - timeStart + timeLost
        end
    end
    self.current.timeToComplete = KeyCount.util.formatTimestamp(self.current.time)
    if self.current.keyresult.value == self.defaults.keyresult.intime.value then
        local s
        local symbol = self.defaults.dungeonPlusChar
        if self.current.time < (self.current.keydata.timelimit * 0.6) then
            s = symbol .. symbol .. symbol
        elseif self.current.time < (self.current.keydata.timelimit * 0.8) then
            s = symbol .. symbol
        else
            s = symbol
        end
        self.current.stars = s
    end
end

function KeyCount:SaveAndReset()
    Log("Called SaveAndReset")
    local cur = table.copy({}, self.current)                 --Required to pass by value instead of reference
    local def = table.copy({}, self.defaults.dungeonDefault) --Required to pass by value instead of reference
    table.insert(self.dungeons, cur)
    table.copy(self.current, def)
    KeyCountDB.current = {}
    Log("Finished SaveAndReset")
end

function KeyCount:SaveDungeons()
    for _, dungeon in ipairs(self.dungeons) do
        local name = dungeon.name or ""
        local details = dungeon.keydata or {}
        local level = details.level or 0
        printf(string.format("Inserting %s %s", name, level), nil, true)
        table.insert(KeyCountDB.dungeons, dungeon)
    end
    self.dungeons = {}
end

function KeyCount:InitDatabase()
    local dungeons = KeyCount:GetStoredDungeons()
    if dungeons then
        if KeyCount.util.checkIfPrintMessage() then
            printf("Checking database status", nil, true)
        end
        local stored = {}
        local amt = 0
        for i, d in ipairs(dungeons) do
            local funcresult, fixed, updated = KeyCount.util.safeExec("FormatData", KeyCount.formatdata.formatdungeon, d)
            if funcresult then
                if fixed then
                    table.insert(stored, fixed)
                end
                if updated then
                    amt = amt + 1
                end
            end
        end

        local msg = "Database check completed"
        if amt > 0 then
            msg = msg .. ": " .. amt .. " dungeons updated"
        end
        if KeyCount.util.checkIfPrintMessage() then
            printf(msg, nil, true)
        end
        if next(stored) ~= nil then
            KeyCountDB.dungeons = table.copy({}, stored)
        else
            printf('Formatted dungeon list is empty! Something likely went wrong, not saving to database!',
                KeyCount.defaults.colors.chatWarning, true)
        end
    end
end

function KeyCount:InitPlayerList()
    local players = KeyCountDB.players or {}
    local dungeons = KeyCount:GetStoredDungeons()
    local sessions = KeyCountDB.sessions or 0
    if KeyCount.util.checkIfPrintMessage() then
        printf("Checking player database", nil, true)
    end
    if not next(players) then
        if dungeons then
            KeyCount:SaveAllPlayers(dungeons)
        end
    else
        if dungeons then
            KeyCount.formatdata.formatplayers(dungeons, players)
        else
            if sessions > 10 then
                printf("ERROR could not initiate player database because no dungeons were found!",
                    KeyCount.defaults.colors.chatError, true)
            end
        end
    end
end

---Save data of a single player to the 'players' table
---@param players table Table to update
---@param player string Playername
---@param playerdata table Players data derived from party table (see defaults.partymember)
---@param dungeon table Dungeon data (see defaults.dungeonDefault)
---@return table players Updated players table
---@return boolean Updated True if new player was added to the player list
local function savePlayer(players, player, playerdata, dungeon)
    local role = playerdata.role
    local class = playerdata.class
    local season = dungeon.season or KeyCount.defaults.dungeonDefault.season
    local updated = false
    if not players[player] then
        --@debug@
        Log(string.format("Adding %s to list of players", player))
        --@end-debug@
        updated = true
        players[player] = {}
    end
    if not players[player][season] then
        players[player][season] = {}
    end
    if not players[player][season][role] then
        players[player][season][role] = table.copy({}, KeyCount.defaults.playerDefault)
    end
    local d = table.copy({}, players[player][season][role])
    d.player = player
    d.role = role
    d.class = class
    d.totalEntries = d.totalEntries + 1
    --@debug@
    Log(string.format("Changing totalEntries for player %s from %d to %d", player,
        d.totalEntries - 1, d.totalEntries))
    --@end-debug@
    local dps = KeyCount.utilstats.getPlayerDps(playerdata)
    local hps = KeyCount.utilstats.getPlayerHps(playerdata)
    d.maxdps = KeyCount.util.getMax(dps, d.maxdps)
    d.maxhps = KeyCount.util.getMax(hps, d.maxhps)

    -- Dungeons
    local keydata = dungeon.keydata
    local key = {
        name = keydata.name,
        level = keydata.level,
        affixes = keydata.affixes,
        result = dungeon.keyresult.value,
        resultstring = dungeon.keyresult.name,
        season = dungeon.season,
        damage = dungeon.party[player].damage,
        healing = dungeon.party[player].healing,
        uuid = dungeon.uuid,
        timeToComplete = dungeon.timeToComplete,
        deaths = playerdata.deaths or 0,
        date = dungeon.date.date
    }
    if key.result == KeyCount.defaults.keyresult.intime.value then
        d.intime = d.intime + 1
    elseif key.result == KeyCount.defaults.keyresult.outtime.value then
        d.outtime = d.outtime + 1
    elseif key.result == KeyCount.defaults.keyresult.abandoned.value then
        d.abandoned = d.abandoned + 1
    end
    table.insert(d.dungeons, key)

    -- Median and best key
    local dungeonlevels = KeyCount.util.getListOfValues(d.dungeons, "level")
    local median = d.median or 0
    local best = d.best or 0
    if dungeonlevels then
        median = KeyCount.util.calculateMedian(dungeonlevels)
        table.sort(dungeonlevels)
        best = dungeonlevels[#dungeonlevels]
    end
    d.median = median
    d.best = best

    players[player][season][role] = table.copy({}, d)
    return players, updated
end

---Sets any keyresults of 'Unknown' to 'Abandoned' (abandoned is correct but this is still bugged)
function KeyCount:SetUnknownToAbandoned()
    if not self.dungeons then return end
    for _, dungeon in ipairs(self.dungeons) do
        local keyresult = dungeon.keyresult or {}
        local value = keyresult.value or KeyCount.defaults.keyresult.unknown.value
        if value == KeyCount.defaults.keyresult.unknown.value then
            dungeon.keyresult = KeyCount.defaults.keyresult.abandoned
        end
    end
end

function KeyCount:SaveAllPlayers(dungeons)
    if not dungeons then return end
    local players = KeyCountDB.players or {}
    local amt = 0
    for _, dungeon in ipairs(dungeons) do
        local party = dungeon.party or {}
        for player, playerdata in pairs(party) do
            local funcresult, res, updated = KeyCount.util.safeExec("SavePlayer", savePlayer, players, player, playerdata,
                dungeon)
            if funcresult then
                if res then
                    players = res
                end
                if updated then
                    amt = amt + 1
                end
            end
        end
    end
    local msg = "Player database check completed"
    if amt > 0 then
        msg = msg .. ": " .. amt .. " players added to the database"
        printf(msg, nil, true)
    else
        print('checking')
        if KeyCount.util.checkIfPrintMessage() then
            print('true')
            printf(msg, nil, true)
        end
    end
    if next(players) ~= nil then
        KeyCountDB.players = table.copy({}, players)
    else
        printf('player list is empty, not saving to database!', KeyCount.defaults.colors.chatWarning, true)
    end
end

function KeyCount:GetPartyMemberInfo()
    local info = {}
    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers == 0 then
        info = self:GetPlayerInfo()
    else
        for i = 1, numGroupMembers do
            local _name, _, _, _, class, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
            local name = KeyCount.util.addRealmToName(_name)
            info[name] = { name = name, class = class, role = role }
        end
    end
    return info
end

function KeyCount:GetPlayerInfo()
    local specIndex = GetSpecialization()
    local _, spec, _, _, specRole = GetSpecializationInfo(specIndex)
    local _name = UnitName("player")
    local name = KeyCount.util.addRealmToName(_name)
    local class = UnitClass("player")
    local info = {}
    info[name] = {
        class = class,
        role = specRole,
        spec = spec,
        name = name
    }
    return info
end

---Get all dungeons in the database
---@return table|nil T Table of dungeons or nil if no dungeons found
function KeyCount:GetStoredDungeons()
    if not KeyCountDB or next(KeyCountDB) == nil or next(KeyCountDB.dungeons) == nil then
        printf("No dungeons stored!", KeyCount.defaults.colors.chatError, true)
        return nil
    end
    return KeyCountDB.dungeons
end

---Get data for all players stored in the database
---@return table|nil T Table of players or nil if no players found
function KeyCount:GetStoredPlayers()
    if not KeyCountDB or next(KeyCountDB) == nil or next(KeyCountDB.players) == nil then
        printf("No players stored!", KeyCount.defaults.colors.chatError, true)
        return nil
    end
    return KeyCountDB.players
end

function KeyCount:SetDetailsData()
    local detailsParty = self.details:getAll()
    if detailsParty then
        for player, data in pairs(detailsParty) do
            player = KeyCount.util.addRealmToName(player)
            local d = data.damage or {}
            local h = data.healing or {}
            local partyplayer = self.current.party[player] or {}
            if next(partyplayer) then
                self.current.party[player].damage = {
                    total = d.total or 0,
                    dps = d.dps or 0
                }
                self.current.party[player].healing = {
                    total = h.total or 0,
                    hps = h.hps or 0
                }
            else
                local ignore = false
                for _, ignored in ipairs(self.details.ignoreDungeonAbilities) do
                    if string.find(player, ignored) then
                        ignore = true
                        break
                    end
                end
                if not ignore then
                    printf(
                        string.format("Warning: something likely went wrong with the recording of Details data! [%s]",
                            player),
                        self.defaults.colors.chatError, true)
                end
            end
        end
        Log("Details data has been stored")
        self.details:resetCombat()
    end
end
