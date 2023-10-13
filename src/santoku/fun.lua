local compat = require("santoku.compat")
local vec = require("santoku.vector")

local M = {}

-- TODO: Can this be made more efficient?
-- TODO: Rename/refactor to curry(2, 3, fn, a)
M.narg = function (...)
  local idx = vec(...)
  return function (fn, ...)
    assert(compat.hasmeta.call(fn))
    local bound = vec(...)
    return function (...)
      local args = vec(...):extend(bound)
      local nargs = vec()
      for i = 1, idx.n do
        nargs:move(args, nargs.n + 1, idx[i], idx[i])
      end
      nargs:move(args)
      return fn(nargs:unpack())
    end
  end
end

M.bindr = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  local args = vec(...)
  return function (...)
    return fn(vec(...):extend(args):unpack())
  end
end

M.bindl = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  local args = vec(...)
  return function (...)
    return fn(args:append(...):unpack())
  end
end

M.bind = M.bindr

M.maybel = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  fn = M.bindl(fn or compat.id, ...)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

M.mayber = function (fn, ...)
  assert(compat.hasmeta.call(fn))
  fn = M.bindr(fn or compat.id, ...)
  return function (ok, ...)
    if ok then
      return true, fn(...)
    else
      return false, ...
    end
  end
end

M.maybe = M.mayber

-- TODO: Use 0 to specify "rest": If its last,
-- append rest to the end, if it's first, append
-- rest to the "holes" left by the indices
M.nret = function (...)
  local idx = vec(...)
  return function (...)
    local rets = vec()
    for i = 1, idx.n do
      local nret = select(idx[i], ...)
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
      assert(compat.hasmeta.call(fns[i]))
      args = vec(fns[i](args:unpack()))
    end
    return args:unpack()
  end
end

M.sel = function (n, f)
  assert(compat.hasmeta.call(f))
  return function (...)
    return f(select(n, ...))
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
