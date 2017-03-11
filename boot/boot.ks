// APEX Mission Control Protocol - Mission Boot Preflight Manager
local bfile is "MISSION BOOT MANAGER". local ver is "ver. APEX-MBM-0.0.1".
if not exists("1:/lib_io.ks") copypath("0:/lib/lib_io.ks", "1:/").
runpath("1:/lib_io.ks"). import("preflight.ks")().
