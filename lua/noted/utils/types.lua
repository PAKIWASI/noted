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
---@field get_id_struct function
---@field set_id_struct function


---exported for persistent storage
---@class id_struct
---@field counter ID
---@field free_ids table<ID,boolean>


---each notebook has one root subfolder (index 1) and zero or more named subfolders
---@class subfolder
---@field name string
---@field notes ID[]


---@class Notebook
---@field path? string root path on disk; nil for abstract (virtual) notebooks
---@field subfolders subfolder[]
---@field new function
---@field delete function
---@field is_real function
---@field add_note function
---@field remove_note function


---@class NotebookManager
---@field add function
---@field remove function
