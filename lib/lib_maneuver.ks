{
	global maneuver is lex("exec", mnv_exec@).

	function mnv_exec {
		parameter autowarp is false.
		if not hasnode return.
		local n is nextnode.
		local v is n:burnvector.
		local starttime is time:seconds + n:eta - mnv_time(v:mag)/2.
		lock steering to n:burnvector.
		if autowarp {
			warpto(starttime - 30).
		}
		wait until time:seconds >= starttime.
		rcs on.
		
		lock throttle to min(mnv_time(n:burnvector:mag), 1).
		until vdot(n:burnvector, v) < 0 {
			if availablethrust < 0.1 and stage:number > 0 {
				stage. wait 0.1.
			} else {
				list engines in eng.
				for e in eng {
					if (e:stage = stage:number and e:ignition and e:flameout) {
						stage. wait 1.
						if (availablethrust = 0 and stage:number > 0) stage. break.
					}
				}
			}
		}
		set throttle to 0.
		rcs off.
		unlock steering.
		remove nextnode.
		wait 0.01.
	}
	
	function mnv_time {
		parameter dV.
		local g is ship:orbit:body:mu/ship:obt:body:radius^2.
		local m is ship:mass * 1000.
		local e is constant():e.
		local engine_count is 0.
		local thrust is 0.
		local isp is 0.
		list engines in all_engines.
		for en in all_engines if en:ignition and not en:flameout {
			set thrust to thrust + en:availablethrust.
			set isp to isp + en:isp.
			set engine_count to engine_count+1.
		}
		if not isp = 0 set isp to isp / MAX(engine_count, 1).
		else return 0.1.
		if not thrust = 0 set thrust to thrust * 1000.
		else return 0.1.
		return g * m * isp * (1 - e^(-dV/(g*isp))) / thrust.
	}
}