frames use "outputs/legacy_myset.dtas", clear
// Legacy/simple consumer fixture migrated from tests\code\dtas_consumer.do.
// It reopens the legacy frameset and saves a derived .dta from the
// foreign_cars frame.
frame change foreign_cars
keep make price
save "outputs/legacy_foreign_from_dtas.dta", replace
