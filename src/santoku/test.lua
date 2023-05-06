-- TODO: Refine this: show nesting of tags,
-- allow continuing on failure with summary of
-- errors, etc.

local compat = require("santoku.compat")
local err = require("santoku.err")
local gen = require("santoku.gen")
local fs = require("santoku.fs")
local str = require("santoku.string")

local M = {}

M.test = function (tag, fn)
  if compat.iscallable(tag) then
    fn = tag
    tag = ""
  else
    tag = ": " .. tag
  end
  local ok, err, detail = pcall(fn)
  if not ok then
    print("FAIL" .. tag)
    print(err)
    print(detail)
    os.exit(1)
  end
end

M.runfiles = function (files)
  return err.pwrap(function (check)
    gen.ivals(files)
      :map(function (fp)
        if check(fs.isdir(fp)) then
          return fs.files(fp, { recurse = true }):map(check)
        else
          return gen.pack(fp)
        end
      end)
      :flatten()
      :filter(function (fp)
        return str.endswith(fp, ".lua")
      end)
      :each(function (fp)
        print("Running", fp)
        check(fs.loadfile(fp, setmetatable({}, { __index = _G })))()
      end)
  end)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.test(...)
  end
})

