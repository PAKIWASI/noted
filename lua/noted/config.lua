local M = {}


---@type NotebookNvimConfig
M.options = {
    default_notebook = "",
    link_pattern     = "%[%[(.-)%]%]",
    index_on_save    = true,
    picker           = "auto",
    keymaps          = {
        goto_link = "gd",
        backlinks = "<leader>nb",
        tree      = "<leader>nt",
    },
}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

---lazily resolve state_path so vim.fn.stdpath is never called at module load time
---@return string
function M.state_path()
    return vim.fs.joinpath(vim.fn.stdpath("data"), "noted-state.json")
end

-- picker resolution

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
