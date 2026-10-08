-- GENERATED FILE -- do not hand-edit, regenerate with scripts/gen_instance_maps.js
-- and replace this file wholesale. See scripts/README.md for details.
--
-- Scenario zone boxes, kept deliberately separate from
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
-- Twm_ScenarioNames is resolved into the actual TWM_SCENARIOS dropdown
-- table at load time (TerrainWorldMap.lua), same as Twm_ArenaNames/
-- Twm_flightmasters' name tables -- see this file's own header comment.
-- `mapID` is Map.csv's own ID (a string) -- used by per-flavor visibility
-- lists such as Twm_SeasonOnlyMaps (Data_Vanilla/mapdata_seasons.lua).
-- `alias` ({ <locale> = {names} }, optional) are other names the map is known
-- by (dungeon finder, top-level area names) -- only for comparing, never shown.
-- `expansion` is Map.csv's own ExpansionID (a string, like every other ID
-- in this codebase) -- drives the expansion-selection dropdown level
-- TerrainWorldMap.lua inserts between this category and the actual list.

Twm_ScenarioNames = {
    {
        key = "BrewmasterScenario01",
        mapID = "1005",
        expansion = "4",
        name = {
            enUS = "A Brewing Storm",
            deDE = "Ein Sturm braut sich zusammen",
            esES = "Cervezas y Truenos",
            esMX = "Cervezas y Truenos",
            frFR = "Une bière foudroyante",
            itIT = "A Brewing Storm",
            koKR = "양조 폭풍",
            ptBR = "Tempestade Cervejeira",
            ruRU = "Хмельная буря",
            zhCN = "酝酿风暴",
            zhTW = "雷電佳釀",
        },
    },
    {
        key = "ALittlePatienceScenario",
        mapID = "1104",
        expansion = "4",
        name = {
            enUS = "A Little Patience",
            deDE = "Ein wenig Geduld",
            esES = "Templanza",
            esMX = "Templanza",
            frFR = "Un peu de patience",
            itIT = "A Little Patience",
            koKR = "약간의 참을성",
            ptBR = "Um Pouco de Paciência",
            ruRU = "Немного терпения",
            zhCN = "王者的耐心",
            zhTW = "耐心試煉",
        },
    },
    {
        key = "AllianceHubMoguIslandProgressionScenario",
        mapID = "1125",
        expansion = "4",
        name = {
            enUS = "Alliance Hub - Mogu Island Progression Scenario",
            deDE = "Allianzknotenpunkt - Moguinselfortschrittszenario",
            esES = "Centro de la Alianza - Gesta de progresión de la isla mogu",
            esMX = "Centro de la Alianza - Gesta de progresión de la isla mogu",
            frFR = "Phase alliance - Scénario de progression de l’île mogu",
            itIT = "Alliance Hub - Mogu Island Progression Scenario",
            koKR = "얼라이언스 중심지 - 모구 섬 진행 시나리오",
            ptBR = "Centro da Aliança - Progressão do Cenário da Ilha Mogu",
            ruRU = "Alliance Hub - Mogu Island Progression Scenario",
            zhCN = "Alliance Hub - Mogu Island Progression Scenario",
            zhTW = "聯盟中心 - 魔古島發展事件",
        },
    },
    {
        key = "ProvingGroundsScenario",
        mapID = "1031",
        expansion = "4",
        name = {
            enUS = "Arena of Annihilation",
            deDE = "Arena der Auslöschung",
            esES = "Arena de la Aniquilación",
            esMX = "Arena de la Aniquilación",
            frFR = "Arène de l’Annihilation",
            itIT = "Arena of Annihilation",
            koKR = "파멸의 투기장",
            ptBR = "Arena da Aniquilação",
            ruRU = "Арена Истребления",
            zhCN = "破军比武场",
            zhTW = "殲滅競技場",
        },
    },
    {
        key = "ScenarioKlaxxiIsland",
        mapID = "1050",
        expansion = "4",
        name = {
            enUS = "Assault on Zan'vess",
            deDE = "Angriff auf Zan'vess",
            esES = "Asalto a Zan'vess",
            esMX = "Asalto a Zan'vess",
            frFR = "L’assaut de Zan’vess",
            itIT = "Assault on Zan'vess",
            koKR = "잔베스 강습",
            ptBR = "Ataque a Zan'vess",
            ruRU = "Атака на Зан'весс",
            zhCN = "突袭扎尼维斯",
            zhTW = "襲擊贊斐斯",
        },
    },
    {
        key = "ShimmerRidgeScenario",
        mapID = "1130",
        expansion = "4",
        name = {
            enUS = "Blood in the Snow",
            deDE = "Blutroter Schnee",
            esES = "Sangre en la Nieve",
            esMX = "Sangre en la Nieve",
            frFR = "Du sang dans la neige",
            itIT = "Blood in the Snow",
            koKR = "피로 얼룩진 설원",
            ptBR = "Sangue na Neve",
            ruRU = "Кровь на снегу",
            zhCN = "雪山血战",
            zhTW = "血染滄雪",
        },
        alias = {
            enUS = {"Dun Morogh"},
            deDE = {"Dun Morogh"},
            esES = {"Dun Morogh"},
            esMX = {"Dun Morogh"},
            frFR = {"Dun Morogh"},
            itIT = {"Dun Morogh"},
            koKR = {"던 모로"},
            ptBR = {"Dun Morogh"},
            ruRU = {"Дун Морог"},
            zhCN = {"丹莫罗"},
            zhTW = {"丹莫洛"},
        },
    },
    {
        key = "ScenarioBrewmaster04",
        mapID = "1051",
        expansion = "4",
        name = {
            enUS = "Brewmoon Festival",
            deDE = "Braumondfest",
            esES = "Festival de la Cerveza Lunar",
            esMX = "Festival de la Cerveza Lunar",
            frFR = "Festival de Brasse-Lune",
            itIT = "Brewmoon Festival",
            koKR = "맥주달 축제",
            ptBR = "Festival da Cerveja da Lua",
            ruRU = "Фестиваль Хмельнолуния",
            zhCN = "酿月祭",
            zhTW = "酒月節",
        },
        alias = {
            deDE = {"Das Braumondfest"},
        },
    },
    {
        key = "CelestialChallenge",
        mapID = "1161",
        expansion = "4",
        name = {
            enUS = "Celestial Tournament",
            deDE = "Turnier der Erhabenen",
            esES = "Torneo Celestial",
            esMX = "Torneo Celestial",
            frFR = "Tournoi des Astres vénérables",
            itIT = "Celestial Tournament",
            koKR = "천신의 시합",
            ptBR = "Torneio Celestial",
            ruRU = "Турнир Небожителей",
            zhCN = "天神比武大会",
            zhTW = "天尊武道會",
        },
    },
    {
        key = "CitySiegeMoguIslandProgressionScenario",
        mapID = "1122",
        expansion = "4",
        name = {
            enUS = "City Siege - Mogu Island Progression Scenario",
            deDE = "Stadtbelagerung - Moguinselfortschrittszenario",
            esES = "Asedio a la ciudad - Gesta de progresión de la isla mogu",
            esMX = "Asedio a la ciudad - Gesta de progresión de la isla mogu",
            frFR = "Siège de la ville - Scénario de progression de l’île mogu",
            itIT = "City Siege - Mogu Island Progression Scenario",
            koKR = "도시 공성전 - 모구 섬 진행 시나리오",
            ptBR = "Cerco à Cidade - Progressão do Cenário da Ilha Mogu",
            ruRU = "City Siege - Mogu Island Progression Scenario",
            zhCN = "City Siege - Mogu Island Progression Scenario",
            zhTW = "圍城 - 魔古島發展事件",
        },
        alias = {
            enUS = {"Isle of Thunder"},
            deDE = {"Insel des Donners"},
            esES = {"Isla del Trueno"},
            esMX = {"Isla del Trueno"},
            frFR = {"Île du Tonnerre"},
            itIT = {"Isle of Thunder"},
            koKR = {"천둥의 섬"},
            ptBR = {"Ilha do Trovão"},
            ruRU = {"Остров Грома"},
            zhCN = {"雷神岛"},
            zhTW = {"雷王島"},
        },
    },
    {
        key = "HordeAmbushScenario",
        mapID = "1095",
        expansion = "4",
        name = {
            enUS = "Dagger in the Dark",
            deDE = "Ein Dolch im Dunkel",
            esES = "Una Daga en la Oscuridad",
            esMX = "Una Daga en la Oscuridad",
            frFR = "Une dague dans la nuit",
            itIT = "Dagger in the Dark",
            koKR = "어둠 속의 비수",
            ptBR = "Adaga no Escuro",
            ruRU = "Кинжал во тьме",
            zhCN = "黑暗中的匕首",
            zhTW = "暗箭難防",
        },
    },
    {
        key = "HordeBaseBeachScenario",
        mapID = "1102",
        expansion = "4",
        name = {
            enUS = "Domination Point",
            deDE = "Herrschaftsfeste",
            esES = "Punto de Dominio",
            esMX = "Punto de Dominio",
            frFR = "Halte de la Domination",
            itIT = "Domination Point",
            koKR = "지배령 거점",
            ptBR = "Ponto de Dominação",
            ruRU = "Крепость Покорителей",
            zhCN = "统御岗哨",
            zhTW = "制霸岬",
        },
        alias = {
            enUS = {"Krasarang Wilds"},
            deDE = {"Krasarangwildnis"},
            esES = {"Espesura Krasarang"},
            esMX = {"Espesura Krasarang"},
            frFR = {"Étendues sauvages de Krasarang"},
            itIT = {"Krasarang Wilds"},
            koKR = {"크라사랑 밀림"},
            ptBR = {"Selva de Krasarang"},
            ruRU = {"Красарангские джунгли"},
            zhCN = {"卡桑琅丛林"},
            zhTW = {"喀撒朗蠻荒"},
        },
    },
    {
        key = "FinalGateMoguIslandProgressionScenario",
        mapID = "1127",
        expansion = "4",
        name = {
            enUS = "Final Gate - Mogu Island Progression Scenario",
            deDE = "Letztes Tor - Moguinselfortschrittszenario",
            esES = "Puerta final - Gesta de progresión de la isla mogu",
            esMX = "Puerta final - Gesta de progresión de la isla mogu",
            frFR = "Dernière porte - Scénario de progression de l’île mogu",
            itIT = "Final Gate - Mogu Island Progression Scenario",
            koKR = "마지막 관문 - 모구 섬 진행 시나리오",
            ptBR = "Portão Final - Progressão do Cenário da Ilha Mogu",
            ruRU = "Final Gate - Mogu Island Progression Scenario",
            zhCN = "Final Gate - Mogu Island Progression Scenario",
            zhTW = "終末之門 - 魔古島發展事件",
        },
    },
    {
        key = "PandaFishingVillageScenario",
        mapID = "1024",
        expansion = "4",
        name = {
            enUS = "Greenstone Village",
            deDE = "Grünstein",
            esES = "Aldea Verdemar",
            esMX = "Aldea Verdemar",
            frFR = "Pierre-Verte",
            itIT = "Greenstone Village",
            koKR = "녹옥 마을",
            ptBR = "Aldeia Rocha Verde",
            ruRU = "Деревня Зеленой Скалы",
            zhCN = "绿石村",
            zhTW = "綠石村",
        },
        alias = {
            enUS = {"The Jade Forest"},
            deDE = {"Der Jadewald"},
            esES = {"El Bosque de Jade"},
            esMX = {"El Bosque de Jade"},
            frFR = {"La forêt de Jade"},
            itIT = {"The Jade Forest"},
            koKR = {"비취 숲"},
            ptBR = {"Floresta de Jade"},
            ruRU = {"Нефритовый лес"},
            zhCN = {"翡翠林"},
            zhTW = {"翠玉林"},
        },
    },
    {
        key = "HalfhillScenario",
        mapID = "1157",
        expansion = "4",
        name = {
            enUS = "Halfhill Scenario",
            deDE = "Halbhügelszenario",
            esES = "Gesta de El Alcor",
            esMX = "Gesta de El Alcor",
            frFR = "Scénario de Micolline",
            itIT = "Halfhill Scenario",
            koKR = "언덕골 시나리오",
            ptBR = "Cenário de Meia Colina",
            ruRU = "Сценарий: Полугорье",
            zhCN = "半山场景战役",
            zhTW = "半丘事件",
        },
        alias = {
            enUS = {"Finding the Secret Ingredient", "Noodle Time", "The Secret Ingredient"},
            deDE = {"Die Geheimzutat", "Nudelzeit"},
            esES = {"El Ingrediente Secreto", "La hora de los fideos"},
            esMX = {"El Ingrediente Secreto", "La hora de los fideos"},
            frFR = {"Trouver l’ingrédient mystère", "L’heure des nouilles", "L’ingrédient mystère"},
            itIT = {"Finding the Secret Ingredient", "Noodle Time", "The Secret Ingredient"},
            koKR = {"비밀 재료를 찾아서", "국수 시간", "비밀 재료"},
            ptBR = {"Encontrando o Ingrediente Secreto", "Hora do Macarrão", "Ingrediente Secreto"},
            ruRU = {"Секретный ингредиент", "Час лапши"},
            zhCN = {"寻找秘制原料", "汤面时间", "秘密配方"},
            zhTW = {"找出神秘食材", "湯麵時刻", "神秘食材"},
        },
    },
    {
        key = "HeartOfTheOldGodScenario",
        mapID = "1144",
        expansion = "4",
        name = {
            enUS = "Heart of the Old God Scenario",
            deDE = "Das dunkle Herz Pandarias",
            esES = "Gesta del Corazón del Dios Antiguo",
            esMX = "Gesta del Corazón del Dios Antiguo",
            frFR = "Scénario du Cœur des Dieux très anciens",
            itIT = "Heart of the Old God Scenario",
            koKR = "고대신의 심장 시나리오",
            ptBR = "Cenário Coração do Deus Antigo",
            ruRU = "Сценарий - Сердце древнего бога",
            zhCN = "古神之心场景战役",
            zhTW = "古神之心事件",
        },
        alias = {
            enUS = {"Dark Heart of Pandaria", "Vale of Eternal Blossoms"},
            deDE = {"Tal der Ewigen Blüten"},
            esES = {"Corazón Oscuro de Pandaria", "Valle de la Flor Eterna"},
            esMX = {"Corazón Oscuro de Pandaria", "Valle de la Flor Eterna"},
            frFR = {"Le sombre cœur de la Pandarie", "Val de l’Éternel printemps"},
            itIT = {"Dark Heart of Pandaria", "Vale of Eternal Blossoms"},
            koKR = {"판다리아의 검은 심장", "영원꽃 골짜기"},
            ptBR = {"Coração Sombrio de Pandária", "Vale das Flores Eternas"},
            ruRU = {"Темное сердце Пандарии", "Вечноцветущий дол"},
            zhCN = {"潘达利亚的黑暗之心", "锦绣谷"},
            zhTW = {"潘達利亞的黑暗之心", "恆春谷"},
        },
    },
    {
        key = "LightningForgeMoguIslandProgressionScenario",
        mapID = "1123",
        expansion = "4",
        name = {
            enUS = "Lightning Forge - Mogu Island Progression Scenario",
            deDE = "Blitzschmiede - Moguinselfortschrittszenario",
            esES = "Forja de los relámpagos - Gesta de progresión de la isla mogu",
            esMX = "Forja de los relámpagos - Gesta de progresión de la isla mogu",
            frFR = "Forge de foudre - Scénario de progression de l’île mogu",
            itIT = "Lightning Forge - Mogu Island Progression Scenario",
            koKR = "천둥 제련소 - 모구 섬 진행 시나리오",
            ptBR = "Forja do Relâmpago - Progressão do Cenário da Ilha Mogu",
            ruRU = "Lightning Forge - Mogu Island Progression Scenario",
            zhCN = "Lightning Forge - Mogu Island Progression Scenario",
            zhTW = "雷霆熔爐 - 魔古島發展事件",
        },
        alias = {
            enUS = {"To The Skies!"},
            deDE = {"In die Lüfte!"},
            esES = {"¡Hacia los Cielos!"},
            esMX = {"¡Hacia los Cielos!"},
            frFR = {"En route vers les cieux !"},
            itIT = {"To The Skies!"},
            koKR = {"하늘 높이!"},
            ptBR = {"Para os Céus!"},
            ruRU = {"В небо!"},
            zhCN = {"直冲云霄！"},
            zhTW = {"飛上天吧!"},
        },
    },
    {
        key = "AllianceBaseBeachScenario",
        mapID = "1103",
        expansion = "4",
        name = {
            enUS = "Lion's Landing",
            deDE = "Löwenlandung",
            esES = "Desembarco del León",
            esMX = "Desembarco del León",
            frFR = "Territoire du Lion",
            itIT = "Lion's Landing",
            koKR = "사자의 상륙지",
            ptBR = "Ancoradouro do Leão",
            ruRU = "Львиный лагерь",
            zhCN = "雄狮港",
            zhTW = "雄獅灘",
        },
        alias = {
            enUS = {"Krasarang Wilds"},
            deDE = {"Krasarangwildnis"},
            esES = {"Espesura Krasarang"},
            esMX = {"Espesura Krasarang"},
            frFR = {"Étendues sauvages de Krasarang"},
            itIT = {"Krasarang Wilds"},
            koKR = {"크라사랑 밀림"},
            ptBR = {"Selva de Krasarang"},
            ruRU = {"Красарангские джунгли"},
            zhCN = {"雄师港", "卡桑琅丛林"},
            zhTW = {"喀撒朗蠻荒"},
        },
    },
    {
        key = "HordeHubMoguIslandProgressionScenario",
        mapID = "1126",
        expansion = "4",
        name = {
            enUS = "Mogu Island Progression Events",
            deDE = "Moguinselfortschrittsereignisse",
            esES = "Eventos de progresión de la isla mogu",
            esMX = "Eventos de progresión de la isla mogu",
            frFR = "Évènements de progression de l’île mogu",
            itIT = "Mogu Island Progression Events",
            koKR = "모구 섬 진행 이벤트",
            ptBR = "Eventos de Progressão da Ilha Mogu",
            ruRU = "Mogu Island Progression Events",
            zhCN = "魔古岛进度事件",
            zhTW = "魔古島發展活動",
        },
        alias = {
            enUS = {"Tear Down This Wall!", "Stormsea Landing", "Assault on Zeb'tula", "To the Skies!", "The Fall of Shan Bu", "The Thunder Forge", "Assault on Shaol'mara", "Isle of Thunder"},
            deDE = {"Die Mauer muss weg!", "Der Sturmgepeitschte Hafen", "Angriff auf Zeb'tula", "In die Lüfte!", "Der Sturz von Shan'Bu", "Die Donnerschmiede", "Angriff auf Shaol'mara", "Insel des Donners"},
            esES = {"¡Abajo la Muralla!", "Muelle Aguaturbia", "Asalto a Zeb'tula", "¡Hacia los Cielos!", "La Caída de Shan Bu", "La Forja del Trueno", "Asalto a Shaol'mara", "Isla del Trueno"},
            esMX = {"¡Abajo la Muralla!", "Muelle Aguaturbia", "Asalto a Zeb'tula", "¡Hacia los Cielos!", "La Caída de Shan Bu", "La Forja del Trueno", "Asalto a Shaol'mara", "Isla del Trueno"},
            frFR = {"Démolissez ce mur !", "Débarcadère de la mer des Tempêtes", "L’assaut de Zeb’tula", "En route vers les cieux !", "La chute de Shan Bu", "La forge du Tonnerre", "L’assaut de Shaol’mara", "Île du Tonnerre"},
            itIT = {"Tear Down This Wall!", "Stormsea Landing", "Assault on Zeb'tula", "To the Skies!", "The Fall of Shan Bu", "The Thunder Forge", "Assault on Shaol'mara", "Isle of Thunder"},
            koKR = {"성벽을 무너뜨려라!", "폭풍바다 선착장", "제브툴라 강습", "하늘 높이!", "샨 부의 몰락", "천둥 제련소", "샤올마라 강습", "천둥의 섬"},
            ptBR = {"Derrubem a Muralha!", "Ancoradouro do Mar Revolto", "Ataque a Zeb'tula", "Para os Céus!", "A Queda de Shan Bu", "A Forja do Trovão", "Ataque a Shaol'mara", "Ilha do Trovão"},
            ruRU = {"Разрушить эту стену!", "Пристань Бушующих Волн", "Атака на Зеб'тул", "В небо!", "Падение Шань-Бу", "Кузня Грома", "Атака на Шаол'мару", "Остров Грома"},
            zhCN = {"摧毁城墙！", "风暴之海码头", "突袭赞布图拉", "直冲云霄！", "山怖之死", "雷霆熔炉", "突袭绍尔马拉", "雷神岛"},
            zhTW = {"突破城牆!", "狂濤港", "襲擊札布圖拉", "飛上天吧!", "衫布敗亡", "雷霆熔爐", "襲擊韶嘛喇", "雷王島"},
        },
    },
    {
        key = "NavalBattleScenario",
        mapID = "1099",
        expansion = "4",
        name = {
            enUS = "Naval Battle Scenario",
            deDE = "Szenario: Seeschlacht",
            esES = "Gesta de batalla naval",
            esMX = "Gesta de batalla naval",
            frFR = "Scénario : bataille navale",
            itIT = "Naval Battle Scenario",
            koKR = "해상 전투 시나리오",
            ptBR = "Cenário da Batalha Naval",
            ruRU = "Морская битва - сценарий",
            zhCN = "海战场景",
            zhTW = "海戰事件",
        },
        alias = {
            enUS = {"Battle on the High Seas"},
            deDE = {"Schlacht auf hoher See"},
            esES = {"Batalla en Alta Mar"},
            esMX = {"Batalla en Alta Mar"},
            frFR = {"Bataille en haute mer"},
            itIT = {"Battle on the High Seas"},
            koKR = {"공해 상에서의 전투"},
            ptBR = {"Batalha em Alto-mar", "Batalha em Alto Mar"},
            ruRU = {"Битва в открытом море"},
            zhCN = {"公海激战"},
            zhTW = {"怒海之戰"},
        },
    },
    {
        key = "BlackTempleScenario",
        mapID = "1112",
        expansion = "4",
        name = {
            enUS = "Pursuing the Black Harvest",
            deDE = "Jagd auf die Schwarze Ernte",
            esES = "Tras la Cosecha Oscura",
            esMX = "Tras la Cosecha Oscura",
            frFR = "À la poursuite de la Sombre récolte",
            itIT = "Pursuing the Black Harvest",
            koKR = "암흑의 수확을 쫓아서",
            ptBR = "Em Busca da Colheita Negra",
            ruRU = "В погоне за Мрачной Жатвой",
            zhCN = "追踪黑暗收割议会",
            zhTW = "追擊黑穫議會",
        },
        alias = {
            enUS = {"Black Temple"},
            deDE = {"Der Schwarze Tempel"},
            esES = {"Templo Oscuro"},
            esMX = {"Templo Oscuro"},
            frFR = {"Temple Noir"},
            itIT = {"Black Temple"},
            koKR = {"검은 사원"},
            ptBR = {"Templo Negro"},
            ruRU = {"Черный храм"},
            zhCN = {"黑暗神殿"},
            zhTW = {"黑暗神廟"},
        },
    },
    {
        key = "ShipyardMoguIslandProgressionScenario",
        mapID = "1124",
        expansion = "4",
        name = {
            enUS = "Shipyard - Mogu Island Progression Scenario",
            deDE = "Werft - Moguinselfortschrittszenario",
            esES = "Astillero - Gesta de progresión de la isla mogu",
            esMX = "Astillero - Gesta de progresión de la isla mogu",
            frFR = "Chantier naval - Scénario de progression de l’île mogu",
            itIT = "Shipyard - Mogu Island Progression Scenario",
            koKR = "항만 - 모구 섬 진행 시나리오",
            ptBR = "Estaleiro - Progressão do Cenário da Ilha Mogu",
            ruRU = "Shipyard - Mogu Island Progression Scenario",
            zhCN = "Shipyard - Mogu Island Progression Scenario",
            zhTW = "船廠 - 魔古島發展事件",
        },
        alias = {
            enUS = {"Infiltrating the Shipyard"},
            deDE = {"Infiltration der Werft"},
            esES = {"Infiltración en el Astillero"},
            esMX = {"Infiltración en el Astillero"},
            frFR = {"Infiltrer le chantier naval"},
            itIT = {"Infiltrating the Shipyard"},
            koKR = {"항만 침입"},
            ptBR = {"Infiltrando-se no Estaleiro"},
            ruRU = {"Проникновение на пристань"},
            zhCN = {"潜入船坞"},
            zhTW = {"潛入船塢"},
        },
    },
    {
        key = "ValleyOfPowerScenario",
        mapID = "1035",
        expansion = "4",
        name = {
            enUS = "Temple of Kotmogu",
            deDE = "Tempel von Katmogu",
            esES = "Templo de Kotmogu",
            esMX = "Templo de Kotmogu",
            frFR = "Temple de Kotmogu",
            itIT = "Temple of Kotmogu",
            koKR = "코트모구의 사원",
            ptBR = "Templo de Kotmogu",
            ruRU = "Храм Котмогу",
            zhCN = "寇魔古寺",
            zhTW = "科特魔古神廟",
        },
        alias = {
            enUS = {"Valley Of Power - Scenario"},
            deDE = {"Das Tal der Macht - Szenario"},
            esES = {"Gesta: Valle del Poder"},
            esMX = {"Gesta: Valle del Poder"},
            frFR = {"Vallée de la puissance - Scénario"},
            itIT = {"Valley Of Power - Scenario"},
            koKR = {"무력의 골짜기 - 시나리오"},
            ptBR = {"Vale do Poder - Cenário"},
            ruRU = {"Долина Силы - сценарий"},
            zhCN = {"能量谷 - 场景战役"},
            zhTW = {"異能山谷 - 事件"},
        },
    },
    {
        key = "BFTHordeScenario",
        mapID = "1000",
        expansion = "3",
        name = {
            enUS = "Theramore's Fall (A)",
            deDE = "Theramores Sturz (A)",
            esES = "Caída de Theramore (A)",
            esMX = "Caída de Theramore (A)",
            frFR = "Chute de Theramore (A)",
            itIT = "Theramore's Fall (A)",
            koKR = "테라모어의 몰락 (얼라이언스)",
            ptBR = "Queda de Theramore (A)",
            ruRU = "Падение Терамора",
            zhCN = "塞拉摩的沦陷",
            zhTW = "塞拉摩攻防戰(聯盟)",
        },
        alias = {
            enUS = {"Theramore's Fall", "Dustwallow Marsh"},
            deDE = {"Theramores Sturz", "Düstermarschen"},
            esES = {"Caída de Theramore", "Marjal Revolcafango"},
            esMX = {"Caída de Theramore", "Marjal Revolcafango"},
            frFR = {"La chute de Theramore", "Marécage d’Âprefange"},
            itIT = {"Theramore's Fall", "Dustwallow Marsh"},
            koKR = {"테라모어의 몰락", "먼지진흙 습지대"},
            ptBR = {"A Queda de Theramore", "Queda de Theramore", "Pântano Vadeoso"},
            ruRU = {"Пылевые топи"},
            zhCN = {"尘泥沼泽"},
            zhTW = {"塞拉摩攻防戰", "塵泥沼澤"},
        },
    },
    {
        key = "BFTAllianceScenario",
        mapID = "999",
        expansion = "3",
        name = {
            enUS = "Theramore's Fall (H)",
            deDE = "Theramores Sturz (H)",
            esES = "Caída de Theramore (H)",
            esMX = "Caída de Theramore (H)",
            frFR = "Chute de Theramore (H)",
            itIT = "Theramore's Fall (H)",
            koKR = "테라모어의 몰락 (호드)",
            ptBR = "Queda de Theramore (H)",
            ruRU = "Падение Терамора",
            zhCN = "塞拉摩的沦陷",
            zhTW = "塞拉摩攻防戰(部落)",
        },
        alias = {
            enUS = {"Theramore's Fall", "Dustwallow Marsh"},
            deDE = {"Theramores Sturz", "Düstermarschen"},
            esES = {"Caída de Theramore", "Marjal Revolcafango"},
            esMX = {"Caída de Theramore", "Marjal Revolcafango"},
            frFR = {"La chute de Theramore", "Marécage d’Âprefange"},
            itIT = {"Theramore's Fall", "Dustwallow Marsh"},
            koKR = {"테라모어의 몰락", "먼지진흙 습지대"},
            ptBR = {"Queda de Theramore", "Pântano Vadeoso"},
            ruRU = {"Пылевые топи"},
            zhCN = {"尘泥沼泽"},
            zhTW = {"塞拉摩攻防戰", "塵泥沼澤"},
        },
    },
    {
        key = "BrewmasterScenario03",
        mapID = "1048",
        expansion = "4",
        name = {
            enUS = "Unga Ingoo",
            deDE = "Unga Ingu",
            esES = "Unga Ingoo",
            esMX = "Unga Ingoo",
            frFR = "Unga Ingou",
            itIT = "Unga Ingoo",
            koKR = "웅가 잉구",
            ptBR = "Ungá Ingô",
            ruRU = "Унга-Ингу",
            zhCN = "盎迦猴岛",
            zhTW = "仰加印古",
        },
    },
}

Twm_mapareas["BFTAllianceScenario"] = {
    [0] = {-3200, -5333.333333333334, -2666.666666666667, -4800},    --Theramore'sFallH
}
Twm_mapareas["BFTHordeScenario"] = {
    [0] = {-3200, -5333.333333333334, -2666.666666666667, -4800},    --Theramore'sFallA
}
Twm_mapareas["BrewmasterScenario01"] = {
    [0] = {0, -2133.3333333333335, 3200, 1066.6666666666667},    --ABrewingStorm
}
Twm_mapareas["PandaFishingVillageScenario"] = {
    [0] = {-533.3333333333334, -4266.666666666667, 4266.666666666667, 1066.6666666666667},    --GreenstoneVillage
}
Twm_mapareas["ProvingGroundsScenario"] = {
    [0] = {1066.6666666666667, 0, 4266.666666666667, 3200},    --ArenaofAnnihilation
}
Twm_mapareas["ValleyOfPowerScenario"] = {
    [0] = {2133.3333333333335, 533.3333333333334, 2666.666666666667, 1066.6666666666667},    --TempleofKotmogu
}
Twm_mapareas["BrewmasterScenario03"] = {
    [0] = {1600, 0, -1600, -3733.3333333333335},    --UngaIngoo
}
Twm_mapareas["ScenarioKlaxxiIsland"] = {
    [0] = {5866.666666666667, 3200, 533.3333333333334, -2666.666666666667},    --AssaultonZan'vess
}
Twm_mapareas["ScenarioBrewmaster04"] = {
    [0] = {1600, -533.3333333333334, 3733.3333333333335, 1066.6666666666667},    --BrewmoonFestival
}
Twm_mapareas["HordeAmbushScenario"] = {
    [0] = {1066.6666666666667, -1600, 2666.666666666667, -533.3333333333334},    --DaggerintheDark
}
Twm_mapareas["NavalBattleScenario"] = {
    [0] = {-2666.666666666667, -5333.333333333334, 3733.3333333333335, 1066.6666666666667},    --NavalBattleScenario
}
Twm_mapareas["HordeBaseBeachScenario"] = {
    [0] = {3733.3333333333335, 533.3333333333334, -533.3333333333334, -3733.3333333333335},    --DominationPoint
}
Twm_mapareas["AllianceBaseBeachScenario"] = {
    [0] = {533.3333333333334, -2666.666666666667, 0, -2666.666666666667},    --Lion'sLanding
}
Twm_mapareas["ALittlePatienceScenario"] = {
    [0] = {2133.3333333333335, -1066.6666666666667, -533.3333333333334, -3200},    --ALittlePatience
}
Twm_mapareas["BlackTempleScenario"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 2133.3333333333335, -1066.6666666666667},    --PursuingtheBlackHarvest
}
Twm_mapareas["CitySiegeMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --CitySiegeMoguIslandProgressionScenario
}
Twm_mapareas["LightningForgeMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --LightningForgeMoguIslandProgressionScenario
}
Twm_mapareas["ShipyardMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --ShipyardMoguIslandProgressionScenario
}
Twm_mapareas["AllianceHubMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --AllianceHubMoguIslandProgressionScenario
}
Twm_mapareas["HordeHubMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --MoguIslandProgressionEvents
}
Twm_mapareas["FinalGateMoguIslandProgressionScenario"] = {
    [0] = {7466.666666666667, 3200, 9066.666666666668, 4800},    --FinalGateMoguIslandProgressionScenario
}
Twm_mapareas["ShimmerRidgeScenario"] = {
    [0] = {1066.6666666666667, -1600, -4266.666666666667, -6400},    --BloodintheSnow
}
Twm_mapareas["HeartOfTheOldGodScenario"] = {
    [0] = {2666.666666666667, -533.3333333333334, 2133.3333333333335, 0},    --HeartoftheOldGodScenario
}
Twm_mapareas["HalfhillScenario"] = {
    [0] = {2133.3333333333335, -533.3333333333334, 1066.6666666666667, -1066.6666666666667},    --HalfhillScenario
}
Twm_mapareas["CelestialChallenge"] = {
    [0] = {-3733.3333333333335, -6933.333333333334, 1066.6666666666667, -2133.3333333333335},    --CelestialTournament
}
