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

local tbl = require("santoku.table")
local fun = require("santoku.fun")
local op = require("santoku.op")
local co = require("santoku.co")

local M = {}

-- TODO: Hide these from the user. For M.END,
-- see the note on M.genend
M.END = {}
M.GEN = {}

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
  local val = tbl.pack(co.resume(cor, co, ...))
  if not val[1] then
    error(val[2])
  end
  local gen = {
    tag = M.GEN,
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
      local nval = tbl.pack(co.resume(cor, ...))
      if not nval[1] then
        error(nval[2])
      else
        local ret = val
        val = nval
        idx = idx + 1
        return select(2, ret:unpack())
      end
    end
  })
end

-- TODO: Cache value on :done() not on generator
-- creation.
M.gensent = function (fn, sent, ...)
  assert(type(fn) == "function")
  local idx = 0
  local val = tbl.pack(fn(...))
  local gen = {
    tag = M.GEN,
    idx = function ()
      return idx
    end,
    done = function ()
      -- TODO: This only checks the first value
      -- when it should really check all values
      return val:unpack() == sent
    end
  }
  return setmetatable(gen, {
    __index = M,
    __call = function (...)
      if gen:done() then
        return
      end
      local nval = tbl.pack(fn(...))
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

M.args = function (...)
  local args = tbl.pack(...)
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

M.mapper = function (fn, ...)
  fn = fn or fun.id
  local args = tbl.pack(...)
  return function (gen)
    return M.genco(function (co)
      while not gen:done() do
        local val = tbl.pack(gen())
        co.yield(fn(val:extend(args):unpack()))
      end
    end)
  end
end

M.map = function (gen, fn, ...)
  return M.mapper(fn, ...)(gen)
end

M.reducer = function (acc, ...)
  assert(type(acc) == "function")
  local val = tbl.pack(...)
  return function (gen)
    assert(type(gen) == "table")
    assert(gen.tag == M.GEN)
    if gen:done() then
      return val:unpack()
    elseif val:len() == 0 then
      val = tbl.pack(gen())
    end
    while not gen:done() do
      val = tbl.pack(acc(val:append(gen()):unpack()))
    end
    return val:unpack()
  end
end

M.reduce = function (gen, acc, ...)
  return M.reducer(acc, ...)(gen)
end

M.filterer = function (fn, ...)
  fn = fn or fun.id
  assert(type(fn) == "function")
  local args = tbl.pack(...)
  return function (gen)
    return M.genco(function (co)
      while not gen:done() do
        local val = tbl.pack(gen())
        if fn(val:extend(args):unpack()) then
          co.yield(val:unpack())
        end
      end
    end)
  end
end

M.filter = function (gen, fn, ...)
  return M.filterer(fn, ...)(gen)
end

M.zipper = function (opts)
  local mode = (opts or {}).mode or "first"
  assert(mode == "first" or mode == "longest")
  return function (...)
    local gens = tbl.pack(...)
    return M.genco(function (co)
      while true do
        local nb = 0
        local ret = tbl.pack()
        for i = 1, gens:len() do
          local gen = gens[i]
          if not gen:done() then
            nb = nb + 1
            ret = ret:append(tbl.pack(gen()))
          elseif i == 1 and mode == "first" then
            return
          else
            ret = ret:append(tbl.pack())
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
end

M.zip = function (...)
  return M.zipper()(...)
end

M.taker = function (n)
  assert(n == nil or type(n) == "number")
  return function (gen)
    assert(type(gen) == "table")
    assert(gen.tag == M.GEN)
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
end

M.take = function (gen, n)
  return M.taker(n)(gen)
end

M.finder = function (...)
  local args = tbl.pack(...)
  return function (gen)
    return gen:filter(args:unpack()):head()
  end
end

M.find = function (gen, ...)
  return M.finder(...)(gen)
end

M.picker = function (n)
  return function (gen)
    return gen:slice(n, 1):head()
  end
end

M.pick = function (gen, n)
  return M.picker(n)(gen)
end

M.slicer = function (start, num)
  start = start or 1
  return function (gen)
    gen:take(start - 1):collect()
    return gen:take(num)
  end
end

M.slice = function (gen, start, num)
  return M.slicer(start, num)(gen)
end

M.eacher = function (fn)
  return function (gen)
    while not gen:done() do
      fn(gen())
    end
  end
end

M.each = function (gen, fn)
  return M.eacher(fn)(gen)
end

M.tabulator = function (keys, opts)
  local rest = (opts or {}).rest
  return function (genVals)
    local t = M.ivals(keys)
      :zip(genVals)
      :reduce(function (a, k, v)
        a[k[1]] = v[1]
        return a
      end, {})
    if rest then
      t[rest] = genVals:collect()
    end
    return t
  end
end

M.tabulate = function (gen, keys, opts)
  return M.tabulator(keys, opts)(gen)
end

M.chain = function (...)
  return M.flatten(M.args(...))
end

M.flatten = function (gengen)
  assert(type(gengen) == "table")
  assert(gengen.tag == M.GEN)
  return M.genco(function (co)
    M.each(gengen, M.eacher(co.yield))
  end)
end

M.any = M.finder()

-- TODO: WHY DOES THIS NOT WORK!?
-- M.all = M.reducer(op["and"], true)
M.all = function (gen)
  return gen:reduce(function (a, n)
    return a and n
  end, true)
end

M.none = fun.compose(op["not"], M.any)

-- TODO: Need some tests to define nil handing
-- behavior
M.collect = function (gen)
  return gen:reduce(function (a, ...)
    if select("#", ...) <= 1 then
      return tbl.append(a, ...)
    else
      return tbl.append(a, { ... })
    end
  end, {})
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
  local vals = M.zipper({ mode = "longest" })(...):map(tbl.equals):all()
  return vals and M.args(...):map(M.done):all()
end

M.max = function (gen, ...)
  return gen:reduce(function(a, b)
    if a > b then
      return a
    else
      return b
    end
  end, ...)
end

M.head = function (gen)
  return gen()
end

M.tail = function (gen)
  gen()
  return gen
end

M.done = function (gen)
  return gen:done()
end

return M
