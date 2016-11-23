global system_sort is list("Celestial Body", "Land Mult.", "No. of Biomes", "Splashed Mult.", "Low Atmosphere", "High Atmosphere", "Border", "Atmo Limit", "Low Orbit", "High Orbit", "Orbit Line", "Recovery").

global solar_system is lex(
	"Kerbol", list("N/A", "N/A", "N/A", "1x", "1x", "18km", "600km", "11x", "2x", "1000Mm", "4x"),
	"Moho", list("10x", "12", "N/A", "N/A", "N/A", "N/A", "N/A", "8x", "7x", "80km", "7x"),
	"Eve", list("8x", "7", "8x", "6x", "6x", "22km", "90km", "7x", "5x", "400km", "5x"),
	"Gilly", list("9x", "3", "N/A", "N/A", "N/A", "N/A", "N/A", "8x", "6x", "6km", "6x"),
	"Kerbin", list("0.3x", "42", "0.4x", "0.7x", "0.9x", "18km", "70km", "1x", "1.5x", "250km", "1x"),
	"Mun", list("4x", "15", "N/A", "N/A", "N/A", "N/A", "N/A", "3x", "2x", "60km", "2x"),
	"Minmus", list("5x", "9", "N/A", "N/A", "N/A", "N/A", "N/A", "4x", "2.5x", "30km", "2.5x"),
	"Duna", list("8x", "5", "N/A", "5x", "5x", "12km", "50km", "7x", "5x", "140km", "5x"),
	"Ike", list("8x", "8", "N/A", "N/A", "N/A", "N/A", "N/A", "7x", "5x", "50km", "5x"),
	"Dres", list("8x", "8", "N/A", "N/A", "N/A", "N/A", "N/A", "7x", "6x", "25km", "6x"),
	"Jool", list("N/A", "N/A", "N/A", "12x", "9x", "120km", "200km", "7x", "6x", "4Mm", "6x"),
	"Laythe", list("14x", "5", "12x", "11x", "10x", "10km", "50km", "9x", "8x", "200km", "8x"),
	"Vall", list("12x", "4", "N/A", "N/A", "N/A", "N/A", "N/A", "9x", "8x", "90 km", "8x"),
	"Tylo", list("12x", "8", "N/A", "N/A", "N/A", "N/A", "N/A", "10x", "8x", "250km", "8x"),
	"Bop", list("12x", "5", "N/A", "N/A", "N/A", "N/A", "N/A", "9x", "8x", "25km", "8x"),
	"Pol", list("12x", "4", "N/A", "N/A", "N/A", "N/A", "N/A", "9x", "8x", "22km", "8x"),
	"Eeloo", list("15x", "7", "N/A", "N/A", "N/A", "N/A", "N/A", "12x", "10x", "60km", "10x")
).

local destination is Minmus.
display().
getPlanet(destination:name).

function getPlanet {
	parameter b. set data to solar_system[b].
	
	print system_sort[0] at (0,3). print b at (23-b:length,3).
	
	from {local x is 1.} until x = system_sort:length step {set x to x+1.} do {
		print system_sort[x] at (0,4+x). print data[x-1] at (23-data[x-1]:length,4+x).
	}
}
