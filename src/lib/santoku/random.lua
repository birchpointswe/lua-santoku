-- TODO: Cryptography functions

local M = {}

M.seed = function (t)
  t = t or os.time()
  math.randomseed(t)
end

M.str = function (n, ...)
  assert(type(n) == "number" and n > 0)
  local l, u
  if select("#", ...) > 0 then
    l, u = ...
  else
    l, u = 32, 127
  end
  assert(type(l) == "number" and l >= 0)
  assert(type(u) == "number" and u >= l)
  local t = {}
  n = n or 1
  while n > 0 do
    t[n] = string.char(math.random(l, u))
    n = n - 1
  end
  return table.concat(t)
end

M.alnum = function (n) 
  return M.str(n, 48, 122)
end

return M
