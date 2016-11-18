{
	global gui is lex(
		"countdown", cnt_down@,
		"initialize", prime_display@,
		"update", update_display@
	).
	
	lock h to terminal:height. lock w to terminal:width. lock gw to round(w/2). local vn is ship:name. set ss to ship:status. lock pitch to 90 - vectorangle(up:forevector, facing:forevector).
	
	set fl to list("Velocity:","Bearing:",0,"Altitude:","Radar:",0,"Apoapsis:","Periapsis:",0,"Apo. ETA:","Per. ETA:",0,"SOLN:","Inclination:").
	set ml to list("Orbital:",0,0,"MSA:",0).
	set el to list("Engine Stage:","Rated Thrust:","Fuel Level:",0,"ENERGY Level:","Energy Demand:", "Energy Production:",0,"Communications:","Safeties:").
	set ft to "FLIGHT". set mt to "MISSION". set et to "ENGINEERING". set st to "SCIENCE".
	set fvo to list(0,0,0,0,0,0,0,0,0,0,0,0,0,0). set mvo to list(0,0,0,0,0). set evo to list(0,0,0,0,0,0,0,0,0,0). set sto to list().
	
	// r = row#, c = column#, s = start, e = end
	function hr {parameter r.from {local x is 0.} until x = w step {set x to x+1.} do {print "-" at (x,r).}}
	function vc {parameter c, sr, er. from {local x to sr.} until x = er step {set x to x+1.} do {print "|" at (c,x).}}
	function nl {parameter r, ec is w. from {local x is 0.} until x = ec step {set x to x+1.} do {print " " at (x,r).}}
	function prime_display {parameter f, ver. clearscreen. print ship:type:toupper + " MISSION" at (0,0). print vn:toupper at (round((w-vn:length)/2),0). print ss at (w-ss:length,0). hr(1). vc(gw,2,h-2). hr(h-2). print f at (0,h-1). print ver at (w-ver:length-1,h). gui_mission_init(). gui_flight_init(). gui_science_init(). gui_engineer_init(). }
	function update_display {
		parameter a, b.
		if ship:status <> ss {
			from {local x is w-ss:length.} until x = w step {set x to x+1.} do {print " " at (x,0).}
			set ss to ship:status.
			print ss at (w-ss:length,0).
		}
		gMission(a). gFlight(0). gScience(b). gEngineering(0).
	}
	function get_runmode {
		if exists("1:/mission.runmode") {
			local lm is open("1:/mission.runmode"):readall():string.
			return lm.
		}
		else return " ".
	}
	function gui_mission_init {
		parameter r is 2, c is gw+2.
		print mt at (round(w-gw-mt:length)/2+gw,r).
		from {local x is 0.} until x = ml:length step {set x to x+1.} do {if ml[x] <> 0 print ml[x] at (c,r+1+x).}
	}
	function gui_flight_init {
		parameter r is 2, c is 1.
		print ft at (round(gw-ft:length)/2,r).
		from {local x is 0.} until x = fl:length step {set x to x+1.} do {if fl[x] <> 0 print fl[x] at (c,r+1+x).}
	}
	function gui_engineer_init {
		parameter r is 18, c is 1.
		print et at (round(gw-et:length)/2,r).
		from {local x is 0.} until x = el:length step {set x to x+1.} do {if el[x] <> 0 print el[x] at (c,r+1+x).}
	}
	function gui_science_init {
		parameter r is 13, c is gw+2.
		print st at (round(w-gw-st:length)/2+gw,r).
		//from {local x is 0.} until x = st:length step {set x to x+1.} do {if sl[x] <> 0 print sl[x] at (c,r+1+x).}
	}
	function gMission {
		parameter data, r is 3, c is gw+2.
		set mv to list(body:name, addons:biome:current,0,get_runmode(), data).
		from {local x is 0.} until x = mv:length step {set x to x+1.} do {
			if mv[x] <> 0 {
				if mvo[x] <> mv[x]:tostring:length from {local y is 0.} until y = mvo[x] step {set y to y+1.} do {print " " at (w-2-y,r+x).}
				print mv[x] at (w-1-mv[x]:tostring:length,r+x).
			}
			set mvo[x] to mv[x]:tostring:length.
		}
	}
	function gFlight {
		parameter data, r is 3, c is 1.
		set fv to list(
			round(sqrt(groundspeed^2 + verticalspeed^2)) + "m/s",
			abs(round(ship:bearing,2)) + " deg",
			0,
			cnv_dist(altitude),
			cnv_dist(alt:radar),
			0,
			cnv_dist(apoapsis),
			cnv_dist(periapsis),
			0,
			0,
			cnv_time(eta:periapsis),
			0,
			round(obt:lan) + " deg",
			round(obt:inclination) + " deg"
		).
		if apoapsis > 0 set fv[9] to cnv_time(eta:apoapsis).
		from {local x is 0.} until x = fv:length step {set x to x+1.} do {
			if fv[x] <> 0 {
				if fvo[x] <> fv[x]:tostring:length from {local y is 0.} until y = fvo[x] step {set y to y+1.} do {print " " at (round(w/2)-2-y,r+x).}
				print fv[x] at (round(w/2)-1-fv[x]:tostring:length,r+x).
			}
			set fvo[x] to fv[x]:tostring:length.
		}
	}
	function gScience {
		parameter data, r is 14, c is gw+2.
		print "Explored Biomes ("+data:length+"):" at (c,r).
		from {local x is 0.} until x = data:length step {set x to x+1.} do {
					print data[x] at (c,r+1+x).}
	}
	function gEngineering {
		parameter data, r is 19, c is 1. 
		set ev to list(
			stage:number,
			round(availablethrust),
			0,
			0,
			0,
			0,
			0,
			0,
			"On",
			"Off"
		).
		from {local x is 0.} until x = ev:length step {set x to x+1.} do {if ev[x] <> 0 print ev[x] at (round(w/2)-1-ev[x]:tostring:length,r+x).}
	}
	function cnt_down {
		parameter c, msg is "LAUNCH".
		until not c {hudtext(c,1,4,72,white,false). set c to c-1. wait 1.}
		hudtext(msg,1,4,72,green,false).
	}
	function cnv_dist {
		parameter data.
		set d to "    " + round(data/1000) + "km".
		return d.
	}
	function cnv_time {
		parameter data. set d to " ".
		set data to round(data).
		set d to mod(data,60) + "s".
		if data > 60 set d to floor(mod(data,3600)/60) + "m" + d.
		if data > 3600 set d to floor(mod(data,21600)/3600) + "h" + d.
		if data > 21600 set d to floor(data/21600) + "d" + d.
		set d to "    " + d.
		return d.
	}
}