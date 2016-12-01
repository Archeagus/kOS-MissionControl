function retrieve_biomes {
	if exists("0:/logs/evabiomes.json") set n to readjson("0:/logs/evabiomes.json").
	return n.
}

function update_biomes {
	parameter n.
	if exists("0:/logs/evabiomes.json") movepath("0:/logs/evabiomes.json","0:/logs/evabiomes.json.backup").
	writejson(n, "0:/logs/evabiomes.json").
}

export(0).