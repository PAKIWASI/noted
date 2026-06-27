local t = require("tests.runner")

-- ─── string_valid ─────────────────────────────────────────────────────────────

t.describe("utils.string_valid", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

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
end)

-- ─── fullpath_valid ───────────────────────────────────────────────────────────

t.describe("utils.fullpath_valid", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("accepts a valid absolute .md path", function()
        t.is_true(u.fullpath_valid("/home/user/notes/aws.md"))
    end)

    t.it("accepts dot-hierarchy names", function()
        t.is_true(u.fullpath_valid("/notes/aws.ec2.security-groups.md"))
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

    t.it("rejects nil", function()
        t.is_false(u.fullpath_valid(nil))
    end)

    t.it("rejects empty string", function()
        t.is_false(u.fullpath_valid(""))
    end)
end)

-- ─── title_valid ──────────────────────────────────────────────────────────────

t.describe("utils.title_valid", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("accepts simple names", function()
        t.is_true(u.title_valid("aws"))
    end)

    t.it("accepts dot-hierarchy names", function()
        t.is_true(u.title_valid("aws.ec2.security-groups"))
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
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("strips directory and .md extension", function()
        t.eq(u.extract_title("/home/user/notes/aws.ec2.md"), "aws.ec2")
    end)

    t.it("handles root-level file", function()
        t.eq(u.extract_title("/note.md"), "note")
    end)

    t.it("handles deeply nested path", function()
        t.eq(u.extract_title("/a/b/c/d.md"), "d")
    end)
end)

-- ─── extract_dir ──────────────────────────────────────────────────────────────

t.describe("utils.extract_dir", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("returns directory with trailing slash", function()
        t.eq(u.extract_dir("/home/user/notes/aws.md"), "/home/user/notes/")
    end)

    t.it("handles root-level file", function()
        t.eq(u.extract_dir("/note.md"), "/")
    end)
end)

-- ─── slugify ──────────────────────────────────────────────────────────────────

t.describe("utils.slugify", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("lowercases and replaces spaces with dashes", function()
        t.eq(u.slugify("Hello World"), "hello-world")
    end)

    t.it("strips non-alphanumeric characters", function()
        t.eq(u.slugify("AWS: EC2!"), "aws-ec2")
    end)

    t.it("collapses multiple spaces", function()
        t.eq(u.slugify("a  b"), "a-b")
    end)

    t.it("leaves existing dashes alone", function()
        t.eq(u.slugify("security-groups"), "security-groups")
    end)
end)

-- ─── join_path ────────────────────────────────────────────────────────────────

t.describe("utils.join_path", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("joins two segments", function()
        t.eq(u.join_path("/home/user", "notes"), "/home/user/notes")
    end)

    t.it("strips redundant slashes", function()
        t.eq(u.join_path("/home/user/", "/notes/"), "/home/user/notes")
    end)

    t.it("joins three segments", function()
        t.eq(u.join_path("/home", "user", "notes"), "/home/user/notes")
    end)
end)

-- ─── get_extension ────────────────────────────────────────────────────────────

t.describe("utils.get_extension", function()
    local u

    t.before_each(function()
        u = require("lua.noted.utils.name_path")
    end)

    t.it("returns md for a .md file", function()
        t.eq(u.get_extension("/notes/aws.md"), "md")
    end)

    t.it("returns nil for path with no extension", function()
        t.is_nil(u.get_extension("/notes/aws"))
    end)

    t.it("returns nil for nil input", function()
        t.is_nil(u.get_extension(nil))
    end)
end)
