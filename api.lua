------Story NPC Lua Api------

----------------------------------------------------------------------------
--                                                                         -
--                        Setup and Utility Functions                      -
--                                                                         -
----------------------------------------------------------------------------

local mesdat = ...
local storage = mesdat.storage
local _context = mesdat._conext
local function get_context(name)
    local context = _context[name] or {}
    _context[name] = context
    return context
end

minetest.register_privilege("npc_master", {
    description = "Can edit/make/delete Story NPC's"
})

local function _priv(name)
    return minetest.check_player_privs(name,  {npc_master = true })
end

---To be defined later, these are for common string getting functions
--Current function ideas:
--Header and footer for formspecs
--Sanitize String functions
--Valid result Functions (returns multiple things, like valid/invalid + error)
--
--
--local filefunction = assert(loadfile("file.lua"))
--local filefuncwithargs = assert(loadfile("funcargs.lua"))(10,20,30) --Note the (10,20,30) can be called later too
--In funcargs.lua: 'local a,b,c =...   '


--
-- Utility Functions from util.lua
--

--Edit-style formspec header
local ehead,
--Edit-style formspec footer
efoot,
--Forspec Sanitize Input Function
mksafe,
--Texture List Table (alphabetical, reverse lookup based on texture_name
texture_table,
-- texture_list
texture_list,
--Model List Table (alphabetical, reverse lookup based on texture_name
model_table,
-- model_list
model_list,
--sound List Table (alphabetical, reverse lookup based on texture_name
sound_table,
-- sound_list
sound_list = (assert(loadfile("util.lua"))

----------------------------------------------------------------------------
--                               Formspecs                                 -
--                                                                         -
-- Hierarchy:                      Actions->Specific Action Subscreen      -
--                                /                                        -
--    Main_edit -> Events -> Event                                         -
--                                \                                        -
--                                 Triggers->Specific Trigger Subscreen    -
--                                                                         -
--          Each formspec also has all its associated funtion calls        -
--          Defined with it so it's easier to modify and understand        -
--          We also check all user input for validity when possible.       -
--                                                                         -
--          Note the function declarations below are required              -
--          otherwise each function doesn't know how to call               -
--          the right formspec                                             -
----------------------------------------------------------------------------
--
-- Function Declarations
--

local main, events, event, actions, triggers
local aflag, adialog, aquery, ashop, anpc, amove, aitem, aquest, aevent
local tflag, tdialog, titem, tloc, tlos

--
--  Main edit formspec functions
--

local function on_recieve_main()
    return true
end

main = function(name, texture_name, model_name, color, bgcolor, sound_nameg, sound_namei)
    local text = "Hello World"
    local formspec = {
        "label[0.375,0.5;", minetest.formspec_escape(text), "]",
		"field[1,1;3,1;name;name:;" .. name .. "]",
		"label[0,2;
		"dropdown[1,2;3,2;texture;" .. texture_list .. ";" .. texture_table[texture_name] .. ";]",
        "dropdown[1,4;3,2;model;" .. model_list .. ";" .. model_table[model_name] .. ";]",
        "field[1,7;3,1;color;Dialog Color:;" .. color .. "]",
		"field[1,8;3,1;color;Dialog BGColor:;" .. bgcolor .. "]",
		"dropdown[1,4;3,2;Sound Rand;" .. sound_list .. ";" .. sound_table[sound_nameg] .. ";]",
		"dropdown[1,4;3,2;Sound Itract;" .. sound_list .. ";" .. sound_table[sound_namei] .. ";]",
        --Movement Type
        --Movement edit-box (coordinates)
        --Events
        --Position (useful for moving an entity)
        --Health Type
        --Max Health
		--Save All Changes
    }

    return ehead() .. table.concat(formspec, "") .. efoot("main")
end

minetest.register_on_joinplayer(function(ObjectRef, last_login)
    ObjectRef:set_inventory_formspec(main())
end)


--
--  Events subscreen
--

--
--  Specific Event Subscreen
--

--
--  Triggers subscreen
--

--
--  Actions subscreen
--

--
--  Action: Flag
--

--
--  Action: Dialog
--

--
--  Action: Query
--

--
--  Action: Shop
--

--
--  Action: Npc
--

--
--  Action: Move
--

--
--  Action: Item
--

--
--  Action: Quest
--

--
--  Action: Event
--

--
-- Trigger: Dialog
--

--
-- Trigger: Item
--

--
-- Trigger: Location
--

--
-- Trigger: Line of Sight
--

--
-- Trigger: Flag
--

----------------------------------------------------------------------------
--                                                                         -
--              Functions for the main API registration Function           -
--                                                                         -
----------------------------------------------------------------------------

--
--
--


----------------------------------------------------------------------------
--                                                                         -
--                    API Registration Function                            -
--                                                                         -
----------------------------------------------------------------------------

local function Register_NPC(model_filename)
    --Register
    --Add Main_formspec
    --register on_recieve_formspec
        --Lots of functionality for on_recieve, each with it's own function to call
    return true
end





