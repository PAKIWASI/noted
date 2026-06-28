local t = require("tests.runner")

-- Both Note and NoteManager are coupled — reset both together.
local function fresh()
    package.loaded["noted.structures.note_manager"] = nil
    package.loaded["noted.structures.note"]         = nil
    local Note = require("noted.structures.note")
    local nm   = require("noted.structures.note_manager")
    return Note, nm
end

-- ─── Note.new ────────────────────────────────────────────────────────────────

t.describe("Note.new", function()
    t.it("registers the note in NoteManager", function()
        local Note, nm = fresh()
        local n = Note.new("/notes/aws.md")
        t.is_true(nm.is_present(n.id))
    end)

    t.it("initialises outlinks and backlinks as empty tables", function()
        local Note = fresh()
        local n = Note.new("/notes/aws.md")
        t.eq(n.outlinks,  {})
        t.eq(n.backlinks, {})
    end)

    t.it("stores the path", function()
        local Note = fresh()
        local n = Note.new("/notes/aws.md")
        t.eq(n.path, "/notes/aws.md")
    end)

    t.it("assigns unique ids to different notes", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        t.neq(a.id, b.id)
    end)
end)

-- ─── Note:delete ─────────────────────────────────────────────────────────────

t.describe("Note:delete", function()
    t.it("removes the note from NoteManager", function()
        local Note, nm = fresh()
        local n = Note.new("/notes/aws.md")
        local id = n.id
        n:delete()
        t.is_false(nm.is_present(id))
    end)

    t.it("frees the id for reuse", function()
        local Note, nm = fresh()
        local n  = Note.new("/notes/aws.md")
        local id = n.id
        n:delete()
        t.is_true(nm.is_free(id))
    end)
end)

-- ─── Note:link ───────────────────────────────────────────────────────────────

t.describe("Note:link", function()
    t.it("adds to source outlinks and target backlinks", function()
        local Note = fresh()
        local src = Note.new("/notes/a.md")
        local tgt = Note.new("/notes/b.md")
        src:link(tgt)
        t.contains(src.outlinks,  tgt.id)
        t.contains(tgt.backlinks, src.id)
    end)

    t.it("does not add reverse entries", function()
        local Note = fresh()
        local src = Note.new("/notes/a.md")
        local tgt = Note.new("/notes/b.md")
        src:link(tgt)
        t.eq(src.backlinks, {})
        t.eq(tgt.outlinks,  {})
    end)

    t.it("errors when linking a note to itself", function()
        local Note = fresh()
        local n = Note.new("/notes/a.md")
        t.has_error(function() n:link(n) end)
    end)
end)

-- ─── Note:is_parent / is_child ───────────────────────────────────────────────

t.describe("Note:is_parent / is_child", function()
    t.it("is_parent returns true after link", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        a:link(b)
        t.is_true(a:is_parent(b.id))
    end)

    t.it("is_parent returns false when no link", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        t.is_false(a:is_parent(b.id))
    end)

    t.it("is_child returns true for the target", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        a:link(b)
        t.is_true(b:is_child(a.id))
    end)

    t.it("link is not symmetric", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        a:link(b)
        t.is_false(b:is_parent(a.id))
        t.is_false(a:is_child(b.id))
    end)
end)
