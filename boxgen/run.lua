package.path = "../?.lua;" .. package.path
local boxgen = require "./boxgen"
local viewer = require "./viewer"
local inspect = require "./inspect"
local pause = require "./pause"
local export = require "./export"

local FILE = "models/spike.obj"
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
    --print("WARNING: Your object is outside normal collision box boundaries,\n you may want to consider shrinking it. This program will still generate the resulting collision box data\nand account for this fact,\n it's just often not what you want :)")
	--pause()
	--Export the Subgrid Groups for Viewing, as they are relavent
    viewer.viewObjSubGrid(objfile, grid, groups)
end

--Now to calculate our collision boxes
local boxGroups = boxgen.boxify(groups, MINFILL, MINVOL, MINQUAL, inspect)

--Export the boxes for viewing
viewer.viewObjBoxes(objfile, grid, boxGroups)

--Pre calculate the Minetest nodes that are going to be filled by these boxes
local generated = export.calcNodes(boxGroups)

	--Note that the first 3x3x3 is ALWAYS considered empty, i.e. no ground conflicts. This is to  actually allow initial placement.
	--Also, I will add an option that just ignores all placement concerns and just does collisions and selections....

--Precalculate the collision and selection box formated strings
generated = export.format(generated)

--
-- Export Minetest Readable data (JSON-Like)
--
output = export.serialize(boxGroups)

local outFile = io.open("data.box", "w+") --Open file for writing
io.output(outFile)
io.write(output)
io.close(outFile)
