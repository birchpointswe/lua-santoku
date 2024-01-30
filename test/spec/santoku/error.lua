local test = require("santoku.test")

local validate = require("santoku.validate")
local isfalse = validate.isfalse
local iseq = validate.isequal

local tbl = require("santoku.table")
local teq = tbl.equals

local err = require("santoku.error")
local try = err.try
local wrapexists = err.wrapexists
local assert = err.assert
local check = err.check

test("error(...)", function ()
  local ok, e = try(function ()
    check(false, "hi")
  end)
  assert(isfalse(ok))
  assert(iseq(e, "hi"))
end)

test("error(...) multi return", function ()
  local ok, a, b, c = try(function ()
    check(false, "a", "b", "c")
  end)
  assert(isfalse(ok))
  assert(teq({ "a", "b", "c" }, { a, b, c }))
end)

test("wrapexists", function ()
  local fn = function ()
    return nil, "error", 1
  end
  local a, b, c = wrapexists(fn)()
  assert(isfalse(a))
  assert(iseq(b, "error"))
  assert(iseq(c, 1))
end)
