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
            frFR = "Temple d'Ahn'Qiraj",
            itIT = "Tempio di Ahn'Qiraj",
            koKR = "안퀴라즈 사원",
            ptBR = "Templo de Ahn'Qiraj",
            ruRU = "Храм Ан'Киража",
            zhCN = "安其拉神殿",
            zhTW = "安其拉神廟",
        },
    },
    {
        key = "BlackwingLair",
        mapID = "469",
        expansion = "0",
        name = {
            enUS = "Blackwing Lair",
            deDE = "Pechschwingenhort",
            esES = "Guarida Alanegra",
            esMX = "Guarida de Alanegra",
            frFR = "Repaire de l'Aile noire",
            itIT = "Fortezza dell'Ala Nera",
            koKR = "검은날개 둥지",
            ptBR = "Covil Asa Negra",
            ruRU = "Логово Крыла Тьмы",
            zhCN = "黑翼之巢",
            zhTW = "黑翼之巢",
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
            itIT = "Sogno di Smeraldo",
            koKR = "에메랄드의 꿈",
            ptBR = "Sonho Esmeralda",
            ruRU = "Изумрудный Сон",
            zhCN = "翡翠梦境",
            zhTW = "翡翠夢境",
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
            itIT = "Nucleo Ardente",
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
        key = "2832",
        mapID = "2832",
        expansion = "0",
        name = {
            enUS = "Nightmare Grove",
            deDE = "Alptraumhain",
            esES = "Arboleda de la Pesadilla",
            esMX = "Arboleda de las Pesadillas",
            frFR = "Bosquet du cauchemar",
            itIT = "Nightmare Grove",
            koKR = "악몽의 숲",
            ptBR = "Bosque do Pesadelo",
            ruRU = "Роща Кошмаров",
            zhCN = "梦魇林地",
            zhTW = "夢魘林地",
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
            frFR = "Repaire d'Onyxia",
            itIT = "Antro di Onyxia",
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
            frFR = "Ruines d'Ahn'Qiraj",
            itIT = "Rovine di Ahn'Qiraj",
            koKR = "안퀴라즈 폐허",
            ptBR = "Ruínas de Ahn'Qiraj",
            ruRU = "Руины Ан'Киража",
            zhCN = "安其拉废墟",
            zhTW = "安其拉廢墟",
        },
    },
    {
        key = "2856",
        mapID = "2856",
        expansion = "0",
        name = {
            enUS = "Scarlet Enclave",
            deDE = "Scharlachrote Enklave",
            esES = "Enclave Escarlata",
            esMX = "Enclave Escarlata",
            frFR = "L’enclave Écarlate",
            itIT = "Scarlet Enclave",
            koKR = "붉은십자군 초소",
            ptBR = "Enclave Escarlate",
            ruRU = "Анклав Алого ордена",
            zhCN = "血色领地",
            zhTW = "血色領區",
        },
    },
    {
        key = "2791",
        mapID = "2791",
        expansion = "0",
        name = {
            enUS = "Storm Cliffs",
            deDE = "Sturmklippen",
            esES = "Acantilados Tormentosos",
            esMX = "Acantilados de la Tormenta",
            frFR = "Falaises de la Tempête",
            koKR = "폭풍 절벽",
            ptBR = "Penhascos Tempestuosos",
            ruRU = "Штормовые утесы",
            zhCN = "风暴悬崖",
            zhTW = "暴風崖",
        },
    },
    {
        key = "2804",
        mapID = "2804",
        expansion = "0",
        name = {
            enUS = "The Crystal Vale",
            deDE = "Kristalltal",
            esES = "La Vega de Cristal",
            esMX = "La Vega de Cristal",
            frFR = "La vallée des Cristaux",
            itIT = "The Crystal Vale",
            koKR = "수정 골짜기",
            ptBR = "Vale de Cristal",
            ruRU = "Долина Кристаллов",
            zhCN = "水晶谷",
            zhTW = "水晶谷",
        },
    },
    {
        key = "2789",
        mapID = "2789",
        expansion = "0",
        name = {
            enUS = "The Tainted Scar",
            deDE = "Faulende Narbe",
            esES = "Escara Impía",
            esMX = "Escara Impía",
            frFR = "La Balafre impure",
            koKR = "타락의 흉터",
            ptBR = "Rasgo Infecto",
            ruRU = "Гниющий Шрам",
            zhCN = "腐烂之痕",
            zhTW = "腐爛之痕",
        },
    },
    {
        key = "Zul'gurub",
        mapID = "309",
        expansion = "0",
        name = {
            enUS = "Zul'Gurub",
            deDE = "Zul'Gurub",
            esES = "Zul'Gurub",
            esMX = "Zul'Gurub",
            frFR = "Zul'Gurub",
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
Twm_mapareas["Stratholme Raid"] = {
    [0] = {-2666.666666666667, -5866.666666666667, 4266.666666666667, 2133.3333333333335},    --Naxxramas
}
Twm_mapareas["2789"] = {
    [0] = {-1600, -3200, -11200, -12800},    --TheTaintedScar
}
Twm_mapareas["2791"] = {
    [0] = {-4800, -7466.666666666667, 3733.3333333333335, 1600},    --StormCliffs
}
Twm_mapareas["2804"] = {
    [0] = {2133.3333333333335, 533.3333333333334, -5866.666666666667, -7466.666666666667},    --TheCrystalVale
}
Twm_mapareas["2832"] = {
    [0] = {2666.666666666667, -4800, 4266.666666666667, -11200},    --NightmareGrove
}
Twm_mapareas["2856"] = {
    [0] = {-3200, -6933.333333333334, 3733.3333333333335, 533.3333333333334},    --ScarletEnclave
}
Twm_mapareas["OnyxiaLairInstance"] = {
    [0] = {-12.714693069458008, -398.3499755859375, 63.24594497680664, -254.60272979736328},    --Onyxia'sLair
}
Twm_mapareas["MoltenCore"] = {
    [0] = {-271.3323059082031, -1280.1649780273438, 1333.05517578125, 408.703369140625},    --MoltenCore
}
