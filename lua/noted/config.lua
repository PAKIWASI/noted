local M = {}


---@type NotebookNvimConfig
M.options = {

}

function M.setup(opts)
    if opts then
        M.options = vim.tbl_deep_extend("force", M.options, opts)
    end
end

return M
