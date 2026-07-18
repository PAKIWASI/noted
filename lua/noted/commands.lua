local M = {}

---@type table<string, fun(args: string[])>
local subcommands = {}

function subcommands.new(args)
    -- :Noted new [notebook-relative-path]
    -- with no arg: prompt for a title via picker.input, resolve against
    -- the current notebook (or ask which notebook if none is inferable
    -- from the current buffer)
    require("noted.actions.new_note")(args[1])
end

function subcommands.link(args)
    -- :Noted link
    -- opens a note-picker (Feat 6) scoped to all known notes, and inserts
    -- format_link(target) at the cursor in the current buffer
    require("noted.actions.link_note")()
end

function subcommands.sync(args)
    -- :Noted sync            -> NotebookManager.sync_curr_buf() (current buffer only)
    -- :Noted sync all        -> NotebookManager.sync_all() (manual full sync,
    --                           TODO.md item 5's "manual full sync command"
    --                           for when link tags were hand-edited outside the plugin)
    local nbm = require("noted.structures.notebook_manager")
    if args[1] == "all" then
        local ok, err = nbm.sync_all()
        if ok then
            nbm.save_all()
            vim.notify("noted: full sync complete", vim.log.levels.INFO)
        else
            vim.notify("noted: sync failed: " .. tostring(err), vim.log.levels.ERROR)
        end
    else
        local ok, err = nbm.sync_curr_buf()
        if ok then nbm.save_curr_buf() end       -- TODO: is this right?
        if not ok then vim.notify("noted: " .. tostring(err), vim.log.levels.WARN) end
    end
end

function subcommands.notebooks(args)
    -- :Noted notebooks  -> picker over registered notebooks (Feat 6)
    require("noted.actions.pick_notebook")()
end

function subcommands.notes(args)
    -- :Noted notes [notebook-name]  -> picker over notes in a notebook,
    -- or prompts for the notebook first if omitted
    require("noted.actions.pick_note")(args[1])
end

function subcommands.backlinks(args)
    -- :Noted backlinks  -> picker over backlinks of the current note
    require("noted.actions.pick_backlinks")()
end

function subcommands.grep(args)
    -- :Noted grep [notebook-name]  -> live-grep scoped to that notebook's
    -- root directory (Feat 7)
    require("noted.actions.grep_notebook")(args[1])
end

function subcommands.enable(args)
    -- :Noted enable  -> Feat 5's manual lazy-load trigger
    require("noted").enable()
end

-- function subcommands.tree(args)
--     require("noted.ui.tree").open()
-- end
--
-- function subcommands.graph(args)
--     require("noted.ui.graph").open()
-- end

local function complete(arg_lead, cmd_line, _)
    local words = vim.split(cmd_line, "%s+")
    if #words <= 2 then
        return vim.tbl_filter(function(k) return k:find(arg_lead, 1, true) == 1 end,
            vim.tbl_keys(subcommands))
    end
    return {}
end

function M.register()
    vim.api.nvim_create_user_command("Noted", function(opts)
        local args = opts.fargs
        local name = table.remove(args, 1)
        local fn = name and subcommands[name]
        if not fn then
            vim.notify("noted: unknown subcommand '" .. tostring(name) .. "'", vim.log.levels.ERROR)
            return
        end
        fn(args)
    end, {
        nargs = "*",
        complete = complete,
        desc = "noted.nvim command dispatcher",
    })
end

return M
