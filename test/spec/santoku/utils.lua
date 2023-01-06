local utils = require("santoku.utils")

describe("utils", function ()

  describe("pack", function ()

    it("should pack args into a table", function ()

      local args = utils.pack(nil, 1, nil, nil, 2, nil)

      assert.equals(6, args.n)
      assert.equals(nil, args[1])
      assert.equals(1,   args[2])
      assert.equals(nil, args[3])
      assert.equals(nil, args[4])
      assert.equals(2,   args[5])
      assert.equals(nil, args[6])

    end)

  end)

  describe("unpack", function ()

    it("should assign table values to arguments", function ()

      local fn = function (a, b, c, d)
        assert.equals(1, a)
        assert.equals(2, b)
        assert.equals(3, c)
        assert.equals(4, d)
      end

      fn(utils.unpack({ 1, 2, 3, 4 }))

    end)

    it("should concat multiple table.pack(...) results", function ()

      local fn = function (a, b, c, d)
        assert.equals(1, a)
        assert.equals(2, b)
        assert.equals(3, c)
        assert.equals(4, d)
      end

      fn(utils.unpack(
          utils.pack(1, 2),
          utils.pack(3, 4)))

    end)

    it("should handle nils", function ()

      local fn = function (a, b, c, d, e, f)
        assert.equals(1, a)
        assert.equals(nil, b)
        assert.equals(2, c)
        assert.equals(nil, d)
        assert.equals(3, e)
        assert.equals(4, f)
      end

      fn(utils.unpack(
          utils.pack(1, nil, 2, nil),
          utils.pack(3, 4)))

    end)

  end)

  describe("id", function ()

    it("should return the argments", function ()
      local a, b, c, d = utils.id(1, 2, 3)
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
      assert.equals(nil, d)
    end)

  end)

  describe("const", function ()

    it("should a function that returns the arguments", function ()
      local fn = utils.const(1, 2, 3)
      for i = 1, 10 do
        local a, b, c = fn()
        assert.equals(1, a)
        assert.equals(2, b)
        assert.equals(3, c)
      end
    end)

  end)

  describe("narg", function ()

    it("should rearrange args", function ()

      local fn = function (a, b, c)
        assert.equals("c", a)
        assert.equals("b", b)
        assert.equals("a", c)
      end

      utils.narg(3, 2, 1)(fn)("a", "b", "c")

    end)

  end)

  describe("nret", function ()

    it("should rearrange returns", function ()

      local fn = function ()
        return "a", "b", "c"
      end

      local a, b, c = utils.nret(3, 2, 1)(fn())

      assert.equals("c", a)
      assert.equals("b", b)
      assert.equals("a", c)

    end)

    it("should handle nils", function ()

      local fn = function ()
        return nil, "a", nil, nil, "b"
      end

      local a, b, c, d, e = utils.nret(5, 4, 3, 2, 1)(fn())

      assert.equals("b", a)
      assert.is_nil(b)
      assert.is_nil(c)
      assert.equals("a", d)
      assert.is_nil(e)

    end)

  end)

  describe("interpreter", function ()

    -- TODO: This is test is basically just
    -- reimplementing the function. We should
    -- use os.execute or something to actually
    -- invoke a program that calls this and
    -- check the return value
    it("should return the interpreter", function ()
      local min = 0
      local i = 0
      while true do
        i = i - 1
        if arg[i] ~= nil then
          min = i
        else
          break
        end
      end
      local vals = utils.interpreter(true)
      local j = 1
      for i = min, #vals do
        assert.equals(vals[j], arg[i])
        j = j + 1
      end
    end)

  end)

  describe("compose", function ()

    it("should compose functions", function ()
      local fna = function (a, b) return a * 2, b + 2 end
      local fnb = function (a, b) return a + 2, b + 3 end
      local fnc = function (a, b) return a * 2, b + 4 end
      local a, b = utils.compose(fna, fnb, fnc)(2, 2)
      assert.equals(12, a)
      assert.equals(11, b)
    end)

    it("should call from right to left", function ()
      local fna = function (a, b) return a * 2 end
      local fnb = function (a, b) return a + 2 end
      local a = utils.compose(fna, fnb)(3)
      assert.equals(10, a)
    end)

  end)

  describe("lens", function ()

    it("should provide a lens into an object", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      local lens2 = utils.lens("a", "b", 2)
      local t, v = lens2(function (x)
        return x + 2
      end)(obj)
      assert.equals(obj, t)
      assert.equals(4, v)
    end)

    it("should provide a lens into an object", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      local lens34 = utils.lens("a", "b", 3)
      local t, v = lens34(utils.id)(obj)
      assert.equals(obj, t)
      assert.same(obj.a.b[3], v)
    end)

  end)

  describe("get", function ()

    it("should get deep vals in objects", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      assert.equals(4, utils.get(obj, "a", "b", 3, 2))
      assert.is_nil(utils.get(obj, "a", "x", 3, 2))
    end)

  end)

  describe("set", function ()

    it("should set deep vals in objects", function ()
      local obj = { a = { b = { 1, 2, { 3, 4 } } } }
      local t, v = utils.set(obj, "x", "a", "b", 3, 2)
      assert.equals(obj, t)
      assert.equals("x", v)
      assert.equals(obj.a.b[3][2], "x")
    end)

  end)

  describe("maybe", function ()

    it("should apply a function if the value is truthy", function ()

      local add1 = function (a) return a + 1 end

      assert.equals(4, utils.maybe(3, add1))
      assert.equals(1, utils.maybe(0, add1))
      assert.is_nil(utils.maybe(nil, add1))
      assert.equals(false, utils.maybe(false, add1))
      assert.equals("b", utils.maybe(false, add1, utils.const("b")))

    end)

  end)

  describe("choose", function ()

    it("should provide a functional if statement", function ()

      assert.equals(1, utils.choose(true, 1, 2))
      assert.equals(2, utils.choose(false, 1, 2))

    end)

    it("should handle nils", function ()

      assert.equals(nil, utils.choose(true, nil, 2))
      assert.is_nil(utils.choose(false, 1, nil))

    end)

  end)

  describe("assign", function ()

    it("should merge hash-like tables", function ()

      local expected = { a = 1, b = { 2, 3 } }
      local one = { a = 1 }
      local two = { b = { 2, 3 } }

      assert.same(expected, utils.assign({}, one, two))

    end)

  end)

  describe("extend", function ()

    it("should merge array-like tables", function ()

      local expected = { 1, 2, 3, 4 }
      local one = { 1, 2 }
      local two = { 3, 4 }

      assert.same(expected, utils.extend({}, one, two))

    end)

    it("should drop trailing nils ", function ()

      local expected = { 1, 2, 3, 4 }
      local one = { 1, 2, nil, nil }
      local two = { 3, 4, nil }

      assert.same(expected, utils.extend({}, one, two))

    end)

    it("should keep middle nils", function ()

      local expected = { 1, nil, 2, nil, 3, 4 }
      local one = { 1, nil, 2, nil }
      local two = { nil, 3, 4 }

      assert.same(expected, utils.extend({}, one, two))

    end)

  end)

end)
