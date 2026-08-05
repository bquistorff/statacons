frames use "outputs/myset.dtas", clear
frame change foreign_cars
keep make price
save "outputs/foreign_from_dtas.dta", replace
