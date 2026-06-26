---@type ID
local counter = 0;
---@type ID[]
local free_list = {}


---@class IdManager
local M = {}

---lazy id assignment
---@return ID
function M.assign()
    local n = #free_list
    if n ~= 0 then
        return table.remove(free_list, n)
    end

    local id = counter
    counter = counter + 1
    return id;
end

---@param id ID
function M.deassign(id)
    -- TODO: how to gaurd against multiple calls to this with same id
    table.insert(free_list, id)
end

---@param id ID
---@return boolean
function M.is_free(id)
    for _, v in ipairs(free_list) do
        if v == id then
            return true
        end
    end

    return id >= counter
end

return M
