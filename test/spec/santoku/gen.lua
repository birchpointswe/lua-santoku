local gen = require("santoku.gen")

describe("santoku.gen", function ()

  describe("genco", function ()

    it("is 'done' when dead", function ()

      local gen = gen.genco(function (co)
        co.yield(1)
        co.yield(2)
      end)

      assert.equals(false, gen:done())
      assert.equals(1, gen())
      assert.equals(2, gen())
      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

    it("is 'done' for empty cor", function ()

      local gen = gen.genco(function () end)

      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

  end)

  describe("gennil", function ()

    it("is 'done' when nil returned", function ()

      local n = 0
      local iter = function ()
        n = n + 1
        if n > 2 then
          return nil
        else
          return n
        end
      end

      local gen = gen.gennil(iter)

      assert.equals(false, gen:done())
      assert.equals(1, gen())
      assert.equals(2, gen())
      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

    it("is 'done' for empty cor", function ()

      local iter = function () end

      local gen = gen.gennil(iter)

      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

  end)

  describe("pairs", function ()

    it("iterates pairs in a table", function ()

      local gen = gen.pairs({ a = 1, b = 2 })
      local a, b

      a, b = gen()
      assert.same({ "a", 1 }, { a, b })

      a, b = gen()
      assert.same({ "b", 2 }, { a, b })

      assert(gen:done())

    end)

  end)

  describe("ipairs", function ()

    it("iterates ipairs in a table", function ()

      local gen = gen.ipairs({ 1, 2 })
      local a, b

      a, b = gen()
      assert.same({ 1, 1 }, { a, b })

      a, b = gen()
      assert.same({ 2, 2 }, { a, b })

      assert(gen:done())

    end)

  end)

  describe("args", function ()

    it("iterates over arguments", function ()

      local gen = gen.args(1, 2, 3, 4)

      assert.equals(1, gen())
      assert.equals(2, gen())
      assert.equals(3, gen())
      assert.equals(4, gen())

      assert(gen:done())

    end)

    it("handles arg nils", function ()

      local vals = gen.args(1, nil, 2, nil, nil)

      assert.equals(false, vals:done())
      assert.equals(1, vals())

      assert.equals(false, vals:done())
      assert.is_nil(vals())

      assert.equals(false, vals:done())
      assert.equals(2, vals())

      assert.equals(false, vals:done())
      assert.is_nil(vals())

      assert.equals(false, vals:done())
      assert.is_nil(vals())

      assert.equals(true, vals:done())
      assert.is_nil(vals())
      assert.is_nil(vals())
      assert.is_nil(vals())

    end)

    it("drops array nils", function ()

      local array = {}

      table.insert(array, "a")
      table.insert(array, nil)
      table.insert(array, "b")
      table.insert(array, nil)
      table.insert(array, nil)
      table.insert(array, "c")
      table.insert(array, nil)

      local vals = gen.ivals(array)

      assert.equals(false, vals:done())
      assert.equals("a", vals())

      assert.equals(false, vals:done())
      assert.equals("b", vals())

      assert.equals(false, vals:done())
      assert.equals("c", vals())

      assert.equals(true, vals:done())
      assert.is_nil(vals())
      assert.is_nil(vals())
      assert.is_nil(vals())

    end)

  end)

  describe("vals", function ()

    it("iterates table values", function ()

      local gen = gen.vals({ a = 1, b = 2 })

      assert.equals(1, gen())
      assert.equals(2, gen())

      assert(gen:done())

    end)

  end)

  describe("keys", function ()

    it("iterates table keys", function ()

      local gen = gen.keys({ a = 1, b = 2 })

      assert.equals("a", gen())
      assert.equals("b", gen())

      assert(gen:done())

    end)

  end)

  describe("ivals", function ()

    it("iterates table ivalues", function ()

      local gen = gen.ivals({ 1, 2, a = "b" })

      assert.equals(1, gen())
      assert.equals(2, gen())

      assert(gen:done())

    end)

  end)

  describe("ikeys", function ()

    it("iterates table keys", function ()

      local gen = gen.ikeys({ "a", "b", a = 12 })

      assert.equals(1, gen())
      assert.equals(2, gen())

      assert(gen:done())

    end)

  end)

  describe("map", function ()

    it("maps over a generator", function ()

      local gen = gen.genco(function (co)
        co.yield(1)
        co.yield(2)
      end):map(function (a)
        return a * 2
      end)

      assert.equals(2, gen())
      assert.equals(4, gen())

    end)

  end)

  describe("reduce", function ()

    it("reduces a generator", function ()
      local gen = gen.genco(function (co)
        co.yield(1)
        co.yield(2)
        co.yield(3)
      end)
      local t, x = gen:reduce(function (a, n)
        return a + n
      end)
      assert.equals(t, 6)
      assert(gen:done())
    end)

  end)

  describe("filter", function ()

    it("filters a generator", function ()
      local gen = gen.genco(function (co)
        co.yield(1)
        co.yield(2)
        co.yield(3)
        co.yield(4)
        co.yield(5)
        co.yield(6)
      end):filter(function (n)
        return (n % 2) == 0
      end)
      assert.equals(2, gen())
      assert.equals(4, gen())
      assert.equals(6, gen())
      assert(gen:done())
    end)

  end)

  describe("zip", function ()

    it("should zip generators together", function ()

      local gen1 = gen.args(1, 2, 3, 4)
      local gen2 = gen.args(1, 2, 3, 4)

      local gen = gen1:zip(gen2)

      local a, b

      a, b = gen()
      assert.same({ 1, 1 }, { a, b })

      a, b = gen()
      assert.same({ 2, 2 }, { a, b })

      a, b = gen()
      assert.same({ 3, 3 }, { a, b })

      a, b = gen()
      assert.same({ 4, 4 }, { a, b })

      assert.equals(true, gen1:done())
      assert.equals(true, gen2:done())
      assert.equals(true, gen:done())

    end)

  end)

  describe("tabulate", function ()

    it("should create a table from a generator", function ()

      local vals = gen.args(1, 2, 3, 4)
      local keys = { "one", "two", "three", "four" }

      local tbl = vals:tabulate(keys)

      assert.equals(1, tbl.one)
      assert.equals(2, tbl.two)
      assert.equals(3, tbl.three)
      assert.equals(4, tbl.four)

    end)

  end)

  describe("slice", function ()

    it("should slice the generator", function ()

      local gen = gen.args("file", ".txt"):slice(2)

      assert.equals(".txt", gen())
      assert.equals(true, gen:done())

    end)

  end)

end)
