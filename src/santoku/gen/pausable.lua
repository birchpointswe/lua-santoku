-- TODO: instead of using coroutines, can this
-- be implemented by returning a standard
-- generator with the remaining items?

local err = require("santoku.err")
local op = require("santoku.op")
local fun = require("santoku.fun")
local tup = require("santoku.tuple")

local M = {}

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
M.zip = function (opts, ...)
  local gens, ngens
  if M.isgen(opts) then
    gens, ngens = tup(opts, ...)
    opts = {}
  else
    gens, ngens = tup(...)
  end
  return M.gen(function (yield, ...)
    while true do
      local nb = 0
      local ret = tup()
      for i = 1, ngens do
        local gen = select(i, ...)
        gen:index():each(function (idx, ...)
        end)
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
  end, gens())
end

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

M.none = fun.compose(op["not"], M.find)

M.head = function (gen)
  assert(M.isgen(gen))
  return gen:each(function (...)
    return gen:stop(...)
  end)
end

return M
