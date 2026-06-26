

---common Note map for all notes
---@type Note<ID, Note>
local notes = {}



---@class NoteManager
local NoteManager = {}

---@param note Note
function NoteManager.add(note)
    if table[note.id] ~= nil then
        error("note with id=%d is already present", note.id)
    end
    table[note.id] = note
end

---@param id ID
function NoteManager.remove(id)
    -- TODO: should we call remove? or = nil? we have a hashmap here
    local removed = table.remove(notes, id)
    if not removed then
        error("note is not present")
    end
end

function NoteManager.is_present(id)
    return notes[id] ~= nil
end


return NoteManager
