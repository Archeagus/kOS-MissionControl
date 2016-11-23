{
	local tAlt is 150000. local mDir is 90. local vDest is Mun. local dAlt is 405000. local dInc is 85.2.local done is 0. lock soln to obt:lan. lock soi to obt:inclination. set i to list(100,10,1). lock sn to stage:number. 	local dHeading is lookdirup(v(0,1,0), sun:position). local atmo is max(body:atm:height,30000). local a is " ". local paused is 0. local releaseAt is 0.
	

	global mission is lex(
		"sequence", list(
		"Preflight", preflight@,
		"Launch", launch@,
		"Ascent", ascent@,
		"Circularize", circularize@,
		"Aligning Target", inclination_adj@,
		"Perform Transfer", perform_transfer@,
		"Finalizing Approach", approach@,
		"Perform Capture", perform_capture@,
		"Adjust Orbit", inclination_adj@,
		"Enable Systems", enable_antennae@,
		"Adrift", idle@,
		"Return", return_home@,
		"Planetfall", drop@
	),
    "events", lex(
		// Time Keeper for missions. Used to pause activity during certain mission stages (such as immediately after a Stage action). To use this event, you must have a "pause(x)" command where x is the number of seconds to pause to initiate it in the mission stage and a "if not pause {" block to skip the instructions impacted by the pause. Instructions within the "if not pause" block will be skipped until the doPause event cycles through, reducing the pause level by two every second (1 every 0.5 seconds) by default.
		"doPause", {parameter mission. if time:seconds > releaseAt set paused to 0.},
		// First pass. Create/update the terminal output and (TODO) log file.
		"updateOutput", {
			parameter mission.
			gui["update"](a, b[vDest:name], round(trgt_pitch)).
			},
		// Deploy energy production.
		"energyPanels", {parameter mission.
			if (ship:altitude > atmo) {
				panels on.
				mission["remove_event"]("energyPanels").
				}
			},
		// Test for engine burnout.
		"checkStaging", {
			parameter mission.
			if throttle > 0 {
				if availablethrust = 0 and a:contains("Safeties") and sn >= fine {stage. lock throttle to 0.}
				else if sn = 0 and availablethrust = 0 and not (a = "Deploying Safeties") {
					hudtext("WARNING: Engines Thrust Unavailable",10,4,25,red,false).
					lock throttle to 0.
				}
				else if sn > 0 {
					list engines in eng.
					for e in eng {
						if e:stage = sn and e:ignition and e:flameout and sn > 0 {
							stage. wait 1.
							if availablethrust = 0 and sn > 0 stage.
							break.
	}	}	}	}	}	)	).

	on abort {set done to 1. return true.}
	on gear {sas off. if throttle = 0 and not hasnode {lock steering to lookdirup(v(0,1,0), sun:position).}	gear off. return true.}
	on AG1 {unlock steering. return true.}
	
  function preflight {
		parameter mission.
		set fine to eng["Final Engine"]().
		set ship:control:pilotmainthrottle to 0.
		lock throttle to 1. lock steering to heading(mDir, 90).
		uA("Preflight Complete"). gui["countdown"](5).
		mission["next"]().
	}

	function launch {
		parameter mission.
		uA("Liftoff").
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
		if apoapsis > tAlt and not a:contains("Burn") {
			uA("Ascent Burn Complete").
			lock throttle to 0.
			lock steering to prograde.
		}
		if altitude > atmo {
			uA("Leaving Atmosphere").
			mission["next"]().
		}
		wait 0.5.
	}

	function circularize {
		parameter mission.

		local dV is list(0).
		for x in i set dV to hillclimb["seek"](dV, circular_fitn@, x).

		add node(time:seconds + eta:apoapsis, 0, 0, dV[0]). wait 0.5.
		uA("Entering Orbit"). maneuver["exec"](true). uA("Orbit Complete").
		lock throttle to 0.	lock steering to dHeading.
		wait 0.5.
		mission["next"]().
	}

	function perform_transfer {
		parameter mission.
		if not pause {
			uA("Transfering to "+vDest:name).
			set mapview to true.
			local mnv is transfer["seek"](vDest, dAlt).
			add mnv. wait 0.01.
			set mapview to false.
			maneuver["exec"](true).
			if ship:obt:hasnextpatch {
				if ish(ship:obt:nextpatch:periapsis, dAlt, 0.1) {
					uA("Awaiting SOI Change").
					lock steering to dHeading.
					warpto(time:seconds + ship:obt:nextpatcheta - 10).
					mission["next"]().
				} else set pause to 30.
			} 
		}
		wait 0.5.
	}

	function approach {
		parameter mission. set s to dAlt.
		
		if pause set pause to pause - 1.
		if not pause {
			if a = "Correcting Course" {
				if periapsis < s * 0.9999 {
					lock steering to prograde. wait 5.
				}
				else if periapsis > s * 1.0001 {
					lock steering to retrograde. wait 5.
				}
				uA("Adjusting Periapsis").
			}
			if (a = "Adjusting Periapsis") {
				if periapsis < s * 0.9999 {
					lock throttle to 0.25.
					if (periapsis > 0 and periapsis < s * 1.0001) {
						lock throttle to min(max(abs(1-s/periapsis),0.01),0.5).}
				}
				else if periapsis > s * 1.0001 {
					lock throttle to 0.5.
					if periapsis < s*5 {
						lock throttle to min(max(abs((periapsis-s)/(s*4)),0.01),0.5).
					}
				}		
			}
			if periapsis > s * 0.99 and periapsis < s  {
				lock throttle to 0.
				uA("Approach Final").
				mission["next"]().
			}
			else if not (a = "Adjusting Periapsis") {
				if body = vDest {
					if eta:apoapsis < eta:periapsis and apoapsis > s*2 {
						if eta:apoapsis < 6 uA("Correcting Course").
					}
					else uA("Correcting Course").
				}
			}
		}
		wait 0.5.
	}

	function perform_capture {
		parameter mission.
		if not pause {
			lock steering to dHeading.
			local dV is list(0).
			for x in i set dV to hillclimb["seek"](dV, cap_fn@, x).
			add node(time:seconds + eta:periapsis, 0, 0, dV[0]). wait 0.5.
			maneuver["exec"](true).
			lock steering to dHeading.
			uA("Capture Complete").
			mission["next"]().
		}
		wait 0.5.
	}


	function inclination_adj {
		parameter mission.
		if not pause {
			if body = Kerbin {
				if not ish(soi, 6, 0.1) {
					set_inc_lan(6,78).
					maneuver["exec"](true).
					set pause to 60.
				}
				else mission["next"]().
			}
			else if not ish(soi, dInc, 0.05) {
				set_inc_lan(dInc,soln).
				maneuver["exec"](true).
				set pause to 60.
			}
			else mission["next"]().
		}
		wait 0.5.
	}

	function enable_antennae {
		parameter mission.
		set targets to list("Kerbin","Mun","active-vessel").
		set n to 0.
		for sp in ship:modulesnamed("ModuleDeployableAntenna") { 
			if sp:hasevent("no target") {
				sp:setfield("target", n). 
				if not (n = targets:length - 1) set n to n + 1.
			}
			if sp:hasevent("extend antenna") sp:doevent("extend antenna").
		}
		for sp in ship:modulesnamed("SCANsat") {
			if sp:hasevent("start radar scan") sp:doevent("start radar scan").
			if sp:hasevent("start multispectral scan") sp:doevent("start multispectral scan").
		}
		mission["next"]().
	}
	
	function idle {
		parameter mission.
		
		if not pause {
			if done {
				mission["next"]().
			}
		}
		wait 0.5.	
	}
	
	function return_home {
		parameter mission, par_vel is 0, par_phase is -45, home is Kerbin.
		 
		if not (a = "Returning Home") {
			uA("Transfer to " + home:name).
			set vec_escape to ship:body:body:prograde:vector:normalized.
			 
			set vec_vel   to ship:prograde:vector:normalized.
			set vec_cross to VCRS(vec_escape, vec_vel):normalized.
			 
			set phase_deg to vectorangle(vec_escape, vec_vel).
			 
			if (obt:inclination<90 and vec_cross:y < 0) or (obt:inclination>90 and vec_cross:y > 0) {
				set phase_deg to 360-phase_deg.
			}
			 
			set phase_deg to phase_deg + par_phase.
			if (phase_deg < 0) {
				set phase_deg to phase_deg+360.
			}
			 
			set eta_sec to (ship:obt:period/360) * phase_deg.
			 
			if(par_vel = 0) {
				set new_periapsis to (apoapsis+periapsis)/2.
				set margin to 50 * 1000.
				set new_semimajor to (new_periapsis+ship:body:radius + ship:body:soiradius+ship:body:radius + margin) / 2.
			 
				set eta_curVel to velocityat(ship, time+eta_sec):obt:mag.
				set eta_reqVel to SQRT(ship:body:mu * (2/(new_periapsis+ship:body:radius) - 1/new_semimajor)).
				set par_vel to eta_reqVel - eta_curVel.
			}
	 
			set man_node to node((time+eta_sec):seconds, 0, 0, par_vel).
			add man_node. wait 0.5.
			maneuver["exec"](true). wait 5.
			lock steering to dHeading.
			uA("Returning Home").
		}
		if ship:body = home {
			if periapsis > atmo * 0.4 lock steering to retrograde.
			if periapsis < atmo * 0.3 lock steering to prograde.
			set pause to 11.
			uA("Final Approach").
			mission["next"]().
		}
		wait 1.
	}
	
	function drop {
		parameter mission.
		
		if pause set pause to pause - 1.
		if not pause {
			if not (a = "Controls Reduced") {
				if a = "Final Approach" {
					if periapsis > atmo * 0.4 or periapsis < atmo * 0.3 {
						if periapsis > atmo * 3 lock throttle to 1.
						else if periapsis > atmo * 2 lock throttle to 0.5.
						else lock throttle to 0.05.
					}
					else {
						lock throttle to 0.
						lock steering to retrograde.
						uA("Entering "+body:name).
					}
				}
				if a:contains("Entering") {
					if altitude < atmo * 1.1 {
						panels off.
						uA("Decelerating").
					}
				}
				if a = "Decelerating" {
					if availablethrust > 0 {lock throttle to 1.	rcs on.}
					else {set cc to 0. uA("Deploying Safeties").}
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
								uA("Controls Released").
								until sn = 0 {stage. wait 1.}
								rcs off. unlock steering. unlock throttle.
							}
						}
					}
				}
			}
		}
		wait 0.5.
	}
	
	function uA {parameter act. set a to act.	hudtext(a,5,2,30,green,false).}
	
	function available_twr {local g is body:mu / (ship:altitude + body:radius)^2. return ship:maxthrust / g / ship:mass.}

	function circular_fitn {parameter data. local maneuver is node(time:seconds + eta:apoapsis, 0, 0, data[0]). local fitn is 0. add maneuver. wait 0.01. set fitn to -maneuver:obt:eccentricity. remove_any_nodes(). return fitn.}
	
	function cap_fn {parameter data. local maneuver is node(time:seconds + eta:periapsis, 0, 0, data[0]). local fitn is 0. add maneuver. wait 0.01.	set fitn to -maneuver:obt:eccentricity. remove_any_nodes(). return fitn.}

	function remove_any_nodes {until not hasnode {remove nextnode. wait 0.01.}}
	
	function ish {parameter a, b, v. if a > b*(1-v) and a < b*(1+v) return true. else return false.}
	
	function pause {parameter p. set releasedAt to time:seconds + p. set paused to 1.}
	
	for f in list(
		"lib_mission_runner.ks", "lib_hillclimb.ks", "lib_transfer.ks",	"lib_maneuver.ks",
		"lib_inclination.ks", "lib_gui.ks", "lib_engineering.ks"
	) runpath("0:/library/"+f).

	run_mission(mission["sequence"], mission["events"]).
}