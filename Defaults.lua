local colors = {
    red = "|cffff3333",
    green = "|cff00ff00",
    yellow = "|cffcccc00",
    blue = "|cff0000ff",
    magenta = "|cffff00ff",
    cyan = "|cff00e5e5",
    orange = "|cffffa700",
    yellow2 = "|cfffff400",
    lightgreen = "|cffa3ff00",
    darkgreen = "|cff2cba00",
    reset = "|r"
}
local seasons = {
    Dragonflight = {
        "Dragonflight-1",
        "Dragonflight-2"
    }
}
Defaults = {
    dungeonNamesShort = {
        AV = "The Azure Vault",
        RLP = "Ruby Life Pools",
        HOV = "Halls of Valor",
        NO = "The Nokhud Offensive",
        SBG = "Shadowmoon Burial Grounds",
        COS = "Court of Stars",
        TJS = "Temple of the Jade Serpent",
        AA = "Algeth'ar Academy",
        BH = "Brackenhide Hollow",
        HOI = "Halls of Infusion",
        NEL = "Neltharus",
        ULD = "Uldaman",
        FH = "Freehold",
        NL = "Neltharion's Lair",
        UR = "The Underrot",
        VP = "Vortex Pinnacle"
    },
    dungeonDefault = {
        season = seasons.Dragonflight[1],
        player = "",
        name = "",
        party = {},
        startedTimestamp = 0,
        completed = false,
        completedTimestamp = 0,
        completedInTime = false,
        timeToComplete = "",
        time = 0,
        deaths = {},
        totalDeaths = 0,
        keyDetails = {
            level = 0,
            affixes = {}
        },
        timeLimit = 0,
        date = ""
    },
    colors = {
        chatAnnounce = colors.cyan,
        chatWarning = colors.yellow,
        chatError = colors.red,
        chatSuccess = colors.green,
        rating = {
            colors.red,
            colors.orange,
            colors.yellow2,
            colors.lightgreen,
            colors.darkgreen
        }
    },
    dateFormat = "%Y-%m-%d",
    dateTimeFormat = "%Y-%m-%d %H:%M:%S"
}
