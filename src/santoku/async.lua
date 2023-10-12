-- TODO: Should these use pcalls?

local gen = require("santoku.gen")
local compat = require("santoku.compat")
local tup = require("santoku.tuple")

local M = {}

local function pipe (final, ok, args, fns)
  local fn = fns()
  if not ok or not fn then
    return final(ok, args())
  else
    return fn(function (ok, ...)
      return pipe(final, ok, tup(...), tup(select(2, fns())))
    end, args())
  end
end

-- TODO: This should be generalizable. Some kind
-- of tup.reducek or tup.cont that reduces over
-- a list of arguments and allows for early
-- exit. tup.reduce_until? Something in gen?
M.pipe = function (...)
  local n = tup.len(...)
  local final = tup.sel(n, ...)
  local fns = tup(tup.take(n - 1, ...))
  return pipe(final, true, tup(), fns)
end

local function each (g, it, done)
  if g:done() or not g:step() then
    return done(true)
  else
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        return each(g, it, done)
      end
    end, g.val())
  end
end

M.each = function (g, it, done)
  assert(gen.iscogen(g))
  assert(compat.iscallable(it))
  return each(g, it, done)
end

local function iter (y, it, done)
  return y(function (...)
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        -- NOTE: Throwing away values returned
        -- from iteration function
        return iter(y, it, done)
      end
    end, ...)
  end, done)
end

M.iter = function (y, it, done)
  return iter(y, it, done)
end

local function loop (loop0, final, ...)
  return loop0(function (...)
    return loop(loop0, final, ...)
  end, function (...)
    return final(...)
  end, ...)
end

M.loop = function (loop0, final)
  return loop(loop0, final)
end

return M
