
-- TODO: should i do dense/sparse array thing?
-- linear search is simpler and how many notes can someone have?

---common Note array for all notes. quick linear search using note.id
---@type Note[]
local notes = {}


local NoteManager = {}


---@param note Note
function NoteManager.add(note)
    table.insert(notes, note)
end


return NoteManager
