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

end)
