// Common variables
private _KEY_DISPLAY_NAME = "display_name";
private _KEY_DESCRIPTION = "description";
private _KEY_MASS = "mass";
private _KEY_MAGAZINES = "magazines";
private _KEY_ALTERNATE_MAGAZINES = "alternate_magazines";

private _KEY_MUZZLE_ATTACHMENTS = "muzzle_attachments";
private _KEY_OPTIC_ATTACHMENTS = "optic_attachments";
private _KEY_POINTER_ATTACHMENTS = "pointer_attachments";
private _KEY_BIPOD_ATTACHMENTS = "bipod_attachments";

private _MUZZLE_ATTACHMENTS_COMMON = [];
private _OPTIC_ATTACHMENTS_COMMON = [];
private _POINTER_ATTACHMENTS_COMMON = [];
private _BIPOD_ATTACHMENTS_COMMON = [];

/*
	Helper functions
*/
add_unique_to_list = {
	params ["_source_array", "_append_array"];
	{
		if !(_x in _append_array) then {_append_array set [count _append_array, _x]};
	} forEach _source_array;
};

weapon_configs = {
	params ["_base_class"];
	private _config = (configFile >> "CfgWeapons");
	configProperties [
		_config,
		// Is of the correct kind, is intended for the user to see (scope == 2) and has 
		// no attatchements
		"(configName _x isKindOf [_base_class, _config])
			and (getNumber (_x >> 'scope') == 2)
			and !isClass (_x >> 'LinkedItems')",
		true
	]
};

alternate_muzzle_configs = {
	params ["_weapon_config"];
	// Get all muzzle class names except "This", which is the primary one
	private _muzzle_names = getArray (_weapon_config >> "muzzles");
	_muzzle_names = _muzzle_names - ["This", "this"];
	// Return an array of configs, not just class names
	_muzzle_names apply {(_weapon_config >> _x)}
};

save_description = {
	params ["_db_name", "_config"];
	// Human readable name
	[
		"python.zakm_ingestion.add_to_db",
		[
			_db_name,
			configName _config,
			_KEY_DISPLAY_NAME,
			getText (_config >> "displayName")
		]
	] call py3_fnc_callExtension;
	// Description
	[
		"python.zakm_ingestion.add_to_db",
		[
			_db_name,
			configName _config,
			_KEY_DESCRIPTION,
			getText (_config >> "descriptionShort")
		]
	] call py3_fnc_callExtension;
};

save_magazines = {
	params ["_db_name", "_magazines"];
	{
		private _config = (configFile >> "CfgMagazines" >> _x);
		// Description
		[_db_name, _config] call save_description;
		// Mass
		[
			"python.zakm_ingestion.add_to_db",
			[
				_db_name,
				_x,
				_KEY_MASS,
				getNumber (_config >> "mass")
			]
		] call py3_fnc_callExtension;
	} forEach _magazines;
};

save_items = {
	params ["_db_name", "_items"];
	{
		private _config = (configFile >> "CfgWeapons" >> _x);
		// Description
		[_db_name, _config] call save_description;
		// Mass
		[
			"python.zakm_ingestion.add_to_db",
			[
				_db_name,
				_x,
				_KEY_MASS,
				getNumber (_config >> "ItemInfo" >> "mass")
			]
		] call py3_fnc_callExtension;
	} forEach _items;
};

save_weapon = {
	params [
		"_base_class",
		"_db_name_weapon",
		"_db_name_magazines",
		"_db_name_alternate_magazines"
	];
	// Collect common magazines
	private _primary_magazines_common = [];
	// Collect common alternate magazines
	private _alternate_magazines_common = [];
	// Save weapons
	{
		private _config_name = configName _x;
		// Description
		[_db_name_weapon, _x] call save_description;
		// Mass
		[
			"python.zakm_ingestion.add_to_db",
			[
				_db_name_weapon,
				_config_name,
				_KEY_MASS,
				getNumber (_x >> "WeaponSlotsInfo" >> "mass")
			]
		] call py3_fnc_callExtension;
		// Magazines
		private _magazines = getArray (_x >> "magazines");
		// Save magazine in common array if it's not already there
		[_magazines, _primary_magazines_common] call add_unique_to_list;
		// Save primary mags to DB
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_MAGAZINES, _magazines]
		] call py3_fnc_callExtension;
		// Alternate magazines (such as grenade launcher). There can be multiple alternate
		// 'muzzles', of which a grenade launcher is one of them.
		private _magazines = [];
		{
			// Save in array for this specific weapon if unique
			[getArray (_x >> "magazines"), _magazines] call add_unique_to_list;
			// Save in array for all weapons of this kind unique
			[getArray (_x >> "magazines"), _alternate_magazines_common] call add_unique_to_list;
		// Do this for every alternative muzzle config for this weapon
		} forEach ([_x] call alternate_muzzle_configs);
		// Save alternate mags to DB
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_ALTERNATE_MAGAZINES, _magazines]
		] call py3_fnc_callExtension;
		// Save muzzle attachments
		private _attachment_names = [_config_name, "muzzle"] call BIS_fnc_compatibleItems;
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_MUZZLE_ATTACHMENTS, _attachment_names]
		] call py3_fnc_callExtension;
		[_attachment_names, _MUZZLE_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save optic attachments
		private _attachment_names = [_config_name, "optic"] call BIS_fnc_compatibleItems;
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_OPTIC_ATTACHMENTS, _attachment_names]
		] call py3_fnc_callExtension;
		[_attachment_names, _OPTIC_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save pointer attachments
		private _attachment_names = [_config_name, "pointer"] call BIS_fnc_compatibleItems;
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_POINTER_ATTACHMENTS, _attachment_names]
		] call py3_fnc_callExtension;
		[_attachment_names, _POINTER_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save bipod attachments
		private _attachment_names = [_config_name, "bipod"] call BIS_fnc_compatibleItems;
		[
			"python.zakm_ingestion.add_to_db",
			[_db_name_weapon, _config_name, _KEY_BIPOD_ATTACHMENTS, _attachment_names]
		] call py3_fnc_callExtension;
		[_attachment_names, _BIPOD_ATTACHMENTS_COMMON] call add_unique_to_list;

	} forEach ([_base_class] call weapon_configs);
	// Save details for all primary mags for this category of weapons to their own DB
	[_db_name_magazines, _primary_magazines_common] call save_magazines;
	// Save details for all alternate mags for this category of weapons to their own DB
	[_db_name_alternate_magazines, _alternate_magazines_common] call save_magazines;
};

misc_configs = {
	params ["_base_class", "_config_type"];
	private _config = (configFile >> _config_type);
	configProperties [
		_config,
		// Is of the correct kind, is intended for the user to see (scope == 2)
		"(configName _x isKindOf [_base_class, _config])
			and (getNumber (_x >> 'scope') == 2)",
		true
	]
};

[
	"Rifle",
	"rifles",
	"rifle_primary_magazines",
	"rifle_alternate_magazines"
] call save_weapon;
[
	"Pistol",
	"pistols",
	"pistol_primary_magazines", 
	"pistol_alternate_magazines"
] call save_weapon;
[
	"Launcher",
	"launchers",
	"launcher_primary_magazines",
	"launcher_alternate_magazines"
] call save_weapon;

["muzzle_attachments", _MUZZLE_ATTACHMENTS_COMMON] call save_items;
["optic_attachments", _OPTIC_ATTACHMENTS_COMMON] call save_items;
["pointer_attachments", _POINTER_ATTACHMENTS_COMMON] call save_items;
["bipod_attachments", _BIPOD_ATTACHMENTS_COMMON] call save_items;

// {

// } forEach (["UniformItem", "CfgWeapons"] call misc_configs);
