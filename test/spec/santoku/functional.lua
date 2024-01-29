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
