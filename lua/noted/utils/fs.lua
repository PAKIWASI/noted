-- utilites for file creation/deletion/move etc
local M = {}


-- directories

---create a directory (and all parents). synchronous.
---@param path string
---@return boolean, string? -- ok, err
function M.mkdir(path)
    local ok, err = vim.uv.fs_mkdir(path, 493) -- 493 = 0755
    if not ok and err and not err:find("EEXIST") then
        return false, err
    end
    return true
end

---recursively create directories (like mkdir -p)
---@param path string
---@return boolean, string?
function M.mkdirp(path)
    local ok = vim.fn.mkdir(path, "p")
    if ok == 0 then
        return false, "mkdir -p failed: " .. path
    end
    return true
end

---remove an empty directory
---@param path string
---@return boolean, string?
function M.rmdir(path)
    local ok, err = vim.uv.fs_rmdir(path)
    return ok ~= nil, err
end


-- files

---read entire file as a string
---@param path string
---@return string?, string? -- content, err
function M.read(path)
    local fd, err = vim.uv.fs_open(path, "r", 292) -- 292 = 0444
    if not fd then return nil, err end
    local stat, serr = vim.uv.fs_fstat(fd)
    if not stat then
        vim.uv.fs_close(fd)
        return nil, serr
    end
    local data, rerr = vim.uv.fs_read(fd, stat.size, 0)
    vim.uv.fs_close(fd)
    return data, rerr
end

---write (overwrite) a file atomically via a temp file
---@param path string
---@param content string
---@return boolean, string?
function M.write(path, content)
    local tmp = path .. ".tmp"
    local fd, err = vim.uv.fs_open(tmp, "w", 420) -- 420 = 0644
    if not fd then return false, err end
    local _, werr = vim.uv.fs_write(fd, content, 0)
    vim.uv.fs_close(fd)
    if werr then
        vim.uv.fs_unlink(tmp)
        return false, werr
    end
    local ok, rerr = vim.uv.fs_rename(tmp, path)
    return ok ~= nil, rerr
end

---delete a file
---@param path string
---@return boolean, string?
function M.delete(path)
    local ok, err = vim.uv.fs_unlink(path)
    return ok ~= nil, err
end

---rename/move a file or directory
---@param src string
---@param dst string
---@return boolean, string?
function M.rename(src, dst)
    local ok, err = vim.uv.fs_rename(src, dst)
    return ok ~= nil, err
end

---check existence and type
---@param path string
---@return "file"|"directory"?
function M.kind(path)
    local stat = vim.uv.fs_stat(path)
    if not stat then return nil end
    return stat.type == "directory" and "directory" or "file"
end

return M
