

---@alias ID integer unique id for each note


---@class Note
---@field private id ID unique id for each note
---@field private path string full path to the note. name of note is it's filename
---@field private children ID[] list of notes mentioned by this note using `[[]]`
---@field private parents ID[] list of notes that mention this note
---@field new function

---@class ID_Manager
---@field assign function
---@field deassign function
---@field is_free function


---@class Notebook
---@field name string the folder name
---@field path? string full path to notebook folder. a notebook doesn't need to be confined to a single folder
---@field subfolders string[] list of all recursive subfolders
---@field notes ID[]
