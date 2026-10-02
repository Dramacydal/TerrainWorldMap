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
        key = "AbyssalMaw",
        mapID = "637",
        expansion = "3",
        name = {
            enUS = "Abyssal Maw Exterior",
            deDE = "Der Meeresschlund",
            esES = "Fauce Abisal Exterior",
            esMX = "Fauce Abisal Exterior",
            frFR = "Extérieur de la Gueule des abysses",
            itIT = "Abyssal Maw Exterior",
            koKR = "심연의 구렁 외부",
            ptBR = "Exterior do Oceano Abissal",
            ruRU = "Внешняя сторона Бездонной пучины",
            zhCN = "深渊之喉外部",
            zhTW = "深淵之喉外部",
        },
    },
    {
        key = "Azjol_LowerCity",
        mapID = "619",
        expansion = "2",
        name = {
            enUS = "Ahn'kahet: The Old Kingdom",
            deDE = "Ahn'kahet: Das Alte Königreich",
            esES = "Ahn'kahet: El Antiguo Reino",
            esMX = "Ahn'kahet: El Antiguo Reino",
            frFR = "Ahn’kahet : l’Ancien royaume",
            itIT = "Ahn'kahet: The Old Kingdom",
            koKR = "안카헤트: 고대 왕국",
            ptBR = "Ahn'kahet: O Velho Reino",
            ruRU = "Ан'кахет: Старое Королевство",
            zhCN = "安卡赫特：古代王国",
            zhTW = "安卡罕特:古王國",
        },
    },
    {
        key = "AhnQirajTerrace",
        mapID = "734",
        expansion = "2",
        name = {
            enUS = "Ahn'Qiraj Terrace",
            deDE = "Terrasse von Ahn'Qiraj",
            esES = "Bancal de Ahn'Qiraj",
            esMX = "Bancal de Ahn'Qiraj",
            frFR = "Terrasse d’Ahn’Qiraj",
            itIT = "Ahn'Qiraj Terrace",
            koKR = "안퀴라즈 정원",
            ptBR = "Terraço de Ahn'Qiraj",
            ruRU = "Терраса Ан'Киража",
            zhCN = "安其拉平台",
            zhTW = "安其拉殿堂",
        },
    },
    {
        key = "Zul'gurub",
        mapID = "309",
        expansion = "0",
        name = {
            enUS = "Ancient Zul'Gurub",
            deDE = "Altes Zul'Gurub",
            esES = "Antiguo Zul'Gurub",
            esMX = "Antiguo Zul'Gurub",
            frFR = "L’antique Zul'Gurub",
            itIT = "Ancient Zul'Gurub",
            koKR = "고대 줄구룹",
            ptBR = "Antiga Zul'Gurub",
            ruRU = "Старый Зул'Гуруб",
            zhCN = "古城祖尔格拉布",
            zhTW = "古祖爾格拉布",
        },
    },
    {
        key = "AuchindounDraenei",
        mapID = "558",
        expansion = "1",
        name = {
            enUS = "Auchindoun: Auchenai Crypts",
            deDE = "Auchindoun: Auchenaikrypta",
            esES = "Auchindoun: Criptas Auchenai",
            esMX = "Auchindoun: Criptas Auchenai",
            frFR = "Auchindoun : Cryptes Auchenaï",
            itIT = "Auchindoun: Auchenai Crypts",
            koKR = "아킨둔: 아키나이 납골당",
            ptBR = "Auchindoun: Catacumbas Auchenai",
            ruRU = "Аукиндон: Аукенайские гробницы",
            zhCN = "奥金顿：奥金尼地穴",
            zhTW = "奧齊頓:奧奇奈地穴",
        },
    },
    {
        key = "AuchindounEthereal",
        mapID = "557",
        expansion = "1",
        name = {
            enUS = "Auchindoun: Mana-Tombs",
            deDE = "Auchindoun: Managruft",
            esES = "Auchindoun: Tumbas de Maná",
            esMX = "Auchindoun: Tumbas de Maná",
            frFR = "Auchindoun : Tombes-mana",
            itIT = "Auchindoun: Mana-Tombs",
            koKR = "아킨둔: 마나 무덤",
            ptBR = "Auchindoun: Tumbas de Mana",
            ruRU = "Аукиндон: Гробницы маны",
            zhCN = "奥金顿：法力墓穴",
            zhTW = "奧齊頓:法力之墓",
        },
    },
    {
        key = "AuchindounDemon",
        mapID = "556",
        expansion = "1",
        name = {
            enUS = "Auchindoun: Sethekk Halls",
            deDE = "Auchindoun: Sethekkhallen",
            esES = "Auchindoun: Salas Sethekk",
            esMX = "Auchindoun: Salas Sethekk",
            frFR = "Auchindoun : Salles des Sethekk",
            itIT = "Auchindoun: Sethekk Halls",
            koKR = "아킨둔: 세데크 전당",
            ptBR = "Auchindoun: Salões dos Sethekk",
            ruRU = "Аукиндон: Сетеккские залы",
            zhCN = "奥金顿：塞泰克大厅",
            zhTW = "奧齊頓:塞司克大廳",
        },
    },
    {
        key = "AuchindounShadow",
        mapID = "555",
        expansion = "1",
        name = {
            enUS = "Auchindoun: Shadow Labyrinth",
            deDE = "Auchindoun: Schattenlabyrinth",
            esES = "Auchindoun: Laberinto de las Sombras",
            esMX = "Auchindoun: Laberinto de las Sombras",
            frFR = "Auchindoun : Labyrinthe des ombres",
            itIT = "Auchindoun: Shadow Labyrinth",
            koKR = "아킨둔: 어둠의 미궁",
            ptBR = "Auchindoun: Labirinto Soturno",
            ruRU = "Аукиндон: Темный лабиринт",
            zhCN = "奥金顿：暗影迷宫",
            zhTW = "奧齊頓:暗影迷宮",
        },
    },
    {
        key = "Azjol_Uppercity",
        mapID = "601",
        expansion = "2",
        name = {
            enUS = "Azjol-Nerub",
            deDE = "Azjol-Nerub",
            esES = "Azjol-Nerub",
            esMX = "Azjol-Nerub",
            frFR = "Azjol-Nérub",
            itIT = "Azjol-Nerub",
            koKR = "아졸네룹",
            ptBR = "Azjol-Nerub",
            ruRU = "Азжол-Неруб",
            zhCN = "艾卓-尼鲁布",
            zhTW = "阿茲歐-奈幽",
        },
    },
    {
        key = "Blackfathom",
        mapID = "48",
        expansion = "0",
        name = {
            enUS = "Blackfathom Deeps",
            deDE = "Tiefschwarze Grotte",
            esES = "Cavernas de Brazanegra",
            esMX = "Cavernas de Brazanegra",
            frFR = "Profondeurs de Brassenoire",
            itIT = "Blackfathom Deeps",
            koKR = "검은심연 나락",
            ptBR = "Profundezas Negras",
            ruRU = "Непроглядная Пучина",
            zhCN = "黑暗深渊",
            zhTW = "黑澗深淵",
        },
    },
    {
        key = "BlackRockSpire_4_0",
        mapID = "645",
        expansion = "3",
        name = {
            enUS = "Blackrock Caverns",
            deDE = "Schwarzfelshöhlen",
            esES = "Cavernas Roca Negra",
            esMX = "Cavernas Roca Negra",
            frFR = "Cavernes de Rochenoire",
            itIT = "Blackrock Caverns",
            koKR = "검은바위 동굴",
            ptBR = "Caverna Rocha Negra",
            ruRU = "Пещеры Черной горы",
            zhCN = "黑石岩窟",
            zhTW = "黑石洞穴",
        },
    },
    {
        key = "BlackrockDepths",
        mapID = "230",
        expansion = "0",
        name = {
            enUS = "Blackrock Depths",
            deDE = "Schwarzfelstiefen",
            esES = "Profundidades de Roca Negra",
            esMX = "Profundidades de Roca Negra",
            frFR = "Profondeurs de Rochenoire",
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
            deDE = "Schwarzfelsspitze",
            esES = "Cumbre de Roca Negra",
            esMX = "Cumbre de Roca Negra",
            frFR = "Pic Rochenoire",
            itIT = "Blackrock Spire",
            koKR = "검은바위 첨탑",
            ptBR = "Pico da Rocha Negra",
            ruRU = "Пик Черной горы",
            zhCN = "黑石塔",
            zhTW = "黑石塔",
        },
    },
    {
        key = "CoilfangDraenei",
        mapID = "547",
        expansion = "1",
        name = {
            enUS = "Coilfang: The Slave Pens",
            deDE = "Echsenkessel: Sklavenunterkünfte",
            esES = "Colmillo Torcido: Recinto de los Esclavos",
            esMX = "Colmillo Torcido: Recinto de los Esclavos",
            frFR = "Glissecroc : les Enclos aux esclaves",
            itIT = "Coilfang: The Slave Pens",
            koKR = "갈퀴송곳니 저수지: 강제 노역소",
            ptBR = "Presacurva: Pátio dos Escravos",
            ruRU = "Резервуар Кривого Клыка: Узилище",
            zhCN = "盘牙湖泊：奴隶围栏",
            zhTW = "盤牙:奴隸監獄",
        },
    },
    {
        key = "CoilfangPumping",
        mapID = "545",
        expansion = "1",
        name = {
            enUS = "Coilfang: The Steamvault",
            deDE = "Echsenkessel: Dampfkammer",
            esES = "Colmillo Torcido: Cámara de Vapor",
            esMX = "Colmillo Torcido: Cámara de Vapor",
            frFR = "Glissecroc : le Caveau de la vapeur",
            itIT = "Coilfang: The Steamvault",
            koKR = "갈퀴송곳니 저수지: 증기 저장고",
            ptBR = "Presacurva: Câmara dos Vapores",
            ruRU = "Кривой Клык: Паровое подземелье",
            zhCN = "盘牙湖泊：蒸汽地窟",
            zhTW = "盤牙:蒸汽洞窟",
        },
    },
    {
        key = "CoilfangMarsh",
        mapID = "546",
        expansion = "1",
        name = {
            enUS = "Coilfang: The Underbog",
            deDE = "Echsenkessel: Tiefensumpf",
            esES = "Colmillo Torcido: La Sotiénaga",
            esMX = "Colmillo Torcido: La Sotiénaga",
            frFR = "Glissecroc : la Basse-tourbière",
            itIT = "Coilfang: The Underbog",
            koKR = "갈퀴송곳니 저수지: 지하수렁",
            ptBR = "Presacurva: Brejo Oculto",
            ruRU = "Кривой Клык: Нижетопь",
            zhCN = "盘牙湖泊：幽暗沼泽",
            zhTW = "盤牙:深幽泥沼",
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
        key = "DireMaul",
        mapID = "429",
        expansion = "0",
        name = {
            enUS = "Dire Maul",
            deDE = "Düsterbruch",
            esES = "La Masacre",
            esMX = "La Masacre",
            frFR = "Hache-Tripes",
            itIT = "Dire Maul",
            koKR = "혈투의 전장",
            ptBR = "Gládio Cruel",
            ruRU = "Забытый Город",
            zhCN = "厄运之槌",
            zhTW = "厄運之槌",
        },
    },
    {
        key = "DrakTheronKeep",
        mapID = "600",
        expansion = "2",
        name = {
            enUS = "Drak'Tharon Keep",
            deDE = "Feste von Drak'Tharon",
            esES = "Fortaleza de Drak'Tharon",
            esMX = "Fortaleza de Drak'Tharon",
            frFR = "Donjon de Drak’Tharon",
            itIT = "Drak'Tharon Keep",
            koKR = "드락타론 성채",
            ptBR = "Bastilha Drak'Tharon",
            ruRU = "Крепость Драк'Тарон",
            zhCN = "达克萨隆要塞",
            zhTW = "德拉克薩隆要塞",
        },
    },
    {
        key = "COTDragonblight",
        mapID = "938",
        expansion = "3",
        name = {
            enUS = "End Time",
            deDE = "Endzeit",
            esES = "Fin de los Días",
            esMX = "Fin de los Días",
            frFR = "La Fin des temps",
            itIT = "End Time",
            koKR = "시간의 끝",
            ptBR = "Fim dos Tempos",
            ruRU = "Конец Времен",
            zhCN = "时光之末",
            zhTW = "終焉之刻",
        },
    },
    {
        key = "Firelands2",
        mapID = "721",
        expansion = "3",
        name = {
            enUS = "Firelands Terrain 2",
            deDE = "Feuerlande-Terrain 2",
            esES = "Firelands Terrain 2",
            esMX = "Firelands Terrain 2",
            frFR = "Terrain 2 de Terres de Feu",
            itIT = "Firelands Terrain 2",
            koKR = "불의 땅 지형 2",
            ptBR = "Terreno 3 das Terras do Fogo",
            ruRU = "Рельеф Огненных Просторов",
            zhCN = "火焰之地，地形2",
            zhTW = "火源之界地形2",
        },
    },
    {
        key = "TheGreatWall",
        mapID = "962",
        expansion = "4",
        name = {
            enUS = "Gate of the Setting Sun",
            deDE = "Das Tor der Untergehenden Sonne",
            esES = "Puerta del Sol Poniente",
            esMX = "Puerta del Sol Poniente",
            frFR = "Porte du Soleil couchant",
            itIT = "Gate of the Setting Sun",
            koKR = "석양문",
            ptBR = "Portal do Sol Poente",
            ruRU = "Врата Заходящего Солнца",
            zhCN = "残阳关",
            zhTW = "落陽關",
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
        key = "GrimBatolDungeon",
        mapID = "670",
        expansion = "3",
        name = {
            enUS = "Grim Batol",
            deDE = "Grim Batol",
            esES = "Grim Batol",
            esMX = "Grim Batol",
            frFR = "Grim Batol",
            itIT = "Grim Batol",
            koKR = "그림 바톨",
            ptBR = "Grim Batol",
            ruRU = "Грим Батол",
            zhCN = "格瑞姆巴托",
            zhTW = "格瑞姆巴托",
        },
    },
    {
        key = "GunDrak",
        mapID = "604",
        expansion = "2",
        name = {
            enUS = "Gundrak",
            deDE = "Gundrak",
            esES = "Gundrak",
            esMX = "Gundrak",
            frFR = "Gundrak",
            itIT = "Gundrak",
            koKR = "군드락",
            ptBR = "Gundrak",
            ruRU = "Гундрак",
            zhCN = "古达克",
            zhTW = "剛德拉克",
        },
    },
    {
        key = "Ulduar80",
        mapID = "602",
        expansion = "2",
        name = {
            enUS = "Halls of Lightning",
            deDE = "Hallen der Blitze",
            esES = "Cámaras de Relámpagos",
            esMX = "Cámaras de Relámpagos",
            frFR = "Les salles de Foudre",
            itIT = "Halls of Lightning",
            koKR = "번개의 전당",
            ptBR = "Salões Relampejantes",
            ruRU = "Чертоги Молний",
            zhCN = "闪电大厅",
            zhTW = "雷光大廳",
        },
    },
    {
        key = "Uldum",
        mapID = "644",
        expansion = "3",
        name = {
            enUS = "Halls of Origination",
            deDE = "Hallen des Ursprungs",
            esES = "Cámaras de los Orígenes",
            esMX = "Cámaras de los Orígenes",
            frFR = "Salles de l’Origine",
            itIT = "Halls of Origination",
            koKR = "시초의 전당",
            ptBR = "Salões Primordiais",
            ruRU = "Чертоги Созидания",
            zhCN = "起源大厅",
            zhTW = "起源大廳",
        },
    },
    {
        key = "HallsOfReflection",
        mapID = "668",
        expansion = "2",
        name = {
            enUS = "Halls of Reflection",
            deDE = "Hallen der Reflexion",
            esES = "Cámaras de Reflexión",
            esMX = "Cámaras de Reflexión",
            frFR = "Salles des Reflets",
            itIT = "Halls of Reflection",
            koKR = "투영의 전당",
            ptBR = "Salões da Reflexão",
            ruRU = "Залы Отражений",
            zhCN = "映像大厅",
            zhTW = "倒影大廳",
        },
    },
    {
        key = "Ulduar70",
        mapID = "599",
        expansion = "2",
        name = {
            enUS = "Halls of Stone",
            deDE = "Hallen des Steins",
            esES = "Cámaras de Piedra",
            esMX = "Cámaras de Piedra",
            frFR = "Les salles de Pierre",
            itIT = "Halls of Stone",
            koKR = "돌의 전당",
            ptBR = "Salões Rochosos",
            ruRU = "Чертоги Камня",
            zhCN = "岩石大厅",
            zhTW = "石之大廳",
        },
    },
    {
        key = "HellfireRampart",
        mapID = "543",
        expansion = "1",
        name = {
            enUS = "Hellfire Citadel: Ramparts",
            deDE = "Höllenfeuerzitadelle: Bollwerk",
            esES = "Ciudadela del Fuego Infernal: Murallas",
            esMX = "Ciudadela del Fuego Infernal: Murallas",
            frFR = "Citadelle des Flammes infernales : les Remparts",
            itIT = "Hellfire Citadel: Ramparts",
            koKR = "지옥불 성채: 지옥불 성루",
            ptBR = "Cidadela Fogo do Inferno: Muralha",
            ruRU = "Цитадель Адского Пламени: бастионы",
            zhCN = "地狱火堡垒：城墙",
            zhTW = "地獄火堡壘:地獄火壁壘",
        },
    },
    {
        key = "HellfireDemon",
        mapID = "542",
        expansion = "1",
        name = {
            enUS = "Hellfire Citadel: The Blood Furnace",
            deDE = "Höllenfeuerzitadelle: Blutkessel",
            esES = "Ciudadela del Fuego Infernal: Horno de Sangre",
            esMX = "Ciudadela del Fuego Infernal: Horno de Sangre",
            frFR = "Citadelle des Flammes infernales : la Fournaise du sang",
            itIT = "Hellfire Citadel: The Blood Furnace",
            koKR = "지옥불 성채: 피의 용광로",
            ptBR = "Cidadela Fogo do Inferno: Fornalha de Sangue",
            ruRU = "Цитадель Адского Пламени: Кузня Крови",
            zhCN = "地狱火堡垒：鲜血熔炉",
            zhTW = "地獄火堡壘:血熔爐",
        },
    },
    {
        key = "HellfireMilitary",
        mapID = "540",
        expansion = "1",
        name = {
            enUS = "Hellfire Citadel: The Shattered Halls",
            deDE = "Höllenfeuerzitadelle: Zerschmetterte Hallen",
            esES = "Ciudadela del Fuego Infernal: Salas Arrasadas",
            esMX = "Ciudadela del Fuego Infernal: Salas Arrasadas",
            frFR = "Citadelle des Flammes infernales : les Salles brisées",
            itIT = "Hellfire Citadel: The Shattered Halls",
            koKR = "지옥불 성채: 으스러진 손의 전당",
            ptBR = "Cidadela Fogo do Inferno: Salões Despedaçados",
            ruRU = "Цитадель Адского Пламени: Разрушенные залы",
            zhCN = "地狱火堡垒：破碎大厅",
            zhTW = "地獄火堡壘:破碎大廳",
        },
    },
    {
        key = "TheHourOfTwilight",
        mapID = "940",
        expansion = "3",
        name = {
            enUS = "Hour of Twilight",
            deDE = "Stunde des Zwielichts",
            esES = "Hora del Crepúsculo",
            esMX = "Hora del Crepúsculo",
            frFR = "L’Heure du Crépuscule",
            itIT = "Hour of Twilight",
            koKR = "황혼의 시간",
            ptBR = "Hora do Crepúsculo",
            ruRU = "Время Сумерек",
            zhCN = "暮光审判",
            zhTW = "暮光之時",
        },
    },
    {
        key = "UldumDungeon",
        mapID = "755",
        expansion = "3",
        name = {
            enUS = "Lost City of the Tol'vir",
            deDE = "Die Verlorene Stadt der Tol'vir",
            esES = "Ciudad Perdida de los Tol'vir",
            esMX = "Ciudad Perdida de los Tol'vir",
            frFR = "Cité perdue des Tol’vir",
            itIT = "Lost City of the Tol'vir",
            koKR = "톨비르의 잃어버린 도시",
            ptBR = "Cidade Perdida dos Tol'vir",
            ruRU = "Затерянный город Тол'вир",
            zhCN = "托维尔失落之城",
            zhTW = "托維爾的失落之城",
        },
    },
    {
        key = "MaelstromDeathwingFight",
        mapID = "977",
        expansion = "3",
        name = {
            enUS = "Maelstrom Deathwing Fight",
            deDE = "Kampf mit Todesschwinge am Mahlstrom",
            esES = "Lucha de Alamuerte en La Vorágine",
            esMX = "Lucha de Alamuerte en La Vorágine",
            frFR = "Combat contre Aile de mort dans le Maelström",
            itIT = "Maelstrom Deathwing Fight",
            koKR = "혼돈의 소용돌이 데스윙 전투지",
            ptBR = "Combate contra o Asa da Morte na Voragem",
            ruRU = "Водоворот, бой со Смертокрылом",
            zhCN = "大漩涡死亡之翼战斗",
            zhTW = "大漩渦死亡之翼決戰",
        },
    },
    {
        key = "Sunwell5ManFix",
        mapID = "585",
        expansion = "1",
        name = {
            enUS = "Magister's Terrace",
            deDE = "Terrasse der Magister",
            esES = "Bancal del Magister",
            esMX = "Bancal del Magister",
            frFR = "Terrasse des Magistères",
            itIT = "Magister's Terrace",
            koKR = "마법학자의 정원",
            ptBR = "Terraço dos Magísteres",
            ruRU = "Терраса Магистров",
            zhCN = "魔导师平台",
            zhTW = "博學者殿堂",
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
        key = "MoguDungeon",
        mapID = "994",
        expansion = "4",
        name = {
            enUS = "Mogu'shan Palace",
            deDE = "Mogu'shanpalast",
            esES = "Palacio Mogu'shan",
            esMX = "Palacio Mogu'shan",
            frFR = "Palais Mogu’shan",
            itIT = "Mogu'shan Palace",
            koKR = "모구샨 궁전",
            ptBR = "Palácio Mogu'shan",
            ruRU = "Дворец Могу'шан",
            zhCN = "魔古山宫殿",
            zhTW = "魔古山宮",
        },
    },
    {
        key = "NexusLegendary",
        mapID = "951",
        expansion = "3",
        name = {
            enUS = "Nexus Legendary",
            deDE = "Der Nexus (Legendäre Waffe)",
            esES = "Legendario del Nexo",
            esMX = "Legendario del Nexo",
            frFR = "Nexus (légendaire)",
            itIT = "Nexus Legendary",
            koKR = "마력의 탑 전설",
            ptBR = "Nexus Lendária",
            ruRU = "Нексус, получение посоха",
            zhCN = "传奇武器任务：魔枢",
            zhTW = "奧核之心傳奇任務",
        },
    },
    {
        key = "CavernsOfTime",
        mapID = "269",
        expansion = "1",
        name = {
            enUS = "Opening of the Dark Portal",
            deDE = "Öffnung des Dunklen Portals",
            esES = "Apertura de El Portal Oscuro",
            esMX = "Apertura de El Portal Oscuro",
            frFR = "Ouverture de la Porte des ténèbres",
            itIT = "Opening of the Dark Portal",
            koKR = "어둠의 문 열기",
            ptBR = "Abertura do Portal Negro",
            ruRU = "Открытие Темного портала",
            zhCN = "开启黑暗之门",
            zhTW = "開啟黑暗之門",
        },
    },
    {
        key = "PetBattleJadeForest",
        mapID = "1032",
        expansion = "4",
        name = {
            enUS = "Pet Battle - Jade Forest",
            deDE = "Haustierkampf - Jadewald",
            esES = "Duelo de mascotas: El Bosque de Jade",
            esMX = "Duelo de mascotas: El Bosque de Jade",
            frFR = "Combat de mascottes - La forêt de jade",
            itIT = "Pet Battle - Jade Forest",
            koKR = "애완동물 대전 - 비취 숲",
            ptBR = "Batalha de Mascotes - Floresta de Jade",
            ruRU = "Битва питомцев - Нефритовый лес",
            zhCN = "Pet Battle - Jade Forest",
            zhTW = "寵物對戰 - 翠玉林",
        },
    },
    {
        key = "QuarryofTears",
        mapID = "658",
        expansion = "2",
        name = {
            enUS = "Pit of Saron",
            deDE = "Grube von Saron",
            esES = "Foso de Saron",
            esMX = "Foso de Saron",
            frFR = "Fosse de Saron",
            itIT = "Pit of Saron",
            koKR = "사론의 구덩이",
            ptBR = "Fosso de Saron",
            ruRU = "Яма Сарона",
            zhCN = "萨隆深渊",
            zhTW = "薩倫之淵",
        },
    },
    {
        key = "OrgrimmarInstance",
        mapID = "389",
        expansion = "0",
        name = {
            enUS = "Ragefire Chasm",
            deDE = "Der Flammenschlund",
            esES = "Sima Ígnea",
            esMX = "Sima Ígnea",
            frFR = "Gouffre de Ragefeu",
            itIT = "Ragefire Chasm",
            koKR = "성난불길 협곡",
            ptBR = "Cavernas Ígneas",
            ruRU = "Огненная Пропасть",
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
            deDE = "Hügel der Klingenhauer",
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
            deDE = "Kral der Klingenhauer",
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
        key = "ScarletSanctuaryArmoryAndLibrary",
        mapID = "1001",
        expansion = "0",
        name = {
            enUS = "Scarlet Halls",
            deDE = "Die Scharlachroten Hallen",
            esES = "Cámaras Escarlata",
            esMX = "Cámaras Escarlata",
            frFR = "Salles Écarlates",
            itIT = "Scarlet Halls",
            koKR = "붉은십자군 전당",
            ptBR = "Salões Escarlates",
            ruRU = "Залы Алого ордена",
            zhCN = "血色大厅",
            zhTW = "血色大廳",
        },
    },
    {
        key = "ScarletMonasteryCathedralGY",
        mapID = "1004",
        expansion = "0",
        name = {
            enUS = "Scarlet Monastery",
            deDE = "Scharlachrotes Kloster",
            esES = "Monasterio Escarlata",
            esMX = "Monasterio Escarlata",
            frFR = "Monastère Écarlate",
            itIT = "Scarlet Monastery",
            koKR = "붉은십자군 수도원",
            ptBR = "Monastério Escarlate",
            ruRU = "Монастырь Алого ордена",
            zhCN = "血色修道院",
            zhTW = "血色修道院",
        },
    },
    {
        key = "MonasteryInstances",
        mapID = "189",
        expansion = "0",
        name = {
            enUS = "Scarlet Monastery of Old",
            deDE = "Das alte Scharlachrote Kloster",
            esES = "Scarlet Monastery of Old",
            esMX = "Scarlet Monastery of Old",
            frFR = "Monastère Écarlate d’antan",
            itIT = "Scarlet Monastery of Old",
            koKR = "옛 붉은십자군 수도원",
            ptBR = "Monastério Escarlate de Outrora",
            ruRU = "Прежний монастырь Алого ордена",
            zhCN = "旧血色修道院",
            zhTW = "Scarlet Monastery of Old",
        },
    },
    {
        key = "NewScholomance",
        mapID = "1007",
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
        key = "SchoolofNecromancy",
        mapID = "289",
        expansion = "0",
        name = {
            enUS = "Scholomance OLD",
            deDE = "Scholomance",
            esES = "Scholomance OLD",
            esMX = "Scholomance OLD",
            frFR = "Scholomance",
            itIT = "Scholomance OLD",
            koKR = "스칼로맨스",
            ptBR = "Scolomântia ANTIGO",
            ruRU = "Некроситет",
            zhCN = "旧通灵学院",
            zhTW = "Scholomance OLD",
        },
    },
    {
        key = "ShadowpanHideout",
        mapID = "959",
        expansion = "4",
        name = {
            enUS = "Shado-Pan Monastery",
            deDE = "Das Shado-Pan-Kloster",
            esES = "Monasterio del Shadopan",
            esMX = "Monasterio del Shadopan",
            frFR = "Monastère des Pandashan",
            itIT = "Shado-Pan Monastery",
            koKR = "음영파 수도원",
            ptBR = "Monastério Shado-pan",
            ruRU = "Монастырь Шадо-Пан",
            zhCN = "影踪禅院",
            zhTW = "影潘僧院",
        },
    },
    {
        key = "Shadowfang",
        mapID = "33",
        expansion = "0",
        name = {
            enUS = "Shadowfang Keep",
            deDE = "Burg Schattenfang",
            esES = "Castillo de Colmillo Oscuro",
            esMX = "Castillo de Colmillo Oscuro",
            frFR = "Donjon d’Ombrecroc",
            itIT = "Shadowfang Keep",
            koKR = "그림자송곳니 성채",
            ptBR = "Bastilha da Presa Negra",
            ruRU = "Крепость Темного Клыка",
            zhCN = "影牙城堡",
            zhTW = "影牙城堡",
        },
    },
    {
        key = "MantidDungeon",
        mapID = "1011",
        expansion = "4",
        name = {
            enUS = "Siege of Niuzao Temple",
            deDE = "Belagerung des Niuzaotempels",
            esES = "Asedio del Templo de Niuzao",
            esMX = "Asedio del Templo de Niuzao",
            frFR = "Siège du temple de Niuzao",
            itIT = "Siege of Niuzao Temple",
            koKR = "니우짜오 사원 공성전투",
            ptBR = "Cerco ao Templo Niuzao",
            ruRU = "Осада храма Нюцзао",
            zhCN = "围攻砮皂寺",
            zhTW = "圍攻怒兆寺",
        },
    },
    {
        key = "StormstoutBrewery",
        mapID = "961",
        expansion = "4",
        name = {
            enUS = "Stormstout Brewery",
            deDE = "Brauerei Sturmbräu",
            esES = "Cervecería del Trueno",
            esMX = "Cervecería del Trueno",
            frFR = "Brasserie Brune d’Orage",
            itIT = "Stormstout Brewery",
            koKR = "스톰스타우트 양조장",
            ptBR = "Cervejaria Malte do Trovão",
            ruRU = "Хмелеварня Буйных Портеров",
            zhCN = "风暴烈酒酿造厂",
            zhTW = "風暴烈酒酒坊",
        },
    },
    {
        key = "StormwindJail",
        mapID = "34",
        expansion = "0",
        name = {
            enUS = "Stormwind Stockade",
            deDE = "Verlies von Sturmwind",
            esES = "Mazmorras de Ventormenta",
            esMX = "Mazmorras de Ventormenta",
            frFR = "Prison de Hurlevent",
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
        key = "TempestKeepArcane",
        mapID = "552",
        expansion = "1",
        name = {
            enUS = "Tempest Keep: The Arcatraz",
            deDE = "Festung der Stürme: Die Arkatraz",
            esES = "El Castillo de la Tempestad: El Arcatraz",
            esMX = "El Castillo de la Tempestad: El Arcatraz",
            frFR = "Donjon de la Tempête : l'Arcatraz",
            itIT = "Tempest Keep: The Arcatraz",
            koKR = "폭풍우 요새: 알카트라즈",
            ptBR = "Bastilha da Tormenta: Arcatraz",
            ruRU = "Крепость Бурь: Аркатрац",
            zhCN = "风暴要塞：禁魔监狱",
            zhTW = "風暴要塞:亞克崔茲",
        },
    },
    {
        key = "TempestKeepAtrium",
        mapID = "553",
        expansion = "1",
        name = {
            enUS = "Tempest Keep: The Botanica",
            deDE = "Festung der Stürme: Die Botanika",
            esES = "El Castillo de la Tempestad: El Invernáculo",
            esMX = "El Castillo de la Tempestad: El Invernáculo",
            frFR = "Donjon de la Tempête : la Botanica",
            itIT = "Tempest Keep: The Botanica",
            koKR = "폭풍우 요새: 신록의 정원",
            ptBR = "Bastilha da Tormenta: Jardim Botânico",
            ruRU = "Крепость Бурь: Ботаника",
            zhCN = "风暴要塞：生态船",
            zhTW = "風暴要塞:波塔尼卡",
        },
    },
    {
        key = "TempestKeepFactory",
        mapID = "554",
        expansion = "1",
        name = {
            enUS = "Tempest Keep: The Mechanar",
            deDE = "Festung der Stürme: Die Mechanar",
            esES = "El Castillo de la Tempestad: El Mechanar",
            esMX = "El Castillo de la Tempestad: El Mechanar",
            frFR = "Donjon de la Tempête : le Méchanar",
            itIT = "Tempest Keep: The Mechanar",
            koKR = "폭풍우 요새: 메카나르",
            ptBR = "Bastilha da Tormenta: Mecanar",
            ruRU = "Крепость Бурь: Механар",
            zhCN = "风暴要塞：能源舰",
            zhTW = "風暴要塞:麥克納爾",
        },
    },
    {
        key = "EastTemple",
        mapID = "960",
        expansion = "4",
        name = {
            enUS = "Temple of the Jade Serpent",
            deDE = "Tempel der Jadeschlange",
            esES = "Templo del Dragón de Jade",
            esMX = "Templo del Dragón de Jade",
            frFR = "Temple du Serpent de jade",
            itIT = "Temple of the Jade Serpent",
            koKR = "옥룡사",
            ptBR = "Templo da Serpente de Jade",
            ruRU = "Храм Нефритовой Змеи",
            zhCN = "青龙寺",
            zhTW = "玉蛟寺",
        },
    },
    {
        key = "StratholmeCOT",
        mapID = "595",
        expansion = "2",
        name = {
            enUS = "The Culling of Stratholme",
            deDE = "Das Ausmerzen von Stratholme",
            esES = "La Matanza de Stratholme",
            esMX = "La Matanza de Stratholme",
            frFR = "L’Épuration de Stratholme",
            itIT = "The Culling of Stratholme",
            koKR = "옛 스트라솔름",
            ptBR = "Expurgo de Stratholme",
            ruRU = "Очищение Стратхольма",
            zhCN = "净化斯坦索姆",
            zhTW = "斯坦索姆的抉擇",
        },
    },
    {
        key = "HillsbradPast",
        mapID = "560",
        expansion = "1",
        name = {
            enUS = "The Escape From Durnholde",
            deDE = "Die Flucht aus Durnholde",
            esES = "La Fuga de Durnholde",
            esMX = "La Fuga de Durnholde",
            frFR = "L'évasion de Fort-de-Durn",
            itIT = "The Escape From Durnholde",
            koKR = "던홀드 탈출",
            ptBR = "A Fuga de Forte do Desterro",
            ruRU = "Побег из Дарнхольда",
            zhCN = "逃离敦霍尔德",
            zhTW = "逃離敦霍爾德",
        },
    },
    {
        key = "IcecrownCitadel5Man",
        mapID = "632",
        expansion = "2",
        name = {
            enUS = "The Forge of Souls",
            deDE = "Die Seelenschmiede",
            esES = "La Forja de Almas",
            esMX = "La Forja de Almas",
            frFR = "La Forge des Âmes",
            itIT = "The Forge of Souls",
            koKR = "영혼의 제련소",
            ptBR = "Forja das Almas",
            ruRU = "Кузня Душ",
            zhCN = "灵魂洪炉",
            zhTW = "眾魂熔爐",
        },
    },
    {
        key = "Nexus70",
        mapID = "576",
        expansion = "2",
        name = {
            enUS = "The Nexus",
            deDE = "Der Nexus",
            esES = "El Nexo",
            esMX = "El Nexo",
            frFR = "Le Nexus",
            itIT = "The Nexus",
            koKR = "마력의 탑",
            ptBR = "Nexus",
            ruRU = "Нексус",
            zhCN = "魔枢",
            zhTW = "奧核之心",
        },
    },
    {
        key = "Nexus80",
        mapID = "578",
        expansion = "2",
        name = {
            enUS = "The Oculus",
            deDE = "Das Oculus",
            esES = "El Oculus",
            esMX = "El Oculus",
            frFR = "L’Oculus",
            itIT = "The Oculus",
            koKR = "마력의 눈",
            ptBR = "Óculus",
            ruRU = "Окулус",
            zhCN = "魔环",
            zhTW = "奧核之眼",
        },
    },
    {
        key = "DeepholmeDungeon",
        mapID = "725",
        expansion = "3",
        name = {
            enUS = "The Stonecore",
            deDE = "Der Steinerne Kern",
            esES = "El Núcleo Pétreo",
            esMX = "El Núcleo Pétreo",
            frFR = "Le Cœur-de-Pierre",
            itIT = "The Stonecore",
            koKR = "바위심장부",
            ptBR = "Litocerne",
            ruRU = "Каменные Недра",
            zhCN = "巨石之核",
            zhTW = "石岩之心",
        },
    },
    {
        key = "SkywallDungeon",
        mapID = "657",
        expansion = "3",
        name = {
            enUS = "The Vortex Pinnacle",
            deDE = "Der Vortexgipfel",
            esES = "La Cumbre del Vórtice",
            esMX = "La Cumbre del Vórtice",
            frFR = "La cime du Vortex",
            itIT = "The Vortex Pinnacle",
            koKR = "소용돌이 누각",
            ptBR = "Pináculo do Vórtice",
            ruRU = "Вершина Смерча",
            zhCN = "旋云之巅",
            zhTW = "漩渦尖塔",
        },
    },
    {
        key = "AbyssalMaw_Interior",
        mapID = "643",
        expansion = "3",
        name = {
            enUS = "Throne of the Tides",
            deDE = "Thron der Gezeiten",
            esES = "Trono de las Mareas",
            esMX = "Trono de las Mareas",
            frFR = "Trône des marées",
            itIT = "Throne of the Tides",
            koKR = "파도의 왕좌",
            ptBR = "Trono das Marés",
            ruRU = "Трон Приливов",
            zhCN = "潮汐王座",
            zhTW = "海潮王座",
        },
    },
    {
        key = "ArgentTournamentDungeon",
        mapID = "650",
        expansion = "2",
        name = {
            enUS = "Trial of the Champion",
            deDE = "Prüfung des Champions",
            esES = "Prueba del Campeón",
            esMX = "Prueba del Campeón",
            frFR = "L’épreuve du champion",
            itIT = "Trial of the Champion",
            koKR = "용사의 시험장",
            ptBR = "Prova do Campeão",
            ruRU = "Испытание чемпиона",
            zhCN = "冠军的试炼",
            zhTW = "勇士試煉",
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
        key = "Valgarde70",
        mapID = "574",
        expansion = "2",
        name = {
            enUS = "Utgarde Keep",
            deDE = "Burg Utgarde",
            esES = "Fortaleza de Utgarde",
            esMX = "Fortaleza de Utgarde",
            frFR = "Donjon d’Utgarde",
            itIT = "Utgarde Keep",
            koKR = "우트가드 성채",
            ptBR = "Bastilha Utgarde",
            ruRU = "Крепость Утгард",
            zhCN = "乌特加德城堡",
            zhTW = "俄特加德要塞",
        },
    },
    {
        key = "UtgardePinnacle",
        mapID = "575",
        expansion = "2",
        name = {
            enUS = "Utgarde Pinnacle",
            deDE = "Turm Utgarde",
            esES = "Pináculo de Utgarde",
            esMX = "Pináculo de Utgarde",
            frFR = "Cime d’Utgarde",
            itIT = "Utgarde Pinnacle",
            koKR = "우트가드 첨탑",
            ptBR = "Pináculo Utgarde",
            ruRU = "Вершина Утгард",
            zhCN = "乌特加德之巅",
            zhTW = "俄特加德之巔",
        },
    },
    {
        key = "DalaranPrison",
        mapID = "608",
        expansion = "2",
        name = {
            enUS = "Violet Hold",
            deDE = "Violette Festung",
            esES = "Bastión Violeta",
            esMX = "Bastión Violeta",
            frFR = "Le fort Pourpre",
            itIT = "Violet Hold",
            koKR = "보랏빛 요새",
            ptBR = "Castelo Violeta",
            ruRU = "Аметистовая крепость",
            zhCN = "紫罗兰监狱",
            zhTW = "紫羅蘭堡",
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
        key = "COTWarOfTheAncients",
        mapID = "939",
        expansion = "3",
        name = {
            enUS = "Well of Eternity",
            deDE = "Brunnen der Ewigkeit",
            esES = "Pozo de la Eternidad",
            esMX = "Pozo de la Eternidad",
            frFR = "Puits d’éternité",
            itIT = "Well of Eternity",
            koKR = "영원의 샘",
            ptBR = "Nascente da Eternidade",
            ruRU = "Источник Вечности",
            zhCN = "永恒之井",
            zhTW = "永恆之井",
        },
    },
    {
        key = "ZulAman",
        mapID = "568",
        expansion = "3",
        name = {
            enUS = "Zul'Aman",
            deDE = "Zul'Aman",
            esES = "Zul'Aman",
            esMX = "Zul'Aman",
            frFR = "Zul’Aman",
            itIT = "Zul'Aman",
            koKR = "줄아만",
            ptBR = "Zul'Aman",
            ruRU = "Зул'Аман",
            zhCN = "祖阿曼",
            zhTW = "祖阿曼",
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
            frFR = "Zul’Farrak",
            itIT = "Zul'Farrak",
            koKR = "줄파락",
            ptBR = "Zul'Farrak",
            ruRU = "Зул'Фаррак",
            zhCN = "祖尔法拉克",
            zhTW = "祖爾法拉克",
        },
    },
    {
        key = "Zul_Gurub5Man",
        mapID = "859",
        expansion = "3",
        name = {
            enUS = "Zul'Gurub",
            deDE = "Zul'Gurub",
            esES = "Zul'Gurub",
            esMX = "Zul'Gurub",
            frFR = "Zul’Gurub",
            itIT = "Zul'Gurub",
            koKR = "줄구룹",
            ptBR = "Zul'Gurub",
            ruRU = "Зул'Гуруб",
            zhCN = "祖尔格拉布",
            zhTW = "祖爾格拉布",
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
Twm_mapareas["RazorfenDowns"] = {
    [0] = {2666.666666666667, -533.3333333333334, 3200, 1066.6666666666667},    --RazorfenDowns
}
Twm_mapareas["MonasteryInstances"] = {
    [0] = {2133.3333333333335, -1066.6666666666667, 2666.666666666667, -533.3333333333334},    --ScarletMonasteryofOld
}
Twm_mapareas["TanarisInstance"] = {
    [0] = {1600, 0, 2666.666666666667, -1066.6666666666667},    --Zul'Farrak
}
Twm_mapareas["CavernsOfTime"] = {
    [0] = {8000.000000000001, -533.3333333333334, 3733.3333333333335, -2666.666666666667},    --OpeningoftheDarkPortal
}
Twm_mapareas["SchoolofNecromancy"] = {
    [0] = {1066.6666666666667, -1066.6666666666667, 1600, -533.3333333333334},    --ScholomanceOLD
}
Twm_mapareas["Zul'gurub"] = {
    [0] = {-533.3333333333334, -3200, -10666.666666666668, -13333.333333333334},    --AncientZul'Gurub
}
Twm_mapareas["Stratholme"] = {
    [0] = {-2133.3333333333335, -4800, 4266.666666666667, 2133.3333333333335},    --Stratholme
}
Twm_mapareas["HellfireRampart"] = {
    [0] = {4266.666666666667, -533.3333333333334, 1066.6666666666667, -3200},    --HellfireCitadelRamparts
}
Twm_mapareas["HillsbradPast"] = {
    [0] = {2666.666666666667, -533.3333333333334, 3733.3333333333335, 533.3333333333334},    --TheEscapeFromDurnholde
}
Twm_mapareas["ZulAman"] = {
    [0] = {2666.666666666667, 0, 1600, -1066.6666666666667},    --Zul'Aman
}
Twm_mapareas["Valgarde70"] = {
    [0] = {2133.3333333333335, -2133.3333333333335, 2133.3333333333335, -2133.3333333333335},    --UtgardeKeep
}
Twm_mapareas["UtgardePinnacle"] = {
    [0] = {2133.3333333333335, -2133.3333333333335, 2133.3333333333335, -2133.3333333333335},    --UtgardePinnacle
}
Twm_mapareas["Nexus80"] = {
    [0] = {3200, -1066.6666666666667, 3200, -1066.6666666666667},    --TheOculus
}
Twm_mapareas["Sunwell5ManFix"] = {
    [0] = {2666.666666666667, -2666.666666666667, 2666.666666666667, -2133.3333333333335},    --Magister'sTerrace
}
Twm_mapareas["StratholmeCOT"] = {
    [0] = {2666.666666666667, -533.3333333333334, 2666.666666666667, -533.3333333333334},    --TheCullingofStratholme
}
Twm_mapareas["Ulduar70"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 2666.666666666667, 0},    --HallsofStone
}
Twm_mapareas["DrakTheronKeep"] = {
    [0] = {1066.6666666666667, -1600, 1066.6666666666667, -1600},    --Drak'TharonKeep
}
Twm_mapareas["Azjol_Uppercity"] = {
    [0] = {1600, -533.3333333333334, 1600, -533.3333333333334},    --AzjolNerub
}
Twm_mapareas["Ulduar80"] = {
    [0] = {2133.3333333333335, -1600, 2666.666666666667, -1066.6666666666667},    --HallsofLightning
}
Twm_mapareas["GunDrak"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 3200, 533.3333333333334},    --Gundrak
}
Twm_mapareas["DalaranPrison"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 3200, 533.3333333333334},    --VioletHold
}
Twm_mapareas["Azjol_LowerCity"] = {
    [0] = {1066.6666666666667, -2666.666666666667, 2666.666666666667, -1066.6666666666667},    --Ahn'kahetTheOldKingdom
}
Twm_mapareas["IcecrownCitadel5Man"] = {
    [0] = {3200, 1600, 5866.666666666667, 4800},    --TheForgeofSouls
}
Twm_mapareas["AbyssalMaw"] = {
    [0] = {1600, -1066.6666666666667, 1600, -1066.6666666666667},    --AbyssalMawExterior
}
Twm_mapareas["AbyssalMaw_Interior"] = {
    [0] = {1600, 0, 533.3333333333334, -1066.6666666666667},    --ThroneoftheTides
}
Twm_mapareas["Uldum"] = {
    [0] = {1600, -1600, 533.3333333333334, -2133.3333333333335},    --HallsofOrigination
}
Twm_mapareas["BlackRockSpire_4_0"] = {
    [0] = {1600, 0, 1066.6666666666667, -533.3333333333334},    --BlackrockCaverns
}
Twm_mapareas["ArgentTournamentDungeon"] = {
    [0] = {2133.3333333333335, 0, 2133.3333333333335, 0},    --TrialoftheChampion
}
Twm_mapareas["SkywallDungeon"] = {
    [0] = {1600, -1066.6666666666667, 533.3333333333334, -2133.3333333333335},    --TheVortexPinnacle
}
Twm_mapareas["QuarryofTears"] = {
    [0] = {1066.6666666666667, -533.3333333333334, 1600, 0},    --PitofSaron
}
Twm_mapareas["HallsOfReflection"] = {
    [0] = {2666.666666666667, 533.3333333333334, 6400, 3733.3333333333335},    --HallsofReflection
}
Twm_mapareas["GrimBatolDungeon"] = {
    [0] = {533.3333333333334, -1600, 533.3333333333334, -1600},    --GrimBatol
}
Twm_mapareas["Firelands2"] = {
    [0] = {1066.6666666666667, -1066.6666666666667, 1066.6666666666667, -1066.6666666666667},    --FirelandsTerrain2
}
Twm_mapareas["DeepholmeDungeon"] = {
    [0] = {2133.3333333333335, 0, 2133.3333333333335, 0},    --TheStonecore
}
Twm_mapareas["AhnQirajTerrace"] = {
    [0] = {2133.3333333333335, 1066.6666666666667, -8533.333333333334, -9600},    --Ahn'QirajTerrace
}
Twm_mapareas["UldumDungeon"] = {
    [0] = {-533.3333333333334, -2666.666666666667, -10133.333333333334, -12266.666666666668},    --LostCityoftheTol'vir
}
Twm_mapareas["Zul_Gurub5Man"] = {
    [0] = {-533.3333333333334, -3200, -10666.666666666668, -13333.333333333334},    --Zul'Gurub
}
Twm_mapareas["COTDragonblight"] = {
    [0] = {2666.666666666667, -1066.6666666666667, 5866.666666666667, 2133.3333333333335},    --EndTime
}
Twm_mapareas["COTWarOfTheAncients"] = {
    [0] = {-4266.666666666667, -6933.333333333334, 4800, 2133.3333333333335},    --WellofEternity
}
Twm_mapareas["TheHourOfTwilight"] = {
    [0] = {2133.3333333333335, -1600, 5333.333333333334, 1066.6666666666667},    --HourofTwilight
}
Twm_mapareas["NexusLegendary"] = {
    [0] = {8000.000000000001, 6400, 4800, 3200},    --NexusLegendary
}
Twm_mapareas["ShadowpanHideout"] = {
    [0] = {4266.666666666667, 1600, 4800, 2133.3333333333335},    --ShadoPanMonastery
}
Twm_mapareas["EastTemple"] = {
    [0] = {-1600, -4266.666666666667, 2666.666666666667, -533.3333333333334},    --TempleoftheJadeSerpent
}
Twm_mapareas["StormstoutBrewery"] = {
    [0] = {3200, -533.3333333333334, 1066.6666666666667, -2666.666666666667},    --StormstoutBrewery
}
Twm_mapareas["TheGreatWall"] = {
    [0] = {3733.3333333333335, 0, 4266.666666666667, 0},    --GateoftheSettingSun
}
Twm_mapareas["MaelstromDeathwingFight"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 2133.3333333333335, -533.3333333333334},    --MaelstromDeathwingFight
}
Twm_mapareas["MoguDungeon"] = {
    [0] = {-1066.6666666666667, -3733.3333333333335, -3200, -5333.333333333334},    --Mogu'shanPalace
}
Twm_mapareas["ScarletSanctuaryArmoryAndLibrary"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 1600, 0},    --ScarletHalls
}
Twm_mapareas["ScarletMonasteryCathedralGY"] = {
    [0] = {1066.6666666666667, 0, 2133.3333333333335, 533.3333333333334},    --ScarletMonastery
}
Twm_mapareas["NewScholomance"] = {
    [0] = {533.3333333333334, -533.3333333333334, 533.3333333333334, -533.3333333333334},    --Scholomance
}
Twm_mapareas["MantidDungeon"] = {
    [0] = {6400, 4266.666666666667, 2666.666666666667, 533.3333333333334},    --SiegeofNiuzaoTemple
}
Twm_mapareas["PetBattleJadeForest"] = {
    [0] = {533.3333333333334, -1066.6666666666667, 3200, 1066.6666666666667},    --PetBattleJadeForest
}
Twm_mapareas["StormwindJail"] = {
    [0] = {17218.487864176434, 16885.206011454266, 17263.965418497723, 16998.67827097575},    --StormwindStockade
}
Twm_mapareas["WailingCaverns"] = {
    [0] = {17605.045633951824, 16574.28184000651, 17254.170588175457, 16521.60738627116},    --WailingCaverns
}
Twm_mapareas["Blackfathom"] = {
    [0] = {17490.690928141277, 16403.813408533733, 16989.84884897868, 16031.55301920573},    --BlackfathomDeeps
}
Twm_mapareas["Uldaman"] = {
    [0] = {17533.000376383465, 16980.93195215861, 17250.97295633952, 16686.795572916668},    --Uldaman
}
Twm_mapareas["GnomeragonInstance"] = {
    [0] = {17822.827555338543, 16890.97662226359, 16865.778330485027, 16060.008219401043},    --Gnomeregan
}
Twm_mapareas["SunkenTemple"] = {
    [0] = {17390.762858072918, 16901.056402842205, 16821.500513712566, 16326.146891276043},    --SunkenTemple
}
Twm_mapareas["BlackRockSpire"] = {
    [0] = {17192.587176005047, 16438.351450602215, 17401.064463297527, 16800.820475260418},    --BlackrockSpire
}
Twm_mapareas["BlackrockDepths"] = {
    [0] = {17331.952799479168, 16102.661478678387, 18553.343180338543, 17240.43793741862},    --BlackrockDepths
}
Twm_mapareas["Mauradon"] = {
    [0] = {17360.026438395184, 16183.290629069012, 18235.53739420573, 16827.60458056132},    --Maraudon
}
Twm_mapareas["OrgrimmarInstance"] = {
    [0] = {17342.04572550456, 16859.836580912273, 17169.622332255047, 16625.407908121746},    --RagefireChasm
}
Twm_mapareas["DireMaul"] = {
    [0] = {18050.113627115887, 16170.778971354168, 17994.42460123698, 16480.373423258465},    --DireMaul
}
Twm_mapareas["HellfireMilitary"] = {
    [0] = {17418.420267740887, 16795.392148653667, 17644.08378092448, 17011.36508623759},    --HellfireCitadelTheShatteredHalls
}
Twm_mapareas["HellfireDemon"] = {
    [0] = {17280.026896158855, 16727.105353037517, 17619.802469889324, 17002.104090372723},    --HellfireCitadelTheBloodFurnace
}
Twm_mapareas["CoilfangPumping"] = {
    [0] = {17096.85901705424, 16364.733835856121, 17195.23334757487, 16626.067804972332},    --CoilfangTheSteamvault
}
Twm_mapareas["CoilfangMarsh"] = {
    [0] = {17252.635965983074, 16356.635965983074, 17490.401255289715, 16850.401255289715},    --CoilfangTheUnderbog
}
Twm_mapareas["CoilfangDraenei"] = {
    [0] = {17105.60076014201, 16190.860087076824, 17221.748224894207, 16689.03096262614},    --CoilfangTheSlavePens
}
Twm_mapareas["TempestKeepArcane"] = {
    [0] = {17308.113489786785, 16632.0145594279, 17609.69883219401, 16964.503580729168},    --TempestKeepTheArcatraz
}
Twm_mapareas["TempestKeepAtrium"] = {
    [0] = {17702.825236002605, 16864.841028849285, 17294.574427286785, 16777.930353800457},    --TempestKeepTheBotanica
}
Twm_mapareas["TempestKeepFactory"] = {
    [0] = {17272.270441691082, 16781.989969889324, 17416.652842203777, 16904.948691050213},    --TempestKeepTheMechanar
}
Twm_mapareas["AuchindounShadow"] = {
    [0] = {17144.96206156413, 16496.24668375651, 17147.630327860516, 16483.29407755534},    --AuchindounShadowLabyrinth
}
Twm_mapareas["AuchindounDemon"] = {
    [0] = {17445.58332316081, 17000.728640238445, 17230.32062784831, 16735.90102640788},    --AuchindounSethekkHalls
}
Twm_mapareas["AuchindounEthereal"] = {
    [0] = {17126.672491709392, 16666.87514750163, 17146.737497965496, 16621.250498453777},    --AuchindounManaTombs
}
Twm_mapareas["AuchindounDraenei"] = {
    [0] = {17117.80312983195, 16601.993570963543, 17361.61728922526, 16757.945646921795},    --AuchindounAuchenaiCrypts
}
Twm_mapareas["Nexus70"] = {
    [0] = {17303.32041422526, 16398.37301127116, 17864.929850260418, 17146.294443766277},    --TheNexus
}
