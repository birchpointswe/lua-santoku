local vec = require("santoku.vector")

local M = {}

M.interpreter = function (args)
  local arg = arg or {}
  local i_min = -1
  while arg[i_min] do
    i_min = i_min - 1
  end
  i_min = i_min + 1
  local ret = vec()
  local i = i_min
  while i < 0 do
    ret:append(arg[i])
    i = i + 1
  end
  if args then
    while arg[i] do
      ret:append(arg[i])
      i = i + 1
    end
  end
  return ret
end

return M
