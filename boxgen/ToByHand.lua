package.path = "../?.lua;" .. package.path
local inspect = require "./inspect"
local export = require "./export"

local f = io.open("data.box", "rb")
local data = export.deserialize(f:read("*all"))
io.close(f)

if data.numNodes > 1 then
	print("\n\n\n\tWARNING: the box data you are converting from is outside the")
	print("\tMinetest limits for collision box size: (-1.5,-1.5,-1.5,1.5,1.5,1.5)")
	print("\tThe resulting collision box you will see will be limited to that area\n")
end

print("Please enter a filename to export the defined boxes to: ")
local filename = io.read()

local f = io.open(filename, "w+")
io.output(f)
io.write([[
Please copy and paste the single line of boxes you see below to your minetest.register_node definition
Like so:

	.
	.
	.
	collision_box = {
				type = "fixed",
				fixed = <really long string>
			},
	selection_box = {
				type = "fixed",
				fixed = <really long string>
			},
	.
	.
	.

The line you need to copy is right below here:

]]) 
io.write(data.nodes[1].boxList)
io.close(f)