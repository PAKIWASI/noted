
---common Note map for all notes
---@type table<ID, Note>
local notes = {}

---lazy id assignment
local counter = 0
---@type table<ID, true>
local free_ids = {}


---@class NoteManager
local NoteManager = {}

function NoteManager.add(note)
    assert(not notes[note.id], "note already present")
    notes[note.id] = note
end

function NoteManager.remove(id)
    assert(notes[id], "note is not present")
    notes[id] = nil
end

function NoteManager.is_present(id)
    return notes[id] ~= nil
end

function NoteManager.assign()
    for id, _ in pairs(free_ids) do
        free_ids[id] = nil
        return id
    end
    local id = counter
    counter = counter + 1
    return id
end

function NoteManager.deassign(id)
    assert(not free_ids[id], "id already freed")
    assert(id < counter, "id was never assigned")
    free_ids[id] = true
end

function NoteManager.is_free(id)
    return free_ids[id] == true or id >= counter
end

function NoteManager.get_notes()
    return notes
end

function NoteManager.set_notes(saved_notes)
    notes = saved_notes
end

---returns the id state needed for persistent storage
function NoteManager.get_id_struct()
    return {
        counter  = counter,
        free_ids = free_ids,
    }
end

---restores id state from persistent storage
function NoteManager.set_id_struct(id_struct)
    counter  = id_struct.counter
    free_ids = id_struct.free_ids
end


return NoteManager
