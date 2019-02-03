import json


def test_save_queue_to_db(tmp_path):
    from python.zakm_ingestion import save_queue_to_db
    from python import zakm_ingestion

    zakm_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    save_queue_to_db([["rifles", "arifle_MX_F", "display_name", "MX"]])
    assert zakm_ingestion.DATABASE_PATH.is_file()
    with open(str(zakm_ingestion.DATABASE_PATH), "r") as open_file:
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
    with open(str(zakm_ingestion.DATABASE_PATH), "r") as open_file:
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
    with open(str(zakm_ingestion.DATABASE_PATH), "r") as open_file:
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
    from python.zakm_ingestion import save_queue_to_db
    from python import zakm_ingestion

    zakm_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

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

    assert zakm_ingestion.DATABASE_PATH.is_file()
    with open(str(zakm_ingestion.DATABASE_PATH), "r") as open_file:
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
    from python.zakm_ingestion import delete_db
    from python import zakm_ingestion

    zakm_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    with open(str(zakm_ingestion.DATABASE_PATH), "w") as open_file:
        open_file.write("test")
    delete_db()
    assert not zakm_ingestion.DATABASE_PATH.is_file()


def test_get_db_path(tmp_path):
    from python.zakm_ingestion import get_db_path
    from python import zakm_ingestion

    zakm_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    assert get_db_path() == str(zakm_ingestion.DATABASE_PATH.absolute())
