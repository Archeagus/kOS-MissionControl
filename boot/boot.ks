// fastboot
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
// set ship:control:pilotmainthrottle to 0.

// Identify the name of the vessel.
set tmp to ship:name. 
hudtext(tmp + " located on launch pad.", 10, 2, 18, white, true).
set VN to "". from {local i is 0.} until i = tmp:length step {set i to i + 1.} do {if(tmp[i] = " ") {set VN to VN + "_".} else {set VN to VN + tmp[i].}	wait 0.001.
} //log "Pre-Flight Initialization" to VN + ".log.np2".
	
// Check for ship-specific boot or mission profiles.
	set b to VN + ".boot.ks".
	if not VN:contains("test") set m to VN + ".mission.ks". else set m to "test.mission.ks".

	if exists("1:/boot/boot.ks") deletepath("1:/boot/boot.ks").

	if exists("0:/boot/"+b) {
		copypath("0:/boot/"+b,"1:/boot/boot.ks").
		hudtext("Retrieved " + ship:name + " preflight protocols.",10,2,18,white,true).
	} else {
		hudtext(VN + " launch protocol not found.",5,2,18, white, true).		
		hudtext("Retrieved default preflight protocols.",5,2,18,white,true).
		copypath("0:/boot/master.boot.ks","1:/boot/boot.ks").
	}

	if exists("0:/" + m) {
		copypath("0:/"+m,"mission.ks").
		hudtext("Retrieved " + ship:name + " mission profile.",10,2,18,white,true).
	} else if core:getfield("kos disk space") <= 10000 {
		hudtext("Retrieved basic profile.",10,2,18,white,true).
		copypath("0:/basic.mission.ks","1:/mission.ks").
	} else {
		hudtext("Retrieved default profile.",10,2,18,white,true).
		copypath("0:/master.mission.ks","1:/mission.ks").
	}

reboot.
