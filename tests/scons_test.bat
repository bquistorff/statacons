Rem Test: scons in CMD. Tests that require looking at the output are marked with MANUAL
Rem We test just the things that might be different in CMD (we test more in Stata)
Rem Must set your python env prior to running
Rem To run in cmd just type the filename


Rem Test dta_sig works (is found) and so second build doesn't do anything
scons -c
scons
del outputs\auto-modified.dta
scons
Rem MANUAL check that the last command built the first but not the second


Rem Test assume-done works (parsing)
scons -f SConstruct-timestamp -c
scons -f SConstruct-timestamp
Rem This is how you touch! (https://superuser.com/a/764721)
copy /b inputs\auto-original.dta +,, inputs\auto-original.dta
scons -f SConstruct-timestamp --assume-done="code/dataprep.do"
scons -f SConstruct-timestamp
Rem MANUAL: Make sure last two didn't build anything


Rem Test parallel
cd simpleParallel
scons -j 2
Rem MANUAL: Make sure the last command did things in parallel
cd ..
