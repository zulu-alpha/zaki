# ZAKI (Zulu-Alpha Kit Ingestor)

Saves all the usable and desirable kit and their relevant information to a DB file for use in the ZAMF.

## Pipeline

1. Ingestion (save relevant config to DB) - **This repo**
2. Configuration (human editable config referencing DB) - **ZAMF**
3. Output  - **ZAMF**
    1. Documentation (auto generate)  - **ZAMF**
    2. Mission script/sqm (gear or crates sqf or eden mission)  - **ZAMF**

## Installation

1. Install [Pythia](https://github.com/overfl0/Pythia) as per their instructions.
2. Copy the **python** directory in the root of this repo to your root Arma 3 directory (`c:\Program Files (x86)\Steam\steamapps\common\Arma 3`).
3. Copy the **ZAKI.VR** directory into your source missions directory (`c:\Users\< User Name >\Documents\Arma 3 - Other Profiles\< Game User Name >\missions`)

## Usage

1. Load up the ZAKI mission in the Eden editor and select **PLAY SCENARIO**.
2. The config export script should automatically run and create the database (any old one will be automatically deleted). You should see `Finished! DB file located at...` at the bottom left of your screen along with the absolute path to the file, which should be in your root Arma 3 directory.
3. Copy that file to where it is needed for the next part of the pipeline.

## Dev

1. Clone repo to your missions directory.
2. Install [Python 3.5.4](https://www.python.org/downloads/release/python-354/), as this is what Pythia uses.
3. Install [Pipenv](https://pipenv.readthedocs.io/en/latest/install/#pragmatic-installation-of-pipenv)
4. In the repo, execute `pipenv install --dev`.
5. Activate the shell (`pipenv shell`) and run `pre-commit install`.
6. You will now have [pytest](https://docs.pytest.org/en/latest/). Every time you commit, your code will be linted with flake8,  bugbear and mypy.
7. Whenever you want to run Pythia code, make sure to copy the files in the `python` directory over to your root Arma 3 directory. You will also have to restart Arma 3 every time you make a change (unless you find a better way).