clear all
do testlib.do

do smoke_dtas_blog.do
do smoke_dtas_errors.do
do smoke_scons_dtas_blog.do

di _newline as result "ALL frames/tests batch checks passed"

