local test = require("santoku.test")

test("test runs a passing case", function ()
  assert(true)
end)

test("test passes nested tags", function ()
  local ran = false
  test("inner", function ()
    ran = true
  end)
  assert(ran)
end)
