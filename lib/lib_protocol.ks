{
	local rm is "1:/runmode.ks".
	export (
		{
			parameter d.
			local r is 0.
			if exists(rm) set r to import("runmode.ks").
			local s is list().
			local e is lex().
			local n is{
				parameter m is r+1.
				if not exists(rm) create(rm).
				local h is open(rm).
				h:clear().
				h:write("export("+m+").").
				set r to m.
			}.
			d(s,e,n).
			return {
				until r>=s:length	{
					s[r]().
					for v in e:values v().
					wait 0.
				}
			}.
		}
	).
}

function pause {parameter p. set ReleaseAt to time+seconds + p. set paused to 1.}
