

---common Note map for all notes
---@type Note<ID, Note>
local notes = {}



---@class NoteManager
local NoteManager = {}

---@param note Note
function NoteManager.add(note)
    assert(table[note.id], "note with id=%d is already present", note.id)
    table[note.id] = note
end

---@param id ID
function NoteManager.remove(id)
    -- TODO: should we call remove? or = nil? we have a hashmap here
    assert(notes[id], "note is not present")
    notes[id] = nil
end

function NoteManager.is_present(id)
    return notes[id] ~= nil
end



return NoteManager
