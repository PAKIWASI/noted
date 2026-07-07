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
    ---@type integer[]
    local offsets = {}
    local num_links = 0
    local start_idx = 1
    while start_idx < #line do
        local s, e = line:find("%[%[*%]%]", start_idx)  -- [[anything inside]]
        if not s or not e then break end
        table.insert(offsets, s)
        num_links = num_links + 1
        start_idx = e + 1
    end
    -- if no links, return null, if only one link (very likely case) then return integer offset.
    -- If mulitple then return the whole offsets array
    return num_links == 0 and nil or (num_links == 1 and offsets[1] or offsets)
end

---checks if [[]] syntax is valid. supports alteranate names with |
---checks if names are valid and slugifies them for storage TODO: do i need to slugify names? and do i write back slugified names in the link?
---returns the note name and optional alt name
---@param line string the line of text containing the link
---@param pos integer the offset to the start of the link
---@return string?, string?
function M.extract_names(line, pos)
    ---@type string
    local title = line:match("%[%[(*)%]%]", pos)
    if #title == 0 then return nil end
    local note_name = title:match("^(%w*)|?")
    if #note_name == 0 then return nil end
    local alt_name = title:match"(|(%w*)$)"
    -- TODO: note doesnot actually NEED an alt name, but if it has one, it needs to be valid
end

---get full path to the linked note
---@param name string
---@return string       -- we only call this when name is not null so note should always exist
function M.get_linked_note(name)

end




return M
