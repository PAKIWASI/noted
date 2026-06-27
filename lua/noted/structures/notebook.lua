---@type table<string, Notebook>
local notebooks = {}


-- TODO: about path/name validation, I think i should do that one level above
-- this so we'll have fewer calls here
local u = require('utils.utils')


---@class Notebook
local Notebook = {}
Notebook.__index = Notebook


---@param name string
---@param path? string
function Notebook.new(name, path)
    u.assert_title_valid(name)
    if path then
        u.assert_fullpath_valid(path)
    end
    local notebook = setmetatable({
        path = path,
        subfolders = { { -- subfolders[0]
            name,       -- name of the notebook itself
            {}          -- notes directly in the folder (not in any subfolder)
        } }
    }, Notebook)
    notebooks[name] = notebook
    return notebook
end

function Notebook:delete()
    notebooks[self.subfolders[1].name] = nil
end

---returns true if notebook is tied to an actual folder
---@return boolean
function Notebook:is_real()
    return self.path ~= nil
end

---return a subfolder if found, nil otherwise
---@param notebook Notebook
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

---comment
---@param id ID
---@param subfolder_name string
function Notebook:add_note(id, subfolder_name)
    local subf = find_subfolder(self, subfolder_name)
    assert(subf, "folder with name doesnot exist")
    table.insert(subf.notes, id)
end


function Notebook:remove_note(id)

end


return Notebook
