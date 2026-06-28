--- Minimal test runner for pure-Lua modules (no Neovim required).
---
--- Usage:
---   lua tests/runner.lua [test_file ...]
---   lua tests/runner.lua              -- runs every *.test.lua in tests/
---
--- Writing tests:
---   local t = require("tests.runner")
---
---   t.describe("my module", function()
---       t.before_each(function() ... end)   -- optional reset between tests
---
---       t.it("does something", function()
---           t.eq(1 + 1, 2)
---           t.is_true(x)
---           t.is_false(y)
---           t.is_nil(z)
---           t.has_error(function() error("boom") end)
---           t.no_error(function() return 1 end)
---           t.contains({ 1, 2, 3 }, 2)
---       end)
---   end)
---
---   t.run()   -- call once at the end of each test file

-- ─── stub vim.* so modules load without Neovim ───────────────────────────────

-- TODO: colored output?

---@diagnostic disable
vim            = vim or {}

vim.uv         = vim.uv or {
    fs_stat = function(path)
        -- delegate to the real C stat via io.open as a best-effort stub
        local f = io.open(path, "r")
        if f then
            f:close()
            return { type = "file" }
        end
        return nil
    end
}

-- add other vim stubs here as more modules need them
-- vim.fn  = vim.fn  or {}
-- vim.api = vim.api or {}
---@diagnostic enable

-- ─── module ──────────────────────────────────────────────────────────────────

local M        = {}

-- state
local _suites  = {}    -- { name, before_each, tests[] }
local _current = nil   -- suite being defined right now

local PASS     = "✓"
local FAIL     = "✗"

-- ─── suite / test registration ───────────────────────────────────────────────

---open a named test suite (can be nested: describe inside describe appends context)
---@param name string
---@param fn function
function M.describe(name, fn)
    local parent = _current
    local suite = {
        name        = parent and (parent.name .. " > " .. name) or name,
        before_each = parent and parent.before_each or nil,
        tests       = {},
    }
    table.insert(_suites, suite)

    local prev = _current
    _current   = suite
    fn()
    _current = prev
end

---register a single test inside the current describe block
---@param name string
---@param fn function
function M.it(name, fn)
    assert(_current, "t.it() called outside of t.describe()")
    table.insert(_current.tests, { name = name, fn = fn })
end

---register a before_each hook for the current describe block
---@param fn function
function M.before_each(fn)
    assert(_current, "t.before_each() called outside of t.describe()")
    _current.before_each = fn
end

-- ─── assertions ──────────────────────────────────────────────────────────────

---deep-equality check (handles tables recursively)
---@param a any
---@param b any
---@return boolean
local function deep_eq(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do
        if not deep_eq(v, b[k]) then return false end
    end
    for k, _ in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

---pretty-print a value for failure messages
---@param v any
---@return string
local function pp(v)
    if type(v) == "string" then return '"' .. v .. '"' end
    if type(v) == "table" then
        local parts = {}
        for k, val in pairs(v) do
            table.insert(parts, tostring(k) .. "=" .. pp(val))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function fail(msg)
    error(msg, 3) -- level 3: points at the t.eq() call site in the test
end

---assert deep equality
---@param got any
---@param expected any
---@param msg? string
function M.eq(got, expected, msg)
    if not deep_eq(got, expected) then
        fail((msg or "eq failed") .. "\n    got:      " .. pp(got)
            .. "\n    expected: " .. pp(expected))
    end
end

---assert two values are not equal
---@param got any
---@param expected any
---@param msg? string
function M.neq(got, expected, msg)
    if deep_eq(got, expected) then
        fail(((msg or "neq failed: both sides are ") .. pp(got)))
    end
end

---@param v any
---@param msg? string
function M.is_true(v, msg)
    if v ~= true then fail(((msg or "expected true, got ") .. pp(v))) end
end

---@param v any
---@param msg? string
function M.is_false(v, msg)
    if v ~= false then fail(((msg or "expected false, got ") .. pp(v))) end
end

---@param v any
---@param msg? string
function M.is_nil(v, msg)
    if v ~= nil then fail(((msg or "expected nil, got ") .. pp(v))) end
end

---@param v any
---@param msg? string
function M.not_nil(v, msg)
    if v == nil then fail((msg or "expected non-nil")) end
end

---assert fn throws any error
---@param fn function
---@param msg? string
function M.has_error(fn, msg)
    local ok = pcall(fn)
    if ok then fail(msg or "expected an error but none was raised") end
end

---assert fn throws an error matching pattern
---@param fn function
---@param pattern string  Lua pattern matched against the error message
---@param msg? string
function M.has_error_matching(fn, pattern, msg)
    local ok, err = pcall(fn)
    if ok then
        fail((msg or "expected an error matching ") .. pp(pattern) .. " but none was raised")
    end
    if not tostring(err):match(pattern) then
        fail((msg or "error message mismatch")
            .. "\n    error:   " .. pp(tostring(err))
            .. "\n    pattern: " .. pp(pattern))
    end
end

---assert fn runs without error
---@param fn function
---@param msg? string
function M.no_error(fn, msg)
    local ok, err = pcall(fn)
    if not ok then fail((msg or "unexpected error") .. ": " .. tostring(err)) end
end

---assert tbl contains value (array search)
---@param tbl table
---@param value any
---@param msg? string
function M.contains(tbl, value, msg)
    for _, v in ipairs(tbl) do
        if deep_eq(v, value) then return end
    end
    fail((msg or "contains failed") .. "\n    value " .. pp(value)
        .. " not found in " .. pp(tbl))
end

---assert tbl does NOT contain value
---@param tbl table
---@param value any
---@param msg? string
function M.not_contains(tbl, value, msg)
    for _, v in ipairs(tbl) do
        if deep_eq(v, value) then
            fail((msg or "not_contains failed") .. ": found " .. pp(value))
        end
    end
end

-- ─── runner ──────────────────────────────────────────────────────────────────

---run all registered test suites and print results
---@return boolean  true if every test passed
function M.run()
    local total, passed, failed = 0, 0, 0
    local failures = {}

    for _, suite in ipairs(_suites) do
        io.write("\n" .. suite.name .. "\n")

        for _, test in ipairs(suite.tests) do
            total = total + 1

            if suite.before_each then
                local ok, err = pcall(suite.before_each)
                if not ok then
                    io.write("  " .. FAIL .. " [before_each] " .. tostring(err) .. "\n")
                    failed = failed + 1
                    table.insert(failures, {
                        suite = suite.name,
                        test  = test.name,
                        err   = "before_each failed: " .. tostring(err),
                    })
                    goto continue
                end
            end

            do
                local ok, err = pcall(test.fn)
                if ok then
                    io.write("  " .. PASS .. " " .. test.name .. "\n")
                    passed = passed + 1
                else
                    io.write("  " .. FAIL .. " " .. test.name .. "\n")
                    io.write("      " .. tostring(err):gsub("\n", "\n      ") .. "\n")
                    failed = failed + 1
                    table.insert(failures, {
                        suite = suite.name,
                        test  = test.name,
                        err   = tostring(err),
                    })
                end
            end

            ::continue::
        end
    end

    -- summary
    io.write(string.rep("─", 50) .. "\n")
    io.write(string.format("  %d/%d passed", passed, total))
    if failed > 0 then
        io.write(string.format("  %d FAILED", failed))
    end
    io.write("\n")

    -- exit code
    if failed > 0 then
        os.exit(1)
    end
    return failed == 0
end

-- ─── CLI entry point (when run directly: lua tests/runner.lua) ───────────────

-- detect if this file is the main script being run
local is_main = arg and arg[0] and arg[0]:match("runner%.lua$")

if is_main then
    -- set up require path so test files can do require("noted.xxx")
    local sep         = package.config:sub(1, 1) -- "/" on unix, "\" on windows
    local runner_path = arg[0]           -- e.g. "tests/runner.lua"
    local tests_dir   = runner_path:match("(.*" .. sep .. ")") or ("." .. sep)
    local plugin_root = tests_dir .. ".." .. sep

    package.path      = plugin_root .. "lua" .. sep .. "?.lua;"
        .. plugin_root .. "lua" .. sep .. "?" .. sep .. "init.lua;"
        .. tests_dir .. "?.lua;"          -- so test files can require("tests.runner")
        .. package.path

    -- collect test files: either from argv or by globbing tests/*.test.lua
    local files       = {}
    if #arg > 0 then
        for _, f in ipairs(arg) do
            table.insert(files, f)
        end
    else
        -- glob via ls; pattern explicitly excludes runner.lua
        local handle = io.popen("ls " .. tests_dir .. "*.test.lua 2>/dev/null")
        if handle then
            for line in handle:lines() do
                table.insert(files, line)
            end
            handle:close()
        end
    end

    if #files == 0 then
        io.write("No test files found (looking for tests/*.test.lua)\n")
        os.exit(0)
    end

    -- Register ourselves so test files' require("tests.runner") returns this
    -- already-loaded module instead of re-executing runner.lua.
    package.loaded["tests.runner"] = M

    for _, f in ipairs(files) do
        io.write("Loading " .. f .. "\n")
        local ok, err = pcall(dofile, f)
        if not ok then
            io.write("ERROR loading " .. f .. ": " .. tostring(err) .. "\n")
            os.exit(1)
        end
    end

    M.run()
end

return M
