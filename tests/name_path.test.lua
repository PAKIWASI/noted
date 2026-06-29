local t = require("tests.runner")

local u = require("lua.noted.utils.name_path")

-- ─── string_valid ─────────────────────────────────────────────────────────────

t.describe("utils.string_valid", function()
    t.it("false for nil", function()
        t.is_false(u.string_valid(nil))
    end)

    t.it("false for empty string", function()
        t.is_false(u.string_valid(""))
    end)

    t.it("true for any non-empty string", function()
        t.is_true(u.string_valid("x"))
        t.is_true(u.string_valid("hello world"))
    end)

    t.it("true for whitespace-only string", function()
        t.is_true(u.string_valid("   "))
    end)

    t.it("true for strings with special characters", function()
        t.is_true(u.string_valid("/path/to/file.md"))
    end)
end)

-- ─── fullpath_valid ───────────────────────────────────────────────────────────

t.describe("utils.fullpath_valid", function()
    t.it("accepts a valid absolute .md path", function()
        t.is_true(u.fullpath_valid("/home/user/notes/aws.md"))
    end)

    t.it("accepts dot-hierarchy names", function()
        t.is_true(u.fullpath_valid("/notes/aws.ec2.security-groups.md"))
    end)

    t.it("accepts a root-level .md file", function()
        t.is_true(u.fullpath_valid("/note.md"))
    end)

    t.it("rejects a relative path", function()
        t.is_false(u.fullpath_valid("notes/aws.md"))
    end)

    t.it("rejects missing .md extension", function()
        t.is_false(u.fullpath_valid("/home/user/notes/aws"))
    end)

    t.it("rejects .md that is not at the end", function()
        t.is_false(u.fullpath_valid("/home/user/notes.md/aws"))
    end)

    t.it("rejects a .md directory followed by a file without extension", function()
        t.is_false(u.fullpath_valid("/notes.md/child"))
    end)

    t.it("rejects nil", function()
        t.is_false(u.fullpath_valid(nil))
    end)

    t.it("rejects empty string", function()
        t.is_false(u.fullpath_valid(""))
    end)

    t.it("rejects a bare slash", function()
        t.is_false(u.fullpath_valid("/"))
    end)
end)

-- ─── title_valid ──────────────────────────────────────────────────────────────

t.describe("utils.title_valid", function()
    t.it("accepts simple names", function()
        t.is_true(u.title_valid("aws"))
    end)

    t.it("accepts dot-hierarchy names", function()
        t.is_true(u.title_valid("aws.ec2.security-groups"))
    end)

    t.it("accepts names with dashes", function()
        t.is_true(u.title_valid("my-note"))
    end)

    t.it("rejects titles with slashes", function()
        t.is_false(u.title_valid("aws/ec2"))
    end)

    t.it("rejects titles ending in .md", function()
        t.is_false(u.title_valid("aws.md"))
    end)

    t.it("rejects nil", function()
        t.is_false(u.title_valid(nil))
    end)

    t.it("rejects empty string", function()
        t.is_false(u.title_valid(""))
    end)
end)

-- ─── extract_title ────────────────────────────────────────────────────────────

t.describe("utils.extract_title", function()
    t.it("strips directory and .md extension", function()
        t.eq(u.extract_title("/home/user/notes/aws.ec2.md"), "aws.ec2")
    end)

    t.it("handles root-level file", function()
        t.eq(u.extract_title("/note.md"), "note")
    end)

    t.it("handles deeply nested path", function()
        t.eq(u.extract_title("/a/b/c/d.md"), "d")
    end)

    t.it("returns empty string for path with no filename", function()
        t.eq(u.extract_title(""), "")
    end)

    t.it("returns filename as-is if no .md extension", function()
        t.eq(u.extract_title("/notes/aws"), "aws")
    end)

    t.it("handles filename with multiple dots", function()
        t.eq(u.extract_title("/notes/a.b.c.md"), "a.b.c")
    end)
end)

-- ─── extract_dir ──────────────────────────────────────────────────────────────

t.describe("utils.extract_dir", function()
    t.it("returns directory with trailing slash", function()
        t.eq(u.extract_dir("/home/user/notes/aws.md"), "/home/user/notes/")
    end)

    t.it("handles root-level file", function()
        t.eq(u.extract_dir("/note.md"), "/")
    end)

    t.it("handles deeply nested path", function()
        t.eq(u.extract_dir("/a/b/c/d.md"), "/a/b/c/")
    end)

    t.it("returns empty string for bare filename", function()
        t.eq(u.extract_dir("note.md"), "")
    end)
end)

-- ─── slugify ──────────────────────────────────────────────────────────────────

t.describe("utils.slugify", function()
    t.it("lowercases and replaces spaces with dashes", function()
        t.eq(u.slugify("Hello World"), "hello-world")
    end)

    t.it("strips non-alphanumeric characters", function()
        t.eq(u.slugify("AWS: EC2!"), "aws-ec2")
    end)

    t.it("collapses multiple spaces into one dash", function()
        t.eq(u.slugify("a  b"), "a-b")
    end)

    t.it("leaves existing dashes alone", function()
        t.eq(u.slugify("security-groups"), "security-groups")
    end)

    t.it("handles already lowercase input", function()
        t.eq(u.slugify("hello"), "hello")
    end)

    t.it("strips leading and trailing punctuation", function()
        t.eq(u.slugify("!hello!"), "hello")
    end)

    t.it("empty string returns empty string", function()
        t.eq(u.slugify(""), "")
    end)

    t.it("strips all non-alphanumeric except dashes", function()
        t.eq(u.slugify("a@b#c$d"), "abcd")
    end)
end)

-- ─── get_extension ────────────────────────────────────────────────────────────

t.describe("utils.get_extension", function()
    t.it("returns md for a .md file", function()
        t.eq(u.get_extension("/notes/aws.md"), "md")
    end)

    t.it("returns nil for path with no extension", function()
        t.is_nil(u.get_extension("/notes/aws"))
    end)

    t.it("returns nil for nil input", function()
        t.is_nil(u.get_extension(nil))
    end)

    t.it("returns the last extension for multiple dots", function()
        t.eq(u.get_extension("/notes/aws.ec2.md"), "md")
    end)

    t.it("returns txt for a .txt file", function()
        t.eq(u.get_extension("/notes/readme.txt"), "txt")
    end)
end)

-- ─── dir_exists ───────────────────────────────────────────────────────────────
-- The runner stub returns {type="file"} for any io.open-able path, never
-- {type="directory"}, so dir_exists will always return false in the test env.
-- These tests document that boundary explicitly.

t.describe("utils.dir_exists", function()
    t.it("returns false when fs_stat returns nil", function()
        t.is_false(u.dir_exists("/tmp/noted-nonexistent-dir-xyz"))
    end)

    t.it("returns false when fs_stat returns file type (stub limitation)", function()
        -- the runner stub can't return type="directory", so this is always false
        -- in the test environment; the logic is still exercised
        t.is_false(u.dir_exists("tests/runner.lua"))
    end)
end)

t.run()
