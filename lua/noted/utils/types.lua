

---@alias ID integer unique id for each note


---@class Note
---@field id ID unique id for each note. MUST ensure uniqueness of a note!!
---@field path string full path to the note. name of note is it's filename
---@field children ID[] list of notes mentioned by this note using `[[]]`
---@field parents ID[] list of notes that mention this note
---@field new function
---@field delete function


---common storage/retrival/id for all notes in any notebook
---@class NoteManager
---@field add function
---@field remove function
---@field assign function
---@field deassign function
---@field is_free function

---we export this for persistant storage
---@class id_struct
---@field counter ID
---@field free_list ID[]


---@class Notebook
---@field name string can be the folder name or just a name if notebook not tied to a folder
---@field path? string full path to notebook folder. a notebook doesn't need to be confined to a single folder
---@field subfolders string[] list of all recursive subfolders
---@field notes ID[] list of note id's attached to this notebook




