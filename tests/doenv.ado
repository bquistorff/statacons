capture program drop doenv
program define doenv, rclass
    syntax using/, [prefix(string)]
    capture file close _env
    file open _env using `using', read
    file read _env line
	while r(eof) == 0 {
        * Case: export EXAMPLE_API_TOKEN="MmFNvtrLeX1NM9F9qRIX"
        if regexm(`"`line'"', "^export") == 1 {
            tokenize `line'
            tokenize `2', parse("=")
            local key_name = "`1'"
            macro shift
            local key_value = "`2'"
            local `key_name' = "`key_value'"
            return local `key_name' "`key_value'"
        }
        * Case: A comment in .env
        else if regexm(`"`line'"', "^\#") == 1 {
            break
        }
        * Case: EXAMPLE_API_TOKEN="MmFNvtrLeX1NM9F9qRIX"
        else {
            tokenize `line', parse("=")
            local key_name = "`1'"
            macro shift
            local key_value = "`2'"
            local `key_name' = "`key_value'"
            return local `key_name' "`key_value'"
        }
        file read _env line
	}
    file close _env
end
