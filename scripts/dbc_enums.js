// Map.csv's InstanceType (0-4, "official from IsInInstance()" per
// WoWDBDefs' Map.dbd) and UiMap.csv's Type columns, named per TrinityCore's
// DBCEnums.h (enum MapTypes / enum UiMapType):
// https://github.com/TrinityCore/TrinityCore/blob/master/src/server/game/DataStores/DBCEnums.h
//
// Map.csv also has a separate, unrelated, unenumerated MapType column
// (checked ad hoc as a raw '1' by each script's own top-level-map filter)
// -- INSTANCE_TYPE_* names these deliberately distinct from that so the
// two don't read as the same thing.
module.exports = {
	INSTANCE_TYPE_COMMON: '0',       // MAP_COMMON
	INSTANCE_TYPE_INSTANCE: '1',     // MAP_INSTANCE (dungeon)
	INSTANCE_TYPE_RAID: '2',         // MAP_RAID
	INSTANCE_TYPE_BATTLEGROUND: '3', // MAP_BATTLEGROUND
	INSTANCE_TYPE_ARENA: '4',        // MAP_ARENA
	INSTANCE_TYPE_SCENARIO: '5',     // MAP_SCENARIO

	UI_MAP_TYPE_CONTINENT: '2', // UI_MAP_TYPE_CONTINENT
	UI_MAP_TYPE_ZONE: '3',      // UI_MAP_TYPE_ZONE
	UI_MAP_TYPE_DUNGEON: '4',   // UI_MAP_TYPE_DUNGEON
	UI_MAP_TYPE_ORPHAN: '6',    // UI_MAP_TYPE_ORPHAN

	UI_MAP_SYSTEM_WORLD: '0', // UI_MAP_SYSTEM_WORLD
};
