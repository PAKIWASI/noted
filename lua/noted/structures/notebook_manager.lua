
---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---comment
---@param notebook Notebook
function NotebookManager.add(notebook)
    local name = notebook.subfolders[1].name
    assert(notebooks[name] == nil, "notebook with this name is already present!")
    notebooks[name] = notebook
end

---comment
---@param name string
function NotebookManager.remove(name)
    assert(notebooks[name], "notebook with name is not present")
    notebooks[name] = nil
end


return NotebookManager
