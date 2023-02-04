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

local vec = require("santoku.vector")
local err = require("santoku.err")
local fun = require("santoku.fun")
local compat = require("santoku.compat")
local op = require("santoku.op")
local tup = require("santoku.tuple")

local M = {}

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
  }, {
    __index = M,
  })
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

M.ipairs = function(t)
  assert(type(t) == "table")
  return M.gen(function (yield)
    for k, v in ipairs(t) do
      yield(k, v)
    end
  end)
end

M.pairs = function(t)
  assert(type(t) == "table")
  local k, v
  local iter, state = pairs(t)
  return M.gen(function (yield)
    for k, v in pairs(t) do
      yield(k, v)
    end
  end)
end

-- TODO: This should just be called gen(...) to
-- follow the pattern of vec and tbl
M.args = function (...)
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

M.ivals = function (t)
  assert(type(t) == "table")
  return M.ipairs(t):map(fun.nret(2))
end

M.ikeys = function (t)
  assert(type(t) == "table")
  return M.ipairs(t):map(fun.nret(1))
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
  fn = fn or fun.id
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
  local val, m = tup(...)
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

M.find = function (gen, ...)
  assert(M.isgen(gen))
  return gen:filter(...):head()
end

M.tabulate = function (gen, opts, ...)
  assert(M.isgen(gen))
  local keys, nkeys
  if type(opts) == "table" then
    keys, nkeys = tup(...)
  else
    keys, nkeys = tup(opts, ...)
    opts = {}
  end
  local rest = opts.rest
  local ret = {}
  gen:index():each(function (idx, v)
    if idx >= nkeys then
      ret[select(idx, keys())] = v
    else
      -- TODO: Pause!
    end
  end)
  -- TODO: Resume!
  -- if rest then
  --   ret[rest] = gen:vec()
  -- end
  return ret
end

-- TODO: Pause/resume
-- M.zip = function (opts, ...)
--   local gens, ngens
--   if M.isgen(opts) then
--     gens, ngens = tup(opts, ...)
--     opts = {}
--   else
--     gens, ngens = tup(...)
--   end
--   return M.gen(function (yield, ...)
--     while true do
--       local nb = 0
--       local ret = tup()
--       for i = 1, ngens do
--         local gen = select(i, ...)
--         gen:index():each(function (idx, ...)
--         end)
--         if not gen:done() then
--           nb = nb + 1
--           local val = vec(gen())
--           ret = ret:append(val)
--         elseif i == 1 and mode == "first" then
--           return
--         else
--           ret = ret:append(vec())
--         end
--       end
--       if nb == 0 then
--         break
--       else
--         co.yield(ret:unpack())
--       end
--     end
--   end, gens())
-- end

M.take = function (gen, n)
  assert(M.isgen(gen))
  assert(n == nil or type(n) == "number")
  if n == nil then
    return gen:clone()
  else
    return M.gen(function (yield)
      return gen:each(function (...)
        if n > 0 then
          n = n - 1
          return yield(...)
        else
          -- TODO: Pause!
          -- return gen:stop()
        end
      end)
    end)
  end
end

M.slice = function (gen, start, num)
  assert(M.isgen(gen))
  gen:take((start or 1) - 1):discard()
  return gen:take(num)
end

M.each = function (gen, fn, ...)
  assert(M.isgen(gen))
  fn = fn or compat.noop
  assert(compat.iscallable(fn))
  return gen.run(fn, ...)
end

M.chain = function (...)
  return M.flatten(M.args(...))
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
      return (tup(t(...)))
    else
      return (tup(t((tup(...)))))
    end
  end, (tup()))
end

M.unpack = function (gen)
  assert(M.isgen(gen))
  return gen:tup()()
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

-- TODO: WHY DOES THIS NOT WORK!?
-- M.all = M.reducer(op["and"], true)
M.all = function (gen)
  assert(M.isgen(gen))
  return gen:reduce(function (a, n)
    return a and n
  end, true)
end

M.none = fun.compose(op["not"], M.find)

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

-- M.head = function (gen)
--   assert(M.isgen(gen))
--   return gen:each(function (...)
--     return gen:stop(...)
--   end)
-- end

-- M.last = function (gen)
--   assert(M.isgen(gen))
--   local last = tup()
--   gen:each(function (...)
--     last = tup(...)
--   end)
--   return last()
-- end

return setmetatable({}, {
  __index = M,
  __call = function (_, ...)
    return M.gen(...)
  end
})
