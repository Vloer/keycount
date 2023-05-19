local colors = {
    red = { chat = "|cffff3333", rgb = { r = 255, g = 51, b = 51, a = 1 } },
    green = { chat = "|cff00ff00", rgb = { r = 0, g = 0, b = 0, a = 1 } },
    yellow = { chat = "|cffcccc00", rgb = { r = 204, g = 204, b = 0, a = 1 } },
    blue = { chat = "|cff0000ff", rgb = { r = 0, g = 0, b = 255, a = 1 } },
    magenta = { chat = "|cffff00ff", rgb = { r = 255, g = 0, b = 255, a = 1 } },
    cyan = { chat = "|cff00e5e5", rgb = { r = 0, g = 229, b = 229, a = 1 } },
    orange = { chat = "|cffffa700", rgb = { r = 255, g = 167, b = 0, a = 1 } },
    yellow2 = { chat = "|cfffff400", rgb = { r = 255, g = 244, b = 0, a = 1 } },
    lightgreen = { chat = "|cffa3ff00", rgb = { r = 163, g = 255, b = 0, a = 1 } },
    darkgreen = { chat = "|cff2cba00", rgb = { r = 44, g = 186, b = 0, a = 1 } },
    reset = "|r"
}
local seasons = {
    Dragonflight = {
        "Dragonflight-1",
        "Dragonflight-2"
    }
}
local defaults = {
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
        season = seasons.Dragonflight[2],
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
            affixes = {},
            timeLimit = 0,
        },
        date = { ["date"] = "", ["datestring"] = "", ["datetime"] = "" },
        stars = ""
    },
    colors = {
        chatAnnounce = colors.cyan.chat,
        chatWarning = colors.yellow.chat,
        chatError = colors.red.chat,
        chatSuccess = colors.green.chat,
        chatRating = {
            colors.red.chat,
            colors.orange.chat,
            colors.yellow2.chat,
            colors.lightgreen.chat,
            colors.darkgreen.chat,
        },
        rating = {
            colors.red.rgb,
            colors.orange.rgb,
            colors.yellow2.rgb,
            colors.lightgreen.rgb,
            colors.darkgreen.rgb,
        }
    },
    dateFormat = "%Y-%m-%d",
    datetimeFormat = "%Y-%m-%d %H:%M:%S",
    gui = {
        filterType = "list",
        filter = "alldata"
    },
    filter = { key = "alldata", value = "" },
    dungeonPlusChar = "*"
}

KeyCount.defaults = defaults