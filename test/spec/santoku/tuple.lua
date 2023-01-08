local tup = require("santoku.tuple")

describe("tuple", function ()

  describe("tup", function ()

    it("should store arguments", function ()

      local args = tup(1, 2, 3, nil, 4, nil)
      local a, b, c, d, e, f = args()
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
      assert.is_nil(d)
      assert.equals(4, e)
      assert.is_nil(f)

    end)

  end)

  describe("push", function ()

    it("should allow O(1) pushing to head of tuple", function ()

      local args = tup(2, 3)
      args = args:push(1)

      local a, b, c = args()

      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)

    end)

  end)

  describe("append", function ()

    it("should allow appending", function ()

      local args

      args = tup(1, 2)
      args = args:append(3)

      local a, b, c = args()

      assert.equal(1, a)
      assert.equal(2, b)
      assert.equal(3, c)

    end)

    it("should append to a tuple", function ()

      local arg0 = tup(1, 2, 3)
      local arg1 = tup(4, 5, 6)
      local args = arg0:append(arg1())

      assert.equals(3, arg0:len())
      assert.equals(3, arg1:len())

      local a, b, c, d, e, f = args()

      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
      assert.equals(4, d)
      assert.equals(5, e)
      assert.equals(6, f)

      assert.equals(6, args:len())

    end)

    it("should handle empty tuples", function ()

      local arg0 = tup()
      local arg1 = tup(4, 5, 6)
      local args = arg0:append(arg1())

      local a, b, c = args()

      assert.equals(3, args.n)
      assert.equals(4, a)
      assert.equals(5, b)
      assert.equals(6, c)

    end)

  end)

  describe("equals", function ()

    it("should check tuple equality", function ()

      local as = tup(1, 2, 3)
      local bs = tup(1, 2, 3)

      assert(as:equals(as))
      assert(as:equals(bs))

    end)

    it("should check tuple inequality", function ()

      local as = tup(1, 4, 3)
      local bs = tup(1, 2, 3)

      assert(not as:equals(bs))
      assert(not bs:equals(as))

    end)

    it("should check tuple equality by length", function ()

      local as = tup(1, 2, 3)
      local bs = tup(1, 2, 3, 4)

      assert(not as:equals(bs))
      assert(not bs:equals(as))

    end)

  end)

  describe("each", function ()

    it("should apply a function to each element in a tuple", function ()

      local i = 0
      local args = tup(1, 2, 3, 4)

      args:each(function (a)
        i = i + 1
        assert.equals(i, a)
      end)

      assert.equals(4, i)

    end)

  end)

  describe("pick", function ()

    it("should extract the nth value", function ()

      local args = tup(1, 2, 3)
      local args, a = args:pick(2)
      local b, c = args()
      assert.equals(2, a())
      assert.equals(1, b)
      assert.equals(3, c)
      assert.equals(2, args:len())

    end)

    it("should return no value for a larger index", function ()

      local args = tup(1, 2, 3)
      local ret, p = args:pick(4)

      assert.equals(3, ret:len())
      assert.equals(0, p:len())

    end)

    it("should correctly handle nils", function ()

      local args = tup(1, 2, nil)

      assert.equals(3, args:len())

      local args1, v = args:pick(3)
      assert.equals(2, args1:len())
      assert.equals(1, v:len())
      assert.is_nil(v())

    end)

    it("should be able to pick multiple values", function ()

      local args = tup(1, 2, 3, 4, 5)
      local args0, ret = args:pick(3, 5)
      local a, b = ret()
      assert.equals(3, a)
      assert.equals(5, b)
      local d, e, f = args0()
      assert.equals(d, 1)
      assert.equals(e, 2)
      assert.equals(f, 4)

    end)

    it("should be able to pick multiple values in reverse order", function ()

      local args = tup(1, 2, 3, 4, 5)
      local args0, ret = args:pick(5, 3)
      local a, b = ret()
      assert.equals(5, a)
      assert.equals(3, b)
      local d, e, f = args0()
      assert.equals(d, 1)
      assert.equals(e, 2)
      assert.equals(f, 4)

    end)

  end)

end)

-- TODO: This should now slow as i increases,
-- but it does due to the slow implementations
-- of push/append/etc.
--
-- local t = tup()
-- for i = 1, 10000 do
--   if i % 100 == 0 then
--     print(i)
--   end
--   t = t:push(i)
-- end
