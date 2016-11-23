	set energy_cap to 0.
	set energy_cur to 0.
	set energy_draw to 0.
	set energy_prod to 0.
	
	list resources in res.
	for r in res {
		if r:name = "electriccharge" {
			set energy_cap to energy_cap + round(r:capacity).
			set energy_cur to energy_cur + round(r:amount).
		}
	}
	
	function energy_drawn {
		set start to time:seconds. set c to energy_cur. set d to 0.
	    for r in res {
			if r:name = "electriccharge" {
				set d to d + r:amount.
			}
		}
		set d to (c - d)/(time:seconds - start).
		return round(d,2).
	}
	set energy_draw to energy_drawn().
	
	print "Energy Capacity: " + energy_cap.
	print "Energy Current:  " + energy_cur.
	print "Energy Draw:     " + energy_draw.