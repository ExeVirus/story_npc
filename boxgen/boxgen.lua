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

local export = io.open("test.lua", "w+")

io.output(export)

io.write(inspect(loader.load("models/flat.obj")))

io.close(export)
