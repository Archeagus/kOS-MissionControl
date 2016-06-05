// Simple function to enable Remote Tech antennas on any vessel.
// Assumes the vessel is launching from or near Kerbin.

	function enable_antennae() {
		for rt in ship:modulesnamed("ModuleRTAntenna") { 
			if rt:hasevent("no target") rt:setfield("target", "Kerbin").
			if rt:hasevent("activate") rt:doevent("activate").
		}
	}
