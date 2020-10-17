local boxgen = require "./boxgen"
local viewer = require "./viewer"
local inspect = require "./inspect"
local pause = require "./pause"

local FILE = "models/glove.obj"
local SPACING = 0.14
local MINFILL = 0.75
local MINVOL = 0.02
local MINQUAL = 0.1 --Don't grow when you the growth is really bad...

--Load Object File
local objfile = boxgen.load(FILE)

--Export it for Viewing in Obj.html
viewer.viewObj(objfile)

--Voxelize the Object (equal spaced grid approximation)
print("starting voxelize\n")
local grid = boxgen.voxelize(boxgen.deref(objfile),SPACING)
print("Finished voxelize\n")

--Export the grid and Obj for viewing
viewer.viewObjGrid(objfile, grid)
print("Output Grid & OBJ to ObjGrid.html\n")

--Break the grid into 3x3x3 chunks
local groups = boxgen.breakup(grid, inspect)

if groups.size.x*groups.size.y*groups.size.z > 1 then
    --Warn user that it's larger than 3x3x3
    print("WARNING: Your object is outside normal collision box boundaries,\n you may want to consider shrinking it. This program will still generate the resulting collision box data\nand account for this fact,\n it's just often not what you want :)")
	pause()
	--Export the Subgrid Groups for Viewing, as they are relavent
    viewer.viewObjSubGrid(objfile, grid, groups)
end

--Now to calculate our collision boxes
local boxGroups = boxgen.boxify(groups, MINFILL, MINVOL, MINQUAL, inspect)

--Export the boxes for viewing
viewer.viewObjBoxes(objfile, grid, boxGroups)

--
-- Export Minetest Readable data
--

