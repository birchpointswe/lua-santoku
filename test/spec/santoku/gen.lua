-- TODO: Confirm that return values are
-- correctly vectors when they should be vectors

-- TODO: Seems to be an infinite loop with
-- each:flatten, perhaps because each returns a
-- generator when it shouldnt?

local assert = require("luassert")
local test = require("santoku.test")

local gen = require("santoku.gen")
local vec = require("santoku.vector")

test("santoku.gen", function ()

  test("gen", function ()

    test("should create a generator", function ()

      local vals = gen(function (yield)
        yield(1)
        yield(2)
      end)

      local called = 0
      vals:index():each(function (idx, i)
        called = called + 1
        assert.equals(idx, i)
      end)

      assert.equals(called, 2)

    end)

    test("shouldnt call the callback if empty", function ()

      local vals = gen()

      local called = 0

      vals:each(function ()
        called = called + 1
      end)

      assert.equals(called, 0)

    end)

  end)

  test("iter", function ()

    test("should wrap a nil-based generator", function ()

      local it = ("this is a test"):gmatch("%w+")
      local vals = gen.iter(it):vec()

      assert.same(vec("this", "is", "a", "test"), vals)

    end)

    test("should work without callbacks", function ()

      local it = ("this is a test"):gmatch("%w+")
      gen.iter(it):each()

    end)

  end)

  test("isgen", function ()

    test("should detect invalid generators", function ()

      assert.False(gen.isgen(1))
      assert.False(gen.isgen({}))
      assert.False(gen.isgen(vec()))

    end)

  end)

  test("iscogen", function ()

    test("should detect invalid co-generators", function ()

      assert(not gen.iscogen(1))
      assert(not gen.iscogen({}))
      assert(not gen.iscogen(vec()))
      assert(not gen.iscogen(gen.pack(1, 2)))
      assert(gen.iscogen(gen.pack(1, 2):co()))

    end)

  end)

  test("vec", function ()

    test("collects generator returns into a vec", function ()

      local vals = gen(function (yield)
        yield(1, 2, 3)
        yield(4, 5, 6)
      end):vec()

      local expected = vec(vec(1, 2, 3), vec(4, 5, 6))

      assert.same(expected, vals)

    end)

  end)

  test("pack", function ()

    test("iterates over arguments", function ()

      local v = gen.pack(1, 2, 3, 4):vec()

      assert.same(v, { 1, 2, 3, 4, n = 4 })

    end)

    test("handles arg nils", function ()

      local v = gen.pack(1, nil, 2, nil, nil):vec()

      assert.same(v, { 1, nil, 2, nil, nil, n = 5 })

    end)

  end)

  test("map", function ()

    test("maps over a generator", function ()

      local vals = gen.pack(1, 2):map(function (a)
        return a * 2
      end):vec()

      assert.same(vals, { 2, 4, n = 2 })

    end)

  end)

  test("reduce", function ()

    test("reduces a generator", function ()
      local vals = gen.pack(1, 2, 3):reduce(function (a, n)
        return a + n
      end)
      assert.same(vals, 6)
    end)

  end)

  test("filter", function ()

    test("filters a generator", function ()

      local vals = gen
        .pack(1, 2, 3, 4, 5, 6)
        :filter(function (n)
          return (n % 2) == 0
        end)
        :vec()

      assert.same(vals, vec(2, 4, 6))

    end)

  end)

  test("chunk", function ()

    test("takes n items from a generator", function ()
      local vals = gen.pack(1, 2, 3):chunk(2):tup()
      local a, b = vals()
      assert.same(a, { 1, 2, n = 2 })
      assert.same(b, { 3, n = 1 })
    end)

  end)

  test("pairs", function ()

    test("iterates pairs in a table", function ()

      local v = gen.pairs({ a = 1, b = 2 }):vec()

      local apair = v:find(function (p) return p[1] == "a" end)
      local bpair = v:find(function (p) return p[1] == "b" end)

      assert(apair[2] == 1)
      assert(bpair[2] == 2)

    end)

  end)

  test("ipairs", function ()

    test("iterates ipairs in a table", function ()

      local v = gen.ipairs({ 1, 2 }):vec()

      assert.same(v, vec(vec(1, 1), vec(2, 2)))

    end)

  end)

  test("vals", function ()

    test("iterates table values", function ()

      local v = gen.vals({ a = 1, b = 2 }):vec()

      assert.equals(1, v:find(function (a) return a == 1 end))
      assert.equals(2, v:find(function (a) return a == 2 end))

    end)

  end)

  test("keys", function ()

    test("iterates table keys", function ()

      local v = gen.keys({ a = 1, b = 2 }):vec()

      assert.equals("a", v:find(function (a) return a == "a" end))
      assert.equals("b", v:find(function (b) return b == "b" end))

    end)

  end)

  test("ivals", function ()

    test("drops array nils", function ()

      local array = {}

      table.insert(array, "a")
      table.insert(array, nil)
      table.insert(array, "b")
      table.insert(array, nil)
      table.insert(array, nil)
      table.insert(array, "c")
      table.insert(array, nil)

      local v = gen.ivals(array):vec()

      assert.same(v, vec("a", "b", "c"))

    end)

    test("iterates table ivalues", function ()

      local v = gen.ivals({ 1, 2, a = "b" }):vec()

      assert.same(v, vec(1, 2))

    end)

  end)

  test("ikeys", function ()

    test("iterates table keys", function ()

      local v = gen.ikeys({ "a", "b", a = 12 }):vec()

      assert.same(v, vec(1, 2))

    end)

  end)

  test("each", function ()

    test("applies a function to each item", function ()
      local gen = gen.pack(1, 2, 3, 4)
      local i = 0
      gen:each(function (x)
        i = i + 1
        assert.equals(i, x)
      end)
      assert(i == 4)
    end)

  end)

  test("flatten", function ()

    test("flattens a generator of generators", function ()
      local v = gen(function (yield)
        yield(gen.pack(1, 2, 3, 4))
        yield(gen.pack(5, 6, 7, 8))
      end):flatten():vec()
      assert.same(v, vec(1, 2, 3, 4, 5, 6, 7, 8))
    end)

  end)

  test("all", function ()

    test("reduces with and", function ()

      local gen1 = gen.pack(true, true, true)
      local gen2 = gen.pack(true, false, true)

      assert(gen1:all())
      assert(not gen2:all())

    end)

  end)

  test("chain", function ()

    test("chains generators", function ()

      local gen1 = gen.pack(1, 2)
      local gen2 = gen.pack(3, 4)
      local vals = gen.chain(gen1, gen2):vec()

      assert.same(vec(1, 2, 3, 4), vals)

    end)

  end)

  test("max", function ()

    test("returns the max value in a generator", function ()

      local gen = gen.pack(1, 6, 3, 9, 2, 10, 4)

      local max = gen:max()

      assert.equals(10, max)

    end)

  end)

  test("empty", function ()

    test("should produce an empty generator", function ()

      local gen = gen.empty()

      local called = false

      gen:each(function ()
        called = true
      end)

      assert(not called)

    end)

  end)

  test("paster", function () 

    test("should paste values to the right", function ()

      local vals = gen.pack(1, 2, 3):paster("num"):vec()

      assert.same(vec(vec(1, "num"), vec(2, "num"), vec(3, "num")), vals)

    end)

  end)

  test("pastel", function () 

    test("should paste values to the left", function ()

      local vals = gen.pack(1, 2, 3):pastel("num"):vec()

      assert.same(vec(vec("num", 1), vec("num", 2), vec("num", 3)), vals)

    end)

  end)

  test("discard", function ()

    test("should run a generator without processing vals", function ()

      local called = false

      local val = gen(function (yield)
        called = true
        yield(1)
        yield(2)
      end):discard()

      assert(called)

    end)

  end)

  test("tup", function ()

    test("should convert a generator to multiple tuples", function ()

      local vals = gen(function (yield)
        yield(1, 2)
        yield(3, 4)
      end):tup()

      local a, b = vals()
      local x, y

      assert.same({ 1, 2 }, { a() })
      assert.same({ 3, 4 }, { b() })

    end)

  end)

  test("unpack", function ()

    test("should unpack a generator", function ()

      local gen = gen.pack(1, 2, 3)

      assert.same({ 1, 2, 3 }, { gen:unpack() })

    end)

  end)

  test("last", function ()

    test("should return the last element in a generator", function ()

      local gen = gen.pack(1, 2, 3)

      assert(3, gen:last())

    end)

  end)

  test("step", function ()

    test("should step through a coroutine-generator", function ()

      local gen = gen.pack(1, 2, 3):co()

      assert(gen:step())
      assert(1 == gen.val())
      assert(gen:step())
      assert(2 == gen.val())
      assert(gen:step())
      assert(3 == gen.val())
      assert(not gen:step())

    end)

    test("throw errors that occur in the coroutine", function ()

      local gen = gen(function (yield)
        error("err")
      end):co()

      assert.has.errors(function ()
        gen:step()
      end)

    end)

  end)

  test("take", function ()

    test("should create a new generator that takes from an existing generator", function ()

      local gen0 = gen.pack(1, 2, 3, 4)
      local gen1 = gen0:co():take(2)

      assert.same(gen1:vec(), vec(1, 2))
      assert.same(gen0:vec(), vec(3, 4))

    end)

  end)

  test("zip", function ()

    test("zips generators together", function ()

      local gen1 = gen.pack(1, 2, 3, 4):co()
      local gen2 = gen.pack(1, 2, 3, 4):co()

      local v = gen1:zip(gen2):tup()

      local a, b, c, d = v()
      local x, y

      x, y = a()
      assert.same({ 1, 1 }, { x(), y() })

      x, y = b()
      assert.same({ 2, 2 }, { x(), y() })

      x, y = c()
      assert.same({ 3, 3 }, { x(), y() })

      x, y = d()
      assert.same({ 4, 4 }, { x(), y() })

    end)

  end)

  test("slice", function ()

    test("slices the generator", function ()

      local gen = gen.pack("file", ".txt"):co():slice(2)

      local v = gen:tup()

      assert.equals(".txt", v())

      assert(not gen:step())

    end)

    test("slices the generator", function ()

      local gen0 = gen.pack(1, 2, 3, 4):co()
      local gen1 = gen0:slice(2, 2):co()

      local v = gen1:tup()

      assert.same({ 2, 3 }, { v() })

      assert(not gen1:step())
      assert(gen0:step())
      assert(not gen0:step())

    end)
  end)

  test("tabulate", function ()

    test("creates a table from a generator", function ()

      local vals = gen.pack(1, 2, 3, 4):co()
      local tbl = vals:tabulate("one", "two", "three", "four" )

      assert.equals(1, tbl.one)
      assert.equals(2, tbl.two)
      assert.equals(3, tbl.three)
      assert.equals(4, tbl.four)

    end)

    test("captures remaining values in a 'rest' property", function ()

      local vals = gen.pack(1, 2, 3, 4):co()
      local tbl = vals:tabulate({ rest = "others" }, "one")

      assert.equals(1, tbl.one)
      assert.same({ 2, 3, 4, n = 3 }, tbl.others)

    end)

  end)

  test("none", function ()

    test("reduces with not and", function ()

      local gen1 = gen.pack(false, false, false):co()
      local gen2 = gen.pack(true, false, true):co()

      assert(gen1:none())
      assert(not gen2:none())

    end)

  end)

  test("equals", function ()

    test("checks if two generators have equal values", function ()

      local gen1 = gen.pack(1, 2, 3, 4):co()
      local gen2 = gen.pack(5, 6, 7, 8):co()

      assert.equals(false, gen1:equals(gen2))
      assert(gen1:done())
      assert(gen2:done())

    end)

   test("checks if two generators have equal values", function ()

     local gen1 = gen.pack(1, 2, 3, 4):co()
     local gen2 = gen.pack(1, 2, 3, 4):co()

     assert.equals(true, gen1:equals(gen2))
     assert(gen1:done())
     assert(gen2:done())

   end)

   test("checks if two generators have equal values", function ()

     local gen1 = gen.pack(1, 2, 3, 4):co()

     -- NOTE: this might seem unexpected but
     -- generators are not immutable. This will
     -- result in comparing 1 to 2 and 3 to 4 due to
     -- repeated invocations of the same generator.
     assert.equals(false, gen1:equals(gen1))

   end)

   test("handles odd length generators", function ()

     local gen1 = gen.pack(1, 2, 3):co()
     local gen2 = gen.pack(1, 2, 3, 4):co()

     assert.equals(false, gen1:equals(gen2))
     assert(gen1:done())

     -- TODO: See the note on the implementation of
     -- gen:equals() for why these are commented out.
     --
     -- assert(not gen2:done())
     -- assert.equals(4, gen2())
     -- assert(gen2:done())

   end)

  end)

  test("find", function ()

    test("finds by a predicate", function ()

      local gen = gen.pack(1, 2, 3, 4):co()

      local v = gen:find(function (a) return a == 3 end)

      assert.equals(3, v)

    end)

  end)

  test("intersperse", function ()

    test("intersperses values into a generator", function ()

      local v = gen.pack(1, 2, 3, 4):intersperse("x"):vec()

      assert.same(v, vec(1, "x", 2, "x", 3, "x", 4))

    end)

  end)
end)
