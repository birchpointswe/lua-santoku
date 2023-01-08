-- TODO: push, pop, head, tail, len, each,
-- get(n), set(n), reverse, map, reduce, filter,
-- zip, slice, rb tree, etc
-- TODO: Some of these functions can likely
-- cheat intead of having to completely
-- re-create tuples after modifying them
-- TODO: Should probably call this list instead
-- of tuple

-- TODO: Leverage this library more fully in the
-- other modules

-- TODO: Reduce reliance on full-iteration of
-- tupleh. Can we directly modify n when we
-- push, pop, or otherwise modify? Can we print
-- in reverse?

-- TODO: expose tup.pack and tup.unpack
-- functions that mirror table.pack/unpack

local M = {}

M.tuple = function (...)
  return M.tuplew(M.tupleh(nil, 0, select('#', ...), ...))
end

-- TODO: Refactor to be O(1) instead of using
-- append()
M.push = function (a, b)
  return M.tuple(b):append(a())
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

M.tail = function (tup)
  return tup:sel(2)
end

-- TODO: Can tupleh be extended for this?
local each
each = function (fn, args, n, a, ...)
  if n == 0 then
    return
  else
    fn(a, args())
    each(fn, args, n - 1, ...)
  end
end

M.each = function (tup, fn, ...)
  return each(fn, M.tuple(...), tup:len(), tup())
end

M.get = function (tup, i)
  return tup:sel(i):head()
end

-- TODO: Eventually replace the for loop with a
-- range generator
-- TODO: There must be a more terse way to
-- represent this function
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

-- TODO: Can tupleh be extended for this?
local pick
pick = function (idx, head, tail, ret)
  if idx:len() == 0 then
    return head, tail, ret
  elseif tail:len() == 0 then
    return pick(idx:tail(), head:append(tail()), M.tuple(), ret)
  elseif idx:head() == head:len() + 1 then
    return pick(idx:tail():map(function (i)
      if i >= head:len() + 1 then
        return i - 1
      else
        return i
      end
    end), M.tuple(), head:append(tail:tail()()), ret:append(tail:head()))
  else
    return pick(idx, head:append(tail:head()), tail:tail(), ret)
  end
end

-- TODO: Extend to pick arbitrary number
M.pick = function (tup, ...)
  local h, t, p = pick(M.tuple(...), M.tuple(), tup, M.tuple())
  return h:append(t()), p
end

local map
map = function (head, tail, fn, ...)
  if tail:len() == 0 then
    return head
  else
    local v = fn(M.tuple(tail:head()):append(...)())
    return map(head:append(v), tail:tail(), fn, ...)
  end
end

M.map = function (tup, ...)
  return map(M.tuple(), tup, ...)
end

return setmetatable({}, {
  __index = M,
  __call = function (_, ...)
    return M.tuple(...)
  end
})
