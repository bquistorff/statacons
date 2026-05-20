program define touch_dta
	syntax anything

	preserve
	use `anything', clear
	save `anything', replace
end
