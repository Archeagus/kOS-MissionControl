// APEX Mission Control Protocol P1 - Basic Mission Preflight Manager
local mfile is "PREFLIGHT MISSION MANAGER". local ver is "ver. APEX-BMPF-0.0.8".
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

local protocol is import("lib_protocol.ks").
local preflight is protocol({parameter seq, ev, next.
	local logging is 0.

	// ID The Ship
	seq:add({
		set tmp to ship:name. 
		hudtext(tmp + " located on launch pad.", 10, 2, 18, white, true).
		set VN to "". from {local i is 0.} until i = tmp:length step {set i to i + 1.} do {if(tmp[i] = " ") {set VN to VN + "_".} else {set VN to VN + tmp[i].}	wait 0.001.
		}
		next().
	}).
	
	// Create Event Manager
	seq:add({
		print "Generating event management system.".
		local f is "1:/events.ks".
		local e is queue("mce_staging.ks").
		print "Auto-stage support enabled.".
		for m in ship:modulesnamed("ModuleProceduralFairing") {
			print "Fairing deployment enabled.". e:push("mce_fairings"). break.}
		for m in ship:modulesnamed("ModuleDeployableSolarPanel") {
			print "Power pruduction support enabled.". e:push("mce_panels.ks"). break.}
		if exists (f) deletepath(f). create(f).
		log "local events is lex(" to f.
		until e:length = 0 log open("0:/events/"+e:pop):readall():string + "," to f.
		log open("0:/events/mce_pause.ks"):readall():string to f.
		log "). export(events)." to f.
		print "SWS support enabled.".
		next().
	}).
	
	// Configure Chutes
	seq:add({
		for ch in ship:modulesnamed("ModuleParachute") {
			if ch:hasfield("min pressure") {
				if ch:part:tostring:contains("Drogue") ch:setfield("min pressure", 0.6).
				else ch:setfield("min pressure", 0.7).
			}
		}
		print "Chute(s) primed.".
		next().
	}).
			
	// Validate Ship Configuration
	if logging {
		seq:add({
			// Parts Lists
			list processors in cpus.
			list parts in sParts.
			list engines in sEng.
			list sensors in sSens.
			list elements in sEl.
			
			local lf is "0:/logs/"+VN+".".
			if exists(lf+"shipCPUs.txt") deletepath(lf+"shipCPUs.txt").
			if exists(lf+"shipEngines.txt") deletepath(lf+"shipEngines.txt").
			if exists(lf+"shipSensors.txt") deletepath(lf+"shipSensors.txt").
			if exists(lf+"shipElem.txt") deletepath(lf+"shipElem.txt").
			log cpus to lf+"shipCPUs.txt". print "Logging CPU configuration.".
			log sEng to lf+"shipEngines.txt". print "Logging ship engines.".
			log sSens to lf+"shipSensors.txt". print "Logging sensor configuration.".
			log sEl to lf+"shipElem.txt". print "Logging element data.".
			
			set l to lf+"shipManifest.txt".
			if exists(l) deletepath(l).
			for sp in sParts {
				print "Logging " + sp:name + " to ship manifest.".
				log "=================================================" to l.
				log sp to l.
				if sp:modules:length {log "Modules" to l. wait 0.5. log sp:modules to l.}
				if sp:children:length {log "Children" to l.	wait 0.5. log sp:children to l.}
			}
			next().
		}).
	}

	// Check for ship-specific boot or mission profiles. Assign test profile if "Test" found in name.
	seq:add({
		set b to VN + ".boot.ks".
		if not VN:contains("test") set m to VN + ".mission.ks". else set m to "test.mission.ks".

		if exists("1:/boot/boot.ks") deletepath("1:/boot/boot.ks").
		if exists("1:/preflight.ks") deletepath("1:/preflight.ks").

		if exists("0:/boot/"+b) {
			copypath("0:/boot/"+b,"1:/boot/boot.ks").
			hudtext("Retrieving " + ship:name + " exclusive preflight & launch protocols.",10,2,18,white,true).
		} else {
			hudtext("Retrieving default preflight protocols.",5,2,18,white,true).
			copypath("0:/boot/master.boot.ks","1:/boot/boot.ks").
		}

		if exists("0:/mission/" + m) {
			copypath("0:/mission/"+m,"mission.ks").
			// Retrieves mission file designed explicitly for vessels with this ship name.
			hudtext("Retrieving " + ship:name + " mission profile.",10,2,18,white,true).
		} else if core:getfield("kos disk space") <= 10000 {
			// Retrieve basic, low-energy, low technology mission profiles. (NO advanced action groups, no maneuver nodes.)
			hudtext("Retrieving basic test mission profile.",10,2,18,white,true).
			copypath("0:/mission/basic.mission.ks","1:/mission.ks").
		} else {
			// Retrieve advanced defail mission, with support for advanced actions and maneuvers.
			hudtext("Retrieving default mission profile.",10,2,18,white,true).
			copypath("0:/mission/master.mission.ks","1:/mission.ks").
		}
		if exists("1:/runmode.ks") deletepath("1:/runmode.ks").
		reboot.
	}).

}).

export(preflight).