-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Dungeon zone boxes, kept deliberately separate from
-- Twm_ContinentMapID/TWM_MAPS and Twm_BattlegroundMapID/TWM_BATTLEGROUNDS
-- (own dropdown category, see this script's header). No MapID table:
-- same as arenas, these have no reliable UiMapID to back position
-- tracking or a continent-hint lookup with.
-- Twm_mapareas is the same generic per-map-name box registry every other
-- top-level map category already populates, derived from (in preference
-- order): valid-tile extent (Big coordinates, via TWM_Mini2Big_Coord's
-- own formula) when a real ADT tile grid exists; the union of
-- Twm_WMOTiles' own real tile corners (--wmo-tiles-file) for a pure-WMO
-- map (most dungeons/raids: a single global WMO, no ADT grid at all)
-- that has baked WMO minimap tiles -- guaranteed to match what actually
-- renders, since it's the same corner data; or, only when neither is
-- available, a coarser box from the WMO's own MOHD bounding box placed
-- by the WDT-level MODF -- see boxFromWdtGlobalPlacement's header. Only
-- the last of these depends on baked minimap art NOT existing --
-- Vanilla has none at all, so its dungeons/raids always use this path.
-- Twm_DungeonNames is resolved into the actual TWM_DUNGEONS dropdown
-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/
-- Twm_flightmasters' name tables -- see this file's own header comment.
-- `mapID` is Map.csv's own ID (a string) -- used by per-flavor visibility
-- lists such as Twm_SeasonOnlyMaps (Data_Vanilla/mapdata_seasons.lua).
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_DungeonNames = {
    {
        key = "Blackfathom",
        mapID = "48",
        expansion = "0",
        name = {
            enUS = "Blackfathom Deeps",
            deDE = "Blackfathom-Tiefe",
            esES = "Cavernas de Brazanegra",
            esMX = "Cavernas de Brazanegra",
            frFR = "Profondeurs de Brassenoire",
            itIT = "Blackfathom Deeps",
            koKR = "검은심연의 나락",
            ptBR = "Profundezas Negras",
            ruRU = "Непроглядная Пучина",
            zhCN = "黑暗深渊",
            zhTW = "黑澗深淵",
        },
    },
    {
        key = "BlackrockDepths",
        mapID = "230",
        expansion = "0",
        name = {
            enUS = "Blackrock Depths",
            deDE = "Blackrocktiefen",
            esES = "Profundidades de Roca Negra",
            esMX = "Profundidades de Roca Negra",
            frFR = "Profondeurs de Blackrock",
            itIT = "Blackrock Depths",
            koKR = "검은바위 나락",
            ptBR = "Abismo Rocha Negra",
            ruRU = "Глубины Черной горы",
            zhCN = "黑石深渊",
            zhTW = "黑石深淵",
        },
    },
    {
        key = "BlackRockSpire",
        mapID = "229",
        expansion = "0",
        name = {
            enUS = "Blackrock Spire",
            deDE = "Blackrockspitze",
            esES = "Cumbre de Roca Negra",
            esMX = "Cumbre de Roca Negra",
            frFR = "Pic Blackrock",
            itIT = "Blackrock Spire",
            koKR = "검은바위 첨탑",
            ptBR = "Pico da Rocha Negra",
            ruRU = "Вершина Черной горы",
            zhCN = "黑石塔",
            zhTW = "黑石塔",
        },
    },
    {
        key = "2807",
        mapID = "2807",
        expansion = "0",
        name = {
            enUS = "Burning of Andorhal",
            deDE = "Brand von Andorhal",
            esES = "El Incendio de Andorhal",
            esMX = "El incendio de Andorhal",
            frFR = "Incendie d’Andorhal",
            itIT = "Burning of Andorhal",
            koKR = "불타는 안돌할",
            ptBR = "Incêndio de Andorhal",
            ruRU = "Горящие руины Андорала",
            zhCN = "燃烧的安多哈尔",
            zhTW = "燃燒的安多哈爾",
        },
    },
    {
        key = "CavernsOfTime",
        mapID = "269",
        expansion = "0",
        name = {
            enUS = "Caverns of Time",
            deDE = "Höhlen der Zeit",
            esES = "Cavernas del Tiempo",
            esMX = "Cavernas del Tiempo",
            frFR = "Grottes du Temps",
            itIT = "Caverns of Time",
            koKR = "시간의 동굴",
            ptBR = "Cavernas do Tempo",
            ruRU = "Пещеры Времени",
            zhCN = "时光之穴",
            zhTW = "時光洞穴",
        },
    },
    {
        key = "DeadminesInstance",
        mapID = "36",
        expansion = "0",
        name = {
            enUS = "Deadmines",
            deDE = "Todesminen",
            esES = "Minas de la Muerte",
            esMX = "Minas de la Muerte",
            frFR = "Mortemines",
            itIT = "Deadmines",
            koKR = "죽음의 폐광",
            ptBR = "Minas Mortas",
            ruRU = "Мертвые копи",
            zhCN = "死亡矿井",
            zhTW = "死亡礦坑",
        },
    },
    {
        key = "2853",
        mapID = "2853",
        expansion = "0",
        name = {
            enUS = "Deadwind Pass",
            deDE = "Gebirgspass der Totenwinde",
            esES = "Paso de la Muerte",
            esMX = "Paso de la Muerte",
            frFR = "Défilé de Deuillevent (Deadwind Pass)",
            itIT = "Deadwind Pass",
            koKR = "죽음의 고개",
            ptBR = "Trilha do Vento Morto",
            ruRU = "Перевал Мертвого Ветра",
            zhCN = "逆风小径",
            zhTW = "逆風小徑",
        },
    },
    {
        key = "2784",
        mapID = "2784",
        expansion = "0",
        name = {
            enUS = "Demon Fall Canyon",
            deDE = "Demonfall-Canyon",
            esES = "Barranco del Demonio",
            esMX = "Barranco del Demonio",
            frFR = "Canyon de la Malechute",
            itIT = "Demon Fall Canyon",
            koKR = "악마벼락 협곡",
            ptBR = "Cânion do Demônio Caído",
            ruRU = "Каньон Гибели Демона",
            zhCN = "屠魔峡谷",
            zhTW = "屠魔峽谷",
        },
    },
    {
        key = "DireMaul",
        mapID = "429",
        expansion = "0",
        name = {
            enUS = "Dire Maul",
            deDE = "Düsterbruch",
            esES = "La Masacre",
            esMX = "La Masacre",
            frFR = "Hache-tripes",
            itIT = "Dire Maul",
            koKR = "혈투의 전장",
            ptBR = "Gládio Cruel",
            ruRU = "Забытый Город",
            zhCN = "厄运之槌",
            zhTW = "厄運之槌",
        },
    },
    {
        key = "GnomeragonInstance",
        mapID = "90",
        expansion = "0",
        name = {
            enUS = "Gnomeregan",
            deDE = "Gnomeregan",
            esES = "Gnomeregan",
            esMX = "Gnomeregan",
            frFR = "Gnomeregan",
            itIT = "Gnomeregan",
            koKR = "놈리건",
            ptBR = "Gnomeregan",
            ruRU = "Гномреган",
            zhCN = "诺莫瑞根",
            zhTW = "諾姆瑞根",
        },
    },
    {
        key = "2875",
        mapID = "2875",
        expansion = "0",
        name = {
            enUS = "Karazhan Crypts",
            deDE = "Karazhangruften",
            esES = "Criptas de Karazhan",
            esMX = "Criptas de Karazhan",
            frFR = "Cryptes de Karazhan",
            itIT = "Karazhan Crypts",
            koKR = "카라잔 납골당",
            ptBR = "Criptas de Karazhan",
            ruRU = "Склепы Каражана",
            zhCN = "卡拉赞墓穴",
            zhTW = "卡拉贊墓穴",
        },
    },
    {
        key = "Mauradon",
        mapID = "349",
        expansion = "0",
        name = {
            enUS = "Maraudon",
            deDE = "Maraudon",
            esES = "Maraudon",
            esMX = "Maraudon",
            frFR = "Maraudon",
            itIT = "Maraudon",
            koKR = "마라우돈",
            ptBR = "Maraudon",
            ruRU = "Мародон",
            zhCN = "玛拉顿",
            zhTW = "瑪拉頓",
        },
    },
    {
        key = "2921",
        mapID = "2921",
        expansion = "0",
        name = {
            enUS = "Naxxramas",
            deDE = "Naxxramas",
            esES = "Naxxramas",
            esMX = "Naxxramas",
            frFR = "Naxxramas",
            itIT = "Naxxramas",
            koKR = "낙스라마스",
            ptBR = "Naxxramas",
            ruRU = "Наксрамас",
            zhCN = "纳克萨玛斯",
            zhTW = "納克薩瑪斯",
        },
    },
    {
        key = "OrgrimmarInstance",
        mapID = "389",
        expansion = "0",
        name = {
            enUS = "Ragefire Chasm",
            deDE = "Ragefireabgrund",
            esES = "Sima Ígnea",
            esMX = "Sima Ígnea",
            frFR = "Gouffre de Ragefeu",
            itIT = "Ragefire Chasm",
            koKR = "성난불길 협곡",
            ptBR = "Cavernas Ígneas",
            ruRU = "Огненная пропасть",
            zhCN = "怒焰裂谷",
            zhTW = "怒焰裂谷",
        },
    },
    {
        key = "RazorfenDowns",
        mapID = "129",
        expansion = "0",
        name = {
            enUS = "Razorfen Downs",
            deDE = "Hügel von Razorfen",
            esES = "Zahúrda Rajacieno",
            esMX = "Zahúrda Rajacieno",
            frFR = "Souilles de Tranchebauge",
            itIT = "Razorfen Downs",
            koKR = "가시덩굴 구릉",
            ptBR = "Urzal dos Mortos",
            ruRU = "Курганы Иглошкурых",
            zhCN = "剃刀高地",
            zhTW = "剃刀高地",
        },
    },
    {
        key = "RazorfenKraulInstance",
        mapID = "47",
        expansion = "0",
        name = {
            enUS = "Razorfen Kraul",
            deDE = "Kral von Razorfen",
            esES = "Horado Rajacieno",
            esMX = "Horado Rajacieno",
            frFR = "Kraal de Tranchebauge",
            itIT = "Razorfen Kraul",
            koKR = "가시덩굴 우리",
            ptBR = "Urzal dos Tuscos",
            ruRU = "Лабиринты Иглошкурых",
            zhCN = "剃刀沼泽",
            zhTW = "剃刀沼澤",
        },
    },
    {
        key = "MonasteryInstances",
        mapID = "189",
        expansion = "0",
        name = {
            enUS = "Scarlet Monastery",
            deDE = "Scharlachrotes Kloster",
            esES = "Monasterio Escarlata",
            esMX = "Monasterio Escarlata",
            frFR = "Monastère écarlate",
            itIT = "Scarlet Monastery",
            koKR = "붉은십자군 수도원",
            ptBR = "Monastério Escarlate",
            ruRU = "Монастырь Алого ордена",
            zhCN = "血色修道院",
            zhTW = "血色修道院",
        },
    },
    {
        key = "SchoolofNecromancy",
        mapID = "289",
        expansion = "0",
        name = {
            enUS = "Scholomance",
            deDE = "Scholomance",
            esES = "Scholomance",
            esMX = "Scholomance",
            frFR = "Scholomance",
            itIT = "Scholomance",
            koKR = "스칼로맨스",
            ptBR = "Scolomântia",
            ruRU = "Некроситет",
            zhCN = "通灵学院",
            zhTW = "通靈學院",
        },
    },
    {
        key = "2806",
        mapID = "2806",
        expansion = "0",
        name = {
            enUS = "Shadow Hold",
            deDE = "Schattenfeste",
            esES = "Guarida Sombría",
            esMX = "Guarida Sombría",
            frFR = "Fort des Ombres",
            itIT = "Shadow Hold",
            koKR = "어둠의 요새",
            ptBR = "Fortaleza do Concílio das Sombras",
            ruRU = "Оплот Теней",
            zhCN = "暗影堡",
            zhTW = "暗影堡",
        },
    },
    {
        key = "Shadowfang",
        mapID = "33",
        expansion = "0",
        name = {
            enUS = "Shadowfang Keep",
            deDE = "Burg Shadowfang",
            esES = "Castillo de Colmillo Oscuro",
            esMX = "Castillo de Colmillo Oscuro",
            frFR = "Donjon d'Ombrecroc",
            itIT = "Shadowfang Keep",
            koKR = "그림자송곳니 성채",
            ptBR = "Bastilha da Presa Negra",
            ruRU = "Крепость Темного Клыка",
            zhCN = "影牙城堡",
            zhTW = "影牙城堡",
        },
    },
    {
        key = "2817",
        mapID = "2817",
        expansion = "0",
        name = {
            enUS = "Starfall Barrow Den",
            deDE = "Grabhügel von Starfall",
            esES = "Túmulo de Estrella Fugaz",
            esMX = "Túmulo Lluvia de Estrellas",
            frFR = "Refuge des saisons de Météores",
            itIT = "Starfall Barrow Den",
            koKR = "별똥별 지하굴",
            ptBR = "Gruta da Chuva Estelar",
            ruRU = "Обитель Звездопада",
            zhCN = "星陨兽穴",
            zhTW = "星殞獸穴",
        },
    },
    {
        key = "StormwindJail",
        mapID = "34",
        expansion = "0",
        name = {
            enUS = "Stormwind Stockade",
            deDE = "Verlies von Stormwind",
            esES = "Mazmorras de Ventormenta",
            esMX = "Mazmorras de Ventormenta",
            frFR = "Prison de Stormwind",
            itIT = "Stormwind Stockade",
            koKR = "스톰윈드 지하감옥",
            ptBR = "Cárcere de Ventobravo",
            ruRU = "Тюрьма Штормграда",
            zhCN = "暴风城监狱",
            zhTW = "暴風城監獄",
        },
    },
    {
        key = "Stratholme",
        mapID = "329",
        expansion = "0",
        name = {
            enUS = "Stratholme",
            deDE = "Stratholme",
            esES = "Stratholme",
            esMX = "Stratholme",
            frFR = "Stratholme",
            itIT = "Stratholme",
            koKR = "스트라솔름",
            ptBR = "Stratholme",
            ruRU = "Стратхольм",
            zhCN = "斯坦索姆",
            zhTW = "斯坦索姆",
        },
    },
    {
        key = "SunkenTemple",
        mapID = "109",
        expansion = "0",
        name = {
            enUS = "Sunken Temple",
            deDE = "Versunkener Tempel",
            esES = "Templo Sumergido",
            esMX = "Templo Sumergido",
            frFR = "Temple englouti",
            itIT = "Sunken Temple",
            koKR = "가라앉은 사원",
            ptBR = "Templo Submerso",
            ruRU = "Затонувший храм",
            zhCN = "沉没的神庙",
            zhTW = "沉沒的神廟",
        },
    },
    {
        key = "2902",
        mapID = "2902",
        expansion = "0",
        name = {
            enUS = "The Scarab Dais",
            deDE = "Die Skarabäushöhe",
            esES = "Estrado del Escarabajo",
            esMX = "Estrado del Escarabajo",
            frFR = "L’Estrade du scarabée",
            itIT = "The Scarab Dais",
            koKR = "스카라베 제단",
            ptBR = "Palanque do Escaravelho",
            ruRU = "Помост Скарабея",
            zhCN = "甲虫之台",
            zhTW = "甲蟲之台",
        },
    },
    {
        key = "2720",
        mapID = "2720",
        expansion = "0",
        name = {
            enUS = "The Searing Basin",
            deDE = "Das Sengende Becken",
            esES = "La Cuenca Abrasadora",
            esMX = "La Cuenca Abrasadora",
            frFR = "Le bassin Incandescent",
            itIT = "The Searing Basin",
            koKR = "불타는 분지",
            ptBR = "Baía Abrasadora",
            ruRU = "Тлеющая низина",
            zhCN = "灼热盆地",
            zhTW = "焦灼盆地",
        },
    },
    {
        key = "Uldaman",
        mapID = "70",
        expansion = "0",
        name = {
            enUS = "Uldaman",
            deDE = "Uldaman",
            esES = "Uldaman",
            esMX = "Uldaman",
            frFR = "Uldaman",
            itIT = "Uldaman",
            koKR = "울다만",
            ptBR = "Uldaman",
            ruRU = "Ульдаман",
            zhCN = "奥达曼",
            zhTW = "奧達曼",
        },
    },
    {
        key = "WailingCaverns",
        mapID = "43",
        expansion = "0",
        name = {
            enUS = "Wailing Caverns",
            deDE = "Höhlen des Wehklagens",
            esES = "Cuevas de los Lamentos",
            esMX = "Cuevas de los Lamentos",
            frFR = "Cavernes des Lamentations",
            itIT = "Wailing Caverns",
            koKR = "통곡의 동굴",
            ptBR = "Caverna Ululante",
            ruRU = "Пещеры Стенаний",
            zhCN = "哀嚎洞穴",
            zhTW = "哀嚎洞穴",
        },
    },
    {
        key = "TanarisInstance",
        mapID = "209",
        expansion = "0",
        name = {
            enUS = "Zul'Farrak",
            deDE = "Zul'Farrak",
            esES = "Zul'Farrak",
            esMX = "Zul'Farrak",
            frFR = "Zul'Farrak",
            itIT = "Zul'Farrak",
            koKR = "줄파락",
            ptBR = "Zul'Farrak",
            ruRU = "Зул'Фаррак",
            zhCN = "祖尔法拉克",
            zhTW = "祖爾法拉克",
        },
    },
}

Twm_mapareas["Shadowfang"] = {
    [0] = {3733.3333333333335, 1066.6666666666667, 1066.6666666666667, -1600},    --ShadowfangKeep
}
Twm_mapareas["DeadminesInstance"] = {
    [0] = {1066.6666666666667, -2133.3333333333335, 1066.6666666666667, -2133.3333333333335},    --Deadmines
}
Twm_mapareas["RazorfenKraulInstance"] = {
    [0] = {2666.666666666667, 1066.6666666666667, 2666.666666666667, 1600},    --RazorfenKraul
}
Twm_mapareas["TanarisInstance"] = {
    [0] = {1600, 0, 2666.666666666667, -1066.6666666666667},    --Zul'Farrak
}
Twm_mapareas["CavernsOfTime"] = {
    [0] = {8000.000000000001, -533.3333333333334, 3733.3333333333335, -2666.666666666667},    --CavernsofTime
}
Twm_mapareas["SchoolofNecromancy"] = {
    [0] = {1066.6666666666667, -1066.6666666666667, 1600, -533.3333333333334},    --Scholomance
}
Twm_mapareas["Stratholme"] = {
    [0] = {-2133.3333333333335, -4800, 4266.666666666667, 2133.3333333333335},    --Stratholme
}
Twm_mapareas["2720"] = {
    [0] = {-2666.666666666667, -4266.666666666667, -6933.333333333334, -9066.666666666668},    --TheSearingBasin
}
Twm_mapareas["2784"] = {
    [0] = {-2133.3333333333335, -3733.3333333333335, 2666.666666666667, 1066.6666666666667},    --DemonFallCanyon
}
Twm_mapareas["2806"] = {
    [0] = {533.3333333333334, -1066.6666666666667, 5866.666666666667, 4266.666666666667},    --ShadowHold
}
Twm_mapareas["2807"] = {
    [0] = {-533.3333333333334, -3200, 3200, 533.3333333333334},    --BurningofAndorhal
}
Twm_mapareas["2817"] = {
    [0] = {-3200, -4800, 8000.000000000001, 6400},    --StarfallBarrowDen
}
Twm_mapareas["2853"] = {
    [0] = {-1066.6666666666667, -2666.666666666667, -9600, -11733.333333333334},    --DeadwindPass
}
Twm_mapareas["2875"] = {
    [0] = {-1066.6666666666667, -2666.666666666667, -9600, -11733.333333333334},    --KarazhanCrypts
}
Twm_mapareas["2902"] = {
    [0] = {2666.666666666667, 0, -7466.666666666667, -10133.333333333334},    --TheScarabDais
}
Twm_mapareas["2921"] = {
    [0] = {-2666.666666666667, -5866.666666666667, 4266.666666666667, 2133.3333333333335},    --Naxxramas
}
Twm_mapareas["StormwindJail"] = {
    [0] = {17218.487864176434, 16885.206011454266, 17263.965418497723, 16998.67827097575},    --StormwindStockade
}
Twm_mapareas["WailingCaverns"] = {
    [0] = {17621.027872721355, 16574.28184000651, 17254.170588175457, 16496.095240275066},    --WailingCaverns
}
Twm_mapareas["Blackfathom"] = {
    [0] = {17490.690928141277, 16407.559412638348, 17011.847265879314, 16074.82712809245},    --BlackfathomDeeps
}
Twm_mapareas["Uldaman"] = {
    [0] = {17533.000376383465, 16980.93195215861, 17250.97295633952, 16686.795572916668},    --Uldaman
}
Twm_mapareas["GnomeragonInstance"] = {
    [0] = {17822.827555338543, 16890.97662226359, 16865.778330485027, 16060.00809733073},    --Gnomeregan
}
Twm_mapareas["SunkenTemple"] = {
    [0] = {17390.762858072918, 16901.056402842205, 16821.500513712566, 16326.146891276043},    --SunkenTemple
}
Twm_mapareas["RazorfenDowns"] = {
    [0] = {1139.452814737957, 497.3407389322929, 2629.675470987957, 2196.0735117594413},    --RazorfenDowns
}
Twm_mapareas["MonasteryInstances"] = {
    [0] = {1538.5705362955741, -483.5473492940255, 2030.1756083170585, 79.47466723124307},    --ScarletMonastery
}
Twm_mapareas["BlackRockSpire"] = {
    [0] = {17192.587176005047, 16438.351450602215, 17401.064463297527, 16800.820475260418},    --BlackrockSpire
}
Twm_mapareas["BlackrockDepths"] = {
    [0] = {17331.952799479168, 16102.661478678387, 18553.343180338543, 17240.43793741862},    --BlackrockDepths
}
Twm_mapareas["Mauradon"] = {
    [0] = {17360.026438395184, 16183.290629069012, 18235.53739420573, 16827.604578653973},    --Maraudon
}
Twm_mapareas["OrgrimmarInstance"] = {
    [0] = {17342.04572550456, 16859.836580912273, 17169.622332255047, 16625.407908121746},    --RagefireChasm
}
Twm_mapareas["DireMaul"] = {
    [0] = {18178.07529703776, 16195.321818033855, 18072.797892252605, 16678.93436686198},    --DireMaul
}
