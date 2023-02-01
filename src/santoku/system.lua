local gen = require("santoku.gen")
local env = require("santoku.env")

local M = {}

M.tmpfile = function ()
  local fp, err = os.tmpname()
  if not fp then
    return false, err
  else
    return true, fp
  end
end

-- TODO: Shell escapes
M.sh = function (...)
  local cmd = table.concat({ ... }, " ")
    :gsub("%$","\\$")
  local ok, iter, cd = pcall(io.popen, cmd, "r")
  if ok then
    -- TODO: Doesn't close the file handle
    -- TODO: Allow user to configure chunks, etc
    return true, gen.iter(iter:lines())
  else
    return false, iter, cd
  end
end

-- TODO: Currently this function accepts a path
-- to a lua file and calls the interpreter on it
-- directly. Should this instead accept a module
-- and use <interp> -e "require(<mod>)"?
M.lua = function (m, ...)
  local interp = env.interpreter()
  return M.sh(interp:append(m, ...):unpack())
end

M.execute = function (...)
  local ok, out, cd = M.sh(...)
  if not ok then
    return false, out, cd
  else
    out:each(print)
    return true
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
