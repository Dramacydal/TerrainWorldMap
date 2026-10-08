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
        alias = {
            enUS = {"The Burning of Andorhal"},
            deDE = {"Der Brand von Andorhal"},
            esES = {"Incendio de Andorhal"},
            frFR = {"L’incendie d’Andorhal"},
            itIT = {"The Burning of Andorhal"},
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
        alias = {
            enUS = {"The Black Morass", "Old Hillsbrad Foothills", "Elsewhen"},
            deDE = {"Das schwarze Fenn", "Die alten Vorgebirge von Hillsbrad", "Anderswann"},
            esES = {"Ciénaga Negra", "Antiguas Laderas de Trabalomas", "Otro Momento"},
            esMX = {"La Ciénaga Negra", "Antiguas Laderas de Trabalomas", "Otro tiempo"},
            frFR = {"Le Noir Marécage", "Anciens contreforts d'Hillsbrad", "Autretemps"},
            itIT = {"The Black Morass", "Old Hillsbrad Foothills", "Elsewhen"},
            koKR = {"검은늪", "옛 힐스브래드 구릉지", "엘스웬"},
            ptBR = {"Lamaçal Negro", "Antigo Contraforte de Eira dos Montes", "Outrora"},
            ruRU = {"Черные топи", "Старые предгорья Хилсбрада", "Гдекогда"},
            zhCN = {"黑色沼泽", "旧希尔斯布莱德丘陵", "别时别地"},
            zhTW = {"黑色沼澤", "老希爾斯布萊德丘陵", "艾爾斯溫"},
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
            enUS = {"Westfall", "The Great Sea", "Unused Ironcladcove", "***On Map Dungeon***", "The Deadmines"},
            deDE = {"Westfall", "Das große Meer", "Unused Ironcladcove", "***On Map Dungeon***", "Die Todesminen"},
            esES = {"Páramos de Poniente", "Mare Magnum", "Unused Ironcladcove", "***On Map Dungeon***", "Las Minas de la Muerte"},
            esMX = {"Páramos de Poniente", "Mare Magnum", "Unused Ironcladcove", "***On Map Dungeon***", "Las Minas de la Muerte"},
            frFR = {"Marche de l'Ouest", "La Grande mer", "Unused Ironcladcove", "***On Map Dungeon***", "Les Mortemines"},
            itIT = {"Westfall", "The Great Sea", "Unused Ironcladcove", "***On Map Dungeon***", "The Deadmines"},
            koKR = {"서부 몰락지대", "대해", "Unused Ironcladcove", "***On Map Dungeon***"},
            ptBR = {"Cerro Oeste", "O Grande Oceano", "Unused Ironcladcove", "***On Map Dungeon***"},
            ruRU = {"Западный край", "Великое море", "Unused Ironcladcove", "***On Map Dungeon***"},
            zhCN = {"西部荒野", "无尽之海", "Unused Ironcladcove", "***On Map Dungeon***"},
            zhTW = {"西部荒野", "無盡之海", "Unused Ironcladcove", "***On Map Dungeon***"},
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
        alias = {
            enUS = {"Redridge Mountains", "Blasted Lands", "Swamp of Sorrows", "Stranglethorn Vale", "Elwynn Forest", "Duskwood"},
            deDE = {"Rotkammgebirge", "Verwüstete Lande", "Sümpfe des Elends", "Schlingendorntal", "Wald von Elwynn", "Dämmerwald"},
            esES = {"Montañas Crestagrana", "Las Tierras Devastadas", "Pantano de las Penas", "Vega de Tuercespina", "Bosque de Elwynn", "Bosque del Ocaso"},
            esMX = {"Montañas Crestagrana", "Las Tierras Devastadas", "Pantano de las Penas", "Vega de Tuercespina", "Bosque de Elwynn", "Bosque del Ocaso"},
            frFR = {"Les Carmines", "Défilé de Deuillevent", "Terres foudroyées", "Marais des Chagrins", "Vallée de Strangleronce", "Forêt d’Elwynn", "Bois de la Pénombre"},
            itIT = {"Redridge Mountains", "Blasted Lands", "Swamp of Sorrows", "Stranglethorn Vale", "Elwynn Forest", "Duskwood"},
            koKR = {"붉은마루 산맥", "저주받은 땅", "슬픔의 늪", "가시덤불 골짜기", "엘윈 숲", "그늘숲"},
            ptBR = {"Montanhas Cristarrubra", "Barreira do Inferno", "Pântano das Mágoas", "Selva do Espinhaço", "Floresta de Elwynn", "Floresta do Crepúsculo"},
            ruRU = {"Красногорье", "Выжженные земли", "Болото Печали", "Тернистая долина", "Элвиннский лес", "Сумеречный лес"},
            zhCN = {"赤脊山", "诅咒之地", "悲伤沼泽", "荆棘谷", "艾尔文森林", "暮色森林"},
            zhTW = {"赤脊山", "詛咒之地", "悲傷沼澤", "荊棘谷", "艾爾文森林", "暮色森林"},
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
        alias = {
            deDE = {"Die Hügel von Razorfen"},
            esES = {"Zahúrda Rojocieno"},
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
        alias = {
            deDE = {"Der Kral von Razorfen"},
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
            deDE = {"Das Scharlachrote Kloster"},
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
        alias = {
            enUS = {"Felwood"},
            deDE = {"Teufelswald", "Die Schattenfeste"},
            esES = {"Frondavil"},
            esMX = {"Frondavil"},
            frFR = {"Gangrebois"},
            itIT = {"Felwood"},
            koKR = {"악령의 숲"},
            ptBR = {"Selva Maleva"},
            ruRU = {"Оскверненный лес"},
            zhCN = {"费伍德森林"},
            zhTW = {"費伍德森林"},
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
        alias = {
            enUS = {"Starfall Village"},
            deDE = {"Starfall"},
            esES = {"Aldea Estrella Fugaz"},
            esMX = {"Aldea Estrella Fugaz"},
            frFR = {"Pluie-d’Étoiles"},
            itIT = {"Starfall Village"},
            koKR = {"별똥별 마을"},
            ptBR = {"Aldeia Chuva Estelar"},
            ruRU = {"Деревня Звездопада"},
            zhCN = {"坠星村"},
            zhTW = {"墜星村"},
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
        alias = {
            enUS = {"The Stockade"},
            deDE = {"Das Verlies"},
            esES = {"Las Mazmorras"},
            esMX = {"Las Mazmorras"},
            frFR = {"La Prison"},
            itIT = {"The Stockade"},
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
    [0] = {151.82119750976562, -181.46065521240234, 197.2987518310547, -67.98839569091797},    --StormwindStockade
}
Twm_mapareas["WailingCaverns"] = {
    [0] = {554.3612060546875, -492.38482666015625, 187.50392150878906, -570.5714263916016},    --WailingCaverns
}
Twm_mapareas["Blackfathom"] = {
    [0] = {424.0242614746094, -659.1072540283203, -54.819400787353516, -991.8395385742188},    --BlackfathomDeeps
}
Twm_mapareas["Uldaman"] = {
    [0] = {466.3337097167969, -85.73471450805664, 184.30628967285156, -379.87109375},    --Uldaman
}
Twm_mapareas["GnomeragonInstance"] = {
    [0] = {756.160888671875, -175.69004440307617, -200.88833618164062, -1006.6585693359375},    --Gnomeregan
}
Twm_mapareas["SunkenTemple"] = {
    [0] = {324.09619140625, -165.6102638244629, -245.16615295410156, -740.519775390625},    --SunkenTemple
}
Twm_mapareas["RazorfenDowns"] = {
    [0] = {1139.452814737957, 497.3407389322929, 2629.675470987957, 2196.0735117594413},    --RazorfenDowns
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
