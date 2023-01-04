local co = require("santoku.co")
local gen = require("santoku.gen")
local utils = require("santoku.utils")

describe("santoku.gen", function ()

  describe("genco", function ()

    it("should be 'done' when dead", function ()

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

    it("should be 'done' for empty cor", function ()

      local gen = gen.genco(function () end)

      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

  end)

  describe("gennil", function ()

    it("should be 'done' when nil returned", function ()

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

    it("should be 'done' for empty cor", function ()

      local iter = function () end

      local gen = gen.gennil(iter)

      assert.equals(true, gen:done())
      assert.is_nil(gen())
      assert.is_nil(gen())

    end)

  end)

  describe("args", function ()

    it("should handle arg nils", function ()

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

    it("should drop array nils", function ()

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

  describe("match", function ()

    it("should return string matches", function ()

      local gen = gen.match("this is a test", "%S+")

      assert.equals("this", gen())
      assert.equals("is", gen())
      assert.equals("a", gen())
      assert.equals("test", gen())
      assert.equals(true, gen:done())

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
