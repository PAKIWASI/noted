
---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---add a new notebook
---@param notebook Notebook
function NotebookManager.add(notebook)
    local name = notebook.subfolders[1].name
    assert(notebooks[name] == nil, "notebook with this name is already present!")
    notebooks[name] = notebook
end

---remove a notebook from storage
---@param name string
function NotebookManager.remove(name)
    assert(notebooks[name], "notebook with name is not present")
    notebooks[name] = nil
end

---save everything as json to nvim's default data directory (.local/state?)
---@param notes table<ID, Note>
---@param id_struct id_struct
---@param notebooks table<string, Notebook>
function NotebookManager.save_all(notes, id_struct, notebooks)
    -- one file for each param
end


---@return table<ID, Note>
---@return id_struct
---@return table<string, Notebook>
function NotebookManager.load_all()

end

---if user makes external changes, sync them (move/del note, modify link etc)
---@param notes table<ID, Note>
---@param id_struct id_struct
---@param notebooks table<string, Notebook>
function NotebookManager.sync_all(notes, id_struct, notebooks)

end


return NotebookManager
