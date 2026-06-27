local M = {}

-- TODO: linux only for now

---true if string is not nil and not empty
---@param str string
---@return boolean
function M.string_valid(str)
    return (str ~= nil and str ~= "")
end

---checks if a full path is valid (absolute path, .md extension)
---@param fullpath string
---@return boolean
function M.fullpath_valid(fullpath)
    if not M.string_valid(fullpath) then
        return false
    end

    if fullpath:sub(1, 1) ~= "/" then
        return false
    end

    local s, e = fullpath:find("%.md$")
    if not s then
        return false
    end

    return e == #fullpath
end

---replace whitespaces with dashes and remove anything not alphanumeric or dash
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
    local filename = path:match("([^/]+)$")
    if not filename then
        return ""
    end
    local title = filename:match("^(.-)%.md$")
    return title or filename
end

---extract directory path from full file path
---@param fullpath string eg "/home/wasi/Documents/notebook1/note1.md"
---@return string -- eg "/home/wasi/Documents/notebook1/"
function M.extract_dir(fullpath)
    return fullpath:match("(.*/)[^/]*$") or ""
end

---check if a string is a valid title (not empty, no slashes, no .md extension)
---@param title string
---@return boolean
function M.title_valid(title)
    if not M.string_valid(title) then
        return false
    end
    if title:find("/") or title:find("%.md$") then
        return false
    end
    return true
end

---join path components
---@param ... string
---@return string
function M.join_path(...)
    local parts = { ... }
    local result = {}
    for _, part in ipairs(parts) do
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
    return vim.uv.fs_stat(path) ~= nil
end

---check if a directory exists on disk
---@param path string
---@return boolean
function M.dir_exists(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end


return M
