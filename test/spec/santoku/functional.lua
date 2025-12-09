local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert

local fun = require("santoku.functional")
local tbl = require("santoku.table")
local op = require("santoku.op")

test("sel", function ()

  test("should drop args given to a function", function ()

    local fn = function (a, b, c)
      assert(tbl.equals({ 2 }, { a }))
      assert(tbl.equals({ 3 }, { b }))
      assert(tbl.equals({}, { c }))
    end

    fun.sel(fn, 2)(1, 2, 3)

  end)

end)

test("compose", function ()

  test("should compose functions", function ()
    local fna = function (a, b) return a * 2, b + 2 end
    local fnb = function (a, b) return a + 2, b + 3 end
    assert(tbl.equals({ 8, 7 }, { fun.compose(fna, fnb)(2, 2) }))
  end)

  test("should call from right to left", function ()
    local fna = function (a) return a * 2 end
    local fnb = function (a) return a + 2 end
    assert(tbl.equals({ 10 }, { fun.compose(fna, fnb)(3) }))
  end)

end)

test("choose", function ()

  test("should provide a functional if statement", function ()
    assert(tbl.equals({ 1 }, { fun.choose(true, 1, 2) }))
    assert(tbl.equals({ 2 }, { fun.choose(false, 1, 2) }))
  end)

  test("should handle nils", function ()
    assert(tbl.equals({}, { fun.choose(true, nil, 2) }))
    assert(tbl.equals({}, { fun.choose(false, 1, nil) }))
  end)

end)

test("bind", function ()
  assert(tbl.equals({ 0.5 }, { fun.bind(op.div, 2)(4) }))
end)

test("maybe", function ()
  assert(tbl.equals({ true, 4 }, { fun.maybe(fun.bind(op.div, 8))(true, 2) }))
  assert(tbl.equals({ false, 2 }, { fun.maybe(fun.bind(op.div, 8))(false, 2) }))
end)

test("id", function ()
  assert(tbl.equals({ 1, 2, 3 }, { fun.id(1, 2, 3) }))
  assert(tbl.equals({}, { fun.id() }))
end)

test("noop", function ()
  assert(tbl.equals({}, { fun.noop() }))
  assert(tbl.equals({}, { fun.noop(1, 2, 3) }))
end)

test("const", function ()
  local fn = fun.const(42)
  assert(fn() == 42)
  assert(fn(1, 2, 3) == 42)
end)

test("take", function ()
  local fn = fun.take(function (a, b) return a + b end, 2)
  assert(fn(1, 2, 3, 4) == 3)
end)

test("take zero", function ()
  local fn = fun.take(function () return 42 end, 0)
  assert(fn(1, 2, 3) == 42)
end)

test("take one", function ()
  local fn = fun.take(function (a) return a * 2 end, 1)
  assert(fn(5, 10, 15) == 10)
end)

test("get", function ()
  local getter = fun.get("name")
  assert(getter({ name = "test" }) == "test")
  assert(getter({ name = "other" }) == "other")
end)

test("tget", function ()
  local t = { a = 1, b = 2, c = 3 }
  local getter = fun.tget(t)
  assert(getter("a") == 1)
  assert(getter("b") == 2)
end)

test("set", function ()
  local setter = fun.set("x", 10)
  local t = {}
  setter(t)
  assert(t.x == 10)
end)

test("tset", function ()
  local t = {}
  local setter = fun.tset(t, 42)
  setter("a")
  setter("b")
  assert(t.a == 42)
  assert(t.b == 42)
end)
