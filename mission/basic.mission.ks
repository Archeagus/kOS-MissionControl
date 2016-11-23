// APEX Mission Control Protocol B1
//Basic Mission Procedures Template
{
	local tAlt is 100000. local mDir is 0. local done is 0. local a is "empty".  set bit_atmo to 0.
	local paused is 0. local atmo is max(body:atm:height, 10000). local releaseAt is 0.
	local b is lex(body:name,list()). lock bl to b[body:name]:length. set bit_alt to 0.

	
	global mission is lex(
		"sequence", list(
		"Preflight", preflight@,
		"Launch", launch@,
		"Ascent", ascent@,
		"Circularize", circularize@,
		"Enable Systems", enable_systems@,
		"Adrift",idle@,
		"Planetfall", drop@
	),
    "events", lex(
		"doPause", {parameter mission. if paused and time:seconds > releaseAt set paused to 0.},
		// First pass. Create/update the terminal output and (TODO) log file.
		"updateOutput", {
			parameter mission.
			clearscreen. // Find a better way to reduce flicker.
			print "Location:       " + body:name + " " + addons:biome:current at (0,1).
			print "Terrain:        " + round(ship:geoposition:terrainheight, 2) at (0,2).
			if exists("1:/mission.runmode") {
				local lm is open("1:/mission.runmode"):readall():string.
				print "Mission Stage:  " + lm at (0,4).
			}
			if not (a = "empty") print "Mission Status: " + a at (0,5).
			print "Apoapsis:       " + round(ship:apoapsis) at (0,7).
			print "Periapsis:      " + round(ship:periapsis) at (0,8).
			print "Thrust:         " + round(ship:availablethrust) at (0,9).
			print "Inclination:    " + round(ship:orbit:inclination,2) at (0,11).
			if bl {print "Explored Biomes ("+bl+"):" at (0,13). from {local x is 0.} until x = bl step {set x to x+1.} do {print b[body:name][x] at (0,14+x).}}
			},
		// Test for engine burnout.
		"checkStaging", {
			parameter mission.
			if throttle > 0 {
				if availablethrust = 0 and a = "Deploying Safeties" {
					stage.
					lock throttle to 0.
				}
				else if stage:number = 0 and availablethrust = 0 and not (a = "Deploying Safeties") {
					hudtext("WARNING: Engines Thrust Unavailable",10,4,25,red,false).
				}
				else if stage:number > 0 {
					list engines in eng.
					set sn to stage:number.
					for e in eng {
						if (e:stage =sn and e:ignition and e:flameout and sn > 0) {
							hudtext("STAGING",5,2,30,white,false). stage. wait 1.
							if (ship:availablethrust = 0 and stage:number > 0) stage.
							break.
			}	}	}	}	},
		// Should probably move this to a preflight add_event.
		"deployFairings", {
			parameter mission.
			if (ship:altitude > 0.55 * atmo) {
				for m in ship:modulesnamed("ModuleProceduralFairing") { 
					if m:hasevent("deploy") {
						m:doevent("deploy").
						wait 1.
					}
				}
				mission["remove_event"]("deployFairings").
			}	},
		// Should probably move this to a preflight add_event.
		"energyPanels", {parameter mission.
			if (ship:altitude > atmo) {
				panels on.
				mission["remove_event"]("energyPanels").
	}	}	)	).
	on abort {set done to 1. return true.}
	on gear {lock steering to lookdirup(v(0,1,0), sun:position). return true.}
	function preflight {
		parameter mission.
		for ch in ship:modulesnamed("ModuleParachute") {
			if ch:hasfield("min pressure") ch:setfield("min pressure",0.6).}
		set ship:control:pilotmainthrottle to 0.
		lock throttle to 1.
		lock steering to heading(mDir, 90).
		gui["countdown"](5).
		mission["next"]().
	}
	function launch {
		parameter mission.
		stage.
		lock pct_alt to alt:radar / tAlt.
		set target_twr to 8.26.
		lock target_pitch to -115.23935 * pct_alt^0.4095114 + 88.963.
		lock throttle to 1.
		lock steering to heading(mDir, target_pitch).
		mission["next"]().
	}
	function ascent {
		parameter mission.
		if not bit_alt and apoapsis > tAlt {
			updateAct("Ascent Burn Complete").
			lock throttle to 0. lock steering to prograde.
			set bit_alt to 1.
		}
		if altitude > atmo and not bit_atmo {
			updateAct("Leaving Atmosphere").
			set bit_atmo to 1.
		}
		if bit_alt and bit_atmo {
			mission["next"]().
		}
		wait 0.5.
	}
	function circularize {
		parameter mission.

		if not paused {
			// Basic Implementation
			if (a = "Leaving Atmosphere" or a = "Ascent Burn Complete") {
				if ship:periapsis < atmo and eta:apoapsis < eta:periapsis {
					if eta:apoapsis < 30 {
						lock steering to prograde.
						if eta:apoapsis < 5 {
							updateAct("Periapsis Burn").
							lock throttle to 1.
						}
						wait 0.01.
					}
				}
				else if ship:periapsis < atmo and eta:apoapsis > eta:periapsis {
					hudtext("SHIP OUT OF POSITION",8,2,30,red,false).
					mission["switch_to"]("Planetfall").
				}
				wait 0.5.
			}
			else if a = "Periapsis Burn" {
				if ship:periapsis > atmo {
					updateAct("Burn Complete").
					lock throttle to 0.
				}
			}
			else if ship:periapsis > atmo or a = "Burn Complete" mission["next"]().
			else updateAct("Apoapsis Reached").
		}
		wait 0.5.
	}
	function enable_systems {
		parameter mission.
		lock steering to lookdirup(v(0,1,0), sun:position).
		if exists("0:/science/evabiomes.json") set b to retrieve_biomes().
		set last_b to "none".
		pause(5).
		mission["next"]().
	}
	function idle {
		parameter mission.
		if not paused {
			if hasnode {
				maneuver["exec"](true).
				lock steering to lookdirup(v(0,1,0), sun:position).
				pause(30).
			}
			if not (last_b = addons:biome:current) {
				for sm in ship:modulesnamed("DMModuleScienceAnimate") {
					if sm:hasevent("log visual observations") sm:doevent("log visual observations").
				}
				set last_b to addons:biome:current.
			}
			if not b[body:name]:contains(addons:biome:current) and ship:crew:length = 1 {
				addons:eva:goeva(ship:crew[0]).
				b[body:name]:add(addons:biome:current).
				update_biomes(b).
				pause(3).
			}
			if done {
				lock steering to retrograde. pause(10).
				mission["next"]().
			}
		}
		wait 0.5.
	}
	function drop {
		parameter mission.
		
		if not paused {
			if not (a = "Controls Released") {
				if a = "Final Approach" {
					if ship:periapsis > atmo * 0.4 {
						lock throttle to 0.05.
					}
					else if ship:periapsis < atmo {
						lock throttle to 0.
						if atmo > 0 updateAct("Waiting for Atmospheric Re-entry").
						else updateAct("Waiting for Approach").
					}
					else if availablethrust = 0 {
						if ship:periapsis > atmo {
							lock throttle to 0.
							hudtext("WARNING: Ship Adrift.",5,4,30,red,false).
							mission["switch_to"]("Adrift").
						}
						else {
							lock throttle to 0.
							updateAct("Waiting").
						}
					}
				}
				if a:contains("Waiting") {
					if ship:altitude < atmo * 0.8 {
						updateAct("Decelerating").
					}
				}
				if a = "Decelerating" {
					if availablethrust > 0 {lock throttle to 1.	rcs on.}
					else {set cc to 0. updateAct("Deploying Safeties").}
				}
				if a = "Deploying Safeties" {
					if alt:radar < 10000 and ship:verticalspeed < -1 {
						set h to ship:modulesnamed("ModuleParachute").
						for ch in h {
							if ch:hasevent("deploy chute") and ch:getfield("Safe To Deploy?") = "Safe" {
								ch:doevent("deploy chute").
								set cc to cc + 1.
							}
							if cc = h:length {
								updateAct("Controls Released").
								until stage:number = 0 {stage. wait 1.}
								rcs off. unlock steering. unlock throttle.
							}
						}
					}
				}
				else {
					if not a:contains("Wait") and not a:contains("Fin") {
						updateAct("Final Approach"). lock steering to retrograde. pause(10).
					}
				}
				wait 0.5.
			}
			if a = "Controls Released" pause(1).
		}
	}
	function pause {
		parameter p. set releaseAt to time:seconds + p. set paused to 1.
	}
	function updateAct {
		parameter act.		
		set a to act.
		hudtext(a,8,2,30,green,false).			
	}
	function available_twr {
		local g is body:mu / (ship:altitude + body:radius)^2.
		return ship:maxthrust / g / ship:mass.
	}
	function circular_fit {
		parameter data.
		local maneuver is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
		local fit is 0.
		add maneuver. wait 0.01.
		set fit to -maneuver:orbit:eccentricity.
		remove_any_nodes().
		return fit.
	}
	function capture_fit {
		parameter data.
		local maneuver is node(time:seconds + eta:periapsis, 0, 0, data[0]).
		local fit is 0.
		add maneuver. wait 0.01.
		set fit to -maneuver:orbit:eccentricity.
		remove_any_nodes().
		return fit.
	}
	function remove_any_nodes {
		until not hasnode {
		remove nextnode. wait 0.01.
		}
	}
}
for dependency in list(
	"lib_mission_runner.ks", "lib_biomes.ks", "lib_gui.ks"
) runpath("0:/lib/"+dependency).

run_mission(mission["sequence"], mission["events"]).