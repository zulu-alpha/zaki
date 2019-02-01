import json
from pathlib import Path
from typing import Union, List, Iterable, Tuple


DATABASE_PATH = Path("zakm_db.json")
Value = Union[str, int, float, List[str]]
Item = Tuple[str, str, str, Value]
ItemQueue = Iterable[Item]


def save_queue_to_db(item_queue: ItemQueue) -> None:
    """Add each item in the given queue to the existing (or new) json db file"""
    if DATABASE_PATH.is_file():
        with open(str(DATABASE_PATH), "r") as open_file:
            db = json.loads(open_file.read())
    else:
        db = dict()

    for item in item_queue:
        add_to_db_dict(db, *item)

    with open(str(DATABASE_PATH), "w") as open_file:
        open_file.write(json.dumps(db))


def add_to_db_dict(db: dict, category: str, row: str, key: str, value: Value) -> dict:
    """Add the new item to the given dictionary representation of the db"""
    if category not in db:
        db[category] = dict()
    if row not in db[category]:
        db[category][row] = dict()
    db[category][row][key] = value
    return db
