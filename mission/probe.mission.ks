// APEX Master Mission Profile Script w/ Kevin Gisi
local mfile is "BASIC ORBITAL MISSION".
local ver is "ver. APEX-MMP-0.1.0".

local events is import("events.ks").
local mission_control is import("lib_protocol.ks").
local transfer is import("lib_transfer.ks").
local incline is import("lib_incline.ks").

local TARGET_ALTITUDE is 495000.
local TARGET_INC is 83.6.
local LAZDATA is incline["init"](TARGET_ALTITUDE, TARGET_INC).
local AZIMUTH is incline["exec"](LAZDATA).
local REENTRY_BURN_ALTITUDE is 100000.
local ATMO is max(body:atm:height,30000).
local freeze is transfer["freeze"].
local satpos is 0.
local mes is 1.
lock sn to stage:number.

local mission is mission_control({ parameter seq, ev, next.
	for k in events:keys ev:add(k, events[k]).
	ev:add("mce_incline", {set AZIMUTH to incline["exec"](LAZDATA).}).
	local status is "". set target_pitch to 90.
	
	seq:add({
		set ship:control:pilotmainthrottle to 0.
		gear off. lock throttle to 1.
		lock steering to heading(90, 90).
		countdown(5). stage.
		next().
	}).
	
	seq:add({
		action("Beginning Ascent Burn").
		lock pct_alt to alt:radar / TARGET_ALTITUDE.
		lock target_pitch to -115.23935 * pct_alt^0.4095114 + 88.963.
		lock steering to heading(AZIMUTH, target_pitch).
		next().
	}).

	seq:add({
		if apoapsis > TARGET_ALTITUDE {
			action("Ascent Burn Complete").
			lock throttle to 0.
			lock steering to prograde.
			pause(eta:apoapsis - 10).
			next().
		}
	}).

	seq:add({
		if alt:radar > body:atm:height {
			action("Entering Orbit").
			transfer["seek"](
				freeze(time:seconds + eta:apoapsis),
				freeze(0), freeze(0), 0, { parameter mnv. return -mnv:orbit:eccentricity. }).
			transfer["exec"](true).
			lock throttle to 0.
			next().
		}
	}).
	
	seq:add({
		for sp in ship:modulesnamed("SCANsat") {
			if sp:hasevent("start radar scan") {
				sp:doevent("start radar scan").
				action("SCANsat Radar Deploying").
			}
			if sp:hasevent("start multispectral scan") {
				sp:doevent("start multispectral scan").
				action("Multispectral Scanner Deploying").
			}
		}
		next().
	}).
	
	seq:add({
		if not satpos {
			lock steering to lookdirup(v(0,1,0), sun:position).
			action("Positioning Satellite").
			set satpos to 1.
		}
		if abort next().
		wait 1.
	}).
	
	seq:add({
		if body = Kerbin {
			action("Returning").
			lock steering to srfretrograde.
			pause(30).
			action("Finalizing Course").
			next().
			}
	}).

	seq:add({
		if not paused {
			if not status = "Planetfall" {
				lock throttle to 1.
				wait until ship:maxthrust < 1.
				lock throttle to 0.
				until sn = 0 {stage. wait 0.}
				action("Planetfall").
			}
		}
	}).
}).

export(mission).
