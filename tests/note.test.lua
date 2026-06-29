local t = require("tests.runner")

-- Both Note and NoteManager are coupled — reset both together.
local function fresh()
    package.loaded["noted.structures.note_manager"] = nil
    package.loaded["noted.structures.note"]         = nil
    local Note = require("noted.structures.note")
    local nm   = require("noted.structures.note_manager")
    return Note, nm
end

-- stub fs so file operations don't touch disk
local function fresh_with_fs(fs_stub)
    package.loaded["noted.structures.note_manager"] = nil
    package.loaded["noted.structures.note"]         = nil
    package.loaded["noted.utils.fs"]                = nil
    package.loaded["noted.utils.fs"]                = fs_stub
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

    t.it("ids are sequential starting from 0", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        t.eq(a.id, 0)
        t.eq(b.id, 1)
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

    t.it("freed id is recycled by the next new note", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local id = a.id
        a:delete()
        local b = Note.new("/notes/b.md")
        t.eq(b.id, id)
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

    t.it("one source can link to multiple targets", function()
        local Note = fresh()
        local src = Note.new("/notes/a.md")
        local b   = Note.new("/notes/b.md")
        local c   = Note.new("/notes/c.md")
        src:link(b)
        src:link(c)
        t.eq(#src.outlinks, 2)
        t.contains(src.outlinks, b.id)
        t.contains(src.outlinks, c.id)
    end)

    t.it("multiple sources can link to the same target", function()
        local Note = fresh()
        local a   = Note.new("/notes/a.md")
        local b   = Note.new("/notes/b.md")
        local tgt = Note.new("/notes/tgt.md")
        a:link(tgt)
        b:link(tgt)
        t.eq(#tgt.backlinks, 2)
        t.contains(tgt.backlinks, a.id)
        t.contains(tgt.backlinks, b.id)
    end)

    t.it("link does not affect unrelated notes", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        local c = Note.new("/notes/c.md")
        a:link(b)
        t.eq(c.outlinks,  {})
        t.eq(c.backlinks, {})
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

    t.it("is_parent finds correct target among multiple outlinks", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        local c = Note.new("/notes/c.md")
        a:link(b)
        a:link(c)
        t.is_true(a:is_parent(b.id))
        t.is_true(a:is_parent(c.id))
    end)

    t.it("is_child finds correct source among multiple backlinks", function()
        local Note = fresh()
        local a   = Note.new("/notes/a.md")
        local b   = Note.new("/notes/b.md")
        local tgt = Note.new("/notes/tgt.md")
        a:link(tgt)
        b:link(tgt)
        t.is_true(tgt:is_child(a.id))
        t.is_true(tgt:is_child(b.id))
    end)

    t.it("is_parent returns false for an unrelated note after several links", function()
        local Note = fresh()
        local a = Note.new("/notes/a.md")
        local b = Note.new("/notes/b.md")
        local c = Note.new("/notes/c.md")
        a:link(b)
        t.is_false(a:is_parent(c.id))
    end)
end)

-- ─── Note:rename ─────────────────────────────────────────────────────────────

t.describe("Note:rename", function()
    t.it("updates self.path on success", function()
        local Note = fresh_with_fs({
            rename = function(_, _) return true end,
            kind   = function(_)    return nil  end,
            write  = function(_, _) return true end,
            read   = function(_)    return nil  end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        n:rename("/notes/b.md")
        t.eq(n.path, "/notes/b.md")
    end)

    t.it("does not update self.path on failure", function()
        local Note = fresh_with_fs({
            rename = function(_, _) return false, "rename failed" end,
            kind   = function(_)    return nil end,
            write  = function(_, _) return true end,
            read   = function(_)    return nil end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        n:rename("/notes/b.md")
        t.eq(n.path, "/notes/a.md")
    end)

    t.it("returns true on success", function()
        local Note = fresh_with_fs({
            rename = function(_, _) return true end,
            kind   = function(_)    return nil end,
            write  = function(_, _) return true end,
            read   = function(_)    return nil end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        local ok, err = n:rename("/notes/b.md")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error string on failure", function()
        local Note = fresh_with_fs({
            rename = function(_, _) return false, "disk error" end,
            kind   = function(_)    return nil end,
            write  = function(_, _) return true end,
            read   = function(_)    return nil end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        local ok, err = n:rename("/notes/b.md")
        t.is_false(ok)
        t.eq(err, "disk error")
    end)
end)

-- ─── Note:write / Note:read ──────────────────────────────────────────────────

t.describe("Note:write / Note:read", function()
    t.it("write delegates to fs.write with note path", function()
        local written_path, written_content
        local Note = fresh_with_fs({
            write  = function(p, c) written_path = p; written_content = c; return true end,
            read   = function(_)    return nil end,
            kind   = function(_)    return nil end,
            rename = function(_, _) return true end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        n:write("hello")
        t.eq(written_path,    "/notes/a.md")
        t.eq(written_content, "hello")
    end)

    t.it("read delegates to fs.read with note path", function()
        local read_path
        local Note = fresh_with_fs({
            write  = function(_, _) return true end,
            read   = function(p)    read_path = p; return "content", nil end,
            kind   = function(_)    return nil end,
            rename = function(_, _) return true end,
            delete = function(_)    return true end,
        })
        local n = Note.new("/notes/a.md")
        local content = n:read()
        t.eq(read_path, "/notes/a.md")
        t.eq(content,   "content")
    end)
end)

t.run()
