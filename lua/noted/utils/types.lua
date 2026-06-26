

---@alias ID integer unique id for each note


---@class Note
---@field id ID unique id for each note
---@field path string full path to the note. name of note is it's filename
---@field children ID[] list of notes mentioned by this note using `[[]]`
---@field parents ID[] list of notes that mention this note
---@field new function
---@field delete function


---assign unique ID to each note
---@class IdManager
---@field assign function
---@field deassign function
---@field is_free function


---common storage/retrival for all notes in any notebooks
---@class NoteManager
---@field add function
---@field remove function



---@class Notebook
---@field name string the folder name
---@field path? string full path to notebook folder. a notebook doesn't need to be confined to a single folder
---@field subfolders string[] list of all recursive subfolders
---@field notes ID[] list of note id's 




