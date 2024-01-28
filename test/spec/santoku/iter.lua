local test = require("santoku.test")

local fun = require("santoku.functional")
local fbindr = fun.bindr

local varg = require("santoku.varg")
local vtup = varg.tup

local op = require("santoku.op")
local oadd = op.add

local arr = require("santoku.array")
local asort = arr.sort

local iter = require("santoku.iter")
local akeys = iter.akeys
local avals = iter.avals
local tkeys = iter.tkeys
local tvals = iter.tvals
local icollect = iter.collect
local ifilter = iter.filter
local ieach = iter.each
local ireduce = iter.reduce
local imap = iter.map
local iasync = iter.async
local iwrap = iter.wrap

local tbl = require("santoku.table")
local teq = tbl.equals

test("akeys", function ()
  assert(teq({ 1, 2, 3, 4 }, icollect(akeys({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("avals", function ()
  assert(teq({ "a", "b", "c", "d" }, icollect(avals({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("tkeys", function ()
  assert(teq({ "2", "a", "b" }, asort(icollect(imap(tostring, tkeys({ a = 2, [2] = 4, b = 6 }))))))
end)

test("tvals", function ()
  assert(teq({ 2, 4, 6 }, asort(icollect(tvals({ a = 2, [2] = 4, b = 6 })))))
end)

test("map", function ()
  assert(teq({ 2, 3, 4, 5 }, icollect(imap(fbindr(oadd, 1), avals({ 1, 2, 3, 4 })))))
end)

test("reduce", function ()
  assert(teq({ 6 }, { ireduce(oadd, 0, avals({ 1, 2, 3 })) }))
end)

test("filter", function ()
  assert(teq({ 2, 4 }, icollect(ifilter(function (a) return a % 2 == 0 end, avals({ 1, 2, 3, 4 })))))
end)

test("each", function ()
  local called = 0
  ieach(function (...)
    called = called + 1
    assert(teq({ ... }, { called }))
  end, avals({ 1, 2, 3, 4 }))
  assert(called == 4)
end)

test("async", function ()
  local async = iasync(avals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  vtup(function (...)
    assert(teq({ ... }, { "hi" }))
  end, async(function (done, x)
    called = called + 1
    assert(teq({ called }, { x }))
    return done(true)
  end, function (ok)
    finished = true
    assert(teq({ 4 }, { called }))
    assert(ok == true)
    return "hi"
  end))
  assert(finished)
end)

test("async abort", function ()
  local async = iasync(avals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  vtup(function (...)
    assert(teq({ ... }, { "exit" }))
  end, async(function (done, x)
    called = called + 1
    assert(teq({ called }, { x }))
    if x > 2 then
      return done(false, "exit")
    else
      return done(true)
    end
  end, function (ok, x)
    finished = true
    assert(teq({ 3 }, { called }))
    assert(ok == false)
    return x
  end))
  assert(finished)
end)

test("wrap", function ()
  local wrap = iwrap(avals({ "a", "b", "c", "d" }))
  assert(teq({ "a", "b", "c", "d" }, { wrap(), wrap(), wrap(), wrap() }))
end)

-- test("chunk", function ()
--
--   test("takes n items from a generator", function ()
--     local vals = gen.pack(1, 2, 3):chunk(2):tup()
--     local a, b = vals()
--     assert.same(a, { 1, 2, n = 2 })
--     assert.same(b, { 3, n = 1 })
--   end)
--
-- end)
--
-- test("flatten", function ()
--
--   test("flattens a generator of generators", function ()
--     local v = gen(function (yield)
--       yield(gen.pack(1, 2, 3, 4))
--       yield(gen.pack(5, 6, 7, 8))
--     end):flatten():vec()
--     assert.same(v, vec(1, 2, 3, 4, 5, 6, 7, 8))
--   end)
--
-- end)
--
-- test("all", function ()
--
--   test("reduces with and", function ()
--
--     local gen1 = gen.pack(true, true, true)
--     local gen2 = gen.pack(true, false, true)
--
--     assert(gen1:all())
--     assert(not gen2:all())
--
--   end)
--
-- end)
--
-- test("chain", function ()
--
--   test("chains generators", function ()
--
--     local gen1 = gen.pack(1, 2)
--     local gen2 = gen.pack(3, 4)
--     local vals = gen.chain(gen1, gen2):vec()
--
--     assert.same(vec(1, 2, 3, 4), vals)
--
--   end)
--
-- end)
--
-- test("append", function ()
--
--   test("adds to end of gen, supports multiple args as single generated value", function ()
--
--     local gen = gen.empty():append(1, 2):append(3, 4):co()
--
--     gen:step()
--     assert.same({ 1, 2 }, { gen.val() })
--     gen:step()
--     assert.same({ 3, 4 }, { gen.val() })
--     assert(not gen:step())
--
--   end)
--
-- end)
--
-- test("max", function ()
--
--   test("returns the max value in a generator", function ()
--
--     local gen = gen.pack(1, 6, 3, 9, 2, 10, 4)
--
--     local max = gen:max()
--
--     assert.equals(10, max)
--
--   end)
--
-- end)
--
-- test("max", function ()
--   assert.equals(10, gen.pack(1, 10, 2, 3, 4, 5):max())
-- end)
--
-- test("min", function ()
--   assert.equals(0, gen.pack(1, 10, 2, 3, 0, 4, 5):min())
-- end)
--
-- test("empty", function ()
--
--   test("should produce an empty generator", function ()
--
--     local gen = gen.empty()
--
--     local called = false
--
--     gen:each(function ()
--       called = true
--     end)
--
--     assert(not called)
--
--   end)
--
-- end)
--
-- test("paster", function ()
--
--   test("should paste values to the right", function ()
--
--     local vals = gen.pack(1, 2, 3):paster("num"):vec()
--
--     assert.same(vec(vec(1, "num"), vec(2, "num"), vec(3, "num")), vals)
--
--   end)
--
-- end)
--
-- test("pastel", function ()
--
--   test("should paste values to the left", function ()
--
--     local vals = gen.pack(1, 2, 3):pastel("num"):vec()
--
--     assert.same(vec(vec("num", 1), vec("num", 2), vec("num", 3)), vals)
--
--   end)
--
-- end)
--
-- test("discard", function ()
--
--   test("should run a generator without processing vals", function ()
--
--     local called = false
--
--     gen(function (yield)
--       called = true
--       yield(1)
--       yield(2)
--     end):discard()
--
--     assert(called)
--
--   end)
--
-- end)
--
-- test("tup", function ()
--
--   test("should convert a generator to multiple tuples", function ()
--
--     local vals = gen(function (yield)
--       yield(1, 2)
--       yield(3, 4)
--     end):tup()
--
--     local a, b = vals()
--
--     assert.same({ 1, 2 }, { a() })
--     assert.same({ 3, 4 }, { b() })
--
--   end)
--
-- end)
--
-- test("unpack", function ()
--
--   test("should unpack a generator", function ()
--
--     local gen = gen.pack(1, 2, 3)
--
--     assert.same({ 1, 2, 3 }, { gen:unpack() })
--
--   end)
--
-- end)
--
-- test("last", function ()
--
--   test("should return the last element in a generator", function ()
--
--     local gen = gen.pack(1, 2, 3)
--
--     assert(3, gen:last())
--
--   end)
--
-- end)
--
-- test("step", function ()
--
--   test("should step through a coroutine-generator", function ()
--
--     local gen = gen.pack(1, 2, 3):co()
--
--     assert(gen:step())
--     assert(1 == gen.val())
--     assert(gen:step())
--     assert(2 == gen.val())
--     assert(gen:step())
--     assert(3 == gen.val())
--     assert(not gen:step())
--
--   end)
--
--   test("throw errors that occur in the coroutine", function ()
--
--     local gen = gen(function ()
--       error("err")
--     end):co()
--
--     assert.has.errors(function ()
--       gen:step()
--     end)
--
--   end)
--
-- end)
--
-- test("take", function ()
--
--   test("should create a new generator that takes from an existing generator", function ()
--
--     local gen0 = gen.pack(1, 2, 3, 4)
--     local gen1 = gen0:co():take(2)
--
--     assert.same(gen1:vec(), vec(1, 2))
--     assert.same(gen0:vec(), vec(3, 4))
--
--   end)
--
-- end)
--
-- test("zip", function ()
--
--   test("zips generators together", function ()
--
--     local gen1 = gen.pack(1, 2, 3, 4):co()
--     local gen2 = gen.pack(1, 2, 3, 4):co()
--
--     local v = gen.zip({ tups = true }, gen1, gen2):tup()
--
--     local a, b, c, d = v()
--     local x, y
--
--     x, y = a()
--     assert.same({ 1, 1 }, { x(), y() })
--
--     x, y = b()
--     assert.same({ 2, 2 }, { x(), y() })
--
--     x, y = c()
--     assert.same({ 3, 3 }, { x(), y() })
--
--     x, y = d()
--     assert.same({ 4, 4 }, { x(), y() })
--
--   end)
--
--   test("by default unpacks tuples", function ()
--     assert.same({ { 1, 3, n = 2 }, { 2, 4, n = 2 }, n = 2 },
--       gen.pack(1, 2):co():zip(gen.pack(3, 4):co()):vec())
--   end)
--
-- end)
--
-- test("slice", function ()
--
--   test("slices the generator", function ()
--
--     local gen = gen.pack("file", ".txt"):co():slice(2)
--
--     local v = gen:tup()
--
--     assert.equals(".txt", v())
--
--     assert(not gen:step())
--
--   end)
--
--   test("slices the generator", function ()
--
--     local gen0 = gen.pack(1, 2, 3, 4):co()
--     local gen1 = gen0:slice(2, 2):co()
--
--     local v = gen1:tup()
--
--     assert.same({ 2, 3 }, { v() })
--
--     assert(not gen1:step())
--     assert(gen0:step())
--     assert(not gen0:step())
--
--   end)
-- end)
--
-- test("tabulate", function ()
--
--   test("creates a table from a generator", function ()
--
--     local vals = gen.pack(1, 2, 3, 4):co()
--     local tbl = vals:tabulate("one", "two", "three", "four" )
--
--     assert.equals(1, tbl.one)
--     assert.equals(2, tbl.two)
--     assert.equals(3, tbl.three)
--     assert.equals(4, tbl.four)
--
--   end)
--
--   test("captures remaining values in a 'rest' property", function ()
--
--     local vals = gen.pack(1, 2, 3, 4):co()
--     local tbl = vals:tabulate({ rest = "others" }, "one")
--
--     assert.equals(1, tbl.one)
--     assert.same({ 2, 3, 4, n = 3 }, tbl.others)
--
--   end)
--
--   test("works with normal generators with pairs of arguments", function ()
--     assert.same({ a = 1, b = 2, c = 3 }, gen(function (yield)
--       yield("a", 1)
--       yield("b", 2)
--       yield("c", 3)
--     end):tabulate())
--   end)
--
-- end)
--
-- test("none", function ()
--
--   test("reduces with not and", function ()
--
--     local gen1 = gen.pack(false, false, false):co()
--     local gen2 = gen.pack(true, false, true):co()
--
--     assert(gen1:none())
--     assert(not gen2:none())
--
--   end)
--
-- end)
--
-- test("equals", function ()
--
--   test("checks if two generators have equal values", function ()
--
--     local gen1 = gen.pack(1, 2, 3, 4):co()
--     local gen2 = gen.pack(5, 6, 7, 8):co()
--
--     assert.equals(false, gen1:equals(gen2))
--     assert(gen1:done())
--     assert(gen2:done())
--
--   end)
--
--  test("checks if two generators have equal values", function ()
--
--    local gen1 = gen.pack(1, 2, 3, 4):co()
--    local gen2 = gen.pack(1, 2, 3, 4):co()
--
--    assert.equals(true, gen1:equals(gen2))
--    assert(gen1:done())
--    assert(gen2:done())
--
--  end)
--
--  test("checks if two generators have equal values", function ()
--
--    local gen1 = gen.pack(1, 2, 3, 4):co()
--
--    -- NOTE: this might seem unexpected but
--    -- generators are not immutable. This will
--    -- result in comparing 1 to 2 and 3 to 4 due to
--    -- repeated invocations of the same generator.
--    assert.equals(false, gen1:equals(gen1))
--
--  end)
--
--  test("handles odd length generators", function ()
--
--    local gen1 = gen.pack(1, 2, 3):co()
--    local gen2 = gen.pack(1, 2, 3, 4):co()
--
--    assert.equals(false, gen1:equals(gen2))
--    assert(gen1:done())
--
--    -- TODO: See the note on the implementation of
--    -- gen:equals() for why these are commented out.
--    --
--    -- assert(not gen2:done())
--    -- assert.equals(4, gen2())
--    -- assert(gen2:done())
--
--  end)
--
-- end)
--
-- test("find", function ()
--
--   test("finds by a predicate", function ()
--
--     local gen = gen.pack(1, 2, 3, 4):co()
--
--     local v = gen:find(function (a) return a == 3 end)
--
--     assert.equals(3, v)
--
--   end)
--
-- end)
--
-- test("interleave", function ()
--
--   test("interleave values into a generator", function ()
--
--     local v = gen.pack(1, 2, 3, 4):interleave("x"):vec()
--
--     assert.same(v, vec(1, "x", 2, "x", 3, "x", 4))
--
--   end)
--
-- end)
--
-- test("nvals", function ()
--
--   local v = vec(1, 2, 3, 4)
--   v:remove(1, 1)
--   assert.same({ 2, 3, 4 }, gen.nvals(v):vec():unwrapped())
--
-- end)
--
-- test("nvals find first in reverse", function ()
--
--   local v = vec(true, true, false, true, true, true)
--   assert.equals(false, gen.nvals(v, -1):co():find(op["not"]))
--
--   local v = vec(true, true, true, true, true, true)
--   assert.is_nil(gen.nvals(v, -1):co():find(op["not"]))
--
-- end)
--
-- test("chunk groups values in vectors", function ()
--   local g = gen.pack(1, 2, 3, 4):chunk(2):co()
--   assert.equals(true, g:step())
--   assert.same({ 1, 2, n = 2 }, g.val())
--   assert.equals(true, g:step())
--   assert.same({ 3, 4, n = 2 }, g.val())
--   assert.equals(false, g:step())
-- end)
--
-- test("group groups a generator into arguments", function ()
--   assert.same({ { 1, 2, n = 2 }, { 3, 4, n = 2 }, n = 2 }, gen.pack(1, 2, 3, 4):group(2):vec())
-- end)
--
-- test("sum", function ()
--   assert.equals(10, gen.pack(4, 4, 2):sum())
-- end)
--
-- test("sum of nothing gives nil", function ()
--   assert.is_nil(gen.pack():sum())
-- end)
--
-- test("range", function ()
--
--   assert.same({ 1, 2, 3, 4, n = 4 }, gen.range(4):vec())
--   assert.same({ -1, -2, -3, -4, n = 4 }, gen.range(-4):vec())
--
--   assert.same({ 3, 4, n = 2 }, gen.range(3, 4):vec())
--   assert.same({ -3, -4, n = 2 }, gen.range(-3, -4):vec())
--
--   assert.same({ 2, 4, 6, n = 3 }, gen.range(2, 6, 2):vec())
--
-- end)
