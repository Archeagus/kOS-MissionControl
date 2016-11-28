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
					for k in e:keys if e[k]() e:remove(k).
					wait 0.
				}
			}.
		}
	).
}

// Global Functions
global paused is 0. global releaseAt is 0.
function pause {parameter p. set releaseAt to time:seconds + p. set paused to 1.}

global status is "".
function action {parameter a. set status to a. hudtext(a,5,2,30,green,false).}

function countdown {parameter c, msg is "LAUNCH". until not c {hudtext(c,1,4,72,white,false). set c to c-1. wait 1.} hudtext(msg,1,4,72,green,false).}


