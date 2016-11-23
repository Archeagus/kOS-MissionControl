function retrieve_biomes {
	if exists("0:/science/evabiomes.json") set n to readjson("0:/science/evabiomes.json").
	return n.
}

function update_biomes {
	parameter n.
	if exists("0:/science/evabiomes.json") movepath("0:/science/evabiomes.json","0:/science/evabiomes.json.backup").
	writejson(n, "0:/science/evabiomes.json").
}