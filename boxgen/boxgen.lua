local loader = {}

function loader.load(file)
	assert(file_exists(file), "File not found: " .. file)

	local get_lines


	get_lines = io.lines


	local lines = {}

	for line in get_lines(file) do
		table.insert(lines, line)
	end

	return loader.parse(lines)
end

function file_exists(file)
	local f = io.open(file, "r")
	if f then f:close() end
	return f ~= nil
end

-- http://wiki.interfaceware.com/534.html
function string_split(s, d)
	local t = {}
	local i = 0
	local f
	local match = '(.-)' .. d .. '()'

	if string.find(s, d) == nil then
		return {s}
	end

	for sub, j in string.gmatch(s, match) do
		i = i + 1
		t[i] = sub
		f = j
	end

	if i ~= 0 then
		t[i+1] = string.sub(s, f)
	end

	return t
end

function loader.parse(object)
	local obj = {
		v	= {}, -- List of vertices - x, y, z, [w]=1.0
--~ 		vt	= {}, -- Texture coordinates - u, v, [w]=0
--~ 		vn	= {}, -- Normals - x, y, z
--~ 		vp	= {}, -- Parameter space vertices - u, [v], [w]
		f	= {}, -- Faces
	}

	for _, line in ipairs(object) do
		local l = string_split(line, "%s+")

		if l[1] == "v" then
			local v = {
				x = tonumber(l[2]),
				y = tonumber(l[3]),
				z = tonumber(l[4]),
--~ 				w = tonumber(l[5]) or 1.0
			}
			table.insert(obj.v, v)
--~ 		elseif l[1] == "vt" then
--~ 			local vt = {
--~ 				u = tonumber(l[2]),
--~ 				v = tonumber(l[3]),
--~ 				w = tonumber(l[4]) or 0
--~ 			}
--~ 			table.insert(obj.vt, vt)
--~ 		elseif l[1] == "vn" then
--~ 			local vn = {
--~ 				x = tonumber(l[2]),
--~ 				y = tonumber(l[3]),
--~ 				z = tonumber(l[4]),
--~ 			}
--~ 			table.insert(obj.vn, vn)
--~ 		elseif l[1] == "vp" then
--~ 			local vp = {
--~ 				u = tonumber(l[2]),
--~ 				v = tonumber(l[3]),
--~ 				w = tonumber(l[4]),
--~ 			}
--~ 			table.insert(obj.vp, vp)
		elseif l[1] == "f" then
			local f = {}

			for i=2, #l do
				table.insert(f, tonumber(string_split(l[i], "/")[1]))
			end

			table.insert(obj.f, f)
		end
	end

	return obj
end

local inspect = require "./inspect"

function loader.deref(object)
	local obj = {}
	for i, v in ipairs(object.f) do
		local val = {}
		for j=1,3 do
			table.insert(val, object.v[ object.f[i][j] ])
		end
		table.insert(obj, val)
	end
	return obj
end



local objfile = loader.load("models/spike.obj")

local export = io.open("test.html", "w+")

io.output(export)

local plotly_header = require "./plotly_header"

io.write(plotly_header)

io.write("<script>\n")
io.write("var data = [{ \n")
io.write('type: "mesh3d",\n')
--Write the X's
io.write('x: [')
for i,v in ipairs(objfile.v) do
	io.write(v.x .. ", ")
end
io.write('],\n');
--Write the Y's
io.write('y: [')
for i,v in ipairs(objfile.v) do
	io.write(v.y .. ", ")
end
io.write('],\n');
--Write the Z's
io.write('z: [')
for i,v in ipairs(objfile.v) do
	io.write(v.z .. ", ")
end
io.write('],\n');
--Write the I's
io.write('i: [')
for i,v in ipairs(objfile.f) do
	io.write(v[1]-1 .. ", ")
end
io.write('],\n');
--Write the J's
io.write('j: [')
for i,v in ipairs(objfile.f) do
	io.write(v[2]-1 .. ", ")
end
io.write('],\n');
--Write the K's
io.write('k: [')
for i,v in ipairs(objfile.f) do
	io.write(v[3]-1 .. ", ")
end
io.write('],\n');

io.write([[
	opacity:0.2,
    color:'rgb(200,100,300)',
}];
Plotly.newPlot('myDiv', data);
</script>
]])

print("wrote test.html\n")

io.close(export)

local export2 = io.open("test2.lua", "w+")

io.output(export2)

for i,v in ipairs(loader.deref(objfile)) do
 	io.write(i .. "\n" .. inspect(v) .. "\n")
end

io.close(export2)

-- function Bounding Box -----------------
--
--  args: object (table of triangles and vertices, dereferenced)
--
--  returns: (table) offset {x,y,z}
--  		 (table) dimensions {w,h,d}

function boundingBox( object )
	local offset = {}
	offset.x = object[1][1].x
	offset.y = object[1][1].y
	offset.z = object[1][1].z
	local dimensions = {}
	dimensions.x = object[1][1].x
	dimensions.y = object[1][1].y
	dimensions.z = object[1][1].z
	for i, v in ipairs(object) do
		for j=1, 3 do
			offset.x = math.min(v[j].x, offset.x)
			dimensions.x = math.max(v[j].x, dimensions.x)
			offset.y = math.min(v[j].y, offset.y)
			dimensions.y = math.max(v[j].y, dimensions.y)
			offset.z = math.min(v[j].z, offset.z)
			dimensions.z = math.max(v[j].z, dimensions.z)
		end
	end
	dimensions.x = dimensions.x-offset.x
	dimensions.y = dimensions.y-offset.y
	dimensions.z = dimensions.z-offset.z
	return offset, dimensions
end

------------ Function raycast( x,y,z, triangle ) ---------------------
--
--		args: 	x,y,z of point to raycast from
-- 				triangle: {{x,y,z},{x,y,z},{z,y,z}}
--		returns: 1 or 0
--

local vector = require("vector")

function raycast( x,y,z, triangle)
	local EPSILON = 0.00001
	local rayOrigin = vector.new( x, y, z)
	local rayVector = vector.new( 0, 1, 0)

	local vert0 = triangle[1]
	local vert1 = triangle[2]
	local vert2 = triangle[3]

	local edge1 = vector.subtract(vert1, vert0)
	local edge2 = vector.subtract(vert2, vert0)

	local h = vector.cross(rayVector, edge2)
	local a = vector.dot(edge1, h)

	if (a > -EPSILON and a < EPSILON) then
		return 0 --Ray is parallel to triangle
	end

	local f = 1.0 / a
	local s = vector.subtract(rayOrigin, vert0)
	local u = f * vector.dot(s, h)
	if( u < 0.0 or u > 1.0) then
		return 0
	end

	local q = vector.cross(s, edge1)
	local v = f * vector.dot(rayVector, q)

	if ( v < 0.0 or (u+v) > 1.0) then
		return 0
	end

	local t = f * vector.dot(edge2, q)
	if ( t > EPSILON ) then
		return 1 --Ray intersection
	end
    --Line intersection
	return 0
end

--print(raycast( 1,1.5,1, {{x=0, y=2, z=0},{x=1,y=2,z=2},{x=2,y=2,z=0}} ))

--
-- Loader.voxelize( object, spacing )
-- Object is a table of triangles
-- spacing is the resulting voxel cube side-length
-- A node is 1. Therefore, 1/10 is 0.1. etc.
--

--
-- Returns an object containing info about the grid
-- as well as the resulting voxel data
--

-- https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm

--
-- First, function determines the max size grid to voxelize on
-- by calculating a simple bounding box (using spacing as a min size)
-- the offset to a corner of the bounding box is also stored to
-- align the voxel-grid later

-- Next, each voxel center-point is ray cast in the positive X direction
--      Based on the number of triangle intersections we determine if
--      we are inside or outside the object(s)
-- Using this information, mark the voxel inside or outside.

-- Finally, we return our resulting voxel grid

function loader.voxelize(object, spacing)
	local grid = {}
	grid.offset, grid.dimensions = boundingBox( object )
	--Note: if you're spacing is too large, the object will 100% fail to be voxelized in a useful manner. You
	--need at least 2 points in all directions to make a box. 1 point in any direction doesn't cut it.
	grid.voxels = {}
	grid.voxel_verts = {}
	local index = 1
	local indexverts = 1
	grid.spacing = spacing
	if(spacing < grid.dimensions.x and spacing < grid.dimensions.y and spacing < grid.dimensions.z) then
		for i = grid.offset.x, grid.offset.x+grid.dimensions.x, spacing do
			for j = grid.offset.y, grid.offset.y+grid.dimensions.y, spacing do
				for k = grid.offset.z, grid.offset.z+grid.dimensions.z, spacing do
					--Now to check each point and see if it is insize or outside our object
					-- (i,j,k) = point
					local count = 0
					for q, v in ipairs(object) do
						count = count + raycast(i,j,k,v)
					end
					if ( count % 2 == 0) then
						grid.voxels[index] = 0
						--we are outside
					else
						grid.voxels[index] = 1
						grid.voxel_verts[indexverts] = vector.new( i, j, k)
						indexverts = indexverts + 1
						--we are inside
					end
					index = index + 1
				end
			end
			print( (i-grid.offset.x)/spacing / (grid.dimensions.x / spacing) * 100 .. "% complete")
		end
	end
	grid.numberOfVoxels = index - 1
	grid.numberOfFilledVoxels = indexverts - 1

	return grid
end

print("starting voxelize\n")
--loader.voxelize(loader.deref(objfile),0.1)
local grid = loader.voxelize(loader.deref(objfile),0.1)
--print(inspect(grid))
print("Finished voxelize\n")

--loader.voxelize(loader.deref(objfile),0.1)

--
-- Function view_result(grid) -- Shows the filled verticies from voxelize
--

function loader.view_result(grid)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["
	for i, v in ipairs(grid.voxel_verts) do
		xs = xs .. v.x .. ", "
		ys = ys .. v.y .. ", "
		zs = zs .. v.z .. ", "
	end
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"

	output = output .. "var grid = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "mode: 'markers',\n"
	output = output .. "marker: { size: 2},\n"
	output = output .. "name: 'grid',\n"
	output = output .. "type: 'scatter3d',\n}\n"
	return output
end

print("starting export for test2.html")


local export = io.open("test2.html", "w+")

io.output(export)

local plotly_header = require "./plotly_header"

io.write(plotly_header)

io.write("<script>\n")
io.write(loader.view_result(grid))
io.write("var data = [{ \n")
io.write('type: "mesh3d",\n')
--Write the X's
io.write('x: [')
for i,v in ipairs(objfile.v) do
	io.write(v.x .. ", ")
end
io.write('],\n');
--Write the Y's
io.write('y: [')
for i,v in ipairs(objfile.v) do
	io.write(v.y .. ", ")
end
io.write('],\n');
--Write the Z's
io.write('z: [')
for i,v in ipairs(objfile.v) do
	io.write(v.z .. ", ")
end
io.write('],\n');
--Write the I's
io.write('i: [')
for i,v in ipairs(objfile.f) do
	io.write(v[1]-1 .. ", ")
end
io.write('],\n');
--Write the J's
io.write('j: [')
for i,v in ipairs(objfile.f) do
	io.write(v[2]-1 .. ", ")
end
io.write('],\n');
--Write the K's
io.write('k: [')
for i,v in ipairs(objfile.f) do
	io.write(v[3]-1 .. ", ")
end
io.write('],\n');

io.write([[
	opacity:0.2,
    color:'rgb(200,100,300)',
	name: 'obj',
	showlegend: true,
}, grid];

var layout = {
  autosize: false,
  width: 1200,
  height: 1000,
  margin: {
    l: 200,
    r: 0,
    b: 0,
    t: 0,
    pad: 4
  },
  showlegend: true,
  legend: {
	x: 1,
	y: 0.5,
   },
};

Plotly.newPlot('myDiv', data, layout);
</script>
]])


io.close(export)

--
-- Break Up(grid): Splits the grid into multiple grids that fit max node bounding box size (-1.5, 1.5)
-- grid = object containing dimensions and vertex values in linear array.
-- the returned groups contains multiple "grids" and has an associated "size" saying how many groups there are
-- Empty resulting boxes are not found at this time.
function loader.breakup(grid, inspect)
	local groups = {}
	local q = 3 --q = cutoff

	--groups.size is the number of broken up boxes along each axis.
	groups.size = {}
	groups.size.x = math.floor((grid.dimensions.x / q)+0.99999)
	groups.size.y = math.floor((grid.dimensions.y / q)+0.99999)
	groups.size.z = math.floor((grid.dimensions.z / q)+0.99999)
	groups.grid = {}
	if(groups.size.x + groups.size.y + groups.size.z ~= q) then
		local index = 1
		--First set up our various grids for being filled with voxels
		for i = 0, groups.size.x-1, 1 do
			for j = 0, groups.size.y-1, 1 do
				for k = 1, groups.size.z, 1 do
					index = k+j*groups.size.z+i*groups.size.z*groups.size.y
					groups.grid[index] = {}
					groups.grid[index].numberOfVoxels = 0
					groups.grid[index].numFilledVoxels = 0
					groups.grid[index].spacing = grid.spacing
					groups.grid[index].voxels = {}
					--Calculate the offsets
					groups.grid[index].offset = {}
					groups.grid[index].offset.x = grid.offset.x + q * (i)
					groups.grid[index].offset.y = grid.offset.y + q * (j)
					groups.grid[index].offset.z = grid.offset.z + q * (k-1)
					--Calculate the dimensions, lessor of full expected length and remaining original grid dimension
					groups.grid[index].dimensions = {}
					groups.grid[index].dimensions.x = math.min(q, grid.dimensions.x - q * i)
					groups.grid[index].dimensions.y = math.min(q, grid.dimensions.y - q * j)
					groups.grid[index].dimensions.z = math.min(q, grid.dimensions.z - q * (k-1))
				end
			end
		end
	--Iterate through all voxels linearly. Assign them to various grids, and give the grid's dimensions....
		local xGridLength = math.floor(grid.dimensions.x/grid.spacing+0.9999999999)
		local yGridLength = math.floor(grid.dimensions.y/grid.spacing+0.9999999999)
		local zGridLength = math.floor(grid.dimensions.z/grid.spacing+0.9999999999)

		--Get the number of voxels in each subdivided q by q by q box
		local voxelLength = {}
		voxelLength.x = q / grid.spacing
		voxelLength.y = q / grid.spacing
		voxelLength.z = q / grid.spacing
		local xGrid, yGrid, ZGrid, ind
		index = 1
		for i = 0, xGridLength-1, 1 do
			xGrid = math.floor(i / voxelLength.x)
			for j = 0, yGridLength-1, 1 do
				yGrid = math.floor(j / voxelLength.y)
				for k = 1, zGridLength, 1 do
					zGrid = math.floor(k / voxelLength.z)
					index = k + j * zGridLength + i * yGridLength * zGridLength --re-doing our array reference :)
					--Now assign the voxel to the associated grid, hopefully the indexes line up correctly....
					ind = 1 + zGrid + yGrid * groups.size.z + xGrid * groups.size.z * groups.size.y
					groups.grid[ind].voxels[groups.grid[ind].numberOfVoxels+1] = grid.voxels[index]
					groups.grid[ind].numberOfVoxels = 1 + groups.grid[ind].numberOfVoxels
					groups.grid[ind].numFilledVoxels = grid.voxels[index] + groups.grid[ind].numFilledVoxels
				end
			end
		end
	else
		groups.grid[1] = grid --Only 1 grid in -1.49->1.49.
	end

	return groups
end

local groups = loader.breakup(grid)

--
--Function view_subdivided_grid(grid,name) exports a single scatter plot of a broken up grid from break_Up
--
--name is the name on hte html file you will see
function loader.view_subdivided_grid(grid,name)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["

	local xGridLength = math.floor(grid.dimensions.x/grid.spacing + 0.99999999)
	local yGridLength = math.floor(grid.dimensions.y/grid.spacing + 0.99999999)
	local zGridLength = math.floor(grid.dimensions.z/grid.spacing + 0.99999999)
	for i = 0, xGridLength-1, 1 do
		for j = 0, yGridLength-1, 1 do
			for k = 1, zGridLength, 1 do
				index = k + j * zGridLength + i * yGridLength * zGridLength--re-doing our array reference :)
				if grid.voxels[index] == 1 then
					xs = xs .. grid.offset.x + i * grid.spacing .. ", "
					ys = ys .. grid.offset.y + j * grid.spacing .. ", "
					zs = zs .. grid.offset.z + (k-1) * grid.spacing .. ", "
				end
			end
		end
	end
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"

	output = output .. "var " .. name .. " = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "mode: 'markers',\n"
	output = output .. "marker: { size: 2},\n"
	output = output .. "name: '" .. name .. "',\n"
	output = output .. "type: 'scatter3d',\n}\n"
	return output
end

print("starting export for test3.html")


local export = io.open("test3.html", "w+")

io.output(export)

local plotly_header = require "./plotly_header"

io.write(plotly_header)

io.write("<script>\n")
io.write(loader.view_result(grid))
--Export all the resulting grids
for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
	io.write(loader.view_subdivided_grid(groups.grid[i], "grid" .. i))
end
io.write("var data = [{ \n")
io.write('type: "mesh3d",\n')
--Write the X's
io.write('x: [')
for i,v in ipairs(objfile.v) do
	io.write(v.x .. ", ")
end
io.write('],\n');
--Write the Y's
io.write('y: [')
for i,v in ipairs(objfile.v) do
	io.write(v.y .. ", ")
end
io.write('],\n');
--Write the Z's
io.write('z: [')
for i,v in ipairs(objfile.v) do
	io.write(v.z .. ", ")
end
io.write('],\n');
--Write the I's
io.write('i: [')
for i,v in ipairs(objfile.f) do
	io.write(v[1]-1 .. ", ")
end
io.write('],\n');
--Write the J's
io.write('j: [')
for i,v in ipairs(objfile.f) do
	io.write(v[2]-1 .. ", ")
end
io.write('],\n');
--Write the K's
io.write('k: [')
for i,v in ipairs(objfile.f) do
	io.write(v[3]-1 .. ", ")
end
io.write('],\n');

io.write([[
	opacity:0.2,
    color:'rgb(200,100,300)',
	name: 'obj',
	showlegend: true,
}, grid
]])

--include the many broken up grids
for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
	io.write(", grid"..i)
end
io.write("];")--end the block

io.write([[
var layout = {
  autosize: false,
  width: 1200,
  height: 1000,
  margin: {
    l: 200,
    r: 0,
    b: 0,
    t: 0,
    pad: 4
  },
  showlegend: true,
  legend: {
	x: 1,
	y: 0.5,
   },
};

Plotly.newPlot('myDiv', data, layout);
</script>
]])

io.close(export)

--
-- boxify(ggroups minfill, minsize) -- takes a group of grid objects of vertexes, and dimensions from de-grid
--
-- and uses a greedy algorithm to combine the vertexes into boxes. Minfill is the minimum percentage filled (70-100% are good numbers)
-- Each resulting box can be. Minsize is a minimum volume a given box can be.

-- This is my own algorithm. Not really optimized, but good results :)
function loader.boxify(groups, minfill, minsize, inspect)
	local boxGroups = {}
	boxGroups.spacing = groups.grid[1].spacing
	boxGroups.size = groups.size
	for a = 0, groups.size.x-1, 1 do
		for b = 0, groups.size.y-1, 1 do
			for c = 1, groups.size.z, 1 do
				local grindex = c+b*groups.size.z+a*groups.size.z*groups.size.y
				--Instantiate a new object to store the resulting boxes
				boxGroups[grindex] = {}
				boxGroups[grindex].numBoxes = 0 --initially
				boxGroups[grindex].boxes = {}
				boxGroups[grindex].offset = groups.grid[grindex].offset


				-----------Now we go through the grid algorithm--------------------

				--First we get the number of voxels along each axis for the grid
				local gridLengths = {}
				gridLengths.x = math.floor(groups.grid[grindex].dimensions.x / groups.grid[grindex].spacing + 0.99999999)
				gridLengths.y = math.floor(groups.grid[grindex].dimensions.y / groups.grid[grindex].spacing + 0.99999999)
				gridLengths.z = math.floor(groups.grid[grindex].dimensions.z / groups.grid[grindex].spacing + 0.99999999)

				--Now we loop through all of the voxels until there are no voxels left after the algorithm eats them
				--Every time we build ourselves a box, we will remove those voxels, we also will reset our search loop back to the
				--beginning so that we research the grid, until finished.
				local i = 0
				local j = 0
				local k = 1
				while (i < gridLengths.x) do
					while (j < gridLengths.y) do
						while (k < gridLengths.z+1) do
							voxeldex = k + j * gridLengths.z + i * gridLengths.z * gridLengths.y

--DELETEME LATER
							local boxNum = boxGroups[grindex].numBoxes

							if groups.grid[grindex].voxels[voxeldex] == 1 then -- Found the first filled voxel
								--Set our start and end corner in voxel coordinates
								local box = {}
								box.start = {}
								box.fin = {}
								box.start.x = i
								box.start.y = j
								box.start.z = k
								box.fin.x = i
								box.fin.y = j
								box.fin.z = k
								box.filled = 1 --number of filled and unfilled voxels in box
								box.unfilled = 0
								--Now to execute our greedy algorithm for the box
								local run_algo = true
								while run_algo do
									local numVoxel = {}
									numVoxel.left 		= 0 --Left = -X
									numVoxel.right 		= 0
									numVoxel.up 		= 0 --Up = +y
									numVoxel.down 		= 0
									numVoxel.forward 	= 0 --Forward = z+
									numVoxel.backward 	= 0

									--Get number of Voxels to the left
									if box.start.x == 1 then --Are we on the edge of our grid?
										numVoxel.left = 0 --Then there's nothing to the left
									else --we aren't so....
										--We need to check what voxels are there
										for up = box.start.y, box.fin.y, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels to the left (1 = filled, 0 = empty)
												numVoxel.left = numVoxel.left + groups.grid[grindex].voxels[forward + up * gridLengths.z + (box.start.x - 1) * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels to the right
									if box.fin.x + 1 == gridLengths.x then --Are we on the edge of our grid?
										numVoxel.right = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for up = box.start.y, box.fin.y, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels to the right (1 = filled, 0 = empty)
												numVoxel.right = numVoxel.right + groups.grid[grindex].voxels[forward + up * gridLengths.z + (box.fin.x + 1) * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels above
									if box.fin.y + 1 == gridLengths.y then --Are we on the edge of our grid?
										numVoxel.up = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.up = numVoxel.up + groups.grid[grindex].voxels[forward + (box.fin.y + 1) * gridLengths.z + right * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels below
									if box.start.y == 1 then --Are we on the edge of our grid?
										numVoxel.down = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.down = numVoxel.down + groups.grid[grindex].voxels[forward + (box.start.y - 1) * gridLengths.z + right * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels forward
									if box.fin.z + 1 == gridLengths.z then --Are we on the edge of our grid?
										numVoxel.forward = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for up = box.start.y, box.fin.y, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.forward = numVoxel.forward + groups.grid[grindex].voxels[box.fin.z + 1 + up * gridLengths.z + right * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels backward
									if box.start.z == 1 then --Are we on the edge of our grid?
										numVoxel.backward = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for up = box.start.y, box.fin.y, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.backward = numVoxel.backward + groups.grid[grindex].voxels[box.start.z - 1 + up * gridLengths.z + right * gridLengths.z * gridLengths.y]
											end
										end
									end

									local remaining = numVoxel
									local finding = true
									local tries = 6
									while tries > 0 and finding do
										local maxVoxel = math.max(remaining.left, remaining.right, remaining.up, remaining.down, remaining.forward, remaining.backward)

									print("MaxVoxel = "..maxVoxel)
									print("NumVoxel = "..inspect(numVoxel))
									print(inspect(box))
									io.stdin:read'*l'

									if numVoxel.left == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.left --number filled voxels
										local unfilled = box.unfilled + (box.fin.y-box.start.y+1)*(box.fin.z-box.start.z+1) - numVoxel.left --number unfilled
										if unfilled == 0 then
											box.start.x = box.start.x - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.start.x = box.start.x - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									if numVoxel.right == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.right --number filled voxels
										local unfilled = box.unfilled + (box.fin.y-box.start.y+1)*(box.fin.z-box.start.z+1) - numVoxel.right --number unfilled
										if unfilled == 0 then
											box.fin.x = box.fin.x + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.fin.x = box.fin.x + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									if numVoxel.up == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.up --number filled voxels
										local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.z-box.start.z+1) - numVoxel.up --number unfilled
										if unfilled == 0 then
											box.fin.y = box.fin.y + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.fin.y = box.fin.y + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									if numVoxel.down == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.down --number filled voxels
										local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.z-box.start.z+1) - numVoxel.down --number unfilled
										if unfilled == 0 then
											box.start.y = box.start.y - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.start.y = box.start.y - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									if numVoxel.backward == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.backward --number filled voxels
										local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.y-box.start.y+1) - numVoxel.backward --number unfilled
										if unfilled == 0 then
											box.start.z = box.start.z - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.start.z = box.start.z - 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									if numVoxel.forward == maxVoxel and finding then --Then let's try left first
										local filled = box.filled + numVoxel.forward --number filled voxels
										local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.y-box.start.y+1) - numVoxel.forward --number unfilled
										if unfilled == 0 then
											box.fin.z = box.fin.z + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										elseif filled/(unfilled+filled) > minfill then --minfill is given to the function, minimum filled voxel in each box
											box.fin.z = box.fin.z + 1 --Grow our box
											box.fin.z = box.fin.z + 1 --Grow our box
											box.filled = filled --Update our filled,unfilled status
											box.unfilled = unfilled
											finding = false --We're done with this iteration
										end
										--If it was less than minfill, let's check the others...
									end

									--Okay so we went through all the directions, did we grow?
									if finding then --Nope....
										--Okay is this a reasonable-sized box? use the function argument :)
										local voxelVolume = (box.fin.z-box.start.z+1) * (box.fin.y-box.start.y+1) * (box.fin.x-box.start.x+1)
										if voxelVolume * groups.grid[grindex].spacing*groups.grid[grindex].spacing*groups.grid[grindex].spacing < minsize then
											--unreasonablly small, delete the respective starting voxel
											groups.grid[grindex].voxels[voxeldex] = 0
											groups.grid[grindex].numberOfVoxels = groups.grid[grindex].numberOfVoxels - 1
										else --Hey we have a good box! let's remove the voxels enclosed and save it
											--delete the voxels
											for right = box.start.x, box.fin.x, 1 do
												for up = box.start.y, box.fin.y, 1 do
													for forward = box.start.z, box.fin.z, 1 do
														groups.grid[grindex].voxels[forward + up * gridLengths.z + right * gridLengths.y * gridLengths.z] = 0
													end
												end
											end
											groups.grid[grindex].numFilledVoxels = groups.grid[grindex].numFilledVoxels - box.filled
											--save box, with spacing adjustments to coutneract tight-fittedness
											box.start.x = box.start.x - 0.5
											box.start.y = box.start.y - 0.5
											box.start.z = box.start.z - 0.5
											box.fin.x = box.fin.x + 0.5
											box.fin.y = box.fin.y + 0.5
											box.fin.z = box.fin.z + 0.5
											boxGroups[grindex].boxes[boxGroups[grindex].numBoxes+1] = box
											boxGroups[grindex].numBoxes = boxGroups[grindex].numBoxes + 1
										end
										run_algo = false --Done with this box
										if boxNum ~= boxGroups[grindex].numBoxes then
											print("Voxels Remaining: " .. groups.grid[grindex].numFilledVoxels)
										end
									end
								end --End algo
								--Now reset the i,j,k back to the beginning
								i = 0
								j = 0
								k = 1
								--We only leave when there are no voxels left...
							end
							k = k + 1
						end
						k = 1
						j = j + 1
					end
					j = 0
					i = i + 1
				end
				-----------End Individual Grid Algorithm----------------------
			end
		end
	end
	return boxGroups
end

local boxGroups = loader.boxify(groups, 0.9, 0.015, inspect)



--
--Function view_boxes(box,name) exports a single box plot from boxify
--
--name is the name on the html file you will see
function loader.view_boxes(box,offset,spacing,name)
	local output = ""--String for plotly
	--strings for x's, y's, z's :)
	local start = box.start
	local fin = box.fin
	start.x = offset.x + start.x * spacing
	start.y = offset.y + start.y * spacing
	start.z = offset.z + start.z * spacing
	fin.x = offset.x + fin.x * spacing
	fin.y = offset.y + fin.y * spacing
	fin.z = offset.z + fin.z * spacing

	local xs = "x: ["
	local ys = "y: ["
	local zs = "z: ["
	xs = xs .. start.x .. ", " .. start.x .. ", " .. fin.x .. ", " .. fin.x .. ", " .. start.x .. ", " .. start.x .. ", " .. fin.x .. ", " .. fin.x .. ", "
	ys = ys .. start.y .. ", " .. fin.y .. ", " .. fin.y .. ", " .. start.y .. ", " .. start.y .. ", " .. fin.y .. ", " .. fin.y .. ", " .. start.y .. ", "
	zs = zs .. start.z .. ", " .. start.z .. ", " .. start.z .. ", " .. start.z .. ", " .. fin.z .. ", " .. fin.z .. ", " .. fin.z .. ", " .. fin.z .. ", "
	xs = xs .. "],\n"
	ys = ys .. "],\n"
	zs = zs .. "],\n"
	--Create output var
	output = output .. "var " .. name .. " = {\n"
	output = output .. xs
	output = output .. ys
	output = output .. zs
	output = output .. "i: [7, 0, 0, 0, 4, 4, 6, 6, 4, 0, 3, 2],\n"
    output = output .. "j: [3, 4, 1, 2, 5, 6, 5, 2, 0, 1, 6, 3],\n"
    output = output .. "k: [0, 7, 2, 3, 6, 7, 1, 1, 5, 5, 7, 6],\n"
	output = output .. "opacity: 0.2, \n"
	output = output .. "color:'rgb(100,100,100)',\n"
	output = output .. "name: '" .. name .. "',\n"
	output = output .. "showlegend: true,\n"
	output = output .. "type: 'mesh3d',\n}\n"
	return output
end

print("starting export for test4.html")


local export = io.open("test4.html", "w+")

io.output(export)

local plotly_header = require "./plotly_header"

io.write(plotly_header)

io.write("<script>\n")
io.write(loader.view_result(grid))
--Export all the resulting grids
--~ for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
--~ 	io.write(loader.view_subdivided_grid(groups.grid[i], "grid" .. i))
--~ end
--Export all the resulting boxes
for i = 1, boxGroups.size.x*boxGroups.size.y*boxGroups.size.z, 1 do
	for j = 1, boxGroups[i].numBoxes, 1 do
		io.write(loader.view_boxes(boxGroups[i].boxes[j], boxGroups[i].offset, boxGroups.spacing, "set" .. i .."box" .. j))
	end
end
io.write("var data = [{ \n")
io.write('type: "mesh3d",\n')
--Write the X's
io.write('x: [')
for i,v in ipairs(objfile.v) do
	io.write(v.x .. ", ")
end
io.write('],\n');
--Write the Y's
io.write('y: [')
for i,v in ipairs(objfile.v) do
	io.write(v.y .. ", ")
end
io.write('],\n');
--Write the Z's
io.write('z: [')
for i,v in ipairs(objfile.v) do
	io.write(v.z .. ", ")
end
io.write('],\n');
--Write the I's
io.write('i: [')
for i,v in ipairs(objfile.f) do
	io.write(v[1]-1 .. ", ")
end
io.write('],\n');
--Write the J's
io.write('j: [')
for i,v in ipairs(objfile.f) do
	io.write(v[2]-1 .. ", ")
end
io.write('],\n');
--Write the K's
io.write('k: [')
for i,v in ipairs(objfile.f) do
	io.write(v[3]-1 .. ", ")
end
io.write('],\n');

io.write([[
	opacity:0.2,
    color:'rgb(200,100,300)',
	name: 'obj',
	showlegend: true,
}, grid
]])

--include the many broken up grids
--~ for i = 1, groups.size.x*groups.size.y*groups.size.z, 1 do
--~ 	io.write(", grid"..i)
--~ end
for i = 1, boxGroups.size.x*boxGroups.size.y*boxGroups.size.z, 1 do
	for j = 1, boxGroups[i].numBoxes, 1 do
		io.write(", set" .. i.."box" .. j)
	end
end
io.write("];")--end the block

io.write([[
var layout = {
  autosize: false,
  width: 1200,
  height: 1000,
  margin: {
    l: 200,
    r: 0,
    b: 0,
    t: 0,
    pad: 4
  },
  showlegend: true,
  legend: {
	x: 1,
	y: 0.5,
   },
};

Plotly.newPlot('myDiv', data, layout);
</script>
]])

io.close(export)


--
-- Export Minetest Readable data
--

local objfile = loader.deref(loader.load("models/spike.obj"))

local export = io.open("test.lua", "w+")

io.output(export)

io.write(inspect(objfile))

io.close(export)

