"mce_gui", {if not BIO:keys:contains(body:name) BIO:add(body:name,lex()).
gui["update"](status, BIO[body:name], round(target_pitch)).}