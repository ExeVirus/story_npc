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
local aflag, adialog, aquery, ashop, anpc, amove, aitem, aquest
local tflag, tdialog, titem, tloc, tlos

--
--  Main edit formspec
--

local function on_recieve_main()
    return true 
end

main = function(variable)
    local text = "Hello World"
    local formspec = {
        "formspec_version[3]",
        "size[10,10,false]",
        "real_coordinates[true]",
        "position[0.5,0.5]",
        "label[0.375,0.5;", minetest.formspec_escape(text), "]",
        --Name
        --Texture
        --Model
        --Text Color
        --Text Background Color
        --Sound (general)
        --Sound (on interact)
        --Movement Type
        --Movement edit-box (coordinates)
        --Events
        --Position (useful for moving an entity)
        --Health Type
        --Max Health
    }
        
    return table.concat(formspec, "")
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





