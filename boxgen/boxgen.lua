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



local objfile = loader.load("models/flat.obj")

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

function raycast( x,y,z, triangle)

	return 1
end


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
	local index = 1
	grid.spacing = spacing
	if(spacing < grid.dimensions.x and spacing < grid.dimensions.y and spacing < grid.dimensions.z) then
		for i = grid.offset.x, grid.offset.x+grid.dimensions.x, spacing do
			for j = grid.offset.y, grid.offset.y+grid.dimensions.y, spacing do
				for k = grid.offset.z, grid.offset.z+grid.dimensions.z, spacing do
					--Now to check each point and see if it is insize or outside our object
					-- (i,j,k) = point
					local count = 0
					for i, v in ipairs(object) do
						count = count + raycast(i,j,k,v)
					end
					if ( count % 2 == 0) then
						grid.voxels[index] = 0
						--we are outside
					else
						grid.voxels[index] = 1
						--we are inside
					end
					index = index + 1
				end
			end
		end
	end

	return grid
end

print(inspect(loader.voxelize(loader.deref(objfile),0.1)))

--loader.voxelize(loader.deref(objfile),0.1)
--
-- Degrid(grid) -- parses all filled grid values into single array of vertexes (For viewing)
--


function loader.degrid(grid)
	local array = {}

	return array
end

--
-- Cluster(array, k) -- takes array of vertexes from de-grid
--
-- and calculates *k* means of the dataset and groups the vertexes
-- to these means, adding a fourth value for the mean-number

-- https://towardsdatascience.com/the-5-clustering-algorithms-data-scientists-need-to-know-a36d136ef68


function loader.cluster(array, k)
	local clusters
end


local objfile = loader.deref(loader.load("models/flat.obj"))

local export = io.open("test.lua", "w+")

io.output(export)

io.write(inspect(objfile))

io.close(export)

