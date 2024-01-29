local test = require("santoku.test")

local validate = require("santoku.validate")
local isfalse = validate.isfalse
local iseq = validate.isequal

local tbl = require("santoku.table")
local teq = tbl.equals

local err = require("santoku.error")
local assert = err.assert
local check = err.check
local try = err.try

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

test("isarray", function ()

  test("should check if a table contains only numeric indices", function ()
    assert(validate.isarray({ 1, 2, 3, 4 }))
    assert(not validate.isarray({ 1, 2, 3, 4, ["5"] = 5 }))
  end)

  test("should ignore the n property if its value is numeric", function ()
    assert(validate.isarray({ 1, 2, 3, 4 }))
    assert(not validate.isarray({ 1, 2, 3, 4, n = "hi" }))
  end)

end)

test("haspairs on table literal", function ()
  assert(validate.haspairs({}))
end)

test("hascall on function literal", function ()
  assert(validate.hascall(function () end))
end)

test("hasadd on number literal", function ()
  assert(validate.hasadd(1))
end)

test("isstring", function ()
  assert(true == validate.isstring("hello"))
end)
