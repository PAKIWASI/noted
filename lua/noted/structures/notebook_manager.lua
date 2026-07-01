local fs     = require("noted.utils.fs")
local config = require("noted.config")
local nm     = require("noted.structures.note_manager")


---common map of notebook name to notebook
---@type table<string, Notebook>
local notebooks = {}


---@class NotebookManager
local NotebookManager = {}

---find an already-registered note by its path, or nil if none matches
---@param path string
---@return Note?
local function find_note_by_path(path)
    for _, note in pairs(nm.get_notes()) do
        if note.path == path then
            return note
        end
    end
    return nil
end

---add a new notebook
function NotebookManager.add(notebook)
    local subpath = notebook.subfolders[1].subpath -- subfolders[1] actually stores the name for notebook
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
    -- notebooks is keyed by name, not indexable, so iterate with pairs
    for _, nb in pairs(notebooks) do
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
    if not decoded then
        return false, "json decode failed"
    end

    -- reset the metatables and assign to the correct modules
    notebooks = setmetatable(decoded.notebooks, require("noted.structures.notebook")) -- lazily require notebook metatable
    nm.set_notes(setmetatable(decoded.notes, require('noted.structures.notes')))      -- same here
    nm.set_id_struct(decoded.id_struct)

    return true, nil
end

---if user makes external changes, sync them (move/del note, modify link etc)
function NotebookManager.sync_all()
    -- we assume we have loaded state into memory prior to calling this

    -- sync notes
    --------------
    -- notes are keyed by id, not indexable, so iterate with pairs
    local notes = nm.get_notes()
    for _, note in pairs(notes) do
        if not note:file_exists() then
            -- file was deleted by user, delete the note
            NotebookManager.remove_note(note.id)
            note:delete()
        end
    end

    -- sync notebooks
    ------------------
    -- we only care about notebooks tied to a folder
    for name, nb in pairs(notebooks) do
        if nb:is_real() then
            if nb:dir_exists() then
                -- sync subfolders, and notes
                for i, subf in ipairs(nb.subfolders) do
                    -- subfolders[1].subpath only stores the notebook's name,
                    -- its actual path on disk is the notebook root itself
                    local dir_path = i == 1 and nb.path or vim.fs.joinpath(nb.path, subf.subpath)
                    local kind = fs.kind(dir_path)

                    if kind == "directory" then
                        -- drop note ids whose note was already removed above
                        for j = #subf.notes, 1, -1 do
                            if not nm.is_present(subf.notes[j]) then
                                table.remove(subf.notes, j)
                            end
                        end

                        -- pick up any .md file the user created directly in the
                        -- folder outside of noted, and register it as a new note
                        local entries = fs.list_dir(dir_path)
                        if entries then
                            for _, entry in ipairs(entries) do
                                if entry.kind == "file" and entry.name:match("%.md$") then
                                    local entry_path = vim.fs.joinpath(dir_path, entry.name)
                                    if not find_note_by_path(entry_path) then
                                        local note = require("noted.structures.note").new(entry_path)
                                        table.insert(subf.notes, note.id)
                                    end
                                end
                            end
                        end
                    end
                end
            else -- user deleted the folder, delete the notebook
                notebooks[name] = nil
            end
        end
        -- virtual notebooks aren't tied to a folder, nothing to sync
    end

    return true, nil
end

---sync the note for the current buffer the user has just saved.
---lives here (rather than on Note/Notebook) because it needs to mutate
---the shared `notebooks` registry: a brand-new file has no note or
---notebook membership yet, and only NotebookManager can create both.
---@return boolean, string?
function NotebookManager.sync_curr_buf()
    local path = vim.api.nvim_buf_get_name(0)
    if not path or path == "" then
        return false, "buffer has no file"
    end

    if find_note_by_path(path) then
        return true, nil -- already tracked, nothing to do
    end

    -- find which real notebook (if any) owns this path, and register a new
    -- note in the matching subfolder
    for _, nb in pairs(notebooks) do
        if nb:is_real() and path:sub(1, #nb.path) == nb.path then
            local relative = path:sub(#nb.path + 2) -- strip "<notebook root>/" prefix
            local dir       = relative:match("(.*)/[^/]+$") or ""
            local subpath   = dir == "" and nb:get_name() or dir

            local note = require("noted.structures.note").new(path)
            nb:add_note(note.id, subpath)
            return true, nil
        end
    end

    return false, "path does not belong to any known notebook"
end

return NotebookManager
