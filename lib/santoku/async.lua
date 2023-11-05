-- TODO: Should these use pcalls?
-- TODO: asserts

local gen = require("santoku.gen")
local compat = require("santoku.compat")
local tup = require("santoku.tuple")

local M = {}

M._pipe = function (final, ok, args, fns)
  local fn = fns()
  if not ok or not fn then
    return final(ok, args())
  else
    return fn(function (ok, ...)
      return M._pipe(final, ok, tup(...), tup(select(2, fns())))
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
  return M._pipe(final, true, tup(), fns)
end

M._each = function (g, it, done)
  if g:done() or not g:step() then
    return done(true)
  else
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        return M._each(g, it, done)
      end
    end, g.val())
  end
end

M.each = function (g, it, done)
  assert(gen.iscogen(g))
  assert(compat.hasmeta.call(it))
  return M._each(g, it, done)
end

M._iter = function (y, it, done)
  return y(function (...)
    return it(function (ok, ...)
      if not ok then
        return done(ok, ...)
      else
        -- NOTE: Throwing away values returned
        -- from iteration function
        return M._iter(y, it, done)
      end
    end, ...)
  end, done)
end

M.iter = function (y, it, done)
  return M._iter(y, it, done)
end

M._loop = function (loop0, final, ...)
  return loop0(function (...)
    return M._loop(loop0, final, ...)
  end, function (...)
    return final(...)
  end, ...)
end

M.loop = function (loop0, final)
  return M._loop(loop0, final)
end

return M
