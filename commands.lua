------Story NPC Commands------
local mesdat = ...
local storage = mesdat.storage
local _context = mesdat._context
local function get_context(name)
    local context = _context[name] or {}
    _context[name] = context
    return context
end

minetest.register_chatcommand("save", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        local context = get_context(name)
        storage:set_string("foo", minetest.serialize(context.flags))
    end,
})

minetest.register_chatcommand("load", {
    privs = {
        interact = true,
    },
    func = function(name, param)
        local context = get_context(name)
        context.flags = minetest.deserialize(storage:get_string("foo"))
    end,
})
