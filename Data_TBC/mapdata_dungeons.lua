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
-- `alias` ({ <locale> = {names} }, optional) are other names the map is known
-- by (dungeon finder, top-level area names) -- only for comparing, never shown.
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_DungeonNames = {
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
        alias = {
            enUS = {"Auchindoun - Auchenai Crypts", "Auchenai Crypts"},
            deDE = {"Auchindoun - Auchenaikrypta", "Auchenaikrypta"},
            esES = {"Criptas Auchenai"},
            esMX = {"Auchindoun - Criptas Auchenai", "Criptas Auchenai"},
            frFR = {"Auchindoun - Cryptes Auchenaï", "Cryptes Auchenaï"},
            itIT = {"Auchindoun - Auchenai Crypts", "Auchenai Crypts"},
            koKR = {"아킨둔 - 아키나이 납골당", "아키나이 납골당"},
            ptBR = {"Auchindoun - Catacumbas Auchenai", "Catacumbas Auchenai"},
            ruRU = {"Аукенайские гробницы"},
            zhCN = {"奥金顿 - 奥金尼地穴", "奥金顿 - 奥金尼地穴（英雄）", "奥金尼地穴"},
            zhTW = {"奧齊頓 - 奧奇奈地穴", "奧奇奈地穴"},
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
        alias = {
            enUS = {"Auchindoun - Mana Tombs", "Mana-Tombs"},
            deDE = {"Auchindoun - Managruft", "Managruft"},
            esES = {"Tumbas de Maná"},
            esMX = {"Auchindoun - Tumbas de Maná", "Tumbas de Maná"},
            frFR = {"Auchindoun - Tombes-mana", "Tombes-mana"},
            itIT = {"Auchindoun - Mana Tombs", "Mana-Tombs"},
            koKR = {"아킨둔 - 마나 무덤", "마나 무덤"},
            ptBR = {"Auchindoun - Tumbas de Mana", "Tumbas de Mana"},
            ruRU = {"Гробницы маны"},
            zhCN = {"奥金顿 - 法力墓穴", "奥金顿 - 法力墓穴（英雄）", "法力陵墓"},
            zhTW = {"奧齊頓 - 法力墓地", "法力墓地"},
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
        alias = {
            enUS = {"Auchindoun - Sethekk Halls", "Sethekk Halls"},
            deDE = {"Auchindoun - Sethekkhallen", "Sethekkhallen"},
            esES = {"Salas Sethekk"},
            esMX = {"Auchindoun - Salas Sethekk", "Salas Sethekk"},
            frFR = {"Auchindoun - Salles des Sethekk", "Les salles des Sethekk"},
            itIT = {"Auchindoun - Sethekk Halls", "Sethekk Halls"},
            koKR = {"아킨둔 - 세데크 전당", "세데크 전당"},
            ptBR = {"Auchindoun - Salões dos Sethekk", "Salões dos Sethekk"},
            ruRU = {"Сетеккские залы"},
            zhCN = {"奥金顿 - 塞泰克大厅", "奥金顿 - 塞泰克大厅（英雄）", "塞泰克大厅"},
            zhTW = {"奧齊頓 - 塞司克大廳", "塞司克大廳"},
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
        alias = {
            enUS = {"Auchindoun - Shadow Labyrinth", "Shadow Labyrinth"},
            deDE = {"Auchindoun - Schattenlabyrinth", "Schattenlabyrinth"},
            esES = {"Laberinto de las Sombras"},
            esMX = {"Auchindoun - Laberinto de las Sombras", "Laberinto de las Sombras"},
            frFR = {"Auchindoun - Labyrinthe des Ombres", "Labyrinthe des ombres"},
            itIT = {"Auchindoun - Shadow Labyrinth", "Shadow Labyrinth"},
            koKR = {"아킨둔 - 어둠의 미궁", "어둠의 미궁"},
            ptBR = {"Auchindoun - Labirinto Soturno", "Labirinto Soturno"},
            ruRU = {"Темный лабиринт"},
            zhCN = {"奥金顿 - 暗影迷宫", "奥金顿 - 暗影迷宫（英雄）", "暗影迷宫"},
            zhTW = {"奧齊頓 - 暗影迷宮", "暗影迷宮"},
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
            koKR = "검은심연의 나락",
            ptBR = "Profundezas Negras",
            ruRU = "Непроглядная Пучина",
            zhCN = "黑暗深渊",
            zhTW = "黑暗深淵",
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
            ruRU = "Вершина Черной горы",
            zhCN = "黑石塔",
            zhTW = "黑石塔",
        },
        alias = {
            enUS = {"Lower Blackrock Spire"},
            deDE = {"Untere Schwarzfelsspitze"},
            esES = {"Cumbre de Roca Negra inferior"},
            esMX = {"Cumbre de Roca Negra inferior"},
            frFR = {"Bas du pic Rochenoire"},
            itIT = {"Lower Blackrock Spire"},
            koKR = {"검은바위 첨탑 하층"},
            ptBR = {"Pico da Rocha Negra Inferior"},
            ruRU = {"Нижняя часть пика Черной горы"},
            zhCN = {"黑石塔下层"},
            zhTW = {"黑石塔下層"},
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
        alias = {
            enUS = {"Coilfang - Slave Pens", "The Slave Pens"},
            deDE = {"Echsenkessel - Sklavenunterkünfte", "Die Sklavenunterkünfte"},
            esES = {"Recinto de los Esclavos"},
            esMX = {"Colmillo Torcido - Recinto de los Esclavos", "Recinto de los Esclavos"},
            frFR = {"Glissecroc - Enclos aux esclaves", "Les enclos aux esclaves"},
            itIT = {"Coilfang - Slave Pens", "The Slave Pens"},
            koKR = {"갈퀴송곳니 저수지 - 강제 노역소", "강제 노역소"},
            ptBR = {"Presacurva - Pátio dos Escravos", "Pátio dos Escravos"},
            ruRU = {"Кривой Клык: Узилище", "Узилище"},
            zhCN = {"盘牙水库 - 奴隶围栏", "盘牙水库 - 奴隶围栏（英雄）", "奴隶围栏"},
            zhTW = {"盤牙 - 奴隸監獄", "奴隸監獄"},
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
        alias = {
            enUS = {"Coilfang - Steam Vaults", "The Steamvault"},
            deDE = {"Echsenkessel - Dampfkammer", "Die Dampfkammer"},
            esES = {"Colmillo Torcido: Cámaras de Vapor", "La Cámara de Vapor"},
            esMX = {"Colmillo Torcido - Cámaras de Vapor", "La Cámara de Vapor"},
            frFR = {"Glissecroc - Caveaux de la vapeur", "Le Caveau de la vapeur"},
            itIT = {"Coilfang - Steam Vaults", "The Steamvault"},
            koKR = {"갈퀴송곳니 저수지 - 증기 저장고", "증기 저장고"},
            ptBR = {"Presacurva - Câmaras dos Vapores", "Câmara dos Vapores"},
            ruRU = {"Паровое подземелье"},
            zhCN = {"盘牙水库 - 蒸汽地窟", "盘牙水库 - 蒸汽地窟（英雄）", "蒸汽地窟"},
            zhTW = {"盤牙 - 蒸汽洞窟", "蒸汽洞窟"},
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
        alias = {
            enUS = {"Coilfang - Underbog", "The Underbog"},
            deDE = {"Echsenkessel - Tiefensumpf", "Der Tiefensumpf"},
            esES = {"Colmillo Torcido: Sotiénaga", "La Sotiénaga"},
            esMX = {"Colmillo Torcido - Sotiénaga", "La Sotiénaga"},
            frFR = {"Glissecroc - Basse-tourbière", "La Basse-tourbière"},
            itIT = {"Coilfang - Underbog", "The Underbog"},
            koKR = {"갈퀴송곳니 저수지 - 지하수렁", "지하수렁"},
            ptBR = {"Presacurva - Brejo Oculto", "Brejo Oculto"},
            ruRU = {"Нижетопь"},
            zhCN = {"盘牙水库 - 幽暗沼泽", "盘牙水库 - 幽暗沼泽（英雄）", "幽暗沼泽"},
            zhTW = {"盤牙 - 深幽泥沼", "深幽泥沼"},
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
        alias = {
            enUS = {"UNUSED Westfall", "The Great Sea", "Unused Ironcladcove", "The Deadmines"},
            deDE = {"UNUSED Westfall", "Das große Meer", "Unused Ironcladcove", "Die Todesminen"},
            esES = {"UNUSED Westfall", "Mare Magnum", "Unused Ironcladcove", "Las Minas de la Muerte"},
            esMX = {"UNUSED Westfall", "Mare Magnum", "Unused Ironcladcove", "Las Minas de la Muerte"},
            frFR = {"UNUSED Westfall", "La Grande mer", "Unused Ironcladcove", "Les Mortemines"},
            itIT = {"UNUSED Westfall", "The Great Sea", "Unused Ironcladcove", "The Deadmines"},
            koKR = {"UNUSED Westfall", "대해", "Unused Ironcladcove"},
            ptBR = {"UNUSED Westfall", "O Grande Oceano", "Unused Ironcladcove"},
            ruRU = {"UNUSED Westfall", "Великое море", "Unused Ironcladcove"},
            zhCN = {"UNUSED Westfall", "无尽之海", "Unused Ironcladcove"},
            zhTW = {"UNUSED Westfall", "無盡之海", "Unused Ironcladcove"},
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
        alias = {
            enUS = {"Dire Maul - East", "Dire Maul - West", "Dire Maul - North"},
            deDE = {"Düsterbruch - Ost", "Düsterbruch - West", "Düsterbruch - Nord"},
            esES = {"La Masacre: Este", "La Masacre: Oeste", "La Masacre: Norte"},
            esMX = {"La Masacre: Este", "La Masacre: Oeste", "La Masacre: Norte"},
            frFR = {"Haches-Tripes - Est", "Haches-Tripes - Ouest", "Haches-Tripes - Nord"},
            itIT = {"Dire Maul - East", "Dire Maul - West", "Dire Maul - North"},
            koKR = {"혈투의 전장 - 동쪽", "혈투의 전장 - 서쪽", "혈투의 전장 - 북쪽"},
            ptBR = {"Gládio Cruel – Leste", "Gládio Cruel – Oeste", "Gládio Cruel – Norte"},
            ruRU = {"Забытый город: восток", "Забытый город: запад", "Забытый город: север"},
            zhCN = {"厄运之槌 - 东", "厄运之槌 - 西", "厄运之槌 - 北"},
            zhTW = {"厄運之槌 - 東方", "厄運之槌 - 西方", "厄運之槌 - 北方"},
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
        alias = {
            enUS = {"Hellfire Citadel - Hellfire Ramparts", "Hellfire Ramparts"},
            deDE = {"Höllenfeuerzitadelle - Höllenfeuerbollwerk", "Höllenfeuerbollwerk"},
            esES = {"Ciudadela del Fuego Infernal: Murallas del Fuego Infernal", "Murallas del Fuego Infernal"},
            esMX = {"Ciudadela del Fuego Infernal - Murallas del Fuego Infernal", "Ciudadela del Fuego Infernal - Murallas Fuego Infernal", "Murallas del Fuego Infernal"},
            frFR = {"Citadelle des Flammes infernales - Remparts", "Remparts des Flammes infernales"},
            itIT = {"Hellfire Citadel - Hellfire Ramparts", "Hellfire Ramparts"},
            koKR = {"지옥불 성채 - 지옥불 성루", "지옥불 성루"},
            ptBR = {"Cidadela Fogo do Inferno - Muralha Fogo do Inferno", "Muralha Fogo do Inferno"},
            ruRU = {"Бастионы Адского Пламени"},
            zhCN = {"地狱火堡垒 - 地狱火城墙", "地狱火堡垒 - 地狱火城墙（英雄）", "地狱火城墙"},
            zhTW = {"地獄火堡壘 - 地獄火壁壘", "地獄火壁壘"},
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
        alias = {
            enUS = {"Hellfire Citadel - Blood Furnace", "The Blood Furnace"},
            deDE = {"Höllenfeuerzitadelle - Blutkessel", "Der Blutkessel"},
            esES = {"El Horno de Sangre"},
            esMX = {"Ciudadela del Fuego Infernal - Horno de Sangre", "El Horno de Sangre"},
            frFR = {"Citadelle des Flammes infernales - Fournaise du sang", "La Fournaise du sang"},
            itIT = {"Hellfire Citadel - Blood Furnace", "The Blood Furnace"},
            koKR = {"지옥불 성채 - 피의 용광로", "피의 용광로"},
            ptBR = {"Cidadela Fogo do Inferno - Fornalha de Sangue", "Fornalha de Sangue"},
            ruRU = {"Кузня Крови"},
            zhCN = {"地狱火堡垒 - 鲜血熔炉", "地狱火堡垒 - 鲜血熔炉（英雄）", "鲜血熔炉"},
            zhTW = {"地獄火堡壘 - 血熔爐", "血熔爐"},
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
        alias = {
            enUS = {"Hellfire Citadel - Shattered Halls", "Hellfire Citadel", "The Shattered Halls"},
            deDE = {"Höllenfeuerzitadelle - Zerschmetterte Hallen", "Höllenfeuerzitadelle", "Die Zerschmetterten Hallen"},
            esES = {"Ciudadela del Fuego Infernal", "Las Salas Arrasadas"},
            esMX = {"Ciudadela del Fuego Infernal - Las Salas Arrasadas", "Ciudadela del Fuego Infernal", "Las Salas Arrasadas"},
            frFR = {"Citadelle des Flammes infernales - Salles brisées", "Citadelle des Flammes infernales", "Les Salles brisées"},
            itIT = {"Hellfire Citadel - Shattered Halls", "Hellfire Citadel", "The Shattered Halls"},
            koKR = {"지옥불 성채 - 으스러진 손의 전당", "지옥불 성채", "으스러진 손의 전당"},
            ptBR = {"Cidadela Fogo do Inferno - Salões Despedaçados", "Cidadela Fogo do Inferno", "Salões Despedaçados"},
            ruRU = {"Цитадель Адского Пламени", "Разрушенные залы"},
            zhCN = {"地狱火堡垒 - 破碎大厅", "地狱火堡垒 - 破碎大厅（英雄）", "地狱火堡垒", "破碎大厅"},
            zhTW = {"地獄火堡壘 - 破碎大廳", "地獄火堡壘", "破碎大廳"},
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
        alias = {
            enUS = {"Magisters' Terrace"},
            itIT = {"Magisters' Terrace"},
            zhCN = {"魔导师平台（英雄）"},
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
        alias = {
            enUS = {"Caverns of Time - Dark Portal", "The Black Morass"},
            deDE = {"Höhlen der Zeit - Dunkles Portal", "Der schwarze Morast"},
            esES = {"Cavernas del Tiempo: Portal Oscuro", "La Ciénaga Negra"},
            esMX = {"Cavernas del Tiempo - Portal Oscuro", "La Ciénaga Negra"},
            frFR = {"Grottes du Temps - Porte des Ténèbres", "Le Noir Marécage"},
            itIT = {"Caverns of Time - Dark Portal", "The Black Morass"},
            koKR = {"시간의 동굴 - 어둠의 문", "검은늪"},
            ptBR = {"Cavernas do Tempo - Portal Negro", "Lamaçal Negro"},
            ruRU = {"Пещеры Времени: Темный портал", "Черные топи"},
            zhCN = {"时光之穴 - 黑暗之门", "时光之穴 - 黑暗之门（英雄）", "黑色沼泽"},
            zhTW = {"時光之穴 - 黑暗之門", "黑色沼澤"},
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
        alias = {
            deDE = {"Flammenschlund"},
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
        alias = {
            enUS = {"Scarlet Monastery - Graveyard", "Scarlet Monastery - Armory", "Scarlet Monastery - Cathedral", "Scarlet Monastery - Library"},
            deDE = {"Scharlachrotes Kloster - Friedhof", "Scharlachrotes Kloster - Waffenkammer", "Scharlachrotes Kloster - Kathedrale", "Scharlachrotes Kloster - Bibliothek", "Das Scharlachrote Kloster"},
            esES = {"Monasterio Escarlata: Cementerio", "Monasterio Escarlata: Armería", "Monasterio Escarlata: Catedral", "Monasterio Escarlata: Biblioteca"},
            esMX = {"Monasterio Escarlata - Cementerio", "Monasterio Escarlata - Arsenal", "Monasterio Escarlata - Catedral", "Monasterio Escarlata - Biblioteca"},
            frFR = {"Monastère Écarlate - cimetière", "Monastère Écarlate - armurerie", "Monastère Écarlate - cathédrale", "Monastère Écarlate - bibliothèque"},
            itIT = {"Scarlet Monastery - Graveyard", "Scarlet Monastery - Armory", "Scarlet Monastery - Cathedral", "Scarlet Monastery - Library"},
            koKR = {"붉은십자군 수도원 - 묘지", "붉은십자군 수도원 - 무기고", "붉은십자군 수도원 - 대성당", "붉은십자군 수도원 - 도서관"},
            ptBR = {"Monastério Escarlate - Cemitério", "Monastério Escarlate - Armaria", "Monastério Escarlate - Catedral", "Monastério Escarlate - Biblioteca"},
            ruRU = {"Монастырь Алого ордена: кладбище", "Монастырь Алого ордена: оружейная", "Монастырь Алого ордена: собор", "Монастырь Алого ордена: библиотека"},
            zhCN = {"血色修道院 - 墓地", "血色修道院 - 军械库", "血色修道院 - 教堂", "血色修道院 - 图书馆"},
            zhTW = {"血色修道院 - 墓園", "血色修道院 - 軍械庫", "血色修道院 - 教堂", "血色修道院 - 圖書館"},
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
        key = "Shadowfang",
        mapID = "33",
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
        alias = {
            frFR = {"Donjon d’Ombrecroc"},
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
        alias = {
            enUS = {"Stormwind Stockades", "The Stockade"},
            deDE = {"Das Verlies"},
            esES = {"Las Mazmorras"},
            esMX = {"Las Mazmorras"},
            frFR = {"La Prison"},
            itIT = {"Stormwind Stockades", "The Stockade"},
            ptBR = {"O Cárcere"},
            ruRU = {"Тюрьма"},
            zhCN = {"监狱"},
            zhTW = {"監獄"},
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
        alias = {
            enUS = {"The Temple of Atal'Hakkar"},
            deDE = {"Der Tempel von Atal'Hakkar"},
            esES = {"El Templo de Atal'Hakkar"},
            esMX = {"El Templo de Atal'Hakkar"},
            frFR = {"Le temple d'Atal'Hakkar"},
            itIT = {"The Temple of Atal'Hakkar"},
            koKR = {"아탈학카르 신전"},
            ptBR = {"Templo de Atal'Hakkar"},
            ruRU = {"Храм Атал'Хаккар"},
            zhCN = {"阿塔哈卡神庙"},
            zhTW = {"阿塔哈卡神廟"},
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
        alias = {
            enUS = {"Tempest Keep - The Arcatraz", "The Arcatraz"},
            deDE = {"Festung der Stürme - Arkatraz", "Die Arkatraz"},
            esES = {"El Arcatraz"},
            esMX = {"El Castillo de la Tempestad - El Arcatraz", "El Arcatraz"},
            frFR = {"Donjon de la Tempête - L’Arcatraz", "L'Arcatraz"},
            itIT = {"Tempest Keep - The Arcatraz", "The Arcatraz"},
            koKR = {"폭풍우 요새 - 알카트라즈", "알카트라즈"},
            ptBR = {"Bastilha da Tormenta - Arcatraz", "Arcatraz"},
            ruRU = {"The Arcatraz"},
            zhCN = {"风暴要塞 - 禁魔监狱", "风暴要塞 - 禁魔监狱（英雄）", "禁魔监狱"},
            zhTW = {"風暴要塞 - 亞克崔茲", "亞克崔茲"},
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
        alias = {
            enUS = {"Tempest Keep - The Botanica", "The Botanica"},
            deDE = {"Festung der Stürme - Botanika", "Die Botanika"},
            esES = {"El Invernáculo"},
            esMX = {"El Castillo de la Tempestad - El Invernáculo", "El Invernáculo"},
            frFR = {"Donjon de la Tempête - La Botanica", "La Botanica"},
            itIT = {"Tempest Keep - The Botanica", "The Botanica"},
            koKR = {"폭풍우 요새 - 신록의 정원", "신록의 정원"},
            ptBR = {"Bastilha da Tormenta - Jardim Botânico", "Jardim Botânico"},
            ruRU = {"Ботаника"},
            zhCN = {"风暴要塞 - 生态船", "风暴要塞 - 生态船（英雄）", "生态船"},
            zhTW = {"風暴要塞 - 波塔尼卡", "波塔尼卡"},
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
        alias = {
            enUS = {"Tempest Keep - The Mechanar", "The Mechanar"},
            deDE = {"Festung der Stürme - Mechanar", "Die Mechanar"},
            esES = {"El Mechanar"},
            esMX = {"El Castillo de la Tempestad - El Mechanar", "El Mechanar"},
            frFR = {"Donjon de la Tempête - Le Méchanar", "Le Méchanar"},
            itIT = {"Tempest Keep - The Mechanar", "The Mechanar"},
            koKR = {"폭풍우 요새 - 메카나르", "메카나르"},
            ptBR = {"Bastilha da Tormenta - Mecanar", "Mecanar"},
            ruRU = {"Механар"},
            zhCN = {"风暴要塞 - 能源舰", "风暴要塞 - 能源舰（英雄）", "能源舰"},
            zhTW = {"風暴要塞 - 麥克納爾", "麥克納爾"},
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
        alias = {
            enUS = {"Caverns of Time - Durnholde", "Old Hillsbrad Foothills", "Hyjal Past"},
            deDE = {"Höhlen der Zeit - Durnholde", "Vorgebirge des Alten Hügellands", "Hyjal der Vergangenheit"},
            esES = {"Cavernas del Tiempo: Durnholde", "Antiguas Laderas de Trabalomas", "El Pasado Hyjal"},
            esMX = {"Cavernas del Tiempo - Durnholde", "Antiguas Laderas de Trabalomas", "El Pasado Hyjal"},
            frFR = {"Grottes du Temps - Fort-de-Durn", "Contreforts de Hautebrande d'antan", "Passé d'Hyjal"},
            itIT = {"Caverns of Time - Durnholde", "Old Hillsbrad Foothills", "Hyjal Past"},
            koKR = {"시간의 동굴 - 던홀드", "옛 힐스브래드 구릉지", "과거의 하이잘"},
            ptBR = {"Cavernas do Tempo - Forte do Desterro", "Antigo Contraforte de Eira dos Montes", "Hyjal Antigo"},
            ruRU = {"Пещеры Времени: Дарнхольд", "Старые предгорья Хилсбрада", "Прошлое Хиджала"},
            zhCN = {"时光之穴 - 敦霍尔德", "时光之穴 - 敦霍尔德（英雄）", "旧希尔斯布莱德丘陵", "海加尔"},
            zhTW = {"時光之穴 - 敦霍爾德", "希爾斯布萊德丘陵舊址", "海加爾廢墟"},
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
        alias = {
            deDE = {"Die Höhlen des Wehklagens"},
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
        alias = {
            frFR = {"Zul’Farrak"},
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
    [0] = {151.82119750976562, -181.46065521240234, 197.2987518310547, -67.98839569091797},    --StormwindStockade
}
Twm_mapareas["WailingCaverns"] = {
    [0] = {554.3612060546875, -492.38482666015625, 187.50392150878906, -570.5714263916016},    --WailingCaverns
}
Twm_mapareas["Blackfathom"] = {
    [0] = {424.0242614746094, -662.8532581329346, -76.81781768798828, -1035.1136474609375},    --BlackfathomDeeps
}
Twm_mapareas["Uldaman"] = {
    [0] = {466.3337097167969, -85.73471450805664, 184.30628967285156, -379.87109375},    --Uldaman
}
Twm_mapareas["GnomeragonInstance"] = {
    [0] = {756.160888671875, -175.69004440307617, -200.88833618164062, -1006.6585083007812},    --Gnomeregan
}
Twm_mapareas["SunkenTemple"] = {
    [0] = {324.0962219238281, -165.6102523803711, -245.16615295410156, -740.519775390625},    --SunkenTemple
}
Twm_mapareas["RazorfenDowns"] = {
    [0] = {1139.452814737957, 477.1406656901054, 2629.675470987957, 2249.14081255595},    --RazorfenDowns
}
Twm_mapareas["MonasteryInstances"] = {
    [0] = {1538.5705362955741, -483.5473492940255, 2030.1756083170585, 79.47466723124307},    --ScarletMonastery
}
Twm_mapareas["BlackRockSpire"] = {
    [0] = {125.9205093383789, -628.3152160644531, 334.3977966308594, -265.84619140625},    --BlackrockSpire
}
Twm_mapareas["BlackrockDepths"] = {
    [0] = {265.2861328125, -964.0051879882812, 1486.676513671875, 173.77127075195312},    --BlackrockDepths
}
Twm_mapareas["Mauradon"] = {
    [0] = {293.3597717285156, -883.3760375976562, 1168.8707275390625, -239.0620880126953},    --Maraudon
}
Twm_mapareas["OrgrimmarInstance"] = {
    [0] = {275.3790588378906, -206.83008575439453, 102.9556655883789, -441.2587585449219},    --RagefireChasm
}
Twm_mapareas["DireMaul"] = {
    [0] = {1111.4086303710938, -871.3448486328125, 1006.1312255859376, -387.7322998046875},    --DireMaul
}
Twm_mapareas["HellfireMilitary"] = {
    [0] = {351.75360107421875, -271.2745180130005, 577.4171142578125, -55.30158042907715},    --HellfireCitadelTheShatteredHalls
}
Twm_mapareas["HellfireDemon"] = {
    [0] = {213.3602294921875, -339.5613136291504, 553.1358032226562, -64.56257629394531},    --HellfireCitadelTheBloodFurnace
}
Twm_mapareas["CoilfangPumping"] = {
    [0] = {30.192350387573242, -701.9328308105469, 128.56668090820312, -440.59886169433594},    --CoilfangTheSteamvault
}
Twm_mapareas["CoilfangMarsh"] = {
    [0] = {185.96929931640625, -710.0307006835938, 423.7345886230469, -216.26541137695312},    --CoilfangTheUnderbog
}
Twm_mapareas["CoilfangDraenei"] = {
    [0] = {38.9340934753418, -875.8065795898438, 155.08155822753906, -377.63570404052734},    --CoilfangTheSlavePens
}
Twm_mapareas["TempestKeepArcane"] = {
    [0] = {241.4468231201172, -434.65210723876953, 543.0321655273438, -102.1630859375},    --TempestKeepTheArcatraz
}
Twm_mapareas["TempestKeepAtrium"] = {
    [0] = {636.1585693359375, -201.8256378173828, 227.9077606201172, -288.73631286621094},    --TempestKeepTheBotanica
}
Twm_mapareas["TempestKeepFactory"] = {
    [0] = {205.60377502441406, -284.67669677734375, 349.9861755371094, -161.71797561645508},    --TempestKeepTheMechanar
}
Twm_mapareas["AuchindounShadow"] = {
    [0] = {78.29539489746094, -570.4199829101562, 80.96366119384766, -583.3725891113281},    --AuchindounShadowLabyrinth
}
Twm_mapareas["AuchindounDemon"] = {
    [0] = {378.9166564941406, -65.93802642822266, 163.65396118164062, -330.76564025878906},    --AuchindounSethekkHalls
}
Twm_mapareas["AuchindounEthereal"] = {
    [0] = {60.00582504272461, -399.79151916503906, 80.07083129882812, -445.4161682128906},    --AuchindounManaTombs
}
Twm_mapareas["AuchindounDraenei"] = {
    [0] = {51.1364631652832, -464.673095703125, 294.95062255859375, -308.72101974487305},    --AuchindounAuchenaiCrypts
}
