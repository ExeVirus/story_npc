------API Utility Functions------

--
-- Header and Footer Functions
--
-- Specifically for the edit forspecs
--

local function editheader()
	local ret = {
		"formspec_version[3]",
        "size[10,10,false]",
        "real_coordinates[true]",
        "position[0.5,0.5]",
		}
	return table.concat(ret, "")
end


local function editfooter(str)
	local ret = "field[-100,-100;0,0;editform;;" .. str .."]"
	return ret
end

--
-- Sanitizes Player Input
-- to remove executable code
--

local function mksafe(str)
	return minetest.formspec_escape(str)
end

--
-- texture_table
-- Creates associative table of texture names for whole mod, alphabetically listed (no .png)
--

local function texturetable()
	local ret

	return ret
end

--
-- texturelist
-- Simply a comma seperated string of texture names (no .png)
--

local function texturelist()
	local ret

	return ret
end

--
-- model_table
-- Creates associative table of model names for whole mod, alphabetically listed (no .png)
--

local function modeltable()
	local ret

	return ret
end

--
-- modellist
-- Simply a comma seperated string of model names (no .png)
--

local function modellist()
	local ret

	return ret
end

--
-- sound_table
-- Creates associative table of sound names for whole mod, alphabetically listed (no .png)
--

local function soundtable()
	local ret

	return ret
end

--
-- soundlist
-- Simply a comma seperated string of sound names (no .png)
--

local function soundlist()
	local ret

	return ret
end


return editheader, editfooter, mksafe, texturetable, texturelist, modeltable, modellist, soundtable, soundlist
