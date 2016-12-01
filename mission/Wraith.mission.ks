// APEX Master Mission Profile Script w/ Kevin Gisi
local mfile is "MINMUS LANDING/RESEARCH".
local ver is "ver. APEX-MMP-0.0.8".

local events is import("events.ks").
local transfer is import("lib_transfer.ks").
local mission_control is import("lib_protocol.ks").
local descent is import("lib_descent.ks").
local adjust is import("lib_inc_orbit.ks").
local gui is import("lib_gui.ks").
local biomes is import("lib_biomes.ks").

local TARGET_ALTITUDE is 100000.
local TARGET_DESTINY_ALTITUDE is 20000.
local TARGET_RETURN_ALTITUDE is 30000.
local REENTRY_BURN_ALTITUDE is 100000.
local freeze is transfer["freeze"].
local ATMO is max(body:atm:height,30000).
local BIO is retrieve_biomes().
lock sn to stage:number.
local FINE is 2.
local DESTINY is Minmus.

local mission is mission_control({ parameter seq, ev, next.
	for k in events:keys ev:add(k, events[k]).
	local status is "". set target_pitch to 90.
	
	seq:add({
		set ship:control:pilotmainthrottle to 0.
		gear off. lock throttle to 1.
		lock steering to heading(90, 90).
		gui["initialize"](mfile,ver).
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
		action("Matching Inclination").
		set_inc_lan(DESTINY:orbit:inclination, DESTINY:orbit:lan).
		transfer["exec"](true).
		next().
	}).

	seq:add({
		action("Seeking " + DESTINY:name + " Transfer").
		transfer["seek_SOI"](DESTINY, 0).
		transfer["exec"](true).
		next().
	}).

	seq:add({
		if ship:obt:hasnextpatch if ship:obt:nextpatch:body:name = DESTINY:name next().
		else {
			action("Altering Course").
			local correction_time is time:seconds + (eta:apoapsis / 4).
			transfer["seek_SOI"](DESTINY, 0, freeze(correction_time)).
			transfer["exec"](true).
			wait 1.
		}
	}).

	seq:add({
		if body <> DESTINY and eta:transition > 60 {
			action("Waiting for Transfer").
			warpto(time:seconds + eta:transition).
		}
		if body = DESTINY next().
	}).

	seq:add({
		if body = DESTINY {
			wait 30.
			action("Perparing Descent").
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
		hudtext(round(verticalspeed),30,4,36,red,false).
		if alt:radar > 120000 warpto(time:seconds + eta:periapsis - 300).
		next().
	}).

	seq:add({
		gear on.
		action("Begin Deceleration Burn").
		descent["suicide_burn"](3000).
		if stage:number >= 4 {
			lock throttle to 0. wait 0.1. stage. wait 1. stage.
		}
		action("Seeking Optimal LZ").
		descent["suicide_burn"](50).
		action("Touching Down").
		descent["powered_landing"]().
		//unlock steering.
		next().
	}).

	seq:add({ if ship:crew():length = 0 next(). }).
	seq:add({ if ship:crew():length = 1 next(). }).

	seq:add({
		action("Launching"). countdown(5).
		lock steering to heading(90, 90).
		lock throttle to 1.
		wait 2. gear off.
		lock steering to heading(90, 45).
		action(DESTINY:name + " Ascent Burn").
		next().
	}).
	
	seq:add({
		if apoapsis > TARGET_DESTINY_ALTITUDE {
			action("Ascent Burn Complete").
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
		if alt:radar > REENTRY_BURN_ALTITUDE * 15 set warp to 5.
		else if alt:radar > REENTRY_BURN_ALTITUDE * 7.5 set warp to 4.
		if alt:radar < REENTRY_BURN_ALTITUDE * 2 {
			set warp to 0.
			next().
		}
	}).

	seq:add({
		if ship:altitude < REENTRY_BURN_ALTITUDE {
			lock steering to retrograde. pause(5).
			next(). panels off.
		}
	}).

	seq:add({
		if not paused {
			lock throttle to 1.
			wait until ship:maxthrust < 1.
			lock throttle to 0.
			until sn = 0 {stage. wait 0.}
			// lock steering to srfretrograde.
			next().
		}
	}).

	seq:add({ if ship:status = "Landed" next(). }).
}).

export(mission).