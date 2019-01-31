import json
from pathlib import Path
from typing import Union, List


DATABASE_PATH = Path("zakm_db.json")
Value = Union[str, int, float, List[str]]


def add_to_db(category: str, row: str, key: str, value: Value) -> None:
    """Add the new data to the existing (or new) json db file"""
    if DATABASE_PATH.is_file():
        with open(str(DATABASE_PATH), "r") as open_file:
            db = json.loads(open_file.read())
    else:
        db = dict()
    if category not in db:
        db[category] = dict()
    if row not in db[category]:
        db[category][row] = dict()
    db[category][row][key] = value
    with open(str(DATABASE_PATH), "w") as open_file:
        open_file.write(json.dumps(db))
