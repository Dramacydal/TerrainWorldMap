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
-- `mapID` is Map.csv's own ID (a string) -- used by per-flavor visibility
-- lists such as Twm_SeasonOnlyMaps (Data_Vanilla/mapdata_seasons.lua).
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_RaidNames = {
    {
        key = "AhnQirajTemple",
        mapID = "531",
        expansion = "0",
        name = {
            enUS = "Ahn'Qiraj Temple",
            deDE = "Tempel von Ahn'Qiraj",
            esES = "Templo de Ahn'Qiraj",
            esMX = "Templo de Ahn'Qiraj",
            frFR = "Temple d’Ahn’Qiraj",
            itIT = "Ahn'Qiraj Temple",
            koKR = "안퀴라즈 사원",
            ptBR = "Templo de Ahn'Qiraj",
            ruRU = "Храм Ан'Киража",
            zhCN = "安其拉神殿",
            zhTW = "安其拉神廟",
        },
    },
    {
        key = "BaradinHold",
        mapID = "757",
        expansion = "3",
        name = {
            enUS = "Baradin Hold",
            deDE = "Baradinfestung",
            esES = "Bastión de Baradin",
            esMX = "Bastión de Baradin",
            frFR = "Bastion de Baradin",
            itIT = "Baradin Hold",
            koKR = "바라딘 요새",
            ptBR = "Guarnição Baradin",
            ruRU = "Крепость Барадин",
            zhCN = "巴拉丁监狱",
            zhTW = "巴拉丁堡",
        },
    },
    {
        key = "BlackTemple",
        mapID = "564",
        expansion = "1",
        name = {
            enUS = "Black Temple",
            deDE = "Der Schwarze Tempel",
            esES = "Templo Oscuro",
            esMX = "Templo Oscuro",
            frFR = "Temple Noir",
            itIT = "Black Temple",
            koKR = "검은 사원",
            ptBR = "Templo Negro",
            ruRU = "Черный храм",
            zhCN = "黑暗神殿",
            zhTW = "黑暗神廟",
        },
    },
    {
        key = "BlackwingDescent",
        mapID = "669",
        expansion = "3",
        name = {
            enUS = "Blackwing Descent",
            deDE = "Pechschwingenabstieg",
            esES = "Descenso de Alanegra",
            esMX = "Descenso de Alanegra",
            frFR = "Descente de l’Aile noire",
            itIT = "Blackwing Descent",
            koKR = "검은날개 강림지",
            ptBR = "Descenso do Asa Negra",
            ruRU = "Твердыня Крыла Тьмы",
            zhCN = "黑翼血环",
            zhTW = "黑翼陷窟",
        },
    },
    {
        key = "BlackwingLair",
        mapID = "469",
        expansion = "0",
        name = {
            enUS = "Blackwing Lair",
            deDE = "Pechschwingenhort",
            esES = "Guarida de Alanegra",
            esMX = "Guarida de Alanegra",
            frFR = "Repaire de l’Aile noire",
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
        mapID = "548",
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
        key = "DeathwingBack",
        mapID = "967",
        expansion = "3",
        name = {
            enUS = "Dragon Soul",
            deDE = "Drachenseele",
            esES = "Alma de Dragón",
            esMX = "Alma de Dragón",
            frFR = "L’Âme des dragons",
            itIT = "Dragon Soul",
            koKR = "용의 영혼",
            ptBR = "Alma Dragônica",
            ruRU = "Душа Дракона",
            zhCN = "巨龙之魂",
            zhTW = "巨龍之魂",
        },
    },
    {
        key = "EmeraldDream",
        mapID = "169",
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
        key = "Firelands1",
        mapID = "720",
        expansion = "3",
        name = {
            enUS = "Firelands",
            deDE = "Feuerlande",
            esES = "Tierras de Fuego",
            esMX = "Tierras de Fuego",
            frFR = "Terres de Feu",
            itIT = "Firelands",
            koKR = "불의 땅",
            ptBR = "Terras do Fogo",
            ruRU = "Огненные Просторы",
            zhCN = "火焰之地",
            zhTW = "火源之界",
        },
    },
    {
        key = "GruulsLair",
        mapID = "565",
        expansion = "1",
        name = {
            enUS = "Gruul's Lair",
            deDE = "Gruuls Unterschlupf",
            esES = "Guarida de Gruul",
            esMX = "Guarida de Gruul",
            frFR = "Repaire de Gruul",
            itIT = "Gruul's Lair",
            koKR = "그룰의 둥지",
            ptBR = "Covil de Gruul",
            ruRU = "Логово Груула",
            zhCN = "格鲁尔的巢穴",
            zhTW = "戈魯爾之巢",
        },
    },
    {
        key = "MantidRaid",
        mapID = "1009",
        expansion = "4",
        name = {
            enUS = "Heart of Fear",
            deDE = "Das Herz der Angst",
            esES = "Corazón del Miedo",
            esMX = "Corazón del Miedo",
            frFR = "Cœur de la peur",
            itIT = "Heart of Fear",
            koKR = "공포의 심장",
            ptBR = "Coração do Medo",
            ruRU = "Сердце Страха",
            zhCN = "恐惧之心",
            zhTW = "恐懼之心",
        },
    },
    {
        key = "IcecrownCitadel",
        mapID = "631",
        expansion = "2",
        name = {
            enUS = "Icecrown Citadel",
            deDE = "Eiskronenzitadelle",
            esES = "Ciudadela de la Corona de Hielo",
            esMX = "Ciudadela de la Corona de Hielo",
            frFR = "Citadelle de la Couronne de glace",
            itIT = "Icecrown Citadel",
            koKR = "얼음왕관 성채",
            ptBR = "Cidadela da Coroa de Gelo",
            ruRU = "Цитадель Ледяной Короны",
            zhCN = "冰冠堡垒",
            zhTW = "冰冠城塞",
        },
    },
    {
        key = "Karazahn",
        mapID = "532",
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
        mapID = "544",
        expansion = "1",
        name = {
            enUS = "Magtheridon's Lair",
            deDE = "Magtheridons Kammer",
            esES = "Guarida de Magtheridon",
            esMX = "Guarida de Magtheridon",
            frFR = "Le repaire de Magtheridon",
            itIT = "Magtheridon's Lair",
            koKR = "마그테리돈의 둥지",
            ptBR = "Covil de Magtheridon",
            ruRU = "Логово Магтеридона",
            zhCN = "玛瑟里顿的巢穴",
            zhTW = "瑪瑟里頓的巢穴",
        },
    },
    {
        key = "MogushanPalace",
        mapID = "1008",
        expansion = "4",
        name = {
            enUS = "Mogu'shan Vaults",
            deDE = "Mogu'shangewölbe",
            esES = "Cámaras Mogu'shan",
            esMX = "Cámaras Mogu'shan",
            frFR = "Caveaux Mogu’shan",
            itIT = "Mogu'shan Vaults",
            koKR = "모구샨 금고",
            ptBR = "Galerias Mogu'shan",
            ruRU = "Подземелья Могу'шан",
            zhCN = "魔古山宝库",
            zhTW = "魔古山寶庫",
        },
    },
    {
        key = "MoltenCore",
        mapID = "409",
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
        mapID = "533",
        expansion = "2",
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
        mapID = "249",
        expansion = "0",
        name = {
            enUS = "Onyxia's Lair",
            deDE = "Onyxias Hort",
            esES = "Guarida de Onyxia",
            esMX = "Guarida de Onyxia",
            frFR = "Repaire d’Onyxia",
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
        mapID = "509",
        expansion = "0",
        name = {
            enUS = "Ruins of Ahn'Qiraj",
            deDE = "Ruinen von Ahn'Qiraj",
            esES = "Ruinas de Ahn'Qiraj",
            esMX = "Ruinas de Ahn'Qiraj",
            frFR = "Ruines d’Ahn’Qiraj",
            itIT = "Ruins of Ahn'Qiraj",
            koKR = "안퀴라즈 폐허",
            ptBR = "Ruínas de Ahn'Qiraj",
            ruRU = "Руины Ан'Киража",
            zhCN = "安其拉废墟",
            zhTW = "安其拉廢墟",
        },
    },
    {
        key = "OrgrimmarRaid",
        mapID = "1136",
        expansion = "4",
        name = {
            enUS = "Siege of Orgrimmar",
            deDE = "Schlacht um Orgrimmar",
            esES = "Asedio de Orgrimmar",
            esMX = "Asedio de Orgrimmar",
            frFR = "Siège d’Orgrimmar",
            itIT = "Siege of Orgrimmar",
            koKR = "오그리마 공성전",
            ptBR = "Cerco a Orgrimmar",
            ruRU = "Осада Оргриммара",
            zhCN = "决战奥格瑞玛",
            zhTW = "圍攻奧格瑪",
        },
    },
    {
        key = "TempestKeepRaid",
        mapID = "550",
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
        key = "MoguExteriorRaid",
        mapID = "996",
        expansion = "4",
        name = {
            enUS = "Terrace of Endless Spring",
            deDE = "Terrasse des Endlosen Frühlings",
            esES = "Veranda de la Primavera Eterna",
            esMX = "Veranda de la Primavera Eterna",
            frFR = "Terrasse Printanière",
            itIT = "Terrace of Endless Spring",
            koKR = "영원한 봄의 정원",
            ptBR = "Terraço da Primavera Eterna",
            ruRU = "Терраса Вечной Весны",
            zhCN = "永春台",
            zhTW = "豐泉台",
        },
    },
    {
        key = "GrimBatolRaid",
        mapID = "671",
        expansion = "3",
        name = {
            enUS = "The Bastion of Twilight",
            deDE = "Die Bastion des Zwielichts",
            esES = "El Bastión del Crepúsculo",
            esMX = "El Bastión del Crepúsculo",
            frFR = "Le bastion du Crépuscule",
            itIT = "The Bastion of Twilight",
            koKR = "황혼의 요새",
            ptBR = "Bastião do Crepúsculo",
            ruRU = "Сумеречный бастион",
            zhCN = "暮光堡垒",
            zhTW = "暮光堡壘",
        },
    },
    {
        key = "HyjalPast",
        mapID = "534",
        expansion = "1",
        name = {
            enUS = "The Battle for Mount Hyjal",
            deDE = "Die Schlacht um den Hyjal",
            esES = "La Batalla del Monte Hyjal",
            esMX = "La Batalla del Monte Hyjal",
            frFR = "La bataille du mont Hyjal",
            itIT = "The Battle for Mount Hyjal",
            koKR = "하이잘 산 전투",
            ptBR = "A Batalha pelo Monte Hyjal",
            ruRU = "Битва за гору Хиджал",
            zhCN = "海加尔山之战",
            zhTW = "海加爾山之戰",
        },
    },
    {
        key = "NexusRaid",
        mapID = "616",
        expansion = "2",
        name = {
            enUS = "The Eye of Eternity",
            deDE = "Das Auge der Ewigkeit",
            esES = "El Ojo de la Eternidad",
            esMX = "El Ojo de la Eternidad",
            frFR = "L’Œil de l’éternité",
            itIT = "The Eye of Eternity",
            koKR = "영원의 눈",
            ptBR = "Olho da Eternidade",
            ruRU = "Око Вечности",
            zhCN = "永恒之眼",
            zhTW = "永恆之眼",
        },
    },
    {
        key = "ChamberOfAspectsBlack",
        mapID = "615",
        expansion = "2",
        name = {
            enUS = "The Obsidian Sanctum",
            deDE = "Das Obsidiansanktum",
            esES = "El Sagrario Obsidiana",
            esMX = "El Sagrario Obsidiana",
            frFR = "Le sanctum Obsidien",
            itIT = "The Obsidian Sanctum",
            koKR = "흑요석 성소",
            ptBR = "Santuário Obsidiano",
            ruRU = "Обсидиановое святилище",
            zhCN = "黑曜石圣殿",
            zhTW = "黑曜聖所",
        },
    },
    {
        key = "ChamberofAspectsRed",
        mapID = "724",
        expansion = "2",
        name = {
            enUS = "The Ruby Sanctum",
            deDE = "Das Rubinsanktum",
            esES = "El Sagrario Rubí",
            esMX = "El Sagrario Rubí",
            frFR = "Le sanctum Rubis",
            itIT = "The Ruby Sanctum",
            koKR = "루비 성소",
            ptBR = "Santuário Rubi",
            ruRU = "Рубиновое святилище",
            zhCN = "红玉圣殿",
            zhTW = "晶紅聖所",
        },
    },
    {
        key = "SunwellPlateau",
        mapID = "580",
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
        key = "SkywallRaid",
        mapID = "754",
        expansion = "3",
        name = {
            enUS = "Throne of the Four Winds",
            deDE = "Thron der Vier Winde",
            esES = "Trono de los Cuatro Vientos",
            esMX = "Trono de los Cuatro Vientos",
            frFR = "Trône des quatre vents",
            itIT = "Throne of the Four Winds",
            koKR = "네 바람의 왕좌",
            ptBR = "Trono dos Quatro Ventos",
            ruRU = "Трон Четырех Ветров",
            zhCN = "风神王座",
            zhTW = "四風王座",
        },
    },
    {
        key = "ThunderIslandRaid",
        mapID = "1098",
        expansion = "4",
        name = {
            enUS = "Throne of Thunder",
            deDE = "Thron des Donners",
            esES = "Solio del Trueno",
            esMX = "Solio del Trueno",
            frFR = "Trône du tonnerre",
            itIT = "Throne of Thunder",
            koKR = "천둥의 왕좌",
            ptBR = "Trono do Trovão",
            ruRU = "Престол Гроз",
            zhCN = "雷电王座",
            zhTW = "雷霆王座",
        },
    },
    {
        key = "ArgentTournamentRaid",
        mapID = "649",
        expansion = "2",
        name = {
            enUS = "Trial of the Crusader",
            deDE = "Prüfung des Kreuzfahrers",
            esES = "Prueba del Cruzado",
            esMX = "Prueba del Cruzado",
            frFR = "L’épreuve du croisé",
            itIT = "Trial of the Crusader",
            koKR = "십자군의 시험장",
            ptBR = "Prova do Cruzado",
            ruRU = "Испытание крестоносца",
            zhCN = "十字军的试炼",
            zhTW = "十字軍試煉",
        },
    },
    {
        key = "UlduarRaid",
        mapID = "603",
        expansion = "2",
        name = {
            enUS = "Ulduar",
            deDE = "Ulduar",
            esES = "Ulduar",
            esMX = "Ulduar",
            frFR = "Ulduar",
            itIT = "Ulduar",
            koKR = "울두아르",
            ptBR = "Ulduar",
            ruRU = "Ульдуар",
            zhCN = "奥杜尔",
            zhTW = "奧杜亞",
        },
    },
    {
        key = "WintergraspRaid",
        mapID = "624",
        expansion = "2",
        name = {
            enUS = "Vault of Archavon",
            deDE = "Archavons Kammer",
            esES = "La Cámara de Archavon",
            esMX = "La Cámara de Archavon",
            frFR = "Caveau d’Archavon",
            itIT = "Vault of Archavon",
            koKR = "아카본 석실",
            ptBR = "Abóbada de Arcavon",
            ruRU = "Склеп Аркавона",
            zhCN = "阿尔卡冯的宝库",
            zhTW = "亞夏梵穹殿",
        },
    },
}

Twm_mapareas["EmeraldDream"] = {
    [0] = {4266.666666666667, -4266.666666666667, 3733.3333333333335, -4800},    --EmeraldDream
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
Twm_mapareas["SunwellPlateau"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 3200, 0},    --TheSunwell
}
Twm_mapareas["UlduarRaid"] = {
    [0] = {3200, -1600, 3200, -2133.3333333333335},    --Ulduar
}
Twm_mapareas["ChamberOfAspectsBlack"] = {
    [0] = {1600, -533.3333333333334, 4266.666666666667, 2133.3333333333335},    --TheObsidianSanctum
}
Twm_mapareas["NexusRaid"] = {
    [0] = {2666.666666666667, 0, 2133.3333333333335, -533.3333333333334},    --TheEyeofEternity
}
Twm_mapareas["WintergraspRaid"] = {
    [0] = {533.3333333333334, -1066.6666666666667, 533.3333333333334, -1066.6666666666667},    --VaultofArchavon
}
Twm_mapareas["IcecrownCitadel"] = {
    [0] = {3733.3333333333335, -3200, 5866.666666666667, -2133.3333333333335},    --IcecrownCitadel
}
Twm_mapareas["ArgentTournamentRaid"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 2666.666666666667, 0},    --TrialoftheCrusader
}
Twm_mapareas["Firelands1"] = {
    [0] = {1066.6666666666667, -1066.6666666666667, 2133.3333333333335, -1066.6666666666667},    --Firelands
}
Twm_mapareas["ChamberofAspectsRed"] = {
    [0] = {1600, -533.3333333333334, 4266.666666666667, 2133.3333333333335},    --TheRubySanctum
}
Twm_mapareas["SkywallRaid"] = {
    [0] = {1600, 0, 533.3333333333334, -1066.6666666666667},    --ThroneoftheFourWinds
}
Twm_mapareas["DeathwingBack"] = {
    [0] = {15466.666666666668, -15466.666666666668, 15466.666666666668, -15466.666666666668},    --DragonSoul
}
Twm_mapareas["MoguExteriorRaid"] = {
    [0] = {5333.333333333334, -4266.666666666667, 0, -5866.666666666667},    --TerraceofEndlessSpring
}
Twm_mapareas["MogushanPalace"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 5866.666666666667, 3200},    --Mogu'shanVaults
}
Twm_mapareas["MantidRaid"] = {
    [0] = {3200, -1066.6666666666667, 0, -4266.666666666667},    --HeartofFear
}
Twm_mapareas["ThunderIslandRaid"] = {
    [0] = {8000.000000000001, 3200, 8000.000000000001, 3200},    --ThroneofThunder
}
Twm_mapareas["OrgrimmarRaid"] = {
    [0] = {2666.666666666667, -6400, 2666.666666666667, -10133.333333333334},    --SiegeofOrgrimmar
}
Twm_mapareas["OnyxiaLairInstance"] = {
    [0] = {17053.95197359721, 16668.31669108073, 17129.912611643475, 16812.063936869305},    --Onyxia'sLair
}
Twm_mapareas["MoltenCore"] = {
    [0] = {16795.334360758465, 15786.501688639324, 18399.721842447918, 17475.370035807293},    --MoltenCore
}
Twm_mapareas["HellfireRaid"] = {
    [0] = {17183.798830668133, 16900.046969095867, 17303.480387369793, 16868.63068262736},    --Magtheridon'sLair
}
Twm_mapareas["CoilfangRaid"] = {
    [0] = {17181.99331156413, 15891.9799601237, 17640.556498209637, 16595.7319132487},    --CoilfangSerpentshrineCavern
}
Twm_mapareas["TempestKeepRaid"] = {
    [0] = {17562.127939860027, 16561.812678019207, 17945.642130533855, 16942.54209391276},    --TempestKeep
}
Twm_mapareas["GruulsLair"] = {
    [0] = {17506.363047281902, 16930.228014628094, 17365.18989054362, 17002.18972269694},    --Gruul'sLair
}
Twm_mapareas["BlackwingDescent"] = {
    [0] = {175.39225260416788, -835.7888234456368, 449.1996256510429, -585.5706303914376},    --BlackwingDescent
}
Twm_mapareas["GrimBatolRaid"] = {
    [0] = {-324.5760091145821, -1264.1352437337227, 290.8219401041679, -1373.711003621418},    --TheBastionofTwilight
}
Twm_mapareas["BaradinHold"] = {
    [0] = {1638.8864847819023, 951.9272104899101, 556.0796305338554, 84.25239435831827},    --BaradinHold
}
