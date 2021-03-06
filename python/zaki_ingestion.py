import json
from collections import OrderedDict
from pathlib import Path
from typing import Union, List, Iterable, Tuple


DATABASE_PATH = Path("zaki_db.json")
Value = Union[str, int, float, List[str]]
Item = Tuple[str, str, str, Value]
ItemQueue = Iterable[Item]


def delete_db() -> None:
    """Deletes the db. Used to clear out an old db from a previous session"""
    if DATABASE_PATH.is_file():
        DATABASE_PATH.unlink()


def save_queue_to_db(item_queue: ItemQueue) -> None:
    """Add each item in the given queue to the existing (or new) json db file"""
    if DATABASE_PATH.is_file():
        with open(str(DATABASE_PATH), "r") as open_file:
            db = json.load(open_file)
    else:
        db = dict()

    for item in item_queue:
        add_to_db_dict(db, *item)

    with open(str(DATABASE_PATH), "w") as open_file:
        json.dump(db, open_file, ensure_ascii=True)


def sanitize(value: Value) -> Value:
    """Sanitizes the given string so that it becomes more readable"""
    if type(value) == str:
        value = str(value).replace("<br />", " ")
        value = value.replace("<br/>", " ")
        value = value.replace("\u00a0", " ")
        value = value.replace("\u2013", "-")
        value = value.replace("\u2012", "-")
        value = value = value.encode("ascii", "ignore").decode("utf-8")
    return value


def add_to_db_dict(db: dict, category: str, row: str, key: str, value: Value) -> dict:
    """Add the new item to the given dictionary representation of the db"""
    if category not in db:
        db[category] = dict()
    if row not in db[category]:
        db[category][row] = dict()
    db[category][row][key] = sanitize(value)
    return db


def sort_db(key: str) -> None:
    """Sorts the database by the given key. It will assume that the key is in a depth of
    3 (i.e: db[level_1_key][level_2_key][given_key_to_sort_by]). Each category (1st level)
    will be sorted separately. It will also sort the top level keys.
    """
    with open(str(DATABASE_PATH), "r") as open_file:
        unsorted_dic = json.load(open_file, object_pairs_hook=OrderedDict)
    partially_sorted_dic = OrderedDict(sorted(unsorted_dic.items(), key=lambda i: i[0]))
    sorted_dic = OrderedDict()  # type: OrderedDict
    for cat, rows in partially_sorted_dic.items():
        sorted_rows = OrderedDict(
            sorted(rows.items(), key=lambda i: i[1][key])
        )
        sorted_dic[cat] = sorted_rows
    with open(str(DATABASE_PATH), "w") as open_file:
        json.dump(sorted_dic, open_file, ensure_ascii=True)


def get_db_path() -> str:
    """Returns a string showing the absolute path to the db file"""
    return str(DATABASE_PATH.absolute())
