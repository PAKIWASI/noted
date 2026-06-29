
local nbm = require('noted.structures.notebook_manager')
local fs = require("noted.utils.fs")
local np = require('noted.utils.name_path')


---@class Notebook
local Notebook = {}
Notebook.__index = Notebook

---@param name string
---@param path? string
---@return Notebook
function Notebook.new(name, path)
    local notebook = setmetatable({
        path = path,
        subfolders = {
            { subpath = name, notes = {} } -- [1] is always the root subfolder, it has the FULLPATH. rest of subfolders have path starting from root
        },
    }, Notebook)
    nbm.add(notebook)
    return notebook
end

function Notebook:delete()
    nbm.remove(self.subfolders[1].subpath)
end

---returns true if notebook is tied to an actual folder on disk
---@return boolean
function Notebook:is_real()
    return self.path ~= nil
end

function Notebook:get_name()
    return self.subfolders[1].subpath
end

---return a subfolder by subpath, or nil if not found
---@param subpath string
---@return subfolder?
local function find_subfolder(notebook, subpath)
    for _, v in ipairs(notebook.subfolders) do
        if v.name == subpath then
            return v
        end
    end
    return nil
end

---return a subfoler by name only (not path), or nil if not found
---@param notebook Notebook
---@param subname string
---@return subfolder?
local function find_subfolder_by_name(notebook, subname)
    for _, v in ipairs(notebook.subfolders) do
        local name = np.extract_dir_name(v.subpath) --TODO: implement this func
        if name == subname then
            return v
        end
    end
    return nil
end


-- TODO: should we take input by name or by subpath?
---add a note id to a subfolder. returns true on success, false if subfolder not found.
---@param id ID
---@param subpath string
---@return boolean
function Notebook:add_note(id, subpath)
    local subf = find_subfolder(self, subpath)
    if not subf then
        return false
    end
    table.insert(subf.notes, id)
    return true
end

---remove a note id from whichever subfolder holds it
---@param id ID
---@return boolean
function Notebook:remove_note(id)
    for _, subf in ipairs(self.subfolders) do
        for i, note_id in ipairs(subf.notes) do
            if note_id == id then
                table.remove(subf.notes, i)
                return true
            end
        end
    end
    return false
end

---create the notebook root directory on disk (only for real notebooks)
---@return boolean, string?
function Notebook:create_dir()
    if not self:is_real() then
        return false, "virtual notebook has no path"
    end
    return fs.mkdirp(self.path)
end

---create a named subfolder under the notebook root
---@param subpath string
---@return boolean, string?
function Notebook:create_subfolder(subpath)
    assert(self:is_real(), "cannot create subfolder on virtual notebook")
    local path = vim.fs.joinpath(self.path, subpath)
    local ok, err = fs.mkdir(path)
    if not ok then return false, err end
    table.insert(self.subfolders, { subpath = subpath, notes = {} })
    return true
end


return Notebook
