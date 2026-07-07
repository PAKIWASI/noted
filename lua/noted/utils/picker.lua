-- thin abstraction over whichever fuzzy-picker backend the user has
-- installed. every backend is reduced to the same shape as the builtin
-- vim.ui.select: pick(items, opts, on_choice).
--
-- opts:
--   prompt       string
--   format_item  fun(item): string
-- on_choice(item, idx) is called with item=nil if the user cancelled.

local config = require("noted.config")

local M = {}

---@generic T
---@param items T[]
---@param opts { prompt?: string, format_item?: (fun(item:T):string) }
---@param on_choice fun(item: T?, idx: integer?)
function M.pick(items, opts, on_choice)
    opts = opts or {}
    local format_item = opts.format_item or tostring
    local backend = config.resolved_picker()

    if #items == 0 then
        vim.notify("noted: nothing to pick from", vim.log.levels.WARN)
        on_choice(nil, nil)
        return
    end

    if backend == "telescope" then
        M._pick_telescope(items, opts, format_item, on_choice)
    elseif backend == "fzf-lua" then
        M._pick_fzf_lua(items, opts, format_item, on_choice)
    elseif backend == "snacks" then
        M._pick_snacks(items, opts, format_item, on_choice)
    else
        -- "mini" registers itself as the vim.ui.select provider on setup,
        -- and "vim.ui.select" is the explicit builtin fallback, so both
        -- go through the same call.
        vim.ui.select(items, {
            prompt = opts.prompt,
            format_item = format_item,
        }, on_choice)
    end
end

function M._pick_telescope(items, opts, format_item, on_choice)
    local ok, pickers = pcall(require, "telescope.pickers")
    if not ok then
        vim.notify("noted: telescope not available, falling back", vim.log.levels.WARN)
        return vim.ui.select(items, { prompt = opts.prompt, format_item = format_item }, on_choice)
    end
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
        prompt_title = opts.prompt or "noted",
        finder = finders.new_table({
            results = items,
            entry_maker = function(item)
                return { value = item, display = format_item(item), ordinal = format_item(item) }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                on_choice(selection and selection.value or nil)
            end)
            return true
        end,
    }):find()
end

function M._pick_fzf_lua(items, opts, format_item, on_choice)
    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        vim.notify("noted: fzf-lua not available, falling back", vim.log.levels.WARN)
        return vim.ui.select(items, { prompt = opts.prompt, format_item = format_item }, on_choice)
    end

    local display_to_item = {}
    local displayed = {}
    for _, item in ipairs(items) do
        local d = format_item(item)
        display_to_item[d] = item
        table.insert(displayed, d)
    end

    fzf.fzf_exec(displayed, {
        prompt = (opts.prompt or "noted") .. "> ",
        actions = {
            ["default"] = function(selected)
                local choice = selected and selected[1]
                on_choice(choice and display_to_item[choice] or nil)
            end,
        },
    })
end

function M._pick_snacks(items, opts, format_item, on_choice)
    local ok, snacks = pcall(require, "snacks")
    if not ok or not snacks.picker or not snacks.picker.select then
        vim.notify("noted: snacks.picker not available, falling back", vim.log.levels.WARN)
        return vim.ui.select(items, { prompt = opts.prompt, format_item = format_item }, on_choice)
    end
    -- Snacks.picker.select is API-compatible with vim.ui.select
    snacks.picker.select(items, { prompt = opts.prompt, format_item = format_item }, on_choice)
end

---prompt for a free-text string (used for note titles, grep queries, etc.)
---@param prompt string
---@param default string?
---@param on_submit fun(text: string?)
function M.input(prompt, default, on_submit)
    vim.ui.input({ prompt = prompt, default = default }, on_submit)
end

return M
