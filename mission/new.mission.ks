// APEX Master Mission Profile Script w/ Kevin Gisi
local mfile is "MUN TRANSFER/RESEARCH".
local ver is "ver. APEX-MMP-0.0.5".

local events is import("events.ks").
local gui is import("lib_gui.ks").
local eng is import("lib_eng.ks").
local transfer is import("lib_transfer").
local mission_control is import("lib_protocol").
local descent is import("lib_descent").

local TARGET_ALTITUDE is 100000.
local TARGET_MUNAR_ALTITUDE is 20000.
local TARGET_RETURN_ALTITUDE is 30000.
local REENTRY_BURN_ALTITUDE is 100000.
local freeze is transfer["freeze"].
local ATMO is max(body:atm:height,30000).

local mission is mission_control({ parameter seq, ev, next.
	local status is "".
	seq:add({
		set ship:control:pilotmainthrottle to 0.
		gear off.
		gui["countdown"](5).
		lock throttle to 1.
		lock steering to heading(90, 90).
		wait 10.
		next().
	}).
	
	seq:add({
		stage. wait 5.
		set status to gui["action"]("Beginning Ascent Burn").
		lock pct_alt to alt:radar / TARGET_ALTITUDE.
		lock target_pitch to -115.23935 * pct_alt^0.4095114 + 88.963.
		lock steering to heading(90, target_pitch).
		next().
	}).

	seq:add({
		if apoapsis > TARGET_ALTITUDE {
			set status to gui["action"]("Ascent Burn Complete").
			lock throttle to 0.
			lock steering to prograde.
			next().
		}
	}).

	seq:add({
		if alt:radar > body:atm:height {
			set status to gui["action"]("Entering Orbit").
			transfer["seek"](
				freeze(time:seconds + eta:apoapsis),
				freeze(0), freeze(0), 0, { parameter mnv. return -mnv:orbit:eccentricity. }).
			transfer["exec"](true).
			lock throttle to 0.
			next().
		}
	}).

	seq:add({
		set status to gui["action"]("Seeking Mun Transfer").
		transfer["seek_SOI"](Mun, 0).
		transfer["exec"](true).
		next().
	}).

	seq:add({
		if not ship:obt:hasnextpatch {
			set status to gui["action"]("Altering Course").
			local correction_time is time:seconds + (eta:apoapsis / 4).
			transfer["seek_SOI"](Mun, 0, freeze(correction_time)).
			transfer["exec"](true).
			wait 1.
		}
		next().
	}).

	seq:add({
		if body <> Mun and eta:transition > 60 {
			set status to gui["action"]("Waiting for Transfer").
			warpto(time:seconds + eta:transition).
		}
		if body = Mun next().
	}).

	seq:add({
		if body = Mun {
			wait 30.
			set status to gui["action"]("Perparing Descent").
			transfer["seek"](
				freeze(time:seconds + 120),
				freeze(0), freeze(0), 0,
				{ parameter mnv.
					if mnv:orbit:periapsis < -100000 return 0.
					return -mnv:orbit:periapsis.
				}
			).
			transfer["exec"](true).
			next().
		}
	}).

	seq:add({
		if alt:radar < 120000 {
			set warp to 0.
			next().
		} else {
			set warp to 4.
		}
	}).

	seq:add({
		gear on.
		set status to gui["action"]("Begin Decelleration Burn").
		descent["suicide_burn"](3000).
		if stage:number >= 2 {
			lock throttle to 0. wait 0.1. stage. wait 0.1.
		}
		set status to gui["action"]("Seeking Optimal LZ.").
		descent["suicide_burn"](50).
		set status to gui["action"]("Touching Down").
		descent["powered_landing"]().
		next().
	}).

	seq:add({ if ship:crew():length = 0 next(). }).
	seq:add({ if ship:crew():length = 1 next(). }).

	seq:add({
		set status to "Launching". gui["countdown"](5).
		lock steering to heading(90, 90).
		lock throttle to 1.
		wait 2.
		lock steering to heading(90, 45).
		set status to gui["action"]("Mun Ascent Burn").
		next().
	}).
	
	seq:add({
		if apoapsis > TARGET_MUNAR_ALTITUDE {
			set status to gui["countdown"]("Ascent Burn Complete").
			lock throttle to 0.
			next().
		}
	}).

	seq:add({
		transfer["seek"](
			freeze(time:seconds + eta:apoapsis),
			freeze(0), freeze(0), 0,
			{ parameter mnv. return -mnv:orbit:eccentricity. }).
		transfer["exec"](true).
		next().
	}).

	seq:add({
		transfer["seek_SOI"](Kerbin, TARGET_RETURN_ALTITUDE).
		transfer["exec"](true).
		next().
	}).

	seq:add({
		local transition_time is time:seconds + eta:transition.
		warpto(transition_time).
		wait until time:seconds >= transition_time.
		next().
	}).

	seq:add({
		if body = Kerbin {
			wait 30.
			transfer["seek"](
				freeze(time:seconds + 120), freeze(0), freeze(0), 0,
				{ parameter mnv. return -abs(mnv:orbit:periapsis -
											 TARGET_RETURN_ALTITUDE). }).
			transfer["exec"](true).
			next().
			}
	}).

	seq:add({
		if alt:radar < REENTRY_BURN_ALTITUDE * 5 {
			set warp to 0.
			next().
		} else {
			set warp to 4.
		}
	}).

	seq:add({
		if ship:altitude < REENTRY_BURN_ALTITUDE {
			lock steering to retrograde. pause(5).
			next().
		}
	}).

	seq:add({
		if not paused {
			lock throttle to 1.
			wait until ship:maxthrust < 1.
			lock throttle to 0.
			stage. wait 0.
			lock steering to srfretrograde.
			next().
		}
	}).

	seq:add({ if ship:status = "Landed" next(). }).
}).

export(mission).