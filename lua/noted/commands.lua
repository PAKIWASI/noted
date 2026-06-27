local M = {}

function M.register()

-- do the subcommand thing

end

--[[
When you implement commands.lua, that's where validation lives. The pattern is:
lua-- commands.lua
local u = require("noted.utils.name_path")

local function cmd_new_note(path)
    if not u.fullpath_valid(path) then
        vim.notify("noted: invalid path: " .. tostring(path), vim.log.levels.ERROR)
        return
    end
    local note = require("noted.structures.note").new(path)
    -- ...
end
--]]

return M
