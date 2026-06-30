
local fs     = require("noted.utils.fs")
local config = require("noted.config")
local nm     = require("noted.structures.note_manager")


---common map of notebook name to notebook
---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---add a new notebook
function NotebookManager.add(notebook)
    local subpath = notebook.subfolders[1].subpath  -- subfolders[1] actually stores the name for notebook
    assert(notebooks[subpath] == nil, "notebook with this name is already present!")
    notebooks[subpath] = notebook
end

---remove a notebook from storage
function NotebookManager.remove(subpath)
    assert(notebooks[subpath], "notebook with name is not present")
    notebooks[subpath] = nil
end

---remove a note from every notebook
function NotebookManager.remove_note(id)
    for _, nb in ipairs(notebooks) do
        nb:remove_note(id)
    end
end

---save everything as json to nvim's default data directory (.local/state?)
function NotebookManager.save_all()
    -- strip metatables, vim.json can only encode plain tables
    local notes = nm.get_notes()
    local notes_plain = {}
    for id, note in pairs(notes) do
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

    return fs.write(config.get_state_path(), payload)
end

---load all notebooks, notes and id state from state file
function NotebookManager.load_all()
    local encoded, err = fs.read(config.get_state_path())
    if err then
        return false, err
    end

    ---@cast encoded string removing the nullable
    local decoded = vim.json.decode(encoded)
    if not decoded then -- TODO: is this needed?
        return false, "json decode failed"
    end

    notebooks = setmetatable(decoded.notebooks, require("noted.structures.notebook"))  -- lazily require notebook metatable
    nm.set_notes(setmetatable(decoded.notes, require('noted.structures.notes')))    -- same here
    nm.set_id_struct(decoded.id_struct)

    return true, nil
end


---if user makes external changes, sync them (move/del note, modify link etc)
function NotebookManager.sync_all()
    -- we assume we have loaded state into memory prior to calling this

    -- sync notes
    local notes = nm.get_notes()
    for _, note in ipairs(notes) do
        if note:file_exists() then
            -- file still exists, check links

        else -- file was deleted by user, delete the note
            NotebookManager.remove_note(note.id)
            note:delete()
        end
    end

    -- sync notebooks
    -- we only care about notebooks tied to a folder
    for _, nb in ipairs(notebooks) do
        if nb:is_real() then
            if nb:dir_exists() then

            else -- user deleted the folder
                
            end
        end
    end

end



-- TODO: does this belong here or in notebook?
function NotebookManager.sync_curr_buf()
end


return NotebookManager
