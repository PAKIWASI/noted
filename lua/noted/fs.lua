local M = {}

--- repace whitespaces with dashes and remove anything not alphanumeric or dash
---@param title string
---@return string
---@return number
local function slugify(title)
    return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
end

function M.create_note(title)

end

function M.delete_note(title)

end

return M
