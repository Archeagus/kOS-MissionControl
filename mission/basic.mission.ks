// APEX Basic Mission Profile Script w/ Kevin Gisi
local mfile is "BASIC ORBITAL MISSION".
local ver is "ver. APEX-BMP-0.1.2".

local events is import("events.ks").
local mission_control is import("lib_protocol.ks").
local transfer is import("lib_transfer.ks").

local TARGET_ALTITUDE is 80000.
local REENTRY_BURN_ALTITUDE is 70000.
local ATMO is max(body:atm:height,30000).
local freeze is transfer["freeze"].
lock sn to stage:number.
//set returning to 0.
set mes to 2.

local mission is mission_control({ parameter seq, ev, next.
	for k in events:keys ev:add(k, events[k]).
	local status is "". set target_pitch to 90.
	
	seq:add({
		set ship:control:pilotmainthrottle to 0.
		gear off. lock throttle to .85.
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
			next().
		}
		if verticalspeed < 0 and alt:radar > 1000 {abort on. next().}
		wait 1.
	}).
	
	seq:add({
		if abort next().
		if alt:radar > atmo {
			if eta:apoapsis < 2 next().
		}
		if verticalspeed < 0 {abort on.}
	}).

	seq:add({
		if abort {
			action("Aborting Mission").
			stage. lock steering to srfretrograde.
			abort off.
			next().
		}
		if not warp {
			if periapsis < 70000 {
				lock throttle to 1.
			}
			else if verticalspeed < 0 and availablethrust = 0 abort on.
			else {
				lock throttle to 0.
				next().
			}
		}
		wait 1.
	}).
	
	seq:add({
		if not abort next().
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
			if periapsis > 40000 {
				lock throttle to max(1-(40000/alt:radar),.1).
			}
			else {
				lock throttle to 0.
				next().
			}
		} wait 0.
	}).
	
	seq:add({
		if not paused {
			if availablethrust > 0 and alt:radar < 70000 lock throttle to .5.
			else if alt:radar > atmo pause(5).
			else {until sn = 0 {stage. wait 0.}	if not status = "Planetfall" action("Planetfall"). pause(5).}
			if alt:radar < 10000 {unlock steering. next().}
		} wait 0.
	}).
	
	seq:add({
		if not status = "Mission Complete" if ship:status = "SPLASHED" or ship:status = "LANDED" action("Mission Complete").
		wait 0.
	}).
	
}).

export(mission).
