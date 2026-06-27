local nm = require('noted.structures.note_manager')


---@class Note
local Note = {}
Note.__index = Note

---@param fullpath string
---@return Note
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
---@param other Note
function Note:link(other)
    assert(self.id ~= other.id, "a note cannot link to itself")
    table.insert(other.backlinks, self.id)
    table.insert(self.outlinks, other.id)
end

---returns true if `self` has an outlink to `other_id`
---@param other_id ID
---@return boolean
function Note:is_parent(other_id)
    for _, id in ipairs(self.outlinks) do
        if id == other_id then return true end
    end
    return false
end

---returns true if `other_id` has an outlink to `self`
---@param other_id ID
---@return boolean
function Note:is_child(other_id)
    for _, id in ipairs(self.backlinks) do
        if id == other_id then return true end
    end
    return false
end


return Note
