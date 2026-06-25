

-- Files under `plugin/` are sourced automatically and unconditionally every time Neovim starts
-- This runs before the user has necessarily called `require("notes").setup(...)`

--Put here only what truly must exist before `setup()` is called — most commonly, nothing at all for a modern plugin

vim.notify("plugin/noted.lua ran")


