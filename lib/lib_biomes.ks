{
	// lib_biomes version 0.1

	local biomes is lex(
		"init", init@,
		"update", udpate@
	).

	function init {
		if exists("0:/logs/evabiomes.json") set n to readjson("0:/logs/evabiomes.json").
		return n.
	}

	function update {
		parameter n.
		if exists("0:/logs/evabiomes.json") movepath("0:/logs/evabiomes.json","0:/logs/evabiomes.json.backup").
		writejson(n, "0:/logs/evabiomes.json").
	}

	export(biomes).
}
