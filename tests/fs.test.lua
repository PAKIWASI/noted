local t = require("tests.runner")

-- fs.lua calls vim.uv.* directly, so we stub vim.uv per-suite.
-- runner.lua already sets up a bare vim global.

local function fresh(uv_stub)
    package.loaded["noted.utils.fs"] = nil
    vim.uv = uv_stub
    return require("noted.utils.fs")
end

-- ─── fs.mkdir ────────────────────────────────────────────────────────────────

t.describe("fs.mkdir", function()
    t.it("returns true on success", function()
        local fs = fresh({ fs_mkdir = function(_, _) return true, nil end })
        local ok, err = fs.mkdir("/some/dir")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns true when directory already exists (EEXIST)", function()
        local fs = fresh({ fs_mkdir = function(_, _) return nil, "EEXIST: already exists" end })
        local ok, err = fs.mkdir("/some/dir")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error on other failures", function()
        local fs = fresh({ fs_mkdir = function(_, _) return nil, "EACCES: permission denied" end })
        local ok, err = fs.mkdir("/some/dir")
        t.is_false(ok)
        t.not_nil(err)
    end)

    t.it("passes path and mode 493 to fs_mkdir", function()
        local got_path, got_mode
        local fs = fresh({ fs_mkdir = function(p, m) got_path = p; got_mode = m; return true end })
        fs.mkdir("/my/dir")
        t.eq(got_path, "/my/dir")
        t.eq(got_mode, 493)
    end)
end)

-- ─── fs.mkdirp ───────────────────────────────────────────────────────────────

t.describe("fs.mkdirp", function()
    t.it("returns true when vim.fn.mkdir succeeds", function()
        vim.fn = { mkdir = function(_, _) return 1 end }
        local fs = fresh({})
        local ok, err = fs.mkdirp("/some/deep/dir")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error message when vim.fn.mkdir fails", function()
        vim.fn = { mkdir = function(_, _) return 0 end }
        local fs = fresh({})
        local ok, err = fs.mkdirp("/some/deep/dir")
        t.is_false(ok)
        t.not_nil(err)
    end)

    t.it("passes path and 'p' flag to vim.fn.mkdir", function()
        local got_path, got_flag
        vim.fn = { mkdir = function(p, f) got_path = p; got_flag = f; return 1 end }
        local fs = fresh({})
        fs.mkdirp("/a/b/c")
        t.eq(got_path, "/a/b/c")
        t.eq(got_flag, "p")
    end)
end)

-- ─── fs.rmdir ────────────────────────────────────────────────────────────────

t.describe("fs.rmdir", function()
    t.it("returns true on success", function()
        local fs = fresh({ fs_rmdir = function(_) return true, nil end })
        local ok, err = fs.rmdir("/some/dir")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error on failure", function()
        local fs = fresh({ fs_rmdir = function(_) return nil, "ENOENT: not found" end })
        local ok, err = fs.rmdir("/some/dir")
        t.is_false(ok)
        t.eq(err, "ENOENT: not found")
    end)
end)

-- ─── fs.read ─────────────────────────────────────────────────────────────────

t.describe("fs.read", function()
    t.it("returns file content on success", function()
        local fs = fresh({
            fs_open  = function(_, _, _) return 99, nil end,
            fs_fstat = function(_)       return { size = 5 }, nil end,
            fs_read  = function(_, _, _) return "hello", nil end,
            fs_close = function(_)       end,
        })
        local content, err = fs.read("/notes/a.md")
        t.eq(content, "hello")
        t.is_nil(err)
    end)

    t.it("returns nil and error when fs_open fails", function()
        local fs = fresh({
            fs_open = function(_, _, _) return nil, "ENOENT: not found" end,
        })
        local content, err = fs.read("/notes/missing.md")
        t.is_nil(content)
        t.eq(err, "ENOENT: not found")
    end)

    t.it("returns nil and error when fs_fstat fails, closes fd", function()
        local closed = false
        local fs = fresh({
            fs_open  = function(_, _, _) return 99, nil end,
            fs_fstat = function(_)       return nil, "fstat error" end,
            fs_close = function(_)       closed = true end,
        })
        local content, err = fs.read("/notes/a.md")
        t.is_nil(content)
        t.eq(err, "fstat error")
        t.is_true(closed)
    end)

    t.it("opens with read-only mode 292", function()
        local got_mode
        local fs = fresh({
            fs_open  = function(_, _, m) got_mode = m; return 99 end,
            fs_fstat = function(_)       return { size = 0 }, nil end,
            fs_read  = function(_, _, _) return "", nil end,
            fs_close = function(_)       end,
        })
        fs.read("/notes/a.md")
        t.eq(got_mode, 292)
    end)

    t.it("closes fd even after successful read", function()
        local closed = false
        local fs = fresh({
            fs_open  = function(_, _, _) return 99, nil end,
            fs_fstat = function(_)       return { size = 2 }, nil end,
            fs_read  = function(_, _, _) return "hi", nil end,
            fs_close = function(_)       closed = true end,
        })
        fs.read("/notes/a.md")
        t.is_true(closed)
    end)
end)

-- ─── fs.write ────────────────────────────────────────────────────────────────

t.describe("fs.write", function()
    t.it("returns true on success", function()
        local fs = fresh({
            fs_open   = function(_, _, _) return 99, nil end,
            fs_write  = function(_, _, _) return 5, nil end,
            fs_close  = function(_)       end,
            fs_rename = function(_, _)    return true, nil end,
            fs_unlink = function(_)       return true end,
        })
        local ok, err = fs.write("/notes/a.md", "hello")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("writes to a .tmp file first", function()
        local opened_path
        local fs = fresh({
            fs_open   = function(p, _, _) opened_path = p; return 99, nil end,
            fs_write  = function(_, _, _) return 5, nil end,
            fs_close  = function(_)       end,
            fs_rename = function(_, _)    return true, nil end,
            fs_unlink = function(_)       return true end,
        })
        fs.write("/notes/a.md", "hello")
        t.eq(opened_path, "/notes/a.md.tmp")
    end)

    t.it("renames tmp to final path on success", function()
        local renamed_src, renamed_dst
        local fs = fresh({
            fs_open   = function(_, _, _)    return 99, nil end,
            fs_write  = function(_, _, _)    return 5, nil end,
            fs_close  = function(_)          end,
            fs_rename = function(src, dst)   renamed_src = src; renamed_dst = dst; return true, nil end,
            fs_unlink = function(_)          return true end,
        })
        fs.write("/notes/a.md", "hello")
        t.eq(renamed_src, "/notes/a.md.tmp")
        t.eq(renamed_dst, "/notes/a.md")
    end)

    t.it("returns false and error when fs_open fails", function()
        local fs = fresh({
            fs_open = function(_, _, _) return nil, "EACCES: permission denied" end,
        })
        local ok, err = fs.write("/notes/a.md", "hello")
        t.is_false(ok)
        t.eq(err, "EACCES: permission denied")
    end)

    t.it("unlinks tmp and returns false when fs_write fails", function()
        local unlinked
        local fs = fresh({
            fs_open   = function(_, _, _) return 99, nil end,
            fs_write  = function(_, _, _) return nil, "write error" end,
            fs_close  = function(_)       end,
            fs_unlink = function(p)       unlinked = p; return true end,
            fs_rename = function(_, _)    return true end,
        })
        local ok, err = fs.write("/notes/a.md", "hello")
        t.is_false(ok)
        t.eq(err, "write error")
        t.eq(unlinked, "/notes/a.md.tmp")
    end)

    t.it("opens tmp with write mode 420", function()
        local got_mode
        local fs = fresh({
            fs_open   = function(_, _, m) got_mode = m; return 99 end,
            fs_write  = function(_, _, _) return 5, nil end,
            fs_close  = function(_)       end,
            fs_rename = function(_, _)    return true end,
            fs_unlink = function(_)       return true end,
        })
        fs.write("/notes/a.md", "data")
        t.eq(got_mode, 420)
    end)
end)

-- ─── fs.delete ───────────────────────────────────────────────────────────────

t.describe("fs.delete", function()
    t.it("returns true on success", function()
        local fs = fresh({ fs_unlink = function(_) return true, nil end })
        local ok, err = fs.delete("/notes/a.md")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error on failure", function()
        local fs = fresh({ fs_unlink = function(_) return nil, "ENOENT: not found" end })
        local ok, err = fs.delete("/notes/a.md")
        t.is_false(ok)
        t.eq(err, "ENOENT: not found")
    end)

    t.it("passes the correct path to fs_unlink", function()
        local got_path
        local fs = fresh({ fs_unlink = function(p) got_path = p; return true end })
        fs.delete("/notes/a.md")
        t.eq(got_path, "/notes/a.md")
    end)
end)

-- ─── fs.rename ───────────────────────────────────────────────────────────────

t.describe("fs.rename", function()
    t.it("returns true on success", function()
        local fs = fresh({ fs_rename = function(_, _) return true, nil end })
        local ok, err = fs.rename("/a.md", "/b.md")
        t.is_true(ok)
        t.is_nil(err)
    end)

    t.it("returns false and error on failure", function()
        local fs = fresh({ fs_rename = function(_, _) return nil, "ENOENT: not found" end })
        local ok, err = fs.rename("/a.md", "/b.md")
        t.is_false(ok)
        t.eq(err, "ENOENT: not found")
    end)

    t.it("passes src and dst to fs_rename", function()
        local got_src, got_dst
        local fs = fresh({ fs_rename = function(s, d) got_src = s; got_dst = d; return true end })
        fs.rename("/old.md", "/new.md")
        t.eq(got_src, "/old.md")
        t.eq(got_dst, "/new.md")
    end)
end)

-- ─── fs.kind ─────────────────────────────────────────────────────────────────

t.describe("fs.kind", function()
    t.it("returns 'file' for a regular file", function()
        local fs = fresh({ fs_stat = function(_) return { type = "file" } end })
        t.eq(fs.kind("/notes/a.md"), "file")
    end)

    t.it("returns 'directory' for a directory", function()
        local fs = fresh({ fs_stat = function(_) return { type = "directory" } end })
        t.eq(fs.kind("/notes/"), "directory")
    end)

    t.it("returns 'file' for any non-directory type (e.g. symlink)", function()
        local fs = fresh({ fs_stat = function(_) return { type = "link" } end })
        t.eq(fs.kind("/notes/link"), "file")
    end)

    t.it("returns nil when path does not exist", function()
        local fs = fresh({ fs_stat = function(_) return nil end })
        t.is_nil(fs.kind("/nonexistent"))
    end)
end)

t.run()
