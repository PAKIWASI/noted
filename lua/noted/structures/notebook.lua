
local nbm  = require('noted.structures.notebook_manager')
local fs   = require("noted.utils.fs")
local Note = require("noted.structures.note")


---@class Notebook
local Notebook = {}
Notebook.__index = Notebook

function Notebook.new(name, path)
    local notebook = setmetatable({
        path = path,
        subfolders = {
            { subpath = name, notes = {} }
            -- [1] is always the root subfolder, it's subpath stores the notebook's name
            -- rest of subfolders have path starting from notebook root
        },
    }, Notebook)
    nbm.add(notebook)
    return notebook
end

---given a folder, recursively create a notebook and discover all notes
function Notebook.new_from_folder(name, path)
    if fs.kind(path) ~= "directory" then
        return nil, "not a directory: " .. path
    end

    local notebook = Notebook.new(name, path)

    ---recursively walk `dir`, registering subfolders and notes as we go
    ---@param dir string absolute path on disk
    ---@param subpath string path relative to the notebook root ("" for the root)
    local function walk(dir, subpath)
        local entries, err = fs.list_dir(dir)
        if not entries then return end

        for _, entry in ipairs(entries) do
            local entry_path = vim.fs.joinpath(dir, entry.name)
            if entry.kind == "directory" then
                local child_subpath = subpath == "" and entry.name or (subpath .. "/" .. entry.name)
                notebook:create_subfolder(child_subpath)
                walk(entry_path, child_subpath)
            elseif entry.name:match("%.md$") then
                local note = Note.new(entry_path)
                notebook:add_note(note.id, subpath == "" and name or subpath)
            end
        end
    end

    walk(path, "")
    return notebook
end

function Notebook:delete()
    nbm.remove(self.subfolders[1].subpath)
end

---returns true if notebook is tied to an actual folder on disk
function Notebook:is_real()
    return self.path ~= nil
end

---subfolders[1].subpath is actually the name of the notebook
function Notebook:get_name()
    return self.subfolders[1].subpath
end

---return a subfolder by subpath, or nil if not found
---@param notebook Notebook
---@param subpath string
---@return subfolder?
local function find_subfolder(notebook, subpath)
    for _, v in ipairs(notebook.subfolders) do
        if v.subpath == subpath then
            return v
        end
    end
    return nil
end

---add a note id to a subfolder. returns true on success, false if subfolder not found.
function Notebook:add_note(id, subpath)
    local subf = find_subfolder(self, subpath)
    if not subf then
        return false
    end
    table.insert(subf.notes, id)
    return true
end

---remove a note id from whichever subfolder holds it
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
function Notebook:create_dir()
    if not self:is_real() then
        return false, "virtual notebook has no path"
    end
    return fs.mkdirp(self.path)
end

---checks if folder for real notebooks exists or not
function Notebook:dir_exists()
    if not self.path then
        return false
    end
    local kind = fs.kind(self.path)
    return kind ~= nil and kind == 'directory'
end

---create a named subfolder under the notebook root, registering all intermediate paths
function Notebook:create_subfolder(subpath)
    assert(self:is_real(), "cannot create subfolder on virtual notebook")

    local path = vim.fs.joinpath(self.path, subpath)
    local ok, err = fs.mkdirp(path)
    if not ok then return false, err end

    -- register each intermediate segment if not already present
    local accumulated = ""
    for segment in subpath:gmatch("[^/]+") do
        accumulated = accumulated == "" and segment or (accumulated .. "/" .. segment)
        if not find_subfolder(self, accumulated) then
            table.insert(self.subfolders, { subpath = accumulated, notes = {} })
        end
    end

    return true
end


return Notebook
