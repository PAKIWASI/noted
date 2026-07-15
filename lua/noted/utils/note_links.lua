-- utils for finding/creating/deleting/syncing link tags in note files
--
-- link syntax: [[note-title]] or [[note-title|alt display name]]
-- when a user writes a link to a note that doesn't exist yet, we create it
-- in the same directory as the note that referenced it.
-- `gd` on a link takes the user to the linked note (creating it first if needed).
-- sync walks every outlink tag in a note and reconciles it against the
-- in-memory Note graph

local np = require("noted.utils.name_path")

local M = {}

M.LINK_PATTERN = "%[%[(.-)%]%]"

---trim leading/trailing whitespace
---@param s string
---@return string
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---find every [[link]] occurrence in a line
---@param line string
---@return {s: integer, e: integer, inner: string}[] -- 1-based inclusive spans, in order
function M.find_links(line)
    local links = {}
    local init = 1
    while init <= #line do
        local s, e, inner = line:find(M.LINK_PATTERN, init)
        if not s then break end
        table.insert(links, { s = s, e = e, inner = inner })
        init = e + 1
    end
    return links
end

---split a link's inner text into target/alias.
---"note-title" -> "note-title", nil
---"note-title|Display Name" -> "note-title", "Display Name"
---@param inner string
---@return string? target nil if inner has no target (e.g. "" or "|alias")
---@return string? alias
function M.parse_inner(inner)
    if inner == nil then return nil end
    local target, alias = inner:match("^(.-)|(.*)$")
    if target then
        target = trim(target)
        alias = trim(alias)
        if target == "" then return nil end
        if alias == "" then alias = nil end
        return target, alias
    end
    local t = trim(inner)
    if t == "" then return nil end
    return t, nil
end

---checks if a [[...]] link's inner text is well-formed:
--- - not empty
--- - has a valid target once split on "|"
--- - at most one "|"
---@param inner string
---@return boolean
function M.is_valid_inner(inner)
    if inner == nil or inner == "" then return false end
    local _, count = inner:gsub("|", "")
    if count > 1 then return false end
    local target = M.parse_inner(inner)
    return target ~= nil
end

---get the link (if any) whose span contains 1-based column `col`.
---for `gd`-on-cursor.
---@param line string
---@param col integer 1-based column
---@return {s: integer, e: integer, inner: string}?
function M.get_link_at(line, col)
    for _, link in ipairs(M.find_links(line)) do
        if col >= link.s and col <= link.e then
            return link
        end
    end
    return nil
end

---build a [[target]] or [[target|alias]] tag for insertion into a buffer
---@param target string
---@param alias string?
---@return string
function M.format_link(target, alias)
    assert(target and target ~= "", "format_link: target is required")
    if alias and alias ~= "" then
        return "[[" .. target .. "|" .. alias .. "]]"
    end
    return "[[" .. target .. "]]"
end

---insert a link tag into `line` at 1-based column `col`, returning the new line
---@param line string
---@param col integer
---@param target string
---@param alias string?
---@return string
function M.insert_link(line, col, target, alias)
    local tag = M.format_link(target, alias)
    return line:sub(1, col - 1) .. tag .. line:sub(col)
end

---find every outlink target in a whole note's content (all lines).
---returns targets in the order they appear; duplicates are kept out.
---@param content string full file content
---@return string[] targets
function M.extract_all_targets(content)
    local seen, targets = {}, {}
    for line in (content .. "\n"):gmatch("(.-)\n") do
        for _, link in ipairs(M.find_links(line)) do
            if M.is_valid_inner(link.inner) then
                local target = M.parse_inner(link.inner)
                if target and not seen[target] then
                    seen[target] = true
                    table.insert(targets, target)
                end
            end
        end
    end
    return targets
end

---find a registered note whose (slugified) title matches `target`.
---`target` itself is slugified before comparing, so links can be written
---with spaces/caps ("[[My Note]]") and still resolve.
---@param notes table<ID, Note>
---@param target string
---@return Note?
function M.find_note_by_title(notes, target)
    local wanted = np.slugify(target)
    for _, note in pairs(notes) do
        if np.slugify(np.extract_title(note.path)) == wanted then
            return note
        end
    end
    return nil
end

---compute the path a new note (created because a link pointed at a
---not-yet-existing note) should get: same directory as the note that
---contains the link, filename slugified from the link target.
---@param from_note_path string
---@param target string
---@return string
function M.new_note_path_for_link(from_note_path, target)
    local dir = np.extract_dir(from_note_path)
    local slug = np.slugify(target)
    return dir .. slug .. ".md"
end

---sync a note's outlinks against its current file content: link every
---target found in the text that isn't already linked, and drop outlinks
---whose tag was removed from the text (best-effort: only touches links
---whose target note we can resolve).
---@param note Note
---@param notes table<ID, Note> every known note, for title resolution
---@return ID[] newly_linked ids that were newly linked as a result of this sync
function M.sync_outlinks(note, notes)
    local content = note:read() or ""
    local targets = M.extract_all_targets(content)

    local newly_linked = {}
    local still_present = {}

    for _, target in ipairs(targets) do
        local other = M.find_note_by_title(notes, target)
        if other and other.id ~= note.id then
            still_present[other.id] = true
            if not note:is_parent(other.id) then
                note:link(other)
                table.insert(newly_linked, other.id)
            end
        end
    end

    -- drop outlinks whose tag is no longer present in the text
    for i = #note.outlinks, 1, -1 do
        local id = note.outlinks[i]
        if not still_present[id] then
            table.remove(note.outlinks, i)
            local other = notes[id]
            if other then
                for j = #other.backlinks, 1, -1 do
                    if other.backlinks[j] == note.id then
                        table.remove(other.backlinks, j)
                    end
                end
            end
        end
    end

    return newly_linked
end

return M
