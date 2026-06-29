local t = require("tests.runner")

-- Notebook and NotebookManager are coupled — reset both together.
local function fresh()
    package.loaded["noted.structures.notebook_manager"] = nil
    package.loaded["noted.structures.notebook"]         = nil
    package.loaded["noted.config"]                      = nil
    return require("noted.structures.notebook")
end

-- ─── Notebook.new ────────────────────────────────────────────────────────────

t.describe("Notebook.new", function()
    t.it("stores the name in subfolders[1].subpath", function()
        local Notebook = fresh()
        local nb = Notebook.new("my-notes")
        t.eq(nb.subfolders[1].subpath, "my-notes")
    end)

    t.it("starts with exactly one subfolder (the root)", function()
        local Notebook = fresh()
        local nb = Notebook.new("my-notes")
        t.eq(#nb.subfolders, 1)
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

    t.it("errors on duplicate notebook name", function()
        local Notebook = fresh()
        Notebook.new("dup")
        t.has_error(function() Notebook.new("dup") end)
    end)

    t.it("two notebooks with different names are independent", function()
        local Notebook = fresh()
        local a = Notebook.new("alpha")
        local b = Notebook.new("beta")
        t.eq(a.subfolders[1].subpath, "alpha")
        t.eq(b.subfolders[1].subpath, "beta")
    end)
end)

-- ─── Notebook:get_name ───────────────────────────────────────────────────────

t.describe("Notebook:get_name", function()
    t.it("returns the notebook name", function()
        local Notebook = fresh()
        local nb = Notebook.new("my-notes")
        t.eq(nb:get_name(), "my-notes")
    end)

    t.it("returns the name for a real notebook too", function()
        local Notebook = fresh()
        local nb = Notebook.new("real", "/notes")
        t.eq(nb:get_name(), "real")
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

    t.it("does not insert when subfolder not found", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:add_note(1, "ghost")
        t.eq(#nb.subfolders[1].notes, 0)
    end)

    t.it("can add multiple notes to the same subfolder", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:add_note(1, "nb")
        nb:add_note(2, "nb")
        nb:add_note(3, "nb")
        t.eq(#nb.subfolders[1].notes, 3)
    end)

    t.it("same id can be added to different subfolders", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        -- manually add a second subfolder
        table.insert(nb.subfolders, { subpath = "sub", notes = {} })
        t.is_true(nb:add_note(7, "nb"))
        t.is_true(nb:add_note(7, "sub"))
        t.contains(nb.subfolders[1].notes, 7)
        t.contains(nb.subfolders[2].notes, 7)
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

    t.it("returns false when id not present anywhere", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.is_false(nb:remove_note(99))
    end)

    t.it("removes from the correct subfolder when multiple exist", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        table.insert(nb.subfolders, { subpath = "sub", notes = {} })
        nb:add_note(10, "nb")
        nb:add_note(20, "sub")
        nb:remove_note(10)
        t.eq(#nb.subfolders[1].notes, 0)
        t.contains(nb.subfolders[2].notes, 20)
    end)

    t.it("removes only the first occurrence when id appears in one subfolder", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:add_note(5, "nb")
        nb:add_note(5, "nb")
        nb:remove_note(5)
        t.eq(#nb.subfolders[1].notes, 1)
        t.eq(nb.subfolders[1].notes[1], 5)
    end)

    t.it("add then remove leaves subfolder empty", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:add_note(1, "nb")
        nb:remove_note(1)
        t.eq(#nb.subfolders[1].notes, 0)
    end)
end)

-- ─── Notebook:delete ─────────────────────────────────────────────────────────

t.describe("Notebook:delete", function()
    t.it("does not error", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        t.no_error(function() nb:delete() end)
    end)

    t.it("allows a new notebook with the same name after deletion", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:delete()
        t.no_error(function() Notebook.new("nb") end)
    end)

    t.it("errors when deleting a notebook that was already deleted", function()
        local Notebook = fresh()
        local nb = Notebook.new("nb")
        nb:delete()
        t.has_error(function() nb:delete() end)
    end)
end)

-- ─── Notebook:create_subfolder (pure in-memory path) ─────────────────────────
-- create_subfolder calls fs.mkdirp, so we stub vim.fs and fs to avoid disk I/O.

t.describe("Notebook:create_subfolder (in-memory registration)", function()
    local function fresh_stubbed()
        package.loaded["noted.structures.notebook_manager"] = nil
        package.loaded["noted.structures.notebook"]         = nil
        package.loaded["noted.config"]                      = nil
        package.loaded["noted.utils.fs"]                    = nil

        -- stub fs so mkdirp always succeeds without touching disk
        package.loaded["noted.utils.fs"] = {
            mkdirp = function(_) return true end,
            mkdir  = function(_) return true end,
        }
        -- stub vim.fs.joinpath (not available outside Neovim)
        vim.fs = vim.fs or {}
        vim.fs.joinpath = function(...)
            local parts = { ... }
            return table.concat(parts, "/")
        end

        return require("noted.structures.notebook")
    end

    t.it("registers a single-level subfolder", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("nb", "/notes")
        nb:create_subfolder("work")
        t.eq(#nb.subfolders, 2)
        t.eq(nb.subfolders[2].subpath, "work")
    end)

    t.it("registers all intermediate segments for nested path", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("nb", "/notes")
        nb:create_subfolder("work/projects")
        t.eq(#nb.subfolders, 3)
        t.eq(nb.subfolders[2].subpath, "work")
        t.eq(nb.subfolders[3].subpath, "work/projects")
    end)

    t.it("does not duplicate intermediate segment registered earlier", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("nb", "/notes")
        nb:create_subfolder("work")
        nb:create_subfolder("work/projects")
        -- should be: root + work + work/projects = 3 total
        t.eq(#nb.subfolders, 3)
    end)

    t.it("new subfolder starts with empty notes", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("nb", "/notes")
        nb:create_subfolder("archive")
        t.eq(nb.subfolders[2].notes, {})
    end)

    t.it("notes can be added to a registered subfolder", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("nb", "/notes")
        nb:create_subfolder("work")
        t.is_true(nb:add_note(99, "work"))
        t.contains(nb.subfolders[2].notes, 99)
    end)

    t.it("errors on virtual notebook", function()
        local Notebook = fresh_stubbed()
        local nb = Notebook.new("virtual") -- no path
        t.has_error(function() nb:create_subfolder("work") end)
    end)
end)

t.run()
