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

local funciton _priv(name)
    return minetest.check_player_privs(name,  {npc_master = true })
end

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
--                                                                         -
--                                                                         -
----------------------------------------------------------------------------
--
--  Main edit formspec
--
local funciton recieve_main()
    return true 
end


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
    --Add formspec
    --register on recieve formspec
        --Lots of functionality for on_recieve, each with it's own function to call
    return true
end





