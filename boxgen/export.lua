local vector = require("vector")
local inspect = require "./inspect"
--- Lua module to serialize values as Lua code.
-- From: https://github.com/fab13n/metalua/blob/no-dll/src/lib/serialize.lua
-- License: MIT
-- @copyright 2006-2997 Fabien Fleutot <metalua@gmail.com>
-- @author Fabien Fleutot <metalua@gmail.com>
-- @author ShadowNinja <shadowninja@minetest.net>
--------------------------------------------------------------------------------

--- Serialize an object into a source code string. This string, when passed as
-- an argument to deserialize(), returns an object structurally identical to
-- the original one.  The following are currently supported:
--   * Booleans, numbers, strings, and nil.
--   * Functions; uses interpreter-dependent (and sometimes platform-dependent) bytecode!
--   * Tables; they can cantain multiple references and can be recursive, but metatables aren't saved.
-- This works in two phases:
--   1. Recursively find and record multiple references and recursion.
--   2. Recursively dump the value into a string.
-- @param x Value to serialize (nil is allowed).
-- @return load()able string containing the value.

local export = {}
function export.serialize(x)
    local local_index  = 1  -- Top index of the "_" local table in the dump
    -- table->nil/1/2 set of tables seen.
    -- nil = not seen, 1 = seen once, 2 = seen multiple times.
    local seen = {}

    -- nest_points are places where a table appears within itself, directly
    -- or not.  For instance, all of these chunks create nest points in
    -- table x: "x = {}; x[x] = 1", "x = {}; x[1] = x",
    -- "x = {}; x[1] = {y = {x}}".
    -- To handle those, two tables are used by mark_nest_point:
    -- * nested - Transient set of tables being currently traversed.
    --   Used for detecting nested tables.
    -- * nest_points - parent->{key=value, ...} table cantaining the nested
    --   keys and values in the parent.  They're all dumped after all the
    --   other table operations have been performed.
    --
    -- mark_nest_point(p, k, v) fills nest_points with information required
    -- to remember that key/value (k, v) creates a nest point  in table
    -- parent. It also marks "parent" and the nested item(s) as occuring
    -- multiple times, since several references to it will be required in
    -- order to patch the nest points.
    local nest_points  = {}
    local nested = {}
    local function mark_nest_point(parent, k, v)
        local nk, nv = nested[k], nested[v]
        local np = nest_points[parent]
        if not np then
            np = {}
            nest_points[parent] = np
        end
        np[k] = v
        seen[parent] = 2
        if nk then seen[k] = 2 end
        if nv then seen[v] = 2 end
    end

    -- First phase, list the tables and functions which appear more than
    -- once in x.
    local function mark_multiple_occurences(x)
        local tp = type(x)
        if tp ~= "table" and tp ~= "function" then
            -- No identity (comparison is done by value, not by instance)
            return
        end
        if seen[x] == 1 then
            seen[x] = 2
        elseif seen[x] ~= 2 then
            seen[x] = 1
        end

        if tp == "table" then
            nested[x] = true
            for k, v in pairs(x) do
                if nested[k] or nested[v] then
                    mark_nest_point(x, k, v)
                else
                    mark_multiple_occurences(k)
                    mark_multiple_occurences(v)
                end
            end
            nested[x] = nil
        end
    end

    local dumped     = {}  -- object->varname set
    local local_defs = {}  -- Dumped local definitions as source code lines

    -- Mutually recursive local functions:
    local dump_val, dump_or_ref_val

    -- If x occurs multiple times, dump the local variable rather than
    -- the value. If it's the first time it's dumped, also dump the
    -- content in local_defs.
    function dump_or_ref_val(x)
        if seen[x] ~= 2 then
            return dump_val(x)
        end
        local var = dumped[x]
        if var then  -- Already referenced
            return var
        end
        -- First occurence, create and register reference
        local val = dump_val(x)
        local i = local_index
        local_index = local_index + 1
        var = "_["..i.."]"
        local_defs[#local_defs + 1] = var.." = "..val
        dumped[x] = var
        return var
    end

    -- Second phase.  Dump the object; subparts occuring multiple times
    -- are dumped in local variables which can be referenced multiple
    -- times.  Care is taken to dump local vars in a sensible order.
    function dump_val(x)
        local  tp = type(x)
        if     x  == nil        then return "nil"
        elseif tp == "string"   then return string.format("%q", x)
        elseif tp == "boolean"  then return x and "true" or "false"
        elseif tp == "function" then
            return string.format("loadstring(%q)", string.dump(x))
        elseif tp == "number"   then
            -- Serialize numbers reversibly with string.format
            return string.format("%.17g", x)
        elseif tp == "table" then
            local vals = {}
            local idx_dumped = {}
            local np = nest_points[x]
            for i, v in ipairs(x) do
                if not np or not np[i] then
                    vals[#vals + 1] = dump_or_ref_val(v)
                end
                idx_dumped[i] = true
            end
            for k, v in pairs(x) do
                if (not np or not np[k]) and
                        not idx_dumped[k] then
                    vals[#vals + 1] = "["..dump_or_ref_val(k).."] = "
                        ..dump_or_ref_val(v)
                end
            end
            return "{"..table.concat(vals, ", ").."}"
        else
            error("Can't serialize data of type "..tp)
        end
    end

    local function dump_nest_points()
        for parent, vals in pairs(nest_points) do
            for k, v in pairs(vals) do
                local_defs[#local_defs + 1] = dump_or_ref_val(parent)
                    .."["..dump_or_ref_val(k).."] = "
                    ..dump_or_ref_val(v)
            end
        end
    end

    mark_multiple_occurences(x)
    local top_level = dump_or_ref_val(x)
    dump_nest_points()

    if next(local_defs) then
        return "local _ = {}\n"
            ..table.concat(local_defs, "\n")
            .."\nreturn "..top_level
    else
        return "return "..top_level
    end
end

local function safe_loadstring(...)
	local func, err = loadstring(...)
	if func then
		setfenv(func, {})
		return func
	end
	return nil, err
end

local function dummy_func() end

function export.deserialize(str, safe)
	if type(str) ~= "string" then
		return nil, "Cannot deserialize type '"..type(str)
			.."'. Argument must be a string."
	end
	if str:byte(1) == 0x1B then
		return nil, "Bytecode prohibited"
	end
	local f, err = loadstring(str)
	if not f then return nil, err end

	-- The environment is recreated every time so deseralized code cannot
	-- pollute it with permanent references.
	setfenv(f, {loadstring = safe and dummy_func or safe_loadstring})

	local good, data = pcall(f)
	if good then
		return data
	else
		return nil, data
	end
end

function boxesToString(input)
    local Str = "{"
    local i = 1
    if input.numBoxes > 0 then
        while (i < input.numBoxes+1) do
            --Subtract the offset, then move to -1.5 starting point
            local start = vector.subtract(vector.subtract(input.boxes[i].start, input.offset),1.5)
            local fin = vector.subtract(vector.subtract(input.boxes[i].fin, input.offset),1.5)
            Str = Str .. "{" .. -start.x.. ", " .. start.y .. ", " ..start.z .. ", " ..-fin.x .. ", " ..fin.y .. ", " ..fin.z .. "},"
            i = i + 1
        end
    end
    Str = Str .. "}"
    return Str
end

--
-- CheckPlacement
--
-- Checks the provided set of boxes caputures 0,0,0

function CheckPlacement(input) 
    local x,y,z --booleans
    local ep = 0.001 --epsilon
    x = input.offset.x < 0 and (input.offset.x + input.dimension.x) > 0
    y = input.offset.y < 0 and (input.offset.y + input.dimension.y) > 0
    z = input.offset.z < 0 and (input.offset.z + input.dimension.z) > 0
    return x and y and z
end

function export.format(input, relocate)
    local data = {}
    --Load only stuff I need into data from input
    local Placement_Index = -1
    if relocate == false then
        --Typically the first boxgroup we come across is not the placement node's boxgroup 
        --when not doing relocation. Which means we first seach and find that placement node 
        --save it's data, set it's numBoxes to zero, and start over counting
        
        --When we come across the correct position for the node, we'll populate data.nodes[1]
        --This way, later in Minetest, we can always assume the placement node is in [1]. Nifty;)
        data.nodes = {} --To be filled with each collision/selection box set and associated x,y,z coord
        data.numNodes = 1 -- to be added to later
        
        if input.size.x * input.size.y * input.size.z > 1 then
            for a = 0, input.size.x-1, 1 do
                for b = 0, input.size.y-1, 1 do
                    for c = 1, input.size.z, 1 do
                        local grindex = c+b*input.size.z+a*input.size.z*input.size.y
                        if CheckPlacement(input[grindex]) then
                            data.nodes[1] = {}
                            data.nodes[1].boxList = boxesToString(input[grindex])
                            data.nodes[1].position = {}
                            data.nodes[1].position.x = a
                            data.nodes[1].position.y = b
                            data.nodes[1].position.z = c-1
                            Placement_Index = grindex
                        end
                    end
                end
			end
			for a = 0, input.size.x-1, 1 do
				for b = 0, input.size.y-1, 1 do
					for c = 1, input.size.z, 1 do
						local grindex = c+b*input.size.z+a*input.size.z*input.size.y
						if input[grindex].numBoxes > 0 and grindex ~= Placement_Index then
							data.numNodes = data.numNodes + 1
							data.nodes[data.numNodes] = {}
							data.nodes[data.numNodes].boxList = boxesToString(input[grindex])
							data.nodes[data.numNodes].position = {}
							data.nodes[data.numNodes].position.x = a   - data.nodes[1].position.x
							data.nodes[data.numNodes].position.y = b   - data.nodes[1].position.y
							data.nodes[data.numNodes].position.z = c-1 - data.nodes[1].position.z
						end
					end
				end
            end
			--After adjusting all positions, set original to origin
			data.nodes[1].position.x = 0
			data.nodes[1].position.y = 0
			data.nodes[1].position.z = 0
        else --only one set of boxes:
            data.nodes[1] = {}
            data.nodes[1].boxList = boxesToString(input[1])
            data.nodes[1].position = {}
            data.nodes[1].position.x = 0
            data.nodes[1].position.y = 0
            data.nodes[1].position.z = 0
        end
    else
        data.nodes = {} --To be filled with each collision/selection box set and associated x,y,z coord
        data.numNodes = 1
        if input.size.x * input.size.y * input.size.z > 1 then
            --Set up the placement node
            data.nodes[1] = {}
            data.nodes[1].boxList = boxesToString(input[1])
            data.nodes[1].position = {}
            data.nodes[1].position.x = 0
            data.nodes[1].position.y = 0
            data.nodes[1].position.z = 0
            Placement_Index = 1
            for a = 0, input.size.x-1, 1 do
                for b = 0, input.size.y-1, 1 do
                    for c = 1, input.size.z, 1 do
                        local grindex = c+b*input.size.z+a*input.size.z*input.size.y
                        --Instantiate a new table at the index
                        if input[grindex].numBoxes > 0 and Placement_Index ~= grindex then
                            --The first index is always the placement node in this setup.
                            data.numNodes = data.numNodes + 1
                            data.nodes[data.numNodes] = {}
                            data.nodes[data.numNodes].boxList = boxesToString(input[grindex])
                            data.nodes[data.numNodes].position = {}
                            data.nodes[data.numNodes].position.x = a
                            data.nodes[data.numNodes].position.y = b
                            data.nodes[data.numNodes].position.z = c-1
                            --Calculate each individual 3x3x3 node's collision and selection boxes and save in array that corresponds with its size
                        end
                    end
                end
            end
        else
            data.nodes[1] = {}
            data.nodes[1].boxList = boxesToString(input[1])
            data.nodes[1].position = {}
            data.nodes[1].position.x = 0
            data.nodes[1].position.y = 0
            data.nodes[1].position.z = 0
        end
    end

    return data
end

return export
