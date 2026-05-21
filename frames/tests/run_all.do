clear all
do testlib.do

// Batch entry point for the frames/tests smoke suite.
// If this script stops before the final PASS line, the first failing
// child do-file identifies which part of the .dtas test harness broke.
do smoke_dtas_legacy.do
do smoke_dtas_blog.do
do smoke_dtas_errors.do
do smoke_scons_dtas_legacy.do
do smoke_scons_dtas_blog.do

di _newline as result "ALL frames/tests batch checks passed"
