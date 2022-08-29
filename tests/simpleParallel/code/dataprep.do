// dataprep.do
version 16.1
sysuse auto

save "outputs/auto-modified`1'.dta", replace
sleep `=`2'*1000'
