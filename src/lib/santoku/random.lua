-- TODO: Cryptography functions

local M = {}

M.seed = function (t)
  t = t or os.time()
  math.randomseed(t)
end

M.str = function (n)
  local t = {}
  n = n or 1
  while n > 0 do
    t[n] = string.char(math.random(32, 127))
  end
  return table.concat(t)
end

return M
