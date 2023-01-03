local fs = require("lfs")
local utils = require("santoku.utils")
local co = require("santoku.co")
local str = require("santoku.string")
local gen = require("santoku.gen")

local M = {}

M.mkdirp = function (dir)
  local p0 = nil
  for p1 in dir:gmatch("([^" .. M.pathdelim .. "]+)/?") do
    if p0 then
      p1 = M.join(p0, p1)
    end
    p0 = p1
    local ok, err, code = fs.mkdir(p1)
    if not ok and code ~= 17 then
      return ok, err, code
    end
  end
  return true
end

M.exists = function (fp)
  local mode, err, code = fs.attributes(fp, "mode")
  if mode == nil and code == 2 then
    return true, false
  elseif mode ~= nil then
    return true, true
  else
    return false, err, code
  end
end

M.dir = function (dir)
  local ok, entries, state = pcall(fs.dir, dir)
  if not ok then
    return false, entries, state
  else
    local coroutine = co.make()
    return true, gen.gen(coroutine.wrap(function ()
      while true do
        local ent, state = entries(state)
        if ent == nil then
          break
        end
        coroutine.yield(ent)
      end
    end))
  end
end

-- TODO: Breadth vs depth, default to depth so
-- that directory contents are returned before
-- directories themselves
M.walk = function (dir, opts)
  local prune = (opts or {}).prune or utils.const(false)
  local prunekeep = (opts or {}).prunekeep or false
  local coroutine = co.make()
  return gen.gen(coroutine.wrap(function()
    local ok, entries = M.dir(dir)
    if not ok then
      coroutine.yield(false, entries)
    else
      for it in entries do
        if it ~= M.dirparent and it ~= M.dirthis then
          it = M.join(dir, it)
          local attr, err, code = fs.attributes(it)
          if not attr then
            coroutine.yield(false, err, code)
          elseif attr.mode == "directory" then
            if not prune(it, attr) then
              coroutine.yield(true, it, attr)
              for ok0, it0, attr0 in M.walk(it, opts) do
                coroutine.yield(ok0, it0, attr0)
              end
            elseif prunekeep then
              coroutine.yield(true, it, attr)
            end
          else
            coroutine.yield(true, it, attr)
          end
        end
      end
    end
  end))
end

-- TODO: Avoid pcall by using io.open/read
-- directly. Potentially use __gc on the
-- coroutine to ensure the file gets closed.
-- Provide binary t/f, chunk size, max line
-- size, max file size, how to handle overunning
-- max line size, etc.
M.lines = function (fp)
  local ok, iter, cd = pcall(io.lines, fp)
  if ok then
    return true, gen.gen(iter)
  else
    return false, iter, cd
  end
end

M.files = function (dir, opts)
  local recurse = (opts or {}).recurse
  local walkopts = {}
  if not recurse then
    walkopts.prune = function (it, attr)
      return attr.mode == "directory"
    end
  end
  return M.walk(dir, walkopts)
end

M.dirs = function (dir)
  local recurse = (opts or {}).recurse
  local walkopts = { prunekeep = true }
  if not recurse then
    walkopts.prune = function (it, attr)
      return attr.mode == "directory"
    end
  end
  return M.walk(dir, walkopts)
    :filter(function (ok, it, attr)
      return not ok or attr.mode == "directory"
    end)
end

-- TODO: Dynamically figure this out for each OS.
-- TODO: Does every OS have a singe-char path delim? If not,
-- some functions below will fail.
-- TODO: Does every OS use the same identifier as both
-- delimiter and root indicator?
M.pathdelim = "/"
M.pathroot = "/"
M.dirparent = ".."
M.dirthis = "."

M.basename = function (fp)
  if fp == M.pathroot then
    return fp
  elseif fp:sub(-1) == M.pathdelim then
    fp = fp:sub(0, -2)
  end
  return string.match(fp, "[^" .. M.pathdelim .. "]*$")
end

M.dirname = function (fp)
  M.unimplemented("dirname")
end

M.join = function (...)
  return M.joinwith(M.pathdelim, ...)
end

M.joinwith = function (d, ...)
  local de = str.escape(d)
  local pat = string.format("(%s)*$", de)
  return gen.ivals(utils.pack(...))
    :filter()
    :reduce(function (a, n)
      return table.concat({
        -- Need these parens to ensure only the first return
        -- value of gsub used in concat
        (a:gsub(pat, "")),
        (n:gsub(pat, ""))
      }, d)
    end)
end

M.splitexts = function (fp)
  local parts = gen.split(fp, M.pathdelim, { delim = "left" }):collect()
  local last = gen.split(parts[#parts], "%.", { delim = "right" }):collect()
  if last[1] == "" then
    last = gen.ivals(last):slice(2):collect()
  end
  return {
    exts = gen.vals(last):slice(2):collect(),
    name = table.concat(gen.chain(
      gen.ivals(parts):slice(0, #parts - 1),
      gen.ivals(last):slice(0, 1))
        :collect())
  }
end

return M
