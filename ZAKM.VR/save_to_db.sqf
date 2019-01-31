2call compile preProcessFile "\iniDB\init.sqf";

// Common variables
private _key_display_name = "display_name";
private _key_description = "description";
private _key_mass = "mass";
private _key_magazines = "magazines";
private _key_alternate_magazines = "alternate_magazines";

private _key_muzzle_attachments = "muzzle_attachments";
private _key_optic_attachments = "optic_attachments";
private _key_pointer_attachments = "pointer_attachments";
private _key_bipod_attachments = "bipod_attachments";


/*
	Helper functions
*/
// Removes " from string and return a string what is missing those.
sanatize_inches = {
	((_this select 0) splitString (toString [34])) joinString ""
};


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
		// Is of the correct kind, is intended for the user to see (scope == 2) and has no attatchements
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
	[_db_name, configName _config, _key_display_name, [getText (_config >> "displayName")] call sanatize_inches] call iniDB_write;
	// Description
	[_db_name, configName _config, _key_description, [getText (_config >> "descriptionShort")] call sanatize_inches] call iniDB_write;
};

save_magazines = {
	params ["_db_name", "_magazines"];
	{
		private _config = (configFile >> "CfgMagazines" >> _x);
		// Description
		[_db_name, _config] call save_description;
		// Mass
		[_db_name, _x, _key_mass, getNumber (_config >> "mass")] call iniDB_write;
	} forEach _magazines;
};

save_items = {
	params ["_db_name", "_items"];
	{
		private _config = (configFile >> "CfgWeapons" >> _x);
		// Description
		[_db_name, _config] call save_description;
		// Mass
		[_db_name, _x, _key_mass, getNumber (_config >> "ItemInfo" >> "mass")] call iniDB_write;
	} forEach _items;
};

save_weapon = {
	params ["_base_class", "_db_name_weapon", "_db_name_magazines", "_db_name_alternate_magazines"];
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
		[_db_name_weapon, _config_name, _key_mass, getNumber (_x >> "WeaponSlotsInfo" >> "mass")] call iniDB_write;
		// Magazines
		private _magazines = getArray (_x >> "magazines");
		// Save magazine in common array if it's not already there
		[_magazines, _primary_magazines_common] call add_unique_to_list;
		// Save primary mags to DB
		[_db_name_weapon, _config_name, _key_magazines, _magazines] call iniDB_write;
		// Alternate magazines (such as grenade launcher). There can be multiple alternate 'muzzles',
		// of which a grenade launcher is one of them.
		private _magazines = [];
		{
			// Save in array for this specific weapon if unique
			[getArray (_x >> "magazines"), _magazines] call add_unique_to_list;
			// Save in array for all weapons of this kind unique
			[getArray (_x >> "magazines"), _alternate_magazines_common] call add_unique_to_list;
		// Do this for every alternative muzzle config for this weapon
		} forEach ([_x] call alternate_muzzle_configs);
		// Save alternate mags to DB
		[_db_name_weapon, _config_name, _key_alternate_magazines, _magazines] call iniDB_write;
		// Save muzzle attachments
		private _attachment_names = [_config_name, "muzzle"] call BIS_fnc_compatibleItems;
		[_db_name_weapon, _config_name, _key_muzzle_attachments, _attachment_names] call iniDB_write;
		[_attachment_names, _muzzle_attachments_common] call add_unique_to_list;
		// Save optic attachments
		private _attachment_names = [_config_name, "optic"] call BIS_fnc_compatibleItems;
		[_db_name_weapon, _config_name, _key_optic_attachments, _attachment_names] call iniDB_write;
		[_attachment_names, _optic_attachments_common] call add_unique_to_list;
		// Save pointer attachments
		private _attachment_names = [_config_name, "pointer"] call BIS_fnc_compatibleItems;
		[_db_name_weapon, _config_name, _key_pointer_attachments, _attachment_names] call iniDB_write;
		[_attachment_names, _pointer_attachments_common] call add_unique_to_list;
		// Save bipod attachments
		private _attachment_names = [_config_name, "bipod"] call BIS_fnc_compatibleItems;
		[_db_name_weapon, _config_name, _key_bipod_attachments, _attachment_names] call iniDB_write;
		[_attachment_names, _bipod_attachments_common] call add_unique_to_list;

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

private _muzzle_attachments_common = [];
private _optic_attachments_common = [];
private _pointer_attachments_common = [];
private _bipod_attachments_common = [];

["Rifle", "rifles", "rifle_primary_magazines", "rifle_alternate_magazines"] call save_weapon;
["Pistol", "pistols", "pistol_primary_magazines", "pistol_alternate_magazines"] call save_weapon;
["Launcher", "launchers", "launcher_primary_magazines", "launcher_alternate_magazines"] call save_weapon;

["muzzle_attachments", _muzzle_attachments_common] call save_items;
["optic_attachments", _optic_attachments_common] call save_items;
["pointer_attachments", _pointer_attachments_common] call save_items;
["bipod_attachments", _bipod_attachments_common] call save_items;

{

} forEach (["UniformItem", "CfgWeapons"] call misc_configs);
