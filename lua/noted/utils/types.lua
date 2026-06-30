---@alias ID integer unique id for each note


---@class Note
---@field id ID unique id for each note
---@field path string full path to the note; the note name is its filename without extension
---@field outlinks ID[] ids of notes that this note links to via [[]]
---@field backlinks ID[] ids of notes that link to this note
---@field new          fun(fullpath: string): Note
---@field delete       fun(self: Note)
---@field link         fun(self: Note, other: Note)
---@field is_parent    fun(self: Note, other_id: ID): boolean
---@field is_child     fun(self: Note, other_id: ID): boolean
---@field create_file  fun(self: Note): boolean, string?
---@field delete_file  fun(self: Note): boolean, string?
---@field read         fun(self: Note): string?, string?
---@field write        fun(self: Note, content: string): boolean, string?
---@field rename       fun(self: Note, new_path: string): boolean, string?
---@field file_exists  fun(self: Note): boolean


---central store and id allocator for all notes across all notebooks
---@class NoteManager
---@field add          fun(note: Note)
---@field remove       fun(id: ID)
---@field is_present   fun(id: ID): boolean
---@field assign       fun(): ID
---@field deassign     fun(id: ID)
---@field is_free      fun(id: ID): boolean
---@field get_notes    fun(): table<ID, Note>
---@field set_notes    fun(saved_notes: table<ID, Note>)
---@field get_id_struct fun(): id_struct
---@field set_id_struct fun(id_struct: id_struct)


---exported for persistent storage
---@class id_struct
---@field counter ID
---@field free_ids table<ID,boolean>


---each notebook has one root subfolder (index 1) and zero or more named subfolders
---@class subfolder
---@field subpath string
---@field notes ID[]
--[[ subpath is path of the subfolder starting at notebook's root. (except for subfolders[1])
--  eg path=/home/wasi/doc/notes, subfolders[1] = {\"notes\"} (it stores notebook name), subfolders[2] = {general_notes}
--  actual path for 2: /home/wasi/doc/notes/general_notes
--]]


---@class Notebook
---@field path? string root path on disk; nil for virtual notebooks
---@field subfolders subfolder[]
---@field new              fun(name: string, path?: string): Notebook
---@field delete           fun(self: Notebook)
---@field is_real          fun(self: Notebook): boolean
---@field get_name         fun(self: Notebook): string
---@field add_note         fun(self: Notebook, id: ID, subpath: string): boolean
---@field remove_note      fun(self: Notebook, id: ID): boolean
---@field create_dir       fun(self: Notebook): boolean, string?
---@field dir_exists       fun(self: Notebook): boolean
---@field create_subfolder fun(self: Notebook, subpath: string): boolean, string?


---@class NotebookManager
---@field add         fun(notebook: Notebook)
---@field remove      fun(subpath: string)
---@field remove_note fun(id: ID)
---@field save_all    fun(): boolean, string?
---@field load_all    fun(): boolean, string?
---@field sync_all    fun(): boolean, string?


---@alias PickerBackend "auto"|"telescope"|"fzf-lua"|"snacks"|"mini"|"vim.ui.select"

---@class NotedKeymaps
---@field goto_link string  keymap in noted md buffers to follow [[link]] under cursor
---@field backlinks string  open backlinks picker for current note
---@field tree      string  open tree view for current note's notebook
---@field graph     string  open graph view for current note's notebook

---@class NotebookNvimOpts
---@field default_notebook string?          used when a command needs one and none given; nil = always prompt
---@field link_pattern     string           Lua pattern to extract link targets from [[…]]
---@field index_on_save    boolean          re-index + save on every BufWritePost in a noted buffer (scoped to saved buffer only, not expensive)
---@field picker           PickerBackend    picker backend; "auto" probes in order: snacks → telescope → fzf-lua → mini → vim.ui.select
---@field keymaps          NotedKeymaps

---@class NotebookNvimConfig
---@field options          NotebookNvimOpts
---@field resolved_picker  fun(): PickerBackend
---@field setup            fun(opts?: NotebookNvimOpts)
---@field state_path       string?
---@field get_state_path   fun(): string
