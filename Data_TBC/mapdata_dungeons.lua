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
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_DungeonNames = {
    {
        key = "AuchindounDraenei",
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
        key = "Blackfathom",
        expansion = "0",
        name = {
            enUS = "Blackfathom Deeps",
            deDE = "Tiefschwarze Grotte",
            esES = "Cavernas de Brazanegra",
            esMX = "Cavernas de Brazanegra",
            frFR = "Profondeurs de Brassenoire",
            itIT = "Blackfathom Deeps",
            koKR = "검은심연의 나락",
            ptBR = "Profundezas Negras",
            ruRU = "Непроглядная Пучина",
            zhCN = "黑暗深渊",
            zhTW = "黑暗深淵",
        },
    },
    {
        key = "BlackrockDepths",
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
            ruRU = "Вершина Черной горы",
            zhCN = "黑石塔",
            zhTW = "黑石塔",
        },
    },
    {
        key = "CoilfangDraenei",
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
        key = "HellfireRampart",
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
        key = "Sunwell5ManFix",
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
        key = "CavernsOfTime",
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
        key = "OrgrimmarInstance",
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
        key = "MonasteryInstances",
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
        key = "Shadowfang",
        expansion = "0",
        name = {
            enUS = "Shadowfang Keep",
            deDE = "Burg Schattenfang",
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
        key = "StormwindJail",
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
        key = "HillsbradPast",
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
        key = "Uldaman",
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
Twm_mapareas["RazorfenDowns"] = {
    [0] = {2666.666666666667, -533.3333333333334, 3200, 1066.6666666666667},    --RazorfenDowns
}
Twm_mapareas["MonasteryInstances"] = {
    [0] = {2133.3333333333335, -1066.6666666666667, 2666.666666666667, -533.3333333333334},    --ScarletMonastery
}
Twm_mapareas["TanarisInstance"] = {
    [0] = {1600, 0, 2666.666666666667, -1066.6666666666667},    --Zul'Farrak
}
Twm_mapareas["CavernsOfTime"] = {
    [0] = {8000.000000000001, -533.3333333333334, 3733.3333333333335, -2666.666666666667},    --OpeningoftheDarkPortal
}
Twm_mapareas["SchoolofNecromancy"] = {
    [0] = {1066.6666666666667, -1066.6666666666667, 1600, -533.3333333333334},    --Scholomance
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
Twm_mapareas["Sunwell5ManFix"] = {
    [0] = {2666.666666666667, -2666.666666666667, 2666.666666666667, -1066.6666666666667},    --Magister'sTerrace
}
Twm_mapareas["StormwindJail"] = {
    [0] = {17216.996500651043, 16883.714647928875, 17263.965418497723, 16998.67827097575},    --StormwindStockade
}
Twm_mapareas["WailingCaverns"] = {
    [0] = {17436.444529215496, 16389.698496500652, 17254.170588175457, 16496.095240275066},    --WailingCaverns
}
Twm_mapareas["Blackfathom"] = {
    [0] = {17569.062266031902, 16482.18474642436, 16989.84884897868, 16031.55301920573},    --BlackfathomDeeps
}
Twm_mapareas["Uldaman"] = {
    [0] = {17136.43044535319, 16584.362021128338, 17250.97295633952, 16686.795572916668},    --Uldaman
}
Twm_mapareas["GnomeragonInstance"] = {
    [0] = {17208.704844156902, 16276.853911081951, 16865.778330485027, 16060.008158365887},    --Gnomeregan
}
Twm_mapareas["SunkenTemple"] = {
    [0] = {17200.276301066082, 16710.569826761883, 16821.500513712566, 16326.146891276043},    --SunkenTemple
}
Twm_mapareas["BlackRockSpire"] = {
    [0] = {17658.252176920574, 16904.016451517742, 17401.064463297527, 16800.820475260418},    --BlackrockSpire
}
Twm_mapareas["BlackrockDepths"] = {
    [0] = {17914.34275309245, 16685.051432291668, 18553.343180338543, 17240.43793741862},    --BlackrockDepths
}
Twm_mapareas["Mauradon"] = {
    [0] = {17878.167704264324, 16701.431894938152, 18235.53739420573, 16827.604578653973},    --Maraudon
}
Twm_mapareas["OrgrimmarInstance"] = {
    [0] = {17175.16726175944, 16692.958117167156, 17169.622332255047, 16625.407908121746},    --RagefireChasm
}
Twm_mapareas["DireMaul"] = {
    [0] = {18065.973185221355, 16083.21970621745, 18072.797892252605, 16678.93436686198},    --DireMaul
}
Twm_mapareas["HellfireMilitary"] = {
    [0] = {17219.951578776043, 16596.923459688824, 17644.08378092448, 17011.36508623759},    --HellfireCitadelTheShatteredHalls
}
Twm_mapareas["HellfireDemon"] = {
    [0] = {17285.568766276043, 16732.647223154705, 17619.802469889324, 17002.104090372723},    --HellfireCitadelTheBloodFurnace
}
Twm_mapareas["CoilfangPumping"] = {
    [0] = {17673.578653971355, 16941.453472773235, 17195.23334757487, 16626.067804972332},    --CoilfangTheSteamvault
}
Twm_mapareas["CoilfangMarsh"] = {
    [0] = {17665.601481119793, 16769.601481119793, 17490.401255289715, 16850.401255289715},    --CoilfangTheUnderbog
}
Twm_mapareas["CoilfangDraenei"] = {
    [0] = {17887.790934244793, 16973.050261179607, 17221.748224894207, 16689.03096262614},    --CoilfangTheSlavePens
}
Twm_mapareas["TempestKeepArcane"] = {
    [0] = {17375.638712565105, 16699.53978220622, 17609.69883219401, 16964.503580729168},    --TempestKeepTheArcatraz
}
Twm_mapareas["TempestKeepAtrium"] = {
    [0] = {17160.72129313151, 16322.737085978191, 17294.574427286785, 16777.930353800457},    --TempestKeepTheBotanica
}
Twm_mapareas["TempestKeepFactory"] = {
    [0] = {17279.591868082684, 16789.311396280926, 17416.652842203777, 16904.948691050213},    --TempestKeepTheMechanar
}
Twm_mapareas["AuchindounShadow"] = {
    [0] = {17617.326029459637, 16968.61065165202, 17147.630327860516, 16483.29407755534},    --AuchindounShadowLabyrinth
}
Twm_mapareas["AuchindounDemon"] = {
    [0] = {17117.484511057537, 16672.629828135174, 17230.32062784831, 16735.90102640788},    --AuchindounSethekkHalls
}
Twm_mapareas["AuchindounEthereal"] = {
    [0] = {17356.088877360027, 16896.291533152264, 17146.737497965496, 16621.250498453777},    --AuchindounManaTombs
}
Twm_mapareas["AuchindounDraenei"] = {
    [0] = {17505.229166666668, 16989.41960779826, 17361.61728922526, 16757.945646921795},    --AuchindounAuchenaiCrypts
}
