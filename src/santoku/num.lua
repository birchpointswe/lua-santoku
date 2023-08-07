local M = {}

M.round = function (n, places)
  places = places or 0
  local x = 10^places
  return math.floor(n * x + 0.5) / x
end

return M
