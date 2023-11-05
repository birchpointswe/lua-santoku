local M = {}

M.trunc = function (n, d)
  local i, f = math.modf(n)
  d = 10^d
  return i + math.modf(f * d) / d
end

return M
