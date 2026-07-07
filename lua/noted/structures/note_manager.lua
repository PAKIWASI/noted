
---common Note map for all notes
---@type table<ID, Note>
local notes = {}

---lazy id assignment
local counter = 0
---@type table<ID, true>
local free_ids = {}


---central store and id allocator for all notes across all notebooks
---@class NoteManager
---@field add           fun(note: Note)
---@field remove        fun(id: ID)
---@field is_present    fun(id: ID): boolean
---@field assign        fun(): ID
---@field deassign      fun(id: ID)
---@field is_free       fun(id: ID): boolean
---@field get_notes     fun(): table<ID, Note>
---@field set_notes     fun(saved_notes: table<ID, Note>)
---@field get_id_struct fun(): id_struct
---@field set_id_struct fun(id_struct: id_struct)
local NoteManager = {}

function NoteManager.add(note)
    assert(not notes[note.id], "note already present")
    notes[note.id] = note
end

function NoteManager.remove(id)
    assert(notes[id], "note is not present")
    notes[id] = nil
end

---return true if note with `id` is in our global notes collection
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

---return true if `id` is free (either in free list or id above counter)
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
