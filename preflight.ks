{
	// APEX Mission Control Protocol P1 - Basic Mission Preflight Manager
	local mfile is "PREFLIGHT MISSION MANAGER". local ver is "ver. APEX-BMPF-0.1.1".

	local protocol is import("lib_protocol.ks").
	function select {parameter p, c is green. set h to highlight(p, c).}
	function dsel {parameter p. set h to highlight(p, white). set h:enabled to false.}
	local preflight is protocol({parameter seq, ev, next.
		local logging is 0.

		// ID The Ship
		seq:add({
			set tmp to ship:name. 
			hudtext(tmp + " located on launch pad.", 10, 3, 20, white, true).
			set VN to "". from {local i is 0.} until i = tmp:length step {set i to i + 1.} do {if(tmp[i] = " ") {set VN to VN + "_".} else {set VN to VN + tmp[i].}	wait 0.
			}
			next().
		}).
		
		// Create ship log.
		seq:add({
			global sl is "0:/logs/"+ VN + ".log".
			if exists(sl) deletepath(sl).
			output(tmp + " ship log created.",sl,true).
			next().
		}).
		
		// Create Event Manager
		seq:add({
			output("Generating event management system.",sl,true). wait 1.
			local f is "1:/events.ks".
			local e is queue("mce_staging.ks").
			output("Auto-stage support enabled.",sl,true). wait 1.
			if core:getfield("kos disk space") > 10000 { 
				e:push("mce_gui.ks"). 
				output("Mission Control terminal support enabled.",sl,true). wait 1.
			}
			for m in ship:modulesnamed("ModuleProceduralFairing") {
				select(m:part). wait 1. output("Fairing deployment enabled.",sl,true).
				e:push("mce_fairings"). dsel(m:part). break.
			}
			for m in ship:modulesnamed("ModuleDeployableSolarPanel") {
				select(m:part). wait 1. output("Power pruduction enabled.",sl,true).
				e:push("mce_panels.ks"). dsel(m:part). break.
			}
			for m in ship:modulesnamed("ModuleDeployableAntenna") {
				select(m:part). wait 1. output("Communications enabled.",sl,true).
				e:push("mce_comms.ks"). dsel(m:part). break.
			}
			if exists (f) deletepath(f). create(f).
			log "local events is lex(" to f.
			until e:length = 0 log open("0:/events/"+e:pop):readall():string + "," to f.
			log open("0:/events/mce_pause.ks"):readall():string to f.
			log "). export(events)." to f.
			output("AWS support enabled.",sl,true).
			next().
		}).
		
		// Configure Chutes
		seq:add({
			local nchutes is 0.
			for ch in ship:modulesnamed("ModuleParachute") {
				if ch:hasfield("min pressure") {
					set nchutes to nchutes + 1.
					select(ch:part).
					if ch:part:tostring:contains("Drogue") ch:setfield("min pressure", 0.6).
					else ch:setfield("min pressure", 0.7).
					wait 1. dsel(ch:part).
				}
			}
			output(nchutes + " chute(s) primed.",sl,true).
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
				local fl is list("CPUs", "Engines", "Sensors", "Elem", "Manifest").
				
				local lf is "0:/logs/"+VN+".".
				for ct in fl {
					set l to lf+ct+".txt".
					if exists(l) deletepath(l).
				}
				log cpus to lf+fl[0]+".txt". print "Logging CPU configuration.".
				log sEng to lf+fl[1]+".txt". print "Logging ship engines.".
				log sSens to lf+fl[2]+".txt". print "Logging sensor configuration.".
				log sEl to lf+fl[3]+".txt". print "Logging element data.".
				
				set l to lf+fl[4]+".txt".
				for sp in sParts {
					select(sp). wait 0.5.
					print "Logging " + sp:name + " to ship manifest.".
					log "=================================================" to l.
					log sp to l.
					if sp:modules:length {log "Modules" to l. wait 0.75. log sp:modules to l.}
					if sp:children:length {log "Children" to l.	wait 0.75. log sp:children to l.}
					dsel(sp).
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
				hudtext("Retrieving " + ship:name + " exclusive preflight & launch protocols.",10,3,20,white,true).
			} else {
				hudtext("Retrieving default preflight protocols.",5,3,20,white,true).
				copypath("0:/boot/master.boot.ks","1:/boot/boot.ks").
			}

			if exists("0:/mission/" + m) {
				copypath("0:/mission/"+m,"1:/mission.ks").
				// Retrieves mission file designed explicitly for vessels with this ship name.
				hudtext("Retrieving " + ship:name + " mission profile.",10,3,20,white,true).
			} else if core:getfield("kos disk space") <= 10000 {
				// Retrieve basic, low-energy, low technology mission profiles. (NO advanced action groups, no maneuver nodes.)
				hudtext("Retrieving basic test mission profile.",10,3,20,white,true).
				copypath("0:/mission/basic.mission.ks","1:/mission.ks").
			} else {
				// Retrieve advanced defail mission, with support for advanced actions and maneuvers.
				hudtext("Retrieving default mission profile.",10,3,20,white,true).
				copypath("0:/mission/master.mission.ks","1:/mission.ks").
			}
			if exists("1:/runmode.ks") deletepath("1:/runmode.ks").
			reboot.
		}).

	}).

	export(preflight).
}
