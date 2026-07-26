// example-04-frameset-save-use.do
// Demonstrates: frames save, frames use, frames modify, frames describe
//
// Replicates the frames save/use/modify examples from the help files.
// Datasets required: ../datasets/hsng.dta  (plus sysuse auto, sysuse census)
// All paths are relative to the assumed working directory: frames/examples/
// Run from frames/examples/ with:
//   do example-04-frameset-save-use.do              (interactive)
//   StataMP-64.exe -e do example-04-frameset-save-use.do  (batch)
// ----------------------------------------------------------------

clear all

local datasets "../datasets"

// ---- 1. Build two frames ----
frame create census
frame change census
sysuse census                                     // 50 states, 1980 census

frame create housing
frame change housing
use "`datasets'/hsng", clear                      // housing cost data

// ---- 2. Save to a .dtas file ----
frames save myframeset, frames(census housing)
// Creates myframeset.dtas in the current working directory

// ---- 3. Describe the frameset on disk ----
frames describe using myframeset                  // detailed
frames describe using myframeset, short           // just obs/vars summary

// ---- 4. Load the frameset back ----
frames reset                                      // clear everything
frames use myframeset, clear
frames dir
pwf                                               // 'census' -- first frame saved

// ---- 5. Partial load ----
frames reset
frames use myframeset, frames(housing)            // load only housing
frames dir                                        // only housing in memory

// ---- 6. frames modify: add a frame to the file ----
frame create auto
frame change auto
sysuse auto

frames modify using myframeset, add(auto)
frames describe using myframeset, short           // now 3 frames in the file

// ---- 7. frames modify: drop a frame from the file ----
frames modify using myframeset, drop(housing)
frames describe using myframeset, short           // back to 2 frames

// ---- 8. save with linked option ----
// (Requires frlink to exist; illustrative only)
// frames save mylinked, frames(persons) linked   // saves linked frames too

// ---- 9. Cleanup ----
frames reset
erase myframeset.dtas
