local gen = require("santoku.gen.pausable")

describe("gen.pausable", function ()

  describe("zip", function ()

    it("zips generators together", function ()

      local gen1 = gen.args(1, 2, 3, 4)
      local gen2 = gen.args(1, 2, 3, 4)

      local v = gen1:zip(gen2):vec()

      assert.same(v, vec(
          vec(1, 1), 
          vec(2, 2), 
          vec(3, 3),
          vec(4, 4)))

    end)

  end)

  describe("slice", function ()

    it("slices the generator", function ()

      local gen = gen.args("file", ".txt"):slice(2)

      assert.equals(".txt", gen())
      assert.equals(true, gen:done())

    end)

  end)

  describe("tabulate", function ()

    it("creates a table from a generator", function ()

      local vals = gen.args(1, 2, 3, 4)
      local tbl = vals:tabulate("one", "two", "three", "four" )

      assert.equals(1, tbl.one)
      assert.equals(2, tbl.two)
      assert.equals(3, tbl.three)
      assert.equals(4, tbl.four)

    end)

    it("captures remaining values in a 'rest' property", function ()

      local vals = gen.args(1, 2, 3, 4)
      local tbl = vals:tabulate({ rest = "others" }, "one")

      assert.equals(1, tbl.one)
      assert.same({ 2, 3, 4, n = 3 }, tbl.others)

    end)

  end)

  describe("none", function ()

    it("reduces with not and", function ()

      local gen1 = gen.args(false, false, false)
      local gen2 = gen.args(true, false, true)

      assert(gen1:none())
      assert(not gen2:none())

    end)

  end)

  describe("equals", function ()

    it("checks if two generators have equal values", function ()

      local gen1 = gen.args(1, 2, 3, 4)
      local gen2 = gen.args(5, 6, 7, 8)

      assert.equals(false, gen1:equals(gen2))
      assert(gen1:done())
      assert(gen2:done())

    end)

   it("checks if two generators have equal values", function ()

     local gen1 = gen.args(1, 2, 3, 4)
     local gen2 = gen.args(1, 2, 3, 4)

     assert.equals(true, gen1:equals(gen2))
     assert(gen1:done())
     assert(gen2:done())

   end)

   it("checks if two generators have equal values", function ()

     local gen1 = gen.args(1, 2, 3, 4)

     -- NOTE: this might seem unexpected but
     -- generators are not immutable. This will
     -- result in comparing 1 to 2 and 3 to 4 due to
     -- repeated invocations of the same generator.
     assert.equals(false, gen1:equals(gen1))

   end)

   it("handles odd length generators", function ()

     local gen1 = gen.args(1, 2, 3)
     local gen2 = gen.args(1, 2, 3, 4)

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

  describe("find", function ()

    it("finds by a predicate", function ()

      local gen = gen.args(1, 2, 3, 4)

      local v = gen:find(function (a) return a == 3 end)

      assert.equals(3, v)

    end)

  end)

  describe("pick", function ()

    it("picks the nth value from a generator", function ()

      local gen = gen.args(1, 2, 3, 4)

      local v = gen:pick(2)

      assert.equals(2, v)

    end)

  end)

end)
