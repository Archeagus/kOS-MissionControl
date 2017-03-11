"mce_comms", {if altitude > atmo {for m in ship:modulesnamed("ModuleDeployableAntenna") {if m:hasevent("extend antenna") {m:doevent("extend antenna"). wait 0.1.} return 1.}}}
