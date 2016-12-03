{
	local lfile is "APEX Mission Control Engineering Library". local ver is "0.1.5".
	local fuelByStage to lex().
	global eng is lex(
		"main_engine_stage", chk_engines@,
		"report_fuel", report_fuel@,
		"get_active_engines", get_active_engines@,
		"get_deltaV", get_deltaV@
	).

	function chk_engines {list engines in n. set l to stage:number. for e in n {if e:stage < l set l to e:stage.} return l.}
	
	function report_fuel {
		parameter sn.
		if fuelByStage:haskey(sn) local report is fuelByStage[sn].
		set k to report:keys.
		from {local x is 0.} until x = k:length step {set x to x+1.} do {
			print k[x] + ": " + round(report[k[x]][0]) + "/" + report[k[x]][1] + "  " at (0,14+x).
		}
	}

	function count_fuel {
		parameter sn, resource_list.
		
		for r in resource_list {
			if fuelByStage[sn]:haskey(r:name) {
				set fuelByStage[sn][r:name][0] to fuelByStage[sn][r:name][0] + r:amount.
				set fuelByStage[sn][r:name][1] to fuelByStage[sn][r:name][1] + r:capacity.
			}
			else fuelByStage[sn]:add(r:name,list(r:amount,r:capacity)).
		}
	}

	function get_active_engines {
		list engines in n.
		for e in n {
			if not fuelByStage:haskey(e:stage) fuelByStage:add(e:stage,lex()). 
			if e:resources:length count_fuel(e:stage,e:resources).
			else {
				set p to e:parent. local done to 0.
				until done {
					if p:tostring:contains("fuel") {
						count_fuel(e:stage,p:resources).
						set p to p:parent.
					}
					else set done to 1.
				}
			}
		}
	}
	
	function get_deltaV {
		parameter fbs. local fm is 0.
		local thr is 0. local mgt is 0.
		local actISP is 0.
		local ftype is lex(
			"LiquidFuel", 0.005,
			"Oxydizer", 0.005,
			"SolidFuel", 0.0075,
			"MonoPropellent", 0.004
		).
		list engines in n.
		for e in n {
			if e:ignition {
				local t is e:maxthrust*e:thrustlimit/100.
				set thr to thr + t.
				if e:visp = 0 set mgt to 1.
				else set mgt to mgt + t / e:visp.
			}
		}
		if mgt = 0 set actISP to 0.
		else set actISP to thr/mgt.	
		for x in ftype:keys if fbs:haskey(x) set fm to fm + fbs[x][0] * ftype[x].
		return ln(ship:mass / (ship:mass-fm)) * 9.81 * actISP.
	}
}

export(eng).

	//get_active_engines().
	//set dV to calculate_deltaV(fuelByStage[stage:number]).
	//set last_dV to dV.
	//until done {
	//	get_active_engines().
	//	if fuelByStage:haskey(stage:number) {
	//		set dV to calculate_deltaV(fuelByStage[stage:number]).
	//		if last_dV > dV set diff to last_dV - dV.
	//		set spentDV to spentDV + diff.
	//		set last_dV to dV.
	//	}
	//	report_fuel().
	//	print "Active DV: " + round(DV) at (0,14).
	//	print "Spent DV:  " + round(spentDV) at (0,15).
	//	wait 0.1.
	//}
