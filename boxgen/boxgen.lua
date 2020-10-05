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
	grid.numberOfVoxels = index
	grid.numberOfFilledVoxels = indexverts

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
		local xGridLength = math.floor(grid.dimensions.x/grid.spacing)
		local yGridLength = math.floor(grid.dimensions.y/grid.spacing)
		local zGridLength = math.floor(grid.dimensions.z/grid.spacing)
		index = 1
		for i = 0, xGridLength-1, 1 do
			for j = 0, yGridLength-1, 1 do
				for k = 1, zGridLength, 1 do
					index = k + j * zGridLength + i * yGridLength * zGridLength--re-doing our array reference :)
				end
			end
		end
	else
		groups.grid[1] = grid --Only 1 grid in -1.49->1.49.
	end

	return groups
end

loader.breakup(grid, inspect)

--
-- boxify(grid, minfill, minsize) -- takes grid object of vertexes, and dimensions from de-grid
--
-- and uses a greedy algorithm to combine the vertexes into boxes. Minfill is the minimum percentage filled
-- Each resulting box can be (70-100% are good numbers). Minsize is a minimum volume a given box can be.

-- My own algorithm


function loader.boxify(grid, minfill, minsize)
	local clusters = {}

	return clusters
end


--
-- Bound - Generates best fit bounding boxes for the provided clusters of points
-- (must be larger than a certain default size, otherwise it's discarded.
-- according to quality values for including space or filled spots
-- any points not included are added to a "unused" array
--

function loader.bound(clusters, minsize, fillQ, unfillQ)
	local bounds = {}
	local leftovers = {}

	return bounds, leftovers
end

--
-- Re-run leftovers through loader.cluster and loader.bound until complete.
--

--
-- Save all bounding boxes for the given -1.49 -> 1.49 area
--

--
--Repeat for every -1.49->1.49 area
--






--
-- Export Javascript viewing file
-- (subplots)


--
-- Export Minetest Readable data
--

local objfile = loader.deref(loader.load("models/spike.obj"))

local export = io.open("test.lua", "w+")

io.output(export)

io.write(inspect(objfile))

io.close(export)

