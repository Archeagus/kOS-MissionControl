// APEX Mission Control Protocol M2 - Master Boot Procedure, v0.1.0
// Satellite Boot File Template, v0.1.0

if not exists("1:/lib_io.ks") copypath("0:/lib/lib_io.ks","1:/").
runpath("1:/lib_io.ks"). import("mission.ks")().

