

---common Note map for all notes
---@type Note<ID, Note>
local notes = {}

---lazy id assignment
local counter = 0;
---@type ID[]
local free_list = {}


---@class NoteManager
local NoteManager = {}



---@param note Note
function NoteManager.add(note)
    assert(table[note.id], "note already present")
    notes[note.id] = note
end

---@param id ID
function NoteManager.remove(id)
    assert(notes[id], "note is not present")
    notes[id] = nil
end

function NoteManager.is_present(id)
    return notes[id] ~= nil
end

---@return ID
function NoteManager.assign()
    local n = #free_list
    if n ~= 0 then
        return table.remove(free_list, n)
    end

    local id = counter
    counter = counter + 1
    return id;
end

---@param id ID
function NoteManager.deassign(id)
    --dev - O(n)
    assert(NoteManager.is_free(id), "id is already free")
    table.insert(free_list, id)
end

---@param id ID
---@return boolean
function NoteManager.is_free(id)
    for _, v in ipairs(free_list) do
        if v == id then
            return true
        end
    end

    return id >= counter
end


return NoteManager
