local M = {}

local u = require('utils')


---create a notebook at an existing folder or create new
---@param path string
function M.create_notebook(path)
    u.assert_string_valid(path)
end




---creates a note in
---@param title string
function M.create_note(title)
end

function M.delete_note(title)
end

return M
