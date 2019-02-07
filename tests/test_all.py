import json
from collections import OrderedDict


def test_save_queue_to_db(tmp_path):
    from python.zaki_ingestion import save_queue_to_db
    from python import zaki_ingestion

    zaki_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    save_queue_to_db([["rifles", "arifle_MX_F", "display_name", "MX"]])
    assert zaki_ingestion.DATABASE_PATH.is_file()
    with open(str(zaki_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.load(open_file)
        assert db == {
            "rifles" : {
                "arifle_MX_F": {
                    "display_name": "MX"
                }
            }
        }

    save_queue_to_db([
        ["rifles", "arifle_MX_F", "mass", 79],
        [
            "rifles",
            "arifle_MX_F",
            "magazines",
            [
                "30Rnd_65x39_caseless_mag",
                "30Rnd_65x39_caseless_mag_Tracer",
                "ACE_30Rnd_65x39_caseless_mag_Tracer_Dim"
            ]
        ]
    ])
    with open(str(zaki_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.load(open_file)
        assert db == {
            "rifles" : {
                "arifle_MX_F": {
                    "display_name": "MX",
                    "mass": 79,
                    "magazines": [
                        "30Rnd_65x39_caseless_mag",
                        "30Rnd_65x39_caseless_mag_Tracer",
                        "ACE_30Rnd_65x39_caseless_mag_Tracer_Dim"
                    ]
                }
            }
        }

    save_queue_to_db([
        ["rifles", "LMG_Zafir_F", "display_name", "Negev NG7"],
        ["launchers", "launch_RPG32_F", "display_name", "RPG-32"],
        ["launchers", "launch_RPG32_F", "magazines", ["RPG32_F", "RPG32_HE_F"]]
    ])
    with open(str(zaki_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.load(open_file)
        assert db == {
            "rifles" : {
                "arifle_MX_F": {
                    "display_name": "MX",
                    "mass": 79,
                    "magazines": [
                        "30Rnd_65x39_caseless_mag",
                        "30Rnd_65x39_caseless_mag_Tracer",
                        "ACE_30Rnd_65x39_caseless_mag_Tracer_Dim"
                    ]
                },
                "LMG_Zafir_F": {
                    "display_name": "Negev NG7"
                }
            },
            "launchers": {
                "launch_RPG32_F": {
                    "display_name": "RPG-32",
                    "magazines": ["RPG32_F", "RPG32_HE_F"]
                }
            }
        }


def test_utf_sanitization(tmp_path):
    from python.zaki_ingestion import save_queue_to_db
    from python import zaki_ingestion

    zaki_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    save_queue_to_db([
        ["rifles", "arifle_MX_F", "display_name", "MX 6.5\u00a0mm"],
        ["optic_attachments", "optic_Nightstalker", "description",
         "Nightstalker Sight<br />Magnification: 4x\u201310x"],
        ["rifle_primary_magazines", "30Rnd_65x39_caseless_mag", "description",
         ("Caliber: 6.5x39 mm \u2012 STANAG Caseless"
          "<br />Rounds: 30<br />Used in: MX/C/M/SW/3GL")],
        ["rifles", "srifle_EBR_F", "description",
         "Assault rifle <br/>Caliber: 7.62x51 mm NATO"]
    ])

    assert zaki_ingestion.DATABASE_PATH.is_file()
    with open(str(zaki_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.load(open_file)
        assert db == {
            "rifles" : {
                "arifle_MX_F": {
                    "display_name": "MX 6.5 mm"
                },
                "srifle_EBR_F": {
                    "description": "Assault rifle  Caliber: 7.62x51 mm NATO"
                }
            },
            "optic_attachments": {
                "optic_Nightstalker": {
                    "description": "Nightstalker Sight Magnification: 4x-10x"
                }
            },
            "rifle_primary_magazines": {
                "30Rnd_65x39_caseless_mag": {
                    "description": ("Caliber: 6.5x39 mm - STANAG Caseless"
                                    " Rounds: 30 Used in: MX/C/M/SW/3GL")
                }
            }
        }


def test_delete(tmp_path):
    from python.zaki_ingestion import delete_db
    from python import zaki_ingestion

    zaki_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    with open(str(zaki_ingestion.DATABASE_PATH), "w") as open_file:
        open_file.write("test")
    delete_db()
    assert not zaki_ingestion.DATABASE_PATH.is_file()


def test_get_db_path(tmp_path):
    from python.zaki_ingestion import get_db_path
    from python import zaki_ingestion

    zaki_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    assert get_db_path() == str(zaki_ingestion.DATABASE_PATH.absolute())


def test_sort_db(tmp_path):
    from python.zaki_ingestion import sort_db
    from python import zaki_ingestion

    zaki_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    unsorted_dic = OrderedDict([
        (
            "Vests", OrderedDict([
                (
                    "CUP_V_B_BAF_DDPM_Osprey_Mk3_AutomaticRifleman", OrderedDict([
                        ("display_name", "Osprey Mk3 DDPM (Automatic Rifleman)"),
                        ("description", "No Armor")
                    ])
                ),
                (
                    "V_HarnessO_brn", OrderedDict([
                        ("display_name", "LBV Harness"),
                        ("description", "No Armor")
                    ])
                ),
                (
                    "V_PlateCarrier1_blk", OrderedDict([
                        ("display_name", "Carrier Lite (Black)"),
                        ("description", "Armor Level III")
                    ])
                )
            ])
        ),
        (
            "Binoculars", OrderedDict([
                (
                    "Binocular", OrderedDict([
                        ("display_name", "Binoculars"),
                        ("description", "Magnification: 4x-12x")
                    ])
                ),
                (
                    "ACE_Yardage450", OrderedDict([
                        ("display_name", "Yardage 450"),
                        ("description", "Laser Rangefinder")
                    ])
                ),
                (
                    "Laserdesignator_02_ghex_F", OrderedDict([
                        ("display_name", "Laser Designator (Green Hex)"),
                        ("description", "Magnification: 1x-20x")
                    ])
                )
            ])
        )
    ])
    sorted_dic = OrderedDict([
        (
            "Binoculars", OrderedDict([
                (
                    "Binocular", OrderedDict([
                        ("display_name", "Binoculars"),
                        ("description", "Magnification: 4x-12x")
                    ])
                ),
                (
                    "Laserdesignator_02_ghex_F", OrderedDict([
                        ("display_name", "Laser Designator (Green Hex)"),
                        ("description", "Magnification: 1x-20x")
                    ])
                ),
                (
                    "ACE_Yardage450", OrderedDict([
                        ("display_name", "Yardage 450"),
                        ("description", "Laser Rangefinder")
                    ])
                )
            ])
        ),
        (
            "Vests", OrderedDict([
                (
                    "V_PlateCarrier1_blk", OrderedDict([
                        ("display_name", "Carrier Lite (Black)"),
                        ("description", "Armor Level III")
                    ])
                ),
                (
                    "V_HarnessO_brn", OrderedDict([
                        ("display_name", "LBV Harness"),
                        ("description", "No Armor")
                    ])
                ),
                (
                    "CUP_V_B_BAF_DDPM_Osprey_Mk3_AutomaticRifleman", OrderedDict([
                        ("display_name", "Osprey Mk3 DDPM (Automatic Rifleman)"),
                        ("description", "No Armor")
                    ])
                )
            ])
        )
    ])
    with open(str(zaki_ingestion.DATABASE_PATH), "w") as open_file:
        json.dump(unsorted_dic, open_file)
    sort_db("display_name")
    with open(str(zaki_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.load(open_file, object_pairs_hook=OrderedDict)
    assert db == sorted_dic
