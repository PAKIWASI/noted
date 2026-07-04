local t = require("tests.runner")

-- NotebookManager.sync_all() exists to reconcile in-memory state against
-- whatever happened to the files on disk while Neovim wasn't looking.
-- The main real-world source of that drift is a vault shared with a tool
-- like Obsidian: notes get deleted, renamed, and moved from *outside*
-- noted entirely. These tests build a tiny virtual filesystem and drive
-- sync_all() through the scenarios that produces.

-- ─── virtual filesystem stub ─────────────────────────────────────────────────
--
-- `paths` maps an absolute path to "file" | "directory". Anything not in the
-- table does not exist. fs_scandir/fs_scandir_next are derived from `paths`
-- by looking at immediate children, matching real vim.uv semantics closely
-- enough for fs.lua's list_dir to work unmodified.

local function make_vfs(paths, overrides)
    paths = paths or {}
    overrides = overrides or {}

    local function children_of(dir)
        local prefix = dir:gsub("/$", "") .. "/"
        local seen, result = {}, {}
        for p, kind in pairs(paths) do
            if p:sub(1, #prefix) == prefix then
                local rest = p:sub(#prefix + 1)
                if rest ~= "" and not rest:find("/") and not seen[rest] then
                    seen[rest] = true
                    table.insert(result, { name = rest, kind = kind })
                end
            end
        end
        return result
    end

    local vfs = {
        fs_stat = function(path)
            local kind = paths[path]
            if not kind then return nil end
            return { type = kind }
        end,
        fs_scandir = function(path)
            if overrides.scandir_errors and overrides.scandir_errors[path] then
                return nil, overrides.scandir_errors[path]
            end
            if paths[path] ~= "directory" then return nil, "ENOENT: not a directory" end
            return { entries = children_of(path), idx = 0 }
        end,
        fs_scandir_next = function(handle)
            handle.idx = handle.idx + 1
            local e = handle.entries[handle.idx]
            if not e then return nil end
            return e.name, e.kind
        end,
        fs_unlink = function(_) return true end,
    }

    return vfs
end

-- ─── module reset ────────────────────────────────────────────────────────────
--
-- NotebookManager, Notebook, Note and NoteManager all share module-level
-- state, so every test needs a fully independent copy of all four plus a
-- fresh virtual filesystem.

local function fresh(paths, overrides)
    package.loaded["noted.structures.notebook_manager"] = nil
    package.loaded["noted.structures.notebook"]         = nil
    package.loaded["noted.structures.note"]             = nil
    package.loaded["noted.structures.note_manager"]     = nil
    package.loaded["noted.config"]                      = nil
    package.loaded["noted.utils.fs"]                    = nil

    vim.uv = make_vfs(paths, overrides)
    vim.fn = vim.fn or {}
    vim.fn.mkdir = function(_, _) return 1 end -- create_subfolder succeeds without touching disk
    vim.fs = vim.fs or {}
    vim.fs.joinpath = function(...) return table.concat({ ... }, "/") end

    local NotebookManager = require("noted.structures.notebook_manager")
    local Notebook        = require("noted.structures.notebook")
    local Note            = require("noted.structures.note")
    local nm              = require("noted.structures.note_manager")
    return NotebookManager, Notebook, Note, nm
end

-- ─── sync_all: deleted notes ─────────────────────────────────────────────────

t.describe("NotebookManager.sync_all > note deleted outside Neovim", function()
    t.it("deregisters a note whose file was removed (e.g. deleted in Obsidian/Finder)", function()
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/vault"] = "directory",
        })
        local nb = Notebook.new("vault", "/vault")
        local note = Note.new("/vault/gone.md")
        nb:add_note(note.id, "vault")

        NotebookManager.sync_all()

        t.is_false(nm.is_present(note.id))
        t.not_contains(nb.subfolders[1].notes, note.id)
    end)

    t.it("leaves other notes in the same subfolder untouched", function()
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/vault"]          = "directory",
            ["/vault/kept.md"]  = "file",
        })
        local nb = Notebook.new("vault", "/vault")
        local kept   = Note.new("/vault/kept.md")
        local gone   = Note.new("/vault/gone.md")
        nb:add_note(kept.id, "vault")
        nb:add_note(gone.id, "vault")

        NotebookManager.sync_all()

        t.is_true(nm.is_present(kept.id))
        t.is_false(nm.is_present(gone.id))
        t.contains(nb.subfolders[1].notes, kept.id)
        t.not_contains(nb.subfolders[1].notes, gone.id)
    end)
end)

-- ─── sync_all: deleted/renamed notebook folders ──────────────────────────────

t.describe("NotebookManager.sync_all > notebook folder deleted or renamed externally", function()
    t.it("drops the notebook when its root folder no longer exists", function()
        local NotebookManager, Notebook = fresh({}) -- /vault does not exist
        Notebook.new("vault", "/vault")

        NotebookManager.sync_all()

        -- if the old notebook is still registered this would raise
        -- "notebook with this name is already present!"
        t.no_error(function() Notebook.new("vault", "/vault-recreated") end)
    end)

    t.it("does not touch a real notebook whose folder still exists", function()
        local NotebookManager, Notebook = fresh({ ["/vault"] = "directory" })
        Notebook.new("vault", "/vault")

        NotebookManager.sync_all()

        t.has_error_matching(function() Notebook.new("vault", "/vault") end,
            "already present")
    end)
end)

-- ─── sync_all: virtual notebooks ─────────────────────────────────────────────

t.describe("NotebookManager.sync_all > virtual notebooks", function()
    t.it("are skipped entirely, even if they reference notes and disk is empty", function()
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/elsewhere/real.md"] = "file",
        })
        local nb = Notebook.new("scratch") -- no path => virtual
        local note = Note.new("/elsewhere/real.md")
        nb:add_note(note.id, "scratch")

        t.no_error(function() NotebookManager.sync_all() end)

        t.is_true(nm.is_present(note.id))
        t.contains(nb.subfolders[1].notes, note.id)
    end)
end)

-- ─── sync_all: picking up files created outside noted ────────────────────────

t.describe("NotebookManager.sync_all > untracked markdown files on disk", function()
    t.it("registers a .md file the user created directly (e.g. via Obsidian)", function()
        local NotebookManager, Notebook, _, nm = fresh({
            ["/vault"]              = "directory",
            ["/vault/new-note.md"]  = "file",
        })
        local nb = Notebook.new("vault", "/vault")

        NotebookManager.sync_all()

        local found_id
        for id, note in pairs(nm.get_notes()) do
            if note.path == "/vault/new-note.md" then found_id = id end
        end
        t.not_nil(found_id, "expected a note to be created for new-note.md")
        t.contains(nb.subfolders[1].notes, found_id)
    end)

    t.it("does not create a duplicate note for a file already tracked", function()
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/vault"]               = "directory",
            ["/vault/existing.md"]   = "file",
        })
        local nb   = Notebook.new("vault", "/vault")
        local note = Note.new("/vault/existing.md")
        nb:add_note(note.id, "vault")

        NotebookManager.sync_all()

        local count = 0
        for _ in pairs(nm.get_notes()) do count = count + 1 end
        t.eq(count, 1)
        t.eq(#nb.subfolders[1].notes, 1)
    end)

    t.it("ignores non-markdown files, e.g. images/attachments dropped into the vault", function()
        local NotebookManager, Notebook, _, nm = fresh({
            ["/vault"]              = "directory",
            ["/vault/diagram.png"]  = "file",
            ["/vault/notes.pdf"]    = "file",
        })
        local nb = Notebook.new("vault", "/vault")

        NotebookManager.sync_all()

        local count = 0
        for _ in pairs(nm.get_notes()) do count = count + 1 end
        t.eq(count, 0)
        t.eq(#nb.subfolders[1].notes, 0)
    end)

    t.it("registers new files inside an already-tracked nested subfolder with the correct subpath", function()
        local NotebookManager, Notebook, _, nm = fresh({
            ["/vault"]                    = "directory",
            ["/vault/Projects"]           = "directory",
            ["/vault/Projects/plan.md"]   = "file",
        })
        local nb = Notebook.new("vault", "/vault")
        nb:create_subfolder("Projects")

        NotebookManager.sync_all()

        local found_id
        for id, note in pairs(nm.get_notes()) do
            if note.path == "/vault/Projects/plan.md" then found_id = id end
        end
        t.not_nil(found_id)
        t.contains(nb.subfolders[2].notes, found_id)
        t.not_contains(nb.subfolders[1].notes, found_id)
    end)

    t.it("does not discover a brand-new subfolder the user created outside noted", function()
        -- Obsidian users create folders constantly; sync_all only walks
        -- subfolders it already knows about, so a wholly new folder (and
        -- anything inside it) is invisible until the user registers it.
        local NotebookManager, Notebook, _, nm = fresh({
            ["/vault"]                     = "directory",
            ["/vault/NewFolder"]           = "directory",
            ["/vault/NewFolder/note.md"]   = "file",
        })
        Notebook.new("vault", "/vault")

        NotebookManager.sync_all()

        local count = 0
        for _ in pairs(nm.get_notes()) do count = count + 1 end
        t.eq(count, 0, "sync_all should not walk unregistered subfolders")
    end)
end)

-- ─── sync_all: renames / moves (delete+create from noted's point of view) ────

t.describe("NotebookManager.sync_all > external rename or move of a note", function()
    t.it("treats a rename as delete-then-create, discarding the old note's link data", function()
        -- Obsidian's rename is just a filesystem rename; from noted's side,
        -- since it wasn't the one who moved the file, this looks identical
        -- to "old file deleted" + "new file appeared".
        --
        -- NOTE: because the delete and the create happen in the same
        -- sync_all() pass, and NoteManager.assign() hands out freed ids
        -- before minting new ones, the replacement note can end up with
        -- the *same numeric id* as the note it replaced. So
        -- nm.is_present(old.id) is NOT a reliable way to check whether the
        -- old note survived — check its content (outlinks/path) instead.
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/vault"]              = "directory",
            ["/vault/renamed.md"]   = "file", -- new name only; original.md is gone
        })
        local nb = Notebook.new("vault", "/vault")
        local old = Note.new("/vault/original.md")
        table.insert(old.outlinks, 999) -- simulate existing link data

        nb:add_note(old.id, "vault")

        NotebookManager.sync_all()

        t.eq(#nb.subfolders[1].notes, 1)
        local new_note = nm.get_notes()[nb.subfolders[1].notes[1]]
        t.eq(new_note.path, "/vault/renamed.md")
        t.eq(new_note.outlinks, {}) -- link history did not survive the rename
    end)

    t.it("treats an external move between tracked subfolders the same way", function()
        local NotebookManager, Notebook, Note, nm = fresh({
            ["/vault"]                      = "directory",
            ["/vault/Archive"]              = "directory",
            ["/vault/Archive/moved.md"]     = "file", -- moved here; not at root anymore
        })
        local nb = Notebook.new("vault", "/vault")
        nb:create_subfolder("Archive")
        local old = Note.new("/vault/moved.md")
        nb:add_note(old.id, "vault")

        NotebookManager.sync_all()

        -- (see the rename test above for why we don't assert on old.id here)
        t.eq(#nb.subfolders[1].notes, 0) -- pruned from the old subfolder
        t.eq(#nb.subfolders[2].notes, 1) -- picked up fresh in the new one

        local new_note = nm.get_notes()[nb.subfolders[2].notes[1]]
        t.eq(new_note.path, "/vault/Archive/moved.md")
    end)
end)

-- ─── sync_all: filesystem errors ─────────────────────────────────────────────

t.describe("NotebookManager.sync_all > filesystem errors", function()
    t.it("does not crash when a subfolder can't be read (e.g. permissions)", function()
        local NotebookManager, Notebook = fresh(
            {
                ["/vault"]        = "directory",
                ["/vault/Locked"] = "directory",
            },
            { scandir_errors = { ["/vault/Locked"] = "EACCES: permission denied" } }
        )
        local nb = Notebook.new("vault", "/vault")
        nb:create_subfolder("Locked")

        t.no_error(function() NotebookManager.sync_all() end)
        t.eq(#nb.subfolders[2].notes, 0)
    end)
end)

-- ─── sync_all: multiple notebooks stay independent ───────────────────────────

t.describe("NotebookManager.sync_all > multiple notebooks", function()
    t.it("syncing one notebook's deleted folder does not affect another", function()
        local NotebookManager, Notebook = fresh({
            ["/work"] = "directory", -- only "work" survives; "personal" is gone
        })
        Notebook.new("work", "/work")
        Notebook.new("personal", "/personal")

        NotebookManager.sync_all()

        t.has_error_matching(function() Notebook.new("work", "/work") end, "already present")
        t.no_error(function() Notebook.new("personal", "/personal") end)
    end)
end)

-- ─── sync_curr_buf: the Neovim-side counterpart ──────────────────────────────
-- Complements the above: this is what happens when the *user* (not an
-- external tool) creates and saves a new file from inside Neovim.

t.describe("NotebookManager.sync_curr_buf", function()
    local function with_buf(path, fn)
        vim.api = vim.api or {}
        vim.api.nvim_buf_get_name = function(_) return path end
        fn()
    end

    t.it("registers a new file saved at a notebook's root", function()
        local NotebookManager, Notebook, _, nm = fresh({ ["/vault"] = "directory" })
        local nb = Notebook.new("vault", "/vault")

        with_buf("/vault/today.md", function()
            local ok, err = NotebookManager.sync_curr_buf()
            t.is_true(ok)
            t.is_nil(err)
        end)

        t.eq(#nb.subfolders[1].notes, 1)
    end)

    t.it("registers a new file saved inside a nested subfolder with the right subpath", function()
        local NotebookManager, Notebook, _, nm = fresh({
            ["/vault"]           = "directory",
            ["/vault/Projects"]  = "directory",
        })
        local nb = Notebook.new("vault", "/vault")
        nb:create_subfolder("Projects")

        with_buf("/vault/Projects/plan.md", function()
            NotebookManager.sync_curr_buf()
        end)

        t.eq(#nb.subfolders[2].notes, 1)
        local note = nm.get_notes()[nb.subfolders[2].notes[1]]
        t.eq(note.path, "/vault/Projects/plan.md")
    end)

    t.it("is a no-op for a file that is already tracked", function()
        local NotebookManager, Notebook, Note, nm = fresh({ ["/vault"] = "directory" })
        local nb = Notebook.new("vault", "/vault")
        local note = Note.new("/vault/today.md")
        nb:add_note(note.id, "vault")

        with_buf("/vault/today.md", function()
            local ok = NotebookManager.sync_curr_buf()
            t.is_true(ok)
        end)

        t.eq(#nb.subfolders[1].notes, 1)
    end)

    t.it("errors when the buffer's file does not belong to any known notebook", function()
        local NotebookManager = fresh({ ["/vault"] = "directory" })

        with_buf("/somewhere/else/note.md", function()
            local ok, err = NotebookManager.sync_curr_buf()
            t.is_false(ok)
            t.not_nil(err)
        end)
    end)

    t.it("errors when the buffer has no file", function()
        local NotebookManager = fresh({})

        with_buf("", function()
            local ok, err = NotebookManager.sync_curr_buf()
            t.is_false(ok)
            t.not_nil(err)
        end)
    end)
end)

t.run()
