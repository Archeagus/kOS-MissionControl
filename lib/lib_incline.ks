{
	// LIB_LAZcalc.ks Version 2.1
	// Created by space-is-hard, Updated by TDW89, Refactored for KOS Mission Control
	
	local INFINITY is 2^64.

	local incline is lex(
		"init", init@,
		"exec", exec@
	).


	//to use: IMPORT(lib_incline.ks). local LAZDATA is incline["init"]([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then ev:add("mce_incline",{set AZImuTH to incline["exec"](LAZDATA)}).

	function init {
		parameter
			desiredAlt,
			desiredInc.
		
		local launchlatitude is ship:latitude.
		
		local data is list().
		
		if desiredAlt <= 0 {
			print "Target altitude cannot be below sea level".
			set launchAzimuth to 1/0.
		}.
		
		local launchNode to "Ascending".
		if desiredInc < 0 {
			set launchNode to "Descending".
			set desiredInc to abs(desiredInc).
		}.
		
		if abs(launchlatitude) > desiredInc {
			set desiredInc to abs(launchlatitude).
			hudtext("Inclination impossible from current latitude, setting for lowest possible inclination.", 10, 2, 30, red, false).
		}.
		
		if 180 - abs(launchlatitude) < desiredInc {
			set desiredInc to 180 - abs(launchlatitude).
			hudtext("Inclination impossible from current latitude, setting for highest possible inclination.", 10, 2, 30, red, false).
		}.
		
		local equatorialVel is (2 * constant():Pi * body:radius) / body:rotationperiod.
		local targetorbVel is sqrt(body:mu/ (body:radius + desiredAlt)).
		data:add(desiredInc).
		data:add(launchlatitude).
		data:add(equatorialVel).
		data:add(targetorbVel).
		data:add(launchNode).
		return data.
	}.

	function exec {
		parameter
			data.
		local inertialAzimuth is arcsin(max(min(cos(data[0]) / cos(ship:latitude), 1), -1)).
		local VXRot is data[3] * sin(inertialAzimuth) - data[2] * cos(data[1]).
		local VYRot is data[3] * cos(inertialAzimuth).
		
		local Azimuth is mod(arctan2(VXRot, VYRot) + 360, 360).
		
		if data[4] = "Ascending" {
			return Azimuth.
			
		} else if data[4] = "Descending" {
			if Azimuth <= 90 {
				return 180 - Azimuth.
			} else if Azimuth >= 270 {
				return 540 - Azimuth.   
			}
		}
	}
	
	export(incline).
}
