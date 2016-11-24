{
	local s is stack().
	local d is lex().
	global import is {
		parameter n.
		s:push(n).
		if not exists("1:/"+n) {
			if n:contains("lib_") copypath("0:/lib/"+n,"1:/").
			else if n:contains("mce_") copypath("0:/events/"+n,"1:/").
			else copypath("0:/"+n,"1:/").
		}
		runpath("1:/"+n).
		return d[n].
	}
	global export is{
		parameter v.
		set d[s:pop()] to v.
	}
}