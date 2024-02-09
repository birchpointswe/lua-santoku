local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local notnil = validate.isnotnil
local isnil = validate.isnil
local eq = validate.isequal

local fun = require("santoku.functional")
local bind = fun.bind
local noop = fun.noop

local varg = require("santoku.varg")
local tup = varg.tup

local op = require("santoku.op")
local add = op.add

local arr = require("santoku.array")
local sort = arr.sort
local spread = arr.spread
local pack = arr.pack

local iter = require("santoku.iter")
local pairs = iter.pairs
local paste = iter.paste
local zip = iter.zip
local ikeys = iter.ikeys
local ivals = iter.ivals
local sum = iter.sum
local keys = iter.keys
local vals = iter.vals
local map = iter.map
local collect = iter.collect
local singleton = iter.singleton
local once = iter.once
local flatten = iter.flatten
local reduce = iter.reduce
local filter = iter.filter
local each = iter.each
local interleave = iter.interleave
local deinterleave = iter.deinterleave
local tail = iter.tail
local drop = iter.drop
local take = iter.take
local last = iter.last
local async = iter.async
local first = iter.first
local chain = iter.chain
local tabulate = iter.tabulate

local tbl = require("santoku.table")
local teq = tbl.equals

test("ikeys", function ()
  assert(teq({ 1, 2, 3, 4 }, collect(ikeys({ "a", "b", "c", "d", a = 1, b = 2 }))))
end)

test("ivals", function ()
  assert(teq({ "a", "b", "c", "d" }, collect(ivals({ "a", "b", "c", "d", a = 1, b = 2 }))))
  assert(teq({}, collect(ivals({}))))
end)

test("keys", function ()
  assert(teq({ "2", "a", "b" }, sort(collect(map(tostring, keys({ a = 2, [2] = 4, b = 6 }))))))
end)

test("vals", function ()
  assert(teq({ 2, 4, 6 }, sort(collect(vals({ a = 2, [2] = 4, b = 6 })))))
end)

test("empty", function ()
  assert(teq({}, collect(noop)))
end)

test("single", function ()
  assert(teq({ "a" }, collect(singleton("a"))))
end)

test("flatten", function ()
  local input = { { 1, 2 }, { 3, 4 }, { 5, 6 }, { 7, 8 } }
  local expected = { 1, 2, 3, 4, 5, 6, 7, 8 }
  assert(teq(expected, collect(flatten(map(ivals, ivals(input))))))
  assert(teq({ 1, 2, 3, 4 }, collect(flatten(map(singleton, ivals({ 1, 2, 3, 4 }))))))
end)

test("flatten", function ()
  local input = { { a = 1 }, { b = 2 }, { c = 3 }, { d = 4 } }
  local expected = { { "a", 1 }, { "b", 2 }, { "c", 3 }, { "d", 4 } }
  assert(teq(expected, collect(map(pack, flatten(map(pairs, vals(input)))))))
  assert(teq({ "a", "b", "c", "d" }, collect(flatten(map(pairs, vals(input))))))
end)

test("map", function ()
  assert(teq({ 2, 3, 4, 5 }, collect(map(bind(add, 1), ivals({ 1, 2, 3, 4 })))))
end)

test("reduce", function ()
  assert(teq({ 6 }, { reduce(add, 0, ivals({ 1, 2, 3 })) }))
end)

test("filter", function ()
  assert(teq({ 2, 4 }, collect(filter(function (a) return a % 2 == 0 end, ivals({ 1, 2, 3, 4 })))))
end)

test("each", function ()
  local called = 0
  each(function (...)
    called = called + 1
    assert(teq({ ... }, { called }))
  end, ivals({ 1, 2, 3, 4 }))
  assert(called == 4)
end)

test("once", function ()
  local it = once(function () return 1 end)
  local i = it()
  assert(notnil(i))
  assert(eq(i, 1))
  i = it()
  assert(isnil(i))
end)

test("interleave", function ()
  assert(teq({ 1, "x", 2, "x", 3 }, collect(interleave("x", ivals({ 1, 2, 3 })))))
  assert(teq({ 1, "x", 3, }, collect(interleave("x", ivals({ 1, 3 })))))
  assert(teq({ 1 }, collect(interleave("x", ivals({ 1 })))))
end)

test("deinterleave", function ()
  assert(teq({ 1, 2, 3 }, collect(deinterleave(ivals({ 1, "x", 2, "x", 3 })))))
  assert(teq({ 1, 2 }, collect(deinterleave(ivals({ 1, "x", 2, "x" })))))
  assert(teq({ 1, 2 }, collect(deinterleave(ivals({ 1, "x", 2 })))))
  assert(teq({ 1 }, collect(deinterleave(ivals({ 1, "x" })))))
  assert(teq({ 1 }, collect(deinterleave(ivals({ 1 })))))
  assert(teq({}, collect(deinterleave(ivals({})))))
end)

test("tail", function ()
  assert(teq({ 2, 3 }, collect(tail(ivals({ 1, 2, 3 })))))
  assert(teq({}, collect(tail(ivals({ 3 })))))
end)

test("drop", function ()
  assert(teq({ 1, 2, 3, 4 }, collect(drop(0, ivals({ 1, 2, 3, 4 })))))
  assert(teq({ 3, 4 }, collect(drop(2, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(4, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(5, ivals({ 1, 2, 3, 4 })))))
  assert(teq({}, collect(drop(1, ivals({})))))
  assert(teq({}, collect(drop(1, ivals({ 3 })))))
end)

test("last", function ()
  assert(teq({ 4 }, { last(vals({ 1, 2, 3, 4 })) }))
  assert(teq({ 4 }, { last(vals({ 4 })) }))
  assert(teq({}, { last(vals({})) }))
end)

test("async", function ()
  local asy = async(ivals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  tup(function (...)
    assert(teq({ ... }, { "hi" }))
  end, asy(function (done, x)
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
  local asy = async(ivals({ 1, 2, 3, 4 }))
  local called = 0
  local finished = false
  tup(function (...)
    assert(teq({ ... }, { "exit" }))
  end, asy(function (done, x)
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

test("first", function ()
  assert(teq({ "a", "a" }, { first(pairs({ a = "a" })) }))
end)

test("chain", function ()
  assert(teq({ "a", "a" }, collect(chain(singleton("a"), keys({ a = 1 })))))
end)

test("paste", function ()
  assert(teq({ { "a", 1 }, { "a", 2 } }, collect(map(pack, paste("a", ivals({ 1, 2 }))))))
end)

test("take", function ()
  assert(teq({ 1, 2, 3 }, collect(take(3, ivals({ 1, 2, 3, 4, 5 })))))
end)

test("tabulate", function ()
  assert(teq({ a = 1, b = 2 }, tabulate(map(spread, ivals({ { "a", 1 }, { "b", 2 } })))))
end)

test("collect into table", function ()
  assert(teq({ 1, 2, 3, 4 }, collect(ivals({ 3, 4 }), { 1, 2 })))
  assert(teq({ 3, 4 }, collect(ivals({ 3, 4 }), { 1, 2 }, 1)))
end)

test("zip", function ()
  assert(teq({ { 1, 3 }, { 2, 4 } }, collect(map(pack, zip(ivals({ 1, 2 }), ivals({ 3, 4 }))))))
end)

test("sum", function ()
  assert(teq({ 10 }, { sum(ivals({ 1, 2, 3, 4 })) }))
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
-- test("paste", function ()
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
-- test("spread", function ()
--   local gen = gen.pack(1, 2, 3)
--   assert.same({ 1, 2, 3 }, { gen:unpack() })
-- end)
--
-- test("take", function ()
--   local gen0 = gen.pack(1, 2, 3, 4)
--   local gen1 = gen0:co():take(2)
--   assert.same(gen1:vec(), vec(1, 2))
--   assert.same(gen0:vec(), vec(3, 4))
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
-- test("nvals find first in reverse", function ()
--   local v = vec(true, true, false, true, true, true)
--   assert.equals(false, gen.nvals(v, -1):co():find(op["not"]))
--   local v = vec(true, true, true, true, true, true)
--   assert.is_nil(gen.nvals(v, -1):co():find(op["not"]))
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
--   assert.same({ 1, 2, 3, 4, n = 4 }, gen.range(4):vec())
--   assert.same({ -1, -2, -3, -4, n = 4 }, gen.range(-4):vec())
--   assert.same({ 3, 4, n = 2 }, gen.range(3, 4):vec())
--   assert.same({ -3, -4, n = 2 }, gen.range(-3, -4):vec())
--   assert.same({ 2, 4, 6, n = 3 }, gen.range(2, 6, 2):vec())
-- end)
