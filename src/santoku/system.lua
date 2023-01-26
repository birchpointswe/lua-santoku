local gen = require("santoku.gen")

local M = {}

M.popen = function (...)
  local cmd = table.concat({ ... }, " ")
  local ok, iter, cd = pcall(io.popen, cmd, "r")
  if ok then
    -- TODO: Doesn't close the file handle
    return true, gen.gennil(iter:lines())
  else
    return false, iter, cd
  end
end

return M
