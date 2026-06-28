
---common Note map for all notes
---@type table<ID, Note>
local notes = {}

---lazy id assignment
local counter = 0
---@type table<ID, true>
local free_ids = {}


---@class NoteManager
local NoteManager = {}


---@param note Note
function NoteManager.add(note)
    assert(not notes[note.id], "note already present")
    notes[note.id] = note
end

---@param id ID
function NoteManager.remove(id)
    assert(notes[id], "note is not present")
    notes[id] = nil
end

---@param id ID
---@return boolean
function NoteManager.is_present(id)
    return notes[id] ~= nil
end

---@return ID
function NoteManager.assign()
    for id, _ in pairs(free_ids) do
        free_ids[id] = nil
        return id
    end
    local id = counter
    counter = counter + 1
    return id
end

---@param id ID
function NoteManager.deassign(id)
    assert(not free_ids[id], "id already freed")
    free_ids[id] = true
end

---@param id ID
---@return boolean
function NoteManager.is_free(id)
    return free_ids[id] == true or id >= counter
end

---@return table<ID, Note>
function NoteManager.get_notes()
    return notes
end

---@param saved_notes table<ID, Note>
function NoteManager.set_notes(saved_notes)
    notes = saved_notes
end

---returns the id state needed for persistent storage
---@return id_struct
function NoteManager.get_id_struct()
    return {
        counter  = counter,
        free_ids = free_ids,
    }
end

---restores id state from persistent storage
---@param id_struct id_struct
function NoteManager.set_id_struct(id_struct)
    counter  = id_struct.counter
    free_ids = id_struct.free_ids
end


return NoteManager
