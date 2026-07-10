
---@alias ID integer unique id for each note


---exported for persistent storage
---@class id_struct
---@field counter  ID
---@field free_ids table<ID,boolean>


---each notebook has one root subfolder (index 1) and zero or more named subfolders
---@class subfolder
---@field subpath string
---@field notes   ID[]
--[[ subpath is path of the subfolder starting at notebook's root. (except for subfolders[1])
--  eg path=/home/wasi/doc/notes, subfolders[1] = {\"notes\"} (it stores notebook name), subfolders[2] = {general_notes}
--  actual path for 2: /home/wasi/doc/notes/general_notes
--]]



---@alias PickerBackend "auto"|"telescope"|"fzf-lua"|"snacks"|"mini"|"vim.ui.select"

---@class NotedKeymaps
---@field goto_link string  keymap in noted md buffers to follow [[link]] under cursor
---@field backlinks string  open backlinks picker for current note
---@field tree      string  open tree view for current note's notebook
---@field graph     string  open graph view for current note's notebook

---@class NotebookNvimOpts
---@field default_notebook string?          used when a command needs one and none given; nil = always prompt
---@field link_pattern     "wikilinks" | "()[] what's this called again?"           Lua pattern to extract link targets from [[…]]
---@field index_on_save    boolean          re-index + save on every BufWritePost in a noted buffer (scoped to saved buffer only, not expensive)
---@field picker           PickerBackend    picker backend; "auto" probes in order: snacks → telescope → fzf-lua → mini → vim.ui.select
---@field keymaps          NotedKeymaps

---@class NotebookNvimConfig
---@field options          NotebookNvimOpts
---@field resolved_picker  fun(): PickerBackend     return the resolved backend name (never "auto")
---@field setup            fun(opts?: NotebookNvimOpts)
---@field state_path       string?
---@field get_state_path   fun(): string





