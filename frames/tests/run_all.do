// run_all.do
// Batch entry point for the frames/tests smoke suite.
// All paths are relative to the assumed working directory: frames/tests/
// Run from frames/tests/ with:
//   do run_all.do                              (interactive)
//   StataMP-64.exe -e do run_all.do            (batch)
//
// If this script stops before the final PASS line, the first failing
// child do-file identifies which part of the .dtas test harness broke.

clear all
do testlib.do

do smoke_dtas_legacy.do
do smoke_dtas_blog.do
do smoke_dtas_errors.do
do smoke_scons_dtas_legacy.do
do smoke_scons_dtas_blog.do

do smoke_dtas_frame_order.do
do smoke_dtas_volatile_chars.do
do smoke_dtas_fralias.do
do smoke_dtas_degenerate.do
do smoke_stata17_fallback.do

di _newline as result "ALL frames/tests batch checks passed"
