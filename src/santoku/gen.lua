-- TODO: CLEAN UP THESE TODOs

-- TODO: Use luassert for asserts across the lib

-- TODO: Add append, extend, etc. functions for
-- basic generators by wrapping

-- TODO: Need some kind of done state

-- TODO: With the callback version there doesn't
-- seem to be an easy way to exit early, but we
-- will want it for things like tabulate, find,
-- take, etc.

-- TODO: Leverage "inherit" to set __index

-- TODO: We should not assign all of M to the
-- generators, instead, only assign gen-related
-- functions

-- TODO: Need an abort capability to
-- early exit iterators that allows for cleanup

-- TODO: Implement pre-curried functions using
-- configuration pattern with no gen first arg
-- resulting in currying behavior. As in:
--    gen.tabulate("a", "b", "c") -- curry
--    gen.tabulate(<gen>, "a", "b", "c") -- no curry

-- TODO: Refactor to avoid coroutines, done, and
-- idx with closures and gensent

-- TODO: Generators need to support
-- close/abort/cleanup for things like closing
-- open files, etc.

local tbl = require("santoku.table")
local vec = require("santoku.vector")
local fun = require("santoku.fun")
local co = require("santoku.co")
local op = require("santoku.op")
local compat = require("santoku.compat")
local tup = require("santoku.tuple")

local M = {}

local MT = {
  __call = function (M, ...)
    return M.gen(...)
  end
}

local MTG = {
  __index = M
}

-- TODO use inherit
M.isgen = function (t)
  if type(t) ~= "table" then
    return false, "not a generator: not a table", t
  end
  return (getmetatable(t) or {}).__index == M, "not a generator", t
end

M.iscogen = function (t)
  if not M.isgen(t) then
    return false, "not a co-generator: not a generator:", t
  elseif not (type(t.cor) == "thread" and type(t.co) == "table") then
    return false, "not a co-generator: missing co and/or cor fields", t
  else
    return true
  end
end

-- TODO: Allow the user to provide an error
-- function, default it to error and ensure only
-- one value is passed
-- TODO: Make sure we handle the final return of
-- the coroutine, not just the yields
-- TODO: Cache value on :done() not on generator
-- creation.
M.gen = function (run, ...)
  run = run or compat.noop
  assert(compat.iscallable(run))
  local args = tup(...)
  return setmetatable({
    run = function (yield, ...)
      yield = yield or compat.noop
      assert(compat.iscallable(yield))
      return run(yield, args(...))
    end
  }, MTG)
end

M.iter = function (fn, ...)
  assert(compat.iscallable(fn))
  return M.gen(function (yield, ...)
    if yield == compat.noop then
      while fn(...) ~= nil do end
    else
      local val
      while true do
        val = tup(fn(...))
        if val() ~= nil then
          yield(val())
        else
          break
        end
      end
    end
  end, ...)
end

M.step = function (gen, ...)
  assert(M.iscogen(gen))
  if gen.status == "dead" then
    return false, "coroutine dead"
  else
    gen.val = tup(gen.co.resume(gen.cor, gen.co.yield, ...))
    gen.status = gen.co.status(gen.cor)
  end
  -- TODO: Make throw or return configurable
  if not gen.val() then
    error((select(2, gen.val())))
  else
    gen.val = tup(select(2, gen.val()))
  end
  return gen.status ~= "dead"
end

M.done = function (gen)
  assert(M.iscogen(gen))
  return gen.status == "dead"
end

M.each = function (gen, fn, ...)
  assert(M.isgen(gen))
  fn = fn or compat.noop
  assert(compat.iscallable(fn))
  if M.iscogen(gen) then
    while gen:step() do
      fn(gen.val(...))
    end
  else
    return gen.run(fn, ...)
  end
end

-- TODO: This should just be called gen(...) to
-- follow the pattern of vec and tbl
M.pack = function (...)
  return M.gen(function (yield, ...)
    for i = 1, select("#", ...) do
      yield((select(i, ...)))
    end
  end, ...)
end

M.vals = function (t)
  assert(type(t) == "table")
  return M.pairs(t):map(fun.nret(2))
end

M.keys = function (t)
  assert(type(t) == "table")
  return M.pairs(t):map(fun.nret(1))
end

M.ivals = function (t, n)
  assert(type(t) == "table")
  return M.ipairs(t, n):map(fun.nret(2))
end

M.nvals = function (t, n)
  assert(type(t) == "table")
  return M.npairs(t, n):map(fun.nret(2))
end

M.ikeys = function (t)
  assert(type(t) == "table")
  return M.ipairs(t):map(fun.nret(1))
end

M.nkeys = function (t)
  assert(type(t) == "table")
  return M.npairs(t):map(fun.nret(1))
end

M.npairs = function (t, n)
  assert(type(t) == "table")
  n = n or 1
  assert(type(n) == "number")
  return M.gen(function (yield)
    local i0, m
    if n > 0 then
      i0, m = 1, t.n
    else
      i0, m = t.n, 1
    end
    for i = i0, m, n do
      yield(i, t[i])
    end
  end)
end

M.ipairs = function (t)
  assert(type(t) == "table")
  return M.gen(function (yield)
    for k, v in ipairs(t) do
      yield(k, v)
    end
  end)
end

M.pairs = function (t)
  assert(type(t) == "table")
  return M.gen(function (yield)
    for k, v in pairs(t) do
      yield(k, v)
    end
  end)
end

M.index = function (gen)
  assert(M.isgen(gen))
  local idx = 0
  return M.gen(function (each)
    return gen:each(function (...)
      idx = idx + 1
      return each(idx, ...)
    end)
  end)
end

M.map = function (gen, fn)
  assert(M.isgen(gen))
  fn = fn or compat.id
  return M.gen(function (yield)
    return gen:each(function (...)
      return yield(fn(...))
    end)
  end)
end

M.reduce = function (gen, acc, ...)
  assert(M.isgen(gen))
  assert(compat.iscallable(acc))
  local ready = false
  local val, m = tup(...), tup.len(...)
  gen:each(function (...)
    if not ready and m == 0 then
      ready = true
      val = tup(...)
      return
    elseif not ready then
      ready = true
    end
    val = tup(acc(val(...)))
  end)
  return val()
end

M.filter = function (gen, fn)
  assert(M.isgen(gen))
  fn = fn or compat.id
  assert(compat.iscallable(fn))
  return M.gen(function (yield)
    return gen:each(function (...)
      if fn(...) then
        return yield(...)
      end
    end)
  end)
end

M.chain = function (...)
  return M.flatten(M.pack(...))
end

M.paster = function (gen, ...)
  local args = tup(...)
  return gen:map(function (...)
    return tup(...)(args())
  end)
end

M.pastel = function (gen, ...)
  local args = tup(...)
  return gen:map(function (...)
    return args(...)
  end)
end

M.intersperse = function (gen, ...)
  assert(M.isgen(gen))
  local args = tup(...)
  local isfirst = true
  return M.gen(function (yield)
    return gen:each(function (...)
      if not isfirst then
        yield(args())
      end
      yield(...)
      isfirst = false
    end)
  end)
end

M.empty = function ()
  return M.gen(function () end)
end

M.flatten = function (gengen)
  assert(M.isgen(gengen))
  return M.gen(function (yield)
    return gengen:each(function (gen)
      return gen:each(yield)
    end)
  end)
end

M.chunk = function (gen, n)
  assert(M.isgen(gen))
  assert(type(n) == "number" and n > 0)
  local chunk = vec()
  return M.gen(function (yield)
    gen:each(function(...)
      if chunk.n >= n then
        yield(chunk)
        chunk = vec(...)
      else
        chunk:append(...)
      end
    end)
    if chunk.n > 0 then
      yield(chunk)
    end
  end)
end

M.discard = function (gen)
  assert(M.isgen(gen))
  return gen:each()
end

-- TODO: Need some tests to define nil handing
-- behavior
M.vec = function (gen, v)
  assert(M.isgen(gen))
  v = v or vec()
  assert(vec.isvec(v))
  return gen:reduce(function (a, ...)
    if select("#", ...) <= 1 then
      return a:append(...)
    else
      return a:append(vec(...))
    end
  end, v)
end

M.tup = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (t, ...)
    if select("#", ...) <= 1 then
      return tup(t(...))
    else
      return tup(t(tup(...)))
    end
  end, tup())
end

M.unpack = function (gen)
  assert(M.isgen(gen))
  return gen:tup()()
end

-- TODO: WHY DOES THIS NOT WORK!?
-- M.all = M.reducer(op["and"], true)
M.all = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (a, n)
    return a and n
  end, true)
end

M.max = function (gen, ...)
  assert(M.isgen(gen))
  return gen:reduce(function(a, b)
    if a > b then
      return a
    else
      return b
    end
  end, ...)
end

M.concat = function (gen, delim)
  return gen:vec():concat(delim)
end

M.last = function (gen)
  assert(M.isgen(gen))
  local last = tup()
  gen:each(function (...)
    last = tup(...)
  end)
  return last()
end

M.set = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (s, v)
    s[v] = true
    return s
  end, {})
end

M.append = function (gen, ...)
  assert(M.isgen(gen))
  local args = tup(...)
  return gen:chain(M.gen(function (yield)
    yield(args())
  end))
end

M.co = function (gen)
  assert(M.isgen(gen))
  gen.co = co()
  gen.cor = gen.co.create(gen.run)
  return gen
end

M.take = function (gen, n)
  assert(M.iscogen(gen))
  assert(type(n) == "number" and n >= 0)
  return M.gen(function (yield)
    while n > 0 and gen:step() do
      n = n - 1
      yield(gen.val())
    end
  end)
end

M.find = function (gen, fn, ...)
  assert(M.iscogen(gen))
  fn = fn or compat.id
  while gen:step() do
    if fn(gen.val(...)) then
      return gen.val()
    end
  end
end

M.includes = function (gen, v)
  assert(M.isgen(gen))
  return nil ~= gen:co():find(function (x)
    return x == v
  end)
end

M.group = function (gen, n)
	assert(M.isgen(gen))
	return gen:chunk(n):map(compat.unpack)
end

M.tabulate = function (gen, opts, ...)
  assert(M.iscogen(gen))
  local keys, nkeys
  if type(opts) == "table" then
    keys, nkeys = tup(...), tup.len(...)
  else
    keys, nkeys = tup(opts, ...), 1 + tup.len(...)
    opts = {}
  end
  local rest = opts.rest
  local ret = tbl()
  local idx = 0
  while idx < nkeys and gen:step() do
    idx = idx + 1
    ret[select(idx, keys())] = gen.val()
  end
  if rest then
    ret[rest] = gen:vec()
  end
  return ret
end

M.zip = function (opts, ...)
  local gens, ngens
  if M.isgen(opts) then
    gens, ngens = tup(opts, ...), 1 + tup.len(...)
    opts = {}
  else
    gens, ngens = tup(...), tup.len(...)
  end
  local mode = opts.mode or "first"
  return M.gen(function (yield, ...)
    while true do
      local nb = 0
      local ret = tup()
      for i = 1, ngens do
        local gen = select(i, ...)
        assert(M.iscogen(gen))
        if gen:step() then
          nb = nb + 1
          ret = tup(ret(gen.val))
        elseif i == 1 and mode == "first" then
          return
        else
          ret = tup(ret(tup()))
        end
      end
      if nb == 0 then
        break
      else
        yield(ret())
      end
    end
  end, gens())
end

M.slice = function (gen, start, num)
  assert(M.iscogen(gen))
  gen:take((start or 1) - 1):discard()
  if num then
    return gen:take(num)
  else
    return gen
  end
end

-- TODO: pausable
-- TODO: Currently the implementation using
-- zip:map results in one extra generator read.
-- If, for example, you have two generators, one
-- of length 3 and the other of length 4, we
-- will pull the 4th value off the second
-- generator instead of just using the fact that
-- the first generator is :done() before the
-- second. Can we somehow do this without
-- resorting to a manual implemetation?
M.equals = function (...)
  local vals = M.zip({ mode = "longest" }, ...):map(tup.equals):all()
  return vals and M.pack(...):map(M.done):all()
end

M.none = fun.compose(op["not"], M.find)

return setmetatable(M, MT)
