local test = require("santoku.test")

local validate = require("santoku.validate")

local err = require("santoku.error")
local assert = err.assert

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


test("isfile", function ()
  assert(validate.istrue(validate.isfile(io.stdout)))
  assert(validate.isfalse(validate.isfile("hi")))
  assert(validate.isfalse(validate.isfile({})))
end)
