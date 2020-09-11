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

io.write("<script>")
io.write("var trace1 = JSON.parse(")
--Write the object
io.write([[{"x": []])
for i,v in ipairs(loader.deref(objfile)) do
 	io.write('"' .. v .. "\n")
end




io.write([[);
var data = [trace1];
var layout = {margin: {
		l: 0
		r: 0
		b: 0
		t: 0
	});
Plotly.newPlot('myDiv', data, layout);
});
</script>
]])

--io.write(inspect(objfile))

io.close(export)

local export2 = io.open("test2.lua", "w+")

io.output(export2)

for i,v in ipairs(loader.deref(objfile)) do
 	io.write(i .. "\n" .. inspect(v) .. "\n")
end

io.close(export2)


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
-- align the voxe-grid later

-- Next, each voxel center-point is ray cast in the positive X direction
--      Based on the number of triangle intersections we determine if
--      we are inside or outside the object(s)
-- Using this information, mark the voxel inside or outside.

-- Finally, we return our resulting voxel grid

function loader.voxelize(object, spacing)
	local grid = {}

	return grid
end

--
-- Degrid(grid) -- parses all filled grid values into single array of vertexes
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

