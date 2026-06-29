---@alias ID integer unique id for each note


---@class Note
---@field id ID unique id for each note
---@field path string full path to the note; the note name is its filename without extension
---@field outlinks ID[] ids of notes that this note links to via [[]]
---@field backlinks ID[] ids of notes that link to this note
---@field new function
---@field delete function
---@field link function
---@field is_parent function
---@field is_child function


---central store and id allocator for all notes across all notebooks
---@class NoteManager
---@field add function
---@field remove function
---@field is_present function
---@field assign function
---@field deassign function
---@field is_free function
---@field get_notes function
---@field set_notes function
---@field get_id_struct function
---@field set_id_struct function


---exported for persistent storage
---@class id_struct
---@field counter ID
---@field free_ids table<ID,boolean>


---each notebook has one root subfolder (index 1) and zero or more named subfolders
---@class subfolder
---@field subpath string    -- path of the subfolder starting at notebook's root. eg subfolders[1] = {/home/wasi/doc/notes}, subfolders[2] = {/general_notes} - actual path: /home/wasi/doc/notes/general_notes
---@field notes ID[]


---@class Notebook
---@field path? string root path on disk; nil for virtual notebooks
---@field subfolders subfolder[]
---@field new function
---@field delete function
---@field is_real function
---@field add_note function
---@field remove_note function


---@class NotebookManager
---@field add function
---@field remove function
---@field save_all function
---@field load_all function
---@field sync_all function


---@alias PickerBackend "auto"|"telescope"|"fzf-lua"|"snacks"|"mini"|"vim.ui.select"

---@class NotedKeymaps
---@field goto_link string  keymap in noted md buffers to follow [[link]] under cursor
---@field backlinks string  open backlinks picker for current note
---@field tree      string  open tree view for current note's notebook

---@class NotebookNvimConfig
---@field default_notebook string?          used when a command needs one and none given; nil = always prompt
---@field link_pattern     string           Lua pattern to extract link targets from [[…]]
---@field index_on_save    boolean          re-index + save on every BufWritePost in a noted buffer
---@field picker           PickerBackend    picker backend; "auto" probes in order: snacks → telescope → fzf-lua → mini → vim.ui.select
---@field keymaps          NotedKeymaps


