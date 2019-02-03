/*
    Author:
    Phoenix, but based on ACE3 arsenal function by Dedmen to increase my expectancy:
    https://github.com/acemod/ACE3/blob/master/addons/arsenal/functions/fnc_scanConfig.sqf

    Description:
    Scans all configs and puts desirable objects and wanted information into a json file.

    Arguments:
    Nothing

    Returns:
    Nothing
*/

_CAT_RIFLES = "Rifles";
_CAT_SIDEARMS = "Sidearms";
_CAT_SECONDARY = "Secondary";
_CAT_OPTIC_ATTACHMENTS = "Optic_Attachments";
_CAT_SIDE_ATTACHMENTS = "Side_Attachments";
_CAT_MUZZLE_ATTACHMENTS = "Muzzle_Attachments";
_CAT_BIPOD_ATTACHMENTS = "Bipod_Attachments";
_CAT_MAGAZINES = "Magazines";
_CAT_HEADGEAR = "Headgear";
_CAT_UNIFORMS = "Uniforms";
_CAT_VESTS = "Vests";
_CAT_BACKPACKS = "Backpacks";
_CAT_GOGGLES = "Goggles";
_CAT_NVGS = "NVGs";
_CAT_BINOCULARS = "Binoculars";
_CAT_MAPS = "Map";
_CAT_COMPASSES = "Compasses";
_CAT_RADIOS = "Radios";
_CAT_WATCHES = "Watches";
_CAT_INTERFACES = "Interfaces";
_CAT_GRENADES = "Grenades";
_CAT_EXPLOSIVES = "Explosives";
_CAT_MISC = "Miscelaneous";

_KEY_DISPLAY_NAME = "display_name";
_KEY_DESCRIPTION = "description";

_DB_QUEUE = [];
_MAX_QUEUE = 5000;

// Weapon types
_TYPE_WEAPON_PRIMARY = 1;
_TYPE_WEAPON_HANDGUN = 2;
_TYPE_WEAPON_SECONDARY = 4;
// Magazine types
_TYPE_MAGAZINE_HANDGUN_AND_GL = 16;  // Mainly
_TYPE_MAGAZINE_PRIMARY_AND_THROW = 256;
_TYPE_MAGAZINE_SECONDARY_AND_PUT = 512;  // Mainly
// More types
_TYPE_BINOCULAR_AND_NVG = 4096;
// Item types
_TYPE_MUZZLE = 101;
_TYPE_OPTICS = 201;
_TYPE_FLASHLIGHT = 301;
_TYPE_BIPOD = 302;
_TYPE_FIRST_AID_KIT = 401;
_TYPE_HEADGEAR = 605;
_TYPE_BINOCULAR = 617;
_TYPE_MEDIKIT = 619;
_TYPE_TOOLKIT = 620;
_TYPE_UAV_TERMINAL = 621;
_TYPE_VEST = 701;
_TYPE_UNIFORM = 801;


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
    _DB_QUEUE pushBackUnique [_cat, _row, _key, _value];
    if (count _DB_QUEUE > 5000) then {
        [] call execute_queue;
    };
};

execute_queue = {
    /*
        Description: 
        Sends all the items in the global queue to the db by calling the relevant Python
        function via Pythia.

        Parameter(s):
        Nothing

        Returns:
        Nothing
    */
    private _len = count _DB_QUEUE;
    ["python.zaki_ingestion.save_queue_to_db", [_DB_QUEUE]] call py3_fnc_callExtension;
    _DB_QUEUE = [];
    [format ["Saved %1 items to DB", _len]] call log_msg;
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


["Starting export to DB..."] call log_msg;
["python.zaki_ingestion.delete_db", []] call py3_fnc_callExtension;

// Save this lookup in variable for performance improvement
private _configCfgWeapons = configFile >> "CfgWeapons";  

{
    private _configItemInfo = _x >> "ItemInfo";
    private _simulationType = getText (_x >> "simulation");
    private _className = configName _x;
    private _hasItemInfo = isClass (_configItemInfo);
    private _itemInfoType = if (_hasItemInfo) then {
        getNumber (_configItemInfo >> "type")
    } else {0};

    switch true do {
        /* Weapon acc */
        case (
                _hasItemInfo and
                {_itemInfoType in [
                    _TYPE_MUZZLE,
                    _TYPE_OPTICS,
                    _TYPE_FLASHLIGHT,
                    _TYPE_BIPOD
                ]} and
                {!(configName _x isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}
            ): {
            // Find category to use based on array index
            private _cat = [
                _CAT_OPTIC_ATTACHMENTS,
                _CAT_SIDE_ATTACHMENTS,
                _CAT_MUZZLE_ATTACHMENTS,
                _CAT_BIPOD_ATTACHMENTS
            ] select ([
                _TYPE_OPTICS,
                _TYPE_FLASHLIGHT,
                _TYPE_MUZZLE,
                _TYPE_BIPOD
            ] find _itemInfoType);
            [_cat, _x] call save_description;
        };
        /* Headgear */
        case (_itemInfoType == _TYPE_HEADGEAR): {
            [_CAT_HEADGEAR, _x] call save_description;
        };
        /* Uniform */
        case (_itemInfoType == _TYPE_UNIFORM): {
            [_CAT_UNIFORMS, _x] call save_description;
        };
        /* Vest */
        case (_itemInfoType == _TYPE_VEST): {
            [_CAT_VESTS, _x] call save_description;
        };
        /* NVgs */
        case (_simulationType == "NVGoggles"): {
            [_CAT_NVGS, _x] call save_description;
        };
        /* Binos */
        case (_simulationType == "Binocular" or
            (
                (_simulationType == 'Weapon') and {
                    (getNumber (_x >> 'type') == _TYPE_BINOCULAR_AND_NVG)
                }
            )): {
            [_CAT_BINOCULARS, _x] call save_description;
        };
        /* Map */
        case (_simulationType == "ItemMap"): {
            [_CAT_MAPS, _x] call save_description;
        };
        /* Compass */
        case (_simulationType == "ItemCompass"): {
            [_CAT_COMPASSES, _x] call save_description;
        };
        /* Radio */
        case (_simulationType == "ItemRadio"): {
            [_CAT_RADIOS, _x] call save_description;
        };
        /* Watch */
        case (_simulationType == "ItemWatch"): {
            [_CAT_WATCHES, _x] call save_description;
        };
        /* GPS */
        case (_simulationType == "ItemGPS"): {
            [_CAT_INTERFACES, _x] call save_description;
        };
        /* UAV terminals */
        case (_itemInfoType == _TYPE_UAV_TERMINAL): {
            [_CAT_INTERFACES, _x] call save_description;
        };
        /* Weapon, at the bottom to avoid adding binos */
        case (isClass (_x >> "WeaponSlotsInfo") and
            {getNumber (_x >> 'type') != _TYPE_BINOCULAR_AND_NVG} and 
            {!isClass (_x >> 'LinkedItems')}): {
            switch (getNumber (_x >> "type")) do {
                case _TYPE_WEAPON_PRIMARY: {
                    [_CAT_RIFLES, _x] call save_description;
                };
                case _TYPE_WEAPON_HANDGUN: {
                    [_CAT_SIDEARMS, _x] call save_description;
                };
                case _TYPE_WEAPON_SECONDARY: {
                    [_CAT_SECONDARY, _x] call save_description;
                };
            };
        };
        /* Misc items */
        case (
                _hasItemInfo and (
                    _itemInfoType in [
                        _TYPE_MUZZLE,
                        _TYPE_OPTICS,
                        _TYPE_FLASHLIGHT,
                        _TYPE_BIPOD
                    ] and
                    {(_className isKindOf ["CBA_MiscItem", (_configCfgWeapons)])}
                ) or
                {_itemInfoType in [_TYPE_FIRST_AID_KIT, _TYPE_MEDIKIT, _TYPE_TOOLKIT]} or
                {(getText ( _x >> "simulation")) == "ItemMineDetector"}
            ): {
            [_CAT_MISC, _x] call save_description;
        };
    };
} foreach configProperties [
    _configCfgWeapons,
    "isClass _x and {
        (if (isNumber (_x >> 'scopeArsenal')) then {
            getNumber (_x >> 'scopeArsenal')
        } else {
            getNumber (_x >> 'scope')
        }) == 2
    } and {
        getNumber (_x >> 'ace_arsenal_hide') != 1
    }",
    true
];

private _grenadeList = [];
{
    _grenadeList append getArray (_configCfgWeapons >> "Throw" >> _x >> "magazines");
} foreach getArray (_configCfgWeapons >> "Throw" >> "muzzles");

private _putList = [];
{
    _putList append getArray (_configCfgWeapons >> "Put" >> _x >> "magazines");
} foreach getArray (_configCfgWeapons >> "Put" >> "muzzles");

{
    private _className = configName _x;

    switch true do {
        // Rifle, handgun, secondary weapons mags
        case (
                ((getNumber (_x >> "type") in [
                    _TYPE_MAGAZINE_PRIMARY_AND_THROW,
                    _TYPE_MAGAZINE_SECONDARY_AND_PUT,
                    1536,
                    _TYPE_MAGAZINE_HANDGUN_AND_GL
                ]) or
                {(getNumber (_x >> "ace_arsenal_hide")) == -1}) and
                {!(_className in _grenadeList)} and
                {!(_className in _putList)}
            ): {
            [_CAT_MAGAZINES, _x] call save_description;
        };
        // Grenades
        case (_className in _grenadeList): {
            [_CAT_GRENADES, _x] call save_description;
        };
        // Put
        case (_className in _putList): {
            [_CAT_EXPLOSIVES, _x] call save_description;
        };
    };
} foreach configProperties [
    (configFile >> "CfgMagazines"),
    "isClass _x and {
        (if (isNumber (_x >> 'scopeArsenal')) then {
            getNumber (_x >> 'scopeArsenal')
        } else {
            getNumber (_x >> 'scope')
        }) == 2
    } and {
        getNumber (_x >> 'ace_arsenal_hide') != 1
    }",
    true
];

{
    if (getNumber (_x >> "isBackpack") == 1) then {
        [_CAT_BACKPACKS, _x] call save_description;
    };
} foreach configProperties [
    (configFile >> "CfgVehicles"),
    "isClass _x and {
        (if (isNumber (_x >> 'scopeArsenal')) then {
            getNumber (_x >> 'scopeArsenal')
        } else {
            getNumber (_x >> 'scope')
        }) == 2
    } and {
        getNumber (_x >> 'ace_arsenal_hide') != 1
    }",
    true
];

{
    [_CAT_GOGGLES, _x] call save_description;
} foreach configProperties [
    (configFile >> "CfgGlasses"),
    "isClass _x and {
        (if (isNumber (_x >> 'scopeArsenal')) then {
            getNumber (_x >> 'scopeArsenal')
        } else {
            getNumber (_x >> 'scope')
        }) == 2
    } and {
        getNumber (_x >> 'ace_arsenal_hide') != 1
    }",
    true
];

[] call execute_queue;
private _path = ["python.zaki_ingestion.get_db_path", []] call py3_fnc_callExtension;
[format ["Finished! DB file located at %1", _path]] call log_msg;
