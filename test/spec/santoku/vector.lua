local vec = require("santoku.vector")

describe("vector", function ()

  describe("extend", function ()

    it("should merge array-like tables", function ()

      local expected = { 1, 2, 3, 4 }
      local one = vec(1, 2)
      local two = vec(3, 4)

      assert.same(expected, vec():extend(one, two):unwrap())

    end)

    it("should handle non-empty initial tables", function ()

      local expected = { "a", "b", 1, 2, 3, 4 }
      local one = vec(1, 2)
      local two = vec(3, 4)

      assert.same(expected, vec("a", "b"):extend(one, two):unwrap())

    end)

    it("should keep middle nils", function ()

      local expected = { 1, nil, 2, nil, nil, 3, 4 }
      local one = vec(1, nil, 2, nil)
      local two = vec(nil, 3, 4)

      assert.same(expected, vec():extend(one, two):unwrap())

    end)

    it("should handle empty tables", function ()
      local vals = vec(1, 2, 3, 4):extend(vec())
      assert.same({ 1, 2, 3, 4, n = 4 }, vals)
    end)

  end)

  describe("append", function ()

    it("should append args to array", function ()

      local expected = { 1, 2, 3 }
      assert.same(expected, vec(1):append(2, 3):unwrap())

    end)

    it("should handle nils", function ()

      local args = vec()

      assert.equals(0, args.n)

      args:append(nil)

      assert.equals(1, args.n)

    end)

  end)

  describe("copy", function ()

    it("should copy into a vector", function ()
      local dest = vec(1, 2, 3, 4)
      local source = vec(3, 4, 5, 6)
      dest:copy(source, 3)
      assert.same({ 1, 2, 3, 4, 5, 6 }, dest:unwrap())
    end)

    it("should copy into a vector", function ()
      local dest = vec()
      local source = vec(3, 4, 5, 6)
      dest:copy(source, 1)
      assert.same({ 3, 4, 5, 6 }, dest:unwrap())
    end)

    it("should work with the same vector", function ()
      local v = vec(1, 2, 3, 4, 5, 6)
      v:copy(v, 1, 2)
      assert.same({ 2, 3, 4, 5, 6, 6 }, v:unwrap())
    end)

    it("should work with the same vector", function ()
      local v = vec(1, 2, 3, 4, 5, 6)
      v:copy(v, 2, 1)
      assert.same({ 1, 1, 2, 3, 4, 5, 6, n = 7 }, v)
    end)

  end)

  describe("slice", function ()

    it("should copy into a vector", function ()
      local v = vec(1, 2, 3, 4):slice(2)
      assert.same({ 2, 3, 4, n = 3 }, v)
    end)

  end)

  describe("tabulate", function ()

    it("creates a table from a vector", function ()

      local vals = vec(1, 2, 3, 4)
      local tbl = vals:tabulate("one", "two", "three", "four" )

      assert.equals(1, tbl.one)
      assert.equals(2, tbl.two)
      assert.equals(3, tbl.three)
      assert.equals(4, tbl.four)

    end)

    it("captures remaining values in a 'rest' property", function ()

      print("\n----")
      local vals = vec(1, 2, 3, 4)
      local tbl = vals:tabulate({ rest = "others" }, "one")

      assert.equals(1, tbl.one)
      assert.same({ 2, 3, 4, n = 3 }, tbl.others)

    end)

  end)

  describe("remove", function ()

    it("removes elements from an array", function ()

      local vals = vec(1, 2, 3, 4)
      vals:remove(2, 3)

      -- NOTE: We are intentionally not
      -- overwriting values
      assert.same({ 1, 4, 3, 4, n = 2 }, vals)

    end)

  end)

  describe("filter", function ()

    it("filters a vector", function ()
      local vals = vec(1, 2, 3, 4, 5, 6)
        :filter(function (n)
          return (n % 2) == 0
        end)
      -- NOTE: Using slice here because filter
      -- won't nil trailing elements after 'n',
      -- which will exist due to the filter
      -- moves
      assert.same({ 2, 4, 6, n = 3 }, vals:slice(1, 3))
    end)

    it("works for consecutive removals", function ()
      local vals = vec(1, 2, 3, 3, 3, 3, 3, 4, 5, 5, 6)
        :filter(function (n)
          return (n % 2) == 0
        end)
      -- NOTE: Using slice here because filter
      -- won't nil trailing elements after 'n',
      -- which will exist due to the filter
      -- moves
      assert.same({ 2, 4, 6, n = 3 }, vals:slice(1, 3))
    end)

  end)

end)
