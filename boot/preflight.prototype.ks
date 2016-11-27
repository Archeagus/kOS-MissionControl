// APEX Mission Control Protocol P0 - Basic Mission Preflight Manager
local mfile is "PREFLIGHT MISSION MANAGER". local ver is "ver. APEX-BMPF-0.0.3".
if not exists("1:/lib_io.ks") copypath("0:/lib/lib_io.ks", "1:/").
runpath("1:/lib_io.ks"). import("preflight.ks")().
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

local protocol is import("lib_protocol.ks").
local engineering is import("lib_engineering.ks").

local preflight is protocol({parameter seq, ev, next.

	// Create Event Manager
	seq:add({
		local f is "1:/events.ks".
		local e is queue("mce_staging.ks", "mce_pause.ks").
		for m in ship:modulesnamed("ModuleProceduralFairing") {e:push("mce_fairings"). break.}
		for m in ship:modulesnamed("ModuleDeployableSolarPanel") {e:push("mce_panels.ks"). break.}
		if exists (f) deletepath(f). create(f).
		log "local events is lex(" to f.
		until e:length = 0 log open("0:/events/"+e:pop):readall():string + "," to f.
		log open("0:/events/mce_gui.ks"):readall():string to f.
		log "). export(events)." to f.
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
		next().
	}).
	
	// Calculate DeltaV
	seq:add({
		local fuelByStage to lex(). local done to 0. local last_dV is 0.
		local engISP to 0. local spentDV is 0. local diff is 0.

		function collect_fuel {
			parameter sn, resource_list.
			
			for r in resource_list {
				if fuelByStage[sn]:haskey(r:name) {
					set fuelByStage[sn][r:name] to fuelByStage[sn][r:name] + r:amount.
				}
				else fuelByStage[sn]:add(r:name,r:amount).
			}
		}

		function get_active_engines {
			local thr is 0. local mgt is 0.
			clearscreen. fuelByStage:clear.
			list engines in n.
			for e in n {
				if not fuelByStage:haskey(e:stage) fuelByStage:add(e:stage,lex()). 
				if e:ignition {
					local t is e:maxthrust*e:thrustlimit/100.
					set thr to thr + t.
					if e:visp = 0 set mgt to 1.
					else set mgt to mgt + t / e:visp.
				}
				if e:resources:length collect_fuel(e:stage,e:resources).
				else {
					set p to e:parent. local done to 0.
					until done {
						if p:tostring:contains("fuel") {
							collect_fuel(e:stage,p:resources).
							set p to p:parent.
						}
						else set done to 1.
					}
				}
			}
			if mgt = 0 set engISP to 0.
			else set engISP to thr/mgt.
		}
		
		function calculate_deltaV {
			parameter fbs, sp. local fm is 0.
			local ftype is lex(
				"LiquidFuel", 0.005,
				"Oxydizer", 0.005,
				"SolidFuel", 0.0075,
				"MonoPropellent", 0.004
			).
			for x in ftype:keys if fbs:haskey(x) set fm to fm + fbs[x] * ftype[x].
			return ln(ship:mass / (ship:mass-fm)) * 9.81 * sp.
		}
		
		function check_staging {
			list engines in n.
			for e in n if e:ignition and e:flameout {stage. wait 1. break.}
			if stage:number = 3 and availablethrust = 0 stage.
		}
		
		get_active_engines().
		stage. SAS on. lock throttle to 1.
		set dV to calculate_deltaV(fuelByStage[stage:number],engISP).
		set last_dV to dV.
		until done {
			get_active_engines().
			if fuelByStage:haskey(stage:number) {
				set dV to calculate_deltaV(fuelByStage[stage:number],engISP).
				if last_dV > dV set diff to last_dV - dV.
				set spentDV to spentDV + diff.
				set last_dV to dV.
			}
			check_staging().
			print "Active DV: " + round(DV) at (0,14).
			print "Spent DV:  " + round(spentDV) at (0,15).
			wait 0.1.
		}
	}).
		
	// Collect Energy Levels
	// Create Science Checklist
	// Test Communications
	// Validate Ship Configuration
	// Generate Flight Log
}).

export(preflight).
{
	
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
		
		set logStr to "[" + time:calendar + "] Initializing new log for " + VN.
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