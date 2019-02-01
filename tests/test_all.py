import json


def test_save_queue_to_db(tmp_path):
    from python.zakm_ingestion import save_queue_to_db
    from python import zakm_ingestion

    zakm_ingestion.DATABASE_PATH = tmp_path / "new_file.json"

    save_queue_to_db([["rifles", "arifle_MX_F", "display_name", "MX"]])
    assert zakm_ingestion.DATABASE_PATH.is_file()
    with open(str(zakm_ingestion.DATABASE_PATH), "r") as open_file:
        db = json.loads(open_file.read())
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
        db = json.loads(open_file.read())
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
        db = json.loads(open_file.read())
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
