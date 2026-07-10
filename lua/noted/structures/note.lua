
local nm = require('noted.structures.note_manager')
local fs = require("noted.utils.fs")


---@class Note
---@field id           ID unique id for each note
---@field path         string full path to the note; the note name is its filename without extension
---@field outlinks     ID[] ids of notes that this note links to via [[]]
---@field backlinks    ID[] ids of notes that link to this note
---@field new          fun(fullpath: string): Note
---@field delete       fun(self: Note)
---@field link         fun(self: Note, other: Note)
---@field is_parent    fun(self: Note, other_id: ID): boolean
---@field is_child     fun(self: Note, other_id: ID): boolean
---@field create_file  fun(self: Note): boolean, string?
---@field delete_file  fun(self: Note): boolean, string?
---@field read         fun(self: Note): string?, string?
---@field write        fun(self: Note, content: string): boolean, string?
---@field rename       fun(self: Note, new_path: string): boolean, string?
---@field file_exists  fun(self: Note): boolean
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
    -- local front_matter = string.format(
    --     "---\nid: %s\ncreated: %s\n---\n\n",
    --     tostring(self.id),
    --     os.date("%Y-%m-%dT%H:%M:%S")
    -- )
    -- local content = front_matter .. "# " .. np.extract_title(self.path) .. "\n\n"
    return fs.write(self.path, "")
end

---read raw markdown content
function Note:read()
    return fs.read(self.path)
end

---check if file with note's path exists on disk
function Note:file_exists()
    local kind = fs.kind(self.path)
    return kind ~= nil and kind == 'file'
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
