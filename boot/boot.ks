// Fastboot - Modified version of u/Gaiiden and u/kvcummins boot systems on r/Kos.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").

// Identify the name of the vessel.
set tmp to ship:name. 
hudtext(tmp + " located on launch pad.", 10, 2, 18, white, true).
set VN to "". from {local i is 0.} until i = tmp:length step {set i to i + 1.} do {if(tmp[i] = " ") {set VN to VN + "_".} else {set VN to VN + tmp[i].}	wait 0.001.
}
	
// Check for ship-specific boot or mission profiles.
	set b to VN + ".boot.ks".
	if not VN:contains("test") set m to VN + ".mission.ks". else set m to "test.mission.ks".

	if exists("1:/boot/boot.ks") deletepath("1:/boot/boot.ks").

	if exists("0:/boot/"+b) {
		copypath("0:/boot/"+b,"1:/boot/boot.ks").
		hudtext("Retrieving " + ship:name + " exclusive preflight & launch protocols.",10,2,18,white,true).
	} else {
		hudtext("Retrieving default preflight protocols.",5,2,18,white,true).
		copypath("0:/boot/master.boot.ks","1:/boot/boot.ks").
	}

	if exists("0:/" + m) {
		copypath("0:/"+m,"mission.ks").
		// Retrieves mission file designed explicitly for vessels with this ship name.
		hudtext("Retrieving " + ship:name + " mission profile.",10,2,18,white,true).
	} else if core:getfield("kos disk space") <= 10000 {
		// Retrieve basic, low-energy, low technology mission profiles. (NO advanced action groups, no maneuver nodes.)
		hudtext("Retrieving basic test mission profile.",10,2,18,white,true).
		copypath("0:/basic.mission.ks","1:/mission.ks").
	} else {
		// Retrieve advanced defail mission, with support for advanced actions and maneuvers.
		hudtext("Retrieving default mission profile.",10,2,18,white,true).
		copypath("0:/master.mission.ks","1:/mission.ks").
	}

reboot.
