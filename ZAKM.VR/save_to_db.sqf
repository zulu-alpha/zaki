_KEY_DISPLAY_NAME = "display_name";
_KEY_DESCRIPTION = "description";
_KEY_MASS = "mass";
_KEY_MAGAZINES = "magazines";
_KEY_ALTERNATE_MAGAZINES = "alternate_magazines";

_KEY_MUZZLE_ATTACHMENTS = "muzzle_attachments";
_KEY_OPTIC_ATTACHMENTS = "optic_attachments";
_KEY_POINTER_ATTACHMENTS = "pointer_attachments";
_KEY_BIPOD_ATTACHMENTS = "bipod_attachments";

_MUZZLE_ATTACHMENTS_COMMON = [];
_OPTIC_ATTACHMENTS_COMMON = [];
_POINTER_ATTACHMENTS_COMMON = [];
_BIPOD_ATTACHMENTS_COMMON = [];

_DB_QUEUE = [];
_MAX_QUEUE = 5000;

log_msg = {
	/*
		Description: 
		Logs given text to both log file and system chat

		Parameter(s):
		0: STRING - String to log

		Returns:
		Nothing
	*/
	params ["_text"];
	systemChat _text;
	diag_log _text;
};

add_to_db_queue = {
	/*
		Description: 
		Adds item to queue to save to db. When queue reaches a safe large number (5000)
		then execute queue.
		5000 is chosen as it's half the experimentally found 10000 array limit that can be
		sent to Pythia.

		Parameter(s):
		0: STRING - Category
		1: STRING - Row
		2: STRING - Key
		3: ANY - Value. It can be a string, number or array of strings

		Returns:
		Nothing
	*/
	params ["_cat", "_row", "_key", "_value"];
	_DB_QUEUE set [count _DB_QUEUE, [_cat, _row, _key, _value]];
	if (_row == "optic_AMS_snd" and _key == "description") then {
		[_value] call log_msg;
	};
	if (count _DB_QUEUE > 5000) then {
		[] call execute_queue;
	};
};

execute_queue = {
	/*
		Description: 
		Sends all the items in the global queue to the db by calling the relevant Pythin
		function via Pythia.

		Parameter(s):
		Nothing

		Returns:
		Nothing
	*/
	private _len = count _DB_QUEUE;
	["python.zakm_ingestion.save_queue_to_db", [_DB_QUEUE]] call py3_fnc_callExtension;
	_DB_QUEUE = [];
	[format ["Saved %1 items to DB", _len]] call log_msg;
};

add_unique_to_list = {
	/*
		Description: 
		Adds classnames (if not already added) of all bipod attachments to save to DB.

		Parameter(s):
		0: ARRAY - Array of classnames
		1: ARRAY - Array of classnames to add to the former

		Returns:
		Nothing
	*/
	params ["_source_array", "_append_array"];
	{
		if !(_x in _append_array) then {_append_array set [count _append_array, _x]};
	} forEach _source_array;
};

weapon_configs = {
	/*
		Description: 
		Get all weapon configs from given base class that relevant to saving to DB.

		Parameter(s):
		0: STRING - String of Base Class

		Returns:
		ARRAY of configs
	*/
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
	/*
		Description: 
		Get all muzzles other than the main one (for alternate magazines)

		Parameter(s):
		0: CONFIG - Config of weapon

		Returns:
		ARRAY of configs
	*/
	params ["_weapon_config"];
	// Get all muzzle class names except "This", which is the primary one
	private _muzzle_names = getArray (_weapon_config >> "muzzles");
	_muzzle_names = _muzzle_names - ["This", "this"];
	// Return an array of configs, not just class names
	_muzzle_names apply {(_weapon_config >> _x)}
};

save_description = {
	/*
		Description: 
		Save the human readable parts of the config to the database

		Parameter(s):
		0: STRING - Category in Database
		1: CONFIG - Config to save text from

		Returns:
		Nothing
	*/
	params ["_cat_name", "_config"];
	// Human readable name
	[
		_cat_name,
		configName _config,
		_KEY_DISPLAY_NAME,
		getText (_config >> "displayName")
	] call add_to_db_queue;
	// Description
	[
		_cat_name,
		configName _config,
		_KEY_DESCRIPTION,
		getText (_config >> "descriptionShort")
	] call add_to_db_queue;
};

save_magazines = {
	/*
		Description: 
		Save details of all the given magazines to the given category of the database.

		Parameter(s):
		0: STRING - Category in Database
		1: ARRAY - Array of configs

		Returns:
		Nothing
	*/
	params ["_cat_name", "_magazines"];
	{
		private _config = (configFile >> "CfgMagazines" >> _x);
		// Description
		[_cat_name, _config] call save_description;
		// Mass
		[
			_cat_name,
			_x,
			_KEY_MASS,
			getNumber (_config >> "mass")
		] call add_to_db_queue;
	} forEach _magazines;
};

save_items = {
	/*
		Description: 
		Save details of all the given items to the given category of the database.

		Parameter(s):
		0: STRING - Category in Database
		1: ARRAY - Array of configs

		Returns:
		Nothing
	*/
	params ["_cat_name", "_items"];
	{
		private _config = (configFile >> "CfgWeapons" >> _x);
		// Description
		[_cat_name, _config] call save_description;
		// Mass
		[
			_cat_name,
			_x,
			_KEY_MASS,
			getNumber (_config >> "ItemInfo" >> "mass")
		] call add_to_db_queue;
	} forEach _items;
};

save_weapons = {
	/*
		Description: 
		Save all relevant information about all the weapons of the given base class to db
		and save attachments to a global array instead for later saving to db (as they
		could be commong to different base calsses of weapons).

		Parameter(s):
		0: STRING - Base class
		1: STRING - Category name in db to save the type of weapons to
		2: STRING - Category name in db to save magazines to
		3: STRING - Category name in db to save alternate magazines to

		Returns:
		Nothing
	*/
	params [
		"_base_class",
		"_cat_name_weapon",
		"_cat_name_magazines",
		"_cat_name_alternate_magazines"
	];
	// Collect common magazines
	private _primary_magazines_common = [];
	// Collect common alternate magazines
	private _alternate_magazines_common = [];
	// Save weapons
	{
		private _config_name = configName _x;
		// Description
		[_cat_name_weapon, _x] call save_description;
		// Mass
		[
			_cat_name_weapon,
			_config_name,
			_KEY_MASS,
			getNumber (_x >> "WeaponSlotsInfo" >> "mass")
		] call add_to_db_queue;
		// Magazines
		private _magazines = getArray (_x >> "magazines");
		// Save magazine in common array if it's not already there
		[_magazines, _primary_magazines_common] call add_unique_to_list;
		// Save primary mags to DB
		[_cat_name_weapon, _config_name, _KEY_MAGAZINES, _magazines] call add_to_db_queue;
		// Alternate magazines (such as grenade launcher). There can be multiple alternate
		// 'muzzles', of which a grenade launcher is one of them.
		private _magazines = [];
		{
			// Save in array for this specific weapon if unique
			[getArray (_x >> "magazines"), _magazines] call add_unique_to_list;
			// Save in array for all weapons of this kind if unique
			[getArray (_x >> "magazines"), _alternate_magazines_common] call add_unique_to_list;
		// Do this for every alternative muzzle config for this weapon
		} forEach ([_x] call alternate_muzzle_configs);
		// Save alternate mags to DB
		[
			_cat_name_weapon,
			_config_name,
			_KEY_ALTERNATE_MAGAZINES,
			_magazines
		] call add_to_db_queue;
		// Save muzzle attachments
		private _attachment_names = [_config_name, "muzzle"] call BIS_fnc_compatibleItems;
		[
			_cat_name_weapon,
			_config_name,
			_KEY_MUZZLE_ATTACHMENTS,
			_attachment_names
		] call add_to_db_queue;
		[_attachment_names, _MUZZLE_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save optic attachments
		private _attachment_names = [_config_name, "optic"] call BIS_fnc_compatibleItems;
		[
			_cat_name_weapon,
			_config_name,
			_KEY_OPTIC_ATTACHMENTS,
			_attachment_names
		] call add_to_db_queue;
		[_attachment_names, _OPTIC_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save pointer attachments
		private _attachment_names = [_config_name, "pointer"] call BIS_fnc_compatibleItems;
		[
			_cat_name_weapon,
			_config_name,
			_KEY_POINTER_ATTACHMENTS,
			_attachment_names
		] call add_to_db_queue;
		[_attachment_names, _POINTER_ATTACHMENTS_COMMON] call add_unique_to_list;
		// Save bipod attachments
		private _attachment_names = [_config_name, "bipod"] call BIS_fnc_compatibleItems;
		[
			_cat_name_weapon,
			_config_name,
			_KEY_BIPOD_ATTACHMENTS,
			_attachment_names
		] call add_to_db_queue;
		[_attachment_names, _BIPOD_ATTACHMENTS_COMMON] call add_unique_to_list;

	} forEach ([_base_class] call weapon_configs);
	// Save details for all primary mags for this category of weapons to their own DB
	[_cat_name_magazines, _primary_magazines_common] call save_magazines;
	// Save details for all alternate mags for this category of weapons to their own DB
	[_cat_name_alternate_magazines, _alternate_magazines_common] call save_magazines;
};

misc_configs = {
	/*
		Description: 
		Save other kind of configs like uniforms

		Parameter(s):

		Returns:

	*/
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

["Starting rifles export to DB..."] call log_msg;
[
	"Rifle",
	"rifles",
	"rifle_primary_magazines",
	"rifle_alternate_magazines"
] call save_weapons;
["Starting pistols export to DB..."] call log_msg;
[
	"Pistol",
	"pistols",
	"pistol_primary_magazines", 
	"pistol_alternate_magazines"
] call save_weapons;
["Starting launchers export to DB..."] call log_msg;
[
	"Launcher",
	"launchers",
	"launcher_primary_magazines",
	"launcher_alternate_magazines"
] call save_weapons;

["Starting attachments export to DB..."] call log_msg;
["muzzle_attachments", _MUZZLE_ATTACHMENTS_COMMON] call save_items;
["optic_attachments", _OPTIC_ATTACHMENTS_COMMON] call save_items;
["pointer_attachments", _POINTER_ATTACHMENTS_COMMON] call save_items;
["bipod_attachments", _BIPOD_ATTACHMENTS_COMMON] call save_items;

// {

// } forEach (["UniformItem", "CfgWeapons"] call misc_configs);

[] call execute_queue;
["Export completed!"] call log_msg;
