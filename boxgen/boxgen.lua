local boxgen = {}

local vector = require("vector")
local inspect = require("inspect")

function boxgen.load(file)
	assert(file_exists(file), "File not found: " .. file)

	local get_lines = io.lines
	local lines = {}

	for line in get_lines(file) do
		table.insert(lines, line)
	end

	return boxgen.parse(lines)
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

function boxgen.parse(object)
	local obj = {
		v	= {}, -- List of vertices - x, y, z, [w]=1.0
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

--
-- Offset will take in x,y,z values to offset to 
-- and output a new .obj with verticies moved by that offset
function boxgen.offset(file,outfile,x,y,z)
    assert(file_exists(file), "File not found: " .. file)
    
    
    local export = io.open(outfile, "w+") --Open file for writing
    io.output(export)
    
    local get_lines = io.lines
    
    for line in get_lines(file) do
        --Edit each line before saving the line to our output
        local l = string_split(line, "%s+")
        if l[1] == "v" then
            line = "v ".. tonumber(l[2])+x .. " " .. tonumber(l[3])+y .. " " .. tonumber(l[4])+z .. "\n"
        else
            line = line .. "\n"
        end
        
        --output the line
        io.write(line) 
	end
    
    io.close(export)
end

function boxgen.deref(object)
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



-- function boxgen.Bounding Box -----------------
--
--  args: object (table of triangles and vertices, dereferenced)
--
--  returns: (table) offset {x,y,z}
--  		 (table) dimensions {w,h,d}

function boxgen.boundingBox( object )
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
-- boxgen.voxelize( object, spacing )
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

function boxgen.voxelize(object, spacing, relocate, reposition)
	local grid = {}
	grid.offset, grid.dimensions = boxgen.boundingBox( object )
    
    if relocate == false then --Adjust for repositioning 
        --This will essentially create more empty voxels, but that helps later when 
        --we are adding up empty space :)
        grid.dimensions.x = grid.dimensions.x + math.abs(reposition.x)
        grid.dimensions.y = grid.dimensions.y + math.abs(reposition.y)
        grid.dimensions.z = grid.dimensions.z + math.abs(reposition.z)
        grid.offset.x = grid.offset.x - math.max(0, reposition.x)
        grid.offset.y = grid.offset.y - math.max(0, reposition.y)
        grid.offset.z = grid.offset.z - math.max(0, reposition.z)
    end
	--Note: if you're spacing is too large, the object will 100% fail to be voxelized in a useful manner. You
	--need at least 2 points in all directions to make a box. 1 point in any direction doesn't cut it.
	grid.voxels = {}
	grid.voxel_verts = {}
	local index = 1
	local indexverts = 1
	grid.spacing = spacing
	if(spacing < grid.dimensions.x and spacing < grid.dimensions.y and spacing < grid.dimensions.z) then

		for i = 0, grid.dimensions.x/spacing, 1 do
			for j = 0, grid.dimensions.y/spacing, 1 do
				for k = 0, grid.dimensions.z/spacing, 1 do
					--Now to check each point and see if it is insize or outside our object
					-- (i,j,k) = point
					local count = 0
					for q, v in ipairs(object) do
						count = count + raycast(grid.offset.x+i*spacing,grid.offset.y+j*spacing,grid.offset.z+k*spacing,v)
					end
					if ( count % 2 == 0) then
						grid.voxels[index] = 0
						--we are outside
					else
						grid.voxels[index] = 1
						grid.voxel_verts[indexverts] = vector.new( grid.offset.x+i*spacing, grid.offset.y+j*spacing, grid.offset.z+k*spacing)
						indexverts = indexverts + 1
						--we are inside
					end
					index = index + 1
				end
			end
			print( i / (grid.dimensions.x / spacing) * 100 .. "% complete")
		end
	end
	grid.numberOfVoxels = index - 1
	grid.numberOfFilledVoxels = indexverts - 1

	return grid
end

--
-- Modulo - Respects signs
--
function boxgen.modulo(a, b)
    local retval = math.abs(a) % b
    local sign = (a > 0 and 1 or (a == 0 and 0 or -1))
    return retval * sign
end


--
-- Break Up(grid): Splits the grid into multiple grids that fit max node bounding box size (-1.5, 1.5)
-- grid = object containing dimensions and vertex values in linear array.
-- the returned groups contains multiple "grids" and has an associated "size" saying how many groups there are
-- Empty resulting boxes are not found at this time.
function boxgen.breakup(grid, inspect, relocate, reposition)
	local groups = {}
	local q = 3 --q = cutoff

	--groups.size is the number of broken up boxes along each axis.
	groups.size = {}
    if relocate == false then
        if math.abs(reposition.x) % q > 0.0001 and reposition.x < 0 then 
            groups.size.x = math.floor((grid.dimensions.x / q))+2
        else
            groups.size.x = math.floor((grid.dimensions.x / q))+1
        end
        if math.abs(reposition.y) % q > 0.0001 and reposition.y < 0 then 
            groups.size.y = math.floor((grid.dimensions.y / q))+2
        else
            groups.size.y = math.floor((grid.dimensions.y / q))+1
        end
        if math.abs(reposition.z) % q > 0.0001 and reposition.z < 0 then 
            groups.size.z = math.floor((grid.dimensions.z / q))+2
        else
            groups.size.z = math.floor((grid.dimensions.z / q))+1
        end
    else
        groups.size.x = math.floor((grid.dimensions.x / q))+1
        groups.size.y = math.floor((grid.dimensions.y / q))+1
        groups.size.z = math.floor((grid.dimensions.z / q))+1
    end
	groups.grid = {}
	if (groups.size.x + groups.size.y + groups.size.z ~= q) then
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
                    if relocate == false then
                        if grid.offset.x < -1.5 then 
                            if i == 0 then
                                groups.grid[index].offset.x = grid.offset.x
                            else
                                groups.grid[index].offset.x = grid.offset.x + q * (i-1) - boxgen.modulo(reposition.x,q)
                            end
                        else
                            groups.grid[index].offset.x = grid.offset.x + q * (i)
                        end
                        if grid.offset.y < -1.5 then 
                            if j == 0 then
                                groups.grid[index].offset.y = grid.offset.y
                            else
                                groups.grid[index].offset.y = grid.offset.y + q * (j-1) - boxgen.modulo(reposition.y,q)
                            end
                        else
                            groups.grid[index].offset.y = grid.offset.y + q * (j)
                        end
                        if grid.offset.z < -1.5 then 
                            if k == 1 then
                                groups.grid[index].offset.z = grid.offset.z
                            else
                                groups.grid[index].offset.z = grid.offset.z + q * (k-2) - boxgen.modulo(reposition.z,q)
                            end
                        else
                            groups.grid[index].offset.z = grid.offset.z + q * (k-1)
                        end
                    else
                        groups.grid[index].offset.x = grid.offset.x + q * (i)
                        groups.grid[index].offset.y = grid.offset.y + q * (j)
                        groups.grid[index].offset.z = grid.offset.z + q * (k-1)
                    end
					--calculate the starting position of the first point for this grid
					groups.grid[index].position = {}
                    if relocate == false then
                        if grid.offset.x < -1.5 then
                            if i == 0 then
                                groups.grid[index].position.x = 0
                            else
                                groups.grid[index].position.x = boxgen.modulo(reposition.x, grid.spacing) + grid.spacing
                            end
                        else
                            groups.grid[index].position.x = (math.floor((groups.grid[index].offset.x - groups.grid[1].offset.x) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.x - groups.grid[1].offset.x)
                            if math.abs(groups.grid[index].position.x - grid.spacing) < 0.0001 then --0.0001 is epsilon because I do so much multiplication above ^^^
                                groups.grid[index].position.x = 0
                            end
                        end
                        if grid.offset.y < -1.5 then
                            if j == 0 then
                                groups.grid[index].position.y = 0
                            else
                                groups.grid[index].position.y = boxgen.modulo(reposition.y, grid.spacing) + grid.spacing
                            end
                        else                        
                            groups.grid[index].position.y = (math.floor((groups.grid[index].offset.y - groups.grid[1].offset.y) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.y - groups.grid[1].offset.y)
                            if math.abs(groups.grid[index].position.y - grid.spacing) < 0.0001 then
                                groups.grid[index].position.y = 0
                            end
                        end
                        if grid.offset.z < -1.5 then
                            if k == 1 then
                                groups.grid[index].position.z = 0
                            else
                                groups.grid[index].position.z = boxgen.modulo(reposition.z, grid.spacing) + grid.spacing
                            end
                        else
                            groups.grid[index].position.z = (math.floor((groups.grid[index].offset.z - groups.grid[1].offset.z) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.z - groups.grid[1].offset.z)
                            if math.abs(groups.grid[index].position.z - grid.spacing) < 0.0001 then
                                groups.grid[index].position.z = 0
                            end
                        end
					else
                        groups.grid[index].position.x = (math.floor((groups.grid[index].offset.x - groups.grid[1].offset.x) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.x - groups.grid[1].offset.x)
                        groups.grid[index].position.y = (math.floor((groups.grid[index].offset.y - groups.grid[1].offset.y) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.y - groups.grid[1].offset.y)
                        groups.grid[index].position.z = (math.floor((groups.grid[index].offset.z - groups.grid[1].offset.z) / grid.spacing)+1) * grid.spacing - (groups.grid[index].offset.z - groups.grid[1].offset.z)
                        if math.abs(groups.grid[index].position.x - grid.spacing) < 0.0001 then --0.0001 is epsilon because I do so much multiplication above ^^^
                            groups.grid[index].position.x = 0
                        end
                        if math.abs(groups.grid[index].position.y - grid.spacing) < 0.0001 then
                            groups.grid[index].position.y = 0
                        end
                        if math.abs(groups.grid[index].position.z - grid.spacing) < 0.0001 then
                            groups.grid[index].position.z = 0
                        end
                    end
					--Calculate the dimensions, lessor of full expected length and remaining original grid dimension
					groups.grid[index].dimensions = {}
                    if relocate == false then
                        --Need to account for the first rows being shorter, and last rows being longer.
                        if i == 0 then --first row of x
                            if math.abs(reposition.x) % q ~= 0 and reposition.x < 0 then --It's less than full width
                                groups.grid[index].dimensions.x = -boxgen.modulo(reposition.x, q)
                            else
                                groups.grid[index].dimensions.x = math.min(q, grid.dimensions.x - q * i)
                            end
                        else
                            groups.grid[index].dimensions.x = math.min(q, grid.dimensions.x - q * (i-1) - groups.grid[1].dimensions.x)
                        end
                        if j == 0 then --first row of y
                            if math.abs(reposition.y) % q ~= 0 and reposition.y < 0 then --It's less than full width
                                groups.grid[index].dimensions.y = -boxgen.modulo(reposition.y, q)
                            else
                                groups.grid[index].dimensions.y = math.min(q, grid.dimensions.y - q * j)
                            end
                        else
                            groups.grid[index].dimensions.y = math.min(q, grid.dimensions.y - q * (j-1) - groups.grid[1].dimensions.y)
                        end
                        if k == 1 then --first row of z
                            if math.abs(reposition.z) % q ~= 0 and reposition.z < 0 then --It's less than full width
                                groups.grid[index].dimensions.z = -boxgen.modulo(reposition.z, q)
                            else
                                groups.grid[index].dimensions.z = math.min(q, grid.dimensions.z - q * (k-1))
                            end
                        else
                            groups.grid[index].dimensions.y = math.min(q, grid.dimensions.y - q * (k-2) - groups.grid[1].dimensions.z)
                        end
                    else 
                        groups.grid[index].dimensions.x = math.min(q, grid.dimensions.x - q * i)
                        groups.grid[index].dimensions.y = math.min(q, grid.dimensions.y - q * j)
                        groups.grid[index].dimensions.z = math.min(q, grid.dimensions.z - q * (k-1))
					end
                    
                    --Set the gridLengths:
					groups.grid[index].lengths = {}
					groups.grid[index].lengths.x = 0
					groups.grid[index].lengths.y = 0
					groups.grid[index].lengths.z = 0
					--Set the grid start and end
					groups.grid[index].start = {}
					groups.grid[index].fin = {}
				end
			end
		end
	--Iterate through all voxels linearly. Assign them to various grids, and give the grid's dimensions....
		local xGridLength = math.floor(grid.dimensions.x/grid.spacing)+1
		local yGridLength = math.floor(grid.dimensions.y/grid.spacing)+1
		local zGridLength = math.floor(grid.dimensions.z/grid.spacing)+1

		--Get the number of voxels in each subdivided q by q by q box
		local voxelLength = {}
		voxelLength.x = q / grid.spacing
		voxelLength.y = q / grid.spacing
		voxelLength.z = q / grid.spacing

		local xGrid, yGrid, ZGrid, ind
		index = 1
        
        if relocate == false then
            for i = 0, xGridLength-1, 1 do
                if groups.grid[1].dimensions.x < q and groups.size.x > 1 then
                    if i*grid.spacing < groups.grid[1].dimensions.x then --If we are in the skinny section
                        xGrid = 0 --Xgrid is zero
                    else --Otherwise
                        xGrid = math.floor((i * grid.spacing-groups.grid[1].dimensions.x) / q)+1 -- we are at least at one, and should start counting beyond teh first dimensions
                    end
                else
                    xGrid = math.floor(i * grid.spacing / q)
                end
                for j = 0, yGridLength-1, 1 do			--Meaning that we should start counting NOT including that very first voxel
                    if groups.grid[1].dimensions.y < q and groups.size.y > 1 then
                        if j*grid.spacing < groups.grid[1].dimensions.y then --If we are in the skinny section
                            yGrid = 0 --Ygrid is zero
                        else --Otherwise
                            yGrid = math.floor((j * grid.spacing-groups.grid[1].dimensions.y) / q)+1 -- we are at least at one, and should start counting beyond teh first dimensions
                        end
                    else
                        yGrid = math.floor(j * grid.spacing / q)
                    end
                    for k = 1, zGridLength, 1 do
                        if groups.grid[1].dimensions.z < q and groups.size.z > 1 then
                            if (k-1)*grid.spacing < groups.grid[1].dimensions.z then --If we are in the skinny section
                                zGrid = 0 --Ygrid is zero
                            else --Otherwise
                                zGrid = math.floor(((k-1) * grid.spacing-groups.grid[1].dimensions.z) / q)+1 -- we are at least at one, and should start counting beyond teh first dimensions
                            end
                        else
                            zGrid = math.floor((k-1) * grid.spacing / q)
                        end
                        index = k + j * zGridLength + i * yGridLength * zGridLength --re-doing our array reference :)
                        --Now assign the voxel to the associated grid, hopefully the indexes line up correctly....
                        ind = 1 + zGrid + yGrid * groups.size.z + xGrid * groups.size.z * groups.size.y
                        if groups.grid[ind].numberOfVoxels == 0 then
                            groups.grid[ind].start.x = i+1
                            groups.grid[ind].start.y = j+1
                            groups.grid[ind].start.z = k
                            groups.grid[ind].fin.x = i+1
                            groups.grid[ind].fin.y = j+1
                            groups.grid[ind].fin.z = k
                        end
                        groups.grid[ind].voxels[groups.grid[ind].numberOfVoxels+1] = grid.voxels[index]
                        groups.grid[ind].numberOfVoxels = 1 + groups.grid[ind].numberOfVoxels
                        groups.grid[ind].numFilledVoxels = grid.voxels[index] + groups.grid[ind].numFilledVoxels

                        --Now updated ends of this grid
                        groups.grid[ind].fin.x = math.max(i+1, groups.grid[ind].fin.x)
                        groups.grid[ind].fin.y = math.max(j+1, groups.grid[ind].fin.y)
                        groups.grid[ind].fin.z = math.max(k, groups.grid[ind].fin.z)
                    end
                end
            end
        else
            for i = 0, xGridLength-1, 1 do
                xGrid = math.floor(i * grid.spacing / q)
                for j = 0, yGridLength-1, 1 do			--Meaning that we should start counting NOT including that very first voxel
                    yGrid = math.floor(j * grid.spacing / q)
                    for k = 1, zGridLength, 1 do
                        zGrid = math.floor((k-1) * grid.spacing / q) --Since k starts at 1, we must subtract 1 from k here to get the correct grid
                        index = k + j * zGridLength + i * yGridLength * zGridLength --re-doing our array reference :)
                        --Now assign the voxel to the associated grid, hopefully the indexes line up correctly....
                        ind = 1 + zGrid + yGrid * groups.size.z + xGrid * groups.size.z * groups.size.y
                        if groups.grid[ind].numberOfVoxels == 0 then
                            groups.grid[ind].start.x = i+1
                            groups.grid[ind].start.y = j+1
                            groups.grid[ind].start.z = k
                            groups.grid[ind].fin.x = i+1
                            groups.grid[ind].fin.y = j+1
                            groups.grid[ind].fin.z = k
                        end
                        groups.grid[ind].voxels[groups.grid[ind].numberOfVoxels+1] = grid.voxels[index]
                        groups.grid[ind].numberOfVoxels = 1 + groups.grid[ind].numberOfVoxels
                        groups.grid[ind].numFilledVoxels = grid.voxels[index] + groups.grid[ind].numFilledVoxels

                        --Now updated ends of this grid
                        groups.grid[ind].fin.x = math.max(i+1, groups.grid[ind].fin.x)
                        groups.grid[ind].fin.y = math.max(j+1, groups.grid[ind].fin.y)
                        groups.grid[ind].fin.z = math.max(k, groups.grid[ind].fin.z)
                    end
                end
            end
        end
		--Now update the resulting grid axis lengths
		for i = 0, groups.size.x-1, 1 do
			for j = 0, groups.size.y-1, 1 do
				for k = 1, groups.size.z, 1 do
					index = k+j*groups.size.z+i*groups.size.z*groups.size.y
					if(groups.grid[index].numberOfVoxels ~= 0) then
						groups.grid[index].lengths.x = groups.grid[index].fin.x - groups.grid[index].start.x + 1
						groups.grid[index].lengths.y = groups.grid[index].fin.y - groups.grid[index].start.y + 1
						groups.grid[index].lengths.z = groups.grid[index].fin.z - groups.grid[index].start.z + 1
					end
				end
			end
		end
	else
		groups.grid[1] = grid --Only 1 grid in -1.5->1.5.
		groups.grid[1].position = {}
		groups.grid[1].position.x = 0
		groups.grid[1].position.y = 0
		groups.grid[1].position.z = 0
		groups.grid[1].lengths = {}
		groups.grid[1].lengths.x = math.floor(grid.dimensions.x/grid.spacing)+1
		groups.grid[1].lengths.y = math.floor(grid.dimensions.y/grid.spacing)+1
		groups.grid[1].lengths.z = math.floor(grid.dimensions.z/grid.spacing)+1
		groups.grid[1].numFilledVoxels = grid.numberOfFilledVoxels
	end

	return groups
end


--
-- boxify(ggroups minfill, minsize, minqual) -- takes a group of grid objects of vertexes, and dimensions from de-grid
--
-- and uses a greedy algorithm to combine the vertexes into boxes. Minfill is the minimum percentage filled (70-100% are good numbers)
-- Each resulting box can be. Minsize is a minimum volume a given box can be. MinQual is the minimum ratio of filled to unfill that can be added to a given box

-- This is my own algorithm. Not really optimized, but good results :)
function boxgen.boxify(groups, minfill, minsize, minqual, inspect)
	local boxGroups = {}
	boxGroups.spacing = groups.grid[1].spacing
	boxGroups.size = groups.size
	for a = 0, groups.size.x-1, 1 do
		for b = 0, groups.size.y-1, 1 do
			for c = 1, groups.size.z, 1 do
				local grindex = c+b*groups.size.z+a*groups.size.z*groups.size.y

				print(groups.grid[grindex].numberOfVoxels)

				--Instantiate a new object to store the resulting boxes
				boxGroups[grindex] = {}
				boxGroups[grindex].numBoxes = 0 --initially
				boxGroups[grindex].boxes = {}
				boxGroups[grindex].offset = {}
				boxGroups[grindex].offset.x = groups.grid[grindex].offset.x + groups.grid[grindex].position.x
				boxGroups[grindex].offset.y = groups.grid[grindex].offset.y + groups.grid[grindex].position.y
				boxGroups[grindex].offset.z = groups.grid[grindex].offset.z + groups.grid[grindex].position.z
                boxGroups[grindex].dimension = {}
                boxGroups[grindex].dimension.x = groups.grid[grindex].lengths.x * boxGroups.spacing
                boxGroups[grindex].dimension.y = groups.grid[grindex].lengths.y * boxGroups.spacing
                boxGroups[grindex].dimension.z = groups.grid[grindex].lengths.z * boxGroups.spacing
                
				-----------Now we go through the grid algorithm--------------------

				--First we get the number of voxels along each axis for the grid
				local gridLengths = {}
				gridLengths.x = groups.grid[grindex].lengths.x
				gridLengths.y = groups.grid[grindex].lengths.y
				gridLengths.z = groups.grid[grindex].lengths.z

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

							local boxNum = boxGroups[grindex].numBoxes

							if groups.grid[grindex].voxels[voxeldex] == 1 then -- Found the first filled voxel
								--Set our start and end corner in voxel coordinates
								local box = {}
								box.start = {}
								box.fin = {}
								box.start.x = i+1 --start at 1
								box.start.y = j+1
								box.start.z = k
								box.fin.x = i+1 --end at 1
								box.fin.y = j+1
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
												numVoxel.left = numVoxel.left + groups.grid[grindex].voxels[forward + (up-1) * gridLengths.z + (box.start.x - 2) * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels to the right
									if box.fin.x == gridLengths.x then --Are we on the edge of our grid?
										numVoxel.right = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for up = box.start.y, box.fin.y, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels to the right (1 = filled, 0 = empty)
												if groups.grid[grindex].numFilledVoxels == -10 then
													print(grindex)
													print(inspect(gridLengths))
													print(inspect(box))
													print("foward: " .. forward .. " up: " .. up .. " box.fin.x: " .. box.fin.x)
													print(forward + (up-1) * gridLengths.z + (box.fin.x) * gridLengths.z * gridLengths.y)
													print(groups.grid[grindex].numberOfVoxels)
													io.stdin:read"*l"
												end
												numVoxel.right = numVoxel.right + groups.grid[grindex].voxels[forward + (up-1) * gridLengths.z + (box.fin.x) * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels above
									if box.fin.y == gridLengths.y then --Are we on the edge of our grid?
										numVoxel.up = 0 --Then there's nothing to the right
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for forward = box.start.z, box.fin.z, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.up = numVoxel.up + groups.grid[grindex].voxels[forward + (box.fin.y) * gridLengths.z + (right-1) * gridLengths.z * gridLengths.y]
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
												numVoxel.down = numVoxel.down + groups.grid[grindex].voxels[forward + (box.start.y - 2) * gridLengths.z + (right-1) * gridLengths.z * gridLengths.y]
											end
										end
									end

									--Get number of Voxels forward
									if box.fin.z == gridLengths.z then --Are we on the edge of our grid?
										numVoxel.forward = 0 --Then there's nothing in front
									else --we aren't so....
										--We need to check what voxels are there
										for right = box.start.x, box.fin.x, 1 do
											for up = box.start.y, box.fin.y, 1 do
												--Add the current voxel to the number of voxels above (1 = filled, 0 = empty)
												numVoxel.forward = numVoxel.forward + groups.grid[grindex].voxels[box.fin.z + 1 + (up-1) * gridLengths.z + (right-1) * gridLengths.z * gridLengths.y]
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
												numVoxel.backward = numVoxel.backward + groups.grid[grindex].voxels[box.start.z - 1 + (up-1) * gridLengths.z + (right-1) * gridLengths.z * gridLengths.y]
											end
										end
									end

									local remaining = numVoxel
									local finding = true
									local tries = 6
									while tries > 0 and finding do
										local maxVoxel = math.max(remaining.left, remaining.right, remaining.up, remaining.down, remaining.forward, remaining.backward)
										if maxVoxel == 0 and finding then
											maxVoxel = -2
											tries = 0
										end

										if remaining.left == maxVoxel and finding then --Then let's try left first
											local filled = box.filled + numVoxel.left --number filled voxels
											local unfilled = box.unfilled + (box.fin.y-box.start.y+1)*(box.fin.z-box.start.z+1) - numVoxel.left --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.start.x = box.start.x - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.start.x = box.start.x - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill or less than minqual, remove from search list and let's check the others...
											remaining.left = -1
											tries = tries - 1
										end

										if remaining.right == maxVoxel and finding then --Then right
											local filled = box.filled + numVoxel.right --number filled voxels
											local unfilled = box.unfilled + (box.fin.y-box.start.y+1)*(box.fin.z-box.start.z+1) - numVoxel.right --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.fin.x = box.fin.x + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.fin.x = box.fin.x + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill or less than minqual, remove from search list and let's check the others...
											remaining.right = -1
											tries = tries - 1
										end

										if remaining.up == maxVoxel and finding then --Then up
											local filled = box.filled + numVoxel.up --number filled voxels
											local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.z-box.start.z+1) - numVoxel.up --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.fin.y = box.fin.y + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.fin.y = box.fin.y + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill, remove from search list and let's check the others...
											remaining.up = -1
											tries = tries - 1
										end

										if remaining.down == maxVoxel and finding then --Then down
											local filled = box.filled + numVoxel.down --number filled voxels
											local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.z-box.start.z+1) - numVoxel.down --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.start.y = box.start.y - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.start.y = box.start.y - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill, remove from search list and let's check the others...
											remaining.down = -1
											tries = tries - 1
										end

										if remaining.backward == maxVoxel and finding then --Then backward
											local filled = box.filled + numVoxel.backward --number filled voxels
											local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.y-box.start.y+1) - numVoxel.backward --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.start.z = box.start.z - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.start.z = box.start.z - 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill, remove from search list and let's check the others...
											remaining.backward = -1
											tries = tries - 1
										end

										if remaining.forward == maxVoxel and finding then --Then forward
											local filled = box.filled + numVoxel.forward --number filled voxels
											local unfilled = box.unfilled + (box.fin.x-box.start.x+1)*(box.fin.y-box.start.y+1) - numVoxel.forward --number unfilled
											local quality = (filled-box.filled) / (filled-box.unfilled)
											if unfilled == 0 then
												box.fin.z = box.fin.z + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											elseif filled/(unfilled+filled) > minfill and quality > minqual then --minfill is given to the function, minimum filled voxel in each box
												box.fin.z = box.fin.z + 1 --Grow our box
												box.filled = filled --Update our filled,unfilled status
												box.unfilled = unfilled
												finding = false --We're done with this iteration
											end
											--If it was less than minfill, remove from search list and let's check the others...
											remaining.forward = -1
											tries = tries - 1
										end
									end --End Tries While loop

									--Okay so we went through all the directions, did we grow?
									if finding then --Nope....
										--Okay is this a reasonable-sized box? use the function argument :)
										local voxelVolume = (box.fin.z-box.start.z+1) * (box.fin.y-box.start.y+1) * (box.fin.x-box.start.x+1)
										if voxelVolume * groups.grid[grindex].spacing*groups.grid[grindex].spacing*groups.grid[grindex].spacing < minsize then
											--unreasonablly small, delete the respective starting voxel
											groups.grid[grindex].voxels[voxeldex] = 0
											groups.grid[grindex].numFilledVoxels = groups.grid[grindex].numFilledVoxels - 1
											print("Voxels Remaining: " .. groups.grid[grindex].numFilledVoxels)
										else --Hey we have a good box! let's remove the voxels enclosed and save it
											--delete the voxels
											for right = box.start.x, box.fin.x, 1 do
												for up = box.start.y, box.fin.y, 1 do
													for forward = box.start.z, box.fin.z, 1 do
														groups.grid[grindex].voxels[forward + (up-1) * gridLengths.z + (right-1) * gridLengths.y * gridLengths.z] = 0
													end
												end
											end
											groups.grid[grindex].numFilledVoxels = groups.grid[grindex].numFilledVoxels - box.filled
											--save box, with spacing adjustments to counteract tight-fittedness
											box.start.x = box.start.x - 0.5
											box.start.y = box.start.y - 0.5
											box.start.z = box.start.z - 0.5
											box.fin.x = box.fin.x + 0.5
											box.fin.y = box.fin.y + 0.5
											box.fin.z = box.fin.z + 0.5
                                            boxGroups[grindex].numBoxes = boxGroups[grindex].numBoxes + 1
											boxGroups[grindex].boxes[boxGroups[grindex].numBoxes] = box
											
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

return boxgen
