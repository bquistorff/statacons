# Building statacons
1. In folder `src`: Bump version + date in `statacons.pkg` and `statacons.ado` (both) and `stataconsign.ado` (both).


# pystatacons
In folder `pypkg`

## To Build
Requirements (python packages): build, wheel, setuptools

Remember to bump versions in `setup.cfg`, `src/pystatacons/__init__.py` and `docs/conf.py`.
```
python -m build
```

Then you can install from the wheel file (or source distribution) in `dist/`. Or, to install the package in dev-mode (from this dir)
```
conda develop src
```
With pip it would be `pip install -e src`.

Check Python code with `flake8` and `mypy`.

## To distribute
Requirements: twine. API key
Remember: Keep the two package versions the same. Delete old versions from `dist/`.

```
python -m twine upload dist/*
```
Use `__token__` for username and token value for password.

# To track if new scons versions break our package
Look at the functions we override in `monkey_patch_scons()`
