

local nm = require('note_manager')

---@class Note
local Note = {}
Note.__index = Note


---@param fullpath string
---@return Note
function Note.new(fullpath)
    local note =  setmetatable({
        id = require('id_manager').assign(),
        path = fullpath,
    }, Note)


end

function Note.delete(id)
    
end


return Note
