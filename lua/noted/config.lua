---@class NotebookNvimConfig
local M = {}


---@type NotebookNvimOpts
M.options = {
    default_notebook = nil,
    link_pattern     = "wikilinks",
    index_on_save    = true,
    picker           = "auto",
    keymaps          = {
        goto_link = "gd",
        backlinks = "<leader>nb",   -- open backlinks picker
        tree      = "<leader>nt",
        graph     = "<leader>ng"
    },
}

---@param opts NotebookNvimOpts?
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.options), opts or {})
end

---@return string?
function M.get_state_path()
    if not M.state_path then
        M.state_path = vim.fs.joinpath(vim.fn.stdpath("data"), "noted-state.json")
    end
    return M.state_path
end


---probe in priority order and return the first available backend name
---@return PickerBackend
local function detect_picker()
    if pcall(require, "snacks.picker") then return "snacks"    end
    if pcall(require, "telescope")     then return "telescope" end
    if pcall(require, "fzf-lua")       then return "fzf-lua"   end
    if pcall(require, "mini.pick")     then return "mini"      end
    return "vim.ui.select"
end

---return the resolved backend name (never "auto")
---@return PickerBackend
function M.resolved_picker()
    local p = M.options.picker or "auto"
    if p == "auto" then return detect_picker() end
    return p
end


return M
