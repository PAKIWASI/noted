local t = require("tests.runner")

local function fresh()
    package.loaded["noted.structures.note_manager"] = nil
    return require("noted.structures.note_manager")
end

-- ─── assign / deassign ───────────────────────────────────────────────────────

t.describe("note_manager assign/deassign", function()
    local nm

    t.before_each(function()
        nm = fresh()
    end)

    t.it("assigns ids starting from 0", function()
        t.eq(nm.assign(), 0)
        t.eq(nm.assign(), 1)
        t.eq(nm.assign(), 2)
    end)

    t.it("recycles a freed id", function()
        local id = nm.assign()
        nm.deassign(id)
        t.eq(nm.assign(), id)
    end)

    t.it("recycled id is no longer free after re-assign", function()
        local id = nm.assign()
        nm.deassign(id)
        nm.assign()   -- consumes the recycled slot
        t.is_false(nm.is_free(id))
    end)

    t.it("counter resumes after recycled ids are exhausted", function()
        local id0 = nm.assign()  -- 0
        local id1 = nm.assign()  -- 1
        nm.deassign(id0)
        nm.deassign(id1)
        nm.assign()              -- recycles one freed id
        nm.assign()              -- recycles the other
        t.eq(nm.assign(), 2)     -- counter picks up at 2
    end)

    t.it("is_free is true before any assign", function()
        t.is_true(nm.is_free(0))
    end)

    t.it("is_free is false after assign", function()
        local id = nm.assign()
        t.is_false(nm.is_free(id))
    end)

    t.it("is_free is true after deassign", function()
        local id = nm.assign()
        nm.deassign(id)
        t.is_true(nm.is_free(id))
    end)

    t.it("is_free is true for ids beyond the counter", function()
        t.is_true(nm.is_free(100))
    end)

    t.it("errors on double-free", function()
        local id = nm.assign()
        nm.deassign(id)
        t.has_error(function() nm.deassign(id) end)
    end)

    t.it("deassigning an id that was never assigned errors", function()
        t.has_error(function() nm.deassign(99) end)
    end)
end)

-- ─── add / remove / is_present ───────────────────────────────────────────────

t.describe("note_manager add/remove", function()
    local nm

    t.before_each(function()
        nm = fresh()
    end)

    t.it("is_present false for unknown id", function()
        t.is_false(nm.is_present(0))
    end)

    t.it("is_present true after add", function()
        local note = { id = nm.assign() }
        nm.add(note)
        t.is_true(nm.is_present(note.id))
    end)

    t.it("errors on duplicate add", function()
        local note = { id = nm.assign() }
        nm.add(note)
        t.has_error(function() nm.add(note) end)
    end)

    t.it("is_present false after remove", function()
        local note = { id = nm.assign() }
        nm.add(note)
        nm.remove(note.id)
        t.is_false(nm.is_present(note.id))
    end)

    t.it("errors on remove of unknown id", function()
        t.has_error(function() nm.remove(99) end)
    end)

    t.it("multiple notes are independently present", function()
        local a = { id = nm.assign() }
        local b = { id = nm.assign() }
        nm.add(a)
        nm.add(b)
        t.is_true(nm.is_present(a.id))
        t.is_true(nm.is_present(b.id))
    end)

    t.it("removing one note does not affect another", function()
        local a = { id = nm.assign() }
        local b = { id = nm.assign() }
        nm.add(a)
        nm.add(b)
        nm.remove(a.id)
        t.is_false(nm.is_present(a.id))
        t.is_true(nm.is_present(b.id))
    end)
end)

-- ─── get_notes / set_notes ───────────────────────────────────────────────────

t.describe("note_manager get_notes / set_notes", function()
    t.it("get_notes returns the live table", function()
        local nm   = fresh()
        local note = { id = nm.assign() }
        nm.add(note)
        local notes = nm.get_notes()
        t.not_nil(notes[note.id])
    end)

    t.it("get_notes reflects subsequent mutations", function()
        local nm    = fresh()
        local notes = nm.get_notes()
        local note  = { id = nm.assign() }
        nm.add(note)
        -- the table returned earlier should show the new note
        t.not_nil(notes[note.id])
    end)

    t.it("set_notes replaces the store", function()
        local nm  = fresh()
        local old = { id = nm.assign() }
        nm.add(old)

        local replacement = { [42] = { id = 42, path = "/x.md", outlinks = {}, backlinks = {} } }
        nm.set_notes(replacement)

        t.is_false(nm.is_present(old.id))
        t.is_true(nm.is_present(42))
    end)

    t.it("get_notes after set_notes returns the new table", function()
        local nm          = fresh()
        local replacement = { [7] = { id = 7, path = "/y.md", outlinks = {}, backlinks = {} } }
        nm.set_notes(replacement)
        t.not_nil(nm.get_notes()[7])
    end)
end)

-- ─── id_struct round-trip ────────────────────────────────────────────────────

t.describe("note_manager id_struct round-trip", function()
    t.it("restores counter and free_ids", function()
        local nm1 = fresh()
        nm1.assign()
        local id = nm1.assign()
        nm1.deassign(id)

        local s = nm1.get_id_struct()
        t.eq(s.counter, 2)
        t.is_true(s.free_ids[id])

        local nm2 = fresh()
        nm2.set_id_struct(s)
        t.eq(nm2.assign(), id)  -- recycled first
        t.eq(nm2.assign(), 2)   -- counter continues
    end)

    t.it("get_id_struct with no assigns returns counter 0 and empty free_ids", function()
        local nm = fresh()
        local s  = nm.get_id_struct()
        t.eq(s.counter, 0)
        t.eq(s.free_ids, {})
    end)

    t.it("set_id_struct affects is_free", function()
        local nm = fresh()
        nm.set_id_struct({ counter = 5, free_ids = { [2] = true } })
        t.is_true(nm.is_free(2))
        t.is_false(nm.is_free(3))  -- assigned (counter > 3, not in free_ids)
    end)
end)

t.run()
