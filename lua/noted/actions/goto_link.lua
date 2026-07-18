local nl = require("noted.utils.note_links")
local nm = require("noted.structures.note_manager")
local Note = require("noted.structures.note")



---resolve+jump to (creating if necessary) the `[[link]]` under the cursor
---in the current buffer. no-op with a notification if cursor isn't on a link.
local function goto_link_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 0-based -> 1-based

    local link = nl.get_link_at(line, col)
    if not link then
        vim.notify("noted: no link under cursor", vim.log.levels.WARN)
        return
    end

    local target = nl.parse_inner(link.inner)
    if not target then
        vim.notify("noted: malformed link under cursor", vim.log.levels.WARN)
        return
    end

    local note = nl.find_note_by_title(nm.get_notes(), target)

    if not note then
        local from_path = vim.api.nvim_buf_get_name(0)
        local new_path  = nl.new_note_path_for_link(from_path, target)
        note = Note.new(new_path)
        local ok, err = note:create_file()
        if not ok then
            vim.notify("noted: could not create linked note: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        -- register into whichever notebook owns `from_path`, mirroring
        -- NotebookManager.sync_curr_buf's own "which notebook owns this
        -- path" walk (Feat 4 factors that walk out into a shared helper
        -- so this call site and sync_curr_buf both use it)
        require("noted.structures.notebook_manager").register_new_note(note, from_path)
    end

    vim.cmd.edit(vim.fn.fnameescape(note.path))
end

return goto_link_under_cursor
