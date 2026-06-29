local t = require("tests.runner")

-- Notebook and NotebookManager are coupled — reset both together.
local function fresh()
    package.loaded["noted.structures.notebook_manager"] = nil
    package.loaded["noted.structures.notebook"]         = nil
    return require("noted.structures.notebook")
end

-- ─── Notebook.new ────────────────────────────────────────────────────────────

t.describe("Notebook.new", function()
    t.it("stores the name", function()
        local Notebook = fresh()
        local nb = Notebook.new("my-notes")
        t.eq(nb.subfolders[1].name, "my-notes")
    end)

    t.it("creates a root subfolder named after the notebook", function()
        local Notebook = fresh()
        local nb = Notebook.new("my-notes")
        t.eq(#nb.subfolders, 1)
        t.eq(nb.subfolders[1].name, "my-notes")
        t.eq(nb.subfolders[1].notes, {})
    end)

    t.it("stores optional path", function()
        local Notebook = fresh()
        local nb = Notebook.new("real", "/home/user/notes")
        t.eq(nb.path, "/home/user/notes")
    end)

    t.it("path is nil when not given", function()
        local Notebook = fresh()
        local nb = Notebook.new("virtual")
        t.is_nil(nb.path)
    end)
end)

-- ─── Notebook:is_real ────────────────────────────────────────────────────────

t.describe("Notebook:is_real", function()
    t.it("false for virtual notebook", function()
        local Notebook = fresh()
        t.is_false(Notebook.new("virtual"):is_real())
    end)

    t.it("true when path given", function()
        local Notebook = fresh()
        t.is_true(Notebook.new("real", "/notes"):is_real())
    end)
end)

-- ─── Notebook:add_note ───────────────────────────────────────────────────────

t.describe("Notebook:add_note", function()
    t.it("returns true and inserts into root subfolder", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.is_true(nb:add_note(42, "nb"))
        t.contains(nb.subfolders[1].notes, 42)
    end)

    t.it("returns false for unknown subfolder", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.is_false(nb:add_note(1, "nonexistent"))
    end)
end)

-- ─── Notebook:remove_note ────────────────────────────────────────────────────

t.describe("Notebook:remove_note", function()
    t.it("returns true and removes the id", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:add_note(1, "nb")
        nb:add_note(2, "nb")
        t.is_true(nb:remove_note(1))
        t.eq(#nb.subfolders[1].notes, 1)
        t.eq(nb.subfolders[1].notes[1], 2)
    end)

    t.it("returns false when id not present", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.is_false(nb:remove_note(99))
    end)
end)

-- ─── Notebook:delete ─────────────────────────────────────────────────────────

t.describe("Notebook:delete", function()
    t.it("does not error", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.no_error(function() nb:delete() end)
    end)
end)
