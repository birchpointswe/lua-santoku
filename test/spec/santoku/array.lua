local serialize = require("santoku.serialize") -- luacheck: ignore
local test = require("santoku.test")
local tbl = require("santoku.table")
local fun = require("santoku.functional")
local op = require("santoku.op")

local implementations = { { "array", require("santoku.array") } }

for _, impl in ipairs(implementations) do
  local name, arr = impl[1], impl[2]

  test(name, function ()

    test("copy", function ()

      test("should copy into an array", function ()
        local dest = { 1, 2, 3, 4 }
        local source = { 3, 4, 5, 6 }
        arr.copy(dest, source, 1, 4, 3)
        assert(tbl.equals({ 1, 2, 3, 4, 5, 6 }, dest))
      end)

      test("should copy into an array", function ()
        local dest = {}
        local source = { 3, 4, 5, 6 }
        arr.copy(dest, source, 1, 4, 1)
        assert(tbl.equals({ 3, 4, 5, 6 }, dest))
      end)

      test("should work with the same array", function ()
        local v = { 1, 2, 3, 4, 5, 6 }
        arr.copy(v, v, 2, 6, 1)
        assert(tbl.equals({ 2, 3, 4, 5, 6, 6 }, v))
      end)

      test("should work with the same array", function ()
        local v = { 1, 2, 3, 4, 5, 6 }
        arr.copy(v, v, 1, 6, 2)
        assert(tbl.equals({ 1, 1, 2, 3, 4, 5, 6 }, v))
      end)

      test("should clear if moving", function ()
        local a = { 1, 2, 3, 4 }
        local b = { 3, 4, 5, 6, 7, 8 }
        arr.move(a, b, 1, 4, 3)
        assert(tbl.equals({ 1, 2, 3, 4, 5, 6 }, a))
        assert(tbl.equals({ 7, 8 }, b))
      end)

      test("simple copy within single table", function ()
        assert(tbl.equals({ 1, 3, 4, 4 }, arr.copy({ 1, 2, 3, 4 }, 3, 4, 2)))
      end)

    end)

    test("flatten", function ()

      test("should flatten nested arrays", function ()
        local expected = { 1, 2, 3, 4 }
        local one = { 1, 2 }
        local two = { 3, 4 }
        assert(tbl.equals(expected, arr.flatten({ one, two })))
      end)

      test("should handle empty tables", function ()
        local expected = { 1, 2 }
        local one = {}
        local two = {}
        assert(tbl.equals(expected, arr.flatten({ { 1, 2 }, one, two })))
      end)

    end)

    test("push", function ()
      local expected = { { 1, 2, 3 } }
      assert(tbl.equals(expected, { arr.push({ 1 }, 2, 3) }))
    end)

    test("slice", function ()
      test("should copy into an array", function ()
        local v = arr.slice({ 1, 2, 3, 4 }, 2)
        assert(tbl.equals({ 2, 3, 4 }, v))
      end)
    end)

    test("tabulate", function ()

      test("creates a table from an array", function ()
        local vals = { 1, 2, 3, 4 }
        local t = arr.tabulate(vals, "one", "two", "three", "four")
        assert(tbl.equals({ one = 1, two = 2, three = 3, four = 4 }, t))
      end)

      test("captures remaining values in a 'rest' property", function ()
        local vals = { 1, 2, 3, 4 }
        local t = arr.tabulate(vals, { rest = "others" }, "one")
        assert(tbl.equals({ one = 1, others = { 2, 3, 4 } }, t))
      end)

    end)

    test("remove", function ()

      test("removes elements from an array", function ()
        local vals = { 1, 2, 3, 4 }
        arr.remove(vals, 2, 3)
        assert(tbl.equals({ 1, 4 }, vals))
      end)

      test("remove", function ()
        local t = { 1, 2, 3, 4, 5, 6 }
        arr.remove(t, 4, 5)
        assert(tbl.equals({ 1, 2, 3, 6 }, t))
      end)

    end)

    test("filter", function ()

      test("filters an array", function ()
        assert(tbl.equals({ 2, 4, 6 },
          arr.filter({ 1, 2, 3, 4, 5, 6 }, function (n)
            return (n % 2) == 0
          end)))
      end)

      test("works for consecutive removals", function ()
        assert(tbl.equals({ 2, 4, 6 },
          arr.filter({ 1, 2, 3, 3, 3, 3, 3, 4, 5, 5, 6 }, function (n)
            return (n % 2) == 0
          end)))
      end)

    end)

    test("sort", function ()

      test("should sort an array", function ()
        local v = arr.sort({ 10, 5, 2, 38, 1, 4 })
        assert(tbl.equals({ 1, 2, 4, 5, 10, 38 }, v))
      end)

      test("should unique sort an array", function ()
        local v = arr.sort({ 10, 38, 10, 10, 38, 1, 4 }, { unique = true })
        assert(tbl.equals({ 1, 4, 10, 38 }, v))
      end)

      test("should unique sort an array", function ()
        local v = arr.sort({ { 2 }, { 5 }, { 1 } }, function (a, b)
          return a[1] < b[1]
        end)
        assert(tbl.equals({ { 1 }, { 2 }, { 5 } }, v))
      end)

    end)

    test("reverse", function ()
      assert(tbl.equals({ 4, 3, 2, 1 }, arr.reverse({ 1, 2, 3, 4 })))
      assert(tbl.equals({ 3, 2, 1 }, arr.reverse({ 1, 2, 3 })))
      assert(tbl.equals({ 2, 1 }, arr.reverse({ 1, 2 })))
      assert(tbl.equals({ 1 }, arr.reverse({ 1 })))
      assert(tbl.equals({}, arr.reverse({})))
    end)

    test("replicate", function ()
      assert(tbl.equals({ 1, 2, 1, 2 }, arr.replicate({ 1, 2 }, 2)))
    end)

    test("includes", function ()
      assert(tbl.equals({ true }, { arr.includes({ 1, 2, 3, 4 }, 3) }))
      assert(tbl.equals({ true }, { arr.includes({ 1, 2, 3, 4 }, 6, 7, 8, 1) }))
    end)

    test("insert", function ()
      assert(tbl.equals({ 1, 2, 3 }, arr.insert({ 1, 3 }, 2, 2)))
      assert(tbl.equals({ 2, 1, 3 }, arr.insert({ 1, 3 }, 1, 2)))
      assert(tbl.equals({ 1, 3, 2 }, arr.insert({ 1, 3 }, 3, 2)))
      assert(tbl.equals({ 1, 3, 2 }, arr.insert({ 1, 3 }, 2)))
    end)

    test("trunc", function ()
      assert(tbl.equals({ 1, 2, 3 }, arr.trunc({ 1, 2, 3, 4 }, 3)))
    end)

    test("map", function ()
      assert(tbl.equals({ 2, 3, 4 }, arr.map({ 1, 2, 3 }, fun.bind(op.add, 1))))
    end)

    test("reduce", function ()
      assert(tbl.equals({ 6 }, { arr.reduce({ 1, 2, 3 }, op.add) }))
      assert(tbl.equals({}, { arr.reduce({}, op.add) }))
    end)

    test("pop", function ()
      local t = { 1, 2, 3 }
      local _, v = arr.pop(t)
      assert(tbl.equals({ 1, 2 }, t))
      assert(v == 3)
    end)

    test("pop empty", function ()
      local t = {}
      local _, v = arr.pop(t)
      assert(tbl.equals({}, t))
      assert(v == nil)
    end)

    test("shift", function ()
      local t = { 1, 2, 3 }
      local _, v = arr.shift(t)
      assert(tbl.equals({ 2, 3 }, t))
      assert(v == 1)
    end)

    test("shift empty", function ()
      local t = {}
      local _, v = arr.shift(t)
      assert(tbl.equals({}, t))
      assert(v == nil)
    end)

    test("each", function ()
      local s = 0
      local t = { 1, 2, 3 }
      arr.each(t, function (v)
        s = s + v
      end)
      assert(s == 6)
    end)

    test("sum, mean, max, min", function ()
      assert(tbl.equals({ 10 }, { arr.sum({ 1, 2, 3, 4 }) }))
      assert(tbl.equals({ 7.5 }, { arr.mean({ 5, 10 }) }))
      local maxval, maxidx = arr.max({ 1, 5, 10, 3 })
      assert(maxval == 10 and maxidx == 3)
      local minval, minidx = arr.min({ 1, 5, 10, 3 })
      assert(minval == 1 and minidx == 1)
    end)

    test("concat", function ()
      assert(tbl.equals({ "abc" }, { arr.concat({ "a", "b", "c" }) }))
    end)

    test("spread", function ()
      assert(tbl.equals({ 1, 2, 3 }, { arr.spread({ 1, 2, 3 }) }))
    end)

    test("shuffle", function ()
      local a = { 1, 2, 3, 4 }
      arr.shuffle(a)
      arr.sort(a)
      assert(tbl.equals(a, { 1, 2, 3, 4 }))
    end)

    test("shuffle with range", function ()
      local a = { 1, 2, 3, 4, 5, 6 }
      arr.shuffle(a, 2, 5)
      assert(a[1] == 1)
      assert(a[6] == 6)
      arr.sort(a, function (x, y) return x < y end)
      assert(tbl.equals(a, { 1, 2, 3, 4, 5, 6 }))
    end)

    test("pack", function ()
      local t = arr.pack(1, 2, 3)
      assert(t.n == nil)
      assert(t[1] == 1 and t[2] == 2 and t[3] == 3)
    end)

    test("pack empty", function ()
      local t = arr.pack()
      assert(t.n == nil)
      assert(#t == 0)
    end)

    test("tup", function ()
      local t = arr.tup(1, 2, 3)
      assert(t.n == 3)
      assert(t[1] == 1 and t[2] == 2 and t[3] == 3)
    end)

    test("tup empty", function ()
      local t = arr.tup()
      assert(t.n == 0)
    end)

    test("tup with nils", function ()
      local t = arr.tup(1, nil, 3)
      assert(t.n == 3)
      assert(t[1] == 1)
      assert(t[2] == nil)
      assert(t[3] == 3)
    end)

    test("tup trailing nils", function ()
      local t = arr.tup(1, 2, nil)
      assert(t.n == 3)
      assert(t[1] == 1)
      assert(t[2] == 2)
      assert(t[3] == nil)
    end)

    test("spread with n", function ()
      local t = { n = 3, 1, nil, 3 }
      local a, b, c = arr.spread(t)
      assert(a == 1)
      assert(b == nil)
      assert(c == 3)
    end)

    test("spread preserves trailing nils", function ()
      local t = arr.tup(1, 2, nil)
      local a, b, c = arr.spread(t)
      assert(a == 1)
      assert(b == 2)
      assert(c == nil)
      assert(select("#", arr.spread(t)) == 3)
    end)

    test("spread without n uses #", function ()
      local t = { 1, 2, 3 }
      local a, b, c = arr.spread(t)
      assert(a == 1 and b == 2 and c == 3)
    end)

    test("clear", function ()
      test("clears entire array", function ()
        local t = { 1, 2, 3, 4 }
        arr.clear(t)
        assert(tbl.equals({}, t))
      end)
      test("clears range", function ()
        local t = { 1, 2, 3, 4, 5 }
        arr.clear(t, 2, 4)
        assert(t[1] == 1)
        assert(t[2] == nil)
        assert(t[3] == nil)
        assert(t[4] == nil)
        assert(t[5] == 5)
      end)
    end)

    test("overlay", function ()
      test("overlays values at index", function ()
        local t = { 1, 2, 3, 4 }
        arr.overlay(t, 2, 10, 20)
        assert(tbl.equals({ 1, 10, 20 }, t))
      end)
      test("truncates with no values", function ()
        local t = { 1, 2, 3, 4 }
        arr.overlay(t, 2)
        assert(tbl.equals({ 1 }, t))
      end)
    end)

    test("find", function ()
      test("finds element matching predicate", function ()
        local v, i = arr.find({ 1, 2, 3, 4 }, function (x) return x > 2 end)
        assert(v == 3)
        assert(i == 3)
      end)
      test("returns nil if not found", function ()
        local v, i = arr.find({ 1, 2, 3 }, function (x) return x > 10 end)
        assert(v == nil)
        assert(i == nil)
      end)
      test("passes extra args to predicate", function ()
        local v, i = arr.find({ 1, 2, 3 }, function (x, threshold) return x > threshold end, 1)
        assert(v == 2)
        assert(i == 2)
      end)
    end)

    test("fill", function ()
      test("fills entire array", function ()
        local t = { 1, 2, 3, 4 }
        arr.fill(t, 0)
        assert(tbl.equals({ 0, 0, 0, 0 }, t))
      end)
      test("fills range", function ()
        local t = { 1, 2, 3, 4, 5 }
        arr.fill(t, 0, 2, 4)
        assert(tbl.equals({ 1, 0, 0, 0, 5 }, t))
      end)
    end)

    test("lookup", function ()
      local t = { 1, 3, 2 }
      local map = { "a", "b", "c" }
      arr.lookup(t, map)
      assert(tbl.equals({ "a", "c", "b" }, t))
    end)

    test("take", function ()
      assert(tbl.equals({ 1, 2 }, arr.take({ 1, 2, 3, 4 }, 2)))
      assert(tbl.equals({ 1, 2, 3, 4 }, arr.take({ 1, 2, 3, 4 }, 10)))
      assert(tbl.equals({}, arr.take({ 1, 2, 3, 4 }, 0)))
    end)

    test("drop", function ()
      assert(tbl.equals({ 3, 4 }, arr.drop({ 1, 2, 3, 4 }, 2)))
      assert(tbl.equals({}, arr.drop({ 1, 2, 3, 4 }, 10)))
      assert(tbl.equals({ 1, 2, 3, 4 }, arr.drop({ 1, 2, 3, 4 }, 0)))
    end)

    test("takelast", function ()
      assert(tbl.equals({ 3, 4 }, arr.takelast({ 1, 2, 3, 4 }, 2)))
      assert(tbl.equals({ 1, 2, 3, 4 }, arr.takelast({ 1, 2, 3, 4 }, 10)))
    end)

    test("droplast", function ()
      assert(tbl.equals({ 1, 2 }, arr.droplast({ 1, 2, 3, 4 }, 2)))
      assert(tbl.equals({}, arr.droplast({ 1, 2, 3, 4 }, 10)))
    end)

    test("zip", function ()
      local a = { 1, 2, 3 }
      local b = { "a", "b", "c" }
      assert(tbl.equals({ { 1, "a" }, { 2, "b" }, { 3, "c" } }, arr.zip(a, b)))
      assert(tbl.equals({ { 1, "a" }, { 2, "b" } }, arr.zip({ 1, 2 }, { "a", "b", "c" })))
    end)

    test("unzip", function ()
      local zipped = { { 1, "a" }, { 2, "b" }, { 3, "c" } }
      local a, b = arr.unzip(zipped)
      assert(tbl.equals({ 1, 2, 3 }, a))
      assert(tbl.equals({ "a", "b", "c" }, b))
    end)

    test("range", function ()
      assert(tbl.equals({ 1, 2, 3, 4, 5 }, arr.range(1, 5)))
      assert(tbl.equals({ 2, 4, 6 }, arr.range(2, 6, 2)))
      assert(tbl.equals({ 5, 4, 3, 2, 1 }, arr.range(5, 1, -1)))
    end)

    test("interleave", function ()
      assert(tbl.equals({ 1, 0, 2, 0, 3 }, arr.interleave({ 1, 2, 3 }, 0)))
      assert(tbl.equals({ 1 }, arr.interleave({ 1 }, 0)))
      assert(tbl.equals({}, arr.interleave({}, 0)))
    end)

    test("compact", function ()
      local t = { 1, nil, 2, false, 3, nil }
      arr.compact(t)
      assert(tbl.equals({ 1, 2, 3 }, t))
    end)

    test("compacted", function ()
      local t = { 1, nil, 2, false, 3, nil }
      local r = arr.compacted(t)
      assert(tbl.equals({ 1, 2, 3 }, r))
      assert(t[1] == 1)
    end)

    test("unique", function ()
      local t = { 1, 2, 2, 3, 1, 4, 3 }
      arr.unique(t)
      assert(tbl.equals({ 1, 2, 3, 4 }, t))
    end)

    test("uniqued", function ()
      local t = { 1, 2, 2, 3, 1, 4 }
      local r = arr.uniqued(t)
      assert(tbl.equals({ 1, 2, 3, 4 }, r))
      assert(#t == 6)
    end)

    test("group", function ()
      local t = { 1, 2, 3, 4, 5, 6 }
      local g = arr.group(t, function (v) return v % 2 == 0 and "even" or "odd" end)
      assert(tbl.equals({ 1, 3, 5 }, g["odd"]))
      assert(tbl.equals({ 2, 4, 6 }, g["even"]))
    end)

    test("partition", function ()
      local t = { 1, 2, 3, 4, 5, 6 }
      local pass, fail = arr.partition(t, function (v) return v % 2 == 0 end)
      assert(tbl.equals({ 2, 4, 6 }, pass))
      assert(tbl.equals({ 1, 3, 5 }, fail))
    end)

    test("toset", function ()
      local t = { "a", "b", "c" }
      local s = arr.toset(t)
      assert(s["a"] == true)
      assert(s["b"] == true)
      assert(s["c"] == true)
      assert(s["d"] == nil)
    end)

    test("chunks", function ()
      local result = {}
      arr.chunks({ 1, 2, 3, 4, 5 }, 2, function (_, i, j)
        result[#result + 1] = { i = i, j = j }
      end)
      assert(tbl.equals({ { i = 1, j = 2 }, { i = 3, j = 4 }, { i = 5, j = 5 } }, result))
    end)

    test("chunked", function ()
      local r = arr.chunked({ 1, 2, 3, 4, 5 }, 2)
      assert(tbl.equals({ { 1, 2 }, { 3, 4 }, { 5 } }, r))
    end)

    test("pull", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 5 do coroutine.yield(i) end
      end)
      assert(tbl.equals({ 1, 2, 3, 4, 5 }, arr.pull(iter)))
    end)

    test("pull with limit", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 10 do coroutine.yield(i) end
      end)
      assert(tbl.equals({ 1, 2, 3 }, arr.pull(iter, 3)))
    end)

    test("pullpacked", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1, 2)
        coroutine.yield("b", 3, 4)
        coroutine.yield("c", 5, 6)
      end)
      local r = arr.pullpacked(iter)
      assert(tbl.equals({ { "a", 1, 2, n = 3 }, { "b", 3, 4, n = 3 }, { "c", 5, 6, n = 3 } }, r))
    end)

    test("pullpacked with limit", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1)
        coroutine.yield("b", 2)
        coroutine.yield("c", 3)
      end)
      local r = arr.pullpacked(iter, 2)
      assert(tbl.equals({ { "a", 1, n = 2 }, { "b", 2, n = 2 } }, r))
    end)

    test("pullmap", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("hello", 1, 5)
        coroutine.yield("world", 1, 5)
      end)
      local r = arr.pullmap(iter, string.sub)
      assert(tbl.equals({ "hello", "world" }, r))
    end)

    test("pullfilter", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1)
        coroutine.yield("b", 2)
        coroutine.yield("c", 3)
        coroutine.yield("d", 4)
      end)
      local r = arr.pullfilter(iter, function (_, n) return n % 2 == 0 end)
      assert(tbl.equals({ { "b", 2, n = 2 }, { "d", 4, n = 2 } }, r))
    end)

    test("pullfilter with limit", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 10 do coroutine.yield("x", i) end
      end)
      local r = arr.pullfilter(iter, function (_, n) return n % 2 == 0 end, 2)
      assert(tbl.equals({ { "x", 2, n = 2 }, { "x", 4, n = 2 } }, r))
    end)

    test("pullreduce", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield(1, 10)
        coroutine.yield(2, 20)
        coroutine.yield(3, 30)
      end)
      local r = arr.pullreduce(iter, function (acc, a, b) return acc + a + b end, 0)
      assert(r == 66)
    end)

    test("pulleach", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1)
        coroutine.yield("b", 2)
      end)
      local results = {}
      arr.pulleach(iter, function (s, n) results[s] = n end)
      assert(tbl.equals({ a = 1, b = 2 }, results))
    end)

    test("pullfind", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1)
        coroutine.yield("b", 2)
        coroutine.yield("c", 3)
      end)
      local s, n = arr.pullfind(iter, function (_, n) return n == 2 end)
      assert(s == "b" and n == 2)
    end)

    test("pullfind not found", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield("a", 1)
      end)
      local r = arr.pullfind(iter, function (_, n) return n == 99 end)
      assert(r == nil)
    end)

    test("pullcount", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 5 do coroutine.yield(i) end
      end)
      assert(arr.pullcount(iter) == 5)
    end)

    test("pullcount with predicate", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 10 do coroutine.yield(i) end
      end)
      assert(arr.pullcount(iter, function (n) return n % 2 == 0 end) == 5)
    end)

    test("pullany true", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield(1)
        coroutine.yield(2)
        coroutine.yield(3)
      end)
      assert(arr.pullany(iter, function (n) return n == 2 end) == true)
    end)

    test("pullany false", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield(1)
        coroutine.yield(3)
      end)
      assert(arr.pullany(iter, function (n) return n == 2 end) == false)
    end)

    test("pullall true", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield(2)
        coroutine.yield(4)
        coroutine.yield(6)
      end)
      assert(arr.pullall(iter, function (n) return n % 2 == 0 end) == true)
    end)

    test("pullall false", function ()
      local iter = coroutine.wrap(function ()
        coroutine.yield(2)
        coroutine.yield(3)
        coroutine.yield(4)
      end)
      assert(arr.pullall(iter, function (n) return n % 2 == 0 end) == false)
    end)

    test("consume alias", function ()
      local iter = coroutine.wrap(function ()
        for i = 1, 3 do coroutine.yield(i) end
      end)
      assert(tbl.equals({ 1, 2, 3 }, arr.consume(iter)))
    end)

    test("scale", function ()
      local t = { 1, 2, 3, 4 }
      arr.scale(t, 2)
      assert(tbl.equals({ 2, 4, 6, 8 }, t))
    end)

    test("scale with range", function ()
      local t = { 1, 2, 3, 4, 5 }
      arr.scale(t, 2, 2, 4)
      assert(tbl.equals({ 1, 4, 6, 8, 5 }, t))
    end)

    test("add", function ()
      local t = { 1, 2, 3, 4 }
      arr.add(t, 10)
      assert(tbl.equals({ 11, 12, 13, 14 }, t))
    end)

    test("add with range", function ()
      local t = { 1, 2, 3, 4, 5 }
      arr.add(t, 10, 2, 4)
      assert(tbl.equals({ 1, 12, 13, 14, 5 }, t))
    end)

    test("abs", function ()
      local t = { -1, 2, -3, 4 }
      arr.abs(t)
      assert(tbl.equals({ 1, 2, 3, 4 }, t))
    end)

    test("scalev", function ()
      local t = { 1, 2, 3, 4 }
      local t2 = { 2, 3, 4, 5 }
      arr.scalev(t, t2)
      assert(tbl.equals({ 2, 6, 12, 20 }, t))
    end)

    test("addv", function ()
      local t = { 1, 2, 3, 4 }
      local t2 = { 10, 20, 30, 40 }
      arr.addv(t, t2)
      assert(tbl.equals({ 11, 22, 33, 44 }, t))
    end)

    test("dot", function ()
      local a = { 1, 2, 3 }
      local b = { 4, 5, 6 }
      assert(arr.dot(a, b) == 32)
    end)

    test("dot with range", function ()
      local a = { 1, 2, 3, 4 }
      local b = { 10, 5, 6, 10 }
      assert(arr.dot(a, b, 2, 3) == 28)
    end)

    test("magnitude", function ()
      local t = { 3, 4 }
      assert(arr.magnitude(t) == 5)
    end)

    test("reverse with range", function ()
      local t = { 1, 2, 3, 4, 5 }
      arr.reverse(t, 2, 4)
      assert(tbl.equals({ 1, 4, 3, 2, 5 }, t))
    end)

  end)

end
