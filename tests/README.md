Setup: 
1. Install `filesys` Stata package: `net install filesys, from(https://raw.github.com/wbuchanan/StataFileSystem/master/)`. (Uses `doenv` (https://github.com/vikjam/doenv), but in ".")
2. Make a `.env` file in the project root (above tests folder) that contains the line `python_env=full path of python.exe` (this will be used by Stata to do a `python set exec ....`).
3. Have Stata automatically findable

Tests:
1. Stata: `do statacons_test.do`
2. CMD: `scons_test.bat`
3. CMD: `scons_test_other.bat` (if setup)
