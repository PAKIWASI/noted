local t = require("tests.runner")

-- NoteManager is a stateful singleton — clear package.loaded between suites
-- so each describe block starts from a clean slate.
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

    t.it("errors on double-free", function()
        local id = nm.assign()
        nm.deassign(id)
        t.has_error(function() nm.deassign(id) end)
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
end)

-- ─── id_struct round-trip (serialisation seam) ───────────────────────────────

t.describe("note_manager id_struct round-trip", function()
    t.it("restores counter and free_ids", function()
        local nm1 = fresh()
        nm1.assign()           -- id 0, counter → 1
        local id = nm1.assign() -- id 1, counter → 2
        nm1.deassign(id)       -- free_ids has 1

        local s = nm1.get_id_struct()
        t.eq(s.counter, 2)
        t.is_true(s.free_ids[id])

        local nm2 = fresh()
        nm2.set_id_struct(s)

        -- recycled id comes back first
        t.eq(nm2.assign(), id)
        -- then the counter continues
        t.eq(nm2.assign(), 2)
    end)
end)
