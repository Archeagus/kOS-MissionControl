// APEX Master Mission Profile Script w/ Kevin Gisi
local mfile is "BASIC ORBITAL MISSION".
local ver is "ver. APEX-MMP-0.1.0".

local events is import("events.ks").
local mission_control is import("lib_protocol.ks").
local transfer is import("lib_transfer.ks").

local TARGET_ALTITUDE is 300000.
local REENTRY_BURN_ALTITUDE is 100000.
local ATMO is max(body:atm:height,30000).
local freeze is transfer["freeze"].
lock sn to stage:number.
set returning to 0.
set mes to 1.

local mission is mission_control({ parameter seq, ev, next.
	for k in events:keys ev:add(k, events[k]).
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
		lock steering to heading(90, target_pitch).
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
		if not paused {
			if periapsis < 70000 {
				lock throttle to 1.
			}
			else {
				lock throttle to 0.
				next().
			}
		}
		wait 0.5.
	}).
	
	seq:add({
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
			lock throttle to 1.
			wait until ship:maxthrust < 1.
			lock throttle to 0.
			until sn = 0 {stage. wait 0.}
			action("Planetfall").
			next().
		}
	}).

	seq:add({
		if alt:radar < 10000 unlock steering.
		if ship:status = "Landed" action("Mission Complete").
		wait 5. 
	}).
}).

export(mission).
