package.path = "../?.lua;" .. package.path
local boxgen = require "./boxgen"
local viewer = require "./viewer"
local inspect = require "./inspect"
local pause = require "./pause"
local export = require "./export"
local getArgs = require "./args"

--Get Settings to run
local settings = getArgs(arg)

--Load Object File
local objfile = boxgen.load(settings.filename)

--Find offset 0,0,0
local offset = boxgen.boundingBox(boxgen.deref(objfile))

--If not relocating, need 1.5 offset from offset:
local reposition = {}
reposition.x = 1.5 + offset.x 
reposition.y = 1.5 + offset.y
reposition.z = 1.5 + offset.z

if settings.relocate then
    --Then we need to change position of all verticies in the obj file to match our output
    boxgen.offset(settings.filename,settings.outfile,-reposition.x,-reposition.y,-reposition.z)
    --reload newly created outfile
    objfile = boxgen.load(settings.outfile)
end

--Export just .obj for viewing in Obj.html
viewer.viewObj(objfile)

--Voxelize the Object (equal spaced grid approximation)
local grid = boxgen.voxelize(boxgen.deref(objfile),settings.spacing, settings.relocate, reposition)

--Break the grid into 3x3x3 chunks (using reposition to adjust location)
local groups = boxgen.breakup(grid, inspect, settings.relocate, reposition)

        -------Optional views-------

    --Export the grid and Obj for viewing
    --viewer.viewObjGrid(objfile, grid)

    --if groups.size.x*groups.size.y*groups.size.z > 1 then
    --    viewer.viewObjSubGrid(objfile, grid, groups)
    --end

        -----End optional views-----

--Now to calculate our collision boxes
local boxGroups = boxgen.boxify(groups, settings.minfill, settings.minvol, settings.minqual, inspect)

--Export the boxes for viewing
viewer.viewObjBoxes(objfile, grid, boxGroups)


--Precalculate the collision and selection box formated strings, as well as
--make a list of x,y,z (in node-coords) from placement node to where these collision and selection boxes
--Should go. I.e. @ y = 1 (1 above) placement node, use this string for collision boxes and this string for selection boxes:
local output = export.format(boxGroups, settings.relocate)
inspect() --This only exists because of jankiness with luajit
--
-- Export Minetest Readable data (JSON-Like)
--
output = export.serialize(output)

local outFile = io.open("data.box", "w+") --Open file for writing
io.output(outFile)
io.write(output)
io.close(outFile)
