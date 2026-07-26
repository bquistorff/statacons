program define write_txt
	syntax anything, fname(string)

	file open hand using "`fname'", write text replace
	file write hand "`anything'"
	file close hand
end
