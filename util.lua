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


return editheader, editfooter, mksafe
