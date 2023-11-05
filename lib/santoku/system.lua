local gen = require("santoku.gen")
local tup = require("santoku.tuple")
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
  local cmd = tup.concat(tup.interleave(" ", ...))
    :gsub("%$","\\$")
  local ok, iter, cd = pcall(io.popen, cmd, "r")
  if ok then
    -- TODO: Doesn't close the file handle
    -- automatically
    -- TODO: Allow user to configure chunks, etc
    return true, gen.iter(iter:lines()), function ()
      local ok, t, cd = iter:close()
      if ok and t == "exit" then
        return true, cd
      else
        return ok, t, cd
      end
    end
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
  local ok, out, close = M.sh(...)
  if not ok then
    return false, out, close
  else
    out:each(print)
    return close()
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
