program define store_modts
	syntax anything, local(string)

	filesys `c(pwd)'/`anything', attr
	c_local `local' "`r(modifiednum)'"
end
