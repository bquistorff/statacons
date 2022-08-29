// dataprep.do
version 16.1

use "inputs/auto-original.dta", clear

generate mpg_sqd = mpg^2
label variable mpg_sqd "Mileage (mpg) squared"

save "outputs/auto-modified2.dta", replace
sleep 10000
