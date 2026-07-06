-- utils for finding/creating/deleting/syncing link tags in note files
-- when a user regesters a link in a note, we automatically create it in the same dir as note (handeled on other end)
-- gd on a link should be processed (valid link syntax, note present etc) and user should be taken to the note
-- sync should find all link tags and sync accordingly

local M = {}


---get the integer offset(s) into line where link(s) starts
---@param line string
---@return integer|integer[]?   -- offset(s) into line or null if no link
function M.get_link_offsets(line)
    -- use find to repeatedly find next links by supplying the previous link pos +1 as init pos
line:find()
end

---returns true if [[]] syntax is valid. supports alteranate names with |
---@param line string the line of text containing the link
---@param pos integer the offset to the start of the link
function M.is_valid(line, pos)

end

---get the name of the note that is linked.
---If this is null then note does not exist. We will create on other end of call site
---@param line string
---@param pos integer
---@return string?      -- note may not exist yet
function M.get_note_name(line, pos)

end

---get the alt name (if any) of the link
---@param line string
---@param pos integer
---@return string?
function M.get_alt_name(line, pos)

end

---get full path to the linked note
---@param name string
---@return string       -- we only call this when name is not null so note should always exist
function M.get_linked_note(name)

end




return M
