{local mce_pause is list("mce_pause", {if time:seconds > releaseAt set paused to 0.}). export(mce_pause).}