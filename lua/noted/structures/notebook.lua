
local nbm = require('noted.structures.notebook_manager')


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
            { name = name, notes = {} }  -- [1] is always the root subfolder
        },
    }, Notebook)
    nbm.add(notebook)
    return notebook
end

function Notebook:delete()
    nbm.remove(self.subfolders[1].name)
end

---returns true if notebook is tied to an actual folder on disk
---@return boolean
function Notebook:is_real()
    return self.path ~= nil
end

function Notebook:get_name()
    return self.subfolders[1].name
end

---return a subfolder by name, or nil if not found
---@param subfolder_name string
---@return subfolder?
local function find_subfolder(notebook, subfolder_name)
    for _, v in ipairs(notebook.subfolders) do
        if v.name == subfolder_name then
            return v
        end
    end
    return nil
end

---add a note id to a subfolder. returns true on success, false if subfolder not found.
---@param id ID
---@param subfolder_name string
---@return boolean
function Notebook:add_note(id, subfolder_name)
    local subf = find_subfolder(self, subfolder_name)
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


return Notebook
