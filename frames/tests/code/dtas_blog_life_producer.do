clear all
// Producer fixture for the "Fun with frames"-style life expectancy
// example. SCons uses this to build a .dtas target from three official
// Stata example datasets.
frame create life0
frame create life1
frame create life2
frame life0: sysuse lifeexp, clear
frame life1: sysuse uslifeexp, clear
frame life2: sysuse uslifeexp2, clear
frames save "outputs/life_blog.dtas", frames(life0 life1 life2) replace
