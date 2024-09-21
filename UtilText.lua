KeyCount.utiltext.availablePlayerRoleAndIcon = {
    DAMAGER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:0:18:0:18|t',
    HEALER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:19:37:0:18|t',
    TANK = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:38:56:0:18|t'
}

KeyCount.utiltext.getSuccessRateColor = function(rate)
    local idx
    if rate == 0 then
        idx = 1
    elseif rate == 100 then
        idx = 5
    else
        idx = math.floor(rate / 20) + 1
        if idx <= 0 then idx = 1 end
    end
    return KeyCount.defaults.colors.rating[idx].chat
end

KeyCount.utiltext.getPlayerStatsString = function(data)
    local playerRoleString = ''
    for role, icon in pairs(KeyCount.utiltext.availablePlayerRoleAndIcon) do
        local _data = data[role] or nil
        if _data then
            local score = KeyCount.utilstats.calculatePlayerScore(_data.intime, _data.outtime, _data.abandoned, _data.median,
        _data.best)
            local rate = KeyCount.util.calculateSuccessRate(_data.intime, _data.outtime, _data.abandoned)
            local rateString = string.format("%.0f", rate)
            local color = KeyCount.utiltext.getSuccessRateColor(score)
            local msg = string.format('%s%s%% (%s/%s)%s ', color, rateString, _data.intime, _data.totalEntries, KeyCount.defaults.colors.reset)
            playerRoleString = playerRoleString .. icon .. msg
        end
    end
    return playerRoleString
end