-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Raid zone boxes, kept deliberately separate from
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
-- Twm_RaidNames is resolved into the actual TWM_RAIDS dropdown
-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/
-- Twm_flightmasters' name tables -- see this file's own header comment.
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_RaidNames = {
    {
        key = "AhnQirajTemple",
        expansion = "0",
        name = {
            enUS = "Ahn'Qiraj Temple",
            deDE = "Tempel von Ahn'Qiraj",
            esES = "Templo de Ahn'Qiraj",
            esMX = "Templo de Ahn'Qiraj",
            frFR = "Temple d'Ahn'Qiraj",
            itIT = "Ahn'Qiraj Temple",
            koKR = "안퀴라즈 사원",
            ptBR = "Templo de Ahn'Qiraj",
            ruRU = "Храм Ан'Киража",
            zhCN = "安其拉神殿",
            zhTW = "安其拉神廟",
        },
    },
    {
        key = "BlackTemple",
        expansion = "1",
        name = {
            enUS = "Black Temple",
            deDE = "Der Schwarze Tempel",
            esES = "El Templo Oscuro",
            esMX = "El Templo Oscuro",
            frFR = "Temple noir",
            itIT = "Black Temple",
            koKR = "검은 사원",
            ptBR = "Templo Negro",
            ruRU = "Черный храм",
            zhCN = "黑暗神殿",
            zhTW = "黑暗神廟",
        },
    },
    {
        key = "BlackwingLair",
        expansion = "0",
        name = {
            enUS = "Blackwing Lair",
            deDE = "Pechschwingenhort",
            esES = "Guarida Alanegra",
            esMX = "Guarida de Alanegra",
            frFR = "Repaire de l'Aile noire",
            itIT = "Blackwing Lair",
            koKR = "검은날개 둥지",
            ptBR = "Covil Asa Negra",
            ruRU = "Логово Крыла Тьмы",
            zhCN = "黑翼之巢",
            zhTW = "黑翼之巢",
        },
    },
    {
        key = "CoilfangRaid",
        expansion = "1",
        name = {
            enUS = "Coilfang: Serpentshrine Cavern",
            deDE = "Echsenkessel: Höhle des Schlangenschreins",
            esES = "Reserva Colmillo Torcido: Caverna Santuario Serpiente",
            esMX = "Reserva Colmillo Torcido: Caverna Santuario Serpiente",
            frFR = "Glissecroc : caverne du sanctuaire du Serpent",
            itIT = "Coilfang: Serpentshrine Cavern",
            koKR = "갈퀴송곳니 저수지: 불뱀 제단",
            ptBR = "Presacurva: Caverna do Serpentário",
            ruRU = "Кривой Клык: Змеиное святилище",
            zhCN = "盘牙湖泊：毒蛇神殿",
            zhTW = "盤牙:毒蛇神殿洞穴",
        },
    },
    {
        key = "EmeraldDream",
        expansion = "0",
        name = {
            enUS = "Emerald Dream",
            deDE = "Smaragdgrüner Traum",
            esES = "Sueño Esmeralda",
            esMX = "Sueño Esmeralda",
            frFR = "Rêve d'émeraude",
            itIT = "Emerald Dream",
            koKR = "에메랄드의 꿈",
            ptBR = "Sonho Esmeralda",
            ruRU = "Изумрудный Сон",
            zhCN = "翡翠梦境",
            zhTW = "翡翠夢境",
        },
    },
    {
        key = "GruulsLair",
        expansion = "1",
        name = {
            enUS = "Gruul's Lair",
            deDE = "Gruuls Unterschlupf",
            esES = "Guarida de Gruul",
            esMX = "Guarida de Gruul",
            frFR = "Le repaire de Gruul",
            itIT = "Gruul's Lair",
            koKR = "그룰의 둥지",
            ptBR = "Covil de Gruul",
            ruRU = "Логово Груула",
            zhCN = "格鲁尔的巢穴",
            zhTW = "戈魯爾之巢",
        },
    },
    {
        key = "Karazahn",
        expansion = "1",
        name = {
            enUS = "Karazhan",
            deDE = "Karazhan",
            esES = "Karazhan",
            esMX = "Karazhan",
            frFR = "Karazhan",
            itIT = "Karazhan",
            koKR = "카라잔",
            ptBR = "Karazhan",
            ruRU = "Каражан",
            zhCN = "卡拉赞",
            zhTW = "卡拉贊",
        },
    },
    {
        key = "HellfireRaid",
        expansion = "1",
        name = {
            enUS = "Magtheridon's Lair",
            deDE = "Magtheridons Kammer",
            esES = "Guarida de Magtheridon",
            esMX = "Guarida de Magtheridon",
            frFR = "Repaire de Magtheridon",
            itIT = "Magtheridon's Lair",
            koKR = "마그테리돈의 둥지",
            ptBR = "Covil de Magtheridon",
            ruRU = "Логово Магтеридона",
            zhCN = "玛瑟里顿的巢穴",
            zhTW = "瑪瑟里頓的巢穴",
        },
    },
    {
        key = "MoltenCore",
        expansion = "0",
        name = {
            enUS = "Molten Core",
            deDE = "Geschmolzener Kern",
            esES = "Núcleo de Magma",
            esMX = "Núcleo de Magma",
            frFR = "Cœur du Magma",
            itIT = "Molten Core",
            koKR = "화산 심장부",
            ptBR = "Núcleo Derretido",
            ruRU = "Огненные Недра",
            zhCN = "熔火之心",
            zhTW = "熔火之心",
        },
    },
    {
        key = "Stratholme Raid",
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
        key = "OnyxiaLairInstance",
        expansion = "0",
        name = {
            enUS = "Onyxia's Lair",
            deDE = "Onyxias Hort",
            esES = "Guarida de Onyxia",
            esMX = "Guarida de Onyxia",
            frFR = "Repaire d'Onyxia",
            itIT = "Onyxia's Lair",
            koKR = "오닉시아의 둥지",
            ptBR = "Covil de Onyxia",
            ruRU = "Логово Ониксии",
            zhCN = "奥妮克希亚的巢穴",
            zhTW = "奧妮克希亞的巢穴",
        },
    },
    {
        key = "AhnQiraj",
        expansion = "0",
        name = {
            enUS = "Ruins of Ahn'Qiraj",
            deDE = "Ruinen von Ahn'Qiraj",
            esES = "Ruinas de Ahn'Qiraj",
            esMX = "Ruinas de Ahn'Qiraj",
            frFR = "Ruines d'Ahn'Qiraj",
            itIT = "Ruins of Ahn'Qiraj",
            koKR = "안퀴라즈 폐허",
            ptBR = "Ruínas de Ahn'Qiraj",
            ruRU = "Руины Ан'Киража",
            zhCN = "安其拉废墟",
            zhTW = "安其拉廢墟",
        },
    },
    {
        key = "TempestKeepRaid",
        expansion = "1",
        name = {
            enUS = "Tempest Keep",
            deDE = "Festung der Stürme",
            esES = "El Castillo de la Tempestad",
            esMX = "El Castillo de la Tempestad",
            frFR = "Donjon de la Tempête",
            itIT = "Tempest Keep",
            koKR = "폭풍우 요새",
            ptBR = "Bastilha da Tormenta",
            ruRU = "Крепость Бурь",
            zhCN = "风暴要塞",
            zhTW = "風暴要塞",
        },
    },
    {
        key = "HyjalPast",
        expansion = "1",
        name = {
            enUS = "The Battle for Mount Hyjal",
            deDE = "Die Schlacht um den Berg Hyjal",
            esES = "Batalla de El Monte Hyjal",
            esMX = "La Batalla del Monte Hyjal",
            frFR = "La bataille du mont Hyjal",
            itIT = "The Battle for Mount Hyjal",
            koKR = "하이잘 산의 전투",
            ptBR = "A Batalha pelo Monte Hyjal",
            ruRU = "Битва за гору Хиджал",
            zhCN = "海加尔山之战",
            zhTW = "海加爾山戰場",
        },
    },
    {
        key = "SunwellPlateau",
        expansion = "1",
        name = {
            enUS = "The Sunwell",
            deDE = "Der Sonnenbrunnen",
            esES = "La Fuente del Sol",
            esMX = "La Fuente del Sol",
            frFR = "Le Puits de soleil",
            itIT = "The Sunwell",
            koKR = "태양샘",
            ptBR = "Nascente do Sol",
            ruRU = "Солнечный Колодец",
            zhCN = "太阳之井",
            zhTW = "太陽之井",
        },
    },
    {
        key = "ZulAman",
        expansion = "1",
        name = {
            enUS = "Zul'Aman",
            deDE = "Zul'Aman",
            esES = "Zul'Aman",
            esMX = "Zul'Aman",
            frFR = "Zul'Aman",
            itIT = "Zul'Aman",
            koKR = "줄아만",
            ptBR = "Zul'Aman",
            ruRU = "Зул'Аман",
            zhCN = "祖阿曼",
            zhTW = "祖阿曼",
        },
    },
    {
        key = "Zul'gurub",
        expansion = "0",
        name = {
            enUS = "Zul'Gurub",
            deDE = "Zul'Gurub",
            esES = "Zul'Gurub",
            esMX = "Zul'Gurub",
            frFR = "Zul'Gurub",
            itIT = "Zul'Gurub",
            koKR = "줄구룹",
            ptBR = "Zul'Gurub",
            ruRU = "Зул'Гуруб",
            zhCN = "祖尔格拉布",
            zhTW = "祖爾格拉布",
        },
    },
}

Twm_mapareas["EmeraldDream"] = {
    [0] = {4266.666666666667, -4266.666666666667, 3733.3333333333335, -4800},    --EmeraldDream
}
Twm_mapareas["Zul'gurub"] = {
    [0] = {-533.3333333333334, -3200, -10666.666666666668, -13333.333333333334},    --Zul'Gurub
}
Twm_mapareas["BlackwingLair"] = {
    [0] = {0, -2133.3333333333335, -6400, -8533.333333333334},    --BlackwingLair
}
Twm_mapareas["AhnQiraj"] = {
    [0] = {3200, 533.3333333333334, -7466.666666666667, -11733.333333333334},    --RuinsofAhn'Qiraj
}
Twm_mapareas["AhnQirajTemple"] = {
    [0] = {3200, 533.3333333333334, -7466.666666666667, -10133.333333333334},    --Ahn'QirajTemple
}
Twm_mapareas["Karazahn"] = {
    [0] = {-1066.6666666666667, -2666.666666666667, -10133.333333333334, -11733.333333333334},    --Karazhan
}
Twm_mapareas["Stratholme Raid"] = {
    [0] = {-2666.666666666667, -5866.666666666667, 4266.666666666667, 2133.3333333333335},    --Naxxramas
}
Twm_mapareas["HyjalPast"] = {
    [0] = {-1066.6666666666667, -4266.666666666667, 6400, 3733.3333333333335},    --TheBattleforMountHyjal
}
Twm_mapareas["BlackTemple"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 2133.3333333333335, -1066.6666666666667},    --BlackTemple
}
Twm_mapareas["ZulAman"] = {
    [0] = {2666.666666666667, 0, 1600, -1066.6666666666667},    --Zul'Aman
}
Twm_mapareas["SunwellPlateau"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 3200, 0},    --TheSunwell
}
Twm_mapareas["OnyxiaLairInstance"] = {
    [0] = {17353.131052652996, 16967.495768229168, 17129.912611643475, 16812.063936869305},    --Onyxia'sLair
}
Twm_mapareas["MoltenCore"] = {
    [0] = {18321.652018229168, 17312.819346110027, 18399.721842447918, 17475.370035807293},    --MoltenCore
}
Twm_mapareas["HellfireRaid"] = {
    [0] = {17154.412623087566, 16870.6607615153, 17303.480387369793, 16868.63068262736},    --Magtheridon'sLair
}
Twm_mapareas["CoilfangRaid"] = {
    [0] = {18217.730509440105, 16927.717157999676, 17640.556498209637, 16595.7319132487},    --CoilfangSerpentshrineCavern
}
Twm_mapareas["TempestKeepRaid"] = {
    [0] = {17564.581919352215, 16564.266657511394, 17945.642130533855, 16942.54209391276},    --TempestKeep
}
Twm_mapareas["GruulsLair"] = {
    [0] = {17087.9086004893, 16511.77356783549, 17365.18989054362, 17002.18972269694},    --Gruul'sLair
}
