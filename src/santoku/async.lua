local tup = require("santoku.tuple")

local M = {}

local function pipe (final, ok, args, fns)
  local fn = fns()
  if not ok or not fn then
    return final(ok, args())
  else
    return fn(args(function (ok, ...)
      return pipe(final, ok, tup(...), tup(select(2, fns())))
    end))
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
  return function (...)
    return pipe(final, true, tup(...), fns)
  end
end

return M
