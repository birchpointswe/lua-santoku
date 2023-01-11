local compat = require("santoku.compat")
local vec = require("santoku.vector")

local M = {}

-- This is effectively a curry/bind function
-- that also allows for argument re-ordering
--
-- TODO: Figure out the arglist before returning
-- the new function instead of re-computing the
-- arglist for every function call. Do the same
-- with nret below.
--
-- TODO: This is not very efficient due to the
-- above and the creation of a new arglist
M.narg = function (...)
  local idx = vec(...)
  return function (fn, ...)
    local bound = vec(...)
    return function (...)
      local args = vec(...):extend(bound)
      local nargs = vec()
      idx:each(function (i)
        nargs:move(args, nargs.n + 1, i, i)
      end)
      nargs:move(args)
      return fn(nargs:unpack())
    end
  end
end

-- TODO: Could an index of 0 mean something
-- useful?
M.nret = function (...)
  local idx = vec(...)
  return function (...)
    local args = vec(...)
    local rets = vec()
    for i = 1, idx.n do
      local nret = args[idx[i]]
      rets = rets:append(nret)
    end
    return rets:unpack()
  end
end

M.compose = function (...)
  local fns = vec(...)
  return function(...)
    local args = vec(...)
    for i = fns.n, 1, -1 do
      assert(type(fns[i]) == "function")
      args = vec(fns[i](args:unpack()))
    end
    return args:unpack()
  end
end

M.maybe = function (a, f, g)
  f = f or compat.id
  g = g or compat.const(a)
  if a then
    return f(a)
  else
    return g()
  end
end

M.choose = function (a, b, c)
  if a then
    return b
  else
    return c
  end
end

return M
