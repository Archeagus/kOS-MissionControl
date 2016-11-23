{
  local MANEUVER_LEAD_TIME is 600.
  local SLOPE_THRESHHOLD is 1.
  local INFINITY is 2^64.

  global transfer is lex(
    "seek", seek@
  ).

  function seek {
    parameter tgt_body, tgt_periapsis.
    local attempt is 1.
    local data is starting_data(attempt).

    // Seek encounter, advancing start time if we get stuck
    until 0 {
	  set data to hillclimb["seek"](data, transfer_fit(tgt_body), 15).
      if transfers_to(nextnode, tgt_body) { break. }
      set attempt to attempt + 1.
      set data to starting_data(attempt).
    }

    set data to hillclimb["seek"](data, periapsis_fit(tgt_body, tgt_periapsis), 10).
    set data to hillclimb["seek"](data, periapsis_fit(tgt_body, tgt_periapsis), 1).

    remove_any_nodes().
    return make_node(data).
  }

  function transfer_fit {
    parameter tgt_body.
    function fitness_fn {
      parameter data.
      local maneuver is make_node(data).
      remove_any_nodes().
      add maneuver. wait 0.01.
      if transfers_to(maneuver, tgt_body) return 1.
      local fitness is -closest_approach(
        tgt_body,
        time:seconds + maneuver:eta,
        time:seconds + maneuver:eta + maneuver:orbit:period
      ).
      return fitness.
    }
    return fitness_fn@.
  }

  // TODO: There's a lot of shared code in these fitness functions. Probably
  // means some stuff can be merged / abstracted
  function periapsis_fit {
    parameter tgt_body, tgt_periapsis.
    function fitness_fn {
      parameter data.
      local maneuver is make_node(data).
      remove_any_nodes().
      add maneuver. wait 0.01.
      if not transfers_to(maneuver, tgt_body) return -INFINITY.
      return -abs(maneuver:orbit:nextpatch:periapsis - tgt_periapsis).
    }
    return fitness_fn@.
  }

  function closest_approach {
    parameter tgt_body, start_time, end_time.
    local start_slope is slope_at(tgt_body, start_time).
    local end_slope is slope_at(tgt_body, end_time).
    local middle_time is (start_time + end_time) / 2.
    local middle_slope is slope_at(tgt_body, middle_time).
    until (end_time - start_time < 0.1) or middle_slope < 0.1 {
      if (middle_slope * start_slope) > 0
        set start_time to middle_time.
      else
        set end_time to middle_time.
      set middle_time to (start_time + end_time) / 2.
      set middle_slope to slope_at(tgt_body, middle_time).
    }
    return separation_at(tgt_body, middle_time).
  }

  function slope_at {
    parameter tgt_body, at_time.
    return (
      separation_at(tgt_body, at_time + 1) -
      separation_at(tgt_body, at_time - 1)
    ) / 2.
  }

  function separation_at {
    parameter tgt_body, at_time.
    return (positionat(ship, at_time) - positionat(tgt_body, at_time)):mag.
  }

  function transfers_to {
    parameter maneuver, tgt_body.
    return (
      maneuver:orbit:hasnextpatch and
      maneuver:orbit:nextpatch:body = tgt_body
    ).
  }

  function starting_data {
    parameter attempt.
    return list(time:seconds + (MANEUVER_LEAD_TIME * attempt), 0, 0, 0).
  }

  function make_node {
    parameter maneuver.
    return node(maneuver[0], maneuver[1], maneuver[2], maneuver[3]).
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.01.
    }
  }
}