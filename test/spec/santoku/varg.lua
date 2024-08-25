local test = require("santoku.test")

local tbl = require("santoku.table")
local teq = tbl.equals

local fun = require("santoku.functional")
local fconst = fun.const

local op = require("santoku.op")
local oadd = op.add

local varg = require("santoku.varg")
local vlen = varg.len
local vsel = varg.sel
local vtake = varg.take
local vget = varg.get
local vset = varg.set
local vappend = varg.append
local vextend = varg.extend
local vinterleave = varg.interleave
local vreduce = varg.reduce
local vtabulate = varg.tabulate
local vfilter = varg.filter
local vreverse = varg.reverse
local veach = varg.each
local vmap = varg.map
local vcall = varg.call

test("basic", function ()
  assert(teq({ 1, 2, 3 }, {
    varg(function (a, b, c)
      assert(teq({ 1, 2, 3 }, { a, b, c }))
      return a, b, c
    end, 1, 2, 3)
  }))
end)

test("len", function ()
  assert(5 == vlen(1, 2, 3, 4, 5))
end)

test("map", function ()
  assert(teq({ 2, 4, 6 }, {
    vmap(function (a) return a * 2 end, 1, 2, 3)
  }))
end)

test("interleave", function ()
  assert(teq({ 1, 5, 2, 5, 3 }, { vinterleave(5, 1, 2, 3) }))
end)

test("sel", function ()
  assert(teq({ 3, 4, 5 }, { vsel(3, 1, 2, 3, 4, 5) }))
end)

test("get", function ()
  assert(teq({ 2 }, { vget(2, 1, 2, 3, 4, 5) }))
  assert(teq({ 3 }, { vget(3, 1, 2, 3, 4, 5) }))
  assert(teq({}, { vget(10, 1, 2, 3, 4, 5) }))
end)

test("set", function ()
  assert(teq({ 1, 10, 3 }, { vset(2, 10, 1, 2, 3) }))
end)

test("take", function ()
  assert(teq({ 1, 2, 3 }, { vtake(3, 1, 2, 3, 4, 5) }))
end)

test("append", function ()
  assert(teq({ 1, 2, 3, 10 }, { vappend(10, 1, 2, 3) }))
end)

test("filter", function ()
  assert(teq({ 2, 4, 6 }, {
    vfilter(function (x)
      return x % 2 == 0
    end, 1, 2, 3, 4, 5, 6)
  }))
end)

test("tabulate", function ()
  assert(teq(
    { a = 1, b = 2, c = 3 },
    vtabulate("a", 1, "b", 2, "c", 3)))
end)

test("reduce", function ()
  assert(teq({ 10 }, { vreduce(oadd, 1, 2, 3, 4) }))
  assert(teq({}, { vreduce(oadd) }))
  assert(teq({ 1 }, { vreduce(oadd, 1) }))
end)

test("each", function ()
  local t = {}
  veach(function (n)
    t[#t + 1] = n
  end, 1, 2, 3)
  assert(teq({ 1, 2, 3 }, t))
end)

test("extend", function ()
  local a = function () return 1, 2, 3 end
  local b = function () return 4, 5, 6 end
  assert(teq({ 1, 2, 3, 4, 5, 6 }, { vextend(b, a()) }))
end)

test("reverse", function ()
  assert(teq({ 3, 2, 1}, { vreverse(1, 2, 3) }))
end)

test("call", function ()
  assert(teq({ 1, 2, 3 }, { vcall(fconst(1), fconst(2), fconst(3)) }))
end)
