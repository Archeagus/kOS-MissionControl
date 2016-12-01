{
	local s is stack().
	local d is lex().
	global import is {
		parameter n.
		s:push(n).
		if not exists("1:/"+n) {
			if n:contains("lib_") copypath("0:/lib/"+n,"1:/").
			else copypath("0:/"+n,"1:/").
		}
		if exists("1:/"+n) runpath("1:/"+n). else runpath("0:/lib/"+n).
		return d[n].
	}.
	global export is{
		parameter v.
		set d[s:pop()] to v.
	}.
}