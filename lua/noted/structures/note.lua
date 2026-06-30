
local nm = require('noted.structures.note_manager')
local fs = require("noted.utils.fs")
local np = require("noted.utils.name_path")


---@class Note
local Note = {}
Note.__index = Note

function Note.new(fullpath)
    local note = setmetatable({
        id       = nm.assign(),
        path     = fullpath,
        outlinks  = {},
        backlinks = {},
    }, Note)
    nm.add(note)
    return note
end

function Note:delete()
    nm.deassign(self.id)
    nm.remove(self.id)
end

---link the current note to another note.
---`self` note is the source (outlink) and `other` is the target (backlink).
function Note:link(other)
    assert(self.id ~= other.id, "a note cannot link to itself")
    table.insert(other.backlinks, self.id)
    table.insert(self.outlinks, other.id)
end

---returns true if `self` has an outlink to `other_id`
function Note:is_parent(other_id)
    for _, id in ipairs(self.outlinks) do
        if id == other_id then return true end
    end
    return false
end

---returns true if `other_id` has an outlink to `self`
function Note:is_child(other_id)
    for _, id in ipairs(self.backlinks) do
        if id == other_id then return true end
    end
    return false
end

---create the .md file on disk for a new note
function Note:create_file()
    if fs.kind(self.path) then
        return false, "file already exists: " .. self.path
    end
    -- TODO: write a minimal YAML front-matter header
    local content = "# " .. np.extract_title(self.path) .. "\n\n"
    return fs.write(self.path, content)
end

---read raw markdown content
function Note:read()
    return fs.read(self.path)
end

---overwrite content (e.g. after editing links)
function Note:write(content)
    return fs.write(self.path, content)
end

---delete the .md file and deregister from NoteManager
function Note:delete_file()
    local ok, err = fs.delete(self.path)
    if not ok then return false, err end
    self:delete()  -- deregisters from NoteManager
    return true
end

---rename the file on disk and update self.path
function Note:rename(new_path)
    local ok, err = fs.rename(self.path, new_path)
    if not ok then return false, err end
    self.path = new_path
    return true
end



return Note
