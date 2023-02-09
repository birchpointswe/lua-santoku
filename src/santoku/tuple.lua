local M = {}

local function tuple (n, a, ...)
  if n == 0 then
    return function (...) 
      return ... 
    end, 0
  else 
    local rest = tuple(n - 1, ...)
    return function (...)
      return a, rest(...)
    end, n
  end
end

M.equals = function (a, ...)
  local m = select("#", a())
  local ts = select("#", ...)
  for j = 1, ts do
    local b = select(j, ...)
    if b == nil then
      return false
    end
    local n = select("#", b()) 
    if m ~= n then
      return false
    end
  end
  for i = 1, m do
    local v = select(i, a())
    for j = 1, ts do
      local b = select(j, ...)
      local w = select(i, b()) 
      if v ~= w then
        return false
      end
    end
  end
  return true
end

M.tuple = function (...)
  return tuple(select("#", ...), ...)
end

return setmetatable(M, {
  __call = function (_, ...)
    return M.tuple(...)
  end
})
