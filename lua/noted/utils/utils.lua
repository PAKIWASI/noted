local M = {}


---true if string is not nil and not empty
---@param string string
---@return boolean
function M.string_valid(string)
    return (string and string ~= "")
end

---asserts string not nil and not empty
---@param string string
function M.assert_string_valid(string)
    assert(string and string ~= "", "string is nil or empty")
end

---repace whitespaces with dashes and remove anything not alphanumeric or dash
---@param title string
---@return string
---@return number
function M.slugify(title)
    return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
end

---@param path string eg "/home/wasi/Documents/notebook1/note1.md"
---@return string eg "note1"
function M.extract_title(path)
end

return M
