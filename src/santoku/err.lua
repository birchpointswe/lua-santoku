local vec = require("santoku.vector")
local compat = require("santoku.compat")
local co = require("santoku.co")

local M = {}

M.unimplemented = function (msg)
  M.error("Unimplemented", msg)
end

M.error = function (...)
  error(table.concat({ ... }, ": "), 2)
end

M.pwrapper = function (co, ...)
  local errs = vec(...)
  local wrapper = {
    err = function (...)
      return M.pwrapper(co, ...)
    end,
    exists = function (val, ...)
      local args = vec(...)
      if val ~= nil then
        return val, ...
      else
        return co.yield(vec():extend(errs, args):unpack())
      end
    end,
    ok = function (ok, ...)
      local args = vec(...)
      if ok then
        return ...
      else
        return co.yield(vec():extend(errs, args):unpack())
      end
    end
  }
  return setmetatable(wrapper, {
    __call = function (_, ...)
      return wrapper.ok(...)
    end
  })
end

-- TODO: allow error recovery and passing details to onErr
-- handler
-- TODO: pass uncaught errors to onErr
-- TODO: Pick an error level that makes errors
-- more readable
-- TODO: Reduce table creations with vec reuse
M.pwrap = function (run, onErr)
  onErr = onErr or compat.id
  local co = co.make()
  local cor = co.create(function ()
    return run(M.pwrapper(co))
  end)
  local ret
  local nxt = vec()
  while true do
    ret = vec(co.resume(cor, nxt:unpack()))
    local status = co.status(cor)
    if status == "dead" then
      break
    elseif status == "suspended" then
      if onErr == error then
        ret = vec(ret[2])
      end
      ret = vec(onErr(ret:unpack()))
      if ret[1] then
        nxt = ret.slice(2)
      else
        ret = ret.slice(2)
        break
      end
    end
  end
  return ret:unpack()
end

return M
