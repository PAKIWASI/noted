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
---@field create_file function
---@field delete_file function
---@field read function
---@field write function
---@field rename function


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
---@field subpath string
---@field notes ID[]
--[[ subpath is path of the subfolder starting at notebook's root. (except for subfolders[1])
--  eg path=/home/wasi/doc/notes, subfolders[1] = {"notes"} (it stores notebook name), subfolders[2] = {general_notes}
--  actual path for 2: /home/wasi/doc/notes/general_notes
--]]


---@class Notebook
---@field path? string root path on disk; nil for virtual notebooks
---@field subfolders subfolder[]
---@field new function
---@field delete function
---@field is_real function
---@field get_name function
---@field add_note function
---@field remove_note function
---@field create_dir function
---@field create_subfolder function


---@class NotebookManager
---@field add function
---@field remove function
---@field save_all function
---@field load_all function
---@field sync_all function


---@class jsonPayload
---@field notes table<ID, Note>
---@field id_struct id_struct
---@field notebooks table<string, Notebook>


---@alias PickerBackend "auto"|"telescope"|"fzf-lua"|"snacks"|"mini"|"vim.ui.select"

---@class NotedKeymaps
---@field goto_link string  keymap in noted md buffers to follow [[link]] under cursor
---@field backlinks string  open backlinks picker for current note
---@field tree      string  open tree view for current note's notebook
---@field graph     string  open graph view for current note's notebook

---@class NotebookNvimOpts
---@field default_notebook string?          used when a command needs one and none given; nil = always prompt
---@field link_pattern     string           Lua pattern to extract link targets from [[…]]
---@field index_on_save    boolean          re-index + save on every BufWritePost in a noted buffer -- TODO: is this expensive?
---@field picker           PickerBackend    picker backend; "auto" probes in order: snacks → telescope → fzf-lua → mini → vim.ui.select
---@field keymaps          NotedKeymaps

---@class NotebookNvimConfig
---@field options NotebookNvimOpts
---@field resolved_picker function
---@field setup function
---@field state_path string?
---@field get_state_path function


