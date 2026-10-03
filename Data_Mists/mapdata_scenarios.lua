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
