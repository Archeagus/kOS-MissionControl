{
	clearscreen.
	set stopped to 0. set energy_report to lex().]
	
	until stopped {
		report_energy().
		wait 0.01.
	}

	function report_energy {
		list engines in n.
		energy_report:clear().
		for e in n {
			if e:stage = stage:number {
				if e:resources:length {
					for r in e:resources {
						if not energy_report:haskey(r:name) energy_report:add(r:name,list(r:amount,r:capacity)).
						else {
							set energy_report[r:name][0] to energy_report[r:name][0] + r:amount.
							set energy_report[r:name][1] to energy_report[r:name][1] + r:capacity.
						}
					}
				} else {
					set p to e:parent. set done to 0.
					until done {
						if p:tostring:contains("fuel") {
							for r in p:resources {
								if not energy_report:haskey(r:name) {
									energy_report:add(r:name,list(r:amount,r:capacity)).
								} else {
									set energy_report[r:name][0] to energy_report[r:name][0] + r:amount.
									set energy_report[r:name][1] to energy_report[r:name][1] + r:capacity.
								}
							}
							set p to p:parent.
						}
						else set done to 1.
					}
				}
			}
		}
		set k to energy_report:keys.
		from {local x is 0.} until x = k:length step {set x to x+1.} do {
			print k[x] + ": " + round(energy_report[k[x]][0]) + "/" + energy_report[k[x]][1] at (0,10+x).
		}
	}
}