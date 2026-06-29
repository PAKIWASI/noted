
local fs     = require("noted.utils.fs")
local config = require("noted.config")
local Note   = require("noted.structures.note")
local nm = require("noted.structures.note_manager")
local Notebook = require("noted.structures.notebook")


---common map of notebook name to notebook
---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---add a new notebook
---@param notebook Notebook
function NotebookManager.add(notebook)
    local subpath = notebook.subfolders[1].subpath  -- subfolders[1] actually stores the name for notebook
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
function NotebookManager.save_all()
    -- strip metatables: vim.json can only encode plain tables
    local notes_plain = {}
    for id, note in pairs(nm.get_notes()) do
        notes_plain[tostring(id)] = {
            path      = note.path,
            outlinks  = note.outlinks,
            backlinks = note.backlinks,
        }
    end

    local nbs_plain = {}
    for name, nb in pairs(notebooks) do
        nbs_plain[name] = {
            path       = nb.path,
            subfolders = nb.subfolders,
        }
    end

    local payload = vim.json.encode({
        notes     = notes_plain,
        id_struct = nm.get_id_struct(),
        notebooks = nbs_plain,
    })

    local ok, err = fs.write(config.get_state_path(), payload)
    if not ok then
        vim.notify("noted: save failed: " .. (err or "?"), vim.log.levels.ERROR)
    end
end

---load all notebooks, notes and id state from state file
function NotebookManager.load_all()
    local encoded, err = fs.read(config.get_state_path())
    if err then
        vim.notify("noted: load failed: " .. err, vim.log.levels.ERROR)
    end

    ---@type jsonPayload
    local decoded = vim.json.decode(encoded) -- we already do nil check, why warning?

    -- 1. get each table
    -- 2. re-attach metatable
    -- 3. set it in the proper modules
    notebooks = setmetatable(decoded.notebooks, Notebook)
    nm.set_notes(setmetatable(decoded.notes, Note))
    nm.set_id_struct(decoded.id_struct)
end


---if user makes external changes, sync them (move/del note, modify link etc)
function NotebookManager.sync_all()
end



return NotebookManager
