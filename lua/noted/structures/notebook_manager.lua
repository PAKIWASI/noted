
local fs = require("noted.utils.fs")



---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---add a new notebook
---@param notebook Notebook
function NotebookManager.add(notebook)
    local subpath = notebook.subfolders[1].subpath
    assert(notebooks[subpath] == nil, "notebook with this name is already present!")
    notebooks[subpath] = notebook
end

---remove a notebook from storage
---@param subpath string
function NotebookManager.remove(subpath)
    assert(notebooks[subpath], "notebook with name is not present")
    notebooks[subpath] = nil
end

---save everything as json to nvim's default data directory (.local/state?)
---@param notes table<ID, Note>
---@param id_struct id_struct
---@param nbs table<string, Notebook>
function NotebookManager.save_all(notes, id_struct, nbs)

    -- TODO: should we set this here or at config level?
    local STATE_PATH = vim.fs.joinpath(vim.fn.stdpath("data"), "noted-state.json")
    -- strip metatables: vim.json can only encode plain tables
    local notes_plain = {}
    for id, note in pairs(notes) do
        notes_plain[tostring(id)] = {
            path      = note.path,
            outlinks  = note.outlinks,
            backlinks = note.backlinks,
        }
    end

    local nbs_plain = {}
    for name, nb in pairs(nbs) do
        nbs_plain[name] = {
            path       = nb.path,
            subfolders = nb.subfolders,
        }
    end

    local payload = vim.json.encode({
        notes      = notes_plain,
        id_struct  = id_struct,
        notebooks  = nbs_plain,
    })

    local ok, err = fs.write(STATE_PATH, payload)
    if not ok then
        vim.notify("noted: save failed: " .. (err or "?"), vim.log.levels.ERROR)
    end
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
