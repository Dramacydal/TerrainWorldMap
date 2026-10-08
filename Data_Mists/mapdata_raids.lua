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
-- `alias` ({ <locale> = {names} }, optional) are other names the map is known
-- by (dungeon finder, top-level area names) -- only for comparing, never shown.
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
        alias = {
            enUS = {"Ahn'Qiraj"},
            deDE = {"Ahn'Qiraj"},
            esES = {"Ahn'Qiraj"},
            esMX = {"Ahn'Qiraj"},
            frFR = {"Ahn’Qiraj"},
            itIT = {"Ahn'Qiraj"},
            koKR = {"안퀴라즈"},
            ptBR = {"Ahn'Qiraj"},
            ruRU = {"Ан'Кираж"},
            zhCN = {"安其拉"},
            zhTW = {"安其拉"},
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
        alias = {
            deDE = {"Schwarzer Tempel"},
            esMX = {"El Templo Oscuro"},
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
        alias = {
            enUS = {"Serpentshrine Cavern"},
            deDE = {"Höhle des Schlangenschreins"},
            esES = {"Caverna Santuario Serpiente"},
            esMX = {"Caverna Santuario Serpiente"},
            frFR = {"Caverne du sanctuaire du Serpent"},
            itIT = {"Serpentshrine Cavern"},
            koKR = {"불뱀 제단"},
            ptBR = {"Caverna do Serpentário"},
            ruRU = {"Змеиное святилище"},
            zhCN = {"毒蛇神殿"},
            zhTW = {"毒蛇神殿洞穴"},
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
        alias = {
            enUS = {"The Siege of Wyrmrest Temple", "Fall of Deathwing", "Spine of the Destroyer UNUSED"},
            deDE = {"Belagerung des Wyrmruhtempels", "Todesschwinges Sturz", "Rückgrat des Zerstörers"},
            esES = {"Asedio Templo Reposo del Dragón", "Caída de Alamuerte", "Espinazo del Destructor UNUSED"},
            esMX = {"Asedio Templo Reposo del Dragón", "Caída de Alamuerte", "Espinazo del Destructor UNUSED"},
            frFR = {"Le siège du temple du Repos du ver", "La chute d’Aile de mort", "L’échine du Destructeur INUTILISÉ"},
            itIT = {"The Siege of Wyrmrest Temple", "Fall of Deathwing", "Spine of the Destroyer UNUSED"},
            koKR = {"고룡쉼터 사원 탈환", "데스윙의 추락", "파괴자의 등뼈 미사용"},
            ptBR = {"Cerco ao Repouso das Serpes", "Queda do Asa da Morte", "Espinhaço do Destruidor UNUSED"},
            ruRU = {"Осада Храма Драконьего Покоя", "Падение Смертокрыла", "Spine of the Destroyer UNUSED"},
            zhCN = {"围攻龙眠神殿", "死亡之翼的陨落", "Spine of the Destroyer UNUSED"},
            zhTW = {"圍攻龍眠神殿", "死亡之翼隕落", "毀滅者之脊"},
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
        alias = {
            enUS = {"The Verdant Fields", "Emerald Forest"},
            deDE = {"Die Saftgrünen Felder", "Smaragdwald"},
            esES = {"Los Verdegales", "Bosque Esmeralda"},
            esMX = {"Los Verdegales", "Bosque Esmeralda"},
            frFR = {"Les champs Verdoyants", "Forêt d’Émeraude"},
            itIT = {"The Verdant Fields", "Emerald Forest"},
            koKR = {"신록의 들판", "에메랄드 숲"},
            ptBR = {"Campos Verdejantes", "Floresta Esmeralda"},
            ruRU = {"Зеленеющие поля", "Изумрудный лес"},
            zhCN = {"青草平原", "翠叶森林"},
            zhTW = {"青草平原", "翠葉森林"},
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
        alias = {
            enUS = {"The Dread Approach", "Nightmare of Shek'zeer"},
            deDE = {"Der Schreckensvorstoß", "Shek'zeers Alptraum"},
            esES = {"Un enfoque aterrador", "Pesadilla de Shek'zeer"},
            esMX = {"Un enfoque aterrador", "Pesadilla de Shek'zeer"},
            frFR = {"L’approche de l’effroi", "Le cauchemar de Shek’zeer"},
            itIT = {"The Dread Approach", "Nightmare of Shek'zeer"},
            koKR = {"다가오는 공포", "셰크지르의 악몽"},
            ptBR = {"A Chegada do Pavor", "Pesadelo de Shek'zeer"},
            ruRU = {"Надвигающийся ужас", "Кошмар Шек'зир"},
            zhCN = {"恐惧临近", "夏柯希尔的梦魇"},
            zhTW = {"恐懼門徑", "杉齊爾的夢魘"},
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
        alias = {
            enUS = {"The Frost Queen's Lair", "Putricide's Laboratory of Alchemical Horrors and Fun", "The Crimson Hall", "The Frozen Throne", "The Sanctum of Blood"},
            deDE = {"Der Hort der Frostkönigin", "Seuchenmords Laboratorium der Alchemistischen Schrecken und Späße", "Die Blutrote Halle", "Der Frostthron", "Das Sanktum des Blutes"},
            esES = {"La Guarida de la Reina de Escarcha", "Laboratorio Horrores y Risas Alquímicas de Putricidio", "La Sala Carmesí", "El Trono Helado", "El Sagrario de Sangre"},
            esMX = {"La Guarida de la Reina de Escarcha", "Laboratorio Horrores y Risas Alquímicas de Putricidio", "La Sala Carmesí", "El Trono Helado", "El Sagrario de Sangre"},
            frFR = {"Le repaire de la Reine du Givre", "Laboratoire des Désopilantes atrocités alchimiques de Putricide", "La salle Cramoisie", "Le Trône de glace", "Le sanctum du Sang"},
            itIT = {"The Frost Queen's Lair", "Putricide's Laboratory of Alchemical Horrors and Fun", "The Crimson Hall", "The Frozen Throne", "The Sanctum of Blood"},
            koKR = {"서리 여왕의 둥지", "공포와 재미가 넘치는 퓨트리사이드의 연금술 실험실", "진홍빛 전당", "얼어붙은 왕좌", "피의 성소"},
            ptBR = {"Covil da Rainha Gélida", "Laboratório de Horrores e Diversões Alquímicas do Putricídio", "Salão Carmesim", "O Trono de Gelo", "Sacrário de Sangue"},
            ruRU = {"Логово Королевы Льда", "Лаборатория алхимических ужасов и забав", "Багровый зал", "Ледяной Трон", "Святилище Крови"},
            zhCN = {"冰霜女王的巢穴", "普崔赛德的恐怖和娱乐化学实验室", "血色厅堂", "冰封王座", "鲜血秘室"},
            zhTW = {"冰霜之后的巢穴", "普崔希德的恐懼與歡樂鍊金實驗室", "赤紅大廳", "冰封王座", "血之聖所"},
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
        alias = {
            frFR = {"Repaire de Magtheridon"},
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
        alias = {
            enUS = {"Guardians of Mogu'shan", "The Vault of Mysteries"},
            deDE = {"Wächter von Mogu'shan", "Das Gewölbe der Mysterien"},
            esES = {"Guardianes de Mogu'shan", "La cámara de los misterios"},
            esMX = {"Guardianes de Mogu'shan", "La cámara de los misterios"},
            frFR = {"Gardiens des Mogu’shan", "Le caveau des Mystères"},
            itIT = {"Guardians of Mogu'shan", "The Vault of Mysteries"},
            koKR = {"모구샨의 수호자", "신비의 금고"},
            ptBR = {"Guardiões de Mogu'shan", "A Galeria dos Mistérios"},
            ruRU = {"Стражи Могу'шан", "Хранилище тайн"},
            zhCN = {"魔古山守护者", "神秘宝库"},
            zhTW = {"魔古山的守護者", "秘法寶庫"},
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
        alias = {
            ptBR = {"Covil da Onyxia"},
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
        alias = {
            enUS = {"Ahn'Qiraj Ruins"},
            itIT = {"Ahn'Qiraj Ruins"},
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
        alias = {
            enUS = {"Vale of Eternal Sorrows", "Gates of Retribution", "The Underhold", "Downfall"},
            deDE = {"Tal des Ewigen Kummers", "Tore der Vergeltung", "Die Tiefenfestung", "Niedergang"},
            esES = {"Valle de la Pena Eterna", "Las Puertas de la Venganza", "El Búnker", "El Ocaso", "Siege of Orgrimmar"},
            esMX = {"Valle de la Pena Eterna", "Las Puertas de la Venganza", "El Búnker", "El Ocaso", "Siege of Orgrimmar"},
            frFR = {"Val de l’Éternelle tristesse", "Les portes de la Vindicte", "Fort-du-Gouffre", "La chute", "Siege of Orgrimmar"},
            itIT = {"Vale of Eternal Sorrows", "Gates of Retribution", "The Underhold", "Downfall"},
            koKR = {"영원한 슬픔의 골짜기", "응보의 성문", "지하요새", "폭군의 몰락"},
            ptBR = {"Vale das Mágoas Eternas", "Portões da Retaliação", "O Forte Subterrâneo", "A Queda", "Siege of Orgrimmar"},
            ruRU = {"Вечноскорбящий дол", "Расплата у врат", "Подземная крепость", "Низвержение", "Siege of Orgrimmar"},
            zhCN = {"锦绣谷之殇", "复仇之门", "地下堡垒", "暴君的黄昏"},
            zhTW = {"恆憂谷", "懲戒之門", "地下要塞", "霸權隕落", "Siege of Orgrimmar"},
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
        alias = {
            enUS = {"Hyjal Past", "Hyjal Summit"},
            deDE = {"Hyjal der Vergangenheit", "Hyjalgipfel"},
            esES = {"El Pasado Hyjal", "La Cima Hyjal"},
            esMX = {"El Pasado Hyjal", "La Cima Hyjal"},
            frFR = {"Passé d’Hyjal", "Sommet d’Hyjal"},
            itIT = {"Hyjal Past", "Hyjal Summit"},
            koKR = {"과거의 하이잘", "하이잘 정상"},
            ptBR = {"Hyjal Antigo", "Pico Hyjal"},
            ruRU = {"Прошлое Хиджала", "Вершина Хиджала"},
            zhCN = {"海加尔", "海加尔峰"},
            zhTW = {"過往的海加爾山", "海加爾山之巔"},
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
        alias = {
            enUS = {"Ruby Sanctum"},
            deDE = {"Rubinsanktum"},
            itIT = {"Ruby Sanctum"},
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
        alias = {
            enUS = {"Sunwell Plateau"},
            deDE = {"Sonnenbrunnen", "Sonnenbrunnenplateau"},
            esES = {"Meseta de La Fuente del Sol"},
            esMX = {"Meseta de La Fuente del Sol"},
            frFR = {"Puits de soleil", "Plateau du Puits de soleil"},
            itIT = {"Sunwell Plateau"},
            koKR = {"태양샘 고원"},
            ptBR = {"A Nascente do Sol", "Platô da Nascente do Sol"},
            ruRU = {"Плато Солнечного Колодца"},
            zhCN = {"太阳之井高地"},
            zhTW = {"太陽之井高地"},
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
        alias = {
            enUS = {"Last Stand of the Zandalari", "Forgotten Depths", "Halls of Flesh-Shaping", "Pinnacle of Storms"},
            deDE = {"Das letzte Gefecht der Zandalari", "Vergessene Tiefen", "Hallen der Fleischformer", "Die Spitze der Stürme", "Der Thron des Donners"},
            esES = {"La carga de la brigada Zandalari", "Abismo de la Desidia", "Cámaras de Modelado de Carne", "Pináculo de las Tormentas"},
            esMX = {"La carga de la brigada Zandalari", "Abismo de la Desidia", "Cámaras de Modelado de Carne", "Pináculo de las Tormentas"},
            frFR = {"Le baroud d’honneur des Zandalari", "Profondeurs oubliées", "Salles des Sculpte-Chair", "Cime des Tempêtes"},
            itIT = {"Last Stand of the Zandalari", "Forgotten Depths", "Halls of Flesh-Shaping", "Pinnacle of Storms"},
            koKR = {"잔달라 부족 최후의 저항", "잊혀진 심연", "살점구체자의 전당", "폭풍의 첨탑"},
            ptBR = {"Resistência Final dos Zandalari", "Profundezas Abandonadas", "Salões da Carne Moldada", "Pináculo das Tempestades"},
            ruRU = {"Последний оплот зандаларов", "Забытые глубины", "Залы Искажения Плоти", "Вершина Бурь"},
            zhCN = {"赞达拉的背水一战", "被遗忘的深渊", "修身殿", "风暴之巅"},
            zhTW = {"贊達拉的最後防線", "遺忘深淵", "血肉塑形大廳", "風暴之巔"},
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
        alias = {
            enUS = {"Trial of the Grand Crusader"},
            deDE = {"Prüfung des Obersten Kreuzfahrers"},
            esES = {"Prueba del Gran Cruzado"},
            esMX = {"Prueba del Gran Cruzado"},
            frFR = {"L'épreuve du grand croisé"},
            itIT = {"Trial of the Grand Crusader"},
            koKR = {"십자군 사령관의 시험장"},
            ptBR = {"Prova do Grande Cruzado"},
            ruRU = {"Испытание великого крестоносца"},
            zhCN = {"大十字军的试炼"},
            zhTW = {"大十字軍試煉"},
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
Twm_mapareas["IcecrownCitadel"] = {
    [0] = {3733.3333333333335, -3200, 5866.666666666667, -2133.3333333333335},    --IcecrownCitadel
}
Twm_mapareas["ArgentTournamentRaid"] = {
    [0] = {533.3333333333334, -533.3333333333334, 1066.6666666666667, 0},    --TrialoftheCrusader
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
    [0] = {14933.333333333334, -14933.333333333334, 14933.333333333334, -14933.333333333334},    --DragonSoul
}
Twm_mapareas["MoguExteriorRaid"] = {
    [0] = {5333.333333333334, -4266.666666666667, 0, -5866.666666666667},    --TerraceofEndlessSpring
}
Twm_mapareas["MogushanPalace"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 5866.666666666667, 3200},    --Mogu'shanVaults
}
Twm_mapareas["MantidRaid"] = {
    [0] = {1600, -533.3333333333334, -533.3333333333334, -3200},    --HeartofFear
}
Twm_mapareas["ThunderIslandRaid"] = {
    [0] = {8000.000000000001, 3200, 8000.000000000001, 3200},    --ThroneofThunder
}
Twm_mapareas["OrgrimmarRaid"] = {
    [0] = {2666.666666666667, -6400, 2666.666666666667, -10133.333333333334},    --SiegeofOrgrimmar
}
Twm_mapareas["OnyxiaLairInstance"] = {
    [0] = {-12.714693069458008, -398.3499755859375, 63.24594497680664, -254.60272979736328},    --Onyxia'sLair
}
Twm_mapareas["MoltenCore"] = {
    [0] = {-271.3323059082031, -1280.1649780273438, 1333.05517578125, 408.703369140625},    --MoltenCore
}
Twm_mapareas["HellfireRaid"] = {
    [0] = {117.13216400146484, -166.61969757080078, 236.813720703125, -198.03598403930664},    --Magtheridon'sLair
}
Twm_mapareas["CoilfangRaid"] = {
    [0] = {115.32664489746094, -1174.6867065429688, 573.8898315429688, -470.93475341796875},    --CoilfangSerpentshrineCavern
}
Twm_mapareas["TempestKeepRaid"] = {
    [0] = {495.4612731933594, -504.85398864746094, 878.9754638671875, -124.12457275390625},    --TempestKeep
}
Twm_mapareas["GruulsLair"] = {
    [0] = {439.6963806152344, -136.43865203857422, 298.5232238769531, -64.47694396972656},    --Gruul'sLair
}
Twm_mapareas["WintergraspRaid"] = {
    [0] = {150.8278757731132, -483.1908925374337, 208.09141031901163, -642.0317357381173},    --VaultofArchavon
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
