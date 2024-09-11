local varg = require("santoku.varg")
local tup = varg.tup

local M = {}

M._pipe = function (n, fns, ok, ...)
  if not ok or n == #fns then
    return fns[#fns](ok, ...)
  else
    return fns[n](function (...)
      return M._pipe(n + 1, fns, ...)
    end, ...)
  end
end

-- TODO: This should be generalizable. Some kind
-- of tup.reducek or tup.cont that reduces over
-- a list of arguments and allows for early
-- exit. tup.reduce_until? Something in iter?
M.pipe = function (...)
  local fns = { ... }
  return M._pipe(1, fns, true)
end

M._each = function (g, it, done)
  return tup(function (...)
    if ... == nil then
      return done(true)
    else
      return it(function (ok, ...)
        if not ok then
          return done(ok, ...)
        else
          return M._each(g, it, done)
        end
      end, ...)
    end
  end, g())
end

M.each = function (g, it, done)
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
