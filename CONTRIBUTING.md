# statacons
## Building
In `src/`: In Stata `zipfile SConstruct config_project.ini utils, saving(project_files, replace)`

# pystatacons
In folder `pypkg`.

## Building
Requirements (python packages): `build` (`python-build` in Anaconda), `wheel`, `setuptools`

```
python -m build
```

## Installing (and dev-mode)
Then you can install from the wheel file (or source distribution) in `dist/`. Or, to install the package in dev-mode (from this dir)
```
conda develop src
```
With pip it would be `pip install -e src`.


## To distribute
Requirements: `twine`. API key
Remember: Keep the two package versions the same. Delete old versions from `dist/`.

```
python -m twine upload dist/*
```
Use `__token__` for username and token value for password.

# Dev-mode (pystatacons and statacons)
If you want to use this package without installing it ("dev" mode), then you need the `src` folder in the adopath. If you're already in Stata and calling one of our programs then getting that initial call working is easy (see code/setup.do). You want something like

```
adopath + ../src
```

But for batch-mode operations (e.g., computing signature from a dta file), started from terminal or Stata, it's a bit trickier and we do this by setting the environment variable before running `scons`.

For starting `scons` from the terminal:
- On Linux you can do:
```
export S_ADO="../src/;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"
```
- And on Windows cmd you can do
```
set S_ADO=../src/;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE
```
For starting `scons` from Stata, you'll want to start python and do:
```
import os
os.environ["S_ADO"] = "../src/;UPDATES;BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"
```

# Docs
1. In `src/`: In Stata `do buildHelpFiles.do`
2. Then in Python you will need `sphinx` and `myst-parser`. Copy `statacons.md`, `sconsign.md`, and `complete_datasignature.md` from `src/` to `docsrc/`. Then do steps in internal repo `CONTRIBUTING.md` and copy those files to `docsrc` (not currently documented well). Then you can go into `docsrc` and `make html` and see the generated docs in `docs/_build/html/index.html` (things should get copied to `docs/`).

# Tests
See `tests/README.md`.

Check Python code with `flake8` and `mypy`.


# Releasing (both)
Versions are kept the same across both type packages.
1. Pass tests?
2. In `src/`: Bump version + date in `statacons.pkg` and `statacons.ado` (both) and `stataconsign.ado` (both).
3. In `pypkg/`: Bump versions in `setup.cfg`, `src/pystatacons/__init__.py` and `docsrc/conf.py`.
4. Update `CHANGELOG.md`
5. Build docs
6. Make release in in GitHub
7. Distrubute Python Package


# To track if new scons versions break our package
Look at the functions we override in `special_sigs.py::monkey_patch_scons()` and `revert_io2` in `runscons.py`.

