local t = require("tests.runner")

local nl = require("lua.noted.utils.note_links")

-- ─── find_links ────────────────────────────────────────────────────────────

t.describe("note_links.find_links", function()
    t.it("returns empty table for a line with no links", function()
        t.eq(nl.find_links("just plain text"), {})
    end)

    t.it("finds a single link and its span", function()
        local links = nl.find_links("see [[aws]] for details")
        t.eq(#links, 1)
        t.eq(links[1].inner, "aws")
        t.eq(links[1].s, 5)
        t.eq(links[1].e, 11)
    end)

    t.it("finds multiple links on the same line", function()
        local links = nl.find_links("[[a]] and [[b]]")
        t.eq(#links, 2)
        t.eq(links[1].inner, "a")
        t.eq(links[2].inner, "b")
    end)

    t.it("does not greedily span across two separate links", function()
        -- a naive greedy pattern would capture "a]] and [[b" as one match
        local links = nl.find_links("[[a]] and [[b]]")
        t.eq(links[1].inner, "a")
        t.eq(links[2].inner, "b")
    end)

    t.it("handles a link with an alias", function()
        local links = nl.find_links("[[aws|Amazon Web Services]]")
        t.eq(#links, 1)
        t.eq(links[1].inner, "aws|Amazon Web Services")
    end)

    t.it("handles an empty link", function()
        local links = nl.find_links("[[]]")
        t.eq(#links, 1)
        t.eq(links[1].inner, "")
    end)

    t.it("handles adjacent links with no space between", function()
        local links = nl.find_links("[[a]][[b]]")
        t.eq(#links, 2)
        t.eq(links[1].inner, "a")
        t.eq(links[2].inner, "b")
    end)
end)

-- ─── parse_inner ───────────────────────────────────────────────────────────

t.describe("note_links.parse_inner", function()
    t.it("returns target with nil alias when there's no pipe", function()
        local target, alias = nl.parse_inner("aws")
        t.eq(target, "aws")
        t.is_nil(alias)
    end)

    t.it("splits target and alias on pipe", function()
        local target, alias = nl.parse_inner("aws|Amazon Web Services")
        t.eq(target, "aws")
        t.eq(alias, "Amazon Web Services")
    end)

    t.it("trims whitespace around target and alias", function()
        local target, alias = nl.parse_inner("  aws  |  AWS  ")
        t.eq(target, "aws")
        t.eq(alias, "AWS")
    end)

    t.it("returns nil for empty inner text", function()
        t.is_nil(nl.parse_inner(""))
    end)

    t.it("returns nil target when only a pipe with empty target is given", function()
        t.is_nil(nl.parse_inner("|alias"))
    end)

    t.it("treats an empty alias as nil", function()
        local target, alias = nl.parse_inner("aws|")
        t.eq(target, "aws")
        t.is_nil(alias)
    end)
end)

-- ─── is_valid_inner ────────────────────────────────────────────────────────

t.describe("note_links.is_valid_inner", function()
    t.it("true for a plain target", function()
        t.is_true(nl.is_valid_inner("aws"))
    end)

    t.it("true for target with alias", function()
        t.is_true(nl.is_valid_inner("aws|AWS"))
    end)

    t.it("false for empty inner", function()
        t.is_false(nl.is_valid_inner(""))
    end)

    t.it("false for nil", function()
        t.is_false(nl.is_valid_inner(nil))
    end)

    t.it("false when there's more than one pipe", function()
        t.is_false(nl.is_valid_inner("aws|AWS|extra"))
    end)

    t.it("false when target is empty even with alias", function()
        t.is_false(nl.is_valid_inner("|AWS"))
    end)
end)

-- ─── get_link_at ───────────────────────────────────────────────────────────

t.describe("note_links.get_link_at", function()
    t.it("returns the link whose span contains the column", function()
        local line = "see [[aws]] here"
        local link = nl.get_link_at(line, 7)
        t.not_nil(link)
        t.eq(link.inner, "aws")
    end)

    t.it("returns nil for a column outside any link", function()
        local line = "see [[aws]] here"
        t.is_nil(nl.get_link_at(line, 2))
    end)

    t.it("picks the correct link among several", function()
        local line = "[[a]] and [[b]]"
        local link = nl.get_link_at(line, 13) -- inside [[b]]
        t.eq(link.inner, "b")
    end)

    t.it("column exactly on the closing bracket still counts as inside", function()
        local line = "[[aws]]"
        local link = nl.get_link_at(line, 7) -- second ']'
        t.not_nil(link)
    end)
end)

-- ─── format_link / insert_link ─────────────────────────────────────────────

t.describe("note_links.format_link", function()
    t.it("formats a plain link", function()
        t.eq(nl.format_link("aws"), "[[aws]]")
    end)

    t.it("formats a link with alias", function()
        t.eq(nl.format_link("aws", "AWS"), "[[aws|AWS]]")
    end)

    t.it("ignores an empty-string alias", function()
        t.eq(nl.format_link("aws", ""), "[[aws]]")
    end)

    t.it("errors on empty target", function()
        t.has_error(function() nl.format_link("") end)
    end)
end)

t.describe("note_links.insert_link", function()
    t.it("inserts a link tag at the given column", function()
        local line = "see  here"
        t.eq(nl.insert_link(line, 5, "aws"), "see [[aws]] here")
    end)

    t.it("inserts at the start of the line", function()
        t.eq(nl.insert_link("hello", 1, "x"), "[[x]]hello")
    end)

    t.it("inserts at the end of the line", function()
        local line = "hello"
        t.eq(nl.insert_link(line, #line + 1, "x"), "hello[[x]]")
    end)
end)

-- ─── extract_all_targets ────────────────────────────────────────────────────

t.describe("note_links.extract_all_targets", function()
    t.it("collects targets across multiple lines", function()
        local content = "intro\n\nsee [[aws]] and [[gcp]]\nmore text [[aws]]"
        t.eq(nl.extract_all_targets(content), { "aws", "gcp" })
    end)

    t.it("dedupes repeated targets", function()
        local content = "[[aws]] [[aws]] [[aws]]"
        t.eq(nl.extract_all_targets(content), { "aws" })
    end)

    t.it("returns empty table for content with no links", function()
        t.eq(nl.extract_all_targets("just some text\nmore text"), {})
    end)

    t.it("skips malformed links", function()
        local content = "[[]] [[aws]] [[|alias]]"
        t.eq(nl.extract_all_targets(content), { "aws" })
    end)

    t.it("uses the target, not the alias", function()
        local content = "[[aws|Amazon Web Services]]"
        t.eq(nl.extract_all_targets(content), { "aws" })
    end)
end)

-- ─── find_note_by_title ─────────────────────────────────────────────────────

t.describe("note_links.find_note_by_title", function()
    local notes

    t.before_each(function()
        notes = {
            [1] = { id = 1, path = "/nb/aws.md" },
            [2] = { id = 2, path = "/nb/gcp-basics.md" },
        }
    end)

    t.it("finds a note by exact slug match", function()
        local n = nl.find_note_by_title(notes, "aws")
        t.eq(n.id, 1)
    end)

    t.it("matches case-insensitively via slugify", function()
        local n = nl.find_note_by_title(notes, "AWS")
        t.eq(n.id, 1)
    end)

    t.it("matches titles with spaces against dashed slugs", function()
        local n = nl.find_note_by_title(notes, "gcp basics")
        t.eq(n.id, 2)
    end)

    t.it("returns nil when no note matches", function()
        t.is_nil(nl.find_note_by_title(notes, "azure"))
    end)
end)

-- ─── new_note_path_for_link ─────────────────────────────────────────────────

t.describe("note_links.new_note_path_for_link", function()
    t.it("places the new note beside the linking note", function()
        t.eq(
            nl.new_note_path_for_link("/nb/general/aws.md", "New Note"),
            "/nb/general/new-note.md"
        )
    end)

    t.it("slugifies the target", function()
        t.eq(
            nl.new_note_path_for_link("/nb/aws.md", "GCP: Compute Engine!"),
            "/nb/gcp-compute-engine.md"
        )
    end)
end)

-- ─── sync_outlinks ───────────────────────────────────────────────────────────

t.describe("note_links.sync_outlinks", function()
    local function make_note(id, path, content)
        return {
            id = id,
            path = path,
            outlinks = {},
            backlinks = {},
            is_parent = function(self, other_id)
                for _, i in ipairs(self.outlinks) do
                    if i == other_id then return true end
                end
                return false
            end,
            link = function(self, other)
                table.insert(other.backlinks, self.id)
                table.insert(self.outlinks, other.id)
            end,
            read = function(self) return content end,
        }
    end

    t.it("links a new outlink found in the text", function()
        local a = make_note(1, "/nb/a.md", "see [[b]]")
        local b = make_note(2, "/nb/b.md", "")
        local notes = { [1] = a, [2] = b }

        local newly = nl.sync_outlinks(a, notes)
        t.eq(newly, { 2 })
        t.contains(a.outlinks, 2)
        t.contains(b.backlinks, 1)
    end)

    t.it("does not duplicate an already-existing outlink", function()
        local a = make_note(1, "/nb/a.md", "see [[b]]")
        local b = make_note(2, "/nb/b.md", "")
        a:link(b)
        local notes = { [1] = a, [2] = b }

        local newly = nl.sync_outlinks(a, notes)
        t.eq(newly, {})
        t.eq(#a.outlinks, 1)
    end)

    t.it("removes an outlink whose tag was deleted from the text", function()
        local a = make_note(1, "/nb/a.md", "no links anymore")
        local b = make_note(2, "/nb/b.md", "")
        a:link(b)
        local notes = { [1] = a, [2] = b }

        nl.sync_outlinks(a, notes)
        t.eq(a.outlinks, {})
        t.eq(b.backlinks, {})
    end)

    t.it("ignores a link target that can't be resolved to a note", function()
        local a = make_note(1, "/nb/a.md", "see [[nonexistent]]")
        local notes = { [1] = a }

        local newly = nl.sync_outlinks(a, notes)
        t.eq(newly, {})
        t.eq(a.outlinks, {})
    end)

    t.it("ignores a self-link", function()
        local a = make_note(1, "/nb/a.md", "see [[a]]")
        local notes = { [1] = a }

        local newly = nl.sync_outlinks(a, notes)
        t.eq(newly, {})
        t.eq(a.outlinks, {})
    end)
end)

t.run()
