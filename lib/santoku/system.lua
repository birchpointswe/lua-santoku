local err = require("santoku.err")
local tup = require("santoku.tuple")

local M = {}

M.pread = require("santoku.system.pread")
M.sh = require("santoku.system.sh")

M.execute = function (...)
  local args = tup(...)
  return err.pwrap(function (check)
    check(M.sh(args())):map(check):each(print)
  end)
end

M.tmpfile = function ()
  local fp, err = os.tmpname()
  if not fp then
    return false, err
  else
    return true, fp
  end
end

M.rm = function (...)
  local ok, err, code = os.remove(...)
  if not ok then
    return false, err, code
  else
    return true
  end
end

return M
