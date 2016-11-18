{
	set f to "APEX Mission Control Engineering Library". set version to "0.1.0".

	global engineering is lex("Final Engine", chk_engines@).

//	set twr to F/(m*g). // Must be greater than 1.

//	set dMag to ln(ship:wetmass/ship:drymass) * g.
//	list engines in n.
//	for e in n {
		
//	}
//	set ISPatm to (sum of force/thrust per engine in the stage)/(Sum of each (engines f/t divided by its isp)). // Per Stage.
//	set ISPvac to (sum of force/thrust per engine in the stage)/(Sum of each (engines f/t divided by its isp)). // Per Stage.
//	set dVatm to dMag * isp(atm). // Per Stage.
//	set dVvac to dMag * isp(vac). // Per Stage.

//	set trueDV to ((dVatm - 1000) / dVatm) * dVvac + 1000.
//	set maxDV to 21.576745349086 * ttlISP.

	function chk_engines {list engines in n. set l to stage:number. for e in n {if e:stage < l set l to e:stage.} return l.}
}

///set eng_lbl to list("Engine Stage:","Available Thrust","Fuel Level:"," ","Energy Level:","Energy Demand:", "Energy Production:"," ","Comms:","Safeties").

set fuelByStage to lex().
set fuel_report to lex().

function collect_fuel {
	parameter sn, resource_list.
	
	for r in resource_list {
		if fuelByStage[sn]:haskey(r:name) {
			set fuelByStage[sn][r:name] to fuelByStage[sn][r:name] + r:amount.
		}
		else fuelByStage[sn]:add(r:name,r:amount).
	}

}

function incomplete {
	list engines in n.
	for e in n {
		if not fuelByStage:haskey(e:stage) fuelByStage:add(e:stage,lex()). 
		print e:stage + " - " + e:title.
		if e:resources:length collect_fuel(e:stage,e:resources).
		else {
			set p to e:parent. set done to 0.
			until done {
				if p:tostring:contains("fuel") {
					collect_fuel(e:stage,p:resources).
					set p to p:parent.
				}
				else set done to 1.
			}
		}
	}
	print fuelByStage. wait 5.
	clearscreen. stage.
	set stopped to 0. set fuel_report to lex().

	until stopped {
		report_fuel().
		wait 0.01.
	}

	function report_fuel {
		list engines in n.
		fuel_report:clear().
		for e in n {
			if e:stage = stage:number {
				if e:resources:length {
					for r in e:resources {
						if not fuel_report:haskey(r:name) fuel_report:add(r:name,list(r:amount,r:capacity)).
						else {
							set fuel_report[r:name][0] to fuel_report[r:name][0] + r:amount.
							set fuel_report[r:name][1] to fuel_report[r:name][1] + r:capacity.
						}
					}
				} else {
					set p to e:parent. set done to 0.
					until done {
						if p:tostring:contains("fuel") {
							for r in p:resources {
								if not fuel_report:haskey(r:name) {
									fuel_report:add(r:name,list(r:amount,r:capacity)).
								} else {
									set fuel_report[r:name][0] to fuel_report[r:name][0] + r:amount.
									set fuel_report[r:name][1] to fuel_report[r:name][1] + r:capacity.
								}
							}
							set p to p:parent.
						}
						else set done to 1.
					}
				}
			}
		}
		set k to fuel_report:keys.
		from {local x is 0.} until x = k:length step {set x to x+1.} do {
			print k[x] + ": " + round(fuel_report[k[x]][0]) + "/" + fuel_report[k[x]][1] at (0,10+x).
		}
	}
}