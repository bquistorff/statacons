// example-01-basic-frames.do
// Demonstrates: frame create, frame change, frame copy, frame put,
//               frames dir, frame prefix, frame drop, frames reset
//
// Datasets required: none (uses sysuse auto, sysuse census)
// All paths are relative to the assumed working directory: frames/examples/
// Run from frames/examples/ with:
//   do example-01-basic-frames.do              (interactive)
//   StataMP-64.exe -e do example-01-basic-frames.do  (batch)
// ----------------------------------------------------------------

clear all

// ---- 1. Create and switch between frames ----
sysuse auto                              // loads into default frame
frame                                    // print current frame name
frames dir                               // list all frames

frame create second
frames dir                               // now two frames

frame change second
count                                    // 0 obs -- empty frame
cwf default                              // switch back

// ---- 2. Frame prefix: run a command in another frame ----
frame second: sysuse census, clear      // load census into 'second'
frames dir                               // default=auto(74x12), second=census(50x7)

frame second: summarize pop              // summarize without switching

// ---- 3. Copy a frame ----
frame copy second census_copy           // full copy of second -> census_copy
frames dir

// ---- 4. frame put: copy a subset ----
// Start from auto in default frame
frame put make price mpg if foreign==1, into(foreign_cars)
frame foreign_cars: list in 1/5

// ---- 5. Drop frames ----
frame drop second census_copy foreign_cars
frames dir

// ---- 6. Reset ----
clear all
frames dir                               // back to single 'default' frame
