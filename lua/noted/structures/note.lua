
---@type NoteManager
local nm = require('note_manager')



---@class Note
local Note = {}
Note.__index = Note

---@param fullpath string
---@return Note
function Note.new(fullpath)
    local note = setmetatable({
        id = nm.assign(),
        path = fullpath,
    }, Note)
    nm.add(note)
    return note
end

function Note:delete()
    nm.deassign(self.id)
    nm.remove(self.id)
end

---link the current note to another note
---`self` note is the parent and `other` is the child
---@param other Note
function Note:link(other)
    assert(self.id ~= other.id)
    table.insert(other.parents, self.id)
    table.insert(self.children, other.id)
end

---is `self` parent of `other`
---@param other_id ID
---@return boolean
function Note:is_parent(other_id)
    for id in self.children do
        if id == other_id then
            return true
        end
    end
    return false
end

---is `self` child of `other`
---@param other_id ID
---@return boolean
function Note:is_child(other_id)
    for id in self.parents do
        if id == other_id then
            return true
        end
    end
    return false
end


return Note
