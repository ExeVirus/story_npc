local MP 	= minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP..'/intllib.lua')

-- Storage Buffer:
local mesdat = {
storage = minetest.get_mod_storage(),
_context = {}   --To be used for all sorts of things later
}

-- Pass mesdat into the following files
assert(loadfile(path .. "/api.lua")) (mesdat)  --API is the core event subsystem, and entity editing
assert(loadfile(path .. "/registrations.lua")) (mesdat) --Simply the Entity registrations using the API
assert(loadfile(path .. "/commands.lua")) (mesdat) --Commands for working with entities more easily, like worldedit





