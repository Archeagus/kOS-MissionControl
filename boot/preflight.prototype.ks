// APEX Mission Control Protocol P1 - Advanced Mission Preflight Sequence
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

{
	global preflight is lex(
		"sequence", list(
			"shipIdentification", shipIdentification@,
			"startLog", startLog@,
			"inventoryShip", inventoryShip@,
			"loadMission", loadMission@,
			"loadBoot", loadBoot@,
			"handOff", handOff@
		),
		"events", lex()
	).

	function shipIdentification {
		parameter preflight.
		// Identify the name of the vessel.
		hudtext(ship:name + " located on launch pad.", 10, 2, 15, white, true).
		set VN to "".
		from {local i is 0.} until i = ship:name:length step {set i to i + 1.} do {
			if(ship:name[i] = " ") {
				set VN to VN + "_".
			} else {
				set VN to VN + ship:name[i].
			}
			wait 0.001.
		}
		
		preflight["next"]().
	}
	
	function startLog {
		parameter preflight.
		
		set logStr to "[" + time:calendar + "] Initializing new log sequence for " + VN.
		log logStr to "0:/logs/" + VN + ".log".
		
		preflight["next"]().
	}
	
	function inventoryShip {
		parameter preflight.
		
		// Parts Lists
		list processors in cpus.
		list parts in sParts.
		list engines in sEng.
		list sensors in sSens.
		list elements in sEl.

		// if exists("0:/shipCPUs.txt") deletepath("0:/shipCPUs.txt").
		if exists("0:/shipEngines.txt") deletepath("0:/shipEngines.txt").
		if exists("0:/shipSensors.txt") deletepath("0:/shipSensors.txt").
		if exists("0:/shipElem.txt") deletepath("0:/shipElem.txt").
		log cpus to "0:/shipCPUs.txt".
		log sEng to "0:/shipEngines.txt".
		log sSens to "0:/shipSensors.txt".
		log sEl to "0:/shipElem.txt".
		
		if exists("0:/shipManifest.txt") deletepath("0:/shipManifest.txt").
		for sp in sParts {
			log "=================================================" to "0:/shipManifest.txt".
			log sp to "0:/shipManifest.txt".
			if sp:modules:length {log "Modules" to "0:/shipManifest.txt".	log sp:modules to "0:/shipManifest.txt".}
			if sp:children:length {log "Children" to "0:/shipManifest.txt".	log sp:children to "0:/shipManifest.txt".}
		}
		
		preflight["next"]().
	}
	
	function loadMission {
		parameter preflight.
		
		set m to VN + ".mission.ks".
		
		if exists("lib_preflight_check.ks") deletepath("lib_preflight_check.ks").

		if archive:exists(m) {
			copypath("0:/"+m,"1:/mission.ks").
			hudtext("Retrieved " + ship:name + " mission profile.",10,2,15,white,true).
		} else if core:getfield("kos disk space") = 10000 {
			hudtext("Retrieved basic mission profile.",10,2,15,white,true).
			copypath("0:/basic.mission.ks","1:/mission.ks").
		} else {
			hudtext("Retrieved default mission profile.",10,2,15,white,true).
			copypath("0:/master.mission.ks","1:/mission.ks").
		}
		
		preflight["next"]().
	}
	
	function loadBoot {
		parameter preflight.
		
		// TODO: Change preflight.prototype.ks to boot.ks

		set b to VN + ".boot.ks".
		if exists("1:/boot/preflight.prototype.ks") deletepath("1:/boot/preflight.prototype.ks").

		if exists("0:/mission/" + b) {
			copypath("0:/mission/" + b,"1:/boot/preflight.prototype.ks").
			hudtext("Retrieved " + ship:name + " preflight protocols.",10,2,15,white,true).
		} else {
			hudtext(VN + " launch protocol not found.", 5, 2, 15, white, true).		
			hudtext("Retrieved default preflight protocols.",5,2,15,white,true).
			copypath("0:/boot/master.boot.ks","1:/boot/boot.ks").
		}
		
		preflight["next"]().
	}
	
	function handOff {
		parameter preflight.

		//reboot.
	}
	for f in list("lib_preflight_check.ks") if not exists(f) runpath("0:/lib/"+f).

	run_preflight(preflight["sequence"], preflight["events"]).
}