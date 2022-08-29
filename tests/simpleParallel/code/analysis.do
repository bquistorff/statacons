// analysis.do
version 16.1

use "outputs/auto-modified.dta", clear

twoway scatter price mpg
graph export "outputs/scatterplot.pdf", replace

