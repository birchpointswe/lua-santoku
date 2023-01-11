-- TODO: Leverage "inherit" to set __index
-- TODO: Consider overloading operators for generators
-- TODO: We should not assign all of M to the
-- generators, instead, only assign gen-related
-- functions
-- TODO: genco, gennil, etc names arent great,
-- perhaps gco, gsent, gnil, gend?
-- user-facing APIs for creating iterators
-- TODO: Need an gen:abort() function to early
-- exit iterators that allows for cleanup
-- TODO: Add asserts to all 'er' functions and
-- the non-'er' functions that don't immediately
-- call the 'er' functions
-- TODO: Do we really want the M.GEN thing for
-- asserts? It's a bit ugly
-- TODO: Ensure that we use a simple "return"
-- instead of "return nil" for cases where we
-- just want to end the function or generator.
-- TODO: Refactor to use gensent/genend instead of
-- genco
-- TODO: Leverage tuple library in earnest (map,
-- reduce, each, etc.)
-- TODO: Don't cache a value on generator
-- creation, but instead cache on :done()

-- TODO: Add pre-curried functions

local vec = require("santoku.vector")
local err = require("santoku.err")
local fun = require("santoku.fun")
local compat = require("santoku.compat")
local op = require("santoku.op")
local co = require("santoku.co")

local M = {}

-- TODO: Hide from the user. See the note on
-- M.genend
M.END = {}

-- TODO use inherit
M.isgen = function (t)
  if type(t) ~= "table" then
    return false
  end
  return (getmetatable(t) or {}).__index == M
end

-- TODO: Allow the user to provide an error
-- function, default it to error and ensure only
-- one value is passed
-- TODO: Make sure we handle the final return of
-- the coroutine, not just the yields
-- TODO: Cache value on :done() not on generator
-- creation.
M.genco = function (fn, ...)
  assert(type(fn) == "function")
  local co = co.make()
  local cor = co.create(fn)
  local idx = 0
  local val = vec(co.resume(cor, co, ...))
  if not val[1] then
    error(val[2])
  end
  local gen = {
    tag = M.GEN,
    -- TODO maybe these shouldnt be functions
    idx = function ()
      return idx
    end,
    done = function ()
      return co.status(cor) == "dead"
    end
  }
  return setmetatable(gen, {
    __index = M,
    __call = function (...)
      if gen:done() then
        return
      end
      local nval = vec(co.resume(cor, ...))
      if not nval[1] then
        error(nval[2])
      else
        local ret = val
        val = nval
        idx = idx + 1
        return ret:unpack(2)
      end
    end
  })
end

-- TODO: Cache value on :done() not on generator
-- creation.
M.gensent = function (fn, sent, ...)
  assert(type(fn) == "function")
  local idx = 0
  local val = vec(fn(...))
  local gen = {
    tag = M.GEN,
    idx = function ()
      return idx
    end,
    done = function ()
      -- TODO: This only checks the first value
      -- when it should really check all values
      return val[1] == sent
    end
  }
  return setmetatable(gen, {
    __index = M,
    __call = function (...)
      if gen:done() then
        return
      end
      local nval = vec(fn(...))
      local ret = val
      val = nval
      idx = idx + 1
      return ret:unpack()
    end
  })
end

M.gennil = function (fn, ...)
  return M.gensent(fn, nil, ...)
end

-- TODO: Instead of relying on the user to
-- return M.END, pass M.END to fn so that the
-- user has it as a first arg to fn and can
-- return it, this hiding M.END from the user
M.genend = function (fn, ...)
  return M.gensent(fn, M.END, ...)
end

-- TODO: generator that signals end by returning
-- zero values. Not sure where we'd use this..
M.genzero = function ()
  err.unimplemented("genzero")
end

M.ipairs = function(t)
  assert(type(t) == "table")
  return M.genco(function (co)
    for k, v in ipairs(t) do
      co.yield(k, v)
    end
  end)
end

M.pairs = function(t)
  assert(type(t) == "table")
  return M.genco(function (co)
    for k, v in pairs(t) do
      co.yield(k, v)
    end
  end)
end

-- TODO: This should just be called gen(...) to
-- follow the pattern of vec and tbl
M.args = function (...)
  local args = vec(...)
  return M.genco(function (co)
    args:each(co.yield)
  end)
end

M.vals = function (t)
  assert(type(t) == "table")
  return M.pairs(t):map(fun.nret(2))
end

M.keys = function (t)
  assert(type(t) == "table")
  return M.pairs(t):map(fun.nret(1))
end

M.ivals = function (t)
  assert(type(t) == "table")
  return M.ipairs(t):map(fun.nret(2))
end

M.ikeys = function (t)
  assert(type(t) == "table")
  return M.ipairs(t):map(fun.nret(1))
end

M.map = function (gen, fn, ...)
  assert(M.isgen(gen))
  fn = fn or fun.id
  local args = vec(...)
  return M.genco(function (co)
    while not gen:done() do
      local val = vec(gen())
      co.yield(fn(val:extend(args):unpack()))
    end
  end)
end

M.reduce = function (gen, acc, ...)
  assert(M.isgen(gen))
  assert(type(acc) == "function")
  local val = vec(...)
  if gen:done() then
    return val:unpack()
  elseif val.n == 0 then
    val = vec(gen())
  end
  while not gen:done() do
    val = vec(acc(val:append(gen()):unpack()))
  end
  return val:unpack()
end

M.filter = function (gen, fn, ...)
  assert(M.isgen(gen))
  fn = fn or compat.id
  assert(type(fn) == "function")
  local args = vec(...)
  return M.genco(function (co)
    while not gen:done() do
      local val = vec(gen())
      if fn(val:extend(args):unpack()) then
        co.yield(val:unpack())
      end
    end
  end)
end

M.zip = function (opts, ...)
  local gens
  if M.isgen(opts) then
    gens = vec(opts, ...)
    opts = {}
  else
    gens = vec(...)
  end
  local mode = opts.mode or "first"
  assert(mode == "first" or mode == "longest")
  return M.genco(function (co)
    while true do
      local nb = 0
      local ret = vec()
      for i = 1, gens.n do
        local gen = gens[i]
        if not gen:done() then
          nb = nb + 1
          local val = vec(gen())
          ret = ret:append(val)
        elseif i == 1 and mode == "first" then
          return
        else
          ret = ret:append(vec())
        end
      end
      if nb == 0 then
        break
      else
        co.yield(ret:unpack())
      end
    end
  end)
end

M.take = function (gen, n)
  assert(M.isgen(gen))
  assert(n == nil or type(n) == "number")
  if n == nil then
    return gen
  else
    return M.genco(function (co)
      while n > 0 and not gen:done() do
        co.yield(gen())
        n = n - 1
      end
    end)
  end
end

M.find = function (gen, ...)
  assert(M.isgen(gen))
  return gen:filter(...):head()
end

M.pick = function (gen, n)
  assert(M.isgen(gen))
  return gen:slice(n, 1):head()
end

M.slice = function (gen, start, num)
  assert(M.isgen(gen))
  gen:take((start or 1) - 1):discard()
  return gen:take(num)
end

M.each = function (gen, fn, ...)
  assert(M.isgen(gen))
  while not gen:done() do
    fn(gen(), ...)
  end
end

M.tabulate = function (gen, opts, ...)
  assert(M.isgen(gen))
  local keys
  if type(opts) == "table" then
    keys = M.args(...)
  else
    keys = M.args(opts, ...)
    opts = {}
  end
  local rest = opts.rest
  local t = keys:zip(gen):reduce(function (a, k, v)
    a[k[1]] = v[1]
    return a
  end, {})
  if rest then
    t[rest] = gen:vec()
  end
  return t
end

M.chain = function (...)
  return M.flatten(M.args(...))
end

M.flatten = function (gengen)
  assert(M.isgen(gengen))
  return M.genco(function (co)
    gengen:each(function (gen)
      gen:each(co.yield)
    end)
  end)
end

M.chunk = function (gen, n)
  assert(M.isgen(gen))
  return M.genco(function (co)
    while not gen:done() do
      co.yield(gen:take(n):vec())
    end
  end)
end

M.unlazy = function (gen, n)
  assert(M.isgen(gen))
  return M.genco(function (co)
    gen:take(n):vec():each(co.yield)
  end)
end

-- TODO: WHY DOES THIS NOT WORK!?
-- M.all = M.reducer(op["and"], true)
M.all = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (a, n)
    return a and n
  end, true)
end

M.none = fun.compose(op["not"], M.find)

M.discard = function (gen)
  assert(M.isgen(gen))
  while not gen:done() do
    gen()
  end
end

-- TODO: Need some tests to define nil handing
-- behavior
M.vec = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (a, ...)
    if select("#", ...) <= 1 then
      return a:append(...)
    else
      return a:append({ ... })
    end
  end, vec())
end

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
  local vals = M.zip({ mode = "longest" }, ...):map(vec.equals):all()
  return vals and M.args(...):map(M.done):all()
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

M.head = function (gen)
  assert(M.isgen(gen))
  return gen()
end

M.tail = function (gen)
  assert(M.isgen(gen))
  gen()
  return gen
end

M.done = function (gen)
  assert(M.isgen(gen))
  return gen:done()
end

return M
