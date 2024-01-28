local test = require("santoku.test")
local fun = require("santoku.functional")
local tbl = require("santoku.table")
local op = require("santoku.op")

test("sel", function ()

  test("should drop args given to a function", function ()

    local f = function (a, b, c)
      assert(tbl.equals({ 2 }, { a }))
      assert(tbl.equals({ 3 }, { b }))
      assert(tbl.equals({}, { c }))
    end

    fun.sel(2, f)(1, 2, 3)

  end)

end)

test("narg", function ()

  test("should rearrange args", function ()

    local fn = function (a, b, c)
      assert(tbl.equals({ "c", "b", "a" }, { a, b, c }))
    end

    fun.narg(3, 2, 1)(fn)("a", "b", "c")

  end)

  test("should curry the first argument", function ()
    local add10 = fun.narg()(op.add, 10)
    assert(tbl.equals({ 20 }, { add10(10) }))
  end)

  test("should curry the second argument", function ()
    local div10 = fun.narg()(op.div, 10)
    assert(tbl.equals({ 10 }, { div10(100) }))
  end)

  test("should curry multiple arguments", function ()
    local fn0 = function (a, b, c) return a, b, c end
    local fn = fun.narg(3)(fn0, "c", "a")
    assert(tbl.equals({ "a", "b", "c" }, { fn("b") }))
  end)

  test("should specify argument order", function ()
    local fn0 = function (a, b, c) return a, b, c end
    local fn = fun.narg()(fn0, "b", "c")
    assert(tbl.equals({ "a", "b", "c" }, { fn("a") }))
  end)

end)

test("nret", function ()

  test("should rearrange returns", function ()

    local fn = function ()
      return "a", "b", "c"
    end

    assert(tbl.equals({ "c", "b", "a" }, { fun.nret(3, 2, 1)(fn()) }))

  end)

  test("should work with one return argument", function ()

    local fn = function ()
      return "a", "b"
    end

    local a, b = fun.nret(2)(fn())

    assert(tbl.equals({ "b" }, { a }))
    assert(tbl.equals({}, { b }))

  end)

end)

test("compose", function ()

  test("should compose functions", function ()
    local fna = function (a, b) return a * 2, b + 2 end
    local fnb = function (a, b) return a + 2, b + 3 end
    local fnc = function (a, b) return a * 2, b + 4 end
    assert(tbl.equals({ 12, 11 }, { fun.compose(fna, fnb, fnc)(2, 2) }))
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

test("bindr", function ()
  assert(tbl.equals({ 0.5 }, { fun.bindr(op.div, 2)(1) }))
end)

test("bindl", function ()
  assert(tbl.equals({ 0.5 }, { fun.bindl(op.div, 2)(4) }))
end)

test("maybel", function ()
  assert(tbl.equals({ true, 4 }, { fun.maybel(op.div, 8)(true, 2) }))
  assert(tbl.equals({ false, 2 }, { fun.maybel(op.div, 8)(false, 2) }))
end)

test("mayber", function ()
  assert(tbl.equals({ true, 0.25 }, { fun.mayber(op.div, 8)(true, 2) }))
  assert(tbl.equals({ false, 2 }, { fun.mayber(op.div, 8)(false, 2) }))
end)
