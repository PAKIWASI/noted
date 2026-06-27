local M = {}


---true if string is not nil and not empty
---@param str string
---@return boolean
function M.string_valid(str)
    return (str and str ~= "")
end

---asserts string not nil and not empty
---@param str string
function M.assert_string_valid(str)
    assert(str and str ~= "", "string is nil or empty")
end

---checks if a full path is valid (absolute path, .md extension)
---@param fullpath string
---@return boolean
function M.fullpath_valid(fullpath)
    if not M.string_valid(fullpath) then
        return false
    end

    -- Check if it's an absolute path
    if fullpath:sub(1, 1) ~= "/" then
        return false
    end

    -- Check if it has .md extension
    local s, e = fullpath:find("%.md$")
    if not s then
        return false
    end

    -- Ensure .md is at the end
    return e == #fullpath
end

---asserts fullpath is valid
---@param fullpath string
function M.assert_fullpath_valid(fullpath)
    assert(M.fullpath_valid(fullpath), "Invalid file path: " .. tostring(fullpath))
end

---repace whitespaces with dashes and remove anything not alphanumeric or dash
---@param title string
---@return string
---@return number -- number of replacements made
function M.slugify(title)
    return title:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
end

---extract the title from a file path (filename without extension)
---@param path string eg "/home/wasi/Documents/notebook1/note1.md"
---@return string -- eg "note1"
function M.extract_title(path)
    M.assert_fullpath_valid(path)

    -- Get the filename from the path
    local filename = path:match("([^/]+)$")
    if not filename then
        return ""
    end

    -- Remove the .md extension
    local title = filename:match("^(.-)%.md$")
    return title or filename
end

---extract directory path from full file path
---@param fullpath string eg "/home/wasi/Documents/notebook1/note1.md"
---@return string -- eg "/home/wasi/Documents/notebook1/"
function M.extract_dir(fullpath)
    M.assert_fullpath_valid(fullpath)
    return fullpath:match("(.*/)[^/]*$") or ""
end

---check if a string is a valid title (not empty, no slashes, etc)
---@param title string
---@return boolean
function M.title_valid(title)
    if not M.string_valid(title) then
        return false
    end
    -- Title shouldn't contain path separators or extension
    if title:find("/") or title:find("%.md$") then
        return false
    end
    return true
end

function M.assert_title_valid(title)
    assert(M.title_valid(title), "title is not valid")
end

---join path components
---@param ... string
---@return string
function M.join_path(...)
    local parts = { ... }
    local result = {}
    for _, part in ipairs(parts) do
        M.assert_string_valid(part)
        -- Remove leading/trailing slashes for joining
        local clean = part:gsub("^/+", ""):gsub("/+$", "")
        if clean ~= "" then
            table.insert(result, clean)
        end
    end
    return "/" .. table.concat(result, "/")
end

---get file extension
---@param path string
---@return string?
function M.get_extension(path)
    if not M.string_valid(path) then
        return nil
    end
    return path:match("%.([^%.]+)$")
end

---check if a file exists on disk
---@param path string
---@return boolean
function M.file_exists(path)
    if not M.string_valid(path) then
        return false
    end

    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---check if a directory exists on disk
---@param path string
---@return boolean
function M.dir_exists(path)
    if not M.string_valid(path) then
        return false
    end

    -- Use luv or vim.loop for better directory checking
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "directory"
end


return M
