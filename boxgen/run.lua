package.path = "../?.lua;" .. package.path
local boxgen = require "./boxgen"
local viewer = require "./viewer"
local inspect = require "./inspect"
local pause = require "./pause"
local export = require "./export"

local name = "spike"
local FILE = "models/" .. name .. ".obj"
local OUTFILE = name .. "R.obj"
local SPACING = 0.1
local MINFILL = 0.75
local MINVOL = 0.02
local MINQUAL = 0.1 --Don't grow when you the growth is really bad...
local RELOCATE = false

--Load Object File
local objfile = boxgen.load(FILE)

local reposition = {}

local offset = boxgen.boundingBox(boxgen.deref(objfile))

--We need to position the voxelized grid to the correct offset from our placement node
--Which has bottom left corner at -1.5,-1.5,-1.5
reposition.x = -1.5 - offset.x 
reposition.y = -1.5 - offset.y
reposition.z = -1.5 - offset.z 

--IF the user
if RELOCATE then
    --Then we need to change position of all verticies in the obj file to match our output
    boxgen.offset(FILE,OUTFILE,reposition.x,reposition.y,reposition.z)
    
    objfile = boxgen.load(OUTFILE)
end

--Export it for Viewing in Obj.html
viewer.viewObj(objfile)

--Voxelize the Object (equal spaced grid approximation)
print("starting voxelize\n")
local grid = boxgen.voxelize(boxgen.deref(objfile),SPACING, RELOCATE, reposition)
print("Finished voxelize\n")

--Export the grid and Obj for viewing
viewer.viewObjGrid(objfile, grid)
print("Output Grid & OBJ to ObjGrid.html\n")



--Break the grid into 3x3x3 chunks (using reposition to adjust location
local groups = boxgen.breakup(grid, inspect, RELOCATE, reposition)

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


--Precalculate the collision and selection box formated strings, as well as
--make a list of x,y,z (in node-coords) from placement node to where these collision and selection boxes
--Should go. I.e. @ y = 1 (1 above) placement node, use this string for collision boxes and this string for selection boxes:
local output = export.format(boxGroups, RELOCATE)
print(inspect(output.nodes))
--
-- Export Minetest Readable data (JSON-Like)
--
output = export.serialize(output)

local outFile = io.open("data.box", "w+") --Open file for writing
io.output(outFile)
io.write(output)
io.close(outFile)
