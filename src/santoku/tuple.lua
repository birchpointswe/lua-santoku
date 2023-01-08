-- TODO: Need: push, pop, head, tail, len, each,
-- get(n), set(n), reverse
-- TODO: Want: map, reduce, filter, zip, slice, etc
-- TODO: Some of these functions can likely
-- cheat intead of having to completely
-- re-create tuples after modifying them
-- TODO: Should probably call this list instead
-- of tuple

local M = {}

M.tuple = function (...)
  return M.tuplew(M.tupleh(nil, 0, select('#', ...), ...))
end

-- TODO: Do we really need to iterate both
-- tuples to concatenate them?
M.append = function (a, ...)
  local nxt, nnxt = M.tupleh(nil, 0, select("#", ...), ...)
  local ret, nret = M.tupleh(nxt, nnxt, select("#", a()), a())
  return M.tuplew(ret, nret)
end

M.tupleh = function (nxt, m, n, first, ...)
  nxt = nxt or function () end
  if n == 0 then
    return function ()
      return nxt()
    end, m
  elseif n == 1 then
    return function()
      return first, nxt()
    end, m + 1
  else
    local rest, m0 = M.tupleh(nxt, m, n - 1, ...)
    return function()
      return first, rest()
    end, m0 + 1
  end
end

M.tuplew = function (t, n)
  return setmetatable({ n = n }, {
    __index = M,
    __call = t
  })
end

M.len = function (tup)
  return tup.n
end

M.sel = function (tup, i)
  return M.tuple(select(i, tup()))
end

M.head = function (tup)
  return (tup())
end

M.get = function (tup, i)
  return tup:sel(i):head()
end

-- TODO: Eventually replace the for loop with a
-- range generator
M.equals = function (a, ...)
  local tups = M.tuple(...)
  for i = 1, tups:len() do
    if tups:get(i):len() ~= a:len() then
      return false
    end
  end
  for i = 1, tups:len() do
    for j = 1, a:len() do
      if tups:get(i):get(j) ~= a:get(j) then
        return false
      end
    end
  end
  return true
end

return setmetatable({}, {
  __index = M,
  __call = function (_, ...)
    return M.tuple(...)
  end
})
